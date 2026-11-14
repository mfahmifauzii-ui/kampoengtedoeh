--!strict
-- New-player guide (client/Controllers/GuideController): on-screen hints for the first loop (cangkul -> tanam -> siram ->
-- panen -> jual) and an arrow to the buyer (Pak Darmo). It runs until the player has finished TRIES sale trips
-- (data.guide.sells, counted by ShopService each time something is sold), then stops for good.

return {
	TRIES = 3,
	BUYER_NPC = "pak_darmo", -- the arrow points here once there is a crop to sell
}
