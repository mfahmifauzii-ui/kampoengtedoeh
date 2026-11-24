--!strict
-- T1 / T1b presenter (CLIENT ONLY, visual only; nothing here touches the server except the tutorial engine's own events).
--
-- MAK SARI: "MakSari_T1_Local" is a local copy of the real NPC (Workspace.Npcs.mak_sari, which stays ONE NPC in the
-- market). It exists from the intro until the end of T1b, then it is destroyed. It stands on the real ground (raycast, never a
-- fixed Y), has no collision, and is posed by code: the stock R15 idle / walk animations do not fit this rig (they crouch it and
-- open its arms), so it stands in its rest pose and walks with a gait of joint angles. The Humanoid is dropped because it forces
-- CanCollide back on.
--
-- THE INTRO (a fresh T1 only, once per session): the loading screen is up as soon as this script runs; nothing plays until
-- "Klik untuk Mulai" -> black 0.5 s -> slow fade in with cinematic bars -> Mak Sari appears 20 studs to the player's RIGHT and
-- WALKS in, stopping 4.5 studs in front-and-beside the player -> the player turns to her -> the camera stands still at a 3/4 side
-- view (both faces + the gate) -> 4 lines in the dialog box, each needs Next -> she walks aside of the gate and stays. There is no
-- Lewati: this tutorial is not skippable.
--
-- THE DIALOG: every word of the intro and of the tutorial is the dialog box (T1Dialog: bamboo, the speaker's face, the name,
-- Next). Nothing draws a bubble in the world and no GUI draws tutorial text: the coachmark only glows / points.
--
-- THE TUTORIAL: T1 (garap, tanam, siram, panen, jual) and T1b (warung, pond tool, Kak Fajar, first fish, first pond, fish in the
-- pond) are the tutorial engine's tutorials; GuideController gives each step to the instruction sink below, which shows the line
-- in the dialog box. The chat is closed from the loading screen to the end of T1b.
--
-- GuideController hooks used: AckWelcome, AckStep, Current, SetInstructionSink; the welcome modal is held back during the
-- intro by the player attribute T1CutsceneUntil (an os.clock deadline, refreshed while the intro lives).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local RS = ReplicatedStorage
local PlotsConfig = require(RS.Shared.Config.Plots)
local Net = require(RS.Shared.Modules.Net)
local State = require(script.Parent:WaitForChild("State"))
local NpcCamera = require(script.Parent:WaitForChild("NpcCamera"))
local PromptGate = require(script.Parent:WaitForChild("PromptGate"))
local NpcPose = require(script.Parent:WaitForChild("NpcPose"))
local T1Dialog = require(script.Parent:WaitForChild("T1Dialog"))
local Locale = require(RS.Shared.Locale)
local Items = require(RS.Shared.Modules.Items)
local Npcs = require(RS.Shared.Config.Npcs)
local Onboarding = require(RS.Shared.Config.Onboarding)
local Map = require(RS.Shared.Config.Map)
local Cutscene = require(script.Parent:WaitForChild("Cutscene"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local FadeManager = require(script.Parent:WaitForChild("FadeManager"))

local GHOST_NAME = "MakSari_T1_Local"
local SOURCE_NPC = "mak_sari"
local TUTORIAL_ID = "t1_awal"
local TUTORIAL_B_ID = "t1b_kolam"
local POLL_SECONDS = 0.25
local SNAPSHOT_WAIT = 12 -- the loading screen gives up after this long without a snapshot

-- Walking
local WALK_SPEED = 7 -- studs per second
local GAIT_CYCLE = 6 -- studs per full walking cycle (two steps)
local GAIT_HIP, GAIT_KNEE, GAIT_ARM = 28, 48, 20 -- degrees of swing

-- Placement (studs). dir = from the gate spawn toward the land; side = the player's RIGHT while facing the land.
local RIGHT_START = 16 -- she appears this far to the player's right (on the road)
local STOP_FORWARD, STOP_SIDE = 3.2, 3.2 -- and stops in front-and-beside the player: 4.5 studs away
local STATION_FORWARD = 5 -- her place for the tutorial: just inside the gate line ...
local STATION_SIDE = 9 -- ... and to the side of the gate opening (the gate is 32 wide)

-- Intro timing and camera
local BLACK_SECONDS = 0.5
local FADE_IN_SECONDS = 2.5
local BAR_HEIGHT = 0.06 -- of the screen height, top and bottom
local CAMERA_AFTER_CHARACTER = 2.4 -- CoachmarkController.gateCamera owns the camera until ~2.1 s after a spawn
-- Conversation shot: low and far enough that both of them stand fully ABOVE the dialog box (which fills the bottom third), and
-- leaning a little toward Mak Sari's side so the player's face turns toward the camera too.
local CAMERA_DISTANCE, CAMERA_HEIGHT, CAMERA_LEAN, CAMERA_FOV = 13, 3.4, -8, 50
local CAMERA_FOCUS_DROP = 0.6 -- the camera looks this far below the pair: they sit high in the frame
local HOLD_SECONDS = 10 -- the welcome-modal hold is refreshed to this far ahead
local ACK_RETRY_SECONDS = 8
local INTRO_BOTTOM = 16 -- px above the bottom bar
local TUTORIAL_BOTTOM = 92 -- px from the bottom of the screen: the dialog sits above the dock
local HIDE_DURING_INTRO = { "HUD", "QuestUI", "LikeUI", "FarmFloat", "LandMarks" } -- the game's own screens, hidden during the intro

-- Texts -----------------------------------------------------------------------------------------------------------

type Speaker = { name: string, npc: string }
local SPEAKERS: { [string]: Speaker } = {
	mak_sari = { name = "Mak Sari", npc = "mak_sari" },
	pak_udin = { name = "Pak Udin", npc = "pak_udin" },
	kak_fajar = { name = "Kak Fajar", npc = "kak_fajar" },
}

-- The tutorial introduces these NPCs itself. The first time a line of theirs plays, the server is told the NPC is met
-- (HasMet records it), so the first real talk afterwards does not repeat the sapaan (Bug 3, Lampiran D #35).
local introduced: { [string]: boolean } = {}
local function speakerFor(who: string): Speaker
	local speaker = SPEAKERS[who] or SPEAKERS.mak_sari
	if not introduced[speaker.npc] then
		introduced[speaker.npc] = true
		task.spawn(function()
			pcall(Net.Invoke, "HasMet", speaker.npc)
		end)
	end
	return speaker
end

-- All tutorial speech is in Locale (Naskah Dialog v0.1, bagian 1). Lines here are KEYS, read with Locale.t when shown.
-- Intro, Mak Sari (Next after every line).
local INTRO = { "tut.t1.intro.1", "tut.t1.intro.2", "tut.t1.intro.3", "tut.t1.intro.4" }

-- Pak Udin after the first sale: lines 3 and 4 (line 1 = greet and 2 = the sale question are the beat's own).
local WARUNG = { "tut.t1.jual.3", "tut.t1.jual.4" }

-- What is said for each tutorial step (key = GuideController's step key; "<key>_ground" while Garap mode is open, "<key>_stuck"
-- after a long wait). No line for a key = the old text GUI teaches that step. The first fish has no step line: its
-- sequence is the jual_ikan beat (BEATS), so no other line speaks in between.
type Line = { who: string, key: string }
local STEP_LINES: { [string]: Line } = {
	-- T1 (Mak Sari, at the gate)
	cangkul = { who = "mak_sari", key = "tut.t1.cangkul.1" },
	cangkul_ground = { who = "mak_sari", key = "tut.t1.cangkul_ground.1" },
	tanam = { who = "mak_sari", key = "tut.t1.tanam.1" },
	tanam_stuck = { who = "mak_sari", key = "tut.t1.tanam_stuck.1" },
	siram = { who = "mak_sari", key = "tut.t1.siram.1" },
	panen_wait = { who = "mak_sari", key = "tut.t1.panen_wait.1" },
	panen_harvest = { who = "mak_sari", key = "tut.t1.panen_harvest.1" },
	panen_sell = { who = "mak_sari", key = "tut.t1.panen_sell.1" },
	-- T1b
	kak_fajar = { who = "pak_udin", key = "tut.t1b.kak_fajar.1" },
	-- B2 (K-54): no line for the fishing step; the first two catches only show the instruction bubble ("Coba lagi, ...").
}

local function lineText(line: Line): string
	return Locale.t(line.key)
end
-- Steps that are dialogs of the intro (T1Ghost plays them itself): the sink says "handled" without showing a line.
local NARRATIVE: { [string]: boolean } = { sapa = true, warung = true }

-- Look (the same parchment as UiKit, copied so nothing here has to load UiKit before the loading screen)

local player = Players.LocalPlayer

-- Ghost state
local ghost: Model? = nil
local ghostRoot: BasePart? = nil
local ghostFoot = 3 -- studs from the rig's pivot (its root) down to the soles
local lastGroundY = 0
local calibrated = false
local joints: { [string]: AnimationConstraint } = {} -- her rig's joints by name (RightHip, LeftKnee, ...)
local sinkSet = false
local guideModule: any = nil

local introState = "idle" -- "idle" | "running" | "done" (once per session; "done" also when it was never needed)
local introFinish: (() -> ())? = nil -- cleanup of the running intro (also called if it errors half way)
local dialogBusy = false -- the intro or the warung beat is playing its own lines: the step sink must not draw over them
local lastSpoken = ""
local lineDismissed = false -- the player pressed Next on the current step line: it stays closed until the step changes
local sinkKey = "" -- the step key the sink last saw; a new step forgets the old step's line (no re-show of an old line)
local lastLine: Line? = nil -- the tutorial line on screen (shown again after an NPC conversation hid it)
local beatStep: string? = nil -- the step whose beat is playing (Playtest 7 item 4): the sink never re-shows its line meanwhile
local sessionTutorial = false -- this session saw T1 pending: the ghost lives on until T1b is done
local t1bStartSent = false
local warungStarted = false
local characterAddedAt = os.clock()
player.CharacterAdded:Connect(function()
	characterAddedAt = os.clock()
end)

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end


-- Tutorial state ----------------------------------------------------------------------------------------------------

local function guideData(): any
	local snap = State.current
	return snap and snap.guide
end

local function isDone(guide: any, id: string): boolean
	return guide.done[id] == true or guide.skipped[id] == true
end

-- The id of the step the player is on right now, straight from the save (guide.step), not from the instruction sink:
-- the sink only speaks for steps that have a line, so it cannot be used to tell which step is live.
local function activeStepId(guide: any): string?
	if not guide or not guide.step or guide.step.id == "" then
		return nil
	end
	for _, tutorial in Onboarding.TUTORIALS do
		if tutorial.id == guide.step.id then
			local step = tutorial.steps[(guide.step.n or 0) + 1]
			return step and step.id
		end
	end
	return nil
end

-- A beat is over for the box only when the server has moved the step on (Playtest 7 item 4). Until then dialogBusy stays
-- true, so the poll cannot re-show the beat's line. Gives up after 6 s (logged) so the tutorial cannot hang.
local function waitStepMoved(step: string)
	local waited = 0
	while waited < 6 do
		if activeStepId(guideData()) ~= step then
			return
		end
		task.wait(0.1)
		waited += 0.1
	end
	warn(`[T1Ghost] step {step} did not move on within 6 s`)
end

-- End of a beat: the box is free again, the sink may speak for the new step, and the banners may follow.
local function endBeat()
	beatStep = nil
	dialogBusy = false
	player:SetAttribute("KTBeatBusy", false)
end

-- Known guide state and T1 not finished. Unknown (no snapshot yet) counts as "do not build".
local function t1Pending(): boolean
	local guide = guideData()
	return guide ~= nil and not isDone(guide, TUTORIAL_ID)
end

-- T1 itself, or the T1b that follows it (it started in this session, or it is the tutorial this save is in the middle of).
local function tutorialPending(): boolean
	local guide = guideData()
	if guide == nil then
		return false
	end
	if not isDone(guide, TUTORIAL_ID) then
		return true
	end
	if isDone(guide, TUTORIAL_B_ID) then
		return false
	end
	return guide.step.id == TUTORIAL_B_ID or sessionTutorial
end

-- A fresh T1 that has not passed its welcome step: the only case the intro plays (a rejoin mid-T1 skips it).
local function introEligible(): boolean
	local guide = guideData()
	if guide == nil or not t1Pending() then
		return false
	end
	local step = guide.step
	-- The cutscene follows the tutorial's state, not the save's age: T1 not finished (or reset with !tut reset) = the intro plays.
	return (step.id == "" or (step.id == TUTORIAL_ID and step.n == 0))
end

-- Geometry --------------------------------------------------------------------------------------------------------

-- Gate spawn of this player's plot (the same math as PlotService.spawnAtPlot), the direction toward the land, and the
-- player's right. dir and side are flat unit vectors.
local function plotAxes(): (Vector3?, Vector3?, Vector3?)
	local plotName = player:GetAttribute("PlotName")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = plots and typeof(plotName) == "string" and plots:FindFirstChild(plotName)
	local origin = plot and plot:FindFirstChild("Origin")
	if not origin or not origin:IsA("BasePart") then
		return nil
	end
	local spawnPos = origin.CFrame * PlotsConfig.GATE_SPAWN -- CFrame * Vector3 = Vector3 (world point)
	local inward = origin.CFrame * Vector3.new(0, PlotsConfig.GATE_SPAWN.Y, PlotsConfig.FRONT_Z - 6)
	local toward = flat(inward - spawnPos)
	if toward.Magnitude < 0.01 then
		return nil
	end
	local dir = toward.Unit
	return spawnPos, dir, dir:Cross(Vector3.yAxis)
end

local function stationPosition(spawnPos: Vector3, dir: Vector3, side: Vector3): Vector3
	return spawnPos + dir * STATION_FORWARD + side * STATION_SIDE
end

-- Ground ----------------------------------------------------------------------------------------------------------

-- Height of the ground under (x, z): a ray from a little above refY down. Solid things only (RespectCanCollide), and never
-- her own body or the player's.
local function groundHeight(x: number, z: number, refY: number): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local ignore: { Instance } = {}
	if ghost then
		table.insert(ignore, ghost)
	end
	if player.Character then
		table.insert(ignore, player.Character)
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(Vector3.new(x, refY + 10, z), Vector3.new(0, -90, 0), params)
	return if hit then hit.Position.Y else nil
end

-- Puts her at (pos.X, pos.Z) with her soles on the ground there, facing lookAt (flat). pos.Y is only the ray's reference.
local function placeGhost(pos: Vector3, lookAt: Vector3?)
	local root = ghostRoot
	if not root then
		return
	end
	local ground = groundHeight(pos.X, pos.Z, pos.Y)
	if ground then
		lastGroundY = ground
	end
	local at = Vector3.new(pos.X, lastGroundY + ghostFoot, pos.Z)
	local target = lookAt or (at + root.CFrame.LookVector)
	root.CFrame = CFrame.lookAt(at, Vector3.new(target.X, at.Y, target.Z))
end

-- Ghost -----------------------------------------------------------------------------------------------------------

local function destroyGhost()
	if ghost then
		ghost:Destroy()
	end
	ghost, ghostRoot = nil, nil
	joints = {}
	calibrated = false
end

-- Pose -----------------------------------------------------------------------------------------------------------
-- This rig's joints (AnimationConstraints) do not follow the stock R15 conventions: Roblox's own idle and walk animations bend
-- its knees ~95 degrees and leave its arms open (a crouching T-pose). So no stock animation plays. The rig is put in its REST
-- pose (every joint Transform = identity, the two attachments of each joint aligned): she stands straight, arms down. Her walk
-- is a gait driven here, a few joint angles per frame. In that pose every limb joint turns about X (forward / back).

local gaitPhase = 0
local walking = false

-- Straight legs again after a walk (the arms are driven by NpcPose.Idle while she stands, see below).
local function restPose()
	NpcPose.StandStraight(joints)
end

-- One frame of the walk: the hips swing, the knee of the leg that swings forward bends, the arms swing against the legs.
local function applyGait(phase: number)
	NpcPose.Gait(joints, phase, GAIT_HIP, GAIT_KNEE, GAIT_ARM)
end

-- While she stands: the relaxed idle (arms near the body, soft elbows, a slow breath), not the stiff rest pose.
RunService.RenderStepped:Connect(function()
	if ghost and not walking then
		NpcPose.Idle(joints, os.clock())
	end
end)

-- Puts the rig in its rest pose, then her soles on the ground by what that pose really measures (the lowest foot).
local function calibrate(model: Model)
	joints = NpcPose.Prepare(model)
	NpcPose.Idle(joints, os.clock())
	task.wait(0.4)
	if ghost ~= model then
		return
	end
	local lowest = math.huge
	for _ = 1, 5 do
		task.wait(0.06)
		if ghost ~= model then
			return
		end
		for _, name in { "LeftFoot", "RightFoot" } do
			local foot = model:FindFirstChild(name)
			if foot and foot:IsA("BasePart") then
				lowest = math.min(lowest, foot.Position.Y - foot.Size.Y / 2)
			end
		end
	end
	local root = ghostRoot
	if root and lowest < math.huge then
		local ground = groundHeight(root.Position.X, root.Position.Z, root.Position.Y)
		if ground then
			ghostFoot -= (lowest - ground) - 0.02
			placeGhost(root.Position, nil)
		end
	end
	calibrated = true
end

-- Builds her (a client-only copy of the real NPC) standing at pos on the ground, facing lookAt. pos.Y is a ray reference.
local function buildGhost(pos: Vector3, lookAt: Vector3): boolean
	if ghost then
		return true
	end
	local npcs = Workspace:FindFirstChild("Npcs")
	local source = npcs and npcs:FindFirstChild(SOURCE_NPC)
	if not source or not source:IsA("Model") then
		return false -- the real NPC has not replicated yet
	end
	local copy = source:Clone()
	copy.Name = GHOST_NAME
	local root = copy:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		copy:Destroy()
		return false
	end
	for _, d in copy:GetDescendants() do
		-- No prompt, scripts, name tag or Humanoid: the Humanoid forces CanCollide back on for the rig's parts, and she is moved
		-- by code (a rest pose and a gait of joint angles).
		if
			d:IsA("ProximityPrompt")
			or d:IsA("Script")
			or d:IsA("LocalScript")
			or d:IsA("ClickDetector")
			or d:IsA("Humanoid")
			or d:IsA("BillboardGui")
		then
			d:Destroy()
		elseif d:IsA("BallSocketConstraint") then
			d.Enabled = false -- ragdoll joints: the AnimationConstraints carry the pose
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			d.Anchored = d == root -- only the root: the limbs follow it and stay free to animate
		end
	end
	copy.PrimaryPart = root

	-- Pivot (root) to soles, measured on the untouched rig: she is put on the ground by this, never by a fixed Y.
	local boxCf, boxSize = copy:GetBoundingBox()
	ghostFoot = root.Position.Y - (boxCf.Position.Y - boxSize.Y / 2)
	lastGroundY = pos.Y - 3
	calibrated = false

	local controller = Instance.new("AnimationController")
	controller.Parent = copy
	local animator = Instance.new("Animator") -- the rig expects an animator; no track ever plays on it
	animator.Parent = controller

	ghost, ghostRoot = copy, root
	placeGhost(pos, lookAt)
	copy.Parent = Workspace -- created on the client only: not replicated, not visible to other players
	task.spawn(calibrate, copy)
	return true
end

local function setWalking(on: boolean)
	walking = on
	gaitPhase = 0
	if not on then
		restPose()
	end
end

-- Walks her to target (flat), her feet following the ground. False if she was cut short (alive() false or she is gone).
local function walkTo(target: Vector3, alive: () -> boolean): boolean
	local root = ghostRoot
	if not root then
		return false
	end
	setWalking(true)
	while true do
		if not alive() or not root.Parent then
			return false
		end
		local here = root.Position
		local delta = flat(target - here)
		local distance = delta.Magnitude
		if distance < 0.15 then
			break
		end
		local dt = RunService.RenderStepped:Wait()
		local dir = delta.Unit
		local step = math.min(distance, WALK_SPEED * dt)
		placeGhost(here + dir * step, here + dir * 10)
		gaitPhase += dt * 2 * math.pi * WALK_SPEED / GAIT_CYCLE
		applyGait(gaitPhase)
	end
	setWalking(false)
	return true
end

-- Turns a part (flat) to face point over `seconds`.
local function faceTo(part: BasePart, point: Vector3, seconds: number)
	local from = part.CFrame
	local to = CFrame.lookAt(from.Position, Vector3.new(point.X, from.Position.Y, point.Z))
	local t = 0
	while t < seconds do
		t += RunService.RenderStepped:Wait()
		if not part.Parent then
			return
		end
		part.CFrame = from:Lerp(to, math.min(t / seconds, 1))
	end
end

-- Dialog ----------------------------------------------------------------------------------------------------------

-- A tutorial line is a BEAT (front of the speech queue, see T1Dialog.Acquire): it waits for the box, then shows. `cancelled`
-- drops it if it is no longer wanted while it waits. Returns at once; the line is drawn when its turn comes.
local function showLine(who: string, text: string, showNext: boolean, bottom: number, onNext: (() -> ())?, cancelled: (() -> boolean)?)
	local speaker = speakerFor(who)
	task.spawn(function()
		local release = T1Dialog.Acquire(speaker.npc, T1Dialog.BEAT, cancelled)
		if not release then
			return
		end
		T1Dialog.Show({
			name = speaker.name,
			text = text,
			avatar = T1Dialog.NpcModel(speaker.npc),
			showNext = showNext,
			bottom = bottom,
			onNext = function()
				release()
				if onNext then
					onNext()
				end
			end,
		})
	end)
end

-- Shows one line and waits for the player to press Next (nothing advances by itself). False if alive() said stop.
local function waitNext(who: string, text: string, bottom: number, alive: () -> boolean): boolean
	local pressed = false
	showLine(who, text, true, bottom, function()
		pressed = true
	end, function()
		return not alive()
	end)
	while not pressed do
		if not alive() then
			return false
		end
		task.wait(0.05)
	end
	return true
end

-- Instruction lines (Playtest 8 item 2, owner rule, GUI doc Bab 5.1). The sink's step line is an instruction bubble. It never
-- disappears by itself: when the step changes it SWAPS its text in place (minimize toward the NPC, then restore with the new
-- text; the turn is kept). Only the player's Next closes it. A beat takes the box: the instruction minimizes, the beat plays,
-- and the instruction restores afterwards with the current step's text, unless the player closed it for that step.
local instrRelease: (() -> boolean)? = nil -- the box turn the instruction holds (on screen, or swapping)
local instrKey: string? = nil -- the sink key of the instruction on screen or waiting for the box

-- Closes the instruction: the box minimizes toward the speaker, then the turn goes back and the box hides. Yields during the
-- minimize, so call it from a task (task.spawn when the caller must not yield). forgetLine also forgets the line (step over).
local function closeInstruction(forgetLine: boolean)
	local release = instrRelease
	instrRelease = nil
	instrKey = nil
	if forgetLine then
		lastLine = nil
	end
	if release then
		T1Dialog.Minimize()
		if release() then
			T1Dialog.Hide()
		end
	end
end

-- The bubble's content for an instruction line. Next only dismisses it (the close uses the minimize animation).
local function instructionOpts(line: Line)
	local speaker = speakerFor(line.who)
	return {
		name = speaker.name,
		text = lineText(line),
		avatar = T1Dialog.NpcModel(speaker.npc),
		showNext = true,
		bottom = TUTORIAL_BOTTOM,
		variant = "instruction", -- GUI doc 5.1: compact instruction bubble
		onNext = function()
			lineDismissed = true
			task.spawn(closeInstruction, false)
		end,
	}
end

-- The step changed while the instruction holds the box: minimize toward the old speaker, then restore with the new text.
-- The turn is kept, so no queued line can take the box in between.
local function swapInstruction(line: Line, key: string)
	instrKey = key
	lastLine = line
	lineDismissed = false
	task.spawn(function()
		T1Dialog.Minimize()
		if instrRelease == nil or instrKey ~= key then
			return -- closed meanwhile
		end
		T1Dialog.Restore(instructionOpts(line))
	end)
end

-- Shows a step's instruction: a swap when it already holds the box, else it waits its turn (a beat goes first) and then opens
-- from the avatar. Never two of the same key at once.
local function showInstruction(line: Line, key: string)
	if instrKey == key then
		return
	end
	local step = activeStepId(guideData())
	if instrRelease ~= nil then
		swapInstruction(line, key)
		return
	end
	local speaker = speakerFor(line.who)
	instrKey = key
	task.spawn(function()
		local release = T1Dialog.Acquire(speaker.npc, T1Dialog.AMBIENT, function()
			return sinkKey ~= key or dialogBusy or activeStepId(guideData()) ~= step
		end)
		if not release then
			if instrKey == key then
				instrKey = nil
			end
			return
		end
		instrRelease = release
		T1Dialog.Restore(instructionOpts(line))
	end)
end

-- The dialog box and the ghost wait for the end of the menu (a missing MenuFlow counts as done).
local function menuDone(): boolean
	local state = player:GetAttribute("KTMenu")
	return state == nil or state == "done"
end

-- Tutorial speech: GuideController hands each step to this sink; the line goes in the dialog box and the GUI shows no text.
local function ensureSink()
	if sinkSet then
		return
	end
	local ok, guide = pcall(function()
		return require(script.Parent:WaitForChild("Controllers"):WaitForChild("GuideController") :: ModuleScript) :: any
	end)
	if not ok then
		return
	end
	guideModule = guide
	guide.SetInstructionSink(function(key: string, stuck: boolean): boolean
		if key ~= sinkKey then
			sinkKey = key
			lastLine = nil -- the old step's line must not come back over the new step (e.g. after the fish dialog)
			lineDismissed = false
			-- A new step key does not close the instruction: showInstruction swaps its text in place (owner rule).
		end
		if key == beatStep then
			return true -- the beat on screen owns this step: its line is never shown again by the poll (Playtest 7 item 4)
		end
		if NARRATIVE[key] then
			return true -- an intro dialog: played by the intro / the warung beat
		end
		local line = (stuck and STEP_LINES[`{key}_stuck`]) or STEP_LINES[key]
		if not line then
			-- No line for the new step: the old step's bubble minimizes out (it must not keep the old text), and it comes back
			-- only with a line of a later step.
			if instrRelease ~= nil or instrKey ~= nil then
				task.spawn(closeInstruction, true)
			end
			return false -- no line for this step: the text GUI teaches instead
		end
		if not dialogBusy and menuDone() and lastSpoken ~= line.key then
			lastSpoken = line.key
			lastLine = line
			lineDismissed = false
			showInstruction(line, key)
		end
		-- The player pressed Next on this step's line but the step is still open: the text goes back to the hint /
		-- coachmark (GuideController shows it when false), so the step never has no visible instruction (found in Play 2026-11-23).
		return not lineDismissed
	end)
	sinkSet = true
end

local function clearSink()
	if guideModule and sinkSet then
		pcall(function()
			guideModule.SetInstructionSink(nil)
		end)
	end
	sinkSet = false
	lastSpoken = ""
	task.spawn(closeInstruction, true)
	lastLine = nil
	-- The poll calls this every tick once the tutorial is done. The dialog box is shared with town NPC talks
	-- (DialogueController), so only hide it when no conversation owns it: otherwise the NPC's bubble vanishes at once.
	if player:GetAttribute("NpcTalkOpen") ~= true then
		T1Dialog.Hide()
	end
end

-- The intro --------------------------------------------------------------------------------------------------------

local function holdWelcomeModal(seconds: number)
	player:SetAttribute("T1CutsceneUntil", os.clock() + seconds)
end

local function releaseWelcomeModal()
	player:SetAttribute("T1CutsceneUntil", nil)
end

local function getControls(): any
	local ok, controls = pcall(function()
		local playerScripts = player:WaitForChild("PlayerScripts", 5)
		local module = playerScripts and playerScripts:WaitForChild("PlayerModule", 5)
		return if module then (require(module :: ModuleScript) :: any):GetControls() else nil
	end)
	return if ok then controls else nil
end

type Intro = {
	gui: ScreenGui,
	cover: Frame,
	barTop: Frame,
	barBottom: Frame,
}

-- The intro's screen furniture: the black cover and the cinematic bars. (The loading screen and the PLAY button are MenuFlow's.)
local function buildIntroUi(): Intro
	local gui = Instance.new("ScreenGui")
	gui.Name = "T1Cutscene"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = UiKit.LAYER.CUTSCENE
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Black cover: hidden until PLAY, then 0.5 s of pure black and a slow fade in.
	local cover = Instance.new("Frame")
	cover.Name = "Cover"
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Color3.new(0, 0, 0)
	cover.BorderSizePixel = 0
	cover.ZIndex = 30
	cover.Active = false
	cover.Visible = false
	cover.Parent = gui

	local function bar(name: string, anchorY: number): Frame
		local b = Instance.new("Frame")
		b.Name = name
		b.AnchorPoint = Vector2.new(0, anchorY)
		b.Position = UDim2.fromScale(0, anchorY)
		b.Size = UDim2.fromScale(1, BAR_HEIGHT)
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BorderSizePixel = 0
		b.ZIndex = 31
		b.Visible = false
		b.Parent = gui
		return b
	end
	local barTop, barBottom = bar("BarTop", 0), bar("BarBottom", 1)

	gui.Parent = player:WaitForChild("PlayerGui")
	return {
		gui = gui,
		cover = cover,
		barTop = barTop,
		barBottom = barBottom,
	}
end

local function runIntro()
	-- Everything the intro needs: the real NPC (to copy), the plot, the character.
	local spawnPos: Vector3? = nil
	local dir: Vector3? = nil
	local side: Vector3? = nil
	local waited = 0
	while waited < 10 do
		holdWelcomeModal(HOLD_SECONDS)
		spawnPos, dir, side = plotAxes()
		local npcs = Workspace:FindFirstChild("Npcs")
		local character = player.Character
		if
			spawnPos
			and npcs
			and npcs:FindFirstChild(SOURCE_NPC)
			and character
			and character:FindFirstChild("HumanoidRootPart")
		then
			break
		end
		task.wait(0.1)
		waited += 0.1
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local okGuide, Guide = pcall(function()
		return require(script.Parent:WaitForChild("Controllers"):WaitForChild("GuideController") :: ModuleScript) :: any
	end)
	if not spawnPos or not dir or not side or not humanoid or not root or not okGuide then
		-- No intro: the tutorial runs without it (she is placed at the gate by the poll).
		warn(`[T1Ghost] intro skipped: spawn={tostring(spawnPos ~= nil)} npc={tostring(Workspace:FindFirstChild("Npcs") ~= nil and Workspace.Npcs:FindFirstChild(SOURCE_NPC) ~= nil)} humanoid={tostring(humanoid ~= nil)}`)
		releaseWelcomeModal()
		introState = "done"
		return
	end
	local ui = buildIntroUi()
	guideModule = Guide
	local rootPart = root :: BasePart
	local camera = Workspace.CurrentCamera :: Camera
	local controls = getControls()
	local playerGui = player:WaitForChild("PlayerGui")
	-- The game's own UI steps aside for the cinematic: collected and hidden once the menu is over (MenuFlow hides everything
	-- until then and gives it back at PLAY), restored in finish.
	local guideGui: Instance? = nil
	local guideGuiWasEnabled = false
	local hiddenGuis: { ScreenGui } = {}
	local previousFov = camera.FieldOfView

	local ended = false
	local cameraTaken = false
	local shotCf = camera.CFrame
	local shotFov = CAMERA_FOV
	local wideShot = camera.CFrame -- the two-shot while she walks in; the conversation shot replaces it when she has arrived
	local conn: RBXScriptConnection? = nil

	local function finish()
		if ended then
			return
		end
		ended = true
		if conn then
			conn:Disconnect()
		end
		pcall(function()
			if controls then
				controls:Enable()
			end
		end)
		pcall(function()
			humanoid.AutoRotate = true
		end)
		if cameraTaken then
			camera.CameraType = Enum.CameraType.Custom
			camera.FieldOfView = previousFov
		end
		if guideGui and guideGui:IsA("ScreenGui") and guideGuiWasEnabled then
			guideGui.Enabled = true
		end
		for _, other in hiddenGuis do
			other.Enabled = true
		end
		dialogBusy = false
		NpcCamera.SetBlur(false)
		player:SetAttribute("KTIntroRunning", nil)
		player:SetAttribute("KTIntroPlaying", nil)
		ui.gui:Destroy()
		releaseWelcomeModal()
		-- The fade already ran right after Mak Sari's last line (see runIntro); the coachmark can show now.
		introState = "done"
	end
	introFinish = finish
	player:SetAttribute("KTIntroPlaying", true) -- the hint bar stays off while the intro cutscene plays (Playtest 7 item 5)

	-- True while the intro should keep going; also keeps the welcome modal held back.
	local function alive(): boolean
		if ended then
			return false
		end
		if not t1Pending() or not rootPart.Parent or humanoid.Health <= 0 then
			finish()
			return false
		end
		holdWelcomeModal(HOLD_SECONDS)
		return true
	end

	local function pause(seconds: number): boolean
		local t = 0
		while t < seconds do
			if not alive() then
				return false
			end
			t += task.wait(0.05)
		end
		return alive()
	end

	-- The camera: held still at the conversation shot once it is taken (and taken again if anything gives it back).
	conn = RunService.RenderStepped:Connect(function(dt: number)
		if not cameraTaken or ended then
			return
		end
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		-- Glides toward the wanted shot (the cut from the two-shot to the conversation shot is not a jump).
		local alpha = 1 - math.exp(-dt * 4)
		camera.CFrame = camera.CFrame:Lerp(shotCf, alpha)
		camera.FieldOfView += (shotFov - camera.FieldOfView) * alpha
	end)

	-- Mak Sari is made NOW, behind the loading screen (it covers the whole screen), so that her pose is calibrated by the time
	-- the player clicks and the black screen after the click stays short.
	do
		local p0 = rootPart.Position
		local s0 = p0 + (dir :: Vector3) * STOP_FORWARD + (side :: Vector3) * RIGHT_START
		buildGhost(Vector3.new(s0.X, p0.Y, s0.Z), p0)
	end

	-- A. The menu (MenuFlow): loading screen -> Play screen -> PLAY. Nothing of the intro shows before that. While it runs, the
	-- player stays locked (MenuFlow leaves the controls to us because of KTIntroRunning).
	player:SetAttribute("KTIntroRunning", true)
	pcall(function()
		if controls then
			controls:Disable()
		end
	end)
	humanoid.AutoRotate = false
	while player:GetAttribute("KTMenu") ~= "done" do
		if not alive() then
			return
		end
		task.wait(0.1)
	end
	-- The menu is over and has given the game's screens back (under its black): now the cinematic hides them.
	guideGui = playerGui:FindFirstChild("GuideUI")
	guideGuiWasEnabled = guideGui ~= nil and guideGui:IsA("ScreenGui") and guideGui.Enabled
	for _, name in HIDE_DURING_INTRO do
		local other = playerGui:FindFirstChild(name)
		if other and other:IsA("ScreenGui") and other.Enabled then
			table.insert(hiddenGuis, other)
		end
	end
	previousFov = camera.FieldOfView
	if guideGui and guideGui:IsA("ScreenGui") then
		guideGui.Enabled = false
	end
	for _, other in hiddenGuis do
		other.Enabled = false
	end

	-- B. Dark screen: black for BLACK_SECONDS, then a slow fade in; the bars are there from now on.
	ui.cover.Visible = true
	ui.cover.BackgroundTransparency = 0
	ui.barTop.Visible, ui.barBottom.Visible = true, true
	dialogBusy = true

	-- Behind the black: her start place (16 studs to the player's right, on the road), and the camera's conversation shot.
	local pp = rootPart.Position
	local startPos = pp + (dir :: Vector3) * STOP_FORWARD + (side :: Vector3) * RIGHT_START
	local stopPos = pp + (dir :: Vector3) * STOP_FORWARD + (side :: Vector3) * STOP_SIDE
	if not ghost and not buildGhost(Vector3.new(startPos.X, pp.Y, startPos.Z), pp) then
		finish()
		return
	end
	placeGhost(Vector3.new(startPos.X, pp.Y, startPos.Z), pp)
	ensureSink()

	-- Conversation camera, 3/4 from the side: the line between the two of them is u; the camera stands on the road side, a bit
	-- behind the player, looking across that line, so both faces and the gate are in one frame. Then pulled in if anything
	-- (a sign, a fence post) is between it and the pair.
	local u = flat(stopPos - pp).Unit
	local across = (-(dir :: Vector3) + (side :: Vector3)).Unit -- perpendicular to u, on the road side
	local lean = math.rad(CAMERA_LEAN)
	local mid = (pp + stopPos) / 2
	local away = across * math.cos(lean) - u * math.sin(lean)
	local eye = mid + away * CAMERA_DISTANCE + Vector3.new(0, CAMERA_HEIGHT, 0)
	local focus = mid - Vector3.new(0, CAMERA_FOCUS_DROP, 0)
	do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.RespectCanCollide = true
		params.FilterDescendantsInstances = { character :: Instance, ghost :: Instance }
		local from = mid + Vector3.new(0, 2.5, 0)
		local hit = Workspace:Raycast(from, eye - from, params)
		if hit then
			eye = from + (eye - from).Unit * math.max((hit.Position - from).Magnitude - 0.8, 3)
		end
	end
	shotCf = CFrame.lookAt(eye, focus)
	wideShot = shotCf

	if not pause(BLACK_SECONDS) then
		return
	end
	while os.clock() < characterAddedAt + CAMERA_AFTER_CHARACTER or not calibrated do
		if not pause(0.05) then
			return
		end
		if os.clock() > characterAddedAt + 8 then
			break
		end
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = CAMERA_FOV
	camera.CFrame = shotCf
	cameraTaken = true
	TweenService:Create(ui.cover, TweenInfo.new(FADE_IN_SECONDS), { BackgroundTransparency = 1 }):Play()
	task.delay(FADE_IN_SECONDS + 0.1, function()
		ui.cover.Visible = false
	end)
	if not pause(1.2) then
		return
	end

	-- C. She walks in from the right (the rig's walk animation) and stops in front-and-beside the player; the player turns to her.
	if not walkTo(stopPos, alive) then
		return
	end
	local npcRoot = ghostRoot
	if npcRoot then
		faceTo(npcRoot, rootPart.Position, 0.35)
	end
	faceTo(rootPart, stopPos, 0.5)
	if not pause(0.3) then
		return
	end
	-- The conversation: over the player's shoulder onto her face (the player a blurred sliver at the left), the rest blurred.
	local face = ghost and ghost:FindFirstChild("Head")
	if face and face:IsA("BasePart") then
		local cf, focusDistance = NpcCamera.Shot(face.Position, character, { ghost :: Instance })
		shotCf, shotFov = cf, NpcCamera.FOV
		NpcCamera.SetBlur(true, focusDistance)
		if not pause(0.9) then
			return
		end
	end
	local intro = math.floor(camera.ViewportSize.Y * BAR_HEIGHT) + INTRO_BOTTOM
	for _, line in INTRO do
		if not waitNext("mak_sari", Locale.t(line), intro, alive) then
			return
		end
	end
	T1Dialog.Hide()
	-- The last line was pressed: the fade starts at once (dark, then dissolve), before the walk-off and the coachmark.
	FadeManager.Play()
	shotCf, shotFov = wideShot, CAMERA_FOV -- the conversation is over: back to the wide shot while she walks aside
	NpcCamera.SetBlur(false)

	-- D. She walks to the side of the gate and stays there for the whole tutorial.
	local station = stationPosition(spawnPos, dir :: Vector3, side :: Vector3)
	if not walkTo(station, alive) then
		return
	end
	if ghostRoot then
		faceTo(ghostRoot, spawnPos, 0.35)
	end

	-- The welcome step is done: the tutorial starts (acknowledged BEFORE the hold ends, so no modal ever shows).
	local t = 0
	while t < ACK_RETRY_SECONDS and not Guide.AckWelcome() do
		if not alive() then
			return
		end
		t += task.wait(0.2)
	end
	finish()
end

-- T1b, the warung beat -------------------------------------------------------------------------------------------

-- Pak Udin's three lines (Next after each) once the shop panel is closed after the sale, then the step is acknowledged.
-- If the player is at the warung (near him), the camera goes over their shoulder onto his face with the blur, like any talk.
local function runWarung(guide: any)
	closeInstruction(false) -- a beat starts: the instruction minimizes, then the beat takes the box (owner rule)
	dialogBusy = true
	local endCutscene: (() -> ())? = nil -- Cutscene.Begin's End: camera and controls back (Cutscene.luau)

	-- v7.4 Bab 16.4: the first sale has its own beat (runSaleBeat, proximity-triggered BEFORE the sale) and it says these
	-- same lines itself. What is left here is the plain visit: a save that resumes at T1b step 0 with the sale long done.

	local function leave()
		if endCutscene then
			endCutscene()
			endCutscene = nil
		end
		dialogBusy = false
	end

	local function alive(): boolean
		local id, n = guide.Current()
		return tutorialPending() and id == TUTORIAL_B_ID and n == 0
	end
	local function shopOpen(): boolean
		local panel = player:WaitForChild("PlayerGui"):FindFirstChild("ShopPanel")
		return panel ~= nil and panel:IsA("ScreenGui") and panel.Enabled
	end
	while shopOpen() do
		if not alive() then
			leave()
			return
		end
		task.wait(0.2)
	end

	local npc = T1Dialog.NpcModel("pak_udin")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = npc and npc:FindFirstChild("Head")
	if
		npc
		and root
		and root:IsA("BasePart")
		and head
		and head:IsA("BasePart")
		and (head.Position - root.Position).Magnitude < 22
	then
		endCutscene = Cutscene.Begin(npc :: Model, head :: BasePart)
	end

	for _, line in WARUNG do
		if not waitNext("pak_udin", Locale.t(line), TUTORIAL_BOTTOM, alive) then
			leave()
			return
		end
	end
	T1Dialog.Hide()
	lastSpoken = ""
	-- Playtest 7 item 4: the ack goes first; the box stays busy until the server has moved the step on.
	guide.AckStep("warung")
	waitStepMoved("warung")
	leave()
end

-- A screen the tutorial line must not cover. (The seed picker and the tile panel are left out: the player needs the line there.)
local BIG_PANELS = {
	"ShopPanel",
	"InventoryPanel",
	"SettingsPanel",
	"GuidePanel",
	"BookPanel",
	"OrdersPanel",
	"RewardsPanel",
	"SocialPanel",
	"StorePanel",
}
local function bigPanelOpen(): boolean
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return false
	end
	for _, name in BIG_PANELS do
		local panel = playerGui:FindFirstChild(name)
		if panel and panel:IsA("ScreenGui") and panel.Enabled then
			return true
		end
	end
	return false
end

-- JUAL (v7.4 Bab 16.4; playtest 2026-11-22) -----------------------------------------------------------------------------
-- Two beats, each once ever, started by WALKING UP to the NPC while its tutorial step is live:
--   * panen_jual: Pak Udin buys the harvest. Warung lines after the sale, then the fade.
--   * jual_ikan:  Kak Fajar buys the first fish. No lines after the sale: the sale itself finishes T1b ("Selesai" shows).
-- No click, no auto-sell, no skip, full price: the beat opens the sale as a bubble choice, waits for the real sale (the
-- guide flag from the server), says the lines and ends.
local SALE_BEAT_DISTANCE = Onboarding.SALE_BEAT_RADIUS -- studs (flat) between the player and the NPC when the beat starts; the server sell range is Shop.NPC_DISTANCE
-- The wide shot of the sale (Bab 16.4, 2026-11-24): a fixed camera on the tree's south-east side, aimed at the warung ring
-- south of the banyan (Pak Udin's stall at z 59, Map.WARUNG). Eye 14 studs east and 10 south of the trunk, 22 up.
local SALE_WIDE_SHOT = {
	eye = Vector3.new(Map.TOWN.TREE_X + 14, 22, Map.TOWN.TREE_Z + 10),
	focus = Vector3.new(-2, 8, 40),
}

-- B-1 timing log: os.clock() when the trigger fires (tryStartBeat), then each milestone of the beat. Set false to silence.
local BEAT_TIMING_LOG = true
local beatEnteredAt: number? = nil
local function beatLog(label: string)
	if BEAT_TIMING_LOG and beatEnteredAt then
		print(`[beat-timing] {label} +{string.format("%.3f", os.clock() - beatEnteredAt)}s`)
	end
end

type Beat = {
	step: string, -- the tutorial step that is live
	npc: string, -- Config/Npcs id
	name: string, -- Locale key of the speaker
	sold: (guide: any) -> boolean, -- true once the sale of this beat happened (server flag)
	ask: string, -- Locale key of the bubble question
	greet: string?, -- Locale key of the sapaan (said first, {name} = the player)
	after: { string }, -- lines said after the sale
	afterChoice: string?, -- the last line after the sale: a bubble with ONE button (afterOk), the beat waits for it
	afterOk: string?, -- Locale key of that button
	ackStep: string?, -- guide step acked when the beat is over
	kind: string?, -- "gift" = walk-up gift beat (Kak Fajar's Terima Hadiah); nil = a sale beat
}

local BEATS: { Beat } = {
	{
		-- Kak Fajar's first visit: walking up starts it (no prompt). Gift bubble -> Terima Hadiah -> fade -> location bubble.
		kind = "gift",
		step = "kak_fajar",
		npc = "kak_fajar",
		name = "npc.kak_fajar",
		sold = function(guide: any): boolean
			return guide.rodGift == true
		end,
		greet = "tut.t1b.hadiah.1", -- naskah 1.4: line 1 (Next), then line 2 with the one button
		ask = "tut.t1b.hadiah.2",
		after = {},
	},
	{
		step = "panen_jual",
		npc = "pak_udin",
		name = "npc.pak_udin",
		sold = function(guide: any): boolean
			return guide.saleCutscene == true
		end,
		greet = "tut.t1.jual.1", -- naskah 1.3: 1 (Next), 2 = the sale question (Jual semua), then 3 and 4 (WARUNG)
		ask = "tut.t1.jual.2",
		after = WARUNG,
		ackStep = "warung",
	},
	{
		step = "jual_ikan",
		npc = "kak_fajar",
		name = "npc.kak_fajar",
		sold = function(guide: any): boolean
			return guide.fishSold == true
		end,
		greet = "tut.t1b.jual_ikan.1", -- naskah 1.5: one sequence, 1 (Next) -> 2 sale (Jual semua) -> 3 (Next) -> 4 (Ok)
		ask = "tut.t1b.jual_ikan.2",
		after = { "tut.t1b.jual_ikan.3" },
		afterChoice = "tut.t1b.jual_ikan.4", -- the closing bubble after the sale: "Ok, Kak Fajar" ends the tutorial part 1
		afterOk = "tut.t1b.ok_fajar",
		ackStep = "jual_ikan", -- the step is an ack: pressing Ok completes it (so Selesai comes after the button)
	},
}

local beatRan: { [string]: boolean } = {} -- a beat started in this session (a failed start clears it, to retry)

-- Anything in the Tas that this NPC buys (his buys are by item kind, Config/Npcs).
local function hasSellableFor(npcId: string): boolean
	local snap = State.current :: any
	local npc = Npcs.byId[npcId]
	if not snap or not snap.items or not npc then
		return false
	end
	for itemId, count in snap.items do
		if typeof(count) == "number" and count > 0 then
			local info = Items.info(itemId)
			if info and npc.buys[info.kind] ~= nil then
				return true
			end
		end
	end
	return false
end

local function npcHeadOf(npcId: string): BasePart?
	local npc = T1Dialog.NpcModel(npcId)
	local head = npc and npc:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

-- The beat due now: its step is live, the sale has not happened, the NPC buys something we carry, and the player is near.
-- Everything else (a panel open, a dialog running, the menu) holds it back without consuming it.
local function dueBeat(): Beat?
	if dialogBusy or not menuDone() or bigPanelOpen() then
		return nil
	end
	local guide = guideData()
	if not guide then
		return nil
	end
	local live = activeStepId(guide)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	for _, beat in BEATS do
		if live == beat.step and not beatRan[beat.step] and not beat.sold(guide) and (beat.kind == "gift" or hasSellableFor(beat.npc)) then
			local head = npcHeadOf(beat.npc)
			if head and (Vector3.new(head.Position.X, 0, head.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude <= SALE_BEAT_DISTANCE then
				return beat
			end
		end
	end
	return nil
end

-- The talk camera is the same one every NPC conversation uses (Cutscene.Begin -> NpcCamera.Shot): the camera glides from
-- where the player stands onto the over-the-shoulder shot of the NPC's face, the blur comes on, the player is held. Same as
-- Mak Sari's intro. The walk happens BEFORE that glide, with the normal camera, so the player is seen walking up to him.
local saleRestore: (() -> ())? = nil -- ends the beat's camera and hold (Cutscene.End); called on the normal end AND on an error

-- One bubble of an NPC beat with ONE button; waits until it is pressed.
local function beatChoice(name: string, npcRig: Model, text: string, label: string)
	local chosen = false
	local release = T1Dialog.Acquire(name, T1Dialog.BEAT) -- a beat: waits for the box, never over another line
	if not release then
		return
	end
	T1Dialog.Show({
		name = Locale.t(name),
		text = text,
		avatar = npcRig,
		showNext = false,
		bottom = TUTORIAL_BOTTOM,
		choices = {
			{
				text = label,
				onChoose = function()
					chosen = true
				end,
			},
		},
	})
	while not chosen do
		task.wait(0.05)
	end
	release()
end

-- One beat line with Next: waits for its turn at the box, then until the player presses Next.
local function lineNext(name: string, npcRig: Model, text: string)
	local pressed = false
	local release = T1Dialog.Acquire(name, T1Dialog.BEAT)
	if not release then
		return
	end
	T1Dialog.Show({
		name = Locale.t(name),
		text = text,
		avatar = npcRig,
		showNext = true,
		bottom = TUTORIAL_BOTTOM,
		onNext = function()
			pressed = true
		end,
	})
	while not pressed do
		task.wait(0.05)
	end
	release()
end

-- Kak Fajar's first visit (playtest 2026-11-22): walking up to him starts the beat, no prompt. The gift bubble has ONE
-- button (Terima Hadiah); then the gift is given and a fade ends the beat (no bubble after it).
local function runGiftBeat(beat: Beat, _guide: any)
	closeInstruction(false) -- a beat starts: the instruction minimizes, then the beat takes the box (owner rule)
	dialogBusy = true
	beatStep = beat.step
	player:SetAttribute("KTBeatBusy", true)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = npcHeadOf(beat.npc)
	local npc = head and head.Parent
	if not head or not npc or not npc:IsA("Model") or not root or not root:IsA("BasePart") or not humanoid then
		endBeat()
		beatRan[beat.step] = false -- not ready: try again on a later poll
		return
	end
	local npcRig: Model = npc
	local ended = false
	local endCutscene: (() -> ())? = nil
	local function restore()
		if ended then
			return
		end
		ended = true
		if endCutscene then
			endCutscene()
		end
		PromptGate.Show()
		T1Dialog.Hide()
		saleRestore = nil -- dialogBusy stays on: runGiftBeat releases it once the step has moved on
	end
	saleRestore = restore

	-- The prompt is hidden from the very first step of the walk (the "Ngobrol" prompt shows at 16 studs, the beat starts at
	-- 22): otherwise the player can press it while he is still walking in. Shown again in restore().
	PromptGate.Hide()

	-- 1. B-1 (playtest 2026-11-22): the beat starts on the trigger frame. The old walk (MoveTo a stand point 5 studs away,
	-- then up to 6 s of polling before Cutscene.Begin) was the delay. The player is already inside SALE_BEAT_RADIUS
	-- (dueBeat), so the hold starts now; only a player outside the radius is moved (PivotTo, as in runSaleBeat).
	local facing = npcRig:GetPivot().LookVector
	local front = Vector3.new(facing.X, 0, facing.Z).Unit
	local npcPos = head.Position
	local stand = npcPos + front * 5
	humanoid:MoveTo(root.Position)
	endCutscene = Cutscene.Begin(npcRig, head, true)
	beatLog("gift: Cutscene.Begin")
	local flatNow = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(npcPos.X, 0, npcPos.Z)).Magnitude
	if flatNow > SALE_BEAT_DISTANCE and character then
		character:PivotTo(CFrame.lookAt(Vector3.new(stand.X, root.Position.Y, stand.Z), Vector3.new(npcPos.X, root.Position.Y, npcPos.Z)))
	end
	task.wait(0.9)

	-- 2. He turns to the player, then the gift bubble (one button).
	local from = npcRig:GetPivot()
	local turnTo = CFrame.lookAt(from.Position, Vector3.new(root.Position.X, from.Position.Y, root.Position.Z))
	for step = 1, 8 do
		npcRig:PivotTo(from:Lerp(turnTo, step / 8))
		task.wait(0.04)
	end
	-- Naskah 1.4: line 1 (Next), then line 2 with the one button (Terima Hadiah).
	if beat.greet then
		lineNext(beat.name, npcRig, Locale.t(beat.greet, { name = player.DisplayName }))
	end
	beatChoice(beat.name, npcRig, Locale.t(beat.ask, { name = player.DisplayName }), Locale.t("dialog.receive_gift"))

	-- 3. The gift: the server gives the rod and the bait once. Then a fade (the hold comes back inside Transition).
	pcall(function()
		Net.Invoke("MeetFajar")
	end)
	Cutscene.Transition(function()
		T1Dialog.Hide()
	end)

	-- 4. The fade is the end of the gift beat. (Where to fish is said after the fish sale, not here.)
	restore()
	waitStepMoved(beat.step) -- the server has the gift (rodgift): the box is free only from here on
	endBeat()
end

local function runBeat(beat: Beat, guide: any)
	closeInstruction(false) -- a beat starts: the instruction minimizes, then the beat takes the box (owner rule)
	dialogBusy = true
	beatStep = beat.step -- Playtest 7 item 4: this step's line is not re-shown while the beat runs or until the step moves on
	player:SetAttribute("KTBeatBusy", true)
	if beat.step == "panen_jual" then
		-- Claimed right away: the sale inside this beat finishes T1 and starts T1b, and the plain warung beat would otherwise
		-- spawn on top of this one (its step "warung" reaches n == 0 while we are still waiting for the sale).
		warungStarted = true
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = npcHeadOf(beat.npc)
	local npc = head and head.Parent
	if not head or not npc or not npc:IsA("Model") or not root or not root:IsA("BasePart") or not humanoid then
		endBeat()
		beatRan[beat.step] = false -- not ready (streaming / respawn): try again on a later poll
		if beat.step == "panen_jual" then
			warungStarted = false
		end
		return
	end
	local npcRig: Model = npc
	local ended = false
	local function restore()
		if ended then
			return
		end
		ended = true
		Cutscene.End()
		PromptGate.Show()
		T1Dialog.Hide()
		saleRestore = nil -- dialogBusy stays on: runBeat releases it once the step has moved on
	end
	saleRestore = restore

	-- No "Ngobrol" prompt from the first step of the walk (see runGiftBeat): shown again in restore().
	PromptGate.Hide()

	-- 1. The wide shot starts at once (a cut, Bab 16.4 rebuild 2026-11-24): the player is LOCKED (Cutscene.Begin ->
	-- PlayerLock), the camera sits near the banyan so Pak Udin, his stall and the buildings are in frame.
	local facing = npcRig:GetPivot().LookVector
	local front = Vector3.new(facing.X, 0, facing.Z).Unit
	local npcPos = head.Position
	local stand = npcPos + front * 5
	local endCutscene = Cutscene.Begin(npcRig, head, true, SALE_WIDE_SHOT)
	beatLog("sale: Cutscene.Begin")
	saleRestore = function()
		endCutscene()
		PromptGate.Show()
		T1Dialog.Hide()
		dialogBusy = false
		saleRestore = nil
	end

	-- 2. The player runs into frame: MoveTo a stand point in front of the NPC (he cannot be out of the sell range). Waits for
	-- the arrival, at most 4 s; then the walk stops where he is.
	if humanoid then
		local arrived = false
		local arrivedConn = humanoid.MoveToFinished:Connect(function()
			arrived = true
		end)
		humanoid:MoveTo(Vector3.new(stand.X, root.Position.Y, stand.Z))
		local waitedWalk = 0
		while not arrived and waitedWalk < 4 do
			task.wait(0.1)
			waitedWalk += 0.1
		end
		arrivedConn:Disconnect()
		if not arrived then
			humanoid:MoveTo(root.Position)
		end
	end

	-- 3. The NPC turns to face the player (a short turn, the rig only: other players see the normal pose).
	local from = npcRig:GetPivot()
	local turnTo = CFrame.lookAt(from.Position, Vector3.new(root.Position.X, from.Position.Y, root.Position.Z))
	for step = 1, 8 do
		npcRig:PivotTo(from:Lerp(turnTo, step / 8))
		task.wait(0.04)
	end

	local function say(text: string, choices: { T1Dialog.Choice }?)
		local pressed = false
		local release = T1Dialog.Acquire(beat.name, T1Dialog.BEAT) -- a beat line: its turn at the box (Playtest 7, item 3)
		if not release then
			return
		end
		if choices then
			T1Dialog.Show({
				name = Locale.t(beat.name),
				text = text,
				avatar = npcRig,
				showNext = false,
				bottom = TUTORIAL_BOTTOM,
				choices = choices,
			})
			return -- the choice's pick hides the box, which gives the turn back
		end
		T1Dialog.Show({
			name = Locale.t(beat.name),
			text = text,
			avatar = npcRig,
			showNext = true,
			bottom = TUTORIAL_BOTTOM,
			onNext = function()
				pressed = true
			end,
		})
		while not pressed do
			task.wait(0.05)
		end
		release()
	end

	-- 4. Sapaan (Next), then the sale is a bubble choice.
	if beat.greet then
		say(Locale.t(beat.greet, { name = player.DisplayName }))
	end
	-- 5. The sale. A rejected sale (or a late save) shows the same bubble again: the beat never ends without the sale.
	local soldNow = false
	while not soldNow do
		local chosen = false
		say(Locale.t(beat.ask), {
			{
				text = Locale.t("tut.t1.s4_sell_all"),
				onChoose = function()
					chosen = true
				end,
			},
		})
		while not chosen do
			task.wait(0.05)
		end
		T1Dialog.Hide()
		Net.Send("Sell", beat.npc, "all")
		local waitedSale = 0
		while waitedSale < 3 do
			local snap = State.current :: any
			if snap and snap.guide and beat.sold(snap.guide) then
				break
			end
			task.wait(0.1)
			waitedSale += 0.1
		end
		local snapNow = State.current :: any
		soldNow = snapNow ~= nil and snapNow.guide ~= nil and beat.sold(snapNow.guide)
	end

	-- 6. The lines after the sale (Next after each; none for the fish), then the fade and the controls back.
	for _, line in beat.after do
		say(Locale.t(line))
	end
	if beat.afterChoice then
		beatChoice(beat.name, npcRig, Locale.t(beat.afterChoice), Locale.t(beat.afterOk or "tut.t1b.ok_fajar"))
	end
	T1Dialog.Hide()
	lastSpoken = ""
	-- Playtest 7 item 4: the ack goes to the server BEFORE the fade, so the fade covers the round trip.
	if beat.ackStep then
		guide.AckStep(beat.ackStep)
	end
	FadeManager.Play(function()
		restore()
	end)
	while FadeManager.IsPlaying() do
		task.wait(0.05)
	end
	-- The box stays busy until the server has moved the step on (no re-show of this beat's line meanwhile).
	waitStepMoved(beat.step)
	endBeat()
end

-- Poll -------------------------------------------------------------------------------------------------------------

-- Decides, once the guide state is known, whether the intro plays (it then waits for MenuFlow's PLAY).
local pendingSince = os.clock()

-- Pemicu adegan jual (Update owner playtest, item 1): dicek tiap frame di sisi klien (Heartbeat), tanpa polling.
local function tryStartBeat()
	if not guideModule or not tutorialPending() then
		return
	end
	-- JUAL PERTAMA (Bab 16.4): walking up to Pak Udin on the "panen_jual" step starts the beat.
	local due = if guideModule then dueBeat() else nil
	if due then
		beatRan[due.step] = true
		beatEnteredAt = os.clock() -- B-1: trigger frame (player inside SALE_BEAT_RADIUS)
		local guideRef = guideModule
		task.spawn(function()
			local ok, err = pcall(if due.kind == "gift" then runGiftBeat else runBeat, due, guideRef)
			if not ok then
				warn(`[T1Ghost] jual beat {due.step} failed: {err}`)
				if saleRestore then
					saleRestore() -- camera, GUIs and the lock back, whatever stage it died in
				end
				Cutscene.End()
				endBeat()
			end
		end)
	end
end

RunService.Heartbeat:Connect(tryStartBeat)

task.spawn(function()
	while true do
		local guide = guideData()
		if guide == nil then
			-- Still loading. Give up (and let the player in) if the snapshot never comes.
			if introState == "idle" and os.clock() - pendingSince > SNAPSHOT_WAIT then
				introState = "done"
			end
		else
			if t1Pending() then
				sessionTutorial = true
			end
			if introState == "idle" then
				if introEligible() then
					introState = "running"
					holdWelcomeModal(HOLD_SECONDS) -- before GuideController can open the welcome modal
					task.spawn(function()
						local ok, err = pcall(runIntro)
						if not ok then
							warn(`[T1Ghost] intro failed: {err}`)
							if introFinish then
								introFinish() -- unlock controls, give the camera back, close the UI
							end
							player:SetAttribute("KTIntroRunning", nil)
							releaseWelcomeModal()
							introState = "done"
						end
					end)
				else
					introState = "done" -- not a fresh T1: no intro
				end
			end

			if tutorialPending() then
				if introState ~= "running" then
					-- No intro (or it is over): she stands at the gate until the end of T1b, and speaks the tutorial.
					if not ghost then
						local spawnPos, dir, side = plotAxes()
						if spawnPos and dir and side then
							buildGhost(stationPosition(spawnPos, dir, side), spawnPos)
						end
					end
					ensureSink()
					-- A big panel (the shop, the bag, Atur ...) would be covered by the tutorial line: it steps aside while one is
					-- open and comes back when it closes. During a conversation with a town NPC the dialog box is the
					-- conversation's own: hands off (DialogueController closes it, then the line comes back here).
					if
						sinkSet
						and lastLine
						and not dialogBusy
						and menuDone()
						and player:GetAttribute("NpcTalkOpen") ~= true
						and not lineDismissed
					then
						if bigPanelOpen() then
							if T1Dialog.IsShown() then
								task.spawn(closeInstruction, false) -- minimizes, then gives the box back (the panel is open)
							end
						elseif not T1Dialog.IsShown() then
							showInstruction(lastLine, sinkKey) -- the same step's line, through the replaceable path
						end
					end
				end
				-- T1 is over (the sale): T1b starts, once.
				if
					isDone(guide, TUTORIAL_ID)
					and not isDone(guide, TUTORIAL_B_ID)
					and guide.step.id ~= TUTORIAL_B_ID
					and not t1bStartSent
				then
					t1bStartSent = true
					Net.Send("GuideEvent", "start", TUTORIAL_B_ID)
				end
				-- T1b's first beat: Pak Udin at the warung.
				if guideModule and not warungStarted then
					local id, n = guideModule.Current()
					if id == TUTORIAL_B_ID and n == 0 then
						warungStarted = true
						task.spawn(function()
							local ok, err = pcall(runWarung, guideModule)
							if not ok then
								warn(`[T1Ghost] warung dialog failed: {err}`)
								-- A failed beat must not leave the camera on the NPC or the controls off.
								Cutscene.End()
								dialogBusy = false
							end
						end)
					end
				end
			elseif introState ~= "running" then
				-- Nothing pending (T1b done, or this save finished the tutorials long ago).
				destroyGhost()
				clearSink()
			end
		end
		task.wait(POLL_SECONDS)
	end
end)
