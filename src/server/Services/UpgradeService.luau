--!strict
-- Buying the permanent upgrades (Config/Shop UPGRADES): Kolam. The tier lives in data.upgrades
-- (Modules/Upgrades). Other services react through UpgradeService.Bought (ShopService refreshes the ponds on "pond"),
-- so this file needs no other game service and there are no require cycles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local Types = require(ReplicatedStorage.Shared.Types)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)

local UpgradeService = {}
UpgradeService.Bought = Signal.new() -- (player, upgradeId, newTier)

-- Price of the next tier, nil when the upgrade is maxed (or unknown).
function UpgradeService.NextCost(data: Types.PlayerData, upgradeId: string): number?
	local config = Shop.UPGRADES[upgradeId]
	if not config then
		return nil
	end
	return config.costs[Upgrades.tier(data, upgradeId) + 1]
end

-- Buys the next tier. Returns true when it went through (the caller does not need to notify).
function UpgradeService.Buy(player: Player, data: Types.PlayerData, upgradeId: string): boolean
	local config = Shop.UPGRADES[upgradeId]
	if not config then
		return false
	end
	local current = Upgrades.tier(data, upgradeId)
	local cost = config.costs[current + 1]
	if not cost then
		Net.Fire("Notify", player, "shop.max")
		return false
	end
	if data.level < config.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = config.unlockLevel })
		return false
	end
	if not EconomyService.TrySpend(player, "koin", cost, `upgrade:{upgradeId}:{current + 1}`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
		return false
	end
	data.upgrades[upgradeId] = current + 1
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "shop.bought", { item = `upgrade.{upgradeId}` })
	UpgradeService.Bought:Fire(player, upgradeId, current + 1)
	return true
end

return UpgradeService
