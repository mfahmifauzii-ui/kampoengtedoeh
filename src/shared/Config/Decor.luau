--!strict
-- All decor items. Add an item here + a "decor.<id>" locale key; no logic changes needed.
-- w/d = footprint in grid cells (CELL studs each) at rotation 0.
-- parts = placeholder look (max ~8 parts, positions relative to footprint center on the ground).
-- REAL MODELS: put a Model named <id> in ReplicatedStorage > DecorModels with its pivot at the
-- footprint center, ground level. It replaces the placeholder automatically.

export type PartSpec = {
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: ("ball" | "cylinder" | "wheel")?, -- cylinder = standing, wheel = axle along Z
	light: boolean?, -- glows at night (PointLight toggled client-side)
}

export type Item = {
	id: string,
	set: string?, -- Collection Book category
	blueprint: string?, -- Config/Blueprints id needed to BUY it (nil = always available). Owned stock never needs it.
	unlockLevel: number?, -- Stage 8/2: player level needed to BUY it (server checks; the Sprinkler needs Lv 7)
	waters: boolean?, -- Stage 2: a Sprinkler, waters the 3x3 beds around it every 60 s (FarmService)
	w: number,
	d: number,
	currency: "koin" | "bunga",
	price: number,
	event: string?, -- Config/Events id: buyable only while that event runs (kept forever once owned)
	parts: { PartSpec },
}

local BAMBOO = Color3.fromRGB(196, 176, 120)
local BAMBOO_GREEN = Color3.fromRGB(128, 146, 92)
local WOOD = Color3.fromRGB(130, 96, 66)
local DARKWOOD = Color3.fromRGB(96, 70, 50)
local CLAY = Color3.fromRGB(178, 110, 78)
local STONE = Color3.fromRGB(150, 146, 136)
local CLOTH = Color3.fromRGB(214, 200, 170)
local LEAF = Color3.fromRGB(104, 132, 80)
local METAL = Color3.fromRGB(78, 80, 76)
local ROOF = Color3.fromRGB(120, 100, 80)
local RATTAN = Color3.fromRGB(150, 110, 70)

local function p(sx: number, sy: number, sz: number, px: number, py: number, pz: number, color: Color3, material: Enum.Material?, shape: any?): PartSpec
	return { size = Vector3.new(sx, sy, sz), pos = Vector3.new(px, py, pz), color = color, material = material, shape = shape }
end

local function lamp(spec: PartSpec): PartSpec
	spec.light = true
	return spec
end

local list: { Item } = {
	-- Set: Pondok Sawah ----------------------------------------------------------------
	{ id = "bale_bambu", blueprint = "pondok_sawah", set = "pondok_sawah", w = 3, d = 2, currency = "koin", price = 300, parts = {
		p(5.6, 1.2, 3.6, 0, 0.6, 0, WOOD),
		p(6, 0.3, 4, 0, 1.35, 0, BAMBOO),
	} },
	{ id = "kursi_bambu", set = "pondok_sawah", w = 1, d = 1, currency = "koin", price = 80, parts = {
		p(1.6, 1, 1.6, 0, 0.5, 0, BAMBOO),
		p(1.6, 1.4, 0.3, 0, 1.7, -0.65, BAMBOO),
	} },
	{ id = "meja_kayu", blueprint = "pondok_sawah", set = "pondok_sawah", w = 2, d = 1, currency = "koin", price = 120, parts = {
		p(3, 2, 1.2, 0, 1, 0, DARKWOOD),
		p(3.6, 0.3, 1.8, 0, 2.15, 0, WOOD),
	} },
	{ id = "lampu_teplok", blueprint = "pondok_sawah", set = "pondok_sawah", w = 1, d = 1, currency = "koin", price = 60, parts = {
		p(0.4, 4, 0.4, 0, 2, 0, DARKWOOD),
		lamp(p(0.9, 0.9, 0.9, 0, 4.4, 0, Color3.fromRGB(230, 200, 140), Enum.Material.SmoothPlastic)),
	} },
	{ id = "pot_tanah_liat", set = "pondok_sawah", w = 1, d = 1, currency = "koin", price = 40, parts = {
		p(1.2, 1.4, 1.4, 0, 0.6, 0, CLAY, nil, "cylinder"),
		p(1.4, 1.4, 1.4, 0, 1.7, 0, LEAF, Enum.Material.Grass, "ball"),
	} },
	{ id = "pagar_bambu_lurus", set = "pondok_sawah", w = 2, d = 1, currency = "koin", price = 30, parts = {
		p(0.4, 2.6, 0.4, -1.8, 1.3, 0, BAMBOO),
		p(0.4, 2.6, 0.4, 1.8, 1.3, 0, BAMBOO),
		p(4, 0.3, 0.3, 0, 2.1, 0, BAMBOO),
		p(4, 0.3, 0.3, 0, 1, 0, BAMBOO),
	} },
	{ id = "pagar_bambu_sudut", set = "pondok_sawah", w = 1, d = 1, currency = "koin", price = 30, parts = {
		p(0.4, 2.6, 0.4, 0, 1.3, 0, BAMBOO),
		p(1, 0.3, 0.3, 0.5, 2.1, 0, BAMBOO),
		p(0.3, 0.3, 1, 0, 2.1, 0.5, BAMBOO),
	} },
	{ id = "jalan_batu", set = "pondok_sawah", w = 1, d = 1, currency = "koin", price = 10, parts = {
		p(1.8, 0.2, 1.8, 0, 0.1, 0, STONE, Enum.Material.Slate),
	} },
	{ id = "orang_orangan_sawah", blueprint = "pondok_sawah", set = "pondok_sawah", w = 1, d = 1, currency = "koin", price = 150, parts = {
		p(0.4, 5, 0.4, 0, 2.5, 0, WOOD),
		p(3, 0.3, 0.3, 0, 3.6, 0, WOOD),
		p(1.4, 1.6, 0.6, 0, 3.2, 0, Color3.fromRGB(110, 120, 140), Enum.Material.Fabric),
		p(1, 1, 1, 0, 4.6, 0, CLOTH, Enum.Material.Fabric, "ball"),
		p(2, 0.3, 2, 0, 5.2, 0, BAMBOO),
	} },
	{ id = "gentong_air", blueprint = "pondok_sawah", set = "pondok_sawah", w = 1, d = 1, currency = "koin", price = 90, parts = {
		p(2, 1.7, 1.7, 0, 1, 0, CLAY, nil, "cylinder"),
	} },
	{ id = "jemuran", blueprint = "pondok_sawah", set = "pondok_sawah", w = 3, d = 1, currency = "koin", price = 110, parts = {
		p(0.3, 4, 0.3, -2.6, 2, 0, WOOD),
		p(0.3, 4, 0.3, 2.6, 2, 0, WOOD),
		p(5.4, 0.1, 0.1, 0, 3.8, 0, DARKWOOD),
		p(1.4, 1.6, 0.1, -1.2, 2.9, 0, CLOTH, Enum.Material.Fabric),
		p(1.2, 1.2, 0.1, 1, 3.1, 0, Color3.fromRGB(170, 120, 100), Enum.Material.Fabric),
	} },
	{ id = "sepeda_onthel", blueprint = "pondok_sawah", set = "pondok_sawah", w = 2, d = 1, currency = "koin", price = 250, parts = {
		p(0.2, 2, 2, -1.2, 1, 0, METAL, nil, "wheel"),
		p(0.2, 2, 2, 1.2, 1, 0, METAL, nil, "wheel"),
		p(2.6, 0.3, 0.3, 0, 1.6, 0, Color3.fromRGB(70, 84, 70)),
		p(0.8, 0.3, 0.5, -0.5, 2.1, 0, DARKWOOD),
	} },

	-- Basic (Koin) -------------------------------------------------------------------
	{ id = "pohon_pisang", blueprint = "taman", w = 2, d = 2, currency = "koin", price = 120, parts = {
		p(0.8, 5, 0.8, 0, 2.5, 0, Color3.fromRGB(120, 130, 80)),
		p(4, 1.5, 4, 0, 5.4, 0, LEAF, Enum.Material.Grass, "ball"),
	} },
	{ id = "rumpun_bambu", blueprint = "taman", w = 2, d = 2, currency = "koin", price = 100, parts = {
		p(0.5, 8, 0.5, -0.8, 4, -0.6, BAMBOO_GREEN),
		p(0.5, 7, 0.5, 0.8, 3.5, -0.4, BAMBOO_GREEN),
		p(0.5, 7.5, 0.5, 0, 3.75, 0.8, BAMBOO_GREEN),
		p(3.5, 2.5, 3.5, 0, 7.6, 0, LEAF, Enum.Material.Grass, "ball"),
	} },
	{ id = "semak", w = 1, d = 1, currency = "koin", price = 20, parts = {
		p(1.8, 1.4, 1.8, 0, 0.7, 0, LEAF, Enum.Material.Grass, "ball"),
	} },
	{ id = "batu_besar", w = 1, d = 1, currency = "koin", price = 25, parts = {
		p(1.8, 1.2, 1.6, 0, 0.6, 0, STONE, Enum.Material.Slate),
	} },
	{ id = "bangku_kayu", blueprint = "taman", w = 2, d = 1, currency = "koin", price = 70, parts = {
		p(3, 1, 0.8, 0, 0.5, 0, DARKWOOD),
		p(3.6, 0.4, 1.2, 0, 1.2, 0, WOOD),
	} },
	{ id = "bunga_kertas", blueprint = "taman", w = 1, d = 1, currency = "koin", price = 50, parts = {
		p(1, 1.2, 1.2, 0, 0.5, 0, CLAY, nil, "cylinder"),
		p(1.8, 1.6, 1.8, 0, 1.8, 0, Color3.fromRGB(176, 110, 130), Enum.Material.Grass, "ball"),
	} },

	-- Bunga (cosmetic premium-lite) --------------------------------------------------
	{ id = "gazebo_bambu", w = 3, d = 3, currency = "bunga", price = 50, parts = {
		p(6, 0.6, 6, 0, 0.3, 0, WOOD),
		p(0.4, 5, 0.4, -2.6, 3, -2.6, BAMBOO),
		p(0.4, 5, 0.4, 2.6, 3, -2.6, BAMBOO),
		p(0.4, 5, 0.4, -2.6, 3, 2.6, BAMBOO),
		p(0.4, 5, 0.4, 2.6, 3, 2.6, BAMBOO),
		p(7, 0.6, 7, 0, 5.8, 0, ROOF),
		p(4, 0.8, 4, 0, 6.4, 0, ROOF),
	} },
	{ id = "lampion_gantung", w = 1, d = 1, currency = "bunga", price = 15, parts = {
		p(0.3, 5, 0.3, 0, 2.5, 0, DARKWOOD),
		p(1.2, 0.2, 0.2, 0.5, 4.9, 0, DARKWOOD),
		lamp(p(0.8, 1, 0.8, 0.9, 4.2, 0, Color3.fromRGB(196, 120, 80), Enum.Material.SmoothPlastic, "ball")),
	} },
	{ id = "kursi_rotan", w = 1, d = 1, currency = "bunga", price = 20, parts = {
		p(1.8, 1, 1.8, 0, 0.5, 0, RATTAN, Enum.Material.Fabric),
		p(1.8, 1.8, 0.4, 0, 1.9, -0.7, RATTAN, Enum.Material.Fabric),
	} },

	-- Event: Ramadan & Lebaran (Config/Events "lebaran") ---------------------------------
	{ id = "ketupat_gantung", event = "lebaran", w = 1, d = 1, currency = "koin", price = 80, parts = {
		p(0.3, 4.5, 0.3, 0, 2.25, 0, BAMBOO),
		p(1.4, 0.2, 0.2, 0.6, 4.4, 0, BAMBOO),
		p(0.9, 0.9, 0.9, 1.1, 3.7, 0, Color3.fromRGB(150, 170, 96), Enum.Material.Fabric),
		p(0.7, 0.7, 0.7, 0.3, 3.5, 0, Color3.fromRGB(150, 170, 96), Enum.Material.Fabric),
	} },
	{ id = "pelita_minyak", event = "lebaran", w = 1, d = 1, currency = "koin", price = 60, parts = {
		p(0.3, 2.4, 0.3, 0, 1.2, 0, BAMBOO),
		p(0.6, 0.6, 0.6, 0, 2.6, 0, METAL, nil, "cylinder"),
		lamp(p(0.4, 0.6, 0.4, 0, 3.2, 0, Color3.fromRGB(236, 180, 100), Enum.Material.SmoothPlastic, "ball")),
	} },
	{ id = "bedug_kecil", event = "lebaran", w = 2, d = 1, currency = "bunga", price = 20, parts = {
		p(0.4, 1.6, 0.4, -1.2, 0.8, 0, DARKWOOD),
		p(0.4, 1.6, 0.4, 1.2, 0.8, 0, DARKWOOD),
		p(2.4, 1.8, 1.8, 0, 2.1, 0, Color3.fromRGB(150, 104, 66), nil, "wheel"),
	} },
}

-- Stage 6: toko hias awal, bisa dibeli dengan Koin tanpa blueprint. Ukuran sesuai spek: 2 stud = 1 sel, 4x4 stud = 2x2 sel.
local STARTER_HIAS: { Item } = {
	{ id = "pagar_bambu", set = "taman", w = 1, d = 1, currency = "koin", price = 30, parts = {
		p(1.8, 1.2, 0.3, 0, 0.6, 0, BAMBOO),
		p(1.8, 0.2, 0.3, 0, 0.9, 0, BAMBOO_GREEN),
	} },
	{ id = "bunga_kamboja", set = "taman", w = 1, d = 1, currency = "koin", price = 25, parts = {
		p(1.4, 0.4, 1.4, 0, 0.2, 0, LEAF),
		p(0.6, 0.6, 0.6, 0, 0.7, 0, Color3.fromRGB(236, 196, 210), nil, "ball"),
	} },
	{ id = "lampu_taman", set = "taman", w = 1, d = 1, currency = "koin", price = 60, parts = {
		p(0.3, 1.8, 0.3, 0, 0.9, 0, METAL),
		p(0.8, 0.5, 0.8, 0, 2.0, 0, Color3.fromRGB(255, 226, 150), Enum.Material.Neon, "ball"),
	} },
	{ id = "kursi_kayu", set = "taman", w = 2, d = 2, currency = "koin", price = 80, parts = {
		p(3.2, 0.3, 3.2, 0, 1.0, 0, WOOD),
		p(3.2, 1.6, 0.3, 0, 1.9, -1.45, WOOD),
	} },
	-- Stage 2: Sprinkler Bambu (Lv 7, 800 Koin). Put it on the land; every 60 s it waters the beds around it (3x3).
	{ id = "sprinkler_bambu", set = "taman", unlockLevel = 7, waters = true, w = 1, d = 1, currency = "koin", price = 800, parts = {
		p(0.6, 1.4, 0.6, 0, 0.7, 0, BAMBOO_GREEN),
		p(1.6, 0.2, 0.2, 0, 1.5, 0, BAMBOO),
		p(0.4, 0.3, 0.4, 0, 1.6, 0, METAL, nil, "ball"),
	} },
	{ id = "pohon_pisang_hias", set = "taman", w = 2, d = 2, currency = "koin", price = 120, parts = {
		p(0.6, 3.6, 0.6, 0, 1.8, 0, DARKWOOD),
		p(3.4, 0.2, 1.0, 0, 3.8, 0, LEAF),
		p(1.0, 0.2, 3.4, 0, 3.9, 0, LEAF),
	} },
}
for _, item in STARTER_HIAS do
	table.insert(list, item)
end

local byId: { [string]: Item } = {}
for _, item in list do
	byId[item.id] = item
end

return {
	list = list,
	byId = byId,

	CELL = 2, -- studs per grid cell
	MAX_PLACED = 150, -- Decor Expansion pass adds +100 (Phase 8)
	BLOCK_MARGIN = 1, -- studs kept clear around the farm and pond

	-- Extra no-build areas in plot-local studs (e.g. your house), as {min = Vector2(x, z), max = Vector2(x, z)}.
	-- (Ponds are blocked by the land rules; there is no start house any more.)
	BLOCKED_EXTRA = {} :: { { min: Vector2, max: Vector2 } },
}
