--!strict
-- NPC shop panel: opened by the dialogue's [Jual / Beli] button. What it shows comes from the NPC's config
-- (Config/Npcs): what it sells (seeds, rods, bait, upgrades, fish) and what it buys from you.
-- Kedekatan gives discounts on what you buy. Haggle NPCs (Bang Tarno) add a "Tawar" button to every item you can
-- sell: pick how much above the base price to ask; the panel shows your real chance.
-- Buttons only send requests; prices, levels, chances and stock are re-checked on the server.
--
-- UI CONTRACT: ScreenGui "ShopPanel" (UiKit.panel). The title is the NPC's name.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Blueprints = require(ReplicatedStorage.Shared.Config.Blueprints)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Decor = require(ReplicatedStorage.Shared.Config.Decor)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.Inventory)
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

local panel: UiKit.Panel
local sellAllButton: TextButton
local currentNpc: string? = nil
local amount = 1 -- how many seeds / bait / fish one tap buys
local haggleItem: string? = nil -- the stack being bargained over (haggle NPCs)

local function level(): number
	local value = player:GetAttribute("Level")
	return if typeof(value) == "number" then value else 1
end

local function koin(n: number): string
	return Locale.t("ui.koin", { n = Locale.formatNumber(n) })
end

-- Returns (current tier, detail text) for an upgrade.
local function upgradeInfo(upgradeId: string, snapshot: any): (number, string)
	if upgradeId == "backpack" then
		local tier = snapshot.backpackTier
		local nextSlots = InventoryConfig.SLOTS[tier + 2]
		return tier, Locale.t("upgrade.backpack.detail", { from = InventoryConfig.SLOTS[tier + 1], to = nextSlots or "-" })
	elseif upgradeId == "pond" then
		local tier = snapshot.pondTier
		local nextCap = Fishing.POND.CAPS[tier + 2]
		return tier, Locale.t("upgrade.pond.detail", { from = Fishing.POND.CAPS[tier + 1], to = nextCap or "-" })
	else
		local tier = snapshot.farmExpansions
		local tiles = Farm.START_TILES + tier * Farm.EXPANSION_TILES
		return tier, Locale.t("upgrade.farm.detail", { from = tiles, to = tiles + Farm.EXPANSION_TILES })
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
	local npcId = npc.id
	local items = snapshot.items
	local playerLevel = level()
	local record = if snapshot.npc then snapshot.npc[npcId] else nil
	local tier = Npcs.tierOf(if record then record.affinity else 0)
	local tawar = if snapshot.skills and snapshot.skills.tawar then snapshot.skills.tawar else { level = 1, xp = 0 }
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	-- Friendship discount on every price you pay (the server applies the same).
	local function pay(price: number): number
		return Trade.discount(price, tier)
	end

	panel.title.Text = Locale.t(`npc.{npcId}`)
	local sells = npc.sells
	local buysSomething = next(npc.buys) ~= nil
	sellAllButton.Visible = buysSomething and haggleItem == nil
	panel.footerLabel.Text = if npc.haggle
		then `{koin(player:GetAttribute("Koin") :: number? or 0)}  ·  {Locale.t("skill.tawar")} Lv {tawar.level}`
		else koin(player:GetAttribute("Koin") :: number? or 0)

	-- Bargaining view: the whole stack of one item, one row per ask.
	local stack = haggleItem
	if stack then
		local info = Items.info(stack)
		local base = if info then Trade.buyPrice(npc, info) else nil
		local count = items[stack]
		if not info or not base or not count then
			haggleItem = nil -- sold out: fall back to the normal list below
		else
			local paused = if record then math.ceil(record.pauseUntil - Workspace:GetServerTimeNow()) else 0
			UiKit.header(panel.list, Locale.t("haggle.header", { item = Items.displayName(info), n = count }), nextOrder())
			UiKit.row(panel.list, nextOrder(), Locale.t("haggle.base"), koin(base * count), Locale.t("ui.sell"), true, function()
				Net.Send("Sell", npcId, stack)
			end)
			if paused > 0 then
				UiKit.header(panel.list, Locale.t("haggle.pause_info", { n = paused }), nextOrder())
			end
			for _, offer in Npcs.HAGGLE.OFFERS do
				local minTier = offer.minTier or 1
				if tier < minTier then
					UiKit.row(panel.list, nextOrder(), `+{offer.pct}%`,
						Locale.t("haggle.locked", { tier = Locale.t(`npc.tier.{Npcs.TIERS[minTier].id}`) }),
						Locale.t("ui.haggle"), false)
				else
					local total = Trade.haggleTotal(base, count, info, offer.pct)
					local chance = Trade.haggleChance(offer.pct, tier, tawar.level)
					UiKit.row(panel.list, nextOrder(), `+{offer.pct}%  ·  {koin(total)}`,
						Locale.t("haggle.chance", { n = chance }), Locale.t("ui.haggle"), paused <= 0, function()
							Net.Send("Haggle", npcId, stack, offer.pct)
						end)
				end
			end
			UiKit.row(panel.list, nextOrder(), Locale.t("haggle.cancel"), nil, Locale.t("ui.back"), true, function()
				haggleItem = nil
				render()
			end)
			return
		end
	end

	-- How many to buy per tap (seeds, bait, fish).
	if sells.seeds or sells.seedsUnggul or sells.bait or sells.fish then
		local row = Instance.new("Frame")
		row.Name = "AmountRow"
		row.LayoutOrder = nextOrder()
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -6, 0, 36)
		row.Parent = panel.list
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 6)
		layout.Parent = row
		for _, pack in Shop.PACKS do
			local button = UiKit.button(row, `Pack{pack}`, `×{pack}`, if amount == pack then UiKit.BUTTON else UiKit.BUTTON_MUTED)
			button.Size = UDim2.new(1 / #Shop.PACKS, -6, 1, 0)
			button.Activated:Connect(function()
				amount = pack
				render()
			end)
		end
	end

	-- Seeds (Pak Darmo) and faster seeds (Bu Wati)
	local function seedSection(headerKey: string, itemPrefix: string, kind: string, unggul: boolean)
		UiKit.header(panel.list, Locale.t(headerKey), nextOrder())
		for _, crop in Crops.list do
			if crop.unlockLevel <= playerLevel + 5 then -- show only the next few locked crops
				local unlocked = playerLevel >= crop.unlockLevel
				local owned = items[itemPrefix .. crop.id] or 0
				UiKit.row(panel.list, nextOrder(), Locale.t(`crop.{crop.id}`),
					`{koin(pay(Trade.seedPrice(crop, unggul)) * amount)}  ·  {Locale.t("ui.owned", { n = owned })}`,
					if unlocked then Locale.t("ui.buy") else Locale.t("ui.locked", { level = crop.unlockLevel }),
					unlocked, function()
						Net.Send("ShopBuy", npcId, kind, crop.id, amount)
					end)
			end
		end
	end
	if sells.seeds then
		seedSection("shop.section.seeds", "seed_", "seed", false)
	end
	if sells.seedsUnggul then
		seedSection("shop.section.seedsx", "seedx_", "seedx", true)
	end

	-- Fish (Mbok Minah)
	if sells.fish then
		UiKit.header(panel.list, Locale.t("shop.section.fish"), nextOrder())
		for _, fish in FishConfig.list do
			if Npcs.FISH_FOR_SALE[fish.rarity] then
				local owned = items[`{fish.id}@S`] or 0
				UiKit.row(panel.list, nextOrder(), Locale.t(`fish.{fish.id}`),
					`{koin(pay(Trade.fishPrice(fish.sellPrice)) * amount)}  ·  {Locale.t("ui.owned", { n = owned })}`,
					Locale.t("ui.buy"), true, function()
						Net.Send("ShopBuy", npcId, "fish", fish.id, amount)
					end)
			end
		end
	end

	-- Rods and bait (Mas Joko)
	if sells.rods then
		UiKit.header(panel.list, Locale.t("shop.section.rods"), nextOrder())
		for _, rod in Fishing.rodList do
			local name = Locale.t(`rod.{rod.id}`)
			if snapshot.ownedRods[rod.id] == true then
				local equipped = snapshot.rod == rod.id
				UiKit.row(panel.list, nextOrder(), name, nil, Locale.t(if equipped then "ui.equipped" else "ui.equip"), not equipped, function()
					Net.Send("ShopEquipRod", rod.id)
				end)
			else
				local unlocked = playerLevel >= rod.unlockLevel
				UiKit.row(panel.list, nextOrder(), name, koin(pay(rod.price)),
					if unlocked then Locale.t("ui.buy") else Locale.t("ui.locked", { level = rod.unlockLevel }),
					unlocked, function()
						Net.Send("ShopBuy", npcId, "rod", rod.id)
					end)
			end
		end
	end
	if sells.bait then
		UiKit.header(panel.list, Locale.t("shop.section.bait"), nextOrder())
		local baitId = Fishing.BAIT.id
		UiKit.row(panel.list, nextOrder(), Locale.t("shop.bait_pack", { item = Locale.t(`item.{baitId}`), n = amount }),
			`{koin(pay(Fishing.BAIT.price) * amount)}  ·  {Locale.t("ui.owned", { n = items[baitId] or 0 })}`,
			Locale.t("ui.buy"), true, function()
				Net.Send("ShopBuy", npcId, "bait", baitId, amount)
			end)
	end

	-- Upgrades (Pak Darmo)
	if sells.upgrades then
		UiKit.header(panel.list, Locale.t("shop.section.upgrades"), nextOrder())
		for _, upgradeId in Shop.UPGRADE_ORDER do
			local config = Shop.UPGRADES[upgradeId]
			local upgradeTier, detail = upgradeInfo(upgradeId, snapshot)
			local cost = config.costs[upgradeTier + 1]
			local name = Locale.t(`upgrade.{upgradeId}`)
			if not cost then
				UiKit.row(panel.list, nextOrder(), name, nil, Locale.t("ui.max"), false)
			else
				local unlocked = playerLevel >= config.unlockLevel
				UiKit.row(panel.list, nextOrder(), name, `{detail}  ·  {koin(pay(cost))}`,
					if unlocked then Locale.t("ui.buy") else Locale.t("ui.locked", { level = config.unlockLevel }),
					unlocked, function()
						Net.Send("ShopBuy", npcId, "upgrade", upgradeId)
					end)
			end
		end
	end

	-- Decor blueprints (Mbak Arsi): each unlocks buying a whole set of decor.
	if sells.blueprints then
		UiKit.header(panel.list, Locale.t("shop.section.blueprints"), nextOrder())
		local owned = snapshot.decorBlueprints or {}
		for _, blueprint in Blueprints.list do
			local names = {}
			for _, item in Decor.list do
				if item.blueprint == blueprint.id then
					table.insert(names, Locale.t(`decor.{item.id}`))
				end
			end
			local detail = Locale.t("blueprint.items", { items = table.concat(names, ", ") })
			local name = Locale.t(`blueprint.{blueprint.id}`)
			if owned[blueprint.id] == true then
				UiKit.row(panel.list, nextOrder(), name, detail, Locale.t("blueprint.owned"), false)
			else
				local unlocked = playerLevel >= blueprint.unlockLevel
				UiKit.row(panel.list, nextOrder(), name, `{koin(pay(blueprint.price))}  ·  {detail}`,
					if unlocked then Locale.t("ui.buy") else Locale.t("ui.locked", { level = blueprint.unlockLevel }),
					unlocked, function()
						Net.Send("ShopBuy", npcId, "blueprint", blueprint.id)
					end)
			end
		end
	end

	-- What this NPC buys from you
	if buysSomething then
		UiKit.header(panel.list, Locale.t("shop.section.sell"), nextOrder())
		local ids = {}
		for itemId in items do
			table.insert(ids, itemId)
		end
		Items.sortIds(ids)
		local shown = 0
		for _, itemId in ids do
			local info = Items.info(itemId)
			local unit = if info then Trade.buyPrice(npc, info) else nil
			if info and unit then
				shown += 1
				local count = items[itemId]
				UiKit.row(panel.list, nextOrder(), `{Items.displayName(info)}  ×{count}`, koin(unit * count), Locale.t("ui.sell"), true, function()
					Net.Send("Sell", npcId, itemId)
				end, if npc.haggle then Locale.t("ui.haggle") else nil, if npc.haggle then function()
					haggleItem = itemId
					render()
				end else nil)
			end
		end
		if shown == 0 then
			UiKit.header(panel.list, Locale.t("shop.sell_empty"), nextOrder())
		end
	end
end

function ShopController.Open(npcId: string)
	currentNpc = npcId
	haggleItem = nil
	panel.gui.Enabled = true
	render()
end

function ShopController.Close()
	currentNpc = nil
	haggleItem = nil
	panel.gui.Enabled = false
end

-- The NPC whose shop is open (the dialogue controller closes it when you walk away).
function ShopController.CurrentNpc(): string?
	return if panel.gui.Enabled then currentNpc else nil
end

function ShopController.Init()
	panel = UiKit.panel("ShopPanel", Locale.t("ui.shop"), ShopController.Close)
	sellAllButton = UiKit.button(panel.footer, "SellAll", Locale.t("ui.sell_all"))
	sellAllButton.AnchorPoint = Vector2.new(1, 0)
	sellAllButton.Position = UDim2.fromScale(1, 0)
	sellAllButton.Size = UDim2.new(0.45, 0, 1, 0)
	sellAllButton.Visible = false
	sellAllButton.Activated:Connect(function()
		if currentNpc then
			Net.Send("Sell", currentNpc, "all")
		end
	end)
end

function ShopController.Start()
	State.Changed:Connect(render)
	player:GetAttributeChangedSignal("Koin"):Connect(render)
	player:GetAttributeChangedSignal("Level"):Connect(render)
end

return ShopController
