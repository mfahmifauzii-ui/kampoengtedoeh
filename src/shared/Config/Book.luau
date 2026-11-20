--!strict
-- Collection Book: entries come from the content configs, so new crops/fish/set decor
-- appear automatically. A finished category or a reached milestone is claimed by hand (BookService.Claim).

local Crops = require(script.Parent.Crops)
local Decor = require(script.Parent.Decor)
local Fish = require(script.Parent.Fish)
local Progression = require(script.Parent.Progression)

type Reward = Progression.Reward

local function ids(list: { any }, filter: ((any) -> boolean)?): { string }
	local out = {}
	for _, entry in list do
		if not filter or filter(entry) then
			table.insert(out, entry.id)
		end
	end
	return out
end

return {
	CATEGORIES = { "crops", "fish", "decor" },
	ENTRIES = {
		crops = ids(Crops.list),
		fish = ids(Fish.list),
		decor = ids(Decor.list, function(item)
			return item.set == "pondok_sawah"
		end),
	} :: { [string]: { string } },

	-- Overall completion (percent of all entries).
	MILESTONES = {
		{ id = "p25", percent = 25, reward = { koin = 500 } },
		{ id = "p50", percent = 50, reward = { bunga = 10 } },
		{ id = "p75", percent = 75, reward = { decor = { lampion_gantung = 1 } } },
		{ id = "p100", percent = 100, reward = { title = "warga_teladan", decor = { gazebo_bambu = 1 } } },
	} :: { { id: string, percent: number, reward: Reward } },

	-- One category fully completed.
	CATEGORY_REWARDS = {
		crops = { koin = 300 },
		fish = { koin = 300 }, -- T-27 family: Bunga (5) removed, Koin 300 like crops; Bab 15.3 Album Bunga comes via Pencapaian (Fase 6)
		decor = { title = "juragan_pondok", decor = { rumpun_bambu = 1 } },
	} :: { [string]: Reward },
}
