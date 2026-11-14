--!strict
-- Village plots (R2a): 10 identical 96 x 96 lands in a square ring around the center town, every plot facing the town.
-- Layout: south 3, north 3, west 2, east 2 (see docs/Map_Plan.md). Plots are axis-aligned (yaw = multiples of 90 degrees)
-- so the soil painted into the Terrain's 4-stud cells always lines up. Change SIDES to change the number of plots
-- (also set Game Settings > Places > Max Players to COUNT).
-- Each plot's local +Z (front / spawn side) faces the map center. If Workspace.Plots doesn't exist, placeholders are
-- built from this. Real plots: Workspace > Folder "Plots" > Model "Plot1".."PlotN", each with PrimaryPart "Origin"
-- (flat part, plot center). Optional TextLabel "OwnerLabel" anywhere inside shows the owner.
-- All coordinates are multiples of 4 (terrain cell edges): DISTANCE, PITCH / 2, SIZE / 2.

local DISTANCE = 240 -- plot center to map center, measured along the side's axis
local PITCH = 104 -- center to center of two neighbours on one side (96 land + an 8-stud lane)
local SIZE = 96

-- Plots of one side are centered on it, so counts of 3 sit at -104 / 0 / 104 and counts of 2 at -52 / 52.
local SIDES = {
	{ name = "south", dx = 0, dz = 1, yaw = math.pi, count = 3 },
	{ name = "north", dx = 0, dz = -1, yaw = 0, count = 3 },
	{ name = "west", dx = -1, dz = 0, yaw = math.pi / 2, count = 2 },
	{ name = "east", dx = 1, dz = 0, yaw = -math.pi / 2, count = 2 },
}

export type Slot = { name: string, x: number, z: number, yaw: number }

-- Lateral offsets of one side, middle plots first (so the first players are spread around the ring).
local function offsets(count: number): { number }
	local list = {}
	for i = 1, count do
		table.insert(list, (i - (count + 1) / 2) * PITCH)
	end
	table.sort(list, function(a, b)
		if math.abs(a) ~= math.abs(b) then
			return math.abs(a) < math.abs(b)
		end
		return a < b
	end)
	return list
end

-- Plot numbers go round-robin over the sides (south, north, west, east, then the next plot of each side ...).
local LAYOUT: { Slot } = {}
do
	local perSide = {}
	local most = 0
	for index, side in SIDES do
		perSide[index] = offsets(side.count)
		most = math.max(most, side.count)
	end
	for round = 1, most do
		for index, side in SIDES do
			local offset = perSide[index][round]
			if offset then
				-- Lateral axis = perpendicular to the side's axis.
				local lateralX = if side.dx == 0 then offset else 0
				local lateralZ = if side.dz == 0 then offset else 0
				table.insert(LAYOUT, {
					name = `{side.name}{round}`,
					x = side.dx * DISTANCE + lateralX,
					z = side.dz * DISTANCE + lateralZ,
					yaw = side.yaw,
				})
			end
		end
	end
end

return {
	COUNT = #LAYOUT,
	SIZE = SIZE, -- the land is exactly SIZE x SIZE, centered on the plot anchor (decor grid cell 0,0 = local -48,-48)
	DISTANCE = DISTANCE,
	PITCH = PITCH,
	FRONT_Z = SIZE / 2, -- the land ends here toward the town (plot-local z); plot-local z = -SIZE / 2 is the back

	-- World position and yaw of every plot (the plot's local +Z points at the map center).
	LAYOUT = LAYOUT,

	SPAWN_OFFSET = Vector3.new(-28, 4, -12), -- relative to Origin; just in front of the farm tiles
	GROUND_COLOR = Color3.fromRGB(134, 150, 104),
}
