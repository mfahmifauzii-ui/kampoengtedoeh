--!strict
-- Resolves any inventory item id to its display key + sell price.
-- Item ids: crops = "<cropId>", Kualitas = "<quality>_<cropId>" (bagus / prima), Super = "super_<cropId>" or "super_<quality>_<cropId>", fish = "<fishId>@<size>" (e.g. "nila@M"), bait = "pelet".

local Crops = require(script.Parent.Parent.Config.Crops)
local Farm = require(script.Parent.Parent.Config.Farm)
local Kualitas = require(script.Parent.Parent.Config.Kualitas)
local FishConfig = require(script.Parent.Parent.Config.Fish)
local Fishing = require(script.Parent.Parent.Config.Fishing)
local Locale = require(script.Parent.Parent.Locale)

export type ItemKind = "crop" | "fish" | "bait" | "seed" | "bahan"

export type ItemInfo = {
	id: string,
	kind: ItemKind,
	nameKey: string,
	nameVars: { [string]: string }?, -- var name -> locale key, translated when the name is shown
	sizeKey: string?,
	sellPrice: number?, -- nil = can't be sold
}

local Items = {}

local KIND_ORDER: { [ItemKind]: number } = { crop = 1, fish = 2, bait = 3, seed = 4, bahan = 5 }

-- Bahan (Bab 10.3 v7.3): Jerami (bonus panen Padi) dan Daun Pisang (bonus panen Pisang, hanya untuk Pepes).
-- Tidak bisa dijual di toko mana pun (sellPrice nil). Dipakai di Craft / Dapur (P2).
local BAHAN: { [string]: string } = {
	jerami = "item.jerami",
	daun_pisang = "item.daun_pisang",
}

function Items.info(itemId: string): ItemInfo?
	local crop = Crops.byId[itemId]
	if crop then
		return { id = itemId, kind = "crop", nameKey = `crop.{crop.id}`, sellPrice = crop.sellPrice }
	end

	-- Harvest produce (Bab 5.4 Kualitas, Bab 5.3 Super): [super_][<quality>_]<crop>.
	local variant = Items.cropVariant(itemId)
	if variant then
		local price = variant.crop.sellPrice
		if variant.super then
			price *= Farm.SUPER_KOIN_MULT
		end
		local vars: { [string]: string } = { crop = `crop.{variant.crop.id}` }
		local nameKey = "item.crop_kualitas"
		if variant.quality then
			price *= variant.quality.mult
			vars.quality = variant.quality.nameKey
		else
			nameKey = "item.super_crop" -- Super only: "{crop} Super"
		end
		if variant.super and variant.quality then
			nameKey = "item.super_kualitas"
		end
		return {
			id = itemId,
			kind = "crop",
			nameKey = nameKey,
			nameVars = vars,
			sellPrice = math.floor(price + 0.5),
		}
	end

	-- Seeds: "seed_<crop>" (normal, Pak Udin). Bibit Unggul DIHAPUS (Bab 29).
	local seedCrop = itemId:match("^seed_(.+)$")
	if seedCrop and Crops.byId[seedCrop] then
		return { id = itemId, kind = "seed", nameKey = "item.seed", nameVars = { crop = `crop.{seedCrop}` } }
	end

	-- Bahan byproduct panen (Bab 5.3 / 10.3 v7.3): tidak bisa dijual.
	local bahanKey = BAHAN[itemId]
	if bahanKey then
		return { id = itemId, kind = "bahan", nameKey = bahanKey }
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

	local bait = Fishing.baitsById[itemId]
	if bait then
		return { id = itemId, kind = "bait", nameKey = `item.{itemId}` }
	end
	return nil
end

-- Parses a harvest item id into its crop, Super flag and Kualitas (nil when it is not a harvest item).
-- Only ids built by Items.cropItemId() parse, so "super_" and "bagus_" are never read off a crop name by accident.
function Items.cropVariant(itemId: string): { crop: Crops.Crop, super: boolean, quality: Kualitas.Quality? }?
	local rest = itemId
	local super = false
	if rest:sub(1, 6) == "super_" then
		super = true
		rest = rest:sub(7)
	end
	local quality: Kualitas.Quality? = nil
	for _, entry in Kualitas.list do
		local prefix = entry.id .. "_"
		if rest:sub(1, #prefix) == prefix then
			quality = entry
			rest = rest:sub(#prefix + 1)
			break
		end
	end
	local crop = Crops.byId[rest]
	if not crop or (not super and quality == nil) then
		return nil -- a plain crop id is handled by Items.info before this
	end
	return { crop = crop, super = super, quality = quality }
end

-- The inventory id of a harvest: the inverse of cropVariant.
function Items.cropItemId(cropId: string, super: boolean, qualityId: string?): string
	local id = cropId
	if qualityId then
		id = `{qualityId}_{id}`
	end
	if super then
		id = `super_{id}`
	end
	return id
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
