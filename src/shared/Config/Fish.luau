--!strict
-- All fish (docs/01_GDD_Kampoeng_Tedoeh_v8.2.md Bab 6.4, LOCKED: 20 ikan). Add a fish here + a "fish.<id>" locale key.
-- Rarity = tier internal (C Early, U Mid, R Late, L Legenda): dipakai roll bobot, pond, FISH_FOR_SALE.
-- requirePhases / requireRain / rainKinds: the fish can ONLY be caught then (rainKinds = jenis hujan tertentu, K-07).
-- unlockLevel = Buka Lv Bab 6.4. xp = XP per tangkapan Bab 6.4 (dipakai FishService).
-- Day phases: "pagi" | "siang" | "sore" | "malam".
-- Lokasi pakai id Studio yang ada (sungai/empang/kolam, map LOCKED): Kanal/Danau/Sungai v7.3 dipetakan ke
-- sungai+empang; Spot 4 belum ada di Studio jadi Late/Spot4 ikut empang+sungai.

export type Rarity = "C" | "U" | "R" | "L"

export type Fish = {
	id: string,
	rarity: Rarity,
	unlockLevel: number, -- Buka Lv (Bab 6.4)
	xp: number, -- XP per tangkapan (Bab 6.4)
	locations: { string },
	sellPrice: number, -- harga Sedang (Bab 6.4)
	requirePhases: { string }?,
	requireRain: boolean?,
	rainKinds: { string }?, -- K-07: hanya saat cuaca ini ("deres" / "petir"); Gerimis tidak
	boost: { phase: string?, rain: boolean?, mult: number }?,
}

local list: { Fish } = {
	{ id = "wader_cakul", rarity = "C", unlockLevel = 1, xp = 10, locations = { "sungai_lahan" }, sellPrice = 20 },
	{ id = "betok", rarity = "C", unlockLevel = 1, xp = 12, locations = { "sungai_lahan" }, sellPrice = 26 },
	{ id = "sepat", rarity = "C", unlockLevel = 2, xp = 14, locations = { "sungai_lahan" }, sellPrice = 30 },
	{ id = "lele", rarity = "C", unlockLevel = 2, xp = 18, locations = { "sungai_lahan" }, sellPrice = 45, requirePhases = { "malam" } },
	{ id = "mujair", rarity = "U", unlockLevel = 5, xp = 26, locations = { "sungai", "empang", "kolam" }, sellPrice = 70 },
	{ id = "nila", rarity = "U", unlockLevel = 5, xp = 32, locations = { "sungai", "empang", "kolam" }, sellPrice = 90 },
	{ id = "tawes", rarity = "U", unlockLevel = 6, xp = 38, locations = { "sungai", "empang" }, sellPrice = 110, requirePhases = { "siang" } },
	{ id = "gurame", rarity = "U", unlockLevel = 8, xp = 50, locations = { "sungai", "empang" }, sellPrice = 160 },
	{ id = "patin", rarity = "U", unlockLevel = 10, xp = 55, locations = { "sungai", "empang" }, sellPrice = 180 },
	{ id = "gabus", rarity = "U", unlockLevel = 10, xp = 60, locations = { "sungai", "empang" }, sellPrice = 200, requireRain = true },
	{ id = "baung", rarity = "U", unlockLevel = 12, xp = 65, locations = { "sungai", "empang" }, sellPrice = 220, requirePhases = { "malam" } },
	{ id = "jelawat", rarity = "R", unlockLevel = 15, xp = 95, locations = { "empang" }, sellPrice = 350 },
	{ id = "toman", rarity = "R", unlockLevel = 18, xp = 110, locations = { "empang" }, sellPrice = 420, requirePhases = { "sore", "malam" } },
	{ id = "tapah", rarity = "R", unlockLevel = 18, xp = 150, locations = { "empang" }, sellPrice = 600, requirePhases = { "malam" } },
	{ id = "sidat", rarity = "R", unlockLevel = 22, xp = 160, locations = { "empang" }, sellPrice = 650, requirePhases = { "malam" }, requireRain = true },
	{ id = "semah", rarity = "R", unlockLevel = 25, xp = 130, locations = { "empang" }, sellPrice = 520, requirePhases = { "pagi" } },
	{ id = "belida", rarity = "R", unlockLevel = 30, xp = 170, locations = { "empang" }, sellPrice = 700 },
	{ id = "gurame_raja", rarity = "L", unlockLevel = 15, xp = 550, locations = { "empang" }, sellPrice = 2200, requirePhases = { "pagi" } },
	{ id = "belut_emas", rarity = "L", unlockLevel = 20, xp = 500, locations = { "sungai" }, sellPrice = 2000, rainKinds = { "deres", "petir" } },
	{ id = "ikan_dewa", rarity = "L", unlockLevel = 30, xp = 600, locations = { "empang" }, sellPrice = 2500, requirePhases = { "malam" } },
}

local byId: { [string]: Fish } = {}
for _, fish in list do
	byId[fish.id] = fish
end

return {
	list = list,
	byId = byId,

	RARITY_WEIGHTS = { C = 70, U = 22, R = 7, L = 0.5 } :: { [Rarity]: number }, -- K-47: Legenda 0,5% per lemparan (GDD 6.5)
	RAIN_MULT = { R = 1.5, L = 2 } :: { [Rarity]: number },

	-- Reel score (0..1) -> size. Value multiplier applies when selling (Bab 6.4: Kecil x0,8 / Sedang x1,0 / Besar x1,2 / Jumbo x1,5).
	SIZES = {
		{ id = "S", minScore = 0, valueMult = 0.8 },
		{ id = "M", minScore = 0.4, valueMult = 1.0 }, -- K-46: 40/40/15/5 (GDD 6.4) bila skor merata
		{ id = "L", minScore = 0.8, valueMult = 1.2 },
		{ id = "Jumbo", minScore = 0.95, valueMult = 1.5 },
	},
}
