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
local AgendaService = require(script.Parent.AgendaService)
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


-- Agenda (Bab 14.5): 5 tugas dipilih player, reset 05:00 WIB. Logika di AgendaService (P2-7);
-- QuestService.Report meneruskannya. Roll awal dilakukan AgendaService saat join.

-- Quest Harian (Bab 9-10, P2-7): 3 quest per hari, reset 05:00 WIB, tidak bisa di-reroll / ditumpuk.
local function pickDistinct(pool: { any }, count: number): { any }
	local copy: { any } = {}
	for _, item in pool do
		table.insert(copy, item)
	end
	local picked: { any } = {}
	while #picked < count and #copy > 0 do
		table.insert(picked, table.remove(copy, math.random(1, #copy)))
	end
	return picked
end

local function rollHarian(data: Types.PlayerData, now: number)
	local day = TimeKeys.day(now - Quests.DAILY_RESET_HOUR * 3600)
	if data.quests.harian.day == day then
		return
	end
	local slots = {}
	for _, def in pickDistinct(Quests.HARIAN, Quests.HARIAN_COUNT) do
		table.insert(slots, { kind = def.id, progress = 0, claimed = false })
	end
	data.quests.harian = { day = day, slots = slots }
end

-- Quest Mingguan (Bab 9-10, P2-7): 3 quest per minggu, reset Senin 05:00 WIB (TimeKeys.week).
local function rollMingguan(data: Types.PlayerData, now: number)
	local week = TimeKeys.week(now - Quests.DAILY_RESET_HOUR * 3600)
	if data.quests.mingguan.week == week then
		return
	end
	local slots = {}
	for _, def in pickDistinct(Quests.MINGGUAN, Quests.MINGGUAN_COUNT) do
		table.insert(slots, { kind = def.id, progress = 0, claimed = false })
	end
	data.quests.mingguan = { week = week, slots = slots }
end

local function reportSlots(player: Player, slots: { any }, pool: { any }, label: string, event: string, add: number)
	for _, slot in slots do
		local def = nil
		for _, candidate in pool do
			if candidate.id == slot.kind then
				def = candidate
				break
			end
		end
		if def and def.event == event and not slot.claimed then
			slot.progress = math.min(slot.progress + add, def.count)
			if slot.progress >= def.count then
				slot.claimed = true
				ProgressionService.Grant(player, def.reward, `{label}:{def.id}`)
				Net.Fire("Notify", player, "quest.done", { title = `{label}.{def.id}.title` })
			end
		end
	end
end

function QuestService.Report(player: Player, event: string, amount: number?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local add = amount or 1
	AgendaService.Report(player, event, add) -- Agenda 5 tugas (P2-7)
	rollHarian(data, os.time())
	rollMingguan(data, os.time())
	reportSlots(player, data.quests.harian.slots, Quests.HARIAN, "quest_harian", event, add)
	reportSlots(player, data.quests.mingguan.slots, Quests.MINGGUAN, "quest_mingguan", event, add)
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
	AgendaService.Roll(data, os.time())
	rollHarian(data, os.time())
	rollMingguan(data, os.time())
	startAvailable(player, data)
	InventoryService.Sync(player)
end

function QuestService.Init()
	DataService.Loaded:Connect(evaluate)
	ProgressionService.LevelUp:Connect(evaluate)
end

return QuestService
