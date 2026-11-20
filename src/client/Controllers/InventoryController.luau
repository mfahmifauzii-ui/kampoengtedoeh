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

local TABS = {
	{ id = "all", text = "Semua" },
	{ id = "seed", text = "Bibit" },
	{ id = "crop", text = "Panen" },
	{ id = "fish", text = "Ikan" },
	{ id = "tool", text = "Alat" },
}
local TAB_HEIGHT = 26 -- smaller than the shop tabs (34 px): the bag is a list of items, not the main action
local selectedTab = "all"

-- Category of an item: seeds (bibit), crops (panen), fish, everything else (tools, bait).
local function categoryOf(itemId: string, info: any): string
	if itemId:match("^seedx?_") then
		return "seed"
	end
	if info.kind == "crop" then
		return "crop"
	end
	if info.kind == "fish" then
		return "fish"
	end
	return "tool"
end

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

	-- Category tabs, like the shop's (small ones): they sit above the grid and filter it.
	local tabs = UiKit.tabs(panel.list, TABS, selectedTab, function(id)
		selectedTab = id
		render()
	end)
	tabs.frame.LayoutOrder = 0
	tabs.frame.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
	for _, button in tabs.buttons do
		button.Size = UDim2.new(1 / #TABS, -4, 1, 0)
		button.TextSize = 12
	end
	local shown = {}
	for _, itemId in ids do
		local info = Items.info(itemId)
		if info and (selectedTab == "all" or categoryOf(itemId, info) == selectedTab) then
			table.insert(shown, itemId)
		end
	end
	ids = shown
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
			-- Icon by category, never a specific icon for another category. A harvest (Super, Mutasi) uses its crop's model
			-- and the harvest icon; bait and anything without its own icon uses the generic bag icon (Tas).
			local isCrop = info.kind == "crop"
			local isFish = info.kind == "fish"
			local isSeed = info.kind == "seed"
			local variant = if isCrop then Items.cropVariant(itemId) else nil
			local cropId: string? = if isCrop then (if variant then variant.crop.id else itemId) elseif isSeed then itemId:gsub("^seedx?_", "") else nil
			local icon = if isFish then "ikan" elseif isSeed then "bibit" elseif isCrop then "panen" else "tas"
			UiKit.cell(grid, order, {
				name = Items.displayName(info),
				badge = `×{count}`,
				accent = if isFish then UiKit.CAT.fish elseif isCrop or isSeed then UiKit.CAT.crop else UiKit.CAT.tool,
				cropId = cropId,
				icon = icon,
				price = if info.sellPrice then Locale.formatNumber(info.sellPrice * count) else nil,
			})
		end
	end
	-- A3 (v6.2.3): the equipped rod is shown too. Rods are ownership flags (data.fishing), not bag items, so without this
	-- the Joran Bambu from Kak Fajar never appeared in the Tas.
	local snapshot2 = State.current :: any
	if snapshot2 and typeof(snapshot2.rod) == "string" and snapshot2.rod ~= "" then
		UiKit.cell(grid, #ids + 1, {
			name = Locale.t(`rod.{snapshot2.rod}`),
			badge = "×1",
			accent = UiKit.CAT.tool,
			icon = "pancing",
		})
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
