--!strict
-- Latest server snapshot (inventory, upgrade tiers, rods). Read-only on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)

export type Snapshot = {
	items: { [string]: number },
	bait: { id: string, count: number }?, -- F-3: the bait a cast uses now (server: InventoryService.ActiveBait); nil = none
	features: { [string]: string }?, -- Q-2 feature gate: "introduced" | "open" per fitur quest (FeatureClient reads this)
	playtime: { day: string, seconds: number, claimed: number }, -- Hadiah playtime (seconds is live via the "PlaytimeSec" attribute)
	pondTier: number,
	pondKakek: boolean?, -- Kolam Kakek pulih (MQ4 / Bundel, v7.4 Bab 16.5): satu-satunya gate kolam
	ponds: { { uid: number, cx: number, cz: number } },
	quests: { active: { [string]: { step: number, count: number } }, done: { [string]: boolean }, daily: { day: string, kind: string, progress: number, claimed: boolean } },
	landChunks: { [string]: boolean }, -- bought chunks of your plot ("ix,iz" keys, Modules/Land)
	landExtra: number, -- how many chunks you bought
	landPrice: number, -- price of the next chunk (with the game pass discount)
	rod: string,
	ownedRods: { [string]: boolean },
	tools: { [string]: boolean },
	decorStock: { [string]: number },
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
