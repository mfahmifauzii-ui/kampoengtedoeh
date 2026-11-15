--!strict
-- Player-built ponds (kolam). Replaces the old fixed plot pond.
--   * The water is TERRAIN (a pit dug 8 studs deep, filled with Water, sand bed under it), exactly like the river.
--     The only Parts are an invisible fishing/collect spot per pond and a few decoration parts per upgrade tier.
--   * Ponds are 16 x 16 studs = 2 x 2 farm-tile cells, saved in data.pond.list and rebuilt on join.
--   * The first pond is free; the next ones cost Fishing.POND.PRICES. Removing one refunds REFUND_RATE of what
--     was paid. Capacity upgrades (Upgrades.tier "pond") apply to every pond and change how they look.
--   * Fishing/collecting is FishService (FishService.SetupPond); this file only digs, fills and decorates.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Map = require(ReplicatedStorage.Shared.Config.Map)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
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

local function digPond(origin: BasePart, cx: number, cz: number)
	local ground = pondCFrame(origin, cx, cz)
	fill(ground, 0, -DEPTH, Enum.Material.Air)
	fill(ground, Map.RIVER.WATER_Y + Land.SURFACE_OFFSET, -DEPTH, Enum.Material.Water)
	fill(ground, -DEPTH, -DEPTH - BED, Enum.Material.Sand)
end

-- Back to what MapService built: sand ground with the green top layer.
local function fillPond(origin: BasePart, cx: number, cz: number)
	local ground = pondCFrame(origin, cx, cz)
	fill(ground, 0, -Map.GRASS_DEPTH, Enum.Material.Sand)
	fill(ground, 0, -4, Enum.Material.LeafyGrass)
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

-- Look per capacity tier: 0 = plain pit, 1 = stone rim, 2 = stone rim + lily pads + lamp posts.
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
	if tier <= 0 then
		return
	end

	local look = Instance.new("Folder")
	look.Name = name
	local ground = pondCFrame(origin, entry.cx, entry.cz)
	local half = Fishing.POND.SIZE / 2

	-- Stone rim just outside the water.
	local ring = half + 1.5
	for t = -half, half, 4 do
		part(look, "Stone", Vector3.new(3.4, 1.2, 3.4), ground * CFrame.new(t, 0.6, ring), STONE_COLOR, Enum.Material.Slate)
		part(look, "Stone", Vector3.new(3.4, 1.2, 3.4), ground * CFrame.new(t, 0.6, -ring), STONE_COLOR, Enum.Material.Slate)
		if math.abs(t) < half then
			part(look, "Stone", Vector3.new(3.4, 1.2, 3.4), ground * CFrame.new(ring, 0.6, t), STONE_COLOR, Enum.Material.Slate)
			part(look, "Stone", Vector3.new(3.4, 1.2, 3.4), ground * CFrame.new(-ring, 0.6, t), STONE_COLOR, Enum.Material.Slate)
		end
	end

	if tier >= 2 then
		-- Lily pads floating on the surface (fixed layout, same for every pond).
		local pads = { { -4, -3 }, { 3, -5 }, { 5, 2 }, { -2, 4 }, { 0, 0 } }
		for _, pad in pads do
			local lily = part(
				look,
				"Lily",
				Vector3.new(0.2, 2.6, 2.6),
				ground * CFrame.new(pad[1], Map.RIVER.WATER_Y + 0.15, pad[2]) * CFrame.Angles(0, 0, math.pi / 2),
				LILY_COLOR,
				Enum.Material.Grass
			)
			lily.Shape = Enum.PartType.Cylinder
		end
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

-- Rebuilds every pond from saved data (on join).
local function buildAll(player: Player, plot: Model)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for _, entry in data.pond.list do
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
	local rects: { Land.Rect } = {}
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

	local price = PondService.NextPrice(data)
	if price > 0 and not EconomyService.TrySpend(player, "koin", price, `pond:{#data.pond.list + 1}`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
		return
	end

	local entry: Types.PondEntry = { uid = data.pond.nextUid, cx = cx, cz = cz, paid = price, lastCollect = os.time() }
	data.pond.nextUid += 1
	table.insert(data.pond.list, entry)
	buildOne(player, plot, data, entry)
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pond.built")
	QuestService.Report(player, "pond_built")
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

function PondService.Start()
	Net.On("PondBuild", onBuild, RATE)
	Net.On("PondRemove", onRemove, RATE)
end

return PondService
