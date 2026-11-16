--!strict
-- ForgeGUI kit (assets/gui/*.png) as Roblox image ids. Upload the PNGs (Studio > Asset Manager > Bulk Import, or
-- Creator Hub > Assets > Image), copy each id here as "rbxassetid://<id>". An empty string = not uploaded yet: the UI
-- then draws the same look with flat parts (see client/UiKit), so nothing breaks while ids are missing.
--
-- Files and what they are:
--   panel.png  1024 x 569  bamboo frame + rattan corners + parchment center  (9-slice: PANEL.slice)
--   button.png 1024 x 307  golden bamboo plank button with rattan ends       (9-slice: BUTTON.slice; tinted in code)
--   icon_<name>.png 256 x 256 transparent icons

export type Skin = { image: string, slice: Rect, sliceScale: number }
export type Picture = { image: string, aspect: number } -- a plain picture (not 9-sliced), aspect = width / height

return {
	-- Coachmark hole corner (assets/gui/coach_corner.png, 256 x 256: a black corner with a quarter-circle cut-out). Empty = the
	-- hole stays square, as before.
	COACH_CORNER = { image = "" },

	PANEL = {
		image = "rbxassetid://96943091231295",
		slice = Rect.new(145, 145, 879, 424), -- corners/border of ready/panel_v1.png (1024 x 569, trimmed)
		sliceScale = 0.22, -- on screen the 150px corners become about 33px
	} :: Skin,

	BUTTON = {
		image = "rbxassetid://131104053141394",
		slice = Rect.new(70, 40, 698, 190), -- ready/button_v1.png (768 x 230, trimmed)
		sliceScale = 0.22,
	} :: Skin,

	-- v2 pieces (assets/gui/ready/*.png). An empty id would make UiKit draw the flat look instead.
	RIBBON = { -- green title ribbon (768 x 144), hung over the panel's top edge; the tails are the slice's left/right
		image = "rbxassetid://137179097497084",
		slice = Rect.new(140, 40, 628, 104),
		sliceScale = 0.42,
	} :: Skin,

	CARD = { -- list-row card (1024 x 245): thin bamboo border, parchment center
		image = "rbxassetid://126654733622214",
		slice = Rect.new(80, 60, 944, 185),
		sliceScale = 0.17,
	} :: Skin,

	CHIP = { -- HUD capsule (768 x 200)
		image = "rbxassetid://74349249580321",
		slice = Rect.new(110, 60, 658, 140),
		sliceScale = 0.22,
	} :: Skin,

	-- Loading screen / Play screen (assets/gui/ready, uploaded 16 Nov 2026).
	LOGO = { -- "Kampoeng Tedoeh" bamboo letters on the brown plank, leaves (logo v2, transparent, 1024 x 541)
		image = "rbxassetid://74663602008475",
		aspect = 1024 / 541,
	} :: Picture,
	-- Loading screen background: the town from above (assets/gui/ready/loading_bg_map.jpg, 2000 x 1125). Empty until it is
	-- uploaded (Studio > Asset Manager > Bulk Import, then copy the id here). While empty, the loading screen shows the blurred
	-- orbit camera as before. It is removed when the Play screen appears.
	LOADING_BG = {
		image = "rbxassetid://130043072685288", -- uploaded 16 Nov via Open Cloud (moderation: Reviewing at upload time)
		aspect = 2000 / 1125,
	} :: Picture,
	LOADING_BAR = { -- empty bamboo frame of the loading bar (1024 x 226, transparent hollow). The green fill sits behind it:
		-- the hollow is x 3.3 % .. 96.8 %, y 13.7 % .. 86.3 % of the picture.
		image = "rbxassetid://137316042779728",
		aspect = 1024 / 226,
	} :: Picture,

	PLATE = { image = "rbxassetid://86005759010163", slice = Rect.new(0, 0, 0, 0), sliceScale = 1 } :: Skin, -- round menu plate (256), drawn Fit
	CLOSE = { image = "rbxassetid://107235699931445", slice = Rect.new(0, 0, 0, 0), sliceScale = 1 } :: Skin, -- round red close badge (256), drawn Fit

	-- Item pictures for the shop rows (UiKit.thumb): transparent PNGs of the crop / fish / rod models, keyed by item id
	-- ("kangkung", "seed_kangkung", "nila@S", "bambu"...) or by crop id. Empty until the models exist: the row then shows the
	-- dimmed placeholder icon instead. Fill an id here and every row of that item swaps its picture, nothing else to touch.
	THUMBS = {} :: { [string]: string },

	ICONS = {
		koin = "rbxassetid://101824585231368", -- gold coin (Koin)
		bunga = "rbxassetid://90836865320846", -- frangipani (Bunga)
		bintang = "rbxassetid://134712616101726", -- star (level)
		hati = "rbxassetid://79367834392412", -- heart (likes)
		tas = "rbxassetid://80416344488435", -- rattan backpack (Tas)
		toko = "rbxassetid://103505311440410", -- market stall (Toko / store)
		pesanan = "rbxassetid://75505775146460", -- scroll with ribbon (Pesanan)
		koleksi = "rbxassetid://89497146008393", -- open book (Koleksi)
		hias = "rbxassetid://72035103405556", -- bench + plant (Hias)
		garap = "rbxassetid://91497454790525", -- hoe + shovel (Garap)
		warga = "rbxassetid://78674819082714", -- two villagers (Warga / social)
		atur = "rbxassetid://78453068752330", -- wooden gear (Atur / settings)
		ikan = "rbxassetid://114859572668416", -- fish
		pancing = "rbxassetid://133616022513657", -- fishing rod
		bibit = "rbxassetid://85277378514415", -- seed packet
		kolam = "rbxassetid://123008103858779", -- pond with a drop
		siram = "rbxassetid://128270474264694", -- watering can (ForgeGUI, 15 Nov 2026): the "Siram" pill over a dry bed
		panen = "rbxassetid://72510453002470", -- harvest basket (ForgeGUI, 15 Nov 2026): the "Panen!" pill over a ripe bed
	} :: { [string]: string },
}
