--!strict
-- Order list (Pesanan) + the HUD "next goal" chip. The list lives in the one Quest Log (tab Pesanan, owner 2026-11-24 butir 2):
-- QuestController calls OrdersController.Fill. The separate Pesanan panel and its dock button are gone.
-- Goal priority: an order you can deliver now -> the next level unlock -> the next Book entry.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Book = require(ReplicatedStorage.Shared.Config.Book)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Orders = require(ReplicatedStorage.Shared.Config.Orders)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local HudController = require(script.Parent.HudController)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local OrdersController = {}

local function haveCount(items: { [string]: number }, itemId: string): number
	if FishConfig.byId[itemId] then
		return (items[`{itemId}@S`] or 0) + (items[`{itemId}@M`] or 0) + (items[`{itemId}@L`] or 0) + (items[`{itemId}@Jumbo`] or 0)
	end
	return items[itemId] or 0
end

local function itemName(itemId: string): string
	return Locale.t(if Crops.byId[itemId] then `crop.{itemId}` else `fish.{itemId}`)
end

local function canDeliver(order: any, items: { [string]: number }): boolean
	for _, request in order.items do
		if haveCount(items, request.item) < request.count then
			return false
		end
	end
	return true
end

local function requestText(order: any, items: { [string]: number }): string
	local parts = {}
	for _, request in order.items do
		table.insert(parts, `{itemName(request.item)} {math.min(haveCount(items, request.item), request.count)}/{request.count}`)
	end
	return table.concat(parts, ", ")
end

local function addOrderRow(list: ScrollingFrame, order: any, items: { [string]: number }, order_: number, _weekly: boolean, showReroll: boolean)
	local name = Locale.t(`npc.{order.npc}`)
	-- Weekly: Koin + XP saja, tanpa Bunga, tanpa dekor (Bab 14.7).
	local reward = Locale.t("order.reward", { koin = Locale.formatNumber(order.koin), xp = order.xp })

	if order.done then
		UiKit.row(list, order_, `{name}: {requestText(order, items)}`, reward, Locale.t("ui.done_check"), false)
		return
	end
	local ready = canDeliver(order, items)
	local row = UiKit.row(list, order_, `{name}: {requestText(order, items)}`, reward, Locale.t("ui.deliver"), ready, function()
		Net.Send("OrderDeliver", order.uid)
	end)

	if showReroll then
		local reroll = UiKit.button(row, "Reroll", Locale.t("ui.reroll"), UiKit.BUTTON_MUTED)
		-- "Ganti" sits left of "Kirim"; the text gives up that width (title wraps to two lines if needed).
		reroll.AnchorPoint = Vector2.new(1, 0.5)
		reroll.Position = UDim2.new(1, -118, 0.5, 0)
		reroll.Size = UDim2.fromOffset(64, 34) -- the Ganti button: small (34 px tall, 44 px hitbox row), not a big key
		reroll.Activated:Connect(function()
			Net.Send("OrderReroll", order.uid)
		end)
		local label = row:FindFirstChildOfClass("TextLabel")
		if label then
			label.Size = UDim2.new(1, -210, 0, 44)
		end
	end
end

-- The order rows for the Quest Log's Pesanan tab (cleared by the caller). Numbers start at `order`.
-- Reroll: 2 Bunga per Order, max 1x per Order per hari (Bab 14.7). Tombol hanya untuk order harian yang belum di-reroll hari ini.
function OrdersController.Fill(list: ScrollingFrame, order: number)
	local snapshot = State.current :: any
	if not snapshot or not snapshot.orders then
		return
	end
	local items = snapshot.items
	local orders = snapshot.orders
	local rerolled = orders.rerolled or {}

	UiKit.header(list, Locale.t("order.daily"), order)
	for index, daily in orders.daily do
		addOrderRow(list, daily, items, order + index, false, rerolled[daily.uid] ~= true)
	end
	local last = order + #orders.daily
	if orders.weekly and orders.weekly.uid then
		UiKit.header(list, Locale.t("order.weekly"), last + 1)
		addOrderRow(list, orders.weekly, items, last + 2, true, false)
	end
	UiKit.header(list, Locale.t("order.rerolls_paid", { n = Orders.REROLL_BUNGA }), last + 3)
end

-- Goal chip -------------------------------------------------------------------------------

local function nextUnlock(level: number): (number?, string?)
	local bestLevel, bestKey = math.huge, nil
	local function consider(unlockLevel: number, key: string)
		if unlockLevel > level and unlockLevel < bestLevel then
			bestLevel, bestKey = unlockLevel, key
		end
	end
	for _, crop in Crops.list do
		consider(crop.unlockLevel, `crop.{crop.id}`)
	end
	for _, rod in Fishing.rodList do
		consider(rod.unlockLevel, `rod.{rod.id}`)
	end
	for location, config in Fishing.LOCATIONS do
		consider(config.unlockLevel, `location.{location}`)
	end
	if bestKey then
		return bestLevel, bestKey
	end
	return nil, nil
end

local function updateGoal()
	local snapshot = State.current :: any
	if not snapshot or not snapshot.orders then
		return
	end
	if snapshot.farm and #snapshot.farm.tiles == 0 then
		HudController.SetGoal(Locale.t("goal.till")) -- a new player has no soil yet
		return
	end
	local items = snapshot.items
	for _, order in snapshot.orders.daily do
		if not order.done and canDeliver(order, items) then
			HudController.SetGoal(Locale.t("goal.order_ready", { npc = Locale.t(`npc.{order.npc}`) }))
			return
		end
	end
	local weekly = snapshot.orders.weekly
	if weekly and weekly.uid and not weekly.done and canDeliver(weekly, items) then
		HudController.SetGoal(Locale.t("goal.order_ready", { npc = Locale.t(`npc.{weekly.npc}`) }))
		return
	end

	local level = player:GetAttribute("Level")
	local xp = player:GetAttribute("XP")
	local xpNext = player:GetAttribute("XPNext")
	if typeof(level) == "number" and typeof(xp) == "number" and typeof(xpNext) == "number" then
		local unlockLevel, key = nextUnlock(level)
		if unlockLevel and key then
			if unlockLevel == level + 1 then
				HudController.SetGoal(Locale.t("goal.next_unlock", { level = unlockLevel, item = Locale.t(key), xp = Locale.formatNumber(xpNext - xp) }))
			else
				HudController.SetGoal(Locale.t("goal.next_unlock_far", { level = unlockLevel, item = Locale.t(key) }))
			end
			return
		end
	end

	-- Kandang/Dapur/Varian dilewati: pencatatnya belum ada (Ternak P2-2, Dapur P2-3, Gerobak P2-6).
	for _, category in { "ladang", "sungai", "rumah" } do
		local recorded = snapshot.book[category]
		for _, id in Book.ENTRIES[category] do
			if not recorded[id] then
				local item: string
				if category == "ladang" then
					item = Locale.t(`crop.{id:match("^(.+):") or id}`)
				elseif category == "sungai" then
					item = Locale.t(`fish.{id:match("^(.+)@") or id}`)
				else
					item = Locale.t(`decor.{id}`)
				end
				HudController.SetGoal(Locale.t("goal.book", { item = item }))
				return
			end
		end
	end
	HudController.SetGoal(Locale.t("goal.max"))
end

function OrdersController.Init()
	-- no panel of its own: the Quest Log (QuestController) draws the order list
end

function OrdersController.Start()
	State.Changed:Connect(updateGoal)
	player:GetAttributeChangedSignal("XP"):Connect(updateGoal)
	updateGoal()
end

return OrdersController
