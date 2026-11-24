--!strict
-- Puddles after rain (K-134). Server-side so every player sees the same puddles. When a rain ends (and it is not
-- continuing as another rain kind), up to Config/Weather PUDDLE_MAX flat puddles appear on random ground spots across
-- the map. Each fades in, stays, then fades out and is destroyed PUDDLE_LIFETIME seconds after the rain ended.
-- A new rain clears the puddles at once (no leaks, no stale parts). Puddles are non-collidable, non-queryable: they
-- block nothing and cannot be used. Placement: a random spot within MAP_RADIUS of the town centre; a valid spot is
-- where the first thing a ray hits straight down is TERRAIN (not water, not a part such as a bed, path or building),
-- and the surface is flat (normal.Y > 0.9). Spots that fail are skipped; at most PUDDLE_TRIES tries per spawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WeatherConfig = require(ReplicatedStorage.Shared.Config.Weather)
local WorldService = require(script.Parent.WorldService)

local PuddleService = {}

local MAP_RADIUS = 150 -- studs from the town centre (the island is 90 and the lands reach past the canal)
local FOLDER_NAME = "KT_Puddles"
local FLAT_NORMAL = 0.9
-- Puddles only on grass-like ground: not water, cobblestone plazas, dirt roads, sand or stone (paths and town ground).
local PUDDLE_MATERIALS: { [Enum.Material]: boolean } = {
	[Enum.Material.Grass] = true,
	[Enum.Material.LeafyGrass] = true,
	[Enum.Material.Mud] = true,
}

local random = Random.new()
local active: { [Instance]: boolean } = {} -- live puddles (for clear)

local function folder(): Folder
	local found = Workspace:FindFirstChild(FOLDER_NAME)
	if found and found:IsA("Folder") then
		return found
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	return created
end

-- Removes every puddle now (rain started again, or a test asked for it).
function PuddleService.Clear()
	for puddle in active do
		active[puddle] = nil
		pcall(function()
			puddle:Destroy()
		end)
	end
end

-- Pluggable visual (K-135): ReplicatedStorage/Assets/Puddle, a Part or Model, is cloned when present. Its own parts keep
-- their authored Transparency as the rest value (0 = solid). Missing template = the placeholder disc below.
-- Fade works on any template: every BasePart in it is tweened from fully clear to its authored Transparency and back.
-- Model rules: the template is placed at its authored size, lying as authored; the placeholder path is unchanged.
local function template(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local found = assets and assets:FindFirstChild("Puddle")
	if found and (found:IsA("BasePart") or found:IsA("Model")) then
		return found
	end
	return nil
end

-- Fades every BasePart of the puddle to its rest value (in) or to fully clear (out). The rest value is the authored
-- Transparency, remembered once in the part's KTRestTransparency attribute the first time it is faded.
-- Returns the tween list so the caller can wait for the last one.
local function fadeTo(puddle: Instance, out: boolean, duration: number): { Tween }
	local tweens = {}
	for _, part in if puddle:IsA("BasePart") then { puddle } else puddle:GetDescendants() do
		if part:IsA("BasePart") then
			local rest = part:GetAttribute("KTRestTransparency")
			if typeof(rest) ~= "number" then
				rest = part.Transparency
				part:SetAttribute("KTRestTransparency", rest)
			end
			if not out then
				part.Transparency = 1
			end
			local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Sine), { Transparency = if out then 1 else rest })
			tween:Play()
			table.insert(tweens, tween)
		end
	end
	return tweens
end

-- One puddle at a valid spot: the template if present, else a glossy blue-grey disc lying on the ground.
-- Fades in, stays, fades out, destroyed.
local function place(position: Vector3, lifetime: number)
	local source = template()
	local puddle: Instance
	if source then
		local clone = source:Clone()
		clone.Parent = folder()
		-- Keeps the template's own rotation (lying as authored), moves it onto the ground spot.
		local pivot = if clone:IsA("Model") then clone:GetPivot() else (clone :: BasePart).CFrame
		local onGround = CFrame.new(position + Vector3.new(0, 0.06, 0)) * (pivot - pivot.Position)
		if clone:IsA("Model") then
			clone:PivotTo(onGround)
		else
			(clone :: BasePart).CFrame = onGround
		end
		for _, part in if clone:IsA("BasePart") then { clone } else clone:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
			end
		end
		puddle = clone
	else
		local disc = Instance.new("Part")
		disc.Name = "Puddle"
		disc.Shape = Enum.PartType.Cylinder
		disc.Anchored = true
		disc.CanCollide = false
		disc.CanQuery = false
		disc.CanTouch = false
		disc.CastShadow = false
		disc.Material = Enum.Material.Glass
		disc.Color = Color3.fromRGB(96, 116, 128)
		disc.Reflectance = 0.2
		-- A cylinder's axis is X: thickness 0.12 along X, diameter 5-8 along Y and Z; turned to lie flat.
		local diameter = random:NextNumber(5, 8)
		disc.Size = Vector3.new(0.12, diameter, diameter)
		disc.CFrame = CFrame.new(position + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
		disc.Transparency = 1
		disc:SetAttribute("KTRestTransparency", 0.35)
		disc.Parent = folder()
		puddle = disc
	end
	active[puddle] = true

	local fade = WeatherConfig.PUDDLE_FADE_SECONDS
	fadeTo(puddle, false, fade)
	task.delay(math.max(lifetime - fade, 0), function()
		if active[puddle] ~= true then
			return -- cleared earlier
		end
		local tweens = fadeTo(puddle, true, fade)
		local function destroy()
			active[puddle] = nil
			pcall(function()
				puddle:Destroy()
			end)
		end
		local last = tweens[#tweens]
		if last then
			last.Completed:Once(destroy) -- the last part's fade ends with the rest
		else
			destroy() -- a template with no BasePart: nothing to fade
		end
	end)
end

-- Places up to PUDDLE_MAX puddles on valid ground. Replaces any puddles already on the map.
function PuddleService.Spawn(lifetime: number?)
	PuddleService.Clear()
	local life = lifetime or WeatherConfig.PUDDLE_LIFETIME
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder() }
	local placed = 0
	for _ = 1, WeatherConfig.PUDDLE_TRIES do
		if placed >= WeatherConfig.PUDDLE_MAX then
			break
		end
		local angle = random:NextNumber() * math.pi * 2
		local radius = math.sqrt(random:NextNumber()) * MAP_RADIUS
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local hit = Workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), params)
		if hit and hit.Instance:IsA("Terrain") and PUDDLE_MATERIALS[hit.Material] == true and hit.Normal.Y > FLAT_NORMAL then
			place(hit.Position, life)
			placed += 1
		end
	end
end

function PuddleService.Start()
	-- Rain ended for good (not another kind of rain): puddles appear. Rain starting again clears them.
	WorldService.RainEnded:Connect(function()
		if not WorldService.IsRaining() then
			PuddleService.Spawn()
		end
	end)
	WorldService.RainChanged:Connect(function(raining: boolean)
		if raining then
			PuddleService.Clear()
		end
	end)
end

return PuddleService
