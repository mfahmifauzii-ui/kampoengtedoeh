--!strict
-- A scripted beat with an NPC (T1b's warung beat, and the first sale's cutscene): the player's controls are off and the camera
-- sits on the NPC's face, the same over-the-shoulder shot and blur as any talk (NpcCamera). Client only.
--
--   Cutscene.Begin(npc, head)     controls off, camera on the NPC. Returns End; End ALWAYS runs (a finally-style cleanup).
--   Cutscene.Transition(onBlack)  fades (FadeManager) with onBlack run while the screen is dark, waits until it is clear,
--                                 and keeps the controls off after it. FadeManager gives the controls back at the end of
--                                 every fade, so the release happens in the same step (onDone), before anything can move.
--   Cutscene.End()                camera back to the player, controls back on, blur off.
--
-- Rollback: delete this module and the calls in T1Ghost.client (runWarung).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FadeManager = require(script.Parent.FadeManager)
local NpcCamera = require(script.Parent.NpcCamera)

local Cutscene = {}

local player = Players.LocalPlayer
local controls: any = nil -- the player's controls, held while a beat is on (nil = none)
local locked = false -- true from Begin until End: the controls stay off
local camConn: RBXScriptConnection? = nil
local cameraTaken = false
local savedFov = 70

local function getControls(): any
	local ok, value = pcall(function()
		local playerScripts = player:WaitForChild("PlayerScripts", 5)
		local module = playerScripts and playerScripts:WaitForChild("PlayerModule", 5)
		return if module then (require(module :: ModuleScript) :: any):GetControls() else nil
	end)
	return if ok then value else nil
end

local function disableControls()
	pcall(function()
		if controls then
			controls:Disable()
		end
	end)
end

-- Keeps the controls off (used after a fade, which gives them back). Does nothing outside a beat.
function Cutscene.Relock()
	if locked then
		disableControls()
	end
end

-- Takes the controls and the camera for the beat. head: the NPC's head part (the shot is aimed at it).
function Cutscene.Begin(npc: Model, head: BasePart): () -> ()
	local camera = Workspace.CurrentCamera :: Camera
	local character = player.Character
	controls = getControls()
	locked = true
	disableControls()

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
	if locked then
		locked = false
		if controls then
			pcall(function()
				controls:Enable()
			end)
		end
	end
	controls = nil
end

-- Yields until the fade is over. The controls are released by FadeManager and taken back in the same step (onDone), so the
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
