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
local State = require(script.Parent.Parent.State)
local PlayerLock = require(script.Parent.Parent.PlayerLock)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer
local HOLD_SECONDS = 2.8 -- how long the player is held and the title stays up
local BAR_SECONDS = 0.45 -- the bars slide in / out

local BannerController = {}

local queue: { { title: string, subtitle: string } } = {}
local playing = false
local seenDone: { [string]: boolean } = {}
local seenQuests: { [string]: boolean } = {}
local initialized = false

local function build(): (ScreenGui, Frame, Frame, TextLabel, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChapterBanner"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
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
		for _, tutorial in Onboarding.TUTORIALS do
			if doneNow[tutorial.id] and not seenDone[tutorial.id] then
				push(Locale.t("banner.done"), Locale.t(tutorial.title))
			end
		end
		-- A quest that just started: "Dimulai" with its title.
		for id in activeNow do
			if not seenQuests[id] then
				local key = `quest.{id}.title`
				push(Locale.t("banner.started"), Locale.t(key))
			end
		end
	end
	seenDone = doneNow
	seenQuests = activeNow
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
