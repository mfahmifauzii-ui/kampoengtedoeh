--!strict
-- The shape of a player's land and the farm-tile grid. Shared by the server (validation, terrain painting)
-- and the client (previews). All coordinates are PLOT-LOCAL studs:
--   x = to the plot's right,  z = toward the map center (the plot's front),  origin = the plot anchor.
--
-- The land is the green wedge of the blueprint: every point at least SETBACK studs from BOTH the river axis and the
-- road axis, cut at the front (FRONT_Z) and the back (BACK_Z). Its slanted edges are a 4-stud staircase, exactly
-- the terrain cell size, so what you can build on is what is painted green.
-- TERRAIN GRID (measured with Terrain:ReadVoxels): cells are 4 studs with their edges at multiples of 4, and a block
-- paints a cell's material when the cell's CENTER lies inside the block. Plot anchors sit on multiples of 4, so in
-- plot-local studs BACK_Z / FRONT_Z are multiples of 4, row half widths are multiples of 4, and a farm tile
-- (8 studs) is exactly 2 x 2 cells. Paint blocks are 0.5 smaller than the cells they fill: that keeps the centers of
-- the neighbouring cells outside the block.
-- Rows are 4 studs tall, row 0 starts at BACK_Z.

local Fishing = require(script.Parent.Parent.Config.Fishing)
local Map = require(script.Parent.Parent.Config.Map)
local Plots = require(script.Parent.Parent.Config.Plots)

export type Rect = { minX: number, minZ: number, maxX: number, maxZ: number }

local SQRT2 = math.sqrt(2)
local TILE = 8 -- farm bed size = 2 x 2 terrain cells (also the pond grid)
local PITCH = 8 -- farm beds sit side by side on the grid (the small visible gap is the bed Part being 1 stud smaller than its cell, see Farm.BED_SIZE)
local TILE_OFFSET = 0 -- tiles already line up with the cell edges (multiples of 4)
local ROW = 4 -- terrain cell size
local APEX = Map.LAND.SETBACK * SQRT2 -- slanted edge: u >= |x| + APEX, with u = distance from the map center along the axis

local Land = {}
Land.TILE = TILE
Land.PITCH = PITCH
Land.TILE_OFFSET = TILE_OFFSET
Land.SURFACE_OFFSET = 2 -- measured: the visible terrain surface is this far above the top of a filled block
Land.ROW = ROW
Land.APEX = APEX
Land.FRONT_Z = Plots.FRONT_Z
Land.BACK_Z = Plots.DISTANCE - Map.LAND.BACK_DISTANCE
Land.ROWS = (Land.FRONT_Z - Land.BACK_Z) // ROW

-- Half width of the land in a 4-stud row: the narrowest edge of the row, rounded down to whole cells.
function Land.rowHalfWidth(row: number): number
	local zNear = Land.BACK_Z + ROW * (row + 1)
	local width = Plots.DISTANCE - zNear - APEX
	return math.max(0, math.floor(width / ROW) * ROW)
end

Land.MAX_HALF_WIDTH = Land.rowHalfWidth(0)

-- Smooth point test (for "am I standing on this plot?"). margin grows the land outward.
function Land.contains(x: number, z: number, margin: number?): boolean
	local m = margin or 0
	if z > Land.FRONT_Z + m or z < Land.BACK_Z - m then
		return false
	end
	local u = Plots.DISTANCE - z
	return u >= math.abs(x) + APEX - m * SQRT2
end

-- Exact staircase test: is the whole rectangle painted-green land?
function Land.rectInside(rect: Rect): boolean
	if rect.minZ < Land.BACK_Z or rect.maxZ > Land.FRONT_Z then
		return false
	end
	local widest = math.max(math.abs(rect.minX), math.abs(rect.maxX))
	local first = math.floor((rect.minZ - Land.BACK_Z) / ROW)
	local last = math.ceil((rect.maxZ - Land.BACK_Z) / ROW) - 1
	for row = first, last do
		if Land.rowHalfWidth(row) < widest then
			return false
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
function Land.canPond(cx: number, cz: number, tiles: { { cx: number, cz: number } }, ponds: { { cx: number, cz: number } }, extraRects: { Rect }): boolean
	local rect = Land.pondRect(cx, cz)
	if not Land.rectInside(rect) then
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

-- Things that are always there: the house. (Ponds are built by the player and tracked by PondService.)
local fixed: { Rect } = {}
do
	local house = Map.HOUSE
	table.insert(fixed, { minX = house.X - house.HALF, minZ = house.Z - house.HALF, maxX = house.X + house.HALF, maxZ = house.Z + house.HALF })
end

function Land.fixedRects(): { Rect }
	return fixed
end

-- Can a grass cell be tilled? tiles = the player's existing tiles, extraRects = e.g. placed decor.
function Land.canTill(cx: number, cz: number, tiles: { { cx: number, cz: number } }, extraRects: { Rect }): boolean
	local rect = Land.tileRect(cx, cz)
	if not Land.rectInside(rect) then
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
