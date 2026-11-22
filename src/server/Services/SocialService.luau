--!strict
-- Mampir (teleport to a plot in this server) and Suka (like a plot once per WIB day).
-- Visitors can look but never touch: farm/decor/pond actions always use the actor's OWN plot.

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")

local PlotsConfig = require(ReplicatedStorage.Shared.Config.Plots)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TutorialService = require(script.Parent.TutorialService)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local FeatureGate = require(script.Parent.FeatureGate)
local EconomyService = require(script.Parent.EconomyService)
local FarmService = require(script.Parent.FarmService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local FishService = require(script.Parent.FishService)

local SocialService = {}

-- Chat per server (Bab 12.5): tidak ada DM (tidak ada channel pribadi), filter kata kasar
-- bawaan TextChatService, plus tolak link / kode / emote chat di sini. Gambar tidak mungkin
-- dikirim lewat chat teks.
local BLOCKED_TEXT = { "http", "www.", "://", ".com", ".net", ".org", ".io", ".gg", ".me", ".ly/", ".xyz", ".link", ".ru", "discord", "t.me", "free robux", "password", "/e " }

local lastVisit: { [Player]: number } = {}
local lastEmote: { [Player]: number } = {}

local function playerById(userId: any): Player?
	if typeof(userId) ~= "number" or userId % 1 ~= 0 then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isOnPlot(player: Player, plot: Model): boolean
	local root = rootOf(player)
	local origin = plot.PrimaryPart
	if not root or not origin then
		return false
	end
	local localPos = origin.CFrame:PointToObjectSpace(root.Position)
	return Land.contains(localPos.X, localPos.Z, Social.LIKE_MARGIN)
end

-- Presence lintas-server (Galeri Kampung = global, Bab 8.7/12.7 P2-5-fix): userId -> jobId,
-- TTL 5 menit + heartbeat. Dipakai untuk teleport ke server pemilik yang sedang online.
local function presenceMapFor(): MemoryStoreSortedMap?
	local ok, map = pcall(function()
		return MemoryStoreService:GetSortedMap("KampoengPresence")
	end)
	if ok then
		return map
	end
	return nil
end

local function publishPresence(player: Player)
	local map = presenceMapFor()
	if not map then
		return
	end
	pcall(function()
		map:SetAsync(tostring(player.UserId), game.JobId, 300)
	end)
end

local function onVisit(player: Player, ownerUserId: any)
	local owner = playerById(ownerUserId)
	if owner == nil and ownerUserId ~= nil then
		-- Pemilik tidak di server ini: coba servernya via presence global.
		local map = presenceMapFor()
		local jobId: string? = nil
		if map then
			local ok, value = pcall(function()
				return map:GetAsync(tostring(ownerUserId))
			end)
			if ok and typeof(value) == "string" and value ~= "" and value ~= game.JobId then
				jobId = value
			end
		end
		if jobId then
			local ok = pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId :: string, { player })
			end)
			if not ok then
				Net.Fire("Notify", player, "social.server_full")
			end
			-- Pemilik offline: lahannya kosong, tidak ada rumah untuk dikunjungi. Tidak ada toast, tidak ada rumah snapshot.
		end
		return
	end
	local plot = owner and PlotService.GetPlot(owner)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not owner or not plot or not plot.PrimaryPart or not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()
	if now - (lastVisit[player] or 0) < Social.VISIT_COOLDOWN then
		return
	end
	lastVisit[player] = now

	FishService.Cancel(player)
	humanoid.Sit = false
	local offset = if owner == player then PlotsConfig.SPAWN_OFFSET else Social.VISIT_OFFSET
	-- Face the plot center from the visit spot.
	local origin = (plot.PrimaryPart :: BasePart).CFrame
	local spot = origin * CFrame.new(offset)
	local lookAt = Vector3.new(origin.Position.X, spot.Position.Y, origin.Position.Z)
	character:PivotTo(if owner == player then spot else CFrame.lookAt(spot.Position, lookAt))
	if owner ~= player then
		Net.Fire("Notify", player, "social.visiting", { name = owner.DisplayName })
	end
end

local function grantMilestones(owner: Player)
	local data = DataService.Get(owner)
	if not data then
		return
	end
	for _, milestone in Social.LIKE_MILESTONES do
		local key = tostring(milestone.likes)
		if data.social.likes >= milestone.likes and not data.social.milestones[key] then
			data.social.milestones[key] = true
			ProgressionService.Grant(owner, milestone.reward, "social_likes")
			Net.Fire("Notify", owner, "social.milestone", { n = milestone.likes })
		end
	end
end

-- Forward: Galeri didefinisikan di bawah (dipakai onLike); helpers-nya resolve saat dipanggil.
local pushGaleri: (number, { week: string, count: number }) -> ()

local function onLike(player: Player, ownerUserId: any)
	local owner = playerById(ownerUserId)
	local plot = owner and PlotService.GetPlot(owner)
	local data = DataService.Get(player)
	local ownerData = owner and DataService.Get(owner)
	if not owner or owner == player or not plot or not data or not ownerData then
		return
	end
	if not isOnPlot(player, plot) then
		Net.Fire("Notify", player, "social.too_far")
		return
	end

	local key = tostring(owner.UserId)
	-- Like 1x per lahan selamanya (Bab 12.7, P2-5). Coba 2x = ditolak (toast).
	if data.social.likedEver[key] then
		Net.Fire("Notify", player, "social.liked")
		return
	end
	data.social.likedEver[key] = true
	ownerData.social.likes += 1
	-- Like mingguan (Galeri Kampung): rollover per minggu WIB.
	local week = TimeKeys.week()
	if ownerData.social.weekly.week ~= week then
		ownerData.social.weekly = { week = week, count = 0 }
	end
	ownerData.social.weekly.count += 1
	pushGaleri(owner.UserId, ownerData.social.weekly)
	-- Pemberi like +20 Koin, max 10 like berhadiah per hari (Bab 12.7, P2-5).
	local today = TimeKeys.day()
	if data.social.likesGiven.day ~= today then
		data.social.likesGiven = { day = today, count = 0 }
	end
	data.social.likesGiven.count += 1
	if data.social.likesGiven.count <= Social.LIKE_REWARD_MAX_DAY then
		EconomyService.Add(player, "koin", Social.LIKE_REWARD_KOIN, "social:like")
	end

	PlotService.SetLikes(owner, ownerData.social.likes)
	Net.Fire("Notify", player, "social.like_sent", { name = owner.DisplayName })
	Net.Fire("Notify", owner, "social.got_like", { name = player.DisplayName })
	grantMilestones(owner)
	InventoryService.Sync(player)
	InventoryService.Sync(owner)
end

-- Galeri Kampung (Bab 8.7/12.7, P2-5): top 5 like mingguan, GLOBAL via OrderedDataStore
-- (bukan per server). Key per minggu => rotasi otomatis; entri lama ditinggalkan.
local galeriNameCache: { [number]: string } = {}
local galeriCache: { at: number, week: string, list: { { userId: number, name: string, likes: number } } } =
	{ at = 0, week = "", list = {} }

-- Store per minggu (nama beda tiap minggu => rotasi otomatis, tanpa cleanup).
local function galeriStoreFor(week: string): OrderedDataStore?
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(`KampoengGaleri_{week}`)
	end)
	if ok then
		return store :: OrderedDataStore
	end
	return nil
end

local function galeriName(userId: number): string
	local cached = galeriNameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local final = if ok and typeof(name) == "string" then name else `Pemain {userId}`
	galeriNameCache[userId] = final
	return final
end

pushGaleri = function(userId: number, weekly: { week: string, count: number })
	if weekly.week == "" or weekly.count <= 0 then
		return
	end
	local store = galeriStoreFor(weekly.week)
	if not store then
		return -- Studio tanpa akses DataStore: papan Galeri kosong sampai live
	end
	pcall(function()
		store:SetAsync(tostring(userId), weekly.count)
	end)
end

local function onGaleriGet(player: Player)
	local week = TimeKeys.week()
	if galeriCache.week == week and os.time() - galeriCache.at < Social.GALERI_CACHE_SECONDS and #galeriCache.list > 0 then
		Net.Fire("GaleriBoard", player, { week = week, list = galeriCache.list })
		return
	end
	local store = galeriStoreFor(week)
	local list: { { userId: number, name: string, likes: number } } = {}
	if store then
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, Social.GALERI_TOP)
		end)
		if ok and pages then
			local okItems, items = pcall(function()
				return pages:GetCurrentPage()
			end)
			if okItems and typeof(items) == "table" then
				for _, entry in items do
					local uid = tonumber(entry.key)
					if uid then
						table.insert(list, { userId = uid, name = galeriName(uid), likes = entry.value })
					end
				end
			end
		end
	end
	galeriCache = { at = os.time(), week = week, list = list }
	Net.Fire("GaleriBoard", player, { week = week, list = list })
end

-- Batas bantu harian (Bab 4.5/12, P2-4 + P2-5): 5 lahan/hari, +1 saat skill Tetangga Baik Lv 3+.
-- P2-5 (Bantu/Sosial) memanggil ini saat reset 05:00; skill dibeli di P2-4.
function SocialService.MaxBantu(data: Types.PlayerData): number
	local bonus = if (data.skill.tetangga_baik or 0) >= 3 then 1 else 0
	return Social.BANTU_MAX_DAY + bonus
end

-- Bantu Tetangga (Bab 12.2, P2-5): per lahan per hari 1 Siram + 1 Panen, per player max 5 lahan
-- (6 dengan Tetangga Baik Lv 3), reset 05:00 WIB. Pembantu +40 Koin +10 XP; tidak mengurangi
-- barang pembantu; tidak bisa bantu lahan sendiri. Siram -> Basah (ikut peluang Bagus/Prima).
-- Panen -> hasil masuk tas pemilik + 1 bibit sejenis bonus, Kualitas tetap milik pemilik.
local function onBantu(helper: Player, ownerId: any, kind: any)
	if not FeatureGate.Check(helper, "bantu") then return end
	if TutorialService.NpcBlocked(helper, nil) then
		Net.Fire("Notify", helper, "npc.tut_block") -- Bab 16.3: no order/event/social while Tutorial 1 runs
		return
	end
	if (kind ~= "siram" and kind ~= "panen") or typeof(ownerId) ~= "number" then
		return
	end
	local owner = playerById(ownerId)
	local data = DataService.Get(helper)
	local ownerData = owner and DataService.Get(owner)
	if not owner or owner == helper or not data or not ownerData then
		return
	end
	local plot = PlotService.GetPlot(owner)
	if not plot or not isOnPlot(helper, plot) then
		Net.Fire("Notify", helper, "social.too_far")
		return
	end
	local today = TimeKeys.day()
	if data.social.helpGiven.day ~= today then
		data.social.helpGiven = { day = today, plots = {} }
	end
	if ownerData.social.helpRecv.day ~= today then
		ownerData.social.helpRecv = { day = today, siram = false, panen = false }
	end
	local key = tostring(owner.UserId)
	local distinct = 0
	for _ in data.social.helpGiven.plots do
		distinct += 1
	end
	local maxPlots = SocialService.MaxBantu(data)
	if data.social.helpGiven.plots[key] == nil and distinct >= maxPlots then
		Net.Fire("Notify", helper, "bantu.max", { n = maxPlots })
		return
	end
	local flag = if kind == "siram" then "siram" else "panen"
	if ownerData.social.helpRecv[flag] then
		Net.Fire("Notify", helper, "bantu.done")
		return
	end
	if kind == "siram" then
		if not FarmService.WaterFor(owner, ownerData) then
			Net.Fire("Notify", helper, "bantu.nothing")
			return
		end
	else
		local uid, cropId = FarmService.HarvestRipeFor(owner, ownerData)
		if not uid or not cropId then
			Net.Fire("Notify", helper, "bantu.nothing")
			return
		end
		-- +1 bibit sejenis bonus untuk pemilik.
		InventoryService.Add(owner, `seed_{cropId}`, 1)
	end
	ownerData.social.helpRecv[flag] = true
	data.social.helpGiven.plots[key] = true
	EconomyService.Add(helper, "koin", Social.BANTU_REWARD_KOIN, `bantu:{kind}`)
	ProgressionService.AddXp(helper, Social.BANTU_REWARD_XP, `bantu:{kind}`)
	QuestService.Report(helper, "bantu") -- Agenda "Bantu 1 lahan" (Bab 14.5)
	InventoryService.Sync(helper)
	InventoryService.Sync(owner)
	Net.Fire("Notify", helper, "bantu.helped", { n = Social.BANTU_REWARD_KOIN, xp = Social.BANTU_REWARD_XP })
	Net.Fire("Notify", owner, "bantu.got_help", { name = helper.DisplayName })
end

-- Kirim Hadiah (Bab 12.3, P2-5): Lv 20, 3 hadiah/hari, max 500 Koin per hadiah (barang, bukan
-- Koin mentah). Tidak bisa Legenda, Bunga, Robux. Penerima dapat barang, pengirim +20 Koin +5 XP.
local function onGift(sender: Player, ownerId: any, itemId: any)
	if TutorialService.NpcBlocked(sender, nil) then
		Net.Fire("Notify", sender, "npc.tut_block")
		return
	end
	if TutorialService.NpcBlocked(sender, nil) then
		Net.Fire("Notify", sender, "npc.tut_block") -- Bab 16.3: no order/event/social while Tutorial 1 runs
		return
	end
	if typeof(ownerId) ~= "number" or typeof(itemId) ~= "string" then
		return
	end
	local data = DataService.Get(sender)
	if not data then
		return
	end
	if data.level < Social.GIFT_UNLOCK then
		Net.Fire("Notify", sender, "fish.locked", { level = Social.GIFT_UNLOCK })
		return
	end
	local owner = playerById(ownerId)
	local ownerData = owner and DataService.Get(owner)
	if not owner or owner == sender or not ownerData then
		return
	end
	local plot = PlotService.GetPlot(owner)
	if not plot or not isOnPlot(sender, plot) then
		Net.Fire("Notify", sender, "social.too_far") -- hadiah diberikan langsung di lahannya
		return
	end
	local today = TimeKeys.day()
	if data.social.gifts.day ~= today then
		data.social.gifts = { day = today, sent = 0 }
	end
	if data.social.gifts.sent >= Social.GIFT_MAX_DAY then
		Net.Fire("Notify", sender, "gift.max")
		return
	end
	local info = Items.info(itemId)
	if not info then
		Net.Fire("Notify", sender, "gift.no_item")
		return
	end
	if itemId == "bunga" or itemId == "robux" then
		Net.Fire("Notify", sender, "gift.no_currency")
		return
	end
	local baseId = itemId:match("^(.+)@") or itemId
	local fish = FishConfig.byId[baseId]
	if fish and fish.rarity == "L" then
		Net.Fire("Notify", sender, "gift.no_legend")
		return
	end
	if (info.sellPrice or 0) > Social.GIFT_MAX_VALUE then
		Net.Fire("Notify", sender, "gift.too_rich")
		return
	end
	if InventoryService.Count(sender, itemId) < 1 or not InventoryService.Remove(sender, itemId, 1) then
		Net.Fire("Notify", sender, "gift.no_item")
		return
	end
	if not InventoryService.Add(owner, itemId, 1) then
		InventoryService.Add(sender, itemId, 1) -- gagal tambah ke tas penerima: kembalikan
		return
	end
	data.social.gifts.sent += 1
	EconomyService.Add(sender, "koin", Social.GIFT_SENDER_KOIN, "gift:send")
	ProgressionService.AddXp(sender, Social.GIFT_SENDER_XP, "gift:send")
	InventoryService.Sync(sender)
	InventoryService.Sync(owner)
	Net.Fire("Notify", sender, "gift.sent")
	Net.Fire("Notify", owner, "gift.got", { name = sender.DisplayName, item = Items.displayName(info) })
end

-- Gestur (Bab 12.4, P2-5): 4 ramah (Social.EMOTES), di mana saja, cooldown 3 detik, tanpa hadiah.
-- Server memvalidasi + cooldown; playback di tiap client via SocialEmoteFx.
local function onEmote(player: Player, emoteId: any)
	if typeof(emoteId) ~= "string" then
		return
	end
	local known = false
	for _, def in Social.EMOTES do
		if def.id == emoteId then
			known = true
			break
		end
	end
	if not known then
		return
	end
	if os.clock() - (lastEmote[player] or 0) < Social.GESTURE_COOLDOWN then
		return
	end
	lastEmote[player] = os.clock()
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Net.Fire("SocialEmoteFx", other, player.UserId, emoteId)
		end
	end
end

-- Save lama (sebelum P2-5) belum punya field sosial baru: isi default agar tidak nil-index.
local function normalizeSocial(data: Types.PlayerData)
	local social = data.social
	if social.likedEver == nil then
		social.likedEver = {}
	end
	if social.weekly == nil then
		social.weekly = { week = "", count = 0 }
	end
	if social.likesGiven == nil then
		social.likesGiven = { day = "", count = 0 }
	end
	if social.helpGiven == nil then
		social.helpGiven = { day = "", plots = {} }
	end
	if social.helpRecv == nil then
		social.helpRecv = { day = "", siram = false, panen = false }
	end
	if social.gifts == nil then
		social.gifts = { day = "", sent = 0 }
	end
	if data.skill == nil then
		data.skill = {}
	end
end

function SocialService.Init()
	PlotService.Assigned:Connect(function(player: Player)
		local data = DataService.Get(player)
		if data then
			normalizeSocial(data)
			PlotService.SetLikes(player, data.social.likes)
			grantMilestones(player) -- catches up if a threshold changed in config
		end
	end)
	DataService.Loaded:Connect(function(_player: Player, data: Types.PlayerData)
		normalizeSocial(data)
	end)

	-- Chat per server (Bab 12.5): hook sekali saat server mulai.
	task.spawn(function()
		local ok, channels = pcall(function()
			return TextChatService:WaitForChild("TextChannels", 10)
		end)
		if not ok or not channels then
			return
		end
		local okChannel, channel = pcall(function()
			return channels:WaitForChild("RBXGeneral", 10)
		end)
		if not okChannel or not channel then
			return
		end
		pcall(function()
			channel.ShouldDeliverCallback = function(message: TextChatMessage): boolean
				local text = string.lower(message.Text or "")
				for _, blocked in BLOCKED_TEXT do
					if string.find(text, blocked, 1, true) then
						return false
					end
				end
				return true
			end
		end)
	end)
end

function SocialService.Start()
	Net.On("SocialVisit", onVisit, { rate = 1, burst = 2 })
	Net.On("SocialLike", onLike, { rate = 1, burst = 3 })
	Net.On("SocialBantu", onBantu, { rate = 4, burst = 8 })
	Net.On("SocialGift", onGift, { rate = 2, burst = 4 })
	Net.On("SocialEmote", onEmote, { rate = 6, burst = 12 })
	Net.On("GaleriGet", onGaleriGet, { rate = 2, burst = 4 })
	Players.PlayerAdded:Connect(publishPresence)
	Players.PlayerRemoving:Connect(function(player)
		lastVisit[player] = nil
		lastEmote[player] = nil
		local map = presenceMapFor()
		if map then
			pcall(function()
				map:RemoveAsync(tostring(player.UserId))
			end)
		end
	end)
	-- Heartbeat presence: publish ulang tiap 60 detik (TTL 300).
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				publishPresence(player)
			end
		end
	end)
end

return SocialService
