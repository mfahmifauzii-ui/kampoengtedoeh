--!strict
-- Blueprints (Mbak Arsi, the tukang, sells them). A blueprint unlocks buying every decor item that names it in its
-- `blueprint` field (Config/Decor). Decor without a blueprint (the free "dasar" set, Bunga items, event items) is
-- always available. Blueprints replace the old per-item level requirement. Owned blueprints: data.decor.blueprints.
-- Items you already own (stock, placed, order rewards) never need the blueprint; it only gates BUYING.
-- Locale keys: blueprint.<id> (name).

export type Blueprint = {
	id: string,
	price: number, -- koin
	unlockLevel: number, -- level needed to buy the blueprint
}

local list: { Blueprint } = {
	{ id = "taman", price = 400, unlockLevel = 3 }, -- pisang, bambu, bangku, bunga kertas
	{ id = "pondok_sawah", price = 600, unlockLevel = 5 }, -- bale, meja, lampu teplok, gentong, jemuran, sepeda...
}

local byId: { [string]: Blueprint } = {}
for _, blueprint in list do
	byId[blueprint.id] = blueprint
end

return {
	list = list,
	byId = byId,
}
