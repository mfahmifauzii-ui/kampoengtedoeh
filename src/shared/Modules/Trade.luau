--!strict
-- Prices for NPC trading. Shared so the client shows exactly what the server will charge or pay.

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

-- Price of one seed. unggul = the faster-growing kind sold by Pak Udin.
function Trade.seedPrice(crop: Crops.Crop, unggul: boolean): number
	return if unggul then math.ceil(crop.seedPrice * Npcs.SEED_UNGGUL_PRICE_MULT) else crop.seedPrice
end

-- Price of one fish bought from Kak Fajar (always size Kecil).
function Trade.fishPrice(sellPrice: number): number
	return math.floor(sellPrice * Npcs.FISH_SELL_MULT + 0.5)
end

return Trade
