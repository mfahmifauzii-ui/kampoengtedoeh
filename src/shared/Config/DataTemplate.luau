--!strict
-- Default save for a NEW player. ProfileStore:Reconcile() adds missing keys to old saves,
-- so new fields can simply be added here. Renames/restructures need a migration
-- (ServerScriptService.Server.Data.Migrations) + bump `version`.

local Economy = require(script.Parent.Economy)
local Types = require(script.Parent.Parent.Types)

local template: Types.PlayerData = {
	version = 7,

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
	backpackTier = 0, -- index into Inventory.SLOTS (tier + 1)

	farm = {
		tiles = {}, -- tilled soil tiles { uid, cx, cz, crop?... }; a new player tills their own (Garap)
		expansions = 0, -- raises the tile cap (Farm.cap)
		nextUid = 1,
	},

	fishing = {
		rod = "bambu", -- equipped rod id
		ownedRods = { bambu = true },
	},

	pond = {
		tier = 0, -- index into Fishing.POND.CAPS (tier + 1); applies to every pond
		list = {}, -- { PondEntry } ponds the player built (Lv 6 quest gives the first one free)
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
	},

	visits = { count = 0, lastDay = "" }, -- Kunjungan Harian (cumulative)

	book = {
		crops = {}, -- [id] = true
		fish = {}, -- [id] = best size index (1 = S, 2 = M, 3 = L)
		decor = {}, -- [id] = true
		claimed = {}, -- [milestoneId or "cat:<category>"] = true
	},

	titles = {}, -- [titleId] = true

	npc = {}, -- [npcId] = NpcRecord (created on first contact; see AffinityService)
	skills = { tawar = { level = 1, xp = 0 } }, -- [skillId] = { level, xp } (Config/Skills)

	social = {
		likes = 0, -- likes received on your plot (all time)
		milestones = {}, -- [likesThreshold as string] = true
		likedDay = "", -- WIB day of likedToday
		likedToday = {}, -- [ownerUserId as string] = true (plots you liked today)
	},

	settings = { music = true, ambient = true, sfx = true },

	passes = {}, -- [passKey] = true; cache of confirmed game pass ownership (fallback if API is down)
	instantGrow = { tokens = 0, day = "", usedToday = 0 },
	onboarding = {}, -- [stepNumber] = true (analytics funnel, logged once)
	purchaseIdCache = {}, -- last N dev product PurchaseIds (ProfileStore pattern; prevents double-grant)
}

return template
