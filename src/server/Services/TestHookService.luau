--!strict
-- Studio-only test hook (K-127). Inert unless RunService:IsStudio(): Start registers nothing, so a published build
-- has no TestHook remote handler at all. The client side (client/Controllers/TestHookController) only reacts when the
-- test harness sets the player attribute KTTestRequest; the owner's own Studio play never sets it.
-- Actions: "skipTutorial" (every tutorial marked done, no intro), "grant" (test state: seeds owned and x0, items, XP,
-- a chest timeline with one chest claimed and the next counting down, Login day 3). No UI here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local WorldService = require(script.Parent.WorldService)

local TestHookService = {}

local function skipTutorial(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for _, tutorial in Onboarding.TUTORIALS do
		data.guide.done[tutorial.id] = true
	end
	data.guide.step = { id = "", n = 0 }
	InventoryService.Sync(player)
end

local function grant(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	-- Seeds: seed_kangkung owned (x5); seed_tomat is left out, so it reads as x0 (dimmed).
	InventoryService.Add(player, "seed_kangkung", 5)
	InventoryService.Add(player, "kangkung", 4) -- harvested crop (bag picture: category icon)
	InventoryService.Add(player, "nila@S", 2) -- fish (sized id)
	InventoryService.Add(player, "cacing", 5) -- bait
	ProgressionService.AddXp(player, 60, "test")
	-- Chest timeline: 10 minutes played today, chest 1 claimed, so chest 2 (20 min) counts down from 10 min.
	data.playtime.day = TimeKeys.day()
	data.playtime.seconds = 600
	data.playtime.claimed = 1
	player:SetAttribute("PlaytimeSec", 600)
	-- Login Harian: 3 days reached this week, none claimed (so day 1 shows as "Ambil").
	local rewards = data.rewards
	if rewards then
		rewards.login.week = TimeKeys.week()
		rewards.login.days = 3
		rewards.login.claimed = {}
	end
	InventoryService.Sync(player)
end

function TestHookService.Init()
	-- Nothing to set up: the handler is registered in Start, and only in Studio.
end

function TestHookService.Start()
	if not RunService:IsStudio() then
		return
	end
	Net.On("TestHook", function(player: Player, action: any)
		if action == "skipTutorial" then
			skipTutorial(player)
		elseif action == "grant" then
			grant(player)
		elseif action == "weather:rain" then
			WorldService.DevSetWeather("gerimis") -- server weather is per server: the same effect for everyone
		elseif action == "weather:clear" then
			WorldService.DevSetWeather("terik")
		end
	end, { rate = 4, burst = 8 })
end

return TestHookService
