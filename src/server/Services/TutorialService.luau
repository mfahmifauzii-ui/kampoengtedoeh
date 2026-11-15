--!strict
-- Tutorial engine, server side (client side: Controllers/GuideController). The tutorials themselves are DATA in
-- Config/Onboarding (TUTORIALS); this service only:
--   * keeps the save (data.guide: step {id, n}, done, skipped, fastLeft) and validates every change a client asks for,
--   * pays rewards (once per tutorial, never on replay),
--   * logs the analytics events tut_<id>_<step>, tut_<id>_done, tut_skip, tut_replay,
--   * runs the fast tutorial timer: the first Onboarding.FAST_PLANTINGS plantings of a NEW save grow in
--     FAST_GROW_SECONDS (FarmService asks ConsumeFast on every planting).
-- The client decides WHEN a step is done (it sees the world); the server only lets the step counter move forward, one tutorial at
-- a time, and pays small one-time rewards. Rewards are tiny on purpose, so a cheating client gains nothing worth the effort.

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

local TutorialService = {}

local byId: { [string]: Onboarding.Tutorial } = {}

local function register(tutorial: Onboarding.Tutorial)
	if tutorial.studioOnly and not RunService:IsStudio() then
		return
	end
	assert(byId[tutorial.id] == nil, `[TutorialService] duplicate tutorial id {tutorial.id}`)
	assert(#tutorial.steps >= 1, `[TutorialService] tutorial {tutorial.id} has no steps`)
	byId[tutorial.id] = tutorial
end

local function logEvent(player: Player, eventName: string, tutorialId: string)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tutorialId,
		})
	end)
end

local function pay(player: Player, reward: Onboarding.Reward?, tutorialId: string)
	if not reward then
		return
	end
	if reward.xp and reward.xp > 0 then
		ProgressionService.AddXp(player, reward.xp, `tutorial:{tutorialId}`)
	end
	if reward.koin and reward.koin > 0 then
		EconomyService.Add(player, "koin", reward.koin, `tutorial:{tutorialId}`)
	end
	if reward.bunga and reward.bunga > 0 then
		EconomyService.Add(player, "bunga", reward.bunga, `tutorial:{tutorialId}`)
	end
	if reward.items then
		for itemId, count in reward.items do
			InventoryService.Add(player, itemId, count)
		end
	end
end

-- Fast tutorial timer ----------------------------------------------------------------------------

-- Called by FarmService for every successful planting. True = this planting grows in FAST_GROW_SECONDS.
function TutorialService.ConsumeFast(player: Player): boolean
	local data = DataService.Get(player)
	if not data or data.guide.fastLeft <= 0 then
		return false
	end
	data.guide.fastLeft -= 1
	return true
end

-- Client requests ---------------------------------------------------------------------------------

local function onGuideEvent(player: Player, action: any, tutorialId: any, n: any)
	if typeof(action) ~= "string" or typeof(tutorialId) ~= "string" then
		return
	end
	local tutorial = byId[tutorialId]
	local data = DataService.Get(player)
	if not tutorial or not data then
		return
	end
	local guide = data.guide

	if action == "start" then
		if guide.done[tutorialId] or guide.skipped[tutorialId] then
			return
		end
		if guide.step.id ~= "" and guide.step.id ~= tutorialId then
			return -- one tutorial at a time
		end
		if guide.step.id ~= tutorialId then
			guide.step = { id = tutorialId, n = 0 }
			logEvent(player, `tut_{tutorialId}_start`, tutorialId)
		end
	elseif action == "step" then
		if guide.step.id ~= tutorialId or typeof(n) ~= "number" or n % 1 ~= 0 then
			return
		end
		local total = #tutorial.steps
		if n <= guide.step.n or n > total then
			return -- only forward
		end
		for index = guide.step.n + 1, n do
			local step = tutorial.steps[index]
			pay(player, step.reward, tutorialId)
			logEvent(player, `tut_{tutorialId}_{step.id}`, tutorialId)
		end
		guide.step.n = n
		if n >= total then
			guide.done[tutorialId] = true
			guide.step = { id = "", n = 0 }
			pay(player, tutorial.reward, tutorialId)
			logEvent(player, `tut_{tutorialId}_done`, tutorialId)
		end
	elseif action == "skip" then
		if guide.done[tutorialId] or guide.skipped[tutorialId] then
			return
		end
		guide.skipped[tutorialId] = true
		if guide.step.id == tutorialId then
			guide.step = { id = "", n = 0 }
		end
		logEvent(player, "tut_skip", tutorialId)
	elseif action == "replay" then
		-- No state change and no reward: only the analytics event.
		logEvent(player, "tut_replay", tutorialId)
		return
	else
		return
	end
	InventoryService.Sync(player)
end

function TutorialService.Init()
	register(Onboarding.TEST_TUTORIAL)
	for _, tutorial in Onboarding.TUTORIALS do
		register(tutorial)
	end

	DataService.Loaded:Connect(function(player: Player, data)
		local guide = data.guide
		-- A save from before the tutorial engine: nothing to catch up, and no fast timer (that is for brand-new saves only).
		if guide.fastLeft < 0 then
			local isNew = #data.farm.tiles == 0 and data.onboarding.first_plant ~= true and guide.sells == 0
			guide.fastLeft = if isNew then Onboarding.FAST_PLANTINGS else 0
		end
		-- The tutorial this save was in the middle of no longer exists (removed from config / Studio-only in a live server).
		if guide.step.id ~= "" and byId[guide.step.id] == nil then
			guide.step = { id = "", n = 0 }
		end
		InventoryService.Sync(player)
	end)
end

function TutorialService.Start()
	Net.On("GuideEvent", onGuideEvent, { rate = 4, burst = 8 })
end

return TutorialService
