--!strict
-- Saved per-player settings (audio toggles). Sent to the client in the state snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local VALID_KEYS = { music = true, ambient = true, sfx = true }

local SettingsService = {}

local function onSet(player: Player, key: any, value: any)
	local data = DataService.Get(player)
	if not data or typeof(key) ~= "string" or not VALID_KEYS[key] or typeof(value) ~= "boolean" then
		return
	end
	(data.settings :: any)[key] = value
	InventoryService.Sync(player)
end

function SettingsService.Start()
	Net.On("SettingsSet", onSet, { rate = 4, burst = 8 })
end

return SettingsService
