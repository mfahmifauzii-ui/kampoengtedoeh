--!strict

export type Currency = "koin" | "bunga"

-- Empty tile = {}. Never leave gaps in the tiles array (ProfileStore can't save them).
export type FarmTile = {
	uid: number, -- stable id (the client addresses tiles by it)
	cx: number, -- tile cell on the plot grid (bed min corner, plot-local studs = cell * Land.PITCH)
	cz: number,
	crop: string?,
	fast: boolean?, -- planted with bibit unggul: grows faster on every cycle
	plantedAt: number?,
	readyAt: number?,
	watered: boolean?,
	harvestsLeft: number?,
}

-- x/z = min-corner grid cell on the plot, r = rotation 0..3 (×90°)
export type DecorEntry = {
	uid: number,
	id: string,
	x: number,
	z: number,
	r: number,
}

-- A player-built pond (water terrain). cx/cz = farm-tile cell (8 studs, same grid as FarmTile) of its min corner;
-- it covers Fishing.POND.SIZE / 8 tiles per side.
-- paid = koin spent (refund on removal is Fishing.POND.REFUND_RATE of it; 0 for the free tutorial pond).
export type PondEntry = {
	uid: number,
	cx: number,
	cz: number,
	paid: number,
	lastCollect: number, -- os.time of the last collect (fish accrue from here)
}

-- items[i].item is a crop id or a fish id (any size counts for fish).
export type OrderEntry = {
	uid: number,
	npc: string,
	items: { { item: string, count: number } },
	koin: number,
	xp: number,
	bunga: number?,
	decor: string?,
	done: boolean,
}

export type PlayerData = {
	version: number,
	koin: number,
	bunga: number,
	xp: number,
	level: number,
	sp: number,
	cabang: { [string]: { lv: number, xp: number } },
	skill: { [string]: number },
	stats: {
		firstJoin: number,
		lastLogin: number,
		sessions: number,
	},
	inventory: { [string]: number },
	upgrades: { [string]: number }, -- tier per permanent upgrade: backpack, pond (Modules/Upgrades)
	farm: {
		tiles: { FarmTile },
		nextUid: number,
	},
	fishing: {
		rod: string,
		ownedRods: { [string]: boolean },
	},
	quests: {
		active: { [string]: { step: number, count: number } },
		done: { [string]: boolean },
	},
	pond: {
		list: { PondEntry },
		nextUid: number,
	},
	decor: {
		placed: { DecorEntry },
		stock: { [string]: number },
		nextUid: number,
		blueprints: { [string]: boolean }, -- owned Config/Blueprints ids
	},
	orders: {
		day: string,
		daily: { OrderEntry },
		rerollsUsed: number,
		week: string,
		weekly: OrderEntry | {},
		nextUid: number,
	},
	playtime: { day: string, seconds: number, claimed: number },
	book: {
		crops: { [string]: boolean },
		fish: { [string]: number },
		decor: { [string]: boolean },
		claimed: { [string]: boolean },
	},
	titles: { [string]: boolean },
	land: {
		chunks: { [string]: boolean }, -- bought 32 x 32 blocks ("chunks" in the code) of the plot, "ix,iz" keys (Modules/Land)
	},
	plotSlot: number, -- the plot number this player had last time (0 = none): tried first when they join
	social: {
		likes: number,
		milestones: { [string]: boolean },
		likedDay: string,
		likedToday: { [string]: boolean },
	},
	settings: { music: boolean, ambient: boolean, sfx: boolean, musicVol: number, sfxVol: number, quality: number }, -- vol 0..1, quality 1..3 (Rendah / Sedang / Tinggi)
	passes: { [string]: boolean },
	instantGrow: { tokens: number, day: string, usedToday: number },
	onboarding: { [string]: boolean },
	guide: {
		sells: number, -- finished sale trips so far: the old new-player guide (hints + NPC arrow) runs for Onboarding.TRIES of them
		step: { id: string, n: number }, -- tutorial engine: running tutorial and how many of its steps are done ("" = none)
		done: { [string]: boolean },
		skipped: { [string]: boolean },
		fastLeft: number, -- plantings left on the 20 s tutorial timer (-1 = not decided yet)
		hasMet: { [string]: boolean }, -- [npcId] = true after the first talk with that NPC (Fase 2 sapaan)
		rodGift: boolean, -- Terima Hadiah from Kak Fajar was taken (idempotent: the rod and bait are given once)
		fishingUnlocked: boolean, -- set with rodGift: the fishing tutorial is open
		fishCaught: boolean, -- the first fish of any kind was caught (the t1b "after_catch" step needs it)
		kolamUnlocked: boolean, -- the t1b "after_catch" step is done: pond building opens (Mak Sari teaches it)
		decorUnlocked: boolean, -- the t1b tutorial is finished: decorating (hias) opens
		saleCutscene: boolean, -- the first-sale cutscene was played for this tutorial run (it is played once per run)
	},
	purchaseIdCache: { string },
}

return {}
