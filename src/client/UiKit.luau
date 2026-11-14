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
UiKit.CREAM = Color3.fromRGB(255, 248, 232)

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
	local flatText = if base == UiKit.BUTTON or base == UiKit.TERRACOTTA then UiKit.CREAM else Color3.fromRGB(120, 104, 80)
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

-- Where each button lives (thumb-friendly layout):
--   DOCK = the things you use all the time, a vertical column on the right edge, centered, clear of the jump button
--          at the bottom right and of the top bar. Big (64 px) icon buttons.
--   everything else = the small top-right row (secondary: Warga, Toko, Koleksi, Atur).
local DOCK_ORDER = { GarapButton = 1, DecorButton = 2, BagButton = 3, OrdersButton = 4 }

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

-- Phone portrait (narrow): the secondary row wraps into a 2-wide grid at the top right, and the dock is a column on the
-- right edge. Landscape / tablet: the secondary row is one line, the dock is a row at the bottom center, between the
-- thumbstick and the jump button. Re-laid out whenever the viewport changes.
local function relayoutBar(bar: Frame, layout: UIListLayout, dock: boolean)
	local camera = Workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else Vector2.new(800, 400)
	local portrait = size.X < size.Y * 1.1
	if dock then
		if portrait then
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
	else
		bar.AnchorPoint = Vector2.new(1, 0)
		bar.Position = UDim2.new(1, -8, 0, 8)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.Wraps = true
		bar.AutomaticSize = Enum.AutomaticSize.Y
		bar.Size = UDim2.fromOffset(if portrait then 144 else 290, 0)
	end
end

local function barOf(hud: Instance, dock: boolean): Frame
	local name = if dock then "DockBar" else "MenuBar"
	local existing = hud:FindFirstChild(name)
	if existing and existing:IsA("Frame") then
		return existing
	end
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.BackgroundTransparency = 1
	bar.AutomaticSize = Enum.AutomaticSize.XY
	bar.Size = UDim2.new(0, 0, 0, 0)
	bar.Parent = hud

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = bar

	onViewportChanged(function()
		relayoutBar(bar, layout, dock)
	end)
	return bar
end

-- Changes the label of a menu button made by menuItem (icon mode: the caption under the icon; flat mode: its text).
function UiKit.setMenuLabel(button: GuiButton, text: string)
	local caption = button:FindFirstChild("Caption")
	if caption and caption:IsA("TextLabel") then
		caption.Text = text
	elseif button:IsA("TextButton") then
		button.Text = text
	end
end

-- Adds/places a HUD button by name (your designed one if it exists, else an icon button in the dock or the top row).
-- Icon buttons show an icon plate + a small caption; flat pills (until the icon loads) show only the text.
function UiKit.menuItem(hud: Instance, name: string, text: string, slot: number): GuiButton?
	local button = hud:FindFirstChild(name, true)
	if not button then
		local iconKey = MENU_ICON[name]
		local dock = DOCK_ORDER[name] ~= nil
		local hasIcon = iconKey ~= nil and UiKit.iconId(iconKey) ~= ""
		local plateSize = if dock then 58 else 48
		local item = Instance.new("TextButton")
		item.Name = name
		item.Text = ""
		item.AutoButtonColor = false
		item.LayoutOrder = if dock then DOCK_ORDER[name] else -slot
		item.Parent = barOf(hud, dock)
		if hasIcon then
			item.BackgroundTransparency = 1
			item.Size = UDim2.fromOffset(plateSize + 10, plateSize + 18)
			local plate = Instance.new("Frame")
			plate.Name = "Plate"
			plate.BackgroundColor3 = UiKit.BG
			plate.Size = UDim2.fromOffset(plateSize, plateSize)
			plate.Position = UDim2.fromOffset(5, 0)
			plate.Parent = item
			corner(plate, plateSize / 2)
			local plateBorder = stroke(plate, UiKit.BAMBOO, 3)
			attachSkin(plate, PLATE, function()
				plate.BackgroundTransparency = 1
				plateBorder.Enabled = false
				local round = plate:FindFirstChildOfClass("UICorner")
				if round then
					round:Destroy()
				end
			end, true)
			local icon = UiKit.icon(plate, iconKey :: string, plateSize - 14)
			if icon then
				icon.ZIndex = 2
				icon.Position = UDim2.fromOffset(7, 7)
			end
			local label = Instance.new("TextLabel")
			label.Name = "Caption"
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromOffset(0, plateSize)
			label.Size = UDim2.new(1, 0, 0, 16)
			label.Font = UiKit.FONT
			label.TextSize = 12
			label.TextColor3 = UiKit.CREAM
			label.Text = text
			label.Parent = item
			stroke(label, Color3.fromRGB(60, 38, 22), 1.2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
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
