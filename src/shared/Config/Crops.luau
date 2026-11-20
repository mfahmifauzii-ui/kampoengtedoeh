--!strict
-- Tanaman. Fase 1 isi: 6 tanaman pertama (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 5.3; waktu Early di v6.2.2).
-- Sisa 12 tanaman rilis masuk di Fase 8. Tambah tanaman: satu entri di sini + locale "crop.<id>".
-- growSeconds = waktu nyata (lanjut walau offline, Bab 5.1). yield = hasil per panen. regrows = panen ulang tambahan.
-- seedPrice = bibit di Pak Udin (Bab 5.3 "Bibit"). sellPrice = Jual (Bab 5.3 "Jual"). xp = XP per panen (Bab 5.3).

export type Crop = {
	id: string,
	unlockLevel: number,
	seedPrice: number, -- Koin, the price of one bibit at Pak Udin
	growSeconds: number,
	sellPrice: number,
	xp: number,
	yield: number,
	regrows: number,
	color: Color3,
}

local list: { Crop } = {
	{ id = "kangkung", unlockLevel = 1, seedPrice = 8, growSeconds = 180, sellPrice = 25, xp = 12, yield = 1, regrows = 0, color = Color3.fromRGB(118, 148, 86) },
	{ id = "bayam", unlockLevel = 1, seedPrice = 10, growSeconds = 300, sellPrice = 32, xp = 15, yield = 1, regrows = 0, color = Color3.fromRGB(86, 140, 84) },
	{ id = "tomat", unlockLevel = 2, seedPrice = 12, growSeconds = 360, sellPrice = 36, xp = 16, yield = 1, regrows = 0, color = Color3.fromRGB(190, 96, 72) },
	{ id = "sawi", unlockLevel = 2, seedPrice = 25, growSeconds = 1200, sellPrice = 80, xp = 35, yield = 1, regrows = 0, color = Color3.fromRGB(92, 152, 98) },
	{ id = "jagung", unlockLevel = 3, seedPrice = 35, growSeconds = 1800, sellPrice = 110, xp = 45, yield = 1, regrows = 0, color = Color3.fromRGB(214, 180, 92) },
	{ id = "ubi_jalar", unlockLevel = 3, seedPrice = 12, growSeconds = 420, sellPrice = 38, xp = 18, yield = 1, regrows = 0, color = Color3.fromRGB(184, 120, 92) },
}

local byId: { [string]: Crop } = {}
for _, crop in list do
	byId[crop.id] = crop
end

return {
	list = list,
	byId = byId,
}
