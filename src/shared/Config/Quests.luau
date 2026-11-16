--!strict
-- Quest definitions (data only). A quest appears once the player reaches `unlockLevel` and, if set, finished the
-- quest named in `after`. It has one or more STEPS done in order; each step counts one game event.
-- Events are reported by the services with QuestService.Report(player, event, amount):
--   "pond_built"  a pond was dug (PondService)
--   "catch_pond"  a fish was reeled in at one of your ponds (FishService)
-- Locale keys: quest.<id>.title, quest.<id>.s<step> (step text, may use {n} = how many are needed).

local Progression = require(script.Parent.Progression)

export type Step = {
	event: string,
	count: number,
}

export type Quest = {
	id: string,
	unlockLevel: number,
	after: string?,
	requireTutorial: boolean?, -- Stage 7: starts only after T1 (guide.done.t1_awal)
	bonusDecor: string?, -- Stage 7: decor item added to the stock as a reward (free)
	steps: { Step },
	reward: Progression.Reward,
}

local list: { Quest } = {
	{
		id = "kolam_pertama",
		unlockLevel = 2, -- same level the Kolam fishing location opens (Config/Fishing)
		steps = {
			{ event = "pond_built", count = 1 }, -- the first pond is free
			{ event = "catch_pond", count = 1 },
		},
		reward = { koin = 300, xp = 60 },
	},
	-- Stage 7: Misi Utama, the 3 steps after T1. Only these 3 + one Daily per day exist for now.
	{
		id = "misi_utama",
		unlockLevel = 1,
		requireTutorial = true,
		steps = {
			{ event = "plant_kangkung", count = 3 }, -- Tanam 3 Kangkung
			{ event = "catch", count = 1 }, -- Mancing 1 Ikan
			{ event = "decor_placed", count = 1 }, -- Taruh 1 Hiasan
		},
		reward = { koin = 50 },
		bonusDecor = "pagar_bambu",
	},
}

-- Stage 7: Daily Quest, one per day (reset 05:00 WIB), picked at random. Never fails: an unfinished daily is simply
-- replaced the next day. Reward is paid once when the count is reached.
export type Daily = { id: string, event: string, count: number }
local DAILY: { Daily } = {
	{ id = "tanam", event = "plant", count = 5 }, -- Tanam 5 apa saja
	{ id = "panen", event = "harvest", count = 5 }, -- Panen 5
	{ id = "pancing", event = "catch", count = 2 }, -- Mancing 2
}
local DAILY_RESET_HOUR = 5 -- WIB
local DAILY_REWARD = { koin = 40, xp = 10 }

local byId: { [string]: Quest } = {}
for _, quest in list do
	byId[quest.id] = quest
end

return {
	list = list,
	byId = byId,
	DAILY = DAILY,
	DAILY_RESET_HOUR = DAILY_RESET_HOUR,
	DAILY_REWARD = DAILY_REWARD,
}
