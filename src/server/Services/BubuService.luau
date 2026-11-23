--!strict
-- Bubu (GDD 6.6, R2.1): place a trap in the river, come back after 6 hours, collect the catch. Progress is wall-clock (no
-- instant finish, offline collect: the record stays in the save). Placing reports "bubu_place" (quest M8 step 1).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bubu = require(ReplicatedStorage.Shared.Config.Bubu)
local Fish = require(ReplicatedStorage.Shared.Config.Fish)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local QuestService = require(script.Parent.QuestService)

local BubuService = {}

local SPOT_TAG = "FishingSpot"
local RIVER = { sungai_lahan = true, sungai = true }

-- The river spot the player stands next to, or nil.
local function riverSpotNear(player: Player): (BasePart?, string?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil, nil
	end
	for _, spot in CollectionService:GetTagged(SPOT_TAG) do
		local location = spot:GetAttribute("Location")
		if spot:IsA("BasePart") and typeof(location) == "string" and RIVER[location] and (spot.Position - root.Position).Magnitude <= Bubu.PLACE_DISTANCE then
			return spot, location
		end
	end
	return nil, nil
end

-- Fish that a bubu of this type catches: the Sungai Lahan fish of the type's rarities.
local function pool(rarities: { string }): { string }
	local ids = {}
	for _, fish in Fish.list do
		if table.find(rarities, fish.rarity) and table.find(fish.locations, "sungai_lahan") then
			table.insert(ids, fish.id)
		end
	end
	return ids
end

function BubuService.Place(player: Player, kind: any): string
	local data = DataService.Get(player)
	local def = if typeof(kind) == "string" then Bubu.TYPES[kind] else nil
	if not data or not def then
		return "jenis tidak dikenal"
	end
	if #data.bubu.list >= Bubu.MAX then
		return "maks 3 bubu"
	end
	if (data.inventory[def.item] or 0) < 1 then
		return "tidak punya bubu"
	end
	local spot, location = riverSpotNear(player)
	if not spot or not location then
		return "pasang di sungai dekat titik mancing"
	end
	InventoryService.Remove(player, def.item, 1)
	local uid = data.bubu.nextUid
	data.bubu.nextUid += 1
	table.insert(data.bubu.list, { uid = uid, kind = kind, spot = location, placedAt = os.time() })
	InventoryService.Sync(player)
	QuestService.Report(player, "bubu_place", 1) -- M8 step 1
	return "terpasang"
end

-- Collect a ready bubu. Not ready = nothing happens (no instant finish).
function BubuService.Collect(player: Player, uid: any): string
	local data = DataService.Get(player)
	if not data or typeof(uid) ~= "number" then
		return "tidak ada"
	end
	for index, entry in data.bubu.list do
		if entry.uid == uid then
			local def = Bubu.TYPES[entry.kind]
			if os.time() < entry.placedAt + Bubu.HOURS * 3600 then
				return "belum siap"
			end
			local ids = pool(def.fishRarities)
			local count = math.random(def.countMin, def.countMax)
			for _ = 1, count do
				if #ids > 0 then
					local fishId = ids[math.random(1, #ids)]
					InventoryService.Add(player, `{fishId}@S`, 1)
				end
			end
			table.remove(data.bubu.list, index)
			InventoryService.Sync(player)
			return `diambil {count}`
		end
	end
	return "tidak ada"
end

-- DEV (K-64): "!tumbuh" also makes ready bubu ready (the wall clock is moved back), so a test does not wait 6 hours.
function BubuService.DevFinishAll(player: Player)
	local data = DataService.Get(player)
	if data then
		for _, entry in data.bubu.list do
			entry.placedAt = os.time() - Bubu.HOURS * 3600
		end
	end
end

function BubuService.Start()
	Net.On("BubuPlace", function(player: Player, kind: any)
		local result = BubuService.Place(player, kind)
		Net.Fire("Notify", player, "bubu.result", { text = result })
	end, { rate = 2, burst = 4 })
	Net.On("BubuCollect", function(player: Player, uid: any)
		local result = BubuService.Collect(player, uid)
		Net.Fire("Notify", player, "bubu.result", { text = result })
	end, { rate = 2, burst = 4 })
end

return BubuService
