--!strict
-- Pure day-cycle math shared by server (phase changes) and client (smooth ClockTime).

local World = require(script.Parent.Parent.Config.World)

local WorldClock = {}

-- Returns (phase, ClockTime 0..24, progress 0..1 within the phase).
function WorldClock.at(now: number, cycleStart: number): (string, number, number)
	local t = (now - cycleStart) % World.CYCLE_SECONDS
	for _, entry in World.CYCLE do
		local length = entry.minutes * 60
		if t < length then
			local progress = t / length
			local clock = entry.clockFrom + (entry.clockTo - entry.clockFrom) * progress
			return entry.phase, clock % 24, progress
		end
		t -= length
	end
	local last = World.CYCLE[#World.CYCLE]
	return last.phase, last.clockTo % 24, 1
end

-- Seconds into the cycle where the given clock hour (0..24) falls, so a cycle can start at any time of day.
function WorldClock.offsetForClock(hour: number): number?
	local offset = 0
	for _, entry in World.CYCLE do
		local from = entry.clockFrom
		local to = entry.clockTo
		local h = hour
		if h < from then
			h += 24
		end
		if h >= from and h < to then
			return offset + (h - from) / (to - from) * entry.minutes * 60
		end
		offset += entry.minutes * 60
	end
	return nil
end

-- Seconds into the cycle where `phase` starts.
function WorldClock.phaseOffset(phase: string): number?
	local offset = 0
	for _, entry in World.CYCLE do
		if entry.phase == phase then
			return offset
		end
		offset += entry.minutes * 60
	end
	return nil
end

return WorldClock
