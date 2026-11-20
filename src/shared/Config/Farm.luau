--!strict
-- Farm rules. Farming is free-form: the player tills (garap) grass cells of their land into soil tiles
-- (Modules/Land.TILE studs each), anywhere on their land. The soil is TERRAIN, not parts.
--
-- Tile limit (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 5.2, T-04): the first TILE_FREE tiles are free. Tile n
-- above that costs n x TILE_COST Koin. Tiles 7-12 need no level, 13-24 need Lv 10, 25-36 need Lv 25.

local TILE_FREE = 6
local TILE_COST = 150
-- { upTo = highest tile number, level = level needed to plow tiles up to it }
local TILE_STEPS = {
	{ upTo = 12, level = 1 },
	{ upTo = 24, level = 10 },
	{ upTo = 36, level = 25 },
}

return {
	TILE_FREE = TILE_FREE,
	TILE_COST = TILE_COST,

	-- Highest tile number this level may plow (the farm snapshot sends it as `cap`).
	tileCap = function(level: number): number
		local cap = 0
		for _, step in TILE_STEPS do
			if level >= step.level then
				cap = step.upTo
			end
		end
		return cap
	end,

	-- Koin for plowing tile number n (n = count + 1): free for the first TILE_FREE tiles.
	tileCost = function(n: number): number
		return if n <= TILE_FREE then 0 else n * TILE_COST
	end,

	-- STAGE 2: alat siram. Bought with Koin from Pak Udin (Alat section). Gembor waters a 3x3 block of beds in one tap.
	-- Sprinkler (Lv 7, Koin 800) is NOT built yet (see docs/OVERNIGHT_LOG.md).
	TOOLS = {
		gembor = { price = 300, unlockLevel = 4, radius = 1 }, -- radius 1 = 3x3 beds around the tapped one
	},

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
	WATER_REDUCTION = 0.15, -- Siram: cuts remaining grow time by 15%, once per growth (Bab 5.1 v6.2)
	-- Super Panen (Bab 5.3): base chance, +bonus if the tile is Basah at harvest. Super = 2x Koin + 50% XP.
	SUPER_CHANCE = 0.05,
	SUPER_WET_BONUS = 0.05,
	SUPER_KOIN_MULT = 2,
	SUPER_XP_MULT = 1.5,
	SEED_UNGGUL_GROW_MULT = 0.9, -- "bibit unggul" (Pak Udin) grows 10% faster
	INTERACT_DISTANCE = 40, -- studs, server-checked (plant / water / harvest)
	TILL_DISTANCE = 60, -- studs from the player to the cell they till or level

	SOIL_DRY = Color3.fromRGB(150, 100, 58), -- terrain material "Ground" (warm furrow brown)
	SOIL_WET = Color3.fromRGB(96, 62, 38), -- terrain material "Mud"
}
