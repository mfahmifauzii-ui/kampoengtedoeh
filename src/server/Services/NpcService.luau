--!strict
-- Town NPCs (Config/Npcs): placeholder R15 shopkeepers standing on the bridge. Each has ONE prompt, "Ngobrol";
-- pressing it tells that player's client to open the dialogue (Net "NpcTalk"). Trading itself is in ShopService.
-- Replace the rigs with your designed NPCs: keep them anchored, named <npcId>, in Workspace.Npcs,
-- with a ProximityPrompt "TalkPrompt" on their root part.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Map = require(ReplicatedStorage.Shared.Config.Map)
local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local MapService = require(script.Parent.MapService)

local NpcService = {}

local models: { [string]: Model } = {}
local folder: Folder

-- World position of an NPC (nil until its rig exists).
function NpcService.Position(npcId: string): Vector3?
	local model = models[npcId]
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function build(npc: Npcs.Npc)
	local ok, rig = pcall(function()
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
	model:SetAttribute("NpcId", npc.id)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	-- The rig looks toward -Z; turn it toward +Z when the NPC should face that way.
	local yaw = if npc.stand.faceZ > 0 then math.pi else 0
	model:PivotTo(MapService.BridgeCFrame(npc.stand.x, Map.BRIDGE.DECK_Y + 3, npc.stand.z) * CFrame.Angles(0, yaw, 0))
	model.Parent = folder

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
		label.Font = Enum.Font.GothamMedium
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
		Net.Fire("NpcTalk", player, npc.id)
	end)
end

function NpcService.Start()
	folder = Instance.new("Folder")
	folder.Name = "Npcs"
	folder.Parent = Workspace
	for _, npc in Npcs.list do
		task.spawn(build, npc) -- creating a rig yields
	end
end

return NpcService
