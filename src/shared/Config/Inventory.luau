--!strict
-- Backpack: each item id uses ceil(count / STACK_SIZE) slots.

return {
	STACK_SIZE = 99,
	SLOTS = { 40, 60, 80, 100 }, -- by backpackTier + 1 (upgrade costs in Shop config)
}
