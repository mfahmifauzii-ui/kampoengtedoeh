--!strict
-- Bag panel (view only). Selling happens at the NPCs (ShopController).
--
-- UI CONTRACT: a TextButton/ImageButton named "BagButton" anywhere in your HUD opens the bag.
-- If missing, a placeholder button is added to the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Locale = require(ReplicatedStorage.Shared.Locale)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local InventoryController = {}

local panel: UiKit.Panel

local function render()
	if not panel.gui.Enabled then
		return
	end
	local snapshot = State.current
	UiKit.clear(panel.list)
	if not snapshot then
		return
	end

	panel.footerLabel.Text = Locale.t("ui.slots", { used = snapshot.slotsUsed, max = snapshot.slotsMax })

	local ids = {}
	for itemId in snapshot.items do
		table.insert(ids, itemId)
	end
	Items.sortIds(ids)

	if #ids == 0 then
		UiKit.header(panel.list, Locale.t("ui.empty"), 1)
		return
	end

	for order, itemId in ids do
		local info = Items.info(itemId)
		local count = snapshot.items[itemId]
		if info then
			local value = if info.sellPrice then Locale.t("ui.koin", { n = Locale.formatNumber(info.sellPrice * count) }) else nil
			UiKit.row(panel.list, order, `{Items.displayName(info)}  ×{count}`, value)
		end
	end
end

function InventoryController.Open()
	panel.gui.Enabled = true
	render()
end

function InventoryController.Close()
	panel.gui.Enabled = false
end

local function hookBagButton()
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild("HUD", 5)
	if not hud then
		return
	end
	local button = UiKit.menuItem(hud, "BagButton", Locale.t("ui.bag"), 1)
	if button then
		button.Activated:Connect(function()
			if panel.gui.Enabled then
				InventoryController.Close()
			else
				InventoryController.Open()
			end
		end)
	end
end

function InventoryController.Init()
	panel = UiKit.panel("InventoryPanel", Locale.t("ui.bag"), InventoryController.Close)
end

function InventoryController.Start()
	State.Changed:Connect(render)
	task.spawn(hookBagButton)
end

return InventoryController
