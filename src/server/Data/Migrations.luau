--!strict
-- Upgrades old saves step by step. Runs BEFORE Reconcile.
-- To change the schema: add STEPS[n] (migrates v n -> n+1), bump CURRENT_VERSION
-- and DataTemplate.version together.

local CURRENT_VERSION = 13

-- Farm beds moved to a wider grid (a path between beds): every tile keeps its crop and moves to the cell its old
-- center falls in; if two tiles land in one cell, the later one takes the nearest free cell (a bed can shift a
-- little, nothing is lost). oldPitch / newPitch = studs between bed corners; the bed itself is 8 studs.
local function respaceTiles(data: any, oldPitch: number, newPitch: number)
	local tiles = if data.farm and typeof(data.farm.tiles) == "table" then data.farm.tiles else {}
	local taken: { [string]: boolean } = {}
	for _, tile in tiles do
		local cx = math.floor((tile.cx * oldPitch + 4) / newPitch)
		local cz = math.floor((tile.cz * oldPitch + 4) / newPitch)
		local radius = 0
		while taken[`{cx},{cz}`] do
			radius += 1
			local found = false
			for dx = -radius, radius do
				for dz = -radius, radius do
					if not found and (math.abs(dx) == radius or math.abs(dz) == radius) and not taken[`{cx + dx},{cz + dz}`] then
						cx, cz, found = cx + dx, cz + dz, true
					end
				end
			end
		end
		taken[`{cx},{cz}`] = true
		tile.cx, tile.cz = cx, cz
	end
end

local STEPS: { [number]: (data: any) -> () } = {
	-- v1 -> v2: farm tiles had a fixed layout (3 columns, by array index). Free-form farming stores a cell
	-- per tile instead. Old tiles keep their crops and move onto a 3-wide block of cells near the plot center-left.
	[1] = function(data)
		local old = if data.farm and typeof(data.farm.tiles) == "table" then data.farm.tiles else {}
		local tiles = {}
		local nextUid = 1
		for index, oldTile in old do
			local tile: any = { uid = nextUid, cx = -5 + (index - 1) % 3, cz = -5 + (index - 1) // 3 }
			for _, field in { "crop", "plantedAt", "readyAt", "watered", "harvestsLeft" } do
				tile[field] = oldTile[field]
			end
			table.insert(tiles, tile)
			nextUid += 1
		end
		data.farm = data.farm or {}
		data.farm.tiles = tiles
		data.farm.nextUid = nextUid
	end,

	-- v2 -> v3: the fixed plot pond is gone; ponds are built by the player (list). The capacity tier is kept,
	-- the old single pond's timer (lastCollect) and any uncollected fish are dropped.
	[2] = function(data)
		local old = if typeof(data.pond) == "table" then data.pond else {}
		data.pond = {
			tier = if typeof(old.tier) == "number" then old.tier else 0,
			list = {},
			nextUid = 1,
		}
	end,

	-- v3 -> v4: decor is unlocked by blueprints instead of item levels. Anyone who already owns decor of a
	-- blueprint (placed or in stock) gets that blueprint, so nobody loses access to what they were using.
	[3] = function(data)
		data.decor = data.decor or {}
		local owned = {}
		local oldBlueprints = {
			bale_bambu = "pondok_sawah",
			meja_kayu = "pondok_sawah",
			lampu_teplok = "pondok_sawah",
			orang_orangan_sawah = "pondok_sawah",
			gentong_air = "pondok_sawah",
			jemuran = "pondok_sawah",
			sepeda_onthel = "pondok_sawah",
			pohon_pisang = "taman",
			rumpun_bambu = "taman",
			bangku_kayu = "taman",
			bunga_kertas = "taman",
		}
		for _, entry in if typeof(data.decor.placed) == "table" then data.decor.placed else {} do
			local blueprint = oldBlueprints[entry.id]
			if blueprint then
				owned[blueprint] = true
			end
		end
		for itemId, count in if typeof(data.decor.stock) == "table" then data.decor.stock else {} do
			local blueprint = oldBlueprints[itemId]
			if blueprint and count > 0 then
				owned[blueprint] = true
			end
		end
		data.decor.blueprints = owned
	end,

	-- v4 -> v5: farm beds moved from the 8-stud grid (beds touching) to a 12-stud grid.
	[4] = function(data)
		respaceTiles(data, 8, 12)
	end,

	-- v5 -> v6: 12 was too tight (the smooth terrain filled the 4-stud path); the grid is now 16 studs.
	[5] = function(data)
		respaceTiles(data, 12, 16)
	end,

	-- v6 -> v7: beds are adjacent again (8-stud grid) with a crisp slab and a thin furrow, which is what a farm
	-- should look like; a spread-out 16-stud grid read like a chessboard.
	[6] = function(data)
		respaceTiles(data, 16, 8)
	end,

	-- v7 -> v8: haggling, NPC kedekatan and skills are gone (Pak Darmo now has a daily crop quota instead).
	-- Nothing the player owns changes; only the old bookkeeping is dropped and `sales` starts empty.
	[7] = function(data)
		data.npc = nil
		data.skills = nil
		data.sales = { day = "", sold = {}, tier = 0 }
	end,

	-- v8 -> v9 (R2a): the land is now a 96 x 96 square (plot-local x and z from -48 to 48) instead of the huge wedge.
	-- Farm beds and ponds that fall outside it are dropped (crops on them are lost; a pond refunds
	-- Fishing.POND.REFUND_RATE of what it cost, as if it had been removed). Decor outside the land is put back in stock
	-- when the player joins (DecorService), so nothing placed is lost. Beds are 8 studs (cell * 8), ponds 16.
	[8] = function(data)
		local Fishing = require(game:GetService("ReplicatedStorage").Shared.Config.Fishing)
		local pondCells = Fishing.POND.SIZE // 8
		local function inside(cell: number, cells: number): boolean
			return cell >= -6 and cell + cells <= 6
		end

		if data.farm and typeof(data.farm.tiles) == "table" then
			local kept = {}
			for _, tile in data.farm.tiles do
				if inside(tile.cx, 1) and inside(tile.cz, 1) then
					table.insert(kept, tile)
				end
			end
			data.farm.tiles = kept
		end

		if data.pond and typeof(data.pond.list) == "table" then
			local kept = {}
			for _, pond in data.pond.list do
				if inside(pond.cx, pondCells) and inside(pond.cz, pondCells) then
					table.insert(kept, pond)
				elseif typeof(pond.paid) == "number" and pond.paid > 0 then
					data.koin = (data.koin or 0) + math.floor(pond.paid * Fishing.POND.REFUND_RATE)
				end
			end
			data.pond.list = kept
		end
	end,

	-- v9 -> v10 (R2 ring map): a plot's coordinate frame moved. Before, the origin was the center of the 96 x 96 land
	-- (x, z from -48 to 48). Now it is the center of the 192 x 192 reserved square and the 128 x 128 start land sits
	-- flush with the road end (x -64 .. 64, z -32 .. 96). Everything keeps its place on the land by shifting 32 studs
	-- along z: beds and ponds by 4 cells (8 studs each), decor by 40 cells in z (2 studs each, and the decor grid's
	-- cell 0 moved from -48 to -96, which is +24 cells in x as well). Old land fits inside the new land.
	[9] = function(data)
		if data.farm and typeof(data.farm.tiles) == "table" then
			for _, tile in data.farm.tiles do
				tile.cz += 4
			end
		end
		if data.pond and typeof(data.pond.list) == "table" then
			for _, pond in data.pond.list do
				pond.cz += 4
			end
		end
		if data.decor and typeof(data.decor.placed) == "table" then
			for _, entry in data.decor.placed do
				entry.x += 24
				entry.z += 40
			end
		end
	end,

	-- v10 -> v11 (R2b): land is bought chunk by chunk, so the tile cap and the "Perluas Kebun" upgrade are gone.
	-- Whatever a player paid for farm expansions (300 / 800 / 2000 / 5000 / 12000 Koin per tier) is refunded in full.
	-- New fields: land.chunks (none bought yet) and plotSlot.
	[10] = function(data)
		local costs = { 300, 800, 2000, 5000, 12000 }
		local tiers = if data.farm and typeof(data.farm.expansions) == "number" then data.farm.expansions else 0
		local refund = 0
		for tier = 1, math.min(tiers, #costs) do
			refund += costs[tier]
		end
		data.koin = (data.koin or 0) + refund
		if data.farm then
			data.farm.expansions = nil
		end
		data.land = { chunks = {} }
		data.plotSlot = 0
	end,

	-- v11 -> v12: land is bought in 32 x 32 BLOCKS now, not 16 x 16 chunks (Config/Plots CHUNK.SIZE). Every block that
	-- contains a chunk the player had bought is now theirs (a block is 2 x 2 old chunks, so it can be a little more
	-- than they paid for; tilled beds, ponds and decor all stay valid). Old keys "ix,iz" become floor(ix / 2), floor(iz / 2).
	[11] = function(data)
		local old = if data.land and typeof(data.land.chunks) == "table" then data.land.chunks else {}
		local blocks = {}
		for key in old do
			local ix, iz = string.match(key, "^(-?%d+),(-?%d+)$")
			if ix and iz then
				blocks[`{math.floor(tonumber(ix) / 2)},{math.floor(tonumber(iz) / 2)}`] = true
			end
		end
		data.land = { chunks = blocks }
	end,
}

-- v12 -> v13 (R3): the three permanent upgrades share one table, data.upgrades[id] = tier (Tas = backpack, Kolam = pond,
-- Kapasitas Warung = warung). Each old tier moves over as is. New: playtime (Hadiah), empty for everyone.
STEPS[12] = function(data)
	local upgrades = { backpack = 0, pond = 0, warung = 0 }
	if typeof(data.backpackTier) == "number" then
		upgrades.backpack = data.backpackTier
	end
	if data.pond and typeof(data.pond.tier) == "number" then
		upgrades.pond = data.pond.tier
		data.pond.tier = nil
	end
	if data.sales and typeof(data.sales.tier) == "number" then
		upgrades.warung = data.sales.tier
		data.sales.tier = nil
	end
	data.backpackTier = nil
	data.upgrades = upgrades
	data.playtime = { day = "", seconds = 0, claimed = 0 }
end

local Migrations = {}
Migrations.CURRENT_VERSION = CURRENT_VERSION

export type Result = "ok" | "newer" -- "newer" = save was written by a newer server build

function Migrations.Run(data: any): Result
	local version = if typeof(data.version) == "number" then data.version else 1

	if version > CURRENT_VERSION then
		return "newer"
	end

	while version < CURRENT_VERSION do
		local step = STEPS[version]
		assert(step, `[Migrations] Missing step for v{version}`)
		step(data)
		version += 1
	end

	data.version = CURRENT_VERSION
	return "ok"
end

return Migrations
