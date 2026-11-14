--!strict
-- Server-wide day cycle + rain. Publishes Workspace attributes:
--   CycleStart (number, os.time), DayPhase ("pagi"|"siang"|"sore"|"malam"), Raining (bool)
-- Clients render lighting/sound from these; gameplay (fish, crops) reads them on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local WorldClock = require(ReplicatedStorage.Shared.Modules.WorldClock)

local WorldService = {}
WorldService.RainChanged = Signal.new() -- (raining: boolean)
WorldService.PhaseChanged = Signal.new() -- (phase: string)

local random = Random.new()
local cycleStart = os.time() - (WorldClock.phaseOffset("pagi") or 0)
local rainEndsAt = 0
local nextRainCheck = 0

function WorldService.IsRaining(): boolean
	return Workspace:GetAttribute("Raining") == true
end

local function setRain(raining: boolean, duration: number?)
	if raining then
		rainEndsAt = os.time() + (duration or random:NextInteger(World.RAIN.MIN_SECONDS, World.RAIN.MAX_SECONDS))
	end
	if WorldService.IsRaining() ~= raining then
		Workspace:SetAttribute("Raining", raining)
		WorldService.RainChanged:Fire(raining)
	end
end

local function tick()
	local now = os.time()
	local phase = WorldClock.at(now, cycleStart)
	if Workspace:GetAttribute("DayPhase") ~= phase then
		Workspace:SetAttribute("DayPhase", phase)
		WorldService.PhaseChanged:Fire(phase)
	end

	if WorldService.IsRaining() then
		if now >= rainEndsAt then
			setRain(false)
		end
	elseif now >= nextRainCheck then
		nextRainCheck = now + World.RAIN.CHECK_INTERVAL
		if random:NextNumber() < World.RAIN.CHANCE then
			setRain(true)
		end
	end
end

function WorldService.Init()
	Workspace:SetAttribute("CycleStart", cycleStart)
	Workspace:SetAttribute("Raining", false)
	nextRainCheck = os.time() + World.RAIN.CHECK_INTERVAL -- first roll after 20 min
	tick()
end

function WorldService.Start()
	while true do
		task.wait(1)
		tick()
	end
end

-- Studio testing only (DevService).
function WorldService.DevSetPhase(phase: string)
	local offset = WorldClock.phaseOffset(phase)
	if offset then
		cycleStart = os.time() - offset
		Workspace:SetAttribute("CycleStart", cycleStart)
		tick()
	end
end

function WorldService.DevToggleRain()
	setRain(not WorldService.IsRaining(), 300)
end

return WorldService
