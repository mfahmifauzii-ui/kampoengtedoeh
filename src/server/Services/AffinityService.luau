--!strict
-- Kedekatan (affinity) with each NPC, 0..100, in data.npc[npcId] (Config/Npcs TIERS).
--   +2 for the first chat of the day, +1 per trade (up to 5 per NPC per day), +1 per won haggle,
--   -1 per lost haggle (never below the tier you already reached).
-- Tiers give a discount on what you buy and a haggling bonus (see Modules/Trade).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local AffinityService = {}

-- The player's record for an NPC (created on first contact). nil if the NPC id is unknown.
function AffinityService.Record(player: Player, npcId: string): Types.NpcRecord?
	local data = DataService.Get(player)
	if not data or not Npcs.byId[npcId] then
		return nil
	end
	local entry = data.npc[npcId]
	if not entry then
		entry = { affinity = 0, talkDay = "", tradeDay = "", tradeGain = 0, failStreak = 0, pauseUntil = 0 }
		data.npc[npcId] = entry
	end
	return entry
end

function AffinityService.Get(player: Player, npcId: string): number
	local entry = AffinityService.Record(player, npcId)
	return if entry then entry.affinity else 0
end

-- 1 = Asing ... 4 = Sahabat
function AffinityService.Tier(player: Player, npcId: string): number
	return Npcs.tierOf(AffinityService.Get(player, npcId))
end

local function add(player: Player, npcId: string, delta: number)
	local entry = AffinityService.Record(player, npcId)
	if not entry or delta == 0 then
		return
	end
	local before = Npcs.tierOf(entry.affinity)
	local floor = if delta < 0 then Npcs.TIERS[before].min else 0
	entry.affinity = math.clamp(entry.affinity + delta, floor, Npcs.AFFINITY.MAX)
	local after = Npcs.tierOf(entry.affinity)
	if after > before then
		Net.Fire("Notify", player, "npc.tier_up", { npc = `npc.{npcId}`, tier = `npc.tier.{Npcs.TIERS[after].id}` })
	end
	InventoryService.Sync(player)
end

-- First "Ngobrol" of the WIB day.
function AffinityService.OnTalk(player: Player, npcId: string)
	local entry = AffinityService.Record(player, npcId)
	local today = TimeKeys.day()
	if entry and entry.talkDay ~= today then
		entry.talkDay = today
		add(player, npcId, Npcs.AFFINITY.TALK_GAIN)
	end
end

-- Every successful buy or sell (capped per day so grinding tiny trades isn't the way).
function AffinityService.OnTrade(player: Player, npcId: string)
	local entry = AffinityService.Record(player, npcId)
	local today = TimeKeys.day()
	if not entry then
		return
	end
	if entry.tradeDay ~= today then
		entry.tradeDay = today
		entry.tradeGain = 0
	end
	if entry.tradeGain < Npcs.AFFINITY.TRADE_DAILY_CAP then
		entry.tradeGain += Npcs.AFFINITY.TRADE_GAIN
		add(player, npcId, Npcs.AFFINITY.TRADE_GAIN)
	end
end

function AffinityService.OnHaggle(player: Player, npcId: string, won: boolean)
	add(player, npcId, if won then Npcs.AFFINITY.HAGGLE_WIN else -Npcs.AFFINITY.HAGGLE_LOSS)
end

-- Studio testing only (DevService).
function AffinityService.DevSet(player: Player, npcId: string, points: number)
	local entry = AffinityService.Record(player, npcId)
	if entry then
		entry.affinity = math.clamp(math.floor(points), 0, Npcs.AFFINITY.MAX)
		InventoryService.Sync(player)
	end
end

return AffinityService
