--!strict
-- Villager orders: 3 daily + 1 weekly, generated from the player's unlocked content.
-- Deliver from anywhere (cozy, no walking chores). Rerolls: free ones, then Bunga (a Bunga sink, not a source).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Orders = require(ReplicatedStorage.Shared.Config.Orders)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local AnalyticsHooks = require(script.Parent.AnalyticsHooks)

type OrderEntry = Types.OrderEntry
type Candidate = { id: string, price: number, maxCount: number }

local RATE = { rate = 3, burst = 6 }
local SIZE_ORDER = { "S", "M", "L", "Jumbo" } -- fish sizes are consumed smallest first

local random = Random.new()

local OrderService = {}

-- Request pool ---------------------------------------------------------------------------

local function candidates(level: number): { Candidate }
	local pool = {}
	for _, crop in Crops.list do
		if crop.unlockLevel <= level then
			table.insert(pool, { id = crop.id, price = crop.sellPrice, maxCount = Orders.MAX_CROP_COUNT })
		end
	end
	for _, fish in FishConfig.list do
		if fish.unlockLevel <= level and (fish.rarity == "C" or fish.rarity == "U") and not fish.requirePhases and not fish.requireRain then
			for _, location in fish.locations do
				local config = Fishing.LOCATIONS[location]
				if config and config.unlockLevel <= level then
					table.insert(pool, { id = fish.id, price = fish.sellPrice, maxCount = Orders.MAX_FISH_COUNT })
					break
				end
			end
		end
	end
	return pool
end

local function pickDistinct(pool: { Candidate }, count: number): { Candidate }
	local copy = table.clone(pool)
	local picked = {}
	for _ = 1, math.min(count, #copy) do
		table.insert(picked, table.remove(copy, random:NextInteger(1, #copy)))
	end
	return picked
end

local function newOrder(data: Types.PlayerData, weekly: boolean): OrderEntry
	local level = data.level
	local pool = candidates(level)
	local typeCount = if weekly then Orders.WEEKLY_TYPES else random:NextInteger(1, math.min(3, 1 + level // 3))
	local countMult = if weekly then Orders.WEEKLY_COUNT_MULT else 1

	local items = {}
	local value = 0
	for _, candidate in pickDistinct(pool, typeCount) do
		local base = math.clamp(math.floor(Orders.valueTarget(level) / candidate.price + 0.5), 1, candidate.maxCount)
		local count = base * countMult
		table.insert(items, { item = candidate.id, count = count })
		value += candidate.price * count
	end

	local koin = math.floor(value * (if weekly then Orders.WEEKLY_REWARD_MULT else Orders.REWARD_MULT) + 0.5)
	local entry: OrderEntry = {
		uid = data.orders.nextUid,
		npc = Orders.NPCS[random:NextInteger(1, #Orders.NPCS)],
		items = items,
		koin = koin,
		xp = math.max(5, math.floor(koin * Orders.XP_PER_KOIN * (if weekly then Orders.WEEKLY_XP_MULT else 1) + 0.5)),
		done = false,
	}
	data.orders.nextUid += 1
	return entry
end

-- Replaces stale daily/weekly sets. Returns true if anything changed.
local function refresh(data: Types.PlayerData): boolean
	local changed = false
	local today, thisWeek = TimeKeys.day(), TimeKeys.week()
	if data.orders.day ~= today then
		data.orders.day = today
		data.orders.rerollsUsed = 0
		data.orders.rerolled = {}
		data.orders.daily = {}
		for _ = 1, Orders.DAILY_COUNT do
			table.insert(data.orders.daily, newOrder(data, false))
		end
		changed = true
	end
	if data.orders.week ~= thisWeek then
		data.orders.week = thisWeek
		data.orders.weekly = newOrder(data, true)
		changed = true
	end
	return changed
end

-- Inventory helpers ----------------------------------------------------------------------

local function haveCount(player: Player, itemId: string): number
	if FishConfig.byId[itemId] then
		local total = 0
		for _, size in SIZE_ORDER do
			total += InventoryService.Count(player, `{itemId}@{size}`)
		end
		return total
	end
	return InventoryService.Count(player, itemId)
end

local function take(player: Player, itemId: string, count: number)
	if not FishConfig.byId[itemId] then
		InventoryService.Remove(player, itemId, count)
		return
	end
	local remaining = count
	for _, size in SIZE_ORDER do
		local id = `{itemId}@{size}`
		local amount = math.min(remaining, InventoryService.Count(player, id))
		if amount > 0 then
			InventoryService.Remove(player, id, amount)
			remaining -= amount
		end
	end
end

local function findOrder(data: Types.PlayerData, uid: any): (OrderEntry?, boolean)
	for index, order in data.orders.daily do
		if order.uid == uid then
			return order, false
		end
	end
	local weekly = data.orders.weekly :: OrderEntry
	if weekly.uid ~= nil and weekly.uid == uid then
		return weekly, true
	end
	return nil, false
end

-- Requests -------------------------------------------------------------------------------

local function onDeliver(player: Player, uid: any)
	local data = DataService.Get(player)
	if not data then
		return
	end
	refresh(data)
	local order = findOrder(data, uid)
	if not order or order.done then
		return
	end
	for _, request in order.items do
		if haveCount(player, request.item) < request.count then
			Net.Fire("Notify", player, "order.missing")
			return
		end
	end
	for _, request in order.items do
		take(player, request.item, request.count)
	end
	order.done = true
	local koin = order.koin
	ProgressionService.Grant(player, {
		koin = koin,
		xp = order.xp,
		decor = if order.decor then { [order.decor] = 1 } else nil,
	}, `order:{order.npc}`)
	Net.Fire("Notify", player, "order.done", { npc = `npc.{order.npc}`, n = koin })
	AnalyticsHooks.Step(player, "first_order")
	InventoryService.Sync(player)
end

function OrderService.FreeRerolls(_player: Player): number
	return Orders.FREE_REROLLS -- T-32: Premium gives no extra reroll (Bab 19)
end

-- Reroll (Bab 14.7): 2 Bunga per Order, max 1x per Order per hari. Order baru = Daily baru
-- (tier sama). Order yang hilang saat reset tidak ada hukuman (refresh ganti semua).
local function onReroll(player: Player, uid: any)
	local data = DataService.Get(player)
	if not data then
		return
	end
	refresh(data)
	for index, order in data.orders.daily do
		if order.uid == uid and not order.done then
			if data.orders.rerolled[uid] == true then
				Net.Fire("Notify", player, "order.reroll_max")
				return
			end
			if not EconomyService.TrySpend(player, "bunga", Orders.REROLL_BUNGA, "order:reroll") then
				Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.bunga" })
				return
			end
			data.orders.rerolled[uid] = true
			data.orders.rerollsUsed += 1
			data.orders.daily[index] = newOrder(data, false)
			InventoryService.Sync(player)
			return
		end
	end
end

function OrderService.Init()
	DataService.Loaded:Connect(function(_player: Player, data: Types.PlayerData)
		refresh(data) -- before the first StateSync goes out
	end)
end

function OrderService.Start()
	Net.On("OrderDeliver", onDeliver, RATE)
	Net.On("OrderReroll", onReroll, RATE)

	-- New day/week while online.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data and refresh(data) then
					InventoryService.Sync(player)
					Net.Fire("Notify", player, "order.new_day")
				end
			end
		end
	end)
end

-- Studio testing only.
function OrderService.DevNewOrders(player: Player)
	local data = DataService.Get(player)
	if data then
		data.orders.day = ""
		data.orders.week = ""
		refresh(data)
		InventoryService.Sync(player)
	end
end

return OrderService
