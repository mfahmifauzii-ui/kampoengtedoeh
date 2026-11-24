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
	-- Waktu tunggu gigitan (Skill Tree / Gameplay Bab 6.1 dan 3.3). Urutan pengali (fishing bite): base (di bawah) x rod.biteMult
	-- (tabel joran) x umpan (Jangkrik x0,7 lewat biteReduction) x buff Pancing (x0,8). Hujan tidak mengubah waktu (K-01). Lihat FishService.biteDelayFor.
	BITE_MIN = 3, -- detik, dengan umpan (Bab 6.1: 3-6 dtk)
	BITE_MAX = 6,
	-- Kolam (pond) only: a pond cast uses no bait (Bab 6.1, pond rule). Sungai and empang need a bait (K-86): no bait, no cast.
	POND_BITE_MIN = 6, -- detik, kolam tanpa umpan (Bab 6.1: 6-12 dtk)
	POND_BITE_MAX = 12,
	REEL_SECONDS = 3, -- client mini-game length
	REEL_MIN_SECONDS = 2.5, -- server: earliest accepted reel after the bite
	-- REEL_WINDOW removed (user, 16 Nov): NO TIMEOUT. The fish waits on the line until it is reeled in.
	CAST_DISTANCE = 18, -- studs, server-checked
	ZONE_WIDTH_DEFAULT = 0.3, -- D-38: kotak tarik (fraksi bilah) saat joran tidak dikenal; server yang menghitung kotak (FishService)
	LEAVE_DISTANCE = 24, -- studs: pemain yang lebih jauh dari spot dianggap menjauh = batal (watchdog server, B-5)

	-- Animasi joran (B-5, Roadmap §12.4): ID Animation PERMANEN (Publish to Roblox), BUKAN hash sementara Studio.
	-- Kosong = belum ada: server tidak memutar animasi, joran tetap pose statis. Isi setelah owner publish.
	ANIMS = {
		FishingIdle = "rbxassetid://129209607577233",
		FishingCast = "rbxassetid://125111359649938",
		FishingReel = "rbxassetid://71161306862981",
		FishingCatch = "rbxassetid://119260434073900",
	} :: { [string]: string },

	LOCATIONS = {
		sungai_lahan = { unlockLevel = 1 }, -- Sungai lahan (Update owner 2026-11-22): 32 spot di 4 sungai sumbu, Early saja
		sungai = { unlockLevel = 5 }, -- Kanal barat (dermaga), Lv 5: Mid + Belut Emas (Config/Fish). Mancing tutorial: lihat Onboarding
		empang = { unlockLevel = 10 }, -- Pro Mancing (kanal timur)
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
		REFUND_RATE = 1.0, -- share of the price returned when a pond is removed (K-09: bangunan & kolam refund 100%)
		UNLOCK_LEVEL = 4, -- Lv 4 (Q-2): Quest M3 Kolam Kakek. Dulu Lv 2: the player may build a kolam (first step of Quest Kolam). Kolam Kakek (MQ4/Bundel) opens it too.
	},
}
