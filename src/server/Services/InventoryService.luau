--!strict
-- Item counts. Tas tanpa cap slot, stack 99 (Bab 18.1 v7.3). Tidak ada Upgrade Tas, tidak ada Backpack Pass.
-- Any service that changes something the client panels show calls InventoryService.Sync.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DecorConfig = require(ReplicatedStorage.Shared.Config.Decor)
local FeatureGate = require(script.Parent.FeatureGate)
local FarmConfig = require(ReplicatedStorage.Shared.Config.Farm)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Bubu = require(ReplicatedStorage.Shared.Config.Bubu)
local RewardsConfig = require(ReplicatedStorage.Shared.Config.Rewards)
local RepeatConfig = require(ReplicatedStorage.Shared.Config.Repeat)
local SuratConfig = require(ReplicatedStorage.Shared.Config.Surat)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local OrdersConfig = require(ReplicatedStorage.Shared.Config.Orders)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local InventoryService = {}

local pendingSync: { [Player]: boolean } = {}

-- Surat aktif untuk tracker: nomor terkecil yang belum selesai dan sudah dibuka (0 = tidak ada).
local function suratSnapshot(data: Types.PlayerData): { n: number, progress: number, need: number }
	for n = 1, SuratConfig.COUNT do
		if not data.surat.done[n] then
			local def = SuratConfig.byN[n]
			if def and n <= data.surat.logins then
				return { n = n, progress = data.surat.progress, need = def.count }
			end
			return { n = 0, progress = 0, need = 0 }
		end
	end
	return { n = 0, progress = 0, need = 0 }
end

local function isValid(itemId: any, amount: any): boolean
	return typeof(itemId) == "string" and typeof(amount) == "number" and amount > 0 and amount % 1 == 0
end

-- Just the cells (the client needs them to preview where you can till / place decor).
local function farmTiles(data: Types.PlayerData)
	local tiles = {}
	for _, tile in data.farm.tiles do
		table.insert(tiles, { uid = tile.uid, cx = tile.cx, cz = tile.cz })
	end
	return tiles
end

-- Pond cells, so the client can preview where a pond fits and keep soil / decor off the water.
local function pondCells(data: Types.PlayerData)
	local ponds = {}
	for _, pond in data.pond.list do
		table.insert(ponds, { uid = pond.uid, cx = pond.cx, cz = pond.cz })
	end
	return ponds
end

-- Breeding per kolam untuk UI (PondService): tier + kakek + breed aktif. Save lama yang belum
-- punya field-nya dikirim apa adanya; client menganggap tier hilang = "tanah".
local function pondStateFor(data: Types.PlayerData)
	local out = {}
	if not data.pond then
		return out
	end
	for _, pond in data.pond.list do
		table.insert(out, { uid = pond.uid, tier = pond.tier, kakek = pond.kakek, breed = pond.breed, stock = table.clone(pond.stock or {}) })
	end
	return out
end

-- F-3: the bait a cast uses (Fishing.BAITS order, the first one the player owns) and its count. nil when none is owned.
-- FishService.cast uses the same rule, so the chip and the cast never disagree.
-- C1 (K-55): the bait in use is the one the player equipped, while they still have some. When it runs out, the first bait the
-- player still has (BAITS order) takes over and becomes the equipped one. nil when there is no bait left.
function InventoryService.ActiveBait(data: Types.PlayerData): (Fishing.Bait?, number)
	local equipped = Fishing.baitsById[data.fishing.equippedBait]
	if equipped and (data.inventory[equipped.id] or 0) > 0 then
		return equipped, data.inventory[equipped.id]
	end
	for _, bait in Fishing.BAITS do
		local count = data.inventory[bait.id] or 0
		if count > 0 then
			data.fishing.equippedBait = bait.id
			return bait, count
		end
	end
	return nil, 0
end

local function buildSnapshot(player: Player, data: Types.PlayerData)
	local passes = {}
	for _, pass in Monetization.PASSES do
		passes[pass.key] = MonetizationService.HasPass(player, pass.key)
	end
	return {
		items = table.clone(data.inventory),
		bait = (function()
			local bait, count = InventoryService.ActiveBait(data)
			return if bait then { id = bait.id, count = count } else nil
		end)(),
		pondTier = Upgrades.tier(data, "pond"),
		ponds = pondCells(data),
		pondState = pondStateFor(data), -- breeding per kolam (uid, tier, kakek, breed) untuk UI
		pondKakek = data.pond.kakekUnlocked == true or data.level >= Fishing.POND.UNLOCK_LEVEL, -- gate kolam: Lv 2 (Fishing.POND.UNLOCK_LEVEL) atau Kolam Kakek pulih. Tombol Kolam ikut ini.
		features = (function()
			-- Quest features (data.features) plus the level-gated ones (FeatureGate.LEVEL_GATES, D-39) as "open".
			local out = table.clone(data.features or {})
			for id in FeatureGate.LEVEL_GATES do
				if FeatureGate.LevelOpen(data.level, id) then
					out[id] = "open"
				end
			end
			return out
		end)(),
		bubu = { -- R2.1: bubu terpasang (pos = titik di sungai, ready = sudah 6 jam) untuk tombol Pasang/Ambil dan label di dunia
			max = Bubu.MAX,
			list = (function()
				local now = os.time()
				local out = {}
				for _, entry in data.bubu.list do
					table.insert(out, { uid = entry.uid, kind = entry.kind, pos = entry.pos, ready = Bubu.isReady(entry.placedAt, now) })
				end
				return out
			end)(),
		},
		ranch = data.ranch, -- kandang + hewan + mood untuk panel Ternak
		bundel = data.bundel, -- Bundel Kakek (Bab 14.6): [id] = { given, done } + sumur_day (UI mendatang)
		dapur = { tier = data.dapur.tier, slots = table.clone(data.dapur.slots) },
		warung = data.warung, -- pajangan + nextVisit untuk panel Warung
		buff = data.buff, -- buff aktif untuk panel (HUD baca atribut)
		gerobak = { restock = RepeatConfig.currentRestock(), slots = RepeatConfig.gerobakOffer(RepeatConfig.currentRestock()), bought = data.gerobak.bought },
		pasar = data.pasar,
		tamu = data.tamu,
		discountUntil = data.discountUntil, -- Diskon Warga (P2-6) untuk tab Acara
		quests = {
			active = table.clone(data.quests.active),
			done = table.clone(data.quests.done),
			daily = table.clone(data.quests.daily),
			agenda = table.clone(data.quests.agenda),
			harian = table.clone(data.quests.harian),
			mingguan = table.clone(data.quests.mingguan),
			surat = suratSnapshot(data),
		},
		farm = { tiles = farmTiles(data), cap = FarmConfig.tileCap(data.level) },
		landChunks = table.clone(data.land.chunks),
		landExtra = Land.extraCount(data.land.chunks),
		landPrice = Land.chunkPrice(Land.extraCount(data.land.chunks)),
		rod = data.fishing.rod,
		equippedBait = data.fishing.equippedBait,
		ownedRods = table.clone(data.fishing.ownedRods),
		tools = table.clone(data.tools),
		decorStock = table.clone(data.decor.stock),
		decorPlaced = #data.decor.placed,
		decorMax = DecorConfig.MAX_PLACED,
		passes = passes,
		premium = MonetizationService.IsPremium(player),
		orders = {
			daily = data.orders.daily,
			weekly = data.orders.weekly,
			rerollsUsed = data.orders.rerollsUsed,
			freeRerolls = OrdersConfig.FREE_REROLLS,
			rerolled = data.orders.rerolled,
		},
		skills = data.skill, -- level skill per id untuk panel + efek (P2-4)
		book = data.book,
		playtime = table.clone(data.playtime),
		rewards = (function()
			local seasonId, seasonDay = RewardsConfig.seasonNow(os.time())
			return { login = table.clone(data.rewards.login), peti = data.rewards.peti, season = table.clone(data.rewards.season), seasonId = seasonId, seasonDay = seasonDay }
		end)(),
		titles = data.titles,
		guideSells = data.guide.sells,
		guideHarvests = data.guide.harvests or 0,
		guide = {
			step = { id = data.guide.step.id, n = data.guide.step.n },
			done = table.clone(data.guide.done),
			skipped = table.clone(data.guide.skipped),
			fastLeft = data.guide.fastLeft,
			rodGift = data.guide.rodGift, -- Kak Fajar's Terima Hadiah was taken (the dialog shows it until then)
			saleCutscene = data.guide.saleCutscene, -- the Jual Pertama beat already played (Bab 16.4): never again
			msStage = data.guide.msStage or (data.guide.mkSariHarvestSeen == true and 1 or 0), -- MS-2: highest Mak Sari stage dismissed (1..3)
			fishSold = data.guide.fishSold == true, -- T1b "jual_ikan": the first fish was sold to Kak Fajar
			-- a save that has not started playing: the "newPlayer" tutorial trigger
			fresh = #data.farm.tiles == 0 and data.onboarding.first_plant ~= true and data.guide.sells == 0,
		},
		social = data.social,
		settings = data.settings,
		-- one-time funnel flags (first_plant, first_harvest, ...). The tutorial reads first_harvest (A1: state-driven steps).
		onboarding = table.clone(data.onboarding),
	}
end

-- Batched: many changes in one frame send one snapshot.
function InventoryService.Sync(player: Player)
	if pendingSync[player] then
		return
	end
	pendingSync[player] = true
	task.defer(function()
		pendingSync[player] = nil
		local data = DataService.Get(player)
		if data and player.Parent then
			Net.Fire("StateSync", player, buildSnapshot(player, data))
		end
	end)
end

function InventoryService.Count(player: Player, itemId: string): number
	local data = DataService.Get(player)
	return if data then data.inventory[itemId] or 0 else 0
end

-- Tas tanpa cap slot (Bab 18.1 v7.3): CanAdd hanya cek valid.
function InventoryService.CanAdd(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	return data ~= nil and isValid(itemId, amount) and Items.info(itemId) ~= nil
end

function InventoryService.Add(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or not isValid(itemId, amount) or Items.info(itemId) == nil then
		return false
	end
	data.inventory[itemId] = (data.inventory[itemId] or 0) + amount
	InventoryService.Sync(player)
	return true
end

function InventoryService.Remove(player: Player, itemId: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or not isValid(itemId, amount) then
		return false
	end
	local current = data.inventory[itemId] or 0
	if current < amount then
		return false
	end
	data.inventory[itemId] = if current == amount then nil else current - amount
	InventoryService.Sync(player)
	return true
end

function InventoryService.Init()
	DataService.Loaded:Connect(InventoryService.Sync)
	MonetizationService.Changed:Connect(InventoryService.Sync)
end

function InventoryService.Start()
	Net.On("StateRequest", InventoryService.Sync, { rate = 1, burst = 3 })
end

return InventoryService
