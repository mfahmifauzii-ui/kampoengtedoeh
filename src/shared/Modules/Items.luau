--!strict
-- Resolves any inventory item id to its display key + sell price.
-- Item ids: crops = "<cropId>", fish = "<fishId>@<size>" (e.g. "nila@M"), bait = "pelet".

local Crops = require(script.Parent.Parent.Config.Crops)
local FishConfig = require(script.Parent.Parent.Config.Fish)
local Fishing = require(script.Parent.Parent.Config.Fishing)
local Locale = require(script.Parent.Parent.Locale)

export type ItemKind = "crop" | "fish" | "bait" | "seed"

export type ItemInfo = {
	id: string,
	kind: ItemKind,
	nameKey: string,
	nameVars: { [string]: string }?, -- var name -> locale key, translated when the name is shown
	sizeKey: string?,
	sellPrice: number?, -- nil = can't be sold
}

local Items = {}

local KIND_ORDER: { [ItemKind]: number } = { crop = 1, fish = 2, bait = 3, seed = 4 }

function Items.info(itemId: string): ItemInfo?
	local crop = Crops.byId[itemId]
	if crop then
		return { id = itemId, kind = "crop", nameKey = `crop.{crop.id}`, sellPrice = crop.sellPrice }
	end

	-- Seeds: "seed_<crop>" (normal, Pak Udin) and "seedx_<crop>" (unggul, Pak Udin).
	local seedCrop = itemId:match("^seed_(.+)$")
	if seedCrop and Crops.byId[seedCrop] then
		return { id = itemId, kind = "seed", nameKey = "item.seed", nameVars = { crop = `crop.{seedCrop}` } }
	end
	local seedxCrop = itemId:match("^seedx_(.+)$")
	if seedxCrop and Crops.byId[seedxCrop] then
		return { id = itemId, kind = "seed", nameKey = "item.seedx", nameVars = { crop = `crop.{seedxCrop}` } }
	end

	local fishId, size = itemId:match("^(.+)@(%a)$")
	local fish = fishId and FishConfig.byId[fishId]
	if fish and size then
		for _, entry in FishConfig.SIZES do
			if entry.id == size then
				return {
					id = itemId,
					kind = "fish",
					nameKey = `fish.{fish.id}`,
					sizeKey = `size.{size}`,
					sellPrice = math.floor(fish.sellPrice * entry.valueMult + 0.5),
				}
			end
		end
	end

	if itemId == Fishing.BAIT.id then
		return { id = itemId, kind = "bait", nameKey = `item.{itemId}` }
	end
	return nil
end

-- "Bibit Kangkung", "Nila (Sedang)", ...
function Items.displayName(info: ItemInfo): string
	local vars: { [string]: string }? = nil
	if info.nameVars then
		vars = {}
		for name, key in info.nameVars do
			(vars :: any)[name] = Locale.t(key)
		end
	end
	local name = Locale.t(info.nameKey, vars)
	return if info.sizeKey then `{name} ({Locale.t(info.sizeKey)})` else name
end

-- Stable display order: crops, fish, bait, seeds; then by id.
function Items.sortIds(ids: { string }): { string }
	table.sort(ids, function(a, b)
		local infoA, infoB = Items.info(a), Items.info(b)
		local orderA = if infoA then KIND_ORDER[infoA.kind] else 9
		local orderB = if infoB then KIND_ORDER[infoB.kind] else 9
		if orderA ~= orderB then
			return orderA < orderB
		end
		return a < b
	end)
	return ids
end

return Items
