--!strict
-- Central fade for the moments the plan calls a "transition": after a talk ends, into and out of a cutscene, between tutorial
-- phases. Nothing else fades (ordinary interactions never do). One ScreenGui for the whole game, so no NPC or feature draws its own.
--
-- Sequence (Plan v3 section 3.1): black fades in 0.3 s, holds 0.15 s (the optional onBlack runs here, while the screen is dark),
-- then dissolves out 0.5 s. Player controls are disabled for the whole run and turned back on at the end, so a fade can never
-- leave the player frozen: the finally-style cleanup always runs.
--
-- Client only. Rollback: delete this module and the two Play() calls in DialogueController.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PlayerLock = require(script.Parent.PlayerLock)
local UiKit = require(script.Parent.UiKit)

local FadeManager = {}

local FADE_IN = 0.3
local HOLD = 0.15
local DISSOLVE_OUT = 0.5

local player = Players.LocalPlayer
local cover: Frame? = nil
local running = 0 -- how many Play() calls are still in progress (overlapping calls share one cover)

local function ensure(): Frame
	local existing = cover
	if existing then
		return existing
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = "FadeManager"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = UiKit.LAYER.FADE -- 150: above the dialogue box (120) and the cutscene bars
	screen.Enabled = true
	local frame = Instance.new("Frame")
	frame.Name = "Black"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screen
	screen.Parent = player:WaitForChild("PlayerGui")
	cover = frame
	return frame
end

-- The player's movement is held by PlayerLock (PlayerModule when the place has it, else the humanoid). Called directly, NOT
-- in a spawned thread: a deferred release ran after onDone's Cutscene.Relock and left the player unlocked during a cutscene
-- (IsLocked false while held). PlayerLock.Set never yields, so a fade does not wait on it.
local function setControls(enabled: boolean)
	PlayerLock.Set(not enabled)
end

-- Plays the fade. onBlack (optional) runs while the screen is fully dark, for example to open the shop the talk led to.
-- onDone (optional) runs after the screen is clear again. Returns immediately; the sequence runs in its own thread.
--
-- Timing comes from task.wait, not from the tween's Completed event: the steps happen on time even if a tween does not
-- report back (a stalled tween must never leave the screen black or the controls locked). The release at the end always runs.
function FadeManager.Play(onBlack: (() -> ())?, onDone: (() -> ())?)
	local frame = ensure()
	running += 1
	if running == 1 then
		setControls(false)
	end
	frame.Visible = true

	task.spawn(function()
		local ok, err = pcall(function()
			local fadeIn =
				TweenService:Create(frame, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					BackgroundTransparency = 0,
				})
			fadeIn:Play()
			task.wait(FADE_IN)

			if onBlack then
				local okBlack, errBlack = pcall(onBlack)
				if not okBlack then
					warn(`[FadeManager] onBlack failed: {errBlack}`)
				end
			end
			task.wait(HOLD)

			local dissolve = TweenService:Create(
				frame,
				TweenInfo.new(DISSOLVE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					BackgroundTransparency = 1,
				}
			)
			dissolve:Play()
			task.wait(DISSOLVE_OUT)
		end)
		if not ok then
			warn(`[FadeManager] fade failed: {err}`)
		end

		-- Always runs, even after an error: the cover is cleared and the controls come back when the last fade ends.
		running = math.max(running - 1, 0)
		if running == 0 then
			frame.BackgroundTransparency = 1
			frame.Visible = false
			setControls(true)
		end
		if onDone then
			local okDone, errDone = pcall(onDone)
			if not okDone then
				warn(`[FadeManager] onDone failed: {errDone}`)
			end
		end
	end)
end

-- True while a fade is running (so a caller can wait, or skip a second fade).
function FadeManager.IsPlaying(): boolean
	return running > 0
end

return FadeManager
