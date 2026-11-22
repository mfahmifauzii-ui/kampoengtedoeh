--!strict
-- The ONE dialog box of the T1 intro and tutorial (screen space, bottom of the screen). Bamboo frame (UiAssets.PANEL, the
-- same 9-slice as every panel), the speaker's face on the left (a ViewportFrame with a copy of the NPC), the name above the
-- text, and a Next button at the bottom right. With showNext the player MUST press Next (nothing advances by itself).
-- Client only. T1Ghost.client drives it; nothing else draws tutorial text.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UiAssets = require(ReplicatedStorage.Shared.Config.UiAssets)

local T1Dialog = {}

export type Choice = { text: string, onChoose: () -> () }

export type Options = {
	name: string, -- "Mak Sari"
	text: string,
	avatar: Model?, -- the NPC to draw as the face (a copy is rendered; the model itself is never touched)
	showNext: boolean, -- true: the Next button shows and onNext fires when pressed
	bottom: number?, -- px from the bottom of the screen (above the cinematic bar, or above the dock)
	onNext: (() -> ())?,
	choices: { Choice }?, -- numbered choices in a row at the bottom of the box (instead of Next); 1-4 / gamepad A X Y B pick one
	variant: string?, -- "instruction" (tutorial / quest step line, GUI doc 5.1) or nil = "conversation" (NPC talk, Next / choices)
}

-- GUI doc 5.1: two variants of ONE component. Text sizes are UiKit token names (uiKit[...] at runtime); the numbers
-- here are layout in px. Instruction = a tutorial / quest step line (1-2 lines); conversation = an NPC talk (up to 3 lines).
type Metrics = {
	avatar: number, -- face (ViewportFrame) diameter
	ring: number, -- bamboo ring behind the face
	nameSize: string, -- UiKit token
	nameTop: number,
	nameH: number,
	textTop: number, -- text starts below the name
	textSize: string, -- UiKit token
	widthShare: number, -- box width as a share of the screen width
	maxWidth: number, -- box width cap, px
	minH: number,
	maxH: number,
	nextW: number,
	nextH: number,
	choiceH: number,
	bottomPad: number,
}

local METRICS: { [string]: Metrics } = {
	conversation = {
		avatar = 40, ring = 48, nameSize = "TEXT_SMALL", nameTop = 12, nameH = 18,
		textTop = 32, textSize = "TEXT_SMALL", widthShare = 0.6, maxWidth = 440,
		minH = 64, maxH = 96, nextW = 64, nextH = 32, choiceH = 32, bottomPad = 12,
	},
	instruction = {
		avatar = 32, ring = 40, nameSize = "TEXT_CAPTION", nameTop = 8, nameH = 16,
		textTop = 24, textSize = "TEXT_SMALL", widthShare = 0.55, maxWidth = 400,
		minH = 48, maxH = 72, nextW = 64, nextH = 32, choiceH = 32, bottomPad = 10,
	},
}

local player = Players.LocalPlayer
local ringImage: ImageLabel? = nil -- the bamboo ring behind the face (resized per variant)

local gui: ScreenGui? = nil
local box: CanvasGroup? = nil -- a CanvasGroup: the minimize / restore fades the whole box with GroupTransparency
local boxScale: UIScale? = nil -- the box's scale (minimize / restore, Owner rule: GUI doc Bab 5.1)
local boxLimit: UISizeConstraint? = nil -- caps the box size; raised for a dialog with choices (the box grows to fit its text)
local nameLabel: TextLabel? = nil
local textLabel: TextLabel? = nil
local nextButton: TextButton? = nil
local viewport: ViewportFrame? = nil
local viewportCamera: Camera? = nil
local avatarModel: Model? = nil -- the NPC currently drawn (the source, to skip a rebuild)
local avatarWell: Frame? = nil -- the round face frame (see ensure)
local avatarPhoto: ImageLabel? = nil -- the 2D portrait when the NPC has one (UiAssets.PORTRAIT_IMAGES)
local dialogWanted = false -- the box is meant to be on screen (Show until Hide); it is hidden only while fishing (Plan 3.6)

-- Speech turns (Playtest 7, item 3): ONE box, ONE line at a time, for every NPC. A line takes its turn with Acquire and gives
-- it back with the release function it returns, or simply by Hide (Next, a choice, the close of a talk). Tutorial beats
-- (BEAT) go ahead of ambient lines (AMBIENT, e.g. an NPC talk opened by a prompt); within one rank the order is first come.
-- A new line never replaces the one on screen: it waits its turn. Right after a beat, ambient lines wait a moment more, so
-- the next line of the same beat is not overtaken.
T1Dialog.BEAT = 1
T1Dialog.AMBIENT = 2
local BEAT_GRACE = 1.5 -- seconds after a beat line before an ambient line may take the box
type Turn = { id: number, npc: string, rank: number }
local turns: { Turn } = {}
local turnCounter = 0
local ownerId: number? = nil -- the turn whose line is on the box now
local ownerRank = 0
local lastBeatEnd = -math.huge
local nextHandler: (() -> ())? = nil
local choicesRow: Frame? = nil
local choiceButtons: { TextButton } = {}
local activeChoices: { Choice }? = nil
local uiKit: any = nil

local NUMBER_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
}
local PAD_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.ButtonA] = 1,
	[Enum.KeyCode.ButtonX] = 2,
	[Enum.KeyCode.ButtonY] = 3,
	[Enum.KeyCode.ButtonB] = 4,
}
local PAD_LABELS = { "A", "X", "Y", "B" }

-- "1. Jual / Beli" on a keyboard / touch screen, "A  Jual / Beli" while a gamepad is the last thing used.
local function choiceLabel(index: number, text: string): string
	local last = UserInputService:GetLastInputType()
	if (last == Enum.UserInputType.Gamepad1 or last == Enum.UserInputType.Gamepad2) and PAD_LABELS[index] then
		return `{PAD_LABELS[index]}  {text}`
	end
	return `{index}. {text}`
end

local function pick(index: number)
	local choices = activeChoices
	local choice = choices and choices[index]
	if choice then
		activeChoices = nil
		T1Dialog.Hide()
		choice.onChoose()
	end
end

local function ensure()
	if gui then
		return
	end
	local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any
	uiKit = UiKit

	local screen = Instance.new("ScreenGui")
	screen.Name = "T1Dialog"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = UiKit.LAYER.DIALOG -- 120: above the cinematic bars and the cover (T1Cutscene 110), the HUD and panels
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Enabled = false

	local frame = Instance.new("CanvasGroup")
	frame.Name = "Box"
	frame.GroupTransparency = 0
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -16)
	frame.Size = UDim2.new(0.92, 0, 0, METRICS.conversation.minH)
	frame.BackgroundColor3 = uiKit.BG -- shown until the bamboo image has loaded
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 18)
	round.Parent = frame
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(METRICS.conversation.maxWidth, METRICS.conversation.minH)
	limit.MinSize = Vector2.new(300, METRICS.conversation.minH)
	limit.Parent = frame
	boxLimit = limit
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = frame
	boxScale = scale

	-- The bamboo background (the existing panel skin). A fixed-size child, never part of a layout.
	local skin = Instance.new("ImageLabel")
	skin.Name = "Bamboo"
	skin.BackgroundTransparency = 1
	skin.Size = UDim2.fromScale(1, 1)
	skin.ZIndex = 1
	skin.Image = UiAssets.PANEL.image
	skin.ScaleType = Enum.ScaleType.Slice
	skin.SliceCenter = UiAssets.PANEL.slice
	skin.SliceScale = UiAssets.PANEL.sliceScale
	skin.Parent = frame
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ skin })
		end)
		if skin.IsLoaded then
			frame.BackgroundTransparency = 1
			round:Destroy()
		end
	end)

	-- The face, left.
	local well = Instance.new("Frame")
	well.Name = "AvatarWell"
	well.AnchorPoint = Vector2.new(0, 0.5)
	well.Position = UDim2.new(0, 34, 0.5, 0)
	well.Size = UDim2.fromOffset(METRICS.conversation.avatar, METRICS.conversation.avatar)
	-- Same face frame as the player's own avatar (HudController's photo): a circle on UiKit.ROW with the bamboo ring behind.
	well.BackgroundColor3 = UiKit.ROW
	well.BorderSizePixel = 0
	well.ClipsDescendants = true -- the 3D face is cut to the circle (a UICorner alone does not clip a ViewportFrame)
	well.ZIndex = 2
	well.Parent = frame
	avatarWell = well
	local wellRound = Instance.new("UICorner")
	wellRound.CornerRadius = UDim.new(1, 0)
	wellRound.Parent = well
	-- The bamboo ring sits on the frame, behind the face, centred on it (larger than the face, so it cannot be a child of well).
	local ring = Instance.new("ImageLabel")
	ring.Name = "PhotoRing"
	ring.BackgroundTransparency = 1
	ring.Image = UiAssets.PLATE.image
	ring.ScaleType = Enum.ScaleType.Fit
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.new(0, 34 + METRICS.conversation.avatar / 2, 0.5, 0)
	ring.Size = UDim2.fromOffset(math.floor(METRICS.conversation.avatar * 46 / 32), math.floor(METRICS.conversation.avatar * 46 / 32))
	ring.ZIndex = 1
	ring.Parent = frame
	ringImage = ring
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Face"
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.ZIndex = 3
	vp.Ambient = Color3.fromRGB(170, 166, 158)
	vp.LightColor = Color3.fromRGB(255, 244, 224)
	vp.LightDirection = Vector3.new(-0.4, -0.6, -1)
	vp.Parent = well
	local vpRound = Instance.new("UICorner")
	vpRound.CornerRadius = UDim.new(1, 0)
	vpRound.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 26
	cam.Parent = vp
	vp.CurrentCamera = cam

	-- The name above the text, then the text.
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 34 + METRICS.conversation.avatar + 14, 0, 14)
	name.Size = UDim2.new(1, -(34 + METRICS.conversation.avatar + 14 + 34), 0, 20)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Font = UiKit.FONT
	name.TextSize = uiKit.TEXT_SMALL
	name.TextColor3 = uiKit.HEADER_DARK
	name.ZIndex = 2
	name.Parent = frame

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Position = UDim2.new(0, 34 + METRICS.conversation.avatar + 14, 0, 34)
	-- Three lines high (14 px text), and narrower on the right so the Next button, bottom right, never covers a line.
	text.Size = UDim2.new(1, -(34 + METRICS.conversation.avatar + 14 + 34 + 100), 0, 54)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.Font = UiKit.FONT_BODY
	text.TextSize = uiKit.TEXT_SMALL
	text.TextColor3 = uiKit.TEXT
	text.ZIndex = 2
	text.Parent = frame

	local next = UiKit.button(frame, "Next", "Next", UiKit.BUTTON) :: TextButton
	next.AnchorPoint = Vector2.new(1, 1)
	next.Position = UDim2.new(1, -34, 1, -16)
	next.Size = UDim2.fromOffset(92, 34)
	next.TextSize = uiKit.TEXT_BODY
	next.ZIndex = 5
	next.Visible = false
	next.Activated:Connect(function()
		local handler = nextHandler
		if handler then
			handler()
		end
	end)

	-- The choices of a conversation: a row of UiKit buttons inside the box, where Next would be.
	local row = Instance.new("Frame")
	row.Name = "Choices"
	row.AnchorPoint = Vector2.new(1, 1)
	row.Position = UDim2.new(1, -34, 1, -16)
	row.Size = UDim2.new(1, -(34 + METRICS.conversation.avatar + 14 + 34), 0, 40)
	row.BackgroundTransparency = 1
	row.ZIndex = 5
	row.Visible = false
	row.Parent = frame
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 10)
	rowLayout.Parent = row
	choicesRow = row

	-- Keys: Enter / gamepad A = Next; 1-4 (keyboard) or A X Y B (gamepad) = the choices. Not E or Space: E talks to an NPC and
	-- Space jumps.
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not screen.Enabled then
			return
		end
		local key = input.KeyCode
		if activeChoices then
			local index = NUMBER_KEYS[key] or PAD_KEYS[key]
			if index then
				pick(index)
			end
			return
		end
		if not next.Visible then
			return
		end
		if key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.ButtonA then
			local handler = nextHandler
			if handler then
				handler()
			end
		end
	end)
	UserInputService.LastInputTypeChanged:Connect(function()
		local choices = activeChoices
		if choices then
			for index, button in choiceButtons do
				button.Text = choiceLabel(index, choices[index].text)
			end
		end
	end)

	screen.Parent = player:WaitForChild("PlayerGui")
	gui, box, nameLabel, textLabel, nextButton, viewport, viewportCamera = screen, frame, name, text, next, vp, cam
end

-- Draws a copy of the NPC's head and shoulders in the face well.
local function setAvatar(model: Model?)
	if model == avatarModel then
		return
	end
	avatarModel = model
	local vp, cam = viewport, viewportCamera
	if avatarPhoto then
		avatarPhoto:Destroy()
		avatarPhoto = nil
	end
	-- An NPC with a 2D portrait is drawn like the player's own photo (round, no 3D box). Others keep the 3D face.
	local image = if model then UiAssets.PORTRAIT_IMAGES[model.Name] else nil
	if image and avatarWell and vp then
		vp.Visible = false
		local photo = Instance.new("ImageLabel")
		photo.Name = "Portrait"
		photo.BackgroundTransparency = 1
		photo.Image = image
		photo.ScaleType = Enum.ScaleType.Fit
		photo.Size = UDim2.fromScale(1, 1)
		photo.ZIndex = 3
		photo.Parent = avatarWell
		avatarPhoto = photo
		return
	end
	if vp then
		vp.Visible = true
	end
	if not vp or not cam then
		return
	end
	for _, child in vp:GetChildren() do
		if child ~= cam then
			child:Destroy()
		end
	end
	if not model then
		return
	end
	local copy = model:Clone()
	for _, d in copy:GetDescendants() do
		if
			d:IsA("Script")
			or d:IsA("LocalScript")
			or d:IsA("Humanoid")
			or d:IsA("BillboardGui")
			or d:IsA("ProximityPrompt")
		then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	copy:PivotTo(CFrame.new(0, 0, 0)) -- identity rotation: the rig faces -Z
	copy.Parent = vp
	-- Frame the whole head (hair and accessories included) and the shoulders below it, for any rig: the view height comes from
	-- the model's own top and the head's size, so no NPC's head is cut by the square viewport or the round mask.
	local head = copy:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local topY = head.Position.Y + head.Size.Y / 2
		for _, d in copy:GetDescendants() do
			if d:IsA("BasePart") then
				local top = d.Position.Y + d.Size.Y / 2
				if top > topY and d.Position.Y > head.Position.Y - head.Size.Y then
					topY = top -- hair, hats and other accessories above the head
				end
			end
		end
		local bottomY = head.Position.Y - head.Size.Y * 1.6 -- down to the shoulders
		local centerY = (topY + bottomY) / 2
		local viewHeight = (topY - bottomY) * 1.3 -- a margin around the top so the head is never at the edge
		local halfFov = math.rad(cam.FieldOfView / 2)
		local distance = (viewHeight / 2) / math.tan(halfFov)
		local center = Vector3.new(head.Position.X, centerY, head.Position.Z)
		local look = head.CFrame.LookVector
		cam.CFrame = CFrame.lookAt(center + look * distance, center)
	end
end

-- Minimize / restore (GUI doc Bab 5.1, owner rule), Windows-style: Minimize drops the box down to the bottom edge (the pivot is
-- its bottom centre), shrinking and fading it. Restore rises it back from the bottom edge to its place, growing and fading in.
-- The box's final position and layout never change: Show always sets the rest position.
local MINIMIZE_SECONDS = 0.2 -- Quad In
local RESTORE_SECONDS = 0.25 -- Back Out for the scale (a small overshoot), Quad Out for the fade
local MINIMIZED_SCALE = 0.3
local BOTTOM_EDGE = UDim2.fromScale(0.5, 1) -- bottom middle of the screen: the box drops to it and rises from it
local animations: { Tween } = {}

local function stopAnimations()
	for _, tween in animations do
		tween:Cancel()
	end
	table.clear(animations)
end

-- GUI doc 5.1: the geometry of one variant. Face, name and text sizes; the box width (share of the screen, capped) and its
-- height (the text is measured and the box is clamped to min / max). Called on every Show, so the variant always fits.
local function layoutFor(opts: Options)
	local m = if opts.variant == "instruction" then METRICS.instruction else METRICS.conversation
	local choices = opts.choices ~= nil
	local camera = Workspace.CurrentCamera
	local viewWidth = if camera then camera.ViewportSize.X else 800
	local boxWidth = math.min(m.maxWidth, viewWidth * m.widthShare)
	local left = 34 + m.avatar + 14 -- the face, then the gap
	local reserve = if choices then 34 else 34 + 100 -- right side: 34 px, plus the Next column when there is no choice row
	local textWidth = boxWidth - left - reserve
	local textSize = uiKit[m.textSize] :: number
	local measured = 0
	local ok, size = pcall(function()
		return game:GetService("TextService"):GetTextSize(opts.text, textSize, Enum.Font.FredokaOne, Vector2.new(textWidth, 1000))
	end)
	if ok then
		measured = (size :: Vector2).Y + 8
	end
	local textHeight = math.max(measured, textSize + 6)
	local height: number
	if choices then
		height = math.max(m.minH, m.textTop + textHeight + 10 + m.choiceH + 16)
	else
		height = math.min(m.maxH, math.max(m.minH, m.textTop + textHeight + m.bottomPad))
	end
	if box then
		box.Size = UDim2.fromOffset(boxWidth, height)
	end
	if boxLimit then
		boxLimit.MaxSize = Vector2.new(boxWidth, height)
		boxLimit.MinSize = Vector2.new(math.min(300, boxWidth), height)
	end
	if avatarWell then
		avatarWell.Size = UDim2.fromOffset(m.avatar, m.avatar)
	end
	if ringImage then
		ringImage.Position = UDim2.new(0, 34 + m.avatar / 2, 0.5, 0)
		ringImage.Size = UDim2.fromOffset(m.ring, m.ring)
	end
	if nameLabel then
		nameLabel.Position = UDim2.new(0, left, 0, m.nameTop)
		nameLabel.Size = UDim2.new(1, -(left + 34), 0, m.nameH)
		nameLabel.TextSize = uiKit[m.nameSize]
	end
	if textLabel then
		textLabel.Position = UDim2.new(0, left, 0, m.textTop)
		textLabel.Size = UDim2.new(1, -(left + reserve), 0, textHeight)
		textLabel.TextSize = textSize
	end
	if nextButton then
		nextButton.Size = UDim2.fromOffset(m.nextW, m.nextH)
	end
	if choicesRow then
		choicesRow.Size = UDim2.new(1, -(left + 34), 0, m.choiceH)
	end
end

-- Shows (or updates) the dialog. Non-blocking: with showNext, onNext fires when the player presses Next.
function T1Dialog.Show(opts: Options)
	ensure()
	local screen, frame, name, text, next =
		gui :: ScreenGui, box :: CanvasGroup, nameLabel :: TextLabel, textLabel :: TextLabel, nextButton :: TextButton
	-- A plain show always starts at full size and fully visible: a minimize or restore in progress is stopped here.
	stopAnimations()
	if boxScale then
		boxScale.Scale = 1
	end
	frame.GroupTransparency = 0
	frame.Position = UDim2.new(0.5, 0, 1, -(opts.bottom or 16))
	name.Text = opts.name
	text.Text = opts.text
	local choices = opts.choices
	next.Visible = opts.showNext and choices == nil
	nextHandler = if next.Visible then opts.onNext else nil
	layoutFor(opts) -- GUI doc 5.1: sizes for this variant (instruction or conversation)
	for _, button in choiceButtons do
		button:Destroy()
	end
	choiceButtons = {}
	activeChoices = choices
	local row = choicesRow :: Frame
	row.Visible = choices ~= nil
	if choices then
		for index, choice in choices do
			local button = uiKit.button(
				row,
				`Choice{index}`,
				choiceLabel(index, choice.text),
				if index == 1 then uiKit.BUTTON else uiKit.BUTTON_MUTED
			) :: TextButton
			button.LayoutOrder = index
			button.Size = UDim2.fromOffset(math.max(120, #choice.text * 9 + 56), uiKit.TOUCH)
			button.TextSize = uiKit.TEXT_BODY
			button.ZIndex = 5
			button.Activated:Connect(function()
				pick(index)
			end)
			table.insert(choiceButtons, button)
		end
	end
	setAvatar(opts.avatar)
	dialogWanted = true
	screen.Enabled = player:GetAttribute("FishingActive") ~= true
end

-- Drops the box down to the bottom edge (scale to MINIMIZED_SCALE, fade out). Yields until the animation is over.
-- The box keeps its turn (the caller decides what follows). Does nothing when no box is on screen.
function T1Dialog.Minimize()
	if not box or not boxScale or not dialogWanted then
		return
	end
	stopAnimations()
	local info = TweenInfo.new(MINIMIZE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local move = TweenService:Create(box, info, { Position = BOTTOM_EDGE, GroupTransparency = 1 })
	local shrink = TweenService:Create(boxScale, info, { Scale = MINIMIZED_SCALE })
	table.insert(animations, move)
	table.insert(animations, shrink)
	move:Play()
	shrink:Play()
	task.wait(MINIMIZE_SECONDS) -- timed, not Completed: a cancelled tween (Hide) must not leave this waiting forever
end

-- Sets the content (Show), then rises from the bottom edge back to its place while growing and fading in. Non-blocking.
function T1Dialog.Restore(opts: Options)
	T1Dialog.Show(opts)
	if not box or not boxScale then
		return
	end
	local rest = box.Position
	box.Position = BOTTOM_EDGE
	boxScale.Scale = MINIMIZED_SCALE
	box.GroupTransparency = 1
	stopAnimations()
	local back = TweenInfo.new(RESTORE_SECONDS, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local fade = TweenInfo.new(RESTORE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweens = {
		TweenService:Create(box, back, { Position = rest }),
		TweenService:Create(boxScale, back, { Scale = 1 }),
		TweenService:Create(box, fade, { GroupTransparency = 0 }),
	}
	for _, tween in tweens do
		table.insert(animations, tween)
		tween:Play()
	end
end

function T1Dialog.Hide()
	stopAnimations()
	dialogWanted = false
	if gui then
		gui.Enabled = false
	end
	nextHandler = nil
	activeChoices = nil
	if ownerId ~= nil and ownerRank == T1Dialog.BEAT then
		lastBeatEnd = os.clock()
	end
	ownerId = nil -- the box is free: the next waiting line may take it
end

-- Waits for the box (see the speech turns above). Returns the release function once this line owns the box, or nil if
-- `cancelled` said so while it waited (a line that is no longer wanted, e.g. the step moved on). Call the release when the
-- line is finished (Next, a choice); Hide also frees it.
function T1Dialog.Acquire(npc: string, rank: number, cancelled: (() -> boolean)?): (() -> boolean)?
	turnCounter += 1
	local turn: Turn = { id = turnCounter, npc = npc, rank = rank }
	local at = #turns + 1
	for index, other in turns do
		if other.rank > rank then
			at = index
			break
		end
	end
	table.insert(turns, at, turn)
	local function leave()
		for index, other in turns do
			if other == turn then
				table.remove(turns, index)
				return
			end
		end
	end
	while true do
		if cancelled and cancelled() then
			leave()
			return nil
		end
		local graceOver = rank ~= T1Dialog.AMBIENT or os.clock() - lastBeatEnd >= BEAT_GRACE
		if turns[1] == turn and ownerId == nil and graceOver then
			break
		end
		task.wait(0.05)
	end
	leave()
	ownerId = turn.id
	ownerRank = rank
	-- Returns true when this call freed the box (the turn was still ours), false when it had already gone.
	return function(): boolean
		if ownerId == turn.id then
			if rank == T1Dialog.BEAT then
				lastBeatEnd = os.clock()
			end
			ownerId = nil
			return true
		end
		return false
	end
end

-- True if a line for `npc` at this rank is already waiting for the box (so the same ambient line is not queued twice).
function T1Dialog.Waiting(npc: string, rank: number): boolean
	for _, turn in turns do
		if turn.npc == npc and turn.rank == rank then
			return true
		end
	end
	return false
end

-- Still counts as shown while fishing (the box is only hidden on screen), so the tutorial does not re-open it.
function T1Dialog.IsShown(): boolean
	return gui ~= nil and dialogWanted
end

-- Plan 3.6: while the fishing UI is on (FishingController sets FishingActive), the conversation box is hidden entirely
-- and comes back, with the same text, when the fishing ends.
player:GetAttributeChangedSignal("FishingActive"):Connect(function()
	if gui then
		gui.Enabled = dialogWanted and player:GetAttribute("FishingActive") ~= true
	end
end)

-- The dialog box of the NPC `id` ("mak_sari", "pak_udin", "kak_fajar"): the model to draw as the face (the real NPC).
function T1Dialog.NpcModel(id: string): Model?
	-- Kak Fajar tutorial (Update owner 2026-11-22): the client-only copy at the fishing spot replaces the shop rig for this player.
	if id == "kak_fajar" then
		local copy = Workspace:FindFirstChild("KakFajar_Tutorial_Local")
		if copy and copy:IsA("Model") then
			return copy
		end
	end
	local npcs = Workspace:FindFirstChild("Npcs")
	local model = npcs and npcs:FindFirstChild(id)
	return if model and model:IsA("Model") then model else nil
end

return T1Dialog
