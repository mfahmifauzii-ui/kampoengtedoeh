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
	LEVEL_UP_REWARD = { bunga = 2 } :: Reward,
	-- Extra one-time rewards on levels with no content unlock (late game goals).
	LEVEL_MILESTONES = {
		[20] = { bunga = 10, title = "petani_rajin" },
		[25] = { bunga = 15 },
		[30] = { bunga = 25, title = "sesepuh_kampung" },
	} :: { [number]: Reward },

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

	UTC_OFFSET = 7 * 3600, -- days reset at 00:00 WIB
}
