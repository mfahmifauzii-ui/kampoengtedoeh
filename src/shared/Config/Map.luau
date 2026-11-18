--!strict
-- Village map layout (R2 ring map). All numbers in studs, origin (0,0,0) = the middle of the town island.
--
--   CENTER : a round town island (banyan tree, warung, 8 shophouses) inside a circular canal, crossed by four plank
--            bridges at north / south / east / west.  Around the canal: a cobblestone ring road.
--   AXES   : a 24-stud dirt road runs from each bridge straight to the map edge (N / S / E / W).
--   PLOTS  : 8 identical lands, two on each axis road, one on each side of it, all facing the road (see Config/Plots).
--   CORNERS: the four diagonal corners are forest (rice terraces later); the part of each plot's reserved square that
--            is not yet owned is forest too, cleared when the player buys it (R2b).
-- MapService builds all of it at server start unless Workspace.Map already exists (hand-built map).
--
-- Scale history: v1 480; v2 720; R2a 608 (ten 96 lands); R2 ring 792 (eight lands, 128 start / 192 reserved).

local TOWN = {
	ISLAND_R = 90, -- the island (grass + plaza)
	CANAL_R = 130, -- outer edge of the water: the canal is ISLAND_R .. CANAL_R (40 wide)
	RING_R = 165, -- outer edge of the cobblestone ring road: the road is CANAL_R .. RING_R (35 wide)
	GROUND_Y = 2, -- the island's grass surface (measured y = 2.00); shops, NPCs and the spawn stand on it
	PLAZA_Y = 1.8, -- the cobblestone plaza around the tree (measured y = 1.80); the warung sits here
	-- The alun-alun: the banyan tree stands here (plaza center, plot-independent). Shops and the warung form a ring
	-- around it and face the tree; grass sits in a disk around the trunk, cobblestone everywhere else on the island.
	TREE_X = 0,
	TREE_Z = -22,
	-- The ring is centered on the banyan's CANOPY (its visual middle), not on the trunk. The trunk stays at TREE_Z (grass).
	RING_X = 0,
	RING_Z = -3,
	-- SHOP_R, not RING_R: this key used to be a second RING_R that overwrote the ring road's 165 (Lua keeps the last key),
	-- so the cobblestone ring road was never built. Shops and the warung still use 62 (footprint centers, measured from
	-- the canopy center; fits inside ISLAND_R with the footprint).
	SHOP_R = 62,
	STAND_IN = 12, -- the shopkeeper stands this far in from the shop's center, just in front of its front wall (~9 studs deep)
	GRASS_R = 22, -- grass disk around the trunk (covers the base under the canopy)
}

-- The warung stall on the ring, on the south side of the tree (the side the bridge customers come from).
-- Its counter faces the tree (yaw pi: local +Z points north, toward the tree); Pak Darmo stands behind it, on the
-- south side (see Config/Npcs).
local WARUNG = { x = TOWN.RING_X, z = TOWN.RING_Z + TOWN.SHOP_R, FLOOR_Y = 7.05, yaw = math.pi } -- FLOOR_Y: top of the warung's wooden floor (the seller stands on it)

export type Shop = { x: number, z: number, yaw: number, standX: number, standZ: number, standYaw: number }

-- 8 shops on the ring around the tree. The warung takes the south slot (90 degrees from +X toward +Z), the 8 shops
-- take the other 8 slots, 40 degrees apart: 130, 170, 210, 250, 290, 330, 10, 50 degrees. yaw = the shop's yaw so its
-- front (local +Z) faces the tree; standYaw = the same direction for an NPC rig (a rig looks toward its local -Z, so
-- the yaw is a half turn different).
local SHOPS: { Shop } = {}
for slot = 1, 8 do
	local angle = math.rad(90 + 40 * slot)
	local c, s = math.cos(angle), math.sin(angle)
	local standR = TOWN.SHOP_R - TOWN.STAND_IN
	table.insert(SHOPS, {
		x = TOWN.RING_X + TOWN.SHOP_R * c,
		z = TOWN.RING_Z + TOWN.SHOP_R * s,
		yaw = math.atan2(-c, -s),
		standX = TOWN.RING_X + standR * c,
		standZ = TOWN.RING_Z + standR * s,
		standYaw = math.atan2(c, s),
	})
end

-- Fishing docks: both banks of the canal, 8 angles each (degrees from +X toward +Z), away from the bridges.
-- West half of the canal = Sungai (Basic Mancing, Lv2), east half = Empang (Pro Mancing, Lv10): same water, same docks; only the fishing
-- location differs.
local DOCKS: { { angle: number, bank: string, location: string } } = {}
for _, bank in { "outer", "inner" } do
	for _, angle in { 27, 63, 117, 153, 207, 243, 297, 333 } do
		table.insert(DOCKS, {
			angle = angle,
			bank = bank,
			location = if math.cos(math.rad(angle)) < 0 then "sungai" else "empang",
		})
	end
end

return {
	SIZE = 792, -- playable square (±396); invisible walls sit on its edge. Plots end at the walls (back = 396)
	MARGIN = 160, -- scenery ground outside the walls (woods + foothills; mountains rise behind it, see MapService)
	GRASS_DEPTH = 16,
	WALL_BOTTOM = -20,
	WALL_TOP = 120,

	-- v3 palette: lush grass, warm sandy paths, clear blue-green water (see Config/World for the light).
	GRASS_COLOR = Color3.fromRGB(104, 156, 60),
	SAND_COLOR = Color3.fromRGB(208, 180, 126),
	WATER_COLOR = Color3.fromRGB(20, 110, 200),
	COBBLE_COLOR = Color3.fromRGB(150, 140, 128),
	DIRT_COLOR = Color3.fromRGB(176, 136, 94),
	FOREST_COLOR = Color3.fromRGB(70, 120, 52), -- forest floor (the not-yet-owned ground and the corners)

	TOWN = TOWN,
	WARUNG = WARUNG,
	SHOPS = SHOPS,

	-- Water (the canal). PondService reuses WATER_Y for the player ponds.
	RIVER = {
		DEPTH = 8, -- below ground level (y = 0)
		BED = 4, -- sand layer under the water
		WATER_Y = -1, -- water surface; 1 stud below the bank so swimmers can climb out
	},

	-- Axis roads (from each bridge to the walls): HALF = half width, so the road is 24 wide. Plots start at HALF.
	ROAD = { HALF = 12 },

	-- The four plank bridges over the canal, along the axes.
	BRIDGE = { WIDTH = 24, DECK_Y = 0.6, THICK = 1 },

	DOCK = { LENGTH = 14, WIDTH = 5 },
	DOCKS = DOCKS,
	-- Water sound emitters along the canal (degrees from +X toward +Z), at the canal's mid radius.
	CANAL_SOUND_ANGLES = { 0, 45, 90, 135, 180, 225, 270, 315 },
}
