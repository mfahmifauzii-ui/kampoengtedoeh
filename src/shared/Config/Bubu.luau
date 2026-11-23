--!strict
-- Bubu (GDD 6.6, Putaran 2 R2.1): a trap placed in the river. Ready after HOURS of wall-clock time (no instant finish), collected
-- later on any join (offline collect). Max MAX placed per player, all types together. Never gives a Legenda.
-- Buying a Bubu is not wired yet (Kak Fajar's shop): for now it comes from the DEV "!give bubu_<tipe> 1" or a future reward.

local Bubu = {}

Bubu.HOURS = 6
Bubu.MAX = 3
Bubu.PLACE_DISTANCE = 25 -- studs from a river fishing spot

-- fishRarities: the fish rarities a catch is drawn from (per type); count: fish per collect.
Bubu.TYPES = {
	bambu = { item = "bubu_bambu", price = 400, fishRarities = { "C" }, countMin = 3, countMax = 4 },
	kayu = { item = "bubu_kayu", price = 1500, fishRarities = { "C", "U" }, countMin = 4, countMax = 6 },
	besi = { item = "bubu_besi", price = 4000, fishRarities = { "U", "R" }, countMin = 6, countMax = 8 },
} :: { [string]: { item: string, price: number, fishRarities: { string }, countMin: number, countMax: number } }

return Bubu
