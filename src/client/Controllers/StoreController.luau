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
	{ id = "koin", text = "store.tab.koin" },
	{ id = "bunga", text = "store.tab.bunga" },
	{ id = "hias", text = "store.tab.hias" },
}
local PASS_TABS: { [string]: string } = { backpack = "passes", offline = "passes", plots = "passes", decor = "hias" }
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
			button = UiKit.button(sideFrame, `Side_{def.id}`, Locale.t(def.text), UiKit.BUTTON_MUTED)
			button.Size = UDim2.new(1, 0, 0, 34) -- small side tabs (was 58 px)
			button.Position = UDim2.fromOffset(0, (index - 1) * 40)
			button.TextSize = 13
			button.Activated:Connect(function()
				selected = def.id
				StoreController.Render()
			end)
			sideButtons[def.id] = button
		end
		button.BackgroundColor3 = if on then UiKit.BUTTON else UiKit.BUTTON_MUTED
		button.TextTransparency = if on then 0 else 0.25
	end
end

-- The panel hugs its content: the height is the header + the rows + the footer, never more than 86 % of the screen (no empty
-- space under the last row). Measured after the rows are laid out (one frame later).
local TOP_SPACE = 52 -- the title ribbon and the first row
local BOTTOM_SPACE = 52 -- the footer line and the rounded bottom edge
local function fitHeight()
	task.defer(function()
		local frame = panel.gui:FindFirstChild("Panel")
		local layout = panel.list:FindFirstChildOfClass("UIListLayout")
		if not (frame and frame:IsA("Frame") and layout) then
			return
		end
		local content = layout.AbsoluteContentSize.Y
		local view = (Workspace.CurrentCamera :: Camera).ViewportSize
		local height = math.min(TOP_SPACE + content + BOTTOM_SPACE, view.Y * 0.86)
		frame.Size = UDim2.new(0.88, 0, 0, height)
	end)
end

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
		if (PASS_TABS[pass.key] or "passes") == selected then
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
			elseif product.kind == "koin" then selected == "koin"
			else selected == "hias"
		if inTab then
			local sub: string? = nil
			if product.kind == "instant_grow" and snapshot and snapshot.instantGrow then
				sub = Locale.t("store.instant_info", {
					tokens = snapshot.instantGrow.tokens,
					used = snapshot.instantGrow.usedToday,
					limit = Monetization.INSTANT_GROW_DAILY_LIMIT,
				})
			end
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

	panel.footerLabel.Text = if snapshot and snapshot.premium then Locale.t("store.premium") else ""
	fitHeight()
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
