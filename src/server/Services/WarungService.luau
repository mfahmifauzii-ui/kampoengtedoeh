--!strict
-- Warung Player (docs/01_GDD_Kampoeng_Tedoeh_v8.1.md Bab 9.3, LOCKED): 1 slot pajang di lahan sendiri (Lv 6,
-- gratis). NPC pengunjung beli 1 olahan tiap 5-10 menit random. Harga = base x Kualitas Olahan.
-- TANPA Reputasi Warung. Offline tetap jalan, max 5 penjualan per login. Hanya olahan
-- (bukan mentah). Bukan pasar antar-player (tanpa tawar-menawar).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local FeatureGate = require(script.Parent.FeatureGate)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local QuestService = require(script.Parent.QuestService)

local RATE = { rate = 4, burst = 8 }

local WarungService = {}
local random = Random.new()

local WOOD = Color3.fromRGB(150, 110, 70)
local STONE = Color3.fromRGB(150, 146, 138)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function getFolder(plot: Model): Folder
	local existing = plot:FindFirstChild("Warung")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Warung"
	folder.Parent = plot
	return folder
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

local function findSpot(data: Types.PlayerData): (number?, number?)
	local existing = Land.ranchRects(Dapur.buildings(data.ranch.kandang, data.dapur.spot, data.warung.spot), Dapur.BUILDING_SIZES)
	local half = Land.REGION_HALF // Land.TILE
	for cz = -half, half do
		for cx = -half, half do
			if Land.canRanch(cx, cz, Dapur.WARUNG_SIZE[1], Dapur.WARUNG_SIZE[2], data.farm.tiles, data.pond.list, existing, decorRects(data), data.land.chunks) then
				return cx, cz
			end
		end
	end
	return nil, nil
end

local function buildLook(plot: Model, entry: { cx: number, cz: number })
	local origin = plot.PrimaryPart
	if not origin then
		return
	end
	local folder = getFolder(plot)
	local old = folder:FindFirstChild("Stall")
	if old then
		old:Destroy()
	end
	local size = Dapur.WARUNG_SIZE
	local rect = Land.ranchRect(entry.cx, entry.cz, size[1], size[2])
	local topY = origin.Position.Y + origin.Size.Y / 2
	local center = origin.CFrame * Vector3.new((rect.minX + rect.maxX) / 2, 0, (rect.minZ + rect.maxZ) / 2)
	local look = Instance.new("Folder")
	look.Name = "Stall"
	part(look, "Floor", Vector3.new(16, 0.5, 16), CFrame.new(center.X, topY + 0.25, center.Z), STONE)
	part(look, "Counter", Vector3.new(6, 1.6, 2), CFrame.new(center.X, topY + 0.8, center.Z), WOOD)
	part(look, "Sign", Vector3.new(4, 1, 0.3), CFrame.new(center.X, topY + 3.6, center.Z + 6), WOOD)
	look.Parent = folder
end

local function buildAll(player: Player, plot: Model)
	local data = DataService.Get(player)
	if data and data.warung.spot then
		buildLook(plot, data.warung.spot)
	end
end

local function clearPlot(plot: Model)
	local folder = plot:FindFirstChild("Warung")
	if folder then
		folder:Destroy()
	end
end

local function nearPlot(player: Player): boolean
	local plot = PlotService.GetPlot(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not plot.PrimaryPart or not root or not root:IsA("BasePart") then
		return false
	end
	return (plot:GetPivot().Position - root.Position).Magnitude <= 60
end

local function nextVisit(): number
	return os.time() + random:NextInteger(Dapur.WARUNG_VISIT_MIN, Dapur.WARUNG_VISIT_MAX)
end

-- Jual 1 unit pajangan ke NPC. Harga = base x Kualitas (Items.info, Bab 9.1).
local function sellOne(player: Player, data: Types.PlayerData): boolean
	local slot = data.warung.item
	if not slot or slot.count <= 0 then
		return false
	end
	local info = Items.info(slot.id)
	if not info or not info.sellPrice then
		data.warung.item = nil
		return false
	end
	slot.count -= 1
	if slot.count <= 0 then
		data.warung.item = nil
	end
	data.warung.nextVisit = nextVisit()
	EconomyService.Add(player, "koin", info.sellPrice, `warung:{slot.id}`)
	return true
end

-- Majukan penjualan sampai `now`, max `maxSales` transaksi. Kembalikan jumlah terjual.
local function processSales(player: Player, data: Types.PlayerData, now: number, maxSales: number): number
	local sold = 0
	while sold < maxSales and data.warung.item and now >= data.warung.nextVisit do
		if not sellOne(player, data) then
			break
		end
		sold += 1
	end
	return sold
end

local function onBuild(player: Player)
	if not FeatureGate.Check(player, "warung") then return end
	local data = DataService.Get(player)
	if not data or data.warung.spot then
		return
	end
	if not nearPlot(player) then
		return
	end
	if data.level < Dapur.WARUNG_UNLOCK then
		Net.Fire("Notify", player, "fish.locked", { level = Dapur.WARUNG_UNLOCK })
		return
	end
	local cx, cz = findSpot(data)
	if cx == nil or cz == nil then
		Net.Fire("Notify", player, "ranch.no_space")
		return
	end
	data.warung.spot = { cx = cx :: number, cz = cz :: number }
	data.warung.nextVisit = nextVisit()
	local plot = PlotService.GetPlot(player)
	if plot then
		buildLook(plot, data.warung.spot)
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "warung.built")
	QuestService.Report(player, "warung_place") -- Quest M7 langkah 1: Pasang Warung
end

-- Pajang 1 jenis olahan (semua unit yang dipunyai). Hanya olahan, bukan mentah (Bab 9.3).
local function onDisplay(player: Player, itemId: any)
	if not FeatureGate.Check(player, "warung") then return end
	if typeof(itemId) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	if not data or not data.warung.spot then
		Net.Fire("Notify", player, "warung.need_build")
		return
	end
	if not nearPlot(player) then
		return
	end
	local info = Items.info(itemId)
	if not info or info.kind ~= "olahan" then
		Net.Fire("Notify", player, "warung.only_olahan")
		return
	end
	if data.warung.item then
		Net.Fire("Notify", player, "warung.full")
		return
	end
	local count = InventoryService.Count(player, itemId)
	if count <= 0 or not InventoryService.Remove(player, itemId, count) then
		return
	end
	data.warung.item = { id = itemId, count = count }
	data.warung.nextVisit = nextVisit()
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "warung.displayed", { n = count, item = itemId })
end

-- Ambil kembali pajangan ke tas.
local function onTake(player: Player)
	local data = DataService.Get(player)
	if not data or not data.warung.item then
		return
	end
	local slot = data.warung.item
	data.warung.item = nil
	if not InventoryService.Add(player, slot.id, slot.count) then
		data.warung.item = slot -- tas penuh (seharusnya tak terjadi): kembalikan
		return
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "warung.taken", { n = slot.count, item = slot.id })
end

function WarungService.Init()
	PlotService.Assigned:Connect(function(player: Player, plot: Model)
		clearPlot(plot) -- sisa pemilik lama
		buildAll(player, plot)
	end)
	PlotService.Released:Connect(function(_player: Player, plot: Model)
		clearPlot(plot)
	end)
	DataService.Loaded:Connect(function(player: Player, data: Types.PlayerData)
		-- Offline: penjualan tetap jalan, max 5 per login (Bab 9.3, anti-AFK).
		data.warung.soldLogin = 0
		local sold = processSales(player, data, os.time(), Dapur.WARUNG_OFFLINE_MAX)
		data.warung.soldLogin = sold
		InventoryService.Sync(player)
		if sold > 0 then
			QuestService.Report(player, "warung_sale", sold) -- MQ9 + Side Warung Laris
			Net.Fire("Notify", player, "warung.offline", { n = sold })
		end
	end)
end

function WarungService.Start()
	Net.On("WarungBuild", function(player: Player)
		onBuild(player)
	end, RATE)
	Net.On("WarungDisplay", onDisplay, RATE)
	Net.On("WarungTake", function(player: Player)
		onTake(player)
	end, RATE)

	-- Kunjungan NPC online: tiap 60 dtk cek, jual bila window-nya lewat (tanpa cap).
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data and data.warung.item then
					local sold = processSales(player, data, os.time(), 999)
					if sold > 0 then
						QuestService.Report(player, "warung_sale", sold) -- MQ9 + Side Warung Laris
						InventoryService.Sync(player)
						Net.Fire("Notify", player, "warung.sold", { n = sold })
					end
				end
			end
		end
	end)
end

return WarungService
