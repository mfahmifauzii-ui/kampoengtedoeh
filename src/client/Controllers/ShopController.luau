--!strict
-- NPC shop panel: opened by the dialogue's [Jual / Beli] button. What it shows comes from the NPC's config
-- (Config/Npcs): what it sells (seeds, rods, bait, upgrades, fish) and what it buys from you.
--
-- Two tabs, Beli and Jual (a tab only shows when the NPC does that at all). Every row has a picture slot (a placeholder
-- icon until the model's image exists, see UiAssets.THUMBS), a number picker, the total and one button. A total the player
-- cannot pay turns red and the button stays grey. Beli always asks first (UiKit.confirm, Batal left / Setuju right);
-- so does Jual Semua. Jual of one item is a deliberate pick (item + number) and goes straight through.
-- Buttons only send requests; prices, levels and stock are re-checked on the server.
--
-- UI CONTRACT: ScreenGui "ShopPanel" (UiKit.panel). The title is the NPC's name.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Trade = require(ReplicatedStorage.Shared.Modules.Trade)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local ShopController = {}

local TABS_HEIGHT = 34
local LIST_TOP_PLAIN = 40 -- list top when there are no tabs (UiKit.panel default)
local LIST_TOP_TABS = LIST_TOP_PLAIN + TABS_HEIGHT + 6

local panel: UiKit.Panel
local tabs: UiKit.Tabs
local sellAllButton: TextButton
local currentNpc: string? = nil
local tab = "buy" -- "buy" | "sell"
local qtyBuy: { [string]: number } = {} -- picked amounts, kept across rebuilds (reset when a shop opens)
local qtySell: { [string]: number } = {}

local function level(): number
	local value = player:GetAttribute("Level")
	return if typeof(value) == "number" then value else 1
end

local function money(): number
	local value = player:GetAttribute("Koin")
	return if typeof(value) == "number" then value else 0
end

local function koin(n: number): string
	return Locale.t("ui.koin", { n = Locale.formatNumber(n) })
end

-- "10 Bambu + 15 Batu" untuk biaya bahan (Bab 6.3 / 17.5). nil = tanpa bahan.
local function matsText(mats: { { id: string, count: number } }?): string?
	if not mats or #mats == 0 then
		return nil
	end
	local parts = {}
	for _, mat in mats do
		table.insert(parts, `{mat.count} {Locale.t(`item.{mat.id}`)}`)
	end
	return table.concat(parts, " + ")
end

-- Returns (current tier, detail text) for an upgrade.
local function upgradeInfo(upgradeId: string, snapshot: any): (number, string)
	if upgradeId == "pond" then
		local tier = snapshot.pondTier
		local nextCap = Fishing.POND.CAPS[tier + 2]
		return tier, Locale.t("upgrade.pond.detail", { from = Fishing.POND.CAPS[tier + 1], to = nextCap or "-" })
	end
end

local UPGRADE_ICON = { pond = "kolam" }

-- Asks "buy this?" with the total; Setuju sends the purchase. `amount` nil = a one-off purchase (rod, upgrade).
local function confirmBuy(npcId: string, kind: string, id: string, itemName: string, unitPrice: number, amount: number?)
	local count = amount or 1
	local total = unitPrice * count
	UiKit.confirm({
		title = Locale.t("confirm.buy_title"),
		body = if amount then Locale.t("confirm.buy_body", { item = itemName, n = count }) else itemName,
		totalText = koin(total),
		totalRed = total > money(),
		canConfirm = total <= money(),
		onConfirm = function()
			Net.Send("ShopBuy", npcId, kind, id, amount)
		end,
	})
end

-- Names (comma separated) of what unfinished orders still need and "Jual Semua" would sell away.
local function neededByOrders(snapshot: any, sellable: { string }): string
	local orders = snapshot.orders
	local names: { string } = {}
	local seen: { [string]: boolean } = {}
	local function check(entry: any)
		if typeof(entry) ~= "table" or entry.done or typeof(entry.items) ~= "table" then
			return
		end
		for _, need in entry.items do
			local base = need.item
			for _, itemId in sellable do
				if (itemId == base or itemId:match("^(.+)@%a$") == base) and not seen[base] then
					seen[base] = true
					local key = if Crops.byId[base] then `crop.{base}` else `fish.{base}`
					table.insert(names, Locale.t(key))
				end
			end
		end
	end
	if orders then
		for _, entry in orders.daily or {} do
			check(entry)
		end
		check(orders.weekly)
	end
	return table.concat(names, ", ")
end

-- Everything this NPC would buy from the bag right now.
local function sellableIds(npc: Npcs.Npc, snapshot: any): { string }
	local ids = {}
	for itemId in snapshot.items do
		local info = Items.info(itemId)
		if info and Trade.buyPrice(npc, info) then
			table.insert(ids, itemId)
		end
	end
	return Items.sortIds(ids)
end

local function renderBuy(npc: Npcs.Npc, snapshot: any, nextOrder: () -> number)
	local npcId = npc.id
	local sells = npc.sells
	local items = snapshot.items
	local playerLevel = level()
	local list = panel.list
	local anything = false

	-- Seeds (Pak Udin). Bibit Unggul DIHAPUS (Bab 29).
	local function seedSection(headerKey: string, itemPrefix: string, kind: string)
		UiKit.header(list, Locale.t(headerKey), nextOrder())
		for _, crop in Crops.list do
			if crop.unlockLevel <= playerLevel + 5 then -- show only the next few locked crops
				anything = true
				local unlocked = playerLevel >= crop.unlockLevel
				local itemId = itemPrefix .. crop.id
				local unit = Trade.seedPrice(crop)
				local name = Locale.t(`crop.{crop.id}`)
				UiKit.tradeRow(list, nextOrder(), {
					name = name,
					sub = `{Locale.t("shop.unit_price", { price = koin(unit) })}  ·  {Locale.t("ui.owned", { n = items[itemId] or 0 })}`,
					thumbKey = itemId,
					placeholderIcon = "bibit",
					unitPrice = unit,
					maxQty = if unlocked then Shop.MAX_AMOUNT else 0,
					pickQty = true,
					qty = qtyBuy[itemId],
					money = money(),
					actionText = Locale.t("ui.buy"),
					disabledText = Locale.t("ui.locked", { level = crop.unlockLevel }),
					onQty = function(n)
						qtyBuy[itemId] = n
					end,
					onAction = function(n)
						confirmBuy(npcId, kind, crop.id, name, unit, n)
					end,
				})
			end
		end
	end
	if sells.seeds then
		seedSection("shop.section.seeds", "seed_", "seed")
	end

	-- Fish (Kak Fajar)
	if sells.fish then
		UiKit.header(list, Locale.t("shop.section.fish"), nextOrder())
		for _, fish in FishConfig.list do
			if Npcs.FISH_FOR_SALE[fish.rarity] then
				anything = true
				local itemId = `{fish.id}@S`
				local unit = Trade.fishPrice(fish.sellPrice)
				local name = Locale.t(`fish.{fish.id}`)
				UiKit.tradeRow(list, nextOrder(), {
					name = name,
					sub = `{Locale.t("shop.unit_price", { price = koin(unit) })}  ·  {Locale.t("ui.owned", { n = items[itemId] or 0 })}`,
					thumbKey = itemId,
					placeholderIcon = "ikan",
					unitPrice = unit,
					maxQty = Shop.MAX_AMOUNT,
					pickQty = true,
					qty = qtyBuy[itemId],
					money = money(),
					actionText = Locale.t("ui.buy"),
					onQty = function(n)
						qtyBuy[itemId] = n
					end,
					onAction = function(n)
						confirmBuy(npcId, "fish", fish.id, name, unit, n)
					end,
				})
			end
		end
	end

	-- Alat Kebun (Bab 17.5): Koin + bahan (bahan dari Nambang, P2-1); locked until its level.
	if sells.tools then
		UiKit.header(list, Locale.t("shop.section.tools"), nextOrder())
		for toolId, tool in Farm.TOOLS do
			anything = true
			local name = Locale.t(`tool.{toolId}`)
			if snapshot.tools and snapshot.tools[toolId] == true then
				UiKit.row(list, nextOrder(), name, Locale.t("tool.owned"), nil, false)
			else
				local unlocked = playerLevel >= tool.unlockLevel
				UiKit.tradeRow(list, nextOrder(), {
					name = name,
					sub = matsText(tool.mats),
					thumbKey = toolId,
					placeholderIcon = "pancing",
					accent = UiKit.CAT.tool,
					unitPrice = tool.price,
					maxQty = if unlocked then 1 else 0,
					pickQty = false,
					money = money(),
					actionText = Locale.t("ui.buy"),
					disabledText = Locale.t("ui.locked", { level = tool.unlockLevel }),
					onAction = function()
						confirmBuy(npcId, "tool", toolId, name, tool.price, nil)
					end,
				})
			end
		end
	end

	-- Rods and bait (Kak Fajar)
	if sells.rods then
		UiKit.header(list, Locale.t("shop.section.rods"), nextOrder())
		for _, rod in Fishing.rodList do
			anything = true
			local name = Locale.t(`rod.{rod.id}`)
			if snapshot.ownedRods[rod.id] == true then
				local equipped = snapshot.rod == rod.id
				UiKit.tradeRow(list, nextOrder(), {
					name = name,
					thumbKey = rod.id,
					placeholderIcon = "pancing",
						accent = UiKit.CAT.tool,
					maxQty = if equipped then 0 else 1,
					pickQty = false,
					actionText = Locale.t("ui.equip"),
					disabledText = Locale.t("ui.equipped"),
					onAction = function()
						Net.Send("ShopEquipRod", rod.id)
					end,
				})
			else
				local unlocked = playerLevel >= rod.unlockLevel
				UiKit.tradeRow(list, nextOrder(), {
					name = `{name} ({rod.box}%)`,
					sub = matsText(rod.mats),
					thumbKey = rod.id,
					placeholderIcon = "pancing",
						accent = UiKit.CAT.tool,
					unitPrice = rod.price,
					maxQty = if unlocked then 1 else 0,
					pickQty = false,
					money = money(),
					actionText = Locale.t("ui.buy"),
					disabledText = Locale.t("ui.locked", { level = rod.unlockLevel }),
					onAction = function()
						confirmBuy(npcId, "rod", rod.id, name, rod.price, nil)
					end,
				})
			end
		end
	end
	-- Umpan (Bab 6.3): 4 umpan, Udang Kecil Lv 6.
	if sells.bait then
		UiKit.header(list, Locale.t("shop.section.bait"), nextOrder())
		for _, bait in Fishing.BAITS do
			anything = true
			local baitId = bait.id
			local name = Locale.t(`item.{baitId}`)
			local unlocked = bait.unlockLevel == nil or playerLevel >= bait.unlockLevel
			UiKit.tradeRow(list, nextOrder(), {
				name = name,
				sub = `{Locale.t("shop.unit_price", { price = koin(bait.price) })}  ·  {Locale.t("ui.owned", { n = items[baitId] or 0 })}`,
				thumbKey = baitId,
				placeholderIcon = "pancing",
							accent = UiKit.CAT.tool,
				unitPrice = bait.price,
				maxQty = if unlocked then Shop.MAX_AMOUNT else 0,
				pickQty = true,
				qty = qtyBuy[baitId],
				money = money(),
				actionText = Locale.t("ui.buy"),
				disabledText = bait.unlockLevel and Locale.t("ui.locked", { level = bait.unlockLevel }) or nil,
				onQty = function(n)
					qtyBuy[baitId] = n
				end,
				onAction = function(n)
					confirmBuy(npcId, "bait", baitId, name, bait.price, n)
				end,
			})
		end
	end

	-- Upgrades (Pak Udin)
	if sells.upgrades then
		UiKit.header(list, Locale.t("shop.section.upgrades"), nextOrder())
		-- R3 17.7: one card per upgrade, its tiers as progress dots, and a buy button with the next tier's price.
		for _, upgradeId in Shop.UPGRADE_ORDER do
			anything = true
			local config = Shop.UPGRADES[upgradeId]
			local upgradeTier, detail = upgradeInfo(upgradeId, snapshot)
			local cost = config.costs[upgradeTier + 1]
			local name = Locale.t(`upgrade.{upgradeId}`)
			local unlocked = playerLevel >= config.unlockLevel
			local onClick: (() -> ())? = nil
			local buttonText = Locale.t("ui.max")
			local price = Locale.t("ui.max")
			if cost then
				local unit: number = cost
				price = koin(unit)
				buttonText = if unlocked then Locale.t("ui.buy") else Locale.t("ui.locked", { level = config.unlockLevel })
				onClick = function()
					confirmBuy(npcId, "upgrade", upgradeId, name, unit, nil)
				end
			end
			UiKit.productCard(list, nextOrder(), {
				title = name,
				sub = detail,
				price = price,
				buttonText = buttonText,
				enabled = cost ~= nil and unlocked,
				onClick = onClick,
				progress = { count = #config.costs, filled = upgradeTier },
				thumbKey = `upgrade_{upgradeId}`,
				placeholderIcon = UPGRADE_ICON[upgradeId],
			})
		end
	end

	if not anything then
		UiKit.header(list, Locale.t("shop.empty_buy"), nextOrder())
	end
end

local function renderSell(npc: Npcs.Npc, snapshot: any, nextOrder: () -> number)
	local npcId = npc.id
	local list = panel.list
	if npc.buys.crop then
		-- The percentage comes from the NPC's own config (Pak Udin 100%, Bang Jali 90%), never a fixed text.
		local pct = math.floor(npc.buys.crop * 100 + 0.5)
		UiKit.header(list, Locale.t("sell.overflow_info", { pct = pct }), nextOrder())
	end
	local ids = sellableIds(npc, snapshot)
	for _, itemId in ids do
		local info = Items.info(itemId) :: Items.ItemInfo
		local unit = Trade.buyPrice(npc, info) :: number
		local count = snapshot.items[itemId]
		local name = Items.displayName(info)
		local maxQty = count
		local sub = `{Locale.t("shop.unit_price", { price = koin(unit) })}  ·  {Locale.t("ui.owned", { n = count })}`
		local disabledText: string? = nil
		maxQty = math.min(maxQty, Shop.MAX_AMOUNT)
		UiKit.tradeRow(list, nextOrder(), {
			name = name,
			sub = sub,
			thumbKey = itemId,
			placeholderIcon = if info.kind == "fish" then "ikan" elseif info.kind == "crop" then "bibit" else "pancing",
			accent = if info.kind == "fish" then UiKit.CAT.fish elseif info.kind == "crop" then UiKit.CAT.crop else UiKit.CAT.tool,
			unitPrice = unit,
			maxQty = maxQty,
			pickQty = true,
			qty = qtySell[itemId],
			money = nil,
			actionText = Locale.t("ui.sell"),
			disabledText = disabledText,
			onQty = function(n)
				qtySell[itemId] = n
			end,
			onAction = function(n)
				Net.Send("Sell", npcId, itemId, n)
			end,
		})
	end
	if #ids == 0 then
		UiKit.header(list, Locale.t("shop.sell_none"), nextOrder())
	end
end

local function render()
	if not panel.gui.Enabled or not currentNpc then
		return
	end
	local npc = Npcs.byId[currentNpc]
	local snapshot = State.current :: any
	UiKit.clear(panel.list)
	if not npc or not snapshot then
		return
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	panel.title.Text = Locale.t(`npc.{npc.id}`)
	local canBuy = next(npc.sells) ~= nil
	local canSell = next(npc.buys) ~= nil

	-- Tabs only when the NPC does both; a one-sided NPC shows just that list.
	if not canBuy then
		tab = "sell"
	elseif not canSell then
		tab = "buy"
	end
	local showTabs = canBuy and canSell
	tabs.frame.Visible = showTabs
	tabs.select(tab)
	local top = if showTabs then LIST_TOP_TABS else LIST_TOP_PLAIN
	panel.list.Position = UDim2.fromOffset(26, top)
	panel.list.Size = UDim2.new(1, -52, 1, -(top + 22 + 38))

	panel.footerLabel.Text = Locale.t("shop.you_have", { price = koin(money()) })
	sellAllButton.Visible = canSell and tab == "sell" and #sellableIds(npc, snapshot) > 0

	if tab == "sell" then
		renderSell(npc, snapshot, nextOrder)
	else
		renderBuy(npc, snapshot, nextOrder)
	end
end

local function onSellAll()
	local npc = if currentNpc then Npcs.byId[currentNpc] else nil
	local snapshot = State.current :: any
	if not npc or not snapshot then
		return
	end
	local ids = sellableIds(npc, snapshot)
	if #ids == 0 then
		return
	end
	local total, kinds = 0, 0
	for _, itemId in ids do
		local info = Items.info(itemId) :: Items.ItemInfo
		local unit = Trade.buyPrice(npc, info) :: number
		local count = snapshot.items[itemId]
		if count > 0 then
			total += unit * count
			kinds += 1
		end
	end
	if kinds == 0 then
		return
	end
	local npcId = npc.id
	-- Stage 1: one tap sells. A confirm only appears when an open order still needs one of these items.
	local needed = neededByOrders(snapshot, ids)
	if needed == "" then
		Net.Send("Sell", npcId, "all")
		return
	end
	local body = Locale.t("confirm.sell_all_body", { n = kinds }) .. "\n" .. Locale.t("confirm.sell_all_orders", { items = needed })
	UiKit.confirm({
		title = Locale.t("confirm.sell_all_title"),
		body = body,
		totalText = koin(total),
		onConfirm = function()
			Net.Send("Sell", npcId, "all")
		end,
	})
end

function ShopController.Open(npcId: string)
	currentNpc = npcId
	table.clear(qtyBuy)
	table.clear(qtySell)
	-- Start where the player most likely wants to be: selling when there is something to sell here, else buying.
	local npc = Npcs.byId[npcId]
	local snapshot = State.current :: any
	tab = "buy"
	if npc and snapshot and next(npc.buys) ~= nil and #sellableIds(npc, snapshot) > 0 then
		tab = "sell"
	end
	panel.gui.Enabled = true
	render()
end

function ShopController.Close()
	currentNpc = nil
	UiKit.closeConfirm()
	panel.gui.Enabled = false
end

-- The NPC whose shop is open (the dialogue controller closes it when you walk away).
function ShopController.CurrentNpc(): string?
	return if panel.gui.Enabled then currentNpc else nil
end

function ShopController.Init()
	panel = UiKit.panel("ShopPanel", Locale.t("ui.shop"), ShopController.Close)

	tabs = UiKit.tabs(panel.gui:FindFirstChild("Panel") :: Instance, {
		{ id = "buy", text = Locale.t("shop.tab.buy") },
		{ id = "sell", text = Locale.t("shop.tab.sell") },
	}, "buy", function(id)
		tab = id
		render()
	end)
	tabs.frame.Position = UDim2.fromOffset(26, LIST_TOP_PLAIN)
	tabs.frame.Size = UDim2.new(1, -52, 0, TABS_HEIGHT)
	tabs.frame.Visible = false

	sellAllButton = UiKit.button(panel.footer, "SellAll", Locale.t("ui.sell_all"))
	sellAllButton.AnchorPoint = Vector2.new(1, 0)
	sellAllButton.Position = UDim2.fromScale(1, 0)
	sellAllButton.Size = UDim2.new(0.4, 0, 1, 0)
	sellAllButton.TextSize = 15
	sellAllButton.Visible = false
	sellAllButton.Activated:Connect(onSellAll)
end

function ShopController.Start()
	State.Changed:Connect(render)
	player:GetAttributeChangedSignal("Koin"):Connect(render)
	player:GetAttributeChangedSignal("Level"):Connect(render)
end

return ShopController
