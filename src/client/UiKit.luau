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
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local UiAssets = require(ReplicatedStorage.Shared.Config.UiAssets)

local UiKit = {}

-- GUI doc Bab 4.5: one table for every DisplayOrder. Controllers use these names, not raw numbers.
-- Panels still use 0 here until the Q-4 layer pass moves them to PANEL (40).
UiKit.LAYER = {
	WORLD = -1,
	ACTION = 10,
	HUD = 20,
	GUIDE = 30,
	PANEL = 40,
	COACH = 50,
	TOAST = 60,
	BANNER = 80,
	MODAL = 100,
	DIALOG = 120,
	FADE = 150,
	-- Added in Q-4 layer closure (Lampiran D #29): layers the GUI table does not name yet, each used by one file.
	WORLD_BACK = -2, -- GuideUI: under the world marks (WORLD -1), so the guide rings sit below land marks
	CUTSCENE = 110, -- T1Cutscene cover: above the HUD and the panels, below the dialog box (DIALOG 120)
	MENU = 200, -- start menu (GUI table "Menu awal 200+"): covers everything, including the HUD
	MENU_PANEL = 210, -- start-menu panel, above the start menu's own screen
	COVER = 250, -- loading / fade cover of the start menu, above the start menu panel
}

-- Every ScreenGui made by UiKit.panel, so other UI can ask "is a panel open?" (B-2 like button).
local panelGuis: { ScreenGui } = {}
function UiKit.anyPanelOpen(): boolean
	for _, gui in panelGuis do
		if gui.Enabled then
			return true
		end
	end
	return false
end

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
UiKit.FONT_BODY = Enum.Font.FredokaOne

-- GUI doc 4.1 colours (UI-1): colours that were written inline before. Use these, not Color3.fromRGB, in controllers.
UiKit.GOLD = Color3.fromRGB(255, 226, 120) -- ring tutorial, highlight, ready to claim
UiKit.GOLD_DEEP = Color3.fromRGB(240, 196, 92) -- coin numbers
UiKit.SHADE = Color3.fromRGB(30, 20, 10) -- panel backdrop, shadows
UiKit.INK_DARK = Color3.fromRGB(48, 32, 20) -- text on light cream
UiKit.LOCKED = Color3.fromRGB(150, 150, 150) -- locked node / slot
UiKit.WATER = Color3.fromRGB(46, 104, 128) -- fishing and pond elements

-- GUI doc 4.2 text sizes (one font, FredokaOne). Sizes 9 and 11 are banned; 13, 15, 17, 19, 20, 22 map to the nearest token.
UiKit.TEXT_DISPLAY = 36 -- banner titles, big numbers
UiKit.TEXT_TITLE = 21 -- panel ribbon title
UiKit.TEXT_HEADING = 18 -- section titles, large card names
UiKit.TEXT_BODY = 16 -- list rows, buttons
UiKit.TEXT_SMALL = 14 -- dialog text, descriptions
UiKit.TEXT_CAPTION = 12 -- sub-text, small labels (the lower limit)

-- GUI doc 4.3 radii (px). R_ROUND is "full round": any value at least half the shape's side.
UiKit.R_SM = 8 -- chips, badges
UiKit.R_MD = 14 -- buttons, cards, grid cells
UiKit.R_LG = 20 -- flat panels, large boxes
UiKit.R_ROUND = 999 -- plates, avatars, nodes

-- GUI doc 4.4 touch targets (UI-1). Tiers, not one global size:
--   TOUCH_CTA 40: the single main action on a screen (Panen Semua, Tingkatkan, Ambil Semua)
--   TOUCH 32: the standard tier: buttons in rows and cards, Next, dialog choices, tabs, steppers
--   TOUCH_ROW 32: one tappable row (quest tracker row, list row tap area)
--   TOUCH_MIN 24: the floor for small links and close icons (never smaller)
--   TOUCH_HUD 50: HUD pills that were already 50 (dock text buttons, column items); GUI doc 4.4 keeps HUD buttons as they are
UiKit.TOUCH = 32
UiKit.TOUCH_CTA = 40
UiKit.TOUCH_ROW = 32
UiKit.TOUCH_MIN = 24
UiKit.TOUCH_HUD = 50
UiKit.ROW_HEIGHT = 54
UiKit.ROW_ALT = Color3.fromRGB(246, 236, 210) -- the second cream of the zebra (rows alternate ROW / ROW_ALT)
-- Category colours (docs/UIUX_Spec.md): each kind of thing has ONE colour, used as the card's left stripe and badges.
UiKit.CAT = {
	crop = Color3.fromRGB(96, 150, 70), -- plants, seeds
	fish = Color3.fromRGB(60, 140, 176), -- fish, water
	tool = Color3.fromRGB(196, 100, 60), -- rods, upgrades, bait
	decor = Color3.fromRGB(158, 92, 120), -- decor, blueprints
	gold = Color3.fromRGB(240, 196, 92), -- money
}

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
	button.TextSize = UiKit.TEXT_HEADING -- was 19: nearest token (GUI doc 4.2)
	button.AutoButtonColor = true
	button.Size = UDim2.fromOffset(120, UiKit.TOUCH)
	button.Parent = parent
	button.Activated:Connect(function()
		Sfx.play("ui_click", nil, 0.05) -- every UiKit button clicks (SoundBank role, muted by Atur > Efek suara)
	end)

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
					overlay.TextYAlignment = button.TextYAlignment
				-- Inactive buttons (TextTransparency 0.45, set by UiKit.row) stay readable, only a little dimmer.
				local dim = if button.TextTransparency > 0 then 0.55 else 0
				overlay.TextTransparency = dim
				overlay.TextStrokeTransparency = 0.1 + dim * 1.1 -- the outline fades with the letters
			end
			mirror()
			for _, property in { "Text", "Font", "TextSize", "TextTransparency", "TextYAlignment" } do
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

-- Removes a panel that is no longer needed (Quest Log closes this way): it is not kept as an invisible instance.
-- Bug 7: one central hide / restore for the rest of the GUI while a banner shows (BannerController). Counter-based: two
-- banners that overlap keep the GUI hidden until the LAST one ends. Only the ScreenGuis that were ON are turned off, and only
-- those are turned back on, so a GUI that was already off stays off. A GUI created during the hide is not touched.
local hideCount = 0
local hiddenByUs: { [ScreenGui]: boolean } = {}

function UiKit.hideOthers(keep: ScreenGui?)
	hideCount += 1
	if hideCount > 1 then
		return
	end
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child ~= keep and child.Enabled then
			hiddenByUs[child] = true
			child.Enabled = false
		end
	end
end

function UiKit.restoreOthers()
	if hideCount == 0 then
		return
	end
	hideCount -= 1
	if hideCount > 0 then
		return
	end
	for gui in hiddenByUs do
		if gui.Parent and not gui.Enabled then
			gui.Enabled = true
		end
	end
	table.clear(hiddenByUs)
end

function UiKit.closePanel(gui: ScreenGui)
	for index, other in panelGuis do
		if other == gui then
			table.remove(panelGuis, index)
			break
		end
	end
	gui:Destroy()
end

function UiKit.panel(name: string, titleText: string, onClose: () -> ()): Panel
	local gui = Instance.new("ScreenGui")
	table.insert(panelGuis, gui)
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.DisplayOrder = UiKit.LAYER.PANEL -- above the HUD (20), below the coachmark, banner and dialog
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
	frame.Size = UDim2.new(0.88, 0, 0.86, 0)
	frame.Active = true -- swallow taps so they do not reach the backdrop
	frame.Parent = gui
	skinPanel(frame)

	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(600, 400)
	sizeLimit.Parent = frame

	-- Title ribbon. Flat green pill until the ribbon image has loaded.
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.AnchorPoint = Vector2.new(0.5, 0)
	ribbon.Position = UDim2.new(0.5, 0, 0, -12)
	ribbon.Size = UDim2.new(0.5, 0, 0, 44)
	ribbon.BackgroundColor3 = UiKit.HEADER
	ribbon.ZIndex = 2
	ribbon.Parent = frame
	corner(ribbon, 14)
	local ribbonStroke = stroke(ribbon, UiKit.HEADER_DARK, 3)
	local ribbonLimit = Instance.new("UISizeConstraint")
	ribbonLimit.MinSize = Vector2.new(190, 0)
	ribbonLimit.MaxSize = Vector2.new(320, 56)
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
	title.Size = UDim2.new(1, -90, 1, -10)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextColor3 = UiKit.CREAM
	title.Font = UiKit.FONT
	title.TextSize = 21
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = titleText
	title.ZIndex = 3
	title.TextStrokeColor3 = UiKit.HEADER_DARK
	title.TextStrokeTransparency = 0.2
	title.Parent = ribbon

	-- Round close badge: the ForgeGUI close image once loaded, else the flat/bamboo button below it.
	local close = UiKit.button(frame, "Close", "X", UiKit.TERRACOTTA)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -6, 0, -10)
	close.Size = UDim2.fromOffset(44, 44)
	close.TextSize = 20
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
	list.Position = UDim2.fromOffset(26, 40)
	list.Size = UDim2.new(1, -52, 1, -(40 + 22 + 38))
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = UiKit.BAMBOO_DARK
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.ElasticBehavior = Enum.ElasticBehavior.Always
	list.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.BackgroundTransparency = 1
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.new(0, 28, 1, -20)
	footer.Size = UDim2.new(1, -56, 0, 34)
	footer.Parent = frame

	local footerLabel = Instance.new("TextLabel")
	footerLabel.Name = "Info"
	footerLabel.Text = "" -- (a new TextLabel says "Label": it showed in the corner of every panel)
	footerLabel.BackgroundTransparency = 1
	footerLabel.Size = UDim2.new(0.55, 0, 1, 0)
	footerLabel.TextXAlignment = Enum.TextXAlignment.Left
	footerLabel.TextColor3 = UiKit.TEXT
	footerLabel.Font = UiKit.FONT
	footerLabel.TextSize = 14
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
	label.Size = UDim2.new(1, 0, 0, 24)
	label.AutomaticSize = Enum.AutomaticSize.Y -- a long line wraps and grows instead of being cut off
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = UiKit.HEADER_DARK
	label.Font = UiKit.FONT
	label.TextSize = 16
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
function UiKit.row(list: ScrollingFrame, order: number, text: string, subText: string?, buttonText: string?, enabled: boolean?, onClick: (() -> ())?, extraText: string?, onExtra: (() -> ())?, accent: Color3?): Frame
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.BackgroundColor3 = if order % 2 == 0 then UiKit.ROW_ALT else UiKit.ROW
	row.Size = UDim2.new(1, 0, 0, UiKit.ROW_HEIGHT)
	row.Parent = list
	corner(row, 10)
	stroke(row, Color3.fromRGB(222, 200, 154), 1.5)
	UiKit.accentStripe(row, accent or UiKit.BAMBOO)

	local hasButton = buttonText ~= nil
	local textInset = (if hasButton then 100 else 24) + (if extraText then 80 else 0)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(16, if subText then 7 else 0)
	label.Size = UDim2.new(1, -textInset, 0, if subText then 22 else UiKit.ROW_HEIGHT)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = if subText then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
	label.TextColor3 = UiKit.TEXT
	label.Font = UiKit.FONT
	label.TextSize = 16
	label.TextWrapped = false
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	label.Parent = row

	if subText then
		local sub = label:Clone()
		sub.Position = UDim2.fromOffset(16, 30)
		sub.Size = UDim2.new(1, -textInset, 0, 18)
		sub.Font = UiKit.FONT_BODY
		sub.TextSize = 12
		sub.TextColor3 = Color3.fromRGB(128, 100, 66)
		sub.Text = subText
		sub.Parent = row
	end

	if buttonText then
		local isEnabled = enabled ~= false
		local button = UiKit.button(row, "Action", buttonText, if isEnabled then UiKit.BUTTON else UiKit.BUTTON_MUTED)
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -8, 0.5, 0)
		button.Size = UDim2.fromOffset(82, 36)
		button.TextSize = 15
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
		extra.Position = UDim2.new(1, -96, 0.5, 0)
		extra.Size = UDim2.fromOffset(70, 36)
		extra.TextSize = 15
		if onExtra then
			extra.Activated:Connect(onExtra)
		end
	end
	return row
end

-- The coloured stripe on a card's left edge (the card's category, see UiKit.CAT).
function UiKit.accentStripe(card: GuiObject, color: Color3)
	local stripe = Instance.new("Frame")
	stripe.Name = "Accent"
	stripe.BackgroundColor3 = color
	stripe.BorderSizePixel = 0
	stripe.AnchorPoint = Vector2.new(0, 0.5)
	stripe.Position = UDim2.new(0, 5, 0.5, 0)
	stripe.Size = UDim2.new(0, 5, 1, -14)
	stripe.ZIndex = 2
	stripe.Parent = card
	corner(stripe, 3)
end

-- Price: a small dark pill with the coin and the amount in gold (the same look as the HUD's Koin). Red when it cannot be paid.
function UiKit.priceChip(parent: Instance, amountText: string, red: boolean?): Frame
	local chip = Instance.new("Frame")
	chip.Name = "PriceChip"
	chip.BackgroundColor3 = UiKit.DARK
	chip.Size = UDim2.fromOffset(0, 24)
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.Parent = parent
	corner(chip, 12)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 3)
	layout.Parent = chip
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 7), UDim.new(0, 8)
	pad.Parent = chip
	local coin = UiKit.icon(chip, "koin", 16)
	if coin then
		coin.LayoutOrder = 1
	end
	local label = Instance.new("TextLabel")
	label.LayoutOrder = 2
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 24)
	label.Font = UiKit.FONT
	label.TextSize = 14
	label.TextColor3 = if red then Color3.fromRGB(255, 130, 116) else UiKit.CAT.gold
	label.Text = amountText
	label.Parent = chip
	return chip
end

-- On/off switch: green with the knob on the right when on, grey with the knob on the left when off. Tapping flips it and runs
-- onToggle(newValue); the caller re-renders (the server owns the value).
function UiKit.switch(parent: Instance, on: boolean, onToggle: (value: boolean) -> ()): TextButton
	local track = Instance.new("TextButton")
	track.Name = "Switch"
	track.Text = ""
	track.AutoButtonColor = false
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -10, 0.5, 0)
	track.Size = UDim2.fromOffset(54, 28)
	track.BackgroundColor3 = if on then Color3.fromRGB(104, 164, 70) else Color3.fromRGB(176, 164, 144)
	track.Parent = parent
	corner(track, 14)
	stroke(track, if on then UiKit.HEADER_DARK else Color3.fromRGB(140, 126, 104), 2)
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Position = if on then UDim2.new(1, -25, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
	knob.Size = UDim2.fromOffset(22, 22)
	knob.BackgroundColor3 = UiKit.CREAM
	knob.Parent = track
	corner(knob, 11)
	track.Activated:Connect(function()
		on = not on
		track.BackgroundColor3 = if on then Color3.fromRGB(104, 164, 70) else Color3.fromRGB(176, 164, 144)
		TweenService:Create(knob, TweenInfo.new(0.12), { Position = if on then UDim2.new(1, -25, 0.5, 0) else UDim2.new(0, 3, 0.5, 0) }):Play()
		onToggle(on)
	end)
	return track
end

-- A grid of cells inside a panel list (the bag, the collection): `columns` cells per row, each cell `cellHeight` tall.
function UiKit.grid(list: ScrollingFrame, order: number, columns: number, cellHeight: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Grid"
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Parent = list
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(1 / columns, -6, 0, cellHeight)
	layout.CellPadding = UDim2.fromOffset(6, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	return frame
end

export type Cell = {
	name: string,
	sub: string?, -- small line under the name
	badge: string?, -- count in the top-right corner ("x3")
	accent: Color3?,
	cropId: string?, -- show this crop's 3D model as the picture
	icon: string?, -- else this icon key
	price: string?, -- shown as a price chip
	onClick: (() -> ())?,
}

-- One grid cell: coloured top edge, picture, name, count badge, optional price chip.
function UiKit.cell(grid: Instance, order: number, def: Cell): TextButton
	local cell = Instance.new("TextButton")
	cell.Name = "Cell"
	cell.LayoutOrder = order
	cell.Text = ""
	cell.AutoButtonColor = false
	cell.BackgroundColor3 = if order % 2 == 0 then UiKit.ROW_ALT else UiKit.ROW
	cell.Parent = grid
	corner(cell, 10)
	stroke(cell, Color3.fromRGB(222, 200, 154), 1.5)
	local top = Instance.new("Frame")
	top.Name = "Accent"
	top.BackgroundColor3 = def.accent or UiKit.BAMBOO
	top.BorderSizePixel = 0
	top.Position = UDim2.fromOffset(8, 0)
	top.Size = UDim2.new(1, -16, 0, 4)
	top.Parent = cell
	corner(top, 2)

	local picture = Instance.new("Frame")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1
	picture.AnchorPoint = Vector2.new(0.5, 0)
	picture.Position = UDim2.new(0.5, 0, 0, 7)
	picture.Size = UDim2.fromOffset(46, 46)
	picture.Parent = cell
	if not (def.cropId and UiKit.modelView(picture, def.cropId)) then
		local icon = UiKit.icon(picture, def.icon or "bibit", 40)
		if icon then
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.5)
		end
	end

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(4, 54)
	name.Size = UDim2.new(1, -8, 0, 16)
	name.Font = UiKit.FONT
	name.TextSize = 13
	name.TextColor3 = UiKit.TEXT
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = def.name
	name.Parent = cell

	if def.badge then
		local badge = Instance.new("TextLabel")
		badge.Name = "Badge"
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, -5, 0, 8)
		badge.Size = UDim2.fromOffset(0, 18)
		badge.AutomaticSize = Enum.AutomaticSize.X
		badge.BackgroundColor3 = def.accent or UiKit.BAMBOO
		badge.Font = UiKit.FONT
		badge.TextSize = 12
		badge.TextColor3 = UiKit.CREAM
		badge.Text = def.badge
		badge.ZIndex = 3
		badge.Parent = cell
		corner(badge, 9)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
		pad.Parent = badge
	end
	if def.price then
		local chip = UiKit.priceChip(cell, def.price)
		chip.AnchorPoint = Vector2.new(0.5, 1)
		chip.Position = UDim2.new(0.5, 0, 1, -4)
	elseif def.sub then
		local sub = name:Clone()
		sub.Position = UDim2.fromOffset(4, 70)
		sub.Size = UDim2.new(1, -8, 0, 14)
		sub.Font = UiKit.FONT_BODY
		sub.TextSize = 11
		sub.TextColor3 = Color3.fromRGB(128, 100, 66)
		sub.Text = def.sub
		sub.Parent = cell
	end
	if def.onClick then
		cell.Activated:Connect(def.onClick)
	end
	return cell
end

-- A crop's own 3D model in a ViewportFrame (ReplicatedStorage.CropModels.<id>, the same model that grows on the bed). Returns
-- false when there is no such model.
function UiKit.modelView(parent: Instance, cropId: string): boolean
	local models = ReplicatedStorage:FindFirstChild("CropModels")
	local template = models and models:FindFirstChild(cropId)
	if not template or not template:IsA("Model") then
		return false
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Model"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Color3.fromRGB(176, 172, 160)
	viewport.LightColor = Color3.fromRGB(255, 244, 222)
	viewport.LightDirection = Vector3.new(-0.6, -1.2, -0.7)
	viewport.Parent = parent
	local model = template:Clone()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	model.Parent = viewport
	local boxCFrame, boxSize = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	viewport.CurrentCamera = camera
	camera.Parent = viewport
	local distance = (boxSize.Magnitude / 2) / math.tan(math.rad(15)) * 1.02
	camera.CFrame = CFrame.lookAt(boxCFrame.Position + Vector3.new(0.42, 0.3, 1).Unit * distance, boxCFrame.Position)
	return true
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
		button.TextSize = 16
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
	frame.Size = UDim2.fromOffset(92, 32)
	frame.Parent = parent

	local current = math.clamp(value, minValue, maxValue)
	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.new(1, -64, 1, 0)
	label.TextColor3 = UiKit.TEXT
	label.Font = UiKit.FONT
	label.TextSize = 16
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
		button.Size = UDim2.fromOffset(32, 32)
		button.TextSize = 20
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
	corner(slot, 10)
	stroke(slot, Color3.fromRGB(214, 190, 140), 1.5)

	local picture = Instance.new("Frame")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, 0.5)
	picture.Size = UDim2.new(1, -6, 1, -6)
	picture.ZIndex = 2
	picture.Parent = slot
	-- A harvested crop (key "kangkung") or its seed ("seed_kangkung") shows the crop's own 3D model; else the picture / an icon.
	local cropId = if thumbKey then thumbKey:gsub("^seed_", "") else nil
	if cropId and UiKit.modelView(picture, cropId) then
		return slot
	end
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.ScaleType = Enum.ScaleType.Fit
	local real = if thumbKey then UiAssets.THUMBS[thumbKey] else nil
	if real and real ~= "" then
		image.Image = real
	else
		image.Image = UiKit.iconId(placeholderIcon or "")
	end
	image.Parent = picture
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
	accent: Color3?, -- the category stripe (UiKit.CAT)
}

-- One shop row: picture slot, name + detail, number picker, total, action button. The total is red when the player cannot
-- pay it. Picking a number only updates the row's own total and button (no rebuild, so holding + keeps repeating).
function UiKit.tradeRow(list: ScrollingFrame, order: number, def: TradeRow): Frame
	local row = Instance.new("Frame")
	row.Name = "TradeRow"
	row.LayoutOrder = order
	row.BackgroundColor3 = if order % 2 == 0 then UiKit.ROW_ALT else UiKit.ROW
	row.Size = UDim2.new(1, 0, 0, 58)
	row.Parent = list
	corner(row, 10)
	stroke(row, Color3.fromRGB(222, 200, 154), 1.5)
	UiKit.accentStripe(row, def.accent or UiKit.BAMBOO)

	local thumb = UiKit.thumb(row, 44, def.thumbKey, def.placeholderIcon)
	thumb.AnchorPoint = Vector2.new(0, 0.5)
	thumb.Position = UDim2.new(0, 16, 0.5, 0)

	-- Columns, right to left: action button | price chip | stepper. Name + detail take the rest.
	local RIGHT = 8 + 76 + 6 + 74 + 6 + (if def.pickQty and def.maxQty > 1 then 92 + 6 else 0)
	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(68, 8)
	label.Size = UDim2.new(1, -68 - RIGHT, 0, 20)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = UiKit.TEXT
	label.Font = UiKit.FONT
	label.TextSize = 15
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = def.name
	label.Parent = row
	if def.sub then
		local sub = label:Clone()
		sub.Name = "Sub"
		sub.Position = UDim2.fromOffset(68, 30)
		sub.Size = UDim2.new(1, -68 - RIGHT, 0, 22)
		sub.Font = UiKit.FONT_BODY
		sub.TextSize = 11
		sub.TextWrapped = true
		sub.TextColor3 = Color3.fromRGB(128, 100, 66)
		sub.Text = def.sub
		sub.Parent = row
	end

	local active = def.maxQty >= 1
	local qty = math.clamp(def.qty or 1, 1, math.max(def.maxQty, 1))

	local action = UiKit.button(row, "Action", if active then def.actionText else (def.disabledText or def.actionText), UiKit.BUTTON)
	action.AnchorPoint = Vector2.new(1, 0.5)
	action.Position = UDim2.new(1, -8, 0.5, 0)
	action.Size = UDim2.fromOffset(76, 36)
	action.TextSize = if not active and #(def.disabledText or "") > 6 then 11 else 15 -- "Kuota habis" must fit the button
	action.TextWrapped = true

	local priceHolder = Instance.new("Frame")
	priceHolder.Name = "Total"
	priceHolder.BackgroundTransparency = 1
	priceHolder.AnchorPoint = Vector2.new(1, 0.5)
	priceHolder.Position = UDim2.new(1, -8 - 76 - 6, 0.5, 0)
	priceHolder.Size = UDim2.fromOffset(74, 26)
	priceHolder.Parent = row

	local function refresh()
		local sum = if def.unitPrice then def.unitPrice * qty else nil
		local short = sum ~= nil and def.money ~= nil and sum > def.money
		priceHolder:ClearAllChildren()
		if sum and (active or def.money ~= nil) then -- selling: no total on a row you cannot sell from
			local chip = UiKit.priceChip(priceHolder, Locale.formatNumber(sum), short)
			chip.AnchorPoint = Vector2.new(1, 0.5)
			chip.Position = UDim2.fromScale(1, 0.5)
		end
		setButtonEnabled(action, active and not short)
	end
	refresh()

	if active and def.pickQty and def.maxQty > 1 then
		local stepper = UiKit.stepper(row, qty, 1, def.maxQty, function(n)
			qty = n
			refresh()
			if def.onQty then
				def.onQty(n)
			end
		end)
		stepper.AnchorPoint = Vector2.new(1, 0.5)
		stepper.Position = UDim2.new(1, -8 - 76 - 6 - 74 - 6, 0.5, 0)
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
	cancelText: string?, -- default "Batal" (left, red; the tutorial welcome uses "Lewati")
	confirmColor: Color3?, -- the right button's colour (default gold); the tutorial welcome uses solid green "Mulai"
	cancelMuted: boolean?, -- true = the left button is the secondary one: outlined, grey, smaller (tutorial "Lewati")
	canConfirm: boolean?, -- false greys Setuju out
	onConfirm: () -> (),
	onCancel: (() -> ())?,
	noCancel: boolean?, -- true = only the confirm button; a tap outside does nothing (the tutorial welcome uses it: no Lewati)
}

local confirmGui: ScreenGui? = nil
local confirmLimit: UISizeConstraint? = nil -- the box stays within 86% x 86% of the screen (UIUX_Spec)
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
	gui.DisplayOrder = UiKit.LAYER.MODAL -- above every panel
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local function cancel()
		local current = confirmCurrent
		if current and current.noCancel then
			return -- the modal only closes through its confirm button
		end
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
	confirmLimit = limit

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
	parts.no.Text = opts.cancelText or Locale.t("confirm.no")
	parts.yes.Text = opts.confirmText or Locale.t("confirm.yes")
	-- Primary / secondary: the main action is the solid one; a muted secondary is smaller and outlined.
	local muted = opts.cancelMuted == true
	-- The bamboo skin (gold) is shown for the standard buttons; a styled button hides it and shows its own flat colour.
	-- Every call sets the state again, so a styled modal never leaks its look into the next one.
	local function styleButton(button: TextButton, solid: Color3?, muted: boolean)
		local skin = button:FindFirstChild("Skin")
		local border = button:FindFirstChildOfClass("UIStroke")
		if skin and skin:IsA("ImageLabel") then
			skin.Visible = solid == nil and not muted
		end
		if solid then
			button.BackgroundTransparency = 0
			button.BackgroundColor3 = solid
		elseif muted then
			button.BackgroundTransparency = 0
			button.BackgroundColor3 = Color3.fromRGB(246, 238, 220) -- light cream, quieter than gold
		elseif skin then
			button.BackgroundTransparency = 1 -- the skin is the look
		end
		if border then
			border.Color = if muted then Color3.fromRGB(150, 140, 120) else border.Color
			border.Thickness = if muted then 2 else border.Thickness
		end
		if muted then
			-- No shadow behind the text: the secondary label is plain, one copy, not a doubled look.
			button.TextStrokeTransparency = 1
			button.TextTransparency = 0
		end
	end
	styleButton(parts.no, nil, muted)
	if muted then
		parts.no.BackgroundColor3 = Color3.fromRGB(246, 238, 220)
		parts.no.TextColor3 = UiKit.TEXT
	elseif not muted then
		parts.no.BackgroundColor3 = UiKit.RED
	end
	parts.no.Visible = opts.noCancel ~= true
	parts.no.Size = if muted then UDim2.new(0.36, -6, 1, 0) else UDim2.new(0.5, -6, 1, 0)
	parts.no.TextSize = if muted then 16 else 22
	setButtonEnabled(parts.yes, opts.canConfirm ~= false) -- enabled colour first (it resets BackgroundColor3)
	styleButton(parts.yes, opts.confirmColor, false) -- then the requested colour (Hapus Petak = brick red) wins
	parts.yes.Size = if opts.noCancel then UDim2.new(1, -12, 1, 0) elseif muted then UDim2.new(0.64, -6, 1, 0) else UDim2.new(0.5, -6, 1, 0)
	-- Fit the current screen (rotation included): max 86% of the width and 86% of the height, never the fixed 480.
	if confirmLimit then
		local view = (Workspace.CurrentCamera :: Camera).ViewportSize
		confirmLimit.MaxSize = Vector2.new(math.min(460, view.X * 0.86), view.Y * 0.86)
	end
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

-- Parchment chip for info lines (tutorial hint, feedback toast): the SAME chip as UiKit.pill (rounded ends, the parchment
-- skin image), with a flat parchment + bamboo border until the image has loaded. Use it on any existing frame.
function UiKit.parchmentBox(frame: GuiObject, _radius: number?)
	frame.BackgroundColor3 = UiKit.BG
	frame.BackgroundTransparency = 0
	corner(frame, 22)
	local chipBorder = stroke(frame, UiKit.BAMBOO, 3)
	attachSkin(frame, CHIP, function()
		frame.BackgroundTransparency = 1
		chipBorder.Enabled = false
		local round = frame:FindFirstChildOfClass("UICorner")
		if round then
			round:Destroy()
		end
	end)
end
-- Parchment box for info lines (tutorial hint, feedback toast): cream parchment, bamboo border, dark brown ink.

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
	KolamButton = "kolam",
	RewardButton = "bintang", -- Hadiah (kalender + peti main)
}

-- Where each button lives (thumb-friendly layout, no captions: the icons speak, a tooltip names them on hover):
--   DOCK = the things you use all the time: a row at the bottom center, between the thumbstick and the jump button.
--          Big (58 px) round icon buttons.
--   everything else = a vertical column at the top right (Warga, Toko, Atur, Koleksi). On phones it collapses behind a
--   round menu button and slides open downward.
local DOCK_ORDER = { GarapButton = 1, KolamButton = 2, DecorButton = 3, BagButton = 4, OrdersButton = 5 }
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
	layout.Padding = UDim.new(0, 6) -- dock gap 6 px (phones and desktop alike)
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

-- The round bamboo plate every round button uses (parchment + bamboo ring, ForgeGUI plate image). Public so floating
-- buttons (e.g. the land "+") look like the rest of the HUD. `parent` should be a button sized `size` square.
function UiKit.plate(parent: GuiObject, size: number, iconKey: string?): Frame
	return makePlate(parent, size, iconKey)
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

-- Menu buttons have no hover tooltip any more (only the buff icons show a tip, on click); kept so callers stay as they are.
local function attachTip(_hud: Instance, _button: GuiButton, _above: boolean) end

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
			-- The column is MENU_SIZE wide: a text button in it must not be wider, or its edge hides under the round buttons
			-- (owner 2026-11-22: "Acara", "Skill", "Dapur" were cut). Dock text buttons keep their own width.
			item.Size = if dock then UDim2.fromOffset(90, UiKit.TOUCH_HUD) else UDim2.fromOffset(MENU_SIZE, UiKit.TOUCH_HUD)
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
				Sfx.play("ui_click", nil, 0.05)
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

-- Foundation for the R3 screens (17.0): product card, progress dots, notification dot, reward popup ---------------

export type ProductDef = {
	progress: { count: number, filled: number }?, -- optional dots under the title (upgrade tiers)
	title: string,
	sub: string?,
	price: string?,
	buttonText: string,
	enabled: boolean?,
	onClick: (() -> ())?,
	thumbKey: string?,
	placeholderIcon: string?,
	accent: Color3?,
}

-- A shop card for one product: a thumb on the left, title + sub-line + price, and a buy button on the right. Same
-- bamboo card as the list rows. Returns the card so the caller can set LayoutOrder.
function UiKit.productCard(list: Instance, order: number, def: ProductDef): Frame
	local card = Instance.new("Frame")
	card.Name = `Product_{def.title}`
	card.LayoutOrder = order
	card.BackgroundColor3 = if order % 2 == 0 then UiKit.ROW_ALT else UiKit.ROW
	card.Size = UDim2.new(1, 0, 0, 64)
	card.Parent = list
	corner(card, 10)
	stroke(card, Color3.fromRGB(222, 200, 154), 1.5)
	UiKit.accentStripe(card, def.accent or UiKit.CAT.tool)

	local thumb = UiKit.thumb(card, 48, def.thumbKey, def.placeholderIcon)
	thumb.AnchorPoint = Vector2.new(0, 0.5)
	thumb.Position = UDim2.new(0, 16, 0.5, 0)

	local RIGHT = 8 + 92 + 6 + 84
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(72, 6)
	title.Size = UDim2.new(1, -72 - RIGHT, 0, 20)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = UiKit.TEXT
	title.Font = UiKit.FONT
	title.TextSize = 15
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = def.title
	title.Parent = card

	local sub = title:Clone()
	sub.Name = "Sub"
	sub.Position = UDim2.fromOffset(72, 27)
	sub.Size = UDim2.new(1, -72 - RIGHT, 0, 16)
	sub.Font = UiKit.FONT_BODY
	sub.TextSize = 11
	sub.TextColor3 = Color3.fromRGB(128, 100, 66)
	sub.Text = def.sub or ""
	sub.Parent = card

	if def.progress then
		local dots = UiKit.progressDots(card, def.progress.count, def.progress.filled, 9)
		dots.Position = UDim2.fromOffset(72, 46)
	end

	local isEnabled = def.enabled ~= false
	local button = UiKit.button(card, "Action", def.buttonText, if isEnabled then UiKit.BUTTON else UiKit.BUTTON_MUTED)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -8, 0.5, 0)
	button.Size = UDim2.fromOffset(84, 36)
	button.TextSize = if #def.buttonText > 7 then 12 else 15
	button.TextTransparency = if isEnabled then 0 else 0.45

	if def.price then
		local priceHolder = Instance.new("Frame")
		priceHolder.BackgroundTransparency = 1
		priceHolder.AnchorPoint = Vector2.new(1, 0.5)
		priceHolder.Position = UDim2.new(1, -8 - 84 - 6, 0.5, 0)
		priceHolder.Size = UDim2.fromOffset(92, 26)
		priceHolder.Parent = card
		local chip = UiKit.priceChip(priceHolder, def.price)
		chip.AnchorPoint = Vector2.new(1, 0.5)
		chip.Position = UDim2.fromScale(1, 0.5)
	end
	if def.onClick then
		local onClick = def.onClick
		button.Activated:Connect(function()
			if isEnabled then
				onClick()
			end
		end)
	end
	return card
end

-- A row of small dots: `filled` of `count` are green (done), the rest tan. Used for upgrade levels and reward progress.
function UiKit.progressDots(parent: Instance, count: number, filled: number, size: number?): Frame
	local dot = size or 14
	local gap = 6
	local frame = Instance.new("Frame")
	frame.Name = "Dots"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(count * dot + (count - 1) * gap, dot)
	frame.Parent = parent
	for i = 1, count do
		local on = i <= filled
		local d = Instance.new("Frame")
		d.Name = `Dot{i}`
		d.Position = UDim2.fromOffset((i - 1) * (dot + gap), 0)
		d.Size = UDim2.fromOffset(dot, dot)
		d.BackgroundColor3 = if on then UiKit.BUTTON else UiKit.BUTTON_MUTED
		d.Parent = frame
		corner(d, dot)
		stroke(d, if on then UiKit.HEADER_DARK else Color3.fromRGB(170, 150, 118), 2)
	end
	return frame
end

-- A red badge with a count on the top-right corner of `target` ("something new here"). Calling it again updates the
-- count; a count of 0 hides it. Returns the badge.
function UiKit.notifyDot(target: GuiObject, count: number): Frame
	local badge = target:FindFirstChild("NotifyDot") :: Frame?
	if not badge then
		badge = Instance.new("Frame")
		badge.Name = "NotifyDot"
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, 4, 0, -4)
		badge.Size = UDim2.fromOffset(22, 22)
		badge.BackgroundColor3 = UiKit.RED
		badge.ZIndex = 8
		badge.Parent = target
		corner(badge, 11)
		stroke(badge, Color3.fromRGB(255, 240, 220), 2)
		local text = Instance.new("TextLabel")
		text.Name = "Count"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = UiKit.FONT
		text.TextSize = 14
		text.TextColor3 = UiKit.CREAM
		text.ZIndex = 9
		text.Parent = badge
	end
	local shown = count > 0
	badge.Visible = shown
	local label = badge:FindFirstChild("Count") :: TextLabel?
	if label then
		label.Text = if count > 99 then "99+" else tostring(count)
	end
	return badge
end

-- A short reward toast in the middle of the screen: a cream chip with the text, floats up and goes (~1.7 s).
-- Fails quietly when there is no player GUI yet.
function UiKit.rewardPopup(text: string)
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	local gui = playerGui:FindFirstChild("RewardPopups")
	if not gui or not gui:IsA("ScreenGui") then
		gui = Instance.new("ScreenGui")
		gui.Name = "RewardPopups"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = UiKit.LAYER.TOAST -- reward popups (GUI doc 4.5: Toast & hadiah)
		gui.Parent = playerGui
	end
	local chip = UiKit.pill(gui :: ScreenGui, "Reward", 260, 56)
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.Position = UDim2.fromScale(0.5, 0.42)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -24, 1, 0)
	label.Position = UDim2.fromOffset(12, 0)
	label.ZIndex = 2
	label.Font = UiKit.FONT
	label.TextSize = 20
	label.TextColor3 = UiKit.TEXT
	label.Text = text
	label.Parent = chip
	local info = TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(chip, info, { Position = UDim2.fromScale(0.5, 0.34) }):Play()
	task.delay(1.7, function()
		chip:Destroy()
	end)
end

-- Responsive scale-------------------------------------------------------------------------------
-- Phones keep scale 1 (44 px targets are already comfortable); big screens scale the UI up so it doesn't look tiny.

local function currentScale(): number
	local camera = Workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	-- Small landscape phones (844x390, width < 900 or height < 450): the whole GUI at 0.75 so the land stays dominant.
	-- Dock icons 58 -> ~44 px, coin bar 42 -> ~32 px, menu buttons 50 -> ~38 px. Desktop and tablets keep the old rule.
	if view.X < 900 or view.Y < 450 then
		return 0.75
	end
	return math.clamp(view.Y / 560, 1, 1.35)
end

function UiKit.autoScale()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local scales: { UIScale } = {}

	local function attach(gui: Instance)
		-- Roblox's own touch controls (the thumbstick and the jump button) live in "TouchGui". Leave them alone:
		-- no UIScale, no ZIndex or safe-inset change, otherwise the jump button shrinks on a phone.
		if gui.Name == "TouchGui" then
			return
		end
		if gui:IsA("ScreenGui") then
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- skins (ZIndex 0) must sit above their parent but below its text overlay
		end
		if gui:IsA("ScreenGui") then
			-- the phone's own safe area (notch, rounded corners): nothing is drawn under the cut-out
			gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
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

