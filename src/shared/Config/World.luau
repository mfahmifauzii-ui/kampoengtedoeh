--!strict
-- Day cycle + rain + lighting presets. All visuals are applied client-side; the server
-- only publishes CycleStart / DayPhase / Raining as Workspace attributes.

export type LightingPreset = {
	brightness: number,
	ambient: Color3,
	outdoorAmbient: Color3,
	tint: Color3, -- ColorCorrection tint
	saturation: number,
	atmosphereDensity: number,
	atmosphereColor: Color3,
	atmosphereDecay: Color3,
	haze: number,
}

-- 24 real minutes. clockFrom/clockTo = Lighting.ClockTime across the phase (wraps past 24).
local CYCLE = {
	{ phase = "pagi", minutes = 5, clockFrom = 5.5, clockTo = 9 },
	{ phase = "siang", minutes = 8, clockFrom = 9, clockTo = 15.5 },
	{ phase = "sore", minutes = 4, clockFrom = 15.5, clockTo = 18.6 },
	{ phase = "malam", minutes = 7, clockFrom = 18.6, clockTo = 29.5 },
}

local total = 0
for _, entry in CYCLE do
	total += entry.minutes * 60
end

return {
	CYCLE = CYCLE,
	CYCLE_SECONDS = total,

	-- Clock hour a new server starts at (each play session begins here, then runs on in real time).
	START_CLOCK = 10,

	RAIN = {
		CHECK_INTERVAL = 1200, -- roll every 20 min
		CHANCE = 0.25,
		MIN_SECONDS = 240,
		MAX_SECONDS = 360,
	},

	TRANSITION_SECONDS = 8, -- lighting tween between phases / rain

	-- v3 look: warm, saturated and clear, like a cozy farm game (lush greens, blue sky, golden light).
	-- Night stays moody but keeps its color. Rain desaturates on top (RAIN_LIGHTING).
	PRESETS = {
		pagi = {
			brightness = 2.0,
			ambient = Color3.fromRGB(132, 128, 124),
			outdoorAmbient = Color3.fromRGB(164, 160, 156),
			tint = Color3.fromRGB(255, 240, 222),
			saturation = 0.12,
			atmosphereDensity = 0.3, -- morning mist: mountains melt into soft silhouettes
			atmosphereColor = Color3.fromRGB(240, 240, 240),
			atmosphereDecay = Color3.fromRGB(214, 150, 120),
			haze = 7,
		},
		siang = {
			brightness = 2.6,
			ambient = Color3.fromRGB(136, 132, 124),
			outdoorAmbient = Color3.fromRGB(172, 168, 160),
			tint = Color3.fromRGB(255, 250, 238),
			saturation = 0.18,
			atmosphereDensity = 0.3, -- thick far haze: only the mountain silhouette shows
			atmosphereColor = Color3.fromRGB(240, 240, 240),
			atmosphereDecay = Color3.fromRGB(96, 152, 214), -- blue sky
			haze = 6.5,
		},
		sore = {
			brightness = 2.2,
			ambient = Color3.fromRGB(140, 116, 98),
			outdoorAmbient = Color3.fromRGB(180, 144, 112),
			tint = Color3.fromRGB(255, 214, 170), -- golden hour
			saturation = 0.2,
			atmosphereDensity = 0.3,
			atmosphereColor = Color3.fromRGB(240, 240, 240),
			atmosphereDecay = Color3.fromRGB(230, 130, 90),
			haze = 7,
		},
		malam = {
			brightness = 0.9,
			ambient = Color3.fromRGB(74, 80, 112),
			outdoorAmbient = Color3.fromRGB(92, 100, 134),
			tint = Color3.fromRGB(200, 212, 244),
			saturation = 0.02,
			atmosphereDensity = 0.3,
			atmosphereColor = Color3.fromRGB(240, 240, 240),
			atmosphereDecay = Color3.fromRGB(40, 48, 92),
			haze = 5,
		},
	} :: { [string]: LightingPreset },

	-- Applied on top of the phase preset while raining.
	RAIN_LIGHTING = {
		brightnessMult = 0.7,
		densityAdd = 0.1,
		saturationAdd = -0.12,
		tint = Color3.fromRGB(214, 220, 228),
	},

	CLOUD_COVER = 0.55,
	RAIN_CLOUD_COVER = 0.85,
	LAMP_PHASES = { malam = true }, -- decor lamps glow during these phases
}
