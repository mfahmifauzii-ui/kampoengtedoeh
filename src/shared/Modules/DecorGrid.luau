--!strict
-- Shared grid math for decor placement (server validates, client previews the same rules)
-- plus the model builder (placeholder parts or a real model from ReplicatedStorage.DecorModels).
--
-- Grid: the plot is SIZE/CELL cells per side. Cell (0,0) is the plot's local -X/-Z corner.
-- An entry's x/z is its min-corner cell; footprint w×d swaps on odd rotations.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Decor = require(script.Parent.Parent.Config.Decor)
local PlotsConfig = require(script.Parent.Parent.Config.Plots)
local Types = require(script.Parent.Parent.Types)
local Land = require(script.Parent.Land)

type Item = Decor.Item

local CELL = Decor.CELL
-- Cell (0,0) stays at plot-local (-HALF, -HALF) so saved decor keeps its place; cells may now be negative
-- or larger than the old 48, as long as they are on the land (see Land).
local HALF = PlotsConfig.SIZE / 2
local X_MIN = math.floor((-Land.MAX_HALF_WIDTH + HALF) / CELL)
local X_MAX = math.ceil((Land.MAX_HALF_WIDTH + HALF) / CELL) -- exclusive
local Z_MIN = math.floor((Land.BACK_Z + HALF) / CELL)
local Z_MAX = math.ceil((Land.FRONT_Z + HALF) / CELL) -- exclusive

local DecorGrid = {}
DecorGrid.X_MIN, DecorGrid.X_MAX, DecorGrid.Z_MIN, DecorGrid.Z_MAX = X_MIN, X_MAX, Z_MIN, Z_MAX

local function key(x: number, z: number): number
	return x * 1000 + z
end

-- No-build rectangles in plot-local studs: the house and the pond (Land.fixedRects) plus config extras.
local function blockedRects(): { Land.Rect }
	local rects: { Land.Rect } = {}
	for _, rect in Land.fixedRects() do
		table.insert(rects, rect)
	end
	for _, rect in Decor.BLOCKED_EXTRA do
		table.insert(rects, { minX = rect.min.X, minZ = rect.min.Y, maxX = rect.max.X, maxZ = rect.max.Y })
	end
	return rects
end

-- Cells that are off the land (staircase edge) or on a fixed rectangle can never hold decor.
local blocked: { [number]: boolean } = {}
do
	local rects = blockedRects()
	for x = X_MIN, X_MAX - 1 do
		for z = Z_MIN, Z_MAX - 1 do
			local cell: Land.Rect = {
				minX = -HALF + x * CELL,
				minZ = -HALF + z * CELL,
				maxX = -HALF + (x + 1) * CELL,
				maxZ = -HALF + (z + 1) * CELL,
			}
			local isBlocked = not Land.rectInside(cell)
			if not isBlocked then
				for _, rect in rects do
					if Land.rectsOverlap(cell, rect) then
						isBlocked = true
						break
					end
				end
			end
			if isBlocked then
				blocked[key(x, z)] = true
			end
		end
	end
end

function DecorGrid.footprint(item: Item, r: number): (number, number)
	if r % 2 == 1 then
		return item.d, item.w
	end
	return item.w, item.d
end

-- Plot-local rectangle (studs) covered by a placed entry; nil for an unknown item.
function DecorGrid.entryRect(entry: Types.DecorEntry): Land.Rect?
	local item = Decor.byId[entry.id]
	if not item then
		return nil
	end
	local w, d = DecorGrid.footprint(item, entry.r)
	return {
		minX = -HALF + entry.x * CELL,
		minZ = -HALF + entry.z * CELL,
		maxX = -HALF + (entry.x + w) * CELL,
		maxZ = -HALF + (entry.z + d) * CELL,
	}
end

-- [cellKey] = uid for every placed entry. Farm beds and rects (ponds) occupy decor cells too (uid -1, never a real uid).
function DecorGrid.occupancy(entries: { Types.DecorEntry }, tiles: { { cx: number, cz: number } }?, rects: { Land.Rect }?): { [number]: number }
	local occupied = {}
	local function block(rect: Land.Rect)
		for x = (rect.minX + HALF) // CELL, math.ceil((rect.maxX + HALF) / CELL) - 1 do
			for z = (rect.minZ + HALF) // CELL, math.ceil((rect.maxZ + HALF) / CELL) - 1 do
				occupied[key(x, z)] = -1
			end
		end
	end
	for _, entry in entries do
		local item = Decor.byId[entry.id]
		if item then
			local w, d = DecorGrid.footprint(item, entry.r)
			for x = entry.x, entry.x + w - 1 do
				for z = entry.z, entry.z + d - 1 do
					occupied[key(x, z)] = entry.uid
				end
			end
		end
	end
	-- Farm beds and extra rectangles (ponds) take decor cells too (uid -1).
	for _, tile in tiles or {} do
		block(Land.tileRect(tile.cx, tile.cz))
	end
	for _, rect in rects or {} do
		block(rect)
	end
	return occupied
end

-- ignoreUid lets an item being moved overlap its own old cells.
function DecorGrid.isValid(item: Item, x: number, z: number, r: number, occupied: { [number]: number }, ignoreUid: number?): boolean
	local w, d = DecorGrid.footprint(item, r)
	if x < X_MIN or z < Z_MIN or x + w > X_MAX or z + d > Z_MAX then
		return false
	end
	for cx = x, x + w - 1 do
		for cz = z, z + d - 1 do
			local k = key(cx, cz)
			if blocked[k] then
				return false
			end
			local owner = occupied[k]
			if owner ~= nil and owner ~= ignoreUid then
				return false
			end
		end
	end
	return true
end

-- CFrame of the footprint center (ground level) relative to the plot Origin's top surface.
function DecorGrid.localCFrame(item: Item, x: number, z: number, r: number, groundY: number): CFrame
	local w, d = DecorGrid.footprint(item, r)
	local cx = -HALF + (x + w / 2) * CELL
	local cz = -HALF + (z + d / 2) * CELL
	return CFrame.new(cx, groundY, cz) * CFrame.Angles(0, r * math.pi / 2, 0)
end

-- Nearest min-corner cell so the item is centered on a plot-local point (clamped to the plot).
function DecorGrid.cellFromLocal(item: Item, r: number, localPoint: Vector3): (number, number)
	local w, d = DecorGrid.footprint(item, r)
	local x = math.floor((localPoint.X + HALF) / CELL - w / 2 + 0.5)
	local z = math.floor((localPoint.Z + HALF) / CELL - d / 2 + 0.5)
	return math.clamp(x, X_MIN, X_MAX - w), math.clamp(z, Z_MIN, Z_MAX - d)
end

-- Builds the visual model with its pivot at the footprint center, ground level.
function DecorGrid.build(item: Item): Model
	local folder = ReplicatedStorage:FindFirstChild("DecorModels")
	local custom = folder and folder:FindFirstChild(item.id)
	if custom and custom:IsA("Model") then
		local model = custom:Clone()
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		return model
	end

	local model = Instance.new("Model")
	model.Name = item.id
	for index, spec in item.parts do
		local part = Instance.new("Part")
		part.Name = `Part{index}`
		part.Anchored = true
		part.Size = spec.size
		part.Color = spec.color
		part.Material = spec.material or Enum.Material.Wood
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		local cframe = CFrame.new(spec.pos)
		if spec.shape == "ball" then
			-- Ball parts are forced round; a sphere mesh allows squashed shapes (tree crowns).
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
		elseif spec.shape == "cylinder" then
			part.Shape = Enum.PartType.Cylinder
			cframe *= CFrame.Angles(0, 0, math.pi / 2) -- stand the X axis up
		elseif spec.shape == "wheel" then
			part.Shape = Enum.PartType.Cylinder
			cframe *= CFrame.Angles(0, math.pi / 2, 0) -- axle along Z
		end
		part.CFrame = cframe
		if spec.light then
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 214, 160)
			light.Brightness = 1.2
			light.Range = 12
			light.Shadows = false
			light.Enabled = false
			light.Parent = part
			CollectionService:AddTag(part, "DecorLight")
		end
		part.Parent = model
	end
	model.WorldPivot = CFrame.identity
	return model
end

return DecorGrid
