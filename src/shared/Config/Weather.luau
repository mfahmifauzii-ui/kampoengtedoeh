--!strict
-- Cuaca server (docs/01_GDD_Kampoeng_Tedoeh_v8.3.md Bab 3.3, LOCKED). Server-local: every server runs its own
-- cycle, no cross-server state (Prinsip #16). WorldService runs the state machine; FarmService and FishService read it.
--   Terik (8-15 menit, random) -> Hujan (3 menit: Gerimis 55% / Deres 30% / Petir 15%) -> Terik -> ...
-- Tidak ada Pelangi di game (Bab 29). Tidak pernah hujan 2x berturut-turut.
-- The day/night cycle (Config/World) is separate and keeps running; the two do not depend on each other.

export type Kind = "terik" | "gerimis" | "deres" | "petir"

return {
	-- Durations in seconds.
	TERIK_MIN_SECONDS = 480, -- 8 menit
	TERIK_MAX_SECONDS = 900, -- 15 menit
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
	PARTICLES = { gerimis = 30, deres = 60, petir = 90 }, -- Bab 21: Gerimis 30, Deres 60, Petir 90 + kilat
	LIGHTNING_INTERVAL = 20, -- Petir: a flash every 20 s
	LIGHTNING_FLASH_SECONDS = 0.1, -- the flash itself is at most 0.1 s
	UI_ANIMATION_SCALE = 0.5, -- Bab 21 limits: UI animations run at half duration on phones
}
