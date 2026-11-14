--!strict
-- NPC dialogue (The Forge style): ONE button ("Ngobrol", a server-side ProximityPrompt) opens this box:
-- the NPC's name, role and greeting, and two choices: [Jual / Beli] opens the NPC's shop, [Sampai jumpa] closes.
--
-- UI CONTRACT (replace with your designed UI, keep the names):
--   ScreenGui "DialogueUI" > Frame "Box" > TextLabel "NpcName", TextLabel "Role", TextLabel "Line",
--   TextButton "TradeButton", TextButton "ByeButton".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local ShopController = require(script.Parent.ShopController)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local CHECK_SECONDS = 0.5

local player = Players.LocalPlayer

local DialogueController = {}

local gui: ScreenGui
local nameLabel: TextLabel
local roleLabel: TextLabel
local lineLabel: TextLabel
local currentNpc: string? = nil

local function label(parent: Instance, name: string, size: number, font: Enum.Font, position: UDim2, labelSize: UDim2): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.Position = position
	text.Size = labelSize
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.TextColor3 = UiKit.TEXT
	text.Font = font
	text.TextSize = size
	text.Parent = parent
	return text
end

local function close()
	currentNpc = nil
	gui.Enabled = false
end

-- Fills the box. Kedekatan is shown next to the role; friends (Akrab and up) get a warmer greeting.
-- Called again when a fresh snapshot arrives, because the "first chat of the day" bonus lands just after the dialogue opens.
local function refresh(npcId: string)
	local snapshot = State.current :: any
	local record = if snapshot and snapshot.npc then snapshot.npc[npcId] else nil
	local points = if record then record.affinity else 0
	local tier = Npcs.tierOf(points)
	nameLabel.Text = Locale.t(`npc.{npcId}`)
	local role = Locale.t(`npc.{npcId}.role`)
	local tierName = Locale.t(`npc.tier.{Npcs.TIERS[tier].id}`)
	roleLabel.Text = role .. "  ·  " .. Locale.t("affinity.line", { tier = tierName, n = points })
	local friendKey = `npc.{npcId}.greet_friend`
	lineLabel.Text = Locale.t(if tier >= 3 and Locale.has(friendKey) then friendKey else `npc.{npcId}.greet`)
end

local function open(npcId: any)
	if typeof(npcId) ~= "string" or not Npcs.byId[npcId] then
		return
	end
	ShopController.Close()
	currentNpc = npcId
	refresh(npcId)
	gui.Enabled = true
end

-- World position of an NPC rig (Workspace.Npcs.<id>), nil if it isn't loaded.
local function npcPosition(npcId: string): Vector3?
	local folder = Workspace:FindFirstChild("Npcs")
	local model = folder and folder:FindFirstChild(npcId)
	return if model and model:IsA("Model") then model:GetPivot().Position else nil
end

function DialogueController.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "DialogueUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5, 1)
	box.Position = UDim2.new(0.5, 0, 1, -24)
	box.Size = UDim2.new(0.92, 0, 0, 176)
	box.BackgroundColor3 = UiKit.BG
	box.BackgroundTransparency = 0.05
	box.Parent = gui
	Instance.new("UICorner").Parent = box
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(460, 176)
	limit.Parent = box

	nameLabel = label(box, "NpcName", 20, Enum.Font.GothamBold, UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 26))
	roleLabel = label(box, "Role", 13, Enum.Font.Gotham, UDim2.fromOffset(16, 36), UDim2.new(1, -32, 0, 18))
	roleLabel.TextTransparency = 0.3
	lineLabel = label(box, "Line", 16, Enum.Font.GothamMedium, UDim2.fromOffset(16, 62), UDim2.new(1, -32, 0, 56))

	local tradeButton = UiKit.button(box, "TradeButton", Locale.t("dialog.trade"), UiKit.BUTTON)
	tradeButton.AnchorPoint = Vector2.new(0, 1)
	tradeButton.Position = UDim2.new(0, 16, 1, -12)
	tradeButton.Size = UDim2.new(0.5, -22, 0, 40)
	tradeButton.TextSize = 17
	tradeButton.Activated:Connect(function()
		local npcId = currentNpc
		close()
		if npcId then
			ShopController.Open(npcId)
		end
	end)

	local byeButton = UiKit.button(box, "ByeButton", Locale.t("dialog.bye"), UiKit.BUTTON_MUTED)
	byeButton.AnchorPoint = Vector2.new(1, 1)
	byeButton.Position = UDim2.new(1, -16, 1, -12)
	byeButton.Size = UDim2.new(0.5, -22, 0, 40)
	byeButton.TextSize = 17
	byeButton.Activated:Connect(close)

	gui.Parent = player:WaitForChild("PlayerGui")
end

function DialogueController.Start()
	Net.Listen("NpcTalk", open)
	State.Changed:Connect(function()
		if currentNpc then
			refresh(currentNpc)
		end
	end)

	-- Walk away from the NPC and the dialogue / shop closes by itself.
	while true do
		task.wait(CHECK_SECONDS)
		local npcId = currentNpc or ShopController.CurrentNpc()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local position = if npcId then npcPosition(npcId) else nil
		if npcId and root and root:IsA("BasePart") and (not position or (root.Position - position).Magnitude > Npcs.LEAVE_DISTANCE) then
			close()
			ShopController.Close()
		end
	end
end

return DialogueController
