--!strict
-- Fishing rules, rods, locations and the player-built ponds (kolam).

export type Rod = {
	id: string,
	price: number, -- Koin
	unlockLevel: number, -- Mancing Lv (Bab 6.3): player level
	box: number, -- Kotak tarik, persen lebar bar (Bab 6.3)
	mats: { { id: string, count: number } }, -- bahan (P2-1: belum ada sumber, belum bisa dipenuhi)
	-- Tuning sementara, ikut kurva lama (bambu/rotan/fiber/juragan). Playtest yang mengunci (Bab 17.8).
	biteMult: number, -- multiplies bite wait time
	rareBonus: number, -- added to R tier weight
	legendaryBonus: number, -- added to L tier weight
}

local rodList: { Rod } = {
	{ id = "bambu", price = 0, unlockLevel = 1, box = 30, mats = {}, biteMult = 1.0, rareBonus = 0, legendaryBonus = 0 },
	{ id = "kayu", price = 900, unlockLevel = 2, box = 33, mats = { { id = "bambu", count = 10 } }, biteMult = 0.9, rareBonus = 2, legendaryBonus = 0 },
	{ id = "kayu_jati", price = 3500, unlockLevel = 4, box = 36, mats = { { id = "bambu", count = 20 } }, biteMult = 0.8, rareBonus = 3, legendaryBonus = 0 },
	{ id = "bambu_wulung", price = 9000, unlockLevel = 6, box = 39, mats = { { id = "bambu", count = 30 } }, biteMult = 0.75, rareBonus = 4, legendaryBonus = 0 },
	{ id = "besi", price = 18000, unlockLevel = 8, box = 42, mats = { { id = "bambu", count = 30 }, { id = "batu", count = 15 } }, biteMult = 0.7, rareBonus = 5, legendaryBonus = 0 },
	{ id = "pusaka", price = 35000, unlockLevel = 10, box = 45, mats = { { id = "bambu", count = 40 }, { id = "batu", count = 20 }, { id = "ijuk", count = 10 } }, biteMult = 0.65, rareBonus = 6, legendaryBonus = 1 },
}

local rods: { [string]: Rod } = {}
for _, rod in rodList do
	rods[rod.id] = rod
end

export type Bait = { id: string, price: number, unlockLevel: number?, biteReduction: number, midMult: number?, lateMult: number? }

-- Umpan (Bab 6.3): dipakai otomatis per lemparan, yang pertama dipunyai dari urutan list.
-- Efek: Jangkrik gigitan 30% lebih cepat; Pelet +15% peluang Mid+; Udang Kecil +10% peluang Late+.
local baitList: { Bait } = {
	{ id = "cacing", price = 10, biteReduction = 0 },
	{ id = "jangkrik", price = 25, biteReduction = 0.3 },
	{ id = "pelet", price = 45, biteReduction = 0, midMult = 1.15 },
	{ id = "udang_kecil", price = 80, unlockLevel = 6, biteReduction = 0, lateMult = 1.1 },
}

local baitsById: { [string]: Bait } = {}
for _, bait in baitList do
	baitsById[bait.id] = bait
end

return {
	BITE_MIN = 3, -- seconds, before rod multiplier (Stage 5: gigitan 3-5 dtk)
	BITE_MAX = 5,
	REEL_SECONDS = 3, -- client mini-game length
	REEL_MIN_SECONDS = 2.5, -- server: earliest accepted reel after the bite
	-- REEL_WINDOW removed (user, 16 Nov): NO TIMEOUT. The fish waits on the line until it is reeled in.
	CAST_DISTANCE = 18, -- studs, server-checked

	LOCATIONS = {
		sungai = { unlockLevel = 1 }, -- Basic Mancing (dermaga, Lv 1: the tutorial gate is guide.fishingUnlocked, not the level)
		empang = { unlockLevel = 10 }, -- Pro Mancing
		kolam = { unlockLevel = 1 }, -- building a kolam (Garap > Kolam) and fishing in it
	} :: { [string]: { unlockLevel: number } },

	rodList = rodList,
	rods = rods,
	BAITS = baitList,
	baitsById = baitsById,

	POND = {
		INTERVAL = 600, -- one fish every 10 minutes, also offline
		CAPS = { 10, 20, 30 }, -- fish per pond, by Kolam upgrade tier + 1
		SIZE = 16, -- every player-built pond is SIZE x SIZE studs (4 x 4 terrain cells)
		MAX_PONDS = 4,
		PRICES = { 0, 400, 900, 1600 }, -- koin, by how many ponds you already have + 1 (the first is free)
		TIER_NAMES = { "tanah", "batu", "taman" }, -- look by Kolam upgrade tier + 1 (see PondService)
		REFUND_RATE = 0.5, -- share of the price returned when a pond is removed
	},
}
