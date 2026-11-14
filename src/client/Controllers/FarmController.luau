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

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local GarapController = require(script.Parent.GarapController)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local openTilePanel: (index: number) -> ()

local TILE_TAG = "FarmTile"
local REFRESH_SECONDS = 0.5
local STAGE_SIZE = { 0.8, 1.6, 2.6 } -- placeholder ball per stage: seedling, growing, ready
-- Real models: height in studs when ripe (stage 3); the other stages scale it down.
local STAGE_SCALE = { 0.3, 0.65, 1 }
local DEFAULT_CROP_HEIGHT = 3
local CROP_HEIGHT: { [string]: number } = {
	kangkung = 2.2,
	cabai = 2.6,
	tomat = 3,
	terong = 3,
	jagung = 5,
	singkong = 4,
	padi = 3.4,
	pisang = 6,
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

local function render(view: TileView)
	local part = view.part
	-- (The soil is terrain painted by the server; the tile part itself is invisible.)

	local cropId = part:GetAttribute("Crop") :: string?
	local stage = getStage(part)

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
	local template = models and models:FindFirstChild(crop.id)
	if template and template:IsA("Model") then
		local model = template:Clone()
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false -- taps must reach the tile's ClickDetector
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
		view.cropPart = model
		return
	end

	local newPart = Instance.new("Part")
	newPart.Name = "CropVisual"
	newPart.Shape = Enum.PartType.Ball
	newPart.Anchored = true
	newPart.CanCollide = false
	newPart.CanQuery = false
	newPart.CanTouch = false
	newPart.CastShadow = false
	newPart.Material = Enum.Material.SmoothPlastic
	local size = STAGE_SIZE[stage]
	newPart.Size = Vector3.one * size
	newPart.Color = crop.color
	newPart.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 + size / 2, 0)
	newPart.Parent = part
	view.cropPart = newPart
end

-- Seed picker (placeholder) ---------------------------------------------------

local function closePicker()
	pickerTileIndex = nil
	if picker then
		picker.Enabled = false
	end
end

local function buildPicker(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "SeedPicker"
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -24)
	panel.Size = UDim2.fromOffset(320, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.fromRGB(58, 52, 44)
	panel.BackgroundTransparency = 0.1
	panel.Parent = gui
	Instance.new("UICorner").Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local function makeButton(name: string, order: number): TextButton
		local button = Instance.new("TextButton")
		button.Name = name
		button.LayoutOrder = order
		button.Size = UDim2.new(1, 0, 0, 40)
		button.BackgroundColor3 = Color3.fromRGB(92, 82, 68)
		button.TextColor3 = Color3.fromRGB(240, 230, 210)
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 18
		button.Parent = panel
		Instance.new("UICorner").Parent = button
		return button
	end

	for order, crop in Crops.list do
		local button = makeButton(crop.id, order)
		button.Activated:Connect(function()
			if not button.Active then
				return -- locked crop
			end
			local index = pickerTileIndex
			closePicker()
			if index then
				Net.Send("FarmPlant", index, crop.id)
			end
		end)
	end

	local close = makeButton("Close", #Crops.list + 1)
	close.Text = Locale.t("seed_picker.close")
	close.BackgroundColor3 = Color3.fromRGB(72, 64, 54)
	close.Activated:Connect(closePicker)

	gui.Parent = playerGui
	return gui
end

local function refreshPickerButtons(gui: ScreenGui)
	local level = player:GetAttribute("Level")
	local playerLevel = if typeof(level) == "number" then level else 1
	local panel = gui:FindFirstChild("Panel") :: Frame
	local snapshot = State.current :: any
	local items = if snapshot and snapshot.items then snapshot.items else {}
	for _, crop in Crops.list do
		local button = panel:FindFirstChild(crop.id) :: TextButton
		local unlocked = playerLevel >= crop.unlockLevel
		-- Planting uses seeds from the bag (bought from Pak Darmo / Bu Wati).
		local have = (items[`seed_{crop.id}`] or 0) + (items[`seedx_{crop.id}`] or 0)
		local usable = unlocked and have > 0
		button.Visible = unlocked or crop.unlockLevel <= playerLevel + 5 -- show only the next few locked crops
		button.Active = usable
		button.AutoButtonColor = usable
		button.TextTransparency = if usable then 0 else 0.5
		local name = Locale.t("crop." .. crop.id)
		button.Text = if not unlocked
			then `{name}  ·  {Locale.t("seed_picker.locked", { level = crop.unlockLevel })}`
			elseif have == 0 then `{name}  ·  {Locale.t("seed_picker.none")}`
			else `{name}  ·  {Locale.t("seed_picker.have", { n = have })}`
	end
end

local function openPicker(index: number)
	local gui = picker or buildPicker()
	picker = gui
	pickerTileIndex = index
	refreshPickerButtons(gui)
	gui.Enabled = true
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

local function onTileTapped(part: BasePart)
	local index = part:GetAttribute("Index")
	if typeof(index) ~= "number" or GarapController.Active then -- Garap mode owns taps on the ground
		return
	end
	local stage = getStage(part)
	if stage == 0 then
		openPicker(index)
	elseif stage == READY_STAGE then
		Net.Send("FarmHarvest", index)
	elseif part:GetAttribute("Watered") ~= true then
		Net.Send("FarmWater", index)
	else
		openTilePanel(index)
	end
end

local function makeTimerLabel(part: BasePart): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Timer"
	billboard.Size = UDim2.fromOffset(90, 26)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 60
	billboard.Enabled = false
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(58, 52, 44)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = Color3.fromRGB(240, 230, 210)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
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
		label = if isMine then makeTimerLabel(part) else nil,
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
	views[instance :: BasePart] = nil
end

function FarmController.Start()
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
