--!strict
-- Nambang + Crafting (docs/01_GDD_Kampoeng_Tedoeh_v8.1.md Bab 8.1 / 8.2, LOCKED).
-- Hutan Nambang (Lv 4): 6 node per-player (instanced, tidak rebutan). 1 node = 4 pukulan;
-- normal +1 bahan, Critical +2 bahan. Node habis -> respawn 4 menit. Rata-rata 1 putaran
-- Hutan (+-5 menit) = 30-45 bahan campuran (6 node x 4 pukulan = 24 base + Critical).
-- Bahan mentah (7) TIDAK dijual di toko mana pun (sellPrice nil, lihat Modules/Items).
-- Olahan di-craft instan + gratis, hanya pakai bahan. Tombol massal x10.
-- XP: 2 per bahan yang didapat (K-08 b, GDD 4.2 / 8.1).
-- Kapak Besi/Baja (Config/Farm TOOLS bonusBahan) menambah bahan saat node habis, per node.

export type NodeDef = {
	id: string, -- "pohon" (Workspace part attribute NodeId)
	itemId: string, -- bahan mentah yang jatuh
	unlockLevel: number, -- Hutan Lv 4, Pohon Aren Lv 15
}

export type RecipeInput = { id: string, count: number }

export type Recipe = {
	id: string, -- "papan"
	itemId: string, -- olahan yang jadi
	inputs: { RecipeInput },
	unlockLevel: number, -- Kaca Lv 25, sisanya tanpa gate (v7.3 tidak memberi angka)
}

local NODES: { NodeDef } = {
	{ id = "pohon", itemId = "kayu", unlockLevel = 4 },
	{ id = "rumpun_bambu", itemId = "bambu", unlockLevel = 4 },
	{ id = "batu_kali", itemId = "batu", unlockLevel = 4 },
	{ id = "tebing_tanah", itemId = "tanah_liat", unlockLevel = 4 },
	{ id = "pinggir_kali", itemId = "pasir", unlockLevel = 4 },
	{ id = "pohon_aren", itemId = "ijuk", unlockLevel = 15 },
}

local RECIPES: { Recipe } = {
	{ id = "papan", itemId = "papan", inputs = { { id = "kayu", count = 2 } }, unlockLevel = 1 },
	{ id = "bata", itemId = "bata", inputs = { { id = "tanah_liat", count = 2 } }, unlockLevel = 1 },
	{ id = "semen", itemId = "semen", inputs = { { id = "pasir", count = 2 }, { id = "batu", count = 1 } }, unlockLevel = 1 },
	{ id = "anyaman", itemId = "anyaman", inputs = { { id = "bambu", count = 3 } }, unlockLevel = 1 },
	{ id = "atap_ijuk", itemId = "atap_ijuk", inputs = { { id = "ijuk", count = 3 } }, unlockLevel = 1 },
	{ id = "genteng", itemId = "genteng", inputs = { { id = "tanah_liat", count = 3 } }, unlockLevel = 1 },
	{ id = "kaca", itemId = "kaca", inputs = { { id = "pasir", count = 3 } }, unlockLevel = 25 },
}

local byNode: { [string]: NodeDef } = {}
for _, node in NODES do
	byNode[node.id] = node
end

local byRecipe: { [string]: Recipe } = {}
for _, recipe in RECIPES do
	byRecipe[recipe.id] = recipe
end

return {
	FOREST_UNLOCK = 4, -- Hutan Nambang terbuka
	HITS_PER_NODE = 4, -- pukulan per node (Bab 8.1)
	XP_PER_BAHAN = 2, -- K-08 (b): XP per bahan yang didapat
	NORMAL_YIELD = 1, -- bahan per pukulan biasa
	CRIT_YIELD = 2, -- bahan per Critical
	RESPAWN_SECONDS = 240, -- 4 menit (Bab 8.1)
	HIT_MIN_INTERVAL = 0.35, -- detik antar pukulan (anti-spam, di bawah ritme normal)
	REACH = 12, -- studs, dicek server (client tunjukkan tombol dalam 10)
	NODES = NODES,
	-- Meja Crafting (Unlock Lv 4). The craft button shows only once it is unlocked, and only near the table: it floats above
	-- the Workspace part/model named CRAFT_TABLE (hand-placed in Studio), within CRAFT_REACH studs.
	CRAFT_UNLOCK = 4,
	CRAFT_TABLE = "Meja Crafting",
	CRAFT_REACH = 10,
	byNode = byNode,
	RECIPES = RECIPES,
	byRecipe = byRecipe,
}
