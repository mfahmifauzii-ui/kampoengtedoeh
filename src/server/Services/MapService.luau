--!strict
-- Builds the village map at server start (R2 ring map, see Config/Map and docs/Map_Plan.md):
-- terrain + a circular canal around the town island, a cobblestone ring road, four axis roads with plank bridges,
-- the town island (banyan tree, warung, 8 shophouses), docks with fishing spots, lamps, forest on the not-yet-owned
-- parts of every plot's reserved square, edge trees and invisible walls.
-- If Workspace.Map already exists (hand-built map), nothing is generated.
--
-- Real models: put Models named "Warung", "TokoKota" (town shophouse) in
-- ServerStorage > MapModels. They replace the placeholders automatically. Each is scaled to the
-- height used here and rotated by its numeric attribute "FrontYaw" (degrees) so its front faces the road.
--
-- World contract with other services: Workspace.Fishing (spots). NPCs: MapService.TownCFrame places them (NpcService).
-- Forest models on a plot's unowned ground carry the attribute ExpansionOf = <plot number> (R2b clears them when
-- the player buys that ground).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Map = require(ReplicatedStorage.Shared.Config.Map)
local Plots = require(ReplicatedStorage.Shared.Config.Plots)
local ShopPalette = require(ReplicatedStorage.Shared.Config.ShopPalette)
local Land = require(ReplicatedStorage.Shared.Modules.Land)

local TOWN = Map.TOWN
local ROAD_HALF = Map.ROAD.HALF
local DECK_Y = Map.BRIDGE.DECK_Y
-- The four axis directions (east, west, south, north): roads, bridges and lamps run along them.
local AXES = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
-- The river runs out along each axis (where the old axis roads were): 12 studs wide, half-width here (see buildTerrain).
local RIVER_HALF = 6
local GATE_WIDTH = 33.3 -- the plot gate's opening (= 2 * GATE_HALF in the fences section)

local C = {
	ASPHALT = Color3.fromRGB(70, 68, 66),
	LINE = Color3.fromRGB(226, 218, 190),
	STONE = Color3.fromRGB(142, 136, 124),
	PLANK = Color3.fromRGB(150, 114, 78),
	DARKWOOD = Color3.fromRGB(96, 70, 50),
	BAMBOO = Color3.fromRGB(196, 176, 120),
	CREAM = Color3.fromRGB(226, 214, 186),
	TERRACOTTA = Color3.fromRGB(196, 100, 64),
	SAGE = Color3.fromRGB(140, 176, 112),
	DUSTY_BLUE = Color3.fromRGB(104, 150, 182),
	MUSTARD = Color3.fromRGB(228, 176, 76),
	LEAF = Color3.fromRGB(88, 158, 62),
	LEAF_DARK = Color3.fromRGB(58, 124, 56),
	GLASS = Color3.fromRGB(190, 208, 204),
}

local MapService = {}
local builtMap: Folder? = nil -- set by Init when this service generated the map (not a hand-built Workspace.Map)

-- Land you can buy (R2b). The forest on a plot's not-yet-owned ground is tagged ExpansionOf = plot number and indexed
-- here by plot and chunk key; buying a chunk hides the trees on it (parked in ServerStorage > ForestHidden) and paints
-- it bright grass, giving the chunk back un-owns it again (a new player may get this plot next).
local forestByPlot: { [number]: { [string]: { Model } } } = {}
local chunkOwned: { [number]: { [string]: boolean } } = {}
local natureFolder: Folder? = nil
local hiddenFolder: Folder? = nil
local fenceRoot: Folder? = nil

local function setForestHidden(plotIndex: number, key: string, hidden: boolean)
	local byKey = forestByPlot[plotIndex]
	local list = byKey and byKey[key]
	if not list or not natureFolder or not hiddenFolder then
		return
	end
	for _, model in list do
		model.Parent = if hidden then hiddenFolder else natureFolder
	end
end

-- Hides the forest on chunks that were bought before the trees existed (a player can join while the map is still building).
local function applyForestVisibility()
	for plotIndex, states in chunkOwned do
		for key in states do
			setForestHidden(plotIndex, key, true)
		end
	end
end


-- Helpers ---------------------------------------------------------------------------------

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function block(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function ghost(part: Part)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

local function getTemplate(name: string): Model?
	local models = ServerStorage:FindFirstChild("MapModels")
	local template = models and models:FindFirstChild(name)
	return if template and template:IsA("Model") then template else nil
end

-- Clones an imported model, scales it to targetHeight, applies its FrontYaw, centers it on cf and rests it on cf's height.
local function placeTemplate(template: Model, parent: Instance, name: string, cf: CFrame, targetHeight: number): Model
	local model = template:Clone()
	model.Name = name
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			-- Recolourable shop models: an untextured MeshPart named after a ShopPalette slot takes its colour + material.
			local slot = ShopPalette[descendant.Name]
			if slot and not (descendant:IsA("MeshPart") and descendant.TextureID ~= "") then
				descendant.Color = slot.Color
				descendant.Material = slot.Material
			end
		end
	end
	local _, size = model:GetBoundingBox()
	if size.Y > 0 then
		model:ScaleTo(model:GetScale() * targetHeight / size.Y)
	end
	local yaw = model:GetAttribute("FrontYaw")
	model:PivotTo(cf * CFrame.Angles(0, math.rad(if typeof(yaw) == "number" then yaw else 0), 0))
	local boxCFrame, boxSize = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(cf.X - boxCFrame.X, cf.Y - (boxCFrame.Y - boxSize.Y / 2), cf.Z - boxCFrame.Z))
	model.Parent = parent
	return model
end

local function lampPost(parent: Instance, cf: CFrame)
	local lampTemplate = getTemplate("LampuJalanBambu")
	if lampTemplate then
		-- Imported bamboo lamp (6 studs). Its bulb is the part named bola_lampu: it gets the same DecorLight tag and light.
		local lamp = placeTemplate(lampTemplate, parent, "Lamp", cf, 6)
		local bulb = lamp:FindFirstChild("bola_lampu", true)
		if bulb and bulb:IsA("BasePart") then
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 214, 160)
			light.Brightness = 1.2
			light.Range = 16
			light.Shadows = false
			light.Enabled = false -- WorldController switches DecorLight lamps on at night
			light.Parent = bulb
			CollectionService:AddTag(bulb, "DecorLight")
		end
		return
	end
	block(parent, "Pole", Vector3.new(0.5, 7, 0.5), cf * CFrame.new(0, 3.5, 0), C.DARKWOOD, Enum.Material.Wood)
	local bulb = block(parent, "Lamp", Vector3.new(1.3, 1.3, 1.3), cf * CFrame.new(0, 7.4, 0), Color3.fromRGB(236, 206, 150))
	bulb.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 160)
	light.Brightness = 1.2
	light.Range = 16
	light.Shadows = false
	light.Enabled = false -- WorldController switches DecorLight lamps on at night
	light.Parent = bulb
	CollectionService:AddTag(bulb, "DecorLight")
end

-- Terrain ---------------------------------------------------------------------------------

-- Back range (the far row, behind the other two): faceted, saturated peaks in three layers, after the low-poly reference:
-- lush grass on the lower slopes, grey rock in the middle, pale snow on the upper slopes and the crest. Wide, soft
-- ridges (few crossing peaks, so no spikes) that still read as ONE range. Own random seed: the two rows in front keep their shapes.
-- Snow is the Terrain material Snow (its color is set in buildTerrain).
local function backRange(terrain: Terrain)
	local random = Random.new(7741)
	local half = Map.SIZE / 2
	local BASE_DEPTH = 6 -- same as buildMountains: ridges start this far below the ground
	local INNER = half + 110 -- same as buildMountains: the woods stay free
	local FOOT = 230 -- same distance as the old back row

	-- A horizontal slab of one ridge between `bottom` and `top`, `base` studs wide on each side of the crest line.
	local function prism(frame: CFrame, length: number, bottom: number, top: number, base: number, material: Enum.Material)
		local sizeY = top - bottom
		local centerY = (top + bottom) / 2
		terrain:FillWedge(frame * CFrame.new(0, centerY, -base / 2), Vector3.new(length, sizeY, base), material)
		terrain:FillWedge(frame * CFrame.new(0, centerY, base / 2) * CFrame.Angles(0, math.pi, 0), Vector3.new(length, sizeY, base), material)
	end

	-- One peak: green over the whole ridge, rock from 50% of its height, snow from 78% up. Each layer is the same slope
	-- shifted up a little (like the rock skin in buildMountains), so the layers sit on each other without seams.
	local function peak(x: number, z: number, yaw: number, length: number, height: number, halfBase: number)
		local frame = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
		local top = height * 1.06
		local slope = halfBase / (height + BASE_DEPTH)
		prism(frame, length, -BASE_DEPTH, height, halfBase, Enum.Material.LeafyGrass)
		local rockFrom = height * 0.5
		prism(frame, length, rockFrom, top, (top - rockFrom) * slope, Enum.Material.Rock)
		local snowFrom = height * 0.78
		prism(frame, length, snowFrom, top, (top - snowFrom) * slope, Enum.Material.Snow)
	end

	local reach = INNER + 340 * 1.5 + 260
	for side = 0, 3 do
		local rotation = CFrame.Angles(0, side * math.pi / 2, 0)
		local along = -reach
		while along <= reach do
			local height = random:NextNumber(140, 200)
			local length = random:NextNumber(200, 300)
			local halfBase = height * random:NextNumber(1.25, 1.6) -- wide, soft slopes (not spiky)
			local distance = INNER + FOOT + halfBase + random:NextNumber(0, 30)
			local center = rotation * Vector3.new(along, 0, distance)
			local yaw = side * math.pi / 2 + random:NextNumber(-0.5, 0.5)
			peak(center.X, center.Z, yaw, length, height, halfBase)

			-- A taller, shorter ridge crossing it, so the crest breaks into several peaks.
			if random:NextNumber() < 0.25 then
				local peakHeight = height * random:NextNumber(1.0, 1.15)
				local offset = rotation * Vector3.new(along + random:NextNumber(-0.3, 0.3) * length, 0, distance)
				peak(
					offset.X,
					offset.Z,
					yaw + math.pi / 2 + random:NextNumber(-0.4, 0.4),
					length * random:NextNumber(0.4, 0.6),
					peakHeight,
					halfBase * peakHeight / height
				)
			end
			along += 260 * random:NextNumber(0.6, 1.0)
		end
	end
end

-- Mountains: three rows of terrain RIDGES around the map (foothills, a range, a tall back range), so the camera never
-- sees the void or the horizon. A ridge is a long triangular prism (two terrain wedges back to back) with steep,
-- straight slopes and a sharp crest; ridges lean at random angles, vary in height and cross each other, and the tall
-- ones get a taller crossing "peak" and a rock skin on their upper part. This reads as mountains, where the earlier
-- overlapping balls read as round hills. Terrain only (no parts), a few seconds of work at most (measured ~1 s).
-- WEDGE ORIENTATION (measured with ReadVoxels): FillWedge(cf, size) rises toward the wedge's local +Z, its vertical
-- wall is at +Z, and X is the length along the crest.
local function buildMountains(terrain: Terrain)
	local random = Random.new(2411)
	local half = Map.SIZE / 2
	local BASE_DEPTH = 6 -- ridges start this far below the ground so no seam shows
	local INNER = half + 110 -- the foot of every slope stays this far from the center: the woods stay free

	-- One ridge: crest along the local X of (x, z, yaw), crest height `height`, `halfBase` studs from crest to foot.
	local function ridge(x: number, z: number, yaw: number, length: number, height: number, halfBase: number, rockFrom: number?)
		local frame = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
		local function prism(bottom: number, top: number, base: number, material: Enum.Material)
			local sizeY = top - bottom
			local centerY = (top + bottom) / 2
			terrain:FillWedge(frame * CFrame.new(0, centerY, -base / 2), Vector3.new(length, sizeY, base), material)
			terrain:FillWedge(frame * CFrame.new(0, centerY, base / 2) * CFrame.Angles(0, math.pi, 0), Vector3.new(length, sizeY, base), material)
		end
		prism(-BASE_DEPTH, height, halfBase, Enum.Material.LeafyGrass)
		if rockFrom then
			-- Rock skin: the same slope shifted up a little, from `rockFrom` to just above the crest.
			local slope = halfBase / (height + BASE_DEPTH)
			local top = height * 1.06
			prism(rockFrom, top, (top - rockFrom) * slope, Enum.Material.Rock)
		end
	end

	-- One row: ridges along the four sides, in a band set by the height range.
	local function row(foot: number, minHeight: number, maxHeight: number, minLength: number, maxLength: number, spacing: number)
		for side = 0, 3 do
			local rotation = CFrame.Angles(0, side * math.pi / 2, 0)
			local tangentYaw = side * math.pi / 2 -- crest direction along the side
			local reach = INNER + maxHeight * 1.5 + maxLength
			local along = -reach
			while along <= reach do
				local height = random:NextNumber(minHeight, maxHeight)
				local length = random:NextNumber(minLength, maxLength)
				local halfBase = height * random:NextNumber(0.95, 1.35)
				local distance = INNER + foot + halfBase + random:NextNumber(0, 30)
				local center = rotation * Vector3.new(along, 0, distance)
				local yaw = tangentYaw + random:NextNumber(-0.5, 0.5)
				local rockFrom = if height >= 90 then height * random:NextNumber(0.45, 0.65) else nil
				ridge(center.X, center.Z, yaw, length, height, halfBase, rockFrom)

				-- A taller, shorter ridge across the first one makes a peak where they meet.
				if height >= 90 and random:NextNumber() < 0.75 then
					local peakHeight = height * random:NextNumber(1.15, 1.35)
					local offset = rotation * Vector3.new(along + random:NextNumber(-0.25, 0.25) * length, 0, distance)
					ridge(
						offset.X,
						offset.Z,
						yaw + math.pi / 2 + random:NextNumber(-0.45, 0.45),
						length * random:NextNumber(0.4, 0.6),
						peakHeight,
						halfBase * peakHeight / height,
						peakHeight * random:NextNumber(0.4, 0.55)
					)
				end
				along += spacing * random:NextNumber(0.55, 1.0)
			end
		end
	end

	row(0, 20, 40, 90, 160, 110) -- foothills, right behind the woods (between the old and the lowered heights)
	row(70, 75, 120, 130, 240, 170) -- the range, its foot behind the foothills (between the old and the lowered heights)
	backRange(terrain) -- tall back range: faceted green/rock/snow peaks (see backRange above)
end

-- Stylized PBR materials (MaterialService > MaterialVariants made for this map): used for the terrain and for any
-- part of that base material. Applied only when the variant exists; the place also stores the overrides.
local STYLIZED_MATERIALS: { { material: Enum.Material, variant: string } } = {
	{ material = Enum.Material.LeafyGrass, variant = "LeafyStylized" }, -- player lands + outer woods
	{ material = Enum.Material.Grass, variant = "GrassStylized" },
	{ material = Enum.Material.Ground, variant = "GroundStylized" }, -- tilled soil
	{ material = Enum.Material.Rock, variant = "RockStylized" }, -- mountain tops
}

local function applyStylizedMaterials()
	local materials = game:GetService("MaterialService")
	for _, entry in STYLIZED_MATERIALS do
		if materials:FindFirstChild(entry.variant) then
			local ok, err = pcall(function()
				materials:SetBaseMaterialOverride(entry.material, entry.variant)
			end)
			if not ok then
				warn(`[MapService] Could not apply {entry.variant}: {err}`)
			end
		end
	end
end

local function buildTerrain()
	local terrain = Workspace.Terrain
	applyStylizedMaterials()
	terrain:Clear()
	local river = Map.RIVER
	local total = Map.SIZE + Map.MARGIN * 2

	-- Public ground is sand-colored; only the START x START part of every plot is green (LeafyGrass: flat grass
	-- texture, Material.Grass would grow 3D blades that hide roads and docks).
	-- MEASURED in Studio: the terrain surface sits Land.SURFACE_OFFSET (2) studs ABOVE the top of a filled block,
	-- so every block is lowered by that much to put the visible ground at y = 0 (roads, docks, plots assume y = 0).
	-- Terrain cells are 4 studs with edges at multiples of 4; a block paints a cell when the cell's center is inside it
	-- (see Land), so the paint blocks below are 0.5 smaller than the cells they fill.
	local drop = -Land.SURFACE_OFFSET
	terrain:FillBlock(CFrame.new(0, -Map.GRASS_DEPTH / 2 + drop, 0), Vector3.new(total, Map.GRASS_DEPTH, total), Enum.Material.Sand)
	-- Every plot's reserved square is LeafyGrass by default (the whole Garap grid, including the part the player does not
	-- own yet), so the grid never sits on a different material. The four corners between the plots stay dark Grass (forest
	-- floor). Trees stand on it (see buildNature); the start land is painted bright on top of it.
	local region = Plots.SIZE
	for _, slot in Plots.LAYOUT do
		terrain:FillBlock(CFrame.new(slot.x, -2 + drop, slot.z), Vector3.new(region - 0.5, 4, region - 0.5), Enum.Material.LeafyGrass)
	end
	local cornerCenter = Plots.INNER + region / 2
	for _, sx in { 1, -1 } do
		for _, sz in { 1, -1 } do
			terrain:FillBlock(CFrame.new(sx * cornerCenter, -2 + drop, sz * cornerCenter), Vector3.new(region - 0.5, 4, region - 0.5), Enum.Material.Grass)
		end
	end
	for _, slot in Plots.LAYOUT do
		local frame = CFrame.new(slot.x, 0, slot.z) * CFrame.Angles(0, slot.yaw, 0)
		terrain:FillBlock(
			frame * CFrame.new(0, -2 + drop, Land.CENTER_Z),
			Vector3.new(Land.HALF * 2 - 0.5, 4, Land.HALF * 2 - 0.5),
			Enum.Material.LeafyGrass
		)
	end

	-- Village woods: the scenery ground outside the walls is grass too (a 4-stud top layer, same recipe as the lands).
	local inner, outer = Map.SIZE / 2, Map.SIZE / 2 + Map.MARGIN
	local ringWidth = Map.MARGIN - 0.5 -- 0.5 short of the wall line, like the paint blocks above
	for _, sign in { 1, -1 } do
		local mid = sign * (inner + outer) / 2
		terrain:FillBlock(CFrame.new(0, -2 + drop, mid), Vector3.new(total, 4, ringWidth), Enum.Material.LeafyGrass)
		terrain:FillBlock(CFrame.new(mid, -2 + drop, 0), Vector3.new(ringWidth, 4, Map.SIZE), Enum.Material.LeafyGrass)
	end

	local started = os.clock()
	buildMountains(terrain)
	print(`[MapService] mountains built in {string.format("%.2f", os.clock() - started)}s`)

	-- Town: a cobblestone disc out to RING_R (the ring road), then the canal is carved through its middle and the
	-- island is filled back inside the canal.
	terrain:FillCylinder(CFrame.new(0, -2 + drop, 0), 4, TOWN.RING_R, Enum.Material.Cobblestone)
	local function disc(top: number, bottom: number, radius: number, material: Enum.Material)
		terrain:FillCylinder(CFrame.new(0, (top + bottom) / 2 + drop, 0), top - bottom, radius, material)
	end
	disc(0, -river.DEPTH, TOWN.CANAL_R, Enum.Material.Air)
	-- Water is the exception to the +2 rule (MEASURED: its surface is exactly the top of the block), so undo the drop.
	disc(river.WATER_Y - drop, -river.DEPTH, TOWN.CANAL_R, Enum.Material.Water)
	disc(-river.DEPTH, -river.DEPTH - river.BED, TOWN.CANAL_R, Enum.Material.Sand)
	-- Island: solid up to ground level, grass on top, a cobblestone plaza around the tree.
	disc(0, -river.DEPTH, TOWN.ISLAND_R, Enum.Material.Sand)
	terrain:FillCylinder(CFrame.new(0, -2 + drop, 0), 4, TOWN.ISLAND_R, Enum.Material.LeafyGrass)
	terrain:FillCylinder(CFrame.new(0, -2 + drop, 0), 4, 40, Enum.Material.Cobblestone)

	-- The river (v2, alun-alun): the four old axis roads are water now, from the canal out to the map edge. Same levels
	-- as the canal (air above, water to WATER_Y, sand bed under it). Each axis strip is one block per layer.
	local function riverBlock(top: number, bottom: number, material: Enum.Material)
		for _, dir in AXES do
			local from, to = TOWN.CANAL_R - 8, Map.SIZE / 2
			local length = to - from
			local center = dir * ((from + to) / 2)
			local size = if dir.X ~= 0 then Vector3.new(length, top - bottom, RIVER_HALF * 2) else Vector3.new(RIVER_HALF * 2, top - bottom, length)
			terrain:FillBlock(CFrame.new(center.X, (top + bottom) / 2 + drop, center.Z), size, material)
		end
	end
	riverBlock(0, -river.DEPTH, Enum.Material.Air)
	riverBlock(river.WATER_Y - drop, -river.DEPTH, Enum.Material.Water) -- water: exact top, like the canal
	riverBlock(-river.DEPTH, -river.DEPTH - river.BED, Enum.Material.Sand)

	pcall(function()
		terrain.Decoration = false -- no 3D grass blades anywhere
	end)
	-- Terrain colors MULTIPLY a PBR variant's own colors (a brown tint on a brown texture came out dark red), so
	-- materials that have a stylized variant get a near-white tint and show the texture; the others keep our colors.
	local materialService = game:GetService("MaterialService")
	local function tint(material: Enum.Material, variant: string, color: Color3, withVariant: Color3)
		terrain:SetMaterialColor(material, if materialService:FindFirstChild(variant) then withVariant else color)
	end
	tint(Enum.Material.LeafyGrass, "LeafyStylized", Map.GRASS_COLOR, Color3.fromRGB(246, 255, 232))
	tint(Enum.Material.Ground, "GroundStylized", Farm.SOIL_DRY, Color3.fromRGB(150, 150, 140)) -- tilled soil (FarmService); the variant is bright orange-red, so tint it toward brown
	terrain:SetMaterialColor(Enum.Material.Mud, Farm.SOIL_WET) -- watered soil
	terrain:SetMaterialColor(Enum.Material.Sand, Map.SAND_COLOR)
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Map.COBBLE_COLOR)
	tint(Enum.Material.Grass, "GrassStylized", Map.FOREST_COLOR, Color3.fromRGB(176, 206, 150)) -- forest floor: darker than the start land
	tint(Enum.Material.Rock, "RockStylized", Color3.fromRGB(110, 102, 92), Color3.fromRGB(189, 189, 189)) -- mountain tops (white was too bright, 128/120/110 too dark)
	terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(236, 242, 248)) -- back range caps: pale, not pure white
	terrain.WaterColor = Map.WATER_COLOR
	terrain.WaterTransparency = 0.5 -- was 0.8: the sand bed showed through and the canal looked muddy
	terrain.WaterReflectance = 0.2 -- less sky/white sheen, so the blue reads deeper
	terrain.WaterWaveSize = 0.08
	terrain.WaterWaveSpeed = 6
end

-- Roads -----------------------------------------------------------------------------------

-- A world-space block along an axis direction: length along the axis, width across it.
local function axisBlock(parent: Instance, name: string, dir: Vector3, from: number, to: number, width: number, y: number, thick: number, color: Color3, material: Enum.Material): Part
	local length = to - from
	local size = if dir.X ~= 0 then Vector3.new(length, thick, width) else Vector3.new(width, thick, length)
	return block(parent, name, size, CFrame.new(dir * (from + length / 2) + Vector3.new(0, y, 0)), color, material)
end

local function buildRoad(map: Folder)
	local lamps = folder(map, "Lamps")

	-- The axis roads are the river now (buildTerrain), so there are no axis roads or axis lamps. Each plot's gate
	-- has a dirt path to the ring road instead (buildPaths).

	-- Lamps around the ring road's outer edge, except where an axis road meets it.
	local count = 24
	for i = 0, count - 1 do
		local angle = math.rad(i * 360 / count + 7.5)
		local c, s = math.cos(angle), math.sin(angle)
		if math.abs(c) < 0.97 and math.abs(s) < 0.97 then
			lampPost(lamps, CFrame.new((TOWN.RING_R + 2) * c, 0, (TOWN.RING_R + 2) * s))
		end
	end
end

-- Gate paths: from each plot's gate (the middle of its front, facing the alun-alun) straight to the ring road, the same
-- width as the gate opening. The ring road is the stop: the path ends a little inside its outer edge.
local function buildPaths(map: Folder)
	local road = folder(map, "Road")
	for _, slot in Plots.LAYOUT do
		local frame = CFrame.new(slot.x, 0, slot.z) * CFrame.Angles(0, slot.yaw, 0)
		local gate = (frame * CFrame.new(0, 0, Land.FRONT_Z)).Position
		local front = frame:VectorToWorldSpace(Vector3.new(0, 0, 1))
		local gx, gz = gate.X, gate.Z
		local fx, fz = front.X, front.Z
		-- Walk from the gate toward the center until the ring road's outer edge (smaller root of |g + t f| = R - 2).
		local stop = TOWN.RING_R - 2
		local b = 2 * (gx * fx + gz * fz)
		local c = gx * gx + gz * gz - stop * stop
		local disc = b * b - 4 * c
		if disc > 0 then
			local t = (-b - math.sqrt(disc)) / 2
			local from, to = -2, t + 1 -- a little into the plot (meets the fence gate), a little into the ring road
			local mid = Vector3.new(gx + fx * (from + to) / 2, 0.15, gz + fz * (from + to) / 2)
			local look = mid + Vector3.new(fx, 0, fz)
			block(road, "GatePath", Vector3.new(GATE_WIDTH, 0.3, to - from), CFrame.lookAt(mid, look), Map.DIRT_COLOR, Enum.Material.Sand)
		end
	end
end

-- Bridges + town island -------------------------------------------------------------------

-- Four plank bridges over the canal, along the axes, from the island to the ring road.
local function buildBridge(map: Folder)
	local b = Map.BRIDGE
	local bridge = folder(map, "Bridge")
	local fromR, toR = TOWN.ISLAND_R - 4, TOWN.CANAL_R + 4
	local length = toR - fromR

	for _, dir in AXES do
		local frame = CFrame.new(dir * ((fromR + toR) / 2)) * (if dir.X ~= 0 then CFrame.identity else CFrame.Angles(0, math.pi / 2, 0))
		block(bridge, "Deck", Vector3.new(length, b.THICK, b.WIDTH), frame * CFrame.new(0, DECK_Y - b.THICK / 2, 0), C.PLANK, Enum.Material.WoodPlanks)
		for _, zSign in { 1, -1 } do
			local z = zSign * (b.WIDTH / 2 - 0.3)
			block(bridge, "RailTop", Vector3.new(length, 0.3, 0.3), frame * CFrame.new(0, DECK_Y + 1.3, z), C.DARKWOOD, Enum.Material.Wood)
			block(bridge, "RailMid", Vector3.new(length, 0.2, 0.2), frame * CFrame.new(0, DECK_Y + 0.7, z), C.DARKWOOD, Enum.Material.Wood)
			local x = -length / 2 + 2
			while x <= length / 2 - 2 do
				block(bridge, "RailPost", Vector3.new(0.4, 1.4, 0.4), frame * CFrame.new(x, DECK_Y + 0.7, z), C.DARKWOOD, Enum.Material.Wood)
				x += 6
			end
		end
	end

	-- The ring road crosses the river on each axis: a short plank deck over it, so the ring road stays walkable.
	for _, dir in AXES do
		local ringMid = (TOWN.CANAL_R + TOWN.RING_R) / 2
		local frame = CFrame.new(dir * ringMid) * (if dir.X ~= 0 then CFrame.identity else CFrame.Angles(0, math.pi / 2, 0))
		block(bridge, "RingDeck", Vector3.new(TOWN.RING_R - TOWN.CANAL_R + 8, b.THICK, RIVER_HALF * 2 + 8), frame * CFrame.new(0, DECK_Y - b.THICK / 2, 0), C.PLANK, Enum.Material.WoodPlanks)
	end
end

local function addSignText(sign: Part, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- the building front is local +Z, which is a part's Back face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = C.CREAM
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
end

-- cf = footprint center on the floor; front of the shop faces local +Z.
local function buildShop(parent: Instance, name: string, cf: CFrame, w: number, d: number, h: number, wall: Color3, roof: Color3, awning: Color3, signText: string)
	local template = getTemplate("TokoKota")
	if template then
		placeTemplate(template, parent, name, cf, h + 6) -- the imported shophouse has two floors
		return
	end
	local model = Instance.new("Model")
	model.Name = name
	block(model, "Walls", Vector3.new(w, h, d), cf * CFrame.new(0, h / 2, 0), wall, Enum.Material.SmoothPlastic)
	block(model, "Roof", Vector3.new(w + 1.5, 0.6, d + 3), cf * CFrame.new(0, h + 0.7, 0.2) * CFrame.Angles(math.rad(12), 0, 0), roof, Enum.Material.Slate)

	local door = block(model, "Door", Vector3.new(3, 5.2, 0.3), cf * CFrame.new(-w / 4, 2.6, d / 2 + 0.1), C.DARKWOOD, Enum.Material.Wood)
	door.CanCollide = false
	local window = block(model, "Window", Vector3.new(4.5, 3.2, 0.3), cf * CFrame.new(w / 4, 3.6, d / 2 + 0.1), C.GLASS, Enum.Material.Glass)
	window.CanCollide = false
	block(model, "Awning", Vector3.new(w - 3, 0.3, 3.2), cf * CFrame.new(w / 8, 6.4, d / 2 + 1.4) * CFrame.Angles(math.rad(18), 0, 0), awning, Enum.Material.Fabric)

	local sign = block(model, "Sign", Vector3.new(w - 4, 1.8, 0.4), cf * CFrame.new(0, h - 1.2, d / 2 + 0.2), C.DARKWOOD, Enum.Material.Wood)
	addSignText(sign, signText)
	model.Parent = parent
end

-- A big banyan tree in the middle of the island (procedural: trunk, a crown of squashed spheres, aerial roots).
local function buildBanyan(parent: Instance)
	local tree = Instance.new("Model")
	tree.Name = "Banyan"
	local function cylinder(name: string, height: number, diameter: number, position: Vector3, color: Color3, collide: boolean)
		local part = block(tree, name, Vector3.new(height, diameter, diameter), CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), color, Enum.Material.Wood)
		part.Shape = Enum.PartType.Cylinder
		part.CanCollide = collide
	end
	local function crown(position: Vector3, size: Vector3, color: Color3)
		local part = block(tree, "Crown", size, CFrame.new(position), color, Enum.Material.Grass)
		part.CanCollide = false
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end

	cylinder("Trunk", 18, 7, Vector3.new(0, 9, 0), C.DARKWOOD, true)
	crown(Vector3.new(0, 28, 0), Vector3.new(34, 24, 34), C.LEAF)
	for i = 0, 5 do
		local angle = i * math.pi / 3
		crown(Vector3.new(math.cos(angle) * 15, 24 + (i % 2) * 3, math.sin(angle) * 15), Vector3.new(20, 15, 20), if i % 2 == 0 then C.LEAF_DARK else C.LEAF)
	end
	-- Aerial roots hanging from the crown's edge.
	for i = 0, 7 do
		local angle = i * math.pi / 4 + 0.2
		cylinder("Root", 18, 0.9, Vector3.new(math.cos(angle) * 12.5, 10, math.sin(angle) * 12.5), C.DARKWOOD, false)
	end
	tree.Parent = parent
end

local SHOP_DEFS = {
	-- slot -> sign + colors. Slots 1-5 belong to NPCs (Config/Npcs), 6-8 are scenery.
	{ text = "town.sign.bibit", wall = Color3.fromRGB(208, 190, 156), awning = C.DUSTY_BLUE, roof = C.TERRACOTTA },
	{ text = "town.sign.ikan", wall = C.CREAM, awning = C.SAGE, roof = C.DARKWOOD },
	{ text = "town.sign.tengkulak", wall = C.CREAM, awning = C.SAGE, roof = C.TERRACOTTA },
	{ text = "town.sign.tukang", wall = C.SAGE, awning = C.MUSTARD, roof = C.DARKWOOD },
	{ text = "town.sign.pancing", wall = Color3.fromRGB(208, 190, 156), awning = C.TERRACOTTA, roof = C.DARKWOOD },
	{ text = "town.sign.roti", wall = C.CREAM, awning = C.TERRACOTTA, roof = C.TERRACOTTA },
	{ text = "town.sign.jamu", wall = C.SAGE, awning = C.DUSTY_BLUE, roof = C.DARKWOOD },
	{ text = "town.sign.kelontong", wall = Color3.fromRGB(208, 190, 156), awning = C.MUSTARD, roof = C.TERRACOTTA },
}

local function buildTown(map: Folder)
	local town = folder(map, "Town")

	-- Eight shophouses on a circle, their fronts toward the tree (Map.SHOPS).
	for slot, def in SHOP_DEFS do
		local shop = Map.SHOPS[slot]
		local cf = CFrame.new(shop.x, TOWN.GROUND_Y, shop.z) * CFrame.Angles(0, shop.yaw, 0)
		buildShop(town, `Shop{slot}`, cf, 16, 12, 8, def.wall, def.roof, def.awning, Locale.t(def.text))
	end

	buildBanyan(town)

	-- Dirt paths from each bridge to the plaza.
	for _, dir in AXES do
		axisBlock(town, "Path", dir, 40, TOWN.ISLAND_R - 4, ROAD_HALF * 2, 0.15, 0.3, Map.DIRT_COLOR, Enum.Material.Sand)
	end

	-- Lamps on the island, behind the shops.
	local lamps = map:FindFirstChild("Lamps") :: Folder
	for i = 0, 7 do
		local angle = math.rad(22.5 + 45 * i)
		lampPost(lamps, CFrame.new(math.cos(angle) * 78, 0, math.sin(angle) * 78))
	end

	-- Where players appear before their plot is assigned: south of the warung, on the south path.
	local townSpawn = Instance.new("SpawnLocation")
	townSpawn.Name = "TownSpawn"
	townSpawn.Anchored = true
	townSpawn.Size = Vector3.new(8, 0.4, 8)
	townSpawn.CFrame = CFrame.new(0, TOWN.GROUND_Y + 0.25, 56)
	townSpawn.Neutral = true
	townSpawn.Duration = 0
	townSpawn.Transparency = 1
	townSpawn.CanCollide = false
	townSpawn.Parent = town
end

-- Warung stall (Pak Darmo stands behind it, see NpcService) -----------------------------------

local function buildWarung()
	local model = Instance.new("Model")
	model.Name = "Warung"
	-- Stall frame: floor center on the -Z strip, front (customers) faces local +Z.
	-- Floor on the plaza (cobblestone, measured y = 1.8 under the warung).
	local wf = CFrame.new(Map.WARUNG.x, TOWN.PLAZA_Y, Map.WARUNG.z)

	local template = getTemplate("Warung")
	if template then
		placeTemplate(template, model, "Visual", wf, 11)
	else
		block(model, "BackWall", Vector3.new(24, 8, 0.6), wf * CFrame.new(0, 4, -5.7), C.BAMBOO, Enum.Material.Wood)
		for _, sx in { -1, 1 } do
			block(model, "SideWall", Vector3.new(0.6, 8, 12), wf * CFrame.new(sx * 11.7, 4, 0), C.BAMBOO, Enum.Material.Wood)
		end
		block(model, "Roof", Vector3.new(27, 0.6, 15), wf * CFrame.new(0, 8.8, 0.6) * CFrame.Angles(math.rad(12), 0, 0), C.TERRACOTTA, Enum.Material.Slate)
		for i = 0, 5 do
			block(model, "AwningStripe", Vector3.new(4, 0.25, 4), wf * CFrame.new(-10 + i * 4, 7.6, 7.2) * CFrame.Angles(math.rad(22), 0, 0),
				if i % 2 == 0 then C.TERRACOTTA else C.CREAM, Enum.Material.Fabric)
		end
		block(model, "CounterVisual", Vector3.new(20, 3.2, 3), wf * CFrame.new(0, 1.6, 3.5), C.PLANK, Enum.Material.WoodPlanks)
		block(model, "CounterTop", Vector3.new(21, 0.3, 3.6), wf * CFrame.new(0, 3.35, 3.5), C.DARKWOOD, Enum.Material.Wood)
		local goodsColors = { C.LEAF, C.MUSTARD, C.DUSTY_BLUE, C.TERRACOTTA, C.SAGE }
		for i, color in goodsColors do
			block(model, "Goods", Vector3.new(2.2, 1.2, 2), wf * CFrame.new(-7 + (i - 1) * 3.5, 4.1, 3.5), color, Enum.Material.Fabric)
		end
	end

	-- Invisible anchor of the stall (kept as the model's PrimaryPart).
	local counter = block(model, "Counter", Vector3.new(20, 3, 3), wf * CFrame.new(0, 2, 3.5), C.PLANK)
	ghost(counter)
	model.PrimaryPart = counter

	local lantern = block(model, "Lantern", Vector3.new(1.2, 1.2, 1.2), wf * CFrame.new(8.5, 6.6, 6.5), Color3.fromRGB(236, 190, 120))
	lantern.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 140)
	light.Range = 18
	light.Shadows = false
	light.Enabled = false
	light.Parent = lantern
	CollectionService:AddTag(lantern, "DecorLight")

	model.Parent = Workspace
end

-- Docks + fishing spots + canal sound -----------------------------------------------------

local function buildFishing(map: Folder)
	local fishing = folder(Workspace, "Fishing")
	local docks = folder(map, "Docks")
	local length, width = Map.DOCK.LENGTH, Map.DOCK.WIDTH

	-- origin = point on the shore edge, dir = unit vector pointing out over the water.
	local function dock(origin: Vector3, dir: Vector3, location: string)
		local center = origin + dir * (length / 2 - 3) + Vector3.new(0, 0.25, 0)
		block(docks, "Planks", Vector3.new(width, 0.5, length), CFrame.lookAt(center, center + dir), C.PLANK, Enum.Material.WoodPlanks)
		local tip = origin + dir * (length - 3)
		local across = Vector3.new(-dir.Z, 0, dir.X)
		for _, s in { 1, -1 } do
			block(docks, "Post", Vector3.new(0.6, 4, 0.6), CFrame.new(tip + across * s * (width / 2 - 0.4) + Vector3.new(0, 0, 0)), C.DARKWOOD, Enum.Material.Wood)
		end
		local spot = block(fishing, `Spot_{location}`, Vector3.new(2, 1, 2), CFrame.new(tip - dir * 2 + Vector3.new(0, 1, 0)), C.PLANK)
		ghost(spot)
		spot:SetAttribute("Location", location)
			spot:SetAttribute("Dir", dir) -- the way the dock points out over the water (client places fish marks past its tip)

		-- The sign (name, level, lock) is drawn by client/FishSpotFx: it depends on the player's level, so it is not baked here.
	end

	-- Outer bank = the ring road side (docks point in toward the island); inner bank = the island side (docks point out).
	for _, entry in Map.DOCKS do
		local angle = math.rad(entry.angle)
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		if entry.bank == "outer" then
			dock(radial * TOWN.CANAL_R, -radial, entry.location)
		else
			dock(radial * TOWN.ISLAND_R, radial, entry.location)
		end
	end

	-- 3D water sound emitters (AudioController attaches the loop to parts with RiverSound = true).
	local mid = (TOWN.ISLAND_R + TOWN.CANAL_R) / 2
	for i, degrees in Map.CANAL_SOUND_ANGLES do
		local angle = math.rad(degrees)
		local emitter = block(fishing, `RiverSound{i}`, Vector3.new(2, 1, 2), CFrame.new(math.cos(angle) * mid, -1, math.sin(angle) * mid), C.STONE)
		ghost(emitter)
		emitter:SetAttribute("RiverSound", true)
	end
end

-- Edge: walls + trees -----------------------------------------------------------------------

local function buildBoundary(map: Folder)
	local walls = folder(map, "Walls")
	local half = Map.SIZE / 2
	local height = Map.WALL_TOP - Map.WALL_BOTTOM
	local centerY = (Map.WALL_TOP + Map.WALL_BOTTOM) / 2
	for _, sign in { 1, -1 } do
		local wallZ = block(walls, "WallZ", Vector3.new(Map.SIZE + 8, height, 2), CFrame.new(0, centerY, sign * (half + 1)), C.STONE)
		local wallX = block(walls, "WallX", Vector3.new(2, height, Map.SIZE + 8), CFrame.new(sign * (half + 1), centerY, 0), C.STONE)
		wallZ.Transparency = 1 -- invisible but solid
		wallX.Transparency = 1
	end
end

-- A low bamboo fence around the land each player owns (not solid: visitors can walk in, you just see where the land
-- ends). It follows the owned blocks, so it moves out when the player buys one. The road side has a 32-stud gate in
-- the middle. One folder per plot (Map.LandFences.Plot<n>); MapService.RebuildFence redoes a single plot.
local FENCE_PITCH = 3.7 -- studs per bamboo segment: centre of the first post to the centre of the last post (model geometry)
local FENCE_OUT = 4.45 -- studs the fence stands outside the land edge
local GATE_HALF = 16.65 -- gate opening 33.3 studs (9 segments) in the middle of the road side

-- Consecutive chunk indices in [CHUNK_MIN, CHUNK_MAX] for which ok(i) holds, as {first, last} pairs.
local function runsOf(ok: (number) -> boolean): { { number } }
	local out = {}
	local first = nil
	for i = Land.CHUNK_MIN, Land.CHUNK_MAX + 1 do
		local on = i <= Land.CHUNK_MAX and ok(i)
		if on and first == nil then
			first = i
		elseif not on and first ~= nil then
			table.insert(out, { first, i - 1 })
			first = nil
		end
	end
	return out
end

local function buildPlotFence(plotIndex: number, chunks: Land.Chunks?)
	local root = fenceRoot :: Folder
	local old = root:FindFirstChild(`Plot{plotIndex}`)
	if old then
		old:Destroy()
	end
	local slot = Plots.LAYOUT[plotIndex]
	local fences = folder(root, `Plot{plotIndex}`)
	local frame = CFrame.new(slot.x, 0, slot.z) * CFrame.Angles(0, slot.yaw, 0)
	local fenceTemplate = getTemplate("PagarBambu")
	local posts: { [string]: boolean } = {}

	local function world(x: number, z: number): Vector3
		return (frame * CFrame.new(x, 0, z)).Position
	end
	local function post(x: number, z: number)
		local key = `{x},{z}`
		if posts[key] then
			return
		end
		posts[key] = true
		local part = block(fences, "Post", Vector3.new(0.5, 2.4, 0.5), CFrame.new(world(x, z) + Vector3.new(0, 1.2, 0)), C.BAMBOO, Enum.Material.Wood)
		part.CanCollide = false
	end

	-- One side of the land, from corner A to corner B, as ONE run. Segment i sits at A + dir * (i + 0.5) * FENCE_PITCH,
	-- so its posts (at +-1.85 from its centre) land exactly on the joints: a corner post is shared by the two sides.
	-- gate = leave the middle of the road side open.
	local function side(ax: number, az: number, bx: number, bz: number, gate: boolean)
		local from, to = world(ax, az), world(bx, bz)
		local len = (to - from).Magnitude
		local dir = (to - from).Unit
		if not fenceTemplate then
			-- fallback without the imported model: one rail with posts at its ends
			post(ax, az)
			post(bx, bz)
			local mid = (from + to) / 2 + Vector3.new(0, 1.7, 0)
			local rail = block(fences, "Rail", Vector3.new(0.25, 0.25, len), CFrame.lookAt(mid, mid + (to - from)), C.BAMBOO, Enum.Material.Wood)
			rail.CanCollide = false
			return
		end
		-- n whole segments, each stretched a few percent (uniformly) so the run ends exactly on its corner posts: no
		-- segment pokes past a corner and crosses the perpendicular side.
		local n = math.max(1, math.floor(len / FENCE_PITCH + 0.5))
		local pitch = len / n
		local fit = pitch / FENCE_PITCH
		for i = 0, n - 1 do
			local along = (i + 0.5) * pitch
			local lx = ax + (bx - ax) * along / len -- plot-local x of this segment's centre
			if not (gate and math.abs(lx) < GATE_HALF) then
				placeTemplate(fenceTemplate, fences, "Pagar", CFrame.fromMatrix(from + dir * along, dir, Vector3.yAxis), 2.5 * fit)
			end
		end
	end

	local function owned(ix: number, iz: number): boolean
		return Land.isOwned(ix, iz, chunks)
	end
	local frontRow = Land.FRONT_Z // Land.CHUNK - 1

	-- Where a side ends: at a convex (outer) corner it runs OUT past the land edge so it meets the perpendicular side;
	-- at a concave (inner) corner, where the next block along the side is owned, it pulls back OUT so the two sides
	-- meet in one post instead of crossing. `before` = the owned block just past that end of the run.
	local function lo(edge: number, before: boolean): number
		return if before then edge + FENCE_OUT else edge - FENCE_OUT
	end
	local function hi(edge: number, after: boolean): number
		return if after then edge - FENCE_OUT else edge + FENCE_OUT
	end

	-- left and right sides: one run per column, grouped over the rows that touch the open side
	for ix = Land.CHUNK_MIN, Land.CHUNK_MAX do
		for _, run in runsOf(function(iz: number) return owned(ix, iz) and not owned(ix - 1, iz) end) do
			local a, b = Land.chunkRect(ix, run[1]), Land.chunkRect(ix, run[2])
			local z0, z1 = lo(a.minZ, owned(ix, run[1] - 1)), hi(b.maxZ, owned(ix, run[2] + 1))
			side(a.minX - FENCE_OUT, z0, a.minX - FENCE_OUT, z1, false)
		end
		for _, run in runsOf(function(iz: number) return owned(ix, iz) and not owned(ix + 1, iz) end) do
			local a, b = Land.chunkRect(ix, run[1]), Land.chunkRect(ix, run[2])
			local z0, z1 = lo(a.minZ, owned(ix, run[1] - 1)), hi(b.maxZ, owned(ix, run[2] + 1))
			side(a.maxX + FENCE_OUT, z0, a.maxX + FENCE_OUT, z1, false)
		end
	end
	-- bottom and top sides: one run per row, grouped over the columns that touch the open side
	for iz = Land.CHUNK_MIN, Land.CHUNK_MAX do
		for _, run in runsOf(function(ix: number) return owned(ix, iz) and not owned(ix, iz - 1) end) do
			local a, b = Land.chunkRect(run[1], iz), Land.chunkRect(run[2], iz)
			local x0, x1 = lo(a.minX, owned(run[1] - 1, iz)), hi(b.maxX, owned(run[2] + 1, iz))
			side(x0, a.minZ - FENCE_OUT, x1, a.minZ - FENCE_OUT, false)
		end
		for _, run in runsOf(function(ix: number) return owned(ix, iz) and not owned(ix, iz + 1) end) do
			local a, b = Land.chunkRect(run[1], iz), Land.chunkRect(run[2], iz)
			local x0, x1 = lo(a.minX, owned(run[1] - 1, iz)), hi(b.maxX, owned(run[2] + 1, iz))
			side(x0, a.maxZ + FENCE_OUT, x1, a.maxZ + FENCE_OUT, iz == frontRow)
		end
	end
end

local function buildLandFences(map: Folder)
	fenceRoot = folder(map, "LandFences")
	for index = 1, #Plots.LAYOUT do
		buildPlotFence(index, nil)
	end
end

-- Procedural fallback (balls on sticks), used only when ServerStorage > MapModels > Nature is empty.
local function buildProceduralTrees(map: Folder)
	local trees = folder(map, "Trees")
	local random = Random.new(1127)
	local roadClear = ROAD_HALF + 10
	local townClear = TOWN.RING_R + 10

	local function tree(x: number, z: number)
		if math.abs(x) < roadClear or math.abs(z) < roadClear or x * x + z * z < townClear * townClear then
			return
		end
		local trunkHeight = random:NextNumber(6, 9)
		local crown = random:NextNumber(9, 14)
		local trunk = block(trees, "Trunk", Vector3.new(trunkHeight, 1.6, 1.6), CFrame.new(x, trunkHeight / 2, z) * CFrame.Angles(0, 0, math.pi / 2), C.DARKWOOD, Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		local top = block(trees, "Crown", Vector3.new(crown, crown * 0.8, crown), CFrame.new(x, trunkHeight + crown * 0.3, z),
			if random:NextNumber() < 0.5 then C.LEAF else C.LEAF_DARK, Enum.Material.Grass)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = top
	end

	local function ring(radius: number, step: number)
		local s = -radius
		while s <= radius do
			tree(s, radius)
			tree(s, -radius)
			tree(radius, s)
			tree(-radius, s)
			s += step
		end
	end
	ring(Map.SIZE / 2 - 3, 24) -- just inside the walls
	ring(Map.SIZE / 2 + 22, 32) -- scenery outside
end

-- Nature (imported packs) ---------------------------------------------------------------------
-- ServerStorage > MapModels > Nature > Pohon (trees), Semak (bushes), Batu (rocks): Models, any number each.
-- Trees/bushes are from "Yasu's Stylized Tree Pack" (leaf textures are colorless, tinted here); rocks are plain meshes.

-- Village palette: mostly fresh greens, a few yellow-green (young leaves / mango) and deep green (old trees).
local LEAF_TINTS = {
	Color3.fromRGB(112, 188, 62),
	Color3.fromRGB(92, 172, 70),
	Color3.fromRGB(138, 194, 58),
	Color3.fromRGB(74, 156, 76),
	Color3.fromRGB(166, 196, 66),
	Color3.fromRGB(58, 132, 70),
	Color3.fromRGB(192, 190, 74), -- sunlit yellow-green
}
local ROCK_COLORS = {
	Color3.fromRGB(158, 152, 140),
	Color3.fromRGB(138, 134, 124),
	Color3.fromRGB(122, 144, 112), -- mossy
	Color3.fromRGB(110, 128, 100), -- very mossy
}
local MAX_TREE_HEIGHT_RATIO = 1.9 -- skips the tall thin trees of the pack (they look wrong among round ones)

-- tallOnly = true returns only the tall thin trees (giants), false only the round ones. Other groups ignore it.
local function natureTemplates(group: string, tallOnly: boolean?): { Model }
	local models = ServerStorage:FindFirstChild("MapModels")
	local nature = models and models:FindFirstChild("Nature")
	local source = nature and nature:FindFirstChild(group)
	local list: { Model } = {}
	if source then
		for _, child in source:GetChildren() do
			if child:IsA("Model") then
				local _, size = child:GetBoundingBox()
				local isTall = size.Y > size.X * MAX_TREE_HEIGHT_RATIO
				if group ~= "Pohon" or isTall == (tallOnly == true) then
					table.insert(list, child)
				end
			end
		end
	end
	return list
end

-- Ground that stays clear of trees, bushes and rocks: the river (out along each axis, from the canal) and each plot's
-- gate path (from the gate to the ring road, 24 studs either side of the gate's middle).
local function inRiverOrPath(x: number, z: number): boolean
	local clearR = TOWN.CANAL_R - 10
	if (math.abs(x) < RIVER_HALF + 10 and math.abs(z) > clearR) or (math.abs(z) < RIVER_HALF + 10 and math.abs(x) > clearR) then
		return true
	end
	for _, slot in Plots.LAYOUT do
		local lp = (CFrame.new(slot.x, 0, slot.z) * CFrame.Angles(0, slot.yaw, 0)):PointToObjectSpace(Vector3.new(x, 0, z))
		if math.abs(lp.X) < 24 and lp.Z > Land.FRONT_Z - 6 and lp.Z < Land.FRONT_Z + 85 then
			return true
		end
		-- Front yard (v2): the unowned ground in front of the land, out to the road, is kept free of trees too, but
		-- not the owned start land (|x| <= 64, z <= FRONT_Z).
		local front = lp.Z > 56 and lp.Z < Land.FRONT_Z + 85 and math.abs(lp.X) < 140
		local onStart = math.abs(lp.X) <= Land.HALF and lp.Z <= Land.FRONT_Z
		if front and not onStart then
			return true
		end
	end
	return false
end

local function buildNature(map: Folder, trees: { Model }, bushes: { Model }, rocks: { Model }, giants: { Model })
	local nature = folder(map, "Nature")
	natureFolder = nature
	local parked = ServerStorage:FindFirstChild("ForestHidden")
	if not parked then
		parked = Instance.new("Folder")
		parked.Name = "ForestHidden"
		parked.Parent = ServerStorage
	end
	hiddenFolder = parked :: Folder
	local random = Random.new(1127)
	local roadClear = ROAD_HALF + 10 -- trees stay this far from the axis roads
	local townClear = TOWN.RING_R + 10 -- ... and from the cobblestone ring road
	local half = Map.SIZE / 2

	-- Every plot's frame (world <- plot-local), to keep nature off the player lands.
	local frames: { CFrame } = {}
	for _, slot in Plots.LAYOUT do
		table.insert(frames, CFrame.new(slot.x, 0, slot.z) * CFrame.Angles(0, slot.yaw, 0))
	end
	local function onLand(x: number, z: number, margin: number): boolean
		local point = Vector3.new(x, 0, z)
		for _, frame in frames do
			local localPoint = frame:PointToObjectSpace(point)
			if Land.startContains(localPoint.X, localPoint.Z, margin) then
				return true
			end
		end
		return false
	end
	-- On an axis road, the ring road or the town.
	local function nearPublic(x: number, z: number, clear: number): boolean
		local reach = TOWN.RING_R + clear
		return math.abs(x) < clear or math.abs(z) < clear or x * x + z * z < reach * reach
	end

	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances = { Workspace.Terrain }
	-- Lowest terrain surface under (x, z) and four points `spread` studs around it (0 if there is no terrain).
	local function groundY(x: number, z: number, spread: number): number
		local lowest = math.huge
		for _, offset in { { 0, 0 }, { spread, 0 }, { -spread, 0 }, { 0, spread }, { 0, -spread } } do
			local hit = Workspace:Raycast(Vector3.new(x + offset[1], 700, z + offset[2]), Vector3.new(0, -1400, 0), groundParams)
			lowest = math.min(lowest, if hit then hit.Position.Y else 0)
		end
		return lowest
	end

	-- baseY = ground level under the thing (a rock in the canal stands on the bed). Everything gets a random turn and
	-- a slight lean (rocks more) so nothing looks stamped out in a row. expansionOf = plot number: tags the model so
	-- the plot's ground can be cleared when the player buys it (R2b).
	local function put(templates: { Model }, group: string, x: number, z: number, height: number, tint: boolean, baseY: number?, expansionOf: number?)
		local template = templates[random:NextInteger(1, #templates)]
		-- Never cover a player's land: the player must be able to place things on every grid cell. The footprint
		-- radius is half of the model's widest side after scaling to `height`; if any of it would reach the land, skip.
		local extents = template:GetExtentsSize()
		local footprint = math.max(extents.X, extents.Z) * (height / math.max(extents.Y, 0.01)) / 2
		if onLand(x, z, footprint + 0.5) then
			return
		end
		if inRiverOrPath(x, z) then
			return
		end
		local lean = math.rad(if group == "Batu" then 14 elseif group == "Semak" then 5 else 3)
		local rotation = CFrame.Angles(random:NextNumber(-lean, lean), random:NextNumber(0, math.pi * 2), random:NextNumber(-lean, lean))
		-- Stand on the REAL terrain: the ground is not flat (canal bank, foothills), so sample its height under the
		-- thing (center + 4 points around it) and rest on the LOWEST, so no side hovers; then sink it further because
		-- trunk and rock bottoms are narrow and pointed and must be fully buried.
		local ground = baseY or groundY(x, z, height * (if group == "Pohon" then 0.08 elseif group == "Semak" then 0.25 else 0.22))
		local model = placeTemplate(template, nature, group, CFrame.new(x, ground, z) * rotation, height)
		local sink = height * (if group == "Pohon" then 0.13 elseif group == "Semak" then 0.12 else 0.2)
		model:PivotTo(model:GetPivot() - Vector3.new(0, sink, 0))
		if expansionOf then
			model:SetAttribute("ExpansionOf", expansionOf)
			-- Index it by the chunk its center is in, so buying that chunk can clear it.
			local localPoint = frames[expansionOf]:PointToObjectSpace(Vector3.new(x, 0, z))
			local key = Land.chunkKey(localPoint.X // Land.CHUNK, localPoint.Z // Land.CHUNK)
			local byKey = forestByPlot[expansionOf]
			if not byKey then
				byKey = {}
				forestByPlot[expansionOf] = byKey
			end
			local list = byKey[key]
			if not list then
				list = {}
				byKey[key] = list
			end
			table.insert(list, model)
		end
		-- One tint per plant (the canopy mesh is one part) and one color per rock.
		local leafColor = LEAF_TINTS[random:NextInteger(1, #LEAF_TINTS)]
		local rockColor = ROCK_COLORS[random:NextInteger(1, #ROCK_COLORS)]
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = group == "Batu"
				descendant.CastShadow = true
				if group == "Batu" then
					descendant.Material = Enum.Material.Slate
					descendant.Color = rockColor
				end
			elseif tint and descendant:IsA("SurfaceAppearance") and descendant.Parent and descendant.Parent.Name:find("Canopy") then
				descendant.Color = leafColor
			end
		end
	end

	-- A mixed bit of forest at one spot: mostly trees, some bushes, a few rocks.
	local function forestSpot(x: number, z: number, expansionOf: number?)
		local roll = random:NextNumber()
		if roll < 0.55 and #trees > 0 then
			put(trees, "Pohon", x, z, random:NextNumber(16, 28), true, nil, expansionOf)
		elseif roll < 0.82 and #bushes > 0 then
			put(bushes, "Semak", x, z, random:NextNumber(4, 8), true, nil, expansionOf)
		elseif #rocks > 0 then
			put(rocks, "Batu", x, z, random:NextNumber(3, 8), false, nil, expansionOf)
		elseif #trees > 0 then
			put(trees, "Pohon", x, z, random:NextNumber(16, 28), true, nil, expansionOf)
		end
	end

	-- 1. Forest belt around the map: five jittered rows, taller toward the back so it reads as a wall of woods.
	-- Heights are uneven on purpose: mostly medium, some tall, and now and then a giant (the pack's tall thin trees).
	if #trees > 0 then
		local function treeAt(x: number, z: number, minHeight: number, maxHeight: number)
			local roll = random:NextNumber()
			if roll < 0.1 and #giants > 0 then
				put(giants, "Pohon", x, z, random:NextNumber(48, 95), true)
			elseif roll < 0.35 then
				put(trees, "Pohon", x, z, random:NextNumber(maxHeight, maxHeight * 1.8), true)
			else
				put(trees, "Pohon", x, z, random:NextNumber(minHeight * 0.8, maxHeight), true)
			end
		end
		local function ring(radius: number, step: number, minHeight: number, maxHeight: number)
			local s = -radius
			while s <= radius do
				for _, spot in { { s, radius }, { s, -radius }, { radius, s }, { -radius, s } } do
					local x = spot[1] + random:NextNumber(-6, 6)
					local z = spot[2] + random:NextNumber(-6, 6)
					if math.abs(x) >= roadClear and math.abs(z) >= roadClear then
						treeAt(x, z, minHeight, maxHeight)
					end
				end
				s += step
			end
		end
		ring(half + 6, 15, 20, 30)
		ring(half + 24, 17, 24, 34)
		ring(half + 44, 20, 28, 40)
		ring(half + 68, 30, 30, 44)
		ring(half + 96, 40, 34, 48)
	end

	-- 2. The part of every plot's reserved square that the player does not own yet (back and sides of the start
	-- land) is forest. It is tagged ExpansionOf = plot number, so buying ground can clear it (R2b). Kept a few studs
	-- off the road side so no crown hangs over the road.
	if #trees > 0 or #bushes > 0 or #rocks > 0 then
		for index = 1, #frames do
			local frame = frames[index]
			local region = Land.REGION_HALF
			local x = -region + 4
			while x <= region - 4 do
				local z = -region + 4
				while z <= Land.FRONT_Z - 10 do
					local world = frame * Vector3.new(x + random:NextNumber(-3, 3), 0, z + random:NextNumber(-3, 3))
					if math.abs(world.X) < half - 6 and math.abs(world.Z) < half - 6 then
						forestSpot(world.X, world.Z, index)
					end
					z += 10
				end
				x += 10
			end
		end

		-- 3. The four corners between the plot regions: dense forest (rice terraces can come later).
		local corner0, corner1 = Plots.INNER + 4, half - 6
		for _, sx in { 1, -1 } do
			for _, sz in { 1, -1 } do
				local x = corner0
				while x <= corner1 do
					local z = corner0
					while z <= corner1 do
						forestSpot(sx * (x + random:NextNumber(-5, 5)), sz * (z + random:NextNumber(-5, 5)), nil)
						z += 12
					end
					x += 12
				end
			end
		end

		-- 4. Public ground between the ring road and the plots: scattered trees and bushes, never on a road.
		local limit = Plots.INNER - 6
		local x = -limit
		while x <= limit do
			local z = -limit
			while z <= limit do
				local px, pz = x + random:NextNumber(-8, 8), z + random:NextNumber(-8, 8)
				if not nearPublic(px, pz, roadClear + 4) and math.abs(px) < limit and math.abs(pz) < limit then
					if random:NextNumber() < 0.5 and #trees > 0 then
						put(trees, "Pohon", px, pz, random:NextNumber(12, 19), true)
					elseif #bushes > 0 then
						put(bushes, "Semak", px, pz, random:NextNumber(4, 7), true)
					end
				end
				z += 26
			end
			x += 26
		end
	end

	-- 5. Canal banks, irregular like a real stream: big boulders that stand in the water (on the bed, tops above the
	-- surface), groups of small stones on the bank, patches of bushes on the island side, and gaps. Not at docks or
	-- bridges.
	if #bushes > 0 or #rocks > 0 then
		local bedY = -Map.RIVER.DEPTH
		local function nearDockOrBridge(degrees: number): boolean
			if math.min(degrees % 90, 90 - degrees % 90) < 9 then
				return true
			end
			for _, entry in Map.DOCKS do
				local difference = math.abs(((entry.angle - degrees) + 180) % 360 - 180)
				if difference < 5 then
					return true
				end
			end
			return false
		end
		local function polar(radius: number, degrees: number): Vector3
			local angle = math.rad(degrees)
			return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		end

		local degrees = 0
		while degrees < 360 do
			local at = degrees + random:NextNumber(-2, 2)
			if not nearDockOrBridge(at) then
				for _, bank in { "outer", "inner" } do
					-- distance = how far from the water's edge toward the water (negative) or onto land (positive)
					local edge = if bank == "outer" then TOWN.CANAL_R else TOWN.ISLAND_R
					local inward = if bank == "outer" then -1 else 1 -- sign that moves from the edge into the water
					local roll = random:NextNumber()
					if roll < 0.2 and #rocks > 0 then
						local point = polar(edge + inward * random:NextNumber(1, 8), at)
						put(rocks, "Batu", point.X, point.Z, random:NextNumber(9, 16), false, bedY)
					elseif roll < 0.4 and #rocks > 0 then
						local base = polar(edge - inward * random:NextNumber(0.3, 1.8), at)
						for _ = 1, random:NextInteger(1, 3) do
							local point = base + Vector3.new(random:NextNumber(-3, 3), 0, random:NextNumber(-3, 3))
							put(rocks, "Batu", point.X, point.Z, random:NextNumber(1.2, 3.2), false)
						end
					elseif roll < 0.7 and bank == "inner" and #bushes > 0 then
						local base = polar(edge - random:NextNumber(1, 3.5), at)
						for _ = 1, random:NextInteger(1, 3) do
							local point = base + Vector3.new(random:NextNumber(-3, 3), 0, random:NextNumber(-3, 3))
							put(bushes, "Semak", point.X, point.Z, random:NextNumber(2, 6), true)
						end
					end
				end
			end
			degrees += random:NextNumber(5, 14)
		end
	end

	-- 6. Rocks scattered in the forest belt: single boulders and small groups of two or three.
	if #rocks > 0 then
		for _ = 1, 90 do
			local radius = half + random:NextNumber(10, 70)
			local along = random:NextNumber(-radius, radius)
			local sign = if random:NextNumber() < 0.5 then 1 else -1
			local x, z = along, radius * sign -- on a side parallel to the X axis ...
			if random:NextNumber() < 0.5 then
				x, z = radius * sign, along -- ... or to the Z axis
			end
			if math.abs(x) >= roadClear and math.abs(z) >= roadClear then
				put(rocks, "Batu", x, z, random:NextNumber(5, 11), false)
				for _ = 1, random:NextInteger(0, 2) do
					put(rocks, "Batu", x + random:NextNumber(-6, 6), z + random:NextNumber(-6, 6), random:NextNumber(2.5, 6), false)
				end
			end
		end
	end

	-- 6b. Big boulders on the foothills' toes, where the woods meet the mountains.
	if #rocks > 0 then
		for _ = 1, 60 do
			local radius = half + random:NextNumber(110, 150)
			local along = random:NextNumber(-radius, radius)
			local sign = if random:NextNumber() < 0.5 then 1 else -1
			local x, z = along, radius * sign
			if random:NextNumber() < 0.5 then
				x, z = radius * sign, along
			end
			put(rocks, "Batu", x, z, random:NextNumber(14, 30), false)
		end
	end

	-- 7. Bushes in the forest belt, so the woods have an undergrowth.
	if #bushes > 0 then
		for _ = 1, 160 do
			local radius = half + random:NextNumber(4, 50)
			local along = random:NextNumber(-radius, radius)
			local sign = if random:NextNumber() < 0.5 then 1 else -1
			local x, z = along, radius * sign
			if random:NextNumber() < 0.5 then
				x, z = radius * sign, along
			end
			if math.abs(x) >= roadClear and math.abs(z) >= roadClear then
				put(bushes, "Semak", x, z, random:NextNumber(5, 9), true)
			end
		end
	end

	applyForestVisibility()
end

local function buildTrees(map: Folder)
	local trees, bushes, rocks = natureTemplates("Pohon"), natureTemplates("Semak"), natureTemplates("Batu")
	if #trees == 0 and #bushes == 0 and #rocks == 0 then
		buildProceduralTrees(map)
		return
	end
	buildNature(map, trees, bushes, rocks, natureTemplates("Pohon", true))
end

-- Land you own (called by LandService) -----------------------------------------------------

-- Gives a chunk of plot `plotIndex` to its player (owned = true: bright grass, forest cleared) or takes it back
-- (false: forest floor, forest returns). Only the 80 extra chunks can change; the start land is always owned.
function MapService.SetChunkOwned(plotIndex: number, ix: number, iz: number, owned: boolean)
	local slot = Plots.LAYOUT[plotIndex]
	if not slot or not Land.inRegion(ix, iz) or Land.isStartChunk(ix, iz) then
		return
	end
	local key = Land.chunkKey(ix, iz)
	local states = chunkOwned[plotIndex]
	if not states then
		states = {}
		chunkOwned[plotIndex] = states
	end
	if (states[key] == true) == owned then
		return
	end
	states[key] = if owned then true else nil

	-- Same paint recipe as the start land (see buildTerrain): a 4-stud top layer, 0.5 smaller than the cells it fills.
	local frame = CFrame.new(slot.x, 0, slot.z) * CFrame.Angles(0, slot.yaw, 0)
	local rect = Land.chunkRect(ix, iz)
	Workspace.Terrain:FillBlock(
		frame * CFrame.new((rect.minX + rect.maxX) / 2, -2 - Land.SURFACE_OFFSET, (rect.minZ + rect.maxZ) / 2),
		Vector3.new(Land.CHUNK - 0.5, 4, Land.CHUNK - 0.5),
		if owned then Enum.Material.LeafyGrass else Enum.Material.Grass
	)
	setForestHidden(plotIndex, key, owned)
end

-- Rebuilds the fence of one plot around its owned chunks (chunks = the player's bought chunks, {} = none).
function MapService.RebuildFence(plotIndex: number, chunks: Land.Chunks?)
	if fenceRoot and Plots.LAYOUT[plotIndex] then
		buildPlotFence(plotIndex, chunks)
	end
end


-- Lifecycle -------------------------------------------------------------------------------

-- Hand-built map (Workspace.Map baked from this generator): index its forest so buying a chunk still clears it.
local function indexBakedForest(map: Folder)
	local nature = map:FindFirstChild("Nature")
	if not nature then
		return
	end
	natureFolder = nature :: Folder
	fenceRoot = map:FindFirstChild("LandFences") :: Folder?
	local parked = ServerStorage:FindFirstChild("ForestHidden")
	if not parked then
		parked = Instance.new("Folder")
		parked.Name = "ForestHidden"
		parked.Parent = ServerStorage
	end
	hiddenFolder = parked :: Folder
	for _, model in nature:GetChildren() do
		local plotIndex = model:GetAttribute("ExpansionOf")
		local slot = if typeof(plotIndex) == "number" then Plots.LAYOUT[plotIndex] else nil
		if slot then
			local frame = CFrame.new(slot.x, 0, slot.z) * CFrame.Angles(0, slot.yaw, 0)
			local p = frame:PointToObjectSpace(model:GetPivot().Position)
			local key = Land.chunkKey(p.X // Land.CHUNK, p.Z // Land.CHUNK)
			local byKey = forestByPlot[plotIndex]
			if not byKey then
				byKey = {}
				forestByPlot[plotIndex] = byKey
			end
			local list = byKey[key]
			if not list then
				list = {}
				byKey[key] = list
			end
			table.insert(list, model)
		end
	end
end
function MapService.Init()
	if Workspace:FindFirstChild("Map") then
		indexBakedForest(Workspace.Map)
		print("[MapService] Workspace.Map exists: using the hand-built map")
		return
	end

	-- The default template's baseplate/spawn would sit inside the terrain and the town.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local old = Workspace:FindFirstChild(name)
		if old and old:IsA("BasePart") then
			old:Destroy()
		end
	end

	buildTerrain()
	local map = Instance.new("Folder")
	map.Name = "Map"
	buildRoad(map)
	buildPaths(map)
	buildBridge(map)
	buildTown(map)
	buildFishing(map)
	buildBoundary(map)
	buildLandFences(map)
	map.Parent = Workspace
	buildWarung()
	builtMap = map -- the nature is placed in Start, once the terrain has physics (see below)
end

-- Trees, bushes and rocks are placed on the real terrain height with raycasts, and a terrain just filled in Init
-- has no collision yet (measured: raycasts read the old surface for a frame or two), so wait a moment first.
function MapService.Start()
	local map = builtMap
	if not map then
		return
	end
	for _ = 1, 3 do
		RunService.Heartbeat:Wait()
	end
	buildTrees(map)
end

-- A world CFrame for a town position (the island is not rotated).
function MapService.TownCFrame(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

return MapService
