--!strict
-- Default save for a NEW player (version 72, Kampoeng_Tedoeh_v7.3 Bab 28). ProfileStore:Reconcile()
-- adds missing keys. No migration code: the game is unreleased, a changed shape means a new DATA_STAGE in DataService.

local Economy = require(script.Parent.Economy)
local Types = require(script.Parent.Parent.Types)

local template: Types.PlayerData = {
	version = 72,

	koin = Economy.START_KOIN,
	bunga = Economy.START_BUNGA,
	xp = 0,
	level = 1,
	sp = 0, -- Skill Point: 1 per Level Player (Bab 4.2), spent on Skill Cabang (Bab 4.5)
	-- Level Cabang (Bab 4.2): Bertani, Mancing, Beternak, Tukang. Max Lv 10. XP is the same amount as the player's XP per action.
	cabang = {
		bertani = { lv = 0, xp = 0 },
		mancing = { lv = 0, xp = 0 },
		beternak = { lv = 0, xp = 0 },
		tukang = { lv = 0, xp = 0 },
	},
	skill = {}, -- [skillId] = level 0..5 (Bab 4.5)

	stats = {
		firstJoin = 0,
		lastLogin = 0,
		sessions = 0,
	},

	inventory = { seed_kangkung = 6 }, -- [itemId] = count. A new player starts with a few seeds (Pak Udin sells more)
	upgrades = { pond = 0 }, -- tier per upgrade (Config/Shop UPGRADES, Modules/Upgrades)

	farm = {
		tiles = {}, -- tilled soil tiles { uid, cx, cz, crop?... }; a new player tills their own (Garap)
		nextUid = 1,
	},

	fishing = {
		-- New accounts start WITHOUT a rod (Plan v3.1 3A, Opsi B): Kak Fajar gives the Joran Bambu (Terima Hadiah).
		-- Old accounts keep the rod they already have: this default only fills keys that are missing.
		rod = "", -- equipped rod id ("" = none)
		ownedRods = {},
	},

	tools = {}, -- owned farm tools (Config/Farm TOOLS: gembor/sabit/sepatu/kapak), bought with Koin + bahan

	pond = {
		list = {},-- { PondEntry } ponds the player built
		nextUid = 1,
		kakekUnlocked = false, -- Kolam Kakek pulih (MQ4/Bundel Kakek P2-7). PondBuild butuh ini.
	},

	ranch = {
		kandang = {}, -- [hewanId] = { tier, cx, cz, animals } (Config/Ranch)
		moodUntil = 0, -- os.time akhir Mood Hujan, 0 = tidak aktif
	},

	dapur = {
		tier = 0, -- 0 = belum bangun, 1/2/3 (Config/Dapur TIERS)
		slots = {}, -- array 1..3 (false = kosong): DataStore aman tanpa hole
		spot = nil, -- sel bangunan (auto-place saat bangun)
	},

	warung = {
		item = nil, -- { id, count } pajangan (1 jenis olahan + jumlah)
		spot = nil, -- sel bangunan (auto-place saat bangun)
		nextVisit = 0,
		soldLogin = 0, -- penjualan offline login ini (max 5)
	},

	buff = { id = nil, endsAt = 0 }, -- 1 buff aktif (makan olahan; timer real-time)

	mining = {
		nodes = {}, -- [nodeId] = { hits, readyAt }: sisa pukulan + waktu respawn per-player (Config/Mining)
	},

	decor = {
		placed = {}, -- { {uid, id, x, z, r} } grid cells on the owner's plot
		stock = {}, -- [itemId] = count owned but not placed
		nextUid = 1,
	},

	orders = {
		day = "", -- WIB day key of the current daily set
		daily = {}, -- { OrderEntry }
		rerollsUsed = 0,
		rerolled = {}, -- [orderUid] = true: order harian yang sudah di-reroll hari ini (max 1x)
		week = "",
		weekly = {}, -- OrderEntry, or {} when none yet
		nextUid = 1,
	},

	quests = {
		active = {}, -- [questId] = { step = 1, count = 0 } (see Config/Quests)
		done = {}, -- [questId] = true
		daily = { day = "", kind = "", progress = 0, claimed = false }, -- Stage 7: Daily Quest (Config/Quests DAILY), reset 05:00 WIB
	},

	playtime = { day = "", seconds = 0, claimed = 0 }, -- Hadiah playtime: active seconds today, chests opened today (Config/Progression PLAYTIME)

	book = {
		ladang = {}, -- ["{crop}:{biasa|bagus|prima}"] = true
		sungai = {}, -- ["{fish}@{S|M|L|Jumbo}"] = true
		kandang = {}, -- [id] = true
		rumah = {}, -- [id] = true
		dapur = {}, -- ["{resep}:{biasa|bagus|prima}"] = true
		varian = {}, -- [id] = true
		claimed = {}, -- [milestoneId or "cat:<category>"] = true
	},

	titles = {}, -- [titleId] = true

	land = {
		chunks = {}, -- bought 32 x 32 blocks of the plot, "ix,iz" keys (Modules/Land); the start land is always owned
	},
	plotSlot = 0, -- last plot number (PlotService tries to give it back)

	social = {
		likes = 0, -- likes received on your plot (all time)
		milestones = {}, -- [likesThreshold as string] = true
		likedDay = "", -- WIB day of likedToday
		likedToday = {}, -- [ownerUserId as string] = true (plots you liked today)
	},

	settings = { music = true, ambient = true, sfx = true, musicVol = 1, sfxVol = 1, quality = 2 }, -- volumes are a share (0..1) of Audio.VOLUME; quality 1 Rendah, 2 Sedang, 3 Tinggi

	passes = {}, -- [passKey] = true; cache of confirmed game pass ownership (fallback if API is down)
	onboarding = {}, -- [stepNumber] = true (analytics funnel, logged once)
	-- sells: sale trips done (Config/Onboarding TRIES), the old guide stops after that many.
	-- Tutorial engine (Config/Onboarding TUTORIALS, server/TutorialService): step = the running tutorial {id, n = steps done},
	-- done/skipped = [tutorialId] = true, fastLeft = plantings still on the fast tutorial timer (-1 = not decided yet:
	-- TutorialService sets 6 for a brand-new save and 0 for an old one on load).
	-- hasMet = [npcId] = true once the player has had the first talk with that NPC (Fase 2: sapaan, then the choices).
	guide = { sells = 0, step = { id = "", n = 0 }, done = {}, skipped = {}, fastLeft = -1, hasMet = {}, rodGift = false, fishingUnlocked = false, fishCaught = false, kolamUnlocked = false, decorUnlocked = false, saleCutscene = false },
	purchaseIdCache = {}, -- last N dev product PurchaseIds (ProfileStore pattern; prevents double-grant)
}

return template
