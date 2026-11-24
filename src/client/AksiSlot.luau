--!strict
-- The Aksi slot rule (K-104, GUI 4.6 / HUD map). Several controllers own a round Aksi button (Pukul, Pancing, Bubu, Kolam,
-- Kelola kandang, Dapur). Only ONE of them is shown at a time:
--   1. Each controller registers a probe: `probe()` returns (distance in studs, object name) when its object is in range,
--      or nothing when it is not. `apply(visible)` shows or hides that controller's button.
--   2. Every 0.1 s the winner is picked: the nearest in-range object wins.
--   3. A tie (distances within TIE_STUDS) goes to the object that a tracked quest points at (its step target, see
--      QuestController -> AksiSlot.setTracked). If still tied, the lower priority number wins (see PRIORITY in the doc).
-- Positions of the buttons are unchanged; the rule only decides which one is visible.

local RunService = game:GetService("RunService")

local AksiSlot = {}

local TIE_STUDS = 1.5
local PERIOD = 0.1

export type Probe = () -> (number?, string?)

type Entry = { id: string, priority: number, probe: Probe, apply: (boolean) -> () }

local entries: { Entry } = {}
local tracked: { [string]: boolean } = {}
local winnerId: string? = nil

-- priority: lower wins a full tie. Pancing 1, Pukul 2, Bubu 3, Kelola 4, Kolam 5, Dapur (Masak / Pasang Tungku) 6.
function AksiSlot.register(id: string, priority: number, probe: Probe, apply: (boolean) -> ())
	table.insert(entries, { id = id, priority = priority, probe = probe, apply = apply })
end

-- The object names a tracked quest points at right now (QuestController calls this on every refresh).
function AksiSlot.setTracked(names: { string })
	tracked = {}
	for _, name in names do
		tracked[name] = true
	end
end

-- The id of the button that is shown now (nil = none). For checks and the Handoff notes.
function AksiSlot.Winner(): string?
	return winnerId
end

local function pick()
	local best: Entry? = nil
	local bestDistance = math.huge
	local bestTied = false
	for _, entry in entries do
		local distance, name = entry.probe()
		if distance ~= nil then
			local tied = name ~= nil and tracked[name] == true
			local closer = distance < bestDistance - TIE_STUDS
			local sameDistance = math.abs(distance - bestDistance) <= TIE_STUDS
			local wins = best == nil or closer
			if not wins and sameDistance then
				if tied ~= bestTied then
					wins = tied -- the tracked quest's object beats the other one
				else
					wins = best ~= nil and entry.priority < best.priority
				end
			end
			if wins then
				best, bestDistance, bestTied = entry, distance, tied
			end
		end
	end
	return best
end

function AksiSlot.Start()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < PERIOD then
			return
		end
		elapsed = 0
		local winner = pick()
		winnerId = if winner then winner.id else nil
		for _, entry in entries do
			entry.apply(entry == winner)
		end
	end)
end

return AksiSlot
