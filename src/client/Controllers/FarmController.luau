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

local openTilePanel: (index: number) -> ()
local onTileTapped: (part: BasePart) -> ()

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
-- A small parchment card in the middle of the screen (it used to sit on top of the dock buttons), with a bamboo
-- button per crop in a 2-column grid and the standard close badge.

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
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.48)
	panel.Size = UDim2.fromOffset(348, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = UiKit.BG
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel
	local border = Instance.new("UIStroke")
	border.Color = UiKit.BAMBOO_DARK
	border.Thickness = 3
	border.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 0
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Font = UiKit.FONT
	title.TextSize = 24
	title.TextColor3 = UiKit.TEXT
	title.Text = Locale.t("seed_picker.title")
	title.Parent = panel

	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.LayoutOrder = 1
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.Parent = panel
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(156, UiKit.TOUCH)
	gridLayout.CellPadding = UDim2.fromOffset(8, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = grid

	for order, crop in Crops.list do
		local button = UiKit.button(grid, crop.id, Locale.t("crop." .. crop.id), UiKit.BUTTON)
		button.LayoutOrder = order
		button.TextSize = 16
		button.TextWrapped = true
		button.Activated:Connect(function()
			if not button.Active then
				return -- locked crop or no seeds
			end
			local index = pickerTileIndex
			closePicker()
			if index then
				require(script.Parent.Parent.FarmFx).plant()
				Net.Send("FarmPlant", index, crop.id)
			end
		end)
	end

	UiKit.closeBadge(panel, 40, closePicker)

	gui.Parent = playerGui
	return gui
end

local function refreshPickerButtons(gui: ScreenGui)
	local level = player:GetAttribute("Level")
	local playerLevel = if typeof(level) == "number" then level else 1
	local panel = (gui:FindFirstChild("Panel") :: Frame):FindFirstChild("Grid") :: Frame
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
		button.TextTransparency = if usable then 0 else 0.45
		button.BackgroundColor3 = if usable then UiKit.BUTTON else UiKit.BUTTON_MUTED
		local name = Locale.t("crop." .. crop.id)
		button.Text = if not unlocked
			then `{name} · {Locale.t("seed_picker.locked", { level = crop.unlockLevel })}`
			elseif have == 0 then `{name} · {Locale.t("seed_picker.none")}`
			else `{name} · {have}`
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

onTileTapped = function(part: BasePart)
	local index = part:GetAttribute("Index")
	-- Garap mode owns taps on the ground, except "till": there a tap on an existing bed is not a Garap action, so it plants,
	-- waters or harvests like normal (it used to be swallowed, leaving a new player stuck right after the first bed).
	if typeof(index) ~= "number" or (GarapController.Active and GarapController.Mode ~= "till") then
		return
	end
	local stage = getStage(part)
	if stage == 0 then
		openPicker(index)
	elseif stage == READY_STAGE then
		require(script.Parent.Parent.FarmFx).harvest()
		Net.Send("FarmHarvest", index)
	elseif part:GetAttribute("Watered") ~= true then
		require(script.Parent.Parent.FarmFx).water()
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
	local glow = readyGlow[instance :: BasePart]
	if glow then
		glow:Destroy()
		readyGlow[instance :: BasePart] = nil
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
