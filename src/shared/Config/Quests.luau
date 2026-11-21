--!strict
-- Quest definitions (data only). A quest appears once the player reaches `unlockLevel` and, if set, finished the
-- quest named in `after`. It has one or more STEPS done in order; each step counts one game event.
-- Events are reported by the services with QuestService.Report(player, event, amount):
--   "pond_built"  a pond was dug (PondService)
--   "catch_pond"  a fish was reeled in at one of your ponds (FishService)
-- Locale keys: quest.<id>.title, quest.<id>.s<step> (step text, may use {n} = how many are needed).

local Progression = require(script.Parent.Progression)

export type Step = {
	event: string,
	count: number,
}

export type Quest = {
	id: string,
	unlockLevel: number,
	after: string?,
	requireTutorial: boolean?, -- Stage 7: starts only after T1 (guide.done.t1_awal)
	requireKakek: boolean?, -- P2-2: starts only after Kolam Kakek pulih (MQ4/Bundel P2-7)
	bonusDecor: string?, -- Stage 7: decor item added to the stock as a reward (free)
	steps: { Step },
	reward: Progression.Reward,
}

local list: { Quest } = {
	{
		id = "kolam_pertama",
		unlockLevel = 2, -- same level the Kolam fishing location opens (Config/Fishing)
		requireKakek = true, -- P2-2: Kolam Kakek keluar dari tutorial (MQ4/Bundel P2-7)
		steps = {
			{ event = "pond_built", count = 1 }, -- the first pond is free
			{ event = "catch_pond", count = 1 },
		},
		reward = { koin = 300, xp = 60 },
	},
	-- Stage 7: Misi Utama, the 3 steps after T1. Only these 3 + one Daily per day exist for now.
	{
		id = "misi_utama",
		unlockLevel = 1,
		requireTutorial = true,
		steps = {
			{ event = "plant_kangkung", count = 3 }, -- Tanam 3 Kangkung
			{ event = "catch", count = 1 }, -- Mancing 1 Ikan
			{ event = "decor_placed", count = 1 }, -- Taruh 1 Hiasan
		},
		reward = { koin = 50 },
		bonusDecor = "pagar_bambu",
	},
}

-- Agenda Harian (Kampoeng_Tedoeh_v7.3 Bab 14.5, LOCKED): 5 tugas per hari, reset 05:00 WIB. Contoh: Panen 5 tanaman,
-- Mancing 3 ikan, Masak 1 olahan, Bantu 1 lahan, Nambang 10 bahan. Hadiah 150-400 Koin per tugas, tanpa Bunga.
-- Split per tugas di bawah ini USULAN interim (v7.3 cuma mengunci rentang 150-400); kunci final ikut playtest Bab 17.8.
-- XP di bawah ini USULAN (v7.3 Bab 14.5 tidak memberi XP; contoh P1-9: Agenda cuma Koin) — butuh lock owner.
-- Tugas P2-7: Agenda bisa dipilih player (semua 5 aktif, player memilih mana yang dikerjakan).
export type Daily = { id: string, event: string, count: number, reward: Progression.Reward }
local DAILY: { Daily } = {
	{ id = "panen", event = "harvest", count = 5, reward = { koin = 200, xp = 30 } },
	{ id = "pancing", event = "catch", count = 3, reward = { koin = 250, xp = 40 } },
	{ id = "masak", event = "cook", count = 1, reward = { koin = 300, xp = 45 } },
	{ id = "bantu", event = "bantu", count = 1, reward = { koin = 150, xp = 25 } },
	{ id = "nambang", event = "mine", count = 10, reward = { koin = 400, xp = 60 } },
}
local DAILY_RESET_HOUR = 5 -- WIB

-- Quest Harian (Bab 9-10, P2-7): 3 quest per hari, reset 05:00 WIB, hadiah Koin + XP + Bunga.
-- Jumlah Bunga per quest = USULAN (v7.3 tak memberi angka; butuh lock owner/playtest 17.8).
-- Tidak bisa di-reroll, tidak bisa ditumpuk (3 jenis beda per hari).
local HARIAN: { Daily } = {
	{ id = "panen_besar", event = "harvest", count = 10, reward = { koin = 300, xp = 50, bunga = 2 } },
	{ id = "pancing_banyak", event = "catch", count = 5, reward = { koin = 350, xp = 55, bunga = 2 } },
	{ id = "masak_banyak", event = "cook", count = 2, reward = { koin = 400, xp = 60, bunga = 3 } },
	{ id = "bantu_banyak", event = "bantu", count = 2, reward = { koin = 250, xp = 40, bunga = 2 } },
	{ id = "nambang_banyak", event = "mine", count = 20, reward = { koin = 450, xp = 65, bunga = 3 } },
}
local HARIAN_COUNT = 3

-- Quest Mingguan (Bab 9-10, P2-7): 3 quest per minggu, reset Senin 05:00 WIB (TimeKeys.week), hadiah lebih besar.
-- Reward = USULAN (v7.3 tak memberi angka; butuh lock owner/playtest 17.8).
local MINGGUAN: { Daily } = {
	{ id = "panen_sepekan", event = "harvest", count = 30, reward = { koin = 1000, xp = 180, bunga = 8 } },
	{ id = "pancing_sepekan", event = "catch", count = 15, reward = { koin = 1100, xp = 200, bunga = 8 } },
	{ id = "masak_sepekan", event = "cook", count = 6, reward = { koin = 1200, xp = 220, bunga = 10 } },
	{ id = "bantu_sepekan", event = "bantu", count = 5, reward = { koin = 900, xp = 160, bunga = 8 } },
	{ id = "nambang_sepekan", event = "mine", count = 60, reward = { koin = 1300, xp = 240, bunga = 12 } },
}
local MINGGUAN_COUNT = 3

local byId: { [string]: Quest } = {}
for _, quest in list do
	byId[quest.id] = quest
end

return {
	list = list,
	byId = byId,
	DAILY = DAILY,
	AGENDA = DAILY, -- nama baru (P2-7); DAILY dipertahankan untuk kompatibilitas
	HARIAN = HARIAN,
	HARIAN_COUNT = HARIAN_COUNT,
	MINGGUAN = MINGGUAN,
	MINGGUAN_COUNT = MINGGUAN_COUNT,
	DAILY_RESET_HOUR = DAILY_RESET_HOUR,
}
