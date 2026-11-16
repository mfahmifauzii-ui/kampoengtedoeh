--!strict
-- Recolours shop models by hand (for shops that were inserted or baked without MapService.placeTemplate).
-- Each MeshPart named after a slot in Config/ShopPalette gets that slot's Color + Material. Nothing else changes.
--
-- Run from the Studio command bar / execute_luau (Edit or Play, on the server or client):
--   require(game.ReplicatedStorage.Shared.Modules.ApplyShopPalette).apply(workspace.Map.Town)
-- Pass a single shop model to recolour only that one. Returns how many parts were recoloured.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopPalette = require(ReplicatedStorage.Shared.Config.ShopPalette)

local ApplyShopPalette = {}

function ApplyShopPalette.apply(root: Instance): number
	local count = 0
	for _, part in root:GetDescendants() do
		if part:IsA("MeshPart") then
			local slot = ShopPalette[part.Name]
			if slot then
				part.Color = slot.Color
				part.Material = slot.Material
				count += 1
			end
		end
	end
	return count
end

return ApplyShopPalette
