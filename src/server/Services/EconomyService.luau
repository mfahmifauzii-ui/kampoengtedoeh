--!strict
-- The only code allowed to change koin/bunga. Mirrors balances to player attributes
-- ("Koin", "Bunga") so the client HUD can read them without extra remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)

type Currency = Types.Currency

local ATTRIBUTE: { [Currency]: string } = {
	koin = "Koin",
	bunga = "Bunga",
}

local EconomyService = {}
EconomyService.Changed = Signal.new() -- (player, currency, delta, reason) — analytics hook point (Phase 8)

local function isValidAmount(amount: any): boolean
	return typeof(amount) == "number"
		and amount == amount -- not NaN
		and amount > 0
		and amount % 1 == 0
		and amount <= EconomyConfig.MAX_TRANSACTION
end

local function apply(player: Player, currency: Currency, delta: number, reason: string): boolean
	local data = DataService.Get(player) :: any
	if not data or ATTRIBUTE[currency] == nil then
		return false
	end

	local newValue = data[currency] + delta
	if newValue < 0 then
		return false
	end
	newValue = math.min(newValue, EconomyConfig.MAX_BALANCE)

	data[currency] = newValue
	player:SetAttribute(ATTRIBUTE[currency], newValue)
	EconomyService.Changed:Fire(player, currency, delta, reason)
	return true
end

function EconomyService.Get(player: Player, currency: Currency): number
	local data = DataService.Get(player) :: any
	return if data then data[currency] else 0
end

function EconomyService.CanAfford(player: Player, currency: Currency, amount: number): boolean
	return isValidAmount(amount) and EconomyService.Get(player, currency) >= amount
end

-- `reason` is a short tag for logs/analytics, e.g. "sell:kangkung", "order:daily".
function EconomyService.Add(player: Player, currency: Currency, amount: number, reason: string): boolean
	if not isValidAmount(amount) then
		warn(`[Economy] Rejected add {amount} {currency} ({reason}) for {player.Name}`)
		return false
	end
	return apply(player, currency, amount, reason)
end

-- Returns false (and changes nothing) if the player can't afford it.
function EconomyService.TrySpend(player: Player, currency: Currency, amount: number, reason: string): boolean
	if not isValidAmount(amount) then
		warn(`[Economy] Rejected spend {amount} {currency} ({reason}) for {player.Name}`)
		return false
	end
	return apply(player, currency, -amount, reason)
end

function EconomyService.Init()
	DataService.Loaded:Connect(function(player: Player, data: Types.PlayerData)
		player:SetAttribute(ATTRIBUTE.koin, data.koin)
		player:SetAttribute(ATTRIBUTE.bunga, data.bunga)
	end)
end

return EconomyService
