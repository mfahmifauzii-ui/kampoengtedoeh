--!strict
-- Game passes + developer products. IDs are 0 until you create them in the Creator
-- Dashboard (Monetization > Passes / Developer Products) and paste the ids here.
-- id = 0 -> shown as "Belum tersedia" and never prompted.
--
-- Principles (docs/01_GDD_Kampoeng_Tedoeh_v8.4.md Bab 18 & 29): Bunga buys style, comfort and time.
-- Nothing sold here is Koin, land, pond or kandang slots, or anything that blocks core progression.
-- Tidak ada Backpack Pass (Bab 29): tas tanpa cap slot. Tidak ada Instant Panen (Bab 29).
-- No popups: the store opens only when the player taps it.

export type Pass = { key: string, id: number, priceDraft: number }
export type Product = { key: string, id: number, priceDraft: number, kind: "bunga", amount: number }

return {
	PASSES = {} :: { Pass },

	PRODUCTS = {
		{ key = "bunga_s", id = 0, priceDraft = 49, kind = "bunga", amount = 50 },
		{ key = "bunga_m", id = 0, priceDraft = 99, kind = "bunga", amount = 120 },
		{ key = "bunga_l", id = 0, priceDraft = 229, kind = "bunga", amount = 300 },
		{ key = "bunga_xl", id = 0, priceDraft = 459, kind = "bunga", amount = 700 }, -- K-44: pack 700 Bunga (GDD 18.4); id 0 = Belum tersedia
	} :: { Product },

	-- Instant Kolam (Bab 18.5): instant kolam pakai Bunga, 1 Bunga per 10 menit sisa, max 30 Bunga.
	INSTANT_KOLAM_BUNGA_PER_600S = 1,
	INSTANT_KOLAM_MAX_BUNGA = 30,

	-- Roblox Premium gives no Koin multiplier and no other boost (Bab 19, T-32). Premium stays a flag only.

	PURCHASE_ID_CACHE_SIZE = 100,
}
