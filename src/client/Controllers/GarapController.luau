--!strict
-- "Garap" mode: till grass cells of your land into soil tiles, or level empty tiles back to grass.
-- UI contract (replace with your designed UI, keep the names):
--   ScreenGui "GarapUI" > TextButton "GarapButton" (toggle), Frame "Bar" (TextLabel "Count",
--   TextButton "TillButton", TextButton "LevelButton"), TextLabel "Hint".
-- The preview square is a transient client Part; the soil itself is terrain created by the server.
-- All checks here are only for the preview: the server validates every request again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local VALID_COLOR =Color3.fromRGB(150, 196, 120)
local INVALID_COLOR = Color3.fromRGB(200, 96, 80)
local LEVEL_COLOR = Color3.fromRGB(226, 178, 96)

local player = Players.LocalPlayer

local GarapController = {}
GarapController.Active = false -- FarmController ignores tile taps while true

local mode = "till" -- "till" | "level"
local gui: ScreenGui
local toggleButton: GuiButton
local bar: Frame
local hintLabel: TextLabel
local countLabel: TextLabel
local tillButton: TextButton
local levelButton: TextButton
local pondButton: TextButton
local pondRemoveButton: TextButton
local ghost: Part? = nil

-- Helpers ------------------------------------------------------------------------------------

local function myPlot(): Model?
	local name = player:GetAttribute("PlotName")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = if typeof(name) == "string" and plots then plots:FindFirstChild(name) else nil
	return if plot and plot:IsA("Model") and plot.PrimaryPart then plot else nil
end

local function farmInfo(): ({ any }, number)
	local snapshot = State.current :: any
	local farm = snapshot and snapshot.farm
	if farm then
		return farm.tiles, farm.cap
	end
	return {}, 0
end

local function tileAt(tiles: { any }, cx: number, cz: number): any?
	for _, tile in tiles do
		if tile.cx == cx and tile.cz == cz then
			return tile
		end
	end
	return nil
end

-- Placed decor rectangles, read from the attributes the server puts on every decor model.
local function decorRects(plot: Model): { Land.Rect }
	local rects: { Land.Rect } = {}
	local folder = plot:FindFirstChild("Decor")
	if folder then
		for _, model in folder:GetChildren() do
			local id, x, z, r = model:GetAttribute("ItemId"), model:GetAttribute("X"), model:GetAttribute("Z"), model:GetAttribute("R")
			if typeof(id) == "string" and typeof(x) == "number" and typeof(z) == "number" and typeof(r) == "number" then
				local rect = DecorGrid.entryRect({ uid = 0, id = id, x = x, z = z, r = r })
				if rect then
					table.insert(rects, rect)
				end
			end
		end
	end
	return rects
end

-- "tile" = already soil, "valid" = can be tilled, "invalid" = can't.
local function cellState(plot: Model, cx: number, cz: number): string
	local tiles, cap = farmInfo()
	if tileAt(tiles, cx, cz) then
		return "tile"
	end
	if #tiles >= cap then
		return "invalid"
	end
	local snapshot = State.current :: any
	local blockers = decorRects(plot)
	for _, rect in Land.pondRects(if snapshot and snapshot.ponds then snapshot.ponds else {}) do
		table.insert(blockers, rect)
	end
	return if Land.canTill(cx, cz, tiles, blockers) then "valid" else "invalid"
end

-- Plot-local point under a camera ray (the ground plane of the plot).
local function rayToLocal(ray: Ray, plot: Model): Vector3?
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

local function pointerCell(ray: Ray): (Model?, number?, number?, Vector3?)
	local plot = myPlot()
	if not plot then
		return nil, nil, nil, nil
	end
	local point = rayToLocal(ray, plot)
	if not point then
		return plot, nil, nil, nil
	end
	local cx, cz = Land.cellOfPoint(point.X, point.Z)
	return plot, cx, cz, point
end

-- Ponds -----------------------------------------------------------------------------------

local function pondsInfo(): { any }
	local snapshot = State.current :: any
	return if snapshot and snapshot.ponds then snapshot.ponds else {}
end

-- Pond placement is centered on the pointer: its min-corner tile cell is the nearest tile corner, minus one.
local function pondCorner(point: Vector3): (number, number)
	return math.floor(point.X / Land.TILE + 0.5) - 1, math.floor(point.Z / Land.TILE + 0.5) - 1
end

local function pondAtPoint(point: Vector3): any?
	for _, pond in pondsInfo() do
		local rect = Land.pondRect(pond.cx, pond.cz)
		if point.X >= rect.minX and point.X <= rect.maxX and point.Z >= rect.minZ and point.Z <= rect.maxZ then
			return pond
		end
	end
	return nil
end

local function pondBuildValid(plot: Model, cx: number, cz: number): boolean
	local tiles = farmInfo()
	local ponds = pondsInfo()
	return #ponds < Fishing.POND.MAX_PONDS and Land.canPond(cx, cz, tiles, ponds, decorRects(plot))
end

local function pondPriceText(): string
	local price = Fishing.POND.PRICES[math.min(#pondsInfo() + 1, #Fishing.POND.PRICES)]
	return if price <= 0 then Locale.t("garap.price_free") else Locale.t("garap.price", { n = price })
end

-- Preview ------------------------------------------------------------------------------------

local function hideGhost()
	if ghost then
		ghost.Transparency = 1
	end
end

local function showGhost(plot: Model?, cx: number?, cz: number?, point: Vector3?)
	if not plot or not cx or not cz or not point then
		hideGhost()
		return
	end
	local origin = plot.PrimaryPart :: BasePart

	-- Pond modes: a 16 x 16 square (the whole pond when removing).
	if mode == "pond" or mode == "pondRemove" then
		local rect: Land.Rect?
		local color = INVALID_COLOR
		if mode == "pond" then
			local pcx, pcz = pondCorner(point)
			rect = Land.pondRect(pcx, pcz)
			color = if pondBuildValid(plot, pcx, pcz) then VALID_COLOR else INVALID_COLOR
		else
			local pond = pondAtPoint(point)
			if pond then
				rect = Land.pondRect(pond.cx, pond.cz)
				color = LEVEL_COLOR
			end
		end
		if not rect then
			hideGhost()
			return
		end
		if not ghost then
			local part = Instance.new("Part")
			part.Name = "GarapGhost"
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Material = Enum.Material.Neon
			part.Parent = Workspace
			ghost = part
		end
		local preview = ghost :: Part
		preview.Shape = Enum.PartType.Block
		preview.Size = Vector3.new(rect.maxX - rect.minX - 0.4, 0.2, rect.maxZ - rect.minZ - 0.4)
		preview.Transparency = 0.55
		preview.Color = color
		preview.CFrame = origin.CFrame * CFrame.new((rect.minX + rect.maxX) / 2, origin.Size.Y / 2 + 0.3, (rect.minZ + rect.maxZ) / 2)
		return
	end

	local state = cellState(plot, cx, cz)
	local color = if mode == "till"
		then (if state == "valid" then VALID_COLOR else INVALID_COLOR)
		else (if state == "tile" then LEVEL_COLOR else INVALID_COLOR)

	if not ghost then
		local part = Instance.new("Part")
		part.Name = "GarapGhost"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Size = Vector3.new(Land.TILE - 0.4, 0.2, Land.TILE - 0.4)
		part.Parent = Workspace
		ghost = part
	end
	local preview = ghost :: Part
	-- The bed is a crisp slab of Farm.BED_SIZE, so the preview is exactly that square.
	preview.Shape = Enum.PartType.Block
	preview.Size = Vector3.new(Farm.BED_SIZE, 0.2, Farm.BED_SIZE)
	preview.Transparency = 0.55
	preview.Color = color
	local centerX, centerZ = Land.tileCenter(cx, cz)
	local lift = if state == "tile" then Farm.BED_RAISE else 0 -- an existing bed is a mound
	preview.CFrame = origin.CFrame * CFrame.new(centerX, origin.Size.Y / 2 + 0.3 + lift, centerZ) -- ground is at y = 0
end

-- Actions ------------------------------------------------------------------------------------

local function act(ray: Ray)
	local plot, cx, cz, point = pointerCell(ray)
	if not plot or not cx or not cz or not point then
		return
	end
	showGhost(plot, cx, cz, point)
	if mode == "pond" then
		local pcx, pcz = pondCorner(point)
		if pondBuildValid(plot, pcx, pcz) then
			Net.Send("PondBuild", pcx, pcz)
		end
	elseif mode == "pondRemove" then
		local pond = pondAtPoint(point)
		if pond then
			Net.Send("PondRemove", pond.uid)
		end
	elseif mode == "till" then
		if cellState(plot, cx, cz) == "valid" then
			Net.Send("FarmTill", cx, cz)
		end
	else
		local tile = tileAt(farmInfo(), cx, cz)
		if tile then
			Net.Send("FarmLevel", tile.uid)
		end
	end
end

local function refreshCount()
	local tiles, cap = farmInfo()
	countLabel.Text = Locale.t("garap.count", { n = #tiles, max = cap })
end

local function refreshHint()
	if mode == "till" then
		hintLabel.Text = Locale.t("garap.hint_till")
	elseif mode == "level" then
		hintLabel.Text = Locale.t("garap.hint_level")
	elseif mode == "pond" then
		hintLabel.Text = Locale.t("garap.hint_pond", { price = pondPriceText() })
	else
		hintLabel.Text = Locale.t("garap.hint_pond_remove")
	end
end

local function setMode(newMode: string)
	mode = newMode
	tillButton.BackgroundColor3 = if mode == "till" then UiKit.BUTTON else UiKit.BUTTON_MUTED
	levelButton.BackgroundColor3 = if mode == "level" then UiKit.BUTTON else UiKit.BUTTON_MUTED
	pondButton.BackgroundColor3 = if mode == "pond" then UiKit.BUTTON else UiKit.BUTTON_MUTED
	pondRemoveButton.BackgroundColor3 = if mode == "pondRemove" then UiKit.BUTTON else UiKit.BUTTON_MUTED
	refreshHint()
	hideGhost()
end

local function setActive(on: boolean)
	GarapController.Active = on
	bar.Visible = on
	hintLabel.Visible = on
	UiKit.setMenuLabel(toggleButton, Locale.t(if on then "garap.done" else "ui.garap"))
	if on then
		setMode("till")
		refreshCount()
	else
		hideGhost()
	end
end

-- UI -----------------------------------------------------------------------------------------

function GarapController.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "GarapUI"
	gui.ResetOnSpawn = false

	-- Garap lives in the right-hand dock with the other everyday buttons (UiKit.menuItem), not floating on the left.
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	toggleButton = UiKit.menuItem(hud :: Instance, "GarapButton", Locale.t("ui.garap"), 1) :: GuiButton

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
	hintLabel.Visible = false
	hintLabel.Parent = gui
	Instance.new("UICorner").Parent = hintLabel

	bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.Size = UDim2.fromOffset(330, 160)
	bar.BackgroundColor3 = UiKit.BG
	bar.BackgroundTransparency = 0.15
	bar.Visible = false
	bar.Parent = gui
	Instance.new("UICorner").Parent = bar

	countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.BackgroundTransparency = 1
	countLabel.Position = UDim2.fromOffset(12, 6)
	countLabel.Size = UDim2.new(1, -24, 0, 24)
	countLabel.TextColor3 = UiKit.TEXT
	countLabel.Font = Enum.Font.GothamMedium
	countLabel.TextSize = 16
	countLabel.Parent = bar

	tillButton = UiKit.button(bar, "TillButton", Locale.t("garap.till"), UiKit.BUTTON)
	tillButton.Position = UDim2.fromOffset(12, 40)
	tillButton.Size = UDim2.new(0.5, -18, 0, 48)
	tillButton.Activated:Connect(function()
		setMode("till")
	end)

	levelButton = UiKit.button(bar, "LevelButton", Locale.t("garap.level"), UiKit.BUTTON_MUTED)
	levelButton.AnchorPoint = Vector2.new(1, 0)
	levelButton.Position = UDim2.new(1, -12, 0, 40)
	levelButton.Size = UDim2.new(0.5, -18, 0, 48)
	levelButton.Activated:Connect(function()
		setMode("level")
	end)

	pondButton = UiKit.button(bar, "PondButton", Locale.t("garap.pond"), UiKit.BUTTON_MUTED)
	pondButton.Position = UDim2.fromOffset(12, 96)
	pondButton.Size = UDim2.new(0.5, -18, 0, 48)
	pondButton.Activated:Connect(function()
		setMode("pond")
	end)

	pondRemoveButton = UiKit.button(bar, "PondRemoveButton", Locale.t("garap.pond_remove"), UiKit.BUTTON_MUTED)
	pondRemoveButton.AnchorPoint = Vector2.new(1, 0)
	pondRemoveButton.Position = UDim2.new(1, -12, 0, 96)
	pondRemoveButton.Size = UDim2.new(0.5, -18, 0, 48)
	pondRemoveButton.Activated:Connect(function()
		setMode("pondRemove")
	end)

	toggleButton.Activated:Connect(function()
		setActive(not GarapController.Active)
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

function GarapController.Start()
	State.Changed:Connect(function()
		if GarapController.Active then
			refreshCount()
			refreshHint() -- the price of the next pond changes with every pond built
		end
	end)

	-- Desktop: click. Mobile: tap in the world.
	UserInputService.InputBegan:Connect(function(input, processed)
		if not GarapController.Active or processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local camera = Workspace.CurrentCamera
		act(camera:ScreenPointToRay(input.Position.X, input.Position.Y))
	end)
	UserInputService.TouchTapInWorld:Connect(function(position, processedByUi)
		if GarapController.Active and not processedByUi then
			local camera = Workspace.CurrentCamera
			act(camera:ViewportPointToRay(position.X, position.Y))
		end
	end)

	-- Desktop hover preview.
	RunService.RenderStepped:Connect(function()
		if GarapController.Active and UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
			local mouse = UserInputService:GetMouseLocation()
			local plot, cx, cz, point = pointerCell(Workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y))
			showGhost(plot, cx, cz, point)
		end
	end)
end

return GarapController
