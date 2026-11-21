--!strict
-- Permanent upgrades bought from Pak Udin (Config/Shop UPGRADES). One tier number per upgrade in data.upgrades:
--   pond = Kolam (pond capacity).
-- Pure helpers, so the server services and the client can read a tier without requiring each other.

local Upgrades = {}

Upgrades.IDS = { "pond" }

-- Current tier of one upgrade (0 = not bought yet).
function Upgrades.tier(data: { upgrades: { [string]: number } }, id: string): number
	return (data.upgrades and data.upgrades[id]) or 0
end

return Upgrades
