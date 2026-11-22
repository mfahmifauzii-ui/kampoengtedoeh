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

local gated: { [string]: boolean } = {}
for _, quest in Quests.list do
	for _, step in quest.steps do
		if step.reveals then
			gated[step.reveals] = true
		end
	end
end

function FeatureGate.IsGated(id: string): boolean
	return gated[id] == true
end

-- True when the feature may be used: not gated, or introduced / open.
function FeatureGate.IsUsable(data: any, id: string): boolean
	if not gated[id] then
		return true
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
