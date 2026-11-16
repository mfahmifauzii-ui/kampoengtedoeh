local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local KSP = game:GetService("KeyframeSequenceProvider")
local Net = require(RS.Shared.Modules.Net)
local anims = RS:WaitForChild("CustomAnims")
local template = workspace:WaitForChild("FishingRod")
local player = Players.LocalPlayer

-- RegisterKeyframeSequence only works in Studio; on a live server it errors. Without it the rod plays no keyframe
-- animation (the game still runs), so a failure is logged once and skipped instead of stopping this whole script.
local ids = {}
for _, name in ipairs({"FishingIdle", "FishingCast", "FishingReel", "FishingCatch"}) do
	local ok, id = pcall(function()
		return KSP:RegisterKeyframeSequence(anims:WaitForChild(name))
	end)
	if ok then
		ids[name] = id
	else
		warn(`[RodAnim] keyframe {name} not registered: {id}`)
	end
end

local Sfx = require(RS.Shared.Sfx)
local reelSound = nil
local lastSpot = nil
local Vfx = require(RS.Shared.Vfx)
local function spotCF(s)
	if not s then return nil end
	if s:IsA("BasePart") then return s.CFrame end
	if s:IsA("Model") then return s:GetPivot() end
	return nil
end
local function rootPart()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local rod = nil
local tracks = nil
local prevState = "idle"

local function loadTracks(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	local t = {}
	for name, id in pairs(ids) do
		local a = Instance.new("Animation")
		a.AnimationId = id
		t[name] = animator:LoadAnimation(a)
	end
	return t
end

local function equip()
	if rod then return end
	local char = player.Character
	if not char then return end
	local hand = char:FindFirstChild("RightHand")
	if not hand then return end
	tracks = loadTracks(char)
	rod = template:Clone()
	rod.Name = "EquippedRod"
	local grip = rod:FindFirstChild("Grip")
	for _, p in ipairs(rod:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
			if p ~= grip then
				local w = Instance.new("WeldConstraint")
				w.Part0 = grip
				w.Part1 = p
				w.Parent = grip
			end
		end
	end
	rod.Parent = char
	local motor = Instance.new("Motor6D")
	motor.Name = "RodGrip"
	motor.Part0 = hand
	motor.Part1 = grip
	motor.C0 = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	motor.C1 = CFrame.new()
	grip.CFrame = hand.CFrame * motor.C0
	motor.Parent = hand
end

local function stopAll()
	if tracks then
		for _, t in pairs(tracks) do t:Stop(0.15) end
	end
end

local function unequip()
	stopAll()
	tracks = nil
	if rod then rod:Destroy() rod = nil end
end

local function play(name)
	if not tracks then return end
	stopAll()
	tracks[name]:Play(0.15)
end

Net.Listen("FishState", function(state, spot)
	if state == "waiting" then
		equip()
		lastSpot = spot
		Sfx.play("fish_cast", rootPart())
		local castCF = spotCF(spot)
		if castCF then Vfx.burst("cast", castCF) end
		play("FishingCast")
		task.delay(1.2, function()
			if prevState == "waiting" then play("FishingIdle") end
		end)
	elseif state == "bite" then
		equip()
		Sfx.stop(reelSound)
		reelSound = Sfx.play("fish_reel", rootPart())
		local biteCF = spotCF(lastSpot)
		if biteCF then Vfx.burst("bite", biteCF) end
		play("FishingReel")
	elseif state == "idle" then
		Sfx.stop(reelSound)
		reelSound = nil
		if prevState == "bite" and tracks then
			Sfx.play("fish_catch", rootPart())
			local r = rootPart()
			if r then Vfx.burst("catch", r.CFrame * CFrame.new(0, 3.5, 0)) end
			play("FishingCatch")
			task.delay(1.3, function()
				if prevState == "idle" then unequip() end
			end)
		else
			unequip()
		end
	end
	prevState = state
end)
