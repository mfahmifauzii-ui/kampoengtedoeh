--!strict
-- Settings panel (HUD "SettingsButton" / placeholder "Atur"): music, nature sounds, SFX.
-- Values are saved on the server and come back through the state snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local KEYS = { "music", "ambient", "sfx" }

local SettingsController = {}

local panel: UiKit.Panel

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	local settings = snapshot and snapshot.settings or {}
	for order, key in KEYS do
		local on = settings[key] ~= false
		UiKit.row(panel.list, order, Locale.t(`settings.{key}`), nil, Locale.t(if on then "settings.on" else "settings.off"), true, function()
			Net.Send("SettingsSet", key, not on)
		end)
	end
end

function SettingsController.Init()
	panel = UiKit.panel("SettingsPanel", Locale.t("ui.settings"), function()
		panel.gui.Enabled = false
	end)
end

function SettingsController.Start()
	State.Changed:Connect(render)
	task.spawn(UiKit.hudButton, "SettingsButton", Locale.t("ui.settings"), 5, function()
		panel.gui.Enabled = not panel.gui.Enabled
		render()
	end)
end

return SettingsController
