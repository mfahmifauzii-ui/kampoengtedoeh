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
	requireAlbum: number?, -- P2-7-fix: mulai hanya bila % Album >= nilai (MQ12, Side Kolektor)
	auto: boolean?, -- P2-7-fix: selesai saat mulai (tanpa langkah; MQ1/MQ4/MQ6, Side Kolektor)
	anyOf: boolean?, -- P2-7-fix: langkah mana pun yang selesai = quest selesai (MQ11 Legenda/Prima Late)
	giveHewan: string?, -- P2-7-fix: beri 1 ekor via RanchService.Give (MQ6 Ayam)
	unlockKakek: boolean?, -- P2-7-fix: set pond.kakekUnlocked (MQ4, Bundel Kolam Kakek)
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
	-- MQ: Main Quest linear, cerita Kakek (Bab 14.2, LOCKED, P2-7-fix). Berurutan via `after`.
	{
		id = "mq1_pulang",
		unlockLevel = 1,
		auto = true,
		steps = {},
		reward = { koin = 100, items = { seed_kangkung = 4 } },
	},
	{
		id = "mq2_siram",
		unlockLevel = 1,
		after = "mq1_pulang",
		steps = {
			{ event = "water", count = 1 }, -- Siram 1 tanaman
		},
		reward = { koin = 50, xp = 20 },
	},
	{
		id = "mq3_panen",
		unlockLevel = 1,
		after = "mq2_siram",
		steps = {
			{ event = "harvest", count = 1 }, -- Panen 1 tanaman (dijamin Super)
		},
		reward = { koin = 100, xp = 30 },
	},
	{
		id = "mq4_kolam",
		unlockLevel = 3,
		after = "mq3_panen",
		auto = true, -- Lv 3, Mak Sari datang: Kolam Kakek pulih
		unlockKakek = true,
		steps = {},
		reward = { koin = 0 },
	},
	-- MQ5/MQ7/MQ8: Bubu/Tungku belum ada sistemnya di src. Reward Koin interim = USULAN (butuh lock owner).
	{
		id = "mq5_bubu",
		unlockLevel = 6,
		after = "mq4_kolam",
		steps = {
			{ event = "catch", count = 3 }, -- Mancing 3 ikan (Bubu menyusul)
		},
		reward = { koin = 150 },
	},
	{
		id = "mq6_kokok",
		unlockLevel = 5,
		after = "mq5_bubu",
		auto = true, -- Lv 5, Pak Udin: Ayam gratis (pakan penuh) + kandang Lv1 bila belum ada
		giveHewan = "ayam",
		steps = {},
		reward = { koin = 0 },
	},
	{
		id = "mq7_dapur",
		unlockLevel = 6,
		after = "mq6_kokok",
		steps = {
			{ event = "dapur_built", count = 1 }, -- Craft Dapur Tier 1
		},
		reward = { koin = 200 },
	},
	{
		id = "mq8_jebakan",
		unlockLevel = 6,
		after = "mq7_dapur",
		steps = {
			{ event = "catch", count = 5 }, -- Mancing 5 ikan (Jebakan Kak Fajar = Bubu, menyusul)
		},
		reward = { koin = 250 },
	},
	-- MQ9: "Slot Warung" kedua belum ada sistem (Warung 1 slot). Reward Koin saja; slot = USULAN.
	{
		id = "mq9_warung",
		unlockLevel = 6,
		after = "mq8_jebakan",
		steps = {
			{ event = "warung_sale", count = 1 }, -- Jual 1 olahan di Warung sendiri
		},
		reward = { koin = 200 },
	},
	{
		id = "mq10_bundel",
		unlockLevel = 8,
		after = "mq9_warung",
		steps = {
			{ event = "bundel_done", count = 1 }, -- Pulihkan 1 Bundel Kakek
		},
		reward = { koin = 300, bunga = 5 },
	},
	-- MQ11: Legenda ATAU Prima Late (anyOf, Bab 14.2). Title "Penakluk Legenda" = USULAN (v7.3 cuma "Title").
	{
		id = "mq11_legenda",
		unlockLevel = 15,
		after = "mq10_bundel",
		anyOf = true,
		steps = {
			{ event = "catch_legenda", count = 1 }, -- Dapat 1 Ikan Legenda
			{ event = "harvest_prima_late", count = 1 }, -- Panen 1 Prima Late
		},
		reward = { koin = 500, title = "penakluk_legenda" },
	},
	{
		id = "mq12_warga",
		unlockLevel = 15,
		after = "mq11_legenda",
		requireAlbum = 50,
		auto = true, -- semua MQ + 50% Album: Title Warga Kampoeng Tedoeh + 10 Bunga
		steps = {},
		reward = { koin = 0, bunga = 10, title = "warga_tedoeh" },
	},
	-- Side Quest (Bab 14.4, LOCKED, P2-7-fix). Syarat buka = USULAN (v7.3 tak memberi).
	-- Kucing Alun-alun + Joran Hilang BELUM BISA: tidak ada sistem kucing / joran hilang di src (tunggu P2-9).
	{
		id = "side_rumah_rapi",
		unlockLevel = 8,
		steps = {
			{ event = "decor_placed", count = 20 }, -- Pasang 20 piece (Pak Amran)
		},
		reward = { title = "dinding_spesial" },
	},
	{
		id = "side_tetangga",
		unlockLevel = 5,
		steps = {
			{ event = "bantu", count = 10 }, -- Bantu 10 lahan (Nek Ani)
		},
		reward = { koin = 300 },
	},
	{
		id = "side_resep",
		unlockLevel = 6,
		steps = {
			{ event = "cook", count = 3 }, -- Masak 3 olahan (Mak Sari; "berbeda" belum ditegakkan, hitung total)
		},
		reward = { koin = 100 },
	},
	{
		id = "side_prima",
		unlockLevel = 8,
		steps = {
			{ event = "harvest_prima", count = 5 }, -- Panen 5 Kualitas Prima (Mak Sari)
		},
		reward = { koin = 200 },
	},
	{
		id = "side_jumbo",
		unlockLevel = 10,
		steps = {
			{ event = "catch_jumbo", count = 1 }, -- Dapat 1 Ikan Jumbo (Kak Fajar)
		},
		reward = { koin = 200, title = "raja_jumbo" },
	},
	{
		id = "side_kolektor",
		unlockLevel = 1,
		requireAlbum = 25,
		auto = true, -- Capai 25% Album (Nek Ani)
		steps = {},
		reward = { koin = 0, bunga = 10 },
	},
	{
		id = "side_kerjabakti",
		unlockLevel = 1,
		steps = {
			{ event = "kb", count = 10 }, -- Ikut 10 Kerja Bakti (Nek Ani)
		},
		reward = { koin = 500, title = "pekerja_bakti" },
	},
	{
		id = "side_warung",
		unlockLevel = 6,
		steps = {
			{ event = "warung_sale", count = 10 }, -- Jual 10 olahan di Warung sendiri (Mak Sari)
		},
		reward = { koin = 300 },
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
