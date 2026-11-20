--!strict
-- A scripted beat with an NPC (T1b's warung beat, and the first sale's cutscene): the player is held still and the camera
-- sits on the NPC's face, the same over-the-shoulder shot and blur as any talk (NpcCamera). Client only.
--
--   Cutscene.Begin(npc, head)     player held still, camera on the NPC. Returns End; End ALWAYS runs (a finally-style cleanup).
--   Cutscene.Transition(onBlack)  fades (FadeManager) with onBlack run while the screen is dark, waits until it is clear,
--                                 and keeps the player held after it. FadeManager releases the hold at the end of every
--                                 fade, so it is taken again in the same step (onDone), before anything can move.
--   Cutscene.End()                camera back to the player, the hold released, blur off.
--
-- The hold itself is PlayerLock's (PlayerModule when the place has it, else the humanoid).
-- Rollback: delete this module and the calls in T1Ghost.client (runWarung).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Onboarding = require(game:GetService("ReplicatedStorage").Shared.Config.Onboarding)
local FadeManager = require(script.Parent.FadeManager)
local NpcCamera = require(script.Parent.NpcCamera)
local PlayerLock = require(script.Parent.PlayerLock)

local Cutscene = {}

local player = Players.LocalPlayer
local held = false -- true from Begin until End: the player stays held still
local camConn: RBXScriptConnection? = nil
local cameraTaken = false
local savedFov = 70
local beatStartedAt: number? = nil -- os.clock() at Begin: the Bab 16.2 length check (<= Onboarding.CUTSCENE_MAX_SECONDS)

-- Keeps the player held (used after a fade, which releases it). Does nothing outside a beat.
function Cutscene.Relock()
	if held then
		PlayerLock.Set(true)
	end
end

-- Holds the player and takes the camera for the beat. head: the NPC's head part (the shot is aimed at it).
function Cutscene.Begin(npc: Model, head: BasePart): () -> ()
	local camera = Workspace.CurrentCamera :: Camera
	local character = player.Character
	held = true
	beatStartedAt = os.clock()
	PlayerLock.Set(true)

	local cf, focusDistance = NpcCamera.Shot(head.Position, character, { npc })
	savedFov = camera.FieldOfView
	camera.CameraType = Enum.CameraType.Scriptable
	cameraTaken = true
	NpcCamera.SetBlur(true, focusDistance)
	camConn = RunService.RenderStepped:Connect(function(dt: number)
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		local alpha = 1 - math.exp(-dt * 4)
		camera.CFrame = camera.CFrame:Lerp(cf, alpha)
		camera.FieldOfView += (NpcCamera.FOV - camera.FieldOfView) * alpha
	end)
	return Cutscene.End
end

function Cutscene.End()
	if beatStartedAt then
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
	if cameraTaken then
		cameraTaken = false
		NpcCamera.SetBlur(false)
		local camera = Workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			camera.FieldOfView = savedFov
		end
	end
	if held then
		held = false
		PlayerLock.Set(false)
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
