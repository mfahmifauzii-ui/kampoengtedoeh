--!strict
-- Hadiah mingguan & jangka panjang (docs/01_GDD_Kampoeng_Tedoeh_v8.1.md Bab 15.1 Login, 15.3 Peti Bunga, 15.4 Title, Bab 19 Season).
-- Data + fungsi murni saja. Angka yang bukan dari dokumen ditandai USULAN dan dicatat di Lampiran D.
--   Login Mingguan : 7 hari kumulatif per minggu (Senin 05:00 WIB, TimeKeys.week). Diulang tiap minggu. 10 Bunga per minggu.
--   Peti Bunga     : 1 peti = PETI_BUNGA Bunga (Update owner 2026-11-22). Sumber peti (lihat RewardsService):
--                    tiap Title yang dimiliki (sekali per title), tiap Album milestone 25/50/75/100% (sekali), Season F2P hari 30.
--                    Event completion belum punya definisi di kode, jadi belum dihubungkan (Lampiran D).
--   Title          : permanen, tidak memberi stat (Bab 15.4). Syarat tiap title diambil dari kode (lihat TITLES).
--   Season         : 30 hari. F2P gratis: hadiah tiap 5 hari (USULAN, Lampiran D). Premium: belum dibuka (PREMIUM_OPEN = false).

local Progression = require(script.Parent.Progression)

export type Track = "f2p" | "premium"

local Rewards = {}

-- Login Mingguan, index = hari ke-n dalam minggu (Bab 15.1, angka dari dokumen). 2 + 3 + 5 = 10 Bunga per minggu.
Rewards.LOGIN = {
	{ koin = 100 },
	{ koin = 150 },
	{ koin = 200 },
	{ bunga = 2 },
	{ koin = 300 },
	{ bunga = 3 },
	{ koin = 500, bunga = 5 },
}

-- 1 Peti Bunga (Update owner 2026-11-22: 25 Bunga).
Rewards.PETI_BUNGA = 25

-- Title (Bab 15.4). Syarat diambil dari kode (sumber di kolom komentar). `TITLES` dipakai untuk daftar di panel dan peti per title.
-- Title yang tidak punya sumber di kode (warga_teladan) TIDAK ada di daftar; lihat Lampiran D.
Rewards.TITLES = {
	-- Book.MILESTONES p50: Album 50% lalu klaim "p50" (BookClaim).
	{ id = "kolektor", source = "Album 50%, klaim milestone p50 (Config/Book)" },
	-- Book.MILESTONES p100: Album 100% lalu klaim "p100".
	{ id = "legenda_kampung", source = "Album 100%, klaim milestone p100 (Config/Book)" },
	-- Quest mq12_warga (auto, requireAlbum 50, setelah mq11_legenda).
	{ id = "warga_tedoeh", source = "Quest mq12_warga: MQ11 selesai + Album 50%" },
	-- Quest mq11_legenda: dapat 1 Ikan Legenda + 1 Panen Prima Late.
	{ id = "penakluk_legenda", source = "Quest mq11_legenda: 1 ikan Legenda + 1 Panen Prima Late" },
	-- Quest side_rumah_rapi: pasang 20 piece dekor.
	{ id = "dinding_spesial", source = "Quest side_rumah_rapi: pasang 20 piece dekor" },
	-- Quest side_jumbo: dapat 1 ikan Jumbo.
	{ id = "raja_jumbo", source = "Quest side_jumbo: dapat 1 ikan Jumbo" },
	-- Quest side_kerjabakti: ikut 10 Kerja Bakti.
	{ id = "pekerja_bakti", source = "Quest side_kerjabakti: ikut 10 Kerja Bakti" },
	-- Book.CATEGORY_REWARDS rumah: satu kategori rumah lengkap + klaim.
	{ id = "juragan_pondok", source = "Kategori Album rumah lengkap + klaim (Config/Book CATEGORY_REWARDS)" },
	-- Social.LIKE_MILESTONES 200 like.
	-- K-28: Title dari like tidak memberi Peti Bunga (syarat bergantung pemain lain).
	{ id = "kebun_favorit", source = "Like 200 (Config/Social LIKE_MILESTONES)", noPeti = true },
}

-- Peti Bunga dari Album milestone (sekali per milestone). Id sama dengan Book.MILESTONES.
Rewards.MILESTONE_PETI = { "p25", "p50", "p75", "p100" }

-- Season (Bab 19). Season 1 mulai di tanggal ini (WIB, reset 05:00). Setelah 30 hari, season berikutnya mulai otomatis
-- dan memakai hadiah yang sama.
Rewards.SEASON = {
	DAYS = 30,
	START = { year = 2026, month = 12, day = 1 }, -- USULAN
	PREMIUM_PRICE = 150, -- Bunga per season (Bab 18.4 / Bab 19)
	-- Premium dibeli (150 Bunga) hanya setelah kosmetik eksklusif season ada. Sampai itu: false (UI "Segera hadir").
	PREMIUM_OPEN = false,
	-- F2P: hadiah tiap 5 hari (USULAN, Update owner 2026-11-22). Bunga total 30 (Bab 19). Isi detail: Lampiran D #20.
	F2P = {
		[5] = { items = { bambu = 10 } },
		[10] = { bunga = 5, items = { kayu = 10 } },
		[15] = { items = { batu = 5 } },
		[20] = { bunga = 10, items = { ijuk = 5 } },
		[25] = { items = { bambu = 15, kayu = 10 } },
		[30] = { bunga = 15, items = { atap_ijuk = 2 }, decor = { rumpun_bambu = 1 } },
	} :: { [number]: Progression.Reward },
	-- Premium: 40 Koin tiap hari + Bunga ekstra (total 60 Bunga). Belum aktif (PREMIUM_OPEN).
	PREMIUM_KOIN = 40,
	PREMIUM_BUNGA = { [10] = 10, [20] = 20, [30] = 30 },
}

-- Hadiah satu hari di satu track Season (tanpa peti; peti Season F2P hari 30 ada di RewardsService).
function Rewards.seasonReward(track: Track, day: number): Progression.Reward
	local season = Rewards.SEASON
	if track == "premium" then
		return { koin = season.PREMIUM_KOIN, bunga = season.PREMIUM_BUNGA[day] }
	end
	return season.F2P[day] or {}
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
