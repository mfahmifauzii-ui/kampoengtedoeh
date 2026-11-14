--!strict
-- Town NPCs. Each stands at a spot on the bridge and offers one dialogue: [Jual / Beli] [Sampai jumpa].
-- "Jual / Beli" opens that NPC's shop. Locale keys per NPC: npc.<id> (name), npc.<id>.role, npc.<id>.greet.
--
-- stand : bridge-local studs (x along the road, z along the river). faceZ = +1 / -1: which way the NPC looks.
-- buys  : item kind -> price multiplier (what the NPC pays you), see Modules/Trade.
-- quota : the NPC buys each crop only up to a daily quota (QUOTA below); past it, sell to the next buyer.
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
	quota: boolean?, -- buys each crop only up to the daily quota (Pak Darmo)
}

local list: { Npc } = {
	{
		-- Behind the counter of the Warung stall. Best price (1.0x), but only up to the daily quota per crop.
		id = "pak_darmo",
		stand = { x = 0, z = -25.2, faceZ = 1 },
		look = { skin = Color3.fromRGB(198, 148, 102), shirt = Color3.fromRGB(220, 206, 176), pants = Color3.fromRGB(96, 70, 50) },
		buys = { crop = 1.0 },
		sells = { seeds = true, upgrades = true },
		quota = true,
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
		-- Lapak Tarno (shop 1): the middleman. Pays 0.7x for crops with no limit: where you sell once
		-- Pak Darmo's daily quota for a crop is used up.
		id = "bang_tarno",
		stand = { x = -27, z = 15.5, faceZ = -1 },
		look = { skin = Color3.fromRGB(168, 120, 84), shirt = Color3.fromRGB(176, 104, 74), pants = Color3.fromRGB(78, 70, 62) },
		buys = { crop = 0.7 },
		sells = {},
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

return {
	list = list,
	byId = byId,

	-- Pak Darmo's daily quota (WIB day): PER_CROP of each crop type at the start, +PER_TIER per "Kapasitas Warung"
	-- upgrade (Config/Shop). Values are assumptions: simulate with tools/balance_sim.py before locking them.
	QUOTA = {
		PER_CROP = 20,
		PER_TIER = 5,
	},

	TALK_DISTANCE = 10, -- studs: how close the "Ngobrol" prompt appears
	LEAVE_DISTANCE = 30, -- the client closes the dialogue / shop when you walk this far away

	SEED_UNGGUL_PRICE_MULT = 1.5, -- Bu Wati's seeds cost this much more than Pak Darmo's...
	FISH_SELL_MULT = 1.3, -- Mbok Minah sells fish (size Kecil) at this multiple of its sell value
	FISH_FOR_SALE = { C = true, U = true } :: { [string]: boolean }, -- rarities she keeps in stock
}
