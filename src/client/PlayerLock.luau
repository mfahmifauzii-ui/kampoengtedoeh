--!strict
-- Takes the player's movement away for a moment (a fade, a cutscene) and gives it back. Client only.
--
-- Set(true): the player's controls off. Set(false): on again. Calls are idempotent: a second Set(true) changes nothing, and
-- Set(false) with nothing locked does nothing.
--
-- Two ways, the first that works:
--   1. PlayerModule (PlayerScripts): GetControls():Disable() / Enable(). This is the normal way.
--   2. Humanoid fallback: when the place has no PlayerModule (this happened in Studio: StarterPlayerScripts had none), the
--      humanoid's WalkSpeed and JumpPower go to 0 and AutoRotate off, and are put back as they were.
-- The module is looked up once; a missing module is logged once.

local Players = game:GetService("Players")

local PlayerLock = {}

local player = Players.LocalPlayer
local controls: any = nil -- found in the background at load (see below); nil = use the humanoid
local locked = false
local lockedVia: string = "" -- "controls" | "humanoid": the way the current lock was taken (the release uses the same)
local saved: { humanoid: Humanoid, walk: number, jump: number, rotate: boolean }? = nil

-- Looked up in its own thread, so requiring this module never yields. Until it is found, locks use the humanoid.
task.spawn(function()
	local ok, value = pcall(function()
		local scripts = player:WaitForChild("PlayerScripts", 5)
		local module = scripts and scripts:WaitForChild("PlayerModule", 5)
		return if module then (require(module :: ModuleScript) :: any):GetControls() else nil
	end)
	if ok and value then
		controls = value
	else
		warn("[PlayerLock] PlayerModule not found: using the humanoid to hold the player still")
	end
end)

local function lockHumanoid()
	if saved then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	saved = { humanoid = humanoid, walk = humanoid.WalkSpeed, jump = humanoid.JumpPower, rotate = humanoid.AutoRotate }
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
end

local function unlockHumanoid()
	local s = saved
	saved = nil
	if s and s.humanoid.Parent then
		s.humanoid.WalkSpeed = s.walk
		s.humanoid.JumpPower = s.jump
		s.humanoid.AutoRotate = s.rotate
	end
end

function PlayerLock.Set(on: boolean)
	if on == locked then
		return
	end
	locked = on
	if on then
		if controls then
			lockedVia = "controls"
			pcall(function()
				controls:Disable()
			end)
		else
			lockedVia = "humanoid"
			lockHumanoid()
		end
	elseif lockedVia == "controls" then
		lockedVia = ""
		pcall(function()
			controls:Enable()
		end)
	else
		lockedVia = ""
		unlockHumanoid()
	end
end

-- True while the player is held still by Set(true).
function PlayerLock.IsLocked(): boolean
	return locked
end

return PlayerLock
