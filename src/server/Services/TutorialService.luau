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

local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local WorldService = require(script.Parent.WorldService)

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

-- Kak Fajar's gift (Terima Hadiah, or a skipped rodgift step): the Joran Bambu and the pelet, given ONCE. Returns false when
-- the save already has it. Owned by the server only.
local FAJAR_BAIT = { id = "pelet", amount = 5 }
local function giveRodGift(player: Player, data: any): boolean
	local guide = data.guide
	if guide.rodGift then
		return false
	end
	guide.rodGift = true
	guide.fishingUnlocked = true
	if data.fishing.ownedRods.bambu ~= true then
		data.fishing.ownedRods.bambu = true
	end
	if data.fishing.rod == "" then
		data.fishing.rod = "bambu"
	end
	InventoryService.Add(player, FAJAR_BAIT.id, FAJAR_BAIT.amount)
	logEvent(player, "tut_fajar_gift", "kak_fajar")
	return true
end

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
		-- No skipping ahead: a step that needs the gift, a fish, or the Mengerti of the first fish only passes when it really happened.
		for index = guide.step.n + 1, n do
			local step = tutorial.steps[index]
			if step.done.kind == "rodgift" and guide.rodGift ~= true then
				return
			end
			if (step.done.kind == "fish" or step.id == "after_catch") and guide.fishCaught ~= true then
				return
			end
		end
		for index = guide.step.n + 1, n do
			local step = tutorial.steps[index]
			pay(player, step.reward, tutorialId)
			logEvent(player, `tut_{tutorialId}_{step.id}`, tutorialId)
			if step.id == "after_catch" then
				guide.kolamUnlocked = true -- the pond opens once the first fish was explained (Mak Sari teaches it)
			end
		end
		guide.step.n = n
		if tutorialId == "t1_awal" and n == Onboarding.GERIMIS_AFTER_STEP and guide.done.gerimis_t1 ~= true then
			guide.done.gerimis_t1 = true -- once per save: FTUE 0:30 Gerimis, waters the first crop so Siram is done by the rain
			WorldService.TutorialRain(Onboarding.GERIMIS_SECONDS)
		end
		if n >= total then
			guide.done[tutorialId] = true
			guide.step = { id = "", n = 0 }
			pay(player, tutorial.reward, tutorialId)
			if tutorialId == "t1b_kolam" then
				guide.decorUnlocked = true -- decorating opens when the whole second tutorial is finished
			end
			logEvent(player, `tut_{tutorialId}_done`, tutorialId)
		end
	elseif action == "skipstep" or action == "skipall" then
		-- A2 (v6.2.3): skip never blocks. The step's own prerequisites are granted first (the rod for the gift step, the fish
		-- flag for the fishing steps), then the step is recorded through the normal "step" path, so its reward is paid the same
		-- way. "skipall" does that for every remaining step (the tutorial's reward too, at the last one).
		if guide.step.id ~= tutorialId then
			return
		end
		local count = #tutorial.steps
		local last = if action == "skipall" then count else guide.step.n + 1
		for index = guide.step.n + 1, math.min(last, count) do
			local step = tutorial.steps[index]
			if step.done.kind == "rodgift" then
				giveRodGift(player, data)
			end
			if step.done.kind == "fish" or step.id == "after_catch" then
				guide.fishCaught = true
			end
			onGuideEvent(player, "step", tutorialId, index)
		end
		logEvent(player, `tut_{tutorialId}_{action}`, tutorialId)
		return
	elseif action == "replay" then
		-- No state change and no reward: only the analytics event.
		logEvent(player, "tut_replay", tutorialId)
		return
	else
		return
	end
	InventoryService.Sync(player)
end

-- First-meet and first-sale (Fase 2) ------------------------------------------------------------

-- Client asks HasMet(npcId) when the player starts a talk. Returns true if that NPC was already met before this call, and
-- records the meeting either way. The client shows the sapaan only when it returns false (the first talk).
local function onHasMet(player: Player, npcId: any): boolean
	if typeof(npcId) ~= "string" or not Npcs.byId[npcId] then
		return true -- unknown NPC: treat as met, so no sapaan plays
	end
	local data = DataService.Get(player)
	if not data then
		return true
	end
	local met = data.guide.hasMet
	if met[npcId] then
		return true
	end
	met[npcId] = true
	return false
end

-- ShopService calls this once, when a sale with at least one item goes through and it is the player's first sale ever
-- (data.guide.sells was 0). The server only tells the client; the cutscene and the dialogue are the client's.
function TutorialService.OnFirstSellSuccess(player: Player, npcId: string)
	Net.Fire("OnFirstSellSuccess", player, npcId)
end

-- Kak Fajar's Terima Hadiah (Plan v3.1 3A, Opsi B). A second press (or an old save that already has the rod) gives nothing.
local function onMeetFajar(player: Player): any
	local data = DataService.Get(player)
	if not data then
		return { ok = false }
	end
	if not giveRodGift(player, data) then
		Net.Fire("Notify", player, "rod.gift_again")
		return { ok = true, gave = false }
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "rod.gift")
	return { ok = true, gave = true }
end

function TutorialService.Init()
	register(Onboarding.TEST_TUTORIAL)
	for _, tutorial in Onboarding.TUTORIALS do
		register(tutorial)
	end

	DataService.Loaded:Connect(function(player: Player, data)
		local guide = data.guide
		-- Old saves (before the Kak Fajar gift and the pond/decor gates): keep what they already have, never take it away.
		-- Owners of a rod, a pond, or a finished second tutorial keep fishing, the pond and decorating.
		if data.fishing.ownedRods.bambu == true or #data.pond.list > 0 or guide.done.t1b_kolam == true or guide.skipped.t1b_kolam == true then
			guide.fishingUnlocked = true
			guide.rodGift = guide.rodGift or data.fishing.ownedRods.bambu == true
		end
		if #data.pond.list > 0 or guide.done.t1b_kolam == true or guide.skipped.t1b_kolam == true then
			guide.kolamUnlocked = true
			guide.fishCaught = guide.fishCaught or #data.pond.list > 0
		end
		if guide.done.t1b_kolam == true or guide.skipped.t1b_kolam == true or #data.pond.list > 0 then
			guide.decorUnlocked = true
		end
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
	Net.On("HasMet", onHasMet, { rate = 4, burst = 8 })
	Net.On("MeetFajar", onMeetFajar, { rate = 2, burst = 4 })
end

return TutorialService
