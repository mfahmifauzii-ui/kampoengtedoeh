--!strict
-- Levels (cap 60, docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 4), Level Cabang, XP sources, playtime chests, time zone.
-- Reward tables everywhere use the same shape:
--   { koin = n?, bunga = n?, xp = n?, items = {[itemId] = n}?, decor = {[decorId] = n}?, title = id? }
-- Bunga is only given by the sources in Bab 4.1 (never by level-up, likes or visits; v6.2 changelog 13-16 & 18).

export type Reward = {
	koin: number?,
	bunga: number?,
	xp: number?,
	items: { [string]: number }?,
	decor: { [string]: number }?,
	title: string?,
}

return {
	MAX_LEVEL = 60, -- Level Cap rilis (Bab 4.2). Naik +20 tiap Update Besar.
	-- XP needed to go from `level` to `level + 1` (Bab 4.3): 200 + 30 x level. Lv 1->2 = 230, Lv 59->60 = 2.170.
	xpToNext = function(level: number): number
		return 200 + 30 * level
	end,

	-- XP per fish caught, by rarity (Fish.luau rarity C/U/R/L). Used by FishService. Bab 6 owns the final numbers (Fase 3).
	FISH_XP = { C = 3, U = 6, R = 15, L = 40 } :: { [string]: number },

	UTC_OFFSET = 7 * 3600, -- WIB
	RESET_HOUR = 5, -- daily and weekly resets at 05:00 WIB (Bab 3.2, 15.1): Agenda, Login, Bantu, Kerja Bakti, Playtime

	-- Level Cabang (Bab 4.2): Bertani, Mancing, Beternak, Tukang. Lv 0 -> 10. Each step is the XP for that level,
	-- in order (Bab 4.3: 300, 600, 900, 1.200, then 1.500 x 6; total 12.000). Max Lv 10.
	CABANG = {
		MAX_LEVEL = 10,
		XP = { 300, 600, 900, 1200, 1500, 1500, 1500, 1500, 1500, 1500 },
	},

	-- Hadiah Waktu Bermain (Bab 15.2): active minutes per WIB day, Koin only (Kayu & Cacing wait for T-23 items).
	-- A tick counts only while the character moved MOVE_STUDS in TICK seconds, so standing AFK earns nothing.
	PLAYTIME = {
		TICK = 10, -- seconds per server check
		MOVE_STUDS = 1,
		CHESTS = {
			{ minutes = 10, reward = { koin = 50 } },
			{ minutes = 30, reward = { koin = 150 } },
			{ minutes = 60, reward = { koin = 300 } },
		} :: { { minutes: number, reward: Reward } },
	},
}
