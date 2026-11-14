--!strict
-- Robux store (HUD "StoreButton" / placeholder "Toko"). Opens ONLY when the player taps it:
-- no popups, no timers, no fake urgency. Prices come from Roblox when the ids are set,
-- otherwise the draft price from config is shown.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local StoreController = {}

local panel: UiKit.Panel
local livePrices: { [string]: number } = {} -- "pass:<id>" / "product:<id>" -> Robux

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

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	local passes = snapshot and snapshot.passes or {}
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	UiKit.header(panel.list, Locale.t("store.section.passes"), nextOrder())
	for _, pass in Monetization.PASSES do
		local isOwned = passes[pass.key] == true
		UiKit.row(panel.list, nextOrder(), Locale.t(`store.pass.{pass.key}`), Locale.t(`store.pass.{pass.key}.desc`),
			if isOwned then Locale.t("store.owned") else price("pass", pass.id, pass.priceDraft),
			not isOwned, function()
				Net.Send("StoreBuy", "pass", pass.key)
			end)
	end

	local sections = { { kind = "bunga", title = "store.section.bunga" }, { kind = "koin", title = "store.section.koin" }, { kind = "instant_grow", title = "store.section.grow" } }
	for _, section in sections do
		UiKit.header(panel.list, Locale.t(section.title), nextOrder())
		for _, product in Monetization.PRODUCTS do
			if product.kind == section.kind then
				local name = Locale.t(`store.product.{product.kind}`, { n = Locale.formatNumber(product.amount) })
				local sub: string? = nil
				if product.kind == "instant_grow" and snapshot and snapshot.instantGrow then
					sub = Locale.t("store.instant_info", {
						tokens = snapshot.instantGrow.tokens,
						used = snapshot.instantGrow.usedToday,
						limit = Monetization.INSTANT_GROW_DAILY_LIMIT,
					})
				end
				UiKit.row(panel.list, nextOrder(), name, sub, price("product", product.id, product.priceDraft), true, function()
					Net.Send("StoreBuy", "product", product.key)
				end)
			end
		end
	end

	panel.footerLabel.Text = if snapshot and snapshot.premium then Locale.t("store.premium") else ""
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
