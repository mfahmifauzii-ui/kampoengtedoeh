--!strict
-- Hadiah mingguan & jangka panjang (Config/Rewards; Bab 15.1 Login, 15.3 Peti Bunga, 15.4 Title, Bab 19 Season).
-- State di data.rewards. Semua klaim dicek ulang di server. Login dan Season di-roll tiap join dan tiap klaim.
-- Title dicek tiap 30 detik (Album % dan title dari quest), dan tiap title baru memberi 1 Peti Bunga sekali saja.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Rewards = require(ReplicatedStorage.Shared.Config.Rewards)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

local RewardsService = {}

local TITLE_CHECK_SECONDS = 30

-- Login: ganti minggu = mulai dari nol. Tiap hari WIB baru yang dibuka = +1 hari login (max 7).
-- Season: ganti season = klaim F2P/Premium dikosongkan dan Premium dimatikan lagi.
local function roll(data: Types.PlayerData)
	local r = data.rewards
	local week = TimeKeys.week()
	if r.login.week ~= week then
		r.login = { week = week, days = 0, lastDay = "", claimed = {} }
	end
	local today = TimeKeys.day()
	if r.login.lastDay ~= today then
		r.login.lastDay = today
		r.login.days = math.min(r.login.days + 1, 7)
	end
	local seasonId = Rewards.seasonNow(os.time())
	if r.season.id ~= seasonId then
		r.season = { id = seasonId, premium = false, f2p = {}, premiumClaimed = {} }
	end
end

-- Peti Bunga dari sumber yang sudah ada di kode (Update owner 2026-11-22). Tiap sumber memberi 1 peti sekali saja,
-- dicatat di data.rewards.titlePeti (kunci "title:<id>" atau "milestone:<id>"):
--   * Title yang dimiliki (dari sumber mana pun: klaim milestone Album, misi, kategori Album, Like milestone)
--   * Album milestone yang sudah diklaim (p25 / p50 / p75 / p100)
-- Season F2P hari 30 dan Event completion: lihat onSeasonClaim dan Lampiran D (event belum punya definisi).
local function checkTitles(player: Player, data: Types.PlayerData): boolean
	local changed = false
	local function grant(key: string, message: string, vars: { [string]: any }?)
		if data.rewards.titlePeti[key] ~= true then
			data.rewards.titlePeti[key] = true
			data.rewards.peti += 1
			changed = true
			Net.Fire("Notify", player, message, vars)
		end
	end
	for _, title in Rewards.TITLES do
		if data.titles[title.id] == true then
			grant(`title:{title.id}`, "title.new", { title = `title.{title.id}` })
		end
	end
	for _, milestoneId in Rewards.MILESTONE_PETI do
		if data.book.claimed[milestoneId] == true then
			grant(`milestone:{milestoneId}`, "peti.new", nil)
		end
	end
	return changed
end

local function syncAll(player: Player)
	InventoryService.Sync(player)
end

local function onLoginClaim(player: Player, day: any)
	if typeof(day) ~= "number" or day % 1 ~= 0 then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	roll(data)
	local login = data.rewards.login
	local reward = Rewards.LOGIN[day]
	local key = tostring(day)
	if not reward or day > login.days or login.claimed[key] then
		return
	end
	login.claimed[key] = true
	ProgressionService.Grant(player, reward, `login:{login.week}:{day}`)
	Net.Fire("Notify", player, "login.claimed", { n = day })
	syncAll(player)
end

local function onPetiOpen(player: Player)
	local data = DataService.Get(player)
	if not data or data.rewards.peti <= 0 then
		return
	end
	data.rewards.peti -= 1
	EconomyService.Add(player, "bunga", Rewards.PETI_BUNGA, "peti:bunga")
	Net.Fire("Notify", player, "peti.opened", { n = Rewards.PETI_BUNGA })
	syncAll(player)
end

local function onSeasonClaim(player: Player, track: any, day: any)
	if (track ~= "f2p" and track ~= "premium") or typeof(day) ~= "number" or day % 1 ~= 0 then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	roll(data)
	local season = data.rewards.season
	local _, today = Rewards.seasonNow(os.time())
	if day < 1 or day > Rewards.SEASON.DAYS or day > today then
		return
	end
	if track == "premium" and not season.premium then
		return
	end
	local claimed = if track == "premium" then season.premiumClaimed else season.f2p
	local key = tostring(day)
	if claimed[key] then
		return
	end
	claimed[key] = true
	ProgressionService.Grant(player, Rewards.seasonReward(track :: Rewards.Track, day), `season:{season.id}:{track}:{day}`)
	if track == "f2p" and day == Rewards.SEASON.DAYS then
		-- Season F2P hari terakhir = 1 Peti Bunga, sekali per season (Update owner 2026-11-22).
		data.rewards.peti += 1
		Net.Fire("Notify", player, "peti.new", nil)
	end
	syncAll(player)
end

local function onSeasonPremium(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if not Rewards.SEASON.PREMIUM_OPEN then
		Net.Fire("Notify", player, "season.premium_soon")
		return
	end
	roll(data)
	local season = data.rewards.season
	if season.premium then
		return
	end
	if not EconomyService.TrySpend(player, "bunga", Rewards.SEASON.PREMIUM_PRICE, `season:{season.id}:premium`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.bunga" })
		return
	end
	season.premium = true
	Net.Fire("Notify", player, "season.premium_on")
	syncAll(player)
end

function RewardsService.Init()
	DataService.Loaded:Connect(function(player: Player, data: Types.PlayerData)
		roll(data)
		checkTitles(player, data)
		syncAll(player)
	end)
end

function RewardsService.Start()
	Net.On("LoginClaim", onLoginClaim, { rate = 3, burst = 6 })
	Net.On("PetiOpen", onPetiOpen, { rate = 3, burst = 6 })
	Net.On("SeasonClaim", onSeasonClaim, { rate = 3, burst = 6 })
	Net.On("SeasonPremium", onSeasonPremium, { rate = 2, burst = 4 })
	task.spawn(function()
		while true do
			task.wait(TITLE_CHECK_SECONDS)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data and checkTitles(player, data) then
					syncAll(player)
				end
			end
		end
	end)
end

return RewardsService
