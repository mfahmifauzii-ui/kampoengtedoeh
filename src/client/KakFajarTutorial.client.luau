--!strict
-- Kak Fajar tutorial, CLIENT ONLY (Update owner 2026-11-22, Task 1). Only for this player.
--   * While the tutorial step is "jual_ikan" (T1b, the sale of the first fish), a local copy of Kak Fajar stands on the
--     bank of the river spot that the server assigned to this player (attribute "RiverSpot", FishService.AssignedRiverSpot).
--   * The server Kak Fajar (Workspace.Npcs.kak_fajar, at the shop) is hidden FOR THIS PLAYER ONLY while the copy exists:
--     LocalTransparencyModifier on his parts and his talk prompt off. Other players still see him.
--   * The copy is found by T1Dialog.NpcModel("kak_fajar"), so the tutorial dialog and the walk-up sale beat use it.
--   * The copy is built on the client: from ReplicatedStorage.NpcTutorial.kak_fajar when a designed rig is there, else
--     from the NPC's colours (Config/Npcs), the same way the server builds a plain NPC.
--   * The sale itself is still checked on the server (ShopService: step jual_ikan + distance to the assigned spot).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local NpcPose = require(script.Parent.NpcPose)
local State = require(script.Parent.State)

local player = Players.LocalPlayer

local NPC_ID = "kak_fajar"
local COPY_NAME = "KakFajar_Tutorial_Local" -- T1Dialog.NpcModel looks this name up for "kak_fajar"
local STAND_OFFSET = 3 -- studs from the spot onto the bank (away from the water)
local IDLE_ANIMATION = "rbxassetid://507766666" -- same idle as NpcService (town NPCs)
local CHECK_SECONDS = 0.25

local copy: Model? = nil



-- Steps of the fishing segment that Kak Fajar is part of (Update owner playtest, item 3): from the step right after the Pak Udin
-- sale (receiving the rod) through the fish sale. The copy exists for the WHOLE segment.
local FAJAR_STEPS = { kak_fajar = true, mancing = true, jual_ikan = true }

-- True while the tutorial is on one of those steps (from the guide snapshot).
local function fishSaleStepLive(): boolean
	local snapshot = State.current :: any
	local guide = snapshot and snapshot.guide
	if not guide or not guide.step or guide.step.id == "" then
		return false
	end
	for _, tutorial in Onboarding.TUTORIALS do
		if tutorial.id == guide.step.id then
			local def = tutorial.steps[guide.step.n + 1]
			return def ~= nil and FAJAR_STEPS[def.id] == true
		end
	end
	return false
end

-- The river spot the server gave this player (nil until the plot and the spots exist).
local function assignedSpot(): BasePart?
	local name = player:GetAttribute("RiverSpot")
	local fishing = Workspace:FindFirstChild("Fishing")
	if typeof(name) ~= "string" or not fishing then
		return nil
	end
	local spot = fishing:FindFirstChild(name)
	return if spot and spot:IsA("BasePart") then spot else nil
end

-- Ground height under a point (a ray from high above; falls back to the spot's own height). Water is ignored (the
-- river is not the floor), and so are the player's character and the copy itself.
local function groundY(x: number, z: number, refY: number, ownRig: Model?): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	if ownRig then
		table.insert(ignore, ownRig)
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(Vector3.new(x, refY + 40, z), Vector3.new(0, -80, 0), params)
	return if hit then hit.Position.Y else refY
end

-- The copy's rig: a designed one from ReplicatedStorage.NpcTutorial, else a colour-only rig like the server's.
local function buildCopy(): Model?
	local tutorialFolder = ReplicatedStorage:FindFirstChild("NpcTutorial")
	local designed = tutorialFolder and tutorialFolder:FindFirstChild(NPC_ID)
	local model: Model? = nil
	if designed and designed:IsA("Model") then
		model = designed:Clone()
	else
		warn("[KakFajarTutorial] ReplicatedStorage.NpcTutorial.kak_fajar tidak ada: salinan memakai rig warna (fallback)")
		local npc = Npcs.byId[NPC_ID]
		if not npc then
			return nil
		end
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = npc.look.skin
		description.TorsoColor = npc.look.shirt
		description.LeftArmColor = npc.look.shirt
		description.RightArmColor = npc.look.shirt
		description.LeftLegColor = npc.look.pants
		description.RightLegColor = npc.look.pants
		local ok, built = pcall(function()
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)
		if not ok or not built then
			return nil
		end
		model = built
	end
	local rig = model :: Model
	rig.Name = COPY_NAME
	local root = rig:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		rig:Destroy()
		return nil
	end
	rig.PrimaryPart = root
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	rig.Parent = Workspace
	return rig
end

-- The same relaxed idle the town NPCs get (NpcService IDLE_ANIMATION), so the copy is never in a T-pose.
local function startIdle(rig: Model)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local idle = Instance.new("Animation")
	idle.AnimationId = IDLE_ANIMATION
	local ok, track = pcall(function()
		return animator:LoadAnimation(idle)
	end)
	if ok and track then
		track.Looped = true
		track:Play()
	end
end

-- Stand on the bank of the spot, facing back toward the bank side (the spot's "Dir" attribute points out over the water).
-- The rig is set on the ground like a player: the ray hits the floor under the bank, and the rig is lowered until its lowest
-- point (the feet, whatever the rig's height or HipHeight) sits on that hit point. The root is then anchored, so it stays put.
-- Playtest 7 (4f3500f) item 1: the bank is found in the world, not assumed. Walking from the spot toward land, the first ray
-- hit that is land (not water, not under the surface) is the bank edge. Water is NOT ignored here.
local BANK_SEARCH = 40 -- studs from the spot toward land
local BANK_STAND = 2 -- studs onto land past the edge where the copy stands
local bankChecked = false

local function isWater(hit: RaycastResult): boolean
	return hit.Material == Enum.Material.Water or string.find(string.lower(hit.Instance.Name), "water") ~= nil
end

-- The bank edge along `landDir` from `spot` (flat), or nil when no land is found within BANK_SEARCH.
local function findBank(spot: BasePart, landDir: Vector3, ownRig: Model?): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = false
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	if ownRig then
		table.insert(ignore, ownRig)
	end
	params.FilterDescendantsInstances = ignore
	local surfaceY = spot.Position.Y
	for step = 1, BANK_SEARCH do
		local p = spot.Position + landDir * step
		local hit = Workspace:Raycast(Vector3.new(p.X, surfaceY + 40, p.Z), Vector3.new(0, -80, 0), params)
		if hit and not isWater(hit) and hit.Position.Y >= surfaceY - 0.5 then
			return hit.Position
		end
	end
	return nil
end

-- Logs (does not move) river spots that have no bank within reach on this map. Runs once.
local function checkSpots(landDir: Vector3)
	if bankChecked then
		return
	end
	bankChecked = true
	local fishing = Workspace:FindFirstChild("Fishing")
	if not fishing then
		return
	end
	for _, spot in fishing:GetChildren() do
		if spot:IsA("BasePart") and findBank(spot, landDir, nil) == nil then
			warn(`[KakFajarTutorial] river spot {spot.Name} has no bank within {BANK_SEARCH} studs (check the map)`)
		end
	end
end

local function placeCopy(rig: Model, spot: BasePart)
	local dir = spot:GetAttribute("Dir")
	local outward = if typeof(dir) == "Vector3" then Vector3.new(dir.X, 0, dir.Z) else Vector3.new(0, 0, 1)
	if outward.Magnitude < 1e-3 then
		outward = Vector3.new(0, 0, 1)
	end
	outward = outward.Unit
	local landDir = -outward -- from the water toward the bank
	checkSpots(landDir)
	local stand: Vector3
	local edge = findBank(spot, landDir, rig)
	if edge then
		local along = Vector3.new(edge.X - spot.Position.X, 0, edge.Z - spot.Position.Z).Magnitude
		stand = spot.Position + landDir * (along + BANK_STAND)
	else
		warn(`[KakFajarTutorial] no bank found from river spot {spot.Name}: falling back to the fixed offset`)
		stand = spot.Position - outward * STAND_OFFSET
	end
	local at = Vector3.new(stand.X, spot.Position.Y, stand.Z)
	rig:PivotTo(CFrame.lookAt(at, at + outward)) -- faces the water, so the player coming from the bank sees his face
	local floorY = groundY(stand.X, stand.Z, spot.Position.Y, rig)
	local boxCFrame, boxSize = rig:GetBoundingBox()
	local feetY = boxCFrame.Position.Y - boxSize.Y / 2
	rig:PivotTo(rig:GetPivot() + Vector3.new(0, floorY - feetY, 0))
	local root = rig:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = true
	end
end

-- Hiding the server Kak Fajar FOR THIS PLAYER (playtest item 5): every part and decal is made invisible locally, the name
-- tags (BillboardGui / SurfaceGui) and prompts are off, and the parts stop colliding, touching and being queried. The
-- original values are remembered and put back exactly. Re-applied on every check, so a streamed-in or rebuilt rig is hidden too.
local saved: { [Instance]: { [string]: any } } = {}

local function remember(inst: Instance, prop: string, value: any)
	local props = saved[inst]
	if not props then
		props = {}
		saved[inst] = props
	end
	if props[prop] == nil then
		props[prop] = value
	end
end

local function hideOne(inst: Instance)
	if inst:IsA("BasePart") then
		remember(inst, "LocalTransparencyModifier", inst.LocalTransparencyModifier)
		remember(inst, "CanCollide", inst.CanCollide)
		remember(inst, "CanTouch", inst.CanTouch)
		remember(inst, "CanQuery", inst.CanQuery)
		inst.LocalTransparencyModifier = 1
		inst.CanCollide = false
		inst.CanTouch = false
		inst.CanQuery = false
	elseif inst:IsA("Decal") or inst:IsA("Texture") then
		remember(inst, "Transparency", inst.Transparency)
		inst.Transparency = 1
	elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") or inst:IsA("ProximityPrompt") then
		remember(inst, "Enabled", inst.Enabled)
		inst.Enabled = false
	end
end

local function hideRig(rig: Model)
	for _, descendant in rig:GetDescendants() do
		if saved[descendant] == nil then
			hideOne(descendant)
		end
	end
end

local function restoreAll()
	for inst, props in saved do
		for prop, value in props do
			pcall(function()
				(inst :: any)[prop] = value
			end)
		end
	end
	table.clear(saved)
end

local function hideServerFajar(hide: boolean)
	if not hide then
		restoreAll()
		return
	end
	local npcs = Workspace:FindFirstChild("Npcs")
	local serverRig = npcs and npcs:FindFirstChild(NPC_ID)
	if serverRig and serverRig:IsA("Model") then
		hideRig(serverRig)
	end
end

local function sync()
	local spot = assignedSpot()
	local wanted = fishSaleStepLive() and spot ~= nil
	if not wanted then
		if copy then
			copy:Destroy()
			copy = nil
		end
		hideServerFajar(false)
		return
	end
	if not copy then
		copy = buildCopy()
		if copy and spot then
			NpcPose.Manage(copy) -- relaxed pose, as on the town NPCs (client only)
			startIdle(copy)
			placeCopy(copy, spot)
		end
	end
	hideServerFajar(copy ~= nil)
end

task.spawn(function()
	while true do
		local ok, err = pcall(sync)
		if not ok then
			warn(`[KakFajarTutorial] {err}`)
		end
		task.wait(CHECK_SECONDS)
	end
end)

