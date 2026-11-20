--!strict
-- Game passes + developer products. IDs are 0 until you create them in the Creator
-- Dashboard (Monetization > Passes / Developer Products) and paste the ids here.
-- id = 0 -> shown as "Belum tersedia" and never prompted.
--
-- Principles (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 18 & 29): Bunga buys style, comfort and time.
-- Nothing sold here is Koin, land, pond or kandang slots, or anything that blocks core progression.
-- No popups: the store opens only when the player taps it.

export type Pass = { key: string, id: number, priceDraft: number }
export type Product = { key: string, id: number, priceDraft: number, kind: "bunga" | "instant_grow", amount: number }

return {
	PASSES = {
		{ key = "backpack", id = 0, priceDraft = 99 }, -- +40 bag slots
	} :: { Pass },

	PRODUCTS = {
		{ key = "bunga_s", id = 0, priceDraft = 49, kind = "bunga", amount = 50 },
		{ key = "bunga_m", id = 0, priceDraft = 99, kind = "bunga", amount = 120 },
		{ key = "bunga_l", id = 0, priceDraft = 229, kind = "bunga", amount = 300 },
		{ key = "instant_grow", id = 0, priceDraft = 15, kind = "instant_grow", amount = 1 },
	} :: { Product },

	-- Pass effects
	BACKPACK_BONUS_SLOTS = 40,

	-- Instant Grow: finish one growing tile. Token use is capped per WIB day,
	-- and you can't buy more than you could use today.
	INSTANT_GROW_DAILY_LIMIT = 3,

	-- Roblox Premium gives no Koin multiplier and no other boost (Bab 19, T-32). Premium stays a flag only.

	PURCHASE_ID_CACHE_SIZE = 100,
}
