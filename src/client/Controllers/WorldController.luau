--!strict
-- Client visuals for the world cycle: smooth ClockTime, tweened lighting per phase/rain,
-- clouds, a pooled rain emitter that follows the camera, and night-time decor lamps.
-- Reads Workspace attributes CycleStart / DayPhase / Raining (set by WorldService).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local WeatherConfig = require(ReplicatedStorage.Shared.Config.Weather)
local WorldClock = require(ReplicatedStorage.Shared.Modules.WorldClock)
local State = require(script.Parent.Parent.State)

local LIGHT_TAG = "DecorLight"
local CLOCK_UPDATE_SECONDS = 0.25

local WorldController = {}

local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local clouds: Clouds?
local rainPart: Part
local rainEmitter: ParticleEmitter
local rainTween: Tween?
-- K-133: ground splashes around the player (pooled: one part and one emitter for the whole session).
local splashPart: Part
local splashEmitter: ParticleEmitter
local splashTween: Tween?
local groundParams: RaycastParams
local groundY = 0
local nextGroundCheck = 0
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
	rainPart.Size = Vector3.new(40, 1, 40) -- a flat sheet above the camera: drops fall through the view
	rainPart.Parent = Workspace

	rainEmitter = Instance.new("ParticleEmitter")
	rainEmitter.Enabled = false
	-- One emitter for the whole session, rate eased by fadeRain (Config/Weather PARTICLES, low counts for phones).
	rainEmitter.Rate = 0
	-- K-129 (rain visibility): a 40-stud box 18 studs above the camera. Drops fall through the view and stay in it ~1 s.
	-- (The earlier 80-stud box at 30 studs spread ~40 drops over an area the camera barely sees.)
	-- K-132 (owner, final): drops fall straight down, each streak vertical. K-131 (horizontal) was reverted: the wall
	-- emitted sideways, and VelocityParallel stretched every streak along that sideways motion.
	rainEmitter.Lifetime = NumberRange.new(1.0, 1.2)
	rainEmitter.Speed = NumberRange.new(28, 34)
	rainEmitter.EmissionDirection = Enum.NormalId.Bottom
	rainEmitter.Acceleration = Vector3.zero
	rainEmitter.SpreadAngle = Vector2.new(4, 4)
	-- K-129 (rain visibility): 0.12 studs drew 1-2 px at play distance, so the rain was not seen. 0.22 with a stronger stretch.
	-- K-129 (rain visibility, tested in Studio): 0.12-0.25 studs grey drops were not readable; 0.35 pale-blue streaks are.
	rainEmitter.Size = NumberSequence.new(0.5) -- K-132: 0.35 was too faint to see from the default phone camera
	rainEmitter.Squash = NumberSequence.new(5) -- stretch into streaks
	rainEmitter.Transparency = NumberSequence.new(0.05)
	rainEmitter.Color = ColorSequence.new(Color3.fromRGB(235, 242, 250))
	rainEmitter.LightInfluence = 1
	-- K-132: VelocityParallel drew the streaks HORIZONTAL in Studio while the drops fell vertically (tested, screenshots).
	-- VelocityPerpendicular gave near-vertical streaks in the same test.
	rainEmitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	rainEmitter.Parent = rainPart

	-- K-133: splash droplets on the ground around the camera. A flat disc at ground level; its rate is a fraction of the rain
	-- rate (Config/Weather SPLASH_RATIO), so Kurangi gerak (which lowers the rain rate) lowers the splashes too.
	splashPart = Instance.new("Part")
	splashPart.Name = "KT_Splash"
	splashPart.Anchored = true
	splashPart.CanCollide = false
	splashPart.CanQuery = false
	splashPart.CanTouch = false
	splashPart.Transparency = 1
	splashPart.Size = Vector3.new(30, 0.2, 30)
	splashPart.Parent = Workspace
	splashEmitter = Instance.new("ParticleEmitter")
	splashEmitter.Enabled = false
	splashEmitter.Rate = 0
	splashEmitter.Shape = Enum.ParticleEmitterShape.Disc
	splashEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	splashEmitter.EmissionDirection = Enum.NormalId.Top
	splashEmitter.Lifetime = NumberRange.new(0.25, 0.35)
	splashEmitter.Speed = NumberRange.new(3, 5)
	splashEmitter.Acceleration = Vector3.new(0, -30, 0)
	splashEmitter.SpreadAngle = Vector2.new(30, 30)
	splashEmitter.Size = NumberSequence.new(0.12, 0.2)
	splashEmitter.Transparency = NumberSequence.new(0.3, 1)
	splashEmitter.Color = ColorSequence.new(Color3.fromRGB(215, 228, 240))
	splashEmitter.LightInfluence = 1
	splashEmitter.Orientation = Enum.ParticleOrientation.FacingCamera
	splashEmitter.Parent = splashPart

	groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Exclude
	groundParams.FilterDescendantsInstances = { rainPart, splashPart }
end

-- Target rate for the current weather. Picture quality Rendah (1) draws no rain at all: the cheapest setting on a 4 GB phone.
local function rainTarget(): number
	local snapshot = State.current :: any
	local quality = snapshot and snapshot.settings and snapshot.settings.quality
	if quality == 1 or Workspace:GetAttribute("Raining") ~= true then
		return 0
	end
	local kind = Workspace:GetAttribute("Weather")
	local rate = (typeof(kind) == "string" and WeatherConfig.PARTICLES[kind]) or WeatherConfig.PARTICLES.gerimis
	-- Kurangi gerak (GUI 4.11): fewer drops; the rain itself stays.
	if snapshot and snapshot.settings and snapshot.settings.reduceMotion == true then
		rate *= WeatherConfig.REDUCE_MOTION_DENSITY
	end
	return rate
end

-- Eases the rate toward its target; a new target cancels the running tween. Disables the emitter once faded out.
local function fadeRain()
	if rainTween then
		rainTween:Cancel()
	end
	local target = rainTarget()
	if target > 0 then
		rainEmitter.Enabled = true
	end
	rainTween = TweenService:Create(rainEmitter, TweenInfo.new(WeatherConfig.RAIN_FADE_SECONDS, Enum.EasingStyle.Sine), { Rate = target })
	rainTween.Completed:Once(function(playback)
		if playback == Enum.PlaybackState.Completed and target == 0 then
			rainEmitter.Enabled = false
		end
	end)
	rainTween:Play()

	-- K-133: splashes follow the rain rate (a fraction of it), with the same fade in and out.
	local splashTarget = target * WeatherConfig.SPLASH_RATIO
	if splashTarget > 0 then
		splashEmitter.Enabled = true
	end
	if splashTween then
		splashTween:Cancel()
	end
	splashTween = TweenService:Create(splashEmitter, TweenInfo.new(WeatherConfig.RAIN_FADE_SECONDS, Enum.EasingStyle.Sine), { Rate = splashTarget })
	splashTween.Completed:Once(function(playback)
		if playback == Enum.PlaybackState.Completed and splashTarget == 0 then
			splashEmitter.Enabled = false
		end
	end)
	splashTween:Play()
end

-- Petir: one flash every LIGHTNING_INTERVAL seconds, at most LIGHTNING_FLASH_SECONDS long (Bab 21.3).
local function lightningFlash()
	local base = Lighting.Brightness
	Lighting.Brightness = base + 2
	TweenService:Create(Lighting, TweenInfo.new(WeatherConfig.LIGHTNING_FLASH_SECONDS, Enum.EasingStyle.Linear), { Brightness = base }):Play()
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

	fadeRain()
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
	Workspace:GetAttributeChangedSignal("Weather"):Connect(function()
		applyLighting(false)
	end)
	State.Changed:Connect(fadeRain) -- picture quality changed in Pengaturan
	task.spawn(function()
		while true do
			task.wait(WeatherConfig.LIGHTNING_INTERVAL)
			if Workspace:GetAttribute("Weather") == "petir" then
				lightningFlash()
			end
		end
	end)
	CollectionService:GetInstanceAddedSignal(LIGHT_TAG):Connect(function(part)
		setLamp(part, lampsOn)
	end)

	-- Rain volume follows the camera (one emitter, no per-drop work in Lua).
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if rainEmitter.Enabled then
			rainPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 18, 0))
		end
		if splashEmitter.Enabled then
			-- ground height under the camera, sampled 4 times a second (no per-frame raycast)
			local now = os.clock()
			if now >= nextGroundCheck then
				nextGroundCheck = now + 0.25
				local from = camera.CFrame.Position
				groundParams.FilterDescendantsInstances = { rainPart, splashPart, game:GetService("Players").LocalPlayer.Character or rainPart }
				local hit = Workspace:Raycast(from, Vector3.new(0, -300, 0), groundParams)
				groundY = if hit then hit.Position.Y else from.Y - 12
			end
			local at = camera.CFrame.Position
			splashPart.CFrame = CFrame.new(at.X, groundY + 0.1, at.Z)
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
