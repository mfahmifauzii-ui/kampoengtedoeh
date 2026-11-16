--!strict
-- NPC dialogue: ONE button ("Ngobrol", a server-side ProximityPrompt) opens a conversation:
--   * the camera goes over the player's shoulder onto the NPC's face, with a depth-of-field blur (NpcCamera),
--   * the NPC's greeting is in the bamboo dialogue box (T1Dialog: face, name, text),
--   * the choices are a row of numbered UiKit buttons inside that box: 1. Jual / Beli opens the NPC's shop, 2. Sampai jumpa closes.
--     Tap / click, the number key (PC) or A / X (gamepad) picks one.
--
-- The old on-screen box ("DialogueUI") is no longer drawn; an empty ScreenGui with that name stays so nothing that looks for it breaks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local NpcCamera = require(script.Parent.Parent.NpcCamera)
local ShopController = require(script.Parent.ShopController)
local State = require(script.Parent.Parent.State)
local T1Dialog = require(script.Parent.Parent.T1Dialog)
local FadeManager = require(script.Parent.Parent.FadeManager) -- Plan v3 3.1: fade after a talk ends
local PromptGate = require(script.Parent.Parent.PromptGate) -- Plan v3 3.2: no proximity prompts while talking

local CHECK_SECONDS = 0.5

local player = Players.LocalPlayer

local DialogueController = {}

local gui: ScreenGui
local currentNpc: string? = nil

-- Talk camera: while the conversation is open the camera glides to the over-the-shoulder shot (NpcCamera) and the NPC turns to you
-- (client-side only); closing glides back to where the camera was and hands it back to the player.
local FOCUS_TIME = 0.6
local RETURN_TIME = 0.45
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
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ CFrame = cframe, FieldOfView = fov }
	)
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
	local headPosition = if head and head:IsA("BasePart")
		then head.Position
		else model:GetPivot().Position + Vector3.new(0, 2.5, 0)
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

	-- The head after the NPC has turned (it may have moved a little).
	local turned = model:FindFirstChild("Head")
	local face = if turned and turned:IsA("BasePart") then turned.Position else headPosition
	local shot, focusDistance = NpcCamera.Shot(face, character, { model })
	camera.CameraType = Enum.CameraType.Scriptable
	tweenCamera(shot, NpcCamera.FOV, FOCUS_TIME, nil)
	NpcCamera.SetBlur(true, focusDistance)
end

local function releaseCamera()
	if focusedModel and focusedPivot and focusedModel.Parent then
		focusedModel:PivotTo(focusedPivot)
	end
	focusedModel, focusedPivot = nil, nil
	NpcCamera.SetBlur(false)
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

-- While a conversation is open every other screen is hidden (HUD, pills, hints, bars): only the NPC, the camera, the dialogue
-- box and the choices remain. They come back, exactly as they were, when it closes.
local hiddenGuis: { ScreenGui } = {}
local KEEP_VISIBLE = { DialogueUI = true, T1Dialog = true }

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
	-- The tutorial keeps the chat closed (T1Ghost sets T1ChatLocked): do not open it behind its back.
	if player:GetAttribute("T1ChatLocked") ~= true then
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		end)
	end
end

local function close()
	currentNpc = nil
	player:SetAttribute("NpcTalkOpen", nil)
	T1Dialog.Hide()
	showOtherGuis()
	PromptGate.Show()
	releaseCamera()
end

-- The dialogue box: the NPC's face, name and greeting, and the numbered choices as a row of buttons inside it:
-- 1. Jual / Beli opens the NPC's shop, 2. Sampai jumpa closes. (Redrawn whenever the state syncs, so the choices are passed each time.)
local function refresh(npcId: string)
	T1Dialog.Show({
		name = Locale.t(`npc.{npcId}`),
		text = Locale.t(`npc.{npcId}.greet`),
		avatar = npcModel(npcId),
		showNext = false,
		bottom = 16,
		choices = {
			{
				text = Locale.t("dialog.trade"),
				onChoose = function()
					local id = currentNpc
					close()
					-- Fade from the talk into the shop: the shop opens while the screen is dark.
					FadeManager.Play(function()
						if id then
							ShopController.Open(id)
						end
					end)
				end,
			},
			{
				text = Locale.t("dialog.bye"),
				onChoose = function()
					close()
					FadeManager.Play()
				end,
			},
		},
	})
end

local function open(npcId: any)
	if typeof(npcId) ~= "string" or not Npcs.byId[npcId] then
		return
	end
	ShopController.Close()
	currentNpc = npcId
	player:SetAttribute("NpcTalkOpen", true)
	hideOtherGuis()
	PromptGate.Hide()
	refresh(npcId)
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
	-- Kept (empty, hidden) for the old UI contract; the conversation is drawn by T1Dialog.
	gui = Instance.new("ScreenGui")
	gui.Name = "DialogueUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
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
		if
			npcId
			and root
			and root:IsA("BasePart")
			and (not position or (root.Position - position).Magnitude > Npcs.LEAVE_DISTANCE)
		then
			close()
			ShopController.Close()
		end
	end
end

return DialogueController
