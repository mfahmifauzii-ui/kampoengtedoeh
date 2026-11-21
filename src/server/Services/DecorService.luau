--!strict
-- Decor placement on the owner's plot: place (from stock, or buy), move/rotate, store.
-- Saved as grid cells in data.decor.placed; models are rebuilt from data on join.
-- Players can only ever touch their own data, so ownership is implicit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Decor = require(ReplicatedStorage.Shared.Config.Decor)
local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local QuestService = require(script.Parent.QuestService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local BookService = require(script.Parent.BookService)
local EventService = require(script.Parent.EventService)

local RATE = { rate = 6, burst = 10 }

local DecorService = {}

local function isInt(value: any, min: number, max: number): boolean
	return typeof(value) == "number" and value % 1 == 0 and value >= min and value <= max
end

function DecorService.MaxPlaced(): number
	return Decor.MAX_PLACED
end

local function getFolder(plot: Model): Folder
	local folder = plot:FindFirstChild("Decor")
	if folder and folder:IsA("Folder") then
		return folder
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = "Decor"
	newFolder.Parent = plot
	return newFolder
end

local function pivotFor(plot: Model, item: Decor.Item, entry: Types.DecorEntry): CFrame
	local origin = plot.PrimaryPart :: BasePart
	return origin.CFrame * DecorGrid.localCFrame(item, entry.x, entry.z, entry.r, origin.Size.Y / 2)
end

local function setEntryAttributes(model: Model, entry: Types.DecorEntry)
	model:SetAttribute("X", entry.x)
	model:SetAttribute("Z", entry.z)
	model:SetAttribute("R", entry.r)
end

local function spawnModel(player: Player, plot: Model, entry: Types.DecorEntry)
	local item = Decor.byId[entry.id]
	if not item then
		return
	end
	local model = DecorGrid.build(item)
	model.Name = `Decor{entry.uid}`
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Uid", entry.uid)
	model:SetAttribute("ItemId", entry.id)
	model:SetAttribute("Owner", player.UserId)
	setEntryAttributes(model, entry)
	model:PivotTo(pivotFor(plot, item, entry))
	model.Parent = getFolder(plot)
end

local function findModel(plot: Model, uid: number): Model?
	local model = getFolder(plot):FindFirstChild(`Decor{uid}`)
	return if model and model:IsA("Model") then model else nil
end

local function findEntry(data: Types.PlayerData, uid: any): (Types.DecorEntry?, number?)
	for index, entry in data.decor.placed do
		if entry.uid == uid then
			return entry, index
		end
	end
	return nil, nil
end

local function rebuild(player: Player, plot: Model)
	local data = DataService.Get(player)
	if not data or not plot.PrimaryPart then
		return
	end
	getFolder(plot):ClearAllChildren()

	-- Drop entries that became invalid (removed items, a new no-build area) back into stock.
	local valid: { Types.DecorEntry } = {}
	for _, entry in data.decor.placed do
		local item = Decor.byId[entry.id]
		if item and DecorGrid.isValid(item, entry.x, entry.z, entry.r, DecorGrid.occupancy(valid, data.farm.tiles, Land.pondRects(data.pond.list)), nil, data.land.chunks) then
			table.insert(valid, entry)
		elseif item then
			data.decor.stock[entry.id] = (data.decor.stock[entry.id] or 0) + 1
		end
	end
	data.decor.placed = valid

	for _, entry in valid do
		spawnModel(player, plot, entry)
	end
end

-- Requests ----------------------------------------------------------------------------

local function onPlace(player: Player, itemId: any, x: any, z: any, r: any)
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	local item = typeof(itemId) == "string" and Decor.byId[itemId] or nil
	if not data or not plot or not item then
		return
	end
	if data.guide.decorUnlocked ~= true then
		Net.Fire("Notify", player, "decor.tut_locked")
		return
	end
	if not isInt(x, DecorGrid.X_MIN, DecorGrid.X_MAX) or not isInt(z, DecorGrid.Z_MIN, DecorGrid.Z_MAX) or not isInt(r, 0, 3) then
		return
	end
	if #data.decor.placed >= DecorService.MaxPlaced() then
		Net.Fire("Notify", player, "decor.limit", { max = DecorService.MaxPlaced() })
		return
	end
	if not DecorGrid.isValid(item, x, z, r, DecorGrid.occupancy(data.decor.placed, data.farm.tiles, Land.pondRects(data.pond.list)), nil, data.land.chunks) then
		Net.Fire("Notify", player, "decor.invalid")
		return
	end

	local stock = data.decor.stock[item.id] or 0
	-- Blueprint bukan gating (Bab 8.7): dekor langsung di-craft pakai bahan tanpa beli Blueprint.
	if stock > 0 then
		data.decor.stock[item.id] = if stock == 1 then nil else stock - 1
	elseif item.unlockLevel and data.level < item.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = item.unlockLevel })
		return
	elseif item.event and not EventService.IsActive(item.event) then
		Net.Fire("Notify", player, "event.over")
		return
	elseif not EconomyService.TrySpend(player, item.currency, item.price, `decor:{item.id}`) then
		Net.Fire("Notify", player, "notify.not_enough", { currency = `currency.{item.currency}` })
		return
	end

	local entry: Types.DecorEntry = { uid = data.decor.nextUid, id = item.id, x = x, z = z, r = r }
	data.decor.nextUid += 1
	table.insert(data.decor.placed, entry)
	spawnModel(player, plot, entry)
	InventoryService.Sync(player)
	BookService.RecordDecor(player, item.id)
	QuestService.Report(player, "decor_placed")
end

local function onMove(player: Player, uid: any, x: any, z: any, r: any)
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	if not data or not plot then
		return
	end
	local entry = findEntry(data, uid)
	local item = entry and Decor.byId[entry.id]
	if not entry or not item then
		return
	end
	if not isInt(x, DecorGrid.X_MIN, DecorGrid.X_MAX) or not isInt(z, DecorGrid.Z_MIN, DecorGrid.Z_MAX) or not isInt(r, 0, 3) then
		return
	end
	if not DecorGrid.isValid(item, x, z, r, DecorGrid.occupancy(data.decor.placed, data.farm.tiles, Land.pondRects(data.pond.list)), entry.uid, data.land.chunks) then
		Net.Fire("Notify", player, "decor.invalid")
		return
	end

	entry.x, entry.z, entry.r = x, z, r
	local model = findModel(plot, entry.uid)
	if model then
		setEntryAttributes(model, entry)
		model:PivotTo(pivotFor(plot, item, entry))
	end
end

local function onStore(player: Player, uid: any)
	local data = DataService.Get(player)
	local plot = PlotService.GetPlot(player)
	if not data or not plot then
		return
	end
	local entry, index = findEntry(data, uid)
	if not entry or not index then
		return
	end
	table.remove(data.decor.placed, index)
	-- "Hapus" (remove) = the piece goes back to the Tas (stock) and can be placed again for free. NO Koin refund here:
	-- selling a decor piece for half its price is a separate action (not built yet).
	data.decor.stock[entry.id] = (data.decor.stock[entry.id] or 0) + 1
	local model = findModel(plot, entry.uid)
	if model then
		model:Destroy()
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "decor.stored")
end

function DecorService.Init()
	PlotService.Assigned:Connect(rebuild)
	PlotService.Released:Connect(function(_player: Player, plot: Model)
		getFolder(plot):ClearAllChildren()
	end)
end

function DecorService.Start()
	Net.On("DecorPlace", onPlace, RATE)
	Net.On("DecorMove", onMove, RATE)
	Net.On("DecorStore", onStore, RATE)
end

return DecorService
