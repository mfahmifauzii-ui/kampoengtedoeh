--!strict
-- Coachmark: the one thing to do during a tutorial step. Visual only (it never takes a tap). GuideController decides WHAT
-- to show (Show / Hide) and whether the step gets a spotlight; this controller draws it.
--
-- Rule 1 of the locked tutorial GUI rules (2026-11-23 owner batch; GUI 4.6, GDD 16.6): two highlight styles, chosen by the
-- target type, FIRST TIME ONLY.
--   a) spotlight = a fixed HUD button (GarapButton on the dock, AksiButton for Pancing): ONE dark overlay with a single hole
--      around the button. Only when Spec.spotlight is true.
--   b) outline = a floating / world-anchored target (the Tanam / Siram / Panen pills over the beds, the ghost in Garap,
--      an NPC): NO dim. The yellow ring on the pill (mode "button") or the arrow only.
-- Rule 3: the dark overlay is made of pieces that never take a tap (Active = false), so the joystick and the camera stay
-- free. It releases by itself when the step changes, when the step completes, or after SPOTLIGHT_TIMEOUT seconds.
--
-- Shared look: the spotlight is a 60 % black overlay (transparency 0.4) built from four frames that meet with a 1 px overlap,
-- so there is no seam. The info bubble sits above the target with an arrow down (below it if there is no room above).
-- There is no skip button in the tutorial (no Lewati): the tutorial is part of the game.
--
-- Modes (GuideController picks one per step):
--   * "button": the target is a named button (GarapButton, TanamButton, SiramButton, PanenButton, AksiButton). The highlight
--     ring follows the button: a round one for round buttons, a rounded box (padding 8 px) for pills. When Spec.spotlight is
--     true the overlay also gets a hole around the button (rule 1a); otherwise there is only the ring (rule 1b).
--   * "ground": no overlay, no ring. The Garap ghost and its green arrow (GarapController) are the target; the land stays bright.
--   * "npc": no overlay. A small arrow floats slowly above an NPC's head ("walk there"), different from the Garap arrow,
--     which bobs DOWN above a ghost ("tap here"). Used for Panen / Jual (Pak Udin is outside any hole).
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
local HudController = require(script.Parent.HudController)

local player = Players.LocalPlayer

local CoachmarkController = {}

export type Spec = {
	mode: string, -- "button" | "ground" | "npc"
	key: string?, -- the step id: a new key restarts the spotlight timer
	text: string?, -- the bubble text (Locale key already resolved); nil = no bubble
	spotlight: boolean, -- button mode only: true = dark overlay with one hole around the button (rule 1a); false = ring only
	findButton: (() -> GuiObject?)?, -- button mode
	npcPoint: (() -> Vector3?)?, -- npc mode: world point above the NPC's head
}

local PAD = 8 -- px around a button inside the hole
local OVERLAY_TRANSPARENCY = 0.4 -- 60 % black, the same on every step
local SPOTLIGHT_TIMEOUT = 25 -- s: the spotlight releases by itself on the same step (rule 3); the bubble and the ring stay
local GOLD = Color3.fromRGB(255, 226, 120)
local TOP_BAR = 70 -- px: the top band of the screen (room for the stat chips and the hint)
local DOCK_BAND = 96 -- px: the bottom band (dock + player card)

local overlayGui: ScreenGui
local topGui: ScreenGui
local pieces: { Frame } = {}
local corners: { ImageLabel } = {} -- rounded hole: one dark corner per hole corner (UiAssets.COACH_CORNER), empty = square hole
local highlight: Frame
local highlightStroke: UIStroke
local highlightRound: UICorner
local bubble: Frame
local arrow: TextLabel
local npcArrow: TextLabel
local current: Spec? = nil
local FADE_IN = 0.4 -- seconds for the darkness to fade in when a coachmark appears
local fadeInFrom = 0 -- os.clock() when the current coachmark appeared
local shownKey: string? = nil -- the step the spotlight timer belongs to
local shownSince = 0 -- os.clock() when that step's coachmark first appeared

local function frame(name: string, parent: Instance): Frame
	local piece = Instance.new("Frame")
	piece.Name = name
	piece.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	piece.BackgroundTransparency = OVERLAY_TRANSPARENCY
	piece.BorderSizePixel = 0
	piece.Active = false -- visual only: the joystick, the camera and every tap pass through the dark (rule 3)
	piece.Visible = false
	piece.Parent = parent
	return piece
end

local function place(piece: Frame, x: number, y: number, w: number, h: number)
	piece.Position = UDim2.fromOffset(x, y)
	piece.Size = UDim2.fromOffset(math.max(0, w), math.max(0, h))
end

function CoachmarkController.Init()
	-- Under the HUD (20) and above panels and the world: the HUD buttons outside the spotlight hole are dimmed (not blocked).
	overlayGui = Instance.new("ScreenGui")
	overlayGui.Name = "CoachOverlay"
	overlayGui.ResetOnSpawn = false
	overlayGui.IgnoreGuiInset = true
	overlayGui.DisplayOrder = UiKit.LAYER.COACH
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
			piece.Active = false -- visual only: the hitbox is a full square and would eat taps inside the hole
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
	topGui.DisplayOrder = UiKit.LAYER.TOAST
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
	bubble.Size = UDim2.fromOffset(30, 16)
	bubble.BackgroundTransparency = 1 -- GUI 4.2: no brown pill; the arrow stays, the step text is in the toast stack
	bubble.Active = false
	bubble.Visible = false
	bubble.Parent = topGui


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
	if spec.text then
		HudController.SetPinned("coach", spec.text)
	else
		HudController.ClearPinned("coach")
	end
	bubble.Visible = spec.text ~= nil
	if not topGui.Enabled then
		fadeInFrom = os.clock() -- a coachmark that was hidden fades in, it does not pop in
	end
	if not topGui.Enabled or spec.key ~= shownKey then
		shownKey = spec.key
		shownSince = os.clock() -- the spotlight timer restarts on every new step
	end
	topGui.Enabled = true
end

function CoachmarkController.Hide()
	current = nil
	HudController.ClearPinned("coach")
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

-- The corner radius in pixels of a button's shape: the first UICorner on the button or on one of its parts (GarapButton's
-- bamboo ring has an offset corner, other buttons use a scale). Capped at half the smaller side. nil = no corner.
local function cornerRadiusPx(button: GuiObject, size: Vector2): number?
	for _, shape in button:GetDescendants() do
		if shape:IsA("UICorner") and shape.Parent and shape.Parent:IsA("GuiObject") then
			local frame = shape.Parent :: GuiObject
			local side = math.min(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
			local radius = shape.CornerRadius.Scale * side + shape.CornerRadius.Offset
			if radius > 0 then
				return math.min(radius, math.min(size.X, size.Y) / 2)
			end
		end
	end
	return nil
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

function CoachmarkController.Update()
	local spec = current
	if not spec then
		return
	end
	local camera = Workspace.CurrentCamera :: Camera
	local view = camera.ViewportSize
	local t = os.clock()

	-- While the fishing UI is on (Plan 3.6), the coachmark steps aside like a panel does.
	if paused or player:GetAttribute("FishingActive") == true then
		overlayGui.Enabled = false
		highlight.Visible = false
		bubble.Visible = false
		arrow.Visible = false
		npcArrow.Visible = false
		return
	end
	bubble.Visible = spec.text ~= nil

	-- Rule 1a/1b and rule 3 (GUI 4.6): the spotlight (dark + one hole) only for a fixed HUD button, only for the first time,
	-- and only until SPOTLIGHT_TIMEOUT. Everything else draws the ring, the arrow and the bubble with no dark at all.
	local spotlightOn = spec.spotlight and spec.mode == "button" and (t - shownSince) < SPOTLIGHT_TIMEOUT
	overlayGui.Enabled = false
	highlight.Visible = false
	bubble.AnchorPoint = Vector2.new(0.5, 0)
	bubble.Position = UDim2.fromOffset(view.X / 2, 70)
	arrow.Visible = false
	npcArrow.Visible = false

	if spec.mode == "button" then
		local button = if spec.findButton then spec.findButton() else nil
		if not button or button.AbsoluteSize.X <= 0 then
			-- The target is not on screen (panel closed, bed off screen): no hole, bubble at the top middle.
			overlayGui.Enabled = false
		else
			local position, size = buttonRect(button)
			-- One highlight in the target's own shape: round for round buttons, a rounded box otherwise.
			-- The button's own corner radius in pixels (see cornerRadiusPx). The hole and the highlight take that radius plus the
			-- PAD around the button, so the hole has the same corners as the button; 12 px when the button has no corner.
			local shapeRadius = cornerRadiusPx(button, size)
			if spotlightOn then
				overlayGui.Enabled = true
				layoutHole(position, size, view, if shapeRadius then shapeRadius + PAD else 12)
			end
			local width, height = size.X + PAD * 2, size.Y + PAD * 2
			highlight.Visible = true
			highlight.Size = UDim2.fromOffset(width, height)
			highlight.Position = UDim2.fromOffset(position.X + size.X / 2, position.Y + size.Y / 2)
			highlightRound.CornerRadius = UDim.new(0, if shapeRadius then shapeRadius + PAD else 12)
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
		-- No overlay and no highlight: the ghost is the target. The bubble sits at the top middle, above the top bar.
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
	-- The darkness fades in over FADE_IN seconds after the coachmark appears (no sudden pop-in after the fade to black).
	local alpha = math.clamp((os.clock() - fadeInFrom) / FADE_IN, 0, 1)
	for _, piece in pieces do
		piece.BackgroundTransparency = 1 - (1 - OVERLAY_TRANSPARENCY) * alpha
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
