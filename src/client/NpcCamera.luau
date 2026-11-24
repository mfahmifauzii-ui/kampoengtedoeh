--!strict
-- The conversation camera, used by EVERY talk with an NPC (the "Ngobrol" dialogue, the intro, the T1b beats): an over-the-
-- shoulder shot. The camera sits just behind the player's right shoulder, so the player is only a blurred sliver at the bottom
-- left of the frame, and it is aimed at the NPC's face, which sits right of centre and above the dialogue box. A depth-of-field
-- blur (the near player and the far background) keeps the eye on the NPC. Client only.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local NpcCamera = {}

NpcCamera.FOV = 34
NpcCamera.WIDE_FOV = 60 -- the Jual Pertama wide shot (Bab 16.4): wide enough for the stall and the buildings

local BACK = 2.4 -- studs behind the player's head
local SIDE = 2.4 -- studs to the player's right: the player ends up at the left of the frame
local RISE = 1.7 -- studs above the player's head: a slight look down, the player's head falls to the bottom edge
local DROP = -0.7 -- the aim point sits this far below the NPC's head: the face rides high in the frame, above the dialogue box
local SHIFT = 0.35 -- the aim point sits this far to the player's left of the NPC: the NPC lands right of centre

local BLUR_NAME = "NpcTalkBlur"
local BLUR_NEAR, BLUR_FAR, BLUR_RADIUS = 0.9, 0.5, 4
local BLUR_SECONDS = 0.5

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- The shot for a player standing near an NPC: its CFrame, and the distance from the camera to the NPC's face (the blur's focus).
-- `ignore` are things the camera must not mind (the NPC itself, the player's character).
function NpcCamera.Shot(npcHead: Vector3, character: Model?, ignore: { Instance }?): (CFrame, number)
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local from = if head and head:IsA("BasePart")
		then head.Position
		elseif root and root:IsA("BasePart") then root.Position + Vector3.new(0, 1.5, 0)
		else npcHead - Vector3.new(0, 0, 6)
	local toNpc = flat(npcHead - from)
	local dir = if toNpc.Magnitude > 0.1 then toNpc.Unit else Vector3.new(0, 0, -1)
	local right = dir:Cross(Vector3.yAxis)

	local eye = from - dir * BACK + right * SIDE + Vector3.new(0, RISE, 0)
	-- A wall or a fence behind the player: pull the camera in so it never films the inside of one.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local filter: { Instance } = {}
	if character then
		table.insert(filter, character)
	end
	if ignore then
		for _, item in ignore do
			table.insert(filter, item)
		end
	end
	params.FilterDescendantsInstances = filter
	local hit = Workspace:Raycast(from, eye - from, params)
	if hit then
		eye = from + (eye - from).Unit * math.max(hit.Distance - 0.4, 0.5)
	end

	local aim = npcHead + Vector3.new(0, DROP, 0) - right * SHIFT
	return CFrame.lookAt(eye, aim), (eye - npcHead).Magnitude
end

-- The wide shot of the Jual Pertama beat (Bab 16.4): a fixed camera at `eye`, aimed at `focus`, so the NPC, his stall and the
-- buildings around read. Pulled in when a wall or prop lies between it and the focus. `ignore` = the NPC and the player.
-- shortcut: one ray from the focus, no clearance margin for near-wall props; upgrade if Play shows clipping at the tree.
function NpcCamera.Wide(eye: Vector3, focus: Vector3, ignore: { Instance }): CFrame
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	params.FilterDescendantsInstances = ignore
	local pos = eye
	local hit = Workspace:Raycast(focus, eye - focus, params)
	if hit then
		pos = focus + (eye - focus).Unit * math.max(hit.Distance - 0.6, 0.5)
	end
	return CFrame.lookAt(pos, focus)
end

-- The depth-of-field blur: on = the NPC (at focusDistance) is sharp, the player in front and the background behind are blurred.
function NpcCamera.SetBlur(on: boolean, focusDistance: number?)
	local effect = Lighting:FindFirstChild(BLUR_NAME)
	if not effect then
		if not on then
			return
		end
		local created = Instance.new("DepthOfFieldEffect")
		created.Name = BLUR_NAME
		created.NearIntensity = 0
		created.FarIntensity = 0
		created.InFocusRadius = BLUR_RADIUS
		created.FocusDistance = focusDistance or 8
		created.Enabled = true
		created.Parent = Lighting
		effect = created
	end
	local dof = effect :: DepthOfFieldEffect
	if on then
		dof.Enabled = true
		TweenService:Create(dof, TweenInfo.new(BLUR_SECONDS), {
			NearIntensity = BLUR_NEAR,
			FarIntensity = BLUR_FAR,
			InFocusRadius = BLUR_RADIUS,
			FocusDistance = focusDistance or dof.FocusDistance,
		}):Play()
	else
		local tween = TweenService:Create(dof, TweenInfo.new(BLUR_SECONDS), { NearIntensity = 0, FarIntensity = 0 })
		tween.Completed:Once(function()
			if dof.Parent and dof.NearIntensity < 0.01 then
				dof.Enabled = false
			end
		end)
		tween:Play()
	end
end

return NpcCamera
