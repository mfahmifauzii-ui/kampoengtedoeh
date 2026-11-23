--!strict
-- Agenda Harian (Bab 14.5, LOCKED, P2-7): 5 tugas per hari, reset 05:00 WIB.
-- Semua 5 aktif; player memilih mana yang dikerjakan (tidak ada preseleksi).
-- Hadiah 150-400 Koin per tugas + XP USULAN (v7.3 tak memberi XP; butuh lock owner).
-- Tanpa Bunga dari Agenda (Bab 14.5). Hadiah diberikan otomatis selesai (pola lama, dipertahankan).
-- Report dipanggil QuestService.Report (semua event farming/mancing/masak/bantu/nambang).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local FeatureGate = require(script.Parent.FeatureGate)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

local AgendaService = {}

-- D1 (K-56): a pool template is only picked when the player can do it now: its level and, when given, its feature are open.
-- Hidden templates (Bantu, until Kebun Warga) are never picked. Returns the eligible templates (may be fewer than asked).
function AgendaService.Eligible(data: Types.PlayerData, pool: { Quests.Daily }): { Quests.Daily }
	local out: { Quests.Daily } = {}
	for _, def in pool do
		local req = def.requires
		local ok = not def.hidden
			and (req == nil or (data.level >= req.level and (req.feature == nil or FeatureGate.IsUsable(data, req.feature))))
		if ok then
			table.insert(out, def)
		end
	end
	return out
end

-- R2.2 (GDD 14.5): all eligible tasks are active at once; each has its own progress. A task pays out by itself when it
-- completes (no claim button). Returns true when this report completed one task (QuestService turns it into "agenda_done").
local function findDef(id: string): Quests.Daily?
	for _, candidate in Quests.AGENDA do
		if candidate.id == id then
			return candidate
		end
	end
	return nil
end

local function rollAgenda(data: Types.PlayerData, now: number)
	local day = TimeKeys.day(now - Quests.DAILY_RESET_HOUR * 3600)
	if data.quests.agenda.day == day then
		return
	end
	local tasks = {}
	for _, def in AgendaService.Eligible(data, Quests.AGENDA) do
		table.insert(tasks, { id = def.id, progress = 0, claimed = false })
	end
	data.quests.agenda = { day = day, tasks = tasks }
end

local function reportAgenda(player: Player, data: Types.PlayerData, event: string, add: number): boolean
	rollAgenda(data, os.time())
	local completed = false
	local touched = false
	for _, task in data.quests.agenda.tasks do
		local def = findDef(task.id)
		if def and def.event == event and not task.claimed then
			touched = true
			task.progress = math.min(task.progress + add, def.count)
			if task.progress >= def.count then
				task.claimed = true
				completed = true
				ProgressionService.Grant(player, def.reward, `agenda:{def.id}`)
				Net.Fire("Notify", player, "quest.done", { title = `agenda.{def.id}.title` })
			end
		end
	end
	if touched then
		InventoryService.Sync(player)
	end
	return completed
end

-- Agenda terbuka saat quest M1 "Kampung Hari Ini" mulai atau sudah selesai (Quest v0.3 Bab 5: Tombol Agenda = M1).
-- M1 sendiri punya langkah "Buka Agenda", jadi gate-nya tidak boleh menunggu M1 selesai.
function AgendaService.IsOpen(data: Types.PlayerData): boolean
	return FeatureGate.IsUsable(data, "agenda")
end

function AgendaService.Roll(data: Types.PlayerData, now: number)
	if not AgendaService.IsOpen(data) then
		return
	end
	rollAgenda(data, now)
end

-- Returns true if this report completed an Agenda task.
function AgendaService.Report(player: Player, event: string, add: number): boolean
	local data = DataService.Get(player)
	if not data or not AgendaService.IsOpen(data) then
		return false
	end
	return reportAgenda(player, data, event, add)
end

function AgendaService.Init()
	DataService.Loaded:Connect(function(player: Player)
		local data = DataService.Get(player)
		if data then
			rollAgenda(data, os.time())
		end
	end)
end

return AgendaService
