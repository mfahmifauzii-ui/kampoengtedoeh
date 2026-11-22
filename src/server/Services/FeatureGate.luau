--!strict
-- Feature gate (Quest v0.3 Bab 2 + 5, Q-2). data.features[id] = "introduced" | "open".
--   introduced = the quest step that asks the player to use the feature is active (the button may show)
--   open       = that step is done (the feature stays open for good)
-- Only ids that some quest step names in `reveals` (Config/Quests) are gated. Any other id is always usable.
-- QuestService.syncFeatures writes the states from the quest progress; this module only reads them.
-- Server rule: a gated remote or a gated prompt rejects the player unless the feature is introduced or open
-- (same pattern as TutorialService.NpcBlocked). Client UI is a separate step (Q-2 client, see Roadmap §10).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)

local FeatureGate = {}

-- D-39: features that open by PLAYER LEVEL, not by a quest step. The Skill panel opens at Player Lv 2 (the first root skills
-- need Player Lv 2; SP = level - 1, so the first SP comes at Lv 2). The server writes "open" into the snapshot for these ids
-- (InventoryService), and the client reads the same snapshot as for the quest features.
FeatureGate.LEVEL_GATES = {
	skill = 2,
}

local gated: { [string]: boolean } = {}
for _, quest in Quests.list do
	for _, step in quest.steps do
		if step.reveals then
			gated[step.reveals] = true
		end
	end
end
for id in FeatureGate.LEVEL_GATES do
	gated[id] = true
end

-- The level a player has reached: the same rule as the Level attribute.
function FeatureGate.LevelOpen(level: number, id: string): boolean
	local need = FeatureGate.LEVEL_GATES[id]
	return need ~= nil and level >= need
end

function FeatureGate.IsGated(id: string): boolean
	return gated[id] == true
end

-- True when the feature may be used: not gated, or introduced / open.
function FeatureGate.IsUsable(data: any, id: string): boolean
	if not gated[id] then
		return true
	end
	if FeatureGate.LEVEL_GATES[id] ~= nil then
		return FeatureGate.LevelOpen(data.level, id)
	end
	local features = data.features
	local state = if typeof(features) == "table" then features[id] else nil
	return state == "introduced" or state == "open"
end

-- Server check for a player: returns false and tells the player when the feature is still closed.
function FeatureGate.Check(player: Player, id: string): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	if FeatureGate.IsUsable(data, id) then
		return true
	end
	Net.Fire("Notify", player, "feature.locked")
	return false
end

return FeatureGate
