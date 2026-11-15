--!strict
-- NPC dialogue (The Forge style): ONE button ("Ngobrol", a server-side ProximityPrompt) opens this box:
-- the NPC's name, role and greeting, and two choices: [Jual / Beli] opens the NPC's shop, [Sampai jumpa] closes.
--
-- UI CONTRACT (replace with your designed UI, keep the names):
--   ScreenGui "DialogueUI" > Frame "Box" > TextLabel "NpcName", TextLabel "Role", TextLabel "Line",
--   TextButton "TradeButton", TextButton "ByeButton".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
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

-- Talk camera: while the dialogue is open the camera glides to a close, slightly-from-the-side shot of the NPC's face and the NPC
-- turns to you (client-side only); closing glides back to where the camera was and hands it back to the player.
local FOCUS_TIME = 0.55
local RETURN_TIME = 0.4
local FOCUS_FOV = 52
local saved: { cframe: CFrame, fov: number }? = nil
local focusedModel: Model? = nil
local focusedPivot: CFrame? = nil
local cameraTween: Tween? = nil

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function npcModel(npcId: string): Model?
	local folder = Workspace:FindFirstChild("Npcs")
	local model = folder and folder:FindFirstChild(npcId)
	return if model and model:IsA("Model") then model else nil
end

local function tweenCamera(cframe: CFrame, fov: number, seconds: number, onDone: (() -> ())?)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if cameraTween then
		cameraTween:Cancel()
	end
	local tween = TweenService:Create(camera, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = cframe, FieldOfView = fov })
	cameraTween = tween
	if onDone then
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				onDone()
			end
		end)
	end
	tween:Play()
end

local function focusNpc(npcId: string)
	local camera = Workspace.CurrentCamera
	local model = npcModel(npcId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not camera or not model or not root or not root:IsA("BasePart") then
		return
	end
	local head = model:FindFirstChild("Head")
	local headPosition = if head and head:IsA("BasePart") then head.Position else model:GetPivot().Position + Vector3.new(0, 2.5, 0)
	local toPlayer = flat(root.Position - headPosition)
	if toPlayer.Magnitude < 0.1 then
		return
	end
	toPlayer = toPlayer.Unit

	if not saved then
		saved = { cframe = camera.CFrame, fov = camera.FieldOfView }
	end
	-- The NPC turns to face you (local only).
	if focusedModel ~= model then
		if focusedModel and focusedPivot then
			focusedModel:PivotTo(focusedPivot)
		end
		focusedModel, focusedPivot = model, model:GetPivot()
	end
	local pivot = (focusedPivot :: CFrame).Position
	model:PivotTo(CFrame.lookAt(pivot, pivot + toPlayer))

	-- Shot: 7 studs out toward you, a little to the side and above eye level, aimed a touch low so the face sits above the dialogue box.
	local side = toPlayer:Cross(Vector3.yAxis).Unit
	local wanted = toPlayer * 7 + side * 2.4 + Vector3.new(0, 0.9, 0)
	-- Walls between the NPC and the camera (a stall's back wall, a roof): pull the camera in so it never films the inside of one.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, player.Character :: Instance }
	local hit = Workspace:Raycast(headPosition, wanted, params)
	if hit then
		wanted = wanted.Unit * math.max(hit.Distance - 0.6, 2.2)
	end
	local position = headPosition + wanted
	camera.CameraType = Enum.CameraType.Scriptable
	tweenCamera(CFrame.lookAt(position, headPosition + Vector3.new(0, -0.7, 0) - side * 0.5), FOCUS_FOV, FOCUS_TIME, nil)
end

local function releaseCamera()
	if focusedModel and focusedPivot and focusedModel.Parent then
		focusedModel:PivotTo(focusedPivot)
	end
	focusedModel, focusedPivot = nil, nil
	local back = saved
	saved = nil
	local camera = Workspace.CurrentCamera
	if not back or not camera then
		return
	end
	tweenCamera(back.cframe, back.fov, RETURN_TIME, function()
		camera.CameraType = Enum.CameraType.Custom
	end)
end

-- While a conversation is open every other screen is hidden (HUD, pills, hints, bars): only the NPC, the camera and the dialogue
-- box remain. They come back, exactly as they were, when it closes.
local hiddenGuis: { ScreenGui } = {}
local KEEP_VISIBLE = { DialogueUI = true }

local function hideOtherGuis()
	if #hiddenGuis > 0 then
		return
	end
	for _, other in player:WaitForChild("PlayerGui"):GetChildren() do
		if other:IsA("ScreenGui") and other.Enabled and not KEEP_VISIBLE[other.Name] then
			other.Enabled = false
			table.insert(hiddenGuis, other)
		end
	end
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	end)
end

local function showOtherGuis()
	for _, other in hiddenGuis do
		if other.Parent then
			other.Enabled = true
		end
	end
	hiddenGuis = {}
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end)
end

local function close()
	currentNpc = nil
	gui.Enabled = false
	showOtherGuis()
	releaseCamera()
end

-- Fills the box: the NPC's name, role and greeting.
local function refresh(npcId: string)
	nameLabel.Text = Locale.t(`npc.{npcId}`)
	roleLabel.Text = Locale.t(`npc.{npcId}.role`)
	lineLabel.Text = Locale.t(`npc.{npcId}.greet`)
end

local function open(npcId: any)
	if typeof(npcId) ~= "string" or not Npcs.byId[npcId] then
		return
	end
	ShopController.Close()
	currentNpc = npcId
	refresh(npcId)
	hideOtherGuis()
	gui.Enabled = true
	Sfx.play("npc_hello")
	focusNpc(npcId)
end

-- World position of an NPC rig (Workspace.Npcs.<id>), nil if it isn't loaded. (The pivot the NPC had BEFORE it turned to face
-- the player, so the walk-away check does not move.)
local function npcPosition(npcId: string): Vector3?
	local model = npcModel(npcId)
	return if model then model:GetPivot().Position else nil
end

function DialogueController.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "DialogueUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5, 1)
	box.Position = UDim2.new(0.5, 0, 1, -14) -- the dock is hidden while talking: sit near the bottom edge
	box.Size = UDim2.new(0.8, 0, 0, 176)
	box.BackgroundColor3 = UiKit.BG
	box.BackgroundTransparency = 0.05
	box.Parent = gui
	Instance.new("UICorner").Parent = box
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(330, 176)
	limit.Parent = box

	nameLabel = label(box, "NpcName", 18, Enum.Font.GothamBold, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 22))
	roleLabel = label(box, "Role", 11, Enum.Font.Gotham, UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 14))
	roleLabel.TextTransparency = 0.3
	lineLabel = label(box, "Line", 14, Enum.Font.GothamMedium, UDim2.fromOffset(12, 46), UDim2.new(1, -24, 0, 38))

	local tradeButton = UiKit.button(box, "TradeButton", Locale.t("dialog.trade"), UiKit.BUTTON)
	-- The choices are stacked vertically (one per line, full width), like a conversation menu.
	tradeButton.AnchorPoint = Vector2.new(0.5, 1)
	tradeButton.Position = UDim2.new(0.5, 0, 1, -46)
	tradeButton.Size = UDim2.new(1, -24, 0, 32)
	tradeButton.TextSize = 15
	tradeButton.Activated:Connect(function()
		local npcId = currentNpc
		close()
		if npcId then
			ShopController.Open(npcId)
		end
	end)

	local byeButton = UiKit.button(box, "ByeButton", Locale.t("dialog.bye"), UiKit.BUTTON_MUTED)
	byeButton.AnchorPoint = Vector2.new(0.5, 1)
	byeButton.Position = UDim2.new(0.5, 0, 1, -10)
	byeButton.Size = UDim2.new(1, -24, 0, 32)
	byeButton.TextSize = 15
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
