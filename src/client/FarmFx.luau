-- Client feedback for farming: character animation, sound and particles for plant, water and harvest.
-- Every effect happens AT THE BED you work on (not on the player): the soil puffs where the seed goes in, the water falls from
-- the can onto the bed, the harvest sparkle rises from the crop. The character turns to face the bed first.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local KSP = game:GetService("KeyframeSequenceProvider")
local TweenService = game:GetService("TweenService")
local Sfx = require(RS.Shared.Sfx)
local Vfx = require(RS.Shared.Vfx)
local Farm = require(RS.Shared.Config.Farm)

local FarmFx = {}
local player = Players.LocalPlayer
local ids = nil
local tracks = {}

-- animation clip name -> sound role (nil = no sound)
local ACTIONS = {
	plant = { clip = "FarmPlant", sound = "plant_seed" },
	water = { clip = "FarmWater", sound = "water_pour" },
}

local SOUND_JITTER = 0.06 -- small random pitch per action (+-6%), so repeated harvests and waterings don't sound mechanical

FarmFx.PLANT_SECONDS = 0.55 -- when the seed "goes in": the caller sends FarmPlant then
FarmFx.WATER_SECONDS = 0.95 -- when the first water lands: the caller sends FarmWater then

local function registerIds()
	if ids then return end
	ids = {}
	local anims = RS:FindFirstChild("CustomAnims")
	for name, action in pairs(ACTIONS) do
		-- Roadmap §12.4: ID permanen dari Config/Farm.ANIMS (sudah di-publish) dipakai dulu, jadi jalan di server live.
		local permanent = Farm.ANIMS[action.clip]
		if permanent and permanent ~= "" then
			ids[name] = permanent
		else
			local seq = if anims then anims:FindFirstChild(action.clip) else nil
			if seq then
				-- Studio only (see RodAnimController): on a live server the animation is skipped, the effect still runs.
				local ok, id = pcall(function()
					return KSP:RegisterKeyframeSequence(seq)
				end)
				if ok then
					ids[name] = id
				end
			end
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

local function myRoot(): BasePart?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Top-centre of a bed, a little above the soil.
local function bedTop(bed: BasePart, lift: number?): CFrame
	return CFrame.new(bed.Position + Vector3.new(0, bed.Size.Y / 2 + (lift or 0.5), 0))
end

-- The character turns (client side) to face the bed it is working on.
local function faceBed(bed: BasePart)
	local root = myRoot()
	if not root then return end
	local target = Vector3.new(bed.Position.X, root.Position.Y, bed.Position.Z)
	if (target - root.Position).Magnitude > 0.5 then
		root.CFrame = CFrame.lookAt(root.Position, target)
	end
end

local function playClip(name: string)
	registerIds()
	local char = player.Character
	if char and ACTIONS[name] then
		local track = trackFor(char, name)
		if track then track:Play(0.1) end
	end
end

-- Watering can ---------------------------------------------------------------------------------------
-- A small tin watering can built from parts (no asset to load): body, rim, spout, sprinkler rose, wooden handle. It is
-- welded into the right hand like a Tool (spout forward) and tilts to pour.

local CAN_TIN = Color3.fromRGB(96, 168, 164)
local CAN_DARK = Color3.fromRGB(62, 120, 122)
local CAN_WOOD = Color3.fromRGB(150, 104, 62)
local CAN_SCALE = 1.3 -- the can is drawn at this size (a hand-held prop must read from the game camera distance)
local HANDLE_AT = Vector3.new(0, 0.1, 0.72) * CAN_SCALE -- the handle's centre in can space: this point sits in the hand

local function canPart(parent: Model, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Shape = shape
	part.Size = size * CAN_SCALE
	part.CFrame = CFrame.new(cf.Position * CAN_SCALE) * cf.Rotation
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function buildCan(): (Model, Part, Attachment)
	local can = Instance.new("Model")
	can.Name = "WateringCan"
	-- An unrotated invisible root: every part is welded to it, and the hand grips it, so "can space" = root space (a rotated
	-- cylinder body as the root would turn the whole prop on its side).
	local root = canPart(can, Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), CFrame.new(), CAN_TIN)
	root.Transparency = 1
	local up = CFrame.Angles(0, 0, math.pi / 2) -- cylinders lie along X: stand them up
	canPart(can, Enum.PartType.Cylinder, Vector3.new(0.95, 0.95, 0.95), up, CAN_TIN)
	canPart(can, Enum.PartType.Cylinder, Vector3.new(0.12, 1.0, 1.0), CFrame.new(0, 0.46, 0) * up, CAN_DARK)
	canPart(can, Enum.PartType.Cylinder, Vector3.new(0.12, 1.0, 1.0), CFrame.new(0, -0.42, 0) * up, CAN_DARK)

	-- Spout: a slim tube rising from the lower front, ending in a wider rose.
	local dir = Vector3.new(0, 0.55, -1).Unit
	local spoutStart = Vector3.new(0, -0.15, -0.42)
	local spoutLength = 1.15
	local spoutCenter = spoutStart + dir * (spoutLength / 2)
	local along = CFrame.lookAt(spoutCenter, spoutCenter + dir) * CFrame.Angles(0, math.pi / 2, 0)
	canPart(can, Enum.PartType.Cylinder, Vector3.new(spoutLength, 0.2, 0.2), along, CAN_TIN)
	local tip = spoutStart + dir * spoutLength
	local rose = CFrame.lookAt(tip + dir * 0.05, tip + dir) * CFrame.Angles(0, math.pi / 2, 0)
	canPart(can, Enum.PartType.Cylinder, Vector3.new(0.14, 0.52, 0.52), rose, CAN_DARK)

	-- Handle loop on the back.
	canPart(can, Enum.PartType.Block, Vector3.new(0.14, 0.14, 0.5), CFrame.new(0, 0.42, 0.62), CAN_WOOD, Enum.Material.Wood)
	canPart(can, Enum.PartType.Block, Vector3.new(0.14, 0.7, 0.14), CFrame.new(0, 0.08, 0.86), CAN_WOOD, Enum.Material.Wood)
	canPart(can, Enum.PartType.Block, Vector3.new(0.14, 0.14, 0.5), CFrame.new(0, -0.26, 0.62), CAN_WOOD, Enum.Material.Wood)

	-- Where the water leaves (the rose), facing along the spout.
	local nozzle = Instance.new("Attachment")
	nozzle.Name = "Nozzle"
	nozzle.CFrame = CFrame.lookAt((tip + dir * 0.12) * CAN_SCALE, (tip + dir * 0.12) * CAN_SCALE + dir)
	nozzle.Parent = root

	for _, descendant in can:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = descendant
			weld.Parent = root
		end
	end
	can.PrimaryPart = root
	return can, root, nozzle
end

-- Takes the can out, pours for `seconds`, puts it away. Everything is time-boxed and cleans up after itself.
local function pourFromCan(bed: BasePart, seconds: number)
	local char = player.Character
	if not char then return end
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end
	local grip = hand:FindFirstChild("RightGripAttachment")
	local gripCFrame = if grip and grip:IsA("Attachment") then grip.CFrame else CFrame.new(0, -0.15, 0)

	local can, body, nozzle = buildCan()
	local weld = Instance.new("Weld")
	weld.Name = "CanGrip"
	weld.Part0 = hand
	local base = gripCFrame -- the grip attachment already carries the Tool orientation: the can's front (-Z, the spout) points forward
	weld.C0 = base
	weld.C1 = CFrame.new(HANDLE_AT)
	weld.Part1 = body
	weld.Parent = body
	can.Parent = char

	-- Tilt forward to pour, hold, then back.
	local tilt = Instance.new("NumberValue")
	tilt.Value = 0
	local connection = tilt.Changed:Connect(function(angle)
		weld.C0 = base * CFrame.Angles(angle, 0, 0)
	end)
	TweenService:Create(tilt, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = -math.rad(42) }):Play()

	-- The stream: droplets leave the rose and arc down onto the bed.
	local stream = Instance.new("ParticleEmitter")
	stream.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	stream.Color = ColorSequence.new(Color3.fromRGB(190, 232, 255), Color3.fromRGB(80, 160, 235))
	stream.LightEmission = 0.6
	stream.Lifetime = NumberRange.new(0.5, 0.75)
	stream.Speed = NumberRange.new(5, 8)
	stream.SpreadAngle = Vector2.new(7, 7)
	stream.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.32), NumberSequenceKeypoint.new(1, 0.12) })
	stream.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.7) })
	stream.Acceleration = Vector3.new(0, -34, 0)
	stream.EmissionDirection = Enum.NormalId.Front
	stream.Rate = 0
	stream.Parent = nozzle

	task.delay(0.35, function()
		stream.Rate = 70
	end)
	-- Splash on the bed while the water lands.
	task.delay(0.6, function()
		Vfx.burst("water", bedTop(bed, 0.9))
	end)
	task.delay(seconds - 0.15, function()
		stream.Rate = 0
		TweenService:Create(tilt, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 0 }):Play()
	end)
	task.delay(seconds + 0.45, function()
		connection:Disconnect()
		tilt:Destroy()
		can:Destroy()
	end)
end

-- Public --------------------------------------------------------------------------------------------

-- Seed goes into the bed: dig animation, soil puff and fresh green sparks AT THE BED.
function FarmFx.plant(bed: BasePart)
	faceBed(bed)
	playClip("plant")
	task.delay(0.35, function()
		Sfx.play("plant_seed", bed)
		Vfx.burst("plant", bedTop(bed, 0.6))
	end)
end

-- Watering: the character takes out a watering can, pours onto the bed, water falls and splashes there.
-- `silent` (a drag stroke after its first bed): the animation plays, the sound does not (one sound per action).
function FarmFx.water(bed: BasePart, silent: boolean?)
	faceBed(bed)
	playClip("water")
	pourFromCan(bed, 1.7)
	if silent then return end
	task.delay(0.55, function()
		Sfx.play("water_pour", bed, SOUND_JITTER)
	end)
end

-- Harvest: a sparkle where the crop was; the pluck sound is one per action (`silent` for the rest of a batch).
function FarmFx.harvest(bed: BasePart, silent: boolean?)
	faceBed(bed)
	Vfx.burst("harvest", bedTop(bed, 2))
	if silent then return end
	Sfx.play("farm_harvest", bed, SOUND_JITTER)
end

-- Kerja Bakti: the character bends and picks up a piece of trash (reuses the plant dig clip; K-117, no new animation).
function FarmFx.pickUp(piece: BasePart)
	faceBed(piece)
	playClip("plant")
	Sfx.play("farm_harvest", piece, SOUND_JITTER)
end

-- Garap: turning grass into a bed (deep dig) or back into grass (soft dig).
function FarmFx.till(back)
	local root = myRoot()
	local sound = Sfx.play("plant_seed", root)
	if sound then sound.PlaybackSpeed = if back then 1.1 else 0.75 end
end

return FarmFx
