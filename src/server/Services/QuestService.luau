--!strict
-- General quest system (definitions: Config/Quests, Quest v0.3). Saved in data.quests: `active` quests with their current
-- step and count, `done` quests. Quests start by themselves when the player's level (and any `after` quest) allows.
-- Services report what happened with QuestService.Report(player, event, amount); the matching step advances, and
-- finishing the last step pays the reward through ProgressionService.Grant.
-- Item steps (`items`) are checked on every report and on join: they complete when the player holds the items
-- (`consume` takes them). The client reads data.quests from the normal state snapshot (InventoryService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Locale = require(ReplicatedStorage.Shared.Locale)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local AgendaService = require(script.Parent.AgendaService)
local BookService = require(script.Parent.BookService)
local DataService = require(script.Parent.DataService)
local FeatureGate = require(script.Parent.FeatureGate)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local RanchService = require(script.Parent.RanchService)
local SuratService = require(script.Parent.SuratService)
local TutorialService = require(script.Parent.TutorialService)

local QuestService = {}

-- Event yang dikirim klien (dialog / panel yang hanya ada di UI). Selain daftar ini ditolak.
-- Catatan: server tidak bisa melihat panel ini dibuka; anggap event ini tidak sekuat event server.
local UI_EVENTS: { [string]: boolean } = {
	agenda_open = true,
	gerobak_view = true,
	surat_read = true,
}

-- Jumlah barang yang dipegang untuk satu kebutuhan. "early:any" = semua ikan Early (rarity C) apa pun ukurannya.
local function countNeed(data: Types.PlayerData, need: string): number
	if need ~= "early:any" then
		return data.inventory[need] or 0
	end
	local total = 0
	for itemId, n in data.inventory do
		local fishId = itemId:match("^(.+)@.+$")
		local fish = fishId and FishConfig.byId[fishId]
		if fish and fish.rarity == "C" then
			total += n
		end
	end
	return total
end

local function holds(data: Types.PlayerData, items: { [string]: number }): boolean
	for need, n in items do
		if countNeed(data, need) < n then
			return false
		end
	end
	return true
end

-- Ambil `n` barang untuk kebutuhan (dipanggil hanya setelah holds() true).
local function takeNeed(player: Player, data: Types.PlayerData, need: string, n: number)
	if need ~= "early:any" then
		InventoryService.Remove(player, need, n)
		return
	end
	local left = n
	for itemId, have in data.inventory do
		local fishId = itemId:match("^(.+)@.+$")
		local fish = fishId and FishConfig.byId[fishId]
		if fish and fish.rarity == "C" and left > 0 then
			local take = math.min(have, left)
			InventoryService.Remove(player, itemId, take)
			left -= take
		end
	end
end

local function takeItems(player: Player, data: Types.PlayerData, items: { [string]: number })
	for need, n in items do
		takeNeed(player, data, need, n)
	end
end

-- Selesaikan 1 quest: grant + hook (kolam/kakek) + notify.
local function finishQuest(player: Player, data: Types.PlayerData, quest: Quests.Quest)
	data.quests.active[quest.id] = nil
	data.quests.done[quest.id] = true
	TutorialService.MarkMet(player, quest.giver) -- the giver's closing line is a meeting too (no second intro later)
	ProgressionService.Grant(player, quest.reward, `quest:{quest.id}`)
	if quest.freePond == true then
		data.pond.freeBuilds += 1
	end
	if quest.unlockKakek == true then
		data.pond.kakekUnlocked = true
	end
	Net.Fire("Notify", player, "quest.done", { title = `quest.{quest.id}.title` })
end

-- Starts the quest: pemberi memberi hewan (M5) dulu; kalau gagal (kandang penuh / belum ada plot) quest tidak mulai
-- dan dicoba lagi di evaluate berikut.
local function startQuest(player: Player, data: Types.PlayerData, quest: Quests.Quest): boolean
	if quest.giveHewan and not RanchService.Give(player, quest.giveHewan) then
		return false
	end
	data.quests.active[quest.id] = { step = 1, count = 0 }
	TutorialService.MarkMet(player, quest.giver) -- Bug: a giver met through a quest is not introduced again
	Net.Fire("Notify", player, "quest.new", { title = `quest.{quest.id}.title` })
	return true
end

-- Q-3: the Naskah key prefix of a quest ("m1_kampung" -> "m1", "s1_bibit" -> "s1"). A quest with a dlg.<prefix>.start.1 line
-- waits for its giver (offered, then started by QuestAccept). Quests without a Naskah line (side_* of v0.2) keep the old
-- auto start, with no dialog and no `!`.
local function hasDialog(quest: Quests.Quest): boolean
	local prefix = string.match(quest.id, "^(%a+%d+)_") or quest.id -- side_* memakai id penuh (dlg.side_rumah_rapi.*)
	return Locale.has(`dlg.{prefix}.start.1`)
end

-- Every condition for starting the quest now, except "not auto" and the dialog rule.
local function isStartable(player: Player, data: Types.PlayerData, quest: Quests.Quest): boolean
	return quest.blocked == nil
		and data.quests.done[quest.id] == nil
		and data.quests.active[quest.id] == nil
		and data.level >= quest.unlockLevel
		and (quest.after == nil or data.quests.done[quest.after] == true)
		and (quest.requireAlbum == nil or BookService.AlbumPercent(player) >= quest.requireAlbum)
end

-- No quest at all until the player has finished the tutorial that ends with the fish sale (t1b_kolam, "jual ikan ke Kak Fajar").
-- Old saves that never got t1b_kolam stay locked until they finish it, so a quest can never appear in the middle of a tutorial.
-- Starts every quest the player now qualifies for. Returns true if something started.
local function startAvailable(player: Player, data: Types.PlayerData): boolean
	local started = false
	if not TutorialService.KolamDone(data) then
		return false
	end
	for _, quest in Quests.list do
		if isStartable(player, data, quest) then
			if quest.auto == true then
				-- Selesai saat mulai (MQ12, Side Kolektor). Give hewan (kalau ada) dulu; gagal = coba lagi berikutnya.
				if startQuest(player, data, quest) then
					started = true
					finishQuest(player, data, quest)
				end
			elseif not hasDialog(quest) and startQuest(player, data, quest) then
				-- a quest with a dialog is only offered here (see QuestAccept)
				started = true
			end
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
	for _, def in pickDistinct(AgendaService.Eligible(data, Quests.HARIAN), Quests.HARIAN_COUNT) do
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
	for _, def in pickDistinct(AgendaService.Eligible(data, Quests.MINGGUAN), Quests.MINGGUAN_COUNT) do
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

-- Maju selama langkah aktif sudah selesai (event tercapai DAN barang ada). Langkah tanpa event selesai begitu barang ada.
-- Mengembalikan true kalau ada perubahan. Quest selesai di langkah terakhir.
local function advance(player: Player, data: Types.PlayerData, quest: Quests.Quest, progress: { step: number, count: number }): boolean
	local changed = false
	while true do
		local step = quest.steps[progress.step]
		if not step then
			return changed
		end
		local eventDone = step.event == nil or progress.count >= step.count
		local itemsOk = step.items == nil or holds(data, step.items)
		if not (eventDone and itemsOk) or (step.event == nil and step.items == nil) then
			return changed
		end
		if step.items and step.consume == true then
			takeItems(player, data, step.items)
		end
		changed = true
		if progress.step >= #quest.steps then
			finishQuest(player, data, quest)
			return true
		end
		progress.step += 1
		progress.count = 0
		Net.Fire("Notify", player, "quest.step", { title = `quest.{quest.id}.title` })
	end
end

-- Quest anyOf (MQ11): langkah mana pun yang cocok dihitung; selesai saat salah satunya tuntas.
local function reportAnyOf(player: Player, data: Types.PlayerData, quest: Quests.Quest, progress: { step: number, count: number }, event: string, add: number)
	for _, alt in quest.steps do
		if alt.event == event then
			progress.count += add
			if progress.count >= alt.count then
				finishQuest(player, data, quest)
			end
			return
		end
	end
end

-- Q-2 feature gate: the states follow the quest progress (no separate event, and it works for old saves).
-- Done quest -> its reveals are open. Active quest -> reveals of finished steps are open, reveal of the current step is
-- introduced. A state never goes back (open stays open).
local function setFeature(data: Types.PlayerData, id: string, state: string)
	local current = data.features[id]
	if current == "open" then
		return
	end
	if state == "open" or current == nil then
		data.features[id] = state
	end
end

local function syncFeatures(data: Types.PlayerData)
	if typeof(data.features) ~= "table" then
		data.features = {}
	end
	for _, quest in Quests.list do
		if data.quests.done[quest.id] == true then
			for _, step in quest.steps do
				if step.reveals then
					setFeature(data, step.reveals, "open")
				end
			end
		else
			local progress = data.quests.active[quest.id]
			if progress then
				for index, step in quest.steps do
					if step.reveals then
						if index < progress.step then
							setFeature(data, step.reveals, "open")
						elseif index == progress.step then
							setFeature(data, step.reveals, "introduced")
						end
					end
				end
			end
		end
	end
end

-- Q-3: quests this player may accept now (startable, not auto, has a Naskah dialog). Sent to the client as QuestOffers;
-- the client shows `!` on the giver and plays the start dialog, then sends QuestAccept.
local function offeredIds(player: Player, data: Types.PlayerData): { string }
	local ids = {}
	if not TutorialService.KolamDone(data) then
		return ids
	end
	for _, quest in Quests.list do
		if quest.auto ~= true and hasDialog(quest) and isStartable(player, data, quest) then
			table.insert(ids, quest.id)
		end
	end
	return ids
end

local function sendOffers(player: Player)
	local data = DataService.Get(player)
	if data then
		Net.Fire("QuestOffers", player, offeredIds(player, data))
	end
end

-- Q-3: the player accepted an offered quest (after its start dialog). The server checks the offer again and starts it.
local function onAccept(player: Player, questId: any)
	if typeof(questId) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	local quest = Quests.byId[questId]
	if not data or not quest or not table.find(offeredIds(player, data), questId) then
		sendOffers(player) -- the client drops its "accepted" mark on every answer
		return
	end
	if not startQuest(player, data, quest) then
		sendOffers(player) -- kandang penuh / belum ada plot: tetap ditawarkan, coba lagi
		return
	end
	advance(player, data, quest, data.quests.active[questId])
	startAvailable(player, data)
	syncFeatures(data)
	InventoryService.Sync(player)
	sendOffers(player)
end

local function reportEvent(player: Player, event: string, amount: number?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if not TutorialService.KolamDone(data) then
		return -- Playtest 7: nothing is counted while the tutorial runs (no quest, Agenda, Harian, Mingguan, Surat)
	end
	local add = amount or 1
	if AgendaService.Report(player, event, add) then -- Agenda 5 tugas (P2-7); true = satu tugas selesai
		QuestService.Report(player, "agenda_done")
	end
	SuratService.Report(player, event, add) -- Surat Kakek 30 (P2-7-fix)
	rollHarian(data, os.time())
	rollMingguan(data, os.time())
	reportSlots(player, data.quests.harian.slots, Quests.HARIAN, "quest_harian", event, add)
	reportSlots(player, data.quests.mingguan.slots, Quests.MINGGUAN, "quest_mingguan", event, add)
	local changed = false

	for questId, progress in data.quests.active do
		local quest = Quests.byId[questId]
		if quest then
			if quest.anyOf == true then
				changed = true
				reportAnyOf(player, data, quest, progress, event, add)
			else
				local step = quest.steps[progress.step]
				if step and step.event == event then
					changed = true
					progress.count += add
				end
				if advance(player, data, quest, progress) then
					changed = true
				end
			end
		end
	end

	if changed then
		startAvailable(player, data) -- finishing a quest can unlock the next one (`after`)
		syncFeatures(data)
		InventoryService.Sync(player)
		sendOffers(player)
	end
end

function QuestService.Report(player: Player, event: string, amount: number?)
	reportEvent(player, event, amount)
end

-- Event dari klien untuk UI yang tidak punya remote sendiri (buka Agenda, lihat Gerobak, baca Surat).
local function onUiReport(player: Player, event: any)
	if typeof(event) ~= "string" or UI_EVENTS[event] ~= true then
		return
	end
	-- Q-2 gate "surat": baca surat hanya bila fitur terbuka (introduced saat langkah s2_surat aktif, open setelah selesai).
	if event == "surat_read" then
		if not FeatureGate.Check(player, "surat") then
			return
		end
		-- R2.3: reading shows the letter again (the text the login toast would show) and counts for Quest S2.
		local data = DataService.Get(player)
		local n = if data then SuratService.Current(data) else 0
		if data and n > 0 and n <= data.surat.logins then
			Net.Fire("Notify", player, "surat.new", { n = n, text = `surat.{n}.text` })
		end
	end
	reportEvent(player, event, 1)
end

-- On join: rolls today's Daily and starts any quest the player now qualifies for.
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
	if TutorialService.KolamDone(data) then
		AgendaService.Roll(data, os.time())
		rollHarian(data, os.time())
		rollMingguan(data, os.time())
	end
	startAvailable(player, data)
	syncFeatures(data)
	for questId, progress in data.quests.active do
		local quest = Quests.byId[questId]
		if not quest then
			data.quests.active[questId] = nil -- quest yang sudah dihapus dari Config (save lama)
		elseif quest.anyOf ~= true then
			advance(player, data, quest, progress) -- langkah barang (tanpa event) bisa sudah terpenuhi
		end
	end
	startAvailable(player, data)
	syncFeatures(data)
	InventoryService.Sync(player)
	sendOffers(player)
end

-- Setor Kolam Kakek: hanya berpengaruh bila M3 sedang di langkah 1 dan barangnya ada (cek di advance()).
local function onKakekSetor(player: Player)
	reportEvent(player, "kakek_setor", 1)
end

-- DEV (K-64): !quest selesai <id> and !buka <fitur> use the same finish and feature code as the real quests.
function QuestService.DevFinish(player: Player, questId: string): string
	local data = DataService.Get(player)
	local quest = Quests.byId[questId]
	if not data or not quest then
		return "quest tidak dikenal"
	end
	if data.quests.done[questId] then
		return "sudah selesai"
	end
	if data.quests.active[questId] == nil and not startQuest(player, data, quest) then
		return "tidak bisa dimulai"
	end
	finishQuest(player, data, quest)
	InventoryService.Sync(player)
	return "selesai"
end

-- DEV (K-64): "!quest mulai <id>" starts a quest through the same start code (no dialogue).
function QuestService.DevStart(player: Player, questId: string): string
	local data = DataService.Get(player)
	local quest = Quests.byId[questId]
	if not data or not quest then
		return "quest tidak dikenal"
	end
	if data.quests.done[questId] or data.quests.active[questId] then
		return "sudah dimulai/selesai"
	end
	if not startQuest(player, data, quest) then
		return "tidak bisa dimulai"
	end
	InventoryService.Sync(player)
	return "mulai"
end

function QuestService.DevOpenFeature(player: Player, featureId: string)
	if featureId == "semua" then
		local data = DataService.Get(player)
		if data then
			for _, id in FeatureGate.GatedIds() do
				setFeature(data, id, "open")
			end
			syncFeatures(data)
			InventoryService.Sync(player)
		end
		return
	end
	local data = DataService.Get(player)
	if data then
		setFeature(data, featureId, "open")
		syncFeatures(data)
		InventoryService.Sync(player)
	end
end

function QuestService.Init()
	Net.On("QuestReport", onUiReport, { rate = 4, burst = 8 })
	Net.On("QuestAccept", onAccept, { rate = 4, burst = 8 })
	Net.On("QuestOffersRequest", function(player: Player)
		sendOffers(player) -- the client asks once it is ready (a join-time send could arrive before its listener)
	end, { rate = 2, burst = 4 })
	Net.On("KakekSetor", onKakekSetor, { rate = 2, burst = 4 })
	DataService.Loaded:Connect(evaluate)
	ProgressionService.LevelUp:Connect(evaluate)
	TutorialService.Finished:Connect(function(player: Player, tutorialId: string)
		if tutorialId == "t1b_kolam" then
			-- Playtest 7: Harian/Mingguan/Agenda start fresh now (progress 0, nothing from the tutorial counted).
			local data = DataService.Get(player)
			if data then
				data.quests.harian = { day = "", slots = {} }
				data.quests.mingguan = { week = "", slots = {} }
				data.quests.daily = { day = "", kind = "", progress = 0, claimed = false }
			end
			evaluate(player) -- the first quests start the moment the fish-sale tutorial is done
		end
	end)
end

return QuestService
