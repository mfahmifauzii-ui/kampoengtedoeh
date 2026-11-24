--!strict
-- A scripted beat with an NPC (T1b's warung beat, and the first sale's cutscene): the player is held still and the camera
-- takes over. Two shots:
--   * talk (default): the same over-the-shoulder shot and blur as any talk (NpcCamera.Shot), glided onto from the player's view.
--   * wide (Jual Pertama, Bab 16.4): a fixed camera near the banyan tree (NpcCamera.Wide), a cut, no blur, so Pak Udin, his
--     stall and the buildings read. Glide from the avatar's own camera is avoided: it passes through the player's hair.
-- Client only.
--
--   Cutscene.Begin(npc, head, interactive?, wide?)  player held still, camera taken. Returns End for THIS beat only.
--   Cutscene.Transition(onBlack)  fades (FadeManager) with onBlack run while the screen is dark, waits until it is clear,
--                                 and keeps the player held after it. FadeManager releases the hold at the end of every
--                                 fade, so it is taken again in the same step (onDone), before anything can move.
--   Cutscene.End()                camera back to the player (NpcCamera.ReturnToPlayer, K-107), the hold released, blur off.
--                                 Safe to call twice.
--
-- Rules (roblox-camera): the camera is driven in RunService.PreRender; one owner at a time (`owner`, a new Begin ends the old
-- beat; a stale End does nothing); nothing is snapshotted: the end gives the camera back from the current character (K-107);
-- the beat ends on CharacterRemoving (respawn).
-- WalkSpeed and JumpPower are NOT touched here: the hold is PlayerLock's, and PlayerLock snapshots and restores them.
-- The hold itself is PlayerLock's (PlayerModule when the place has it, else the humanoid).
-- Rollback: delete this module and the calls in T1Ghost.client (runWarung).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Onboarding = require(game:GetService("ReplicatedStorage").Shared.Config.Onboarding)
local FadeManager = require(script.Parent.FadeManager)
local NpcCamera = require(script.Parent.NpcCamera)
local PlayerLock = require(script.Parent.PlayerLock)
local PromptGate = require(script.Parent.PromptGate)

local Cutscene = {}

local player = Players.LocalPlayer
local held = false -- true from Begin until End: the player stays held still
local owner: {}? = nil -- the token of the beat that owns the camera and the hold; nil = no beat
local camConn: RBXScriptConnection? = nil
local removingConn: RBXScriptConnection? = nil
local cameraTaken = false
local beatStartedAt: number? = nil -- os.clock() at Begin: the Bab 16.2 length check (<= Onboarding.CUTSCENE_MAX_SECONDS)
-- Bab 16.4 (v7.4): the Jual Pertama beat waits for the player (he reads the lines and sells at his own pace), so its
-- length is not a cutscene length in the sense of Bab 16.2 and is not checked. Every timed beat still is.
local untimed = false

-- Keeps the player held (used after a fade, which releases it). Does nothing outside a beat.
function Cutscene.Relock()
	if held then
		PlayerLock.Set(true)
	end
end

-- Holds the player and takes the camera for the beat. head: the NPC's head part (the talk shot is aimed at it).
-- interactive: this beat waits for the player, so the Bab 16.2 length check does not apply to it (see `untimed`).
-- wide: the fixed camera of the Jual Pertama beat { eye, focus } (see NpcCamera.Wide); nil = the talk shot.
-- Safety net (2026-11-23): an untimed beat waits for the player; it must not hold his movement for longer than this.
-- After it, the hold is released (the beat itself stays; only the movement comes back).
local UNTIMED_RELEASE_SECONDS = 60

function Cutscene.Begin(npc: Model, head: BasePart, interactive: boolean?, wide: { eye: Vector3, focus: Vector3 }?): () -> ()
	if owner then
		Cutscene.End() -- one owner: a new beat takes the camera and the hold from the old one
	end
	local token = {}
	owner = token
	local camera = Workspace.CurrentCamera :: Camera
	local character = player.Character
	held = true
	untimed = interactive == true
	beatStartedAt = os.clock()
	PlayerLock.Set(true)
	if untimed then
		local startedAt = beatStartedAt
		task.delay(UNTIMED_RELEASE_SECONDS, function()
			if held and beatStartedAt == startedAt then
				held = false
				PlayerLock.Set(false)
			end
		end)
	end
	-- Playtest 2026-11-22: no "Ngobrol" / nameplate prompt over a cutscene. Back on in End().
	PromptGate.Hide()

	local ignore: { Instance } = { npc }
	if character then
		table.insert(ignore, character)
	end
	local goal: CFrame
	local fov: number
	if wide then
		goal = NpcCamera.Wide(wide.eye, wide.focus, ignore)
		fov = NpcCamera.WIDE_FOV
	else
		local focusDistance: number
		goal, focusDistance = NpcCamera.Shot(head.Position, character, { npc })
		fov = NpcCamera.FOV
		NpcCamera.SetBlur(true, focusDistance)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	cameraTaken = true
	if wide then
		camera.CFrame = goal -- a cut: the wide shot is in place on the first frame
		camera.FieldOfView = fov
	end
	-- PreRender: the camera is set after the character's own update, every frame, so nothing moves it back.
	camConn = RunService.PreRender:Connect(function(dt: number)
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		local alpha = if wide then 1 else 1 - math.exp(-dt * 4)
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)
		camera.FieldOfView += (fov - camera.FieldOfView) * alpha
	end)
	-- Respawn / character removal: the beat ends here, the camera and the hold go back before the new character spawns.
	removingConn = player.CharacterRemoving:Connect(function()
		if owner == token then
			Cutscene.End()
		end
	end)
	return function()
		if owner == token then
			Cutscene.End()
		end
	end
end

function Cutscene.End()
	owner = nil
	if beatStartedAt and untimed then
		beatStartedAt = nil
		untimed = false
	elseif beatStartedAt then
		-- Bab 16.2: a cutscene is at most 6 s. Log only (no UI): a beat that runs long shows up in the output.
		local took = os.clock() - beatStartedAt
		beatStartedAt = nil
		if took > Onboarding.CUTSCENE_MAX_SECONDS then
			warn(`[Cutscene] {math.floor(took * 10) / 10} s, lebih dari {Onboarding.CUTSCENE_MAX_SECONDS} s (Bab 16.2)`)
		else
			print(`[Cutscene] {math.floor(took * 10) / 10} s (batas {Onboarding.CUTSCENE_MAX_SECONDS} s)`)
		end
	end
	if camConn then
		camConn:Disconnect()
		camConn = nil
	end
	if removingConn then
		removingConn:Disconnect()
		removingConn = nil
	end
	if cameraTaken then
		cameraTaken = false
		-- K-107: back to the player's camera from the current character, never a saved type or FOV (see NpcCamera.ReturnToPlayer).
		NpcCamera.ReturnToPlayer()
	end
	if held then
		held = false
		PlayerLock.Set(false)
		PromptGate.Show()
	end
end

-- Yields until the fade is over. The hold is released by FadeManager and taken back in the same step (onDone), so the
-- player never gets a free frame during the dissolve.
function Cutscene.Transition(onBlack: () -> ())
	local finished = false
	FadeManager.Play(onBlack, function()
		Cutscene.Relock()
		finished = true
	end)
	while not finished do
		task.wait(0.05)
	end
end

return Cutscene
