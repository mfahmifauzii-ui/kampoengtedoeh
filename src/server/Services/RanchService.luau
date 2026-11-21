--!strict
-- Ternak (Kampoeng_Tedoeh_v7.3 Bab 7.1, LOCKED): satu kandang per jenis hewan, beli hewan,
-- isi pakan, produksi jalan walau offline (timestamp), ambil semua, Mood Hujan.
-- Hewan tidak mati/sakit/kabur. Tidak ada daging, tidak ada kasih minum/bar haus.
-- Pakan Jagung (5 Jagung -> 6 jatah, kandang ayam) jalan di sini; resep Dapur penuhnya P2-3.
-- Skill Tempat Pakan Besar (Bab 4.5, P2-4): max jatah = Ranch.FeedMax (3, atau 5 saat skill ada).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectionService = game:GetService("CollectionService")

local Ranch = require(ReplicatedStorage.Shared.Config.Ranch)
local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local Locale = require(ReplicatedStorage.Shared.Locale)
local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local WorldService = require(script.Parent.WorldService)

local RANCH_TAG = "Ranch"
local RATE = { rate = 4, burst = 8 }
local REACH = 18 -- studs dari tengah kandang (server; client tunjukkan tombol dalam 10)

local RanchService = {}

-- State -----------------------------------------------------------------------

local function kandangOf(data: Types.PlayerData, hewanId: string): Types.RanchKandang?
	return data.ranch.kandang[hewanId]
end

-- Majukan produksi 1 ekor sampai `now`. Tiap siklus: 1 jatah -> 1 produk (buffer max).
-- 3 siklus cukup untuk konvergen (feed max 3 habis / prod max 3 penuh).
local function advance(hewan: Ranch.Hewan, animal: Types.RanchAnimal, now: number, cdMult: number)
	local cooldown = hewan.product.minutes * 60 * cdMult
	if cooldown <= 0 or now <= animal.last then
		return
	end
	local elapsed = now - animal.last
	-- 3 siklus cukup untuk konvergen (feed max 3 habis / prod max 3 penuh); last dijepret ke
	-- batas siklus terakhir supaya sekali hitung langsung tuntas (offline lama sekalipun).
	local cycles = math.min(math.floor(elapsed / cooldown), 3)
	animal.last = now - (elapsed % cooldown)
	for _ = 1, cycles do
		if animal.feed > 0 and animal.prod < Ranch.PROD_MAX then
			animal.feed -= 1
			animal.prod += 1
		end
	end
end

function RanchService.AdvanceAll(data: Types.PlayerData, now: number)
	-- Skill Telur Cepat (Bab 4.5, P2-4): Cooldown -2%/lv (waktu x (1 - 0,02 x lv)).
	local cdMult = 1 - 0.02 * (data.skill.telur_cepat or 0)
	for id, entry in data.ranch.kandang do
		local hewan = Ranch.byHewan[id]
		if hewan then
			for _, animal in entry.animals do
				advance(hewan, animal, now, cdMult)
			end
		end
	end
end

-- Mood Hujan (Bab 7.1, LOCKED): 5 menit setelah hujan selesai. Bukan buff (lihat Config/Buffs:
-- Mood Hujan haram kena buff) — jendela waktu di data, dibaca saat ambil/breeding.
function RanchService.MoodActive(data: Types.PlayerData, now: number?): boolean
	return data.ranch.moodUntil > (now or os.time())
end

-- Koin + bahan (pola ShopService.payMats): cek bahan dulu, baru potong koin. Gagal aman.
local function payCost(player: Player, cost: Ranch.Cost, reason: string): boolean
	for _, mat in cost.mats do
		if InventoryService.Count(player, mat.id) < mat.count then
			return false
		end
	end
	if not EconomyService.TrySpend(player, "koin", cost.koin, reason) then
		return false
	end
	for _, mat in cost.mats do
		InventoryService.Remove(player, mat.id, mat.count)
	end
	return true
end

local function characterRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Posisi ----------------------------------------------------------------------

-- Tengah kandang di world (pola PondService.pondCFrame: offset plot-lokal dari origin).
local function kandangCenter(origin: BasePart, entry: Types.RanchKandang, hewanId: string): Vector3
	local size = Ranch.KANDANG_SIZES[hewanId] or { 2, 2 }
	local rect = Land.ranchRect(entry.cx, entry.cz, size[1], size[2])
	return (origin.CFrame * CFrame.new((rect.minX + rect.maxX) / 2, origin.Size.Y / 2, (rect.minZ + rect.maxZ) / 2)).Position
end

local function decorOnlyRects(data: Types.PlayerData): { Land.Rect }
	local rects: { Land.Rect } = {}
	for _, entry in data.decor.placed do
		local rect = DecorGrid.entryRect(entry)
		if rect then
			table.insert(rects, rect)
		end
	end
	return rects
end

-- Cari sel bebas untuk kandang w x d (scan deterministik dari belakang lahan). Nil bila penuh.
local function findSpot(data: Types.PlayerData, w: number, d: number): (number?, number?)
	local existing = Land.ranchRects(Dapur.buildings(data.ranch.kandang, data.dapur.spot, data.warung.spot), Dapur.BUILDING_SIZES)
	local half = Land.REGION_HALF // Land.TILE
	for cz = -half, half do
		for cx = -half, half do
			if Land.canRanch(cx, cz, w, d, data.farm.tiles, data.pond.list, existing, decorOnlyRects(data), data.land.chunks) then
				return cx, cz
			end
		end
	end
	return nil, nil
end

-- Bangunan --------------------------------------------------------------------

local WOOD = Color3.fromRGB(150, 110, 70)
local POST = Color3.fromRGB(96, 72, 52)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.WoodPlanks
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function getFolder(plot: Model): Folder
	local existing = plot:FindFirstChild("Ranch")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Ranch"
	folder.Parent = plot
	return folder
end

-- Kandang: lantai + 4 tiang + 1 spot tak terlihat (2 prompt: Ambil Semua + Kelola).
local function buildOne(plot: Model, player: Player, hewanId: string, entry: Types.RanchKandang)
	local origin = plot.PrimaryPart
	if not origin then
		return
	end
	local folder = getFolder(plot)
	local old = folder:FindFirstChild(`Kandang_{hewanId}`)
	if old then
		old:Destroy()
	end
	local size = Ranch.KANDANG_SIZES[hewanId] or { 2, 2 }
	local rect = Land.ranchRect(entry.cx, entry.cz, size[1], size[2])
	local w, d = rect.maxX - rect.minX, rect.maxZ - rect.minZ
	local topY = origin.Position.Y + origin.Size.Y / 2
	local center = origin.CFrame * Vector3.new((rect.minX + rect.maxX) / 2, 0, (rect.minZ + rect.maxZ) / 2)
	local look = Instance.new("Folder")
	look.Name = `Kandang_{hewanId}`

	part(look, "Floor", Vector3.new(w, 0.5, d), CFrame.new(center.X, topY + 0.25, center.Z), WOOD)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(look, "Post", Vector3.new(0.6, 3, 0.6), CFrame.new(center.X + sx * (w / 2 - 0.3), topY + 1.5, center.Z + sz * (d / 2 - 0.3)), POST)
		end
	end
	-- Papan nama kandang (tiang + papan).
	part(look, "SignPole", Vector3.new(0.4, 2.4, 0.4), CFrame.new(center.X, topY + 1.2, center.Z + d / 2 + 0.6), POST)
	part(look, "Sign", Vector3.new(3, 1, 0.3), CFrame.new(center.X, topY + 2.6, center.Z + d / 2 + 0.6), WOOD)

	local spot = Instance.new("Part")
	spot.Name = "Spot"
	spot.Anchored = true
	spot.CanCollide = false
	spot.CanQuery = false
	spot.Transparency = 1
	spot.Size = Vector3.new(w, 3, d)
	spot.CFrame = CFrame.new(center.X, topY + 1.5, center.Z)
	spot:SetAttribute("Owner", player.UserId)
	spot:SetAttribute("HewanId", hewanId)
	spot.Parent = look

	local ambil = Instance.new("ProximityPrompt")
	ambil.Name = "RanchAmbil"
	ambil.ActionText = Locale.t("prompt.ranch_ambil")
	ambil.HoldDuration = 0
	ambil.MaxActivationDistance = 12
	ambil.RequiresLineOfSight = false
	ambil.Parent = spot
	ambil.Triggered:Connect(function(triggeredBy: Player)
		if triggeredBy == player then -- kandang sendiri; pengunjung ditolak di canTouch juga
			RanchService.Collect(triggeredBy, hewanId)
		end
	end)
	local kelola = Instance.new("ProximityPrompt")
	kelola.Name = "RanchKelola"
	kelola.ActionText = Locale.t("prompt.ranch_kelola")
	kelola.HoldDuration = 0
	kelola.KeyboardKeyCode = Enum.KeyCode.F
	kelola.GamepadKeyCode = Enum.KeyCode.ButtonY
	kelola.MaxActivationDistance = 12
	kelola.RequiresLineOfSight = false
	kelola.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	kelola.Parent = spot
	kelola.Triggered:Connect(function(triggeredBy: Player)
		if triggeredBy == player then
			Net.Fire("RanchOpen", triggeredBy)
		end
	end)

	look.Parent = folder
	CollectionService:AddTag(spot, RANCH_TAG)
end

local function buildAll(player: Player, plot: Model)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for id, entry in data.ranch.kandang do
		if Ranch.byHewan[id] then
			buildOne(plot, player, id, entry)
		end
	end
end

local function clearPlot(plot: Model)
	local folder = plot:FindFirstChild("Ranch")
	if folder then
		folder:Destroy()
	end
end

-- Aksi --------------------------------------------------------------------------

local function nearKandang(player: Player, data: Types.PlayerData, hewanId: string): boolean
	local entry = kandangOf(data, hewanId)
	local plot = PlotService.GetPlot(player)
	local origin = plot and plot.PrimaryPart
	local root = characterRoot(player)
	if not entry or not origin or not root then
		return false
	end
	return (kandangCenter(origin, entry, hewanId) - root.Position).Magnitude <= REACH
end

-- Semua aksi ternak butuh lahan sendiri; beli/isi/ambil butuh berdiri dekat kandang.
local function canTouch(player: Player, data: Types.PlayerData, hewanId: string?): boolean
	if not PlotService.GetPlot(player) or not characterRoot(player) then
		return false
	end
	if hewanId then
		return nearKandang(player, data, hewanId)
	end
	return true
end

-- Bangun (tier 1) / upgrade (tier 2) kandang.
local function onKandang(player: Player, hewanId: any, tier: any)
	if typeof(hewanId) ~= "string" or (tier ~= 1 and tier ~= 2) then
		return
	end
	local hewan = Ranch.byHewan[hewanId]
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	if not hewan or not data or not plot or not plot.PrimaryPart then
		return
	end
	local costDef = Ranch.KANDANG[hewanId]
	if not costDef then
		return
	end
	if not canTouch(player, data, nil) then
		return
	end
	local entry = kandangOf(data, hewanId)
	if tier == 1 then
		if entry then
			return
		end
		if data.level < hewan.unlockLevel then
			Net.Fire("Notify", player, "fish.locked", { level = hewan.unlockLevel })
			return
		end
		local w, d = costDef.size[1], costDef.size[2]
		local cx, cz = findSpot(data, w, d)
		if cx == nil or cz == nil then
			Net.Fire("Notify", player, "ranch.no_space")
			return
		end
		if not payCost(player, costDef.build, `ranch:{hewanId}:build`) then
			Net.Fire("Notify", player, if EconomyService.CanAfford(player, "koin", costDef.build.koin) then "ranch.no_mats" else "notify.not_enough", { currency = "currency.koin" })
			return
		end
		data.ranch.kandang[hewanId] = { tier = 1, cx = cx :: number, cz = cz :: number, animals = {} }
		buildOne(plot, player, hewanId, data.ranch.kandang[hewanId])
		InventoryService.Sync(player)
		Net.Fire("Notify", player, "ranch.built", { item = `hewan.{hewanId}` })
	else
		if not entry or entry.tier ~= 1 then
			return
		end
		if not payCost(player, costDef.upgrade, `ranch:{hewanId}:upgrade`) then
			Net.Fire("Notify", player, if EconomyService.CanAfford(player, "koin", costDef.upgrade.koin) then "ranch.no_mats" else "notify.not_enough", { currency = "currency.koin" })
			return
		end
		entry.tier = 2
		buildOne(plot, player, hewanId, entry) -- bangun ulang (kapasitas baru)
		InventoryService.Sync(player)
		Net.Fire("Notify", player, "ranch.upgraded", { item = `hewan.{hewanId}` })
	end
end

-- Beli 1 ekor (kandang harus ada + ada slot kosong).
local function onHewan(player: Player, hewanId: any)
	if typeof(hewanId) ~= "string" then
		return
	end
	local hewan = Ranch.byHewan[hewanId]
	local data = DataService.Get(player)
	if not hewan or not data then
		return
	end
	local entry = kandangOf(data, hewanId)
	if not entry then
		Net.Fire("Notify", player, "ranch.need_kandang")
		return
	end
	if not canTouch(player, data, hewanId) then
		return
	end
	if data.level < hewan.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = hewan.unlockLevel })
		return
	end
	local maxAnimals = hewan.maxAnimals[math.clamp(entry.tier, 1, #hewan.maxAnimals)]
	if #entry.animals >= maxAnimals then
		Net.Fire("Notify", player, "ranch.max", { n = maxAnimals })
		return
	end
	if not EconomyService.TrySpend(player, "koin", hewan.price, `ranch:{hewanId}:buy`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
		return
	end
	RanchService.AdvanceAll(data, os.time())
	table.insert(entry.animals, { feed = 0, prod = 0, last = os.time() })
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "ranch.bought", { item = `hewan.{hewanId}` })
end

-- Isi pakan penuh 1 kandang: "koin" (semua ekor, bayar per jatah), "jagung" (ayam saja,
-- 5 Jagung -> 6 jatah, yang paling lapar dulu) atau "pakan" (pakai item Pakan Jagung dari Dapur).
-- Penuh = BLOCK + toast, tanpa potong apa pun (tanpa hangus).
-- Skill Tempat Pakan Besar (Bab 4.5, P2-4): max jatah FeedMax (3 -> 5).
local function feedMax(data: Types.PlayerData): number
	return Ranch.FeedMax(data.skill.tempat_pakan_besar or 0)
end

local function fillHungriest(entry: Types.RanchKandang, n: number, maxFeed: number): number
	local added = 0
	local left = n
	while left > 0 do
		local hungriest: Types.RanchAnimal? = nil
		for _, animal in entry.animals do
			if animal.feed < maxFeed and (not hungriest or animal.feed < (hungriest :: Types.RanchAnimal).feed) then
				hungriest = animal
			end
		end
		if not hungriest then
			break
		end
		(hungriest :: Types.RanchAnimal).feed += 1
		added += 1
		left -= 1
	end
	return added
end

local function onPakan(player: Player, hewanId: any, kind: any)
	if typeof(hewanId) ~= "string" or (kind ~= "koin" and kind ~= "jagung" and kind ~= "pakan") then
		return
	end
	local hewan = Ranch.byHewan[hewanId]
	local data = DataService.Get(player)
	if not hewan or not data then
		return
	end
	local entry = kandangOf(data, hewanId)
	if not entry or #entry.animals == 0 then
		Net.Fire("Notify", player, if not entry then "ranch.need_kandang" else "ranch.no_hewan")
		return
	end
	if not canTouch(player, data, hewanId) then
		return
	end
	RanchService.AdvanceAll(data, os.time())
	if kind == "jagung" then
		if hewanId ~= "ayam" then
			return -- Pakan Jagung hanya untuk Pakan Ayam (Bab 7.1)
		end
		-- Penuh (tidak muat 6 jatah) = BLOCK + toast, Jagung tidak dipotong. Tanpa hangus.
		local maxFeed = feedMax(data)
		local space = 0
		for _, animal in entry.animals do
			space += math.max(maxFeed - animal.feed, 0)
		end
		if space < Ranch.PAKAN_JAGUNG.jatah then
			Net.Fire("Notify", player, "ranch.feed_full")
			return
		end
		if InventoryService.Count(player, "jagung") < Ranch.PAKAN_JAGUNG.jagung then
			Net.Fire("Notify", player, "ranch.no_mats")
			return
		end
		InventoryService.Remove(player, "jagung", Ranch.PAKAN_JAGUNG.jagung)
		local added = fillHungriest(entry, Ranch.PAKAN_JAGUNG.jatah, maxFeed)
		InventoryService.Sync(player)
		Net.Fire("Notify", player, "ranch.jagung", { n = added })
		return
	end
	if kind == "pakan" then
		if hewanId ~= "ayam" then
			return -- Pakan Jagung hanya untuk Pakan Ayam (Bab 9.2)
		end
		local maxFeed = feedMax(data)
		local space = 0
		for _, animal in entry.animals do
			space += math.max(maxFeed - animal.feed, 0)
		end
		if space <= 0 then
			Net.Fire("Notify", player, "ranch.feed_full")
			return
		end
		local have = InventoryService.Count(player, "pakan_jagung")
		if have <= 0 then
			Net.Fire("Notify", player, "ranch.no_mats")
			return
		end
		local take = math.min(have, 6, space)
		InventoryService.Remove(player, "pakan_jagung", take)
		local added = fillHungriest(entry, take, maxFeed)
		InventoryService.Sync(player)
		Net.Fire("Notify", player, "ranch.pakan", { n = added })
		return
	end
	local maxFeed = feedMax(data)
	local missing = 0
	for _, animal in entry.animals do
		missing += math.max(maxFeed - animal.feed, 0)
	end
	if missing <= 0 then
		Net.Fire("Notify", player, "ranch.feed_full")
		return
	end
	local cost = missing * hewan.feedPrice
	if not EconomyService.TrySpend(player, "koin", cost, `ranch:{hewanId}:feed`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
		return
	end
	for _, animal in entry.animals do
		animal.feed = maxFeed
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "ranch.fed", { n = missing })
end

-- Ambil semua produk 1 kandang (1 tombol di depan kandang / panel). XP per produk (CABANG DIHAPUS, P2-4).
function RanchService.Collect(player: Player, hewanId: string)
	local hewan = Ranch.byHewan[hewanId]
	local data = DataService.Get(player)
	if not hewan or not data then
		return
	end
	local entry = kandangOf(data, hewanId)
	if not entry then
		return
	end
	if not canTouch(player, data, hewanId) then
		return
	end
	RanchService.AdvanceAll(data, os.time())
	local count, xp = 0, 0
	for _, animal in entry.animals do
		if animal.prod > 0 then
			count += animal.prod
			xp += animal.prod * hewan.product.xp
			animal.prod = 0
			animal.last = os.time()
		end
	end
	if count <= 0 then
		Net.Fire("Notify", player, "ranch.empty")
		return
	end
	if not InventoryService.Add(player, hewan.product.item, count) then
		return
	end
	if xp > 0 then
		ProgressionService.AddXp(player, xp, `ranch:{hewanId}`)
	end
	Net.Fire("Notify", player, "ranch.collected", { n = count, item = `item.{hewan.product.item}` })
	-- Mood Hujan: produk yang diambil di window +10% Koin (Bab 7.1, LOCKED).
	if RanchService.MoodActive(data) then
		local bonus = math.floor(count * hewan.product.sell * Ranch.MOOD_KOIN_MULT + 0.5)
		if bonus > 0 and EconomyService.Add(player, "koin", bonus, `ranch:{hewanId}:mood`) then
			Net.Fire("Notify", player, "ranch.mood_bonus", { n = bonus })
		end
	end
end

local function onAmbil(player: Player, hewanId: any)
	if typeof(hewanId) ~= "string" then
		return
	end
	RanchService.Collect(player, hewanId)
end

function RanchService.Init()
	PlotService.Assigned:Connect(function(player: Player, plot: Model)
		clearPlot(plot) -- sisa pemilik lama
		buildAll(player, plot)
	end)
	PlotService.Released:Connect(function(_player: Player, plot: Model)
		clearPlot(plot)
	end)
	DataService.Loaded:Connect(function(player: Player, data: Types.PlayerData)
		RanchService.AdvanceAll(data, os.time()) -- produksi jalan walau offline
		InventoryService.Sync(player)
	end)
	-- Mood Hujan mulai saat hujan SELESAI (WorldService.RainEnded), 5 menit (Bab 7.1, LOCKED).
	WorldService.RainEnded:Connect(function(_kind: string)
		local now = os.time()
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if data and (next(data.ranch.kandang) ~= nil or #data.pond.list > 0) then
				data.ranch.moodUntil = now + Ranch.MOOD_SECONDS
				Net.Fire("Notify", player, "ranch.mood", { m = Ranch.MOOD_SECONDS // 60 })
			end
		end
	end)
end

function RanchService.Start()
	Net.On("RanchKandang", onKandang, RATE)
	Net.On("RanchHewan", onHewan, RATE)
	Net.On("RanchPakan", onPakan, RATE)
	Net.On("RanchAmbil", onAmbil, RATE)
end

return RanchService
