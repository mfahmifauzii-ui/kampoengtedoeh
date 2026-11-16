--!strict
-- Villager orders. Requests are generated from what the player has unlocked;
-- fish with time/weather conditions are never required (no waiting on the clock).

return {
	NPCS = { "pak_rt", "bu_sari", "mbah_karto", "mas_yudi", "dik_rara" },

	DAILY_COUNT = 3,
	FREE_REROLLS = 1, -- per day
	REROLL_BUNGA = 2, -- after the free ones

	-- Koin worth requested per item type, by level. Count = round(target / sellPrice).
	valueTarget = function(level: number): number
		return 40 + level * 15
	end,
	MAX_CROP_COUNT = 8, -- Stage 3: daily orders ask 5-8 items max
	MAX_FISH_COUNT = 4,

	REWARD_MULT = 1.5, -- reward Koin = request value × this
	XP_PER_KOIN = 0.25,

	WEEKLY_TYPES = 4,
	WEEKLY_COUNT_MULT = 3,
	WEEKLY_REWARD_MULT = 3,
	WEEKLY_XP_MULT = 0.5, -- weekly XP = Koin × XP_PER_KOIN × this (avoids multi-level jumps early)
	WEEKLY_BUNGA = 5,
	WEEKLY_DECOR_POOL = { "pohon_pisang", "rumpun_bambu", "bangku_kayu", "bunga_kertas" },
}
