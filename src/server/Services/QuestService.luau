--!strict
-- General quest system (definitions: Config/Quests). Saved in data.quests: `active` quests with their current
-- step and count, `done` quests. Quests start by themselves when the player's level (and any `after` quest)
-- allows. Services report what happened with QuestService.Report(player, event, amount); the matching step
-- advances, and finishing the last step pays the reward through ProgressionService.Grant.
-- The client reads data.quests from the normal state snapshot (InventoryService) and shows the tracker.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

local QuestService = {}

-- Starts every quest the player now qualifies for. Returns true if something started.
local function startAvailable(player: Player, data: Types.PlayerData): boolean
	local started = false
	for _, quest in Quests.list do
		if
			data.quests.done[quest.id] == nil
			and data.quests.active[quest.id] == nil
			and data.level >= quest.unlockLevel
			and (quest.after == nil or data.quests.done[quest.after] == true)
		then
			data.quests.active[quest.id] = { step = 1, count = 0 }
			started = true
			Net.Fire("Notify", player, "quest.new", { title = `quest.{quest.id}.title` })
		end
	end
	return started
end

local function evaluate(player: Player)
	local data = DataService.Get(player)
	if data and startAvailable(player, data) then
		InventoryService.Sync(player)
	end
end

function QuestService.Report(player: Player, event: string, amount: number?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local add = amount or 1
	local changed = false

	for questId, progress in data.quests.active do
		local quest = Quests.byId[questId]
		local step = quest and quest.steps[progress.step]
		if quest and step and step.event == event then
			changed = true
			progress.count += add
			if progress.count >= step.count then
				progress.step += 1
				progress.count = 0
				if progress.step > #quest.steps then
					data.quests.active[questId] = nil
					data.quests.done[questId] = true
					ProgressionService.Grant(player, quest.reward, `quest:{questId}`)
					Net.Fire("Notify", player, "quest.done", { title = `quest.{questId}.title` })
				else
					Net.Fire("Notify", player, "quest.step", { title = `quest.{questId}.title` })
				end
			end
		end
	end

	if changed then
		startAvailable(player, data) -- finishing a quest can unlock the next one (`after`)
		InventoryService.Sync(player)
	end
end

function QuestService.Init()
	DataService.Loaded:Connect(evaluate)
	ProgressionService.LevelUp:Connect(evaluate)
end

return QuestService
