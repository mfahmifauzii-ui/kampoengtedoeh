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

	-- A grid, 5 per row: the picture says what it is (crops show their own 3D model), the badge says how many, the gold chip what
	-- the stack is worth. Category colour on the cell's top edge: green plants, blue fish, terracotta tools and bait.
	local grid = UiKit.grid(panel.list, 1, 5, 96)
	for order, itemId in ids do
		local info = Items.info(itemId)
		local count = snapshot.items[itemId]
		if info then
			local isCrop = info.kind == "crop"
			local isFish = info.kind == "fish"
			UiKit.cell(grid, order, {
				name = Items.displayName(info),
				badge = `×{count}`,
				accent = if isFish then UiKit.CAT.fish elseif isCrop or itemId:match("^seedx?_") then UiKit.CAT.crop else UiKit.CAT.tool,
				cropId = if isCrop then itemId elseif itemId:match("^seedx?_") then itemId:gsub("^seedx?_", "") else nil,
				icon = if isFish then "ikan" elseif itemId:match("^seedx?_") then "bibit" else "pancing",
				price = if info.sellPrice then Locale.formatNumber(info.sellPrice * count) else nil,
			})
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
