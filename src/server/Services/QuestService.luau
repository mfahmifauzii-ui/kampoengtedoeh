--!strict
-- General quest system (definitions: Config/Quests). Saved in data.quests: `active` quests with their current
-- step and count, `done` quests. Quests start by themselves when the player's level (and any `after` quest)
-- allows. Services report what happened with QuestService.Report(player, event, amount); the matching step
-- advances, and finishing the last step pays the reward through ProgressionService.Grant.
-- The client reads data.quests from the normal state snapshot (InventoryService) and shows the tracker.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
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
			and (quest.requireTutorial ~= true or data.guide.done.t1_awal == true)
			and (quest.requireKakek ~= true or data.pond.kakekUnlocked == true)
		then
			data.quests.active[quest.id] = { step = 1, count = 0 }
			started = true
			Net.Fire("Notify", player, "quest.new", { title = `quest.{quest.id}.title` })
		end
	end
	return started
end


-- Stage 7 Daily: one random kind per WIB day, starting at Quests.DAILY_RESET_HOUR. Progress is counted, never lost:
-- an unfinished daily is replaced by a new one the next day (no fail state).
local function rollDaily(data: Types.PlayerData, now: number)
	local day = TimeKeys.day(now - Quests.DAILY_RESET_HOUR * 3600)
	if data.quests.daily.day == day then
		return
	end
	local pick = Quests.DAILY[math.random(1, #Quests.DAILY)]
	data.quests.daily = { day = day, kind = pick.id, progress = 0, claimed = false }
end

local function reportDaily(player: Player, data: Types.PlayerData, event: string, add: number)
	rollDaily(data, os.time())
	local daily = data.quests.daily
	local def = nil
	for _, candidate in Quests.DAILY do
		if candidate.id == daily.kind then
			def = candidate
		end
	end
	if not def or def.event ~= event or daily.claimed then
		return
	end
	daily.progress = math.min(daily.progress + add, def.count)
	if daily.progress >= def.count then
		daily.claimed = true
		ProgressionService.Grant(player, def.reward, `daily:{def.id}`)
		Net.Fire("Notify", player, "quest.done", { title = `daily.{def.id}.title` })
	end
	InventoryService.Sync(player)
end

function QuestService.Report(player: Player, event: string, amount: number?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local add = amount or 1
	reportDaily(player, data, event, add)
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
					if quest.bonusDecor then
						data.decor.stock[quest.bonusDecor] = (data.decor.stock[quest.bonusDecor] or 0) + 1
					end
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

-- On join: rolls today's Daily (Stage 7) and starts any quest the player now qualifies for.
local function evaluate(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	-- DEV ONLY (Studio test hook, 16 Nov): Workspace attribute "DevStartLevel" raises the level of the loaded save so the
	-- Gembor / Sprinkler tests can run (chat commands are not reachable in the Studio tool). REMOVE BEFORE LAUNCH.
	if game:GetService("RunService"):IsStudio() then
		local wanted = game:GetService("Workspace"):GetAttribute("DevStartLevel")
		if typeof(wanted) == "number" and data.level < wanted then
			data.level = wanted
		end
	end
	rollDaily(data, os.time())
	startAvailable(player, data)
	InventoryService.Sync(player)
end

function QuestService.Init()
	DataService.Loaded:Connect(evaluate)
	ProgressionService.LevelUp:Connect(evaluate)
end

return QuestService
