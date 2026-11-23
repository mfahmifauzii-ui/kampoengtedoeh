--!strict
-- Fishing: cast (ProximityPrompt) -> bite after a server-rolled delay -> client reel
-- mini-game -> catch. The fish is rolled by the SERVER at cast time; the client's reel
-- score only picks the size tier. A catch can never fail.
-- Player ponds (kolam) hold a STOCK of fish that the player deposits (PondDeposit). Fishing at a pond takes a random
-- fish from the stock (same mini-game); no fish is ever created by time (B-3, 2026-11-22). The stock is part of PlayerData.
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
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Buffs = require(ReplicatedStorage.Shared.Config.Buffs)
local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Ranch = require(ReplicatedStorage.Shared.Config.Ranch)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Map = require(ReplicatedStorage.Shared.Config.Map)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local FeatureGate = require(script.Parent.FeatureGate)
local InventoryService = require(script.Parent.InventoryService)
local NpcService = require(script.Parent.NpcService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local BookService = require(script.Parent.BookService)
local QuestService = require(script.Parent.QuestService)
local AnalyticsHooks = require(script.Parent.AnalyticsHooks)
local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local Types = require(ReplicatedStorage.Shared.Types)
local FishingTutorial = require(ReplicatedStorage.Shared.Modules.FishingTutorial)

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
	usedBait: Fishing.Bait?,
	pondItem: string?, -- kolam: the stock item taken at cast ("nila@M"); back to the stock if the fish is not caught
	pondUid: number?,
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
	-- Belut Emas (K-07): hanya saat Hujan Deres atau Petir, tidak saat Gerimis.
	if fish.rainKinds then
		local weather = Workspace:GetAttribute("Weather")
		if not table.find(fish.rainKinds, weather) then
			return false
		end
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
-- then pick a fish inside that tier by its own weight. Buka Lv (Bab 6.4): only fish at or below the player's level.
-- bait = umpan yang kepakai: Pelet +15% Mid (U), Udang Kecil +10% Late (R) — Bab 6.3.
local function rollFish(location: string, level: number, rareBonus: number, legendaryBonus: number, bait: Fishing.Bait?, allowed: { [Rarity]: boolean }?): string?
	local phase, raining = getConditions()

	local byTier: { [Rarity]: { { fish: Fish, weight: number } } } = {}
	for _, fish in FishConfig.list do
		if fish.unlockLevel <= level and table.find(fish.locations, location) and isAvailable(fish, phase, raining) and (not allowed or allowed[fish.rarity]) then
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
			if bait then
				if rarity == "U" and bait.midMult then
					weight *= bait.midMult
				elseif rarity == "R" and bait.lateMult then
					weight *= bait.lateMult
				end
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

-- K-06 (b): tangkapan Legenda berikutnya = ukuran yang belum ada di Album Sungai (4 tangkapan = lengkap).
-- Nil bila semua ukuran sudah ada (pakai ukuran biasa).
local function unownedLegendSize(player: Player, fishId: string): string?
	local data = DataService.Get(player)
	local recorded = if data then (data.book :: any).sungai else nil
	for _, entry in FishConfig.SIZES do
		if recorded == nil or recorded[`{fishId}@{entry.id}`] == nil then
			return entry.id
		end
	end
	return nil
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

-- Visual bersama (B-5, 2026-11-22): joran (Motor6D ke tangan kanan), pelampung, tali (Beam), riak saat gigitan. Satu Model per
-- pemain di Workspace.FishingVisuals. Dibuat saat lemparan, dihancurkan di semua jalur akhir (endSession, mati, keluar, lepas
-- dari plot) dan saat pemain menjauh dari spot. Pancing tutorial Kak Fajar (salinan lokal di klien) tidak membuat visual.
type Visuals = { model: Model, bobber: BasePart, tip: BasePart, tracks: { [string]: AnimationTrack } }
local visuals: { [Player]: Visuals } = {}
local VISUALS_FOLDER = "FishingVisuals"
local TIP_FALLBACK = 2 -- studs dari pegangan ke ujung joran bila template tak punya bagian "Tip" (cek geometri di Studio)
local CATCH_SECONDS = 1.3 -- lama animasi tangkap sebelum visual hilang (sama dengan klien)

local function visualsFolder(): Folder
	local folder = Workspace:FindFirstChild(VISUALS_FOLDER)
	if not (folder and folder:IsA("Folder")) then
		folder = Instance.new("Folder")
		folder.Name = VISUALS_FOLDER
		folder.Parent = Workspace
	end
	return folder :: Folder
end

local function destroyVisuals(player: Player)
	local record = visuals[player]
	if not record then
		return
	end
	visuals[player] = nil
	for _, track in record.tracks do
		track:Stop(0.1)
	end
	record.model:Destroy()
end

-- Animasi (Roadmap §12.4): ID Animation permanen dari Config/Fishing.ANIMS. Kosong = tidak diputar, pose joran statis.
local function playAnim(player: Player, name: string)
	local record = visuals[player]
	local id = Fishing.ANIMS[name]
	if not record or not id or id == "" then
		return
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not animator then
		return
	end
	local track = record.tracks[name]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		track = animator:LoadAnimation(animation)
		record.tracks[name] = track
	end
	for otherName, other in record.tracks do
		if otherName ~= name then
			other:Stop(0.15)
		end
	end
	track:Play(0.15)
end

-- Joran: salinan Workspace.FishingRod (template klien, bagian "Grip") dilas ke tangan kanan lewat Motor6D. Tanpa template: batang biasa.
-- Mengembalikan bagian ujung joran (tali diikat di sana).
local function buildRod(model: Model, character: Model): BasePart?
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not (hand and hand:IsA("BasePart")) then
		return nil
	end
	local template = Workspace:FindFirstChild("FishingRod")
	local rod: Instance
	if template then
		rod = template:Clone()
	else
		local stick = Instance.new("Part")
		stick.Name = "Grip"
		stick.Size = Vector3.new(0.3, 0.3, 4)
		rod = stick
	end
	local grip = rod:FindFirstChild("Grip", true) or rod
	if not grip:IsA("BasePart") then
		rod:Destroy()
		return nil
	end
	local gripPart = grip :: BasePart
	rod.Parent = model

	local parts: { Instance } = rod:GetDescendants()
	table.insert(parts, rod)
	for _, part in parts do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
			if part ~= gripPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = gripPart
				weld.Part1 = part
				weld.Parent = gripPart
			end
		end
	end

	local motor = Instance.new("Motor6D")
	motor.Name = "RodGrip"
	motor.Part0 = hand
	motor.Part1 = gripPart
	motor.C0 = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(-90), 0, 0) -- sama dengan RodAnimController
	motor.C1 = CFrame.new()
	motor.Parent = model
	gripPart.CFrame = hand.CFrame * motor.C0

	local tip = rod:FindFirstChild("Tip", true)
	if tip and tip:IsA("BasePart") then
		return tip
	end
	local fallback = Instance.new("Part")
	fallback.Name = "Tip"
	fallback.Size = Vector3.new(0.2, 0.2, 0.2)
	fallback.Transparency = 1
	fallback.Massless = true
	fallback.CanCollide = false
	fallback.CanQuery = false
	fallback.CanTouch = false
	fallback.CFrame = gripPart.CFrame * CFrame.new(0, 0, -TIP_FALLBACK)
	fallback.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = gripPart
	weld.Part1 = fallback
	weld.Parent = gripPart
	return fallback
end

-- Riak di permukaan saat gigitan (B-5): cincin yang melebar lalu hilang.
local function splash(position: Vector3, parent: Instance)
	local ring = Instance.new("Part")
	ring.Name = "Splash"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = Color3.fromRGB(230, 245, 255)
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.1, 1, 1)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = parent
	TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, 6, 6),
		Transparency = 1,
	}):Play()
	task.delay(1, function()
		ring:Destroy()
	end)
end

local function startVisuals(player: Player, spot: BasePart)
	destroyVisuals(player)
	local character = player.Character
	if not character then
		return
	end
	local model = Instance.new("Model")
	model.Name = `Fishing_{player.UserId}`
	local tip = buildRod(model, character)
	if not tip then
		model:Destroy()
		return
	end
	-- Pelampung: sama dengan placeBobber di klien (di atas dermaga / permukaan spot).
	local bobber = Instance.new("Part")
	bobber.Name = "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.one * 0.8
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.CanTouch = false
	bobber.Color = Color3.fromRGB(196, 92, 72)
	bobber.Position = spot.Position + Vector3.new(0, spot.Size.Y / 2 + 0.3, 0)
	bobber.Parent = model
	-- Tali: Beam dari ujung joran ke pelampung.
	local tipAttachment = Instance.new("Attachment")
	tipAttachment.Parent = tip
	local bobberAttachment = Instance.new("Attachment")
	bobberAttachment.Parent = bobber
	local line = Instance.new("Beam")
	line.Attachment0 = tipAttachment
	line.Attachment1 = bobberAttachment
	line.Width0 = 0.06
	line.Width1 = 0.06
	line.Color = ColorSequence.new(Color3.fromRGB(240, 240, 235))
	line.FaceCamera = true
	line.Parent = model

	model:SetAttribute("Owner", player.UserId)
	model.Parent = visualsFolder()
	visuals[player] = { model = model, bobber = bobber, tip = tip, tracks = {} }
end

-- Pemain yang menjauh dari spot (lebih dari LEAVE_DISTANCE) = batal: umpan kembali, visual hilang lewat endSession.
local function watchSession(player: Player, session: Session)
	task.spawn(function()
		while sessions[player] == session do
			task.wait(0.5)
			if sessions[player] == session and not isNear(player, session.spot, Fishing.LEAVE_DISTANCE) then
				FishService.Cancel(player)
			end
		end
	end)
end

-- Atribut "Fishing" (B-5, 2026-11-22) = state server: Casting (lemparan) -> Waiting (menunggu) -> Bite (gigitan) -> Reeling
-- (tarikan diterima) -> nil. Klien tetap memakai FishingActive untuk UI; atribut ini untuk pemain lain (visual, animasi).
local CAST_SECONDS = 1.2 -- sama dengan lama animasi lempar di klien (RodAnimController)

local function endSession(player: Player, catchSeconds: number?)
	sessions[player] = nil
	Net.Fire("FishState", player, "idle")
	local record = visuals[player]
	if catchSeconds and record then
		-- Tangkap: visual tinggal sebentar untuk animasi tangkap, lalu hilang. Lemparan baru punya visual sendiri (cek record).
		player:SetAttribute("Fishing", "Reeling")
		task.delay(catchSeconds, function()
			if visuals[player] == record and sessions[player] == nil then
				player:SetAttribute("Fishing", nil)
				destroyVisuals(player)
			end
		end)
		return
	end
	player:SetAttribute("Fishing", nil)
	destroyVisuals(player)
end

local function beginCast(player: Player, session: Session, data: Types.PlayerData)
	player:SetAttribute("Fishing", "Casting")
	-- Pancing tutorial Kak Fajar (T1b, langkah mancing) = salinan lokal di klien: server tidak membuat visual (B-5).
	if not FishingTutorial.isActive(data.guide) then
		startVisuals(player, session.spot)
		playAnim(player, "FishingCast")
	end
	watchSession(player, session)
	task.delay(CAST_SECONDS, function()
		if sessions[player] == session then
			player:SetAttribute("Fishing", "Waiting")
			playAnim(player, "FishingIdle")
		end
	end)
end

-- D-38 (Joran Kuat dipindah ke server): kotak tarik dihitung di server. Kotak menentukan skor reel dan jadi ukuran ikan,
-- jadi server yang memutuskan dan mengirimnya bersama gigitan. Rumus: lebar joran (rod.box / 100; default ZONE_WIDTH_DEFAULT
-- bila joran tak dikenal), +10 % saat buff Pancing (Dapur.BUFF_PANCING_BOX), +2 % per level Joran Kuat.
local function zoneWidthFor(data: Types.PlayerData): number
	local rod = Fishing.rods[data.fishing.rod]
	local width = if rod and typeof(rod.box) == "number" then rod.box / 100 else Fishing.ZONE_WIDTH_DEFAULT
	if Buffs.active(data.buff, "pancing", os.time()) then
		width *= Dapur.BUFF_PANCING_BOX
	end
	return width * (1 + 0.02 * (data.skill.joran_kuat or 0))
end

-- B-1: waktu tunggu gigitan. Base: dengan umpan 3-6 dtk, tanpa umpan 6-12 dtk (Fishing.BITE_*). Lalu rod.biteMult (tabel joran),
-- umpan (biteReduction), dan buff Pancing (Dapur.BUFF_PANCING_BITE). Hujan TIDAK mengubah waktu tunggu (K-01, GDD 3.3).
local function biteDelayFor(rod: Fishing.Rod, usedBait: Fishing.Bait?, data: Types.PlayerData): number
	local low, high = Fishing.BITE_MIN, Fishing.BITE_MAX
	if not usedBait then
		low, high = Fishing.BITE_NO_BAIT_MIN, Fishing.BITE_NO_BAIT_MAX
	end
	local delay = random:NextNumber(low, high) * rod.biteMult
	if usedBait then
		delay *= 1 - usedBait.biteReduction
	end
	if Buffs.active(data.buff, "pancing", os.time()) then
		delay *= Dapur.BUFF_PANCING_BITE
	end
	return delay
end

-- Riak + animasi reel saat gigitan (visual hanya ada bila bukan pancing tutorial).
local function scheduleBite(player: Player, session: Session, biteDelay: number)
	local data = DataService.Get(player)
	local zoneWidth = if data then zoneWidthFor(data) else Fishing.ZONE_WIDTH_DEFAULT
	task.delay(biteDelay, function()
		if sessions[player] == session then
			player:SetAttribute("Fishing", "Bite")
			local record = visuals[player]
			if record then
				splash(record.bobber.Position, record.model)
				playAnim(player, "FishingReel")
			end
			Net.Fire("FishState", player, "bite", zoneWidth) -- the server's catch box width (D-38)
		end
	end)
end

-- Pond (kolam) helpers: stock, capacity, the part of a pond. Defined before casting, which uses them.

-- Kapasitas simpan kolam = tier persis (P2-2-fix, Bab 7.2 LOCKED): Tanah 10 / Semen 20 / Keramik 30.
local function pondCap(_data: Types.PlayerData, entry: Types.PondEntry): number
	local tierDef = Ranch.byTier[entry.tier or "tanah"] or Ranch.byTier.tanah
	return tierDef.cap
end

-- Each pond part carries Attribute "PondUid" = its PondEntry.uid in data.pond.list.
local function findEntry(data: Types.PlayerData, uid: any): Types.PondEntry?
	for _, entry in data.pond.list do
		if entry.uid == uid then
			if typeof(entry.stock) ~= "table" then
				entry.stock = {} -- save tanpa stok (dibuat sebelum B-3): kosong, tanpa migrasi lain
			end
			return entry
		end
	end
	return nil
end

-- The pond part of this player with that uid (tag Pond, Owner = player).
local function pondPart(player: Player, uid: number): BasePart?
	for _, pond in CollectionService:GetTagged(POND_TAG) do
		if pond:IsA("BasePart") and pond:GetAttribute("Owner") == player.UserId and pond:GetAttribute("PondUid") == uid then
			return pond
		end
	end
	return nil
end

local function syncPond(player: Player, pond: BasePart)
	local data = DataService.Get(player)
	local entry = data and findEntry(data, pond:GetAttribute("PondUid"))
	if data and entry then
		pond:SetAttribute("Cap", pondCap(data, entry))
		pond:SetAttribute("Stock", #entry.stock)
	end
end

-- Puts a fish that was taken from the stock back (escape, cancel, no room in the bag).
local function returnToPond(player: Player, session: Session)
	if not session.pondItem or not session.pondUid then
		return
	end
	local data = DataService.Get(player)
	local entry = data and findEntry(data, session.pondUid)
	if entry then
		table.insert(entry.stock, session.pondItem)
		local pond = pondPart(player, session.pondUid)
		if pond then
			syncPond(player, pond)
		end
	end
	session.pondItem = nil
end

-- Kolam: the fish comes from the stock (random), not from the global table. Empty = toast, no mini-game.
local function startPondCast(player: Player, spot: BasePart, data: Types.PlayerData, rod: Fishing.Rod)
	local uid = spot:GetAttribute("PondUid")
	local entry = if typeof(uid) == "number" then findEntry(data, uid) else nil
	if not entry then
		return
	end
	if #entry.stock == 0 then
		Net.Fire("Notify", player, "pond.empty")
		return
	end
	local index = random:NextInteger(1, #entry.stock)
	local item = table.remove(entry.stock, index) :: string
	local pond = pondPart(player, entry.uid)
	if pond then
		syncPond(player, pond)
	end
	local fishId = item:match("^(.+)@.+$") or item

	-- Kolam: tidak memakai umpan, jadi waktu tunggu tanpa umpan (lihat biteDelayFor).
	local biteDelay = biteDelayFor(rod, nil, data)
	local session: Session = {
		spot = spot,
		fishId = fishId,
		biteAt = os.clock() + biteDelay,
		usedBait = nil,
		pondItem = item,
		pondUid = entry.uid,
	}
	sessions[player] = session
	beginCast(player, session, data)
	Net.Fire("FishState", player, "waiting", spot)
	scheduleBite(player, session, biteDelay)
end

-- Q-2 feature gate untuk spot: kolam (pond), kanal barat (Location sungai), empang.
local SPOT_FEATURE: { [string]: string } = { kolam = "kolam", sungai = "kanal_barat", empang = "empang" }
local function spotOpen(player: Player, spot: BasePart): boolean
	local loc = spot:GetAttribute("Location")
	local feature = if typeof(loc) == "string" then SPOT_FEATURE[loc] else nil
	return feature == nil or FeatureGate.Check(player, feature)
end

local function startCast(player: Player, spot: BasePart)
	if not spotOpen(player, spot) then return end
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

	local rod = Fishing.rods[data.fishing.rod]
	if not rod then
		return -- cannot happen after the rod check above; kept so the type stays exact
	end
	if location == "kolam" then
		startPondCast(player, spot, data, rod)
		return
	end
	-- Umpan (Bab 6.3): yang pertama dipunyai dari urutan BAITS. Jangkrik = gigitan 30% lebih cepat.
	local usedBait: Fishing.Bait? = nil
	local activeBait = InventoryService.ActiveBait(data)
	if activeBait and InventoryService.Remove(player, activeBait.id, 1) then
		usedBait = activeBait
	end
	if usedBait and (data.inventory[usedBait.id] or 0) == 0 then
		-- C1 (K-55): the equipped bait ran out: the next bait the player has takes over, with a toast.
		local nextBait = InventoryService.ActiveBait(data)
		if nextBait then
			Net.Fire("Notify", player, "fish.bait_switched", { item = `item.{nextBait.id}` })
		end
	end
	-- Pity Legenda (Bab 6.5, LOCKED, P2-4): counter per player per jenis Legenda, naik hanya saat
	-- lemparan di kondisi yang cocok. Lemparan ke-200 dijamin (dikurangi skill Firasat, min 150).
	-- Counter reset setelah dapat.
	data.fishing.pity = data.fishing.pity or {}
	local firasat = data.skill.firasat or 0
	local pityAt = math.max(150, 200 - 10 * firasat)
	local forcedId: string? = nil
	local forcedCount = -1
	local bestRatio = 0
	do
		local phase, raining = getConditions()
		for _, fish in FishConfig.list do
			if fish.rarity == "L"
				and data.level >= fish.unlockLevel
				and table.find(fish.locations, location)
				and isAvailable(fish, phase, raining)
			then
				local n = (data.fishing.pity[fish.id] or 0) + 1
				data.fishing.pity[fish.id] = n
				bestRatio = math.max(bestRatio, n / pityAt)
				if n >= pityAt and n > forcedCount then
					forcedId, forcedCount = fish.id, n
				end
			end
		end
	end
	-- Firasat (Bab 6.5, P2-4-fix): pity >= 75% + dekat Kak Fajar (<= NPC_DISTANCE, USULAN:
	-- v7.3 cuma bilang "kalau dekat") -> bubble Kak Fajar + gelembung emas di pelampung.
	-- Tanpa angka pity di UI.
	if bestRatio >= 0.75 then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local kakekPos = NpcService.Position("kak_fajar")
		if root and root:IsA("BasePart") and kakekPos and (root.Position - kakekPos).Magnitude <= Shop.NPC_DISTANCE then
			Net.Fire("Notify", player, "fish.firasat")
			Net.Fire("FishFirasat", player)
		end
	end
	local fishId = forcedId or rollFish(location, data.level, rod.rareBonus, rod.legendaryBonus, usedBait, nil)
	if not fishId then
		Net.Fire("Notify", player, "fish.none_here")
		return
	end

	local biteDelay = biteDelayFor(rod, usedBait, data)
	local session: Session = { spot = spot, fishId = fishId, biteAt = os.clock() + biteDelay, usedBait = usedBait }
	sessions[player] = session
	beginCast(player, session, data)
	Net.Fire("FishState", player, "waiting", spot)
	scheduleBite(player, session, biteDelay)
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
	player:SetAttribute("Fishing", "Reeling")

	-- LEPAS (Bab 6.2, P2-4-fix): skor 0 = tidak pernah menahan ikan di kotak = ikan lepas, umpan
	-- hilang, tanpa hukuman lain. Skor > 0 sekecil apa pun tetap dapat (menjaga "tanpa fail").
	-- Skill Umpan Hemat (Bab 4.5): 5%/lv umpan kembali saat lepas.
	if score <= 0 then
		local lepasData = DataService.Get(player)
		if lepasData and session.usedBait and random:NextNumber() < 0.05 * (lepasData.skill.umpan_hemat or 0) then
			InventoryService.Add(player, session.usedBait.id, 1)
			Net.Fire("Notify", player, "fish.bait_back")
		else
			Net.Fire("Notify", player, "fish.lepas")
		end
		returnToPond(player, session) -- kolam: ikan lepas kembali ke stok
		endSession(player)
		return
	end

	-- Skill Ikan Besar (Bab 4.5, P2-4): skor +2%/lv (peluang Besar/Jumbo naik, nilai harapan).
	-- Kolam: ukuran ikan = ukuran yang sudah ada di stok (tidak diacak ulang).
	local reelData = DataService.Get(player)
	local ikanBesar = reelData and reelData.skill.ikan_besar or 0
	local legendSize = if FishConfig.byId[session.fishId] and FishConfig.byId[session.fishId].rarity == "L" then unownedLegendSize(player, session.fishId) else nil
	local size = if session.pondItem then session.pondItem:match("@(.+)$") or "S" else (legendSize or sizeFor(math.clamp(score + 0.02 * ikanBesar, 0, 1)))
	local item = FishService.ItemId(session.fishId, size)
	sessions[player] = nil
	local caught = InventoryService.Add(player, item, 1)
	if caught then
		playAnim(player, "FishingCatch")
		Net.Fire("Notify", player, "fish.caught", { item = `fish.{session.fishId}`, size = `size.{size}` })
		local caughtData = DataService.Get(player)
		if caughtData then
			caughtData.guide.fishCaught = true -- the t1b "after_catch" step only passes after a real catch
		end
		local fish = FishConfig.byId[session.fishId]
		if fish.rarity == "L" and caughtData then
			-- Pity reset (Bab 6.5): counter spesies ini kembali 0 setelah dapat.
			caughtData.fishing.pity = caughtData.fishing.pity or {}
			caughtData.fishing.pity[fish.id] = 0
		end
		ProgressionService.AddXp(player, fish.xp or 0, `catch:{fish.id}`)
		BookService.RecordFish(player, fish.id, size)
		AnalyticsHooks.Step(player, "first_catch")
		QuestService.Report(player, "catch")
		if fish.rarity == "L" then
			QuestService.Report(player, "catch_legenda") -- MQ11 Legenda Pertama (Bab 14.2)
		end
		if size == "Jumbo" then
			QuestService.Report(player, "catch_jumbo") -- Side Ikan Jumbo (Bab 14.4)
		end
		-- Quest S5 (kanal barat, ikan Mid = rarity U) dan S9 (Empang). Lokasi spot = Config/Fishing "sungai" / "empang".
		local spotLocation = session.spot:GetAttribute("Location")
		if spotLocation == "sungai" and fish.rarity == "U" then
			QuestService.Report(player, "catch_mid_kanal")
		end
		if spotLocation == "empang" then
			QuestService.Report(player, "catch_empang")
		end
		if session.spot:GetAttribute("Location") == "kolam" then
			QuestService.Report(player, "catch_pond")
		end
	elseif session.pondItem and session.pondUid then
		-- Tas tidak bisa menerima (item tidak valid): ikan tetap di kolam.
		returnToPond(player, session)
		Net.Fire("Notify", player, "pond.bag_full")
	end
	endSession(player, if caught then CATCH_SECONDS else nil)
end

local function onCancel(player: Player)
	local session = sessions[player]
	if session then
		-- Batal/teleport/jalan menjauh = umpan SELALU kembali (Bab 6.1: ketarik otomatis,
		-- umpan tidak hilang). Umpan Hemat hanya untuk LEPAS, bukan cancel (P2-4-fix).
		if session.usedBait then
			InventoryService.Add(player, session.usedBait.id, 1)
			Net.Fire("Notify", player, "fish.bait_back")
		end
		returnToPond(player, session) -- kolam: ikan kembali ke stok
		endSession(player)
	end
end
FishService.Cancel = onCancel -- used by SocialService when teleporting

-- Pond (kolam) -------------------------------------------------------------------

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
	-- Dermaga (sungai / empang): no proximity prompt. The round Mancing button (client AksiButton) casts from them.
	-- Kolam keeps its own prompt.
	if location == "sungai" or location == "sungai_lahan" or location == "empang" then
		CollectionService:AddTag(spot, SPOT_TAG)
		return
	end
	local prompt = makePrompt(spot, "FishPrompt", "prompt.fish", 0)
	-- Stage 5 (user, 16 Nov): the fishing prompt of EVERY spot (kolam, dermaga sungai, dermaga empang) shows only within
	-- 4 studs, the same as a bed's proximity. Outside 4 studs there is no button.
	prompt.MaxActivationDistance = 4
	prompt.Triggered:Connect(function(player)
		startCast(player, spot)
	end)
	CollectionService:AddTag(spot, SPOT_TAG)
end

-- PondDeposit(uid, itemId): one fish from the bag into the pond stock. Owner, distance, fish, capacity are checked here.
local function onDeposit(player: Player, uid: any, itemId: any)
	if not FeatureGate.Check(player, "kolam") then return end
	if typeof(uid) ~= "number" or typeof(itemId) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	local entry = if data then findEntry(data, uid) else nil
	local pond = pondPart(player, uid :: number)
	if not data or not entry or not pond then
		return
	end
	if not isNear(player, pond, Fishing.CAST_DISTANCE) then
		Net.Fire("Notify", player, "pond.far")
		return
	end
	local fishId = itemId:match("^(.+)@.+$")
	if not fishId or not FishConfig.byId[fishId] then
		Net.Fire("Notify", player, "pond.not_fish")
		return
	end
	if InventoryService.Count(player, itemId) < 1 then
		return
	end
	if #entry.stock >= pondCap(data, entry) then
		Net.Fire("Notify", player, "pond.full")
		return
	end
	InventoryService.Remove(player, itemId, 1)
	table.insert(entry.stock, itemId)
	syncPond(player, pond)
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.deposited", { item = `fish.{fishId}` })
	QuestService.Report(player, "pond_deposit", 1) -- per ikan yang disetor
end

-- PondWithdraw(uid, index): one fish from the stock back into the bag.
local function onWithdraw(player: Player, uid: any, index: any)
	if not FeatureGate.Check(player, "kolam") then return end
	if typeof(uid) ~= "number" or typeof(index) ~= "number" then
		return
	end
	local data = DataService.Get(player)
	local entry = if data then findEntry(data, uid) else nil
	local pond = pondPart(player, uid :: number)
	if not data or not entry or not pond then
		return
	end
	if not isNear(player, pond, Fishing.CAST_DISTANCE) then
		Net.Fire("Notify", player, "pond.far")
		return
	end
	local at = math.floor(index)
	local item = entry.stock[at]
	if not item then
		return
	end
	if not InventoryService.CanAdd(player, item, 1) then
		Net.Fire("Notify", player, "pond.bag_full")
		return
	end
	table.remove(entry.stock, at)
	InventoryService.Add(player, item, 1)
	syncPond(player, pond)
	InventoryService.Sync(player)
	local fishId = item:match("^(.+)@.+$") or item
	Net.Fire("Notify", player, "pond.withdrew", { item = `fish.{fishId}` })
end

-- Turns an (invisible) part over a player-built pond into the fishing spot + its two prompts:
-- "Mancing" (the usual cast, FishPrompt) and "Kolam" (opens the pond sheet on the client, PondOpen).
-- Called by the pond builder once the water terrain exists; there is no fixed pond anymore.
function FishService.SetupPond(player: Player, pond: BasePart, entry: Types.PondEntry)
	pond:SetAttribute("Location", "kolam")
	pond:SetAttribute("Owner", player.UserId)
	pond:SetAttribute("PondUid", entry.uid)

	setupSpot(pond)
	-- Two prompts on one part: different keys + AlwaysShow, otherwise Roblox shows only one.
	local kolam = makePrompt(pond, "KolamPrompt", "prompt.pond_open", 1)
	kolam.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	local fishPrompt = pond:FindFirstChild("FishPrompt") :: ProximityPrompt
	fishPrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	-- Q-2: client hides both pond prompts while the kolam feature is closed (FeatureClient)
	kolam:SetAttribute("Feature", "kolam")
	fishPrompt:SetAttribute("Feature", "kolam")
	local uid = entry.uid
	kolam.Triggered:Connect(function(triggeredBy)
		if pond:GetAttribute("Owner") == triggeredBy.UserId then
			Net.Fire("PondOpen", triggeredBy, uid)
		end
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

-- River spots (2026-11-22): 8 fishing spots on every axis river between the player lands, 4 per bank, facing each other
-- across the water. Only the invisible spot part: no planks, no posts. The player sees the spot as the fish-mark ripple on
-- the water (client FishSpotFx, which reads Dir). Built here, not in MapService, so they exist with a hand-built
-- Workspace.Map too. Runs once (attribute "RiverSpots" on the folder marks it done), before the spot scan below.
local RIVER_AXES = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
local RIVER_SPOT_REACH = 3 -- studs from the bank's edge to the spot's centre, out over the water

local function buildRiverSpots(fishing: Folder)
	if fishing:GetAttribute("RiverSpots") == true then
		return
	end
	fishing:SetAttribute("RiverSpots", true)
	local index = 0
	for _, axis in RIVER_AXES do
		local across = Vector3.new(-axis.Z, 0, axis.X) -- across the river (unit)
		for _, along in Map.RIVER_SPOTS.ALONG do
			for _, side in { 1, -1 } do
				-- origin = the bank's edge; dir = out over the water, toward the opposite bank (the two rows face each other).
				local origin = axis * along + across * side * Map.RIVER_SPOTS.BANK
				local dir = -across * side
				local spot = Instance.new("Part")
				index += 1
				spot.Name = `Spot_sungai_lahan_{index}` -- unik: tiap pemain diberi satu spot (FishService.AssignedRiverSpot)
				spot.Anchored = true
				spot.Size = Vector3.new(2, 1, 2)
				spot.CFrame = CFrame.new(origin + dir * RIVER_SPOT_REACH + Vector3.new(0, 1, 0))
				spot.Transparency = 1
				spot.CanCollide = false
				spot.CanQuery = false
				spot.CanTouch = false
				spot:SetAttribute("Location", "sungai_lahan")
				spot:SetAttribute("Dir", dir)
				spot.Parent = fishing
			end
		end
	end
end

-- Sungai lahan (Update owner 2026-11-22, Task 1): spot milik pemain = spot sungai lahan TERDEKAT dari lahannya.
-- Dihitung di server dari posisi plot (deterministik), bukan dari posisi klien. Nil bila belum ada plot atau spot.
function FishService.AssignedRiverSpot(player: Player): BasePart?
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	local fishing = Workspace:FindFirstChild("Fishing")
	if not origin or not (fishing and fishing:IsA("Folder")) then
		return nil
	end
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, part in fishing:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("Location") == "sungai_lahan" then
			local distance = (part.Position - origin.Position).Magnitude
			if distance < bestDistance or (distance == bestDistance and best ~= nil and part.Name < best.Name) then
				best, bestDistance = part, distance
			end
		end
	end
	return best
end

function FishService.Init()
	-- A3 (v6.2.3): the spots are found in ANY workspace "Fishing" folder, not just the first one. The Studio map had an empty
	-- "Fishing" folder first (and two folders of river sound emitters), so no spot ever got its Location, its FishingSpot tag,
	-- its prompt, or the tutorial's arrow. With no spot anywhere, the placeholder water and spots are built.
	local fishing = Workspace:FindFirstChild("Fishing")
	if not (fishing and fishing:IsA("Folder")) then
		fishing = Instance.new("Folder")
		fishing.Name = "Fishing"
		fishing.Parent = Workspace
	end
	buildRiverSpots(fishing :: Folder)

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
		local session = sessions[player]
		if session then
			returnToPond(player, session)
		end
		sessions[player] = nil
		player:SetAttribute("Fishing", nil)
		destroyVisuals(player)
	end)
end

function FishService.Start()
	-- Panah tutorial: nama spot sungai lahan milik pemain (Task 1). Diset saat plot diberikan.
	PlotService.Assigned:Connect(function(player: Player)
		local spot = FishService.AssignedRiverSpot(player)
		player:SetAttribute("RiverSpot", if spot then spot.Name else nil)
	end)
	Net.On("FishReel", onReel, { rate = 2, burst = 3 })
	Net.On("FishCancel", onCancel, { rate = 2, burst = 3 })
	Net.On("FishCast", onCastNearest, { rate = 2, burst = 3 })
	Net.On("PondDeposit", onDeposit, { rate = 3, burst = 6 })
	Net.On("PondWithdraw", onWithdraw, { rate = 3, burst = 6 })
	-- Mati / ganti karakter = batal, dan visual hilang. Dipasang juga untuk pemain yang sudah ada.
	local function hookCharacter(player: Player)
		player.CharacterRemoving:Connect(function()
			if sessions[player] then
				onCancel(player)
			end
			destroyVisuals(player)
			player:SetAttribute("Fishing", nil)
		end)
	end
	Players.PlayerAdded:Connect(hookCharacter)
	for _, player in Players:GetPlayers() do
		hookCharacter(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			returnToPond(player, session)
		end
		sessions[player] = nil
		destroyVisuals(player)
	end)
end

-- Re-sends cap/stock of all the player's ponds (after a tier upgrade or a change).
local function ownedPonds(player: Player): { BasePart }
	local ponds = {}
	for _, pond in CollectionService:GetTagged(POND_TAG) do
		if pond:IsA("BasePart") and pond:GetAttribute("Owner") == player.UserId then
			table.insert(ponds, pond)
		end
	end
	return ponds
end

function FishService.RefreshPond(player: Player)
	for _, pond in ownedPonds(player) do
		syncPond(player, pond)
	end
end

-- Studio testing only (called by DevService): every pond of the player is filled to its cap with Early fish.
function FishService.DevFillPond(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for _, entry in data.pond.list do
		local stock = findEntry(data, entry.uid)
		if stock then
			while #stock.stock < pondCap(data, stock) do
				table.insert(stock.stock, FishService.ItemId("wader_cakul", "S"))
			end
		end
	end
	FishService.RefreshPond(player)
end

return FishService
