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
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Map = require(ReplicatedStorage.Shared.Config.Map)
local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local NpcPose = require(script.Parent.NpcPose)
local State = require(script.Parent.State)

local player = Players.LocalPlayer

local NPC_ID = "kak_fajar"
local COPY_NAME = "KakFajar_Tutorial_Local" -- T1Dialog.NpcModel looks this name up for "kak_fajar"
local IDLE_ANIMATION = "rbxassetid://507766666" -- same idle as NpcService (town NPCs)
local CHECK_SECONDS = 0.25

-- Ground rules (Playtest 8, item 1). A point is ground when a collidable, non-foliage part (or terrain) with a floor-like
-- normal is hit. Trees, bushes and characters are never ground. The bank is the first ground point that sits within
-- [water surface - BANK_BELOW, water surface + BANK_ABOVE]; higher hits (canopies, roofs) are not the bank.
local FLOOR_NORMAL_Y = 0.7 -- a floor is at most this steep (normal.Y)
local BANK_BELOW = 0.5 -- studs under the water surface still counted as bank
local BANK_ABOVE = 6 -- studs above the water surface still counted as bank
local BANK_SEARCH = 40 -- studs from the spot toward land (the usual bank)
local BANK_SEARCH_FAR = 200 -- studs along the same line, only when the near search finds no bank
local BANK_STAND = 2 -- studs onto land past the bank edge where the copy stands
local FIND_PASSES = 8 -- rays per point at most: a rejected hit is skipped and the ray is cast again below it
local FOLIAGE_WORDS = { "tree", "pohon", "beringin", "bush", "semak" }

local copy: Model? = nil
local failedSpot: BasePart? = nil -- a spot with no walkable stand point: not searched again (no per-frame raycasts)
local checkedSpots = false -- the Studio-only map check runs once


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

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function isWater(hit: RaycastResult): boolean
	return hit.Material == Enum.Material.Water or string.find(string.lower(hit.Instance.Name), "water") ~= nil
end

-- Foliage: any part inside a model named like a tree or bush (Roblox has no leaf material).
local function isFoliage(part: BasePart): boolean
	local node: Instance? = part
	while node and node ~= Workspace do
		local name = string.lower(node.Name)
		for _, word in FOLIAGE_WORDS do
			if string.find(name, word, 1, true) then
				return true
			end
		end
		node = node.Parent
	end
	return false
end

-- A character or NPC rig (any model with a Humanoid) holds the part.
local function isCharacter(part: BasePart): boolean
	local node: Instance? = part.Parent
	while node and node ~= Workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return true
		end
		node = node.Parent
	end
	return false
end

-- Walkable: terrain, or a collidable part that is not foliage and not a character, with a floor-like normal, not water.
local function isFloor(hit: RaycastResult): boolean
	if isWater(hit) or hit.Normal.Y < FLOOR_NORMAL_Y then
		return false
	end
	local part = hit.Instance
	if part:IsA("Terrain") then
		return true
	end
	return part:IsA("BasePart") and part.CanCollide and not isFoliage(part) and not isCharacter(part)
end

-- The first walkable point straight down from above (x, z), skipping whatever is not walkable (foliage, characters, the copy,
-- the player). Water is ignored, so the river bed can be hit: it is rejected by height in findBank / planStand.
local function groundHit(x: number, z: number, fromY: number, ownRig: Model?): Vector3?
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	if ownRig then
		table.insert(ignore, ownRig)
	end
	for _ = 1, FIND_PASSES do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true
		params.FilterDescendantsInstances = ignore
		local hit = Workspace:Raycast(Vector3.new(x, fromY + 80, z), Vector3.new(0, -200, 0), params)
		if not hit then
			return nil
		end
		if isFloor(hit) then
			return hit.Position
		end
		if hit.Instance:IsA("Terrain") then
			return nil -- terrain too steep to stand on: no ground here
		end
		table.insert(ignore, hit.Instance)
	end
	return nil
end

-- The water surface at the spot: the first water hit straight down. Map.RIVER.WATER_Y when no water is hit.
local function waterSurfaceY(spot: BasePart): number
	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local top = spot.Position + Vector3.new(0, 80, 0)
	for _ = 1, FIND_PASSES do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = false
		params.FilterDescendantsInstances = ignore
		local hit = Workspace:Raycast(top, Vector3.new(0, -200, 0), params)
		if not hit then
			break
		end
		if isWater(hit) then
			return hit.Position.Y
		end
		table.insert(ignore, hit.Instance)
	end
	return Map.RIVER.WATER_Y
end

-- Direction from the spot toward land: toward the player's own plot (the centre of their beds, the attribute "Owner" =
-- UserId). Without a bed yet: the opposite of the spot's "Dir" (which points out over the water).
local function landDirection(spot: BasePart): Vector3
	local dir = spot:GetAttribute("Dir")
	local outward = if typeof(dir) == "Vector3" then flat(dir) else Vector3.new(0, 0, 1)
	if outward.Magnitude < 1e-3 then
		outward = Vector3.new(0, 0, 1)
	end
	local fallback = -outward.Unit
	local sum = Vector3.zero
	local count = 0
	for _, inst in Workspace:GetDescendants() do
		if inst:IsA("BasePart") and inst:GetAttribute("Owner") == player.UserId then
			sum += inst.Position
			count += 1
		end
	end
	if count == 0 then
		return fallback
	end
	local toPlot = flat(sum / count - spot.Position)
	if toPlot.Magnitude < 1e-3 then
		return fallback
	end
	return toPlot.Unit
end

-- The bank edge: walking from the spot along landDir, the first walkable point inside the water band. Higher or lower
-- walkable points are not the bank and the walk goes on.
local function findBank(spot: BasePart, surfaceY: number, landDir: Vector3, reach: number): Vector3?
	for step = 1, reach do
		local p = spot.Position + landDir * step
		local ground = groundHit(p.X, p.Z, surfaceY, nil)
		if ground and ground.Y >= surfaceY - BANK_BELOW and ground.Y <= surfaceY + BANK_ABOVE then
			return ground
		end
	end
	return nil
end

-- Studio only, once: logs river spots with no bank within BANK_SEARCH studs. Each spot uses its own "Dir" as the land side.
-- It only logs; no spot is moved.
local function checkSpots()
	if checkedSpots or not RunService:IsStudio() then
		return
	end
	checkedSpots = true
	local fishing = Workspace:FindFirstChild("Fishing")
	if not fishing then
		return
	end
	for _, spot in fishing:GetChildren() do
		if spot:IsA("BasePart") then
			local dir = spot:GetAttribute("Dir")
			local landDir = if typeof(dir) == "Vector3" and flat(dir).Magnitude > 1e-3 then -flat(dir).Unit else Vector3.new(0, 0, -1)
			if findBank(spot, waterSurfaceY(spot), landDir, BANK_SEARCH) == nil then
				warn(`[KakFajarTutorial] river spot {spot.Name} has no bank within {BANK_SEARCH} studs (check the map)`)
			end
		end
	end
end

-- Where the copy stands (a walkable point on land, never in the air) and which way he faces (toward the water). Nil when
-- no walkable point exists on the line from the spot toward the plot.
local function planStand(spot: BasePart): (Vector3?, Vector3)
	local landDir = landDirection(spot)
	local outward = -landDir
	local surfaceY = waterSurfaceY(spot)
	local edge = findBank(spot, surfaceY, landDir, BANK_SEARCH)
	if not edge then
		edge = findBank(spot, surfaceY, landDir, BANK_SEARCH_FAR)
		if edge then
			warn(`[KakFajarTutorial] river spot {spot.Name}: bank found beyond {BANK_SEARCH} studs`)
		end
	end
	if not edge then
		return nil, outward
	end
	-- Two studs further onto land, if that point is walkable too; otherwise the edge itself (still a walkable point).
	local along = flat(edge - spot.Position).Magnitude
	local beyond = spot.Position + landDir * (along + BANK_STAND)
	local ground = groundHit(beyond.X, beyond.Z, surfaceY, nil)
	if ground and ground.Y >= surfaceY - BANK_BELOW and ground.Y <= surfaceY + BANK_ABOVE then
		return ground, outward
	end
	return edge, outward
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
			-- Only the root is anchored (as NpcService build()): the limbs must move on their joints (Motor6D / AnimationConstraint).
			descendant.Anchored = descendant == root
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

-- Sets the rig on the planned ground point, facing the water. The rig is lowered until its lowest point (the feet, whatever
-- the rig's height) sits on that point. The root is anchored, so it stays put.
local function placeCopy(rig: Model, ground: Vector3, outward: Vector3)
	rig:PivotTo(CFrame.lookAt(ground, ground + outward))
	local boxCFrame, boxSize = rig:GetBoundingBox()
	local feetY = boxCFrame.Position.Y - boxSize.Y / 2
	rig:PivotTo(rig:GetPivot() + Vector3.new(0, ground.Y - feetY, 0))
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
		failedSpot = nil
		hideServerFajar(false)
		return
	end
	if not copy and spot ~= failedSpot then
		-- The stand point is planned first (no copy in the world yet), then the rig is built and placed on it.
		local ground, outward = planStand(spot :: BasePart)
		if not ground then
			failedSpot = spot
			warn(`[KakFajarTutorial] river spot {(spot :: BasePart).Name}: no walkable point on the way to the plot; the copy is not placed`)
		else
			local rig = buildCopy()
			if rig then
				placeCopy(rig, ground, outward)
				copy = rig
				-- Playtest 7 item 2, after the rig is parented and placed. A designed rig has AnimationConstraint joints: NpcPose
				-- drives them (it stops every track each frame, so no idle track there). The Motor6D fallback rig has no
				-- AnimationConstraint: it gets the idle track only.
				if rig:FindFirstChildWhichIsA("AnimationConstraint", true) then
					NpcPose.Manage(rig)
				else
					startIdle(rig)
				end
			end
		end
	end
	checkSpots()
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
