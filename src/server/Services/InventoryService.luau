--!strict
-- Item counts with backpack capacity, plus the client state snapshot ("StateSync").
-- Any service that changes something the client panels show calls InventoryService.Sync.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DecorConfig = require(ReplicatedStorage.Shared.Config.Decor)
local FarmConfig = require(ReplicatedStorage.Shared.Config.Farm)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.Inventory)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local OrdersConfig = require(ReplicatedStorage.Shared.Config.Orders)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Plots = require(ReplicatedStorage.Shared.Config.Plots)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local STACK = InventoryConfig.STACK_SIZE

local InventoryService = {}

local pendingSync: { [Player]: boolean } = {}

local function slotsFor(count: number): number
	return math.ceil(count / STACK)
end

local function slotsUsed(data: Types.PlayerData): number
	local used = 0
	for _, count in data.inventory do
		used += slotsFor(count)
	end
	return used
end

local function slotsMax(player: Player, data: Types.PlayerData): number
	local base = InventoryConfig.SLOTS[math.clamp(data.backpackTier + 1, 1, #InventoryConfig.SLOTS)]
	return base + (if MonetizationService.HasPass(player, "backpack") then Monetization.BACKPACK_BONUS_SLOTS else 0)
end

local function isValid(itemId: any, amount: any): boolean
	return typeof(itemId) == "string" and typeof(amount) == "number" and amount > 0 and amount % 1 == 0
end

-- Just the cells (the client needs them to preview where you can till / place decor).
local function farmTiles(data: Types.PlayerData)
	local tiles = {}
	for _, tile in data.farm.tiles do
		table.insert(tiles, { uid = tile.uid, cx = tile.cx, cz = tile.cz })
	end
	return tiles
end

-- Pond cells, so the client can preview where a pond fits and keep soil / decor off the water.
local function pondCells(data: Types.PlayerData)
	local ponds = {}
	for _, pond in data.pond.list do
		table.insert(ponds, { uid = pond.uid, cx = pond.cx, cz = pond.cz })
	end
	return ponds
end

local function buildSnapshot(player: Player, data: Types.PlayerData)
	local passes = {}
	for _, pass in Monetization.PASSES do
		passes[pass.key] = MonetizationService.HasPass(player, pass.key)
	end
	return {
		items = table.clone(data.inventory),
		slotsUsed = slotsUsed(data),
		slotsMax = slotsMax(player, data),
		backpackTier = data.backpackTier,
		pondTier = data.pond.tier,
		ponds = pondCells(data),
		quests = { active = table.clone(data.quests.active), done = table.clone(data.quests.done) },
		farm = { tiles = farmTiles(data), cap = FarmConfig.MAX_TILES },
		landChunks = table.clone(data.land.chunks),
		landExtra = Land.extraCount(data.land.chunks),
		landPrice = Land.chunkPrice(Land.extraCount(data.land.chunks), if passes.plots == true then Plots.CHUNK.PASS_DISCOUNT else 0),
		rod = data.fishing.rod,
		ownedRods = table.clone(data.fishing.ownedRods),
		decorStock = table.clone(data.decor.stock),
		decorBlueprints = table.clone(data.decor.blueprints),
		decorPlaced = #data.decor.placed,
		decorMax = DecorConfig.MAX_PLACED + (if passes.decor then Monetization.DECOR_BONUS else 0),
		passes = passes,
		instantGrow = data.instantGrow,
		premium = MonetizationService.IsPremium(player),
		orders = {
			daily = data.orders.daily,
			weekly = data.orders.weekly,
			rerollsUsed = data.orders.rerollsUsed,
			freeRerolls = OrdersConfig.FREE_REROLLS
				+ (if MonetizationService.IsPremium(player) then Monetization.PREMIUM_EXTRA_REROLLS else 0),
		},
		book = data.book,
		visits = data.visits.count,
		titles = data.titles,
		sales = { day = data.sales.day, sold = table.clone(data.sales.sold) },
		warungTier = data.sales.tier,
		social = data.social,
		settings = data.settings,
	}
end

-- Batched: many changes in one frame send one snapshot.
function InventoryService.Sync(player: Player)
	if pendingSync[player] then
		return
	end
	pendingSync[player] = true
	task.defer(function()
		pendingSync[player] = nil
		local data = DataService.Get(player)
		if data and player.Parent then
			Net.Fire("StateSync", player, buildSnapshot(player, data))
		end
	end)
end

function InventoryService.Count(player: Player, itemId: string): number
	local data = DataService.Get(player)
	return if data then data.inventory[itemId] or 0 else 0
end

function InventoryService.HasFreeSlot(player: Player): boolean
	local data = DataService.Get(player)
	return data ~= nil and slotsUsed(data) < slotsMax(player, data)
end

function InventoryService.CanAdd(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or not isValid(itemId, amount) or Items.info(itemId) == nil then
		return false
	end
	local current = data.inventory[itemId] or 0
	local extra = slotsFor(current + amount) - slotsFor(current)
	return slotsUsed(data) + extra <= slotsMax(player, data)
end

-- Returns false (and tells the player their bag is full) if it doesn't fit.
function InventoryService.Add(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or not isValid(itemId, amount) or Items.info(itemId) == nil then
		return false
	end
	if not InventoryService.CanAdd(player, itemId, amount) then
		Net.Fire("Notify", player, "inv.full")
		return false
	end
	data.inventory[itemId] = (data.inventory[itemId] or 0) + amount
	InventoryService.Sync(player)
	return true
end

function InventoryService.Remove(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or not isValid(itemId, amount) then
		return false
	end
	local current = data.inventory[itemId] or 0
	if current < amount then
		return false
	end
	data.inventory[itemId] = if current == amount then nil else current - amount
	InventoryService.Sync(player)
	return true
end

function InventoryService.Init()
	DataService.Loaded:Connect(InventoryService.Sync)
	MonetizationService.Changed:Connect(InventoryService.Sync)
end

function InventoryService.Start()
	Net.On("StateRequest", InventoryService.Sync, { rate = 1, burst = 3 })
end

return InventoryService
