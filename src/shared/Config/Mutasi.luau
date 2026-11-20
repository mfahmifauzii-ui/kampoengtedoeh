--!strict
-- Mutasi panen (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 5.4, LOCKED). A harvest rolls at most one Mutasi:
-- every Mutasi whose condition holds gets its chance roll, and the one with the highest mult wins.
-- A mutated item is "<mutation>_<crop>" (e.g. embun_kangkung); Super stacks in front: super_embun_kangkung.
-- price = sellPrice x mult (Bab 17.7: Mutasi and Super multiply, they do not replace each other).
--
-- when (checked by FarmService at harvest, server only):
--   "grown_rain"  : the crop's readyAt fell in Gerimis or Deres (WorldService.WeatherAt)
--   "grown_petir" : the crop's readyAt fell in Petir
--   "wet"         : the tile is Basah at harvest (tile.watered)
--   "pelangi"     : the harvest happens during Pelangi
--
-- Fase 2 note: the FTUE first harvest still forces "embun" (Onboarding.FTUE_FIRST_MUTATION), as before.

export type When = "grown_rain" | "grown_petir" | "wet" | "pelangi"

export type Mutation = {
	id: string,
	mult: number,
	chance: number, -- roll when the condition holds
	when: When,
	nameKey: string, -- Locale key of the mutation name (shown as "{crop} {mutation}")
	announce: boolean, -- server banner to every player in the server when it is harvested
}

local list: { Mutation } = {
	{ id = "embun", mult = 1.5, chance = 0.20, when = "grown_rain", nameKey = "mutasi.embun", announce = false },
	{ id = "petir", mult = 3, chance = 0.10, when = "grown_petir", nameKey = "mutasi.petir", announce = false },
	{ id = "emas", mult = 5, chance = 0.01, when = "wet", nameKey = "mutasi.emas", announce = true },
	{ id = "pelangi", mult = 10, chance = 0.03, when = "pelangi", nameKey = "mutasi.pelangi", announce = true },
}

-- Banner for announced Mutasi only when the crop takes at least this long to grow (seconds). The doc (Bab 5.4) says
-- "tanaman Late" (2 jam+); the owner's request says "rare Mutasi". Set this to 7200 to follow the doc. Default 0 = any crop.
local ANNOUNCE_MIN_GROW_SECONDS = 0

local byId: { [string]: Mutation } = {}
for _, mutation in list do
	byId[mutation.id] = mutation
end

return {
	list = list,
	byId = byId,
	ANNOUNCE_MIN_GROW_SECONDS = ANNOUNCE_MIN_GROW_SECONDS,
}
