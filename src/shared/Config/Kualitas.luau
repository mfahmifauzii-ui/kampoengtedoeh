--!strict
-- Kualitas Panen (docs/01_GDD_Kampoeng_Tedoeh_v8.4.md Bab 5.4, LOCKED). Kualitas ditentukan saat panen, dari timing + siram.
-- Nil (Biasa) = panen biasa, tidak ada prefix di id item. Bagus / Prima jadi prefix: "bagus_<crop>" / "prima_<crop>".
-- Super DIHAPUS (Update owner 2026-11-22). Harga = sellPrice x mult (Bab 17.7).
--
-- timely: panen <=5 menit setelah matang (TIMELY_WINDOW_SECONDS). wet: petak Basah (tile.watered).
--   timely && wet  : Biasa 50% / Bagus 35% / Prima 15%
--   salah satu     : Biasa 65% / Bagus 25% / Prima 10%
--   telat && !wet  : Biasa 85% / Bagus 12% / Prima 3%

export type Quality = {
	id: string,
	mult: number,
	nameKey: string, -- Locale key of the quality name
	announce: boolean, -- server banner to every player in the server when it is harvested
}

local list: { Quality } = {
	{ id = "bagus", mult = 1.1, nameKey = "kualitas.bagus", announce = false },
	{ id = "prima", mult = 1.25, nameKey = "kualitas.prima", announce = true },
}

-- Batas akhir peluang (Update owner 2026-11-22, Task 3), dihitung SETELAH semua bonus (Mata Kualitas + Buff Tani):
--   Bagus max 50%, Prima max 20%. Biasa = sisanya.
local CAP_BAGUS = 0.50
local CAP_PRIMA = 0.20

-- Panen tepat waktu: <=5 menit setelah matang.
local TIMELY_WINDOW_SECONDS = 300

-- Banner Prima hanya untuk tanaman Late (2 jam+). Bab 5.4: "Panen Prima pada tanaman Late".
local ANNOUNCE_MIN_GROW_SECONDS = 7200

local DISTRIBUTION = {
	timelyWet = { bagus = 0.35, prima = 0.15 }, -- sisanya Biasa (50%)
	oneOf = { bagus = 0.25, prima = 0.10 }, -- sisanya Biasa (65%)
	lateDry = { bagus = 0.12, prima = 0.03 }, -- sisanya Biasa (85%)
}

local byId: { [string]: Quality } = {}
for _, quality in list do
	byId[quality.id] = quality
end

-- roll: hasil random:NextNumber() dari pemanggil (FarmService). Returns quality id atau nil (Biasa).
-- bonusBagus/bonusPrima: Skill Mata Kualitas (Bab 4.5, P2-4) — additive di atas tabel Bab 5.4.
local function pick(timely: boolean, wet: boolean, roll: number, bonusBagus: number?, bonusPrima: number?): string?
	local dist = if timely and wet then DISTRIBUTION.timelyWet
		elseif timely or wet then DISTRIBUTION.oneOf
		else DISTRIBUTION.lateDry
	local bagus = math.min(dist.bagus + (bonusBagus or 0), CAP_BAGUS)
	local prima = math.min(dist.prima + (bonusPrima or 0), CAP_PRIMA)
	if roll < bagus then
		return "bagus"
	elseif roll < bagus + prima then
		return "prima"
	end
	return nil -- Biasa
end

return {
	list = list,
	byId = byId,
	TIMELY_WINDOW_SECONDS = TIMELY_WINDOW_SECONDS,
	CAP_BAGUS = CAP_BAGUS,
	CAP_PRIMA = CAP_PRIMA,
	ANNOUNCE_MIN_GROW_SECONDS = ANNOUNCE_MIN_GROW_SECONDS,
	pick = pick,
}
