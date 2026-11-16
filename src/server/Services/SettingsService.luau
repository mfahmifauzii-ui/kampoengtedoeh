--!strict
-- Saved per-player settings (audio toggles, music / SFX volume, picture quality). Sent to the client in the state snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local SWITCH_KEYS = { music = true, ambient = true, sfx = true } -- booleans
local VOLUME_KEYS = { musicVol = true, sfxVol = true } -- 0..1
local QUALITY_KEY = "quality" -- 1, 2 or 3

local SettingsService = {}

local function onSet(player: Player, key: any, value: any)
	local data = DataService.Get(player)
	if not data or typeof(key) ~= "string" then
		return
	end
	local settings = data.settings :: any
	if SWITCH_KEYS[key] and typeof(value) == "boolean" then
		settings[key] = value
	elseif VOLUME_KEYS[key] and typeof(value) == "number" and value == value then
		settings[key] = math.clamp(value, 0, 1)
	elseif key == QUALITY_KEY and typeof(value) == "number" and value % 1 == 0 and value >= 1 and value <= 3 then
		settings[key] = value
	else
		return
	end
	InventoryService.Sync(player)
end

function SettingsService.Start()
	Net.On("SettingsSet", onSet, { rate = 4, burst = 8 })
end

return SettingsService
