--!strict
-- Bag panel (view only). Selling happens at the NPCs (ShopController).
--
-- UI CONTRACT: a TextButton/ImageButton named "BagButton" anywhere in your HUD opens the bag.
-- If missing, a placeholder button is added to the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
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
	{ id = "olahan", text = "Olahan" }, -- K-33: urutan Semua · Bibit · Panen · Ikan · Olahan · Bahan · Umpan · Alat
	{ id = "bahan", text = "Bahan" },
	{ id = "bait", text = "Umpan" }, -- F-1: bait (Pelet, Cacing, Jangkrik, Udang Kecil) has its own tab
	{ id = "tool", text = "Alat" },
}
local TAB_HEIGHT = UiKit.TOUCH -- a tab is a standard touch target (32 px, GUI doc 4.4)
local selectedTab = "all"
local drawerItem: string? = nil -- C1 (K-55): the rod ("rod:<id>") or the bait whose drawer is open

-- Category of an item: seeds (bibit), crops (panen), fish, bait (umpan), everything else (tools).
local function categoryOf(itemId: string, info: any): string
	if itemId:match("^seed_") then
		return "seed"
	end
	if info.kind == "bait" then
		return "bait" -- F-1: bait is only under Umpan (and Semua)
	end
	if info.kind == "crop" or info.kind == "ternak" then
		return "crop" -- K-33: Panen memuat tanaman + telur + susu
	end
	if info.kind == "fish" then
		return "fish"
	end
	if info.kind == "olahan" then
		return "olahan"
	end
	if info.kind == "bahan" then
		return "bahan"
	end
	return "tool"
end

-- C1 (K-55): the rods the player owns (Alat). Sorted, so the list does not move around.
local function ownedRodIds(snapshot: any): { string }
	local list = {}
	for rodId, owned in snapshot.ownedRods or {} do
		if owned == true and typeof(rodId) == "string" then
			table.insert(list, rodId)
		end
	end
	table.sort(list)
	return list
end

-- C1 (K-55): the drawer of a rod or bait, one row at the top of the Tas: its name, whether it is in use, and the Pakai button.
local function drawerRow(snapshot: any)
	if not drawerItem then
		return
	end
	local isRod = string.sub(drawerItem, 1, 4) == "rod:"
	local id = if isRod then string.sub(drawerItem, 5) else drawerItem
	local stillHas = if isRod then snapshot.ownedRods ~= nil and snapshot.ownedRods[id] == true else (snapshot.items ~= nil and (snapshot.items[id] or 0) > 0)
	if not stillHas then
		drawerItem = nil
		return
	end
	local using = if isRod then snapshot.rod == id else snapshot.equippedBait == id
	UiKit.row(panel.list, 1, Locale.t(if isRod then `rod.{id}` else `item.{id}`),
		if using then Locale.t("tas.dipakai_now") else Locale.t("tas.pakai_hint"),
		if using then nil else Locale.t("tas.pakai"), true,
		if using then nil else function()
			if isRod then
				Net.Send("ShopEquipRod", id)
			else
				Net.Send("EquipBait", id)
			end
			drawerItem = nil
		end)
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

	local ids = {}
	for itemId in snapshot.items do
		table.insert(ids, itemId)
	end
	Items.sortIds(ids)

	-- Category tabs (6 in one row: Semua, Bibit, Panen, Ikan, Alat, Umpan). UiKit.tabs shares the row width between the tabs,
	-- so each tab gets the same share and its label is not cut at the edge (F-1).
	local tabs = UiKit.tabs(panel.list, TABS, selectedTab, function(id)
		selectedTab = id
		render()
	end)
	tabs.frame.LayoutOrder = 0
	tabs.frame.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
	local shown = {}
	for _, itemId in ids do
		local info = Items.info(itemId)
		if info and (selectedTab == "all" or categoryOf(itemId, info) == selectedTab) then
			table.insert(shown, itemId)
		end
	end
	ids = shown
	local rodIds: { string } = if selectedTab == "all" or selectedTab == "tool" then ownedRodIds(snapshot) else {}
	if #ids == 0 and #rodIds == 0 then
		UiKit.header(panel.list, Locale.t("ui.empty"), 1)
		return
	end

	-- A grid, 5 per row: the picture says what it is (crops show their own 3D model), the badge says how many, the gold chip what
	-- the stack is worth. Category colour on the cell's top edge: green plants, blue fish, terracotta tools and bait.
	drawerRow(snapshot)
	local grid = UiKit.grid(panel.list, 2, 5, 96)
	for order, itemId in ids do
		local info = Items.info(itemId)
		local count = snapshot.items[itemId]
		if info then
			-- Icon by category, never a specific icon for another category. A harvest (Kualitas) uses its crop's model
			-- and the harvest icon; bait and anything without its own icon uses the generic bag icon (Tas).
			local isCrop = info.kind == "crop"
			local isFish = info.kind == "fish"
			local isSeed = info.kind == "seed"
			local variant = if isCrop then Items.cropVariant(itemId) else nil
			local cropId: string? = if isCrop then (if variant then variant.crop.id else itemId) elseif isSeed then itemId:gsub("^seed_", "") else nil
			local icon = if isFish then "ikan" elseif isSeed then "bibit" elseif isCrop then "panen" else "tas"
			local cellButton = UiKit.cell(grid, order, {
				name = Items.displayName(info),
				badge = if info.kind == "bait" and snapshot.equippedBait == itemId then Locale.t("tas.dipakai") else `×{count}`,
				accent = if isFish then UiKit.CAT.fish elseif isCrop or isSeed then UiKit.CAT.crop else UiKit.CAT.tool,
				cropId = cropId,
				icon = icon,
				price = if info.sellPrice then Locale.formatNumber(info.sellPrice * count) else nil,
			})
			if info.kind == "bait" then
				cellButton.Activated:Connect(function()
					drawerItem = itemId
					render()
				end)
			end
		end
	end
	-- C1 (K-55): every owned rod is in Alat (and Semua). The equipped one shows "Dipakai"; a tap opens the drawer with Pakai.
	for index, rodId in rodIds do
		local using = snapshot.rod == rodId
		local cellButton = UiKit.cell(grid, #ids + index, {
			name = Locale.t(`rod.{rodId}`),
			badge = if using then Locale.t("tas.dipakai") else nil,
			accent = UiKit.CAT.tool,
			icon = "pancing",
		})
		cellButton.Activated:Connect(function()
			drawerItem = `rod:{rodId}`
			render()
		end)
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
