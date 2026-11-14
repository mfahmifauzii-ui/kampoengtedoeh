--!strict
-- Village plot layout: 4 plots in an X-shaped map (see Config/Map). 1 server = 4 players.
-- Each plot's local +Z (front / spawn side) faces the map center (the bridge town).
-- If Workspace.Plots doesn't exist, placeholders are built from this.
-- Real plots: Workspace > Folder "Plots" > Model "Plot1".."Plot4", each with PrimaryPart "Origin"
-- (flat part, plot center). Optional TextLabel "OwnerLabel" anywhere inside shows the owner.

return {
	COUNT = 4, -- also set Game Settings > Places > Max Players = 4
	SIZE = 96, -- reference frame of the decor grid (cell 0,0 = local -48,-48); the LAND itself is the wedge in Modules/Land
	DISTANCE = 228, -- plot anchor to map center (x1.5 of 152). Keep it a multiple of 4: terrain cells are 4 studs
	FRONT_Z = 104, -- the land ends here toward the town (plot-local z); keep it a multiple of 4 (terrain cell edges). v3: was 72 (front now 124 studs from the map center, about 40 from the bridge ramps)

	-- yaw makes the plot's local +Z point at the map center.
	LAYOUT = {
		{ name = "south", x = 0, z = 1, yaw = math.pi }, -- Plot1
		{ name = "west", x = -1, z = 0, yaw = math.pi / 2 }, -- Plot2
		{ name = "north", x = 0, z = -1, yaw = 0 }, -- Plot3
		{ name = "east", x = 1, z = 0, yaw = -math.pi / 2 }, -- Plot4
	} :: { { name: string, x: number, z: number, yaw: number } },

	SPAWN_OFFSET = Vector3.new(-28, 4, -12), -- relative to Origin; just in front of the farm tiles
	GROUND_COLOR = Color3.fromRGB(134, 150, 104),
}
