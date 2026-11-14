--!strict
-- The shared UI look: a warm village feel (bamboo, rattan, parchment) to match the map, built for phones first.
-- Every controller builds its panels through this file, so the whole game restyles from here.
--
-- Two modes, chosen per element by Config/UiAssets:
--   * IMAGE: the ForgeGUI kit (panel / button / icons) once its ids are filled in.
--   * FLAT: the same look drawn with plain Frames (parchment + bamboo stroke), used until the images are uploaded.
-- Mobile rules: touch targets are at least 44 px, rows 56 px, text at least 13 px, and every ScreenGui gets a UIScale
-- (UiKit.autoScale) that grows the UI on big screens but never shrinks it below phone size.

local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Locale = require(ReplicatedStorage.Shared.Locale)
local UiAssets = require(ReplicatedStorage.Shared.Config.UiAssets)

local UiKit = {}

-- Palette ------------------------------------------------------------------------------------
UiKit.BG = Color3.fromRGB(250, 240, 214) -- parchment: panels and chips
UiKit.ROW = Color3.fromRGB(255, 251, 240) -- list rows (cards)
UiKit.HEADER = Color3.fromRGB(96, 142, 62) -- sheet header band (leaf green)
UiKit.HEADER_DARK = Color3.fromRGB(62, 100, 38)
UiKit.FOOTER = Color3.fromRGB(240, 226, 190)
UiKit.TEXT = Color3.fromRGB(80, 52, 32) -- dark brown ink
UiKit.BUTTON = Color3.fromRGB(112, 160, 70) -- leaf green: the main action
UiKit.BUTTON_MUTED = Color3.fromRGB(206, 196, 176) -- tan: secondary / inactive
UiKit.BAMBOO = Color3.fromRGB(214, 164, 64)
UiKit.BAMBOO_DARK = Color3.fromRGB(150, 104, 40)
UiKit.TERRACOTTA = Color3.fromRGB(196, 100, 64)
UiKit.RED = Color3.fromRGB(200, 64, 52) -- "Batal" in every modal, and a total the player cannot afford
UiKit.RED_TEXT = Color3.fromRGB(196, 44, 36) -- red numbers on parchment
UiKit.CREAM = Color3.fromRGB(255, 248, 232)
UiKit.DARK = Color3.fromRGB(66, 46, 30) -- dark bamboo brown: floating menus, hints and tooltips (cream text on it)

UiKit.FONT = Enum.Font.FredokaOne -- headings, buttons, numbers
UiKit.FONT_BODY = Enum.Font.GothamMedium

UiKit.TOUCH = 50 -- minimum touch target, px (thumb-sized)
UiKit.ROW_HEIGHT = 82

local PANEL = UiAssets.PANEL
local BUTTON = UiAssets.BUTTON
local RIBBON = UiAssets.RIBBON
local CARD = UiAssets.CARD
local CHIP = UiAssets.CHIP
local PLATE = UiAssets.PLATE
local CLOSE = UiAssets.CLOSE

local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- Icons ------------------------------------------------------------------------------------

function UiKit.iconId(key: string): string
	return UiAssets.ICONS[key] or ""
end

-- An icon as an ImageLabel (nil while its id is not uploaded).
-- A few sheet-cut icons carry a sliver of the neighbouring sprite on their right edge: show only the first N pixels.
local ICON_CROP: { [string]: number } = { tas = 230, hias = 230 }

function UiKit.icon(parent: Instance, key: string, size: number): ImageLabel?
	local id = UiKit.iconId(key)
	if id == "" then
		return nil
	end
	local image = Instance.new("ImageLabel")
	image.Name = `Icon_{key}`
	image.BackgroundTransparency = 1
	image.Image = id
	image.Size = UDim2.fromOffset(size, size)
	image.ScaleType = Enum.ScaleType.Fit
	local crop = ICON_CROP[key]
	if crop then
		image.ImageRectOffset = Vector2.zero
		image.ImageRectSize = Vector2.new(crop, 256)
	end
	image.Parent = parent
	return image
end

-- Surfaces ---------------------------------------------------------------------------------

-- Runs `callback` once the image has LOADED. IsLoaded's changed-signal does not fire reliably (and images inside a
-- disabled ScreenGui do not load until it is shown), so poll lightly until the image is loaded or destroyed.
local cached: { [string]: boolean } = {} -- skin ids the preload below fetched successfully

local function whenLoaded(image: ImageLabel, callback: () -> ())
	-- A cached skin applies at once. Waiting for IsLoaded on every rebuild (panels re-render on each tap) made ALL the
	-- buttons flash their flat fallback for a moment whenever one of them was pressed.
	if image.IsLoaded or cached[image.Image] then
		callback()
		return
	end
	task.spawn(function()
		while image.Parent and not image.IsLoaded do
			task.wait(0.2)
		end
		if image.Parent then
			callback()
		end
	end)
end

-- Warm the cache so the skins are ready the moment a panel opens.
task.spawn(function()
	local warm = {}
	for _, id in { PANEL.image, BUTTON.image, RIBBON.image, CARD.image, CHIP.image, PLATE.image, CLOSE.image } do
		if id ~= "" then
			local image = Instance.new("ImageLabel")
			image.Image = id
			table.insert(warm, image)
		end
	end
	pcall(function()
		ContentProvider:PreloadAsync(warm)
	end)
	for _, image in warm do
		local ok, status = pcall(function()
			return ContentProvider:GetAssetFetchStatus(image.Image)
		end)
		if ok and status == Enum.AssetFetchStatus.Success then
			cached[image.Image] = true
		end
	end
end)

-- Puts a ForgeGUI image behind a GuiObject's content (ZIndex 0, 9-sliced unless `fit`). Returns nil while the asset id is
-- empty. `onLoaded` runs once the image really loaded: that is where the caller hides its flat fallback.
local function attachSkin(target: GuiObject, def: UiAssets.Skin, onLoaded: (() -> ())?, fit: boolean?): ImageLabel?
	if def.image == "" then
		return nil
	end
	local skin = Instance.new("ImageLabel")
	skin.Name = "Skin"
	skin.BackgroundTransparency = 1
	skin.Size = UDim2.fromScale(1, 1)
	skin.ZIndex = 0
	skin.Image = def.image
	if fit then
		skin.ScaleType = Enum.ScaleType.Fit
	else
		skin.ScaleType = Enum.ScaleType.Slice
		skin.SliceCenter = def.slice
		skin.SliceScale = def.sliceScale
	end
	skin.Parent = target
	if onLoaded then
		whenLoaded(skin, onLoaded)
	end
	return skin
end

-- Gives a Frame/TextButton the panel look: the bamboo frame image, or a parchment card with a bamboo border.
local function skinPanel(frame: GuiObject)
	-- Flat look first (parchment + bamboo border); the image goes on top and, once it has actually LOADED, replaces
	-- it. An image that is still in Roblox moderation or fails to load therefore never leaves an invisible panel.
	frame.BackgroundColor3 = UiKit.BG
	corner(frame, 16)
	local border = stroke(frame, UiKit.BAMBOO, 4)
	if PANEL.image ~= "" then
		local skin = Instance.new("ImageLabel")
		skin.Name = "Skin"
		skin.BackgroundTransparency = 1
		skin.Size = UDim2.fromScale(1, 1)
		skin.ZIndex = 0
		skin.Image = PANEL.image
		skin.ScaleType = Enum.ScaleType.Slice
		skin.SliceCenter = PANEL.slice
		skin.SliceScale = PANEL.sliceScale
		skin.Parent = frame
		whenLoaded(skin, function()
			frame.BackgroundTransparency = 1
			border.Enabled = false
			local round = frame:FindFirstChildOfClass("UICorner")
			if round then
				round:Destroy()
			end
		end)
	end
end

-- Maps a requested button color to a tint for the golden bamboo image (multiplied, so it can only darken).
local function imageTint(color: Color3): Color3
	if color == UiKit.BUTTON then
		return Color3.new(1, 1, 1)
	elseif color == UiKit.BUTTON_MUTED then
		return Color3.fromRGB(238, 230, 216) -- barely darker than the gold: it multiplies, so anything stronger turns brown
	elseif color == UiKit.TERRACOTTA then
		return Color3.fromRGB(255, 176, 150)
	elseif color == UiKit.RED then
		return Color3.fromRGB(255, 112, 100) -- multiplies the golden plank into a clear red
	end
	return Color3.new(1, 1, 1)
end

function UiKit.button(parent: Instance, name: string, text: string, color: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Font = UiKit.FONT
	button.TextSize = 19
	button.AutoButtonColor = true
	button.Size = UDim2.fromOffset(120, UiKit.TOUCH)
	button.Parent = parent

	-- Flat look first; the bamboo image goes on top and takes over once it has LOADED (see skinPanel).
	-- Consumers keep changing BackgroundColor3 to show state, so the image tint mirrors it.
	local base = color or UiKit.BUTTON
	local flatText = if base == UiKit.BUTTON or base == UiKit.TERRACOTTA or base == UiKit.RED then UiKit.CREAM else Color3.fromRGB(120, 104, 80)
	button.BackgroundColor3 = base
	button.TextColor3 = flatText
	corner(button, 14)
	local border = stroke(button, Color3.fromRGB(base.R * 255 * 0.62, base.G * 255 * 0.62, base.B * 255 * 0.62), 2.5)
	local shade = Instance.new("UIGradient") -- light top, darker bottom: reads as a raised key
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))
	shade.Parent = button
	button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	button.TextStrokeTransparency = if flatText == UiKit.CREAM then 0.75 else 1
	if BUTTON.image ~= "" then
		local skin = Instance.new("ImageLabel")
		skin.Name = "Skin"
		skin.BackgroundTransparency = 1
		skin.Size = UDim2.fromScale(1, 1)
		skin.ZIndex = 0
		skin.Image = BUTTON.image
		skin.ScaleType = Enum.ScaleType.Slice
		skin.SliceCenter = BUTTON.slice
		skin.SliceScale = BUTTON.sliceScale
		skin.ImageColor3 = imageTint(base)
		skin.Parent = button
		whenLoaded(skin, function()
			button.BackgroundTransparency = 1
			button.TextColor3 = UiKit.TEXT
			button.TextStrokeTransparency = 1
			button.AutoButtonColor = false
			border.Enabled = false
			shade.Enabled = false
			-- The skin now covers the button's own text, so show it on an overlay label that mirrors the button.
			local overlay = Instance.new("TextLabel")
			overlay.Name = "Caption"
			overlay.BackgroundTransparency = 1
			overlay.Size = UDim2.fromScale(1, 1)
			overlay.ZIndex = 2
			-- Cream letters with a dark outline: readable on the golden plank AND on its darkened (inactive) tint.
			overlay.TextColor3 = UiKit.CREAM
			overlay.TextStrokeColor3 = Color3.fromRGB(70, 40, 14)
			overlay.TextStrokeTransparency = 0.1
			overlay.TextWrapped = true
			overlay.Parent = button
			local function mirror()
				overlay.Text = button.Text
				overlay.Font = button.Font
				overlay.TextSize = button.TextSize
				-- Inactive buttons (TextTransparency 0.45, set by UiKit.row) stay readable, only a little dimmer.
				local dim = if button.TextTransparency > 0 then 0.55 else 0
				overlay.TextTransparency = dim
				overlay.TextStrokeTransparency = 0.1 + dim * 1.1 -- the outline fades with the letters
			end
			mirror()
			for _, property in { "Text", "Font", "TextSize", "TextTransparency" } do
				button:GetPropertyChangedSignal(property):Connect(mirror)
			end
		end)
		button:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
			skin.ImageColor3 = imageTint(button.BackgroundColor3)
		end)
	end
	return button
end

-- Panels -----------------------------------------------------------------------------------

export type Panel = {
	gui: ScreenGui,
	title: TextLabel,
	list: ScrollingFrame,
	footer: Frame,
	footerLabel: TextLabel,
}

function UiKit.panel(name: string, titleText: string, onClose: () -> ()): Panel
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Dim backdrop: tapping outside the panel closes it (easy one-handed exit on phones).
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
	backdrop.BackgroundTransparency = 0.4
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Parent = gui
	backdrop.Activated:Connect(onClose)

	-- The ForgeGUI bamboo frame (9-slice), centered, with the green title ribbon hung over its top edge and a round
	-- close badge on its top-right corner. Content insets leave room for the frame's ~34 px border.
	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(0.96, 0, 0.92, 0)
	frame.Active = true -- swallow taps so they do not reach the backdrop
	frame.Parent = gui
	skinPanel(frame)

	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(620, 700)
	sizeLimit.Parent = frame

	-- Title ribbon. Flat green pill until the ribbon image has loaded.
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.AnchorPoint = Vector2.new(0.5, 0)
	ribbon.Position = UDim2.new(0.5, 0, 0, -16)
	ribbon.Size = UDim2.new(0.62, 0, 0, 58)
	ribbon.BackgroundColor3 = UiKit.HEADER
	ribbon.ZIndex = 2
	ribbon.Parent = frame
	corner(ribbon, 14)
	local ribbonStroke = stroke(ribbon, UiKit.HEADER_DARK, 3)
	local ribbonLimit = Instance.new("UISizeConstraint")
	ribbonLimit.MinSize = Vector2.new(240, 0)
	ribbonLimit.MaxSize = Vector2.new(420, 80)
	ribbonLimit.Parent = ribbon
	attachSkin(ribbon, RIBBON, function()
		ribbon.BackgroundTransparency = 1
		ribbonStroke.Enabled = false
		local round = ribbon:FindFirstChildOfClass("UICorner")
		if round then
			round:Destroy()
		end
	end)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.5)
	title.Size = UDim2.new(1, -120, 1, -12)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextColor3 = UiKit.CREAM
	title.Font = UiKit.FONT
	title.TextSize = 26
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = titleText
	title.ZIndex = 3
	title.TextStrokeColor3 = UiKit.HEADER_DARK
	title.TextStrokeTransparency = 0.2
	title.Parent = ribbon

	-- Round close badge: the ForgeGUI close image once loaded, else the flat/bamboo button below it.
	local close = UiKit.button(frame, "Close", "X", UiKit.TERRACOTTA)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, -8)
	close.Size = UDim2.fromOffset(56, 56)
	close.TextSize = 24
	close.ZIndex = 4
	close.Activated:Connect(onClose)
	local closeSkin = attachSkin(close, CLOSE, nil, true)
	if closeSkin then
		closeSkin.ZIndex = 5
		whenLoaded(closeSkin, function()
			-- Hide the flat button and its plank skin/caption: the badge image replaces them all.
			close.BackgroundTransparency = 1
			close.TextTransparency = 1
			for _, child in close:GetChildren() do
				if (child:IsA("ImageLabel") and child ~= closeSkin) or (child:IsA("TextLabel") and child.Name == "Caption") then
					(child :: GuiObject).Visible = false
				elseif child:IsA("UIStroke") or child:IsA("UIGradient") then
					(child :: any).Enabled = false
				end
			end
		end)
	end

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(32, 52)
	list.Size = UDim2.new(1, -64, 1, -(52 + 26 + 56))
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = UiKit.BAMBOO_DARK
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.ElasticBehavior = Enum.ElasticBehavior.Always
	list.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.BackgroundTransparency = 1
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.new(0, 36, 1, -28)
	footer.Size = UDim2.new(1, -72, 0, 50)
	footer.Parent = frame

	local footerLabel = Instance.new("TextLabel")
	footerLabel.Name = "Info"
	footerLabel.BackgroundTransparency = 1
	footerLabel.Size = UDim2.new(0.55, 0, 1, 0)
	footerLabel.TextXAlignment = Enum.TextXAlignment.Left
	footerLabel.TextColor3 = UiKit.TEXT
	footerLabel.Font = UiKit.FONT
	footerLabel.TextSize = 18
	footerLabel.TextWrapped = true
	footerLabel.Parent = footer

	-- Slide up from the bottom whenever the panel is shown.
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			frame.Position = UDim2.fromScale(0.5, 1.4)
			TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.52) }):Play()
		end
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return { gui = gui, title = title, list = list, footer = footer, footerLabel = footerLabel }
end

function UiKit.clear(list: ScrollingFrame)
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Section header: bold green text.
function UiKit.header(list: ScrollingFrame, text: string, order: number)
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 34)
	label.AutomaticSize = Enum.AutomaticSize.Y -- a long line wraps and grows instead of being cut off
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = UiKit.HEADER_DARK
	label.Font = UiKit.FONT
	label.TextSize = 20
	label.TextWrapped = true
	label.Text = text
	label.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.Parent = label
end

-- A row card: two-line text on the left and an optional action button on the right.
-- enabled = false greys the button out and ignores taps.
-- extraText / onExtra add a second button to the left of the main one (e.g. "Tawar" next to "Jual").
function UiKit.row(list: ScrollingFrame, order: number, text: string, subText: string?, buttonText: string?, enabled: boolean?, onClick: (() -> ())?, extraText: string?, onExtra: (() -> ())?): Frame
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.BackgroundColor3 = UiKit.ROW
	row.Size = UDim2.new(1, 0, 0, UiKit.ROW_HEIGHT)
	row.Parent = list
	corner(row, 16)
	local rowBorder = stroke(row, Color3.fromRGB(228, 208, 164), 2)
	attachSkin(row, CARD, function()
		row.BackgroundTransparency = 1
		rowBorder.Enabled = false
		local round = row:FindFirstChildOfClass("UICorner")
		if round then
			round:Destroy()
		end
	end)

	local hasButton = buttonText ~= nil
	local textInset = (if hasButton then 138 else 30) + (if extraText then 96 else 0)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(22, 9)
	label.Size = UDim2.new(1, -textInset, 0, 40)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = UiKit.TEXT
	label.Font = UiKit.FONT
	label.TextSize = 18
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	label.Parent = row

	if subText then
		local sub = label:Clone()
		sub.Position = UDim2.fromOffset(22, 52)
		sub.Size = UDim2.new(1, -textInset, 0, 20)
		sub.Font = UiKit.FONT_BODY
		sub.TextSize = 14
		sub.TextWrapped = false
		sub.TextColor3 = Color3.fromRGB(128, 100, 66)
		sub.Text = subText
		sub.Parent = row
	end

	if buttonText then
		local isEnabled = enabled ~= false
		local button = UiKit.button(row, "Action", buttonText, if isEnabled then UiKit.BUTTON else UiKit.BUTTON_MUTED)
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -16, 0.5, 0)
		button.Size = UDim2.fromOffset(106, 50)
		button.AutoButtonColor = isEnabled and BUTTON.image == ""
		button.TextTransparency = if isEnabled then 0 else 0.45
		if not isEnabled then
			local plank = button:FindFirstChild("Skin")
			if plank and plank:IsA("ImageLabel") then
				plank.ImageTransparency = 0.45 -- inactive: the plank fades into the card instead of going dark
			end
			local shade = button:FindFirstChildOfClass("UIGradient")
			if shade then
				shade:Destroy() -- inactive: flat, not raised
			end
		end
		if onClick then
			button.Activated:Connect(function()
				if isEnabled then
					onClick()
				end
			end)
		end
	end
	if extraText then
		local extra = UiKit.button(row, "Extra", extraText, UiKit.BUTTON)
		extra.AnchorPoint = Vector2.new(1, 0.5)
		extra.Position = UDim2.new(1, -130, 0.5, 0)
		extra.Size = UDim2.fromOffset(84, 50)
		if onExtra then
			extra.Activated:Connect(onExtra)
		end
	end
	return row
end

-- Tabs, number picker, item picture, trade row, confirm modal --------------------------------------

-- Greys a button out (or brings it back). Works before and after its image skin has loaded.
local function setButtonEnabled(button: TextButton, enabled: boolean)
	button.BackgroundColor3 = if enabled then UiKit.BUTTON else UiKit.BUTTON_MUTED
	button.AutoButtonColor = enabled and BUTTON.image == ""
	button.TextTransparency = if enabled then 0 else 0.45
	local plank = button:FindFirstChild("Skin")
	if plank and plank:IsA("ImageLabel") then
		plank.ImageTransparency = if enabled then 0 else 0.45
	end
	local shade = button:FindFirstChildOfClass("UIGradient")
	if shade then
		shade.Enabled = enabled
	end
end

export type Tabs = { frame: Frame, buttons: { [string]: TextButton }, select: (id: string) -> () }

-- A row of tab buttons filling the width. The selected tab is green, the others tan. `onSelect(id)` runs on a tap.
function UiKit.tabs(parent: Instance, defs: { { id: string, text: string } }, selected: string, onSelect: (id: string) -> ()): Tabs
	local frame = Instance.new("Frame")
	frame.Name = "Tabs"
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local buttons: { [string]: TextButton } = {}
	-- The chosen tab is the bright plank; the others are clearly darker and dimmer (the plain muted tint is too close to tell).
	local function select(id: string)
		for tabId, button in buttons do
			local on = tabId == id
			button.BackgroundColor3 = if on then UiKit.BUTTON else UiKit.BUTTON_MUTED
			local plank = button:FindFirstChild("Skin")
			if plank and plank:IsA("ImageLabel") then
				plank.ImageColor3 = if on then Color3.new(1, 1, 1) else Color3.fromRGB(168, 150, 120)
			end
			button.TextTransparency = if on then 0 else 0.25
		end
	end
	for order, def in defs do
		local button = UiKit.button(frame, `Tab_{def.id}`, def.text, if def.id == selected then UiKit.BUTTON else UiKit.BUTTON_MUTED)
		button.LayoutOrder = order
		button.Size = UDim2.new(1 / #defs, -8 * (#defs - 1) / #defs, 1, 0)
		button.TextSize = 21
		button.Activated:Connect(function()
			select(def.id)
			onSelect(def.id)
		end)
		buttons[def.id] = button
	end
	select(selected)
	return { frame = frame, buttons = buttons, select = select }
end

-- Number picker: [ - ] 3 [ + ]. Holding a button repeats. `onChange(n)` runs after every change; the picker keeps its own
-- value, so a caller only has to update what depends on it (a total), not rebuild the panel.
function UiKit.stepper(parent: Instance, value: number, minValue: number, maxValue: number, onChange: (n: number) -> ()): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Stepper"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(150, 38)
	frame.Parent = parent

	local current = math.clamp(value, minValue, maxValue)
	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.new(1, -84, 1, 0)
	label.TextColor3 = UiKit.TEXT
	label.Font = UiKit.FONT
	label.TextSize = 22
	label.Text = tostring(current)
	label.Parent = frame

	local function set(n: number)
		n = math.clamp(n, minValue, maxValue)
		if n ~= current then
			current = n
			label.Text = tostring(n)
			onChange(n)
		end
	end

	local function make(name: string, text: string, delta: number, anchorX: number)
		local button = UiKit.button(frame, name, text, UiKit.BUTTON_MUTED)
		button.AnchorPoint = Vector2.new(anchorX, 0.5)
		button.Position = UDim2.new(anchorX, 0, 0.5, 0)
		button.Size = UDim2.fromOffset(40, 38)
		button.TextSize = 26
		local token = 0
		button.MouseButton1Down:Connect(function()
			token += 1
			local mine = token
			set(current + delta)
			task.spawn(function()
				task.wait(0.4)
				while token == mine and frame.Parent do
					set(current + delta)
					task.wait(0.07)
				end
			end)
		end)
		local function release()
			token += 1
		end
		button.MouseButton1Up:Connect(release)
		button.MouseLeave:Connect(release)
	end
	make("Minus", "-", -1, 0)
	make("Plus", "+", 1, 1)
	return frame
end

-- Item picture slot: the card frame with a transparent picture inside. The picture is UiAssets.THUMBS[key] once the model's
-- image exists; until then a dimmed icon (`placeholderIcon`, an icon key) stands in, so the layout never changes later.
function UiKit.thumb(parent: Instance, size: number, thumbKey: string?, placeholderIcon: string?): Frame
	local slot = Instance.new("Frame")
	slot.Name = "Thumb"
	slot.BackgroundColor3 = Color3.fromRGB(240, 226, 190)
	slot.Size = UDim2.fromOffset(size, size)
	slot.Parent = parent
	corner(slot, 14)
	local slotBorder = stroke(slot, Color3.fromRGB(214, 190, 140), 2)
	local skin = attachSkin(slot, CARD, function()
		slot.BackgroundTransparency = 1
		slotBorder.Enabled = false
		local round = slot:FindFirstChildOfClass("UICorner")
		if round then
			round:Destroy()
		end
	end)
	if skin then
		skin.ImageColor3 = Color3.fromRGB(240, 226, 190) -- a touch darker than the row card behind it
	end

	local picture = Instance.new("ImageLabel")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1 -- the picture has a transparent background: the frame shows through
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, 0.5)
	picture.Size = UDim2.new(1, -16, 1, -16)
	picture.ScaleType = Enum.ScaleType.Fit
	picture.ZIndex = 2
	local real = if thumbKey then UiAssets.THUMBS[thumbKey] else nil
	if real and real ~= "" then
		picture.Image = real
	else
		picture.Image = UiKit.iconId(placeholderIcon or "")
		picture.ImageTransparency = 0.4 -- placeholder: visibly "not the final picture"
		picture.ImageColor3 = Color3.fromRGB(170, 150, 118)
	end
	picture.Parent = slot
	return slot
end

export type TradeRow = {
	name: string,
	sub: string?,
	thumbKey: string?,
	placeholderIcon: string?,
	unitPrice: number?, -- Koin for ONE unit; nil = no price shown (e.g. "Pakai" a rod you own)
	maxQty: number, -- 0 = nothing to pick, the row is inactive
	pickQty: boolean, -- show the number picker
	qty: number?, -- starting quantity (kept by the caller across rebuilds)
	money: number?, -- the player's Koin: a total above it turns red and blocks the button (buying). nil = selling
	actionText: string,
	disabledText: string?, -- shown on the button when maxQty is 0 (e.g. "Lv 3", "Kuota habis")
	onQty: ((n: number) -> ())?,
	onAction: (qty: number) -> (),
}

-- One shop row: picture slot, name + detail, number picker, total, action button. The total is red when the player cannot
-- pay it. Picking a number only updates the row's own total and button (no rebuild, so holding + keeps repeating).
function UiKit.tradeRow(list: ScrollingFrame, order: number, def: TradeRow): Frame
	local row = Instance.new("Frame")
	row.Name = "TradeRow"
	row.LayoutOrder = order
	row.BackgroundColor3 = UiKit.ROW
	row.Size = UDim2.new(1, 0, 0, 108)
	row.Parent = list
	corner(row, 16)
	local rowBorder = stroke(row, Color3.fromRGB(228, 208, 164), 2)
	attachSkin(row, CARD, function()
		row.BackgroundTransparency = 1
		rowBorder.Enabled = false
		local round = row:FindFirstChildOfClass("UICorner")
		if round then
			round:Destroy()
		end
	end)

	local thumb = UiKit.thumb(row, 76, def.thumbKey, def.placeholderIcon)
	thumb.AnchorPoint = Vector2.new(0, 0.5)
	thumb.Position = UDim2.new(0, 18, 0.5, 0)

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(106, 14)
	label.Size = UDim2.new(1, -106 - 214, 0, 28)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = UiKit.TEXT
	label.Font = UiKit.FONT
	label.TextSize = 19
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = def.name
	label.Parent = row
	if def.sub then
		local sub = label:Clone()
		sub.Name = "Sub"
		sub.Position = UDim2.fromOffset(106, 46)
		sub.Size = UDim2.new(1, -106 - 214, 0, 50)
		sub.Font = UiKit.FONT_BODY
		sub.TextSize = 14
		sub.TextColor3 = Color3.fromRGB(128, 100, 66)
		sub.Text = def.sub
		sub.Parent = row
	end

	-- Right block: picker on top, total + button below.
	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.AnchorPoint = Vector2.new(1, 0.5)
	right.Position = UDim2.new(1, -16, 0.5, 0)
	right.Size = UDim2.fromOffset(196, 92)
	right.Parent = row

	local active = def.maxQty >= 1
	local qty = math.clamp(def.qty or 1, 1, math.max(def.maxQty, 1))

	local total = Instance.new("TextLabel")
	total.Name = "Total"
	total.BackgroundTransparency = 1
	total.AnchorPoint = Vector2.new(0, 1)
	total.Position = UDim2.fromScale(0, 1)
	total.Size = UDim2.new(1, -92, 0, 40)
	total.TextXAlignment = Enum.TextXAlignment.Left
	total.TextColor3 = UiKit.TEXT
	total.Font = UiKit.FONT
	total.TextSize = 17
	total.TextWrapped = true
	total.Parent = right

	local action = UiKit.button(right, "Action", if active then def.actionText else (def.disabledText or def.actionText), UiKit.BUTTON)
	action.AnchorPoint = Vector2.new(1, 1)
	action.Position = UDim2.fromScale(1, 1)
	action.Size = UDim2.fromOffset(86, 42)
	action.TextSize = if not active and #(def.disabledText or "") > 7 then 14 else 18 -- "Kuota habis" must fit the button
	action.TextWrapped = true

	local function refresh()
		local sum = if def.unitPrice then def.unitPrice * qty else nil
		local short = sum ~= nil and def.money ~= nil and sum > def.money
		total.Visible = sum ~= nil and (active or def.money ~= nil) -- selling: no total on a row you cannot sell from
		if sum then
			total.Text = Locale.t("ui.koin", { n = Locale.formatNumber(sum) })
			total.TextColor3 = if short then UiKit.RED_TEXT else UiKit.TEXT
		end
		setButtonEnabled(action, active and not short)
	end
	refresh()

	if active and def.pickQty and def.maxQty > 1 then
		local stepper = UiKit.stepper(right, qty, 1, def.maxQty, function(n)
			qty = n
			refresh()
			if def.onQty then
				def.onQty(n)
			end
		end)
		stepper.AnchorPoint = Vector2.new(1, 0)
		stepper.Position = UDim2.fromScale(1, 0)
		stepper.Size = UDim2.fromOffset(196, 38)
	end

	action.Activated:Connect(function()
		local sum = if def.unitPrice then def.unitPrice * qty else 0
		if active and not (def.money ~= nil and sum > def.money) then
			def.onAction(qty)
		end
	end)
	return row
end

-- Confirm modal (the ONE modal look for the whole game): dim backdrop, a bamboo panel, title, text, an optional total and two
-- buttons: Batal on the LEFT (red), Setuju on the RIGHT (green). Tapping outside the panel is Batal.
export type Confirm = {
	title: string,
	body: string?,
	totalText: string?, -- e.g. "1.500 Koin"
	totalRed: boolean?, -- the player cannot pay it
	confirmText: string?, -- default "Setuju"
	canConfirm: boolean?, -- false greys Setuju out
	onConfirm: () -> (),
	onCancel: (() -> ())?,
}

local confirmGui: ScreenGui? = nil
local confirmParts: { title: TextLabel, body: TextLabel, totalRow: Frame, totalValue: TextLabel, no: TextButton, yes: TextButton }? = nil
local confirmCurrent: Confirm? = nil

function UiKit.closeConfirm()
	confirmCurrent = nil
	if confirmGui then
		confirmGui.Enabled = false
	end
end

local function buildConfirm()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ConfirmModal"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100 -- above every panel
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local function cancel()
		local current = confirmCurrent
		UiKit.closeConfirm()
		if current and current.onCancel then
			current.onCancel()
		end
	end

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
	backdrop.BackgroundTransparency = 0.45
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Parent = gui
	backdrop.Activated:Connect(cancel)

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromOffset(400, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.Active = true -- taps on the box must not reach the backdrop
	box.Parent = gui
	skinPanel(box)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(460, 480)
	limit.Parent = box

	-- The content sits in its own frame: the panel skin is a child of `box`, and a layout on `box` itself would line the
	-- skin up like one more row.
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.ZIndex = 2
	content.Parent = box
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 42), UDim.new(0, 40)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 44), UDim.new(0, 44)
	pad.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = content

	local function text(name: string, order: number, font: Enum.Font, size: number, color: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.LayoutOrder = order
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextWrapped = true
		label.TextColor3 = color
		label.Font = font
		label.TextSize = size
		label.Parent = content
		return label
	end
	local title = text("Title", 1, UiKit.FONT, 26, UiKit.TEXT)
	local body = text("Body", 2, UiKit.FONT_BODY, 16, UiKit.TEXT)

	local totalRow = Instance.new("Frame")
	totalRow.Name = "TotalRow"
	totalRow.LayoutOrder = 3
	totalRow.BackgroundTransparency = 1
	totalRow.Size = UDim2.new(1, 0, 0, 38)
	totalRow.Parent = content
	local totalLabel = Instance.new("TextLabel")
	totalLabel.BackgroundTransparency = 1
	totalLabel.Size = UDim2.fromScale(0.4, 1)
	totalLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalLabel.TextColor3 = Color3.fromRGB(128, 100, 66)
	totalLabel.Font = UiKit.FONT
	totalLabel.TextSize = 18
	totalLabel.Text = Locale.t("confirm.total")
	totalLabel.Parent = totalRow
	local totalValue = Instance.new("TextLabel")
	totalValue.Name = "Value"
	totalValue.BackgroundTransparency = 1
	totalValue.AnchorPoint = Vector2.new(1, 0)
	totalValue.Position = UDim2.fromScale(1, 0)
	totalValue.Size = UDim2.fromScale(0.6, 1)
	totalValue.TextXAlignment = Enum.TextXAlignment.Right
	totalValue.Font = UiKit.FONT
	totalValue.TextSize = 28
	totalValue.Parent = totalRow

	-- Batal (left, red) and Setuju (right, green): the same on every modal.
	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.LayoutOrder = 4
	buttons.BackgroundTransparency = 1
	buttons.Size = UDim2.new(1, 0, 0, 56)
	buttons.Parent = content
	local no = UiKit.button(buttons, "Cancel", Locale.t("confirm.no"), UiKit.RED)
	no.Position = UDim2.fromScale(0, 0)
	no.Size = UDim2.new(0.5, -6, 1, 0)
	no.TextSize = 22
	no.Activated:Connect(cancel)
	local yes = UiKit.button(buttons, "Confirm", Locale.t("confirm.yes"), UiKit.BUTTON)
	yes.AnchorPoint = Vector2.new(1, 0)
	yes.Position = UDim2.fromScale(1, 0)
	yes.Size = UDim2.new(0.5, -6, 1, 0)
	yes.TextSize = 22
	yes.Activated:Connect(function()
		local current = confirmCurrent
		if current and current.canConfirm ~= false then
			UiKit.closeConfirm()
			current.onConfirm()
		end
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	confirmGui = gui
	confirmParts = { title = title, body = body, totalRow = totalRow, totalValue = totalValue, no = no, yes = yes }
end

-- Shows the modal, or refreshes it when it is already open (a caller may call this again when the Koin changes).
function UiKit.confirm(opts: Confirm)
	if not confirmGui or not confirmParts then
		buildConfirm()
	end
	local parts = confirmParts :: any
	confirmCurrent = opts
	parts.title.Text = opts.title
	parts.body.Text = opts.body or ""
	parts.body.Visible = opts.body ~= nil
	parts.totalRow.Visible = opts.totalText ~= nil
	parts.totalValue.Text = opts.totalText or ""
	parts.totalValue.TextColor3 = if opts.totalRed then UiKit.RED_TEXT else UiKit.TEXT
	parts.yes.Text = opts.confirmText or Locale.t("confirm.yes")
	setButtonEnabled(parts.yes, opts.canConfirm ~= false)
	;(confirmGui :: ScreenGui).Enabled = true
end

function UiKit.confirmOpen(): boolean
	return confirmGui ~= nil and confirmGui.Enabled
end

-- HUD: stat chips and the menu bar --------------------------------------------------------------

-- A rounded chip with an icon on the left and a value label (the returned TextLabel).
-- An empty capsule with the bamboo look (the ForgeGUI chip image, flat fallback). Parent your own content to it.
function UiKit.pill(parent: Instance, name: string, width: number, height: number): Frame
	local chip = Instance.new("Frame")
	chip.Name = name
	chip.BackgroundColor3 = UiKit.BG
	chip.Size = UDim2.fromOffset(width, height)
	chip.Parent = parent
	corner(chip, 22)
	local chipBorder = stroke(chip, UiKit.BAMBOO, 3)
	attachSkin(chip, CHIP, function()
		chip.BackgroundTransparency = 1
		chipBorder.Enabled = false
		local round = chip:FindFirstChildOfClass("UICorner")
		if round then
			round:Destroy()
		end
	end)
	return chip
end

function UiKit.chip(parent: Instance, name: string, iconKey: string?, width: number, height: number?): TextLabel
	local chipHeight = height or 52
	local chip = UiKit.pill(parent, `{name}Chip`, width, chipHeight)

	local hasIcon = iconKey ~= nil and UiKit.iconId(iconKey) ~= ""
	if hasIcon then
		local icon = UiKit.icon(chip, iconKey :: string, chipHeight - 12)
		if icon then
			icon.ZIndex = 2
		end
		if icon then
			icon.Position = UDim2.fromOffset(8, 6)
		end
	end

	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(if hasIcon then chipHeight + 2 else 16, 0)
	label.Size = UDim2.new(1, if hasIcon then -(chipHeight + 14) else -32, 1, 0)
	label.ZIndex = 2
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = UiKit.TEXT
	label.Font = UiKit.FONT
	label.TextSize = if chipHeight < 48 then 15 else 18
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = chip
	return label
end

local MENU_ICON = {
	BagButton = "tas",
	DecorButton = "hias",
	OrdersButton = "pesanan",
	BookButton = "koleksi",
	SettingsButton = "atur",
	StoreButton = "toko",
	SocialButton = "warga",
	GarapButton = "garap",
}

-- Where each button lives (thumb-friendly layout, no captions: the icons speak, a tooltip names them on hover):
--   DOCK = the things you use all the time: a row at the bottom center, between the thumbstick and the jump button.
--          Big (58 px) round icon buttons.
--   everything else = a vertical column at the top right (Warga, Toko, Atur, Koleksi). On phones it collapses behind a
--   round menu button and slides open downward.
local DOCK_ORDER = { GarapButton = 1, DecorButton = 2, BagButton = 3, OrdersButton = 4 }
local MENU_SIZE = 50 -- round button size in the top-right column

-- Calls `callback` now and whenever the screen size changes (rotation, window resize). It follows the CURRENT camera:
-- Roblox may swap Workspace.CurrentCamera (respawn, cutscenes), and a connection to the old one would go silent.
local function onViewportChanged(callback: () -> ())
	local connection: RBXScriptConnection? = nil
	local function bind()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		local camera = Workspace.CurrentCamera
		if camera then
			connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(callback)
		end
		callback()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
	bind()
end

-- A phone or tablet (touch) gets the collapsible menu. Testing on a PC: player:SetAttribute("CompactHud", true).
local function isCompact(): boolean
	return UserInputService.TouchEnabled or Players.LocalPlayer:GetAttribute("CompactHud") == true
end

-- Phone portrait (narrow): the dock is a column on the right edge. Landscape / tablet: a row at the bottom center.
local function relayoutDock(bar: Frame, layout: UIListLayout)
	local camera = Workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else Vector2.new(800, 400)
	if size.X < size.Y * 1.1 then
		bar.AnchorPoint = Vector2.new(1, 0)
		bar.Position = UDim2.new(1, -8, 0, 184)
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	else
		bar.AnchorPoint = Vector2.new(0.5, 1)
		bar.Position = UDim2.new(0.5, 0, 1, -10)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	end
end

local function dockOf(hud: Instance): Frame
	local existing = hud:FindFirstChild("DockBar")
	if existing and existing:IsA("Frame") then
		return existing
	end
	local bar = Instance.new("Frame")
	bar.Name = "DockBar"
	bar.BackgroundTransparency = 1
	bar.AutomaticSize = Enum.AutomaticSize.XY
	bar.Size = UDim2.new(0, 0, 0, 0)
	bar.Parent = hud

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = bar

	onViewportChanged(function()
		relayoutDock(bar, layout)
	end)
	return bar
end

-- A round bamboo plate (the ForgeGUI plate image, flat fallback) that fills its parent, with an optional icon.
local function makePlate(parent: GuiObject, size: number, iconKey: string?): Frame
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.BackgroundColor3 = UiKit.BG
	plate.Size = UDim2.fromScale(1, 1)
	plate.Parent = parent
	corner(plate, size / 2)
	local plateBorder = stroke(plate, UiKit.BAMBOO, 3)
	attachSkin(plate, PLATE, function()
		plate.BackgroundTransparency = 1
		plateBorder.Enabled = false
		local round = plate:FindFirstChildOfClass("UICorner")
		if round then
			round:Destroy()
		end
	end, true)
	if iconKey then
		local icon = UiKit.icon(plate, iconKey, size - 14)
		if icon then
			icon.ZIndex = 2
			icon.Position = UDim2.fromOffset(7, 7)
		end
	end
	return plate
end

-- Hover tooltip (mouse only): a small dark label next to the button, named by its "TipText" attribute.
local function tipOf(hud: Instance): TextLabel
	local existing = hud:FindFirstChild("HudTip")
	if existing and existing:IsA("TextLabel") then
		return existing
	end
	local tip = Instance.new("TextLabel")
	tip.Name = "HudTip"
	tip.BackgroundColor3 = UiKit.DARK
	tip.BackgroundTransparency = 0.1
	tip.AutomaticSize = Enum.AutomaticSize.XY
	tip.Size = UDim2.fromOffset(0, 0)
	tip.TextColor3 = UiKit.CREAM
	tip.Font = UiKit.FONT
	tip.TextSize = 15
	tip.Visible = false
	tip.ZIndex = 50
	tip.Parent = hud
	corner(tip, 10)
	stroke(tip, UiKit.BAMBOO, 2)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
	pad.Parent = tip
	return tip
end

-- Shows `text` next to `anchor` (left of it, or above it for the bottom dock). Positions are in screen fractions, so
-- the HUD's UIScale does not matter. Used by the menu buttons and the buff icons.
function UiKit.showTip(hud: Instance, anchor: GuiObject, text: string, above: boolean)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local view = camera.ViewportSize
	local tip = tipOf(hud)
	tip.Text = text
	local topLeft, size = anchor.AbsolutePosition, anchor.AbsoluteSize
	if above then
		if topLeft.X + size.X / 2 < view.X * 0.3 then
			-- Near the left edge (the player card): line the tip's left edge up with the icon so it never runs off screen.
			tip.AnchorPoint = Vector2.new(0, 1)
			tip.Position = UDim2.fromScale(math.max(topLeft.X, 8) / view.X, (topLeft.Y - 6) / view.Y)
		else
			tip.AnchorPoint = Vector2.new(0.5, 1)
			tip.Position = UDim2.fromScale((topLeft.X + size.X / 2) / view.X, (topLeft.Y - 6) / view.Y)
		end
	else
		tip.AnchorPoint = Vector2.new(1, 0.5)
		tip.Position = UDim2.fromScale((topLeft.X - 8) / view.X, (topLeft.Y + size.Y / 2) / view.Y)
	end
	tip.Visible = true
end

function UiKit.hideTip(hud: Instance)
	local tip = hud:FindFirstChild("HudTip")
	if tip and tip:IsA("TextLabel") then
		tip.Visible = false
	end
end

local function attachTip(hud: Instance, button: GuiButton, above: boolean)
	if not UserInputService.MouseEnabled then
		return
	end
	button.MouseEnter:Connect(function()
		local text = button:GetAttribute("TipText")
		if typeof(text) == "string" and text ~= "" then
			UiKit.showTip(hud, button, text, above)
		end
	end)
	button.MouseLeave:Connect(function()
		UiKit.hideTip(hud)
	end)
end

-- Names a menu button (shown as a tooltip on hover; the buttons carry no captions).
function UiKit.setMenuLabel(button: GuiButton, text: string)
	button:SetAttribute("TipText", text)
	if button:IsA("TextButton") and button.Text ~= "" then
		button.Text = text
	end
end

-- Marks a menu button as "on" (a green ring), e.g. the Garap button while Garap mode is open.
function UiKit.setMenuActive(button: GuiButton, active: boolean)
	local ring = button:FindFirstChild("ActiveRing", true) -- it lives inside the plate
	if ring and ring:IsA("GuiObject") then
		ring.Visible = active
	end
end

-- The top-right column: [menu toggle] + the clipped "Items" frame that slides open downward on phones.
local menuState: { setExpanded: ((on: boolean, animate: boolean) -> ())? } = { setExpanded = nil }

local function menuItemsOf(hud: Instance): Frame
	local existing = hud:FindFirstChild("MenuBar")
	if existing then
		return existing:FindFirstChild("Items") :: Frame
	end
	local menu = Instance.new("Frame")
	menu.Name = "MenuBar"
	menu.BackgroundTransparency = 1
	menu.AnchorPoint = Vector2.new(1, 0)
	menu.Position = UDim2.new(1, -8, 0, 8)
	menu.AutomaticSize = Enum.AutomaticSize.XY
	menu.Size = UDim2.fromOffset(MENU_SIZE, 0)
	menu.Parent = hud
	local menuLayout = Instance.new("UIListLayout")
	menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
	menuLayout.Padding = UDim.new(0, 8)
	menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	menuLayout.Parent = menu

	-- Round menu button with a hamburger (three bars) that turns a quarter when open.
	local toggle = Instance.new("TextButton")
	toggle.Name = "MenuToggle"
	toggle.Text = ""
	toggle.AutoButtonColor = false
	toggle.BackgroundTransparency = 1
	toggle.Size = UDim2.fromOffset(MENU_SIZE, MENU_SIZE)
	toggle.LayoutOrder = -1000
	toggle.Parent = menu
	local plate = makePlate(toggle, MENU_SIZE, nil)
	local bars = Instance.new("Frame")
	bars.Name = "Bars"
	bars.BackgroundTransparency = 1
	bars.AnchorPoint = Vector2.new(0.5, 0.5)
	bars.Position = UDim2.fromScale(0.5, 0.5)
	bars.Size = UDim2.fromOffset(22, 18)
	bars.ZIndex = 2
	bars.Parent = plate
	for i = 0, 2 do
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = UiKit.TEXT
		bar.BorderSizePixel = 0
		bar.Position = UDim2.fromOffset(0, i * 7)
		bar.Size = UDim2.fromOffset(22, 4)
		bar.ZIndex = 3
		bar.Parent = bars
		corner(bar, 2)
	end
	toggle:SetAttribute("TipText", Locale.t("ui.menu"))
	attachTip(hud, toggle, false)

	local items = Instance.new("Frame")
	items.Name = "Items"
	items.BackgroundTransparency = 1
	items.ClipsDescendants = true
	items.LayoutOrder = 0
	items.Size = UDim2.fromOffset(MENU_SIZE, 0)
	items.AutomaticSize = Enum.AutomaticSize.Y
	items.Parent = menu
	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemsLayout.Padding = UDim.new(0, 8)
	itemsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	itemsLayout.Parent = items

	local expanded = true
	local running: Tween? = nil
	local function setExpanded(on: boolean, animate: boolean)
		expanded = on
		if running then
			running:Cancel()
			running = nil
		end
		items.AutomaticSize = Enum.AutomaticSize.None
		local target = if on then itemsLayout.AbsoluteContentSize.Y else 0
		local turn = if on then 90 else 0
		if animate then
			local tween = TweenService:Create(items, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(MENU_SIZE, target) })
			running = tween
			tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed and on then
					items.AutomaticSize = Enum.AutomaticSize.Y -- follow items added later
				end
			end)
			tween:Play()
			TweenService:Create(bars, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Rotation = turn }):Play()
		else
			items.Size = UDim2.fromOffset(MENU_SIZE, target)
			bars.Rotation = turn
			if on then
				items.AutomaticSize = Enum.AutomaticSize.Y
			end
		end
	end
	menuState.setExpanded = setExpanded
	toggle.Activated:Connect(function()
		setExpanded(not expanded, true)
	end)

	local function refreshCompact()
		local compact = isCompact()
		toggle.Visible = compact
		setExpanded(not compact, false)
	end
	refreshCompact()
	Players.LocalPlayer:GetAttributeChangedSignal("CompactHud"):Connect(refreshCompact)
	return items
end

-- Adds/places a HUD button by name (your designed one if it exists, else a round icon button in the dock or the top-right
-- column). No captions: `text` becomes the hover tooltip. Flat pills (until the icon loads) show only the text.
function UiKit.menuItem(hud: Instance, name: string, text: string, slot: number): GuiButton?
	local button = hud:FindFirstChild(name, true)
	if not button then
		local iconKey = MENU_ICON[name]
		local dock = DOCK_ORDER[name] ~= nil
		local hasIcon = iconKey ~= nil and UiKit.iconId(iconKey) ~= ""
		local plateSize = if dock then 58 else MENU_SIZE
		local item = Instance.new("TextButton")
		item.Name = name
		item.Text = ""
		item.AutoButtonColor = false
		item.LayoutOrder = if dock then DOCK_ORDER[name] else -slot
		item.Parent = if dock then dockOf(hud) else menuItemsOf(hud)
		if hasIcon then
			item.BackgroundTransparency = 1
			item.Size = UDim2.fromOffset(plateSize, plateSize)
			local plate = makePlate(item, plateSize, iconKey)
			local active = Instance.new("Frame")
			active.Name = "ActiveRing"
			active.BackgroundTransparency = 1
			active.Size = UDim2.fromScale(1, 1)
			active.ZIndex = 4
			active.Visible = false
			active.Parent = plate
			corner(active, plateSize / 2)
			stroke(active, Color3.fromRGB(120, 200, 80), 4)
		else
			item.Size = UDim2.fromOffset(if dock then 90 else 76, UiKit.TOUCH)
			item.BackgroundColor3 = UiKit.BG
			item.Text = text
			item.TextColor3 = UiKit.TEXT
			item.Font = UiKit.FONT
			item.TextSize = 16
			item.TextWrapped = true
			corner(item, 14)
			stroke(item, UiKit.BAMBOO, 3)
		end
		item:SetAttribute("TipText", text)
		attachTip(hud, item, dock)
		if not dock then
			-- On phones the column folds away again after you pick something.
			item.Activated:Connect(function()
				if isCompact() and menuState.setExpanded then
					menuState.setExpanded(false, true)
				end
			end)
		end
		button = item
	end
	return if button:IsA("GuiButton") then button else nil
end

-- Same, and binds the tap. (Existing designed buttons are bound too.)
function UiKit.hudButton(name: string, text: string, slot: number, onClick: () -> ())
	local hud = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	if not hud then
		return
	end
	local button = UiKit.menuItem(hud, name, text, slot)
	if button then
		button.Activated:Connect(onClick)
	end
end

-- A small round close badge (the ForgeGUI close image, flat terracotta "X" until it loads) for floating menus.
function UiKit.closeBadge(parent: Instance, size: number, onClick: () -> ()): TextButton
	local close = UiKit.button(parent, "Close", "X", UiKit.TERRACOTTA)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, 8, 0, -8)
	close.Size = UDim2.fromOffset(size, size)
	close.TextSize = 18
	close.ZIndex = 6
	close.Activated:Connect(onClick)
	local closeSkin = attachSkin(close, CLOSE, nil, true)
	if closeSkin then
		closeSkin.ZIndex = 7
		whenLoaded(closeSkin, function()
			close.BackgroundTransparency = 1
			close.TextTransparency = 1
			for _, child in close:GetChildren() do
				if (child:IsA("ImageLabel") and child ~= closeSkin) or (child:IsA("TextLabel") and child.Name == "Caption") then
					(child :: GuiObject).Visible = false
				elseif child:IsA("UIStroke") or child:IsA("UIGradient") then
					(child :: any).Enabled = false
				end
			end
		end)
	end
	return close
end

-- Responsive scale -------------------------------------------------------------------------------
-- Phones keep scale 1 (44 px targets are already comfortable); big screens scale the UI up so it doesn't look tiny.

local function currentScale(): number
	local camera = Workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else 600
	-- The game is landscape: phones (~390 px tall) stay at 1 so touch targets keep their size; tall screens scale up.
	return math.clamp(height / 560, 1, 1.35)
end

function UiKit.autoScale()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local scales: { UIScale } = {}

	local function attach(gui: Instance)
		if gui:IsA("ScreenGui") then
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- skins (ZIndex 0) must sit above their parent but below its text overlay
		end
		if gui:IsA("ScreenGui") and not gui:FindFirstChild("KT_Scale") and gui:GetAttribute("NoScale") ~= true then
			local scale = Instance.new("UIScale")
			scale.Name = "KT_Scale"
			scale.Scale = currentScale()
			scale.Parent = gui
			table.insert(scales, scale)
		end
	end
	for _, gui in playerGui:GetChildren() do
		attach(gui)
	end
	playerGui.ChildAdded:Connect(attach)

	local function update()
		local value = currentScale()
		for _, scale in scales do
			scale.Scale = value
		end
	end
	onViewportChanged(update)
	GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(update) -- cheap re-sync after Roblox menu / rotation
end

return UiKit

