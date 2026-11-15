--!strict
-- Fishing rules, rods, locations and the player-built ponds (kolam).

export type Rod = {
	id: string,
	price: number,
	unlockLevel: number,
	biteMult: number, -- multiplies bite wait time
	rareBonus: number, -- added to R tier weight
	legendaryBonus: number, -- added to L tier weight
}

local rodList: { Rod } = {
	{ id = "bambu", price = 0, unlockLevel = 1, biteMult = 1.0, rareBonus = 0, legendaryBonus = 0 },
	{ id = "rotan", price = 500, unlockLevel = 5, biteMult = 0.85, rareBonus = 2, legendaryBonus = 0 },
	{ id = "fiber", price = 2000, unlockLevel = 10, biteMult = 0.75, rareBonus = 4, legendaryBonus = 0 },
	{ id = "juragan", price = 6000, unlockLevel = 18, biteMult = 0.65, rareBonus = 6, legendaryBonus = 1 },
}

local rods: { [string]: Rod } = {}
for _, rod in rodList do
	rods[rod.id] = rod
end

return {
	BITE_MIN = 4, -- seconds, before rod multiplier
	BITE_MAX = 10,
	REEL_SECONDS = 3, -- client mini-game length
	REEL_MIN_SECONDS = 2.5, -- server: earliest accepted reel after the bite
	REEL_WINDOW = 30, -- server: bite expires after this
	CAST_DISTANCE = 18, -- studs, server-checked

	LOCATIONS = {
		sungai = { unlockLevel = 2 }, -- Basic Mancing
		empang = { unlockLevel = 10 }, -- Pro Mancing
		kolam = { unlockLevel = 2 }, -- building a kolam (Garap > Kolam) and fishing in it
	} :: { [string]: { unlockLevel: number } },

	-- Optional bait: one is used automatically per cast while you have any.
	BAIT = { id = "pelet", price = 5, biteReduction = 0.3 },

	rodList = rodList,
	rods = rods,

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
