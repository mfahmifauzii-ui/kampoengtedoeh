--!strict
-- Robux store (HUD "StoreButton" / placeholder "Toko"). Opens ONLY when the player taps it:
-- no popups, no timers, no fake urgency. Prices come from Roblox when the ids are set,
-- otherwise the draft price from config is shown.
-- R3 17.6: one panel with side tabs (Paket, Koin, Bunga, Hias) and a product card per item.
-- Hias = the decor pass and Langsung Panen (instant grow). Id 0 = "Belum tersedia" and never prompted.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local StoreController = {}

local TABS = {
	{ id = "passes", text = "store.tab.passes" },
	{ id = "bunga", text = "store.tab.bunga" },
	{ id = "hias", text = "store.tab.hias" },
}
local SIDE_WIDTH = 116

local panel: UiKit.Panel
local selected = "passes"
local livePrices: { [string]: number } = {} -- "pass:<id>" / "product:<id>" -> Robux
local sideButtons: { [string]: TextButton } = {}
local sideFrame: Frame? = nil

local function price(kind: string, id: number, draft: number): string
	local live = livePrices[`{kind}:{id}`]
	return Locale.t("store.price", { n = live or draft })
end

local function fetchPrices()
	for _, pass in Monetization.PASSES do
		if pass.id > 0 then
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, pass.id, Enum.InfoType.GamePass)
			if ok and info and info.PriceInRobux then
				livePrices[`pass:{pass.id}`] = info.PriceInRobux
			end
		end
	end
	for _, product in Monetization.PRODUCTS do
		if product.id > 0 then
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, product.id, Enum.InfoType.Product)
			if ok and info and info.PriceInRobux then
				livePrices[`product:{product.id}`] = info.PriceInRobux
			end
		end
	end
end

-- The side column: one tab per group, the chosen one is the green plank (UiKit.tabs look, stacked vertically).
local function renderSide(sideFrame: Frame)
	for index, def in TABS do
		local on = def.id == selected
		local button = sideButtons[def.id]
		if not button then
			-- GUI doc 4.4: a tab is a standard touch target (32 px), with 8 px between tabs.
			button = UiKit.button(sideFrame, `Side_{def.id}`, Locale.t(def.text), UiKit.BUTTON_MUTED)
			button.Size = UDim2.new(1, 0, 0, UiKit.TOUCH)
			button.Position = UDim2.fromOffset(0, (index - 1) * (UiKit.TOUCH + 8))
			button.TextSize = UiKit.TEXT_SMALL
			button.Activated:Connect(function()
				selected = def.id
				StoreController.Render()
			end)
			sideButtons[def.id] = button
		end
		-- Bug 5: readable in both states. The chosen tab is the green plank with cream text; the others are tan with dark ink
		-- (no transparency, so nothing looks faded or disabled).
		button.BackgroundColor3 = if on then UiKit.BUTTON else UiKit.BUTTON_MUTED
		button.TextColor3 = if on then UiKit.CREAM else UiKit.TEXT
		button.TextTransparency = 0
	end
end

-- Bug 5: the panel keeps the UiKit sheet size (88 % x 86 % of the screen, max 600 x 400). The old fit-to-content measured
-- the list before it was laid out and shrank the sheet to ~100 px, so the rows were out of view. Rows scroll inside the sheet.

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	if sideFrame then
		renderSide(sideFrame)
	end
	local snapshot = State.current :: any
	local passes = snapshot and snapshot.passes or {}
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	for _, pass in Monetization.PASSES do
		if selected == "passes" then
			local owned = passes[pass.key] == true
			local def = pass
			UiKit.productCard(panel.list, nextOrder(), {
				title = Locale.t(`store.pass.{pass.key}`),
				sub = Locale.t(`store.pass.{pass.key}.desc`),
				price = if owned then "" else price("pass", pass.id, pass.priceDraft),
				buttonText = if owned then Locale.t("store.owned") elseif pass.id > 0 then Locale.t("ui.buy") else Locale.t("store.hint_unavailable"),
				enabled = pass.id > 0 and not owned,
				onClick = function()
					Net.Send("StoreBuy", "pass", def.key)
				end,
			})
		end
	end

	for _, product in Monetization.PRODUCTS do
		local inTab = if product.kind == "bunga" then selected == "bunga"
			else selected == "hias"
		if inTab then
			local sub: string? = nil
			local def = product
			UiKit.productCard(panel.list, nextOrder(), {
				title = Locale.t(`store.product.{product.kind}`, { n = Locale.formatNumber(product.amount) }),
				sub = sub,
				price = price("product", product.id, product.priceDraft),
				buttonText = if product.id > 0 then Locale.t("ui.buy") else Locale.t("store.hint_unavailable"),
				enabled = product.id > 0,
				onClick = function()
					Net.Send("StoreBuy", "product", def.key)
				end,
			})
		end
	end

	panel.footerLabel.Text = "" -- Premium gives no Koin boost (Bab 19, T-32): no footer line
end

function StoreController.Render()
	render()
end

function StoreController.Open()
	panel.gui.Enabled = true
	render()
end

function StoreController.Init()
	panel = UiKit.panel("StorePanel", Locale.t("ui.robux_store"), function()
		panel.gui.Enabled = false
	end)
	panel.footerLabel.Size = UDim2.fromScale(1, 1)
	panel.footerLabel.TextWrapped = true
	panel.footerLabel.TextSize = 13

	-- Make room on the left for the side tabs: the list starts after the column.
	panel.list.Position = UDim2.fromOffset(32 + SIDE_WIDTH + 12, 52)
	panel.list.Size = UDim2.new(1, -(64 + SIDE_WIDTH + 12), 1, -(52 + 26 + 56))
	local frame = panel.gui:FindFirstChild("Panel")
	if frame and frame:IsA("Frame") then
		local side = Instance.new("Frame")
		side.Name = "SideTabs"
		side.BackgroundTransparency = 1
		side.Position = UDim2.fromOffset(32, 52)
		side.Size = UDim2.new(0, SIDE_WIDTH, 1, -(52 + 26 + 56))
		side.Parent = frame
		sideFrame = side
		renderSide(side)
	end
end

function StoreController.Start()
	State.Changed:Connect(render)
	task.spawn(fetchPrices)
	task.spawn(UiKit.hudButton, "StoreButton", Locale.t("ui.robux_store"), 6, function()
		if panel.gui.Enabled then
			panel.gui.Enabled = false
		else
			StoreController.Open()
		end
	end)
end

return StoreController
