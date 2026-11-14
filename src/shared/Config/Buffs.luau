--!strict
-- Buffs: temporary bonuses (never penalties). The player card has exactly three buff slots, one per kind, so two buffs
-- of the same kind never stack and the card never grows. A slot shows an empty icon until its buff is active; an active
-- buff shows the full icon that drains away (top to bottom) as its time runs out.
--
-- The server publishes an active buff as two player attributes (the HUD only reads them):
--   Buff_<id>_End  = Workspace:GetServerTimeNow() when it ends
--   Buff_<id>_Dur  = its full length in seconds (so the icon knows how full it is)
-- STATUS: the slots and their display are built (Studio test: chat "!buff tani 60"); the EFFECTS are not coded yet.
-- Sources come later (cooked food from the player warung, gifts). No buff changes Koin directly (see the economy notes).
--
-- icon = a key in Config/UiAssets ICONS (placeholder until the ForgeGUI buff icons exist: empty + full art per buff).

export type Buff = { id: string, icon: string, nameKey: string, descKey: string, seconds: number }

return {
	SLOTS = {
		-- Farming: new plantings grow 10% faster while it lasts.
		{ id = "tani", icon = "bibit", nameKey = "buff.tani", descKey = "buff.tani.desc", seconds = 600 },
		-- Fishing: fish bite 25% sooner (cast to bite time).
		{ id = "mancing", icon = "pancing", nameKey = "buff.mancing", descKey = "buff.mancing.desc", seconds = 600 },
		-- Everything: +10% XP from every source.
		{ id = "umum", icon = "bintang", nameKey = "buff.umum", descKey = "buff.umum.desc", seconds = 600 },
	} :: { Buff },
}
