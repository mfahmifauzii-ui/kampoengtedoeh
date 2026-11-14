--!strict
-- Builds the village map at server start (X-shaped map, see Config/Map and docs/Map_Plan.md):
-- terrain + river + round Empang pool, road, bridge with the town on it, warung + NPC, docks with
-- fishing spots, lamps, edge trees and invisible walls.
-- If Workspace.Map already exists (hand-built map), nothing is generated.
--
-- Real models: put Models named "Warung", "TokoKota" (town shophouse), "RumahPanggung" in
-- ServerStorage > MapModels. They replace the placeholders automatically. Each is scaled to the
-- height used here and rotated by its numeric attribute "FrontYaw" (degrees) so its front faces the road.
--
-- World contract with other services: Workspace.Fishing (spots). NPCs: MapService.BridgeCFrame places them (NpcService).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local FishingConfig = require(ReplicatedStorage.Shared.Config.Fishing)
local Map = require(ReplicatedStorage.Shared.Config.Map)
local Plots = require(ReplicatedStorage.Shared.Config.Plots)
local Land = require(ReplicatedStorage.Shared.Modules.Land)

local SQRT2 = math.sqrt(2)
local ROAD_ROT = CFrame.Angles(0, math.pi / 4, 0) -- local X = road direction (SW -> NE)
local RIVER_ROT = CFrame.Angles(0, -math.pi / 4, 0) -- local X = river direction (NW -> SE)
local ROAD_DIR = Vector3.new(1, 0, -1) / SQRT2
local RIVER_SIDE = ROAD_DIR -- unit vector pointing from the river axis to its NE bank
local BRIDGE_FRAME = ROAD_ROT -- local X = along the road, local Z = along the river

local DECK_Y = Map.BRIDGE.DECK_Y

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

local function riverPoint(t: number): Vector3
	return Vector3.new(t / SQRT2, 0, t / SQRT2)
end

local function roadPoint(u: number): Vector3
	return ROAD_DIR * u
end

local function bridgeAt(x: number, y: number, z: number): CFrame
	return BRIDGE_FRAME * CFrame.new(x, y, z)
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

	row(0, 28, 55, 90, 160, 110) -- foothills, right behind the woods
	row(70, 110, 190, 130, 240, 170) -- the range, its foot behind the foothills
	row(230, 220, 330, 200, 320, 260) -- tall back range, far back so the slopes stay gentle in view
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

	-- Public ground is sand-colored; only the four player lands are green (LeafyGrass: flat grass texture,
	-- Material.Grass would grow 3D blades that hide roads and docks).
	-- MEASURED in Studio: the terrain surface sits Land.SURFACE_OFFSET (2) studs ABOVE the top of a filled block,
	-- so every block is lowered by that much to put the visible ground at y = 0 (roads, docks, plots assume y = 0).
	-- Terrain cells are 4 studs with edges at multiples of 4; a block paints a cell when the cell's center is inside it
	-- (see Land), so the paint blocks below are 0.5 smaller than the cells they fill.
	local drop = -Land.SURFACE_OFFSET
	terrain:FillBlock(CFrame.new(0, -Map.GRASS_DEPTH / 2 + drop, 0), Vector3.new(total, Map.GRASS_DEPTH, total), Enum.Material.Sand)
	for _, slot in Plots.LAYOUT do
		local frame = CFrame.new(slot.x * Plots.DISTANCE, 0, slot.z * Plots.DISTANCE) * CFrame.Angles(0, slot.yaw, 0)
		for row = 0, Land.ROWS - 1 do
			local half = Land.rowHalfWidth(row)
			if half > 0 then
				local z = Land.BACK_Z + row * Land.ROW + Land.ROW / 2
				-- 0.5 smaller than the cells it fills: the neighbouring cells' centers stay outside the block
				terrain:FillBlock(
					frame * CFrame.new(0, -2 + drop, z),
					Vector3.new(half * 2 - 0.5, 4, Land.ROW - 0.5),
					Enum.Material.LeafyGrass
				)
			end
		end
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

	local function riverBlock(top: number, bottom: number, material: Enum.Material)
		terrain:FillBlock(
			CFrame.new(0, (top + bottom) / 2 + drop, 0) * RIVER_ROT,
			Vector3.new(river.LENGTH, top - bottom, river.WIDTH),
			material
		)
	end
	riverBlock(0, -river.DEPTH, Enum.Material.Air)
	-- Water is the exception to the +2 rule (MEASURED: its surface is exactly the top of the block), so undo the drop.
	riverBlock(river.WATER_Y - drop, -river.DEPTH, Enum.Material.Water)
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
	tint(Enum.Material.Rock, "RockStylized", Color3.fromRGB(110, 102, 92), Color3.fromRGB(189, 189, 189)) -- mountain tops (white was too bright, 128/120/110 too dark)
	terrain.WaterColor = Map.WATER_COLOR
	terrain.WaterTransparency = 0.5 -- was 0.8: the sand bed showed through and the river looked muddy
	terrain.WaterReflectance = 0.2 -- less sky/white sheen, so the blue reads deeper
	terrain.WaterWaveSize = 0.08
	terrain.WaterWaveSpeed = 6
end

-- Road ------------------------------------------------------------------------------------

local function buildRoad(map: Folder)
	local road = folder(map, "Road")
	local lamps = folder(map, "Lamps")
	local startU = Map.BRIDGE.SPAN / 2 + Map.BRIDGE.RAMP
	local halfLength = Map.ROAD.LENGTH / 2
	local side = Vector3.new(1, 0, 1) / SQRT2 -- across the road

	for _, sign in { 1, -1 } do
		local length = halfLength - startU
		local mid = sign * (startU + length / 2)
		block(road, "Asphalt", Vector3.new(length, 0.3, Map.ROAD.WIDTH),
			CFrame.new(roadPoint(mid) + Vector3.new(0, 0.15, 0)) * ROAD_ROT, C.ASPHALT, Enum.Material.Asphalt)

		local u = startU + 8
		while u < halfLength - 8 do
			block(road, "Dash", Vector3.new(6, 0.1, 0.7),
				CFrame.new(roadPoint(sign * u) + Vector3.new(0, 0.33, 0)) * ROAD_ROT, C.LINE)
			u += 14
		end

		-- Lamps on both sides of the road.
		local lampU = startU + 20
		while lampU < halfLength - 120 do
			for _, s in { 1, -1 } do
				local position = roadPoint(sign * lampU) + side * s * (Map.ROAD.WIDTH / 2 + 3)
				lampPost(lamps, CFrame.new(position))
			end
			lampU += 56
		end
	end
end

-- Bridge + town ---------------------------------------------------------------------------

local function rampSlab(parent: Instance, sign: number, z: number, width: number, color: Color3, material: Enum.Material)
	local b = Map.BRIDGE
	local run, rise = b.RAMP, DECK_Y
	local length = math.sqrt(run * run + rise * rise)
	local phi = math.atan2(rise, run)
	local thickness = 0.6
	local theta = -sign * phi -- descends away from the deck
	local up = Vector3.new(-math.sin(theta), math.cos(theta), 0)
	local topMid = Vector3.new(sign * (b.SPAN / 2 + run / 2), rise / 2, z)
	local center = topMid - up * (thickness / 2)
	block(parent, "Ramp", Vector3.new(length + 0.5, thickness, width), BRIDGE_FRAME * CFrame.new(center) * CFrame.Angles(0, 0, theta), color, material)
end

local function buildBridge(map: Folder)
	local b = Map.BRIDGE
	local bridge = folder(map, "Bridge")

	block(bridge, "Deck", Vector3.new(b.SPAN, b.DECK_THICK, b.WIDTH), bridgeAt(0, DECK_Y - b.DECK_THICK / 2, 0), C.PLANK, Enum.Material.WoodPlanks)
	block(bridge, "RoadSurface", Vector3.new(b.SPAN, 0.1, Map.ROAD.WIDTH), bridgeAt(0, DECK_Y + 0.05, 0), C.ASPHALT, Enum.Material.Asphalt)

	-- Supports: stone abutments on both banks and two piers in the water.
	for _, sign in { 1, -1 } do
		block(bridge, "Abutment", Vector3.new(12, DECK_Y + 10, b.WIDTH), bridgeAt(sign * 30, (DECK_Y - 10) / 2, 0), C.STONE, Enum.Material.Cobblestone)
	end
	for _, sign in { 1, -1 } do
		block(bridge, "Pier", Vector3.new(5, DECK_Y + 10, 5), bridgeAt(0, (DECK_Y - 10) / 2, sign * 22), C.STONE, Enum.Material.Cobblestone)
	end

	-- Ramps: asphalt in the middle (the road), plank strips on the sides.
	local sideWidth = (b.WIDTH - Map.ROAD.WIDTH) / 2
	for _, sign in { 1, -1 } do
		rampSlab(bridge, sign, 0, Map.ROAD.WIDTH, C.ASPHALT, Enum.Material.Asphalt)
		for _, zSign in { 1, -1 } do
			rampSlab(bridge, sign, zSign * (Map.ROAD.WIDTH / 2 + sideWidth / 2), sideWidth, C.PLANK, Enum.Material.WoodPlanks)
		end
	end

	-- Side rails over the water.
	for _, zSign in { 1, -1 } do
		local z = zSign * (b.WIDTH / 2 - 0.3)
		block(bridge, "RailTop", Vector3.new(b.SPAN, 0.3, 0.3), bridgeAt(0, DECK_Y + 1.3, z), C.DARKWOOD, Enum.Material.Wood)
		block(bridge, "RailMid", Vector3.new(b.SPAN, 0.2, 0.2), bridgeAt(0, DECK_Y + 0.7, z), C.DARKWOOD, Enum.Material.Wood)
		for x = -36, 36, 6 do
			block(bridge, "RailPost", Vector3.new(0.4, 1.4, 0.4), bridgeAt(x, DECK_Y + 0.7, z), C.DARKWOOD, Enum.Material.Wood)
		end
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

local function buildTown(map: Folder)
	local town = folder(map, "Town")
	local roofs = { C.TERRACOTTA, C.DARKWOOD, C.TERRACOTTA, C.DARKWOOD }

	-- +Z strip: four shops facing the road (rotated half a turn so their front faces -Z).
	local plusSide = {
		{ x = -27, text = "town.sign.tengkulak", wall = C.CREAM, awning = C.SAGE },
		{ x = -9, text = "town.sign.tukang", wall = C.SAGE, awning = C.MUSTARD },
		{ x = 9, text = "town.sign.roti", wall = C.CREAM, awning = C.TERRACOTTA },
		{ x = 27, text = "town.sign.bibit", wall = Color3.fromRGB(208, 190, 156), awning = C.DUSTY_BLUE },
	}
	for i, shop in plusSide do
		local cf = bridgeAt(shop.x, DECK_Y, 24) * CFrame.Angles(0, math.pi, 0)
		buildShop(town, `Shop{i}`, cf, 16, 12, 8, shop.wall, roofs[i], shop.awning, Locale.t(shop.text))
	end

	-- -Z strip: a shop at each end, the warung stall in the middle (built separately).
	local minusSide = {
		{ x = -28, text = "town.sign.pancing", wall = Color3.fromRGB(208, 190, 156), awning = C.TERRACOTTA },
		{ x = 28, text = "town.sign.ikan", wall = C.CREAM, awning = C.SAGE },
	}
	for i, shop in minusSide do
		buildShop(town, `Shop{i + 4}`, bridgeAt(shop.x, DECK_Y, -24), 16, 12, 8, shop.wall, C.DARKWOOD, shop.awning, Locale.t(shop.text))
	end

	-- Lamps on the deck.
	local lamps = map:FindFirstChild("Lamps") :: Folder
	for _, x in { -18, 18 } do
		for _, zSign in { 1, -1 } do
			lampPost(lamps, bridgeAt(x, DECK_Y, zSign * 31))
		end
	end

	-- Where players appear before their plot is assigned.
	local townSpawn = Instance.new("SpawnLocation")
	townSpawn.Name = "TownSpawn"
	townSpawn.Anchored = true
	townSpawn.Size = Vector3.new(8, 0.4, 8)
	townSpawn.CFrame = bridgeAt(0, DECK_Y + 0.25, 0)
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
	local wf = bridgeAt(0, DECK_Y, -24)

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

-- Docks + fishing spots + river sound -----------------------------------------------------

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

		-- Small sign so players know where they are and what level it needs.
		local level = FishingConfig.LOCATIONS[location].unlockLevel
		local name = Locale.t(`location.{location}`)
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(150, 26)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.MaxDistance = 55
		billboard.Parent = spot
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(245, 236, 214)
		label.TextStrokeTransparency = 0.6
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 16
		label.Text = if level > 1 then `{name} · Lv {level}` else name
		label.Parent = billboard
	end

	for _, entry in Map.RIVER_DOCKS do
		for _, side in { 1, -1 } do
			local origin = riverPoint(entry.t) + RIVER_SIDE * side * (Map.RIVER.WIDTH / 2)
			dock(origin, -RIVER_SIDE * side, entry.location)
		end
	end

	-- 3D river sound emitters (AudioController attaches the loop to parts with RiverSound = true).
	for i, t in Map.RIVER_SOUND_T do
		local emitter = block(fishing, `RiverSound{i}`, Vector3.new(2, 1, 2), CFrame.new(riverPoint(t) + Vector3.new(0, -1, 0)), C.STONE)
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

-- A low bamboo fence on the slanted edges and the front of each land (not solid: visitors can walk in, you just
-- see where your land ends). The front has a gap in the middle.
local function buildLandFences(map: Folder)
	local fences = folder(map, "LandFences")
	local distance = Plots.DISTANCE

	for _, slot in Plots.LAYOUT do
		local frame = CFrame.new(slot.x * distance, 0, slot.z * distance) * CFrame.Angles(0, slot.yaw, 0)
		local function at(x: number, z: number): Vector3
			return (frame * CFrame.new(x, 0, z)).Position
		end
		local function line(points: { Vector3 })
			for i, point in points do
				local post = block(fences, "Post", Vector3.new(0.5, 2.4, 0.5), CFrame.new(point + Vector3.new(0, 1.2, 0)), C.BAMBOO, Enum.Material.Wood)
				post.CanCollide = false
				local nextPoint = points[i + 1]
				if nextPoint then
					local mid = (point + nextPoint) / 2 + Vector3.new(0, 1.7, 0)
					local rail = block(fences, "Rail", Vector3.new(0.25, 0.25, (nextPoint - point).Magnitude),
						CFrame.lookAt(mid, mid + (nextPoint - point)), C.BAMBOO, Enum.Material.Wood)
					rail.CanCollide = false
				end
			end
		end

		-- Slanted side edges, from the front to the back row (x follows the middle of the 4-stud staircase).
		for _, side in { 1, -1 } do
			local points: { Vector3 } = {}
			local z = Land.FRONT_Z
			while z >= Land.BACK_Z do
				table.insert(points, at(side * (distance - z - Land.APEX - 2), z))
				z -= 12
			end
			line(points)
		end

		-- Front edge, with a 16-stud gap in the middle.
		local frontHalf = distance - Land.FRONT_Z - Land.APEX - 2
		for _, side in { 1, -1 } do
			local points: { Vector3 } = {}
			local x = 8
			while x <= frontHalf do
				table.insert(points, at(side * x, Land.FRONT_Z))
				x += 12
			end
			table.insert(points, at(side * frontHalf, Land.FRONT_Z))
			line(points)
		end
	end
end

-- Procedural fallback (balls on sticks), used only when ServerStorage > MapModels > Nature is empty.
local function buildProceduralTrees(map: Folder)
	local trees = folder(map, "Trees")
	local random = Random.new(1127)
	local riverClear = Map.RIVER.WIDTH / 2 + 12
	local roadClear = Map.ROAD.WIDTH / 2 + 10

	local function tree(x: number, z: number)
		if math.abs(x - z) / SQRT2 < riverClear or math.abs(x + z) / SQRT2 < roadClear then
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
	ring(Map.SIZE / 2 - 3, 24) -- just inside the walls (land now reaches 8 studs from the wall)
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

local function buildNature(map: Folder, trees: { Model }, bushes: { Model }, rocks: { Model }, giants: { Model })
	local nature = folder(map, "Nature")
	local random = Random.new(1127)
	local riverClear = Map.RIVER.WIDTH / 2 + 12 -- trees stay this far from the river / road axes
	local roadClear = Map.ROAD.WIDTH / 2 + 10
	local half = Map.SIZE / 2

	-- Every plot's frame (world <- plot-local), to keep nature off the player lands.
	local frames: { CFrame } = {}
	for _, slot in Plots.LAYOUT do
		table.insert(frames, CFrame.new(slot.x * Plots.DISTANCE, 0, slot.z * Plots.DISTANCE) * CFrame.Angles(0, slot.yaw, 0))
	end
	local function onLand(x: number, z: number, margin: number): boolean
		local point = Vector3.new(x, 0, z)
		for _, frame in frames do
			local localPoint = frame:PointToObjectSpace(point)
			if Land.contains(localPoint.X, localPoint.Z, margin) then
				return true
			end
		end
		return false
	end
	local function nearAxes(x: number, z: number, river: number, road: number): boolean
		return math.abs(x - z) / SQRT2 < river or math.abs(x + z) / SQRT2 < road
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

	-- baseY = ground level under the thing (a rock in the river stands on the bed). Everything gets a random turn and
	-- a slight lean (rocks more) so nothing looks stamped out in a row.
	local function put(templates: { Model }, group: string, x: number, z: number, height: number, tint: boolean, baseY: number?)
		local template = templates[random:NextInteger(1, #templates)]
		-- Never cover a player's land: the player must be able to place things on every grid cell. The footprint
		-- radius is half of the model's widest side after scaling to `height`; if any of it would reach the land, skip.
		local extents = template:GetExtentsSize()
		local footprint = math.max(extents.X, extents.Z) * (height / math.max(extents.Y, 0.01)) / 2
		if onLand(x, z, footprint + 0.5) then
			return
		end
		local lean = math.rad(if group == "Batu" then 14 elseif group == "Semak" then 5 else 3)
		local rotation = CFrame.Angles(random:NextNumber(-lean, lean), random:NextNumber(0, math.pi * 2), random:NextNumber(-lean, lean))
		-- Stand on the REAL terrain: the ground is not flat (river bank, foothills), so sample its height under the
		-- thing (center + 4 points around it) and rest on the LOWEST, so no side hovers; then sink it further because
		-- trunk and rock bottoms are narrow and pointed and must be fully buried.
		local ground = baseY or groundY(x, z, height * (if group == "Pohon" then 0.08 elseif group == "Semak" then 0.25 else 0.22))
		local model = placeTemplate(template, nature, group, CFrame.new(x, ground, z) * rotation, height)
		local sink = height * (if group == "Pohon" then 0.13 elseif group == "Semak" then 0.12 else 0.2)
		model:PivotTo(model:GetPivot() - Vector3.new(0, sink, 0))
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
					if not nearAxes(x, z, riverClear, roadClear) then
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

		-- Trees along the road verge (smaller, so their crowns stay off the land fences): both arms, not in town.
		local verge = Map.ROAD.WIDTH / 2 + 7
		local u = 130
		while u < half * SQRT2 - 30 do
			for _, sign in { 1, -1 } do
				for _, side in { 1, -1 } do
					local across = Vector3.new(1, 0, 1) / SQRT2
					local point = roadPoint(sign * (u + random:NextNumber(-8, 8))) + across * side * (verge + random:NextNumber(-1.5, 1.5))
					if math.abs(point.X) < half - 6 and math.abs(point.Z) < half - 6 and not onLand(point.X, point.Z, 4) then
						put(trees, "Pohon", point.X, point.Z, random:NextNumber(11, 16), true)
					end
				end
			end
			u += random:NextNumber(26, 40)
		end
	end

	-- 2. Bushes (and now and then a rock) hugging the outside of every land: sample along its slanted sides.
	for index = 1, #frames do
		local frame = frames[index]
		local z = Land.BACK_Z
		while z <= Land.FRONT_Z do
			for _, side in { 1, -1 } do
				local edge = Plots.DISTANCE - z - Land.APEX
				local localX = side * (edge + random:NextNumber(3, 9))
				local world = frame * Vector3.new(localX, 0, z + random:NextNumber(-3, 3))
				if
					not onLand(world.X, world.Z, 2)
					and not nearAxes(world.X, world.Z, Map.RIVER.WIDTH / 2 + 3, Map.ROAD.WIDTH / 2 + 3)
					and math.abs(world.X) < half - 4
					and math.abs(world.Z) < half - 4
				then
					if #rocks > 0 and random:NextNumber() < 0.22 then
						put(rocks, "Batu", world.X, world.Z, random:NextNumber(3, 7), false)
					elseif #bushes > 0 then
						put(bushes, "Semak", world.X, world.Z, random:NextNumber(4, 7.5), true)
					end
				end
			end
			z += random:NextNumber(4.5, 8)
		end
	end

	-- 2b. River banks, irregular like a real stream: big boulders that stand in the water (on the river bed, tops
	-- above the surface), groups of small stones on the bank, patches of bushes, and gaps. Not at docks or town.
	if #bushes > 0 or #rocks > 0 then
		local waterEdge = Map.RIVER.WIDTH / 2
		local bedY = -Map.RIVER.DEPTH
		local function nearDock(t: number): boolean
			for _, entry in Map.RIVER_DOCKS do
				if math.abs(entry.t - t) < 10 then
					return true
				end
			end
			return false
		end
		local function bankPoint(t: number, side: number, distance: number): Vector3
			return riverPoint(t) + RIVER_SIDE * side * distance
		end
		local function inside(point: Vector3): boolean
			return math.abs(point.X) < half - 6 and math.abs(point.Z) < half - 6
		end

		local t = 60
		while t < half * SQRT2 - 20 do
			for _, sign in { 1, -1 } do
				for _, side in { 1, -1 } do
					local tt = sign * t + random:NextNumber(-6, 6)
					local roll = random:NextNumber()
					if not nearDock(tt) then
						if roll < 0.22 and #rocks > 0 then
							-- Boulder in (or against) the water: its bottom on the river bed, its top breaking the surface.
							-- Centered in the water (the land starts 4 studs past the bank), so even a wide boulder stays off it.
							local distance = waterEdge + random:NextNumber(-8, -1)
							local point = bankPoint(tt, side, distance)
							if inside(point) then
								put(rocks, "Batu", point.X, point.Z, random:NextNumber(9, 16), false, bedY)
							end
						elseif roll < 0.42 and #rocks > 0 then
							-- A few stones on the bank, small to medium, close together.
							local base = bankPoint(tt, side, waterEdge + random:NextNumber(0.3, 1.8))
							for _ = 1, random:NextInteger(1, 3) do
								local point = base + Vector3.new(random:NextNumber(-3, 3), 0, random:NextNumber(-3, 3))
								if inside(point) then
									put(rocks, "Batu", point.X, point.Z, random:NextNumber(1.2, 3.2), false)
								end
							end
						elseif roll < 0.72 and #bushes > 0 then
							-- A patch of one to three bushes of different sizes.
							local base = bankPoint(tt, side, waterEdge + random:NextNumber(1, 3.5))
							for _ = 1, random:NextInteger(1, 3) do
								local point = base + Vector3.new(random:NextNumber(-3, 3), 0, random:NextNumber(-3, 3))
								if inside(point) then
									put(bushes, "Semak", point.X, point.Z, random:NextNumber(2, 6), true)
								end
							end
						end
					end
				end
			end
			t += random:NextNumber(5, 15)
		end
	end

	-- 3. Rocks scattered in the forest belt: single boulders and small groups of two or three.
	if #rocks > 0 then
		for _ = 1, 90 do
			local radius = half + random:NextNumber(10, 70)
			local along = random:NextNumber(-radius, radius)
			local sign = if random:NextNumber() < 0.5 then 1 else -1
			local x, z = along, radius * sign -- on a side parallel to the X axis ...
			if random:NextNumber() < 0.5 then
				x, z = radius * sign, along -- ... or to the Z axis
			end
			if not nearAxes(x, z, riverClear, roadClear) then
				put(rocks, "Batu", x, z, random:NextNumber(5, 11), false)
				for _ = 1, random:NextInteger(0, 2) do
					put(rocks, "Batu", x + random:NextNumber(-6, 6), z + random:NextNumber(-6, 6), random:NextNumber(2.5, 6), false)
				end
			end
		end
	end

	-- 3b. Big boulders on the foothills' toes, where the woods meet the mountains.
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

	-- 4. Bushes in the forest belt, so the woods have an undergrowth.
	if #bushes > 0 then
		for _ = 1, 160 do
			local radius = half + random:NextNumber(4, 50)
			local along = random:NextNumber(-radius, radius)
			local sign = if random:NextNumber() < 0.5 then 1 else -1
			local x, z = along, radius * sign
			if random:NextNumber() < 0.5 then
				x, z = radius * sign, along
			end
			if not nearAxes(x, z, riverClear, roadClear) then
				put(bushes, "Semak", x, z, random:NextNumber(5, 9), true)
			end
		end
	end
end

local function buildTrees(map: Folder)
	local trees, bushes, rocks = natureTemplates("Pohon"), natureTemplates("Semak"), natureTemplates("Batu")
	if #trees == 0 and #bushes == 0 and #rocks == 0 then
		buildProceduralTrees(map)
		return
	end
	buildNature(map, trees, bushes, rocks, natureTemplates("Pohon", true))
end

-- Plot house ------------------------------------------------------------------------------

-- Called by PlotService for every plot it builds. The house is scenery; decor can't be placed on it (Decor.BLOCKED_EXTRA).
function MapService.AddHouse(plot: Model)
	local origin = plot.PrimaryPart
	if not origin then
		return
	end
	local house = Map.HOUSE
	-- Footprint center on the plot surface; the front (stairs / porch) faces local +Z, toward the road.
	local cf = origin.CFrame * CFrame.new(house.X, origin.Size.Y / 2, house.Z)

	local template = getTemplate("RumahPanggung")
	if template then
		placeTemplate(template, plot, "Rumah", cf, house.HEIGHT)
		return
	end

	local model = Instance.new("Model")
	model.Name = "Rumah"
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			block(model, "Post", Vector3.new(0.8, 3, 0.8), cf * CFrame.new(sx * 5, 1.5, sz * 4.5), C.DARKWOOD, Enum.Material.Wood)
		end
	end
	block(model, "Floor", Vector3.new(12, 0.6, 11), cf * CFrame.new(0, 3.3, 0), C.PLANK, Enum.Material.WoodPlanks)
	block(model, "Walls", Vector3.new(10, 5, 9), cf * CFrame.new(0, 6.1, 0), C.BAMBOO, Enum.Material.Wood)
	block(model, "Roof", Vector3.new(14, 0.7, 13), cf * CFrame.new(0, 9.1, 0.2) * CFrame.Angles(math.rad(14), 0, 0), C.TERRACOTTA, Enum.Material.Slate)
	local door = block(model, "Door", Vector3.new(2.6, 4, 0.3), cf * CFrame.new(-2, 5.6, 4.6), C.DARKWOOD, Enum.Material.Wood)
	door.CanCollide = false
	local window = block(model, "Window", Vector3.new(2.8, 2.2, 0.3), cf * CFrame.new(2.6, 6.4, 4.6), C.GLASS, Enum.Material.Glass)
	window.CanCollide = false
	model.Parent = plot
end

-- Lifecycle -------------------------------------------------------------------------------

function MapService.Init()
	if Workspace:FindFirstChild("Map") then
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

function MapService.BridgeCFrame(x: number, y: number, z: number): CFrame
	return bridgeAt(x, y, z)
end

return MapService
