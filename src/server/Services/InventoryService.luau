--!strict
-- Item counts. Tas tanpa cap slot, stack 99 (Bab 18.1 v7.3). Tidak ada Upgrade Tas, tidak ada Backpack Pass.
-- Any service that changes something the client panels show calls InventoryService.Sync.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DecorConfig = require(ReplicatedStorage.Shared.Config.Decor)
local FarmConfig = require(ReplicatedStorage.Shared.Config.Farm)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local OrdersConfig = require(ReplicatedStorage.Shared.Config.Orders)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local InventoryService = {}

local pendingSync: { [Player]: boolean } = {}

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
		pondTier = Upgrades.tier(data, "pond"),
		ponds = pondCells(data),
		quests = { active = table.clone(data.quests.active), done = table.clone(data.quests.done), daily = table.clone(data.quests.daily) },
		farm = { tiles = farmTiles(data), cap = FarmConfig.tileCap(data.level) },
		landChunks = table.clone(data.land.chunks),
		landExtra = Land.extraCount(data.land.chunks),
		landPrice = Land.chunkPrice(Land.extraCount(data.land.chunks)),
		rod = data.fishing.rod,
		ownedRods = table.clone(data.fishing.ownedRods),
		tools = table.clone(data.tools),
		decorStock = table.clone(data.decor.stock),
		decorPlaced = #data.decor.placed,
		decorMax = DecorConfig.MAX_PLACED,
		passes = passes,
		premium = MonetizationService.IsPremium(player),
		orders = {
			daily = data.orders.daily,
			weekly = data.orders.weekly,
			rerollsUsed = data.orders.rerollsUsed,
			freeRerolls = OrdersConfig.FREE_REROLLS,
		},
		book = data.book,
		playtime = table.clone(data.playtime),
		titles = data.titles,
		guideSells = data.guide.sells,
		guide = {
			step = { id = data.guide.step.id, n = data.guide.step.n },
			done = table.clone(data.guide.done),
			skipped = table.clone(data.guide.skipped),
			fastLeft = data.guide.fastLeft,
			rodGift = data.guide.rodGift, -- Kak Fajar's Terima Hadiah was taken (the dialog shows it until then)
			-- a save that has not started playing: the "newPlayer" tutorial trigger
			fresh = #data.farm.tiles == 0 and data.onboarding.first_plant ~= true and data.guide.sells == 0,
		},
		social = data.social,
		settings = data.settings,
		-- one-time funnel flags (first_plant, first_harvest, ...). The tutorial reads first_harvest (A1: state-driven steps).
		onboarding = table.clone(data.onboarding),
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

-- Tas tanpa cap slot (Bab 18.1 v7.3): CanAdd hanya cek valid.
function InventoryService.CanAdd(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	return data ~= nil and isValid(itemId, amount) and Items.info(itemId) ~= nil
end

function InventoryService.Add(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or not isValid(itemId, amount) or Items.info(itemId) == nil then
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
