--!strict
-- Client visuals for the world cycle: smooth ClockTime, tweened lighting per phase/rain,
-- clouds, a pooled rain emitter that follows the camera, and night-time decor lamps.
-- Reads Workspace attributes CycleStart / DayPhase / Raining (set by WorldService).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local WorldClock = require(ReplicatedStorage.Shared.Modules.WorldClock)

local LIGHT_TAG = "DecorLight"
local CLOCK_UPDATE_SECONDS = 0.25

local WorldController = {}

local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local clouds: Clouds?
local rainPart: Part
local rainEmitter: ParticleEmitter
local lampsOn = false

-- Reuses ANY existing instance of the class: the place already has the Studio-template Atmosphere / Bloom /
-- SunRays, and a second Atmosphere is ignored by the engine (that grey default fog hid our presets).
local function getOrCreate(parent: Instance, className: string, name: string): any
	local existing = parent:FindFirstChildOfClass(className)
	if existing then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function setupEffects()
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true

	atmosphere = getOrCreate(Lighting, "Atmosphere", "KT_Atmosphere")
	-- Offset high: far terrain (the mountain rows, 470+ studs out) fades into the haze as soft silhouettes.
	atmosphere.Offset = 0.6
	atmosphere.Glare = 0.1

	colorCorrection = getOrCreate(Lighting, "ColorCorrectionEffect", "KT_Color")
	colorCorrection.Contrast = 0
	colorCorrection.Brightness = 0

	local bloom = getOrCreate(Lighting, "BloomEffect", "KT_Bloom")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.3

	local sunRays = getOrCreate(Lighting, "SunRaysEffect", "KT_SunRays")
	sunRays.Intensity = 0.06
	sunRays.Spread = 0.6

	-- Sky: no textured skybox (the default one paints grey clouds and hard stars over our colors). The sky
	-- gradient comes from the Atmosphere (World.PRESETS), volumetric Clouds below, and procedural stars at night.
	local sky = getOrCreate(Lighting, "Sky", "KT_Sky")
	for _, face in { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" } do
		sky["Skybox" .. face] = ""
	end
	sky.StarCount = 2500
	sky.CelestialBodiesShown = true
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 9

	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local cloudInstance = getOrCreate(terrain, "Clouds", "KT_Clouds")
		cloudInstance.Density = 0.6
		cloudInstance.Color = Color3.fromRGB(255, 250, 244)
		clouds = cloudInstance
	end
end

local function setupRain()
	rainPart = Instance.new("Part")
	rainPart.Name = "KT_Rain"
	rainPart.Anchored = true
	rainPart.CanCollide = false
	rainPart.CanQuery = false
	rainPart.CanTouch = false
	rainPart.Transparency = 1
	rainPart.Size = Vector3.new(80, 1, 80)
	rainPart.Parent = Workspace

	rainEmitter = Instance.new("ParticleEmitter")
	rainEmitter.Enabled = false
	-- Mobile gets fewer particles.
	rainEmitter.Rate = if UserInputService.TouchEnabled then 140 else 300
	rainEmitter.Lifetime = NumberRange.new(0.9, 1.1)
	rainEmitter.Speed = NumberRange.new(55, 65)
	rainEmitter.EmissionDirection = Enum.NormalId.Bottom
	rainEmitter.SpreadAngle = Vector2.new(4, 4)
	rainEmitter.Size = NumberSequence.new(0.12)
	rainEmitter.Squash = NumberSequence.new(3) -- stretch into streaks
	rainEmitter.Transparency = NumberSequence.new(0.45)
	rainEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 210, 220))
	rainEmitter.LightInfluence = 1
	rainEmitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	rainEmitter.Parent = rainPart
end

local function applyLighting(instant: boolean)
	local phase = Workspace:GetAttribute("DayPhase")
	local preset = World.PRESETS[if typeof(phase) == "string" then phase else "siang"] or World.PRESETS.siang
	local raining = Workspace:GetAttribute("Raining") == true
	local rain = World.RAIN_LIGHTING

	local info = TweenInfo.new(if instant then 0 else World.TRANSITION_SECONDS, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, {
		Brightness = preset.brightness * (if raining then rain.brightnessMult else 1),
		Ambient = preset.ambient,
		OutdoorAmbient = preset.outdoorAmbient,
	}):Play()
	TweenService:Create(colorCorrection, info, {
		TintColor = if raining then preset.tint:Lerp(rain.tint, 0.6) else preset.tint,
		Saturation = preset.saturation + (if raining then rain.saturationAdd else 0),
	}):Play()
	TweenService:Create(atmosphere, info, {
		Density = preset.atmosphereDensity + (if raining then rain.densityAdd else 0),
		Color = preset.atmosphereColor,
		Decay = preset.atmosphereDecay,
		Haze = preset.haze,
	}):Play()
	if clouds then
		TweenService:Create(clouds, info, { Cover = if raining then World.RAIN_CLOUD_COVER else World.CLOUD_COVER }):Play()
	end

	rainEmitter.Enabled = raining
end

local function setLamp(part: Instance, on: boolean)
	local light = part:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = on
	end
	if part:IsA("BasePart") then
		part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

local function updateLamps()
	local phase = Workspace:GetAttribute("DayPhase")
	local shouldBeOn = typeof(phase) == "string" and World.LAMP_PHASES[phase] == true
	if shouldBeOn == lampsOn then
		return
	end
	lampsOn = shouldBeOn
	for _, part in CollectionService:GetTagged(LIGHT_TAG) do
		setLamp(part, lampsOn)
	end
end

function WorldController.Init()
	setupEffects()
	setupRain()
end

function WorldController.Start()
	applyLighting(true)
	updateLamps()
	Workspace:GetAttributeChangedSignal("DayPhase"):Connect(function()
		applyLighting(false)
		updateLamps()
	end)
	Workspace:GetAttributeChangedSignal("Raining"):Connect(function()
		applyLighting(false)
	end)
	CollectionService:GetInstanceAddedSignal(LIGHT_TAG):Connect(function(part)
		setLamp(part, lampsOn)
	end)

	-- Rain volume follows the camera (one emitter, no per-drop work in Lua).
	RunService.RenderStepped:Connect(function()
		if rainEmitter.Enabled then
			local camera = Workspace.CurrentCamera
			rainPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 30, 0))
		end
	end)

	-- Smooth sun/moon movement.
	while true do
		local cycleStart = Workspace:GetAttribute("CycleStart")
		if typeof(cycleStart) == "number" then
			local _, clock = WorldClock.at(Workspace:GetServerTimeNow(), cycleStart)
			Lighting.ClockTime = clock
		end
		task.wait(CLOCK_UPDATE_SECONDS)
	end
end

return WorldController
