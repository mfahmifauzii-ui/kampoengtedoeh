--!strict
-- Buff Olahan (Kampoeng_Tedoeh_v7.3 Bab 9.4, LOCKED). Olahan bisa dijual ATAU dimakan sendiri.
-- Cuma 1 buff aktif, tidak stack. Makan Olahan baru = ganti buff lama.
-- Durasi dari Kualitas Olahan: Biasa 10 mnt / Bagus 12 mnt / Prima 15 mnt. Timer real-time, tidak pause offline.
-- Hanya kegiatan AKTIF. Yang TIDAK kena buff (pasif, haram): Cooldown Ternak, Breeding Kolam, Waktu Masak Dapur,
-- Bubu, Warung offline, Mood Hujan, Stat Dekor.
--
-- The server publishes an active buff as two player attributes (the HUD only reads them):
--   Buff_<id>_End  = Workspace:GetServerTimeNow() when it ends
--   Buff_<id>_Dur  = its full length in seconds (so the icon knows how full it is)
-- STATUS: the slots and their display are built (Studio test: chat "!buff tani 60"); the EFFECTS are not coded yet.
-- Food mapping below is data only (Dapur belum di-code).
--
-- icon = a key in Config/UiAssets ICONS (placeholder until the ForgeGUI buff icons exist: empty + full art per buff).

export type Buff = {
	id: string,
	icon: string,
	nameKey: string,
	descKey: string,
	food: { string }, -- Olahan yang memberi buff ini (Bab 9.4)
}

return {
	SLOTS = {
		-- Nanem: Panen +10% peluang Super. Tidak ngaruh ke waktu tumbuh.
		{ id = "tani", icon = "bibit", nameKey = "buff.tani", descKey = "buff.tani.desc", food = { "Tumis Kangkung", "Tumis Bayam", "Sambal Tomat", "Sup Ubi", "Salad Sawi", "Nasi Goreng Spesial", "Nasi Padang Mini", "Salad Buah" } },
		-- Mancing: Gigitan 20% lebih cepat + Kotak tarik +10% lebih lebar.
		{ id = "pancing", icon = "pancing", nameKey = "buff.pancing", descKey = "buff.pancing.desc", food = { "Ikan Early Goreng", "Pepes Ikan Mid", "Ikan Late Bakar" } },
		-- Nambang: Jendela Critical +25% lebih lebar + +1 bahan saat Critical. Berlaku untuk Batu / Tanah Liat / Pasir / Bambu / Ijuk.
		{ id = "tukang", icon = "garap", nameKey = "buff.tukang", descKey = "buff.tukang.desc", food = { "Jus Jagung", "Keripik Singkong", "Gulai Telur", "Kue Pisang", "Selai Stroberi", "Es Tebu", "Es Krim Durian", "Durian Goreng" } },
		-- Nebang Pohon: Jendela Critical +25% lebih lebar + +1 Kayu saat Critical. Hanya untuk Pohon (Kayu).
		{ id = "tebang", icon = "panen", nameKey = "buff.tebang", descKey = "buff.tebang.desc", food = { "Kopi Tubruk", "Teh Melati", "Kopi Susu Gula Aren", "Telur Asin" } },
	} :: { Buff },

	-- Durasi dari Kualitas Olahan (Bab 9.4).
	DURATION_SECONDS = {
		biasa = 600,
		bagus = 720,
		prima = 900,
	} :: { [string]: number },
}
