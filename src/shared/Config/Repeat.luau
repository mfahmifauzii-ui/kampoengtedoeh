--!strict
-- Event Berulang (Kampoeng_Tedoeh Bab 13, LOCKED, P2-6): Gerobak Kaget, Pasar Malam,
-- Kerja Bakti Kilat, Kalender Musiman + Pesanan Tamu.
-- Angka USULAN ditandai; v7.3 memberi struktur + sebagian angka, sisanya butuh lock owner.

export type GerobakSlot = {
	slot: number, -- 1..3
	kind: string, -- "seed" | "bahan" | "decor" | "hewan" | "rare"
	stocked: boolean, -- slot terisi di restock ini
}

local GEROBAK = {
	RESTOCK_SECONDS = 900, -- 15 menit nyata
	MAX_PER_SLOT = 3, -- max 3 beli per slot per restock
	STOCK_CHANCE = { 0.6, 0.35, 0.05 }, -- peluang slot terisi per restock (USULAN: v7.3 ambigu)
	SEED_VARIAN = { "jagung_ungu", "tomat_kuning", "semangka_kotak", "cabai_pelangi", "stroberi_putih", "pisang_merah" },
	SEED_PRICE_MULT = 2, -- bibit varian = 2x seedPrice base (USULAN, v7.3 tak memberi harga)
	BAHAN_POOL = { "kayu", "bambu", "batu", "tanah_liat", "pasir" },
	BAHAN_COUNT = 5, -- per slot
	BAHAN_PRICE = 40, -- per paket bahan (USULAN)
	HEWAN_VARIAN = { "ayam_cemani", "bebek_belang" },
	DECOR_COMMON = { "bangku_kayu", "pot_tanah_liat", "kursi_kayu", "bunga_kamboja", "lampu_taman", "pagar_bambu" },
	DECOR_RARE = { "gazebo_bambu", "lampion_gantung", "sepeda_onthel", "kursi_rotan" },
}

local PASAR = {
	VISIT_MIN = 300, -- NPC datang tiap ... (pakai pergantian fase malam; durasi malam 9 mnt)
	BUY_MULT = 1.5, -- +50% dari harga base
	MAX_PER_NIGHT = 10, -- max 10 per player per malam
	GELANG_PER_NIGHT = 3, -- Lempar Gelang 3x gratis per malam
	-- Pedagang Tamu rotasi 6 (Bab 13.2: cuma contoh "Pak Kumis Jamu"; 5 nama lain USULAN).
	TRADERS = { "pak_kumis", "nek_esih", "bang_dodo", "mpok_riah", "kang_asep", "yu_tum" },
	GELANG_KOIN = { 50, 150 }, -- Koin kecil
	GELANG_BAHAN_COUNT = { 2, 3 }, -- bahan mentah acak
	GELANG_BUNGA = { 5, 10 }, -- Bunga (pengganti "tiket dekor": belum ada sistem tiket, USULAN)
}

local KERJA = {
	BASE_TRASH = 10, -- kotoran base
	TRASH_PER_PLAYER = 6, -- +6 x player di server
	TRASH_MAX = 58, -- max 58 (untuk 8 player)
	KOIN_PER_POINT = 15, -- 15 Koin per poin
	XP_PER_POINT = 3, -- 3 XP per poin
	MAX_POINTS = 20, -- max 20 poin berhadiah per Kerja Bakti
	MAX_PER_DAY = 4, -- max 4 Kerja Bakti berhadiah per hari
	TIMEOUT_SECONDS = 900, -- 15 menit: sisa kotoran dibersihkan otomatis
	BONUS_KOIN = 150, -- Bonus Kampung 100%: +150 Koin untuk yang punya >= 1 poin
	BONUS_DISCOUNT_SECONDS = 1800, -- Diskon Warga 30 menit nyata (= 1 hari game)
	BONUS_DISCOUNT_MULT = 0.9, -- -10% bibit/umpan/pakan di Toko Pak Udin
}

-- Kalender event (Bab 13.3 + Kalender rilis v7.3). Lebaran + Festival Panen = USULAN tanggal
-- (v7.3: "mengikuti tanggal" / "musim panen" tanpa tanggal pasti).
local KALENDER = {
	{
		id = "agustusan",
		monthStart = 8, dayStart = 10,
		monthEnd = 8, dayEnd = 24,
		decor = { "lampion_gantung", "bunga_kertas", "lampu_taman" },
	},
	{
		id = "lebaran",
		monthStart = 3, dayStart = 20,
		monthEnd = 3, dayEnd = 26,
		decor = { "ketupat_gantung", "pelita_minyak", "bedug_kecil" },
	},
	{
		id = "tahun_baru",
		monthStart = 12, dayStart = 28,
		monthEnd = 1, dayEnd = 7,
		decor = { "lampion_gantung", "bangku_kayu", "lampu_taman" },
	},
	{
		id = "hari_tani",
		monthStart = 9, dayStart = 20,
		monthEnd = 9, dayEnd = 30,
		decor = { "pot_tanah_liat", "bunga_kamboja", "gentong_air" },
	},
	{
		id = "festival_panen",
		monthStart = 10, dayStart = 1,
		monthEnd = 10, dayEnd = 15,
		decor = { "rumpun_bambu", "jemuran", "pot_tanah_liat" },
	},
}

local TAMU = {
	ITEM_MIN = 3, -- 3-5 barang per Pesanan Tamu
	ITEM_MAX = 5,
	QTY_MIN = 2, -- 2-5 per jenis (USULAN: v7.3 cuma bilang "3-5 barang")
	QTY_MAX = 5,
	KOIN_MULT = 1.5, -- hadiah Koin = 1,5x total nilai base (USULAN)
	BUNGA = 3, -- hadiah Bunga (USULAN jumlah)
}

-- Id restock Gerobak saat ini (15 menit nyata). Sama di server dan client (jam dinding).
local function currentRestock(now: number?): number
	return math.floor((now or os.time()) / GEROBAK.RESTOCK_SECONDS)
end

-- Isi 3 slot Gerobak untuk restockId: deterministik (Random seeded) supaya server dan
-- klien sepakat tanpa sinkronisasi. Bentuk: { { slot, kind, id, count, price, stocked } }.
-- kind: "seed" (seed_x), "bahan" (item mentah), "hewan" (id hewan varian), "decor" (id decor).
local function gerobakOffer(restockId: number): { { slot: number, kind: string, id: string, count: number, price: number, stocked: boolean } }
	local rng = Random.new(restockId)
	local slots = {}
	local seedId = GEROBAK.SEED_VARIAN[rng:NextInteger(1, #GEROBAK.SEED_VARIAN)]
	table.insert(slots, {
		slot = 1,
		kind = "seed",
		id = `seed_{seedId}`,
		count = GEROBAK.MAX_PER_SLOT,
		price = 0, -- dihitung pembeli dari seedPrice x SEED_PRICE_MULT
		stocked = rng:NextNumber() < GEROBAK.STOCK_CHANCE[1],
	})
	local bahanId = GEROBAK.BAHAN_POOL[rng:NextInteger(1, #GEROBAK.BAHAN_POOL)]
	table.insert(slots, {
		slot = 2,
		kind = if rng:NextNumber() < 0.5 then "bahan" else "decor",
		id = "",
		count = GEROBAK.BAHAN_COUNT,
		price = GEROBAK.BAHAN_PRICE,
		stocked = rng:NextNumber() < GEROBAK.STOCK_CHANCE[2],
	})
	local hewanId = GEROBAK.HEWAN_VARIAN[rng:NextInteger(1, #GEROBAK.HEWAN_VARIAN)]
	table.insert(slots, {
		slot = 3,
		kind = if rng:NextNumber() < 0.5 then "hewan" else "rare",
		id = hewanId,
		count = GEROBAK.MAX_PER_SLOT,
		price = 0, -- hewan: Ranch.VARIAN; rare: decor price
		stocked = rng:NextNumber() < GEROBAK.STOCK_CHANCE[3],
	})
	-- Isi id + price slot 2/3 sesuai kind yang terundi (urutan RNG tetap supaya deterministik).
	do
		local rng2 = Random.new(restockId * 31 + 7)
		if slots[2].kind == "decor" then
			local pick = GEROBAK.DECOR_COMMON[rng2:NextInteger(1, #GEROBAK.DECOR_COMMON)]
			slots[2].id = pick
		else
			slots[2].id = bahanId
		end
		if slots[3].kind == "rare" then
			slots[3].id = GEROBAK.DECOR_RARE[rng2:NextInteger(1, #GEROBAK.DECOR_RARE)]
		end
	end
	return slots
end

return {
	GEROBAK = GEROBAK,
	PASAR = PASAR,
	KERJA = KERJA,
	KALENDER = KALENDER,
	TAMU = TAMU,
	currentRestock = currentRestock,
	gerobakOffer = gerobakOffer,
}
