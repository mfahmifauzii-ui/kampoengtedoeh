--!strict
-- Buying land (R2b). A plot's reserved square is 192 x 192 studs; the player owns the 128 x 128 start land plus the
-- 16 x 16 chunks they bought (data.land.chunks, Modules/Land). Every request is checked on the server: the chunk must
-- be inside the square, not owned, and touch owned land; the price comes from Land.chunkPrice (game pass discount).
-- Buying paints the chunk bright grass, hides the forest on it and moves the fence out (MapService).
--   LandBuy(ix, iz)    chunk indices in plot-local chunks (x = ix * 16, z = iz * 16)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Plots = require(ReplicatedStorage.Shared.Config.Plots)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local MapService = require(script.Parent.MapService)
local MonetizationService = require(script.Parent.MonetizationService)
local PlotService = require(script.Parent.PlotService)

local RATE = { rate = 4, burst = 8 }

local LandService = {}

-- Price of the next chunk for this player (the "plots" pass takes Plots.CHUNK.PASS_DISCOUNT off).
function LandService.NextPrice(player: Player, extraOwned: number): number
	local discount = if MonetizationService.HasPass(player, "plots") then Plots.CHUNK.PASS_DISCOUNT else 0
	return Land.chunkPrice(extraOwned, discount)
end

-- Paints and clears every extra chunk of a plot to match `chunks`. Does nothing for a chunk that is already right.
local function applyOwnership(plotIndex: number, chunks: Land.Chunks)
	for ix = Land.CHUNK_MIN, Land.CHUNK_MAX do
		for iz = Land.CHUNK_MIN, Land.CHUNK_MAX do
			if not Land.isStartChunk(ix, iz) then
				MapService.SetChunkOwned(plotIndex, ix, iz, chunks[Land.chunkKey(ix, iz)] == true)
			end
		end
	end
	MapService.RebuildFence(plotIndex, chunks)
end

local function isChunkIndex(value: any): boolean
	return typeof(value) == "number" and value % 1 == 0 and value >= Land.CHUNK_MIN and value <= Land.CHUNK_MAX
end

local function onBuy(player: Player, ix: any, iz: any)
	if not isChunkIndex(ix) or not isChunkIndex(iz) then
		return
	end
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	local plotIndex = if plot then PlotService.PlotIndex(plot) else nil
	if not data or not plot or not plotIndex then
		return
	end
	local chunks = data.land.chunks
	if not Land.canBuyChunk(ix, iz, chunks) then
		Net.Fire("Notify", player, "land.invalid")
		return
	end
	local owned = Land.extraCount(chunks)
	if not EconomyService.TrySpend(player, "koin", LandService.NextPrice(player, owned), `land:{owned + 1}`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
		return
	end

	chunks[Land.chunkKey(ix, iz)] = true
	MapService.SetChunkOwned(plotIndex, ix, iz, true)
	MapService.RebuildFence(plotIndex, chunks)
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "land.bought", { n = owned + 1, max = Land.EXTRA_CHUNKS })
end

function LandService.Init()
	-- The plot's ground follows its player: their chunks when they arrive, the plain start land when they leave.
	PlotService.Assigned:Connect(function(player: Player, plot: Model)
		local data = DataService.Get(player)
		local plotIndex = PlotService.PlotIndex(plot)
		if data and plotIndex then
			applyOwnership(plotIndex, data.land.chunks)
		end
	end)
	PlotService.Released:Connect(function(_player: Player, plot: Model)
		local plotIndex = PlotService.PlotIndex(plot)
		if not plotIndex then
			return
		end
		-- Deferred: the farm and pond services tidy their own terrain on release first, then the ground is reset.
		task.defer(function()
			if PlotService.GetOwner(plot) == nil then
				applyOwnership(plotIndex, {})
			end
		end)
	end)
end

function LandService.Start()
	Net.On("LandBuy", onBuy, RATE)
end

return LandService
