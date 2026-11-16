--!strict
-- A relaxed, alive pose for the town NPC rigs (client only: it changes the local copies of the rigs, never the server).
--
-- Why this exists: the stock R15 idle animation does not fit these rigs' joints (AnimationConstraints). It leaves the arms open
-- in a stiff T / A shape and, on some rigs, bends the knees. So the stock animation is stopped on the client, the two attachments
-- of every joint are aligned (the rig's canonical rest pose: standing straight), and an idle pose is driven from here: arms hanging
-- a little away from the body with a soft elbow bend, plus a slow breath and sway so nobody stands like a statue.
-- In that pose every joint turns about X (forward / back) or Z (in / out).

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local NpcPose = {}

export type Joints = { [string]: AnimationConstraint }

local ARM_IN = 30 -- degrees each shoulder is turned in from the rest pose: the arms hang near the body
local ELBOW = 14 -- degrees of elbow bend at rest
local MANAGE_DISTANCE = 140 -- studs from the camera: farther rigs are left alone (nobody sees them)

local managed: { [Model]: { joints: Joints, animators: { Animator }, offset: number } } = {}

-- Stops every animation track playing on the rig (the stock idle) and aligns the joints. Returns the joints by name.
function NpcPose.Prepare(model: Model): Joints
	for _, d in model:GetDescendants() do
		if d:IsA("Animator") then
			for _, track in d:GetPlayingAnimationTracks() do
				track:Stop(0)
			end
		end
	end
	local joints: Joints = {}
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationConstraint") and d.Attachment0 and d.Attachment1 then
			d.Attachment0.CFrame = CFrame.new(d.Attachment0.CFrame.Position) * d.Attachment1.CFrame.Rotation
			d.Transform = CFrame.new()
			joints[d.Name] = d
		end
	end
	return joints
end

local function set(joints: Joints, name: string, x: number, y: number, z: number)
	local joint = joints[name]
	if joint then
		joint.Transform = CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
	end
end

-- The relaxed standing pose at time t (seconds): arms near the body, a soft elbow, a slow breath and a slight sway.
function NpcPose.Idle(joints: Joints, t: number)
	local breathe = math.sin(t * 1.5)
	local sway = math.sin(t * 0.6)
	set(joints, "RightShoulder", 2.5 * sway, 0, -ARM_IN + 1.2 * breathe)
	set(joints, "LeftShoulder", -2.5 * sway, 0, ARM_IN - 1.2 * breathe)
	set(joints, "RightElbow", ELBOW + 2 * breathe, 0, 0)
	set(joints, "LeftElbow", ELBOW - 2 * breathe, 0, 0)
	set(joints, "RightWrist", 4, 0, 0)
	set(joints, "LeftWrist", 4, 0, 0)
	set(joints, "Waist", 0.8 * breathe, 1.2 * sway, 0)
	set(joints, "Neck", 0.6 * sway, 1.5 * sway, 0)
end

-- One frame of a walk on top of the relaxed arms: hips swing, the knee of the forward leg bends, the arms swing against the legs.
function NpcPose.Gait(joints: Joints, phase: number, hip: number, knee: number, arm: number)
	local s, c = math.sin(phase), math.cos(phase)
	set(joints, "RightHip", hip * s, 0, 0)
	set(joints, "LeftHip", -hip * s, 0, 0)
	set(joints, "RightKnee", -knee * math.max(0, c), 0, 0) -- a knee bends backward: negative X on these rigs
	set(joints, "LeftKnee", -knee * math.max(0, -c), 0, 0)
	set(joints, "RightShoulder", -arm * s, 0, -ARM_IN)
	set(joints, "LeftShoulder", arm * s, 0, ARM_IN)
	set(joints, "RightElbow", ELBOW + 4, 0, 0)
	set(joints, "LeftElbow", ELBOW + 4, 0, 0)
	set(joints, "Waist", 0, -2 * s, 0)
end

-- Straight legs again (after a walk).
function NpcPose.StandStraight(joints: Joints)
	for _, name in { "RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle" } do
		set(joints, name, 0, 0, 0)
	end
end

-- Keeps a rig in the relaxed idle for as long as it exists (used for the town NPCs).
function NpcPose.Manage(model: Model)
	if managed[model] then
		return
	end
	local animators: { Animator } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Animator") then
			table.insert(animators, d)
		end
	end
	managed[model] = { joints = NpcPose.Prepare(model), animators = animators, offset = math.random() * 20 }
	model.Destroying:Once(function()
		managed[model] = nil
	end)
end

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local now = os.clock()
	for model, rig in managed do
		local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - camera.CFrame.Position).Magnitude < MANAGE_DISTANCE then
			-- The server may restart the stock idle at any time: stop it again if it did.
			for _, animator in rig.animators do
				for _, track in animator:GetPlayingAnimationTracks() do
					track:Stop(0)
				end
			end
			NpcPose.Idle(rig.joints, now + rig.offset)
		end
	end
end)

return NpcPose
