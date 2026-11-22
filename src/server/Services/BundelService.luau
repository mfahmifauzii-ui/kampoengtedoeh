--!strict
-- Bundel Kakek (Bab 14.6, LOCKED, P2-7-fix): kumpul setoran bertahap, selesai = hadiah + flag.
-- Net "BundelGive" (bundelId, itemId, count?): setor barang ke kebutuhan yang cocok dan belum penuh.
-- Selesai 1 bundel -> QuestService.Report "bundel_done" (MQ10). Tidak ada UI khusus (P2-8/P2-9);
-- status kebaca di snapshot (data.bundel) untuk UI mendatang.
-- Sumur Tua: siram 1 petak otomatis per login (1x/hari) selama bundelnya pulih.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bundel = require(ReplicatedStorage.Shared.Config.Bundel)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local FarmService = require(script.Parent.FarmService)
local InventoryService = require(script.Parent.InventoryService)
local QuestService = require(script.Parent.QuestService)

local BundelService = {}

local RATE = { rate = 4, burst = 8 }

local function stateOf(data: Types.PlayerData, id: string): { given: { [string]: number }, done: boolean }
	local bag = data.bundel :: any
	local entry = bag[id]
	if typeof(entry) ~= "table" then
		entry = { given = {}, done = false }
		bag[id] = entry
	end
	return entry
end

-- Apakah itemId memenuhi need ("id persis" atau matcher ":any").
local function matches(need: string, itemId: string): boolean
	if need == itemId then
		return true
	end
	if need == "olahan:any" then
		local info = Items.info(itemId)
		return info ~= nil and info.kind == "olahan"
	elseif need == "prima:any" then
		local base = itemId
		return base:match("^prima_") ~= nil
	elseif need == "early:any" or need == "jumbo:any" then
		local fishId, size = itemId:match("^(.+)@(.+)$")
		local fish = fishId and FishConfig.byId[fishId]
		if not fish then
			return false
		end
		if need == "jumbo:any" then
			return size == "Jumbo"
		end
		return fish.rarity == "C" -- Early = rarity C (Dapur FISH_CAT)
	end
	return false
end

local function isComplete(def: Bundel.Bundel, given: { [string]: number }): boolean
	for _, want in def.needs do
		if (given[want.need] or 0) < want.count then
			return false
		end
	end
	return true
end

local function onGive(player: Player, bundelId: any, itemId: any, count: any)
	if typeof(bundelId) ~= "string" or typeof(itemId) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	local def = Bundel.byId[bundelId]
	if not data or not def then
		return
	end
	if data.level < def.unlockLevel then
		Net.Fire("Notify", player, "bundel.locked", { level = def.unlockLevel })
		return
	end
	local state = stateOf(data, bundelId)
	if state.done then
		return
	end
	local want = math.clamp(if typeof(count) == "number" then math.floor(count) else 1, 1, 99)
	for _, need in def.needs do
		local have = state.given[need.need] or 0
		if have < need.count and matches(need.need, itemId) then
			local room = need.count - have
			local take = math.min(room, want, InventoryService.Count(player, itemId))
			if take > 0 then
				InventoryService.Remove(player, itemId, take)
				state.given[need.need] = have + take
				want -= take
				local info = Items.info(itemId)
				Net.Fire("Notify", player, "bundel.give", { n = take, item = if info then Items.displayName(info) else itemId })
			end
			if want <= 0 then
				break
			end
		end
	end
	if isComplete(def, state.given) then
		state.done = true
		if def.rewardKoin > 0 then
			EconomyService.Add(player, "koin", def.rewardKoin, `bundel:{def.id}`)
		end
		if def.rewardBunga and def.rewardBunga > 0 then
			EconomyService.Add(player, "bunga", def.rewardBunga, `bundel:{def.id}`)
		end
		if def.rewardDecor then
			data.decor.stock[def.rewardDecor] = (data.decor.stock[def.rewardDecor] or 0) + 1
		end
		if def.rewardFreePond == true then
			data.pond.freeBuilds += 1
		end
		if def.rewardKakek == true then
			data.pond.kakekUnlocked = true
		end
		InventoryService.Sync(player)
		Net.Fire("Notify", player, "bundel.done", { bundel = `bundel.{def.id}` })
		QuestService.Report(player, "bundel_done")
		QuestService.Report(player, `bundel_{def.id}`) -- Quest M9: "bundel_sumur_tua"
	end
	InventoryService.Sync(player)
end

function BundelService.Init()
	DataService.Loaded:Connect(function(player: Player)
		local data = DataService.Get(player)
		if not data then
			return
		end
		-- Sumur Tua: siram 1 petak otomatis 1x/hari (Bab 14.6).
		local bag = data.bundel :: any
		local sumur = bag.sumur_tua
		if typeof(sumur) == "table" and sumur.done == true then
			local today = TimeKeys.day()
			if bag.sumur_day ~= today then
				bag.sumur_day = today
				FarmService.WaterFor(player, data)
				InventoryService.Sync(player)
			end
		end
	end)
end

function BundelService.Start()
	Net.On("BundelGive", onGive, RATE)
end

return BundelService
