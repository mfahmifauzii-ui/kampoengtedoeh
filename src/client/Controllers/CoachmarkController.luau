--!strict
-- Coachmark: the one thing to do during a tutorial step. Visual + input only. GuideController decides WHAT to show
-- (Show / Hide); this controller draws it. ONE highlight per step, always the shape of its target.
--
-- Shared look (every step): a 60 % black overlay (transparency 0.4) built from four dark frames that meet with a 1 px overlap,
-- so there is no seam. The info bubble sits above the target with an arrow down (below it if there is no room above).
-- There is no skip button in the tutorial (no Lewati): the tutorial is part of the game.
--
-- Modes (GuideController picks one per step):
--   * "button": the overlay covers the whole screen except a HOLE around a named button (GarapButton, TanamButton,
--     SiramButton, PanenButton). The highlight follows the button: a round one for round docks buttons, a rounded box
--     (padding 8 px) for pills. The button itself shows through the hole.
--   * "ground": the 3D world is NOT darkened. Only the UI zones (top bar, dock, right menu column, player card) are dimmed
--     and blocked, so the land stays clear and the player can pick a grid square. No ring here: the Garap ghost and its
--     green arrow (GarapController) are the target.
--   * "npc": no overlay. A small arrow floats slowly above an NPC's head ("walk there"), different from the Garap arrow,
--     which bobs DOWN above a ghost ("tap here"). Used for Panen / Jual (Pak Darmo is outside any hole).
--
-- Camera (T1 spawn only): on a new player's spawn (server sets the GateSpawn attribute) the camera is placed behind the
-- character, looking at the gate, once. Then the normal camera comes back at once; nothing is locked during T1.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local UiAssets = require(ReplicatedStorage.Shared.Config.UiAssets)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local CoachmarkController = {}

export type Spec = {
	mode: string, -- "button" | "ground" | "npc"
	text: string?, -- the bubble text (Locale key already resolved); nil = no bubble
	block: boolean, -- button / ground: true = dark zones that block taps; false = no overlay
	findButton: (() -> GuiObject?)?, -- button mode
	npcPoint: (() -> Vector3?)?, -- npc mode: world point above the NPC's head
}

local PAD = 8 -- px around a button inside the hole
local OVERLAY_TRANSPARENCY = 0.4 -- 60 % black, the same on every step
local GOLD = Color3.fromRGB(255, 226, 120)
local TOP_BAR = 70 -- px: the top band of the screen (room for the stat chips and the hint)
local DOCK_BAND = 96 -- px: the bottom band (dock + player card)
local RIGHT_COLUMN = 84 -- px: the menu column on the right
local CARD_WIDTH = 300 -- px: the player card at the bottom left

local overlayGui: ScreenGui
local topGui: ScreenGui
local pieces: { Frame } = {}
local corners: { ImageLabel } = {} -- rounded hole: one dark corner per hole corner (UiAssets.COACH_CORNER), empty = square hole
local hudPool: { Frame } = {} -- ground mode: one dark blocking frame per visible HUD panel
local highlight: Frame
local highlightStroke: UIStroke
local highlightRound: UICorner
local bubble: Frame
local bubbleText: TextLabel
local arrow: TextLabel
local npcArrow: TextLabel
local current: Spec? = nil

local function frame(name: string, parent: Instance): Frame
	local piece = Instance.new("Frame")
	piece.Name = name
	piece.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	piece.BackgroundTransparency = OVERLAY_TRANSPARENCY
	piece.BorderSizePixel = 0
	piece.Active = true -- swallows every tap on it
	piece.Parent = parent
	return piece
end

local function place(piece: Frame, x: number, y: number, w: number, h: number)
	piece.Position = UDim2.fromOffset(x, y)
	piece.Size = UDim2.fromOffset(math.max(0, w), math.max(0, h))
end

function CoachmarkController.Init()
	-- Under the HUD (20) and above panels and the world: the HUD buttons outside the hole are dimmed and blocked.
	overlayGui = Instance.new("ScreenGui")
	overlayGui.Name = "CoachOverlay"
	overlayGui.ResetOnSpawn = false
	overlayGui.IgnoreGuiInset = true
	overlayGui.DisplayOrder = 25
	overlayGui:SetAttribute("NoScale", true) -- real pixels: the hole must line up with AbsolutePosition (UiKit.autoScale skips this)
	overlayGui.Enabled = false
	overlayGui.Parent = player:WaitForChild("PlayerGui")
	pieces = {}
	for _, name in { "Top", "Bottom", "Left", "Right" } do
		table.insert(pieces, frame(name, overlayGui))
	end
	-- Rounded hole corners: four copies of the same corner picture, turned to each corner. Only when the picture is uploaded.
	if UiAssets.COACH_CORNER.image ~= "" then
		for _, rotation in { 0, 90, 180, 270 } do
			local piece = Instance.new("ImageLabel")
			piece.Name = `HoleCorner{rotation}`
			piece.BackgroundTransparency = 1
			piece.BorderSizePixel = 0
			piece.Image = UiAssets.COACH_CORNER.image
			piece.ImageColor3 = Color3.fromRGB(0, 0, 0)
			piece.ImageTransparency = OVERLAY_TRANSPARENCY
			piece.Rotation = rotation
			piece.Active = true -- swallows taps like the dark pieces
			piece.Visible = false
			piece.Parent = overlayGui
			table.insert(corners, piece)
		end
	end

	-- Above the HUD and the overlay: the highlight, the bubble and the NPC arrow.
	topGui = Instance.new("ScreenGui")
	topGui.Name = "CoachTop"
	topGui.ResetOnSpawn = false
	topGui.IgnoreGuiInset = true
	topGui.DisplayOrder = 60
	topGui:SetAttribute("NoScale", true)
	topGui.Enabled = false
	topGui.Parent = player:WaitForChild("PlayerGui")

	highlight = Instance.new("Frame")
	highlight.Name = "Highlight"
	highlight.AnchorPoint = Vector2.new(0.5, 0.5)
	highlight.BackgroundTransparency = 1
	highlight.Active = false -- never takes a tap
	highlight.Visible = false
	highlight.Parent = topGui
	highlightRound = Instance.new("UICorner")
	highlightRound.CornerRadius = UDim.new(0.5, 0)
	highlightRound.Parent = highlight
	highlightStroke = Instance.new("UIStroke")
	highlightStroke.Color = GOLD
	highlightStroke.Thickness = 4
	highlightStroke.Parent = highlight

	bubble = Instance.new("Frame")
	bubble.Name = "Bubble"
	bubble.AutomaticSize = Enum.AutomaticSize.X
	bubble.Size = UDim2.fromOffset(0, 40)
	bubble.BackgroundColor3 = Color3.fromRGB(48, 32, 20)
	bubble.Active = false
	bubble.Visible = false
	bubble.Parent = topGui
	local bubbleRound = Instance.new("UICorner")
	bubbleRound.CornerRadius = UDim.new(0, 12)
	bubbleRound.Parent = bubble
	local bubbleEdge = Instance.new("UIStroke")
	bubbleEdge.Color = GOLD
	bubbleEdge.Thickness = 2
	bubbleEdge.Parent = bubble
	local bubblePad = Instance.new("UIPadding")
	bubblePad.PaddingLeft, bubblePad.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
	bubblePad.Parent = bubble

	bubbleText = Instance.new("TextLabel")
	bubbleText.Name = "Text"
	bubbleText.AutomaticSize = Enum.AutomaticSize.X
	bubbleText.Size = UDim2.fromScale(0, 1)
	bubbleText.BackgroundTransparency = 1
	bubbleText.TextColor3 = UiKit.CREAM
	bubbleText.Font = UiKit.FONT
	bubbleText.TextSize = 16
	bubbleText.Parent = bubble

	arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(0.5, 0)
	arrow.Size = UDim2.fromOffset(30, 16)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▼"
	arrow.TextColor3 = GOLD
	arrow.Font = UiKit.FONT
	arrow.TextSize = 18
	arrow.Parent = bubble

	-- The NPC arrow: it floats up and down slowly (walk there), unlike the Garap arrow which bobs down onto a ghost.
	npcArrow = Instance.new("TextLabel")
	npcArrow.Name = "NpcArrow"
	npcArrow.AnchorPoint = Vector2.new(0.5, 1)
	npcArrow.Size = UDim2.fromOffset(40, 34)
	npcArrow.BackgroundTransparency = 1
	npcArrow.Text = "▼"
	npcArrow.TextColor3 = GOLD
	npcArrow.Font = UiKit.FONT
	npcArrow.TextSize = 30
	npcArrow.Visible = false
	npcArrow.Active = false
	npcArrow.Parent = topGui

	RunService.RenderStepped:Connect(CoachmarkController.Update)
end

function CoachmarkController.Show(spec: Spec)
	current = spec
	bubbleText.Text = spec.text or ""
	bubble.Visible = spec.text ~= nil
	topGui.Enabled = true
end

function CoachmarkController.Hide()
	current = nil
	if overlayGui then
		overlayGui.Enabled = false
	end
	if topGui then
		topGui.Enabled = false
	end
end

-- A panel or modal is open (the seed picker, Atur, a confirm): the coachmark steps aside (no overlay, no highlight, no bubble).
-- It comes back by itself when the panel closes.
local paused = false
function CoachmarkController.SetPaused(on: boolean)
	paused = on
end

function CoachmarkController.IsShowing(): boolean
	return current ~= nil
end

-- The button's rectangle in rendered pixels. AbsolutePosition leaves out the top bar inset (IgnoreGuiInset = true), but a
-- frame's Position is drawn from the very top: the inset is added so the hole lines up with the button on screen.
local function buttonRect(button: GuiObject): (Vector2, Vector2)
	local inset = GuiService:GetGuiInset().Y
	return button.AbsolutePosition + Vector2.new(0, inset), button.AbsoluteSize
end

-- Button mode: the four dark zones around the hole.
local function layoutHole(position: Vector2, size: Vector2, view: Vector2, radius: number)
	local left, top = position.X - PAD, position.Y - PAD
	local width, height = size.X + PAD * 2, size.Y + PAD * 2
	local right, bottom = left + width, top + height
	-- The four pieces TOUCH but never overlap (whole pixels): two dark frames on top of each other would show a darker line.
	for _, piece in pieces do
		piece.Visible = true
	end
	for _, piece in hudPool do
		piece.Visible = false
	end
	local l, t, r, b = math.floor(left), math.floor(top), math.ceil(right), math.ceil(bottom)
	place(pieces[1], 0, 0, view.X, t) -- top: 0 .. t
	place(pieces[2], 0, b, view.X, view.Y - b) -- bottom: b .. screen bottom
	place(pieces[3], 0, t, l, b - t) -- left: t .. b
	place(pieces[4], r, t, view.X - r, b - t) -- right: t .. b
	-- Rounded corners: each corner piece covers the square corner of the hole outside its arc (radius, at most half the hole).
	if #corners > 0 then
		local rad = math.floor(math.min(radius, (r - l) / 2, (b - t) / 2))
		local spots = { { l, t }, { r - rad, t }, { r - rad, b - rad }, { l, b - rad } } -- top-left, top-right, bottom-right, bottom-left
		for i, piece in corners do
			piece.Visible = rad > 0
			piece.Position = UDim2.fromOffset(spots[i][1], spots[i][2])
			piece.Size = UDim2.fromOffset(rad, rad)
		end
	end
	highlight.Position = UDim2.fromOffset(left + width / 2, top + height / 2)
	highlight.Size = UDim2.fromOffset(width, height)
end

-- Ground mode: the UI itself only. One dark, blocking frame per visible HUD panel (stat chips, menu column, dock, player
-- card), padded by 4 px. Everything else (the land, the sky, the road) stays bright.
local function layoutHudZones(view: Vector2)
	for _, piece in pieces do
		piece.Visible = false
	end
	for _, piece in corners do
		piece.Visible = false
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = if playerGui then playerGui:FindFirstChild("HUD") else nil
	local rects: { { x: number, y: number, w: number, h: number } } = {}
	if hud then
		local inset = GuiService:GetGuiInset().Y
		for _, child in hud:GetChildren() do
			if child:IsA("GuiObject") and child.Visible and child.AbsoluteSize.X > 0 then
				-- skip a full-screen container: it would dim the land too
				if child.AbsoluteSize.X < view.X * 0.95 or child.AbsoluteSize.Y < view.Y * 0.95 then
					table.insert(rects, {
						x = child.AbsolutePosition.X,
						y = child.AbsolutePosition.Y + inset,
						w = child.AbsoluteSize.X,
						h = child.AbsoluteSize.Y,
					})
				end
			end
		end
	end
	for index, rect in rects do
		local piece = hudPool[index]
		if not piece then
			piece = frame("Hud" .. index, overlayGui)
			hudPool[index] = piece
		end
		piece.Visible = true
		place(piece, rect.x - 4, rect.y - 4, rect.w + 8, rect.h + 8)
	end
	for index = #rects + 1, #hudPool do
		hudPool[index].Visible = false
	end
end

function CoachmarkController.Update()
	local spec = current
	if not spec then
		return
	end
	local camera = Workspace.CurrentCamera :: Camera
	local view = camera.ViewportSize
	local t = os.clock()

	if paused then
		overlayGui.Enabled = false
		highlight.Visible = false
		bubble.Visible = false
		arrow.Visible = false
		npcArrow.Visible = false
		return
	end
	bubble.Visible = spec.text ~= nil

	-- Overlay: only when the step blocks.
	overlayGui.Enabled = spec.block
	highlight.Visible = false
	bubble.AnchorPoint = Vector2.new(0.5, 0)
	bubble.Position = UDim2.fromOffset(view.X / 2, 70)
	arrow.Visible = false
	npcArrow.Visible = false

	if spec.mode == "button" then
		local button = if spec.findButton then spec.findButton() else nil
		if not button or button.AbsoluteSize.X <= 0 then
			-- The target is not on screen (panel closed, bed off screen): no hole, no block, bubble at the top middle.
			overlayGui.Enabled = false
		else
			local position, size = buttonRect(button)
			-- One highlight in the target's own shape: round for round buttons, a rounded box otherwise.
			local corner = button:FindFirstChildOfClass("UICorner")
			local round = corner ~= nil and corner.CornerRadius.Scale >= 0.5
			if spec.block then
				-- The hole has the same corners as the button: a full round hole for round buttons, 12 px otherwise (as the highlight).
				local holeRadius = if round then math.min(size.X, size.Y) / 2 + PAD else 12
				layoutHole(position, size, view, holeRadius)
			end
			local width, height = size.X + PAD * 2, size.Y + PAD * 2
			highlight.Visible = true
			highlight.Size = UDim2.fromOffset(width, height)
			highlight.Position = UDim2.fromOffset(position.X + size.X / 2, position.Y + size.Y / 2)
			highlightRound.CornerRadius = if round then UDim.new(0.5, 0) else UDim.new(0, 12)
			highlightStroke.Thickness = 4 + (math.sin(t * 4) + 1) * 1.5
			highlightStroke.Transparency = 0.1 + (math.sin(t * 4) + 1) * 0.15

			-- Bubble above with the arrow down; below with the arrow up when there is no room.
			local center = Vector2.new(position.X + size.X / 2, position.Y + size.Y / 2)
			local top = position.Y - PAD
			local bottom = position.Y + size.Y + PAD
			arrow.Visible = spec.text ~= nil
			if top > 120 then
				bubble.AnchorPoint = Vector2.new(0.5, 1)
				bubble.Position = UDim2.fromOffset(center.X, top - 10)
				arrow.AnchorPoint = Vector2.new(0.5, 0)
				arrow.Position = UDim2.new(0.5, 0, 1, -2)
				arrow.Text = "▼"
			else
				bubble.AnchorPoint = Vector2.new(0.5, 0)
				bubble.Position = UDim2.fromOffset(center.X, bottom + 10)
				arrow.AnchorPoint = Vector2.new(0.5, 1)
				arrow.Position = UDim2.new(0.5, 0, 0, 2)
				arrow.Text = "▲"
			end
		end
	elseif spec.mode == "ground" then
		if spec.block then
			layoutHudZones(view)
		end
		-- No highlight: the ghost is the target. The bubble sits at the top middle, above the top bar.
		bubble.AnchorPoint = Vector2.new(0.5, 0)
		bubble.Position = UDim2.fromOffset(view.X / 2, TOP_BAR + 10)
	end
	-- The NPC arrow (walk there) can come with any mode: it floats above the NPC's head.
	if spec.npcPoint then
		local point = spec.npcPoint()
		if point then
			local screen, onScreen = camera:WorldToViewportPoint(point)
			local float = math.sin(t * 2) * 4 -- slow float: 4 px up and down
			if onScreen then
				npcArrow.Visible = true
				npcArrow.Text = "▼"
				npcArrow.Position = UDim2.fromOffset(screen.X, screen.Y - 30 + float)
			else
				-- Off screen: pin the arrow to the edge on the NPC's side, pointing that way.
				local margin = 44
				local x = math.clamp(screen.X, margin, view.X - margin)
				local y = math.clamp(screen.Y, TOP_BAR + margin, view.Y - DOCK_BAND - margin)
				npcArrow.Visible = true
				npcArrow.Text = if screen.X < view.X / 2 then "◀" else "▶"
				npcArrow.Position = UDim2.fromOffset(x, y + float)
			end
		end
	end
	for _, piece in pieces do
		piece.BackgroundTransparency = OVERLAY_TRANSPARENCY -- one darkness on every step
	end
end

-- Camera for a new player's first spawn: behind the character, a little above, looking at the gate. Set once, then the
-- normal camera comes back (nothing is locked during T1).
local function gateCamera(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not root then
		return
	end
	task.wait(0.9) -- the server moves the character to the gate first (after its own HumanoidRootPart wait)
	local camera = Workspace.CurrentCamera :: Camera
	local forward = root.CFrame.LookVector
	local base = root.Position
	local eye = base - forward * 11 + Vector3.new(0, 5.5, 0)
	local look = base + forward * 4 + Vector3.new(0, 1.5, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(eye, look)
	task.wait(1.2)
	camera.CameraType = Enum.CameraType.Custom
end

function CoachmarkController.Start()
	local function onCharacter(character: Model)
		task.spawn(function()
			-- Every spawn (respawn, rejoin, first join): the camera goes behind the character, looking into the land.
			gateCamera(character)
		end)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

return CoachmarkController
