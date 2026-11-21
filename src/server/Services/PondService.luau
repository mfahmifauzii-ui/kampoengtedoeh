--!strict
-- Player-built ponds (kolam). Replaces the old fixed plot pond.
--   * The water is TERRAIN (a pit dug 8 studs deep, filled with Water, sand bed under it), exactly like the river.
--     The only Parts are an invisible fishing/collect spot per pond and a few decoration parts per upgrade tier.
--   * Ponds are 16 x 16 studs = 2 x 2 farm-tile cells, saved in data.pond.list and rebuilt on join.
--   * Breed tiers (Bab 7.2, Config/Ranch KOLAM_TIERS): Tanah (Lv 3, 1000+20 Batu, 6 jam, cap 10) /
--     Semen (Lv 15, 5 jam, cap 20) / Keramik (Lv 30, 4 jam, cap 30). Kolam baru = tier Tanah.
--   * Kolam Kakek BUKAN tutorial (P2-2-fix, Bab 7.2/14.2/14.6): PondBuild butuh pond.kakekUnlocked
--     (diset MQ4/Bundel Kakek P2-7; Studio: !kakek). Kolam pertama setelah unlock = gratis + Kakek;
--     kolam 2-4 = harga tier Tanah. Upgrade tier = bayar harga tier target (Semen/Keramik, berurutan).
--     Removing one refunds REFUND_RATE of the koin paid (mats hangus).
--   * Breeding: 2 ikan sejenis non-Legenda + 20 Koin -> 1 anak (@M/Sedang, 100% harga).
--     Kakek -10% waktu, Mood Hujan -10% waktu. Instant Bunga via InstantCost (Bab 18.5, max 30).
--   * Kapasitas simpan efektif = max(upgrade global "pond", breed tier) — USULAN stacking, final ikut playtest.
--   * Fishing/collecting is FishService (FishService.SetupPond); this file only digs, fills and decorates.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Ranch = require(ReplicatedStorage.Shared.Config.Ranch)
local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Map = require(ReplicatedStorage.Shared.Config.Map)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local RanchService = require(script.Parent.RanchService)
local FishService = require(script.Parent.FishService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local QuestService = require(script.Parent.QuestService)

local RATE = { rate = 4, burst = 6 }
local MAX_CELL = 40
local DEPTH = 8 -- pit depth below the ground (same as the river)
local BED = 4 -- sand under the water
local STONE_COLOR = Color3.fromRGB(150, 146, 138)
local LILY_COLOR = Color3.fromRGB(86, 168, 72)
local POST_COLOR = Color3.fromRGB(96, 72, 52)

local PondService = {}

-- Terrain ---------------------------------------------------------------------------------

-- Ground-level center of a pond, in world space.
local function pondCFrame(origin: BasePart, cx: number, cz: number): CFrame
	local rect = Land.pondRect(cx, cz)
	return origin.CFrame * CFrame.new((rect.minX + rect.maxX) / 2, origin.Size.Y / 2, (rect.minZ + rect.maxZ) / 2)
end

-- Same recipe as the river in MapService (see the MEASURED notes there): blocks are lowered by SURFACE_OFFSET,
-- water is the exception (its surface is exactly the top of the block), and every block is 0.5 smaller than the
-- cells it fills so the neighbouring cells' centers stay outside it.
local function fill(ground: CFrame, top: number, bottom: number, material: Enum.Material)
	local drop = -Land.SURFACE_OFFSET
	local size = Fishing.POND.SIZE - 0.5
	Workspace.Terrain:FillBlock(ground * CFrame.new(0, (top + bottom) / 2 + drop, 0), Vector3.new(size, top - bottom, size), material)
end

-- Round pond: the water, the pit and the sand bed are CYLINDERS (Terrain:FillCylinder), so the pond reads as a circle. The
-- 16 x 16 square stays the placement / data rule; its corners are left as grass.
local function fillRound(ground: CFrame, top: number, bottom: number, material: Enum.Material)
	local drop = -Land.SURFACE_OFFSET
	local radius = Fishing.POND.SIZE / 2 - 0.5
	Workspace.Terrain:FillCylinder(ground * CFrame.new(0, (top + bottom) / 2 + drop, 0), top - bottom, radius, material)
end

local function digPond(origin: BasePart, cx: number, cz: number)
	local ground = pondCFrame(origin, cx, cz)
	fillRound(ground, 0, -DEPTH, Enum.Material.Air)
	fillRound(ground, Map.RIVER.WATER_Y + Land.SURFACE_OFFSET, -DEPTH, Enum.Material.Water)
	fillRound(ground, -DEPTH, -DEPTH - BED, Enum.Material.Sand)
end

-- The visible ground height just OUTSIDE the pond (ray down at 8 points on a ring around it, median). The pond is refilled to
-- exactly this height, so the spot never ends up as a hill or a hole. Falls back to the default top if nothing is hit.
local function surroundingTop(origin: BasePart, cx: number, cz: number): number
	local ground = pondCFrame(origin, cx, cz)
	local heights = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	for index = 0, 7 do
		local angle = index / 8 * math.pi * 2
		local at = ground * CFrame.new(math.cos(angle) * 13, 60, math.sin(angle) * 13)
		local hit = Workspace:Raycast(at.Position, Vector3.new(0, -120, 0), params)
		if hit then
			table.insert(heights, hit.Position.Y)
		end
	end
	if #heights == 0 then
		return origin.Position.Y
	end
	table.sort(heights)
	return heights[math.ceil(#heights / 2)]
end

-- Back to the ground around it, INSIDE the round pond only: clear everything above the pit, then put sand and the green
-- top layer back at the same height as the ground around the pond (the visible top = block top + SURFACE_OFFSET).
-- Back to the ground, in two passes like the Terrain tool's Flatten: (1) refill the round pit with sand and the green top
-- layer, (2) flatten: cut away everything above the level of the ground around the pond, and fill any hole below it, over the
-- whole 16 x 16 square. The level comes from a ray down outside the pond, so the spot ends level with its surroundings.
local function fillPond(origin: BasePart, cx: number, cz: number)
	local ground = pondCFrame(origin, cx, cz)
	local level = surroundingTop(origin, cx, cz) -- world Y of the ground around the pond
	local blockTop = level - ground.Position.Y - Land.SURFACE_OFFSET -- block top, relative to the ground (fillRound adds the drop)
	-- pass 1: refill the round pit
	fillRound(ground, blockTop + 8, -DEPTH - BED - 1, Enum.Material.Air)
	fillRound(ground, blockTop, -DEPTH - BED, Enum.Material.Sand)
	fillRound(ground, blockTop, blockTop - 4, Enum.Material.LeafyGrass)
	-- pass 2: flatten the square to the level of the ground around it
	-- voxel level: the rendered surface sits SURFACE_OFFSET above the voxels it is made of (see fillRound), so the flatten
	-- works on the voxel level level - SURFACE_OFFSET; that is what makes the visible top equal to the ground around it
	local voxelLevel = level - Land.SURFACE_OFFSET
	local side = Fishing.POND.SIZE
	local rotation = ground.Rotation
	Workspace.Terrain:FillBlock(CFrame.new(ground.Position.X, voxelLevel - 3, ground.Position.Z) * rotation, Vector3.new(side, 6, side), Enum.Material.LeafyGrass)
	-- the air starts exactly at the level (terrain voxels are 4 studs: a block starting at +0.5 left the 0..4 voxel half grass = a 2-stud dome)
	Workspace.Terrain:FillBlock(CFrame.new(ground.Position.X, voxelLevel + 4, ground.Position.Z) * rotation, Vector3.new(side, 8, side), Enum.Material.Air)
end

-- Parts ------------------------------------------------------------------------------------

local function getFolder(plot: Model): Folder
	local existing = plot:FindFirstChild("Ponds")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Ponds"
	folder.Parent = plot
	return folder
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false -- decoration never traps a swimmer or blocks the way
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The rock assets the map already has (Workspace.Map.Nature: every model named "Batu" -- they differ in shape and colour).
local function rockTemplates(): { Model }
	local nature = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Nature")
	local list = {}
	if nature then
		for _, child in nature:GetChildren() do
			if child:IsA("Model") and child.Name == "Batu" then
				table.insert(list, child)
			end
		end
	end
	return list
end

-- One stone: a clone of a random map rock, keeping its own proportions (some are already flat), uniformly scaled so its
-- widest side is `size` studs, and set down so its lowest point rests on the ground at `cf` (no floating stones).
-- One stone, ALWAYS flat: a clone of a random map rock, scaled so its width is `size` studs and its height is 35 % of that
-- (every part is squashed in Y around the rock's pivot, so the shape stays a flat slab). It rests on the ground at `cf`, lifted
-- by `lift` studs: a small different lift per stone stops neighbouring flat tops from z-fighting.
-- One stone, ALWAYS flat, standing on the ground. A clone of a random map rock is scaled so its widest horizontal side is
-- `size` studs, then squashed in Y (every part, around the rock's pivot) so its height is 35 % of its width. It is turned to
-- `cf`'s yaw, then lowered until its lowest point touches the ground at `cf` plus `lift` (a small per-stone lift so flat
-- tops never sit on the same plane: no z-fighting).
local function placeRock(templates: { Model }, parent: Instance, cf: CFrame, size: number, lift: number)
	if #templates == 0 then
		local height = size * 0.35
		part(parent, "Stone", Vector3.new(size, height, size), cf * CFrame.new(0, height / 2 + lift, 0), STONE_COLOR, Enum.Material.Slate)
		return
	end
	local rock = templates[math.random(1, #templates)]:Clone()
	for _, d in rock:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	-- 1) width
	local _, box = rock:GetBoundingBox()
	rock:ScaleTo(rock:GetScale() * size / math.max(box.X, box.Z, 0.01))
	-- 2) flatten around the pivot
	local pivot = rock:GetPivot()
	local _, now = rock:GetBoundingBox()
	local squash = (size * 0.35) / math.max(now.Y, 0.01)
	for _, d in rock:GetDescendants() do
		if d:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(d.CFrame)
			d.Size = Vector3.new(d.Size.X, d.Size.Y * squash, d.Size.Z)
			d.CFrame = pivot * CFrame.new(rel.Position.X, rel.Position.Y * squash, rel.Position.Z) * rel.Rotation
		end
	end
	-- 3) turn and seat on the ground: put it at the spot with the right yaw, then move it so its lowest point is on the ground
	local _, yaw, _ = cf:ToEulerAnglesYXZ()
	rock:PivotTo(CFrame.new(cf.Position.X, 0, cf.Position.Z) * CFrame.Angles(0, yaw, 0))
	local boundsCFrame, boundsSize = rock:GetBoundingBox()
	local lowest = boundsCFrame.Position.Y - boundsSize.Y / 2
	rock:PivotTo(rock:GetPivot() + Vector3.new(0, cf.Position.Y + lift - lowest, 0))
	rock.Name = "Stone"
	rock.Parent = parent
end

-- Look per capacity tier: every pond is round with a rock rim and two lily pads (1); tier 2 adds the lamp posts.
local function buildLook(plot: Model, entry: Types.PondEntry, tier: number)
	local origin = plot.PrimaryPart
	if not origin then
		return
	end
	local folder = getFolder(plot)
	local name = `Look{entry.uid}`
	local old = folder:FindFirstChild(name)
	if old then
		old:Destroy()
	end

	local look = Instance.new("Folder")
	look.Name = name
	local ground = pondCFrame(origin, entry.cx, entry.cz)
	local half = Fishing.POND.SIZE / 2

	-- Stone rim: a ring of the rocks from the map (Map.Nature "Batu" models), round the water, each a different size and turn.
	local rim = half + 1.2
	local templates = rockTemplates()
	-- A tight ring of flat stones touching each other: about one stone per 2.2 studs of arc, each a little wider than that
	-- spacing, so neighbours overlap at the edges. Each stone gets its own tiny lift (cycling 0.02 / 0.05 / 0.08 studs) so two
	-- flat tops never sit on exactly the same plane (no z-fighting).
	local count = 22
	local circumference = 2 * math.pi * rim
	for index = 1, count do
		local angle = (index - 1) / count * math.pi * 2
		local at = ground * CFrame.new(math.cos(angle) * rim, 0, math.sin(angle) * rim)
		local size = circumference / count + 0.6 + math.random() * 0.4 -- a bit wider than the arc: they touch
		local lift = 0.02 + (index % 3) * 0.03
		placeRock(templates, look, at * CFrame.Angles(0, angle + math.pi / 2 + (math.random() - 0.5) * 0.3, 0), size, lift)
	end
	-- Two lily pads of different sizes on the surface (a small pond decoration, not a crop).
	local pads = { { x = 2.2, z = -1.8, d = 2.2 }, { x = -2.6, z = 1.6, d = 3.4 } }
	for _, pad in pads do
		local lily = part(
			look,
			"Lily",
			Vector3.new(0.2, pad.d, pad.d),
			ground * CFrame.new(pad.x, Map.RIVER.WATER_Y + 0.15, pad.z) * CFrame.Angles(0, 0, math.pi / 2),
			LILY_COLOR,
			Enum.Material.Grass
		)
		lily.Shape = Enum.PartType.Cylinder
	end
	if tier >= 2 then
		-- Lamp posts at the four corners (switched on at night like the other lamps).
		local corner = half + 3
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local base = ground * CFrame.new(sx * corner, 0, sz * corner)
				part(look, "Pole", Vector3.new(0.5, 5, 0.5), base * CFrame.new(0, 2.5, 0), POST_COLOR, Enum.Material.Wood)
				local bulb = part(look, "Lamp", Vector3.new(1.1, 1.1, 1.1), base * CFrame.new(0, 5.3, 0), Color3.fromRGB(236, 206, 150), Enum.Material.SmoothPlastic)
				bulb.Shape = Enum.PartType.Ball
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 214, 160)
				light.Brightness = 1
				light.Range = 14
				light.Shadows = false
				light.Enabled = false
				light.Parent = bulb
				CollectionService:AddTag(bulb, "DecorLight")
			end
		end
	end

	look.Parent = folder
end

-- The invisible spot over the water that carries the fishing / collect prompts (FishService).
local function buildSpot(player: Player, plot: Model, entry: Types.PondEntry)
	local origin = plot.PrimaryPart
	if not origin then
		return
	end
	local spot = Instance.new("Part")
	spot.Name = `Pond{entry.uid}`
	spot.Anchored = true
	spot.CanCollide = false
	spot.CanQuery = true
	spot.Transparency = 1
	spot.Size = Vector3.new(Fishing.POND.SIZE, 1, Fishing.POND.SIZE)
	spot.CFrame = pondCFrame(origin, entry.cx, entry.cz) * CFrame.new(0, Map.RIVER.WATER_Y, 0)
	spot:SetAttribute("Cx", entry.cx)
	spot:SetAttribute("Cz", entry.cz)
	spot.Parent = getFolder(plot)
	FishService.SetupPond(player, spot, entry)
end

local function buildOne(player: Player, plot: Model, data: Types.PlayerData, entry: Types.PondEntry)
	local origin = plot.PrimaryPart
	if not origin then
		return
	end
	digPond(origin, entry.cx, entry.cz)
	buildSpot(player, plot, entry)
	buildLook(plot, entry, Upgrades.tier(data, "pond"))
end

-- Save lama (sebelum P2-2-fix) belum punya tier/kakek: tier default Tanah, kakek TIDAK
-- di-auto-grant (hanya MQ4/Bundel P2-7 yang memberi, via kakekUnlocked + kolam pertama).
local function normalizeEntry(_list: { Types.PondEntry }, entry: Types.PondEntry)
	if typeof(entry.tier) ~= "string" or not Ranch.byTier[entry.tier] then
		entry.tier = "tanah"
	end
	if entry.kakek ~= true then
		entry.kakek = false
	end
end

-- Rebuilds every pond from saved data (on join).
local function buildAll(player: Player, plot: Model)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for _, entry in data.pond.list do
		normalizeEntry(data.pond.list, entry)
		buildOne(player, plot, data, entry)
	end
end

-- Puts the terrain of every pond on a plot back to grass and removes the parts (plot released).
local function clearPlot(plot: Model)
	local origin = plot.PrimaryPart
	local folder = plot:FindFirstChild("Ponds")
	if not folder then
		return
	end
	for _, child in folder:GetChildren() do
		local cx, cz = child:GetAttribute("Cx"), child:GetAttribute("Cz")
		if origin and typeof(cx) == "number" and typeof(cz) == "number" then
			fillPond(origin, cx, cz)
		end
	end
	folder:Destroy()
end

-- Validation helpers --------------------------------------------------------------------

local function isCell(value: any): boolean
	return typeof(value) == "number" and value % 1 == 0 and math.abs(value) <= MAX_CELL
end

local function characterDistance(player: Player, position: Vector3): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return (root.Position - position).Magnitude
	end
	return nil
end

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

-- Price of the NEXT pond for this player.
function PondService.NextPrice(data: Types.PlayerData): number
	return Fishing.POND.PRICES[math.min(#data.pond.list + 1, #Fishing.POND.PRICES)]
end

-- Koin + bahan: cek bahan dulu, baru potong koin. Gagal aman tanpa refund.
local function payBuild(player: Player, koin: number, mats: { { id: string, count: number } }, reason: string): boolean
	for _, mat in mats do
		if InventoryService.Count(player, mat.id) < mat.count then
			return false
		end
	end
	if koin > 0 and not EconomyService.TrySpend(player, "koin", koin, reason) then
		return false
	end
	for _, mat in mats do
		InventoryService.Remove(player, mat.id, mat.count)
	end
	return true
end

local function findPond(data: Types.PlayerData, uid: any): Types.PondEntry?
	if typeof(uid) ~= "number" then
		return nil
	end
	for _, entry in data.pond.list do
		if entry.uid == uid then
			return entry
		end
	end
	return nil
end

-- Requests ----------------------------------------------------------------------------

local function onBuild(player: Player, cx: any, cz: any)
	if not isCell(cx) or not isCell(cz) then
		return
	end
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	if not data or not plot or not origin then
		return
	end
	if data.guide.kolamUnlocked ~= true then
		Net.Fire("Notify", player, "pond.tut_locked")
		return
	end
	-- Kolam Kakek keluar dari tutorial (P2-2, Bab 7.2/14.2/14.6): bangun kolam apa pun butuh
	-- Kolam Kakek pulih (MQ4/Bundel P2-7 set kakekUnlocked; Studio: !kakek). Kolam 2-4 otomatis
	-- ikut kegate karena kolam pertama = Kolam Kakek.
	if data.pond.kakekUnlocked ~= true then
		Net.Fire("Notify", player, "pond.locked")
		return
	end
	local unlock = Fishing.LOCATIONS.kolam.unlockLevel
	if data.level < unlock then
		Net.Fire("Notify", player, "fish.locked", { level = unlock })
		return
	end
	if #data.pond.list >= Fishing.POND.MAX_PONDS then
		Net.Fire("Notify", player, "pond.max", { max = Fishing.POND.MAX_PONDS })
		return
	end
	local distance = characterDistance(player, pondCFrame(origin, cx, cz).Position)
	if not distance or distance > Farm.TILL_DISTANCE + Fishing.POND.SIZE then
		Net.Fire("Notify", player, "farm.till_far")
		return
	end
	if not Land.canPond(cx, cz, data.farm.tiles, data.pond.list, decorRects(data), data.land.chunks) then
		Net.Fire("Notify", player, "pond.invalid")
		return
	end

	-- Kolam pertama setelah unlock = gratis + Kolam Kakek (P2-7 memberi unlock-nya). Kolam 2-4
	-- = harga tier Tanah (Bab 7.2: Lv 3, 1000 Koin + 20 Batu). Gate tutorial (kolamUnlocked) tidak berubah.
	-- Token gratis Bundel Empang (Bab 14.6): "spot mancing pribadi" = 1 kolam gratis.
	local first = #data.pond.list == 0
	local price, mats = 0, {}
	if not first and (data.pond.freeBuilds or 0) > 0 then
		data.pond.freeBuilds -= 1
	elseif not first then
		local tanah = Ranch.byTier.tanah
		if data.level < tanah.unlockLevel then
			Net.Fire("Notify", player, "fish.locked", { level = tanah.unlockLevel })
			return
		end
		price, mats = tanah.koin, tanah.mats
	end
	local affordKoin = price <= 0 or EconomyService.CanAfford(player, "koin", price)
	if not payBuild(player, price, mats, `pond:{#data.pond.list + 1}`) then
		Net.Fire("Notify", player, if affordKoin then "ranch.no_mats" else "notify.not_enough", { currency = "currency.koin" })
		return
	end

	local entry: Types.PondEntry = {
		uid = data.pond.nextUid,
		cx = cx,
		cz = cz,
		paid = price,
		lastCollect = os.time(),
		tier = "tanah",
		kakek = first,
		breed = nil,
	}
	data.pond.nextUid += 1
	table.insert(data.pond.list, entry)
	buildOne(player, plot, data, entry)
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.built")
	QuestService.Report(player, "pond_built")
end

-- Breeding (Bab 7.2): 2 ikan sejenis non-Legenda + Pakan Ikan 20 Koin -> 1 anak (@M).
-- Durasi = tier kolam x Kakek 0.9 x Mood 0.9. Anak = 100% harga Sedang (otomatis via Items.info).
local function speciesCount(player: Player, fishId: string): number
	local total = 0
	for _, size in FishConfig.SIZES do
		total += InventoryService.Count(player, FishService.ItemId(fishId, size.id))
	end
	return total
end

local function takeSpecies(player: Player, fishId: string, need: number): boolean
	local left = need
	for _, size in FishConfig.SIZES do -- S/M/L/Jumbo: yang kecil dipakai dulu
		if left <= 0 then
			break
		end
		local id = FishService.ItemId(fishId, size.id)
		local take = math.min(left, InventoryService.Count(player, id))
		if take > 0 then
			InventoryService.Remove(player, id, take)
			left -= take
		end
	end
	return left == 0
end

local function onBreedStart(player: Player, pondUid: any, fishId: any)
	if typeof(fishId) ~= "string" then
		return
	end
	local fish = FishConfig.byId[fishId]
	local data = DataService.Get(player)
	if not fish or not data then
		return
	end
	if fish.rarity == "L" then
		Net.Fire("Notify", player, "pond.breed_legend")
		return
	end
	local entry = findPond(data, pondUid)
	if not entry then
		return
	end
	if entry.breed then
		Net.Fire("Notify", player, "pond.breed_busy")
		return
	end
	if speciesCount(player, fishId) < 2 then
		Net.Fire("Notify", player, "pond.breed_need2")
		return
	end
	if not EconomyService.TrySpend(player, "koin", Ranch.BREED_FEED_KOIN, `pond:{entry.uid}:breed`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
		return
	end
	if not takeSpecies(player, fishId, 2) then
		return
	end
	local tierDef = Ranch.byTier[entry.tier or "tanah"] or Ranch.byTier.tanah
	local mult = (if entry.kakek then Ranch.KAKEK_MULT else 1) * (if RanchService.MoodActive(data) then Ranch.MOOD_BREED_MULT else 1)
	local now = os.time()
	entry.breed = { fish = fishId, startedAt = now, endsAt = now + math.floor(tierDef.hours * 3600 * mult) }
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.breed_started", { item = `fish.{fishId}` })
end

local function collectBaby(player: Player, entry: Types.PondEntry)
	local breed = entry.breed
	if not breed then
		return
	end
	if not InventoryService.Add(player, FishService.ItemId(breed.fish, "M"), 1) then
		return
	end
	entry.breed = nil
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.breed_done", { item = `fish.{breed.fish}` })
end

local function onBreedCollect(player: Player, pondUid: any)
	local data = DataService.Get(player)
	local entry = data and findPond(data, pondUid)
	if not data or not entry or not entry.breed then
		return
	end
	if os.time() < entry.breed.endsAt then
		Net.Fire("Notify", player, "pond.breed_wait", { s = entry.breed.endsAt - os.time() })
		return
	end
	collectBaby(player, entry)
end

-- Instant Kolam pakai Bunga (Bab 18.5): 1 Bunga/10 mnt sisa, max 30. Bubu tidak bisa instant
-- (tidak ada sistem Bubu di src/). Bunga tidak bisa beli bahan/hewan (Bab 18.1).
local function onBreedInstant(player: Player, pondUid: any)
	local data = DataService.Get(player)
	local entry = data and findPond(data, pondUid)
	if not data or not entry or not entry.breed then
		return
	end
	local remaining = entry.breed.endsAt - os.time()
	if remaining <= 0 then
		collectBaby(player, entry) -- sudah matang: langsung ambil
		return
	end
	local cost = PondService.InstantCost(remaining)
	if not EconomyService.TrySpend(player, "bunga", cost, `pond:{entry.uid}:instant`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.bunga" })
		return
	end
	entry.breed.endsAt = os.time()
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.breed_instant", { n = cost })
end

-- Upgrade tier kolam berurutan (Tanah -> Semen -> Keramik), bayar harga tier target.
local TIER_ORDER = { tanah = 1, semen = 2, keramik = 3 }

local function onPondTier(player: Player, pondUid: any, tierId: any)
	if typeof(tierId) ~= "string" then
		return
	end
	local target = Ranch.byTier[tierId]
	local data = DataService.Get(player)
	local entry = data and findPond(data, pondUid)
	if not target or not data or not entry then
		return
	end
	if (TIER_ORDER[entry.tier or "tanah"] or 1) + 1 ~= TIER_ORDER[tierId] then
		return -- harus berurutan, tidak bisa loncat
	end
	if data.level < target.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = target.unlockLevel })
		return
	end
	local affordKoin = EconomyService.CanAfford(player, "koin", target.koin)
	if not payBuild(player, target.koin, target.mats, `pond:{entry.uid}:{tierId}`) then
		Net.Fire("Notify", player, if affordKoin then "ranch.no_mats" else "notify.not_enough", { currency = "currency.koin" })
		return
	end
	entry.tier = tierId
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.tier_up", { tier = `pond.tier.{tierId}` })
end

-- Anyone swimming in the pit would be buried by the sand: lift them onto the bank first.
local function liftSwimmers(origin: BasePart, entry: Types.PondEntry)
	local rect = Land.pondRect(entry.cx, entry.cz)
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local localPos = origin.CFrame:PointToObjectSpace(root.Position)
			if localPos.X > rect.minX - 2 and localPos.X < rect.maxX + 2 and localPos.Z > rect.minZ - 2 and localPos.Z < rect.maxZ + 2
				and localPos.Y < origin.Size.Y / 2 + 6 then
				root.CFrame = root.CFrame + Vector3.new(0, origin.Size.Y / 2 + 8 - localPos.Y, 0)
			end
		end
	end
end

local function onRemove(player: Player, uid: any)
	if typeof(uid) ~= "number" then
		return
	end
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	if not data or not plot or not origin then
		return
	end
	local entry, index
	for i, candidate in data.pond.list do
		if candidate.uid == uid then
			entry, index = candidate, i
			break
		end
	end
	if not entry or not index then
		return
	end
	local distance = characterDistance(player, pondCFrame(origin, entry.cx, entry.cz).Position)
	if not distance or distance > Farm.TILL_DISTANCE + Fishing.POND.SIZE then
		Net.Fire("Notify", player, "farm.till_far")
		return
	end

	table.remove(data.pond.list, index)
	liftSwimmers(origin, entry)
	local folder = getFolder(plot)
	for _, name in { `Pond{uid}`, `Look{uid}` } do
		local child = folder:FindFirstChild(name)
		if child then
			child:Destroy()
		end
	end
	fillPond(origin, entry.cx, entry.cz)

	local refund = math.floor(entry.paid * Fishing.POND.REFUND_RATE)
	if refund > 0 then
		EconomyService.Add(player, "koin", refund, "pond:refund")
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.removed", { n = refund })
end

-- A capacity upgrade changed the tier: refresh the look of every pond.
function PondService.RefreshLook(player: Player)
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	if not data or not plot then
		return
	end
	for _, entry in data.pond.list do
		buildLook(plot, entry, Upgrades.tier(data, "pond"))
	end
end

function PondService.Init()
	PlotService.Assigned:Connect(function(player: Player, plot: Model)
		clearPlot(plot) -- leftovers of a previous owner
		buildAll(player, plot)
	end)
	PlotService.Released:Connect(function(_player: Player, plot: Model)
		clearPlot(plot) -- the next owner of this plot must not inherit the water
	end)
end

-- Instant Kolam (Bab 18.5 v7.3): instant kolam pakai Bunga. 1 Bunga per 10 menit sisa, max 30 Bunga.
-- PondEntry belum ada timestamp breeding; helper ini dipakai saat breeding di-code.
function PondService.InstantCost(remainingSeconds: number): number
	if remainingSeconds <= 0 then
		return 0
	end
	return math.min(Monetization.INSTANT_KOLAM_MAX_BUNGA, math.ceil(remainingSeconds / 600) * Monetization.INSTANT_KOLAM_BUNGA_PER_600S)
end

function PondService.Start()
	Net.On("PondBuild", onBuild, RATE)
	Net.On("PondRemove", onRemove, RATE)
	Net.On("BreedStart", onBreedStart, RATE)
	Net.On("BreedCollect", onBreedCollect, RATE)
	Net.On("BreedInstant", onBreedInstant, RATE)
	Net.On("PondTier", onPondTier, RATE)
end

return PondService
