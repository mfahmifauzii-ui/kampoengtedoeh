--!strict
-- Trading with town NPCs. Every request names an NPC (Config/Npcs) and is distance-checked to it; what an NPC
-- buys and sells comes from its config, prices from Modules/Trade. The client only sends requests.
--   Sell(npcId, itemId | "all")                         NPC buys items from the player
--   ShopBuy(npcId, kind, id, amount?)                   kind: rod | bait | upgrade | seed | seedx | fish | blueprint
--   Haggle(npcId, itemId, pct)                          bargain: the whole stack at base price +pct% (haggle NPCs)
-- Kedekatan: closer NPCs give a discount on everything you buy, every trade builds it (AffinityService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blueprints = require(ReplicatedStorage.Shared.Config.Blueprints)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Trade = require(ReplicatedStorage.Shared.Modules.Trade)
local Types = require(ReplicatedStorage.Shared.Types)
local AffinityService = require(script.Parent.AffinityService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local FarmService = require(script.Parent.FarmService)
local FishService = require(script.Parent.FishService)
local PondService = require(script.Parent.PondService)
local InventoryService = require(script.Parent.InventoryService)
local NpcService = require(script.Parent.NpcService)
local SkillService = require(script.Parent.SkillService)

local RATE = { rate = 4, burst = 8 }
local RATE_HAGGLE = { rate = 3, burst = 6 }

type UpgradeState = {
	get: (data: Types.PlayerData) -> number,
	set: (data: Types.PlayerData, tier: number) -> (),
	after: ((player: Player) -> ())?,
}

local UPGRADE_STATE: { [string]: UpgradeState } = {
	backpack = {
		get = function(data) return data.backpackTier end,
		set = function(data, tier) data.backpackTier = tier end,
	},
	pond = {
		get = function(data) return data.pond.tier end,
		set = function(data, tier) data.pond.tier = tier end,
		after = function(player)
			FishService.RefreshPond(player)
			PondService.RefreshLook(player)
		end,
	},
	farm = {
		get = function(data) return data.farm.expansions end,
		set = function(data, tier) data.farm.expansions = tier end,
		after = function(player) FarmService.Rebuild(player) end,
	},
}

local random = Random.new()

local ShopService = {}

-- Returns the NPC only if the id is real and the player's character is close to it.
local function npcNear(player: Player, npcId: any): Npcs.Npc?
	local npc = if typeof(npcId) == "string" then Npcs.byId[npcId] else nil
	local position = if npc then NpcService.Position(npc.id) else nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if npc and position and root and root:IsA("BasePart") and (root.Position - position).Magnitude <= Shop.NPC_DISTANCE then
		return npc
	end
	Net.Fire("Notify", player, "shop.too_far")
	return nil
end

local function validPack(amount: any): boolean
	return typeof(amount) == "number" and table.find(Shop.PACKS, amount) ~= nil
end

local function notEnough(player: Player)
	Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
end

-- Selling --------------------------------------------------------------------------

local function onSell(player: Player, npcId: any, target: any)
	if typeof(target) ~= "string" then
		return
	end
	local npc = npcNear(player, npcId)
	local data = DataService.Get(player)
	if not npc or not data or next(npc.buys) == nil then
		return
	end

	-- Unit price this NPC pays for an item, nil if it doesn't buy it.
	local function unitPrice(itemId: string): number?
		local info = Items.info(itemId)
		return if info then Trade.buyPrice(npc, info) else nil
	end

	local toSell: { string } = {}
	if target == "all" then
		for itemId in data.inventory do
			if unitPrice(itemId) then
				table.insert(toSell, itemId)
			end
		end
	elseif data.inventory[target] and unitPrice(target) then
		table.insert(toSell, target)
	end

	local total = 0
	for _, itemId in toSell do
		local price = unitPrice(itemId) :: number
		local count = data.inventory[itemId]
		if count and InventoryService.Remove(player, itemId, count) then
			total += price * count
		end
	end

	if total > 0 then
		EconomyService.Add(player, "koin", total, if target == "all" then "sell:all" else `sell:{target}`)
		Net.Fire("Notify", player, "sell.sold", { n = total }) -- (AnalyticsHooks logs first_sell from the Koin gain)
		AffinityService.OnTrade(player, npc.id)
	else
		Net.Fire("Notify", player, "sell.nothing")
	end
end

-- Haggling -------------------------------------------------------------------------

local function offerFor(pct: number): { pct: number, minTier: number? }?
	for _, offer in Npcs.HAGGLE.OFFERS do
		if offer.pct == pct then
			return offer
		end
	end
	return nil
end

local function onHaggle(player: Player, npcId: any, itemId: any, pct: any)
	if typeof(itemId) ~= "string" or typeof(pct) ~= "number" then
		return
	end
	local npc = npcNear(player, npcId)
	local data = DataService.Get(player)
	if not npc or not npc.haggle or not data then
		return
	end
	local offer = offerFor(pct)
	local tier = AffinityService.Tier(player, npc.id)
	if not offer or tier < (offer.minTier or 1) then
		return
	end
	local info = Items.info(itemId)
	local base = if info then Trade.buyPrice(npc, info) else nil
	local count = data.inventory[itemId]
	if not info or not base or not count then
		Net.Fire("Notify", player, "sell.nothing")
		return
	end

	local record = AffinityService.Record(player, npc.id) :: Types.NpcRecord
	local now = os.time()
	if now < record.pauseUntil then
		Net.Fire("Notify", player, "haggle.pause", { n = record.pauseUntil - now })
		return
	end

	local chance = Trade.haggleChance(offer.pct, tier, SkillService.Level(player, "tawar"))
	if random:NextNumber() * 100 < chance then
		local total = Trade.haggleTotal(base, count, info, offer.pct)
		if InventoryService.Remove(player, itemId, count) then
			EconomyService.Add(player, "koin", total, `sell:haggle:{itemId}`)
			record.failStreak = 0
			Net.Fire("Notify", player, "haggle.success", { n = total, pct = offer.pct })
			AffinityService.OnHaggle(player, npc.id, true)
			AffinityService.OnTrade(player, npc.id)
			SkillService.AddXp(player, "tawar", Npcs.HAGGLE.XP_WIN)
		end
	else
		record.failStreak += 1
		Net.Fire("Notify", player, "haggle.fail", { npc = `npc.{npc.id}` })
		if record.failStreak >= Npcs.HAGGLE.FAIL_STREAK then
			record.failStreak = 0
			record.pauseUntil = now + Npcs.HAGGLE.PAUSE_SECONDS
			Net.Fire("Notify", player, "haggle.pause", { n = Npcs.HAGGLE.PAUSE_SECONDS })
		end
		AffinityService.OnHaggle(player, npc.id, false)
		SkillService.AddXp(player, "tawar", Npcs.HAGGLE.XP_LOSS)
	end
end

-- Buying ---------------------------------------------------------------------------
-- tier = the player's kedekatan tier with this NPC: Trade.discount lowers every unit price.
-- Each function returns true when the purchase went through.

local function buyRod(player: Player, data: Types.PlayerData, rodId: string, tier: number): boolean
	local rod = Fishing.rods[rodId]
	if not rod or rod.price <= 0 or data.fishing.ownedRods[rodId] then
		return false
	end
	if data.level < rod.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = rod.unlockLevel })
		return false
	end
	if not EconomyService.TrySpend(player, "koin", Trade.discount(rod.price, tier), `rod:{rodId}`) then
		notEnough(player)
		return false
	end
	data.fishing.ownedRods[rodId] = true
	data.fishing.rod = rodId
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "shop.bought", { item = `rod.{rodId}` })
	return true
end

local function buyBait(player: Player, baitId: string, amount: any, tier: number): boolean
	if baitId ~= Fishing.BAIT.id or not validPack(amount) then
		return false
	end
	if not InventoryService.CanAdd(player, baitId, amount) then
		Net.Fire("Notify", player, "inv.full")
		return false
	end
	if not EconomyService.TrySpend(player, "koin", Trade.discount(Fishing.BAIT.price, tier) * amount, `bait:{baitId}`) then
		notEnough(player)
		return false
	end
	InventoryService.Add(player, baitId, amount)
	Net.Fire("Notify", player, "shop.bought", { item = `item.{baitId}` })
	return true
end

local function buyUpgrade(player: Player, data: Types.PlayerData, upgradeId: string, tier: number): boolean
	local config = Shop.UPGRADES[upgradeId]
	local state = UPGRADE_STATE[upgradeId]
	if not config or not state then
		return false
	end
	local current = state.get(data)
	local cost = config.costs[current + 1]
	if not cost then
		Net.Fire("Notify", player, "shop.max")
		return false
	end
	if data.level < config.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = config.unlockLevel })
		return false
	end
	if not EconomyService.TrySpend(player, "koin", Trade.discount(cost, tier), `upgrade:{upgradeId}:{current + 1}`) then
		notEnough(player)
		return false
	end
	state.set(data, current + 1)
	if state.after then
		state.after(player)
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "shop.bought", { item = `upgrade.{upgradeId}` })
	return true
end

-- Mbak Arsi's blueprints: one purchase unlocks buying every decor item of that set (Config/Blueprints).
local function buyBlueprint(player: Player, data: Types.PlayerData, blueprintId: string, tier: number): boolean
	local blueprint = Blueprints.byId[blueprintId]
	if not blueprint or data.decor.blueprints[blueprintId] == true then
		return false
	end
	if data.level < blueprint.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = blueprint.unlockLevel })
		return false
	end
	if not EconomyService.TrySpend(player, "koin", Trade.discount(blueprint.price, tier), `blueprint:{blueprintId}`) then
		notEnough(player)
		return false
	end
	data.decor.blueprints[blueprintId] = true
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "shop.bought", { item = `blueprint.{blueprintId}` })
	return true
end

-- Seeds go into the bag; planting uses them (FarmService). unggul = Bu Wati's faster, pricier kind.
local function buySeed(player: Player, data: Types.PlayerData, cropId: string, amount: any, unggul: boolean, tier: number): boolean
	local crop = Crops.byId[cropId]
	if not crop or not validPack(amount) then
		return false
	end
	if data.level < crop.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = crop.unlockLevel })
		return false
	end
	local itemId = (if unggul then "seedx_" else "seed_") .. crop.id
	if not InventoryService.CanAdd(player, itemId, amount) then
		Net.Fire("Notify", player, "inv.full")
		return false
	end
	local cost = Trade.discount(Trade.seedPrice(crop, unggul), tier) * amount
	if not EconomyService.TrySpend(player, "koin", cost, `seed:{crop.id}`) then
		notEnough(player)
		return false
	end
	InventoryService.Add(player, itemId, amount)
	Net.Fire("Notify", player, if unggul then "shop.bought_seedx" else "shop.bought_seed", { n = amount, crop = `crop.{crop.id}` })
	return true
end

-- Mbok Minah sells common/uncommon fish (size Kecil) so orders and the Book don't depend on luck.
local function buyFish(player: Player, fishId: string, amount: any, tier: number): boolean
	local fish = FishConfig.byId[fishId]
	if not fish or not Npcs.FISH_FOR_SALE[fish.rarity] or not validPack(amount) then
		return false
	end
	local itemId = FishService.ItemId(fish.id, "S")
	if not InventoryService.CanAdd(player, itemId, amount) then
		Net.Fire("Notify", player, "inv.full")
		return false
	end
	local cost = Trade.discount(Trade.fishPrice(fish.sellPrice), tier) * amount
	if not EconomyService.TrySpend(player, "koin", cost, `fish:{fish.id}`) then
		notEnough(player)
		return false
	end
	InventoryService.Add(player, itemId, amount)
	Net.Fire("Notify", player, "shop.bought_fish", { n = amount, fish = `fish.{fish.id}` })
	return true
end

local function onBuy(player: Player, npcId: any, kind: any, id: any, amount: any)
	if typeof(kind) ~= "string" or typeof(id) ~= "string" then
		return
	end
	local npc = npcNear(player, npcId)
	local data = DataService.Get(player)
	if not npc or not data then
		return
	end
	local tier = AffinityService.Tier(player, npc.id)
	local bought = false
	if kind == "rod" and npc.sells.rods then
		bought = buyRod(player, data, id, tier)
	elseif kind == "bait" and npc.sells.bait then
		bought = buyBait(player, id, amount, tier)
	elseif kind == "upgrade" and npc.sells.upgrades then
		bought = buyUpgrade(player, data, id, tier)
	elseif kind == "seed" and npc.sells.seeds then
		bought = buySeed(player, data, id, amount, false, tier)
	elseif kind == "seedx" and npc.sells.seedsUnggul then
		bought = buySeed(player, data, id, amount, true, tier)
	elseif kind == "fish" and npc.sells.fish then
		bought = buyFish(player, id, amount, tier)
	elseif kind == "blueprint" and npc.sells.blueprints then
		bought = buyBlueprint(player, data, id, tier)
	end
	if bought then
		AffinityService.OnTrade(player, npc.id)
	end
end

local function onEquipRod(player: Player, rodId: any)
	local data = DataService.Get(player)
	if data and typeof(rodId) == "string" and data.fishing.ownedRods[rodId] and Fishing.rods[rodId] then
		data.fishing.rod = rodId
		InventoryService.Sync(player)
	end
end

function ShopService.Start()
	Net.On("Sell", onSell, RATE)
	Net.On("ShopBuy", onBuy, RATE)
	Net.On("Haggle", onHaggle, RATE_HAGGLE)
	Net.On("ShopEquipRod", onEquipRod, RATE)
end

return ShopService
