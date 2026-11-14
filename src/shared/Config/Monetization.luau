--!strict
-- Game passes + developer products. IDs are 0 until you create them in the Creator
-- Dashboard (Monetization > Passes / Developer Products) and paste the ids here.
-- id = 0 -> shown as "Belum tersedia" and never prompted.
--
-- Principles (see docs/Monetization_Review.md): cosmetics + convenience only, nothing
-- that blocks core progression, no popups — the store opens only when the player taps it.

export type Pass = { key: string, id: number, priceDraft: number }
export type Product = { key: string, id: number, priceDraft: number, kind: "bunga" | "koin" | "instant_grow", amount: number }

return {
	PASSES = {
		{ key = "backpack", id = 0, priceDraft = 99 }, -- +40 bag slots
		{ key = "offline", id = 0, priceDraft = 149 }, -- 2× pond capacity
		{ key = "decor", id = 0, priceDraft = 149 }, -- +100 decor limit
		{ key = "plots", id = 0, priceDraft = 199 }, -- +4 farm tiles
	} :: { Pass },

	PRODUCTS = {
		{ key = "bunga_s", id = 0, priceDraft = 49, kind = "bunga", amount = 50 },
		{ key = "bunga_m", id = 0, priceDraft = 99, kind = "bunga", amount = 120 },
		{ key = "bunga_l", id = 0, priceDraft = 229, kind = "bunga", amount = 300 },
		{ key = "koin_s", id = 0, priceDraft = 25, kind = "koin", amount = 500 },
		{ key = "koin_m", id = 0, priceDraft = 75, kind = "koin", amount = 2000 },
		{ key = "koin_l", id = 0, priceDraft = 199, kind = "koin", amount = 6000 },
		{ key = "instant_grow", id = 0, priceDraft = 15, kind = "instant_grow", amount = 1 },
	} :: { Product },

	-- Pass effects
	BACKPACK_BONUS_SLOTS = 40,
	OFFLINE_POND_MULT = 2,
	DECOR_BONUS = 100,
	PLOT_BONUS_TILES = 4, -- must match Farm.PASS_EXTRA_TILES

	-- Instant Grow: finish one growing tile. Token use is capped per WIB day,
	-- and you can't buy more than you could use today.
	INSTANT_GROW_DAILY_LIMIT = 3,

	-- Roblox Premium perks (small, never required)
	PREMIUM_ORDER_KOIN_MULT = 1.1,
	PREMIUM_EXTRA_REROLLS = 1,

	PURCHASE_ID_CACHE_SIZE = 100,
}
