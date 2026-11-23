--!strict
-- Farm rules. Farming is free-form: the player tills (garap) grass cells of their land into soil tiles
-- (Modules/Land.TILE studs each), anywhere on their land. The soil is TERRAIN, not parts.
--
-- Tile limit (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 5.2, T-04): the first TILE_FREE tiles are free. Tile n
-- above that costs n x TILE_COST Koin. Tiles 7-12 need no level, 13-24 need Lv 10, 25-36 need Lv 25.

local TILE_FREE = 6
local TILE_COST = 150
local TILE_REFUND_RATE = 0.5 -- "Hapus Petak" gives back this share of what a BOUGHT bed cost (free beds: nothing)
-- { upTo = highest tile number, level = level needed to plow tiles up to it }
local TILE_STEPS = {
	{ upTo = 12, level = 1 },
	{ upTo = 24, level = 10 },
	{ upTo = 36, level = 25 },
}

return {
	TILE_FREE = TILE_FREE,
	TILE_COST = TILE_COST,
	TILE_REFUND_RATE = TILE_REFUND_RATE,

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

	-- Alat Koin (docs/01_GDD_Kampoeng_Tedoeh_v8.3.md Bab 17.5, LOCKED). Bought with Koin + bahan from Pak Udin (Alat section).
	-- mats = bahan (P2-1: belum ada sumber, belum bisa dipenuhi). cells = petak per tap (garis, gembor/sabit).
	-- Efek sabit (panen garis) + sepatu (jalan) + kapak (bonus bahan) di-wire di P2; gembor garis jalan sekarang.
	TOOLS = {
		gembor_plastik = { price = 0, unlockLevel = 1, mats = {}, cells = 1 }, -- siram 1 petak
		gembor_seng = { price = 2000, unlockLevel = 3, mats = { { id = "kayu", count = 10 } }, cells = 2 }, -- siram 2 petak (garis)
		gembor_kuningan = { price = 8000, unlockLevel = 8, mats = { { id = "papan", count = 20 } }, cells = 3 }, -- siram 3 petak (garis)
		sabit_kayu = { price = 0, unlockLevel = 1, mats = {}, cells = 1 }, -- panen 1 petak
		sabit_besi = { price = 5000, unlockLevel = 5, mats = { { id = "batu", count = 10 } }, cells = 3 }, -- panen 3 petak (garis)
		sepatu_bot = { price = 800, unlockLevel = 2, mats = { { id = "ijuk", count = 5 } }, speedMult = 1.05 }, -- jalan +5% di lahan sendiri
		kapak_batu = { price = 0, unlockLevel = 1, mats = {} }, -- normal
		kapak_besi = { price = 3000, unlockLevel = 3, mats = { { id = "batu", count = 15 } }, bonusBahan = 1 }, -- +1 bahan per node
		kapak_baja = { price = 10000, unlockLevel = 7, mats = { { id = "batu", count = 20 }, { id = "semen", count = 10 } }, bonusBahan = 2 }, -- +2 bahan per node
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
	-- Telat panen (Bab 5.1): a ripe crop left unharvested for OVERDUE_AFTER_SECONDS grows to OVERDUE_SCALE. It never wilts or
	-- disappears. OVERDUE_AFTER_SECONDS = 600 is a TEAM NUMBER (the doc gives no threshold): change it in Config only.
	OVERDUE_AFTER_SECONDS = 600,
	OVERDUE_SCALE = 1.1,
	INTERACT_DISTANCE = 40, -- studs, server-checked (plant / water / harvest)
	TILL_DISTANCE = 60, -- studs from the player to the cell they till or level

	SOIL_DRY = Color3.fromRGB(150, 100, 58), -- terrain material "Ground" (warm furrow brown)
	SOIL_WET = Color3.fromRGB(96, 62, 38), -- terrain material "Mud"

	-- Animasi tanam/siram (Roadmap §12.4 pola sama dengan Fishing.ANIMS): ID Animation PERMANEN hasil Publish to Roblox.
	-- Kosong = pakai sequence dari ReplicatedStorage.CustomAnims (hanya jalan di Studio).
	ANIMS = {
		FarmPlant = "rbxassetid://72416432910267",
		FarmWater = "rbxassetid://106687765397165",
	} :: { [string]: string },
}
