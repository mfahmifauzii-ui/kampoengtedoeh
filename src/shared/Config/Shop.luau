--!strict
-- NPC shops (see Config/Npcs for who sells what). Rods come from Fishing.rodList, bait from Fishing.BAITS.
-- Upgrade cost i = price of going from tier i-1 to tier i.
-- Tas tanpa cap slot, stack 99 (Bab 18.1 v7.3). Tidak ada Upgrade Tas.

return {
	NPC_DISTANCE = 25, -- studs, server-checked for every buy/sell

	MAX_AMOUNT = 99, -- most you can buy or sell in one go (the number picker in the shop; the server re-checks)

	UPGRADE_ORDER = { "pond" },
	UPGRADES = {
		pond = { costs = { 1500, 5000 }, unlockLevel = 6 }, -- Fishing.POND.CAPS
	} :: { [string]: { costs: { number }, unlockLevel: number } },

	-- Pak Udin: Garam (bahan masak) dan Bubu (GDD 6.6, R2.1). Bubu harga = Koin saja (lihat Config/Bubu TYPES).
	SUPPLIES = {
		garam = { price = 10 }, -- Garam di Pak Udin (Bab 9.2): bahan masak
		bubu_bambu = { price = 400 },
		bubu_kayu = { price = 1500 },
		bubu_besi = { price = 4000 },
	} :: { [string]: { price: number } },

	-- Toko Bunga (Bab 9-10, P2-7): tukar Bunga dengan dekor langka / bibit varian.
	-- Harga = USULAN (v7.3 tak memberi angka; butuh lock owner/playtest 17.8).
	BUNGA_GOODS = {
		{ id = "gazebo_bambu", kind = "decor", bunga = 30 },
		{ id = "lampion_gantung", kind = "decor", bunga = 25 },
		{ id = "sepeda_onthel", kind = "decor", bunga = 40 },
		{ id = "kursi_rotan", kind = "decor", bunga = 20 },
		{ id = "seed_jagung_ungu", kind = "seed", bunga = 15 },
		{ id = "seed_tomat_kuning", kind = "seed", bunga = 12 },
		{ id = "seed_semangka_kotak", kind = "seed", bunga = 20 },
		{ id = "seed_cabai_pelangi", kind = "seed", bunga = 16 },
		{ id = "seed_stroberi_putih", kind = "seed", bunga = 22 },
		{ id = "seed_pisang_merah", kind = "seed", bunga = 22 },
	} :: { { id: string, kind: string, bunga: number } },
}
