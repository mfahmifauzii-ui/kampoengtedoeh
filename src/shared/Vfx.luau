-- Vfx: layered particle bursts and expanding rings at a CFrame. Client-side visuals only; every call is pcall-isolated.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Vfx = {}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

-- Each layer: one ParticleEmitter. Size/transparency/color are keyframed over the particle's life.
local function size(a, b, c) return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(0.5, b), NumberSequenceKeypoint.new(1, c) }) end
local function fade(peak) return NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, peak), NumberSequenceKeypoint.new(1, 1) }) end
local function tint(a, b) return ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b) }) end

local PRESETS = {
	plant = {
		{ texture = SMOKE, count = 10, speed = NumberRange.new(4, 9), life = NumberRange.new(0.5, 0.8), spread = 65, gravity = -26, size = size(0.6, 1.1, 0.4), alpha = 0.35, color = tint(Color3.fromRGB(140, 98, 60), Color3.fromRGB(90, 60, 36)), light = 0 },
		{ texture = SMOKE, count = 5, speed = NumberRange.new(1, 2.5), life = NumberRange.new(0.9, 1.3), spread = 180, gravity = 0, size = size(0.8, 1.5, 2.1), alpha = 0.14, color = tint(Color3.fromRGB(205, 180, 140), Color3.fromRGB(180, 160, 120)), light = 0 },
		{ texture = SPARKLE, count = 8, speed = NumberRange.new(3, 6), life = NumberRange.new(0.6, 1.0), spread = 120, gravity = -4, size = size(0.5, 0.7, 0.1), alpha = 0.9, color = tint(Color3.fromRGB(190, 255, 150), Color3.fromRGB(110, 200, 90)), light = 0.6 },
	},
	water = {
		{ texture = SPARKLE, count = 34, speed = NumberRange.new(6, 11), life = NumberRange.new(0.45, 0.7), spread = 30, gravity = -30, size = size(0.7, 0.9, 0.12), alpha = 1, color = tint(Color3.fromRGB(180, 230, 255), Color3.fromRGB(70, 150, 230)), light = 0.7 },
		{ texture = SMOKE, count = 6, speed = NumberRange.new(1, 3), life = NumberRange.new(0.8, 1.2), spread = 90, gravity = -2, size = size(0.5, 0.9, 1.2), alpha = 0.16, color = tint(Color3.fromRGB(200, 235, 255), Color3.fromRGB(160, 210, 240)), light = 0.2 },
		{ texture = SPARKLE, count = 6, speed = NumberRange.new(2, 4), life = NumberRange.new(0.4, 0.6), spread = 180, gravity = -14, size = size(0.25, 0.3, 0.02), alpha = 1, color = tint(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 220, 255)), light = 1 },
	},
	cast = {
		{ texture = SMOKE, count = 16, speed = NumberRange.new(5, 9), life = NumberRange.new(0.5, 0.9), spread = 80, gravity = -18, size = size(0.8, 1.6, 0.6), alpha = 0.45, color = tint(Color3.fromRGB(235, 248, 255), Color3.fromRGB(160, 210, 240)), light = 0.2 },
		{ texture = SPARKLE, count = 18, speed = NumberRange.new(7, 11), life = NumberRange.new(0.4, 0.7), spread = 60, gravity = -32, size = size(0.35, 0.4, 0.05), alpha = 0.95, color = tint(Color3.fromRGB(200, 240, 255), Color3.fromRGB(90, 170, 240)), light = 0.8 },
	},
	bite = {
		{ texture = SPARKLE, count = 10, speed = NumberRange.new(2, 4), life = NumberRange.new(0.5, 0.8), spread = 90, gravity = -6, size = size(0.4, 0.6, 0.1), alpha = 0.9, color = tint(Color3.fromRGB(220, 240, 255), Color3.fromRGB(120, 180, 240)), light = 0.9 },
	},
	catch = {
		{ texture = SPARKLE, count = 36, speed = NumberRange.new(7, 13), life = NumberRange.new(0.9, 1.3), spread = 170, gravity = -8, size = size(0.7, 0.9, 0.1), alpha = 1, color = tint(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 190, 80)), light = 1 },
		{ texture = FIRE, count = 6, speed = NumberRange.new(2, 4), life = NumberRange.new(0.6, 0.9), spread = 40, gravity = 4, size = size(0.8, 1.5, 0.2), alpha = 0.5, color = tint(Color3.fromRGB(255, 220, 130), Color3.fromRGB(255, 160, 60)), light = 1 },
	},
	harvest = {
		{ texture = SPARKLE, count = 28, speed = NumberRange.new(5, 9), life = NumberRange.new(0.8, 1.2), spread = 150, gravity = -10, size = size(0.6, 0.8, 0.1), alpha = 1, color = tint(Color3.fromRGB(190, 255, 140), Color3.fromRGB(255, 220, 110)), light = 1 },
		{ texture = SMOKE, count = 6, speed = NumberRange.new(1, 3), life = NumberRange.new(0.9, 1.3), spread = 120, gravity = -3, size = size(0.8, 1.8, 2.4), alpha = 0.28, color = tint(Color3.fromRGB(200, 255, 170), Color3.fromRGB(160, 230, 130)), light = 0.2 },
	},
}

-- Rings: a flat disc that grows and fades (splash, ripple, catch glow).
local RINGS = {
	cast = { color = Color3.fromRGB(200, 235, 255), from = 0.6, to = 7, time = 0.55 },
	bite = { color = Color3.fromRGB(190, 225, 255), from = 0.4, to = 4.5, time = 0.6 },
	catch = { color = Color3.fromRGB(255, 220, 120), from = 0.8, to = 9, time = 0.7 },
}

local function ring(name, cf)
	local r = RINGS[name]
	if not r then return end
	local disc = Instance.new("Part")
	disc.Name = "VfxRing"
	disc.Shape = Enum.PartType.Cylinder
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc.Material = Enum.Material.Neon
	disc.Color = r.color
	disc.Transparency = 0.25
	disc.Size = Vector3.new(0.12, r.from, r.from)
	disc.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	disc.Parent = workspace
	local info = TweenInfo.new(r.time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(disc, info, { Size = Vector3.new(0.05, r.to, r.to), Transparency = 1 }):Play()
	Debris:AddItem(disc, r.time + 0.2)
end

function Vfx.burst(name: string, cf: CFrame)
	local layers = PRESETS[name]
	if not layers then return end
	pcall(function()
		local anchor = Instance.new("Part")
		anchor.Name = "VfxAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.CFrame = cf
		anchor.Parent = workspace
		for _, layer in ipairs(layers) do
			local e = Instance.new("ParticleEmitter")
			e.Texture = layer.texture
			e.Color = layer.color
			e.Lifetime = layer.life
			e.Speed = layer.speed
			e.SpreadAngle = Vector2.new(layer.spread, layer.spread)
			e.Size = layer.size
			e.Transparency = fade(layer.alpha)
			e.LightEmission = layer.light
			e.Acceleration = Vector3.new(0, layer.gravity, 0)
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-120, 120)
			e.Rate = 0
			e.Parent = anchor
			e:Emit(layer.count)
		end
		Debris:AddItem(anchor, 2)
		ring(name, cf)
	end)
end

return Vfx
