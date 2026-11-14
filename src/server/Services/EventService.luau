--!strict
-- Seasonal events from Config/Events. Publishes Workspace attribute "ActiveEvent" (id or nil)
-- and greets players with one toast while an event runs. No timers or pressure in UI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Config.Events)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local DataService = require(script.Parent.DataService)

local EventService = {}

local override: string? = nil -- Studio "!event <id>" / "!event off"
local overrideSet = false

local function computeActive(): string?
	if overrideSet then
		return override
	end
	local today = TimeKeys.day()
	for _, event in Events.list do
		if today >= event.from and today <= event.to then
			return event.id
		end
	end
	return nil
end

local function greet(player: Player, id: string)
	if not player.Parent then
		return
	end
	Net.Fire("Notify", player, "event.started", { name = `event.{id}`, desc = `event.{id}.desc` })
end

local function refresh()
	local active = computeActive()
	if Workspace:GetAttribute("ActiveEvent") == active then
		return
	end
	Workspace:SetAttribute("ActiveEvent", active)
	if active then
		for _, player in Players:GetPlayers() do
			greet(player, active)
		end
	end
end

function EventService.Active(): string?
	return Workspace:GetAttribute("ActiveEvent") :: string?
end

function EventService.IsActive(id: string): boolean
	return EventService.Active() == id
end

-- id = event id, "off" = force none, "auto" = back to the calendar.
function EventService.DevSet(id: string)
	if id == "auto" then
		overrideSet, override = false, nil
	elseif id == "off" then
		overrideSet, override = true, nil
	elseif Events.byId[id] then
		overrideSet, override = true, id
	else
		warn(`[EventService] Unknown event "{id}". Use: off, auto, or an id from Config/Events`)
		return
	end
	refresh()
	print(`[EventService] ActiveEvent = {EventService.Active()}`)
end

function EventService.Init()
	refresh()
	DataService.Loaded:Connect(function(player: Player)
		local active = EventService.Active()
		if active then
			task.delay(4, greet, player, active) -- after the join toasts
		end
	end)
end

function EventService.Start()
	while true do
		task.wait(Events.CHECK_SECONDS)
		refresh()
	end
end

return EventService
