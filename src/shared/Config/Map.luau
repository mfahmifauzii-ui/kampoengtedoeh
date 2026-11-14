--!strict
-- Village map layout. All numbers in studs, origin (0,0,0) = bridge center.
--   Road  : SW -> NE diagonal.     River : NW -> SE diagonal.     They cross at the center bridge.
--   Plots : 10 lands in a square ring, 3 south / 3 north / 2 west / 2 east, all facing the town (see Config/Plots).
-- The river and the road split the ring into four sectors; a plot's corners stay >= 28 studs from both axes.
-- MapService builds all of it at server start unless Workspace.Map already exists (hand-built map).

return {
	-- Scale history: v1 480; v2 720 (x1.5, four huge wedge lands); R2a 608 (ten 96 x 96 lands, Config/Plots).
	-- River, road, bridge and town keep their real-world size.
	SIZE = 608, -- playable square (±304); invisible walls sit on its edge. Plots end 16 studs inside it (back = 288)
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

	-- (Player land: Config/Plots + Modules/Land. Its corners keep >= 28 studs from both axes: river bank is 24 from
	-- its axis and the road edge 14, so the public strip beside them is 4 / 14 studs.)

	-- Rumah panggung on every plot, in plot-local studs (X right, Z toward the front/road). HALF = no-build half size.
	HOUSE = { X = 30, Z = 24, HALF = 8, HEIGHT = 13 },

	DOCK = { LENGTH = 14, WIDTH = 5 },
	-- Fishing docks: t = distance from the center along the river (negative = NW arm). Both banks get a dock.
	-- Same river, same docks everywhere; only the fishing location differs: NW arm = Sungai (Lv1), SE arm = Empang (Lv4).
	-- R2a: the map shrank to ±304, so the docks moved in (t / sqrt 2 + the bank offset must stay inside the walls).
	RIVER_DOCKS = {
		{ t = -350, location = "sungai" },
		{ t = -290, location = "sungai" },
		{ t = -230, location = "sungai" },
		{ t = -170, location = "sungai" },
		{ t = -110, location = "sungai" },
		{ t = 110, location = "empang" },
		{ t = 170, location = "empang" },
		{ t = 230, location = "empang" },
		{ t = 290, location = "empang" },
		{ t = 350, location = "empang" },
	} :: { { t: number, location: string } },
	RIVER_SOUND_T = { -400, -320, -240, -160, -80, 80, 160, 240, 320, 400 },
}
