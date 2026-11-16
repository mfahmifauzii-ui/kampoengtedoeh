--!strict
-- Loading screen -> Play screen -> PLAY (client only). It is the first thing on screen: nothing of the game UI shows before it.
--
--   * Background (both screens): an eagle-eye camera orbits the middle of the map slowly, behind a depth-of-field blur.
--   * Loading screen: the logo, the bamboo loading bar (a green fill that really follows the load: UI images, the state
--     snapshot, the character and plot, the streamed map), and "Loading...". No buttons, no Koin / Bunga chips.
--   * Play screen: the logo, the PLAY button (the text PLAY, not an icon), and the round wooden Pengaturan button bottom right.
--     Nothing else. Pengaturan = music (slider + switch), SFX (slider + switch), picture quality (Rendah / Sedang / Tinggi), all
--     saved with the profile (SettingsService) and applied at once.
--   * PLAY: 0.5 s fade to black, then either the intro cutscene of a new player (T1Ghost) or the game.
--
-- Hand-off with T1Ghost.client: the player attribute KTMenu is "loading" -> "play" -> "done" ("done" = the black fade is over
-- and the game's own screens are back). KTIntroRunning (set by T1Ghost) means the intro takes over from here: this script then
-- leaves the controls locked and the screens to it. Components are UiKit's (button, plate, switch, tabs, panel): no new style.

local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local RS = ReplicatedStorage
local UiAssets = require(RS.Shared.Config.UiAssets)
local Locale = require(RS.Shared.Locale)
local Net = require(RS.Shared.Modules.Net)
local State = require(script.Parent:WaitForChild("State"))
local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any

local player = Players.LocalPlayer

-- Background camera and blur
local ORBIT_CENTER = Vector3.new(0, 6, 0) -- the middle of the map (the town)
local ORBIT_RADIUS, ORBIT_HEIGHT, ORBIT_SPEED, ORBIT_FOV = 190, 95, 0.03, 55 -- one lap takes ~3.5 minutes
local BLUR_FOCUS, BLUR_RADIUS, BLUR_FAR = 12, 0, 1 -- very strong: nothing is in focus from up there (16 Nov: "blur banget")
-- DepthOfFieldEffect is not drawn on many phones (low picture quality), so a plain BlurEffect goes with it: that one is drawn
-- everywhere. It blurs the 3D map only, never the menu's own screens.
local BLUR_FULL_SIZE = 20

-- Loading
local MIN_LOAD_SECONDS = 6 -- the bar never finishes faster than this (slower on purpose: the real load is shown, not a fake one)
local FADE_SECONDS = 0.5 -- loading -> play crossfade
local BLACK_SECONDS = 0.5 -- PLAY -> black

local LOGO_BOX = Vector2.new(0.6, 0.46) -- the logo fits inside this share of the screen
local BAR_BOX = Vector2.new(0.47, 0.1) -- same length as before, shorter height (the picture is stretched to this box) -- smaller bar: the picture fits inside this share of the screen
local BAR_HOLLOW = { x0 = 0.034, x1 = 0.967, y0 = 0.08, y1 = 0.92 } -- the bar picture's hollow (a little inside the rails)

-- The screens that stay while the menu is up
local KEEP: { [string]: boolean } = { KTMenu = true, KTSettings = true, KTMenuCover = true, T1Cutscene = true }

local playerGui = player:WaitForChild("PlayerGui")
player:SetAttribute("KTMenu", "loading")

-- Hiding the game and Roblox's own screens ---------------------------------------------------------------------------

local hidden: { ScreenGui } = {}
local hiding = true

-- A screen the game turns on while the menu is up (an arrow, a coachmark, the HUD) is switched off again at once, not on the
-- next 0.2 s sweep, and comes back with the rest in showGame.
local watched: { [ScreenGui]: boolean } = {}
local function watch(gui: ScreenGui)
	if watched[gui] then
		return
	end
	watched[gui] = true
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if hiding and gui.Enabled and not KEEP[gui.Name] then
			gui.Enabled = false
			if not table.find(hidden, gui) then
				table.insert(hidden, gui)
			end
		end
	end)
end

local function hideGame()
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and not KEEP[gui.Name] then
			watch(gui)
			if gui.Enabled then
				gui.Enabled = false
				if not table.find(hidden, gui) then
					table.insert(hidden, gui)
				end
			end
		end
	end
end

local function setCore(visible: boolean)
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, visible)
			StarterGui:SetCore("TopbarEnabled", visible)
		end)
		if ok then
			return
		end
		task.wait(0.3)
	end
end

local function showGame()
	hiding = false
	for _, gui in hidden do
		if gui.Parent then
			gui.Enabled = true
		end
	end
	hidden = {}
	setCore(true) -- the chat comes back with the rest of Roblox's screens (the tutorial no longer locks it)
end

task.spawn(setCore, false)
hideGame()
task.spawn(function()
	while hiding do
		hideGame()
		task.wait(0.2)
	end
end)

-- The player cannot walk around behind the menu.
local controls: any = nil
task.spawn(function()
	local ok, found = pcall(function()
		local scripts = player:WaitForChild("PlayerScripts", 10)
		local module = scripts and scripts:WaitForChild("PlayerModule", 10)
		return if module then (require(module :: ModuleScript) :: any):GetControls() else nil
	end)
	if ok and found and hiding then
		controls = found
		pcall(function()
			controls:Disable()
		end)
	end
end)

-- Picture quality (saved: settings.quality 1 Rendah, 2 Sedang, 3 Tinggi) ------------------------------------------------

local appliedQuality = 0
local function applyQuality(level: number)
	if level == appliedQuality or level < 1 or level > 3 then
		return
	end
	appliedQuality = level
	pcall(function()
		Lighting.GlobalShadows = level >= 3
	end)
	local engineLevel = if level == 1 then 1 elseif level == 2 then 5 else 10
	pcall(function()
		local rendering = (settings() :: any).Rendering
		rendering.QualityLevel = engineLevel
	end)
end

-- The orbit camera and its blur -----------------------------------------------------------------------------------------

local camera = Workspace.CurrentCamera :: Camera
local orbitAngle = math.random() * math.pi * 2
local blur = Instance.new("DepthOfFieldEffect")
blur.Name = "KTMenuBlur"
blur.FocusDistance = BLUR_FOCUS
blur.InFocusRadius = BLUR_RADIUS
blur.NearIntensity = 0
blur.FarIntensity = BLUR_FAR
blur.Parent = Lighting
local blurFull = Instance.new("BlurEffect")
blurFull.Name = "KTMenuBlurFull"
blurFull.Size = BLUR_FULL_SIZE
blurFull.Parent = Lighting

RunService:BindToRenderStep("KTMenuCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	orbitAngle += ORBIT_SPEED * dt
	camera = Workspace.CurrentCamera :: Camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = ORBIT_FOV
	local eye = ORBIT_CENTER
		+ Vector3.new(math.cos(orbitAngle) * ORBIT_RADIUS, ORBIT_HEIGHT, math.sin(orbitAngle) * ORBIT_RADIUS)
	camera.CFrame = CFrame.lookAt(eye, ORBIT_CENTER)
end)

-- Streaming is on: ask for the part of the map the camera is looking at (and keep asking as it goes round).
local streamed = false
task.spawn(function()
	while hiding do
		local eye = ORBIT_CENTER
			+ Vector3.new(math.cos(orbitAngle) * ORBIT_RADIUS * 0.5, 0, math.sin(orbitAngle) * ORBIT_RADIUS * 0.5)
		-- Counts as loaded only when the streaming request really returned (not when it was just asked for).
		local ok = pcall(function()
			player:RequestStreamAroundAsync(eye, 6)
		end)
		if ok then
			streamed = true
		end
		task.wait(4)
	end
end)

-- The screen --------------------------------------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "KTMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 200
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- A picture of a known aspect, kept inside `box` (a share of the screen) and centred at `center`.
local function pictureHolder(parent: Instance, name: string, aspect: number, box: Vector2, center: Vector2): Frame
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(center.X, center.Y)
	holder.Size = UDim2.fromScale(box.X, box.Y)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = aspect
	ratio.AspectType = Enum.AspectType.FitWithinMaxSize
	ratio.Parent = holder
	return holder
end

local function image(parent: Instance, id: string, name: string): ImageLabel
	local picture = Instance.new("ImageLabel")
	picture.Name = name
	picture.BackgroundTransparency = 1
	picture.Size = UDim2.fromScale(1, 1)
	picture.Image = id
	picture.ScaleType = Enum.ScaleType.Fit
	picture.Parent = parent
	return picture
end

-- Loading background: the town picture, drawn over the orbit camera. It is removed when the Play screen appears, so the
-- eagle-eye camera shows (blurred) behind the Play button. Empty id = no picture (the camera shows through).
local loadingBackdrop: ImageLabel? = nil
if UiAssets.LOADING_BG.image ~= "" then
	loadingBackdrop = Instance.new("ImageLabel")
	loadingBackdrop.Name = "LoadingBackdrop"
	loadingBackdrop.BackgroundTransparency = 1
	loadingBackdrop.Size = UDim2.fromScale(1, 1)
	loadingBackdrop.Image = UiAssets.LOADING_BG.image
	loadingBackdrop.ScaleType = Enum.ScaleType.Crop
	loadingBackdrop.Parent = gui
end

-- Logo (stays through both screens).
local logoHolder = pictureHolder(gui, "Logo", UiAssets.LOGO.aspect, LOGO_BOX, Vector2.new(0.5, 0.27))
logoHolder.Position = UDim2.new(0.5, 0, 0.27, 20) -- 20 px lower than the scale centre (Play screen layout)
image(logoHolder, UiAssets.LOGO.image, "Picture")

-- Loading group: the bar and "Loading...".
local loadingGroup = Instance.new("CanvasGroup")
loadingGroup.Name = "Loading"
loadingGroup.BackgroundTransparency = 1
loadingGroup.Size = UDim2.fromScale(1, 1)
loadingGroup.Parent = gui

local barHolder = pictureHolder(loadingGroup, "Bar", UiAssets.LOADING_BAR.aspect, BAR_BOX, Vector2.new(0.5, 0.7))
barHolder:FindFirstChildOfClass("UIAspectRatioConstraint"):Destroy() -- keep the length; the height is the box's own
local fill = Instance.new("Frame") -- behind the frame picture: the bamboo covers its edges
fill.Name = "Fill"
fill.Position = UDim2.fromScale(BAR_HOLLOW.x0, BAR_HOLLOW.y0)
fill.Size = UDim2.fromScale(0, BAR_HOLLOW.y1 - BAR_HOLLOW.y0)
fill.BackgroundColor3 = UiKit.HEADER -- leaf green #609646 (the ribbon's green)
fill.BorderSizePixel = 0
fill.ZIndex = 1
fill.ClipsDescendants = true
fill.Parent = barHolder
local fillRound = Instance.new("UICorner")
fillRound.CornerRadius = UDim.new(0, 4)
fillRound.Parent = fill
-- Glossy: a vertical leaf-green gradient (light top, deeper bottom) plus a soft white sheen over the top half.
local fillShade = Instance.new("UIGradient")
fillShade.Rotation = 90
fillShade.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 236, 130)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(104, 168, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 106, 36)),
})
fillShade.Parent = fill
local gloss = Instance.new("Frame")
gloss.Name = "Gloss"
gloss.Size = UDim2.fromScale(1, 0.5)
gloss.BackgroundColor3 = Color3.new(1, 1, 1)
gloss.BackgroundTransparency = 0.25
gloss.BorderSizePixel = 0
gloss.ZIndex = 2
gloss.Parent = fill
local glossRound = Instance.new("UICorner")
glossRound.CornerRadius = UDim.new(0, 4)
glossRound.Parent = gloss
local glossFade = Instance.new("UIGradient")
glossFade.Rotation = 90
glossFade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
glossFade.Parent = gloss
local frame = image(barHolder, UiAssets.LOADING_BAR.image, "Frame")
frame.ZIndex = 2
frame.ScaleType = Enum.ScaleType.Stretch -- fills the shorter box edge to edge

-- "Loading..." on a dark bamboo chip: cream text, no outline (UiKit's toast look).
local chip = Instance.new("Frame")
chip.Name = "LoadingChip"
chip.AnchorPoint = Vector2.new(0.5, 0.5)
chip.Position = UDim2.fromScale(0.5, 0.88)
chip.Size = UDim2.fromOffset(0, 0)
chip.AutomaticSize = Enum.AutomaticSize.XY
chip.BackgroundColor3 = UiKit.DARK
chip.BackgroundTransparency = 1
chip.Visible = false -- no brown frame and no "Loading..." words: the bar alone says it
chip.Parent = loadingGroup
local chipRound = Instance.new("UICorner")
chipRound.CornerRadius = UDim.new(0, 12)
chipRound.Parent = chip
local chipEdge = Instance.new("UIStroke")
chipEdge.Color = UiKit.BAMBOO
chipEdge.Thickness = 2
chipEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
chipEdge.Enabled = false
chipEdge.Parent = chip
local chipPad = Instance.new("UIPadding")
chipPad.PaddingLeft, chipPad.PaddingRight = UDim.new(0, 18), UDim.new(0, 18)
chipPad.PaddingTop, chipPad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
chipPad.Parent = chip
local chipText = Instance.new("TextLabel")
chipText.BackgroundTransparency = 1
chipText.Size = UDim2.fromOffset(0, 0)
chipText.AutomaticSize = Enum.AutomaticSize.XY
chipText.Font = UiKit.FONT
chipText.TextSize = 18
chipText.TextColor3 = UiKit.CREAM
chipText.TextStrokeColor3 = Color3.fromRGB(70, 40, 14) -- readable on the blurred map without a frame
chipText.TextStrokeTransparency = 0.2
chipText.Text = Locale.t("menu.loading")
chipText.Parent = chip

-- Play group: PLAY and Pengaturan. Nothing else.
local playGroup = Instance.new("CanvasGroup")
playGroup.Name = "Play"
playGroup.BackgroundTransparency = 1
playGroup.Size = UDim2.fromScale(1, 1)
playGroup.GroupTransparency = 1
playGroup.Visible = false
playGroup.Parent = gui

-- The word PLAY (not an icon) goes through UiKit.button's own caption: cream letters with the same dark outline as every button.
local playButton = UiKit.button(playGroup, "PlayButton", Locale.t("menu.play"), UiKit.BUTTON) :: TextButton
playButton.AnchorPoint = Vector2.new(0.5, 0.5)
playButton.Position = UDim2.fromScale(0.5, 0.7) -- gap to the logo: 20 px less than when the logo moved down (Play screen layout)
playButton.Size = UDim2.fromOffset(270, 68)
playButton.TextSize = 36

local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Text = ""
settingsButton.AutoButtonColor = false
settingsButton.BackgroundTransparency = 1
settingsButton.AnchorPoint = Vector2.new(1, 1)
settingsButton.Position = UDim2.new(1, -16, 1, -16)
settingsButton.Size = UDim2.fromOffset(58, 58)
settingsButton.Parent = playGroup
UiKit.plate(settingsButton, 58, "atur") -- the same round wooden plate + gear as the HUD's Atur

-- Pengaturan popup (UiKit.panel) ------------------------------------------------------------------------------------------

local panel = UiKit.panel("KTSettings", Locale.t("menu.settings_title"), function() end)
panel.gui.DisplayOrder = 210
local panelFrame = panel.gui:FindFirstChild("Panel") :: Frame

local function rowCard(order: number, labelText: string, height: number): Frame
	local card = Instance.new("Frame")
	card.Name = `Row{order}`
	card.LayoutOrder = order
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = if order % 2 == 0 then UiKit.ROW_ALT else UiKit.ROW
	card.Parent = panel.list
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 10)
	round.Parent = card
	local line = Instance.new("UIStroke")
	line.Color = Color3.fromRGB(222, 200, 154)
	line.Thickness = 1.5
	line.Parent = card
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(16, if height > 60 then 6 else 0)
	label.Size = UDim2.new(0.4, 0, 0, if height > 60 then 26 else height)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = UiKit.FONT
	label.TextSize = 15
	label.TextColor3 = UiKit.TEXT
	label.Text = labelText
	label.Parent = card
	return card
end

-- A slider in the panel's own colours (the track tan, the fill leaf green, the knob cream with a bamboo ring). `onChange` runs
-- while dragging; `onCommit` when the finger / mouse is let go.
local function slider(parent: GuiObject, value: number, onChange: (number) -> (), onCommit: (number) -> ())
	local holder = Instance.new("Frame")
	holder.Name = "Slider"
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Position = UDim2.new(1, -84, 0.5, 0)
	holder.Size = UDim2.fromOffset(170, 40)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.Position = UDim2.new(0, 0, 0.5, 0)
	track.Size = UDim2.new(1, 0, 0, 10)
	track.BackgroundColor3 = Color3.fromRGB(214, 196, 160)
	track.Parent = holder
	local trackRound = Instance.new("UICorner")
	trackRound.CornerRadius = UDim.new(0, 5)
	trackRound.Parent = track
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(value, 1)
	bar.BackgroundColor3 = UiKit.HEADER
	bar.Parent = track
	local barRound = Instance.new("UICorner")
	barRound.CornerRadius = UDim.new(0, 5)
	barRound.Parent = bar
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.fromScale(value, 0.5)
	knob.Size = UDim2.fromOffset(26, 26)
	knob.BackgroundColor3 = UiKit.CREAM
	knob.ZIndex = 3
	knob.Parent = track
	local knobRound = Instance.new("UICorner")
	knobRound.CornerRadius = UDim.new(0.5, 0)
	knobRound.Parent = knob
	local knobRing = Instance.new("UIStroke")
	knobRing.Color = UiKit.BAMBOO
	knobRing.Thickness = 2.5
	knobRing.Parent = knob
	local hit = Instance.new("TextButton") -- a 44 px tall touch target
	hit.Name = "Hit"
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.AutoButtonColor = false
	hit.Size = UDim2.new(1, 20, 0, 44)
	hit.Position = UDim2.new(0, -10, 0.5, -22)
	hit.ZIndex = 4
	hit.Parent = holder

	local dragging = false
	local current = value
	local function setFrom(x: number)
		current = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		bar.Size = UDim2.fromScale(current, 1)
		knob.Position = UDim2.fromScale(current, 0.5)
		onChange(current)
	end
	hit.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging = false
			onCommit(current)
		end
	end)
end

local function renderSettings()
	for _, child in panel.list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snapshot = State.current :: any
	local settings = if snapshot and snapshot.settings then snapshot.settings else {}
	local AudioController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("AudioController")) :: any

	-- Musik and SFX: slider + switch.
	for order, def in
		{
			{ key = "music", vol = "musicVol", text = Locale.t("menu.music"), group = "music" },
			{ key = "sfx", vol = "sfxVol", text = Locale.t("menu.sfx"), group = "sfx" },
		}
	do
		local card = rowCard(order, def.text, 58)
		local share = if typeof(settings[def.vol]) == "number" then settings[def.vol] else 1
		slider(card, share, function(value)
			AudioController.Preview(def.group, value) -- you hear it while you drag
		end, function(value)
			Net.Send("SettingsSet", def.vol, value)
		end)
		UiKit.switch(card, settings[def.key] ~= false, function(value)
			Net.Send("SettingsSet", def.key, value)
		end)
	end

	-- Kualitas Gambar: three tabs (the lit plank is the chosen one).
	local quality = if typeof(settings.quality) == "number" then settings.quality else 2
	local card = rowCard(3, Locale.t("menu.quality"), 94)
	local names: { [string]: string } =
		{ ["1"] = Locale.t("menu.quality.1"), ["2"] = Locale.t("menu.quality.2"), ["3"] = Locale.t("menu.quality.3") }
	local tabs: any = nil
	-- The chosen one must be unmistakable: a tick and a bright plank (no outline); the others stay fully readable (not
	-- dimmed like a disabled button), on a plain tan plank.
	-- One place decides a plank's tint: the chosen tab is white (lit gold), every other tab is the same tan.
	local chosenQuality = ""
	local function paintPlank(plank: Instance, on: boolean)
		if plank:IsA("ImageLabel") then
			plank.ImageColor3 = Color3.new(1, 1, 1) -- the darkening is the "Dim" veil, not the tint
			plank.ImageTransparency = 0
		end
	end
	local function paintTabs(selected: string)
		chosenQuality = selected
		for id, button in tabs.buttons do
			local on = id == selected
			button.Text = if on then `✓ {names[id]}` else names[id]
			-- Full state set every time, identical for every unselected tab: the chosen one is the lit plank, the others share one tan plank.
			button.BackgroundColor3 = if on then UiKit.BUTTON else UiKit.BUTTON_MUTED
			button.AutoButtonColor = false -- no press darkening: the tab keeps its plank on tap
			button.TextTransparency = 0
			local shade = button:FindFirstChildOfClass("UIGradient")
			if shade then
				shade.Enabled = true
			end
			local plank = button:FindFirstChild("Skin")
			if plank then
				paintPlank(plank, on)
			end
			-- A dark veil of our own over every tab that is not chosen. It does not depend on the plank's tint (which UiKit
			-- rewrites on its own schedule), so exactly one tab is lit at any time.
			local dim = button:FindFirstChild("Dim")
			if not dim then
				local veil = Instance.new("Frame")
				veil.Name = "Dim"
				veil.Size = UDim2.fromScale(1, 1)
				veil.BackgroundColor3 = Color3.fromRGB(70, 42, 18)
				veil.BackgroundTransparency = 0.42
				veil.BorderSizePixel = 0
				veil.Active = false
				veil.ZIndex = 1
				local veilRound = Instance.new("UICorner")
				veilRound.CornerRadius = UDim.new(0, 10)
				veilRound.Parent = veil
				veil.Parent = button
				dim = veil
			end
			if dim and dim:IsA("Frame") then
				dim.Visible = not on
			end
		end
	end
	tabs = UiKit.tabs(
		card,
		{
			{ id = "1", text = names["1"] },
			{ id = "2", text = names["2"] },
			{ id = "3", text = names["3"] },
		},
		tostring(quality),
		function(id: string)
			local level = tonumber(id) or 2
			applyQuality(level)
			Net.Send("SettingsSet", "quality", level)
			paintTabs(id)
		end
	)
	tabs.frame.Position = UDim2.fromOffset(14, 38)
	tabs.frame.Size = UDim2.new(1, -28, 0, 44)
	paintTabs(tostring(quality))
	-- UiKit re-tints a plank whenever its button's background changes; win that race by repainting right after.
	for id, button in tabs.buttons do
		button:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
			local plank = button:FindFirstChild("Skin")
			if plank then
				paintPlank(plank, id == chosenQuality)
			end
		end)
	end

	local body = 58 * 2 + 94 + 5 * 2
	panelFrame.Size = UDim2.new(0.88, 0, 0, 40 + body + 36) -- room under the last card for the frame's rattan corners
	panel.list.Size = UDim2.new(1, -52, 0, body)
	panel.list.ScrollBarThickness = 0
end

local function setPanel(open: boolean)
	if open then
		renderSettings()
	end
	panel.gui.Enabled = open
end
local closeButton = panelFrame:FindFirstChild("Close") :: GuiButton
closeButton.Activated:Connect(function()
	setPanel(false)
end)
local backdrop = panel.gui:FindFirstChild("Backdrop") :: GuiButton
backdrop.Activated:Connect(function()
	setPanel(false)
end)
settingsButton.Activated:Connect(function()
	setPanel(not panel.gui.Enabled)
end)

-- Loading: the bar follows the real load ---------------------------------------------------------------------------------

local assetShare = 0 -- the UI pictures preloaded, 0..1
local mapShare = 0 -- the map's meshes, textures and decals preloaded, 0..1
task.spawn(function()
	local ids: { string } = {}
	local function add(id: string?)
		if id and id ~= "" then
			table.insert(ids, id)
		end
	end
	for _, skin in
		{
			UiAssets.PANEL,
			UiAssets.BUTTON,
			UiAssets.RIBBON,
			UiAssets.CARD,
			UiAssets.CHIP,
			UiAssets.PLATE,
			UiAssets.CLOSE,
		}
	do
		add(skin.image)
	end
	add(UiAssets.LOGO.image)
	add(UiAssets.LOADING_BAR.image)
	for _, id in UiAssets.ICONS do
		add(id)
	end
	local done = 0
	local okUi = pcall(function()
		ContentProvider:PreloadAsync(ids, function()
			done += 1
			assetShare = math.min(done / math.max(#ids, 1), 1)
		end)
	end)
	if not okUi then
		warn("[MenuFlow] UI preload failed; the bar continues without it")
	end
	assetShare = 1

	-- The town itself: every mesh, texture and decal in the map is really loaded before the bar can finish.
	if not game:IsLoaded() then
		game.Loaded:Wait() -- the list must be the whole map, not the part that happened to exist when this ran
	end
	local parts: { Instance } = {}
	for _, d in Workspace:GetDescendants() do
		if d:IsA("MeshPart") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("SpecialMesh") then
			table.insert(parts, d)
		end
	end
	local mapDone = 0
	local okMap = pcall(function()
		ContentProvider:PreloadAsync(parts, function()
			mapDone += 1
			mapShare = math.min(mapDone / math.max(#parts, 1), 1)
		end)
	end)
	if not okMap then
		warn("[MenuFlow] map preload failed; the bar continues without it")
	end
	mapShare = 1
end)

local function loadTarget(): number
	local snapshot = State.current
	local character = player.Character
	local ready = 0
	ready += if game:IsLoaded() then 1 else 0
	ready += 3 * assetShare
	ready += 2 * mapShare
	ready += if snapshot ~= nil then 2 else 0
	ready += if character
			and character:FindFirstChild("HumanoidRootPart")
			and typeof(player:GetAttribute("PlotName")) == "string"
		then 1
		else 0
	ready += if streamed then 1 else 0
	return ready / 10
end

local phase = "loading"
local leavingMenu = false
local shown = 0
local started = os.clock()
local loadConn: RBXScriptConnection? = nil

local function showPlayScreen()
	phase = "play"
	player:SetAttribute("KTMenu", "play")
	playGroup.Visible = true
	TweenService:Create(loadingGroup, TweenInfo.new(FADE_SECONDS), { GroupTransparency = 1 }):Play()
	TweenService:Create(playGroup, TweenInfo.new(FADE_SECONDS), { GroupTransparency = 0 }):Play()
	local loadingImage = loadingBackdrop
	if loadingImage then
		TweenService:Create(loadingImage, TweenInfo.new(FADE_SECONDS), { ImageTransparency = 1 }):Play()
	end
	task.delay(FADE_SECONDS, function()
		loadingGroup.Visible = false
		if loadingImage then
			loadingImage.Visible = false -- the picture is gone: only the blurred eagle-eye camera remains
		end
	end)
end

loadConn = RunService.RenderStepped:Connect(function(dt: number)
	-- (test hook) KTMenuHold set while the Play screen is up: back to the Loading screen at that share of the bar.
	if phase == "play" and not leavingMenu and typeof(player:GetAttribute("KTMenuHold")) == "number" then
		phase = "loading"
		player:SetAttribute("KTMenu", "loading")
		loadingGroup.Visible = true
		loadingGroup.GroupTransparency = 0
		playGroup.Visible = false
		playGroup.GroupTransparency = 1
		shown = 0
		started = os.clock() - MIN_LOAD_SECONDS
	end
	if phase ~= "loading" then
		return
	end
	local hold = player:GetAttribute("KTMenuHold") -- (a test hook: holds the bar at this share and the screen on Loading)
	local target = loadTarget()
	local limit = math.min((os.clock() - started) / MIN_LOAD_SECONDS, if typeof(hold) == "number" then hold else 1)
	shown = math.max(shown, math.min(shown + (target - shown) * math.min(dt * 3, 1), limit))
	fill.Size =
		UDim2.fromScale((BAR_HOLLOW.x1 - BAR_HOLLOW.x0) * math.clamp(shown, 0, 1), BAR_HOLLOW.y1 - BAR_HOLLOW.y0)
	if shown >= 0.995 and target >= 1 and typeof(hold) ~= "number" then
		fill.Size = UDim2.fromScale(BAR_HOLLOW.x1 - BAR_HOLLOW.x0, BAR_HOLLOW.y1 - BAR_HOLLOW.y0)
		showPlayScreen()
	end
end)

-- PLAY -------------------------------------------------------------------------------------------------------------------

-- Every entry into the game starts the same way: the player stands at the gate and the camera is behind them (11 studs back,
-- 5.5 up), looking into the land. The same numbers as CoachmarkController.gateCamera. The menu's orbit camera and the
-- default camera's leftover angle used to decide the view, so it was different on every join.
local function putCameraBehindCharacter()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if flat.Magnitude < 0.01 then
		return
	end
	local forward = flat.Unit
	local base = root.Position
	camera = Workspace.CurrentCamera :: Camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(base - forward * 11 + Vector3.new(0, 5.5, 0), base + forward * 4 + Vector3.new(0, 1.5, 0))
end

local leaving = false
local function leaveMenu()
	if leaving or phase ~= "play" then
		return
	end
	leaving = true
	leavingMenu = true
	setPanel(false)

	-- 0.5 s to black (its own screen, so it outlives the menu).
	local coverGui = Instance.new("ScreenGui")
	coverGui.Name = "KTMenuCover"
	coverGui.ResetOnSpawn = false
	coverGui.IgnoreGuiInset = true
	coverGui.DisplayOrder = 250
	coverGui.Parent = playerGui
	local cover = Instance.new("Frame")
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Color3.new(0, 0, 0)
	cover.BackgroundTransparency = 1
	cover.BorderSizePixel = 0
	cover.Parent = coverGui
	TweenService:Create(cover, TweenInfo.new(BLACK_SECONDS), { BackgroundTransparency = 0 }):Play()
	task.wait(BLACK_SECONDS + 0.05)

	-- Under the black: the menu goes away and the game's screens come back.
	RunService:UnbindFromRenderStep("KTMenuCamera")
	blur:Destroy()
	blurFull:Destroy()
	if loadConn then
		loadConn:Disconnect()
	end
	gui:Destroy()
	panel.gui:Destroy()
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	putCameraBehindCharacter() -- still under the black
	task.wait() -- one frame with the placed view, then the player's camera takes over from it
	camera.CameraType = Enum.CameraType.Custom
	-- The camera must follow THIS character's humanoid. After the menu's orbit it can be left on nothing (or on an old
	-- character), and then the player walks and the view stays.
	local function followHumanoid()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and camera.CameraSubject ~= humanoid then
			camera.CameraSubject = humanoid
		end
	end
	followHumanoid()
	showGame()
	-- Safety net: a few seconds after PLAY, if nothing that owns the camera (the intro, a talk) is running and it is still
	-- scripted, the player's camera is given back.
	task.delay(3.5, function()
		if player:GetAttribute("KTIntroRunning") ~= true and player:GetAttribute("NpcTalkOpen") ~= true then
			local current = Workspace.CurrentCamera :: Camera
			camera = current
			if current.CameraType ~= Enum.CameraType.Custom then
				current.CameraType = Enum.CameraType.Custom
			end
			followHumanoid()
		end
	end)
	if player:GetAttribute("KTIntroRunning") ~= true and controls then
		pcall(function()
			controls:Enable()
		end)
	end
	phase = "done"
	player:SetAttribute("KTMenu", "done")

	-- A new player goes into the intro (T1Ghost puts its own black up); anyone else dissolves into the game.
	task.wait(0.3)
	if playerGui:FindFirstChild("T1Cutscene") then
		coverGui:Destroy()
	else
		local reveal = TweenService:Create(cover, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
		reveal:Play()
		reveal.Completed:Wait()
		coverGui:Destroy()
	end
end
playButton.Activated:Connect(leaveMenu)

-- The saved quality is applied for the whole session, whatever screen is up.
State.Changed:Connect(function()
	local snapshot = State.current :: any
	local level = snapshot and snapshot.settings and snapshot.settings.quality
	if typeof(level) == "number" then
		applyQuality(level)
	end
end)
