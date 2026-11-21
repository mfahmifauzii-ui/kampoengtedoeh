--!strict
-- Mampir (visit), Suka (like) and emotes.
-- Likes: each visitor can like each plot once per WIB day. Milestones pay the plot OWNER once.

local Progression = require(script.Parent.Progression)

return {
	VISIT_OFFSET = Vector3.new(0, 4, 40), -- relative to a plot's Origin: by the sign, facing the road
	VISIT_COOLDOWN = 3, -- seconds between teleports
	BANTU_MAX_DAY = 5, -- max lahan dibantu per hari (Bab 12, P2-5 Bantu; +1 via skill Tetangga Baik)
	LIKE_MARGIN = 6, -- studs outside the plot edge that still count as "on the plot"

	-- T-27 (owner, 20 Nov): Bunga removed here. Koin = 100 per old Bunga (3/10/25 -> 300/1.000/2.500), about one
	-- Agenda task (150-400, Bab 17.7) for the first milestone. Title kebun_favorit stays on the last one.
	LIKE_MILESTONES = {
		{ likes = 10, reward = { koin = 300 } },
		{ likes = 50, reward = { koin = 1000 } },
		{ likes = 200, reward = { koin = 2500, title = "kebun_favorit" } },
	} :: { { likes: number, reward: Progression.Reward } },

	-- The 4 gestures of Bab 12.5. anim = the Roblox Animate PlayEmote name; nil = icon only until a custom
	-- animation exists (TODO T-23: Jempol). No dance, no point, no physical contact.
	EMOTES = {
		{ id = "lambai", anim = "wave" },
		{ id = "jempol", anim = nil },
		{ id = "tepuk", anim = "cheer" },
		{ id = "ketawa", anim = "laugh" },
	} :: { { id: string, anim: string? } },
}
