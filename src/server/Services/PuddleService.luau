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

-- One puddle at a valid spot: a glossy blue-grey disc lying on the ground. Fades in, stays, fades out, destroyed.
local function place(position: Vector3, lifetime: number)
	local puddle = Instance.new("Part")
	puddle.Name = "Puddle"
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.CanQuery = false
	puddle.CanTouch = false
	puddle.CastShadow = false
	puddle.Material = Enum.Material.Glass
	puddle.Color = Color3.fromRGB(96, 116, 128)
	puddle.Reflectance = 0.2
	-- A cylinder's axis is X: thickness 0.12 along X, diameter 5-8 along Y and Z; turned to lie flat.
	local diameter = random:NextNumber(5, 8)
	puddle.Size = Vector3.new(0.12, diameter, diameter)
	puddle.CFrame = CFrame.new(position + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
	puddle.Transparency = 1
	puddle.Parent = folder()
	active[puddle] = true

	local fade = WeatherConfig.PUDDLE_FADE_SECONDS
	TweenService:Create(puddle, TweenInfo.new(fade, Enum.EasingStyle.Sine), { Transparency = 0.35 }):Play()
	task.delay(math.max(lifetime - fade, 0), function()
		if active[puddle] ~= true then
			return -- cleared earlier
		end
		local out = TweenService:Create(puddle, TweenInfo.new(fade, Enum.EasingStyle.Sine), { Transparency = 1 })
		out.Completed:Once(function()
			active[puddle] = nil
			pcall(function()
				puddle:Destroy()
			end)
		end)
		out:Play()
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
