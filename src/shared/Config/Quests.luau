--!strict
-- Quest definitions (data only). Source: docs/03_Quest_Naskah.md.
--
-- kind     "main" = opens new gameplay or a story milestone (banner Dimulai/Selesai). One at a time, in `after` order.
--          "side" = continues gameplay that is already open (toast only). Runs in parallel, never blocks a main.
-- giver    NPC id (Config/Npcs) who gives the quest.
-- after    main only: the previous main quest. A main waits until it is done (queue when levels are skipped).
-- steps    in order. A step is one of:
--            { event, count }                 counted by QuestService.Report(player, event, amount)
--            { items, consume? }              done when the player holds every item (no event). consume = taken on completion.
--            { event, count, items, consume? } event first, then the items check (deposit steps, e.g. "kakek_setor").
-- reveals  feature id (Q-2 feature gate): "introduced" while the step is active, "open" once it completes.
-- reward   Progression.Reward. freePond = 1 free pond build. unlockKakek = pond.kakekUnlocked.
-- blocked  reason string: quest is listed but never starts (its system does not exist in src yet).
--
-- Item keys in `items`: an item id, or "early:any" (any Early fish, rarity C, Config/Fish).
-- Events: services report them with QuestService.Report. UI-only events come from the client through "QuestReport"
-- (whitelist in QuestService). Locale keys: quest.<id>.title, quest.<id>.s<n> (may use {n}).

local Progression = require(script.Parent.Progression)
local Features = require(script.Parent.Features)

-- K-73: S6 and side_tetangga need Bantu. While Features.BANTU_ENABLED is false they are listed as blocked and never start.
local BANTU_BLOCKED = if Features.BANTU_ENABLED then nil else "Bantu ditunda (K-73)"

export type Step = {
	event: string?,
	count: number,
	items: { [string]: number }?,
	consume: boolean?,
	reveals: string?,
	target: string?, -- tempat yang ditunjuk panah Quest Log saat langkah ini aktif: id NPC, atau nama objek di Workspace
}

export type Quest = {
	id: string,
	kind: "main" | "side",
	giver: string,
	unlockLevel: number,
	after: string?,
	steps: { Step },
	reward: Progression.Reward,
	freePond: boolean?,
	unlockKakek: boolean?,
	requireAlbum: number?, -- mulai hanya bila % Album >= nilai (MQ12, Side Kolektor)
	auto: boolean?, -- selesai saat mulai (tanpa langkah): MQ12, Side Kolektor
	anyOf: boolean?, -- langkah mana pun yang selesai = quest selesai (MQ11 Legenda / Prima Late)
	giveHewan: string?, -- diberi 1 ekor saat quest mulai (M5 Ayam); gagal = coba lagi berikutnya
	blocked: string?,
}

local list: { Quest } = {
	-- ===== Main Quest (Bab 4.1) =====
	{
		id = "m1_kampung",
		kind = "main",
		giver = "nek_ani",
		unlockLevel = 2,
		steps = {
			{ event = "agenda_open", count = 1, reveals = "agenda" },
			{ event = "agenda_done", count = 1 },
			{ event = "gerobak_view", count = 1, reveals = "gerobak" },
		},
		reward = { koin = 100 },
	},
	{
		id = "m2_hutan",
		kind = "main",
		giver = "pak_amran",
		unlockLevel = 4,
		after = "m1_kampung",
		steps = {
			{ event = "mine", count = 1, reveals = "hutan" }, -- pergi ke Hutan Nambang = pukul 1 node
			{ count = 1, items = { batu = 10, kayu = 9 } }, -- kumpulkan 10 Batu + 9 Kayu (tidak diambil di sini)
			{ event = "craft_papan", count = 2, reveals = "craft" }, -- 2 Papan = 4 Kayu (Config/Mining resep papan)
		},
		reward = { koin = 50, xp = 20 },
	},
	{
		id = "m3_kolam_kakek",
		kind = "main",
		giver = "kak_fajar",
		unlockLevel = 4,
		after = "m2_hutan",
		steps = {
			-- Setor 10 Batu + 5 Kayu + 3 ikan Early. Sisa kayu M2 = 5 (9 - 4 untuk papan), pas.
			{ event = "kakek_setor", count = 1, items = { batu = 10, kayu = 5, ["early:any"] = 3 }, consume = true, reveals = "kolam" },
			{ event = "catch_pond", count = 1 },
		},
		reward = { koin = 300, xp = 60 },
		unlockKakek = true,
		freePond = true,
	},
	{
		id = "m4_pagar",
		kind = "main",
		giver = "pak_amran",
		unlockLevel = 5,
		after = "m3_kolam_kakek",
		steps = {
			{ event = "decor_placed", count = 1, reveals = "hias" },
		},
		reward = {},
	},
	{
		id = "m5_kokok",
		kind = "main",
		giver = "pak_udin",
		unlockLevel = 5,
		after = "m4_pagar",
		giveHewan = "ayam",
		steps = {
			{ event = "feed_animal", count = 1, reveals = "kandang_ayam" },
			{ event = "collect_egg", count = 1 },
		},
		reward = {},
	},
	{
		id = "m6_dapur",
		kind = "main",
		giver = "mak_sari",
		unlockLevel = 6,
		after = "m5_kokok",
		steps = {
			{ event = "dapur_built", count = 1, reveals = "dapur" }, -- K-94: Tungku dibangun dari panel Dapur (tanpa pointer, lihat R5.8a)
			{ event = "cook", count = 1, target = "Tungku" }, -- masak di Tungku (Dapur) yang sudah berdiri
			{ event = "eat", count = 1, target = "Tungku" },
		},
		reward = { koin = 200 },
	},
	{
		id = "m7_warung",
		kind = "main",
		giver = "mak_sari",
		unlockLevel = 7,
		after = "m6_dapur",
		steps = {
			{ event = "warung_place", count = 1, reveals = "warung" },
			{ event = "warung_sale", count = 1 },
		},
		reward = { koin = 200 },
	},
	{
		id = "m8_bubu",
		kind = "main",
		giver = "kak_fajar",
		unlockLevel = 8,
		after = "m7_warung",
		steps = {
			{ event = "bubu_place", count = 1, reveals = "bubu" }, -- selesai saat bubu terpasang (bubu 6 jam tidak ditunggu)
		},
		reward = {},
	},
	{
		id = "m9_sumur",
		kind = "main",
		giver = "nek_ani",
		unlockLevel = 8,
		after = "m8_bubu",
		steps = {
			{ event = "bundel_sumur_tua", count = 1, reveals = "bundel" }, -- Bundel Sumur Tua (Config/Bundel)
		},
		reward = { koin = 300, bunga = 5 },
	},

	-- ===== Main Quest milestone cerita (Bab 4.4) =====
	{
		id = "mq11_legenda",
		kind = "main",
		giver = "kak_fajar",
		unlockLevel = 15,
		after = "m9_sumur",
		anyOf = true,
		steps = {
			{ event = "catch_legenda", count = 1 }, -- 1 Ikan Legenda
			{ event = "harvest_prima_late", count = 1 }, -- atau 1 Panen Prima Late
		},
		reward = { koin = 500, title = "penakluk_legenda" },
	},
	{
		id = "mq12_warga",
		kind = "main",
		giver = "mak_sari",
		unlockLevel = 15,
		after = "mq11_legenda",
		requireAlbum = 50,
		auto = true, -- semua Main + Album 50%
		steps = {},
		reward = { bunga = 10, title = "warga_tedoeh" },
	},

	-- ===== Side Quest (Bab 4.2) =====
	{
		id = "s1_bibit",
		kind = "side",
		giver = "pak_udin",
		unlockLevel = 1,
		steps = {
			{ event = "buy_seed", count = 2 },
			{ event = "plant_bayam", count = 2 },
		},
		reward = { koin = 50 },
	},
	{
		id = "s2_surat",
		kind = "side",
		giver = "mak_sari",
		unlockLevel = 2,
		steps = {
			{ event = "surat_read", count = 1, reveals = "surat" },
		},
		reward = {},
	},
	{
		id = "s3_tetangga",
		kind = "side",
		giver = "bang_jali",
		unlockLevel = 3,
		steps = {
			{ event = "sell_bang_jali", count = 1, reveals = "jual_bang_jali" },
		},
		reward = {},
	},
	{
		id = "s4_rangka",
		kind = "side",
		giver = "pak_amran",
		unlockLevel = 3,
		steps = {
			{ event = "talk_pak_amran", count = 1 },
		},
		reward = {},
	},
	{
		id = "s5_ikan_kanal",
		kind = "side",
		giver = "kak_fajar",
		unlockLevel = 5,
		steps = {
			{ event = "catch_mid_kanal", count = 1, reveals = "kanal_barat" },
		},
		reward = { koin = 100 },
	},
	{
		id = "s6_tetangga_baik",
		blocked = BANTU_BLOCKED,
		kind = "side",
		giver = "nek_ani",
		unlockLevel = 5,
		steps = {
			{ event = "bantu", count = 1, reveals = "bantu" },
		},
		reward = { koin = 40, xp = 10 },
	},
	{
		id = "s7_sawah",
		kind = "side",
		giver = "pak_udin",
		unlockLevel = 9,
		steps = {
			{ event = "plant_padi", count = 1 },
			{ event = "harvest_padi", count = 1 },
		},
		reward = { koin = 100 },
	},
	{
		id = "s8_kandang_bebek",
		kind = "side",
		giver = "pak_udin",
		unlockLevel = 10,
		steps = {
			{ event = "kandang_bebek", count = 1, reveals = "kandang_bebek" },
			{ event = "beli_bebek", count = 1 },
		},
		reward = { koin = 200 },
	},
	{
		id = "s9_empang",
		kind = "side",
		giver = "kak_fajar",
		unlockLevel = 10,
		steps = {
			{ event = "catch_empang", count = 1, reveals = "empang" },
		},
		reward = { koin = 200 },
	},

	-- ===== Side Quest Bab 14.4 (gameplay yang sudah ada). Pemberi = USULAN (belum ada di dokumen). =====
	-- Kucing Alun-alun + Joran Hilang belum bisa: tidak ada sistemnya di src.
	{
		id = "side_rumah_rapi",
		kind = "side",
		giver = "pak_amran",
		unlockLevel = 8,
		steps = {
			{ event = "decor_placed", count = 20 }, -- Pasang 20 piece
		},
		reward = { title = "dinding_spesial" },
	},
	{
		id = "side_tetangga",
		blocked = BANTU_BLOCKED,
		kind = "side",
		giver = "nek_ani",
		unlockLevel = 5,
		steps = {
			{ event = "bantu", count = 10 }, -- Bantu 10 lahan
		},
		reward = { koin = 300 },
	},
	{
		id = "side_resep",
		kind = "side",
		giver = "mak_sari",
		unlockLevel = 6,
		steps = {
			{ event = "cook", count = 3 }, -- Masak 3 olahan (berbeda belum ditegakkan)
		},
		reward = { koin = 200 }, -- K-15: Resep Mak 200 Koin (USULAN)
	},
	{
		id = "side_prima",
		kind = "side",
		giver = "mak_sari",
		unlockLevel = 8,
		steps = {
			{ event = "harvest_prima", count = 5 }, -- Panen 5 Kualitas Prima
		},
		reward = { koin = 200 },
	},
	{
		id = "side_jumbo",
		kind = "side",
		giver = "kak_fajar",
		unlockLevel = 10,
		steps = {
			{ event = "catch_jumbo", count = 1 },
		},
		reward = { koin = 200, title = "raja_jumbo" },
	},
	{
		id = "side_kolektor",
		kind = "side",
		giver = "nek_ani",
		unlockLevel = 1,
		requireAlbum = 25,
		auto = true, -- Capai 25% Album
		steps = {},
		reward = { bunga = 10 },
	},
	{
		id = "side_kerjabakti",
		kind = "side",
		giver = "nek_ani",
		unlockLevel = 2, -- K-81: the pickup prompt opens with the Gerobak gate (M1 step 3, Lv 2)
		steps = {
			{ event = "kb", count = 10 }, -- Ikut 10 Kerja Bakti
		},
		reward = { koin = 500, title = "pekerja_bakti" },
	},
	{
		id = "side_warung",
		kind = "side",
		giver = "mak_sari",
		unlockLevel = 7,
		steps = {
			{ event = "warung_sale", count = 10 }, -- Jual 10 olahan di Warung sendiri
		},
		reward = { koin = 300 },
	},
}

-- Agenda Harian (docs/01_GDD_Kampoeng_Tedoeh_v8.4.md Bab 14.5, LOCKED): 5 tugas per hari, reset 05:00 WIB. Contoh: Panen 5 tanaman,
-- Mancing 3 ikan, Masak 1 olahan, Bantu 1 lahan, Nambang 10 bahan. Hadiah 150-400 Koin per tugas, tanpa Bunga.
-- Split per tugas di bawah ini USULAN interim (v7.3 cuma mengunci rentang 150-400); kunci final ikut playtest Bab 17.8.
-- XP di bawah ini USULAN (v7.3 Bab 14.5 tidak memberi XP; contoh P1-9: Agenda cuma Koin) — butuh lock owner.
-- Tugas P2-7: Agenda bisa dipilih player (semua 5 aktif, player memilih mana yang dikerjakan).
-- D1 (K-56): requires = what the player needs before the template can be picked (level, and a feature when given).
-- hidden = not picked at all for now (Bantu, while Features.BANTU_ENABLED is false, K-73).
export type Requires = { level: number, feature: string? }
export type Daily = { id: string, event: string, count: number, reward: Progression.Reward, requires: Requires?, hidden: boolean? }
local DAILY: { Daily } = {
	{ id = "panen", event = "harvest", count = 5, reward = { koin = 200, xp = 30 }, requires = { level = 1 } },
	{ id = "pancing", event = "catch", count = 3, reward = { koin = 250, xp = 40 }, requires = { level = 1 } },
	{ id = "masak", event = "cook", count = 1, reward = { koin = 300, xp = 45 }, requires = { level = 6, feature = "dapur" } },
	{ id = "bantu", event = "bantu", count = 1, reward = { koin = 150, xp = 25 }, requires = { level = 1 }, hidden = not Features.BANTU_ENABLED }, -- D1 (K-56), K-73: hidden while BANTU_ENABLED is false
	{ id = "tanam", event = "plant", count = 5, reward = { koin = 150, xp = 25 }, requires = { level = 1 } }, -- K-73: pengganti slot Bantu (nilai sama, 150 Koin + 25 XP)
	{ id = "nambang", event = "mine", count = 10, reward = { koin = 400, xp = 60 }, requires = { level = 4, feature = "hutan" } },
}
local DAILY_RESET_HOUR = 5 -- WIB

-- Quest Harian (Bab 9-10, P2-7): 3 quest per hari, reset 05:00 WIB, hadiah Koin + XP + Bunga.
-- Jumlah Bunga per quest = USULAN (v7.3 tak memberi angka; butuh lock owner/playtest 17.8).
-- Tidak bisa di-reroll, tidak bisa ditumpuk (3 jenis beda per hari).
local HARIAN: { Daily } = {
	{ id = "panen_besar", event = "harvest", count = 10, reward = { koin = 300, xp = 50, bunga = 2 }, requires = { level = 1 } },
	{ id = "pancing_banyak", event = "catch", count = 5, reward = { koin = 350, xp = 55, bunga = 2 }, requires = { level = 1 } },
	{ id = "masak_banyak", event = "cook", count = 2, reward = { koin = 400, xp = 60, bunga = 3 }, requires = { level = 6, feature = "dapur" } },
	{ id = "nambang_banyak", event = "mine", count = 20, reward = { koin = 450, xp = 65, bunga = 3 }, requires = { level = 4, feature = "hutan" } },
}
local HARIAN_COUNT = 3

-- Quest Mingguan (Bab 9-10, P2-7): 3 quest per minggu, reset Senin 05:00 WIB (TimeKeys.week), hadiah lebih besar.
-- Reward = USULAN (v7.3 tak memberi angka; butuh lock owner/playtest 17.8).
local MINGGUAN: { Daily } = {
	{ id = "panen_sepekan", event = "harvest", count = 30, reward = { koin = 1000, xp = 180, bunga = 8 }, requires = { level = 1 } },
	{ id = "pancing_sepekan", event = "catch", count = 15, reward = { koin = 1100, xp = 200, bunga = 8 }, requires = { level = 1 } },
	{ id = "masak_sepekan", event = "cook", count = 6, reward = { koin = 1200, xp = 220, bunga = 10 }, requires = { level = 6, feature = "dapur" } },
	{ id = "nambang_sepekan", event = "mine", count = 60, reward = { koin = 1300, xp = 240, bunga = 12 }, requires = { level = 4, feature = "hutan" } },
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
