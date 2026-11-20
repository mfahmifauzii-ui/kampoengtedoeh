--!strict
-- Objek awal lahan, "Lahan Kakek yang Gak Keurus" (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 3.4).
-- Posisi tetap: satu template untuk semua pemain (seed tetap), dibuat di sini saat modul dimuat.
-- Setiap objek bersih sekali: bitnya mati di PlayerData (land.lahanAwal untuk lahan awal, land.chunkLahan untuk chunk yang dibeli).
-- Koordinat plot-local (Config/Plots): pusat kotak cadangan = (0, 0), +Z = ke jalan.
-- Bangunan Kakek yang rusak (5) tidak ada di sini: dicatat di Bundel (Bab 14.5), bukan di bitmask.

local Farm = require(script.Parent.Farm)
local Plots = require(script.Parent.Plots)

export type Object = { kind: string, taps: number, x: number, z: number }

local SEED = 62006

-- Lahan awal 128 x 128 (Config/Plots START_SIZE, x -64..64, z -32..96). The clean 24 x 24 area and the path to the gate stay bare.
local START = { x0 = -64, x1 = 64, z0 = -32, z1 = 96 }
local CLEAN = { x0 = -12, x1 = 12, z0 = 20, z1 = 44 } -- area bersih awal 24 x 24 (tempat rangka rumah)
local PATH = { x0 = -6, x1 = 6, z0 = 44, z1 = 96 } -- jalan setapak dari gerbang ke rumah
local SPACING = 4 -- studs between two objects

-- Bab 3.4: 40 ilalang (1 tap), 12 semak (2), 8 batu kecil (2), 4 tunggul (3). Total 64 = the bitmask size.
local START_KINDS = {
	{ id = "ilalang", count = 40, taps = 1 },
	{ id = "semak", count = 12, taps = 2 },
	{ id = "batu", count = 8, taps = 2 },
	{ id = "tunggul", count = 4, taps = 3 },
}

-- Chunk yang dibeli (Bab 3.1) juga dapat ilalang & semak. Jumlahnya dari kepadatan lahan awal (64 objek di ~14.800 stud²,
-- satu chunk 32 x 32 = 1.024 stud²) dibulatkan: 4 objek. Dikonfirmasi owner (T-25, Bab 3.4 v6.2.1).
local CHUNK_KINDS = {
	{ id = "ilalang", count = 3, taps = 1 },
	{ id = "semak", count = 1, taps = 2 },
}

local CHUNK_COUNT = 0
for _, kind in CHUNK_KINDS do
	CHUNK_COUNT += kind.count
end

local function inside(x: number, z: number, r: { x0: number, x1: number, z0: number, z1: number }): boolean
	return x >= r.x0 and x <= r.x1 and z >= r.z0 and z <= r.z1
end

local function tooClose(list: { Object }, x: number, z: number): boolean
	for _, o in list do
		if (o.x - x) ^ 2 + (o.z - z) ^ 2 < SPACING * SPACING then
			return true
		end
	end
	return false
end

-- Deterministic placement: the same seed always gives the same layout on every server.
local function place(seed: number, area: { x0: number, x1: number, z0: number, z1: number }, kinds: { { id: string, count: number, taps: number } }, avoid: ((number, number) -> boolean)?): { Object }
	local rng = Random.new(seed)
	local out: { Object } = {}
	for _, kind in kinds do
		for _ = 1, kind.count do
			local placed = false
			for _ = 1, 500 do
				local x = rng:NextNumber(area.x0, area.x1)
				local z = rng:NextNumber(area.z0, area.z1)
				if not (avoid and avoid(x, z)) and not tooClose(out, x, z) then
					table.insert(out, { kind = kind.id, taps = kind.taps, x = x, z = z })
					placed = true
					break
				end
			end
			assert(placed, "LahanAwal: no room left for a starting object (adjust SPACING or the areas)")
		end
	end
	return out
end

local START_OBJECTS = place(SEED, START, START_KINDS, function(x, z)
	return inside(x, z, CLEAN) or inside(x, z, PATH)
end)

-- Objects of one bought chunk (ix, iz), plot-local, in the same order every time.
local function chunkObjects(ix: number, iz: number): { Object }
	local size = Plots.CHUNK.SIZE
	local area = {
		x0 = ix * size + 2,
		x1 = ix * size + size - 2,
		z0 = iz * size + 2,
		z1 = iz * size + size - 2,
	}
	return place(SEED + 1000 + (ix + 100) * 211 + (iz + 100), area, CHUNK_KINDS)
end

return {
	SEED = SEED,
	START_OBJECTS = START_OBJECTS, -- 64 entries: index = bit position (1..64) in land.lahanAwal
	START_COUNT = #START_OBJECTS,
	chunkObjects = chunkObjects,
	CHUNK_COUNT = CHUNK_COUNT,
	-- Full bitmask for a chunk (all its objects present): 2^count - 1.
	CHUNK_FULL_BITS = 2 ^ CHUNK_COUNT - 1,
	-- Bab 3.4: all starting objects cleared -> "Lahan Kakek Bersih" + 200 Koin (the dekor Papan Nama Lahan is not in the game yet).
	CLEAN_REWARD = { koin = 200 },
	INTERACT_DISTANCE = Farm.INTERACT_DISTANCE,
}
