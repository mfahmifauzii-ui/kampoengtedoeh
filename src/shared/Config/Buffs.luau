--!strict
-- Buff Olahan (docs/01_GDD_Kampoeng_Tedoeh_v8.4.md Bab 9.4, LOCKED). Olahan bisa dijual ATAU dimakan sendiri.
-- Cuma 1 buff aktif, tidak stack. Makan Olahan baru = ganti buff lama.
-- Durasi dari Kualitas Olahan: Biasa 10 mnt / Bagus 12 mnt / Prima 15 mnt. Timer real-time, tidak pause offline.
-- Hanya kegiatan AKTIF. Yang TIDAK kena buff (pasif, haram): Cooldown Ternak, Breeding Kolam, Waktu Masak Dapur,
-- Bubu, Warung offline, Mood Hujan, Stat Dekor.
--
-- The server publishes an active buff as two player attributes (the HUD only reads them):
--   Buff_<id>_End  = Workspace:GetServerTimeNow() when it ends
--   Buff_<id>_Dur  = its full length in seconds (so the icon knows how full it is)
-- STATUS: the slots and their display are built (Studio test: chat "!buff tani 60"); the EFFECTS are not coded yet.
-- Food mapping below is recipe ids (Config/Dapur RECIPES); makan 1 Olahan = buff tsb (DapurService).
--
-- icon = a key in Config/UiAssets ICONS (placeholder until the ForgeGUI buff icons exist: empty + full art per buff).

export type Buff = {
	id: string,
	icon: string,
	nameKey: string,
	descKey: string,
	food: { string }, -- Olahan yang memberi buff ini (Bab 9.4)
}

local SLOTS = {
	-- Nanem: Panen +10% peluang Bagus. Tidak ngaruh ke waktu tumbuh.
	{ id = "tani", icon = "bibit", nameKey = "buff.tani", descKey = "buff.tani.desc", food = { "tumis_kangkung", "tumis_bayam", "sambal_tomat", "sup_ubi", "salad_sawi", "nasi_goreng_spesial", "nasi_padang_mini", "salad_buah" } },
	-- Mancing: Gigitan 20% lebih cepat + Kotak tarik +10% lebih lebar.
	{ id = "pancing", icon = "pancing", nameKey = "buff.pancing", descKey = "buff.pancing.desc", food = { "ikan_early_goreng", "pepes_ikan_mid", "ikan_late_bakar" } },
	-- Nambang: Jendela Critical +25% lebih lebar + +1 bahan saat Critical. Berlaku untuk Batu / Tanah Liat / Pasir / Bambu / Ijuk.
	{ id = "tukang", icon = "garap", nameKey = "buff.tukang", descKey = "buff.tukang.desc", food = { "jus_jagung", "keripik_singkong", "gulai_telur", "kue_pisang", "selai_stroberi", "es_tebu", "es_krim_durian", "durian_goreng" } },
	-- Nebang Pohon: Jendela Critical +25% lebih lebar + +1 Kayu saat Critical. Hanya untuk Pohon (Kayu).
	{ id = "tebang", icon = "panen", nameKey = "buff.tebang", descKey = "buff.tebang.desc", food = { "kopi_tubruk", "teh_melati", "kopi_susu_gula_aren", "telur_asin" } },
} :: { Buff }

-- Durasi dari Kualitas Olahan (Bab 9.4).
local DURATION_SECONDS = {
	biasa = 600,
	bagus = 720,
	prima = 900,
} :: { [string]: number }

-- Buff aktif? buff = data.buff { id, endsAt } (DapurService, timer real-time, tidak pause offline).
local function active(buff: { id: string?, endsAt: number }?, id: string, now: number): boolean
	return buff ~= nil and buff.id == id and (buff.endsAt or 0) > now
end

return {
	SLOTS = SLOTS,
	DURATION_SECONDS = DURATION_SECONDS,
	active = active,
}
