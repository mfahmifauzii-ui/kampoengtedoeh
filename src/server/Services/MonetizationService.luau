--!strict
-- Game passes, developer products (ProcessReceipt), Premium perks.
-- Tidak ada Instant Panen (Bab 29). Instant Kolam pakai Bunga langsung (Bab 18.5, PondService.InstantCost).
--
-- Receipts follow ProfileStore's PurchaseId-cache pattern: grant + record the PurchaseId,
-- then only return PurchaseGranted once that PurchaseId is confirmed SAVED. A crash before
-- saving means Roblox retries the receipt later; the cache prevents granting twice.
--
-- Prompts are only ever opened by the player (store panel); the server re-checks first.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

type Product = Monetization.Product

local MonetizationService = {}
MonetizationService.PassChanged = Signal.new() -- (player, passKey, owned)
MonetizationService.Changed = Signal.new() -- (player) anything the client snapshot shows

local passByKey: { [string]: Monetization.Pass } = {}
local passById: { [number]: Monetization.Pass } = {}
for _, pass in Monetization.PASSES do
	passByKey[pass.key] = pass
	if pass.id > 0 then
		passById[pass.id] = pass
	end
end
local productByKey: { [string]: Product } = {}
local productById: { [number]: Product } = {}
for _, product in Monetization.PRODUCTS do
	productByKey[product.key] = product
	if product.id > 0 then
		productById[product.id] = product
	end
end

local owned: { [Player]: { [string]: boolean } } = {}

-- Passes -------------------------------------------------------------------------------

function MonetizationService.HasPass(player: Player, key: string): boolean
	local cache = owned[player]
	if cache and cache[key] ~= nil then
		return cache[key]
	end
	local data = DataService.Get(player)
	return data ~= nil and data.passes[key] == true
end

local function setPass(player: Player, key: string, has: boolean)
	local data = DataService.Get(player)
	local cache = owned[player] or {}
	owned[player] = cache
	local before = MonetizationService.HasPass(player, key)
	cache[key] = has
	if data then
		data.passes[key] = if has then true else nil
	end
	if before ~= has then
		MonetizationService.PassChanged:Fire(player, key, has)
	end
	MonetizationService.Changed:Fire(player)
end

local function checkPasses(player: Player)
	for _, pass in Monetization.PASSES do
		if pass.id > 0 then
			for _ = 1, 3 do
				local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
				if ok then
					setPass(player, pass.key, has)
					break
				end
				task.wait(2) -- API hiccup: keep the saved cache meanwhile
			end
		elseif MonetizationService.HasPass(player, pass.key) then
			MonetizationService.PassChanged:Fire(player, pass.key, true) -- Studio dev-granted
		end
	end
end

function MonetizationService.IsPremium(player: Player): boolean
	return player.MembershipType == Enum.MembershipType.Premium
end

-- Products / receipts ----------------------------------------------------------------------

local function grantProduct(player: Player, product: Product)
	EconomyService.Add(player, "bunga", product.amount, `iap:{product.key}`)
	MonetizationService.Changed:Fire(player)
	Net.Fire("Notify", player, "store.thanks")
end

local function purchaseIdCheckAsync(player: Player, profile: any, purchaseId: string, product: Product): Enum.ProductPurchaseDecision
	if not profile:IsActive() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local cache = profile.Data.purchaseIdCache
	if table.find(cache, purchaseId) == nil then
		local ok, err = pcall(grantProduct, player, product)
		if not ok then
			warn(`[Monetization] Grant failed {player.Name} {purchaseId}: {err}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		while #cache >= Monetization.PURCHASE_ID_CACHE_SIZE do
			table.remove(cache, 1)
		end
		table.insert(cache, purchaseId)
	end

	local function isSaved(): boolean
		local saved = profile.LastSavedData and profile.LastSavedData.purchaseIdCache
		return saved ~= nil and table.find(saved, purchaseId) ~= nil
	end
	if isSaved() then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	while profile:IsActive() do
		local lastSaved = profile.LastSavedData
		profile:Save()
		if profile.LastSavedData == lastSaved then
			profile.OnAfterSave:Wait()
		end
		if isSaved() then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		if profile:IsActive() then
			task.wait(10)
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productById[receipt.ProductId]
	if not player or not product then
		if not product then
			warn(`[Monetization] Unknown ProductId {receipt.ProductId}`)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = DataService.GetProfile(player)
	while profile == nil and player.Parent == Players do
		task.wait()
		profile = DataService.GetProfile(player)
	end
	if profile == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return purchaseIdCheckAsync(player, profile, receipt.PurchaseId, product)
end

-- Store requests (player-initiated) -------------------------------------------------------

local function onStoreBuy(player: Player, kind: any, key: any)
	if typeof(kind) ~= "string" or typeof(key) ~= "string" then
		return
	end
	if kind == "pass" then
		local pass = passByKey[key]
		if not pass or MonetizationService.HasPass(player, key) then
			return
		end
		if pass.id <= 0 then
			Net.Fire("Notify", player, "store.unavailable")
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
	elseif kind == "product" then
		local product = productByKey[key]
		local data = DataService.Get(player)
		if not product or not data then
			return
		end
		if product.id <= 0 then
			Net.Fire("Notify", player, "store.unavailable")
			return
		end
		MarketplaceService:PromptProductPurchase(player, product.id)
	end
end

function MonetizationService.Init()
	DataService.Loaded:Connect(function(player: Player)
		task.spawn(checkPasses, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = passById[passId]
		if purchased and pass then
			setPass(player, pass.key, true)
			Net.Fire("Notify", player, "store.thanks")
		end
	end)
	Net.On("StoreBuy", onStoreBuy, { rate = 1, burst = 3 })
end

-- Studio testing only (DevService) ------------------------------------------------------

function MonetizationService.DevTogglePass(player: Player, key: string)
	if passByKey[key] then
		setPass(player, key, not MonetizationService.HasPass(player, key))
	end
end

-- Runs the real receipt path with a fake PurchaseId (call twice with the same id to
-- verify it isn't granted twice).
function MonetizationService.DevReceipt(player: Player, key: string, purchaseId: string): string
	local product = productByKey[key]
	local profile = DataService.GetProfile(player)
	if not product or not profile then
		return "invalid"
	end
	return purchaseIdCheckAsync(player, profile, purchaseId, product).Name
end

return MonetizationService
