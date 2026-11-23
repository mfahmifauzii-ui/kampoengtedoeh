--!strict
-- Skill Tree (docs/01_GDD_Kampoeng_Tedoeh_v8.2.md Bab 4.5, the single source of truth). 16 skill, 6 cabang, max Lv 5 each.
--   Beli: 1 SP + Koin naik per level, 1.000 x level berikutnya (K-12, GDD 4.5.1). Tidak ada reset. Tidak pakai Bunga / Robux.
--   Prasyarat (Bab 2), semua opsional kecuali yang tertulis:
--     level   = Player Lv minimum
--     all     = daftar { id, lv }: SEMUA harus terpenuhi (skill Lv minimum)
--     any     = daftar { id, lv }: SALAH SATU harus terpenuhi (OR, Capstone)
--     total   = jumlah level semua skill minimum (Tetangga Baik, "N SP di mana pun")
--   Breakpoint (Bab 1.1): efek baru mulai di Lv `breakpoint`. Di bawahnya skill tetap dibeli (biaya dan prasyarat dihitung
--   per Lv) tetapi tidak punya efek. Skill lain memberi efek sejak Lv 1.
-- Logika prasyarat ada di sini (Skills.missing), dipakai server (SkillService) dan klien (SkillController): satu sumber.

export type Req = { id: string, lv: number }

export type Prereq = {
	level: number?,
	all: { Req }?,
	any: { Req }?,
	total: number?,
}

export type SkillDef = {
	id: string, -- "mata_kualitas"
	cabang: string, -- "bertani"
	maxLevel: number, -- 5
	prereq: Prereq,
	breakpoint: number?, -- efek mulai di Lv ini (Bab 1.1); nil = efek sejak Lv 1
}

-- Why a skill cannot be bought yet (for the UI text, Lampiran in Skill Tree Bab 3).
export type Missing =
	{ kind: "level", level: number }
	| { kind: "skill", id: string, lv: number }
	| { kind: "any", a: Req, b: Req }
	| { kind: "total", n: number }

local SKILLS: { SkillDef } = {
	-- Bertani (root Lv 2)
	{ id = "tangan_hijau", cabang = "bertani", maxLevel = 5, prereq = { level = 2 } },
	{ id = "bibit_hemat", cabang = "bertani", maxLevel = 5, prereq = { level = 4, all = { { id = "tangan_hijau", lv = 2 } } } },
	{ id = "mata_kualitas", cabang = "bertani", maxLevel = 5, prereq = { level = 6, all = { { id = "tangan_hijau", lv = 2 } } } },
	{ id = "panen_raya", cabang = "bertani", maxLevel = 5, prereq = { level = 10, any = { { id = "bibit_hemat", lv = 3 }, { id = "mata_kualitas", lv = 3 } } } },
	-- Mancing (root Lv 2)
	{ id = "joran_kuat", cabang = "mancing", maxLevel = 5, prereq = { level = 2 } },
	{ id = "firasat", cabang = "mancing", maxLevel = 5, prereq = { level = 6, all = { { id = "joran_kuat", lv = 2 } } } },
	{ id = "umpan_hemat", cabang = "mancing", maxLevel = 5, prereq = { level = 4, all = { { id = "joran_kuat", lv = 2 } } } },
	{ id = "ikan_besar", cabang = "mancing", maxLevel = 5, prereq = { level = 10, any = { { id = "umpan_hemat", lv = 3 }, { id = "firasat", lv = 3 } } } },
	-- Ternak (root Lv 5)
	{ id = "tempat_pakan_besar", cabang = "ternak", maxLevel = 5, prereq = { level = 5 }, breakpoint = 3 },
	{ id = "telur_cepat", cabang = "ternak", maxLevel = 5, prereq = { level = 8, all = { { id = "tempat_pakan_besar", lv = 2 } } } },
	{ id = "susu_melimpah", cabang = "ternak", maxLevel = 5, prereq = { level = 12, all = { { id = "telur_cepat", lv = 3 } } } },
	-- Tukang (root Lv 4)
	{ id = "kayu_kuat", cabang = "tukang", maxLevel = 5, prereq = { level = 4 } },
	{ id = "tukang_cepat", cabang = "tukang", maxLevel = 5, prereq = { level = 8, all = { { id = "kayu_kuat", lv = 3 } } }, breakpoint = 3 },
	-- Masak (root Lv 6)
	{ id = "koki_cepat", cabang = "masak", maxLevel = 5, prereq = { level = 6 } },
	{ id = "rasa_prima", cabang = "masak", maxLevel = 5, prereq = { level = 10, all = { { id = "koki_cepat", lv = 3 } } } },
	-- Sosial (tunggal, lintas cabang)
	{ id = "tetangga_baik", cabang = "sosial", maxLevel = 5, prereq = { level = 10, total = 5 }, breakpoint = 3 },
}

local byId: { [string]: SkillDef } = {}
for _, def in SKILLS do
	byId[def.id] = def
end

local CABANG_ORDER = { "bertani", "mancing", "ternak", "tukang", "masak", "sosial" }

-- Biaya (Skill Tree Bab 1): per level.
local SP_PER_LEVEL = 1
-- K-12 (a): biaya Koin naik per level: Lv 1 = 1.000 ... Lv 5 = 5.000 (total per skill 15.000, semua 240.000).
local function koinForLevel(nextLevel: number): number
	return 1000 * nextLevel
end

-- The first unmet requirement, or nil when the skill can be bought (Player Lv and prerequisites only; SP and Koin and max
-- are checked by SkillService). `levels` = { [skillId] = level }, `playerLevel` = Player Lv, `totalLevels` = sum of levels.
local function missing(def: SkillDef, levels: { [string]: number }, playerLevel: number): Missing?
	local p = def.prereq
	if p.level and playerLevel < p.level then
		return { kind = "level", level = p.level }
	end
	for _, req in p.all or {} do
		if (levels[req.id] or 0) < req.lv then
			return { kind = "skill", id = req.id, lv = req.lv }
		end
	end
	if p.any then
		local met = false
		for _, req in p.any do
			if (levels[req.id] or 0) >= req.lv then
				met = true
			end
		end
		if not met then
			return { kind = "any", a = p.any[1], b = p.any[2] }
		end
	end
	if p.total then
		local sum = 0
		for _, lv in levels do
			sum += lv
		end
		if sum < p.total then
			return { kind = "total", n = p.total }
		end
	end
	return nil
end

-- Level that counts for the EFFECT (Bab 1.1): 0 below the breakpoint, otherwise the real level.
local function effectLevel(def: SkillDef, lv: number): number
	if def.breakpoint and lv < def.breakpoint then
		return 0
	end
	return lv
end

-- Efek Tetangga Baik (Bab 2.6): +1 lahan Bantu/hari di Lv 3, +2 di Lv 5. Dipakai server (SocialService) dan klien (UI).
local function tetanggaBonus(lv: number): number
	if lv >= 5 then
		return 2
	elseif lv >= 3 then
		return 1
	end
	return 0
end

-- Efek Tukang Cepat (Bab 2.4): +1 bahan per node di Lv 3, +2 di Lv 5.
local function tukangBonus(lv: number): number
	if lv >= 5 then
		return 2
	elseif lv >= 3 then
		return 1
	end
	return 0
end

-- Batas bonus bahan per node (Skill Tree Bab 6 keputusan 1): kapak + Tukang Cepat, paling banyak +4.
local NODE_BONUS_MAX = 4

return {
	SKILLS = SKILLS,
	byId = byId,
	CABANG_ORDER = CABANG_ORDER,
	SP_PER_LEVEL = SP_PER_LEVEL,
	koinForLevel = koinForLevel,
	missing = missing,
	effectLevel = effectLevel,
	tetanggaBonus = tetanggaBonus,
	tukangBonus = tukangBonus,
	NODE_BONUS_MAX = NODE_BONUS_MAX,
}
