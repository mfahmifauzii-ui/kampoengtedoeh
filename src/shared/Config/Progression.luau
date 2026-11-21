--!strict
-- Levels (cap 60, docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 4), XP sources, playtime chests, time zone.
-- CABANG DIHAPUS total (P2-4, Bab 4.5): diganti 16 skill. Jangan tambah kembali.
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

	-- XP per tangkapan = per ikan (Fish.xp, Bab 6.4 v7.3).

	UTC_OFFSET = 7 * 3600, -- WIB
	RESET_HOUR = 5, -- daily and weekly resets at 05:00 WIB (Bab 3.2, 15.1): Agenda, Login, Bantu, Kerja Bakti, Playtime

	-- Hadiah Waktu Bermain (Bab 15.2 v7.3, LOCKED): 5 peti, active minutes per WIB day, Koin only.
	-- A tick counts only while the character moved MOVE_STUDS in TICK seconds, so standing AFK earns nothing.
	PLAYTIME = {
		TICK = 10, -- seconds per server check
		MOVE_STUDS = 1,
		CHESTS = {
			{ minutes = 10, reward = { koin = 50 } },
			{ minutes = 20, reward = { koin = 100 } },
			{ minutes = 30, reward = { koin = 150 } },
			{ minutes = 45, reward = { koin = 200 } },
			{ minutes = 60, reward = { koin = 300 } },
		} :: { { minutes: number, reward: Reward } },
	},
}
