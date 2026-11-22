--!strict
-- Orders panel (HUD "OrdersButton" / placeholder "Pesanan") + the HUD "next goal" chip.
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

local panel: UiKit.Panel

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

local function addOrderRow(order: any, items: { [string]: number }, order_: number, _weekly: boolean, showReroll: boolean)
	local name = Locale.t(`npc.{order.npc}`)
	-- Weekly: Koin + XP saja, tanpa Bunga, tanpa dekor (Bab 14.7).
	local reward = Locale.t("order.reward", { koin = Locale.formatNumber(order.koin), xp = order.xp })

	if order.done then
		UiKit.row(panel.list, order_, `{name}: {requestText(order, items)}`, reward, Locale.t("ui.done_check"), false)
		return
	end
	local ready = canDeliver(order, items)
	local row = UiKit.row(panel.list, order_, `{name}: {requestText(order, items)}`, reward, Locale.t("ui.deliver"), ready, function()
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

-- Playtest 7: the Orders button and panel stay hidden until the tutorial (t1b_kolam) is finished or skipped.
local function tutorialDone(snapshot: any): boolean
	local guide = snapshot and snapshot.guide
	return guide ~= nil and (guide.done.t1b_kolam == true or guide.skipped.t1b_kolam == true)
end

local function syncButton()
	local gui = player:FindFirstChild("PlayerGui")
	local hud = gui and gui:FindFirstChild("HUD")
	local button = hud and hud:FindFirstChild("OrdersButton", true)
	if button and button:IsA("GuiObject") then
		button.Visible = tutorialDone(State.current)
	end
end

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	if not snapshot or not snapshot.orders or not tutorialDone(snapshot) then
		panel.gui.Enabled = false
		return
	end
	local items = snapshot.items
	local orders = snapshot.orders
	-- Reroll: 2 Bunga per Order, max 1x per Order per hari (Bab 14.7). Tombol hanya untuk
	-- order harian yang belum di-reroll hari ini.
	local rerolled = orders.rerolled or {}
	local rerollText = Locale.t("order.rerolls_paid", { n = Orders.REROLL_BUNGA })

	UiKit.header(panel.list, Locale.t("order.daily"), 1)
	for index, order in orders.daily do
		addOrderRow(order, items, 1 + index, false, rerolled[order.uid] ~= true)
	end
	if orders.weekly and orders.weekly.uid then
		UiKit.header(panel.list, Locale.t("order.weekly"), 20)
		addOrderRow(orders.weekly, items, 21, true, false)
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
	panel = UiKit.panel("OrdersPanel", Locale.t("ui.orders"), function()
		panel.gui.Enabled = false
	end)
end

function OrdersController.Start()
	State.Changed:Connect(function()
		syncButton()
		render()
		updateGoal()
	end)
	player:GetAttributeChangedSignal("XP"):Connect(updateGoal)
	task.spawn(UiKit.hudButton, "OrdersButton", Locale.t("ui.orders"), 3, function()
		if not tutorialDone(State.current) then
			return
		end
		panel.gui.Enabled = not panel.gui.Enabled
		render()
	end)
	task.spawn(function()
		-- the HUD button can be created after the first snapshot: keep its visibility in step with the tutorial
		while true do
			syncButton()
			task.wait(0.5)
		end
	end)
	updateGoal()
end

return OrdersController
