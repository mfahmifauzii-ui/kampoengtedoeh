--!strict
-- All crops. Add a crop here + a "crop.<id>" locale key; no logic changes needed.
-- growSeconds is real time; growth continues while offline.
-- yield = items per harvest; regrows = extra harvests before the tile is empty again.
-- color is the placeholder visual until real models exist.

export type Crop = {
	id: string,
	unlockLevel: number,
	seedPrice: number, -- Koin, paid when planting (no seed items)
	growSeconds: number,
	sellPrice: number,
	xp: number,
	yield: number,
	regrows: number,
	color: Color3,
}

local list: { Crop } = {
	{ id = "kangkung", unlockLevel = 1, seedPrice = 5, growSeconds = 60, sellPrice = 9, xp = 2, yield = 1, regrows = 0, color = Color3.fromRGB(118, 148, 86) },
	{ id = "cabai", unlockLevel = 1, seedPrice = 10, growSeconds = 180, sellPrice = 20, xp = 3, yield = 1, regrows = 0, color = Color3.fromRGB(176, 78, 62) },
	{ id = "tomat", unlockLevel = 3, seedPrice = 15, growSeconds = 300, sellPrice = 30, xp = 5, yield = 1, regrows = 0, color = Color3.fromRGB(190, 96, 72) },
	{ id = "terong", unlockLevel = 5, seedPrice = 25, growSeconds = 600, sellPrice = 50, xp = 8, yield = 1, regrows = 0, color = Color3.fromRGB(104, 78, 118) },
	{ id = "jagung", unlockLevel = 8, seedPrice = 40, growSeconds = 1200, sellPrice = 85, xp = 12, yield = 1, regrows = 0, color = Color3.fromRGB(214, 180, 92) },
	{ id = "singkong", unlockLevel = 11, seedPrice = 60, growSeconds = 2700, sellPrice = 140, xp = 20, yield = 1, regrows = 0, color = Color3.fromRGB(150, 118, 84) },
	{ id = "padi", unlockLevel = 14, seedPrice = 80, growSeconds = 7200, sellPrice = 220, xp = 35, yield = 1, regrows = 0, color = Color3.fromRGB(196, 176, 110) },
	{ id = "pisang", unlockLevel = 18, seedPrice = 200, growSeconds = 28800, sellPrice = 120, xp = 40, yield = 1, regrows = 2, color = Color3.fromRGB(208, 190, 96) },
}

local byId: { [string]: Crop } = {}
for _, crop in list do
	byId[crop.id] = crop
end

return {
	list = list,
	byId = byId,
}
