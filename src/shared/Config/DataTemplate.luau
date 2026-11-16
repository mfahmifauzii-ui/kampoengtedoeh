--!strict
-- Default save for a NEW player. ProfileStore:Reconcile() adds missing keys to old saves,
-- so new fields can simply be added here. Renames/restructures need a migration
-- (ServerScriptService.Server.Data.Migrations) + bump `version`.

local Economy = require(script.Parent.Economy)
local Types = require(script.Parent.Parent.Types)

local template: Types.PlayerData = {
	version = 13,

	koin = Economy.START_KOIN,
	bunga = Economy.START_BUNGA,
	xp = 0,
	level = 1,

	stats = {
		firstJoin = 0,
		lastLogin = 0,
		sessions = 0,
	},

	inventory = { seed_kangkung = 6 }, -- [itemId] = count. A new player starts with a few seeds (Pak Darmo sells more)
	upgrades = { backpack = 0, pond = 0, warung = 0 }, -- tier per upgrade (Config/Shop UPGRADES, Modules/Upgrades)

	farm = {
		tiles = {}, -- tilled soil tiles { uid, cx, cz, crop?... }; a new player tills their own (Garap)
		nextUid = 1,
	},

	fishing = {
		rod = "bambu", -- equipped rod id
		ownedRods = { bambu = true },
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
		blueprints = {}, -- [blueprintId] = true (bought from Mbak Arsi, Config/Blueprints)
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

	visits = { count = 0, lastDay = "", pending = false }, -- Kunjungan Harian (cumulative). pending = today's bonus can be claimed (after T1, user 16 Nov)
	playtime = { day = "", seconds = 0, claimed = 0 }, -- Hadiah playtime: active seconds today, chests opened today (Config/Progression PLAYTIME)
	playtime = { day = "", seconds = 0, claimed = 0 }, -- Hadiah playtime: active seconds today, chests opened today (Config/Progression PLAYTIME)

	book = {
		crops = {}, -- [id] = true
		fish = {}, -- [id] = best size index (1 = S, 2 = M, 3 = L)
		decor = {}, -- [id] = true
		claimed = {}, -- [milestoneId or "cat:<category>"] = true
	},

	titles = {}, -- [titleId] = true

	land = { chunks = {} }, -- bought 32 x 32 blocks of the plot, "ix,iz" keys (Modules/Land); the start land is always owned
	plotSlot = 0, -- last plot number (PlotService tries to give it back)
	sales = { day = "", sold = {} }, -- Pak Darmo's daily crop quota (Config/Npcs QUOTA); Kapasitas Warung tier is in upgrades.warung

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
	guide = { sells = 0, step = { id = "", n = 0 }, done = {}, skipped = {}, fastLeft = -1, hasMet = {} },
	purchaseIdCache = {}, -- last N dev product PurchaseIds (ProfileStore pattern; prevents double-grant)
}

return template
