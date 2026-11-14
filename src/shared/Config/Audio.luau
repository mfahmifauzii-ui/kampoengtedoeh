--!strict
-- Sound ids. Free Creator Store assets from verified creators (ProSoundEffects,
-- DistrokidOfficial) — LISTEN AND SWAP freely; nil = silent.

local function id(n: number?): string?
	return if n then `rbxassetid://{n}` else nil
end

return {
	VOLUME = { music = 0.22, ambient = 0.35, sfx = 0.5 },

	-- Lo-fi / calm playlist, shuffled with a pause between tracks.
	MUSIC = {
		id(87083199878076), -- Quiet Library Clouds
		id(79439593998299), -- Desk Lamp Glow
		id(133914369779227), -- Quiet Morning Drizzle
		id(72974959848644), -- Paper Moon
	} :: { string },
	MUSIC_GAP_SECONDS = 25,

	-- Looping nature beds, crossfaded by day phase.
	AMBIENT = {
		pagi = id(9112831284), -- Morning Birds 1
		siang = id(9116969965), -- Morning Birds 2
		sore = id(9116969962), -- Morning Birds 3
		malam = id(9112764546), -- Crickets Night 1
	} :: { [string]: string? },
	RAIN = id(9112856881), -- Rain On Window 1
	RIVER = id(9119646667), -- Stream Flow 1 (3D, on the river)

	-- One-shots keyed by notification locale key. Fill these with your picks.
	SFX = {
		["fish.caught"] = id(9119293555), -- Small Splash
		["farm.harvested"] = id(nil),
		["sell.sold"] = id(nil),
		["order.done"] = id(nil),
		["level.up"] = id(nil),
		["level.up_unlocks"] = id(nil),
		["book.new"] = id(nil),
	} :: { [string]: string? },
}
