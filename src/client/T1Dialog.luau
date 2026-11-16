--!strict
-- The ONE dialog box of the T1 intro and tutorial (screen space, bottom of the screen). Bamboo frame (UiAssets.PANEL, the
-- same 9-slice as every panel), the speaker's face on the left (a ViewportFrame with a copy of the NPC), the name above the
-- text, and a Next button at the bottom right. With showNext the player MUST press Next (nothing advances by itself).
-- Client only. T1Ghost.client drives it; nothing else draws tutorial text.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local UiAssets = require(ReplicatedStorage.Shared.Config.UiAssets)

local T1Dialog = {}

export type Choice = { text: string, onChoose: () -> () }

export type Options = {
	name: string, -- "Mbok Minah"
	text: string,
	avatar: Model?, -- the NPC to draw as the face (a copy is rendered; the model itself is never touched)
	showNext: boolean, -- true: the Next button shows and onNext fires when pressed
	bottom: number?, -- px from the bottom of the screen (above the cinematic bar, or above the dock)
	onNext: (() -> ())?,
	choices: { Choice }?, -- numbered choices in a row at the bottom of the box (instead of Next); 1-4 / gamepad A X Y B pick one
}

local BOX_HEIGHT = 112
local BOX_MAX_WIDTH = 520
local AVATAR = 50
local INK = Color3.fromRGB(80, 52, 32)
local LEAF_DARK = Color3.fromRGB(62, 100, 38)
local PARCHMENT = Color3.fromRGB(250, 240, 214)
local BAMBOO = Color3.fromRGB(214, 164, 64)

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local box: Frame? = nil
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
	screen.DisplayOrder = 120 -- above the cinematic bars and the cover (T1Cutscene 110), the coachmark (60) and the HUD
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Enabled = false

	local frame = Instance.new("Frame")
	frame.Name = "Box"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -16)
	frame.Size = UDim2.new(0.92, 0, 0, BOX_HEIGHT)
	frame.BackgroundColor3 = PARCHMENT -- shown until the bamboo image has loaded
	frame.BorderSizePixel = 0
	frame.Parent = screen
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 18)
	round.Parent = frame
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(BOX_MAX_WIDTH, BOX_HEIGHT)
	limit.MinSize = Vector2.new(300, BOX_HEIGHT)
	limit.Parent = frame
	boxLimit = limit

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
	well.Size = UDim2.fromOffset(AVATAR, AVATAR)
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
	ring.Position = UDim2.new(0, 34 + AVATAR / 2, 0.5, 0)
	ring.Size = UDim2.fromOffset(math.floor(AVATAR * 46 / 32), math.floor(AVATAR * 46 / 32))
	ring.ZIndex = 1
	ring.Parent = frame
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
	name.Position = UDim2.new(0, 34 + AVATAR + 14, 0, 14)
	name.Size = UDim2.new(1, -(34 + AVATAR + 14 + 34), 0, 20)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Font = UiKit.FONT
	name.TextSize = 15
	name.TextColor3 = LEAF_DARK
	name.ZIndex = 2
	name.Parent = frame

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Position = UDim2.new(0, 34 + AVATAR + 14, 0, 34)
	-- Three lines high (14 px text), and narrower on the right so the Next button, bottom right, never covers a line.
	text.Size = UDim2.new(1, -(34 + AVATAR + 14 + 34 + 100), 0, 54)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.Font = UiKit.FONT_BODY
	text.TextSize = 14
	text.TextColor3 = INK
	text.ZIndex = 2
	text.Parent = frame

	local next = UiKit.button(frame, "Next", "Next", UiKit.BUTTON) :: TextButton
	next.AnchorPoint = Vector2.new(1, 1)
	next.Position = UDim2.new(1, -34, 1, -16)
	next.Size = UDim2.fromOffset(92, 34)
	next.TextSize = 15
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
	row.Size = UDim2.new(1, -(34 + AVATAR + 14 + 34), 0, 40)
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

-- Shows (or updates) the dialog. Non-blocking: with showNext, onNext fires when the player presses Next.
function T1Dialog.Show(opts: Options)
	ensure()
	local screen, frame, name, text, next =
		gui :: ScreenGui, box :: Frame, nameLabel :: TextLabel, textLabel :: TextLabel, nextButton :: TextButton
	frame.Position = UDim2.new(0.5, 0, 1, -(opts.bottom or 16))
	name.Text = opts.name
	text.Text = opts.text
	local choices = opts.choices
	next.Visible = opts.showNext and choices == nil
	nextHandler = if next.Visible then opts.onNext else nil
	-- With choices the text is two lines high and the whole width (the choices sit on the bottom row), else three lines and
	-- narrower on the right (Next sits there).
	if choices then
		-- Choices sit on a row at the bottom (under the text). The box grows to fit the whole text above that row, so the
		-- text is never covered by the buttons, at any screen width.
		local camera = workspace.CurrentCamera
		local viewWidth = if camera then camera.ViewportSize.X else 800
		local textWidth = math.min(BOX_MAX_WIDTH, viewWidth * 0.92) - (34 + AVATAR + 14 + 34)
		local ok, measured = pcall(function()
			return game:GetService("TextService"):GetTextSize(opts.text, 14, Enum.Font.Gotham, Vector2.new(textWidth, 1000))
		 end)
		local textHeight = if ok then (measured :: Vector2).Y + 8 else 64
		local boxHeight = math.max(BOX_HEIGHT, 34 + textHeight + 10 + 40 + 16)
		text.Size = UDim2.new(1, -(34 + AVATAR + 14 + 34), 0, textHeight)
		if box then
			box.Size = UDim2.new(0.92, 0, 0, boxHeight)
		end
		if boxLimit then
			boxLimit.MaxSize = Vector2.new(BOX_MAX_WIDTH, boxHeight)
		end
	else
		text.Size = UDim2.new(1, -(34 + AVATAR + 14 + 34 + 100), 0, 54)
		if box then
			box.Size = UDim2.new(0.92, 0, 0, BOX_HEIGHT)
		end
		if boxLimit then
			boxLimit.MaxSize = Vector2.new(BOX_MAX_WIDTH, BOX_HEIGHT)
		end
	end
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
			button.Size = UDim2.fromOffset(math.max(120, #choice.text * 9 + 56), 40)
			button.TextSize = 16
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

function T1Dialog.Hide()
	dialogWanted = false
	if gui then
		gui.Enabled = false
	end
	nextHandler = nil
	activeChoices = nil
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

-- The dialog box of the NPC `id` ("mbok_minah", "pak_darmo", "mas_joko"): the model to draw as the face (the real NPC).
function T1Dialog.NpcModel(id: string): Model?
	local npcs = Workspace:FindFirstChild("Npcs")
	local model = npcs and npcs:FindFirstChild(id)
	return if model and model:IsA("Model") then model else nil
end

return T1Dialog
