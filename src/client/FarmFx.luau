-- Client feedback for farming: animation, sound and particles for plant, water and harvest.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local KSP = game:GetService("KeyframeSequenceProvider")
local Sfx = require(RS.Shared.Sfx)
local Vfx = require(RS.Shared.Vfx)

local FarmFx = {}
local player = Players.LocalPlayer
local ids = nil
local tracks = {}

-- animation clip name -> sound role (nil = no sound)
local ACTIONS = {
	plant = { clip = "FarmPlant", sound = "plant_seed" },
	water = { clip = "FarmWater", sound = "water_pour" },
}

local function registerIds()
	if ids then return end
	ids = {}
	local anims = RS:FindFirstChild("CustomAnims")
	if not anims then return end
	for name, action in pairs(ACTIONS) do
		local seq = anims:FindFirstChild(action.clip)
		if seq then
			ids[name] = KSP:RegisterKeyframeSequence(seq)
		end
	end
end

local function trackFor(char, name)
	if tracks[name] and tracks[name].animator.Parent then
		return tracks[name].track
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or not ids or not ids[name] then return nil end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	local a = Instance.new("Animation")
	a.AnimationId = ids[name]
	local track = animator:LoadAnimation(a)
	tracks[name] = { track = track, animator = animator }
	return track
end

-- Where the effect appears: at the feet for planting, in front of the hand for watering and harvest.
local function effectCFrame(name)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	if name == "plant" then
		return root.CFrame * CFrame.new(0, -2.8, -2)
	elseif name == "water" then
		return root.CFrame * CFrame.new(1.4, 0.6, -2.2)
	elseif name == "harvest" then
		return root.CFrame * CFrame.new(0, 0.5, -2.2)
	end
	return nil
end

local function play(name)
	registerIds()
	local action = ACTIONS[name]
	local char = player.Character
	if char and action then
		local track = trackFor(char, name)
		if track then track:Play(0.1) end
	end
	if action and action.sound then
		local root = char and char:FindFirstChild("HumanoidRootPart")
		Sfx.play(action.sound, root)
	end
	local cf = effectCFrame(name)
	if cf then
		Vfx.burst(name == "plant" and "plant" or name == "water" and "water" or "harvest", cf)
	end
end

function FarmFx.plant() play("plant") end
function FarmFx.water() play("water") end
function FarmFx.harvest()
	local cf = effectCFrame("harvest")
	if cf then Vfx.burst("harvest", cf) end
end

return FarmFx
