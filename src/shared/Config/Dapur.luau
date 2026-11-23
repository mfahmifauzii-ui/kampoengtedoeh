--!strict
-- Dapur + Warung + Buff Olahan (docs/01_GDD_Kampoeng_Tedoeh_v8.2.md Bab 9.2 / 9.3 / 9.4, LOCKED).
-- 24 resep persis tabel Bab 9.2. Tier Dapur = Tier resep (1/2/3, buka Lv 6/15/35).
-- Kualitas Olahan dari bahan TERTINGGI (ada 1 Prima -> Prima, dst). Harga = base x Kualitas
-- (Biasa x1,0 / Bagus x1,1 / Prima x1,25, pinjam mult Kualitas Panen). Resep branching (pakai
-- olahan sebagai bahan) harganya FIXED di tabel (prinsip 1,6x sudah dihitung di desain, Bab 9.1).
-- Resep ikan pakai kategori (Early=C / Mid=U / Late=R), Legenda tidak bisa dimasak.
-- Pakan Jagung = pakan Ayam (bahan, 6 jatah), BUKAN Olahan: tidak dijual di Warung, tidak memberi buff.

export type Input = {
	kind: string, -- "crop" | "fish" | "garam" | "bahan" | "ternak" | "olahan"
	id: string?, -- cropId / bahanId / ternakId / recipeId (olahan); nil untuk garam & fish
	cat: string?, -- fish: "early" | "mid" | "late"
	count: number,
}

export type Recipe = {
	id: string, -- "tumis_kangkung"
	tier: number, -- 1/2/3 (butuh Dapur tier tsb)
	inputs: { Input },
	minutes: number,
	sell: number?, -- harga base FIXED (resep biasa + branching)
	mult: number?, -- 1.6: harga = round10(1.6 x total nilai base bahan yang dipakai)
	xp: number, -- XP saat ambil olahan jadi
	outputCount: number?, -- Pakan Jagung: 6 (bahan pakan_jagung); olahan lain: 1
}

export type DapurTier = {
	unlockLevel: number,
	mats: { { id: string, count: number } }, -- craft Inti (tanpa Koin)
	slots: number,
	timeMult: number, -- 1 / 0.85 / 0.7
}

local TIERS: { DapurTier } = {
	{ unlockLevel = 6, mats = { { id = "kayu", count = 10 }, { id = "batu", count = 8 }, { id = "tanah_liat", count = 5 } }, slots = 1, timeMult = 1 },
	{ unlockLevel = 15, mats = { { id = "papan", count = 15 }, { id = "bata", count = 10 } }, slots = 2, timeMult = 0.85 },
	{ unlockLevel = 35, mats = { { id = "papan", count = 20 }, { id = "bata", count = 15 }, { id = "semen", count = 10 } }, slots = 3, timeMult = 0.7 },
}

local function crop(id: string, count: number): Input
	return { kind = "crop", id = id, count = count }
end
local function fish(cat: string, count: number): Input
	return { kind = "fish", cat = cat, count = count }
end
local function garam(count: number): Input
	return { kind = "garam", count = count }
end
local function bahan(id: string, count: number): Input
	return { kind = "bahan", id = id, count = count }
end
local function ternak(id: string, count: number): Input
	return { kind = "ternak", id = id, count = count }
end
local function olahan(id: string, count: number): Input
	return { kind = "olahan", id = id, count = count }
end

local RECIPES: { Recipe } = {
	-- Tier 1 (Lv 6)
	{ id = "pakan_jagung", tier = 1, inputs = { crop("jagung", 1) }, minutes = 3, xp = 20, outputCount = 6 },
	{ id = "tumis_kangkung", tier = 1, inputs = { crop("kangkung", 5), garam(1) }, minutes = 5, sell = 220, xp = 40 },
	{ id = "tumis_bayam", tier = 1, inputs = { crop("bayam", 5), garam(1) }, minutes = 5, sell = 280, xp = 45 },
	{ id = "sambal_tomat", tier = 1, inputs = { crop("tomat", 4), crop("cabai", 2) }, minutes = 6, sell = 630, xp = 60 },
	{ id = "sup_ubi", tier = 1, inputs = { crop("ubi_jalar", 3), crop("jahe", 1) }, minutes = 7, sell = 400, xp = 55 },
	{ id = "jus_jagung", tier = 1, inputs = { crop("jagung", 3), crop("tebu", 1) }, minutes = 8, sell = 780, xp = 70 },
	{ id = "keripik_singkong", tier = 1, inputs = { crop("singkong", 4), garam(1) }, minutes = 8, sell = 620, xp = 65 },
	{ id = "ikan_early_goreng", tier = 1, inputs = { fish("early", 3), garam(1) }, minutes = 6, mult = 1.6, xp = 50 },
	-- Tier 2 (Lv 15)
	{ id = "telur_asin", tier = 2, inputs = { ternak("telur_bebek", 4), garam(1) }, minutes = 20, sell = 350, xp = 90 },
	{ id = "selai_stroberi", tier = 2, inputs = { crop("stroberi", 4), crop("tebu", 2) }, minutes = 30, sell = 3200, xp = 300 },
	{ id = "pepes_ikan_mid", tier = 2, inputs = { fish("mid", 2), crop("jahe", 1), bahan("daun_pisang", 1) }, minutes = 25, mult = 1.6, xp = 110 },
	{ id = "nasi_goreng_spesial", tier = 2, inputs = { olahan("sambal_tomat", 1), crop("padi", 3), ternak("telur_ayam", 1) }, minutes = 25, sell = 2600, xp = 200 },
	{ id = "es_tebu", tier = 2, inputs = { crop("tebu", 3), crop("melati", 1) }, minutes = 20, sell = 980, xp = 100 },
	{ id = "gulai_telur", tier = 2, inputs = { ternak("telur_ayam", 3), crop("cabai", 2), crop("jahe", 1) }, minutes = 24, sell = 820, xp = 115 },
	{ id = "salad_sawi", tier = 2, inputs = { crop("sawi", 4), crop("tomat", 2), garam(1) }, minutes = 20, sell = 640, xp = 95 },
	{ id = "kue_pisang", tier = 2, inputs = { crop("pisang", 3), crop("tebu", 2), ternak("telur_ayam", 1) }, minutes = 30, sell = 3100, xp = 350 },
	-- Tier 3 (Lv 35)
	{ id = "kopi_tubruk", tier = 3, inputs = { crop("kopi", 4), crop("tebu", 1) }, minutes = 40, sell = 4400, xp = 380 },
	{ id = "teh_melati", tier = 3, inputs = { crop("teh", 3), crop("melati", 2) }, minutes = 45, sell = 4500, xp = 390 },
	{ id = "es_krim_durian", tier = 3, inputs = { crop("durian", 2), ternak("susu", 3), crop("tebu", 1) }, minutes = 60, sell = 5200, xp = 520 },
	{ id = "durian_goreng", tier = 3, inputs = { crop("durian", 2), crop("tebu", 1), garam(1) }, minutes = 50, sell = 4400, xp = 500 },
	{ id = "kopi_susu_gula_aren", tier = 3, inputs = { olahan("kopi_tubruk", 1), ternak("susu", 2), crop("tebu", 1) }, minutes = 50, sell = 5200, xp = 480 },
	{ id = "nasi_padang_mini", tier = 3, inputs = { olahan("sambal_tomat", 1), olahan("telur_asin", 1), crop("padi", 3) }, minutes = 55, sell = 2900, xp = 220 },
	{ id = "ikan_late_bakar", tier = 3, inputs = { fish("late", 2), crop("cabai", 1), crop("jahe", 1) }, minutes = 45, mult = 1.6, xp = 250 },
	{ id = "salad_buah", tier = 3, inputs = { crop("mangga", 2), crop("pisang", 2), crop("stroberi", 2) }, minutes = 45, sell = 6500, xp = 450 },
}

local byId: { [string]: Recipe } = {}
for _, recipe in RECIPES do
	byId[recipe.id] = recipe
end

local Ranch = require(script.Parent.Ranch)

-- Ukuran semua bangunan lahan dalam sel grid (kandang + dapur + warung) + gabungannya.
-- Dipakai Land.takenRects di semua cek tabrakan (till / gali kolam / decor / bangun).
local BUILDING_SIZES = table.clone(Ranch.KANDANG_SIZES)
BUILDING_SIZES.dapur = { 2, 2 }
BUILDING_SIZES.warung = { 2, 2 }

local function buildings(ranchKandang: { [string]: { cx: number, cz: number } }?, dapurSpot: { cx: number, cz: number }?, warungSpot: { cx: number, cz: number }?): { [string]: { cx: number, cz: number } }
	local map = table.clone((ranchKandang or {}) :: { [string]: { cx: number, cz: number } })
	if dapurSpot then
		map.dapur = dapurSpot
	end
	if warungSpot then
		map.warung = warungSpot
	end
	return map
end

-- Olahan -> buff (Bab 9.4): makan 1 Olahan = 1 buff aktif (ganti lama, tidak stack).
local BUFF_BY_RECIPE: { [string]: string } = {}
local function buff(buffId: string, recipes: { string })
	for _, id in recipes do
		BUFF_BY_RECIPE[id] = buffId
	end
end
buff("tani", { "tumis_kangkung", "tumis_bayam", "sambal_tomat", "sup_ubi", "salad_sawi", "nasi_goreng_spesial", "nasi_padang_mini", "salad_buah" })
buff("pancing", { "ikan_early_goreng", "pepes_ikan_mid", "ikan_late_bakar" })
buff("tukang", { "jus_jagung", "keripik_singkong", "gulai_telur", "kue_pisang", "selai_stroberi", "es_tebu", "es_krim_durian", "durian_goreng" })
buff("tebang", { "kopi_tubruk", "teh_melati", "kopi_susu_gula_aren", "telur_asin" })

return {
	TIERS = TIERS,
	RECIPES = RECIPES,
	byId = byId,
	BUFF_BY_RECIPE = BUFF_BY_RECIPE,
	BUILDING_SIZES = BUILDING_SIZES,
	buildings = buildings,

	FISH_CAT = { early = "C", mid = "U", late = "R" }, -- kategori resep -> rarity ikan (Legenda tidak bisa dimasak)
	BUFF_DURATION = { biasa = 600, bagus = 720, prima = 900 }, -- detik, real-time (Bab 9.4)
	BUFF_TANI_BAGUS = 0.1, -- Update owner 2026-11-22: +10% absolut ke peluang Bagus saat panen (Super dihapus)
	BUFF_PANCING_BITE = 0.8, -- gigitan 20% lebih cepat (x waktu tunggu)
	BUFF_PANCING_BOX = 1.1, -- Kotak tarik +10% lebih lebar
	BUFF_CRIT_WINDOW = 1.25, -- jendela Critical +25% lebih lebar (client)
	GARAM_PRICE = 10, -- Garam di Pak Udin (Bab 9.2)
	DAPUR_SIZE = { 2, 2 }, -- sel grid (auto-place; "ditaruh bebas" = drag Studio, menyusul)
	WARUNG_SIZE = { 2, 2 },
	WARUNG_UNLOCK = 7,
	WARUNG_VISIT_MIN = 300, -- NPC tiap 5-10 mnt random (detik)
	WARUNG_VISIT_MAX = 600,
	WARUNG_OFFLINE_MAX = 5, -- max penjualan per login saat offline
}
