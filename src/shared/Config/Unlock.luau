--!strict
-- Unlock table per Level Player (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 4.4). Aturan: "Konten baru = Level
-- Player. Alat baru = Level Cabang." The lists here are the reference for the content Levels; the per-content configs
-- (Config/Crops, Fish, Npcs, Shop, ...) carry the same numbers in their unlockLevel fields until their phase moves them here.
-- Levels 61-100 are filled by Update 1 and 2 (Bab 26) and are not listed.

return {
	[1] = { "Nanem (Kangkung, Bayam)", "Mancing Kanal", "Rumah Pertama" },
	[2] = { "Tomat", "Sawi", "Bang Jali" },
	[3] = { "Jagung", "Ubi Jalar", "Bundel: Kolam Kakek", "Kolam Tanah tambahan" },
	[4] = { "Hutan Nambang", "Meja Crafting" },
	[5] = { "Ayam", "Kandang Ayam", "Danau" },
	[6] = { "Singkong", "Bubu", "Dapur Tier 1", "Bundel: Sumur Tua" },
	[8] = { "Cabai", "Padi", "Lapak lihat-saja" },
	[10] = { "Bebek", "Sungai (Spot 3)", "Rak Pajangan Panen", "Petak 13-24" },
	[12] = { "Stroberi", "Bundel: Lumbung Kakek" },
	[15] = { "Pisang", "Tebu", "Kolam Semen", "Dapur Tier 2", "Pohon Aren (Ijuk)", "Bingkai Album" },
	[18] = { "Spot 4 (Sungai Malam)" },
	[20] = { "Lapak Tetangga (jual)", "Kirim Hadiah", "Bundel: Saung Kakek" },
	[22] = { "Sapi", "Kandang Sapi", "Jahe" },
	[25] = { "Kopi", "Teh", "Akuarium", "Greenhouse", "Kaca", "Petak 25-36" },
	[30] = { "Kolam Keramik", "Melati", "Bundel: Empang & Dermaga Kakek" },
	[35] = { "Dapur Tier 3", "Mangga" },
	[40] = { "Bubu Besi", "Rumah 2 Lantai (atap & tangga tingkat)" },
	[45] = { "Durian" },
	[50] = { "Atap Joglo (set Joglo)" },
	[60] = { "Title Warga Kampoeng Tedoeh", "Mahkota Lampion (dekor)" },
} :: { [number]: { string } }
