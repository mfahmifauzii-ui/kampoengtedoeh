--!strict
-- Genshin-style chapter banner (owner, 2026-11-22): "Selesai" when a tutorial is finished, "Dimulai" when a quest starts.
-- Mechanic (as in the reference): two black bars slide in across the screen, a gold title and a small subtitle fade in in
-- the middle, the player cannot move for the banner's few seconds, then the bars slide out. Shows once per event, queued
-- so two events in a row play one after the other. It never plays on the first snapshot of a save (no event happened).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local State = require(script.Parent.Parent.State)
local PlayerLock = require(script.Parent.Parent.PlayerLock)
local UiKit = require(script.Parent.Parent.UiKit)
local FadeManager = require(script.Parent.Parent.FadeManager)
local T1Dialog = require(script.Parent.Parent.T1Dialog)

local player = Players.LocalPlayer
local HOLD_SECONDS = 2.8 -- how long the player is held and the title stays up
local BAR_SECONDS = 0.45 -- the bars slide in / out

local BannerController = {}

local queue: { { title: string, subtitle: string } } = {}
local playing = false
local seenDone: { [string]: boolean } = {}
local seenQuests: { [string]: boolean } = {}
local seenQuestDone: { [string]: boolean } = {}

-- Playtest item 6: only MAIN quests get the Dimulai / Selesai banner (and its short lock). Side quests get the tracker row and
-- the small toast that the server already sends (quest.new / quest.done).
local function isMain(id: string): boolean
	local quest = Quests.byId[id]
	return quest ~= nil and quest.kind == "main"
end
local initialized = false

local function build(): (ScreenGui, Frame, Frame, TextLabel, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChapterBanner"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = UiKit.LAYER.BANNER -- 80: above the panels (40) and the HUD (20), GUI doc 4.5
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local top = Instance.new("Frame")
	top.Name = "BarTop"
	top.BackgroundColor3 = Color3.fromRGB(10, 8, 6)
	top.BorderSizePixel = 0
	top.Size = UDim2.fromScale(1, 0.2)
	top.Position = UDim2.fromScale(0, -0.2)
	top.Parent = gui

	local bottom = Instance.new("Frame")
	bottom.Name = "BarBottom"
	bottom.BackgroundColor3 = Color3.fromRGB(10, 8, 6)
	bottom.BorderSizePixel = 0
	bottom.Size = UDim2.fromScale(1, 0.2)
	bottom.Position = UDim2.fromScale(0, 1)
	bottom.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 56)
	title.Position = UDim2.new(0, 0, 0.5, -34)
	title.Font = UiKit.FONT
	title.TextSize = 44
	title.TextColor3 = Color3.fromRGB(255, 226, 120)
	title.TextStrokeTransparency = 0.3
	title.TextTransparency = 1
	title.Text = ""
	title.Parent = gui

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.new(1, 0, 0, 24)
	subtitle.Position = UDim2.new(0, 0, 0.5, 26)
	subtitle.Font = UiKit.FONT
	subtitle.TextSize = 17
	subtitle.TextColor3 = Color3.fromRGB(240, 232, 214)
	subtitle.TextTransparency = 1
	subtitle.Text = ""
	subtitle.Parent = gui

	return gui, top, bottom, title, subtitle
end

local function tweenTo(object: Instance, props: { [string]: any }, seconds: number)
	local tween = TweenService:Create(object, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function playOne(entry: { title: string, subtitle: string })
	local gui, top, bottom, title, subtitle = build()
	title.Text = entry.title
	subtitle.Text = entry.subtitle
	gui.Enabled = true
	UiKit.hideOthers(gui) -- Bug 7: the HUD, tracker, buttons and bubbles go away while the banner shows
	PlayerLock.Set(true)

	tweenTo(top, { Position = UDim2.fromScale(0, 0) }, BAR_SECONDS)
	tweenTo(bottom, { Position = UDim2.fromScale(0, 0.8) }, BAR_SECONDS)
	task.wait(BAR_SECONDS * 0.6)
	tweenTo(title, { TextTransparency = 0 }, 0.4)
	task.wait(0.3)
	tweenTo(subtitle, { TextTransparency = 0 }, 0.4)
	task.wait(HOLD_SECONDS)

	tweenTo(title, { TextTransparency = 1 }, 0.3)
	tweenTo(subtitle, { TextTransparency = 1 }, 0.3)
	tweenTo(top, { Position = UDim2.fromScale(0, -0.2) }, BAR_SECONDS)
	tweenTo(bottom, { Position = UDim2.fromScale(0, 1) }, BAR_SECONDS)
	task.wait(BAR_SECONDS)
	PlayerLock.Set(false)
	UiKit.restoreOthers() -- exactly what was on before (counter: the last banner in a queue restores)
	gui:Destroy()
end

local function push(title: string, subtitle: string)
	table.insert(queue, { title = title, subtitle = subtitle })
	if playing then
		return
	end
	playing = true
	task.spawn(function()
		while #queue > 0 do
			local entry = table.remove(queue, 1)
			local ok, err = pcall(playOne, entry :: any)
			if not ok then
				warn(`[ChapterBanner] {err}`)
				PlayerLock.Set(false)
			end
		end
		playing = false
	end)
end

-- Playtest 7 item 4: "Selesai" waits until the Ok fade is over and the dialog box is empty (the last line of a beat is gone).
-- Gives up after 20 s so the banner cannot be lost.
local function pushWhenClear(title: string, subtitle: string)
	task.spawn(function()
		local waited = 0
		while waited < 20 and (player:GetAttribute("KTBeatBusy") == true or FadeManager.IsPlaying() or T1Dialog.IsShown()) do
			task.wait(0.2)
			waited += 0.2
		end
		push(title, subtitle)
	end)
end

local function onSnapshot(snapshot: any)
	local guide = snapshot and snapshot.guide
	local quests = snapshot and snapshot.quests
	if not guide or not quests then
		return
	end
	local doneNow: { [string]: boolean } = {}
	for id, value in guide.done do
		if value == true then
			doneNow[id] = true
		end
	end
	local activeNow: { [string]: boolean } = {}
	for id in quests.active do
		activeNow[id] = true
	end

	if initialized then
		-- A tutorial that just finished: "Selesai" with its title.
		-- Playtest 2026-11-22: "Selesai" is for the whole first-loop tutorial (T1b, ends after the fish sale to Kak Fajar),
		-- not after T1 (the harvest sale to Pak Udin is only a step of it).
		for _, tutorial in Onboarding.TUTORIALS do
			if tutorial.id == "t1b_kolam" and doneNow[tutorial.id] and not seenDone[tutorial.id] then
				pushWhenClear(Locale.t("banner.done"), Locale.t(tutorial.title))
			end
		end
		-- A quest that just started: "Dimulai" with its title. Held while a tutorial is running (guide.step.id set): the
		-- banner waits until the tutorial's talk is over, and then shows once (seenQuests is not updated for it yet).
		local tutorialRunning = guide.step ~= nil and guide.step.id ~= ""
		for id in activeNow do
			if not seenQuests[id] and not tutorialRunning and isMain(id) then
				local key = `quest.{id}.title`
				push(Locale.t("banner.started"), Locale.t(key))
			end
		end
	end
	seenDone = doneNow
	-- Main quest finished: "Selesai" with its title (side quests: toast only).
	local doneQuestNow: { [string]: boolean } = {}
	for id, value in quests.done do
		if value == true then
			doneQuestNow[id] = true
			if initialized and not seenQuestDone[id] and (guide.step == nil or guide.step.id == "") and isMain(id) then
				push(Locale.t("banner.done"), Locale.t(`quest.{id}.title`))
			end
		end
	end
	seenQuestDone = doneQuestNow
	if initialized and guide.step ~= nil and guide.step.id ~= "" then
		-- Tutorial running: a quest that is new now stays unseen, so its "Dimulai" still comes after the tutorial.
		for id in seenQuests do
			if not activeNow[id] then
				seenQuests[id] = nil
			end
		end
	else
		seenQuests = activeNow
	end
	initialized = true
end

function BannerController.Init()
end

function BannerController.Start()
	State.Changed:Connect(onSnapshot)
	if State.current then
		onSnapshot(State.current)
	end
end

return BannerController
