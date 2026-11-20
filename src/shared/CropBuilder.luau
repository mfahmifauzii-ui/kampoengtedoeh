--!strict
-- Stylized crop models built from Parts (no uploaded mesh needed). One Model per crop id, base at y = 0, about 3 studs
-- tall; FarmController scales it per growth stage. Used when ReplicatedStorage > CropModels has no model for a crop.
-- Ellipsoids are Parts with a Sphere SpecialMesh. Every part is recolourable here.

local Crops = require(script.Parent.Config.Crops)

local CropBuilder = {}

local LEAF = Color3.fromRGB(96, 168, 70)
local LEAF_DARK = Color3.fromRGB(66, 132, 56)
local STEM = Color3.fromRGB(110, 150, 70)

local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- An ellipsoid: a Part with a sphere mesh sized to the part.
local function blob(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = part(model, name, size, cf, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function stick(model: Model, name: string, a: Vector3, b: Vector3, thick: number, color: Color3): Part
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local cf = if math.abs(dir.Y) > 0.999 then CFrame.new(mid) else CFrame.lookAt(mid, b) * CFrame.Angles(math.rad(90), 0, 0)
	return part(model, name, Vector3.new(thick, len, thick), cf, color)
end

-- A leaf: a flat ellipsoid leaning out from `base` toward angle `yaw`, tilted `tilt` degrees from vertical.
local function leaf(model: Model, base: Vector3, yaw: number, tilt: number, length: number, width: number, color: Color3)
	local cf = CFrame.new(base) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(-tilt), 0, 0)
	blob(model, "Leaf", Vector3.new(width, length, width * 0.18), cf * CFrame.new(0, length / 2, 0), color)
end

local BUILDERS: { [string]: (Model) -> () } = {}

BUILDERS.kangkung = function(m)
	for i = 0, 6 do
		local yaw = i * 51
		local tilt = 18 + (i % 3) * 10
		leaf(m, Vector3.new(0, 0, 0), yaw, tilt, 2.4 - (i % 2) * 0.5, 0.7, if i % 2 == 0 then LEAF else LEAF_DARK)
	end
	stick(m, "Stem", Vector3.new(0, 0, 0), Vector3.new(0, 1.6, 0), 0.18, STEM)
end

BUILDERS.cabai = function(m)
	stick(m, "Stem", Vector3.new(0, 0, 0), Vector3.new(0, 2.2, 0), 0.2, STEM)
	blob(m, "Bush", Vector3.new(2.2, 1.6, 2.2), CFrame.new(0, 2.2, 0), LEAF_DARK)
	blob(m, "Bush2", Vector3.new(1.6, 1.2, 1.6), CFrame.new(0.4, 2.8, -0.2), LEAF)
	local red = Color3.fromRGB(214, 52, 40)
	for i = 0, 4 do
		local a = math.rad(i * 72 + 20)
		local p = Vector3.new(math.cos(a) * 1.2, 1.7, math.sin(a) * 1.2)
		part(m, "Chili", Vector3.new(0.22, 0.8, 0.22), CFrame.new(p) * CFrame.Angles(math.rad(12), a, 0), red)
	end
end

BUILDERS.tomat = function(m)
	stick(m, "Stake", Vector3.new(0.5, 0, 0), Vector3.new(0.5, 3.0, 0), 0.14, Color3.fromRGB(150, 110, 70))
	stick(m, "Stem", Vector3.new(0, 0, 0), Vector3.new(0, 2.4, 0), 0.2, STEM)
	blob(m, "Bush", Vector3.new(2.3, 1.7, 2.3), CFrame.new(0, 2.1, 0), LEAF_DARK)
	blob(m, "Top", Vector3.new(1.5, 1.1, 1.5), CFrame.new(-0.2, 2.8, 0.1), LEAF)
	local red = Color3.fromRGB(222, 70, 52)
	for i, p in { Vector3.new(1.05, 1.6, 0.45), Vector3.new(-0.85, 1.5, 0.8), Vector3.new(0.1, 1.45, -1.12), Vector3.new(-0.65, 2.25, -0.85) } do
		local f = part(m, "Tomato", Vector3.one * (0.62 - i * 0.03), CFrame.new(p), red)
		f.Shape = Enum.PartType.Ball
	end
end

BUILDERS.terong = function(m)
	stick(m, "Stem", Vector3.new(0, 0, 0), Vector3.new(0, 2.0, 0), 0.22, Color3.fromRGB(110, 120, 80))
	for i = 0, 4 do
		leaf(m, Vector3.new(0, 1.2, 0), i * 72, 55, 1.5, 0.9, if i % 2 == 0 then LEAF else LEAF_DARK)
	end
	blob(m, "Bush", Vector3.new(1.8, 1.2, 1.8), CFrame.new(0, 2.2, 0), LEAF_DARK)
	local purple = Color3.fromRGB(96, 52, 120)
	for _, x in { -0.7, 0.75 } do
		blob(m, "Eggplant", Vector3.new(0.55, 1.3, 0.55), CFrame.new(x, 1.0, 0.3) * CFrame.Angles(0, 0, math.rad(x * 14)), purple)
		part(m, "Cap", Vector3.new(0.45, 0.18, 0.45), CFrame.new(x, 1.68, 0.3), Color3.fromRGB(90, 130, 60))
	end
end

BUILDERS.jagung = function(m)
	stick(m, "Stalk", Vector3.new(0, 0, 0), Vector3.new(0, 3.6, 0), 0.28, Color3.fromRGB(120, 160, 70))
	for i = 0, 5 do
		leaf(m, Vector3.new(0, 0.6 + i * 0.5, 0), i * 137, 50, 1.9 - i * 0.15, 0.42, if i % 2 == 0 then LEAF else LEAF_DARK)
	end
	blob(m, "Husk", Vector3.new(0.6, 1.3, 0.6), CFrame.new(0.32, 2.0, 0) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(150, 180, 90))
	blob(m, "Cob", Vector3.new(0.45, 0.9, 0.45), CFrame.new(0.42, 2.35, 0) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(240, 200, 70))
	stick(m, "Tassel", Vector3.new(0, 3.6, 0), Vector3.new(0.2, 4.1, 0), 0.08, Color3.fromRGB(210, 180, 110))
end

BUILDERS.singkong = function(m)
	local wood = Color3.fromRGB(150, 110, 80)
	stick(m, "Stem", Vector3.new(0, 0, 0), Vector3.new(0.1, 3.0, 0), 0.24, wood)
	stick(m, "Stem2", Vector3.new(0, 1.0, 0), Vector3.new(-0.7, 2.5, 0.2), 0.18, wood)
	for _, top in { Vector3.new(0.1, 3.0, 0), Vector3.new(-0.7, 2.5, 0.2) } do
		for i = 0, 6 do
			leaf(m, top, i * 51, 62, 1.1, 0.3, if i % 2 == 0 then LEAF else LEAF_DARK)
		end
	end
	blob(m, "Mound", Vector3.new(1.4, 0.5, 1.4), CFrame.new(0, 0.05, 0), Color3.fromRGB(110, 80, 56))
end

BUILDERS.padi = function(m)
	local gold = Color3.fromRGB(214, 186, 96)
	local green = Color3.fromRGB(150, 176, 80)
	for i = 0, 8 do
		local a = math.rad(i * 40)
		local r = 0.25 + (i % 3) * 0.12
		local base = Vector3.new(math.cos(a) * r * 0.5, 0, math.sin(a) * r * 0.5)
		local top = Vector3.new(math.cos(a) * r * 1.6, 2.6 + (i % 2) * 0.3, math.sin(a) * r * 1.6)
		stick(m, "Stalk", base, top, 0.08, green)
		local droop = top + Vector3.new(math.cos(a) * 0.45, -0.35, math.sin(a) * 0.45)
		stick(m, "Grain", top, droop, 0.2, gold)
	end
end

BUILDERS.pisang = function(m)
	stick(m, "Trunk", Vector3.new(0, 0, 0), Vector3.new(0, 3.0, 0), 0.6, Color3.fromRGB(130, 150, 80))
	for i = 0, 4 do
		leaf(m, Vector3.new(0, 2.9, 0), i * 72 + 10, 58, 2.4, 0.95, if i % 2 == 0 then LEAF else LEAF_DARK)
	end
	local yellow = Color3.fromRGB(236, 206, 70)
	for i = 0, 5 do
		local a = math.rad(i * 60)
		part(m, "Banana", Vector3.new(0.18, 0.6, 0.18), CFrame.new(0.45 + math.cos(a) * 0.18, 2.1 - (i % 2) * 0.25, math.sin(a) * 0.18) * CFrame.Angles(0, 0, math.rad(25)), yellow)
	end
	stick(m, "BunchStem", Vector3.new(0.3, 2.6, 0), Vector3.new(0.5, 1.7, 0), 0.08, Color3.fromRGB(110, 120, 60))
end

local cache: { [string]: Model } = {}

-- Generic plant for a crop with no builder yet (Bayam, Sawi, Ubi Jalar until their own models exist): a visible stem and
-- five leaves in the crop's own colour. Every part is visible (no hidden root), and the stem is the PrimaryPart so the
-- pivot stays upright.
local function genericBuilder(model: Model, color: Color3): Part
	local stem = stick(model, "Stem", Vector3.new(0, 0, 0), Vector3.new(0, 1.6, 0), 0.18, STEM)
	for i = 0, 4 do
		local yaw = i * 72
		local tilt = 30 + (i % 2) * 12
		leaf(model, Vector3.new(0, 0.9, 0), yaw, tilt, 1.8 - (i % 2) * 0.3, 0.6, if i % 2 == 0 then color else LEAF_DARK)
	end
	return stem
end

-- Returns a template Model for a crop id (cached; clone it before use), or nil for an id that is not in Config/Crops.
-- Crops without a builder get the generic plant, so a new crop never breaks the farm.
function CropBuilder.template(cropId: string): Model?
	if cache[cropId] then
		return cache[cropId]
	end
	local crop = Crops.byId[cropId]
	if not crop then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = cropId
	local builder = BUILDERS[cropId]
	if builder then
		-- An upright, invisible root at the base is the PrimaryPart, so the model's pivot and bounding box stay level
		-- (a tilted leaf as PrimaryPart tipped the whole plant over when FarmController placed it).
		local root = part(model, "Root", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.1, 0), Color3.new(0, 0, 0))
		root.Transparency = 1
		model.PrimaryPart = root
		builder(model)
	else
		model.PrimaryPart = genericBuilder(model, crop.color)
	end
	cache[cropId] = model
	return model
end

return CropBuilder
