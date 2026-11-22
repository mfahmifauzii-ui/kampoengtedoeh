--!strict
-- Hadiah mingguan & jangka panjang (docs/Kampoeng_Tedoeh_v7.5.md Bab 15.1 Login, 15.3 Peti Bunga, 15.4 Title, Bab 19 Season).
-- Data + fungsi murni saja. Angka yang bukan dari dokumen ditandai USULAN dan dicatat di Lampiran D #15-#18.
--   Login Mingguan : 7 hari kumulatif per minggu (Senin 05:00 WIB, TimeKeys.week). Hari yang sudah login tidak hilang kalau
--                    tidak login di hari lain. Tiap minggu mulai dari nol lagi (diulang tiap minggu).
--   Peti Bunga     : 1 peti = PETI_BUNGA Bunga. Didapat tiap kali 1 Title baru dimiliki (USULAN).
--   Title          : permanen, tidak memberi stat (Bab 15.4). Tiap title baru memberi 1 Peti Bunga (USULAN).
--   Season         : 30 hari, 2 track. F2P gratis. Premium = beli PREMIUM_PRICE Bunga per season, lalu bisa ambil track Premium.

local Progression = require(script.Parent.Progression)

export type Track = "f2p" | "premium"

local Rewards = {}

-- Login Mingguan, index = hari ke-n dalam minggu (Bab 15.1, angka dari dokumen).
Rewards.LOGIN = {
	{ koin = 100 },
	{ koin = 150 },
	{ koin = 200 },
	{ bunga = 2 },
	{ koin = 300 },
	{ bunga = 3 },
	{ koin = 500, bunga = 5 },
}

-- 1 Peti Bunga (USULAN: 25 Bunga, sesuai catatan owner).
Rewards.PETI_BUNGA = 25

-- Title (Bab 15.4). `album` = syarat % Album; tanpa `album` = didapat dari quest (Config/Quests reward.title) atau sistem lain.
-- Semua title di Locale "title.<id>". Tidak ada stat.
Rewards.TITLES = {
	{ id = "kolektor", album = 50 }, -- Bab 15.4: Kolektor (Album 50%)
	{ id = "legenda_kampung", album = 100 }, -- Bab 15.4: Legenda Kampung (Album 100%)
	{ id = "warga_tedoeh" }, -- MQ12 (Bab 14.2)
	{ id = "penakluk_legenda" }, -- MQ11
	{ id = "dinding_spesial" },
	{ id = "raja_jumbo" },
	{ id = "pekerja_bakti" },
	{ id = "warga_teladan" },
	{ id = "juragan_pondok" },
	{ id = "kebun_favorit" },
}

-- Season (Bab 19). Season 1 mulai di tanggal ini (WIB, reset 05:00). Setelah 30 hari, season berikutnya mulai otomatis
-- dan memakai hadiah yang sama (USULAN).
Rewards.SEASON = {
	DAYS = 30,
	START = { year = 2026, month = 12, day = 1 }, -- USULAN
	PREMIUM_PRICE = 150, -- Bunga per season (Bab 18.4 / Bab 19)
	-- F2P: 50 Koin tiap hari + Bunga di hari tertentu (total 30 Bunga, Bab 19).
	F2P_KOIN = 50,
	F2P_BUNGA = { [7] = 5, [14] = 5, [21] = 10, [30] = 10 },
	-- Premium: 40 Koin tiap hari + Bunga ekstra (total 60 Bunga; harga 150, jadi tetap ada biaya).
	PREMIUM_KOIN = 40,
	PREMIUM_BUNGA = { [10] = 10, [20] = 20, [30] = 30 },
}

-- Hadiah satu hari di satu track Season.
function Rewards.seasonReward(track: Track, day: number): Progression.Reward
	local season = Rewards.SEASON
	if track == "premium" then
		return { koin = season.PREMIUM_KOIN, bunga = season.PREMIUM_BUNGA[day] }
	end
	return { koin = season.F2P_KOIN, bunga = season.F2P_BUNGA[day] }
end

-- Season yang sedang berjalan: (id, hari ke-1..DAYS). Hari baru mulai jam 05:00 WIB seperti hari lain di game.
function Rewards.seasonNow(now: number): (string, number)
	local start = Rewards.SEASON.START
	local startEpoch = os.time({ year = start.year, month = start.month, day = start.day, hour = 0 }) -- os.time memakai UTC
	local shifted = now + Progression.UTC_OFFSET - Progression.RESET_HOUR * 3600
	local index = (shifted - startEpoch) // 86400
	return `S{index // Rewards.SEASON.DAYS + 1}`, index % Rewards.SEASON.DAYS + 1
end

return Rewards
