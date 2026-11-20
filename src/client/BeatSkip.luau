--!strict
-- Lewati for scripted beats (T-45, Bab 16.2 v6.2.3): the NPC lines and cutscenes of a tutorial beat (T1Ghost intro and
-- warung beats, the first-sale cutscene, the pond talk). One button, top right under Settings, 52 px tall (above 48 dp),
-- no confirm popup. Pressing it sets BeatSkip.Requested: every wait in the beat returns at once and the remaining speech
-- is not shown. The beat's own end effects still run (for example the first sale is already paid on the server), and
-- the tutorial step still completes only when its own condition holds (Bab 16.2: nothing is skipped on the server).
--
--   BeatSkip.Begin(tutorialId)   show the button and clear the flag (call when the beat starts)
--   BeatSkip.End()               hide the button (call when the beat ends, also after an error)
--   BeatSkip.Requested           true after Lewati: the beat's waits return immediately
--
-- The server gets one analytics event ("beatskip") so the funnel shows how often beats are skipped. It never changes state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.UiKit)

local player = Players.LocalPlayer

local BeatSkip = {}
BeatSkip.Requested = false

local gui: ScreenGui? = nil
local button: TextButton? = nil
local activeTutorial: string? = nil

local function build()
	if gui then
		return
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = "BeatSkip"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 8
	screen.Enabled = false
	screen.Parent = player:WaitForChild("PlayerGui")
	local skip = UiKit.button(screen, "BeatSkipButton", Locale.t("tut.skip"), UiKit.BUTTON_MUTED)
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -16, 0, 84)
	skip.Size = UDim2.fromOffset(150, 52)
	skip.Activated:Connect(function()
		if BeatSkip.Requested then
			return
		end
		BeatSkip.Requested = true
		skip.Visible = false
		Net.Send("GuideEvent", "beatskip", activeTutorial or "", 0)
	end)
	gui = screen
	button = skip
end

function BeatSkip.Begin(tutorialId: string?)
	build()
	activeTutorial = tutorialId
	BeatSkip.Requested = false
	if button then
		button.Visible = true
	end
	if gui then
		gui.Enabled = true
	end
end

function BeatSkip.End()
	activeTutorial = nil
	if gui then
		gui.Enabled = false
	end
	BeatSkip.Requested = false
end

return BeatSkip
