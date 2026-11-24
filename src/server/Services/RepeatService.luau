--!strict
-- Event Berulang (Kampoeng_Tedoeh Bab 13, P2-6, LOCKED): Gerobak Kaget, Pasar Malam,
-- Kerja Bakti Kilat, Kalender Musiman + Pesanan Tamu.
-- Angka USULAN ditandai; v7.3 memberi struktur, sebagian angka butuh lock owner.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FeatureGate = require(script.Parent.FeatureGate)
local BookService = require(script.Parent.BookService)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Decor = require(ReplicatedStorage.Shared.Config.Decor)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Map = require(ReplicatedStorage.Shared.Config.Map)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TutorialService = require(script.Parent.TutorialService)
local Ranch = require(ReplicatedStorage.Shared.Config.Ranch)
local Repeat = require(ReplicatedStorage.Shared.Config.Repeat)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local NpcService = require(script.Parent.NpcService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local WorldService = require(script.Parent.WorldService)

local random = Random.new()
local RATE = { rate = 4, burst = 8 }
local WIB_OFFSET = 7 * 3600 -- WIB = UTC+7 (sama seperti TimeKeys SHIFT)

-- Harga decor katalog (mata uang asli: Koin ATAU Bunga — Gerobak tidak mengubahnya).
local function decorPriceOf(decorId: string): (number, string)
	local def = Decor.byId[decorId]
	if not def then
		return 0, "koin"
	end
	return def.price, def.currency
end

-- Nama pajang slot Gerobak (locale key; diterjemahkan client).
local function slotItemName(slot: { slot: number, kind: string, id: string, count: number, price: number, stocked: boolean }): string
	if slot.kind == "seed" then
		return `crop.{(slot.id:match("^seed_(.+)$") or slot.id)}`
	elseif slot.kind == "hewan" then
		return `hewan.{slot.id}`
	elseif slot.kind == "decor" or slot.kind == "rare" then
		return `decor.{slot.id}`
	end
	return `item.{slot.id}`
end

local RepeatService = {}

-- Diskon Warga (Bab 13.4): -10% bibit/umpan/pakan di Toko Pak Udin selama 30 mnt nyata.
-- Dipanggil ShopService (beli) + RanchService (isi pakan Koin).
function RepeatService.DiscountActive(data: Types.PlayerData): boolean
	return (data.discountUntil or 0) > os.time()
end

-- Gerobak Kaget ---------------------------------------------------------------

-- Harga 1 unit slot Gerobak (USULAN: v7.3 tak memberi harga).
local function gerobakPrice(slot: { slot: number, kind: string, id: string, count: number, price: number, stocked: boolean }): number
	if slot.kind == "seed" then
		local cropId = slot.id:match("^seed_(.+)$")
		local crop = cropId and Crops.byId[cropId]
		return if crop then math.floor(crop.seedPrice * Repeat.GEROBAK.SEED_PRICE_MULT + 0.5) else 0
	elseif slot.kind == "bahan" then
		return Repeat.GEROBAK.BAHAN_PRICE
	elseif slot.kind == "hewan" then
		local varian = Ranch.VARIAN[slot.id]
		return if varian then varian.price else 0
	elseif slot.kind == "decor" or slot.kind == "rare" then
		-- Harga decor = harga katalog (Decor.luau) — dicari saat beli, bukan di sini.
		return -1
	end
	return 0
end

local function restockState(data: Types.PlayerData): { restock: number, bought: { [number]: number } }
	local restock = Repeat.currentRestock()
	if data.gerobak.restock ~= restock then
		data.gerobak = { restock = restock, bought = {} }
	end
	return data.gerobak
end

local function onGerobakBuy(player: Player, slotIndex: any)
	if not FeatureGate.Check(player, "gerobak") then return end
	if TutorialService.NpcBlocked(player, nil) then
		Net.Fire("Notify", player, "npc.tut_block") -- Bab 16.3: no order/event/social while Tutorial 1 runs
		return
	end
	if typeof(slotIndex) ~= "number" then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local state = restockState(data)
	local offer = Repeat.gerobakOffer(state.restock)
	local slot: { slot: number, kind: string, id: string, count: number, price: number, stocked: boolean }? = nil
	for _, entry in offer do
		if entry.slot == slotIndex then
			slot = entry
			break
		end
	end
	if not slot or not slot.stocked then
		Net.Fire("Notify", player, "gerobak.empty")
		return
	end
	local bought = state.bought[slot.slot] or 0
	if bought >= Repeat.GEROBAK.MAX_PER_SLOT then
		Net.Fire("Notify", player, "gerobak.full")
		return
	end
	if slot.kind == "seed" then
		local cropId = slot.id:match("^seed_(.+)$")
		local crop = cropId and Crops.byId[cropId]
		local price = gerobakPrice(slot)
		if not crop or price <= 0 then
			return
		end
		if data.level < crop.unlockLevel then
			Net.Fire("Notify", player, "gerobak.need_level", { level = crop.unlockLevel })
			return
		end
		if not InventoryService.CanAdd(player, slot.id, 1) then
			return
		end
		if not EconomyService.TrySpend(player, "koin", price, `gerobak:{slot.id}`) then
			Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
			return
		end
		InventoryService.Add(player, slot.id, 1)
		BookService.RecordVarian(player, slot.id)
	elseif slot.kind == "bahan" then
		if not InventoryService.CanAdd(player, slot.id, 1) then
			return
		end
		if not EconomyService.TrySpend(player, "koin", slot.price, `gerobak:{slot.id}`) then
			Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
			return
		end
		InventoryService.Add(player, slot.id, 1)
	elseif slot.kind == "hewan" then
		local varian = Ranch.VARIAN[slot.id]
		local hewan = varian and Ranch.byHewan[varian.kandang]
		local kandang = hewan and data.ranch.kandang[varian.kandang]
		if not hewan or not kandang then
			Net.Fire("Notify", player, "ranch.need_kandang")
			return
		end
		local maxAnimals = hewan.maxAnimals[math.clamp(kandang.tier, 1, #hewan.maxAnimals)]
		if #kandang.animals >= maxAnimals then
			Net.Fire("Notify", player, "ranch.max", { n = maxAnimals })
			return
		end
		if not EconomyService.TrySpend(player, "koin", varian.price, `gerobak:{slot.id}`) then
			Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
			return
		end
		table.insert(kandang.animals, { feed = 0, prod = 0, last = os.time() })
		BookService.RecordVarian(player, slot.id)
	else -- decor / rare: tambah ke stock dekor langsung (pola QuestService bonusDecor).
		-- Mata uang ASLI katalog (Koin ATAU Bunga): Gerobak tidak mengubah ekonomi decor.
		local decorPrice, decorCurrency = decorPriceOf(slot.id)
		if decorPrice <= 0 then
			return
		end
		if not EconomyService.TrySpend(player, decorCurrency, decorPrice, `gerobak:{slot.id}`) then
			Net.Fire("Notify", player, "notify.not_enough", { currency = if decorCurrency == "bunga" then "currency.bunga" else "currency.koin" })
			return
		end
		data.decor.stock[slot.id] = (data.decor.stock[slot.id] or 0) + 1
	end
	state.bought[slot.slot] = bought + 1
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "gerobak.bought", { item = slotItemName(slot) })
end

-- Pasar Malam -------------------------------------------------------------------
-- Tiap Malam game (9 mnt): Pedagang Tamu rotasi 6 membeli 1 jenis barang +50%, max 10/player.
-- + Lempar Gelang 3x gratis: hadiah Koin kecil / bahan / Bunga (USULAN: v7.3 sebut "tiket dekor",
-- belum ada sistem tiket — diganti Bunga).

local nightCounter = 0 -- id malam game; reset tiap restart server (murah, didokumentasikan)
local pasar = {
	item = "",
	trader = "",
}

-- Rollover data pasar per malam: kembalikan {sold, throws} malam BERJALAN (sekaligus simpan
-- item/trader malam ini ke data agar snapshot selalu benar walau server restart).
local function rollPasar(data: Types.PlayerData): { sold: number, throws: number }
	if data.pasar.night ~= nightCounter or data.pasar.item ~= pasar.item then
		data.pasar = { night = nightCounter, item = pasar.item, trader = pasar.trader, sold = 0, throws = 0 }
	end
	return { sold = data.pasar.sold, throws = data.pasar.throws }
end

local function rollPasarItem(): string
	-- 1 jenis barang acak: tanaman ATAU ikan non-Legenda (USULAN: v7.3 cuma bilang "1 jenis barang acak").
	local pool: { string } = {}
	for _, crop in Crops.list do
		if not crop.varian then
			table.insert(pool, crop.id)
		end
	end
	for _, fish in FishConfig.list do
		if fish.rarity ~= "L" then
			table.insert(pool, `fish:{fish.id}`)
		end
	end
	return pool[random:NextInteger(1, #pool)]
end

local function pasarBasePrice(itemId: string): number
	local crop = Crops.byId[itemId]
	if crop then
		return crop.sellPrice
	end
	local fishId = itemId:match("^fish:(.+)$")
	local fish = fishId and FishConfig.byId[fishId]
	if fish then
		return fish.sellPrice
	end
	return 0
end

local TRADERS = { "pak_kumis", "nek_esih", "bang_dodo", "mpok_riah", "kang_asep", "yu_tum" }

local function rollAllPasar()
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			rollPasar(data)
			InventoryService.Sync(player)
		end
	end
end

local function startPasar()
	nightCounter += 1
	pasar.item = rollPasarItem()
	pasar.trader = TRADERS[(nightCounter - 1) % #TRADERS + 1]
	rollAllPasar()
	NpcService.Show(pasar.trader)
end

local function endPasar()
	NpcService.Hide(pasar.trader)
end

local function takeFish(player: Player, fishId: string, count: number): number
	local left = count
	local taken = 0
	for _, size in FishConfig.SIZES do
		if left <= 0 then
			break
		end
		local id = `{fishId}@{size.id}`
		local have = InventoryService.Count(player, id)
		local take = math.min(left, have)
		if take > 0 then
			InventoryService.Remove(player, id, take)
			left -= take
			taken += take
		end
	end
	return taken
end

local function onPasarJual(player: Player, amount: any)
	if TutorialService.NpcBlocked(player, nil) then
		Net.Fire("Notify", player, "npc.tut_block") -- Bab 16.3: no order/event/social while Tutorial 1 runs
		return
	end
	local data = DataService.Get(player)
	if not data or pasar.item == "" then
		return
	end
	if typeof(amount) ~= "number" or amount <= 0 then
		amount = 999
	end
	local state = rollPasar(data)
	local room = math.min(Repeat.PASAR.MAX_PER_NIGHT - state.sold, math.floor(amount))
	if room <= 0 then
		Net.Fire("Notify", player, "pasar.full")
		return
	end
	local base = pasarBasePrice(pasar.item)
	if base <= 0 then
		return
	end
	local crop = Crops.byId[pasar.item]
	local got: number
	if crop then
		got = math.min(room, InventoryService.Count(player, pasar.item))
		if got <= 0 then
			Net.Fire("Notify", player, "pasar.no_item")
			return
		end
		InventoryService.Remove(player, pasar.item, got)
	else
		local fishId = (pasar.item:match("^fish:(.+)$") or "")
		got = takeFish(player, fishId, room)
		if got <= 0 then
			Net.Fire("Notify", player, "pasar.no_item")
			return
		end
	end
	local price = math.floor(base * Repeat.PASAR.BUY_MULT + 0.5)
	EconomyService.Add(player, "koin", price * got, `pasar:{pasar.item}`)
	data.pasar.sold = state.sold + got
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "pasar.sold", { n = got, koin = price * got })
end

local function onGelangThrow(player: Player)
	if TutorialService.NpcBlocked(player, nil) then
		Net.Fire("Notify", player, "npc.tut_block") -- Bab 16.3: no order/event/social while Tutorial 1 runs
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local state = rollPasar(data)
	if state.throws >= Repeat.PASAR.GELANG_PER_NIGHT then
		Net.Fire("Notify", player, "gelang.max")
		return
	end
	data.pasar.throws = state.throws + 1
	local roll = random:NextNumber()
	if roll < 0.6 then
		local koin = random:NextInteger(Repeat.PASAR.GELANG_KOIN[1], Repeat.PASAR.GELANG_KOIN[2])
		EconomyService.Add(player, "koin", koin, "gelang:koin")
		Net.Fire("Notify", player, "gelang.koin", { n = koin })
	elseif roll < 0.9 then
		local bahanId = Repeat.GEROBAK.BAHAN_POOL[random:NextInteger(1, #Repeat.GEROBAK.BAHAN_POOL)]
		local count = random:NextInteger(Repeat.PASAR.GELANG_BAHAN_COUNT[1], Repeat.PASAR.GELANG_BAHAN_COUNT[2])
		InventoryService.Add(player, bahanId, count)
		Net.Fire("Notify", player, "gelang.bahan", { n = count, item = `item.{bahanId}` })
	else
		local bunga = random:NextInteger(Repeat.PASAR.GELANG_BUNGA[1], Repeat.PASAR.GELANG_BUNGA[2])
		EconomyService.Add(player, "bunga", bunga, "gelang:bunga")
		Net.Fire("Notify", player, "gelang.bunga", { n = bunga })
	end
	InventoryService.Sync(player)
end

-- Kerja Bakti Kilat -------------------------------------------------------------
-- Setelah Hujan Deres / Petir selesai: kotoran 10 + 6 per player (max 58). +15 Koin +3 XP
-- per poin, max 20 poin/event, max 4 event berhadiah/hari. Bonus Kampung 100%: semua yang punya
-- >= 1 poin dapat +150 Koin + Diskon Warga (-10% 30 mnt). Solo 1 player pun bisa 100%.

-- K-117: sampah tiap pemain milik pemain itu (klien yang menggambar). Server hanya menyimpan posisinya.
local kb = {
	active = false,
	total = 0, -- jumlah sampah semua peserta (KBTotal)
	collected = 0, -- sudah dipungut semua peserta (KBGot)
	points = {} :: { [number]: number }, -- [userId] = poin event ini
	counted = {} :: { [number]: boolean }, -- [userId] = event ini sudah dihitung ke kuota harian
	pieces = {} :: { [number]: { Vector3 } }, -- [userId] = posisi sampah (index = piece id), kosong = sudah dipungut
	deadline = 0, -- os.time batas event (TIMEOUT_SECONDS)
}

local function kbCount(data: Types.PlayerData): number
	local today = TimeKeys.day()
	if data.kb.day ~= today then
		data.kb.day = today
		data.kb.count = 0
	end
	return data.kb.count
end

local function clearTrash()
	kb.pieces = {} -- klien menghapus gambarnya sendiri saat KBActive jadi false
end

local function kbStop(rewarded: boolean)
	-- Bonus Kampung 100%: terkumpul semua => yang punya >= 1 poin dapat bonus (Bab 13.4).
	if rewarded then
		for userId, points in kb.points do
			if points > 0 then
				local p = Players:GetPlayerByUserId(userId)
				local data = p and DataService.Get(p)
				if data then
					EconomyService.Add(p, "koin", Repeat.KERJA.BONUS_KOIN, "kb:bonus")
					data.discountUntil = os.time() + Repeat.KERJA.BONUS_DISCOUNT_SECONDS
					InventoryService.Sync(p)
					Net.Fire("Notify", p, "kb.bonus", { n = Repeat.KERJA.BONUS_KOIN })
				end
			end
		end
	end
	clearTrash()
	kb.active = false
	kb.total = 0
	kb.collected = 0
	kb.points = {}
	kb.counted = {}
	kb.deadline = 0
	Workspace:SetAttribute("KBActive", false)
end

local function kbGroundY(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	local hit = Workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), params)
	return if hit then hit.Position.Y else 2
end

-- K-117: satu titik sampah acak di piringan alun-alun, tidak dekat batang pohon dan tidak dekat sampah lain
-- milik pemain yang sama. Gagal setelah 40 percobaan = titik itu dilewati (sampah lebih sedikit, tidak macet).
local function kbSpot(taken: { Vector3 }): Vector3?
	local KERJA = Repeat.KERJA
	for _ = 1, 40 do
		local angle = random:NextNumber() * math.pi * 2
		local radius = math.sqrt(random:NextNumber()) * KERJA.SPREAD_R -- akar: sebaran merata di luas piringan
		local x = Map.TOWN.RING_X + math.cos(angle) * radius
		local z = Map.TOWN.RING_Z + math.sin(angle) * radius
		local tree = math.sqrt((x - Map.TOWN.TREE_X) ^ 2 + (z - Map.TOWN.TREE_Z) ^ 2)
		local clear = tree >= KERJA.TREE_CLEAR
		for _, other in taken do
			if math.sqrt((x - other.X) ^ 2 + (z - other.Z) ^ 2) < KERJA.SPACING then
				clear = false
				break
			end
		end
		if clear then
			return Vector3.new(x, kbGroundY(x, z) + 0.4, z)
		end
	end
	return nil
end

local function kbStart()
	if kb.active then
		return
	end
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end
	kb.active = true
	kb.total = 0
	kb.collected = 0
	kb.points = {}
	kb.counted = {}
	kb.pieces = {}
	kb.deadline = os.time() + Repeat.KERJA.TIMEOUT_SECONDS
	local taken: { Vector3 } = {}
	for _, player in players do
		-- K-117: server memutuskan jumlah sampah tiap pemain (PIECES_EACH); tiap pemain dapat set sendiri.
		local mine: { Vector3 } = {}
		for _ = 1, Repeat.KERJA.PIECES_EACH do
			local spot = kbSpot(taken)
			if spot then
				table.insert(mine, spot)
				table.insert(taken, spot)
			end
		end
		kb.pieces[player.UserId] = mine
		kb.total += #mine
		Net.Fire("KBPieces", player, mine)
	end
	if kb.total <= 0 then
		kbStop(false)
		return
	end
	Workspace:SetAttribute("KBActive", true)
	Workspace:SetAttribute("KBTotal", kb.total)
	Workspace:SetAttribute("KBGot", 0)
	task.delay(Repeat.KERJA.TIMEOUT_SECONDS, function()
		if kb.active and os.time() >= kb.deadline then
			kbStop(false) -- waktu habis: bersihkan tanpa bonus
		end
	end)
end

-- K-117: pungut sampah sendiri. Server cek: event aktif, gerbang gerobak, id milik pemain ini dan belum dipungut,
-- jarak HRP <= PICK_REACH. Sekali saja: id dihapus dari daftar sebelum hadiah.
local function onKBPick(player: Player, pieceId: any)
	if not kb.active or typeof(pieceId) ~= "number" then
		return
	end
	if not FeatureGate.Check(player, "gerobak") then return end -- Q-2 server gate (same as the other gerobak actions)
	local mine = kb.pieces[player.UserId]
	local spot = if mine then mine[pieceId] else nil
	if not spot then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or (root.Position - spot).Magnitude > Repeat.KERJA.PICK_REACH then
		return
	end
	mine[pieceId] = nil
	kb.collected += 1
	Workspace:SetAttribute("KBGot", kb.collected)
	Net.Fire("KBPicked", player, pieceId)
	local data = DataService.Get(player)
	if data then
		local uid = player.UserId
		local paid = kb.points[uid] or 0
		local counted = kb.counted[uid] == true
		-- Berhadiah bila: poin event ini < 20 DAN sudah ikut < 4 event berhadiah hari ini.
		if paid < Repeat.KERJA.MAX_POINTS and (counted or kbCount(data) < Repeat.KERJA.MAX_PER_DAY) then
			EconomyService.Add(player, "koin", Repeat.KERJA.KOIN_PER_POINT, "kb:poin")
			ProgressionService.AddXp(player, Repeat.KERJA.XP_PER_POINT, "kb:poin")
			QuestService.Report(player, "kb") -- Side Kerja Bakti 10x (Bab 14.4)
			kb.points[uid] = paid + 1
			if not counted then
				kb.counted[uid] = true
				data.kb.count += 1
			end
			InventoryService.Sync(player)
		end
	end
	if kb.collected >= kb.total then
		kbStop(true) -- 100%: semua peserta dapat bonus
	end
end

-- Kalender Musiman + Pesanan Tamu -------------------------------------------------
-- 5 event setahun (v7.3 Bab 13.3). Lebaran + Festival Panen tanggalnya USULAN.
-- Tamu Event (tamu_event NPC) minta 3-5 barang: hadiah Koin + Bunga + 1 dekor event.

local currentEvent: string? = nil
local eventProps: { Instance } = {}

local function activeEvent(now: number): string?
	local d = os.date("!*t", now + WIB_OFFSET)
	for _, ev in Repeat.KALENDER do
		if ev.monthStart <= ev.monthEnd then
			if (d.month > ev.monthStart or (d.month == ev.monthStart and d.day >= ev.dayStart))
				and (d.month < ev.monthEnd or (d.month == ev.monthEnd and d.day <= ev.dayEnd)) then
				return ev.id
			end
		else -- rentang tahun baru (Des -> Jan)
			if (d.month > ev.monthStart or (d.month == ev.monthStart and d.day >= ev.dayStart))
				or (d.month < ev.monthEnd or (d.month == ev.monthEnd and d.day <= ev.dayEnd)) then
				return ev.id
			end
		end
	end
	return nil
end

local function eventDef(id: string): { id: string, decor: { string } }?
	for _, ev in Repeat.KALENDER do
		if ev.id == id then
			return ev
		end
	end
	return nil
end

local function clearEventDecor()
	for _, prop in eventProps do
		pcall(function()
			prop:Destroy()
		end)
	end
	eventProps = {}
end

local function buildEventDecor(eventId: string)
	clearEventDecor()
	local def = eventDef(eventId)
	if not def then
		return
	end
	-- Hiasan alun-alun dari Config (lampion/gapura sederhana; visual final = P2-9).
	local colors = {
		agustusan = Color3.fromRGB(220, 60, 50),
		lebaran = Color3.fromRGB(60, 180, 90),
		tahun_baru = Color3.fromRGB(240, 200, 60),
		hari_tani = Color3.fromRGB(120, 180, 80),
		festival_panen = Color3.fromRGB(220, 150, 40),
	}
	local color = colors[eventId] or Color3.fromRGB(240, 220, 120)
	for i, _decorId in def.decor do
		local angle = (i / #def.decor) * math.pi * 2
		local pole = Instance.new("Part")
		pole.Name = "EventDecor"
		pole.Anchored = true
		pole.CanCollide = false
		pole.Size = Vector3.new(0.6, 5, 0.6)
		pole.Position = Vector3.new(math.cos(angle) * 14, 4.3, math.sin(angle) * 14)
		pole.Color = Color3.fromRGB(110, 80, 55)
		pole.Material = Enum.Material.WoodPlanks
		pole.TopSurface = Enum.SurfaceType.Smooth
		pole.BottomSurface = Enum.SurfaceType.Smooth
		pole.Parent = Workspace
		local lamp = Instance.new("Part")
		lamp.Name = "EventLamp"
		lamp.Anchored = true
		lamp.CanCollide = false
		lamp.Shape = Enum.PartType.Ball
		lamp.Size = Vector3.new(2, 2, 2)
		lamp.Position = pole.Position + Vector3.new(0, 3.4, 0)
		lamp.Color = color
		lamp.Material = Enum.Material.Neon
		lamp.TopSurface = Enum.SurfaceType.Smooth
		lamp.BottomSurface = Enum.SurfaceType.Smooth
		lamp.Parent = Workspace
		table.insert(eventProps, pole)
		table.insert(eventProps, lamp)
	end
end

-- Bangkitkan pesanan Tamu untuk 1 player (3-5 barang acak; USULAN komposisi: tanaman non-varian).
local function genTamuOrder(player: Player)
	local data = DataService.Get(player)
	if not data or not currentEvent then
		return
	end
	if data.tamu.event == currentEvent and not data.tamu.done and next(data.tamu.items) ~= nil then
		return
	end
	local pool: { string } = {}
	for _, crop in Crops.list do
		if not crop.varian and crop.unlockLevel <= data.level then
			table.insert(pool, crop.id)
		end
	end
	if #pool == 0 then
		for _, crop in Crops.list do
			if not crop.varian then
				table.insert(pool, crop.id)
			end
		end
	end
	local items: { [string]: number } = {}
	local types = math.min(Repeat.TAMU.ITEM_MAX, math.max(Repeat.TAMU.ITEM_MIN, 3))
	for _ = 1, types do
		local id = pool[random:NextInteger(1, #pool)]
		items[id] = (items[id] or 0) + random:NextInteger(Repeat.TAMU.QTY_MIN, Repeat.TAMU.QTY_MAX)
	end
	data.tamu = { event = currentEvent, items = items, done = false }
	InventoryService.Sync(player)
end

local function setEvent(eventId: string?)
	if currentEvent == eventId then
		return
	end
	currentEvent = eventId
	clearEventDecor()
	if eventId then
		buildEventDecor(eventId)
		NpcService.Show("tamu_event")
		for _, player in Players:GetPlayers() do
			genTamuOrder(player)
			Net.Fire("Notify", player, "event.started", { name = `event.{eventId}`, desc = `event.{eventId}.desc` })
		end
	else
		NpcService.Hide("tamu_event")
	end
	Workspace:SetAttribute("EventAktif", eventId or "")
end

local function onTamuDeliver(player: Player)
	if TutorialService.NpcBlocked(player, nil) then
		Net.Fire("Notify", player, "npc.tut_block") -- Bab 16.3: no order/event/social while Tutorial 1 runs
		return
	end
	local data = DataService.Get(player)
	if not data or data.tamu.done or data.tamu.event == "" then
		return
	end
	if currentEvent ~= data.tamu.event then
		data.tamu = { event = "", items = {}, done = false }
		return
	end
	local totalBase = 0
	for itemId, need in data.tamu.items do
		if InventoryService.Count(player, itemId) < need then
			Net.Fire("Notify", player, "tamu.missing")
			return
		end
		local crop = Crops.byId[itemId]
		if crop then
			totalBase += crop.sellPrice * need
		end
	end
	for itemId, need in data.tamu.items do
		InventoryService.Remove(player, itemId, need)
	end
	data.tamu.done = true
	local koin = math.floor(totalBase * Repeat.TAMU.KOIN_MULT + 0.5)
	ProgressionService.AddXp(player, 100, "tamu:order") -- XP flat 100 (USULAN: v7.3 tak memberi angka)
	EconomyService.Add(player, "koin", koin, "tamu:order")
	EconomyService.Add(player, "bunga", Repeat.TAMU.BUNGA, "tamu:order")
	-- 1 dekor event acak (USULAN pool = decor alun-alun event tsb).
	local def = currentEvent and eventDef(currentEvent)
	local decorId = def and def.decor[random:NextInteger(1, #def.decor)] or nil
	if decorId then
		data.decor.stock[decorId] = (data.decor.stock[decorId] or 0) + 1
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "tamu.done", { n = koin, bunga = Repeat.TAMU.BUNGA })
end

local lastRestock = -1

local function slotVarianName(itemId: string): string
	local cropId = itemId:match("^seed_(.+)$") or itemId
	return `crop.{cropId}`
end

local function checkRestock()
	local restock = Repeat.currentRestock()
	if restock == lastRestock then
		return
	end
	lastRestock = restock
	-- Toast 1x saat ada Bibit Varian (Bab 13.1). Bisa dimatikan di Settings.
	local offer = Repeat.gerobakOffer(restock)
	local varian = nil
	for _, slot in offer do
		if slot.slot == 1 and slot.stocked then
			varian = slot.id
			break
		end
	end
	if varian then
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if data and data.settings.gerobak ~= false then
				Net.Fire("Notify", player, "gerobak.restock", { item = slotVarianName(varian) })
			end
		end
	end
end

local function checkEvent()
	setEvent(activeEvent(os.time()))
end

function RepeatService.Init()
	WorldService.PhaseChanged:Connect(function(phase: string)
		if phase == "malam" then
			startPasar()
		else
			endPasar()
		end
	end)
	WorldService.RainEnded:Connect(function(kind: string)
		if kind == "deres" or kind == "petir" then
			kbStart()
		end
	end)
	DataService.Loaded:Connect(function(player: Player)
		local data = DataService.Get(player)
		if data then
			rollPasar(data) -- sinkronkan malam berjalan (reset bila sudah ganti malam)
		end
		checkEvent() -- setEvent menilai ulang + memberi Tamu ke yang online (termasuk yang baru join)
	end)
	lastRestock = Repeat.currentRestock()
	task.spawn(function()
		while true do
			task.wait(60)
			checkRestock()
			checkEvent()
		end
	end)
end

-- K-118: gerobak placeholder di alun-alun (R4.10 menggantinya dengan art asli). Dibangun dari part sederhana,
-- selalu ada di plaza. Klien (RepeatController) menampilkan "Lihat Gerobak" saat pemain dekat dan gerbang gerobak terbuka.
local CART_AT = Vector3.new(-18, Map.TOWN.PLAZA_Y, 14) -- antara cincin toko (r 62) dan batang pohon; tidak di jalan jembatan
local function buildGerobakCart()
	local model = Instance.new("Model")
	model.Name = "GerobakCart"
	local function piece(name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = CFrame.new(CART_AT) * cf
		p.Color = color
		p.Material = Enum.Material.WoodPlanks
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Shape = shape or Enum.PartType.Block
		p.Parent = model
		return p
	end
	local wood = Color3.fromRGB(150, 104, 62)
	local bak = piece("Bak", Vector3.new(5, 1.6, 3), CFrame.new(0, 2.2, 0), wood)
	piece("Atap", Vector3.new(5.4, 0.3, 3.4), CFrame.new(0, 4.2, 0), Color3.fromRGB(196, 72, 60))
	piece("Pegangan", Vector3.new(3.5, 0.3, 0.3), CFrame.new(-4.2, 2.4, 0), wood)
	for _, x in { -1.2, 1.2 } do -- roda: silinder dengan sumbu Z (diputar 90 derajat di Y)
		for _, z in { -1.7, 1.7 } do
			piece("Roda", Vector3.new(0.4, 2, 2), CFrame.new(x, 1, z) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(70, 52, 38), Enum.PartType.Cylinder)
		end
	end
	CollectionService:AddTag(bak, "GerobakCart")
	model.Parent = Workspace
end

function RepeatService.Start()
	buildGerobakCart()
	Net.On("KBPick", onKBPick, { rate = 6, burst = 12 })
	Net.On("GerobakBuy", onGerobakBuy, RATE)
	Net.On("PasarJual", onPasarJual, RATE)
	Net.On("GelangThrow", onGelangThrow, RATE)
	Net.On("TamuDeliver", onTamuDeliver, RATE)
end

return RepeatService
