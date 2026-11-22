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

local function rollAgenda(data: Types.PlayerData, now: number)
	local day = TimeKeys.day(now - Quests.DAILY_RESET_HOUR * 3600)
	if data.quests.daily.day == day then
		return
	end
	local pick = Quests.AGENDA[math.random(1, #Quests.AGENDA)]
	data.quests.daily = { day = day, kind = pick.id, progress = 0, claimed = false }
end

-- Returns true when this report completed (claimed) one Agenda task; QuestService turns that into "agenda_done".
local function reportAgenda(player: Player, data: Types.PlayerData, event: string, add: number): boolean
	rollAgenda(data, os.time())
	local daily = data.quests.daily
	local def = nil
	for _, candidate in Quests.AGENDA do
		if candidate.id == daily.kind then
			def = candidate
			break
		end
	end
	if not def or def.event ~= event or daily.claimed then
		return false
	end
	daily.progress = math.min(daily.progress + add, def.count)
	if daily.progress >= def.count then
		daily.claimed = true
		ProgressionService.Grant(player, def.reward, `agenda:{def.id}`)
		Net.Fire("Notify", player, "quest.done", { title = `agenda.{def.id}.title` })
		InventoryService.Sync(player)
		return true
	end
	InventoryService.Sync(player)
	return false
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
