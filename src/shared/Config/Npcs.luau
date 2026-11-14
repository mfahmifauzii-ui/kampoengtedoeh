--!strict
-- Town NPCs. Each stands at a spot on the bridge and offers one dialogue: [Jual / Beli] [Sampai jumpa].
-- "Jual / Beli" opens that NPC's shop. Locale keys per NPC: npc.<id> (name), npc.<id>.role, npc.<id>.greet.
--
-- stand : bridge-local studs (x along the road, z along the river). faceZ = +1 / -1: which way the NPC looks.
-- buys  : item kind -> price multiplier (what the NPC pays you), see Modules/Trade.
-- sells : what the NPC sells: seeds, seedsUnggul (faster-growing, pricier), rods, bait, upgrades, fish.
-- Prices live in Modules/Trade; trade rules are enforced by ServerScriptService ShopService.

export type Sells = {
	seeds: boolean?,
	seedsUnggul: boolean?,
	rods: boolean?,
	bait: boolean?,
	upgrades: boolean?,
	fish: boolean?,
	blueprints: boolean?, -- decor blueprints (Config/Blueprints)
}

export type Npc = {
	id: string,
	stand: { x: number, z: number, faceZ: number },
	look: { skin: Color3, shirt: Color3, pants: Color3 },
	buys: { [string]: number },
	sells: Sells,
	haggle: boolean?, -- you can bargain with this NPC when selling (see HAGGLE below)
}

local list: { Npc } = {
	{
		-- Behind the counter of the Warung stall.
		id = "pak_darmo",
		stand = { x = 0, z = -25.2, faceZ = 1 },
		look = { skin = Color3.fromRGB(198, 148, 102), shirt = Color3.fromRGB(220, 206, 176), pants = Color3.fromRGB(96, 70, 50) },
		buys = { crop = 1.0 },
		sells = { seeds = true, upgrades = true },
	},
	{
		-- Toko Bibit (shop 4)
		id = "bu_wati",
		stand = { x = 27, z = 15.5, faceZ = -1 },
		look = { skin = Color3.fromRGB(190, 140, 98), shirt = Color3.fromRGB(150, 168, 128), pants = Color3.fromRGB(110, 84, 66) },
		buys = {},
		sells = { seedsUnggul = true },
	},
	{
		-- Toko Pancing (shop 5)
		id = "mas_joko",
		stand = { x = -28, z = -15.5, faceZ = 1 },
		look = { skin = Color3.fromRGB(176, 128, 90), shirt = Color3.fromRGB(122, 148, 164), pants = Color3.fromRGB(70, 76, 86) },
		buys = {},
		sells = { rods = true, bait = true },
	},
	{
		-- Pasar Ikan (shop 6)
		id = "mbok_minah",
		stand = { x = 28, z = -15.5, faceZ = 1 },
		look = { skin = Color3.fromRGB(200, 152, 110), shirt = Color3.fromRGB(196, 120, 90), pants = Color3.fromRGB(96, 70, 50) },
		buys = { fish = 1.0 },
		sells = { fish = true },
	},
	{
		-- Lapak Tarno (shop 1): a middleman. Pays 0.7x for crops, but you can bargain the price up.
		id = "bang_tarno",
		stand = { x = -27, z = 15.5, faceZ = -1 },
		look = { skin = Color3.fromRGB(168, 120, 84), shirt = Color3.fromRGB(176, 104, 74), pants = Color3.fromRGB(78, 70, 62) },
		buys = { crop = 0.7 },
		sells = {},
		haggle = true,
	},
	{
		-- Toko Tukang (shop 2): the builder. Sells decor blueprints.
		id = "mbak_arsi",
		stand = { x = -9, z = 15.5, faceZ = -1 },
		look = { skin = Color3.fromRGB(196, 146, 104), shirt = Color3.fromRGB(228, 176, 76), pants = Color3.fromRGB(86, 96, 120) },
		buys = {},
		sells = { blueprints = true },
	},
}

local byId: { [string]: Npc } = {}
for _, npc in list do
	byId[npc.id] = npc
end

-- Kedekatan (affinity), 0..100 per NPC. Each tier gives a discount on what you BUY from every NPC and a bonus
-- to your haggling chance (percentage points).
local TIERS = {
	{ id = "asing", min = 0, discount = 0, haggleBonus = 0 },
	{ id = "kenal", min = 20, discount = 0, haggleBonus = 5 },
	{ id = "akrab", min = 50, discount = 0.05, haggleBonus = 10 },
	{ id = "sahabat", min = 80, discount = 0.10, haggleBonus = 15 },
}

local function tierOf(points: number): number
	local tier = 1
	for index, entry in TIERS do
		if points >= entry.min then
			tier = index
		end
	end
	return tier
end

-- Bargaining offers: pct = how far above the NPC's base price you ask. Bigger asks need a closer relationship.
-- The best ask (+64% of Bang Tarno's 0.7x) lands at 1.15x Pak Darmo's price, never above (HAGGLE.CAP_MULT).
local OFFERS: { { pct: number, minTier: number? } } = {
	{ pct = 10 },
	{ pct = 20 },
	{ pct = 30 },
	{ pct = 40, minTier = 2 },
	{ pct = 50, minTier = 3 },
	{ pct = 64, minTier = 4 },
}

return {
	list = list,
	byId = byId,

	TIERS = TIERS,
	tierOf = tierOf,
	AFFINITY = {
		MAX = 100,
		TALK_GAIN = 2, -- first chat of the day
		TRADE_GAIN = 1, -- each trade ...
		TRADE_DAILY_CAP = 5, -- ... up to this much per NPC per day
		HAGGLE_WIN = 1,
		HAGGLE_LOSS = 1, -- never drops you below the tier you already reached
	},

	HAGGLE = {
		OFFERS = OFFERS,
		BASE_CHANCE = 70, -- percent, before the ask, affinity and skill
		MIN_CHANCE = 5,
		MAX_CHANCE = 95,
		FAIL_STREAK = 2, -- this many failures in a row ...
		PAUSE_SECONDS = 60, -- ... and the NPC won't bargain for this long (selling at the base price still works)
		CAP_MULT = 1.15, -- a haggled price never exceeds this multiple of the item's full sell value
		XP_WIN = 6, -- "tawar" skill XP
		XP_LOSS = 2,
	},

	TALK_DISTANCE = 10, -- studs: how close the "Ngobrol" prompt appears
	LEAVE_DISTANCE = 30, -- the client closes the dialogue / shop when you walk this far away

	SEED_UNGGUL_PRICE_MULT = 1.5, -- Bu Wati's seeds cost this much more than Pak Darmo's...
	FISH_SELL_MULT = 1.3, -- Mbok Minah sells fish (size Kecil) at this multiple of its sell value
	FISH_FOR_SALE = { C = true, U = true } :: { [string]: boolean }, -- rarities she keeps in stock
}
