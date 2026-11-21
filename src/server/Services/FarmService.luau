--!strict
-- Free-form farming. The player tills (garap) grass cells of their land into soil tiles, then plants,
-- waters and harvests them.
--   * Soil is TERRAIN: a raised Ground (dry) / Mud (wet) bed, never a Part. The only Parts are invisible
--     click targets, one per tile, that carry the tile's state as attributes for the client.
--   * Tile state lives in data.farm.tiles (saved by ProfileStore) and is rebuilt on join, so the farm is
--     exactly as the player left it. Growth is timestamp-based (os.time): it continues offline.
--   * Tiles are addressed by uid (stable), never by array index.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Buffs = require(ReplicatedStorage.Shared.Config.Buffs)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Kualitas = require(ReplicatedStorage.Shared.Config.Kualitas)
local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local EconomyService = require(script.Parent.EconomyService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local BookService = require(script.Parent.BookService)
local WorldService = require(script.Parent.WorldService)
local TutorialService = require(script.Parent.TutorialService)
local AnalyticsHooks = require(script.Parent.AnalyticsHooks)
local QuestService = require(script.Parent.QuestService)

local TILE_TAG = "FarmTile"
local RATE = { rate = 8, burst = 12 }
local RATE_TILL = { rate = 10, burst = 20 }
local MAX_CELL = 40 -- sanity bound for requested cells (the land is about ±36 cells wide)

local FarmService = {}
local random = Random.new()

local soilState: { [BasePart]: string } = {} -- "dry" | "wet": what is painted in the terrain right now

-- Terrain soil ----------------------------------------------------------------------------

-- Ground-level center of a tile cell, in world space.
local function tileCFrame(origin: BasePart, cx: number, cz: number): CFrame
	local x, z = Land.tileCenter(cx, cz)
	return origin.CFrame * CFrame.new(x, origin.Size.Y / 2, z)
end

-- The terrain under a tilled bed stays FLAT: the 2 x 2 cells are painted Ground (dry) or Mud (wet) with occupancy
-- Farm.BED_OCCUPANCY = 0.5, the same as grass, so the ground does not change height. The raised look is the soil slab
-- Part (makeTilePart, Farm.TILE_HEIGHT / BED_RAISE). An older version used occupancy 0.85 for a soft mound (1.4 studs);
-- that is no longer the value. The cells are written with WriteVoxels so the paint matches the cell boundaries exactly.
--   "none" = grass again (GROUND_OCCUPANCY 0.5), "dry" = Ground, "wet" = Mud.
-- Tiles line up with the terrain cells (Land) and plots sit on multiples of 4 and turn in quarter turns, so the
-- tile's world box is already cell-aligned and the top layer is the one just under the ground.
local function paintSoil(origin: BasePart, cx: number, cz: number, state: string)
	local center = tileCFrame(origin, cx, cz).Position
	local half = Land.TILE / 2
	-- Snap to the 4-stud grid: the plot's rotation leaves tiny float errors (7.9999995), and a region that starts a
	-- hair below a cell edge is rounded DOWN a whole cell (measured: beds painted 4 studs off).
	local centerX, centerZ = math.round(center.X / 4) * 4, math.round(center.Z / 4) * 4
	local top = math.round(center.Y / 4) * 4
	local region = Region3.new(Vector3.new(centerX - half, top - 4, centerZ - half), Vector3.new(centerX + half, top, centerZ + half))
	local terrain = Workspace.Terrain
	local materials, occupancy = terrain:ReadVoxels(region, 4)
	local material = if state == "none"
		then Enum.Material.LeafyGrass
		elseif state == "wet" then Enum.Material.Mud
		else Enum.Material.Ground
	local fill = if state == "none" then Farm.GROUND_OCCUPANCY else Farm.BED_OCCUPANCY
	local size = materials.Size
	for x = 1, size.X do
		for y = 1, size.Y do
			for z = 1, size.Z do
				materials[x][y][z] = material
				occupancy[x][y][z] = fill
			end
		end
	end
	terrain:WriteVoxels(region, 4, materials, occupancy)
end

-- Tiles ------------------------------------------------------------------------------------

local function findTile(data: Types.PlayerData, uid: number): (Types.FarmTile?, number?)
	for index, tile in data.farm.tiles do
		if tile.uid == uid then
			return tile, index
		end
	end
	return nil, nil
end

local function getTilePart(player: Player, uid: number): BasePart?
	local plot = PlotService.GetPlot(player)
	local folder = plot and plot:FindFirstChild("Farm")
	local part = folder and folder:FindFirstChild(`Tile{uid}`)
	return if part and part:IsA("BasePart") then part else nil
end

-- Mirrors tile state to its click-target attributes and repaints the soil when wet/dry changes.
local function sync(player: Player, tile: Types.FarmTile)
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	local part = getTilePart(player, tile.uid)
	if not part or not origin then
		return
	end
	part:SetAttribute("Crop", tile.crop)
	part:SetAttribute("PlantedAt", tile.plantedAt)
	part:SetAttribute("ReadyAt", tile.readyAt)
	part:SetAttribute("Watered", tile.watered)

	local state = if tile.crop ~= nil and tile.watered == true then "wet" else "dry"
	if soilState[part] ~= state then
		soilState[part] = state
		paintSoil(origin, tile.cx, tile.cz, state)
		part.Color = if state == "wet" then Farm.BED_COLOR_WET else Farm.BED_COLOR_DRY
	end
end

local function makeTilePart(player: Player, folder: Folder, origin: BasePart, tile: Types.FarmTile)
	local part = Instance.new("Part")
	part.Name = `Tile{tile.uid}`
	part.Anchored = true
	part.CanCollide = false
	-- The visible bed: a low soil slab, 1 stud smaller than its grid cell so neighbouring beds show a thin furrow.
	part.Size = Vector3.new(Farm.BED_SIZE, Farm.TILE_HEIGHT, Farm.BED_SIZE)
	part.CFrame = tileCFrame(origin, tile.cx, tile.cz) * CFrame.new(0, Farm.TILE_HEIGHT / 2, 0)
	-- Sand material: the GroundStylized override (MapService) applies to every Ground / Mud part too and renders
	-- almost black on a Part (measured), while Sand has no override and takes its Color as is.
	part.Material = Enum.Material.Sand
	part.Color = Farm.BED_COLOR_DRY
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("Owner", player.UserId)
	part:SetAttribute("Index", tile.uid) -- the client sends this uid back
	part:SetAttribute("Cx", tile.cx)
	part:SetAttribute("Cz", tile.cz)

	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = Farm.INTERACT_DISTANCE
	detector.Parent = part

	part.Parent = folder
	CollectionService:AddTag(part, TILE_TAG)
end

local function getFarmFolder(plot: Model): Folder
	local existing = plot:FindFirstChild("Farm")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Farm"
	folder.Parent = plot
	return folder
end

-- Removes the soil of every tile on a plot (terrain back to grass) and its click targets.
local function clearPlot(plot: Model)
	local origin = plot.PrimaryPart
	local folder = plot:FindFirstChild("Farm")
	if not folder then
		return
	end
	for _, part in folder:GetChildren() do
		local cx, cz = part:GetAttribute("Cx"), part:GetAttribute("Cz")
		if origin and typeof(cx) == "number" and typeof(cz) == "number" then
			paintSoil(origin, cx, cz, "none")
		end
		if part:IsA("BasePart") then
			soilState[part] = nil
		end
	end
	folder:ClearAllChildren()
end

-- Rebuilds the whole farm from saved data (on join).
local function buildTiles(player: Player, plot: Model)
	local data = DataService.Get(player)
	local origin = plot.PrimaryPart
	if not data or not origin then
		return
	end
	clearPlot(plot)
	local folder = getFarmFolder(plot)
	for _, tile in data.farm.tiles do
		makeTilePart(player, folder, origin, tile)
		sync(player, tile)
	end
end

-- How many tiles this player may have tilled, by level (Bab 5.2).
function FarmService.Cap(data: Types.PlayerData): number
	return Farm.tileCap(data.level)
end

local function characterDistance(player: Player, position: Vector3): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return (root.Position - position).Magnitude
	end
	return nil
end

local function isCell(value: any): boolean
	return typeof(value) == "number" and value % 1 == 0 and math.abs(value) <= MAX_CELL
end

-- Rectangles tilling must avoid: placed decor, ponds and buildings (kandang/dapur/warung).
local function decorRects(data: Types.PlayerData): { Land.Rect }
	local rects: { Land.Rect } = Land.takenRects(data.pond.list, Dapur.buildings(data.ranch.kandang, data.dapur.spot, data.warung.spot), Dapur.BUILDING_SIZES)
	for _, entry in data.decor.placed do
		local rect = DecorGrid.entryRect(entry)
		if rect then
			table.insert(rects, rect)
		end
	end
	return rects
end

-- Garap / Ratakan ------------------------------------------------------------------------

local function onTill(player: Player, cx: any, cz: any)
	if not isCell(cx) or not isCell(cz) then
		return
	end
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	if not data or not plot or not origin then
		return
	end
	local cap = FarmService.Cap(data)
	local n = #data.farm.tiles + 1
	if n > cap then
		Net.Fire("Notify", player, "farm.till_full", { max = cap })
		return
	end
	local distance = characterDistance(player, tileCFrame(origin, cx, cz).Position)
	if not distance or distance > Farm.TILL_DISTANCE then
		Net.Fire("Notify", player, "farm.till_far")
		return
	end
	if not Land.canTill(cx, cz, data.farm.tiles, decorRects(data), data.land.chunks) then
		Net.Fire("Notify", player, "farm.till_invalid")
		return
	end
	local cost = Farm.tileCost(n)
	if cost > 0 and not EconomyService.TrySpend(player, "koin", cost, `till:{n}`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
		return
	end

	local tile: Types.FarmTile = { uid = data.farm.nextUid, cx = cx, cz = cz }
	data.farm.nextUid += 1
	table.insert(data.farm.tiles, tile)
	makeTilePart(player, getFarmFolder(plot), origin, tile)
	sync(player, tile)
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "farm.tilled")
end

local function onLevel(player: Player, uid: any)
	if typeof(uid) ~= "number" then
		return
	end
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	if not data or not plot or not origin then
		return
	end
	local tile, index = findTile(data, uid)
	if not tile or not index then
		return
	end
	if tile.crop ~= nil then
		Net.Fire("Notify", player, "farm.level_busy")
		return
	end
	local distance = characterDistance(player, tileCFrame(origin, tile.cx, tile.cz).Position)
	if not distance or distance > Farm.TILL_DISTANCE then
		Net.Fire("Notify", player, "farm.till_far")
		return
	end

	table.remove(data.farm.tiles, index)
	local part = getTilePart(player, uid)
	if part then
		soilState[part] = nil
		part:Destroy()
	end
	paintSoil(origin, tile.cx, tile.cz, "none")
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "farm.leveled")
end

-- Pindah: an EMPTY bed moves to another free cell of your own land. Nothing is lost; the bed keeps its soil.
local function onMove(player: Player, uid: any, cx: any, cz: any)
	if typeof(uid) ~= "number" or typeof(cx) ~= "number" or typeof(cz) ~= "number" or cx % 1 ~= 0 or cz % 1 ~= 0 then
		return
	end
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	if not data or not plot or not origin then
		return
	end
	local tile = findTile(data, uid)
	if not tile then
		return
	end
	-- A bed WITH a crop moves too: the tile record keeps its crop, planted time, ready time and watered state, so the
	-- harvest timer keeps running (nothing is reset). Only the cell changes.
	local distance = characterDistance(player, tileCFrame(origin, tile.cx, tile.cz).Position)
	if not distance or distance > Farm.TILL_DISTANCE then
		Net.Fire("Notify", player, "farm.till_far")
		return
	end
	if cx == tile.cx and cz == tile.cz then
		return
	end
	local others = {}
	for _, other in data.farm.tiles do
		if other.uid ~= uid then
			table.insert(others, other)
		end
	end
	if not Land.canTill(cx, cz, others, decorRects(data), data.land.chunks) then
		Net.Fire("Notify", player, "farm.move_invalid")
		return
	end

	local oldCx, oldCz = tile.cx, tile.cz
	local part = getTilePart(player, uid)
	if part then
		soilState[part] = nil
		part:Destroy()
	end
	paintSoil(origin, oldCx, oldCz, "none")
	tile.cx, tile.cz = cx, cz
	makeTilePart(player, getFarmFolder(plot), origin, tile)
	sync(player, tile)
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "farm.moved")
end

-- Plant / water / harvest ---------------------------------------------------------------

-- Shared validation for every tile request: the uid must be a tile of THIS player and their character close to it.
local function getValidTile(player: Player, uid: any): (Types.PlayerData?, Types.FarmTile?)
	if typeof(uid) ~= "number" or uid % 1 ~= 0 then
		return nil, nil
	end
	local data = DataService.Get(player)
	local tile = data and findTile(data, uid)
	local part = tile and getTilePart(player, uid)
	if not data or not tile or not part then
		return nil, nil
	end
	local distance = characterDistance(player, part.Position)
	if not distance or distance > Farm.INTERACT_DISTANCE + 10 then
		return nil, nil
	end
	return data, tile
end

-- Applies the watering bonus once per growth. Returns true if the tile changed.
local function waterTile(tile: Types.FarmTile, now: number): boolean
	if tile.crop == nil or tile.watered == true then
		return false
	end
	local readyAt = tile.readyAt :: number
	if now >= readyAt then
		return false
	end
	tile.readyAt = now + math.ceil((readyAt - now) * (1 - Farm.WATER_REDUCTION))
	tile.watered = true
	return true
end

local function clearCrop(tile: Types.FarmTile)
	tile.crop = nil
	tile.fast = nil
	tile.plantedAt = nil
	tile.readyAt = nil
	tile.watered = nil
	tile.harvestsLeft = nil
end

-- Skill Tangan Hijau (Bab 4.5, P2-4): tumbuh +2%/lv (waktu x (1 - 0,02 x lv)).
local function growSeconds(data: Types.PlayerData, crop: Crops.Crop): number
	local lv = data.skill.tangan_hijau or 0
	return math.ceil(crop.growSeconds * (1 - 0.02 * lv))
end

local function onPlant(player: Player, uid: any, cropId: any)
	if typeof(cropId) ~= "string" then
		return
	end
	local crop = Crops.byId[cropId]
	local data, tile = getValidTile(player, uid)
	if not crop or not data or not tile or tile.crop ~= nil then
		return
	end
	if data.level < crop.unlockLevel then
		Net.Fire("Notify", player, "farm.locked", { level = crop.unlockLevel })
		return
	end
	-- Planting uses a seed from the bag: normal bibit only. Bibit Unggul DIHAPUS (Bab 29).
	if not InventoryService.Remove(player, `seed_{crop.id}`, 1) then
		Net.Fire("Notify", player, "farm.no_seed", { crop = `crop.{crop.id}` })
		return
	end

	local now = os.time()
	tile.crop = crop.id
	tile.plantedAt = now
	tile.readyAt = now + growSeconds(data, crop)
	-- Tutorial seeds: the first plantings of a new save grow fast (data.guide.fastLeft); later ones use the normal timer.
	if TutorialService.ConsumeFast(player) then
		tile.readyAt = now + Onboarding.FAST_GROW_SECONDS
		InventoryService.Sync(player) -- fastLeft is in the snapshot
	end
	tile.watered = false
	tile.harvestsLeft = crop.regrows
	if WorldService.IsRaining() then
		waterTile(tile, now)
	end
	sync(player, tile)
	AnalyticsHooks.Step(player, "first_plant")
	-- Stage 7 quest reports: Misi Utama counts Kangkung only, the Daily counts any planting.
	QuestService.Report(player, "plant")
	if crop.id == "kangkung" then
		QuestService.Report(player, "plant_kangkung")
	end
end

local function onWater(player: Player, uid: any)
	local _, tile = getValidTile(player, uid)
	if tile and waterTile(tile, os.time()) then
		sync(player, tile)
	end
end

-- Gembor tiers (Bab 17.5): gembor_plastik 1 petak, gembor_seng 2 petak (garis), gembor_kuningan 3 petak (garis).
-- Waters the tapped bed + the nearest (cells - 1) beds on the same row, but only beds that are planted, growing and
-- dry. Needs the tool owned; the distance check runs on the tapped bed.
local GEMBOR_ORDER = { "gembor_kuningan", "gembor_seng", "gembor_plastik" } -- best first

local function gemborCells(data: Types.PlayerData): number?
	for _, toolId in GEMBOR_ORDER do
		if data.tools[toolId] == true then
			local tool = Farm.TOOLS[toolId]
			return tool and tool.cells or nil
		end
	end
	return nil
end

local function onWaterArea(player: Player, uid: any)
	local data, tile = getValidTile(player, uid)
	if not data or not tile then
		return
	end
	local cells = gemborCells(data)
	if not cells then
		return
	end
	local now = os.time()
	-- Same row (cz), nearest first, tapped bed included.
	local row = {}
	for _, other in data.farm.tiles do
		if other.cz == tile.cz then
			table.insert(row, other)
		end
	end
	table.sort(row, function(a, b)
		return math.abs(a.cx - tile.cx) < math.abs(b.cx - tile.cx)
	end)
	for i = 1, math.min(cells, #row) do
		if waterTile(row[i], now) then
			sync(player, row[i])
		end
	end
end

-- Rain waters every growing crop of every player in the server.
local function waterAllForRain()
	local now = os.time()
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			for _, tile in data.farm.tiles do
				if waterTile(tile, now) then
					sync(player, tile)
				end
			end
		end
	end
end

-- Kualitas roll (Bab 5.4 v7.3, Config/Kualitas). Server only.
--   timely: panen <=5 menit setelah matang. wet: petak Basah. Mutasi DIHAPUS total (Bab 29).
local function rollQuality(tile: Types.FarmTile, now: number, mataLv: number): string?
	local readyAt = tile.readyAt
	local timely = readyAt ~= nil and now - readyAt <= Kualitas.TIMELY_WINDOW_SECONDS
	local wet = tile.watered == true
	-- Skill Mata Kualitas (Bab 4.5, P2-4): Bagus +2%/lv, Prima +0,5%/lv, additive.
	return Kualitas.pick(timely, wet, random:NextNumber(), 0.02 * mataLv, 0.005 * mataLv)
end

-- Harvest roll (Bab 5.3 Super, Bab 5.4 Kualitas). Server only.
--   Super: base 5%, +5% if the tile is Basah. Fase 1 forces it for the FTUE first harvest (forceSuper).
--   Buff Tani (Bab 9.4): +10% peluang Super (superBonus). Tidak ngaruh ke waktu tumbuh.
--   Kualitas: timing + Basah roll (rollQuality). Returns (super, qualityId?).
local function rollHarvest(tile: Types.FarmTile, now: number, forceSuper: boolean, superBonus: number, mataLv: number): (boolean, string?)
	local super = forceSuper
	if not super then
		local chance = Farm.SUPER_CHANCE + (if tile.watered == true then Farm.SUPER_WET_BONUS else 0) + superBonus
		super = random:NextNumber() < chance
	end
	return super, rollQuality(tile, now, mataLv)
end

-- The FTUE first harvest of a new save is always Super (Bab 16.3 0:50). Once per save:
-- guide.done.ftue_super, set after a successful Add. Skipping T1 turns the guarantee off.
local function takeFirstHarvestGuarantee(data: Types.PlayerData): boolean
	local guide = data.guide
	if guide.done.ftue_super == true or guide.done.t1_awal == true or guide.skipped.t1_awal == true then
		return false
	end
	return Onboarding.FTUE_FIRST_SUPER
end

local function onHarvest(player: Player, uid: any)
	local data, tile = getValidTile(player, uid)
	if not data or not tile or tile.crop == nil then
		return
	end
	local now = os.time()
	if now < (tile.readyAt :: number) then
		return
	end
	local crop = Crops.byId[tile.crop :: string]
	if not crop then
		return
	end
	local guaranteed = takeFirstHarvestGuarantee(data)
	local taniBonus = if Buffs.active(data.buff, "tani", now) then Dapur.BUFF_TANI_SUPER else 0
	local super, quality = rollHarvest(tile, now, guaranteed, taniBonus, data.skill.mata_kualitas or 0)
	local itemId = Items.cropItemId(crop.id, super, quality)
	if not InventoryService.Add(player, itemId, crop.yield) then
		return
	end
	-- Byproduct panen (Bab 5.3 v7.3): Padi -> 2 Jerami, Pisang -> 2 Daun Pisang. Tidak blokir panen kalau gagal.
	if crop.byproduct then
		InventoryService.Add(player, crop.byproduct.id, crop.byproduct.count)
	end
	-- Skill Bibit Hemat (Bab 4.5, P2-4): 4%/lv, 1 bibit kembali saat panen.
	if random:NextNumber() < 0.04 * (data.skill.bibit_hemat or 0) then
		InventoryService.Add(player, `seed_{crop.id}`, 1)
		Net.Fire("Notify", player, "farm.seed_back", { crop = `crop.{crop.id}` })
	end
	if guaranteed then
		data.guide.done.ftue_super = true -- marked only after the item is in the bag (a full bag must not waste it)
	end
	data.onboarding.first_harvest = true -- A1: the tutorial treats a harvest as done for the planting and watering steps

	local harvestsLeft = tile.harvestsLeft or 0
	if harvestsLeft > 0 then
		tile.harvestsLeft = harvestsLeft - 1
		tile.plantedAt = now
		tile.readyAt = now + growSeconds(data, crop)
		tile.watered = false
	else
		clearCrop(tile) -- the tile itself (uid, cell) stays: the soil stays tilled
	end
	sync(player, tile)
	Net.Fire("Notify", player, "farm.harvested", { n = crop.yield, item = `crop.{crop.id}` })
	if super then
		Net.Fire("Notify", player, "farm.super")
	end
	if quality then
		Net.Fire("Notify", player, "farm.kualitas", { quality = `kualitas.{quality}` })
	end
	-- Banner server: Panen Prima pada tanaman Late (2 jam+, Bab 5.4).
	if quality and Kualitas.byId[quality].announce and crop.growSeconds >= Kualitas.ANNOUNCE_MIN_GROW_SECONDS then
		Net.FireAll("KualitasBanner", player.Name, crop.id, quality)
	end
	local xp = math.floor(crop.xp * (if super then Farm.SUPER_XP_MULT else 1) + 0.5)
	ProgressionService.AddXp(player, xp, `harvest:{crop.id}`)
	AnalyticsHooks.Step(player, "first_harvest")
	BookService.RecordCrop(player, crop.id, quality) -- Album Ladang: entri per Kualitas (Bab 11)
	QuestService.Report(player, "harvest")
end

-- The tile cap changed (farm expansion / pass): the client snapshot shows it.
function FarmService.Rebuild(player: Player)
	InventoryService.Sync(player)
end

-- Studio testing only (called by DevService).
function FarmService.DevFinishAll(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local now = os.time()
	for _, tile in data.farm.tiles do
		if tile.crop then
			tile.readyAt = now
			sync(player, tile)
		end
	end
end

-- Stage 2: Sprinkler Bambu (decor, Lv 7). Every SPRINKLER_SECONDS it waters the planted, dry beds within reach of each
-- sprinkler on its owner's land (3x3 around it). It only waters; it never plants or harvests.
local SPRINKLER_SECONDS = 60
local SPRINKLER_REACH = Land.PITCH * 1.5 -- studs from the sprinkler to a bed centre: the 3x3 block of beds around it

local function sprinklersTick()
	local now = os.time()
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		local plot = PlotService.GetPlot(player)
		local decor = plot and plot:FindFirstChild("Decor")
		if data and decor then
			for _, model in decor:GetChildren() do
				if model:GetAttribute("ItemId") == "sprinkler_bambu" and model:IsA("Model") then
					local center = model:GetPivot().Position
					local watered = 0
					for _, tile in data.farm.tiles do
						local part = getTilePart(player, tile.uid)
						if part and (part.Position - center).Magnitude <= SPRINKLER_REACH and waterTile(tile, now) then
							sync(player, tile)
							watered += 1
						end
					end
					print(`[Sprinkler] {player.Name}: {watered} petak tersiram`)
				end
			end
		end
	end
end

function FarmService.Init()
	task.spawn(function()
		while true do
			task.wait(SPRINKLER_SECONDS)
			sprinklersTick()
		end
	end)
	WorldService.RainChanged:Connect(function(raining: boolean)
		if raining then
			waterAllForRain()
		end
	end)
	PlotService.Assigned:Connect(buildTiles)
	PlotService.Released:Connect(function(_player: Player, plot: Model)
		clearPlot(plot) -- the next owner of this plot must not inherit the soil
	end)
end

function FarmService.Start()
	Net.On("FarmPlant", onPlant, RATE)
	Net.On("FarmWater", onWater, RATE)
	Net.On("FarmWaterArea", onWaterArea, RATE)
	Net.On("FarmHarvest", onHarvest, RATE)
	Net.On("FarmTill", onTill, RATE_TILL)
	Net.On("FarmLevel", onLevel, RATE_TILL)
	Net.On("FarmMove", onMove, RATE_TILL)
end

return FarmService
