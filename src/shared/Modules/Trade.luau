--!strict
-- Prices for NPC trading. Shared so the client shows exactly what the server will charge or pay.

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

-- Price of one bibit biasa (Bibit Unggul DIHAPUS, Bab 29).
function Trade.seedPrice(crop: { seedPrice: number }): number
	return crop.seedPrice
end

-- Price of one fish bought from Kak Fajar (always size Kecil).
function Trade.fishPrice(sellPrice: number): number
	return math.floor(sellPrice * Npcs.FISH_SELL_MULT + 0.5)
end

return Trade
