--!strict
-- The shape of a player's land and the farm-tile grid. Shared by the server (validation, terrain painting)
-- and the client (previews). All coordinates are PLOT-LOCAL studs:
--   x = to the plot's right,  z = toward the map center (the plot's front),  origin = the plot's center.
--
-- R2: every plot has a reserved REGION square (Plots.SIZE = 192: x and z from -96 to 96, +Z = toward the road). The
-- player's land is the START x START (128) square inside it, flush with the road end: x -64 .. 64, z -32 .. 96.
-- (R2b: the land grows block by block into the rest of the region; the rules for that live in this module.)
-- TERRAIN GRID (measured with Terrain:ReadVoxels): cells are 4 studs with their edges at multiples of 4, and a block
-- paints a cell's material when the cell's CENTER lies inside the block. Plot anchors sit on multiples of 4, so in
-- plot-local studs the land edges are multiples of 4 and a farm tile (8 studs) is exactly 2 x 2 cells. Paint blocks
-- are 0.5 smaller than the cells they fill: that keeps the centers of the neighbouring cells outside the block.
-- Rows are 4 studs tall, row 0 starts at BACK_Z.

local Fishing = require(script.Parent.Parent.Config.Fishing)
local Plots = require(script.Parent.Parent.Config.Plots)

export type Rect = { minX: number, minZ: number, maxX: number, maxZ: number }

local TILE = 8 -- farm bed size = 2 x 2 terrain cells (also the pond grid)
local PITCH = 8 -- farm beds sit side by side on the grid (the small visible gap is the bed Part being 1 stud smaller than its cell, see Farm.BED_SIZE)
local TILE_OFFSET = 0 -- tiles already line up with the cell edges (multiples of 4)
local ROW = 4 -- terrain cell size

local Land = {}
Land.TILE = TILE
Land.PITCH = PITCH
Land.TILE_OFFSET = TILE_OFFSET
Land.SURFACE_OFFSET = 2 -- measured: the visible terrain surface is this far above the top of a filled block
Land.ROW = ROW
Land.HALF = Plots.START_SIZE / 2 -- half width of the land (x runs -HALF .. HALF)
Land.REGION_HALF = Plots.SIZE / 2 -- half of the reserved square
Land.FRONT_Z = Plots.FRONT_Z -- the road end
Land.BACK_Z = Plots.FRONT_Z - Plots.START_SIZE
Land.CENTER_Z = (Land.FRONT_Z + Land.BACK_Z) / 2
Land.ROWS = (Land.FRONT_Z - Land.BACK_Z) // ROW

-- Half width of the land in a 4-stud row (the same for every row: the land is a square).
function Land.rowHalfWidth(_row: number): number
	return Land.HALF
end

Land.MAX_HALF_WIDTH = Land.HALF

-- Smooth point test (for "am I standing on this plot?"): the whole reserved square, owned or not. margin grows it.
function Land.contains(x: number, z: number, margin: number?): boolean
	local m = margin or 0
	return math.abs(x) <= Land.REGION_HALF + m and math.abs(z) <= Land.REGION_HALF + m
end

-- The START land only (nature placement keeps trees off it when the map is built).
function Land.startContains(x: number, z: number, margin: number?): boolean
	local m = margin or 0
	return math.abs(x) <= Land.HALF + m and z >= Land.BACK_Z - m and z <= Land.FRONT_Z + m
end

-- Chunks ------------------------------------------------------------------------------------
-- The reserved square is a 6 x 6 grid of CHUNK x CHUNK (32 x 32) blocks: block (ix, iz) covers x ix*32 .. ix*32 + 32 and
-- z iz*32 .. iz*32 + 32, with ix and iz in -3 .. 2. The start land is the blocks ix -2 .. 1 and iz -1 .. 2 (16 blocks);
-- 20 blocks lie outside it, and 14 of those can be bought (the town-facing column is never for sale). Owned extra blocks are kept
-- as a set of "ix,iz" keys (data.land.chunks on the server, snapshot.landChunks on the client).
local CH = Plots.CHUNK.SIZE
Land.CHUNK = CH
Land.CHUNK_MIN = -Land.REGION_HALF // CH -- -6
Land.CHUNK_MAX = Land.REGION_HALF // CH - 1 -- 5
local START_IX0, START_IX1 = -Land.HALF // CH, Land.HALF // CH - 1
local START_IZ0, START_IZ1 = Land.BACK_Z // CH, Land.FRONT_Z // CH - 1
Land.START_CHUNKS = (START_IX1 - START_IX0 + 1) * (START_IZ1 - START_IZ0 + 1)
-- Bought blocks: everything outside the start land except the town-facing column (one block column of the square).
-- With CHUNK.SIZE = 32 this is 36 - 16 - 6 = 14.
Land.EXTRA_CHUNKS = (Land.CHUNK_MAX - Land.CHUNK_MIN + 1) ^ 2 - Land.START_CHUNKS - (Land.CHUNK_MAX - Land.CHUNK_MIN + 1)

export type Chunks = { [string]: boolean }

function Land.chunkKey(ix: number, iz: number): string
	return `{ix + 0},{iz + 0}` -- (+ 0 turns a floating-point -0 into 0)
end

function Land.chunkRect(ix: number, iz: number): Rect
	return { minX = ix * CH, minZ = iz * CH, maxX = ix * CH + CH, maxZ = iz * CH + CH }
end

function Land.inRegion(ix: number, iz: number): boolean
	return ix >= Land.CHUNK_MIN and ix <= Land.CHUNK_MAX and iz >= Land.CHUNK_MIN and iz <= Land.CHUNK_MAX
end

function Land.isStartChunk(ix: number, iz: number): boolean
	return ix >= START_IX0 and ix <= START_IX1 and iz >= START_IZ0 and iz <= START_IZ1
end

function Land.isOwned(ix: number, iz: number, chunks: Chunks?): boolean
	if not Land.inRegion(ix, iz) then
		return false
	end
	return Land.isStartChunk(ix, iz) or (chunks ~= nil and chunks[Land.chunkKey(ix, iz)] == true)
end

local NEIGHBOURS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- Can the player buy this chunk now? In the square, not owned, and touching an owned chunk.
-- inward: the plot-local X side (+1 / -1) that faces the town (Plots.INWARD). Its whole column of blocks is never for
-- sale, so the land only grows to the back and the outer side.
function Land.isBlocked(ix: number, inward: number?): boolean
	if inward == nil then
		return false
	end
	return ix == (if inward > 0 then Land.CHUNK_MAX else Land.CHUNK_MIN)
end

function Land.canBuyChunk(ix: number, iz: number, chunks: Chunks?, inward: number?): boolean
	if not Land.inRegion(ix, iz) or Land.isOwned(ix, iz, chunks) or Land.isBlocked(ix, inward) then
		return false
	end
	for _, step in NEIGHBOURS do
		if Land.isOwned(ix + step[1], iz + step[2], chunks) then
			return true
		end
	end
	return false
end

-- Every chunk the player could buy right now.
function Land.buyableChunks(chunks: Chunks?, inward: number?): { { ix: number, iz: number } }
	local list = {}
	for ix = Land.CHUNK_MIN, Land.CHUNK_MAX do
		for iz = Land.CHUNK_MIN, Land.CHUNK_MAX do
			if Land.canBuyChunk(ix, iz, chunks, inward) then
				table.insert(list, { ix = ix, iz = iz })
			end
		end
	end
	return list
end

function Land.extraCount(chunks: Chunks?): number
	local n = 0
	for _ in chunks or {} do
		n += 1
	end
	return n
end

-- Price of the next chunk when the player already owns `extraOwned` bought chunks. discount: 0..1 (game pass).
function Land.chunkPrice(extraOwned: number, discount: number?): number
	local price = Plots.CHUNK.PRICE_BASE * Plots.CHUNK.PRICE_GROWTH ^ extraOwned
	price = math.floor(price * (1 - (discount or 0)) / 10 + 0.5) * 10
	return math.max(10, price)
end

-- Is the whole rectangle owned land? chunks = the bought chunks (nil = only the start land).
function Land.rectInside(rect: Rect, chunks: Chunks?): boolean
	if rect.minX < -Land.REGION_HALF or rect.maxX > Land.REGION_HALF or rect.minZ < -Land.REGION_HALF or rect.maxZ > Land.REGION_HALF then
		return false
	end
	for ix = rect.minX // CH, math.ceil(rect.maxX / CH) - 1 do
		for iz = rect.minZ // CH, math.ceil(rect.maxZ / CH) - 1 do
			if not Land.isOwned(ix, iz, chunks) then
				return false
			end
		end
	end
	return true
end

function Land.rectsOverlap(a: Rect, b: Rect): boolean
	return a.minX < b.maxX and a.maxX > b.minX and a.minZ < b.maxZ and a.maxZ > b.minZ
end

-- Farm tiles sit on a PITCH x PITCH grid: the raised bed is TILE x TILE and the remaining PITCH - TILE studs on the
-- +x / +z side of every cell is the path between beds (kept free so beds never touch).
function Land.tileRect(cx: number, cz: number): Rect
	local minX, minZ = cx * PITCH + TILE_OFFSET, cz * PITCH + TILE_OFFSET
	return { minX = minX, minZ = minZ, maxX = minX + TILE, maxZ = minZ + TILE }
end

-- Plot-local center of a tile's bed.
function Land.tileCenter(cx: number, cz: number): (number, number)
	return cx * PITCH + TILE_OFFSET + TILE / 2, cz * PITCH + TILE_OFFSET + TILE / 2
end

function Land.cellOfPoint(x: number, z: number): (number, number)
	return math.floor((x - TILE_OFFSET) / PITCH), math.floor((z - TILE_OFFSET) / PITCH)
end

-- Ponds ------------------------------------------------------------------------------------
-- Ponds use their own 8-stud grid (tile cell units of TILE studs), so they line up with the terrain cells.
local POND_TILES = Fishing.POND.SIZE // TILE

function Land.pondRect(cx: number, cz: number): Rect
	local minX, minZ = cx * TILE + TILE_OFFSET, cz * TILE + TILE_OFFSET
	return { minX = minX, minZ = minZ, maxX = minX + POND_TILES * TILE, maxZ = minZ + POND_TILES * TILE }
end

-- The rectangles of a list of ponds. Added to the "taken" rectangles wherever tilling or decor is checked, so
-- soil and decor can never sit on water.
function Land.pondRects(ponds: { { cx: number, cz: number } }): { Rect }
	local rects: { Rect } = {}
	for _, pond in ponds do
		table.insert(rects, Land.pondRect(pond.cx, pond.cz))
	end
	return rects
end

-- Can a pond be dug with its min corner at tile cell (cx, cz)? tiles = farm tiles, ponds = existing ponds.
function Land.canPond(cx: number, cz: number, tiles: { { cx: number, cz: number } }, ponds: { { cx: number, cz: number } }, extraRects: { Rect }, chunks: Chunks?): boolean
	local rect = Land.pondRect(cx, cz)
	if not Land.rectInside(rect, chunks) then
		return false
	end
	for _, other in Land.fixedRects() do
		if Land.rectsOverlap(rect, other) then
			return false
		end
	end
	for _, tile in tiles do
		if Land.rectsOverlap(rect, Land.tileRect(tile.cx, tile.cz)) then
			return false
		end
	end
	for _, pond in ponds do
		if Land.rectsOverlap(rect, Land.pondRect(pond.cx, pond.cz)) then
			return false
		end
	end
	for _, other in extraRects do
		if Land.rectsOverlap(rect, other) then
			return false
		end
	end
	return true
end

-- No fixed rectangles any more: the start house was removed from the land (ponds are tracked by PondService).
local fixed: { Rect } = {}

function Land.fixedRects(): { Rect }
	return fixed
end

-- Can a grass cell be tilled? tiles = the player's existing tiles, extraRects = e.g. placed decor.
function Land.canTill(cx: number, cz: number, tiles: { { cx: number, cz: number } }, extraRects: { Rect }, chunks: Chunks?): boolean
	local rect = Land.tileRect(cx, cz)
	if not Land.rectInside(rect, chunks) then
		return false
	end
	for _, other in fixed do
		if Land.rectsOverlap(rect, other) then
			return false
		end
	end
	for _, tile in tiles do
		if tile.cx == cx and tile.cz == cz then
			return false
		end
	end
	for _, other in extraRects do
		if Land.rectsOverlap(rect, other) then
			return false
		end
	end
	return true
end

return Land
