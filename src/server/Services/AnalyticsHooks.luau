--!strict
-- Roblox AnalyticsService hooks (Creator Dashboard > Analytics):
--   * Economy events for every Koin/Bunga change (sources vs sinks, by transaction type)
--   * Onboarding funnel: first-session steps, each logged once per player
-- All calls are pcall'd; analytics must never break gameplay.

local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local FUNNEL = { "joined", "first_plant", "first_harvest", "first_sell", "first_catch", "first_order", "first_decor" }

local CURRENCY_NAME = { koin = "Koin", bunga = "Bunga" }

-- Reason prefix (see EconomyService callers) -> Roblox transaction type.
local TRANSACTION: { [string]: Enum.AnalyticsEconomyTransactionType } = {
	iap = Enum.AnalyticsEconomyTransactionType.IAP,
	seed = Enum.AnalyticsEconomyTransactionType.Shop,
	fish = Enum.AnalyticsEconomyTransactionType.Shop,
	rod = Enum.AnalyticsEconomyTransactionType.Shop,
	bait = Enum.AnalyticsEconomyTransactionType.Shop,
	upgrade = Enum.AnalyticsEconomyTransactionType.Shop,
	decor = Enum.AnalyticsEconomyTransactionType.Shop,
	visit = Enum.AnalyticsEconomyTransactionType.TimedReward,
}

local AnalyticsHooks = {}

local stepIndex: { [string]: number } = {}
for index, name in FUNNEL do
	stepIndex[name] = index
end

function AnalyticsHooks.Step(player: Player, name: string)
	local index = stepIndex[name]
	local data = DataService.Get(player)
	if not index or not data or data.onboarding[name] then
		return
	end
	data.onboarding[name] = true
	pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, index, name)
end

local function onEconomyChanged(player: Player, currency: string, delta: number, reason: string)
	local prefix = reason:match("^(%a+)") or reason
	if prefix == "dev" or RunService:IsStudio() then
		return
	end
	local data = DataService.Get(player) :: any
	if not data then
		return
	end
	local transaction = TRANSACTION[prefix] or Enum.AnalyticsEconomyTransactionType.Gameplay
	pcall(
		AnalyticsService.LogEconomyEvent,
		AnalyticsService,
		player,
		if delta > 0 then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink,
		CURRENCY_NAME[currency] or currency,
		math.abs(delta),
		data[currency],
		transaction.Name,
		reason
	)
end

function AnalyticsHooks.Init()
	EconomyService.Changed:Connect(function(player: Player, currency: string, delta: number, reason: string)
		onEconomyChanged(player, currency, delta, reason)
		local prefix = reason:match("^(%a+)")
		-- (first_plant is logged by FarmService when a seed is actually planted: seeds are bought earlier now)
		if prefix == "sell" then
			AnalyticsHooks.Step(player, "first_sell")
		elseif prefix == "decor" then
			AnalyticsHooks.Step(player, "first_decor")
		end
	end)
	DataService.Loaded:Connect(function(player: Player)
		AnalyticsHooks.Step(player, "joined")
	end)
end

return AnalyticsHooks
