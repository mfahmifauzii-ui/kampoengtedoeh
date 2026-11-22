--!strict
-- Bundel Kakek: Memulihkan Peninggalan Kakek (Bab 14.6, LOCKED, P2-7-fix).
-- Kerangka kosong muncul di level bukanya; setoran bertahap (boleh dicicil, tidak hilang);
-- selesai = hadiah + flag. Ukuran (4x4/6x6/10x10) = info katalog (visual Studio, bukan gate).
-- need: id barang persis, atau "olahan:any" (olahan apa saja), "prima:any" (hasil Prima apa saja),
-- "early:any" (3 ikan rarity C ukuran apa saja), "jumbo:any" (1 ikan Jumbo apa saja).

export type Need = { need: string, count: number }
export type Bundel = {
	id: string,
	unlockLevel: number,
	size: string, -- "4x4" / "6x6" / "10x10" (info katalog)
	needs: { Need },
	rewardKoin: number,
	rewardBunga: number?,
	rewardDecor: string?,
	rewardFreePond: boolean?, -- Empang: "spot mancing pribadi" = 1 token kolam gratis
	rewardKakek: boolean?, -- Kolam Kakek: pulihkan Kolam Kakek
}

local list: { Bundel } = {
	{
		id = "sumur_tua",
		unlockLevel = 8,
		size = "4x4",
		needs = {
			{ need = "kayu", count = 10 },
			{ need = "batu", count = 5 },
			{ need = "olahan:any", count = 2 },
		},
		rewardKoin = 0,
		rewardDecor = "sumur_tua", -- siram 1 petak otomatis per hari (hook BundelService)
	},
	{
		id = "saung_kakek",
		unlockLevel = 20,
		size = "6x6",
		needs = {
			{ need = "anyaman", count = 15 },
			{ need = "atap_ijuk", count = 10 },
			{ need = "olahan:any", count = 3 },
		},
		rewardKoin = 0,
		rewardDecor = "saung_kakek", -- duduk 5 dtk -> buff +5% XP 10 mnt BELUM ADA sistem duduk (parsial, P2-9)
	},
	{
		id = "lumbung",
		unlockLevel = 15,
		size = "6x6",
		needs = {
			{ need = "papan", count = 20 },
			{ need = "bata", count = 10 },
			{ need = "prima:any", count = 1 },
		},
		rewardKoin = 0,
		rewardDecor = "lumbung", -- penyimpanan visual
	},
	{
		id = "empang",
		unlockLevel = 30,
		size = "10x10",
		needs = {
			{ need = "papan", count = 30 },
			{ need = "semen", count = 10 },
			{ need = "early:any", count = 10 },
			{ need = "jumbo:any", count = 1 },
		},
		rewardKoin = 0,
		rewardFreePond = true,
	},
	-- Kolam Kakek dipindah ke Quest M3 "Kolam Kakek" (Quest v0.3 Bab 4.1; Config/Quests m3_kolam_kakek).
}

local byId: { [string]: Bundel } = {}
for _, bundel in list do
	byId[bundel.id] = bundel
end

return {
	list = list,
	byId = byId,
}
