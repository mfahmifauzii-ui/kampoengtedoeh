--!strict
-- Default save for a NEW player (version 62, docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 28). ProfileStore:Reconcile()
-- adds missing keys. No migration code: the game is unreleased, a changed shape means a new DATA_STAGE in DataService.

local Economy = require(script.Parent.Economy)
local Types = require(script.Parent.Parent.Types)

local template: Types.PlayerData = {
	version = 62,

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
	upgrades = { backpack = 0, pond = 0 }, -- tier per upgrade (Config/Shop UPGRADES, Modules/Upgrades)

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

	tools = { gembor = false }, -- Stage 2: owned farm tools (Config/Farm TOOLS), bought with Koin

	pond = {
		list = {},-- { PondEntry } ponds the player built (the Lv 2 quest gives the first one free)
		nextUid = 1,
	},

	decor = {
		placed = {}, -- { {uid, id, x, z, r} } grid cells on the owner's plot
		stock = {}, -- [itemId] = count owned but not placed
		nextUid = 1,
		blueprints = {}, -- [blueprintId] = true (bought from Pak Amran, Config/Blueprints)
	},

	orders = {
		day = "", -- WIB day key of the current daily set
		daily = {}, -- { OrderEntry }
		rerollsUsed = 0,
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
		crops = {}, -- [id] = true
		fish = {}, -- [id] = best size index (1 = S, 2 = M, 3 = L)
		decor = {}, -- [id] = true
		claimed = {}, -- [milestoneId or "cat:<category>"] = true
	},

	titles = {}, -- [titleId] = true

	land = {
		chunks = {}, -- bought 32 x 32 blocks of the plot, "ix,iz" keys (Modules/Land); the start land is always owned
		-- Bab 3.4 LahanAwal: 1 bit per clearable starting object (64 = ilalang 40, semak 12, batu 8, tunggul 4). Bit 1 = still there.
		lahanAwal = { lo = 4294967295, hi = 4294967295 }, -- two 32-bit halves (objects 1-32, 33-64); all 64 present at the start
		chunkLahan = {}, -- ["ix,iz"] = bits of the starting-style objects on a bought chunk (Config/LahanAwal CHUNK_FULL_BITS when absent)
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
	instantGrow = { tokens = 0, day = "", usedToday = 0 },
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
