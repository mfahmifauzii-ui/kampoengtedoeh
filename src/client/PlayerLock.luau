--!strict
-- Takes the player's movement away for a moment (a fade, a cutscene, fishing) and gives it back. Client only.
--
-- B-4: counter, not a flag. Every system takes its own hold and releases its own hold:
--   local release = PlayerLock.Acquire("fishing")            -- or Acquire("fishing", true) = humanoid-only (camera stays free)
--   ...
--   release()                                                -- idempotent; the player is free again only when EVERY hold is released
-- Set(true) / Set(false) keep the old API for Cutscene, BannerController and FadeManager: they are one hold named "legacy".
--
-- Two ways, the first that works (only when no hold asks for humanoid-only):
--   1. PlayerModule (PlayerScripts): GetControls():Disable() / Enable(). This is the normal way.
--   2. Humanoid: WalkSpeed and JumpPower go to 0 and AutoRotate off, and are put back as they were when the last hold
--      is released. The values are captured per character, so a respawn while held is handled (CharacterAdded).
-- The module is looked up once; a missing module is logged once.

local Players = game:GetService("Players")

local PlayerLock = {}

local player = Players.LocalPlayer
local controls: any = nil -- found in the background at load (see below); nil = use the humanoid
local holds: { [string]: boolean } = {} -- reason -> humanoidOnly; the set of current holds
local holdCount = 0
local lockedVia: string = "" -- "controls" | "humanoid" | "": how the current lock is applied
local saved: { humanoid: Humanoid, walk: number, jump: number, rotate: boolean }? = nil
local DEFAULT_WALK_SPEED = 16 -- Roblox default, used when the humanoid is already at 0 (see lockHumanoid)
local DEFAULT_JUMP_POWER = 50
local nextToken = 0

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
	-- The values to give back. A 0 here is never a real "normal" speed (it is what a lock leaves behind), so the Roblox
	-- defaults are used instead: otherwise the player stays stuck at WalkSpeed 0 after the unlock.
	local walk = humanoid.WalkSpeed
	if walk <= 0 then
		walk = DEFAULT_WALK_SPEED
	end
	local jump = humanoid.JumpPower
	if jump <= 0 then
		jump = DEFAULT_JUMP_POWER
	end
	saved = { humanoid = humanoid, walk = walk, jump = jump, rotate = humanoid.AutoRotate }
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

-- Applies the lock that the current holds ask for. Called on every change and on every new character.
local function apply()
	local wantHumanoidOnly = true
	local wanted = holdCount > 0
	for _, humanoidOnly in holds do
		if not humanoidOnly then
			wantHumanoidOnly = false
		end
	end
	local via = if not wanted then "" elseif controls and not wantHumanoidOnly then "controls" else "humanoid"
	if via == lockedVia then
		if via == "humanoid" and wanted then
			lockHumanoid() -- still locked, but a new character may have arrived: lockHumanoid does nothing if saved is current
		end
		return
	end
	-- Release the old way first.
	if lockedVia == "controls" then
		pcall(function()
			controls:Enable()
		end)
	elseif lockedVia == "humanoid" then
		unlockHumanoid()
	end
	lockedVia = via
	-- Take the new way.
	if via == "controls" then
		pcall(function()
			controls:Disable()
		end)
	elseif via == "humanoid" then
		lockHumanoid()
	end
end

-- One hold. The returned function releases exactly this hold (a second call does nothing).
function PlayerLock.Acquire(reason: string, humanoidOnly: boolean?): () -> ()
	nextToken += 1
	local key = `{reason}#{nextToken}`
	holds[key] = humanoidOnly == true
	holdCount += 1
	apply()
	local released = false
	return function()
		if released then
			return
		end
		released = true
		holds[key] = nil
		holdCount -= 1
		apply()
	end
end

-- Old API: one hold named "legacy". Set(true) twice takes it once; Set(false) with nothing held does nothing.
local legacyRelease: (() -> ())? = nil
function PlayerLock.Set(on: boolean)
	if on then
		if not legacyRelease then
			legacyRelease = PlayerLock.Acquire("legacy")
		end
	elseif legacyRelease then
		local release = legacyRelease
		legacyRelease = nil
		release()
	end
end

-- True while at least one hold is active.
function PlayerLock.IsLocked(): boolean
	return holdCount > 0
end

-- A new character while held: the humanoid is new, so the lock is taken again on it (B-4: respawn while fishing).
player.CharacterAdded:Connect(function()
	saved = nil
	if holdCount > 0 and lockedVia == "humanoid" then
		task.defer(function()
			if holdCount > 0 and lockedVia == "humanoid" then
				lockHumanoid()
			end
		end)
	end
end)

return PlayerLock
