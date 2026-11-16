--!strict
-- All fish. Add a fish here + a "fish.<id>" locale key; no logic changes needed.
-- Rarity: C (common), U (uncommon), R (rare), L (legendary).
-- requirePhases / requireRain: the fish can ONLY be caught then.
-- boost: weight multiplier when the condition holds (still catchable otherwise).
-- Day phases: "pagi" | "siang" | "sore" | "malam".

export type Rarity = "C" | "U" | "R" | "L"

export type Fish = {
	id: string,
	rarity: Rarity,
	locations: { string },
	sellPrice: number,
	requirePhases: { string }?,
	requireRain: boolean?,
	boost: { phase: string?, rain: boolean?, mult: number }?,
}

local list: { Fish } = {
	{ id = "wader", rarity = "C", locations = { "sungai" }, sellPrice = 8 },
	{ id = "nila", rarity = "C", locations = { "empang", "kolam" }, sellPrice = 10 },
	{ id = "mujair", rarity = "C", locations = { "empang" }, sellPrice = 10 },
	{ id = "lele", rarity = "C", locations = { "kolam", "empang" }, sellPrice = 12, boost = { phase = "malam", mult = 2 } },
	{ id = "mas", rarity = "U", locations = { "empang", "kolam" }, sellPrice = 20 },
	{ id = "bawal", rarity = "U", locations = { "empang" }, sellPrice = 28 },
	{ id = "gabus", rarity = "U", locations = { "sungai" }, sellPrice = 35, requirePhases = { "sore", "malam" } },
	{ id = "belut", rarity = "U", locations = { "sungai" }, sellPrice = 40, requireRain = true },
	{ id = "gurame", rarity = "R", locations = { "empang" }, sellPrice = 25, requirePhases = { "pagi" } },
	{ id = "udang_galah", rarity = "R", locations = { "sungai" }, sellPrice = 90, requirePhases = { "malam" } },
	{ id = "koi", rarity = "R", locations = { "kolam" }, sellPrice = 150, boost = { rain = true, mult = 2 } },
	{ id = "arwana", rarity = "L", locations = { "sungai" }, sellPrice = 500, requirePhases = { "malam" }, requireRain = true },
}

local byId: { [string]: Fish } = {}
for _, fish in list do
	byId[fish.id] = fish
end

return {
	list = list,
	byId = byId,

	RARITY_WEIGHTS = { C = 70, U = 22, R = 7, L = 1 } :: { [Rarity]: number },
	RAIN_MULT = { R = 1.5, L = 2 } :: { [Rarity]: number },

	-- Reel score (0..1) -> size. Value multiplier applies when selling.
	SIZES = {
		{ id = "S", minScore = 0, valueMult = 1.0 },
		{ id = "M", minScore = 0.5, valueMult = 1.2 },
		{ id = "L", minScore = 0.85, valueMult = 1.5 },
	},
}
