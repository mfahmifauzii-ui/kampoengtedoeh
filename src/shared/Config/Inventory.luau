--!strict
-- Backpack: each item id uses ceil(count / STACK_SIZE) slots.

return {
	STACK_SIZE = 99,
	SLOTS = { 50, 60, 80, 100 }, -- by Tas upgrade tier + 1 (upgrade costs in Shop config). Stage 8: 50 at start, 100 from Lv 10 (InventoryService)
LEVEL_100_SLOTS = 10, -- from this level the Tas holds at least 100 items
}
