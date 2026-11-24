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
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local NpcCamera = require(script.Parent.Parent.NpcCamera)
local ShopController = require(script.Parent.ShopController)
local State = require(script.Parent.Parent.State)
local T1Dialog = require(script.Parent.Parent.T1Dialog)
local FadeManager = require(script.Parent.Parent.FadeManager)
local QuestOfferController = require(script.Parent.QuestOfferController)
local PromptGate = require(script.Parent.Parent.PromptGate) -- Plan v3 3.2: no proximity prompts while talking

local CHECK_SECONDS = 0.5

local player = Players.LocalPlayer

local DialogueController = {}

local gui: ScreenGui
local currentNpc: string? = nil
local holdFor: string? = nil -- the NPC whose sapaan decision / greeting is on screen (see open and FirstMeetDialogue)

-- Talk camera: while the conversation is open the camera glides to the over-the-shoulder shot (NpcCamera) and the NPC turns to you
-- (client-side only); closing glides back to where the camera was and hands it back to the player.
local FOCUS_TIME = 0.6
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
	-- K-106: the server turns the NPC toward the player (0.35 s, replicated); the camera does not wait for it.
	Net.Send("NpcFace", npcId, true)

	-- The head after the NPC has turned (it may have moved a little).
	local turned = model:FindFirstChild("Head")
	local face = if turned and turned:IsA("BasePart") then turned.Position else headPosition
	local shot, focusDistance = NpcCamera.Shot(face, character, { model })
	camera.CameraType = Enum.CameraType.Scriptable
	tweenCamera(shot, NpcCamera.FOV, FOCUS_TIME, nil)
	NpcCamera.SetBlur(true, focusDistance)
end

-- instant = true: the camera goes back at once, with no tween (Jual / Beli opens the shop straight away).
-- K-107: the camera goes back to the player at once (NpcCamera.ReturnToPlayer). No saved shot is restored any more.
local function releaseCamera(_instant: boolean?)
	if cameraTween then
		cameraTween:Cancel()
		cameraTween = nil
	end
	NpcCamera.ReturnToPlayer()
end

-- While a conversation is open every other screen is hidden (HUD, pills, hints, bars): only the NPC, the camera, the dialogue
-- box and the choices remain. They come back, exactly as they were, when it closes.
local hiddenGuis: { ScreenGui } = {}
-- K-92: the quest tracker stays up during a talk (it vanished when a talk took a quest; quest UI must not blink).
local KEEP_VISIBLE = { DialogueUI = true, T1Dialog = true, QuestUI = true }

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
	-- The chat is open again whenever a talk ends (it is hidden only while the talk box is up).
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end)
end

-- Puts the camera back on the player for good: cancels any dialogue tween, the NPC turns back, the blur goes, and the
-- camera follows the character's Humanoid again. Used by every way a talk ends and on respawn, so a Scriptable camera
-- can never stay on an NPC (a tween that was cancelled never reached its "back to Custom" step).
local function resetCameraToPlayer()
	if cameraTween then
		cameraTween:Cancel()
		cameraTween = nil
	end
	NpcCamera.ReturnToPlayer()
end

local function close(instantCamera: boolean?)
	if currentNpc then
		Net.Send("NpcFace", currentNpc, false) -- K-106: the NPC turns back (server side; also on respawn and leaving)
	end
	currentNpc = nil
	holdFor = nil
	QuestOfferController.Cancel() -- Q-3: a start dialog that is still running does not accept its quest
	player:SetAttribute("NpcTalkOpen", nil)
	T1Dialog.Hide()
	showOtherGuis()
	PromptGate.Show()
	releaseCamera(instantCamera)
end

-- The dialogue box: the NPC's face, name and greeting, and the numbered choices as a row of buttons inside it:
-- 1. Jual / Beli opens the NPC's shop (Kak Fajar, until his gift is taken: Terima Hadiah), 2. Sampai jumpa closes.
-- (Redrawn whenever the state syncs, so the choices are passed each time.)
local function gotRodGift(): boolean
	local snap = State.current
	return snap ~= nil and snap.guide ~= nil and snap.guide.rodGift == true
end

-- A shop stays closed below the NPC's unlockLevel (Mak Sari: the Dapur opens at Lv 6). Its dialogue shows npc.<id>.locked.
local function lockedFor(npcId: string): boolean
	local npc = Npcs.byId[npcId]
	local level = player:GetAttribute("Level")
	return npc ~= nil and npc.unlockLevel ~= nil and (typeof(level) ~= "number" or level < npc.unlockLevel)
end

-- A6 (K-53): Bang Jali's shop is closed until S3 "Tetangga di Depan" sells to him. Before its level: "Terbuka di Level {n}" plus
-- where to go. From its level on: the line tells the player to sell 1 item to him first.
local function gatedLine(): string
	local need = Quests.byId["s3_tetangga"].unlockLevel
	local level = player:GetAttribute("Level")
	if typeof(level) == "number" and level >= need then
		return Locale.t("npc.bang_jali.gated_quest")
	end
	return Locale.t("npc.bang_jali.gated", { level = need })
end

-- The shop choice is always "Jual / Beli" (opens the shop panel). The one-button "Jual semua panen (N%)" is the tutorial's
-- sale step only (T1Ghost), never a normal dialogue choice (owner video 3:52: Pak Udin still showed it after the tutorial).
local function tradeLabel(_npcId: string): string
	return Locale.t("dialog.trade")
end

local function greetSuffix(npcId: string): string
	return if lockedFor(npcId) then "locked" else "greet"
end

local function refresh(npcId: string)
	-- K-93: a finished quest of this giver is handed in first (its closing line, then the reward is paid), then the choices.
	local ready = QuestOfferController.ReadyFor(npcId)
	if ready then
		QuestOfferController.PlayTurnIn(npcId, ready, function()
			refresh(npcId)
		end)
		return
	end
	-- Q-3: a quest this giver offers is first introduced by its Naskah start dialog; the last Next accepts it (QuestAccept),
	-- then the normal choices come back here.
	local offer = QuestOfferController.ForGiver(npcId)
	if offer then
		QuestOfferController.PlayStart(npcId, offer, function()
			refresh(npcId)
		end)
		return
	end
	local choices = {}
	local giftMode = npcId == "kak_fajar" and not gotRodGift()
	local locked = not giftMode and lockedFor(npcId)
	if giftMode then
		-- GIFT MODE: the only choice is Terima Hadiah (no Sampai jumpa, no tap-outside close). The box is drawn again after the gift.
		table.insert(choices, {
			text = Locale.t("dialog.receive_gift"),
			onChoose = function()
				-- Terima Hadiah: the server gives the Joran Bambu and the pelet once (TutorialService).
				-- Then the talk ends with a fade (owner, P2-8): the player follows the arrow to the fishing spot.
				task.spawn(function()
					pcall(Net.Invoke, "MeetFajar")
					FadeManager.Play(function()
						close(true)
					end)
				end)
			end,
		})
	elseif not locked and not ShopController.Gated(npcId) then
		table.insert(choices, {
			text = tradeLabel(npcId),
			onChoose = function()
				local id = currentNpc
				-- Jual / Beli: no fade and no camera tween. The shop simply opens (only Sampai jumpa fades).
				close(true)
				if id then
					ShopController.Open(id)
				end
			end,
		})
	end
	-- TRADE MODE (after the gift): Jual / Beli and Sampai jumpa.
	if not giftMode then
		table.insert(choices, {
			text = Locale.t("dialog.bye"),
			onChoose = function()
				close() -- Sampai jumpa: no fade (cutscenes keep their own fades)
			end,
		})
	end
	T1Dialog.Show({
		name = Locale.t(`npc.{npcId}`),
		-- Gift mode (Kak Fajar's first visit) has its own line: the gift, not the shop greeting (playtest 2026-11-22).
		text = if giftMode then Locale.t(`npc.{npcId}.gift`) elseif ShopController.Gated(npcId) then gatedLine() else Locale.t(`npc.{npcId}.{greetSuffix(npcId)}`),
		avatar = npcModel(npcId),
		showNext = false,
		bottom = 16,
		choices = choices,
	})
end

-- First talk with an NPC (Fase 2): the sapaan and the introduction (Npcs.meet) with Next, then the choices as usual.
local function FirstMeetDialogue(npcId: string)
	local npc = Npcs.byId[npcId]
	T1Dialog.Show({
		name = Locale.t(`npc.{npcId}`),
		text = Locale.t(npc.meet, { name = player.DisplayName }),
		avatar = npcModel(npcId),
		showNext = true,
		bottom = 16,
		onNext = function()
			if holdFor == npcId and currentNpc == npcId then
				holdFor = nil
				refresh(npcId)
			end
		end,
	})
end

local function open(npcId: any)
	if typeof(npcId) ~= "string" or not Npcs.byId[npcId] then
		return
	end
	-- Playtest 7 item 3: this NPC's talk is already waiting for the box (one ambient line per approach): not queued twice.
	if T1Dialog.Waiting(npcId, T1Dialog.AMBIENT) then
		return
	end
	ShopController.Close()
	currentNpc = npcId
	-- holdFor = this NPC while the choose-or-sapaan decision is pending: State.Changed must not draw the choices first.
	holdFor = npcId
	player:SetAttribute("NpcTalkOpen", true)
	hideOtherGuis()
	PromptGate.Hide()
	Sfx.play("npc_hello")
	focusNpc(npcId)
	task.spawn(function()
		-- HasMet records the meeting on the server and tells us whether it was already there (false = first talk).
		local ok, alreadyMet = pcall(Net.Invoke, "HasMet", npcId)
		if currentNpc ~= npcId or holdFor ~= npcId then
			return -- closed meanwhile
		end
		-- The box is one channel: the talk waits its turn (a tutorial beat goes first) and is not lost; it opens when the box is free.
		-- The talk owns the box until close() hides it (T1Dialog.Hide gives the turn back).
		local held = T1Dialog.Acquire(npcId, T1Dialog.AMBIENT, function()
			return currentNpc ~= npcId
		end)
		if not held then
			return -- closed while it waited
		end
		if currentNpc ~= npcId or holdFor ~= npcId then
			held() -- closed right after its turn came: give the box back
			return
		end
		if ok and alreadyMet == false then
			FirstMeetDialogue(npcId)
		else
			holdFor = nil
			refresh(npcId)
		end
	end)
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
	-- Respawn: a talk that was open on the old character ends now, and the camera is back on the new character.
	player.CharacterAdded:Connect(function()
		if currentNpc then
			close(true)
		end
		ShopController.Close()
		resetCameraToPlayer()
	end)
	State.Changed:Connect(function()
		if currentNpc and holdFor == nil then
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
