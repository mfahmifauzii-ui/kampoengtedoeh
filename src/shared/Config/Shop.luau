--!strict
-- NPC shops (see Config/Npcs for who sells what). Rods come from Fishing.rodList, bait from Fishing.BAIT.
-- Upgrade cost i = price of going from tier i-1 to tier i.

return {
	NPC_DISTANCE = 25, -- studs, server-checked for every buy/sell

	PACKS = { 1, 10 }, -- amounts you can buy at once (seeds, bait, fish)

	UPGRADE_ORDER = { "backpack", "pond", "farm" },
	UPGRADES = {
		backpack = { costs = { 1000, 4000, 10000 }, unlockLevel = 1 }, -- Inventory.SLOTS
		pond = { costs = { 1500, 5000 }, unlockLevel = 6 }, -- Fishing.POND.CAPS
		farm = { costs = { 300, 800, 2000, 5000, 12000 }, unlockLevel = 1 }, -- +3 tiles each
	} :: { [string]: { costs: { number }, unlockLevel: number } },
}
