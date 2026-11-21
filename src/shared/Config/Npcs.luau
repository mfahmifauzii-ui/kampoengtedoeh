--!strict
-- Town NPCs (names and roles per docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 10). Each stands in front of a
-- shophouse on the town island, or beside a Warung Mini at a plot gate, and offers one dialogue: [Jual / Beli] [Sampai jumpa].
-- "Jual / Beli" opens that NPC's shop. Locale keys per NPC: npc.<id> (name), npc.<id>.role, npc.<id>.greet, npc.<id>.meet.
--
-- stand : world studs on the town island (x, z) and the rig's yaw (a rig looks toward its local -Z, so yaw = pi looks
--         toward +Z). Shop NPCs stand in front of their shop's door and face the island center (Config/Map SHOPS).
-- buys  : item kind -> price multiplier (what the NPC pays you), see Modules/Trade. Raw produce = crop.
-- sells : what the NPC sells: seeds, rods, bait, upgrades, fish, tools. Bibit Unggul DIHAPUS (Bab 29), Blueprint bukan gating (Bab 8.7).
-- unlockLevel : the NPC's shop stays closed below this player level; the dialogue shows npc.<id>.locked instead.
-- hidden : the NPC is in the config but not spawned yet (its feature comes in a later phase).
-- Prices live in Modules/Trade; trade rules are enforced by ServerScriptService ShopService.

export type Sells = {
	seeds: boolean?,
	rods: boolean?,
	bait: boolean?,
	upgrades: boolean?,
	fish: boolean?,
	tools: boolean?, -- farm tools (Config/Farm TOOLS)
}

export type Npc = {
	id: string,
	meet: string, -- Locale key: the first talk's sapaan and perkenalan, {name} = the player (Client DialogueController)
	stand: { x: number, z: number, y: number?, yaw: number },
	look: { skin: Color3, shirt: Color3, pants: Color3 },
	buys: { [string]: number },
	sells: Sells,
	miniIndex: number?, -- Bang Jali at the n-th "Warung Mini": stands in front of that stall, ignores `stand`
	model: string?, -- ServerStorage.NpcModels.<model> rig to clone (default: the npc id); else a plain colour-only rig is built
	unlockLevel: number?, -- player level needed before the shop opens (Mak Sari: Dapur Tier 1, Lv 6)
	hidden: boolean?, -- configured but not spawned yet (Pedagang Tamu, Tamu Event: Fase 7)
}

local Map = require(script.Parent.Map)

-- Bab 22.3: an NPC walking to the player moves at this speed (studs/s). 8 = 50% of the default player speed (16).
local WALK_SPEED = 8

-- Where the shopkeeper of shop slot `slot` stands (Map.SHOPS: 8 shophouses on a circle around the banyan tree).
-- Slots: 1 Toko Bibit (no NPC), 2 Pasar Ikan (no NPC), 3 Pos Ronda (Nek Ani), 4 Toko Tukang (Pak Amran),
-- 5 Toko Pancing (Kak Fajar), 6 Toko Roti (no NPC), 7 Warung Mak Sari (Mak Sari), 8 Toko Kelontong (no NPC).
local function atShop(slot: number): { x: number, z: number, yaw: number }
	local shop = Map.SHOPS[slot]
	return { x = shop.standX, z = shop.standZ, yaw = shop.standYaw }
end

local list: { Npc } = {
	{
		-- Behind the counter of the main warung. Sells bibit biasa and tools, buys raw produce at full price. Bibit Unggul DIHAPUS (Bab 29).
		id = "pak_udin",
		meet = "npc.pak_udin.meet",
		stand = { x = -3.832, z = 55.594, y = 5.8, yaw = math.rad(-32.99) }, -- spot picked in Studio (x -3.832, z 55.594, yaw -32.99 deg); y lowered from 8.449 to 5.8 so the feet touch the plank (plank top ~5.1 here; pivot = feet + 0.68). Explicit y: NpcService does not re-seat him
		look = { skin = Color3.fromRGB(198, 148, 102), shirt = Color3.fromRGB(220, 206, 176), pants = Color3.fromRGB(96, 70, 50) },
		buys = { crop = 1.0 },
		sells = { seeds = true, upgrades = true, tools = true },
	},
	{
		-- Toko Pancing (shop slot 5): joran, umpan, and buys fish at full price. Moves to the canal bank in Fase 3.
		id = "kak_fajar",
		meet = "npc.kak_fajar.meet",
		stand = atShop(5), -- shop 5
		look = { skin = Color3.fromRGB(176, 128, 90), shirt = Color3.fromRGB(122, 148, 164), pants = Color3.fromRGB(70, 76, 86) },
		buys = { fish = 1.0 },
		sells = { rods = true, bait = true, fish = true },
	},
	{
		-- Toko Tukang (shop slot 4): the carpenter. Blueprint = simpan / share desain, bukan gating (Bab 8.7). Simpan/share belum di-code.
		id = "pak_amran",
		meet = "npc.pak_amran.meet",
		stand = atShop(4), -- shop 4
		look = { skin = Color3.fromRGB(196, 146, 104), shirt = Color3.fromRGB(228, 176, 76), pants = Color3.fromRGB(86, 96, 120) },
		buys = {},
		sells = {},
	},
	{
		-- Warung Mak Sari (shop slot 7). Buys processed food (olahan) at full price once the Dapur is open (Lv 6).
		id = "mak_sari",
		meet = "npc.mak_sari.meet",
		stand = atShop(7), -- shop 7
		look = { skin = Color3.fromRGB(200, 152, 110), shirt = Color3.fromRGB(196, 120, 90), pants = Color3.fromRGB(96, 70, 50) },
		buys = {}, -- olahan is buyable from Fase 5 (Dapur)
		sells = {},
		unlockLevel = 6,
	},
	{
		-- Pos Ronda (shop slot 3): rings the kentongan after a storm (Kerja Bakti Kilat, Fase 7). Sells nothing.
		id = "nek_ani",
		meet = "npc.nek_ani.meet",
		stand = atShop(3), -- shop 3
		look = { skin = Color3.fromRGB(186, 132, 96), shirt = Color3.fromRGB(150, 110, 150), pants = Color3.fromRGB(90, 70, 60) },
		buys = {},
		sells = {},
	},
	{
		-- Pedagang Tamu: rotating trader at the Pasar Malam (Fase 7). Not spawned yet.
		id = "pedagang_tamu",
		meet = "npc.pedagang_tamu.meet",
		stand = atShop(6), -- placeholder spot, unused while hidden
		look = { skin = Color3.fromRGB(190, 140, 98), shirt = Color3.fromRGB(180, 80, 60), pants = Color3.fromRGB(70, 60, 50) },
		buys = {},
		sells = {},
		hidden = true,
	},
	{
		-- Tamu Event: guest at the banyan's pelataran during an event (Fase 7). Not spawned yet.
		id = "tamu_event",
		meet = "npc.tamu_event.meet",
		stand = atShop(6), -- placeholder spot, unused while hidden
		look = { skin = Color3.fromRGB(176, 128, 90), shirt = Color3.fromRGB(230, 200, 120), pants = Color3.fromRGB(60, 60, 70) },
		buys = {},
		sells = {},
		hidden = true,
	},
}

-- Bang Jali runs every "Warung Mini" (hand-placed models named "Warung Mini" in Workspace, one per plot gate).
-- He buys EVERYTHING at 90% of the item's price and sells nothing (v6.2 Bab 10.2). One NPC per stall
-- (ids bang_jali_1 .. _N, same name and dialogue); NpcService stands each beside its stall, see miniStand.
local MINI_COUNT = 8 -- one per plot gate: every land has its own Warung Mini in front of its gate
local MINI_BUY_MULT = 0.9
for i = 1, MINI_COUNT do
	table.insert(list, {
		id = `bang_jali_{i}`,
		meet = "npc.bang_jali.meet",
		stand = { x = 0, z = 0, yaw = 0 }, -- unused: placed beside the stall at runtime (miniIndex)
		miniIndex = i,
		model = "bang_jali",
		look = { skin = Color3.fromRGB(168, 120, 84), shirt = Color3.fromRGB(176, 104, 74), pants = Color3.fromRGB(78, 70, 62) },
		buys = { crop = MINI_BUY_MULT, fish = MINI_BUY_MULT, ternak = MINI_BUY_MULT }, -- EVERYTHING: produk ternak Bab 7.1
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
	MINI_SIDE_OFFSET = 0, -- studs along the stall's local X: 0 = centred in front of the stall
	MINI_FRONT_OFFSET = -12, -- studs along the stall's local Z (negative = in front, where the counter faces). The stall's front edge is at Z -8.8, so this leaves about 3 studs of room

	WALK_SPEED = WALK_SPEED, -- Bab 22.3: NPC walk-up speed (studs/s), see NpcService.WalkTo
	TALK_DISTANCE = 16, -- studs: how close the "Ngobrol" prompt appears
	LEAVE_DISTANCE = 30, -- the client closes the dialogue / shop when you walk this far away

	FISH_SELL_MULT = 1.3, -- Kak Fajar sells fish (size Kecil) at this multiple of its sell value
	FISH_FOR_SALE = { C = true, U = true } :: { [string]: boolean }, -- rarities Kak Fajar keeps in stock
}
