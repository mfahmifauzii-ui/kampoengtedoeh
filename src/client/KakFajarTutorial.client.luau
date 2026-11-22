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
local State = require(script.Parent.State)

local player = Players.LocalPlayer

local NPC_ID = "kak_fajar"
local COPY_NAME = "KakFajar_Tutorial_Local" -- T1Dialog.NpcModel looks this name up for "kak_fajar"
local STAND_OFFSET = 3 -- studs from the spot onto the bank (away from the water)
local CHECK_SECONDS = 0.25

local copy: Model? = nil
local hiddenServerParts: { BasePart } = {}
local hiddenPrompt: ProximityPrompt? = nil

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

-- Ground height under a point (a ray from high above; falls back to the spot's own height).
local function groundY(x: number, z: number, refY: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { player.Character or Workspace }
	local copyModel = Workspace:FindFirstChild(COPY_NAME)
	if copyModel then
		table.insert(ignore, copyModel)
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

-- Stand on the bank of the spot, facing back toward the bank side (the spot's "Dir" attribute points out over the water).
local function placeCopy(rig: Model, spot: BasePart)
	local dir = spot:GetAttribute("Dir")
	local outward = if typeof(dir) == "Vector3" then Vector3.new(dir.X, 0, dir.Z) else Vector3.new(0, 0, 1)
	if outward.Magnitude < 1e-3 then
		outward = Vector3.new(0, 0, 1)
	end
	outward = outward.Unit
	local bank = spot.Position - outward * STAND_OFFSET
	local y = groundY(bank.X, bank.Z, spot.Position.Y) + 3
	local at = Vector3.new(bank.X, y, bank.Z)
	rig:PivotTo(CFrame.lookAt(at, at + outward)) -- faces the water, so the player coming from the bank sees his face
end

local function hideServerFajar(hide: boolean)
	if not hide then
		for _, part in hiddenServerParts do
			part.LocalTransparencyModifier = 0
		end
		table.clear(hiddenServerParts)
		if hiddenPrompt then
			hiddenPrompt.Enabled = true
			hiddenPrompt = nil
		end
		return
	end
	if #hiddenServerParts > 0 then
		return
	end
	local npcs = Workspace:FindFirstChild("Npcs")
	local serverRig = npcs and npcs:FindFirstChild(NPC_ID)
	if not serverRig or not serverRig:IsA("Model") then
		return
	end
	for _, descendant in serverRig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
			table.insert(hiddenServerParts, descendant)
		elseif descendant:IsA("ProximityPrompt") and descendant.Name == "TalkPrompt" then
			descendant.Enabled = false
			hiddenPrompt = descendant
		end
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

