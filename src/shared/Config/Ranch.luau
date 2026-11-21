--!strict
-- Ternak + Kolam breeding (Kampoeng_Tedoeh_v7.3 Bab 7.1 / 7.2, LOCKED).
-- Loop ternak: Beli hewan -> Isi pakan -> Produksi jalan walau offline -> Ambil -> Jual / olah (Dapur P2-3).
-- Hewan tidak mati/sakit/kabur. Tidak ada daging. Tidak ada kasih minum / bar haus.
-- Loop kolam: Simpan 2 ikan sejenis non-Legenda -> Pakan Ikan 20 Koin -> Tunggu -> 1 anak (@M/Sedang).
--
-- Tempat Pakan: max 3 jatah per ekor (skill Tempat Pakan Besar max 5 = P2-4 Skill-16).
-- 1 siklus = 1 jatah per ekor. Jatah habis = produksi berhenti (idle). Produk menumpuk max 3 per ekor.
-- Ukuran kandang (stud, Bab 7.1) dipetakan ke sel grid 8 stud: Ayam 12x12 -> 2x2, Bebek 14x14 -> 2x2,
-- Sapi 18x16 -> 3x2. Satu kandang per jenis hewan; upgrade Lv1 -> Lv2 menaikkan kapasitas isi.

export type Product = {
	item: string, -- telur_ayam / telur_bebek / susu
	minutes: number, -- cooldown 1 siklus produksi
	sell: number, -- harga jual per produk (Koin)
	xp: number, -- XP per produk diambil
}

export type Hewan = {
	id: string, -- "ayam"
	unlockLevel: number,
	price: number, -- Koin per ekor
	maxAnimals: { number }, -- [tier] kapasitas isi kandang Lv1 / Lv2
	feedPrice: number, -- Koin per jatah pakan
	product: Product,
}

export type Cost = { koin: number, mats: { { id: string, count: number } } }

export type KandangCost = {
	size: { number }, -- { selX, selZ } dalam sel grid
	build: Cost,
	upgrade: Cost,
}

export type KolamTier = {
	id: string, -- "tanah"
	unlockLevel: number,
	koin: number,
	mats: { { id: string, count: number } },
	hours: number, -- waktu breeding 1 siklus
	cap: number, -- Kapasitas Simpan (ikan)
}

local HEWAN: { Hewan } = {
	{
		id = "ayam",
		unlockLevel = 5,
		price = 300,
		maxAnimals = { 6, 10 },
		feedPrice = 15,
		product = { item = "telur_ayam", minutes = 15, sell = 40, xp = 10 },
	},
	{
		id = "bebek",
		unlockLevel = 10,
		price = 600,
		maxAnimals = { 5, 8 },
		feedPrice = 20,
		product = { item = "telur_bebek", minutes = 20, sell = 55, xp = 13 },
	},
	{
		id = "sapi",
		unlockLevel = 22,
		price = 3500,
		maxAnimals = { 2, 4 },
		feedPrice = 30,
		product = { item = "susu", minutes = 30, sell = 160, xp = 28 },
	},
}

local KANDANG: { [string]: KandangCost } = {
	ayam = {
		size = { 2, 2 },
		build = { koin = 800, mats = { { id = "kayu", count = 15 } } },
		upgrade = { koin = 3000, mats = { { id = "papan", count = 20 } } },
	},
	bebek = {
		size = { 2, 2 },
		build = { koin = 1200, mats = { { id = "kayu", count = 20 } } },
		upgrade = { koin = 5000, mats = { { id = "papan", count = 25 }, { id = "bata", count = 10 } } },
	},
	sapi = {
		size = { 3, 2 },
		build = { koin = 4000, mats = { { id = "kayu", count = 30 }, { id = "bata", count = 15 } } },
		upgrade = { koin = 10000, mats = { { id = "bata", count = 30 }, { id = "semen", count = 15 } } },
	},
}

local KOLAM_TIERS: { KolamTier } = {
	{ id = "tanah", unlockLevel = 3, koin = 1000, mats = { { id = "batu", count = 20 } }, hours = 6, cap = 10 },
	{ id = "semen", unlockLevel = 15, koin = 3000, mats = { { id = "bata", count = 20 }, { id = "semen", count = 15 } }, hours = 5, cap = 20 },
	{ id = "keramik", unlockLevel = 30, koin = 6000, mats = { { id = "bata", count = 30 }, { id = "semen", count = 25 } }, hours = 4, cap = 30 },
}

local byHewan: { [string]: Hewan } = {}
for _, hewan in HEWAN do
	byHewan[hewan.id] = hewan
end

-- Hewan Varian Gerobak Kaget (Bab 13.1, P2-6): tinggal di kandang grupnya, produksi = base.
-- Harga Gerobak = 2x base (USULAN, v7.3 tak memberi harga). Kosmetik = data tercatat;
-- model 3D varian belum ada, pakai model base.
local VARIAN: { [string]: { kandang: string, price: number } } = {
	ayam_cemani = { kandang = "ayam", price = 600 },
	bebek_belang = { kandang = "bebek", price = 1200 },
}

local byTier: { [string]: KolamTier } = {}
for _, tier in KOLAM_TIERS do
	byTier[tier.id] = tier
end

-- Ukuran kandang dalam sel grid (dipakai Land.ranchRects di cek tabrakan).
local KANDANG_SIZES: { [string]: { number } } = {}
for id, cost in KANDANG do
	KANDANG_SIZES[id] = cost.size
end

return {
	HEWAN = HEWAN,
	byHewan = byHewan,
	VARIAN = VARIAN,
	KANDANG = KANDANG,
	KOLAM_TIERS = KOLAM_TIERS,
	byTier = byTier,

	KANDANG_SIZES = KANDANG_SIZES,

	FEED_MAX = 3, -- jatah per ekor TANPA skill (lihat FeedMax di bawah)
	PROD_MAX = 3, -- produk menumpuk per ekor
	PAKAN_JAGUNG = { jagung = 5, jatah = 6 }, -- 5 Jagung -> 6 jatah Pakan Ayam (kandang ayam saja)
	BREED_FEED_KOIN = 20, -- Pakan Ikan per 1x breeding
	KAKEK_MULT = 0.9, -- Kolam Kakek breeding 10% lebih cepat
	MOOD_SECONDS = 300, -- 5 menit setelah hujan selesai (Bab 7.1 Mood Hujan, LOCKED)
	MOOD_KOIN_MULT = 0.1, -- produk diambil di window mood: +10% Koin
	MOOD_BREED_MULT = 0.9, -- breeding dimulai di window mood: -10% waktu

	-- Tempat Pakan Besar (Bab 4.5, P2-4): max jatah 3 -> 5 saat skill lv >= 1 (USULAN: v7.3
	-- tidak merinci progresi per level; final ikut owner/playtest 17.8).
	FeedMax = function(skillLv: number): number
		return if skillLv >= 1 then 5 else 3
	end,
}
