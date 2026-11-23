--!strict
-- Album Kampung (docs/01_GDD_Kampoeng_Tedoeh_v8.2.md Bab 11, LOCKED): GUI utama 214 entri.
--   Ladang 54 (18 tanaman x 3 Kualitas) + Sungai 80 (20 ikan x 4 ukuran) + Dapur 72 (24 resep x 3 Kualitas) + Varian 8 = 214.
--   Kandang (3 hewan + 2 Hewan Varian) + Rumah (piece Decor, auto) = tab terpisah, tidak masuk 214.
-- Entry id: ladang "{crop}:{biasa|bagus|prima}", sungai "{fish}@{S|M|L|Jumbo}", dapur "{resep}:{biasa|bagus|prima}",
--   varian/kandang/rumah = id polos.
-- Dapur/Varian/Kandang direkam saat sistemnya ada (Dapur P2-3, Ternak P2-2, Gerobak P2-6).
--
-- MILESTONE di bawah ini USULAN (Bab 11), bukan LOCKED. BUTUH LOCK OWNER sebelum dibuka ke player.

local Crops = require(script.Parent.Crops)
local Decor = require(script.Parent.Decor)
local Fish = require(script.Parent.Fish)
local Progression = require(script.Parent.Progression)

type Reward = Progression.Reward

local QUALITIES = { "biasa", "bagus", "prima" }

-- 24 resep rilis (Bab 9.2). Id mekanis dari nama (Dapur P2-3 yang memakai).
local RECIPES = {
	"pakan_jagung", "tumis_kangkung", "tumis_bayam", "sambal_tomat", "sup_ubi", "jus_jagung", "keripik_singkong", "ikan_early_goreng",
	"telur_asin", "selai_stroberi", "pepes_ikan_mid", "nasi_goreng_spesial", "es_tebu", "gulai_telur", "salad_sawi", "kue_pisang",
	"kopi_tubruk", "teh_melati", "es_krim_durian", "durian_goreng", "kopi_susu_gula_aren", "nasi_padang_mini", "ikan_late_bakar", "salad_buah",
} :: { string }

-- 6 Bibit Varian + 2 Hewan Varian (Bab 13.1, Gerobak Kaget P2-6).
local VARIAN = {
	"jagung_ungu", "tomat_kuning", "semangka_kotak", "cabai_pelangi", "stroberi_putih", "pisang_merah",
	"ayam_cemani", "bebek_belang",
} :: { string }

-- 3 hewan + 2 Hewan Varian (Ternak P2-2).
local KANDANG = { "ayam", "bebek", "sapi", "ayam_cemani", "bebek_belang" } :: { string }

local function ids(list: { any }, filter: ((any) -> boolean)?): { string }
	local out = {}
	for _, entry in list do
		if not filter or filter(entry) then
			table.insert(out, entry.id)
		end
	end
	return out
end

local ladang = {}
for _, cropId in ids(Crops.list, function(crop: any)
	return crop.varian ~= true -- Bibit Varian punya tab sendiri ("varian", Bab 13.1 P2-6)
end) do
	for _, quality in QUALITIES do
		table.insert(ladang, `{cropId}:{quality}`)
	end
end

local sungai = {}
for _, fishId in ids(Fish.list) do
	for _, size in Fish.SIZES do
		table.insert(sungai, `{fishId}@{size.id}`)
	end
end

local dapur = {}
for _, recipe in RECIPES do
	for _, quality in QUALITIES do
		table.insert(dapur, `{recipe}:{quality}`)
	end
end

return {
	CATEGORIES = { "ladang", "sungai", "kandang", "rumah", "dapur", "varian" } :: { string },
	-- Tab GUI utama (jumlahnya 214). Kandang + Rumah tab terpisah, tidak dihitung.
	GUI_CATEGORIES = { "ladang", "sungai", "dapur", "varian" } :: { string },
	ENTRIES = {
		ladang = ladang,
		sungai = sungai,
		kandang = KANDANG,
		rumah = ids(Decor.list),
		dapur = dapur,
		varian = VARIAN,
	} :: { [string]: { string } },

	-- Overall completion (percent of the 214 GUI entries). USULAN, bukan LOCKED — BUTUH LOCK OWNER.
	MILESTONES = {
		{ id = "p25", percent = 25, reward = { bunga = 10 } },
		{ id = "p50", percent = 50, reward = { bunga = 20, title = "kolektor" } },
		{ id = "p75", percent = 75, reward = { bunga = 30, decor = { bingkai_emas = 1 } } },
		{ id = "p100", percent = 100, reward = { bunga = 50, title = "legenda_kampung" } },
	} :: { { id: string, percent: number, reward: Reward } },

	-- One category fully completed (angka lama, dipertahankan: tidak dibahas di v7.3 = LOCKED).
	CATEGORY_REWARDS = {
		ladang = { koin = 300 },
		sungai = { koin = 300 },
		rumah = { title = "juragan_pondok", decor = { rumpun_bambu = 1 } },
	} :: { [string]: Reward },
}
