--!strict
-- Farm rules. Farming is free-form: the player tills (garap) grass cells of their land into soil tiles
-- (Modules/Land.TILE studs each), anywhere on their land. The soil is TERRAIN, not parts.

-- R2b: no tile cap from upgrades any more: the land you own is the limit. MAX_TILES is only a safety valve (data size
-- and server work), well above what 192 x 192 studs (minus house, ponds, decor) can hold in practice.
local MAX_TILES = 100

return {
	MAX_TILES = MAX_TILES,

	-- A bed = soil painted on the terrain (flat, the dark furrow color you see in the gaps) + a low soil slab (a Part)
	-- on top. Beds are adjacent on the 8-stud grid; the slab is BED_SIZE wide, so a 1-stud furrow shows between them,
	-- like in any farming game. (Smooth terrain alone can't make a crisp gap: it blurs about 2 studs each side.)
	TILE_HEIGHT = 0.6, -- thickness of the soil slab = how far the bed stands above the ground
	BED_SIZE = 7, -- studs; the grid cell is 8 (Land.TILE)
	BED_RAISE = 0.6, -- studs the bed top stands above the ground (crops and the preview rest on it)
	BED_OCCUPANCY = 0.5, -- terrain under a bed stays flat (the slab gives the height)
	GROUND_OCCUPANCY = 0.5, -- plain grass
	BED_COLOR_DRY = Color3.fromRGB(150, 102, 62), -- slab color (Sand material, no override)
	BED_COLOR_WET = Color3.fromRGB(94, 64, 40), -- after watering
	WATER_REDUCTION = 0.2, -- watering cuts remaining grow time by 20%
	SEED_UNGGUL_GROW_MULT = 0.9, -- "bibit unggul" (Bu Wati) grows 10% faster
	INTERACT_DISTANCE = 40, -- studs, server-checked (plant / water / harvest)
	TILL_DISTANCE = 60, -- studs from the player to the cell they till or level

	SOIL_DRY = Color3.fromRGB(150, 100, 58), -- terrain material "Ground" (warm furrow brown)
	SOIL_WET = Color3.fromRGB(96, 62, 38), -- terrain material "Mud"
}
