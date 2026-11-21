--!strict
-- Skills (Kampoeng_Tedoeh_v7.3 Bab 4.5, LOCKED): 16 skill, max Lv 5 tiap skill.
-- Beli pakai SP (1 SP per level, Bab 4.1/4.3). TIDAK pakai Koin/Bunga/Robux.
-- Biaya Koin 15.000 di Bab 17.4 adalah USULAN (butuh lock owner): tidak di-charge.

export type SkillDef = {
	id: string, -- "mata_kualitas"
	cabang: string, -- "bertani"
	maxLevel: number, -- 5
}

local SKILLS: { SkillDef } = {
	{ id = "tangan_hijau", cabang = "bertani", maxLevel = 5 },
	{ id = "bibit_hemat", cabang = "bertani", maxLevel = 5 },
	{ id = "mata_kualitas", cabang = "bertani", maxLevel = 5 },
	{ id = "panen_raya", cabang = "bertani", maxLevel = 5 },
	{ id = "joran_kuat", cabang = "mancing", maxLevel = 5 },
	{ id = "firasat", cabang = "mancing", maxLevel = 5 },
	{ id = "umpan_hemat", cabang = "mancing", maxLevel = 5 },
	{ id = "ikan_besar", cabang = "mancing", maxLevel = 5 },
	{ id = "tempat_pakan_besar", cabang = "ternak", maxLevel = 5 },
	{ id = "telur_cepat", cabang = "ternak", maxLevel = 5 },
	{ id = "susu_melimpah", cabang = "ternak", maxLevel = 5 },
	{ id = "tukang_cepat", cabang = "tukang", maxLevel = 5 },
	{ id = "kayu_kuat", cabang = "tukang", maxLevel = 5 },
	{ id = "koki_cepat", cabang = "masak", maxLevel = 5 },
	{ id = "rasa_prima", cabang = "masak", maxLevel = 5 },
	{ id = "tetangga_baik", cabang = "sosial", maxLevel = 5 },
}

local byId: { [string]: SkillDef } = {}
for _, def in SKILLS do
	byId[def.id] = def
end

local CABANG_ORDER = { "bertani", "mancing", "ternak", "tukang", "masak", "sosial" }

return {
	SKILLS = SKILLS,
	byId = byId,
	CABANG_ORDER = CABANG_ORDER,
	SP_PER_LEVEL = 1, -- 1 SP per level skill (Bab 4.1: beli pakai SP)
}
