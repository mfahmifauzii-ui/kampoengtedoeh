--!strict
-- Hadiah playtime (Config/Progression PLAYTIME, Bab 15.2: 5 peti). The server counts ACTIVE seconds per WIB day: a tick only counts
-- when the character moved at least MOVE_STUDS since the last tick, so standing AFK earns nothing. The five peti open in
-- order, by hand (PlaytimeClaim). Attribute "PlaytimeSec" shows today's seconds on the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

local PlaytimeService = {}

local lastPosition: { [Player]: Vector3 } = {}

-- Starts a new WIB day when the day key changed: seconds and peti reset. Returns true when it rolled.
local function roll(player: Player, data: Types.PlayerData): boolean
	local today = TimeKeys.day()
	if data.playtime.day ~= today then
		data.playtime.day = today
		data.playtime.seconds = 0
		data.playtime.claimed = 0
		player:SetAttribute("PlaytimeSec", 0)
		return true
	end
	return false
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function tick()
	local config = Progression.PLAYTIME
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		local root = rootOf(player)
		if data and root then
			if roll(player, data) then
				InventoryService.Sync(player) -- the client's peti list must show the new day too
			end
			local position = root.Position
			local previous = lastPosition[player]
			lastPosition[player] = position
			if previous and (position - previous).Magnitude >= config.MOVE_STUDS then
				data.playtime.seconds += config.TICK
				player:SetAttribute("PlaytimeSec", data.playtime.seconds)
			end
		end
	end
end

-- Opens peti number `index`: it must be the next one in order and its minutes must be reached today.
local function onClaim(player: Player, index: any)
	if typeof(index) ~= "number" or index ~= math.floor(index) then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	roll(player, data)
	local chest = Progression.PLAYTIME.CHESTS[index]
	if not chest or index ~= data.playtime.claimed + 1 then
		return
	end
	if data.playtime.seconds < chest.minutes * 60 then
		Net.Fire("Notify", player, "chest.locked")
		return
	end
	data.playtime.claimed = index
	ProgressionService.Grant(player, chest.reward, `playtime:{data.playtime.day}:{index}`)
	Net.Fire("Notify", player, "chest.opened", { n = index })
end

function PlaytimeService.Init()
	DataService.Loaded:Connect(function(player: Player, data: Types.PlayerData)
		roll(player, data)
		player:SetAttribute("PlaytimeSec", data.playtime.seconds)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastPosition[player] = nil
	end)
end

function PlaytimeService.Start()
	Net.On("PlaytimeClaim", onClaim, { rate = 3, burst = 6 })
	task.spawn(function()
		while true do
			task.wait(Progression.PLAYTIME.TICK)
			tick()
		end
	end)
end

return PlaytimeService
