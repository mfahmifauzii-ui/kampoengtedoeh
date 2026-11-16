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
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local GarapController = require(script.Parent.GarapController)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)
local Vfx = require(ReplicatedStorage.Shared.Vfx)
local FarmFloat = require(script.Parent.Parent.FarmFloat)
local FarmFx = require(script.Parent.Parent.FarmFx)
local FeedbackController = require(script.Parent.FeedbackController)

local openTilePanel: (index: number) -> ()
local onTileTapped: (part: BasePart) -> ()

local TILE_TAG = "FarmTile"
local BRICK = Color3.fromRGB(176, 92, 66) -- Hapus Petak: soft brick red (destructive, but still cozy with wood and cream)
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
local function addThumbnail(parent: GuiObject, cropId: string, size: number?)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Thumb"
	viewport.BackgroundTransparency = 1
	local side = size or 96
	viewport.Size = if size then UDim2.fromOffset(size - 4, size - 4) else UDim2.new(1, -8, 0, 96)
	viewport.Position = if size then UDim2.fromOffset(2, 2) else UDim2.fromOffset(4, 4)
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
		-- Planting is by proximity only (SeedPopup): standing within 1 stud of the empty bed shows the seed row. A tap on the
		-- bed does not open a picker any more.
		return
	elseif kind == "ripe" then
		FarmFloat.setPending(part, 1.1)
		FarmFx.harvest(part)
		-- The harvested crop flies from its bed to the Bag, and the coins of this harvest fly from the same spot.
		local cropId = part:GetAttribute("Crop")
		local crop = if typeof(cropId) == "string" then Crops.byId[cropId] else nil
		local screen, onScreen = (Workspace.CurrentCamera :: Camera):WorldToViewportPoint(part.Position + Vector3.new(0, 2, 0))
		if crop and onScreen then
			local point = Vector2.new(screen.X, screen.Y + game:GetService("GuiService"):GetGuiInset().Y)
			FeedbackController.FlyToBag(point, crop.color, string.sub(Locale.t("crop." .. crop.id), 1, 1))
		end
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

-- STAGE 2: Gembor mode -------------------------------------------------------------------------
-- The Gembor button shows once you own the tool. When it is ON, a tap on a dry bed waters the 3x3 block of beds
-- around it (server: FarmWaterArea). Only planted, growing and dry beds get water.
local gemborOn = false
local gemborButton: TextButton? = nil

local function gemborOwned(): boolean
	local snapshot = State.current
	return snapshot ~= nil and snapshot.tools ~= nil and snapshot.tools.gembor == true
end

-- The 3x3 area, lit for a moment around the tapped bed (beds sit one grid cell = Land.PITCH apart).
local function showGemborArea(part: BasePart)
	local radius = Farm.TOOLS.gembor.radius
	local side = (radius * 2 + 1) * Land.PITCH - (Land.PITCH - Farm.BED_SIZE)
	local box = Instance.new("Part")
	box.Name = "GemborArea"
	box.Anchored = true
	box.CanCollide = false
	box.CanQuery = false
	box.CanTouch = false
	box.Material = Enum.Material.SmoothPlastic
	box.Color = UiKit.BAMBOO
	box.Transparency = 0.55
	box.Size = Vector3.new(side, 0.2, side)
	box.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 + 0.25, 0)
	box.Parent = Workspace
	local TweenService = game:GetService("TweenService")
	TweenService:Create(box, TweenInfo.new(1), { Transparency = 1 }):Play()
	game:GetService("Debris"):AddItem(box, 1.2)
end

local function gemborWater(part: BasePart)
	local index = part:GetAttribute("Index")
	if typeof(index) ~= "number" then
		return
	end
	showGemborArea(part)
	FarmFloat.setPending(part, 2.4)
	FarmFx.water(part)
	task.delay(FarmFx.WATER_SECONDS, function()
		Net.Send("FarmWaterArea", index)
	end)
end

local function refreshGemborButton()
	local button = gemborButton
	if not button then
		return
	end
	button.Visible = gemborOwned() and not GarapController.Active
	button.Text = Locale.t(if gemborOn then "ui.gembor_on" else "ui.gembor_off")
end

local function buildGemborButton()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Gembor"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = playerGui
	local button = UiKit.button(gui, "GemborButton", Locale.t("ui.gembor_off"))
	button.Size = UDim2.fromOffset(190, UiKit.TOUCH)
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = UDim2.new(0.5, 0, 0, 124 + UiKit.TOUCH + 8)
	button.Visible = false
	button.Activated:Connect(function()
		gemborOn = not gemborOn
		refreshGemborButton()
	end)
	gemborButton = button
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
		if gemborOn and gemborOwned() then
			gemborWater(part)
		else
			act(part, "dry")
		end
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

-- Bed menu (press and hold a bed's pill): an EMPTY bed gets Pindah (main) and Hapus Petak (secondary, asks first). A bed with a
-- crop is locked: the same buttons, greyed, with the reason in text, so the player is never left tapping for nothing.
local bedMenu: ScreenGui? = nil
local bedCard: Frame? = nil

local function closeBedMenu()
	if bedMenu then
		bedMenu.Enabled = false
	end
	GarapController.MenuOpen = false -- Garap resumes (it was never switched off)
end

local function buildBedMenu(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "BedMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 45 -- above the HUD and the floating pills, below the confirm modal
	gui:SetAttribute("NoScale", true) -- real pixels: the card sits on the bed
	gui.Enabled = false
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BackgroundTransparency = 1
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Parent = gui
	backdrop.Activated:Connect(closeBedMenu)
	gui.Parent = player:WaitForChild("PlayerGui")
	bedCard = Instance.new("Frame")
	bedCard.Name = "Card"
	bedCard.AnchorPoint = Vector2.new(0.5, 1)
	bedCard.AutomaticSize = Enum.AutomaticSize.XY
	bedCard.BackgroundColor3 = Color3.fromRGB(250, 240, 214)
	bedCard.Active = true -- taps on the card do not reach the backdrop
	bedCard.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 12)
	round.Parent = bedCard
	local edge = Instance.new("UIStroke")
	edge.Color = UiKit.BAMBOO
	edge.Thickness = 2
	edge.Parent = bedCard
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = bedCard
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bedCard
	bedMenu = gui
	return gui
end

-- A flat colour for a bed-menu button (the bamboo skin is gold). Locked = grey and faded, so it reads as "not now".
local function paintBedButton(button: TextButton, solid: Color3?, locked: boolean)
	local skin = button:FindFirstChild("Skin")
	if skin and skin:IsA("ImageLabel") then
		skin.Visible = false
	end
	button.BackgroundTransparency = 0
	if locked then
		button.BackgroundColor3 = Color3.fromRGB(196, 186, 166)
		button.TextColor3 = Color3.fromRGB(128, 118, 100)
	elseif solid then
		button.BackgroundColor3 = solid
		button.TextColor3 = Color3.fromRGB(255, 248, 230)
	end
end

local function openBedMenu(part: BasePart, kind: string)
	local index = part:GetAttribute("Index")
	if typeof(index) ~= "number" then
		return
	end
	local gui = bedMenu or buildBedMenu()
	local card = bedCard :: Frame
	for _, child in card:GetChildren() do
		if not child:IsA("UIBase") then
			child:Destroy()
		end
	end
	local planted = kind ~= "empty" or part:GetAttribute("Crop") ~= nil -- a planted bed can still be moved (its crop and timer come along); only Hapus is locked

	local note = Instance.new("TextLabel")
	note.Name = "Note"
	note.LayoutOrder = 0
	note.AutomaticSize = Enum.AutomaticSize.XY
	note.BackgroundTransparency = 1
	note.TextColor3 = UiKit.TEXT
	note.Font = UiKit.FONT
	note.TextSize = 13
	note.Text = if planted then Locale.t("bed.locked") else Locale.t("bed.menu_title")
	note.Parent = card

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.LayoutOrder = 1
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.BackgroundTransparency = 1
	row.Parent = card
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = row

	local move = UiKit.button(row, "Move", Locale.t("bed.move"), Color3.fromRGB(96, 150, 70))
	move.Size = UDim2.fromOffset(120, 44) -- 44 px hitbox (UIUX_Spec)
	move.TextSize = 16
	move.Active = true
	move.Interactable = true
	paintBedButton(move, Color3.fromRGB(96, 150, 70), false)
	move.Activated:Connect(function()
		closeBedMenu()
		GarapController.StartMove(index)
	end)

	-- Hapus Petak is destructive: soft brick red, never the green of Pindah. Locked while a crop is in the bed.
	local remove = UiKit.button(row, "Remove", Locale.t("bed.remove"), BRICK)
	remove.Size = UDim2.fromOffset(132, 44)
	remove.TextSize = 16
	remove.Active = not planted
	remove.Interactable = not planted
	paintBedButton(remove, if planted then nil else BRICK, planted)
	remove.Activated:Connect(function()
		if planted then
			return
		end
		closeBedMenu()
		UiKit.confirm({
			title = Locale.t("bed.remove_title"),
			body = Locale.t("bed.remove_body"),
			confirmText = Locale.t("bed.remove"),
			cancelText = Locale.t("confirm.no"),
			confirmColor = BRICK,
			cancelMuted = true,
			onConfirm = function()
				Net.Send("FarmLevel", index)
			end,
		})
	end)

	-- Sit the card just above the bed (rendered pixels; the top bar inset is added like in CoachmarkController).
	local camera = Workspace.CurrentCamera :: Camera
	local screen, onScreen = camera:WorldToViewportPoint(part.Position + Vector3.new(0, 2.5, 0))
	card.Position = UDim2.fromOffset(screen.X, screen.Y)
	gui.Enabled = onScreen
	GarapController.MenuOpen = onScreen -- Garap pauses (ghost hidden) while this menu is up
end

-- Seed popup (proximity) ----------------------------------------------------------------
-- Stand within PROXIMITY studs of an EMPTY bed of yours: one small overlay (1 row of up to 4 seed icons, a dashed white ring
-- on the ground around the bed) appears above the bed, pointing down at it. Only the NEAREST bed in range gets one.
-- Tap a lit icon = plant that seed there. Hold it 0.3 s = a small "name · xN" tip. No hover anywhere.
local TweenService = game:GetService("TweenService")
local Land = require(ReplicatedStorage.Shared.Modules.Land)

local PROXIMITY = 4 -- studs from the bed's edge (HumanoidRootPart to the edge of the square): on a phone a joystick walk lands near 4, not exactly 1
local RING_RADIUS = Land.TILE / 2 + PROXIMITY -- bed centre to the dashed ring
local RING_DOTS = 12
local HOLD_TIP_SECONDS = 0.3
-- The bamboo ring matches the dock buttons on a phone (the dock is 58 px x 0.75 = ~44 px there), 64 px on desktop.
local function slotPx(): number
	local view = (Workspace.CurrentCamera :: Camera).ViewportSize
	return if view.X < 900 or view.Y < 450 then 44 else 64
end
local BAMBOO_RING_IMAGE = "rbxassetid://86005759010163" -- the uploaded bamboo circle (the only backdrop of a seed slot)

local popupGui: ScreenGui? = nil
local popupCard: Frame
local popupArrow: TextLabel
local popupTip: TextLabel
local popupScale: UIScale
local popupBed: BasePart? = nil
local ringDots: { Frame } = {}
local tipHideAt = 0

local function bedEdgeDistance(root: BasePart, bed: BasePart): number
	local localPoint = bed.CFrame:PointToObjectSpace(root.Position)
	local dx = math.max(math.abs(localPoint.X) - bed.Size.X / 2, 0)
	local dz = math.max(math.abs(localPoint.Z) - bed.Size.Z / 2, 0)
	return math.sqrt(dx * dx + dz * dz)
end

-- Beds just planted from the card: skipped for a moment, until the server answers.
local pendingPlant: { [BasePart]: number } = {}

-- The one empty bed of mine nearest to me, within PROXIMITY (nil if none).
local function nearestEmptyBed(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local best: BasePart? = nil
	local bestDistance = PROXIMITY
	for _, bed in CollectionService:GetTagged(TILE_TAG) do
		local pending = pendingPlant[bed :: BasePart]
		if pending and os.clock() < pending then
			continue
		end
		if bed:IsA("BasePart") and bed:GetAttribute("Owner") == player.UserId and bed:GetAttribute("Crop") == nil then
			local distance = bedEdgeDistance(root, bed)
			if distance <= bestDistance then
				best = bed
				bestDistance = distance
			end
		end
	end
	return best
end

local function buildPopup()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SeedPopup"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 35 -- above the HUD and the pills, under the coachmark's top layer
	gui:SetAttribute("NoScale", true)
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	popupGui = gui

	for index = 1, RING_DOTS do
		local dot = Instance.new("Frame")
		dot.Name = "RingDot" .. index
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Size = UDim2.fromOffset(5, 5)
		dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		dot.BackgroundTransparency = 0.25
		dot.BorderSizePixel = 0
		dot.Active = false
		dot.Visible = false
		dot.Parent = gui
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = dot
		table.insert(ringDots, dot)
	end

	popupCard = Instance.new("Frame")
	popupCard.Name = "TanamButton" -- the tutorial rings this card in step Tanam (GuideController findHighlight), shown only next to an empty bed
	popupCard.AnchorPoint = Vector2.new(0.5, 1)
	popupCard.AutomaticSize = Enum.AutomaticSize.XY
	popupCard.BackgroundTransparency = 1 -- no dark backdrop: only the bamboo rings and the white arrow
	popupCard.Active = true -- taps on the card do not reach the world
	popupCard.Visible = false
	popupCard.Parent = gui
	popupScale = Instance.new("UIScale")
	popupScale.Scale = 0
	popupScale.Parent = popupCard
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 12)
	round.Parent = popupCard
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8) -- 8 px panel padding
	pad.Parent = popupCard
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(slotPx(), slotPx()) -- bamboo rings, 8 px gaps
	grid.CellPadding = UDim2.fromOffset(10, 10) -- 10 px between the rings
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = 4 -- 1 row of 4; 8 seeds = 2 rows, 12 = 3 rows
	grid.Parent = popupCard

	popupArrow = Instance.new("TextLabel")
	popupArrow.Name = "Arrow"
	popupArrow.AnchorPoint = Vector2.new(0.5, 0)
	popupArrow.Size = UDim2.fromOffset(24, 12)
	popupArrow.BackgroundTransparency = 1
	popupArrow.Text = "▼"
	popupArrow.TextColor3 = Color3.fromRGB(250, 240, 214)
	popupArrow.TextSize = 14
	popupArrow.Font = UiKit.FONT
	popupArrow.Visible = false
	popupArrow.Parent = gui

	popupTip = Instance.new("TextLabel")
	popupTip.Name = "Tip"
	popupTip.AnchorPoint = Vector2.new(0.5, 1)
	popupTip.AutomaticSize = Enum.AutomaticSize.X
	popupTip.Size = UDim2.fromOffset(0, 22)
	popupTip.BackgroundColor3 = Color3.fromRGB(48, 32, 20)
	popupTip.BackgroundTransparency = 0.05
	popupTip.TextColor3 = UiKit.CREAM
	popupTip.Font = UiKit.FONT
	popupTip.TextSize = 13
	popupTip.Visible = false
	popupTip.Parent = gui
	local tipRound = Instance.new("UICorner")
	tipRound.CornerRadius = UDim.new(0, 8)
	tipRound.Parent = popupTip
end

local function hidePopup()
	popupBed = nil
	if popupGui then
		popupGui.Enabled = false
	end
end

-- Fills the card with the seed icons for this bed. Lit = have seed & unlocked (tap plants); grey = unlocked, none in the bag
-- (tip: buy at the shop); dark with "Lv N" = locked.
local function fillPopup(bed: BasePart)
	for _, child in popupCard:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local level = player:GetAttribute("Level")
	local playerLevel = if typeof(level) == "number" then level else 1
	local snapshot = State.current :: any
	local items = if snapshot and snapshot.items then snapshot.items else {}
	for order, crop in Crops.list do
		local unlocked = playerLevel >= crop.unlockLevel
		local have = (items[`seed_{crop.id}`] or 0) + (items[`seedx_{crop.id}`] or 0)
		-- Locked seeds are hidden from the card entirely (no lock icon, no "Lv"): the shop shows them as a goal instead.
		if not unlocked then
			continue
		end
		-- The bamboo circle is the uploaded image (rbxassetid://86005759010163): no white backdrop, no gold stroke, no dark
		-- backdrop. The seed (3D thumbnail) sits in its middle; the count is plain white text in the top-right corner.
		local icon = Instance.new("ImageButton") -- a button: it takes the tap (plant / tip)
		icon.Name = crop.id
		icon.LayoutOrder = order
		icon.Size = UDim2.fromOffset(slotPx(), slotPx())
		icon.BackgroundTransparency = 1
		icon.Image = BAMBOO_RING_IMAGE
		icon.ScaleType = Enum.ScaleType.Fit
		icon.AutoButtonColor = false
		icon.ClipsDescendants = false -- the count is never clipped
		icon.Parent = popupCard

		local status = if have > 0 then "lit" else "empty"
		addThumbnail(icon, crop.id, slotPx() - 12)
		local thumb = icon:FindFirstChild("Thumb")
		if thumb and thumb:IsA("GuiObject") then
			thumb.AnchorPoint = Vector2.new(0.5, 0.5)
			thumb.Position = UDim2.fromScale(0.5, 0.5)
			thumb.Size = UDim2.fromOffset(slotPx() - 12, slotPx() - 12) -- the seed, as big as the ring allows
			thumb.ZIndex = 3
		end
			if have == 0 and thumb then
				-- Disabled look: the ring fades and greys, the seed is greyed (its viewport lighting goes grey, no overlay box).
				icon.ImageTransparency = 0.5
				icon.ImageColor3 = Color3.fromRGB(150, 150, 150)
				if thumb:IsA("ViewportFrame") then
					thumb.Ambient = Color3.fromRGB(120, 120, 120)
					thumb.LightColor = Color3.fromRGB(150, 150, 150)
				end
				thumb.BackgroundTransparency = 1
			end

		-- Count: white text, top right, inside the ring (no backdrop circle).
		local count = Instance.new("TextLabel")
		count.Name = "Count"
		count.AnchorPoint = Vector2.new(1, 0)
		count.Position = UDim2.new(1, -4, 0, 2)
		count.Size = UDim2.fromOffset(28, 18)
		count.BackgroundTransparency = 1
		count.TextColor3 = Color3.fromRGB(255, 255, 255)
		count.TextStrokeColor3 = Color3.fromRGB(60, 40, 20)
		count.TextStrokeTransparency = 0
		count.Font = UiKit.FONT
		count.TextSize = 13
		count.Text = "x" .. have
		count.ZIndex = 10
		count.Parent = icon

		-- Tap: a lit icon plants (the card closes); a grey/locked one explains itself in a small tip.
		local pressedAt = 0
		icon.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				pressedAt = os.clock()
			end
		end)
		icon.Activated:Connect(function()
			local held = os.clock() - pressedAt >= HOLD_TIP_SECONDS
			if status == "lit" and not held then
				-- The bed stays "empty" on this screen until the server confirms the planting: do not re-show the card for it.
				pendingPlant[bed] = os.clock() + 2
				hidePopup()
				plantAt(bed, crop.id)
				return
			end
			-- Held (lit) or a grey icon: a tip near the card (only unlocked seeds are on the card).
			popupTip.Text = if status == "empty" then Locale.t("seed.tip_none")
				else Locale.t("seed.tip_have", { name = Locale.t("crop." .. crop.id), n = have })
			popupTip.Visible = true
			tipHideAt = os.clock() + 1.6
		end)
	end
	-- Staggered pop from the middle: icons scale 0 -> 1, 0.05 s apart, from the centre out (LayoutOrder 1..n).
end

local function showPopup(bed: BasePart)
	popupBed = bed
	fillPopup(bed)
	popupGui.Enabled = true
	popupCard.Visible = true
	popupArrow.Visible = true
	popupScale.Scale = 0
	TweenService:Create(popupScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local children = {}
	for _, child in popupCard:GetChildren() do
		if child:IsA("TextButton") then
			table.insert(children, child)
		end
	end
	table.sort(children, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for position, icon in children do
		local stagger = Instance.new("UIScale")
		stagger.Scale = 0
		stagger.Parent = icon
		task.delay((position - 1) * 0.05, function()
			TweenService:Create(stagger, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end)
	end
end

-- Every frame: find the nearest empty bed in range, show / move / hide the popup, place it above the bed (below if no room,
-- clamped inside the screen), and keep the dashed ring on the ground around the bed.
local function updatePopup()
	if not popupGui then
		return
	end
	local blocked = GarapController.Active or UiKit.confirmOpen()
	local target = if blocked then nil else nearestEmptyBed()
	if target ~= popupBed then
		if target then
			showPopup(target)
		else
			hidePopup()
		end
	end
	if os.clock() > tipHideAt then
		popupTip.Visible = false
	end
	if not popupBed then
		for _, dot in ringDots do
			dot.Visible = false
		end
		return
	end
	local camera = Workspace.CurrentCamera :: Camera
	local view = camera.ViewportSize
	local bed = popupBed
	local center = bed.Position
	local top, onScreen = camera:WorldToViewportPoint(center + Vector3.new(0, bed.Size.Y / 2 + 1, 0))
	local width, height = popupCard.AbsoluteSize.X, popupCard.AbsoluteSize.Y
	local x = math.clamp(top.X, width / 2 + 8, view.X - width / 2 - 8)
	local above = top.Y - 18 - height >= 110 -- room above (the top bar and hint sit at the top)
	popupCard.AnchorPoint = Vector2.new(0.5, if above then 1 else 0)
	popupCard.Position = UDim2.fromOffset(x, if above then top.Y - 18 else top.Y + 18)
	popupArrow.AnchorPoint = Vector2.new(0.5, if above then 0 else 1)
	popupArrow.Text = if above then "▼" else "▲"
	popupArrow.Position = UDim2.fromOffset(math.clamp(top.X, 12, view.X - 12), if above then top.Y - 16 else top.Y + 16)
	popupArrow.Visible = onScreen
	popupTip.Position = UDim2.fromOffset(x, popupCard.AbsolutePosition.Y - 6)

	-- Dashed white ring: 12 dots, one stud past the bed's edge.
	for index, dot in ringDots do
		local angle = (index - 1) / RING_DOTS * math.pi * 2
		local point = center + Vector3.new(math.cos(angle) * RING_RADIUS, 0.2, math.sin(angle) * RING_RADIUS)
		local screen, visible = camera:WorldToViewportPoint(point)
		dot.Visible = visible
		dot.Position = UDim2.fromOffset(screen.X, screen.Y)
	end
end

-- STAGE 1: PANEN SEMUA + DRAG SIRAM -------------------------------------------------------------
-- Panen Semua: one tap sends the harvest of every ripe bed of mine, one by one (HARVEST_GAP apart), so each crop's
-- flight to the Bag queues up instead of landing on the same frame. Each one still goes through act("ripe"), so the
-- server stays the only authority (it re-checks ripeness, distance and rate).
-- Drag siram: a stroke that STARTS on a dry bed of mine waters every dry bed of mine that the pointer crosses.
local HARVEST_GAP = 0.25
local harvestAllButton: TextButton? = nil
local dragWaterActive = false
local dragWaterDone: { [BasePart]: boolean } = {}

local function myRipeParts(): { BasePart }
	local parts = {}
	for part, view in views do
		if view.isMine and getStage(part) == READY_STAGE then
			table.insert(parts, part)
		end
	end
	return parts
end

-- Panen Semua is LOCKED behind a Gamepass (decided 16 Nov; Plan v3 3.3's level 3 rule is withdrawn). For now it is hidden
-- completely: the button is never shown and its call is switched off. The harvest code (harvestAll) stays in place.
-- TODO Gamepass: set PanenSemuaGamepassId, make HasPanenSemuaGamepass real, then set PANEN_SEMUA_ENABLED = true.
local PANEN_SEMUA_ENABLED = false
local PanenSemuaGamepassId = "" -- TODO Gamepass: empty until the gamepass exists

local function harvestAll()
	if not PANEN_SEMUA_ENABLED then
		return -- locked (Gamepass TODO): the button is hidden, this is a second switch
	end
	local parts = myRipeParts()
	for index, part in parts do
		task.delay((index - 1) * HARVEST_GAP, function()
			if getStage(part) == READY_STAGE then
				act(part, "ripe")
			end
		end)
	end
end

local function buildHarvestAllButton()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HarvestAll"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = playerGui
	local button = UiKit.button(gui, "HarvestAllButton", Locale.t("ui.harvest_all"))
	button.Size = UDim2.fromOffset(190, UiKit.TOUCH)
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = UDim2.new(0.5, 0, 0, 124) -- below the hint bar at the top (it was covering the T1 hint, 16 Nov)
	button.Visible = false
	button.Activated:Connect(harvestAll)
	harvestAllButton = button
end

local function HasPanenSemuaGamepass(): boolean
	if PanenSemuaGamepassId == "" then
		return false -- no gamepass id yet
	end
	-- TODO Gamepass: return MarketplaceService:UserOwnsGamePassAsync(player.UserId, tonumber(PanenSemuaGamepassId)) (server-side check)
	return false
end

local function refreshHarvestAllButton()
	local button = harvestAllButton
	if not button then
		return
	end
	-- Hidden for now. Level and ripe beds no longer decide: only the gamepass will, once it exists.
	button.Visible = PANEN_SEMUA_ENABLED and HasPanenSemuaGamepass() and #myRipeParts() > 0 and not GarapController.Active
	if button.Visible then
		button.Text = Locale.t("ui.harvest_all") .. " (" .. #myRipeParts() .. ")"
	end
end

-- Drag siram ---------------------------------------------------------------------------------
local dragParams = RaycastParams.new()
dragParams.FilterType = Enum.RaycastFilterType.Include

local function tileUnderPointer(position: Vector2): BasePart?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	dragParams.FilterDescendantsInstances = CollectionService:GetTagged(TILE_TAG)
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, dragParams)
	if hit and hit.Instance:IsA("BasePart") then
		return hit.Instance
	end
	return nil
end

local function isDryMine(part: BasePart): boolean
	local view = views[part]
	return view ~= nil and view.isMine and getStage(part) ~= 0 and getStage(part) ~= READY_STAGE and part:GetAttribute("Watered") ~= true
end

local function waterStrokeAt(position: Vector2)
	local part = tileUnderPointer(position)
	if not part or dragWaterDone[part] or not isDryMine(part) then
		return
	end
	dragWaterDone[part] = true
	act(part, "dry")
end

local function setupDragWater()
	local UserInputService = game:GetService("UserInputService")
	local function isPointer(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not isPointer(input) or UiKit.confirmOpen() or GarapController.Active then
			return
		end
		local position = Vector2.new(input.Position.X, input.Position.Y)
		local part = tileUnderPointer(position)
		if part and isDryMine(part) then
			dragWaterActive = true
			table.clear(dragWaterDone)
			dragWaterDone[part] = true
			act(part, "dry")
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragWaterActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			waterStrokeAt(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isPointer(input) then
			dragWaterActive = false
		end
	end)
end

function FarmController.Start()
	-- In Garap mode a tap on a bed that is already here opens this same menu (GarapController.showGhost / act).
	GarapController.BedTapHandler = openBedMenu
	buildHarvestAllButton()
	buildGemborButton()
	setupDragWater()
	FarmFloat.Init({
		onAction = act,
		onHold = openBedMenu,
		blocked = function()
			return GarapController.Active or (pickerPanel ~= nil and pickerPanel.gui.Enabled) or UiKit.confirmOpen()
		end,
	})
	buildPopup()
	game:GetService("RunService").RenderStepped:Connect(updatePopup)
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
		refreshHarvestAllButton()
		refreshGemborButton()
	end
end

return FarmController
