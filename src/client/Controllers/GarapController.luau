--!strict
-- "Garap" mode (the Garap button in the dock): work your land with TWO tools, each one smart about what is under the pointer.
--   Cangkul   grass -> soil bed (ghost square, green = valid, gray = not here). A bed with a crop, or an empty bed, is left to
--             FarmController (water / harvest / plant / Pindah / Hapus Petak from the bed menu). Hapus Petak is a bed-menu
--             action with a confirm; there is no "Hijaukan" any more (the word is gone from the game).
--   Kolam     free land -> dig a 16 x 16 pond (green square, price in the hint). Over a pond -> fill it in (orange, asks first,
--             50% refund).
-- GRID: while Garap (or Pindah) is on, your own land shows a thin white grid (about 38 % opaque), one square per bed cell.
-- The ghost snaps to that grid and follows the pointer / finger; a green arrow bobbing above it means "tap here", a gray one
-- means "not here". Pindah uses the same grid and ghost: a long press on an empty bed starts it (see FarmController).
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
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Decor = require(ReplicatedStorage.Shared.Config.Decor)
local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local VALID_COLOR = Color3.fromRGB(104, 214, 84) -- bright green: clearly "can place" on grass (the ghost is a preview)
local INVALID_COLOR = Color3.fromRGB(196, 72, 60) -- red: "not here" (a warm red, same family as Hapus Petak)
local ARROW_VALID = Color3.fromRGB(150, 220, 110)
local ARROW_INVALID = Color3.fromRGB(230, 90, 76)
local GRID_COLOR = Color3.fromRGB(255, 255, 255)
local GRID_TRANSPARENCY = 0.8 -- thin line every 2 studs: faint, grass shows through
local GRID_THICK_TRANSPARENCY = 0.55 -- thick line every 8 studs (a bed square): clearer
local GRID_WIDTH = 0.06
local GRID_THICK_WIDTH = 0.16
local GRID_LIFT = 0.08 -- studs above the ground, so the lines do not z-fight the grass

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
local refreshKolamButton: () -> ()
local hintLabel: TextLabel
local ghost: Part? = nil
local ghostLabel: TextLabel? = nil -- the green / gray arrow above the ghost (name kept from the old label)
local gridFolder: Folder? = nil -- the white grid over your own land (only while Garap / Pindah is on)
local TILE_TAG = "FarmTile"
local movingUid: number? = nil -- Pindah: the bed being moved (nil = not moving)
local movePart: BasePart? = nil -- the original bed part being moved
local movePreview: Model? = nil -- the translucent copy that follows the pointer
local moveOutline: Highlight? = nil
local moveSource: { cx: number, cz: number } = { cx = 0, cz = 0 }
local pointer: Vector2? = nil -- last touch position (viewport px); the ghost follows it on phones
local hintHidden = false -- the tutorial's coachmark is on: its bubble replaces this hint

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

-- GRASS CHECK: a bed square (8x8) may only be placed when EVERY sample point of it sits on Leafy Grass. 5 x 5 points at the
-- edges and in between (0, 2, 4, 6, 7.9 studs), so half on a road or a building is caught. A ray goes down from above each
-- point; a hit on Terrain must be LeafyGrass, a hit on any part (road slab, building, fence) or no hit at all counts as "not
-- grass". Cached for half a second: this runs for the ghost every frame.
local GRASS_OFFSETS = { 0, 2, 4, 6, 7.9 }
local grassCache: { [string]: { ok: boolean, at: number } } = {}
local grassParams: RaycastParams? = nil

-- B (playtest): the grass check asks ONLY the terrain. It used to exclude a few known parts, so any other part above the
-- ground (a weed, bush, rock, stump, fence, decor) hit first, the material was not LeafyGrass, and the square was invalid.
-- Include-filter on Workspace.Terrain makes the ray ignore every part, decor and clutter included.
local function grassRayParams(): RaycastParams
	if not grassParams then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.IgnoreWater = false
		params.FilterDescendantsInstances = { Workspace.Terrain }
		grassParams = params
	end
	return grassParams :: RaycastParams
end

local function squareIsGrass(plot: Model, cx: number, cz: number): boolean
	local key = `{cx},{cz}`
	local cached = grassCache[key]
	local now = os.clock()
	if cached and now - cached.at < 0.5 then
		return cached.ok
	end
	local origin = plot.PrimaryPart :: BasePart
	local rect = Land.tileRect(cx, cz)
	local params = grassRayParams()
	local ok = true
	for _, ox in GRASS_OFFSETS do
		for _, oz in GRASS_OFFSETS do
			local world = origin.CFrame:PointToWorldSpace(Vector3.new(rect.minX + ox, 0, rect.minZ + oz))
			local hit = Workspace:Raycast(world + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), params)
			local onGrass = hit ~= nil and hit.Instance:IsA("Terrain") and hit.Material == Enum.Material.LeafyGrass
			if not onGrass then
				ok = false
			end
		end
	end
	grassCache[key] = { ok = ok, at = now }
	return ok
end

-- "tile" = already soil, "valid" = can be tilled, "invalid" = can't (blocked, outside the land, or not all Leafy Grass).
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
	if not Land.canTill(cx, cz, tiles, blockers, if snapshot then snapshot.landChunks else nil) then
		return "invalid"
	end
	return if squareIsGrass(plot, cx, cz) then "valid" else "invalid"
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
	if not ghostLabel then
		return
	end
	-- the arrow sits over the moving bed copy during Pindah, otherwise over the ghost square
	local anchor = if movePreview then movePreview:GetPivot().Position elseif ghost then ghost.Position else nil
	if not anchor then
		return
	end
	local screen, onScreen = (Workspace.CurrentCamera :: Camera):WorldToViewportPoint(anchor + Vector3.new(0, 2.5, 0))
	ghostLabel.Visible = onScreen and (movePreview ~= nil or (ghost ~= nil and ghost.Transparency < 1))
	-- Scale-based position: the GUI may be auto-scaled (UiKit.autoScale), pixel offsets would drift. The bob is a pixel
	-- offset on top of that (it moves the arrow up and down, 0..6 px, so it reads as "tap here").
	local view = (Workspace.CurrentCamera :: Camera).ViewportSize
	local inset = GuiService:GetGuiInset().Y
	local bob = (math.sin(os.clock() * 5) + 1) * 3
	ghostLabel.Position = UDim2.new(screen.X / view.X, 0, (screen.Y - inset) / (view.Y - inset), -bob)
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
		-- An arrow above the square: it bobs down toward the ghost (green = tap here, gray = not here). A plain screen label placed
		-- over the square each frame (a BillboardGui on the ghost never showed up).
		local arrow = Instance.new("TextLabel")
		arrow.Name = "Arrow"
		arrow.AnchorPoint = Vector2.new(0.5, 1)
		arrow.Size = UDim2.fromOffset(34, 26)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▼"
		arrow.TextColor3 = ARROW_VALID
		arrow.Font = UiKit.FONT
		arrow.TextSize = 24
		arrow.Visible = false
		arrow.Parent = gui
		ghostLabel = arrow
		ghost = part
	end
	return ghost :: Part
end

-- What a tap would do at this spot: "till" | "pond" | "pondRemove" | nil (nothing, or not Garap's tap).
local function actionAt(plot: Model, cx: number, cz: number, point: Vector3): string?
	if mode == "pond" then
		return if pondAtPoint(point) then "pondRemove" else "pond"
	end
	local state = cellState(plot, cx, cz)
	if state == "tile" then
		return nil -- a bed already here: no Garap action (crop: water / harvest; empty: the bed menu, long press)
	end
	return "till"
end

-- Pindah: the free cell under the pointer for the bed being moved. The moving bed does not block its own cell.
local function moveState(plot: Model, cx: number, cz: number): string
	local tiles, _cap = farmInfo()
	local others = {}
	for _, tile in tiles do
		if tile.uid ~= movingUid then
			table.insert(others, tile)
		end
	end
	local blockers = decorRects(plot)
	for _, rect in Land.pondRects(if State.current and (State.current :: any).ponds then (State.current :: any).ponds else {}) do
		table.insert(blockers, rect)
	end
	local ok = Land.canTill(cx, cz, others, blockers, if State.current then (State.current :: any).landChunks else nil)
	-- Pindah obeys the same grass rule as Garap: a bed never moves onto a road, a building or bare ground.
	return if ok and squareIsGrass(plot, cx, cz) then "valid" else "invalid"
end

-- Public hooks: FarmController sets BedTapHandler (opens the Pindah / Hapus menu) and flips MenuOpen while that menu is up.
GarapController.MenuOpen = false
local lastGhostValid: boolean? = nil -- what the hint last said for a placement ghost (valid / not)
GarapController.BedTapHandler = nil :: ((part: BasePart, kind: string) -> ())?

-- My bed on a cell (its Tile part), or nil.
local function bedPartAt(cx: number, cz: number): BasePart?
	for _, part in CollectionService:GetTagged("FarmTile") do
		if part:IsA("BasePart") and part:GetAttribute("Owner") == player.UserId and part:GetAttribute("Cx") == cx and part:GetAttribute("Cz") == cz then
			return part
		end
	end
	return nil
end

-- Forward declaration: refreshHint is defined further down, but setBedHover (below) calls it. Declared here so the name exists.
local refreshHint: () -> () -- defined below (forward declaration)

-- A yellow outline around the bed under the pointer (a Highlight, no fill): "this is an existing bed, not a place to put one".
local bedHighlight: Highlight? = nil
local hoverPart: BasePart? = nil
local function setBedHover(part: BasePart?)
	if part == hoverPart then
		return
	end
	hoverPart = part
	if part then
		if not bedHighlight then
			local highlight = Instance.new("Highlight")
			highlight.Name = "GarapBedOutline"
			highlight.FillTransparency = 1
			highlight.OutlineColor = Color3.fromRGB(255, 226, 120) -- gold, same as the tutorial ring
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			bedHighlight = highlight
		end
		local outline = bedHighlight :: Highlight
		outline.Adornee = part
		outline.Parent = part
		hintLabel.Text = Locale.t("garap.hint_bed")
		lastGhostValid = nil
	else
		if bedHighlight then
			bedHighlight.Adornee = nil
			bedHighlight.Parent = nil
		end
		lastGhostValid = nil
		refreshHint()
	end
end

-- The arrow above the ghost: green = tap here, gray = not here.
local function setArrow(valid: boolean)
	if ghostLabel then
		ghostLabel.TextColor3 = if valid then ARROW_VALID else ARROW_INVALID
	end
	-- The hint line says why a square is refused; it changes only when the state changes (no per-frame text churn).
	if valid ~= lastGhostValid then
		lastGhostValid = valid
		if valid then
			refreshHint()
		else
			hintLabel.Text = Locale.t("garap.tip_not_grass")
		end
	end
end

local function showGhost(plot: Model?, cx: number?, cz: number?, point: Vector3?)
	if not plot or not cx or not cz or not point then
		hideGhost()
		return
	end
	local origin = plot.PrimaryPart :: BasePart
	if movingUid ~= nil then
		-- Pindah: the translucent copy of the bed follows the pointer on the grid (the same 8x8 square as Garap). Green outline
		-- where it may be placed, red where not. The original stays lifted (50 %) until it is put down or the move is cancelled.
		local valid = moveState(plot, cx, cz) == "valid"
		hideGhost()
		if movePreview and movePart and movePart.Parent then
			local srcX, srcZ = Land.tileCenter(moveSource.cx, moveSource.cz)
			local dstX, dstZ = Land.tileCenter(cx, cz)
			local target = origin.CFrame * CFrame.new(dstX - srcX, 0, dstZ - srcZ) * origin.CFrame:ToObjectSpace(movePart.CFrame)
			movePreview:PivotTo(target)
			if moveOutline then
				moveOutline.OutlineColor = if valid then Color3.fromRGB(120, 230, 90) else Color3.fromRGB(230, 70, 60)
			end
		end
		setArrow(valid)
		if ghostLabel then
			ghostLabel.Visible = true
		end
		placeLabel()
		return
	end
	-- A bed that is already here: no placement ghost. An outline (Highlight) marks the bed and the hint says what a tap does.
	if movingUid == nil and not GarapController.MenuOpen and cellState(plot, cx, cz) == "tile" then
		hideGhost()
		setBedHover(bedPartAt(cx, cz))
		return
	end
	setBedHover(nil)
	local action = actionAt(plot, cx, cz, point)
	if not action then
		hideGhost()
		return
	end
	local preview = ensureGhost()
	preview.Shape = Enum.PartType.Block
	preview.Transparency = 0.3

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
			preview.Color = VALID_COLOR
		end
		preview.Size = Vector3.new(rect.maxX - rect.minX - 0.4, 0.2, rect.maxZ - rect.minZ - 0.4)
		preview.CFrame = origin.CFrame * CFrame.new((rect.minX + rect.maxX) / 2, origin.Size.Y / 2 + 0.3, (rect.minZ + rect.maxZ) / 2)
		placeLabel()
		return
	end

	-- Cangkul: green = can be tilled here (inside your land, free), gray = not here (road, outside the fence, another bed).
	local state = cellState(plot, cx, cz)
	local valid = state == "valid"
	preview.Color = if valid then VALID_COLOR else INVALID_COLOR
	setArrow(valid)
	if ghostLabel then
		ghostLabel.Visible = true
	end
	-- The bed is a crisp slab of Farm.BED_SIZE, so the preview is exactly that square.
	preview.Size = Vector3.new(Land.TILE, 0.2, Land.TILE) -- exactly one grid square (8 studs): no gap around the ghost
	local centerX, centerZ = Land.tileCenter(cx, cz)
	local lift = if state == "tile" then Farm.BED_RAISE else 0 -- an existing bed is a mound
	preview.CFrame = origin.CFrame * CFrame.new(centerX, origin.Size.Y / 2 + 0.3 + lift, centerZ) -- ground is at y = 0
	placeLabel()
end

-- Actions ------------------------------------------------------------------------------------

-- The nearest valid till square among the 8 neighbours of (cx, cz), by distance to the tap point. nil when none is valid.
local function snapCell(plot: Model, cx: number, cz: number, point: Vector3): (number?, number?)
	local bestX, bestZ, bestDistance = nil, nil, math.huge
	for dx = -1, 1 do
		for dz = -1, 1 do
			if dx ~= 0 or dz ~= 0 then
				local nx, nz = cx + dx, cz + dz
				if cellState(plot, nx, nz) == "valid" then
					local centerX, centerZ = Land.tileCenter(nx, nz)
					local distance = (Vector2.new(centerX, centerZ) - Vector2.new(point.X, point.Z)).Magnitude
					if distance < bestDistance then
						bestX, bestZ, bestDistance = nx, nz, distance
					end
				end
			end
		end
	end
	return bestX, bestZ
end

-- T-48 (playtest): immediate press feedback. The ghost square pops to 90 % and eases back in 0.14 s, so the tap is seen at
-- once even before the server answers. One tween, no particles: cheap on 4 GB phones.
local function pressFeedback()
	local square = ghost
	if not square or square.Transparency >= 1 then
		return
	end
	local base = square:GetAttribute("BaseSize")
	if typeof(base) ~= "Vector3" then
		base = square.Size
		square:SetAttribute("BaseSize", base)
	end
	square.Size = base * 0.9
	TweenService:Create(square, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = base }):Play()
end

local function act(ray: Ray)
	local plot, cx, cz, point = pointerCell(ray)
	if not plot or not cx or not cz or not point then
		return
	end
	pressFeedback()
	showGhost(plot, cx, cz, point)
	if GarapController.MenuOpen then
		return -- the Pindah / Hapus menu is open: Garap waits, the ghost is hidden
	end
	-- A bed that is already here: a tap opens its Pindah / Hapus menu right away (no need to leave Garap and long-press).
	-- Not while a bed is being moved (then it is simply not a valid place).
	if movingUid == nil and cellState(plot, cx, cz) == "tile" then
		local part = bedPartAt(cx, cz)
		if part and GarapController.BedTapHandler then
			GarapController.BedTapHandler(part, if part:GetAttribute("Crop") == nil then "empty" else "grow")
		end
		return
	end
	if movingUid ~= nil then
		-- Pindah: a tap on a valid square places the bed. An invalid one does nothing (the gray arrow already said so).
		if moveState(plot, cx, cz) == "valid" then
			Net.Send("FarmMove", movingUid, cx, cz)
			GarapController.CancelMove() -- defined below (a table field, so it exists at call time)
		end
		return
	end
	-- B (playtest): snap. A tap on a square that is not valid (the edge of a grass patch, a fence, a square next to a bed)
	-- uses the nearest VALID square among the 8 around it, so the highlighted square is what you get.
	if mode == "till" and cellState(plot, cx, cz) ~= "valid" then
		local sx, sz = snapCell(plot, cx, cz, point)
		if sx and sz then
			cx, cz = sx, sz
			showGhost(plot, cx, cz, point)
		end
	end
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
	end
end

function refreshHint()
	if movingUid ~= nil then
		hintLabel.Text = Locale.t("garap.hint_move")
	elseif mode == "till" then
		-- Once there is a bed, say what comes next (a new player used to be stuck here: the hint never changed).
		-- T-04 TODO closed: the hint shows the price of the next bed (Bab 5.2: n x 150 after the first 6, Config/Farm).
		local tiles = farmInfo()
		local hint = Locale.t(if #tiles > 0 then "garap.hint_till_more" else "garap.hint_till")
		local nextCost = Farm.tileCost(#tiles + 1)
		local price = if nextCost <= 0 then Locale.t("garap.price_free") else Locale.t("garap.price", { n = Locale.formatNumber(nextCost) })
		hintLabel.Text = `{hint} · {Locale.t("garap.next_price", { price = price })}`
	else
		hintLabel.Text = Locale.t("garap.hint_pond", { price = pondPriceText() })
	end
end

function refreshKolamButton()
	if kolamButton then
		kolamButton.Visible = (State.current :: any) ~= nil and (State.current :: any).pondKakek == true
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

-- Grid over your own land: one thin white line per bed cell (Land.TILE), only on chunks you own. Built while Garap (or Pindah)
-- is on, removed when it ends, so the land is clean and cozy otherwise.
local function clearGrid()
	if gridFolder then
		gridFolder:Destroy()
		gridFolder = nil
	end
end

local function buildGrid()
	clearGrid()
	local plot = myPlot()
	local snapshot = State.current :: any
	if not plot or not plot.PrimaryPart or not snapshot then
		return
	end
	local origin = plot.PrimaryPart :: BasePart
	local folder = Instance.new("Folder")
	folder.Name = "GarapGrid"
	local y = origin.Size.Y / 2 + GRID_LIFT
	-- One grid for Garap AND decor: a thin line every 2 studs (Decor.CELL = the smallest decor), a thicker, stronger line
	-- every 8 studs (the bed square, Land.TILE). Garap snaps to the thick lines, decor snaps to every thin one.
	local function line(sizeX: number, sizeZ: number, x: number, z: number, thick: boolean)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = GRID_COLOR
		part.Transparency = if thick then GRID_THICK_TRANSPARENCY else GRID_TRANSPARENCY
		part.Size = Vector3.new(sizeX, 0.05, sizeZ)
		part.CFrame = origin.CFrame * CFrame.new(x, y, z)
		part.Parent = folder
	end
	for ix = Land.CHUNK_MIN, Land.CHUNK_MAX do
		for iz = Land.CHUNK_MIN, Land.CHUNK_MAX do
			if Land.isOwned(ix, iz, snapshot.landChunks) then
				local r = Land.chunkRect(ix, iz)
				local span = r.maxX - r.minX
				for k = 0, span // Decor.CELL do
					local x = r.minX + k * Decor.CELL
					local z = r.minZ + k * Decor.CELL
					local thick = x % Land.TILE == 0
					local thickZ = z % Land.TILE == 0
					line(if thick then GRID_THICK_WIDTH else GRID_WIDTH, span, x, (r.minZ + r.maxZ) / 2, thick)
					line(span, if thickZ then GRID_THICK_WIDTH else GRID_WIDTH, (r.minX + r.maxX) / 2, z, thickZ)
				end
			end
		end
	end
	folder.Parent = Workspace
	gridFolder = folder
end

-- The grid is ONE grid: it shows while Garap is on, and while another mode holds it (Hias asks with GarapController.HoldGrid).
local gridHolds = 0
local function refreshGrid()
	if GarapController.Active or gridHolds > 0 then
		buildGrid()
	else
		clearGrid()
	end
end

-- Hias (decor) opens: the same grid as Garap, not a second one. Pair every true with a false.
function GarapController.HoldGrid(on: boolean)
	gridHolds = math.max(0, gridHolds + (if on then 1 else -1))
	refreshGrid()
end

-- on = Garap mode with that tool; off = finished.
local function setActive(on: boolean, newMode: string?)
	GarapController.Active = on
	hintLabel.Visible = on and not hintHidden
	if not on then
		movingUid = nil
	end
	refreshGrid()
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
-- PINDAH: the bed itself moves. The original bed goes 50 % transparent (it is "lifted"); a translucent copy of the bed (soil
-- and its plant, with the same growth visual) follows the pointer on the grid. Green outline = the copy may be placed here
-- (all Leafy Grass, inside the land); red outline = not here (road, building, another bed). Taking the copy away restores
-- the original at full opacity. The plant's timer is not touched: only the cell changes on the server.

local function setMoveTransparency(part: BasePart, value: number)
	part.Transparency = value
	for _, d in part:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = value
		end
	end
end

local function clearMove()
	if movePart and movePart.Parent then
		setMoveTransparency(movePart, 0)
	end
	if movePreview then
		movePreview:Destroy()
		movePreview = nil
	end
	movePart = nil
	movingUid = nil
end

local function buildMovePreview(part: BasePart)
	local slab = part:Clone()
	-- a copy must not count as a bed: no tag, no owner / index, no tap targets
	CollectionService:RemoveTag(slab, TILE_TAG)
	slab:SetAttribute("Owner", nil)
	slab:SetAttribute("Index", nil)
	for _, d in slab:GetDescendants() do
		if d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Transparency = 0.5
		end
	end
	slab.Anchored = true
	slab.CanCollide = false
	slab.CanQuery = false
	slab.CanTouch = false
	slab.Transparency = 0.5
	local model = Instance.new("Model")
	model.Name = "MovePreview"
	slab.Parent = model
	model.PrimaryPart = slab
	local outline = Instance.new("Highlight")
	outline.Name = "MoveOutline"
	outline.FillTransparency = 1 -- outline only: the copy stays see-through
	outline.OutlineTransparency = 0.1
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Adornee = model
	outline.Parent = model
	moveOutline = outline
	model.Parent = Workspace
	movePreview = model
end

-- Pindah: the bed (its uid) moves. The move ends on a valid tap, or when Garap / the menu closes it.
function GarapController.StartMove(uid: number)
	clearMove()
	movingUid = uid
	for _, part in CollectionService:GetTagged(TILE_TAG) do
		if part:IsA("BasePart") and part:GetAttribute("Owner") == player.UserId and part:GetAttribute("Index") == uid then
			movePart = part
			moveSource = { cx = part:GetAttribute("Cx") or 0, cz = part:GetAttribute("Cz") or 0 }
			setMoveTransparency(part, 0.5) -- the original is "lifted"
			buildMovePreview(part)
			break
		end
	end
	if not GarapController.Active then
		setActive(true, "till")
	end
	refreshHint()
end

function GarapController.CancelMove()
	if movingUid == nil then
		return
	end
	clearMove()
	hideGhost()
	refreshHint()
end

-- Hides the Garap hint line while the tutorial's coachmark is on (one instruction at a time).
function GarapController.SetHintHidden(on: boolean)
	hintHidden = on
	hintLabel.Visible = GarapController.Active and not on
end

-- Closes Garap mode (the tutorial does this once tilling is over: the bed pills stay hidden while Garap is open).
function GarapController.Stop()
	if GarapController.Active then
		setActive(false)
	end
end

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
	hintLabel.Position = UDim2.new(0.5, 0, 0.12, 0) -- top of the screen, not the middle
	hintLabel.Size = UDim2.new(0.4, 0, 0, 36) -- at most 40 % of the width
	hintLabel.TextColor3 = UiKit.CREAM
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.TextSize = 14
	hintLabel.TextWrapped = true
	hintLabel.Visible = false
	hintLabel.Parent = gui
	darkBox(hintLabel)

	kolamButton = UiKit.menuItem(hud :: Instance, "KolamButton", Locale.t("garap.tool_pond"), 2) :: GuiButton
	-- v7.4 Bab 16.5: the pond left Tutorial 1. The dock button only appears once MQ4 / Bundel Kakek opened the pond
	-- (pond.kakekUnlocked), so no tutorial step can point at it and a new player never sees a button he cannot use.
	refreshKolamButton()
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
		refreshKolamButton()
		if GarapController.Active then
			buildGrid() -- the land may have grown (a new block bought): the grid follows what you own
			refreshHint() -- the price of the next pond changes with every pond built
		end
	end)

	-- Phones: the ghost follows the finger (touch positions are viewport pixels).
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			pointer = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	UserInputService.TouchStarted:Connect(function(touch)
		pointer = Vector2.new(touch.Position.X, touch.Position.Y)
	end)

	-- Desktop: click. Mobile: tap in the world.
	UserInputService.InputBegan:Connect(function(input, processed)
		if not GarapController.Active or processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local camera = Workspace.CurrentCamera
		act(camera:ScreenPointToRay(input.Position.X, input.Position.Y))
	end)
	-- B (playtest): a tap is a touch that starts and ends close together (within TAP_SLOP px, under TAP_MAX_SECONDS), and that
	-- did not start on a UI button. TouchTapInWorld was dropped for slightly moving or slower taps, the cause of several tries.
	local TAP_SLOP, TAP_MAX_SECONDS = 18, 0.45
	local touchStart: { pos: Vector2, at: number }? = nil
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch and not processed then
			touchStart = { pos = Vector2.new(input.Position.X, input.Position.Y), at = os.clock() }
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch or not touchStart then
			return
		end
		local start = touchStart
		touchStart = nil
		local here = Vector2.new(input.Position.X, input.Position.Y)
		if GarapController.Active and (here - start.pos).Magnitude <= TAP_SLOP and os.clock() - start.at <= TAP_MAX_SECONDS then
			local camera = Workspace.CurrentCamera
			act(camera:ViewportPointToRay(here.X, here.Y))
		end
	end)

	-- The ghost and its arrow follow the pointer every frame (desktop: mouse hover; phones: the last touch).
	RunService.RenderStepped:Connect(function()
		if GarapController.MenuOpen then
			hideGhost() -- Garap is paused while the Pindah / Hapus menu is open
			setBedHover(nil)
			return
		end
		if not GarapController.Active then
			return
		end
		local camera = Workspace.CurrentCamera
		local ray: Ray? = nil
		if UserInputService.TouchEnabled and pointer then
			ray = camera:ViewportPointToRay(pointer.X, pointer.Y)
		elseif UserInputService.MouseEnabled then
			local mouse = UserInputService:GetMouseLocation()
			ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
		end
		if ray then
			local plot, cx, cz, point = pointerCell(ray)
			showGhost(plot, cx, cz, point)
		end
	end)
end

return GarapController
