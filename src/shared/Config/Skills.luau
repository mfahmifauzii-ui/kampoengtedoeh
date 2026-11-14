--!strict
-- Player skills. Stored as data.skills[id] = { level, xp }. Locale: skill.<id>.
-- Only "tawar" exists for now; add an entry here (and use SkillService.AddXp) for Bertani / Memancing / ...

export type Skill = {
	id: string,
	maxLevel: number,
	xpToNext: (level: number) -> number,
	chanceBonusPerLevel: number, -- tawar: percentage points of haggle chance per level above 1
}

local list: { Skill } = {
	{
		id = "tawar",
		maxLevel = 10,
		xpToNext = function(level: number): number
			return 20 + 10 * level
		end,
		chanceBonusPerLevel = 3,
	},
}

local byId: { [string]: Skill } = {}
for _, skill in list do
	byId[skill.id] = skill
end

return {
	list = list,
	byId = byId,
}
