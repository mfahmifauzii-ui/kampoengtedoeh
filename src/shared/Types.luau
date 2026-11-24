--!strict

export type Currency = "koin" | "bunga"

-- Empty tile = {}. Never leave gaps in the tiles array (ProfileStore can't save them).
export type FarmTile = {
	uid: number, -- stable id (the client addresses tiles by it)
	cx: number, -- tile cell on the plot grid (bed min corner, plot-local studs = cell * Land.PITCH)
	cz: number,
	crop: string?,
	plantedAt: number?,
	readyAt: number?,
	watered: boolean?,
	fastHold: boolean?, -- tutorial bed: the fast timer is held until it is watered (K-71)
	harvestsLeft: number?,
	paid: number?, -- koin spent on this bed when it was bought (0 / nil = a free bed). "Hapus Petak" refunds TILE_REFUND_RATE of it.
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
-- tier = breed tier Tanah/Semen/Keramik (Bab 7.2); kakek = Kolam Kakek (breeding 10% lebih cepat).
export type PondEntry = {
	uid: number,
	cx: number,
	cz: number,
	paid: number,
	stock: { string }, -- B-3: ikan yang disetor pemain, item id "fishId@size" (urutan = urutan simpan)
	tier: string,
	kakek: boolean,
	breed: PondBreed?,
}

-- Per-player mining node: sisa pukulan + kapan respawn (os.time, 0 = siap). Node habis = hits 0.
export type MiningNodeState = {
	hits: number,
	readyAt: number,
}

-- Satu ekor ternak: feed = jatah pakan (0..FEED_MAX), prod = produk menumpuk (0..PROD_MAX),
-- last = os.time siklus produksi terakhir yang dihitung.
export type RanchAnimal = {
	feed: number,
	prod: number,
	last: number,
}

-- Satu kandang (satu jenis hewan): tier 1/2, posisi sel grid, isi hewan.
export type RanchKandang = {
	tier: number,
	cx: number,
	cz: number,
	animals: { RanchAnimal },
}

-- Breeding kolam yang jalan: 1 anak per kolam per siklus.
export type PondBreed = {
	fish: string, -- id spesies indukan (non-Legenda)
	startedAt: number,
	endsAt: number, -- os.time siap diambil (instant Bunga memajukan ke now)
}

-- Satu slot Dapur: resep + kapan mulai/selesai + kualitas hasil (dihitung saat mulai masak).
-- base = harga base resep 1.6x (round10(1.6 x nilai bahan)); 0 untuk resep fixed & Pakan Jagung.
export type DapurSlot = {
	recipe: string,
	startedAt: number,
	endsAt: number,
	quality: string, -- "biasa" | "bagus" | "prima"
	base: number,
}

-- Pajang Warung: 1 jenis olahan + jumlahnya.
export type WarungItem = {
	id: string, -- "{kualitas}_{resep}" (atau "{kualitas}_{resep}_{base}" utk 1.6x)
	count: number,
}

-- Buff aktif: 1 buff (makan olahan baru = ganti). Timer real-time.
export type ActiveBuff = {
	id: string?, -- "tani" | "pancing" | "tukang" | "tebang"
	endsAt: number,
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
	-- CABANG DIHAPUS total (P2-4, Bab 4.5). Jangan tambah kembali.
	skill: { [string]: number },
	stats: {
		firstJoin: number,
		lastLogin: number,
		sessions: number,
	},
	inventory: { [string]: number },
	upgrades: { [string]: number }, -- tier per permanent upgrade: pond (Modules/Upgrades)
	farm: {
		tiles: { FarmTile },
		nextUid: number,
	},
	bubu: { list: { { uid: number, kind: string, spot: string, placedAt: number, pos: { number }? } }, nextUid: number },
	fishing: {
		rod: string,
		equippedBait: string,
		ownedRods: { [string]: boolean },
		pity: { [string]: number }, -- counter per spesies Legenda (Bab 6.5, P2-4)
	},
	quests: {
		active: { [string]: { step: number, count: number } },
		done: { [string]: boolean },
		ready: { [string]: boolean }, -- K-93: all tasks done, waits for the turn-in at the giver (siap diserahkan)
		tracked: { string }, -- Quest Log Track: quest ids, "h:<kind>", "w:<kind>"; at most 3
		harian: { day: string, slots: { { kind: string, progress: number, claimed: boolean } } },
		mingguan: { week: string, slots: { { kind: string, progress: number, claimed: boolean } } },
		agenda: { day: string, tasks: { { id: string, progress: number, claimed: boolean } } },
	},
	surat: { lastDay: string, logins: number, progress: number, done: { [number]: boolean } },
	bundel: { [string]: any }, -- Bundel Kakek (Bab 14.6): [id] = { given, done } + sumur_day
	features: { [string]: string }, -- Q-2 feature gate: "introduced" | "open" per fitur quest (FeatureGate)
	pond: {
		list: { PondEntry },
		nextUid: number,
		kakekUnlocked: boolean, -- Kolam Kakek pulih (MQ4/Bundel P2-7). PondBuild butuh ini.
		freeBuilds: number, -- token kolam gratis (Bundel Empang, Bab 14.6)
	},
	ranch: {
		kandang: { [string]: RanchKandang }, -- [hewanId], satu kandang per jenis
		moodUntil: number, -- os.time akhir Mood Hujan (0 = tidak aktif)
	},
	dapur: {
		tier: number, -- 0 = belum bangun, 1/2/3
		slots: { [number]: DapurSlot | false }, -- array 1..3, false = kosong
		spot: { cx: number, cz: number }?, -- sel bangunan (auto-place)
	},
	warung: {
		item: WarungItem?, -- pajangan (1 jenis olahan + jumlah)
		spot: { cx: number, cz: number }?, -- sel bangunan (auto-place)
		nextVisit: number, -- os.time kunjungan NPC berikutnya
		soldLogin: number, -- penjualan offline login ini (max 5)
	},
	gerobak: {
		restock: number, -- restockId terakhir dilihat (floor(os.time()/900))
		bought: { [number]: number }, -- [slot] = unit terbeli restock ini (max 3/slot)
	},
	pasar: {
		night: number, -- id malam game terakhir (counter server; reset tiap restart)
		item: string, -- itemId yang dibeli pedagang malam ini
		trader: string, -- id pedagang malam ini
		sold: number, -- terjual malam ini (max 10)
		throws: number, -- lemparan gelang dipakai malam ini (max 3)
	},
	tamu: {
		event: string, -- id event kalender saat order dibuat ("" = tidak ada)
		items: { [string]: number }, -- [itemId] = butuh; kosong = selesai/belum ada
		done: boolean,
	},
	kb: {
		day: string, -- WIB day: reset max 4/hari
		count: number, -- Kerja Bakti berhadiah hari ini
	},
	discountUntil: number, -- os.time akhir Diskon Warga (0 = tidak aktif)
	buff: ActiveBuff,
	mining: {
		nodes: { [string]: MiningNodeState },
	},
	decor: {
		placed: { DecorEntry },
		stock: { [string]: number },
		nextUid: number,
	},
	orders: {
		day: string,
		daily: { OrderEntry },
		rerollsUsed: number,
		rerolled: { [number]: boolean }, -- order harian yang sudah di-reroll hari ini
		week: string,
		weekly: OrderEntry | {},
		nextUid: number,
	},
	playtime: { day: string, seconds: number, claimed: number },
	rewards: {
		login: { week: string, days: number, lastDay: string, claimed: { [string]: boolean } },
		peti: number,
		titlePeti: { [string]: boolean },
		season: { id: string, premium: boolean, f2p: { [string]: boolean }, premiumClaimed: { [string]: boolean } },
	},
	book: {
		ladang: { [string]: boolean }, -- "{crop}:{biasa|bagus|prima}"
		sungai: { [string]: boolean }, -- "{fish}@{S|M|L|Jumbo}"
		kandang: { [string]: boolean },
		rumah: { [string]: boolean },
		dapur: { [string]: boolean }, -- "{resep}:{biasa|bagus|prima}"
		varian: { [string]: boolean },
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
		likedEver: { [string]: boolean }, -- 1x per lahan selamanya (P2-5)
		weekly: { week: string, count: number }, -- likes diterima minggu ini (Galeri)
		likesGiven: { day: string, count: number }, -- +20 Koin max 10/hari
		helpGiven: { day: string, plots: { [string]: boolean } }, -- max 5 lahan/hari
		helpRecv: { day: string, siram: boolean, panen: boolean },
		gifts: { day: string, sent: number }, -- kirim hadiah max 3/hari
	},
	settings: { music: boolean, ambient: boolean, sfx: boolean, musicVol: number, sfxVol: number, quality: number }, -- vol 0..1, quality 1..3 (Rendah / Sedang / Tinggi)
	passes: { [string]: boolean },
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
		kolamUnlocked: boolean, -- LEGACY (v7.4 Bab 16.5): no longer set or read; the pond gate is pond.kakekUnlocked. Kept for old saves.
		decorUnlocked: boolean, -- the t1b tutorial is finished: decorating (hias) opens
		saleCutscene: boolean, -- the first-sale cutscene was played for this tutorial run (it is played once per run)
	},
	purchaseIdCache: { string },
}

return {}
