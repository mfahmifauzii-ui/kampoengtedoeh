--!strict
-- Fishing: cast (ProximityPrompt) -> bite after a server-rolled delay -> client reel
-- mini-game -> catch. The fish is rolled by the SERVER at cast time; the client's reel
-- score only picks the size tier. A catch can never fail.
-- Also runs the player-built ponds (kolam), which fill while the owner is offline.
--
-- World contract: Workspace > Folder "Fishing" containing BaseParts tagged "FishingSpot"
-- with attribute Location = "sungai" | "empang". Placeholders are built if it's missing.
-- Every pond the player builds gets a part via FishService.SetupPond (tags "FishingSpot" + "Pond",
-- Location = "kolam", PondUid = its data.pond.list entry).
--
-- Day phase / rain are read from Workspace attributes "DayPhase" and "Raining"
-- (set by the world cycle in Phase 7; defaults: "siang", false).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local BookService = require(script.Parent.BookService)
local QuestService = require(script.Parent.QuestService)
local AnalyticsHooks = require(script.Parent.AnalyticsHooks)
local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local Types = require(ReplicatedStorage.Shared.Types)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)

type Fish = FishConfig.Fish
type Rarity = FishConfig.Rarity

local SPOT_TAG = "FishingSpot"
local POND_TAG = "Pond"
local WATER_COLOR = Color3.fromRGB(60, 148, 168)
local RARITY_ORDER: { Rarity } = { "C", "U", "R", "L" }

type Session = {
	spot: BasePart,
	fishId: string,
	biteAt: number, -- os.clock
}

local sessions: { [Player]: Session } = {}
local random = Random.new()

local FishService = {}

-- Conditions ---------------------------------------------------------------------

local function getConditions(): (string, boolean)
	local phase = Workspace:GetAttribute("DayPhase")
	local raining = Workspace:GetAttribute("Raining")
	return (if typeof(phase) == "string" then phase else "siang"), raining == true
end

local function isAvailable(fish: Fish, phase: string, raining: boolean): boolean
	if fish.requirePhases and not table.find(fish.requirePhases, phase) then
		return false
	end
	if fish.requireRain and not raining then
		return false
	end
	return true
end

local function fishWeight(fish: Fish, phase: string, raining: boolean): number
	local boost = fish.boost
	if boost and (boost.phase == nil or boost.phase == phase) and (boost.rain == nil or boost.rain == raining) then
		return boost.mult
	end
	return 1
end

-- Two-step roll: pick a rarity tier (only tiers with an available fish count),
-- then pick a fish inside that tier by its own weight.
local function rollFish(location: string, rareBonus: number, legendaryBonus: number, allowed: { [Rarity]: boolean }?): string?
	local phase, raining = getConditions()

	local byTier: { [Rarity]: { { fish: Fish, weight: number } } } = {}
	for _, fish in FishConfig.list do
		if table.find(fish.locations, location) and isAvailable(fish, phase, raining) and (not allowed or allowed[fish.rarity]) then
			local tier = byTier[fish.rarity] or {}
			table.insert(tier, { fish = fish, weight = fishWeight(fish, phase, raining) })
			byTier[fish.rarity] = tier
		end
	end

	local tierWeights: { [Rarity]: number } = {}
	local total = 0
	for _, rarity in RARITY_ORDER do
		if byTier[rarity] then
			local weight = FishConfig.RARITY_WEIGHTS[rarity]
			if rarity == "R" then
				weight += rareBonus
			elseif rarity == "L" then
				weight += legendaryBonus
			end
			if raining and FishConfig.RAIN_MULT[rarity] then
				weight *= FishConfig.RAIN_MULT[rarity]
			end
			tierWeights[rarity] = weight
			total += weight
		end
	end
	if total <= 0 then
		return nil
	end

	local roll = random:NextNumber() * total
	local chosen: Rarity = "C"
	for _, rarity in RARITY_ORDER do
		local weight = tierWeights[rarity]
		if weight then
			chosen = rarity
			roll -= weight
			if roll <= 0 then
				break
			end
		end
	end

	local candidates = byTier[chosen]
	local candidateTotal = 0
	for _, entry in candidates do
		candidateTotal += entry.weight
	end
	local pick = random:NextNumber() * candidateTotal
	for _, entry in candidates do
		pick -= entry.weight
		if pick <= 0 then
			return entry.fish.id
		end
	end
	return candidates[#candidates].fish.id
end

local function sizeFor(score: number): string
	local size = FishConfig.SIZES[1].id
	for _, entry in FishConfig.SIZES do
		if score >= entry.minScore then
			size = entry.id
		end
	end
	return size
end

-- Item ids for fish carry their size: "nila@M".
function FishService.ItemId(fishId: string, size: string): string
	return `{fishId}@{size}`
end

-- Casting ------------------------------------------------------------------------

local function isNear(player: Player, part: BasePart, distance: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and (root.Position - part.Position).Magnitude <= distance
end

local function endSession(player: Player)
	sessions[player] = nil
	Net.Fire("FishState", player, "idle")
end

local function startCast(player: Player, spot: BasePart)
	local data = DataService.Get(player)
	local location = spot:GetAttribute("Location")
	if not data or typeof(location) ~= "string" then
		return
	end
	local locationConfig = Fishing.LOCATIONS[location]
	if not locationConfig then
		return
	end

	local existing = sessions[player]
	-- NO TIMEOUT (user, 16 Nov): a fish that bit stays on the line until it is reeled in or the player cancels.
	-- There is no "kabur" timer any more, so an existing session always means "already fishing".
	if existing then
		return -- already fishing
	end
	if location == "kolam" and spot:GetAttribute("Owner") ~= player.UserId then
		return
	end
	-- Tutorial gate (not a level): the dock and the pond open at Lv 1, but only after Kak Fajar's gift (fishingUnlocked).
	if data.guide.fishingUnlocked ~= true then
		Net.Fire("Notify", player, "fish.tut_locked")
		return
	end
	if data.level < locationConfig.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = locationConfig.unlockLevel })
		return
	end
	-- No rod without Kak Fajar's gift (Opsi B): the server checks ownership itself, the client never decides this.
	if data.fishing.rod == "" or data.fishing.ownedRods[data.fishing.rod] ~= true or Fishing.rods[data.fishing.rod] == nil then
		Net.Fire("Notify", player, "fish.need_rod")
		return
	end
	if not isNear(player, spot, Fishing.CAST_DISTANCE) then
		return
	end

	-- Need a free slot up front so a finished reel is never lost to a full bag.
	if not InventoryService.HasFreeSlot(player) then
		Net.Fire("Notify", player, "inv.full")
		return
	end

	local rod = Fishing.rods[data.fishing.rod]
	if not rod then
		return -- cannot happen after the rod check above; kept so the type stays exact
	end
	local fishId = rollFish(location, rod.rareBonus, rod.legendaryBonus, nil)
	if not fishId then
		Net.Fire("Notify", player, "fish.none_here")
		return
	end

	local biteDelay = random:NextNumber(Fishing.BITE_MIN, Fishing.BITE_MAX) * rod.biteMult
	if InventoryService.Remove(player, Fishing.BAIT.id, 1) then
		biteDelay *= 1 - Fishing.BAIT.biteReduction
	end
	local session: Session = { spot = spot, fishId = fishId, biteAt = os.clock() + biteDelay }
	sessions[player] = session
	Net.Fire("FishState", player, "waiting", spot)

	task.delay(biteDelay, function()
		if sessions[player] == session then
			Net.Fire("FishState", player, "bite")
		end
	end)
end

local function onReel(player: Player, score: any)
	local session = sessions[player]
	if not session or typeof(score) ~= "number" or score ~= score then
		return
	end
	local elapsed = os.clock() - session.biteAt
	if elapsed < Fishing.REEL_MIN_SECONDS then
		return -- too fast to be a real reel; keep the session so a legit reel still lands
	end
	-- NO TIMEOUT: the bite never expires, the player can reel in whenever they tap (no fail state).

	local size = sizeFor(math.clamp(score, 0, 1))
	sessions[player] = nil
	if InventoryService.Add(player, FishService.ItemId(session.fishId, size), 1) then
		Net.Fire("Notify", player, "fish.caught", { item = `fish.{session.fishId}`, size = `size.{size}` })
		local caughtData = DataService.Get(player)
		if caughtData then
			caughtData.guide.fishCaught = true -- the t1b "after_catch" step only passes after a real catch
		end
		local fish = FishConfig.byId[session.fishId]
		ProgressionService.AddXp(player, Progression.FISH_XP[fish.rarity] or 0, `catch:{fish.id}`)
		BookService.RecordFish(player, fish.id, size)
		AnalyticsHooks.Step(player, "first_catch")
		QuestService.Report(player, "catch")
		if session.spot:GetAttribute("Location") == "kolam" then
			QuestService.Report(player, "catch_pond")
		end
	end
	Net.Fire("FishState", player, "idle")
end

local function onCancel(player: Player)
	if sessions[player] then
		endSession(player)
	end
end
FishService.Cancel = onCancel -- used by SocialService when teleporting

-- Pond (kolam) -------------------------------------------------------------------

local function pondCap(tier: number): number
	return Fishing.POND.CAPS[math.clamp(tier + 1, 1, #Fishing.POND.CAPS)]
end

-- Each pond part carries Attribute "PondUid" = its PondEntry.uid in data.pond.list.
local function findEntry(data: Types.PlayerData, pond: BasePart): Types.PondEntry?
	local uid = pond:GetAttribute("PondUid")
	for _, entry in data.pond.list do
		if entry.uid == uid then
			return entry
		end
	end
	return nil
end

local function syncPond(player: Player, pond: BasePart)
	local data = DataService.Get(player)
	local entry = data and findEntry(data, pond)
	if data and entry then
		pond:SetAttribute("LastCollect", entry.lastCollect)
		pond:SetAttribute("Cap", pondCap(Upgrades.tier(data, "pond")))
	end
end

local function collectPond(player: Player, pond: BasePart)
	local data = DataService.Get(player)
	if not data or pond:GetAttribute("Owner") ~= player.UserId or not isNear(player, pond, Fishing.CAST_DISTANCE) then
		return
	end
	local entry = findEntry(data, pond)
	if not entry then
		return
	end
	if data.level < Fishing.LOCATIONS.kolam.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = Fishing.LOCATIONS.kolam.unlockLevel })
		return
	end

	local now = os.time()
	local cap = pondCap(Upgrades.tier(data, "pond"))
	local ready = (now - entry.lastCollect) // Fishing.POND.INTERVAL
	local count = math.min(ready, cap)
	if count <= 0 then
		Net.Fire("Notify", player, "pond.empty")
		return
	end

	-- Stops at the first fish that doesn't fit; the rest stay in the pond.
	local allowed = { C = true, U = true }
	local collected = 0
	for _ = 1, count do
		local fishId = rollFish("kolam", 0, 0, allowed)
		if not fishId then
			break
		end
		local size = if random:NextNumber() < 0.7 then "S" else "M"
		if not InventoryService.Add(player, FishService.ItemId(fishId, size), 1) then
			break
		end
		BookService.RecordFish(player, fishId, size)
		collected += 1
	end
	if collected == 0 then
		return
	end

	if ready > cap and collected == count then
		entry.lastCollect = now -- pond was overflowing: restart the clock
	else
		local backlog = math.min(ready, cap) -- never bank more than the cap
		entry.lastCollect = now - (backlog - collected) * Fishing.POND.INTERVAL - (now - entry.lastCollect) % Fishing.POND.INTERVAL
	end
	syncPond(player, pond)
	Net.Fire("Notify", player, "pond.collected", { n = collected })
end

local function makePrompt(parent: BasePart, name: string, actionKey: string, order: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = Locale.t(actionKey)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, order * 72)
	prompt.Parent = parent
	return prompt
end

local function setupSpot(spot: BasePart)
	local location = spot:GetAttribute("Location")
	-- Dermaga pancing punya nama sendiri (Basic / Pro Mancing); kolam milik pemain tetap "Mancing".
	local actionKey = if location == "sungai" or location == "empang" then `spot.{location}` else "prompt.fish"
	local prompt = makePrompt(spot, "FishPrompt", actionKey, 0)
	-- Stage 5 (user, 16 Nov): the fishing prompt of EVERY spot (kolam, dermaga sungai, dermaga empang) shows only within
	-- 4 studs, the same as a bed's proximity. Outside 4 studs there is no button.
	prompt.MaxActivationDistance = 4
	prompt.Triggered:Connect(function(player)
		startCast(player, spot)
	end)
	CollectionService:AddTag(spot, SPOT_TAG)
end

-- Turns an (invisible) part over a player-built pond into the fishing + collect spot.
-- Called by the pond builder (phase 2) once the water terrain exists; there is no fixed pond anymore.
function FishService.SetupPond(player: Player, pond: BasePart, entry: Types.PondEntry)
	pond:SetAttribute("Location", "kolam")
	pond:SetAttribute("Owner", player.UserId)
	pond:SetAttribute("PondUid", entry.uid)

	setupSpot(pond)
	-- Two prompts on one part: different keys + AlwaysShow, otherwise Roblox shows only one.
	local collect = makePrompt(pond, "CollectPrompt", "prompt.pond_collect", 1)
	collect.KeyboardKeyCode = Enum.KeyCode.F
	collect.GamepadKeyCode = Enum.KeyCode.ButtonY
	collect.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	local fishPrompt = pond:FindFirstChild("FishPrompt") :: ProximityPrompt
	fishPrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	collect.Triggered:Connect(function(triggeredBy)
		collectPond(triggeredBy, pond)
	end)
	CollectionService:AddTag(pond, POND_TAG)
	syncPond(player, pond)
end

-- Placeholder water ---------------------------------------------------------------

local function buildPlaceholderWater(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Fishing"

	local function water(name: string, size: Vector3, position: Vector3)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.Size = size
		part.Position = position
		part.Color = WATER_COLOR
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0.15
		part.Parent = folder
	end

	local function spot(location: string, position: Vector3)
		local part = Instance.new("Part")
		part.Name = `Spot_{location}`
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Size = Vector3.new(2, 1, 2)
		part.Position = position
		part:SetAttribute("Location", location)
		part.Parent = folder
	end

	-- Sungai: long strip behind the first row of plots.
	water("Sungai", Vector3.new(480, 0.6, 20), Vector3.new(0, 0.2, -150))
	for x = -200, 200, 80 do
		spot("sungai", Vector3.new(x, 0.6, -142))
	end

	-- Empang: village pond east of the plots.
	water("Empang", Vector3.new(40, 0.6, 40), Vector3.new(270, 0.2, 0))
	for _, offset in { Vector3.new(-18, 0, 0), Vector3.new(18, 0, 0), Vector3.new(0, 0, -18), Vector3.new(0, 0, 18) } do
		spot("empang", Vector3.new(270, 0.6, 0) + offset)
	end

	folder.Parent = Workspace
	return folder
end

-- Lifecycle ---------------------------------------------------------------------

-- The Mancing button (v6.2.3 A3): cast at the nearest fishing spot within CAST_DISTANCE. The server picks the spot;
-- startCast checks everything else (gift, level, rod, distance).
local function onCastNearest(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local best: BasePart? = nil
	local bestDistance = Fishing.CAST_DISTANCE
	for _, spot in CollectionService:GetTagged(SPOT_TAG) do
		if spot:IsA("BasePart") then
			local distance = (spot.Position - root.Position).Magnitude
			if distance <= bestDistance then
				best, bestDistance = spot, distance
			end
		end
	end
	if best then
		startCast(player, best)
	end
end

function FishService.Init()
	-- A3 (v6.2.3): the spots are found in ANY workspace "Fishing" folder, not just the first one. The Studio map had an empty
	-- "Fishing" folder first (and two folders of river sound emitters), so no spot ever got its Location, its FishingSpot tag,
	-- its prompt, or the tutorial's arrow. With no spot anywhere, the placeholder water and spots are built.
	local spots = 0
	for _, folder in Workspace:GetChildren() do
		if folder.Name == "Fishing" then
			for _, child in folder:GetDescendants() do
				if child:IsA("BasePart") and typeof(child:GetAttribute("Location")) == "string" then
					setupSpot(child)
					spots += 1
				end
			end
		end
	end
	if spots == 0 then
		warn("[FishService] no fishing spot in workspace.Fishing: building the placeholder dock")
		local folder = buildPlaceholderWater()
		folder.Parent = Workspace
		for _, child in folder:GetDescendants() do
			if child:IsA("BasePart") and typeof(child:GetAttribute("Location")) == "string" then
				setupSpot(child)
			end
		end
	end

	PlotService.Released:Connect(function(player: Player)
		sessions[player] = nil
	end)
end

function FishService.Start()
	Net.On("FishReel", onReel, { rate = 2, burst = 3 })
	Net.On("FishCancel", onCancel, { rate = 2, burst = 3 })
	Net.On("FishCast", onCastNearest, { rate = 2, burst = 3 })
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

-- Re-sends pond cap/timer after a pond upgrade.
local function ownedPonds(player: Player): { BasePart }
	local ponds = {}
	for _, pond in CollectionService:GetTagged(POND_TAG) do
		if pond:IsA("BasePart") and pond:GetAttribute("Owner") == player.UserId then
			table.insert(ponds, pond)
		end
	end
	return ponds
end

-- Re-sends cap/timer of all the player's ponds (after a tier upgrade or the offline pass).
function FishService.RefreshPond(player: Player)
	for _, pond in ownedPonds(player) do
		syncPond(player, pond)
	end
end

-- Studio testing only (called by DevService): every pond of the player is full.
function FishService.DevFillPond(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for _, entry in data.pond.list do
		entry.lastCollect -= Fishing.POND.INTERVAL * 50
	end
	FishService.RefreshPond(player)
end

return FishService
