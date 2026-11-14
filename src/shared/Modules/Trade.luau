--!strict
-- Prices for NPC trading. Shared so the client shows exactly what the server will charge or pay.

local Crops = require(script.Parent.Parent.Config.Crops)
local Npcs = require(script.Parent.Parent.Config.Npcs)
local Skills = require(script.Parent.Parent.Config.Skills)
local Items = require(script.Parent.Items)

local Trade = {}

-- What the NPC pays for ONE unit of an item; nil = this NPC doesn't buy it.
function Trade.buyPrice(npc: Npcs.Npc, info: Items.ItemInfo): number?
	local multiplier = npc.buys[info.kind]
	if not multiplier or not info.sellPrice then
		return nil
	end
	return math.floor(info.sellPrice * multiplier + 0.5)
end

-- Price of one seed. unggul = the faster-growing kind sold by Bu Wati.
function Trade.seedPrice(crop: Crops.Crop, unggul: boolean): number
	return if unggul then math.ceil(crop.seedPrice * Npcs.SEED_UNGGUL_PRICE_MULT) else crop.seedPrice
end

-- Price of one fish bought from Mbok Minah (always size Kecil).
function Trade.fishPrice(sellPrice: number): number
	return math.floor(sellPrice * Npcs.FISH_SELL_MULT + 0.5)
end

-- Friendship discount on what YOU buy (tier = Npcs.tierOf(affinity)). Applied per unit, never below 1 Koin.
function Trade.discount(price: number, tier: number): number
	local off = Npcs.TIERS[tier].discount
	return if off > 0 then math.max(1, math.floor(price * (1 - off) + 0.5)) else price
end

-- Chance (percent) that Bang Tarno accepts an ask of +pct%.
function Trade.haggleChance(pct: number, tier: number, tawarLevel: number): number
	local rules = Npcs.HAGGLE
	local skill = Skills.byId.tawar
	local chance = rules.BASE_CHANCE - pct + Npcs.TIERS[tier].haggleBonus + (tawarLevel - 1) * skill.chanceBonusPerLevel
	return math.clamp(chance, rules.MIN_CHANCE, rules.MAX_CHANCE)
end

-- What the whole stack pays if the haggle succeeds: base * count * (1 + pct%), rounded ONCE on the total (rounding
-- per unit would make +10% and +20% identical for cheap crops), capped at HAGGLE.CAP_MULT of the full sell value.
function Trade.haggleTotal(base: number, count: number, info: Items.ItemInfo, pct: number): number
	local asked = math.floor(base * count * (1 + pct / 100) + 0.5)
	local cap = math.floor((info.sellPrice or base) * count * Npcs.HAGGLE.CAP_MULT + 0.5)
	return math.min(asked, cap)
end

return Trade
