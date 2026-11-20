--!strict
-- Server-wide day cycle + weather (Config/Weather, Bab 3.3). Publishes Workspace attributes:
--   CycleStart (number, os.time), DayPhase ("pagi"|"siang"|"sore"|"malam"),
--   Weather ("terik"|"gerimis"|"deres"|"petir"|"pelangi"), WeatherEndsAt (os.time), Raining (bool: gerimis/deres/petir)
-- Clients render lighting/sound from these; gameplay (fish, crops, Mutasi) reads them on the server.
-- Server-local: every server runs its own cycle. Nothing is saved or shared between servers (Prinsip #16).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeatherConfig = require(ReplicatedStorage.Shared.Config.Weather)
local World = require(ReplicatedStorage.Shared.Config.World)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local WorldClock = require(ReplicatedStorage.Shared.Modules.WorldClock)

local WorldService = {}
WorldService.RainChanged = Signal.new() -- (raining: boolean): true when Gerimis/Deres/Petir starts, false when it ends
WorldService.RainEnded = Signal.new() -- (kind: string): the rain kind that just ended (Fase 6 Kerja Bakti Kilat listens here)
WorldService.WeatherChanged = Signal.new() -- (kind: string, previous: string)
WorldService.PhaseChanged = Signal.new() -- (phase: string)

local random = Random.new()
local cycleStart = os.time() - (WorldClock.offsetForClock(World.START_CLOCK) or 0) -- every new server starts at START_CLOCK

local weather = "terik"
local weatherEndsAt = 0
-- Past weather windows on this server: { kind, from, to }. `to` is nil for the current one.
local history: { { kind: string, from: number, to: number? } } = {}

local function randomTerik(): number
	return random:NextInteger(WeatherConfig.TERIK_MIN_SECONDS, WeatherConfig.TERIK_MAX_SECONDS)
end

-- Roll the rain kind when Terik ends (55 / 30 / 15 by default).
local function rollRain(): string
	local roll = random:NextNumber()
	local acc = 0
	for _, entry in WeatherConfig.RAIN_ROLL do
		acc += entry.chance
		if roll < acc then
			return entry.kind
		end
	end
	return WeatherConfig.RAIN_ROLL[#WeatherConfig.RAIN_ROLL].kind
end

function WorldService.IsRaining(): boolean
	return WeatherConfig.IS_RAIN[weather] == true
end

-- The current weather kind on this server.
function WorldService.CurrentWeather(): string
	return weather
end

-- The weather kind at os.time `t` on this server. nil when `t` is before this server started or older than
-- WeatherConfig.HISTORY_SECONDS. Mutasi uses it: "the weather when this crop finished growing".
function WorldService.WeatherAt(t: number): string?
	for i = #history, 1, -1 do
		local entry = history[i]
		if t >= entry.from and (entry.to == nil or t < entry.to) then
			return entry.kind
		end
	end
	return nil
end

local function setWeather(kind: string, seconds: number)
	local now = os.time()
	local previous = weather
	local wasRain = WeatherConfig.IS_RAIN[previous] == true
	local isRain = WeatherConfig.IS_RAIN[kind] == true

	local last = history[#history]
	if last then
		last.to = now
	end
	table.insert(history, { kind = kind, from = now })
	while #history > 0 and history[1].to ~= nil and (history[1].to :: number) < now - WeatherConfig.HISTORY_SECONDS do
		table.remove(history, 1)
	end

	weather = kind
	weatherEndsAt = now + seconds
	Workspace:SetAttribute("Weather", kind)
	Workspace:SetAttribute("WeatherEndsAt", weatherEndsAt)
	if isRain ~= wasRain then
		Workspace:SetAttribute("Raining", isRain)
		WorldService.RainChanged:Fire(isRain)
	end
	if previous ~= kind then
		WorldService.WeatherChanged:Fire(kind, previous)
	end
	if wasRain and not isRain then
		WorldService.RainEnded:Fire(previous)
	end
end

-- Terik -> rain (3 menit). Rain -> 40% Pelangi after Deres/Petir (60 detik), else Terik. Pelangi -> Terik.
local function advance()
	if weather == "terik" then
		setWeather(rollRain(), WeatherConfig.RAIN_SECONDS)
	elseif WeatherConfig.IS_RAIN[weather] then
		if WeatherConfig.PELANGI_AFTER[weather] and random:NextNumber() < WeatherConfig.PELANGI_CHANCE then
			setWeather("pelangi", WeatherConfig.PELANGI_SECONDS)
		else
			setWeather("terik", randomTerik())
		end
	else
		setWeather("terik", randomTerik())
	end
end

local function tick()
	local now = os.time()
	local phase = WorldClock.at(now, cycleStart)
	if Workspace:GetAttribute("DayPhase") ~= phase then
		Workspace:SetAttribute("DayPhase", phase)
		WorldService.PhaseChanged:Fire(phase)
	end

	if now >= weatherEndsAt then
		advance()
	end
end

function WorldService.Init()
	Workspace:SetAttribute("CycleStart", cycleStart)
	Workspace:SetAttribute("Raining", false)
	setWeather("terik", randomTerik()) -- the first Terik of a new server is random too
	tick()
end

function WorldService.Start()
	while true do
		task.wait(1)
		tick()
	end
end

-- Tutorial Gerimis (FTUE 0:30): rain for `seconds`, unless it already rains. Rain waters every crop (FarmService).
-- After it ends the normal cycle goes on (Terik).
function WorldService.TutorialRain(seconds: number)
	if not WorldService.IsRaining() then
		setWeather("gerimis", seconds)
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

-- Studio testing only: "!rain" toggles a 300 s Gerimis.
function WorldService.DevToggleRain()
	if WorldService.IsRaining() then
		setWeather("terik", randomTerik())
	else
		setWeather("gerimis", 300)
	end
end

-- Studio testing only: "!cuaca <kind>" starts that weather with its normal duration.
function WorldService.DevSetWeather(kind: string): boolean
	if kind == "terik" then
		setWeather("terik", randomTerik())
	elseif WeatherConfig.IS_RAIN[kind] then
		setWeather(kind, WeatherConfig.RAIN_SECONDS)
	elseif kind == "pelangi" then
		setWeather("pelangi", WeatherConfig.PELANGI_SECONDS)
	else
		return false
	end
	return true
end

return WorldService
