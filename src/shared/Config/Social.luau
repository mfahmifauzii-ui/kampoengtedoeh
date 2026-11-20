--!strict
-- Mampir (visit), Suka (like) and emotes.
-- Likes: each visitor can like each plot once per WIB day. Milestones pay the plot OWNER once.

local Progression = require(script.Parent.Progression)

return {
	VISIT_OFFSET = Vector3.new(0, 4, 40), -- relative to a plot's Origin: by the sign, facing the road
	VISIT_COOLDOWN = 3, -- seconds between teleports
	LIKE_MARGIN = 6, -- studs outside the plot edge that still count as "on the plot"

	LIKE_MILESTONES = {
		{ likes = 10, reward = { bunga = 3 } },
		{ likes = 50, reward = { bunga = 10 } },
		{ likes = 200, reward = { bunga = 25, title = "kebun_favorit" } },
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
