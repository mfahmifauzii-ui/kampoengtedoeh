--!strict
-- Cuaca server (docs/01_GDD_Kampoeng_Tedoeh_v8.4.md Bab 3.3, LOCKED). Server-local: every server runs its own
-- cycle, no cross-server state (Prinsip #16). WorldService runs the state machine; FarmService and FishService read it.
--   Terik (8-15 menit, random) -> Hujan (3 menit: Gerimis 55% / Deres 30% / Petir 15%) -> Terik -> ...
-- Tidak ada Pelangi di game (Bab 29). Tidak pernah hujan 2x berturut-turut.
-- The day/night cycle (Config/World) is separate and keeps running; the two do not depend on each other.

export type Kind = "terik" | "gerimis" | "deres" | "petir"

return {
	-- Durations in seconds.
	-- K-128 (owner has never seen rain): was 480-900 s (8-15 min), so a normal 10-minute session rarely reached rain.
	TERIK_MIN_SECONDS = 180, -- 3 menit (K-128, was 8)
	TERIK_MAX_SECONDS = 300, -- 5 menit (was 15)
	RAIN_SECONDS = 180, -- 3 menit

	-- Roll when Terik ends. Chances sum to 1.
	RAIN_ROLL = {
		{ kind = "gerimis" :: Kind, chance = 0.55 },
		{ kind = "deres" :: Kind, chance = 0.30 },
		{ kind = "petir" :: Kind, chance = 0.15 },
	},

	-- Rain kinds (Workspace "Raining" is true for these).
	IS_RAIN = { gerimis = true, deres = true, petir = true },

	-- How long the server remembers past weather windows (seconds).
	HISTORY_SECONDS = 10800,

	-- Client visuals (Bab 21.3). Particle counts are kept low for the 4 GB phone target (Bab 21 limits).
	-- K-129: rates raised (was 30/60/90, which drew too few drops to read). Phone cap: at most 150/s with 1.3 s life (about 190 alive).
	PARTICLES = { gerimis = 80, deres = 120, petir = 150 }, -- Bab 21: Gerimis, Deres, Petir + kilat
	REDUCE_MOTION_DENSITY = 0.4, -- Kurangi gerak: 40% of the drops, rain still on
	-- K-133: ground splashes = this fraction of the rain rate. K-135: 0.12 was barely visible; 0.25 = about 20/s at Gerimis
	-- (phone-safe: 0.3-0.5 s life, about 10 alive). Pooled: two emitters (burst + ring).
	SPLASH_RATIO = 0.25,
	-- K-134: puddles after rain. Server-side, visible to everyone. Cap and lifetime are per server.
	PUDDLE_MAX = 12, -- at most this many puddles on the map
	PUDDLE_LIFETIME = 180, -- seconds after the rain ends (3 menit); then fade out and destroy
	PUDDLE_FADE_SECONDS = 3,
	PUDDLE_TRIES = 300, -- random spots tried per spawn (cap on the scan)
	RAIN_FADE_SECONDS = 3, -- rain rate eases in/out over this long (no pop-in or pop-out)
	LIGHTNING_INTERVAL = 20, -- Petir: a flash every 20 s
	LIGHTNING_FLASH_SECONDS = 0.1, -- the flash itself is at most 0.1 s
	UI_ANIMATION_SCALE = 0.5, -- Bab 21 limits: UI animations run at half duration on phones
}
