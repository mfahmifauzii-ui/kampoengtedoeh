--!strict
-- Town NPCs. Each stands in front of a shophouse on the town island and offers one dialogue: [Jual / Beli] [Sampai jumpa].
-- "Jual / Beli" opens that NPC's shop. Locale keys per NPC: npc.<id> (name), npc.<id>.role, npc.<id>.greet.
--
-- stand : world studs on the town island (x, z) and the rig's yaw (a rig looks toward its local -Z, so yaw = pi looks
--         toward +Z). Shop NPCs stand in front of their shop's door and face the island center (Config/Map SHOPS).
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
	tools: boolean?, -- farm tools (Config/Farm TOOLS), Stage 2
}

export type Npc = {
	id: string,
	meet: string, -- Locale key: the first talk's sapaan and perkenalan, {name} = the player (Client DialogueController)
	stand: { x: number, z: number, y: number?, yaw: number },
	look: { skin: Color3, shirt: Color3, pants: Color3 },
	buys: { [string]: number },
	sells: Sells,
	quota: boolean?, -- buys each crop only up to the daily quota (Pak Darmo)
	miniIndex: number?, -- Bang Tarno at the n-th "Warung Mini": stands beside that stall, ignores `stand`
	model: string?, -- ServerStorage.NpcModels.<model> rig to clone (default: the npc id); else a plain colour-only rig is built
}

local Map = require(script.Parent.Map)

-- Where the shopkeeper of shop slot `slot` stands (Map.SHOPS: 8 shophouses on a circle around the banyan tree).
local function atShop(slot: number): { x: number, z: number, yaw: number }
	local shop = Map.SHOPS[slot]
	return { x = shop.standX, z = shop.standZ, yaw = shop.standYaw }
end

local list: { Npc } = {
	{
		-- Behind the counter of the Warung stall. Best price (1.0x), but only up to the daily quota per crop.
		id = "pak_darmo",
		meet = "npc.pak_darmo.meet",
		stand = { x = -3.832, z = 55.594, y = 5.8, yaw = math.rad(-32.99) }, -- spot picked in Studio (x -3.832, z 55.594, yaw -32.99 deg); y lowered from 8.449 to 5.8 so the feet touch the plank (plank top ~5.1 here; pivot = feet + 0.68). Explicit y: NpcService does not re-seat him
		look = { skin = Color3.fromRGB(198, 148, 102), shirt = Color3.fromRGB(220, 206, 176), pants = Color3.fromRGB(96, 70, 50) },
		buys = { crop = 1.0 },
		sells = { seeds = true, upgrades = true, tools = true },
		quota = true,
	},
	{
		-- Toko Bibit (shop slot 1)
		id = "bu_wati",
		meet = "npc.bu_wati.meet",
		stand = atShop(1), -- shop 1
		look = { skin = Color3.fromRGB(190, 140, 98), shirt = Color3.fromRGB(150, 168, 128), pants = Color3.fromRGB(110, 84, 66) },
		buys = {},
		sells = { seedsUnggul = true },
	},
	{
		-- Toko Pancing (shop slot 5)
		id = "mas_joko",
		meet = "npc.mas_joko.meet",
		stand = atShop(5), -- shop 5
		look = { skin = Color3.fromRGB(176, 128, 90), shirt = Color3.fromRGB(122, 148, 164), pants = Color3.fromRGB(70, 76, 86) },
		buys = {},
		sells = { rods = true, bait = true },
	},
	{
		-- Pasar Ikan (shop slot 2)
		id = "mbok_minah",
		meet = "npc.mbok_minah.meet",
		stand = atShop(2), -- shop 2
		look = { skin = Color3.fromRGB(200, 152, 110), shirt = Color3.fromRGB(196, 120, 90), pants = Color3.fromRGB(96, 70, 50) },
		buys = { fish = 1.0 },
		sells = { fish = true },
	},
	{
		-- Toko Tukang (shop slot 4): the builder. Sells decor blueprints.
		id = "mbak_arsi",
		meet = "npc.mbak_arsi.meet",
		stand = atShop(4), -- shop 4
		look = { skin = Color3.fromRGB(196, 146, 104), shirt = Color3.fromRGB(228, 176, 76), pants = Color3.fromRGB(86, 96, 120) },
		buys = {},
		sells = { blueprints = true },
	},
}

-- Bang Tarno runs every "Warung Mini" (hand-placed models named "Warung Mini" in Workspace, one per ring-road axis).
-- He replaces the old Lapak Tarno: pays MINI_BUY_MULT x Pak Darmo's price for crops, with no daily quota. One NPC per
-- stall (ids bang_tarno_1 .. _N, same name and dialogue); NpcService stands each beside its stall, see miniStand.
local MINI_COUNT = 8 -- one per plot gate (v2): every land has its own Warung Mini in front of its gate
local MINI_BUY_MULT = 0.9
for i = 1, MINI_COUNT do
	table.insert(list, {
		id = `bang_tarno_{i}`,
		meet = "npc.bang_tarno.meet",
		stand = { x = 0, z = 0, yaw = 0 }, -- unused: placed beside the stall at runtime (miniIndex)
		miniIndex = i,
		model = "bang_tarno",
		look = { skin = Color3.fromRGB(168, 120, 84), shirt = Color3.fromRGB(176, 104, 74), pants = Color3.fromRGB(78, 70, 62) },
		buys = { crop = MINI_BUY_MULT },
		sells = {},
	})
end

local byId: { [string]: Npc } = {}
for _, npc in list do
	byId[npc.id] = npc
end

return {
	list = list,
	byId = byId,
	MINI_STALL_NAME = "Warung Mini",
	MINI_SIDE_OFFSET = 13, -- studs along the stall's local X (left of the counter seen from the front)
	MINI_FRONT_OFFSET = -3, -- studs along the stall's local Z (negative = toward the front, where the counter faces)

	-- Pak Darmo's daily quota (WIB day): PER_CROP of each crop type at the start, +PER_TIER per "Kapasitas Warung"
	-- upgrade (Config/Shop). Values are assumptions: simulate with tools/balance_sim.py before locking them.
	QUOTA = {
		PER_CROP = 20,
		PER_TIER = 5,
	},

	TALK_DISTANCE = 16, -- studs: how close the "Ngobrol" prompt appears
	LEAVE_DISTANCE = 30, -- the client closes the dialogue / shop when you walk this far away

	SEED_UNGGUL_PRICE_MULT = 1.5, -- Bu Wati's seeds cost this much more than Pak Darmo's...
	FISH_SELL_MULT = 1.3, -- Mbok Minah sells fish (size Kecil) at this multiple of its sell value
	FISH_FOR_SALE = { C = true, U = true } :: { [string]: boolean }, -- rarities she keeps in stock
}
