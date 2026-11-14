--!strict
-- NPC shops (see Config/Npcs for who sells what). Rods come from Fishing.rodList, bait from Fishing.BAIT.
-- Upgrade cost i = price of going from tier i-1 to tier i.

return {
	NPC_DISTANCE = 25, -- studs, server-checked for every buy/sell

	MAX_AMOUNT = 99, -- most you can buy or sell in one go (the number picker in the shop; the server re-checks)

	UPGRADE_ORDER = { "backpack", "pond", "warung" },
	UPGRADES = {
		backpack = { costs = { 1000, 4000, 10000 }, unlockLevel = 1 }, -- Inventory.SLOTS
		pond = { costs = { 1500, 5000 }, unlockLevel = 6 }, -- Fishing.POND.CAPS
		-- Kapasitas Warung: +Npcs.QUOTA.PER_TIER crops per type per day that Pak Darmo buys at full price. Always
		-- Koin-only. Costs are assumptions (simulate before locking).
		warung = { costs = { 600, 2000, 5000, 12000 }, unlockLevel = 3 },
	} :: { [string]: { costs: { number }, unlockLevel: number } },
}
