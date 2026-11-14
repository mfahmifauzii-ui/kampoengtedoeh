--!strict
-- Latest server snapshot (inventory, slots, upgrade tiers, rods). Read-only on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)

export type Snapshot = {
	items: { [string]: number },
	slotsUsed: number,
	slotsMax: number,
	backpackTier: number,
	pondTier: number,
	ponds: { { uid: number, cx: number, cz: number } },
	quests: { active: { [string]: { step: number, count: number } }, done: { [string]: boolean } },
	landChunks: { [string]: boolean }, -- bought chunks of your plot ("ix,iz" keys, Modules/Land)
	landExtra: number, -- how many chunks you bought
	landPrice: number, -- price of the next chunk (with the game pass discount)
	rod: string,
	ownedRods: { [string]: boolean },
	decorStock: { [string]: number },
	decorBlueprints: { [string]: boolean },
	decorPlaced: number,
	decorMax: number,
}

local State = {
	current = nil :: Snapshot?,
	Changed = Signal.new(), -- (snapshot)
}

Net.Listen("StateSync", function(snapshot: any)
	if typeof(snapshot) == "table" then
		State.current = snapshot
		State.Changed:Fire(snapshot)
	end
end)
Net.Send("StateRequest")

return State
