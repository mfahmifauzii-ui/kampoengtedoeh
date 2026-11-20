--!strict
-- Levels, XP sources, daily visit rewards, time zone.
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
	MAX_LEVEL = 30,
	-- XP needed to go from `level` to `level + 1`. Phase 10 model (tools/balance_sim.py, 35 min/day):
	-- Lv5 first session, Lv10 day 3, Lv18 (all content) ~day 9, Lv20 ~day 11, Lv30 ~day 31. Total ≈ 81k XP.
	xpToNext = function(level: number): number
		return math.floor(20 * level ^ 1.5 + 10 * math.max(0, level - 8) ^ 2.1)
	end,
	-- No Bunga from level-up or level milestones (v6.2 Bab 4.1: Bunga comes only from the sources listed there).

	FISH_XP = { C = 3, U = 6, R = 15, L = 40 } :: { [string]: number },

	-- Kunjungan Harian: cumulative (never resets). Step = ((count - 1) % 7) + 1.
	VISIT_REWARDS = {
		{ koin = 50 },
		{ koin = 75 },
		{ koin = 100 },
		{ items = { pelet = 10 } },
		{ koin = 150 },
		{ koin = 200 },
		{ bunga = 3 },
	} :: { Reward },

	-- Hadiah playtime (R3 17.4): three peti a day, Koin only, opened in order (Bab 15.2 v6.2). Kayu/Cacing items wait for Fase 4/5 (TODO T-23). A tick counts only while the character moved
	-- at least MOVE_STUDS in TICK seconds, so standing AFK earns nothing. Minutes and rewards are a first draft.
	PLAYTIME = {
		TICK = 10, -- seconds per server check
		MOVE_STUDS = 1,
		CHESTS = {
			{ minutes = 10, reward = { koin = 50 } },
			{ minutes = 30, reward = { koin = 150 } },
			{ minutes = 60, reward = { koin = 300 } },
		} :: { { minutes: number, reward: Reward } },
	},

	UTC_OFFSET = 7 * 3600, -- days reset at 00:00 WIB
}
