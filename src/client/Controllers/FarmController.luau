--!strict
-- Renders crops on every farm tile (from tile attributes) and handles taps on your own tiles:
--   empty -> seed picker, ready -> harvest, growing & dry -> water.
-- Visuals: a model from ReplicatedStorage.CropModels.<cropId> (scaled per growth stage) when it exists,
-- otherwise a placeholder ball that grows per stage.
--
-- SEED PICKER: a plain placeholder is built here. When you design it, tell me the
-- instance names and I'll bind to them the same way as the HUD.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CropBuilder = require(ReplicatedStorage.Shared.CropBuilder)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local GarapController = require(script.Parent.GarapController)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)
local Vfx = require(ReplicatedStorage.Shared.Vfx)
local FarmFloat = require(script.Parent.Parent.FarmFloat)
local FarmFx = require(script.Parent.Parent.FarmFx)

local openTilePanel: (index: number) -> ()
local onTileTapped: (part: BasePart) -> ()

local TILE_TAG = "FarmTile"
local REFRESH_SECONDS = 0.5
local STAGE_SIZE = { 0.8, 1.6, 2.6 } -- placeholder ball per stage: seedling, growing, ready
-- Real models: height in studs when ripe (stage 3); the other stages scale it down.
local STAGE_SCALE = { 0.4, 0.7, 1 }
local DEFAULT_CROP_HEIGHT = 3
local CROP_HEIGHT: { [string]: number } = { -- ripe height in studs (a bed is 7 studs wide: a crop should fill it, not sit in a corner)
	kangkung = 4,
	cabai = 4.6,
	tomat = 5.2,
	terong = 5.2,
	jagung = 8,
	singkong = 6.5,
	padi = 5.6,
	pisang = 9,
}
local READY_STAGE = 3

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

type TileView = {
	part: BasePart,
	isMine: boolean,
	stage: number,
	cropId: string?,
	cropPart: Instance?, -- the ball placeholder (Part) or a cloned crop Model
	label: TextLabel?,
	connections: { RBXScriptConnection },
}

local views: { [BasePart]: TileView } = {}
local picker: ScreenGui?
local pickerTileIndex: number?

local FarmController = {}
local readyGlow: { [BasePart]: ParticleEmitter? } = {}

local function getStage(part: BasePart): number
	if part:GetAttribute("Crop") == nil then
		return 0
	end
	local plantedAt = part:GetAttribute("PlantedAt")
	local readyAt = part:GetAttribute("ReadyAt")
	if typeof(plantedAt) ~= "number" or typeof(readyAt) ~= "number" then
		return 0
	end
	local now = Workspace:GetServerTimeNow()
	if now >= readyAt then
		return READY_STAGE
	end
	local progress = (now - plantedAt) / math.max(readyAt - plantedAt, 1)
	return if progress < 0.4 then 1 else 2
end

local function formatRemaining(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

-- Makes a crop visual tappable. The bed is a flat, invisible target under the plant, so tapping the plant you SEE used to
-- do nothing (new players tapped the ripe crop and nothing happened). A ClickDetector on the visual forwards to the same
-- handler as the bed. The visual's parts must be queryable for the click to hit them.
local function makeTappable(view: TileView, visual: Instance)
	if not view.isMine then
		return
	end
	local source = view.part:FindFirstChildOfClass("ClickDetector")
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = if source then source.MaxActivationDistance else 32
	detector.Parent = visual
	detector.MouseClick:Connect(function()
		onTileTapped(view.part)
	end)
end

local function render(view: TileView)
	local part = view.part
	-- (The soil is terrain painted by the server; the tile part itself is invisible.)

	local cropId = part:GetAttribute("Crop") :: string?
	local stage = getStage(part)

	-- Ripe crops of your own sparkle softly, so you can see from afar what is ready to harvest.
	local wantsGlow = view.isMine and stage == READY_STAGE
	local glow = readyGlow[part]
	if wantsGlow and not glow then
		readyGlow[part] = Vfx.loop("ready", part)
	elseif not wantsGlow and glow then
		glow:Destroy()
		readyGlow[part] = nil
	end

	if view.label then
		local label = view.label
		local billboard = label.Parent :: BillboardGui
		billboard.Enabled = stage > 0
		if stage == READY_STAGE then
			label.Text = Locale.t("farm.ready")
		elseif stage > 0 then
			label.Text = formatRemaining((part:GetAttribute("ReadyAt") :: number) - Workspace:GetServerTimeNow())
		end
	end

	if stage == view.stage and cropId == view.cropId then
		return
	end
	view.stage = stage
	view.cropId = cropId

	local crop = cropId and Crops.byId[cropId]
	if view.cropPart then
		view.cropPart:Destroy()
		view.cropPart = nil
	end
	if stage == 0 or not crop then
		return
	end

	-- A real model (ReplicatedStorage > CropModels > <cropId>) when one exists, else the placeholder ball.
	local models = ReplicatedStorage:FindFirstChild("CropModels")
	local found = models and models:FindFirstChild(crop.id)
	local template: Model? = if found and found:IsA("Model") then found else CropBuilder.template(crop.id)
	if template then
		local model = template:Clone()
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = true -- taps hit the plant itself (makeTappable), not only the bed under it
				descendant.CanTouch = false
			end
		end
		-- Scale so the model is this tall (one model serves all three growth stages), then stand it on the soil.
		local height = (CROP_HEIGHT[crop.id] or DEFAULT_CROP_HEIGHT) * STAGE_SCALE[stage]
		local _, size = model:GetBoundingBox()
		model:ScaleTo(model:GetScale() * height / math.max(size.Y, 0.01))
		local boxCFrame, boxSize = model:GetBoundingBox()
		local pivotToBox = model:GetPivot():ToObjectSpace(boxCFrame)
		local ground = part.CFrame * CFrame.new(0, part.Size.Y / 2 + boxSize.Y / 2, 0)
		model:PivotTo(ground * pivotToBox:Inverse())
		model.Name = "CropVisual"
		model.Parent = part
		makeTappable(view, model)
		view.cropPart = model
		return
	end

	local newPart = Instance.new("Part")
	newPart.Name = "CropVisual"
	newPart.Shape = Enum.PartType.Ball
	newPart.Anchored = true
	newPart.CanCollide = false
	newPart.CanQuery = true -- tappable: see makeTappable
	newPart.CanTouch = false
	newPart.CastShadow = false
	newPart.Material = Enum.Material.SmoothPlastic
	local size = STAGE_SIZE[stage]
	newPart.Size = Vector3.one * size
	newPart.Color = crop.color
	newPart.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 + size / 2, 0)
	newPart.Parent = part
	makeTappable(view, newPart)
	view.cropPart = newPart
end

-- Seed picker -----------------------------------------------------------------
-- The standard bamboo sheet (UiKit.panel) with one card per crop. Each card shows the crop's own 3D model in a ViewportFrame,
-- so the picture is always exactly the model that grows on the bed (no separate thumbnail to get out of step). A card is dimmed
-- with a reason when the crop is locked (level) or you have no bibit of it.

local CARD_W, CARD_H = 120, 156
local pickerPanel: UiKit.Panel? = nil
local pickerBed: BasePart? = nil
local cards: { [string]: { button: TextButton, status: TextLabel, dim: Frame } } = {}

local function cropTemplate(cropId: string): Model?
	local models = ReplicatedStorage:FindFirstChild("CropModels")
	local found = models and models:FindFirstChild(cropId)
	return if found and found:IsA("Model") then found else CropBuilder.template(cropId)
end

-- The crop model, framed, in a ViewportFrame.
local function addThumbnail(parent: GuiObject, cropId: string)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Thumb"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.new(1, -8, 0, 96)
	viewport.Position = UDim2.fromOffset(4, 4)
	viewport.Ambient = Color3.fromRGB(176, 172, 160)
	viewport.LightColor = Color3.fromRGB(255, 244, 222)
	viewport.LightDirection = Vector3.new(-0.6, -1.2, -0.7)
	viewport.Parent = parent
	local template = cropTemplate(cropId)
	if not template then
		return
	end
	local model = template:Clone()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	model.Parent = viewport
	local boxCFrame, boxSize = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	viewport.CurrentCamera = camera
	camera.Parent = viewport
	local radius = boxSize.Magnitude / 2
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.02
	local center = boxCFrame.Position
	camera.CFrame = CFrame.lookAt(center + Vector3.new(0.42, 0.3, 1).Unit * distance, center)
end

local function closePicker()
	pickerBed = nil
	if pickerPanel then
		pickerPanel.gui.Enabled = false
	end
end

local function plantAt(bed: BasePart, cropId: string)
	local index = bed:GetAttribute("Index")
	if typeof(index) ~= "number" then
		return
	end
	FarmFloat.setPending(bed, 1.4)
	FarmFx.plant(bed)
	task.delay(FarmFx.PLANT_SECONDS, function()
		Net.Send("FarmPlant", index, cropId)
	end)
end

local function buildPicker(): UiKit.Panel
	local panel = UiKit.panel("SeedPicker", Locale.t("seed_picker.title"), closePicker)
	local sheet = panel.gui:FindFirstChild("Panel") :: Frame
	sheet.Size = UDim2.new(0.9, 0, 0.86, 0)
	local limit = sheet:FindFirstChildOfClass("UISizeConstraint")
	if limit then
		limit.MaxSize = Vector2.new(640, 380)
	end

	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.Parent = panel.list
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(CARD_W, CARD_H)
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = grid

	for order, crop in Crops.list do
		local button = Instance.new("TextButton")
		button.Name = crop.id
		button.LayoutOrder = order
		button.Text = ""
		button.AutoButtonColor = false
		button.BackgroundColor3 = UiKit.ROW
		button.Parent = grid
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, 14)
		round.Parent = button
		local border = Instance.new("UIStroke")
		border.Color = UiKit.BAMBOO
		border.Thickness = 3
		border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		border.Parent = button

		addThumbnail(button, crop.id)

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(4, 102)
		name.Size = UDim2.new(1, -8, 0, 24)
		name.Font = UiKit.FONT
		name.TextSize = 19
		name.TextColor3 = UiKit.TEXT
		name.Text = Locale.t("crop." .. crop.id)
		name.Parent = button

		local status = Instance.new("TextLabel")
		status.BackgroundTransparency = 1
		status.Position = UDim2.fromOffset(4, 126)
		status.Size = UDim2.new(1, -8, 0, 22)
		status.Font = Enum.Font.GothamBold
		status.TextSize = 14
		status.TextColor3 = UiKit.TEXT
		status.Parent = button

		-- Dim veil for locked / out-of-bibit crops (over the picture only).
		local dim = Instance.new("Frame")
		dim.Name = "Dim"
		dim.BackgroundColor3 = UiKit.BG
		dim.BackgroundTransparency = 0.45
		dim.Size = UDim2.new(1, 0, 0, 100)
		dim.ZIndex = 5
		dim.Visible = false
		dim.Parent = button
		local dimRound = Instance.new("UICorner")
		dimRound.CornerRadius = UDim.new(0, 14)
		dimRound.Parent = dim

		button.Activated:Connect(function()
			local bed = pickerBed
			if not button.Active or not bed then
				return
			end
			closePicker()
			plantAt(bed, crop.id)
		end)
		cards[crop.id] = { button = button, status = status, dim = dim }
	end
	panel.footerLabel.Text = Locale.t("seed_picker.hint")
	panel.footerLabel.TextSize = 15
	panel.footerLabel.Size = UDim2.new(1, 0, 1, 0)
	return panel
end

local function refreshPickerCards()
	local level = player:GetAttribute("Level")
	local playerLevel = if typeof(level) == "number" then level else 1
	local snapshot = State.current :: any
	local items = if snapshot and snapshot.items then snapshot.items else {}
	for _, crop in Crops.list do
		local card = cards[crop.id]
		local unlocked = playerLevel >= crop.unlockLevel
		-- Planting uses bibit from the bag (bought from Pak Darmo / Bu Wati).
		local have = (items[`seed_{crop.id}`] or 0) + (items[`seedx_{crop.id}`] or 0)
		local usable = unlocked and have > 0
		card.button.Visible = unlocked or crop.unlockLevel <= playerLevel + 5 -- show only the next few locked crops
		card.button.Active = usable
		card.dim.Visible = not usable
		card.status.TextColor3 = if usable then UiKit.TEXT elseif unlocked then UiKit.RED_TEXT else Color3.fromRGB(120, 104, 80)
		card.status.Text = if not unlocked
			then Locale.t("seed_picker.locked", { level = crop.unlockLevel })
			elseif have == 0 then Locale.t("seed_picker.none")
			else Locale.t("seed_picker.have", { n = have })
	end
end

local function openPicker(bed: BasePart)
	local panel = pickerPanel or buildPicker()
	pickerPanel = panel
	pickerBed = bed
	refreshPickerCards()
	panel.gui.Enabled = true
end

-- Growing + already watered: optional Instant Grow (token) panel. Never shown automatically.
local tilePanel: UiKit.Panel? = nil

openTilePanel = function(index: number)
	local current = tilePanel or UiKit.panel("TilePanel", Locale.t("tile.title"), function()
		(tilePanel :: UiKit.Panel).gui.Enabled = false
	end)
	tilePanel = current
	UiKit.clear(current.list)
	local snapshot = State.current :: any
	local tokens = snapshot and snapshot.instantGrow and snapshot.instantGrow.tokens or 0
	UiKit.row(current.list, 1, Locale.t("tile.instant"), Locale.t("tile.instant_sub", { n = tokens }), Locale.t("tile.instant"), tokens > 0, function()
		Net.Send("FarmInstantGrow", index)
		current.gui.Enabled = false
	end)
	UiKit.row(current.list, 2, Locale.t("store.product.instant_grow"), nil, Locale.t("tile.buy_token"), true, function()
		Net.Send("StoreBuy", "product", "instant_grow")
	end)
	current.gui.Enabled = true
end

-- Tile interaction -------------------------------------------------------------

-- What a tap on a bed (or its floating pill) does, by the bed's state.
local function act(part: BasePart, kind: string)
	local index = part:GetAttribute("Index")
	if typeof(index) ~= "number" then
		return
	end
	if kind == "empty" then
		openPicker(part)
	elseif kind == "ripe" then
		FarmFloat.setPending(part, 1.1)
		FarmFx.harvest(part)
		Net.Send("FarmHarvest", index)
	elseif kind == "dry" then
		FarmFloat.setPending(part, 2.4)
		FarmFx.water(part)
		task.delay(FarmFx.WATER_SECONDS, function()
			Net.Send("FarmWater", index)
		end)
	else
		openTilePanel(index) -- growing and already watered: Instant Grow
	end
end

onTileTapped = function(part: BasePart)
	local index = part:GetAttribute("Index")
	if typeof(index) ~= "number" then
		return
	end
	local stage = getStage(part)
	-- Garap mode owns taps on the ground (Cangkul turns an EMPTY bed back into grass, Kolam is about ponds). Only a bed with a
	-- crop still waters / harvests like normal there. Planting an empty bed happens outside Garap mode.
	if GarapController.Active and (GarapController.Mode ~= "till" or stage == 0) then
		return
	end
	if stage == 0 then
		act(part, "empty")
	elseif stage == READY_STAGE then
		act(part, "ripe")
	elseif part:GetAttribute("Watered") ~= true then
		act(part, "dry")
	else
		act(part, "grow")
	end
end

local function makeTimerLabel(part: BasePart): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Timer"
	billboard.Size = UDim2.fromOffset(108, 30)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 60
	billboard.Enabled = false
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = UiKit.DARK
	label.BackgroundTransparency = 0.1
	label.TextColor3 = UiKit.CREAM
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard
	Instance.new("UICorner").Parent = label
	return label
end

local function addTile(instance: Instance)
	if not instance:IsA("BasePart") or views[instance] then
		return
	end
	local part = instance :: BasePart
	local isMine = part:GetAttribute("Owner") == player.UserId
	local view: TileView = {
		part = part,
		isMine = isMine,
		stage = -1,
		cropId = nil,
		cropPart = nil,
		label = nil, -- (the floating pills show the timer now: FarmFloat)
		connections = {},
	}
	views[part] = view

	table.insert(view.connections, part.AttributeChanged:Connect(function()
		render(view)
	end))

	if isMine then
		local detector = part:FindFirstChildOfClass("ClickDetector")
		if detector then
			table.insert(view.connections, detector.MouseClick:Connect(function()
				onTileTapped(part)
			end))
		end
	end
	render(view)
end

local function removeTile(instance: Instance)
	local view = views[instance :: BasePart]
	if not view then
		return
	end
	for _, connection in view.connections do
		connection:Disconnect()
	end
	if view.cropPart then
		view.cropPart:Destroy()
	end
	local glow = readyGlow[instance :: BasePart]
	if glow then
		glow:Destroy()
		readyGlow[instance :: BasePart] = nil
	end
	views[instance :: BasePart] = nil
end

function FarmController.Start()
	FarmFloat.Init({
		onAction = act,
		blocked = function()
			return GarapController.Active or (pickerPanel ~= nil and pickerPanel.gui.Enabled) or UiKit.confirmOpen()
		end,
	})
	CollectionService:GetInstanceAddedSignal(TILE_TAG):Connect(addTile)
	CollectionService:GetInstanceRemovedSignal(TILE_TAG):Connect(removeTile)
	for _, instance in CollectionService:GetTagged(TILE_TAG) do
		addTile(instance)
	end

	while true do
		task.wait(REFRESH_SECONDS)
		for _, view in views do
			render(view)
		end
	end
end

return FarmController
