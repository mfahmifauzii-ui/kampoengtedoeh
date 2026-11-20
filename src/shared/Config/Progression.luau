--!strict
-- Levels (cap 60, docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 4), Level Cabang, XP sources, daily visit rewards, time zone.
-- Reward tables everywhere use the same shape:
--   { koin = n?, bunga = n?, xp = n?, items = {[itemId] = n}?, decor = {[decorId] = n}?, title = id? }

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
	},

	UTC_OFFSET = 7 * 3600, -- WIB
	RESET_HOUR = 5, -- daily and weekly resets at 05:00 WIB (Bab 3.2, 15.1): Agenda, Login, Bantu, Kerja Bakti, Playtime

	-- Level Cabang (Bab 4.2): Bertani, Mancing, Beternak, Tukang. Lv 0 -> 10. Each step is the XP for that level,
	-- in order (Bab 4.3: 300, 600, 900, 1.200, then 1.500 x 6; total 12.000). Max Lv 10.
	CABANG = {
		MAX_LEVEL = 10,
		XP = { 300, 600, 900, 1200, 1500, 1500, 1500, 1500, 1500, 1500 },
	},
}
