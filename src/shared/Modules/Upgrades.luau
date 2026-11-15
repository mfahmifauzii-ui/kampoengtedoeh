--!strict
-- Permanent upgrades bought from Pak Darmo (Config/Shop UPGRADES). One tier number per upgrade in data.upgrades:
--   backpack = Tas (inventory slots), pond = Kolam (pond capacity), warung = Kapasitas Warung (daily crop quota).
-- Pure helpers, so the server services and the client can read a tier without requiring each other.

local Upgrades = {}

Upgrades.IDS = { "backpack", "pond", "warung" }

-- Current tier of one upgrade (0 = not bought yet).
function Upgrades.tier(data: { upgrades: { [string]: number } }, id: string): number
	return (data.upgrades and data.upgrades[id]) or 0
end

return Upgrades
