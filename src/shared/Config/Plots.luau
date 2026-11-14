--!strict
-- Village plots (R2 ring map): 8 identical lands, two on each of the four axis roads (see Config/Map), one on each
-- side of the road, all FACING the road. Every plot has its own reserved square of REGION x REGION studs; the player
-- starts with a START x START land inside it, at the road end, and grows into the rest (R2b: buy 16-stud chunks).
-- Because every plot has the same square and the same start, all players start and finish with exactly the same land.
--
-- Plot-local frame: origin = center of the reserved square, +Z = toward the road (the front), +X = to the right.
--   reserved square : x, z in -96 .. 96            (192 x 192)
--   start land      : x in -64 .. 64, z in -32 .. 96  (128 x 128, flush with the road)
-- Plots are axis-aligned (yaw = multiples of 90 degrees) so the soil painted into the Terrain's 4-stud cells always
-- lines up; every coordinate here is a multiple of 4. Set Game Settings > Places > Max Players = COUNT.
-- If Workspace.Plots doesn't exist, placeholders are built from this. Real plots: Workspace > Folder "Plots" > Model
-- "Plot1".."PlotN", each with PrimaryPart "Origin" (flat part, plot center). Optional TextLabel "OwnerLabel".

local REGION = 192
local START = 128
local ROAD_HALF = 12 -- half width of the axis roads (Config/Map ROAD.HALF)
local INNER = ROAD_HALF + REGION -- half size of the inner square (town, ring road and plazas) = 204
local LATERAL = ROAD_HALF + REGION / 2 -- plot center, sideways from the axis = 108
local DEPTH = INNER + REGION / 2 -- plot center, along the axis = 300

export type Slot = { name: string, x: number, z: number, yaw: number }

-- yaw turns the plot's local +Z toward its road. Order = plot numbers: spread around the ring, so a server that is
-- not full still looks alive on every side.
local LAYOUT: { Slot } = {
	{ name = "south_left", x = -LATERAL, z = DEPTH, yaw = math.pi / 2 }, -- road is to the east
	{ name = "north_right", x = LATERAL, z = -DEPTH, yaw = -math.pi / 2 }, -- road is to the west
	{ name = "east_top", x = DEPTH, z = -LATERAL, yaw = 0 }, -- road is to the south
	{ name = "west_bottom", x = -DEPTH, z = LATERAL, yaw = math.pi }, -- road is to the north
	{ name = "south_right", x = LATERAL, z = DEPTH, yaw = -math.pi / 2 },
	{ name = "north_left", x = -LATERAL, z = -DEPTH, yaw = math.pi / 2 },
	{ name = "east_bottom", x = DEPTH, z = LATERAL, yaw = math.pi },
	{ name = "west_top", x = -DEPTH, z = -LATERAL, yaw = 0 },
}

return {
	COUNT = #LAYOUT,
	SIZE = REGION, -- reserved square; the decor grid's cell (0,0) is plot-local (-96, -96)
	START_SIZE = START,
	ROAD_HALF = ROAD_HALF,
	INNER = INNER, -- the plots' reserved squares start this far from the map center (along their axis)
	FRONT_Z = REGION / 2, -- the road side of the reserved square AND of the start land (plot-local z)

	-- World position and yaw of every plot (the plot's local +Z points at its road).
	LAYOUT = LAYOUT,

	-- Buying land (R2b): the player grows from the START land into the rest of the reserved square, one BLOCK at a time
	-- (SIZE x SIZE studs; called a "chunk" in the code). SIZE must divide 128 and 192 and line up with the start land:
	-- 32 gives a 6 x 6 grid in the square, 4 x 4 of it the start land, so 20 blocks can be bought. A block must touch
	-- land the player already owns. Price of the n-th extra block (n = 0 for the first): PRICE_BASE * PRICE_GROWTH ^ n,
	-- rounded to 10: #1 1.500, #5 3.110, #10 7.740, #15 19.260, #20 47.920; all 20 cost about 280.000 Koin (assumption,
	-- see tools/balance_sim.py). The game pass "plots" gives PASS_DISCOUNT off every block.
	CHUNK = { SIZE = 32, PRICE_BASE = 1500, PRICE_GROWTH = 1.2, PASS_DISCOUNT = 0.2 },

	SPAWN_OFFSET = Vector3.new(0, 4, 70), -- relative to Origin; inside the start land, in front of the house
	GROUND_COLOR = Color3.fromRGB(134, 150, 104),
}
