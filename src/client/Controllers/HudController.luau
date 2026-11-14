--!strict
-- Binds currency, level/XP, the "next goal" chip and toasts to the HUD.
--
-- UI CONTRACT (for your designed UI):
--   StarterGui > ScreenGui "HUD" (ResetOnSpawn = false) containing, at any depth:
--     TextLabel "KoinLabel"    -> "1.250 Koin"
--     TextLabel "BungaLabel"   -> "10 Bunga"
--     TextLabel "LevelLabel"   -> "Lv 3 · 45/104 XP"            (optional)
--     Frame     "XPFill"       -> width scale = XP progress     (optional)
--     TextLabel "GoalLabel"    -> next small goal (set via HudController.SetGoal) (optional)
--     TextLabel "ToastLabel"   -> notifications, queued ~1.8s each (Visible toggled) (optional)
--   Buttons "BagButton", "DecorButton", "OrdersButton", "BookButton" are bound by their controllers.
-- If no "HUD" exists, a plain placeholder is built so the game is testable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiAssets = require(ReplicatedStorage.Shared.Config.UiAssets)
local UiKit = require(script.Parent.Parent.UiKit)

local TOAST_SECONDS = 1.8
local MAX_QUEUED_TOASTS = 5

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local HudController = {}

local koinLabel: TextLabel
local bungaLabel: TextLabel
local levelLabel: TextLabel?
local xpFill: Frame?
local goalLabel: TextLabel?
local levelBadge: TextLabel? -- level number on the photo's star
local staminaFill: Frame?
local staminaLabel: TextLabel?
local toastLabel: TextLabel?
local toastQueue: { string } = {}
local toastRunning = false

local function buildPlaceholder(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false

	-- INSETS: the HUD ignores Roblox's top-bar inset (full-screen canvas) but still respects the phone's own safe area
	-- (notch / rounded corners), so nothing hides behind a cut-out.
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets

	-- TOP: Koin + Bunga, in a row right after Roblox's own menu buttons (which fill the top-left corner).
	local TOP_X = 236
	local STRIP_HEIGHT = 42
	local bar = Instance.new("Frame")
	bar.Name = "CurrencyBar"
	bar.BackgroundTransparency = 1
	bar.Position = UDim2.fromOffset(TOP_X, 6)
	bar.Size = UDim2.fromOffset(0, 0)
	bar.AutomaticSize = Enum.AutomaticSize.XY
	bar.Parent = gui
	local barLayout = Instance.new("UIListLayout")
	barLayout.FillDirection = Enum.FillDirection.Horizontal
	barLayout.Padding = UDim.new(0, 6)
	barLayout.SortOrder = Enum.SortOrder.LayoutOrder
	barLayout.Parent = bar

	local koin = UiKit.chip(bar, "KoinLabel", "koin", 104, STRIP_HEIGHT)
	local koinChip = koin.Parent :: Frame
	koinChip.LayoutOrder = 1
	local bunga = UiKit.chip(bar, "BungaLabel", "bunga", 92, STRIP_HEIGHT)
	local bungaChip = bunga.Parent :: Frame
	bungaChip.LayoutOrder = 2

	-- BOTTOM LEFT: the player card = photo + level badge + name + XP bar + STAMINA bar. The stamina bar is ready for the
	-- rest system: it reads the player attributes "Stamina" / "StaminaMax" (shows 100 / 100 until the server sets them).
	local card = UiKit.pill(gui, "StatusCard", 214, 72)
	card.AnchorPoint = Vector2.new(0, 1)
	card.Position = UDim2.new(0, 8, 1, -6)

	local ring = Instance.new("ImageLabel") -- bamboo ring behind the photo
	ring.Name = "PhotoRing"
	ring.BackgroundTransparency = 1
	ring.Image = UiAssets.PLATE.image
	ring.ScaleType = Enum.ScaleType.Fit
	ring.Size = UDim2.fromOffset(54, 54)
	ring.Position = UDim2.fromOffset(8, 9)
	ring.ZIndex = 2
	ring.Parent = card
	local photo = Instance.new("ImageLabel")
	photo.Name = "Photo"
	photo.BackgroundColor3 = UiKit.ROW
	photo.Size = UDim2.fromOffset(38, 38)
	photo.Position = UDim2.fromOffset(16, 17)
	photo.ZIndex = 3
	photo.Parent = card
	local photoRound = Instance.new("UICorner")
	photoRound.CornerRadius = UDim.new(1, 0)
	photoRound.Parent = photo
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and photo.Parent then
			photo.Image = content
		end
	end)

	local badge = Instance.new("TextLabel") -- level star on the photo's corner
	badge.Name = "LevelBadge"
	badge.BackgroundTransparency = 1
	badge.Size = UDim2.fromOffset(24, 24)
	badge.Position = UDim2.fromOffset(2, 42)
	badge.ZIndex = 5
	badge.Font = UiKit.FONT
	badge.TextSize = 12
	badge.TextColor3 = UiKit.CREAM
	badge.TextStrokeColor3 = Color3.fromRGB(110, 64, 16)
	badge.TextStrokeTransparency = 0.2
	badge.Text = "1"
	badge.Parent = card
	local star = UiKit.icon(card, "bintang", 26)
	if star then
		star.Position = UDim2.fromOffset(1, 41)
		star.ZIndex = 4
	end
	levelBadge = badge

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(68, 5)
	nameLabel.Size = UDim2.new(1, -80, 0, 16)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = UiKit.FONT
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = UiKit.TEXT
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = player.DisplayName
	nameLabel.ZIndex = 2
	nameLabel.Parent = card

	-- A bar = dark track + colored fill + a centered caption.
	local function makeBar(name: string, y: number, color: Color3): (Frame, TextLabel)
		local track = Instance.new("Frame")
		track.Name = name .. "Track"
		track.BackgroundColor3 = Color3.fromRGB(150, 118, 76)
		track.Position = UDim2.fromOffset(68, y)
		track.Size = UDim2.new(1, -82, 0, 18)
		track.ZIndex = 2
		track.Parent = card
		local trackRound = Instance.new("UICorner")
		trackRound.CornerRadius = UDim.new(0, 9)
		trackRound.Parent = track
		local trackStroke = Instance.new("UIStroke")
		trackStroke.Color = Color3.fromRGB(96, 66, 36)
		trackStroke.Thickness = 2
		trackStroke.Parent = track
		local fillBar = Instance.new("Frame")
		fillBar.Name = name .. "Fill"
		fillBar.BackgroundColor3 = color
		fillBar.Size = UDim2.fromScale(1, 1)
		fillBar.ZIndex = 3
		fillBar.Parent = track
		local fillRound = Instance.new("UICorner")
		fillRound.CornerRadius = UDim.new(0, 9)
		fillRound.Parent = fillBar
		local caption = Instance.new("TextLabel")
		caption.Name = name .. "Label"
		caption.BackgroundTransparency = 1
		caption.Size = UDim2.fromScale(1, 1)
		caption.ZIndex = 4
		caption.Font = UiKit.FONT
		caption.TextSize = 10
		caption.TextColor3 = UiKit.CREAM
		caption.TextStrokeColor3 = Color3.fromRGB(60, 36, 14)
		caption.TextStrokeTransparency = 0.25
		caption.Parent = track
		return fillBar, caption
	end
	local xpBarFill, xpBarLabel = makeBar("XP", 24, Color3.fromRGB(104, 168, 64))
	xpBarFill.Name = "XPFill" -- contract names: XPFill (Frame) + LevelLabel (TextLabel)
	xpBarFill.Size = UDim2.fromScale(0, 1)
	xpBarLabel.Name = "LevelLabel"
	local staminaFillBar, staminaCaption = makeBar("Stamina", 46, Color3.fromRGB(236, 158, 52))
	staminaFill = staminaFillBar
	staminaLabel = staminaCaption

	-- Toast: one parchment pill, above the Garap bar so it never hides under it.
	local toast = UiKit.chip(gui, "ToastLabel", nil, 360)
	local toastChip = toast.Parent :: Frame
	toastChip.AnchorPoint = Vector2.new(0.5, 1)
	toastChip.Position = UDim2.new(0.5, 0, 1, -130)
	toastChip.Size = UDim2.fromOffset(340, 56)
	toast.TextWrapped = true
	toast.TextSize = 18
	toast.TextXAlignment = Enum.TextXAlignment.Center
	toast.Position = UDim2.fromOffset(8, 0)
	toast.Size = UDim2.new(1, -16, 1, 0)
	toastChip.Visible = false
	toast:GetPropertyChangedSignal("Visible"):Connect(function()
		toastChip.Visible = toast.Visible
	end)
	toast.Visible = false

	gui.Parent = playerGui
	return gui
end

local function find(gui: Instance, name: string, class: string): any
	local found = gui:FindFirstChild(name, true)
	return if found and found:IsA(class) then found else nil
end

local function refresh()
	local koin = player:GetAttribute("Koin")
	local bunga = player:GetAttribute("Bunga")
	koinLabel.Text = if typeof(koin) == "number"
		then Locale.formatNumber(koin) -- number only: the coin icon says what it is (saves width on phones)
		else Locale.t("hud.loading")
	bungaLabel.Text = if typeof(bunga) == "number"
		then Locale.formatNumber(bunga)
		else Locale.t("hud.loading")

	local level, xp, xpNext = player:GetAttribute("Level"), player:GetAttribute("XP"), player:GetAttribute("XPNext")
	if levelLabel and typeof(level) == "number" and typeof(xp) == "number" and typeof(xpNext) == "number" then
		local progress = if xpNext > 0 then Locale.t("hud.xp", { xp = Locale.formatNumber(xp), next = Locale.formatNumber(xpNext) }) else Locale.t("hud.xp_max")
		levelLabel.Text = `{Locale.t("hud.level", { level = level })} · {progress}`
		if xpFill then
			xpFill.Size = UDim2.fromScale(if xpNext > 0 then math.clamp(xp / xpNext, 0, 1) else 1, 1)
		end
	end
	if levelBadge and typeof(level) == "number" then
		levelBadge.Text = tostring(level)
	end

	-- Stamina (rest system, coming): attributes Stamina / StaminaMax; a full 100 / 100 bar until the server sets them.
	local stamina, staminaMax = player:GetAttribute("Stamina"), player:GetAttribute("StaminaMax")
	local maxValue = if typeof(staminaMax) == "number" and staminaMax > 0 then staminaMax else 100
	local value = if typeof(stamina) == "number" then math.clamp(stamina, 0, maxValue) else maxValue
	if staminaFill then
		staminaFill.Size = UDim2.fromScale(value / maxValue, 1)
	end
	if staminaLabel then
		staminaLabel.Text = `Stamina {math.floor(value)}/{math.floor(maxValue)}`
	end
end

-- Translates vars: numbers get Indonesian formatting, strings that are locale keys get
-- translated, and arrays of keys become a comma-separated list.
local function resolveVars(vars: { [string]: any }?): { [string]: any }
	local resolved: { [string]: any } = {}
	for name, value in vars or {} do
		if typeof(value) == "number" then
			resolved[name] = Locale.formatNumber(value)
		elseif typeof(value) == "string" and Locale.has(value) then
			resolved[name] = Locale.t(value)
		elseif typeof(value) == "table" then
			local parts = {}
			for _, key in value do
				table.insert(parts, if typeof(key) == "string" then Locale.t(key) else tostring(key))
			end
			resolved[name] = table.concat(parts, ", ")
		else
			resolved[name] = value
		end
	end
	return resolved
end

local function runToasts()
	local label = toastLabel
	if toastRunning or not label then
		return
	end
	toastRunning = true
	while #toastQueue > 0 do
		label.Text = table.remove(toastQueue, 1) :: string
		label.Visible = true
		task.wait(TOAST_SECONDS)
	end
	label.Visible = false
	toastRunning = false
end

function HudController.Toast(text: string)
	if #toastQueue >= MAX_QUEUED_TOASTS then
		table.remove(toastQueue, 1)
	end
	table.insert(toastQueue, text)
	task.spawn(runToasts)
end

function HudController.SetGoal(text: string)
	if goalLabel then
		goalLabel.Text = text
		goalLabel.Visible = text ~= ""
	end
end

function HudController.Init()
	local gui = playerGui:WaitForChild("HUD", 3) or buildPlaceholder()
	koinLabel = assert(find(gui, "KoinLabel", "TextLabel"), "[HUD] KoinLabel missing")
	bungaLabel = assert(find(gui, "BungaLabel", "TextLabel"), "[HUD] BungaLabel missing")
	levelLabel = find(gui, "LevelLabel", "TextLabel")
	xpFill = find(gui, "XPFill", "Frame")
	goalLabel = find(gui, "GoalLabel", "TextLabel")
	toastLabel = find(gui, "ToastLabel", "TextLabel")
	UiKit.autoScale() -- every ScreenGui (now and later) gets a responsive UIScale
end

function HudController.Start()
	refresh()
	for _, attribute in { "Koin", "Bunga", "Level", "XP", "XPNext", "Stamina", "StaminaMax" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	Net.Listen("Notify", function(key: any, vars: any)
		if typeof(key) == "string" then
			HudController.Toast(Locale.t(key, resolveVars(if typeof(vars) == "table" then vars else nil)))
		end
	end)
end

return HudController
