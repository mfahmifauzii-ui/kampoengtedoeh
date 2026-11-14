--!strict
-- Player skills (Config/Skills): level + XP stored in data.skills[id]. Level-ups notify the player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skills = require(ReplicatedStorage.Shared.Config.Skills)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local SkillService = {}

local function record(data: Types.PlayerData, skillId: string): Types.SkillRecord?
	if not Skills.byId[skillId] then
		return nil
	end
	local entry = data.skills[skillId]
	if not entry then
		entry = { level = 1, xp = 0 }
		data.skills[skillId] = entry
	end
	return entry
end

function SkillService.Level(player: Player, skillId: string): number
	local data = DataService.Get(player)
	local entry = data and record(data, skillId)
	return if entry then entry.level else 1
end

function SkillService.AddXp(player: Player, skillId: string, amount: number)
	local data = DataService.Get(player)
	local skill = Skills.byId[skillId]
	local entry = data and record(data, skillId)
	if not data or not skill or not entry or amount <= 0 then
		return
	end
	if entry.level < skill.maxLevel then
		entry.xp += amount
		while entry.level < skill.maxLevel and entry.xp >= skill.xpToNext(entry.level) do
			entry.xp -= skill.xpToNext(entry.level)
			entry.level += 1
			Net.Fire("Notify", player, "skill.level_up", { skill = `skill.{skillId}`, level = entry.level })
		end
		if entry.level >= skill.maxLevel then
			entry.xp = 0
		end
	end
	InventoryService.Sync(player)
end

-- Studio testing only (DevService).
function SkillService.DevSet(player: Player, skillId: string, level: number)
	local data = DataService.Get(player)
	local skill = Skills.byId[skillId]
	local entry = data and record(data, skillId)
	if skill and entry then
		entry.level = math.clamp(math.floor(level), 1, skill.maxLevel)
		entry.xp = 0
		InventoryService.Sync(player)
	end
end

return SkillService
