--!strict
-- "Garap" mode (the Garap button in the dock): work your land with TWO tools, each one smart about what is under the pointer.
--   Cangkul   grass -> soil bed (green square). An EMPTY bed -> back to grass (orange square, "Hijaukan"). A bed with a crop is
--             left alone: the tap goes through to FarmController (water / harvest).
--   Kolam     free land -> dig a 16 x 16 pond (green square, price in the hint). Over a pond -> fill it in (orange, asks first,
--             50% refund).
-- So there is no "Hijaukan" / "Urug" button: the colour of the square and the little label above it say what the tap will do.
-- Planting an empty bed is done OUTSIDE Garap mode (a tap on an empty bed here would remove it).
-- Buying more land is NOT here: LandController floats a "+" over every chunk you can buy.
-- No popup menu: the tools are two buttons in the dock, Garap (Cangkul) and Kolam. Tap one to turn its mode on (green ring), tap
-- it again (or the other one switches mode) to finish. UI contract: dock buttons "GarapButton" and "KolamButton" (HUD > DockBar),
-- ScreenGui "GarapUI" > TextLabel "Hint".
-- The preview square is a transient client Part; the soil itself is terrain created by the server.
-- All checks here are only for the preview: the server validates every request again.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
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

local VALID_COLOR = Color3.fromRGB(150, 196, 120)
local INVALID_COLOR = Color3.fromRGB(200, 96, 80)
local LEVEL_COLOR = Color3.fromRGB(226, 178, 96)

local player = Players.LocalPlayer

local GarapController = {}
GarapController.Active = false -- LandController hides its "+" buttons while true
-- FarmController ignores tile taps while Garap is on, EXCEPT a bed WITH A CROP in "till" mode (water / harvest go through);
-- an empty bed there is Garap's own (it turns back to grass).
GarapController.Mode = "till"

local mode = "till" -- "till" (Cangkul) | "pond" (Kolam)
local gui: ScreenGui
local toggleButton: GuiButton
local kolamButton: GuiButton
local hintLabel: TextLabel
local ghost: Part? = nil
local ghostLabel: TextLabel? = nil

-- A dark bamboo-brown rounded box with a bamboo outline: the Garap bar and its hint (cream text on it).
local function darkBox(frame: GuiObject)
	frame.BackgroundColor3 = UiKit.DARK
	frame.BackgroundTransparency = 0.08
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 16)
	round.Parent = frame
	local border = Instance.new("UIStroke")
	border.Color = UiKit.BAMBOO
	border.Thickness = 3
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- on a TextLabel the default (Contextual) outlines the LETTERS in gold
	border.Parent = frame
end

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

-- Does this bed (uid) have a crop? Read from the attributes the server puts on the bed's click part.
local function bedHasCrop(uid: number): boolean
	for _, part in CollectionService:GetTagged("FarmTile") do
		if part:GetAttribute("Index") == uid and part:GetAttribute("Owner") == player.UserId then
			return part:GetAttribute("Crop") ~= nil
		end
	end
	return false
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
	return if Land.canTill(cx, cz, tiles, blockers, if snapshot then snapshot.landChunks else nil) then "valid" else "invalid"
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
	local snapshot = State.current :: any
	return #ponds < Fishing.POND.MAX_PONDS and Land.canPond(cx, cz, tiles, ponds, decorRects(plot), if snapshot then snapshot.landChunks else nil)
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
	if ghostLabel then
		ghostLabel.Visible = false
	end
end

-- Puts the label just above the ghost square's centre.
local function placeLabel()
	if not ghost or not ghostLabel then
		return
	end
	local screen, onScreen = (Workspace.CurrentCamera :: Camera):WorldToViewportPoint(ghost.Position + Vector3.new(0, 2.5, 0))
	ghostLabel.Visible = onScreen
	-- Scale-based position: the GUI may be auto-scaled (UiKit.autoScale), pixel offsets would drift.
	local view = (Workspace.CurrentCamera :: Camera).ViewportSize
	local inset = GuiService:GetGuiInset().Y
	ghostLabel.Position = UDim2.fromScale(screen.X / view.X, (screen.Y - inset) / (view.Y - inset))
end

local function ensureGhost(): Part
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
		-- A little label above the square says what a tap will do (Cangkul / Hijaukan / Gali kolam / Urug kolam). It is a plain
		-- screen label placed over the square each frame (a BillboardGui on the ghost never showed up).
		local label = Instance.new("TextLabel")
		label.Name = "Tip"
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Size = UDim2.fromOffset(92, 22)
		label.TextColor3 = UiKit.CREAM
		label.Font = UiKit.FONT
		label.TextSize = 13
		label.Visible = false
		darkBox(label)
		label.Parent = gui
		ghostLabel = label
		ghost = part
	end
	return ghost :: Part
end

-- What a tap would do at this spot: "till" | "level" | "pond" | "pondRemove" | nil (nothing, or not Garap's tap).
local function actionAt(plot: Model, cx: number, cz: number, point: Vector3): string?
	if mode == "pond" then
		return if pondAtPoint(point) then "pondRemove" else "pond"
	end
	local state = cellState(plot, cx, cz)
	if state == "tile" then
		local tile = tileAt(farmInfo(), cx, cz)
		if tile and not bedHasCrop(tile.uid) then
			return "level"
		end
		return nil -- a bed with a crop: the tap goes through to FarmController (water / harvest)
	end
	return "till"
end

local ACTION_TEXT = { till = "garap.tip_till", level = "garap.tip_level", pond = "garap.tip_pond", pondRemove = "garap.tip_pond_remove" }

local function showGhost(plot: Model?, cx: number?, cz: number?, point: Vector3?)
	if not plot or not cx or not cz or not point then
		hideGhost()
		return
	end
	local origin = plot.PrimaryPart :: BasePart
	local action = actionAt(plot, cx, cz, point)
	if not action then
		hideGhost()
		return
	end
	local preview = ensureGhost()
	preview.Shape = Enum.PartType.Block
	preview.Transparency = 0.55
	if ghostLabel then
		ghostLabel.Text = Locale.t(ACTION_TEXT[action])
	end

	-- Pond tools: a 16 x 16 square (the whole pond when filling it in).
	if action == "pond" or action == "pondRemove" then
		local rect: Land.Rect
		if action == "pond" then
			local pcx, pcz = pondCorner(point)
			rect = Land.pondRect(pcx, pcz)
			preview.Color = if pondBuildValid(plot, pcx, pcz) then VALID_COLOR else INVALID_COLOR
		else
			local pond = pondAtPoint(point) :: any
			rect = Land.pondRect(pond.cx, pond.cz)
			preview.Color = LEVEL_COLOR
		end
		preview.Size = Vector3.new(rect.maxX - rect.minX - 0.4, 0.2, rect.maxZ - rect.minZ - 0.4)
		preview.CFrame = origin.CFrame * CFrame.new((rect.minX + rect.maxX) / 2, origin.Size.Y / 2 + 0.3, (rect.minZ + rect.maxZ) / 2)
		placeLabel()
		return
	end

	-- Cangkul: green = can be tilled, red = cannot, orange = an empty bed (tap turns it back into grass).
	local state = cellState(plot, cx, cz)
	preview.Color = if action == "level" then LEVEL_COLOR elseif state == "valid" then VALID_COLOR else INVALID_COLOR
	if action == "till" and state ~= "valid" and ghostLabel then
		ghostLabel.Text = Locale.t("garap.tip_blocked")
	end
	-- The bed is a crisp slab of Farm.BED_SIZE, so the preview is exactly that square.
	preview.Size = Vector3.new(Farm.BED_SIZE, 0.2, Farm.BED_SIZE)
	local centerX, centerZ = Land.tileCenter(cx, cz)
	local lift = if state == "tile" then Farm.BED_RAISE else 0 -- an existing bed is a mound
	preview.CFrame = origin.CFrame * CFrame.new(centerX, origin.Size.Y / 2 + 0.3 + lift, centerZ) -- ground is at y = 0
	placeLabel()
end

-- Actions ------------------------------------------------------------------------------------

local function act(ray: Ray)
	local plot, cx, cz, point = pointerCell(ray)
	if not plot or not cx or not cz or not point then
		return
	end
	showGhost(plot, cx, cz, point)
	local action = actionAt(plot, cx, cz, point)
	if action == "pond" then
		local pcx, pcz = pondCorner(point)
		if pondBuildValid(plot, pcx, pcz) then
			Net.Send("PondBuild", pcx, pcz)
		end
	elseif action == "pondRemove" then
		local pond = pondAtPoint(point)
		if pond then
			-- Filling a pond loses its fish and refunds only part of the price: ask first (standard confirm modal).
			UiKit.confirm({
				title = Locale.t("garap.pond_remove_title"),
				body = Locale.t("garap.pond_remove_body"),
				confirmText = Locale.t("garap.pond_remove_yes"),
				onConfirm = function()
					Net.Send("PondRemove", pond.uid)
				end,
			} :: any)
		end
	elseif action == "till" then
		if cellState(plot, cx, cz) == "valid" then
			Net.Send("FarmTill", cx, cz)
			require(script.Parent.Parent.FarmFx).till(false)
		end
	elseif action == "level" then
		local tile = tileAt(farmInfo(), cx, cz)
		if tile then
			Net.Send("FarmLevel", tile.uid)
			require(script.Parent.Parent.FarmFx).till(true)
		end
	end
end

local function refreshHint()
	if mode == "till" then
		-- Once there is a bed, say what comes next (a new player used to be stuck here: the hint never changed).
		hintLabel.Text = Locale.t(if #farmInfo() > 0 then "garap.hint_till_more" else "garap.hint_till")
	else
		hintLabel.Text = Locale.t("garap.hint_pond", { price = pondPriceText() })
	end
end

local function setMode(newMode: string)
	mode = newMode
	GarapController.Mode = newMode
	UiKit.setMenuActive(toggleButton, GarapController.Active and mode == "till")
	UiKit.setMenuActive(kolamButton, GarapController.Active and mode == "pond")
	refreshHint()
	hideGhost()
end

-- on = Garap mode with that tool; off = finished.
local function setActive(on: boolean, newMode: string?)
	GarapController.Active = on
	hintLabel.Visible = on
	UiKit.setMenuLabel(toggleButton, Locale.t(if on and (newMode or mode) == "till" then "garap.done" else "ui.garap"))
	UiKit.setMenuLabel(kolamButton, Locale.t(if on and (newMode or mode) == "pond" then "garap.done" else "garap.tool_pond"))
	if on then
		setMode(newMode or "till")
	else
		setMode(mode)
		hideGhost()
	end
end

-- A dock button: off -> on with its tool; on with the same tool -> off; on with the other tool -> switch.
local function pressTool(tool: string)
	if GarapController.Active and mode == tool then
		setActive(false)
	else
		setActive(true, tool)
	end
end

-- UI -----------------------------------------------------------------------------------------

function GarapController.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "GarapUI"
	gui.ResetOnSpawn = false

	-- Garap lives in the dock with the other everyday buttons (UiKit.menuItem), not floating on the left.
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	toggleButton = UiKit.menuItem(hud :: Instance, "GarapButton", Locale.t("ui.garap"), 1) :: GuiButton

	hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(0.5, 0)
	hintLabel.Position = UDim2.new(0.5, 0, 0, 56)
	hintLabel.Size = UDim2.new(0.6, 0, 0, 36)
	hintLabel.TextColor3 = UiKit.CREAM
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.TextSize = 15
	hintLabel.TextWrapped = true
	hintLabel.Visible = false
	hintLabel.Parent = gui
	darkBox(hintLabel)

	kolamButton = UiKit.menuItem(hud :: Instance, "KolamButton", Locale.t("garap.tool_pond"), 2) :: GuiButton
	toggleButton.Activated:Connect(function()
		pressTool("till")
	end)
	kolamButton.Activated:Connect(function()
		pressTool("pond")
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

function GarapController.Start()
	State.Changed:Connect(function()
		if GarapController.Active then
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
