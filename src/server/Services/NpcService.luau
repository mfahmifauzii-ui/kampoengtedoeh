--!strict
-- Town NPCs (Config/Npcs). Rigs hand-placed in Workspace.Npcs (named <npcId>) are used as they are; missing ones are built. Each has ONE prompt, "Ngobrol";
-- pressing it tells that player's client to open the dialogue (Net "NpcTalk"). Trading itself is in ShopService.
-- Replace the rigs with your designed NPCs: keep them anchored, named <npcId>, in Workspace.Npcs,
-- with a ProximityPrompt "TalkPrompt" on their root part.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Map = require(ReplicatedStorage.Shared.Config.Map)
local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local MapService = require(script.Parent.MapService)
local TutorialService = require(script.Parent.TutorialService)

local NpcService = {}

local IDLE_ANIMATION = "rbxassetid://507766666" -- Roblox R15 idle (breathing, small arm sway)

local models: { [string]: Model } = {}
local folder: Folder

-- World position of an NPC (nil until its rig exists).
function NpcService.Position(npcId: string): Vector3?
	local model = models[npcId]
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- Hand-placed rigs: if Workspace.Npcs already holds a model named after this NPC (edited by hand in Studio), use it and
-- only make sure it has its talk prompt. The rig is then never moved or replaced by the server.
local function adopt(npc: Npcs.Npc): boolean
	local existing = folder:FindFirstChild(npc.id)
	if not existing or not existing:IsA("Model") then
		return false
	end
	local root = existing:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		warn(`[NpcService] {npc.id} has no HumanoidRootPart; it will not talk`)
		return true
	end
	existing.PrimaryPart = root
	existing.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- see build(): always replicated, streaming radius or not
	models[npc.id] = existing
	for _, descendant in existing:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
	if not root:FindFirstChild("TalkPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ActionText = Locale.t("prompt.talk")
		prompt.ObjectText = Locale.t(`npc.{npc.id}`)
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = Npcs.TALK_DISTANCE
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Parent = root
		prompt.Triggered:Connect(function(player: Player)
			if TutorialService.NpcBlocked(player, npc.id) then
				Net.Fire("Notify", player, "npc.tut_block") -- Bab 16.3: "Selesaikan tutorial dulu", no dialog
				return
			end
			Net.Fire("NpcTalk", player, npc.id)
		end)
	end
	return true
end

-- Where Bang Jali of the n-th "Warung Mini" stands: in front of the stall (Npcs.MINI_SIDE_OFFSET / MINI_FRONT_OFFSET), on the
-- ground, with his BACK to the stall (same yaw as the stall, no extra turn: he looks out toward the player, the counter is
-- behind him). Stalls are sorted by position so the numbering is stable.
local function miniStand(index: number): CFrame?
	local stalls: { Model } = {}
	for _, child in Workspace:GetChildren() do
		if child:IsA("Model") and child.Name == Npcs.MINI_STALL_NAME then
			table.insert(stalls, child)
		end
	end
	table.sort(stalls, function(a, b)
		local pa, pb = a:GetPivot().Position, b:GetPivot().Position
		return if pa.X ~= pb.X then pa.X < pb.X else pa.Z < pb.Z
	end)
	local stall = stalls[index]
	if not stall then
		return nil
	end
	local pivot = stall:GetPivot()
	local spot = pivot * CFrame.new(Npcs.MINI_SIDE_OFFSET, 0, Npcs.MINI_FRONT_OFFSET)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	local hit = Workspace:Raycast(spot.Position + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), params)
	local groundY = if hit then hit.Position.Y else pivot.Position.Y - 9
	return CFrame.new(spot.X, groundY + 3, spot.Z) * (pivot - pivot.Position) -- keeps the stall's yaw: his back is to the stall
end

local function build(npc: Npcs.Npc)
	if adopt(npc) then
		return
	end
	local miniCFrame = if npc.miniIndex then miniStand(npc.miniIndex) else nil
	if npc.miniIndex and not miniCFrame then
		return -- no stall number miniIndex in the world
	end
	local usedTemplate = false
	local ok, rig = pcall(function()
		-- A designed rig (ServerStorage.NpcModels.<model or id>: Indonesian clothes, face, hair) when one exists.
		local templates = ServerStorage:FindFirstChild("NpcModels")
		local template = templates and templates:FindFirstChild(npc.model or npc.id)
		if template and template:IsA("Model") then
			usedTemplate = true
			return template:Clone()
		end
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = npc.look.skin
		description.TorsoColor = npc.look.shirt
		description.LeftArmColor = npc.look.shirt
		description.RightArmColor = npc.look.shirt
		description.LeftLegColor = npc.look.pants
		description.RightLegColor = npc.look.pants
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or typeof(rig) ~= "Instance" then
		warn(`[NpcService] Could not create NPC {npc.id}: {rig}`)
		return
	end
	local model = rig :: Model
	model.Name = npc.id
	-- Persistent: the NPC is always replicated to every client, whatever the player's streaming radius. Without it the
	-- T1 intro (T1Ghost copies this model) finds no NPC far from the shop and skips the cutscene, and the NPC is missing.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model:SetAttribute("NpcId", npc.id)
	-- Only the root is anchored: the limbs stay free so the idle animation can move them (they hang on the Motor6Ds).
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = descendant.Name == "HumanoidRootPart"
			descendant.CanCollide = false
			descendant.CanQuery = descendant.Name == "HumanoidRootPart" or descendant.CanQuery
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		-- A gentle idle loop so the town does not look like a wax museum.
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local idle = Instance.new("Animation")
		idle.AnimationId = IDLE_ANIMATION
		local okTrack, track = pcall(function()
			return animator:LoadAnimation(idle)
		end)
		if okTrack and track then
			track.Looped = true
			track:Play()
		end
	end

	-- The rig looks toward its local -Z; stand.yaw turns it to face the way it should (Config/Npcs).
	model:PivotTo(miniCFrame or (MapService.TownCFrame(npc.stand.x, npc.stand.y or (Map.TOWN.GROUND_Y + 3), npc.stand.z) * CFrame.Angles(0, npc.stand.yaw, 0)))
	model.Parent = folder
	if usedTemplate and npc.stand.y == nil then
		-- Designed rigs differ in height: stand them on whatever floor is under them (stall floor, road, grass).
		-- An explicit stand.y is a hand-placed spot (Pak Udin behind the warung roof): the raycast would land on the roof beams.
		local boxCFrame, boxSize = model:GetBoundingBox()
		local bottom = boxCFrame.Position.Y - boxSize.Y / 2
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { folder }
		local hit = Workspace:Raycast(Vector3.new(boxCFrame.Position.X, bottom + 6, boxCFrame.Position.Z), Vector3.new(0, -40, 0), params)
		if hit then
			model:PivotTo(model:GetPivot() + Vector3.new(0, hit.Position.Y - bottom, 0))
		end
	end

	local root = model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	model.PrimaryPart = root
	models[npc.id] = model

	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(220, 36)
		billboard.StudsOffset = Vector3.new(0, 2.6, 0)
		billboard.MaxDistance = 70
		billboard.Parent = head
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(245, 236, 214)
		label.TextStrokeTransparency = 0.6
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 18
		label.Text = Locale.t(`npc.{npc.id}`)
		label.Parent = billboard
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = Locale.t("prompt.talk")
	prompt.ObjectText = Locale.t(`npc.{npc.id}`)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Npcs.TALK_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = root
	prompt.Triggered:Connect(function(player: Player)
		if TutorialService.NpcBlocked(player, npc.id) then
			Net.Fire("Notify", player, "npc.tut_block")
			return
		end
		Net.Fire("NpcTalk", player, npc.id)
	end)
end

-- Rig yang dipasang lewat Show() (Hide hanya menghapus ini; rig Studio dibiarkan).
local shownByUs: { [string]: boolean } = {}

-- Tampilkan NPC tersembunyi (Pedagang Pasar Malam, Tamu Event - Bab 13, P2-6).
-- build() memakai rig Studio bila ada, generik bila tidak; aman dipanggil ulang.
function NpcService.Show(npcId: string): boolean
	if models[npcId] then
		return true
	end
	for _, npc in Npcs.list do
		if npc.id == npcId then
			shownByUs[npcId] = true
			task.spawn(build, npc)
			return true
		end
	end
	return false
end

-- Sembunyikan NPC lagi. Hanya rig yang dipasang lewat Show() yang dihapus; rig Studio dibiarkan.
function NpcService.Hide(npcId: string)
	if not shownByUs[npcId] then
		return
	end
	shownByUs[npcId] = nil
	local model = models[npcId]
	models[npcId] = nil
	if model then
		model:Destroy()
	end
end

-- Bab 22.3 walk-up: an NPC walks to `target` at `speed` studs/s (Mak Sari: 50% of the player's speed, Npcs.WALK_SPEED).
-- Visual only: the rig stays anchored and is moved by CFrame, so there is no pathing and no physics, and it stops at the
-- target. A newer walk for the same NPC cancels the older one. Triggers come later: Mak Sari at MQ4/MQ7 (Fase 5), Pak Amran
-- to the Kanal in the FTUE 2:40 (Fase 3). Nothing calls it yet.
local walkToken: { [string]: number } = {}

function NpcService.WalkTo(npcId: string, target: Vector3, speed: number?): boolean
	local model = models[npcId]
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local token = (walkToken[npcId] or 0) + 1
	walkToken[npcId] = token
	local pace = speed or Npcs.WALK_SPEED
	task.spawn(function()
		local last = os.clock()
		while walkToken[npcId] == token and root.Parent do
			local now = os.clock()
			local dt = math.min(now - last, 0.1)
			last = now
			local pos = root.Position
			local flat = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
			local dist = flat.Magnitude
			if dist < 1 then
				break
			end
			local dir = flat.Unit
			local step = math.min(dist, pace * dt)
			local nextPos = Vector3.new(pos.X + dir.X * step, pos.Y, pos.Z + dir.Z * step)
			root.CFrame = CFrame.lookAt(nextPos, nextPos + dir)
			task.wait()
		end
	end)
	return true
end

-- D.1 (playtest): an NPC without its own rig gets the generic blocky R15 fallback. Say so once, with every id, so a
-- missing model in ServerStorage.NpcModels (or a rename in Studio) shows up in the output. No aliases: the model name must
-- match the NPC id (or Npcs.model). A hand-placed rig in Workspace.Npcs counts as present.
local function warnMissingModels()
	local templates = ServerStorage:FindFirstChild("NpcModels")
	local missing: { string } = {}
	for _, npc in Npcs.list do
		if npc.hidden then
			continue
		end
		local name = npc.model or npc.id
		local template = templates and templates:FindFirstChild(name)
		local placed = folder:FindFirstChild(npc.id)
		if not (template and template:IsA("Model")) and not placed then
			table.insert(missing, name)
		end
	end
	if #missing > 0 then
		warn(`[NpcService] {#missing} NPC tanpa model di ServerStorage.NpcModels (pakai rig generik): {table.concat(missing, ", ")}`)
	end
end

-- Model Kak Fajar tutorial (Update owner playtest, item 4): the SAME rig the shop NPC uses (ServerStorage.NpcModels.<model or id>)
-- is copied to ReplicatedStorage.NpcTutorial.<id> on server start, so the client can clone it for the river copy. Nothing to
-- set up by hand. Without a source model the client falls back to a colour rig and logs a warning.
local function publishTutorialModel(npcId: string)
	local npc = Npcs.byId[npcId]
	local templates = ServerStorage:FindFirstChild("NpcModels")
	local source = templates and templates:FindFirstChild(if npc and npc.model then npc.model else npcId)
	local folderTut = ReplicatedStorage:FindFirstChild("NpcTutorial")
	if not folderTut then
		folderTut = Instance.new("Folder")
		folderTut.Name = "NpcTutorial"
		folderTut.Parent = ReplicatedStorage
	end
	if source and source:IsA("Model") then
		local copy = source:Clone()
		copy.Name = npcId
		local old = folderTut:FindFirstChild(npcId)
		if old then
			old:Destroy()
		end
		copy.Parent = folderTut
	else
		warn(`[NpcService] ServerStorage.NpcModels.{npcId} not found: the tutorial copy of {npcId} will use the colour fallback`)
	end
end

function NpcService.Start()
	publishTutorialModel("kak_fajar")
	folder = Workspace:FindFirstChild("Npcs") :: Folder? or Instance.new("Folder")
	folder.Name = "Npcs"
	folder.Parent = Workspace
	warnMissingModels()
	for _, npc in Npcs.list do
		if npc.hidden then
			continue
		end
		task.spawn(build, npc) -- creating a rig yields
	end
end

return NpcService
