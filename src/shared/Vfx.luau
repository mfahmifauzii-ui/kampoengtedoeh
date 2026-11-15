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
	-- Coins after a sale or a finished order: gold sparkles that pop up and fall.
	coins = {
		{ texture = SPARKLE, count = 22, speed = NumberRange.new(8, 13), life = NumberRange.new(0.7, 1.0), spread = 35, gravity = -40, size = size(0.55, 0.65, 0.2), alpha = 1, color = tint(Color3.fromRGB(255, 230, 120), Color3.fromRGB(240, 170, 50)), light = 0.9 },
		{ texture = SPARKLE, count = 8, speed = NumberRange.new(1, 3), life = NumberRange.new(0.5, 0.8), spread = 180, gravity = 0, size = size(0.9, 1.1, 0.1), alpha = 0.6, color = tint(Color3.fromRGB(255, 245, 190), Color3.fromRGB(255, 210, 110)), light = 1 },
	},
	-- Level up: a golden fountain with warm confetti-like sparkles.
	levelup = {
		{ texture = SPARKLE, count = 60, speed = NumberRange.new(12, 20), life = NumberRange.new(1.0, 1.6), spread = 25, gravity = -22, size = size(0.6, 0.8, 0.15), alpha = 1, color = tint(Color3.fromRGB(255, 236, 140), Color3.fromRGB(255, 150, 90)), light = 1 },
		{ texture = SPARKLE, count = 30, speed = NumberRange.new(4, 8), life = NumberRange.new(1.2, 1.8), spread = 180, gravity = -4, size = size(0.4, 0.6, 0.1), alpha = 1, color = tint(Color3.fromRGB(180, 240, 255), Color3.fromRGB(190, 255, 170)), light = 1 },
		{ texture = FIRE, count = 10, speed = NumberRange.new(2, 5), life = NumberRange.new(0.6, 1.0), spread = 30, gravity = 8, size = size(1.2, 2.2, 0.4), alpha = 0.55, color = tint(Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 170, 80)), light = 1 },
	},
	-- New land block: dust and leaves where the forest was cleared.
	land = {
		{ texture = SMOKE, count = 18, speed = NumberRange.new(3, 7), life = NumberRange.new(1.0, 1.6), spread = 80, gravity = -2, size = size(1.5, 3.5, 5), alpha = 0.3, color = tint(Color3.fromRGB(220, 200, 160), Color3.fromRGB(190, 175, 140)), light = 0 },
		{ texture = SPARKLE, count = 30, speed = NumberRange.new(5, 10), life = NumberRange.new(1.2, 1.8), spread = 70, gravity = -10, size = size(0.5, 0.6, 0.2), alpha = 1, color = tint(Color3.fromRGB(150, 220, 90), Color3.fromRGB(90, 170, 60)), light = 0.4 },
	},
	-- Quest done: small cheerful burst of mixed colours.
	quest = {
		{ texture = SPARKLE, count = 28, speed = NumberRange.new(6, 11), life = NumberRange.new(0.8, 1.2), spread = 60, gravity = -16, size = size(0.5, 0.6, 0.12), alpha = 1, color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 160)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 130)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 220, 255)) }), light = 0.9 },
	},
}

-- Rings: a flat disc that grows and fades (splash, ripple, catch glow).
local RINGS = {
	cast = { color = Color3.fromRGB(200, 235, 255), from = 0.6, to = 7, time = 0.55 },
	bite = { color = Color3.fromRGB(190, 225, 255), from = 0.4, to = 4.5, time = 0.6 },
	catch = { color = Color3.fromRGB(255, 220, 120), from = 0.8, to = 9, time = 0.7 },
	levelup = { color = Color3.fromRGB(255, 220, 130), from = 1, to = 14, time = 0.8 },
	land = { color = Color3.fromRGB(200, 240, 150), from = 2, to = 20, time = 0.9 },
	ripple = { color = Color3.fromRGB(215, 240, 255), from = 0.5, to = 5, time = 1.4 },
	-- Fish sign on the water: a thin ring (a bright disc with a water-coloured disc on top), grows softly and fades.
	fishmark = { color = Color3.fromRGB(235, 250, 255), hole = Color3.fromRGB(44, 118, 176), from = 1.4, to = 8, time = 2.2, alpha = 0.85 },
}

-- Disc on the water surface. `hole` turns it into a ring: a second, smaller disc in the water colour sits on top.
local function ring(name, cf)
	local r = RINGS[name]
	if not r then return end
	local function disc(color: Color3, from: number, to: number, transparency: number, lift: number)
		local d = Instance.new("Part")
		d.Name = "VfxRing"
		d.Shape = Enum.PartType.Cylinder
		d.Anchored = true
		d.CanCollide = false
		d.CanQuery = false
		d.CanTouch = false
		d.Material = Enum.Material.Neon
		d.Color = color
		d.Transparency = transparency
		d.Size = Vector3.new(0.12, from, from)
		d.CFrame = cf * CFrame.new(0, lift, 0) * CFrame.Angles(0, 0, math.pi / 2)
		d.Parent = workspace
		local grow = TweenInfo.new(r.time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(d, grow, { Size = Vector3.new(0.05, to, to) }):Play()
		-- Fish marks fade linearly: a quad-out fade would be gone in the first few tenths of a second.
		local fade = if r.hole then TweenInfo.new(r.time, Enum.EasingStyle.Linear) else grow
		TweenService:Create(d, fade, { Transparency = 1 }):Play()
		Debris:AddItem(d, r.time + 0.2)
	end
	local alpha = r.alpha or 0.25
	disc(r.color, r.from, r.to, 1 - alpha, 0)
	if r.hole then
		-- The hole is drawn a bit higher and grows a little slower, so the ring keeps a thin rim as it spreads.
		disc(r.hole, r.from * 0.7, r.to * 0.8, 0.35, 0.02)
	end
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

-- Just the expanding ring (ambient ripples on the water).
function Vfx.ring(name: string, cf: CFrame)
	pcall(ring, name, cf)
end

-- Looping effects that stay on a part until removed (ready crops, fireflies, motes). Returns the emitter.
local LOOPS = {
	ready = { texture = SPARKLE, rate = 2.5, speed = NumberRange.new(0.6, 1.4), life = NumberRange.new(1.0, 1.6), spread = 180, gravity = 1.2, size = size(0.25, 0.4, 0.05), alpha = 0.15, color = tint(Color3.fromRGB(255, 245, 170), Color3.fromRGB(255, 215, 110)), light = 1, shape = Enum.ParticleEmitterShape.Box },
	fireflies = { texture = SPARKLE, rate = 6, speed = NumberRange.new(0.3, 1.0), life = NumberRange.new(3, 5), spread = 180, gravity = 0.15, size = size(0.18, 0.28, 0.1), alpha = 0.05, color = tint(Color3.fromRGB(220, 255, 140), Color3.fromRGB(180, 240, 110)), light = 1, shape = Enum.ParticleEmitterShape.Box },
	motes = { texture = SPARKLE, rate = 3, speed = NumberRange.new(0.2, 0.6), life = NumberRange.new(4, 6), spread = 180, gravity = 0.05, size = size(0.12, 0.18, 0.06), alpha = 0.45, color = tint(Color3.fromRGB(255, 244, 210), Color3.fromRGB(255, 230, 180)), light = 0.6, shape = Enum.ParticleEmitterShape.Box },
	smoke = { texture = SMOKE, rate = 3, speed = NumberRange.new(1.5, 2.5), life = NumberRange.new(3, 4.5), spread = 12, gravity = 0.6, size = size(0.8, 2.2, 3.5), alpha = 0.55, color = tint(Color3.fromRGB(230, 226, 220), Color3.fromRGB(200, 200, 200)), light = 0, shape = Enum.ParticleEmitterShape.Box },
}

function Vfx.loop(name: string, parent: Instance): ParticleEmitter?
	local l = LOOPS[name]
	if not l then return nil end
	local ok, e = pcall(function()
		local e = Instance.new("ParticleEmitter")
		e.Name = "VfxLoop_" .. name
		e.Texture = l.texture
		e.Color = l.color
		e.Lifetime = l.life
		e.Speed = l.speed
		e.SpreadAngle = Vector2.new(l.spread, l.spread)
		e.Size = l.size
		e.Transparency = fade(l.alpha)
		e.LightEmission = l.light
		e.Acceleration = Vector3.new(0, l.gravity, 0)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-40, 40)
		e.Rate = l.rate
		e.Shape = l.shape
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		e.LightInfluence = if l.light > 0.5 then 0 else 1
		e.Parent = parent -- shaped emitters go straight under a Part (an Attachment ignores Shape)
		return e
	end)
	return if ok then e else nil
end

return Vfx
