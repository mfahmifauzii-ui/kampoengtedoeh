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
}

local byId: { [string]: Quest } = {}
for _, quest in list do
	byId[quest.id] = quest
end

return {
	list = list,
	byId = byId,
}
