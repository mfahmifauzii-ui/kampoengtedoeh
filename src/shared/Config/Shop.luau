--!strict
-- NPC shops (see Config/Npcs for who sells what). Rods come from Fishing.rodList, bait from Fishing.BAIT.
-- Upgrade cost i = price of going from tier i-1 to tier i.

return {
	NPC_DISTANCE = 25, -- studs, server-checked for every buy/sell

	MAX_AMOUNT = 99, -- most you can buy or sell in one go (the number picker in the shop; the server re-checks)

	UPGRADE_ORDER = { "backpack", "pond" },
	UPGRADES = {
		backpack = { costs = { 1000, 4000, 10000 }, unlockLevel = 1 }, -- Inventory.SLOTS
		pond = { costs = { 1500, 5000 }, unlockLevel = 6 }, -- Fishing.POND.CAPS
	} :: { [string]: { costs: { number }, unlockLevel: number } },
}
