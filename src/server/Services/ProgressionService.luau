--!strict
-- XP + levels, generic reward granting, and Kunjungan Harian (daily visit reward).
-- Player attributes for the HUD: "Level", "XP" (progress inside the level), "XPNext".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blueprints = require(ReplicatedStorage.Shared.Config.Blueprints)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Decor = require(ReplicatedStorage.Shared.Config.Decor)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)

type Reward = Progression.Reward

local ProgressionService = {}
ProgressionService.LevelUp = Signal.new() -- (player, newLevel)

local function syncAttributes(player: Player, data: Types.PlayerData)
	player:SetAttribute("Level", data.level)
	player:SetAttribute("XP", data.xp)
	player:SetAttribute("SP", data.sp)
	player:SetAttribute("XPNext", if data.level >= Progression.MAX_LEVEL then 0 else Progression.xpToNext(data.level))
end

-- Locale keys of everything that unlocks exactly at `level`.
local function unlocksAt(level: number): { string }
	local keys = {}
	for _, crop in Crops.list do
		if crop.unlockLevel == level then
			table.insert(keys, `crop.{crop.id}`)
		end
	end
	for _, rod in Fishing.rodList do
		if rod.unlockLevel == level and rod.price > 0 then
			table.insert(keys, `rod.{rod.id}`)
		end
	end
	for location, config in Fishing.LOCATIONS do
		if config.unlockLevel == level and level > 1 then
			table.insert(keys, `location.{location}`)
		end
	end
	for upgradeId, config in Shop.UPGRADES do
		if config.unlockLevel == level and level > 1 then
			table.insert(keys, `upgrade.{upgradeId}`)
		end
	end
	for _, blueprint in Blueprints.list do
		if blueprint.unlockLevel == level and level > 1 then
			table.insert(keys, `blueprint.{blueprint.id}`)
		end
	end
	return keys
end

-- Grants a reward table (see Config/Progression). Returns nothing; each part notifies itself.
function ProgressionService.Grant(player: Player, reward: Reward, reason: string)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if reward.koin then
		EconomyService.Add(player, "koin", reward.koin, reason)
	end
	if reward.bunga then
		EconomyService.Add(player, "bunga", reward.bunga, reason)
	end
	if reward.items then
		for itemId, amount in reward.items do
			InventoryService.Add(player, itemId, amount)
		end
	end
	if reward.decor then
		for decorId, amount in reward.decor do
			if Decor.byId[decorId] then
				data.decor.stock[decorId] = (data.decor.stock[decorId] or 0) + amount
			end
		end
	end
	if reward.title then
		data.titles[reward.title] = true
	end
	if reward.xp then
		ProgressionService.AddXp(player, reward.xp, reason)
	end
	InventoryService.Sync(player)
end

-- Level Cabang XP (Bab 4.2): the same amount as the action's Player XP. branch = bertani | mancing | beternak | tukang.
function ProgressionService.AddCabangXp(player: Player, branch: string, amount: number)
	local data = DataService.Get(player)
	local cabang = data and data.cabang[branch]
	if not cabang or typeof(amount) ~= "number" or amount <= 0 or cabang.lv >= Progression.CABANG.MAX_LEVEL then
		return
	end
	cabang.xp += math.floor(amount)
	while cabang.lv < Progression.CABANG.MAX_LEVEL and cabang.xp >= Progression.CABANG.XP[cabang.lv + 1] do
		cabang.xp -= Progression.CABANG.XP[cabang.lv + 1]
		cabang.lv += 1
	end
	if cabang.lv >= Progression.CABANG.MAX_LEVEL then
		cabang.xp = 0
	end
end

function ProgressionService.AddXp(player: Player, amount: number, _reason: string)
	local data = DataService.Get(player)
	if not data or typeof(amount) ~= "number" or amount <= 0 or data.level >= Progression.MAX_LEVEL then
		return
	end
	data.xp += math.floor(amount)

	while data.level < Progression.MAX_LEVEL and data.xp >= Progression.xpToNext(data.level) do
		data.xp -= Progression.xpToNext(data.level)
		data.level += 1
		data.sp += 1 -- Skill Point: 1 per Level Player (Bab 4.2)
		syncAttributes(player, data)
		local unlocks = unlocksAt(data.level)
		Net.Fire("Notify", player, if #unlocks > 0 then "level.up_unlocks" else "level.up", { level = data.level, unlocks = unlocks })
		ProgressionService.LevelUp:Fire(player, data.level)
	end
	if data.level >= Progression.MAX_LEVEL then
		data.xp = 0
	end
	syncAttributes(player, data)
end

-- Studio testing only (DevService).
function ProgressionService.DevSetLevel(player: Player, level: number)
	local data = DataService.Get(player)
	if data then
		data.level = math.clamp(level, 1, Progression.MAX_LEVEL)
		data.xp = 0
		syncAttributes(player, data)
		InventoryService.Sync(player)
		ProgressionService.LevelUp:Fire(player, data.level) -- lets level-gated things (quests) start while testing
	end
end

-- Kunjungan Harian: first time we see the player on a new WIB day.
-- Stage fix (user, 16 Nov): the daily bonus is NOT given before the first tutorial (T1) is over. It waits, and is
-- claimed right after T1 (TutorialService calls CheckDailyVisit). Skipping T1 also unlocks it.
local function checkDailyVisit(player: Player)
	local data = DataService.Get(player)
	local today = TimeKeys.day()
	if not data or data.visits.lastDay == today then
		return
	end
	if data.guide.done.t1_awal ~= true and data.guide.skipped.t1_awal ~= true then
		return
	end
	-- Not paid automatically any more: it becomes CLAIMABLE (visits.pending) and the player taps "Ambil hadiah" in Panduan.
	data.visits.lastDay = today
	data.visits.pending = true
	InventoryService.Sync(player)
end

-- The claim (Net VisitClaim): pays today's Kunjungan Harian once.
local function onVisitClaim(player: Player)
	local data = DataService.Get(player)
	if not data or data.visits.pending ~= true then
		return
	end
	data.visits.pending = false
	data.visits.count += 1
	local step = (data.visits.count - 1) % #Progression.VISIT_REWARDS + 1
	ProgressionService.Grant(player, Progression.VISIT_REWARDS[step], `visit:{data.visits.count}`)
	Net.Fire("Notify", player, "visit.reward", { day = data.visits.count, step = step })
	InventoryService.Sync(player)
end

ProgressionService.CheckDailyVisit = checkDailyVisit

function ProgressionService.Init()
	Net.On("VisitClaim", onVisitClaim, { rate = 3, burst = 6 })
	DataService.Loaded:Connect(function(player: Player, data: Types.PlayerData)
		syncAttributes(player, data)
		task.delay(3, checkDailyVisit, player) -- after the HUD is up
	end)
end

function ProgressionService.Start()
	-- Players online across midnight WIB still get the next day's visit.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				checkDailyVisit(player)
			end
		end
	end)
end

return ProgressionService
