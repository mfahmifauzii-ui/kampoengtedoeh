--!strict
-- Prices and quotas for NPC trading. Shared so the client shows exactly what the server will charge or pay.

local Crops = require(script.Parent.Parent.Config.Crops)
local Npcs = require(script.Parent.Parent.Config.Npcs)
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

-- Pak Darmo's daily quota per crop type at a "Kapasitas Warung" tier (0 = none bought).
function Trade.quota(tier: number): number
	return Npcs.QUOTA.PER_CROP + tier * Npcs.QUOTA.PER_TIER
end

-- How many more of a crop Pak Darmo will buy today. sales = data.sales (day = WIB day key of `sold`).
function Trade.quotaLeft(sales: { day: string, sold: { [string]: number } }, tier: number, cropId: string, today: string): number
	local sold = if sales.day == today then sales.sold[cropId] or 0 else 0
	return math.max(0, Trade.quota(tier) - sold)
end

return Trade
