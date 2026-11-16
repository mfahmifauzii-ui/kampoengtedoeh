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
	screen.DisplayOrder = 150 -- above the dialogue box (120) and the cutscene bars, below nothing that the player should see
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

local function setControls(enabled: boolean)
	pcall(function()
		local scripts = player:WaitForChild("PlayerScripts", 5)
		local module = scripts and scripts:WaitForChild("PlayerModule", 5)
		if not module then
			return
		end
		local controls = (require(module :: ModuleScript) :: any):GetControls()
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end)
end

-- Plays the fade. onBlack (optional) runs while the screen is fully dark, for example to open the shop the talk led to.
-- onDone (optional) runs after the screen is clear again. Returns immediately; the sequence runs in its own thread.
function FadeManager.Play(onBlack: (() -> ())?, onDone: (() -> ())?)
	local frame = ensure()
	running += 1
	if running == 1 then
		setControls(false)
	end
	frame.Visible = true

	task.spawn(function()
		local fadeIn =
			TweenService:Create(frame, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 0,
			})
		fadeIn:Play()
		fadeIn.Completed:Wait()

		if onBlack then
			local ok, err = pcall(onBlack)
			if not ok then
				warn(`[FadeManager] onBlack failed: {err}`)
			end
		end
		task.wait(HOLD)

		local dissolve =
			TweenService:Create(frame, TweenInfo.new(DISSOLVE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			})
		dissolve:Play()
		dissolve.Completed:Wait()

		running -= 1
		if running <= 0 then
			running = 0
			frame.Visible = false
			setControls(true)
		end
		if onDone then
			local ok, err = pcall(onDone)
			if not ok then
				warn(`[FadeManager] onDone failed: {err}`)
			end
		end
	end)
end

-- True while a fade is running (so a caller can wait, or skip a second fade).
function FadeManager.IsPlaying(): boolean
	return running > 0
end

return FadeManager
