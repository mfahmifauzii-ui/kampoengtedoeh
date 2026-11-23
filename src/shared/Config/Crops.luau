--!strict
-- Tanaman rilis: 18 tanaman (docs/01_GDD_Kampoeng_Tedoeh_v8.4.md Bab 5.3, LOCKED). Tambah tanaman: satu entri di sini + locale "crop.<id>".
-- growSeconds = waktu nyata (lanjut walau offline, Bab 5.1). yield = hasil per panen. regrows = panen ulang tambahan.
-- seedPrice = bibit di Pak Udin (Bab 5.3 "Bibit"). sellPrice = Jual (Bab 5.3 "Jual"). xp = XP per panen (Bab 5.3).
-- byproduct = bonus per panen (Bab 5.3: Padi -> 2 Jerami, Pisang -> 2 Daun Pisang).

export type Byproduct = {
	id: string, -- "jerami" | "daun_pisang" (Modules/Items, kind "bahan": tidak bisa dijual)
	count: number,
}

export type Crop = {
	id: string,
	unlockLevel: number,
	seedPrice: number, -- Koin, the price of one bibit at Pak Udin
	growSeconds: number,
	sellPrice: number,
	xp: number,
	yield: number,
	regrows: number,
	byproduct: Byproduct?,
	color: Color3,
	varian: boolean?, -- Bibit Varian Gerobak Kaget (Bab 13.1, P2-6): jual +50%, Kualitas tetap
}

local list: { Crop } = {
	{ id = "kangkung", unlockLevel = 1, seedPrice = 8, growSeconds = 180, sellPrice = 25, xp = 12, yield = 1, regrows = 0, color = Color3.fromRGB(118, 148, 86) },
	{ id = "bayam", unlockLevel = 1, seedPrice = 10, growSeconds = 300, sellPrice = 32, xp = 15, yield = 1, regrows = 0, color = Color3.fromRGB(86, 140, 84) },
	{ id = "tomat", unlockLevel = 2, seedPrice = 12, growSeconds = 360, sellPrice = 36, xp = 16, yield = 1, regrows = 0, color = Color3.fromRGB(190, 96, 72) },
	{ id = "sawi", unlockLevel = 2, seedPrice = 25, growSeconds = 1200, sellPrice = 80, xp = 35, yield = 1, regrows = 0, color = Color3.fromRGB(92, 152, 98) },
	{ id = "jagung", unlockLevel = 3, seedPrice = 35, growSeconds = 1800, sellPrice = 110, xp = 45, yield = 1, regrows = 0, color = Color3.fromRGB(214, 180, 92) },
	{ id = "ubi_jalar", unlockLevel = 3, seedPrice = 12, growSeconds = 420, sellPrice = 38, xp = 18, yield = 1, regrows = 0, color = Color3.fromRGB(184, 120, 92) },
	{ id = "singkong", unlockLevel = 6, seedPrice = 30, growSeconds = 1500, sellPrice = 95, xp = 40, yield = 1, regrows = 0, color = Color3.fromRGB(150, 110, 75) },
	{ id = "cabai", unlockLevel = 8, seedPrice = 40, growSeconds = 1800, sellPrice = 125, xp = 50, yield = 1, regrows = 0, color = Color3.fromRGB(200, 60, 50) },
	{ id = "padi", unlockLevel = 8, seedPrice = 120, growSeconds = 7200, sellPrice = 400, xp = 140, yield = 1, regrows = 0, byproduct = { id = "jerami", count = 2 }, color = Color3.fromRGB(220, 190, 110) },
	{ id = "stroberi", unlockLevel = 12, seedPrice = 130, growSeconds = 7200, sellPrice = 420, xp = 150, yield = 1, regrows = 0, color = Color3.fromRGB(220, 90, 100) },
	{ id = "pisang", unlockLevel = 15, seedPrice = 160, growSeconds = 10800, sellPrice = 520, xp = 180, yield = 1, regrows = 0, byproduct = { id = "daun_pisang", count = 2 }, color = Color3.fromRGB(140, 170, 90) },
	{ id = "tebu", unlockLevel = 8, seedPrice = 50, growSeconds = 2400, sellPrice = 160, xp = 60, yield = 1, regrows = 0, color = Color3.fromRGB(130, 170, 100) },
	{ id = "jahe", unlockLevel = 6, seedPrice = 45, growSeconds = 2100, sellPrice = 140, xp = 55, yield = 1, regrows = 0, color = Color3.fromRGB(180, 140, 90) },
	{ id = "kopi", unlockLevel = 25, seedPrice = 200, growSeconds = 14400, sellPrice = 650, xp = 220, yield = 1, regrows = 0, color = Color3.fromRGB(150, 60, 60) },
	{ id = "teh", unlockLevel = 25, seedPrice = 260, growSeconds = 21600, sellPrice = 850, xp = 280, yield = 1, regrows = 0, color = Color3.fromRGB(100, 150, 95) },
	{ id = "melati", unlockLevel = 15, seedPrice = 40, growSeconds = 1800, sellPrice = 130, xp = 50, yield = 1, regrows = 0, color = Color3.fromRGB(235, 235, 225) },
	{ id = "mangga", unlockLevel = 35, seedPrice = 320, growSeconds = 28800, sellPrice = 1100, xp = 360, yield = 1, regrows = 0, color = Color3.fromRGB(230, 150, 60) },
	{ id = "durian", unlockLevel = 45, seedPrice = 380, growSeconds = 28800, sellPrice = 1300, xp = 400, yield = 1, regrows = 0, color = Color3.fromRGB(110, 140, 70) },
	-- Bibit Varian Gerobak Kaget (Bab 13.1, P2-6): tumbuh seperti base, jual +50% (dibulatkan),
	-- Kualitas tetap Biasa/Bagus/Prima. Harga bibit Gerobak = 2x seedPrice (USULAN, v7.3 tak memberi harga).
	{ id = "jagung_ungu", unlockLevel = 3, seedPrice = 70, growSeconds = 1800, sellPrice = 165, xp = 45, yield = 1, regrows = 0, color = Color3.fromRGB(150, 80, 180), varian = true },
	{ id = "tomat_kuning", unlockLevel = 2, seedPrice = 24, growSeconds = 360, sellPrice = 54, xp = 16, yield = 1, regrows = 0, color = Color3.fromRGB(230, 200, 80), varian = true },
	{ id = "semangka_kotak", unlockLevel = 20, seedPrice = 200, growSeconds = 10800, sellPrice = 450, xp = 120, yield = 1, regrows = 0, color = Color3.fromRGB(80, 160, 90), varian = true },
	{ id = "cabai_pelangi", unlockLevel = 8, seedPrice = 80, growSeconds = 1800, sellPrice = 188, xp = 50, yield = 1, regrows = 0, color = Color3.fromRGB(200, 80, 200), varian = true },
	{ id = "stroberi_putih", unlockLevel = 12, seedPrice = 260, growSeconds = 7200, sellPrice = 630, xp = 300, yield = 1, regrows = 0, color = Color3.fromRGB(240, 240, 240), varian = true },
	{ id = "pisang_merah", unlockLevel = 15, seedPrice = 320, growSeconds = 10800, sellPrice = 780, xp = 180, yield = 1, regrows = 0, color = Color3.fromRGB(180, 60, 60), varian = true },
}

local byId: { [string]: Crop } = {}
for _, crop in list do
	byId[crop.id] = crop
end

return {
	list = list,
	byId = byId,
}
