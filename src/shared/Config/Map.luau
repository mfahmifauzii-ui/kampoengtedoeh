--!strict
-- Village map layout (blueprint: X shape). All numbers in studs, origin (0,0,0) = bridge center.
--   Road  : SW -> NE diagonal.     River : NW -> SE diagonal.     They cross at the center bridge.
--   Plots : 1 = South, 2 = West, 3 = North, 4 = East (see Config/Plots).
-- MapService builds all of it at server start unless Workspace.Map already exists (hand-built map).

return {
	-- Scale history: v1 480 / DISTANCE 152; v2 (x1.5) 720 / DISTANCE 228. River, road, bridge and town keep their
	-- real-world size; only the map, the plot distance and the land grew.
	SIZE = 720, -- playable square (±360); invisible walls sit on its edge
	MARGIN = 160, -- scenery ground outside the walls (woods + foothills; mountains rise behind it, see MapService)
	GRASS_DEPTH = 16,
	WALL_BOTTOM = -20,
	WALL_TOP = 120,

	-- v3 palette: lush grass, warm sandy paths, clear blue-green water (see Config/World for the light).
	GRASS_COLOR = Color3.fromRGB(104, 156, 60),
	SAND_COLOR = Color3.fromRGB(208, 180, 126),
	WATER_COLOR = Color3.fromRGB(20, 110, 200),

	RIVER = {
		WIDTH = 48,
		LENGTH = 1200, -- keeps the water inside the scenery ground at the corners
		DEPTH = 8, -- below ground level (y = 0)
		BED = 4, -- sand layer under the water
		WATER_Y = -1, -- water surface; 1 stud below the bank so swimmers can climb out
	},

	ROAD = {
		WIDTH = 28,
		LENGTH = 1200,
	},

	-- Deck spans the river along the road direction; buildings (the town) stand on it.
	BRIDGE = {
		SPAN = 72, -- along the road
		WIDTH = 64, -- along the river
		DECK_Y = 5,
		DECK_THICK = 1.5,
		RAMP = 28, -- ramp length at each end
	},

	-- Player land = the green wedge of the blueprint. SETBACK = min distance from BOTH the river axis and the road axis
	-- (river bank is 24 from its axis, road edge 14, so the public strip beside them is 4 / 14 studs; v3: SETBACK was 32).
	-- BACK_DISTANCE = how far from the map center the land reaches along its axis.
	LAND = { SETBACK = 28, BACK_DISTANCE = 352 }, -- v3: was 336; land now reaches 8 studs from the wall. DISTANCE - BACK_DISTANCE must be a multiple of 4 (terrain cell edges)

	-- Rumah panggung on every plot, in plot-local studs (X right, Z toward the front/road). HALF = no-build half size.
	HOUSE = { X = 30, Z = 24, HALF = 8, HEIGHT = 13 },

	DOCK = { LENGTH = 14, WIDTH = 5 },
	-- Fishing docks: t = distance from the center along the river (negative = NW arm). Both banks get a dock.
	-- Same river, same docks everywhere; only the fishing location differs: NW arm = Sungai (Lv1), SE arm = Empang (Lv4).
	RIVER_DOCKS = {
		{ t = -430, location = "sungai" },
		{ t = -350, location = "sungai" },
		{ t = -270, location = "sungai" },
		{ t = -190, location = "sungai" },
		{ t = -110, location = "sungai" },
		{ t = 110, location = "empang" },
		{ t = 190, location = "empang" },
		{ t = 270, location = "empang" },
		{ t = 350, location = "empang" },
		{ t = 430, location = "empang" },
	} :: { { t: number, location: string } },
	RIVER_SOUND_T = { -480, -380, -280, -180, -80, 80, 180, 280, 380, 480 },
}
