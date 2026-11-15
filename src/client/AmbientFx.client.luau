-- Ambient and reward VFX (client only, cheap, fails inert):
--   * fireflies around the player at night, warm dust motes in the day
--   * coins on a sale / finished order, a fountain on level up, dust + leaves on a new land block, a burst on a quest
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Net = require(RS.Shared.Modules.Net)
local Vfx = require(RS.Shared.Vfx)

local player = Players.LocalPlayer

local function rootCF(): CFrame?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root and (root :: BasePart).CFrame or nil
end

-- Reward bursts ----------------------------------------------------------------------------------------------
local REWARD = {
	["sell.sold"] = "coins",
	["order.done"] = "coins",
	["pond.collected"] = "coins",
	["land.bought"] = "land",
	["quest.done"] = "quest",
	["book.milestone"] = "quest",
}

Net.Listen("Notify", function(key: any)
	local preset = REWARD[key]
	local cf = rootCF()
	if not preset or not cf then
		return
	end
	if preset == "land" then
		local ground = cf * CFrame.new(0, -2.5, -6)
		Vfx.burst("land", ground)
	else
		Vfx.burst(preset, cf * CFrame.new(0, 2.5, 0))
	end
end)

local lastLevel = player:GetAttribute("Level")
player:GetAttributeChangedSignal("Level"):Connect(function()
	local level = player:GetAttribute("Level")
	if typeof(level) == "number" and typeof(lastLevel) == "number" and level > lastLevel then
		local cf = rootCF()
		if cf then
			Vfx.burst("levelup", cf * CFrame.new(0, -2.8, 0))
		end
	end
	lastLevel = level
end)

-- Fireflies (night) and motes (day) in a box that follows the player -------------------------------------------
local cloud = Instance.new("Part")
cloud.Name = "AmbientFxCloud"
cloud.Anchored = true
cloud.CanCollide = false
cloud.CanQuery = false
cloud.CanTouch = false
cloud.Transparency = 1
cloud.Size = Vector3.new(70, 8, 70)
cloud.Parent = Workspace

local fireflies = Vfx.loop("fireflies", cloud)
local motes = Vfx.loop("motes", cloud)

local function isNight(): boolean
	local t = Lighting.ClockTime
	return t < 5.8 or t > 18.6
end

-- Main tick (4 Hz is plenty for ambience) ------------------------------------------------------------------
-- (the fishing spots' signs and water marks live in FishSpotFx)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then
		return
	end
	acc = 0
	local cf = rootCF()
	if cf then
		cloud.CFrame = CFrame.new(cf.Position + Vector3.new(0, 1, 0))
	end
	local night = isNight()
	if fireflies then
		fireflies.Enabled = night
	end
	if motes then
		motes.Enabled = not night and Lighting.ClockTime > 7 and Lighting.ClockTime < 17.5
	end
end)
