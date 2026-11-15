--!strict
-- Decor mode ("Hias") for your own plot.
--   Catalog item -> ghost preview snapped to the grid (green = ok, red = blocked).
--   Desktop: ghost follows the mouse, click to place, R to rotate.
--   Mobile: tap the ground to move the ghost, then "Pasang".
--   Tap an existing decor -> move / rotate / "Simpan" (back to storage).
-- After placing a NEW item the ghost stays, so fences and paths can be laid quickly.
--
-- UI CONTRACT: a button named "DecorButton" in your HUD toggles decor mode (placeholder
-- added if missing). The DecorUI panel itself is a placeholder for now.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Decor = require(ReplicatedStorage.Shared.Config.Decor)
local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

type Item = Decor.Item

type Placing = {
	item: Item,
	x: number,
	z: number,
	r: number,
	uid: number?, -- set when moving an existing decor
	valid: boolean,
}

local ROTATE_ACTION = "DecorRotate"
local VALID_COLOR = Color3.fromRGB(150, 196, 120)
local INVALID_COLOR = Color3.fromRGB(200, 96, 80)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local DecorController = {}

local active = false
local placing: Placing? = nil
local ghost: Model? = nil
local highlight: Highlight? = nil
local hiddenParts: { [BasePart]: number } = {}

local gui: ScreenGui
local hintLabel: TextLabel
local countLabel: TextLabel
local catalog: ScrollingFrame
local actionBar: Frame
local confirmButton: TextButton
local storeButton: TextButton

-- World helpers ---------------------------------------------------------------------

local function myPlot(): Model?
	local name = player:GetAttribute("PlotName")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = if typeof(name) == "string" and plots then plots:FindFirstChild(name) else nil
	return if plot and plot:IsA("Model") and plot.PrimaryPart then plot else nil
end

local function placedEntries(plot: Model): { any }
	local entries = {}
	local folder = plot:FindFirstChild("Decor")
	if folder then
		for _, model in folder:GetChildren() do
			local uid = model:GetAttribute("Uid")
			if typeof(uid) == "number" then
				table.insert(entries, {
					uid = uid,
					id = model:GetAttribute("ItemId"),
					x = model:GetAttribute("X"),
					z = model:GetAttribute("Z"),
					r = model:GetAttribute("R"),
				})
			end
		end
	end
	return entries
end

-- Where a screen ray hits the plot's top plane, in plot-local studs.
local function rayToPlotLocal(ray: Ray, plot: Model): Vector3?
	local origin = plot.PrimaryPart :: BasePart
	local planeY = origin.Position.Y + origin.Size.Y / 2
	if math.abs(ray.Direction.Y) < 1e-4 then
		return nil
	end
	local t = (planeY - ray.Origin.Y) / ray.Direction.Y
	if t <= 0 then
		return nil
	end
	return origin.CFrame:PointToObjectSpace(ray.Origin + ray.Direction * t)
end

-- Ghost -----------------------------------------------------------------------------

local function refreshGhost()
	local state = placing
	local plot = myPlot()
	if not state or not ghost or not plot then
		return
	end
	local origin = plot.PrimaryPart :: BasePart
	ghost:PivotTo(origin.CFrame * DecorGrid.localCFrame(state.item, state.x, state.z, state.r, origin.Size.Y / 2))

	local snapshot = State.current :: any
	local occupied = DecorGrid.occupancy(
		placedEntries(plot) :: any,
		if snapshot and snapshot.farm then snapshot.farm.tiles else nil,
		Land.pondRects(if snapshot and snapshot.ponds then snapshot.ponds else {})
	)
	state.valid = DecorGrid.isValid(state.item, state.x, state.z, state.r, occupied, state.uid, if snapshot then snapshot.landChunks else nil)
	if highlight then
		highlight.FillColor = if state.valid then VALID_COLOR else INVALID_COLOR
	end
	confirmButton.AutoButtonColor = state.valid
	confirmButton.BackgroundColor3 = if state.valid then UiKit.BUTTON else UiKit.BUTTON_MUTED
end

local function moveGhostTo(ray: Ray)
	local state = placing
	local plot = myPlot()
	if not state or not plot then
		return
	end
	local localPoint = rayToPlotLocal(ray, plot)
	if localPoint then
		local x, z = DecorGrid.cellFromLocal(state.item, state.r, localPoint)
		if x ~= state.x or z ~= state.z then -- only re-validate when the cell changes
			state.x, state.z = x, z
			refreshGhost()
		end
	end
end

local function restoreHidden()
	for part, transparency in hiddenParts do
		part.LocalTransparencyModifier = transparency
	end
	table.clear(hiddenParts)
end

local function endPlacing()
	if ghost then
		ghost:Destroy()
	end
	ghost = nil
	highlight = nil
	placing = nil
	restoreHidden()
	ContextActionService:UnbindAction(ROTATE_ACTION)
	actionBar.Visible = false
	hintLabel.Text = Locale.t("decor.hint")
end

local function rotate()
	local state = placing
	if not state then
		return
	end
	state.r = (state.r + 1) % 4
	local w, d = DecorGrid.footprint(state.item, state.r)
	state.x = math.clamp(state.x, DecorGrid.X_MIN, DecorGrid.X_MAX - w)
	state.z = math.clamp(state.z, DecorGrid.Z_MIN, DecorGrid.Z_MAX - d)
	refreshGhost()
end

local function startPlacing(item: Item, existing: Model?)
	endPlacing()
	local plot = myPlot()
	if not plot then
		return
	end

	local model = DecorGrid.build(item)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Transparency = math.max(part.Transparency, 0.35)
		end
	end
	local glow = Instance.new("Highlight")
	glow.FillTransparency = 0.55
	glow.OutlineTransparency = 0.3
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = model
	model.Parent = Workspace
	ghost, highlight = model, glow

	local state: Placing = { item = item, x = 0, z = 0, r = 0, uid = nil, valid = false }
	if existing then
		state.uid = existing:GetAttribute("Uid") :: number
		state.x = existing:GetAttribute("X") :: number
		state.z = existing:GetAttribute("Z") :: number
		state.r = existing:GetAttribute("R") :: number
		for _, part in existing:GetDescendants() do
			if part:IsA("BasePart") then
				hiddenParts[part] = part.LocalTransparencyModifier
				part.LocalTransparencyModifier = 1
			end
		end
	else
		-- Start next to the player if they're on their plot, else the plot center.
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local origin = plot.PrimaryPart :: BasePart
		local localPoint = if root and root:IsA("BasePart")
			then origin.CFrame:PointToObjectSpace(root.Position + root.CFrame.LookVector * 6)
			else Vector3.zero
		state.x, state.z = DecorGrid.cellFromLocal(item, 0, localPoint)
	end
	placing = state

	storeButton.Visible = state.uid ~= nil
	actionBar.Visible = true
	hintLabel.Text = Locale.t(if UserInputService.TouchEnabled then "decor.hint_touch" else "decor.hint_mouse")
	ContextActionService:BindAction(ROTATE_ACTION, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			rotate()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)
	refreshGhost()
end

local function confirm()
	local state = placing
	if not state or not state.valid then
		return
	end
	if state.uid then
		Net.Send("DecorMove", state.uid, state.x, state.z, state.r)
		endPlacing()
	else
		Net.Send("DecorPlace", state.item.id, state.x, state.z, state.r)
		require(ReplicatedStorage.Shared.Sfx).play("place_item")
		-- Keep the ghost for the next one; it turns red once the server model occupies the cell.
		task.delay(0.3, refreshGhost)
	end
end

local function storeSelected()
	local state = placing
	if state and state.uid then
		Net.Send("DecorStore", state.uid)
		endPlacing()
	end
end

-- Pointer -----------------------------------------------------------------------------

local function trySelectExisting(ray: Ray)
	local plot = myPlot()
	local folder = plot and plot:FindFirstChild("Decor")
	if not folder then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if not result then
		return
	end
	local model = result.Instance:FindFirstAncestorWhichIsA("Model")
	while model and model.Parent ~= folder do
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	local itemId = model and model:GetAttribute("ItemId")
	local item = typeof(itemId) == "string" and Decor.byId[itemId] or nil
	if model and item then
		startPlacing(item, model)
	end
end

local function onPointer(ray: Ray, isMouse: boolean)
	if not active then
		return
	end
	if placing then
		moveGhostTo(ray)
		if isMouse then
			confirm()
		end
	else
		trySelectExisting(ray)
	end
end

-- UI ---------------------------------------------------------------------------------

local function catalogText(item: Item, snapshot: State.Snapshot?): (string, boolean)
	local name = Locale.t(`decor.{item.id}`)
	if item.event then
		name = `{name} · {Locale.t("event.tag")}`
	end
	local stock = snapshot and snapshot.decorStock[item.id] or 0
	if stock > 0 then
		return `{name}\n{Locale.t("decor.stock", { n = stock })}`, true
	end
	-- Buying needs the blueprint (owned stock above never does).
	local blueprints = snapshot and snapshot.decorBlueprints or {}
	if item.blueprint and blueprints[item.blueprint] ~= true then
		local blueprintName = Locale.t(`blueprint.{item.blueprint}`)
		return `{name}\n{Locale.t("decor.need_blueprint", { name = blueprintName })}`, false
	end
	local priceKey = if item.currency == "bunga" then "ui.bunga" else "ui.koin"
	return `{name}\n{Locale.t(priceKey, { n = Locale.formatNumber(item.price) })}`, true
end

-- Seasonal items show only while their event runs, or when you still have some in stock.
local function isListed(item: Item, snapshot: State.Snapshot?): boolean
	if not item.event then
		return true
	end
	local stock = snapshot and snapshot.decorStock[item.id] or 0
	return stock > 0 or Workspace:GetAttribute("ActiveEvent") == item.event
end

local function renderCatalog()
	local snapshot = State.current
	if snapshot then
		countLabel.Text = Locale.t("decor.count", { n = snapshot.decorPlaced, max = snapshot.decorMax })
	end
	for order, item in Decor.list do
		local button = catalog:FindFirstChild(item.id) :: TextButton?
		if not button then
			local newButton = UiKit.button(catalog, item.id, "", UiKit.ROW)
			newButton.LayoutOrder = order
			newButton.Size = UDim2.fromOffset(120, 64)
			newButton.TextWrapped = true
			newButton.TextSize = 13
			newButton.Activated:Connect(function()
				if newButton:GetAttribute("Enabled") == true then
					startPlacing(item, nil)
				end
			end)
			button = newButton
		end
		local text, enabled = catalogText(item, snapshot)
		local target = button :: TextButton
		target.Visible = isListed(item, snapshot)
		target.Text = text
		target:SetAttribute("Enabled", enabled)
		target.TextTransparency = if enabled then 0 else 0.45
	end
end

local function buildUi()
	gui = Instance.new("ScreenGui")
	gui.Name = "DecorUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false

	hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(0.5, 0)
	hintLabel.Position = UDim2.new(0.5, 0, 0, 12)
	hintLabel.Size = UDim2.new(0.6, 0, 0, 34)
	hintLabel.BackgroundColor3 = UiKit.BG
	hintLabel.BackgroundTransparency = 0.2
	hintLabel.TextColor3 = UiKit.TEXT
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.TextSize = 14
	hintLabel.TextWrapped = true
	hintLabel.Text = Locale.t("decor.hint")
	hintLabel.Parent = gui
	Instance.new("UICorner").Parent = hintLabel

	local done = UiKit.button(gui, "Done", Locale.t("ui.done"), UiKit.BG)
	done.AnchorPoint = Vector2.new(1, 0)
	done.Position = UDim2.new(1, -16, 0, 64)
	done.Size = UDim2.fromOffset(100, 40)
	done.Activated:Connect(function()
		DecorController.SetActive(false)
	end)

	local bottom = Instance.new("Frame")
	bottom.Name = "Catalog"
	bottom.AnchorPoint = Vector2.new(0.5, 1)
	bottom.Position = UDim2.new(0.5, 0, 1, -10)
	bottom.Size = UDim2.new(1, -20, 0, 104)
	bottom.BackgroundColor3 = UiKit.BG
	bottom.BackgroundTransparency = 0.15
	bottom.Parent = gui
	Instance.new("UICorner").Parent = bottom

	countLabel = Instance.new("TextLabel")
	countLabel.BackgroundTransparency = 1
	countLabel.Position = UDim2.fromOffset(12, 4)
	countLabel.Size = UDim2.new(1, -24, 0, 20)
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.TextColor3 = UiKit.TEXT
	countLabel.Font = Enum.Font.Gotham
	countLabel.TextSize = 13
	countLabel.Parent = bottom

	catalog = Instance.new("ScrollingFrame")
	catalog.Name = "Items"
	catalog.BackgroundTransparency = 1
	catalog.BorderSizePixel = 0
	catalog.Position = UDim2.fromOffset(8, 28)
	catalog.Size = UDim2.new(1, -16, 0, 70)
	catalog.CanvasSize = UDim2.new()
	catalog.AutomaticCanvasSize = Enum.AutomaticSize.X
	catalog.ScrollingDirection = Enum.ScrollingDirection.X
	catalog.ScrollBarThickness = 4
	catalog.Parent = bottom

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = catalog

	actionBar = Instance.new("Frame")
	actionBar.Name = "Actions"
	actionBar.AnchorPoint = Vector2.new(0.5, 1)
	actionBar.Position = UDim2.new(0.5, 0, 1, -122)
	actionBar.Size = UDim2.fromOffset(440, 44)
	actionBar.BackgroundTransparency = 1
	actionBar.Visible = false
	actionBar.Parent = gui

	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionLayout.Padding = UDim.new(0, 8)
	actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	actionLayout.Parent = actionBar

	local function actionButton(name: string, textKey: string, order: number, color: Color3, onClick: () -> ()): TextButton
		local button = UiKit.button(actionBar, name, Locale.t(textKey), color)
		button.LayoutOrder = order
		button.Size = UDim2.fromOffset(100, 44)
		button.Activated:Connect(onClick)
		return button
	end
	actionButton("Rotate", "ui.rotate", 1, UiKit.BG, rotate)
	confirmButton = actionButton("Confirm", "ui.place", 2, UiKit.BUTTON, confirm)
	storeButton = actionButton("Store", "ui.store", 3, UiKit.BG, storeSelected)
	actionButton("Cancel", "ui.cancel", 4, UiKit.BUTTON_MUTED, endPlacing)

	gui.Parent = player:WaitForChild("PlayerGui")
end

local function hookDecorButton()
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	if not hud then
		return
	end
	local button = UiKit.menuItem(hud, "DecorButton", Locale.t("ui.decor"), 2)
	if button then
		button.Activated:Connect(function()
			DecorController.SetActive(not active)
		end)
	end
end

function DecorController.SetActive(value: boolean)
	active = value
	if not value then
		endPlacing()
	end
	gui.Enabled = value
	if value then
		renderCatalog()
	end
end

function DecorController.Init()
	buildUi()
end

function DecorController.Start()
	task.spawn(hookDecorButton)
	State.Changed:Connect(function()
		if active then
			renderCatalog()
		end
	end)
	Workspace:GetAttributeChangedSignal("ActiveEvent"):Connect(function()
		if active then
			renderCatalog()
		end
	end)
	player:GetAttributeChangedSignal("Level"):Connect(function()
		if active then
			renderCatalog()
		end
	end)

	-- Desktop: click places / selects. Mobile: tap moves the ghost / selects.
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		onPointer(camera:ScreenPointToRay(input.Position.X, input.Position.Y), true)
	end)
	UserInputService.TouchTapInWorld:Connect(function(position, processedByUi)
		if not processedByUi then
			onPointer(camera:ViewportPointToRay(position.X, position.Y), false)
		end
	end)

	-- Desktop hover preview.
	RunService.RenderStepped:Connect(function()
		if active and placing and UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
			local mouse = UserInputService:GetMouseLocation()
			moveGhostTo(camera:ViewportPointToRay(mouse.X, mouse.Y))
		end
	end)
end

return DecorController
