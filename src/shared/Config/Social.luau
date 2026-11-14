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

	-- Built-in Roblox emotes played through the default Animate script (no assets needed).
	EMOTES = { "wave", "cheer", "point", "dance" },
}
