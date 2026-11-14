--!strict
-- Orders panel (HUD "OrdersButton" / placeholder "Pesanan") + the HUD "next goal" chip.
-- Goal priority: an order you can deliver now -> the next level unlock -> the next Book entry.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blueprints = require(ReplicatedStorage.Shared.Config.Blueprints)
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

local panel: UiKit.Panel

local function haveCount(items: { [string]: number }, itemId: string): number
	if FishConfig.byId[itemId] then
		return (items[`{itemId}@S`] or 0) + (items[`{itemId}@M`] or 0) + (items[`{itemId}@L`] or 0)
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

local function addOrderRow(order: any, items: { [string]: number }, order_: number, weekly: boolean, rerollText: string?)
	local name = Locale.t(`npc.{order.npc}`)
	local reward = if weekly
		then Locale.t("order.reward_weekly", { koin = Locale.formatNumber(order.koin), xp = order.xp, bunga = order.bunga or 0, decor = Locale.t(`decor.{order.decor}`) })
		else Locale.t("order.reward", { koin = Locale.formatNumber(order.koin), xp = order.xp })

	if order.done then
		UiKit.row(panel.list, order_, `{name}: {requestText(order, items)}`, reward, Locale.t("ui.done_check"), false)
		return
	end
	local ready = canDeliver(order, items)
	local row = UiKit.row(panel.list, order_, `{name}: {requestText(order, items)}`, reward, Locale.t("ui.deliver"), ready, function()
		Net.Send("OrderDeliver", order.uid)
	end)

	if rerollText then
		local reroll = UiKit.button(row, "Reroll", Locale.t("ui.reroll"), UiKit.BUTTON_MUTED)
		-- "Ganti" sits left of "Kirim"; the text gives up that width (title wraps to two lines if needed).
		reroll.AnchorPoint = Vector2.new(1, 0.5)
		reroll.Position = UDim2.new(1, -124, 0.5, 0)
		reroll.Size = UDim2.fromOffset(84, 52)
		reroll.Activated:Connect(function()
			Net.Send("OrderReroll", order.uid)
		end)
		local label = row:FindFirstChildOfClass("TextLabel")
		if label then
			label.Size = UDim2.new(1, -226, 0, 44)
		end
	end
end

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	if not snapshot or not snapshot.orders then
		return
	end
	local items = snapshot.items
	local orders = snapshot.orders
	local rerollsLeft = (orders.freeRerolls or Orders.FREE_REROLLS) - orders.rerollsUsed
	local rerollText = if rerollsLeft > 0
		then Locale.t("order.rerolls_free", { n = rerollsLeft })
		else Locale.t("order.rerolls_paid", { n = Orders.REROLL_BUNGA })

	UiKit.header(panel.list, Locale.t("order.daily"), 1)
	for index, order in orders.daily do
		addOrderRow(order, items, 1 + index, false, rerollText)
	end
	if orders.weekly and orders.weekly.uid then
		UiKit.header(panel.list, Locale.t("order.weekly"), 20)
		addOrderRow(orders.weekly, items, 21, true, nil)
	end
	panel.footerLabel.Text = rerollText
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
	for _, blueprint in Blueprints.list do
		consider(blueprint.unlockLevel, `blueprint.{blueprint.id}`)
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

	for _, category in Book.CATEGORIES do
		local recorded = snapshot.book[category]
		for _, id in Book.ENTRIES[category] do
			if not recorded[id] then
				local prefix = if category == "crops" then "crop" elseif category == "fish" then "fish" else "decor"
				HudController.SetGoal(Locale.t("goal.book", { item = Locale.t(`{prefix}.{id}`) }))
				return
			end
		end
	end
	HudController.SetGoal(Locale.t("goal.max"))
end

function OrdersController.Init()
	panel = UiKit.panel("OrdersPanel", Locale.t("ui.orders"), function()
		panel.gui.Enabled = false
	end)
end

function OrdersController.Start()
	State.Changed:Connect(function()
		render()
		updateGoal()
	end)
	player:GetAttributeChangedSignal("XP"):Connect(updateGoal)
	task.spawn(UiKit.hudButton, "OrdersButton", Locale.t("ui.orders"), 3, function()
		panel.gui.Enabled = not panel.gui.Enabled
		render()
	end)
	updateGoal()
end

return OrdersController
