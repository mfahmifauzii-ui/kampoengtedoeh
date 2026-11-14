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
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Buffs = require(ReplicatedStorage.Shared.Config.Buffs)
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
local toastLabel: TextLabel?
local hudGui: ScreenGui? = nil
type BuffSlot = { def: Buffs.Buff, slot: Frame, stroke: UIStroke, clip: Frame, hit: TextButton }
local buffSlots: { BuffSlot } = {} -- the three buff icons on the player card (empty = off, full and draining = on)
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

	-- TOP CENTER: Koin + Bunga, side by side.
	local STRIP_HEIGHT = 42
	local bar = Instance.new("Frame")
	bar.Name = "CurrencyBar"
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 6)
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

	-- BOTTOM LEFT: the player card = photo + level star + name + a slim XP bar, and under it the three buff slots.
	local card = UiKit.pill(gui, "StatusCard", 214, 84)
	card.AnchorPoint = Vector2.new(0, 1)
	card.Position = UDim2.new(0, 8, 1, -6)

	local ring = Instance.new("ImageLabel") -- bamboo ring behind the photo
	ring.Name = "PhotoRing"
	ring.BackgroundTransparency = 1
	ring.Image = UiAssets.PLATE.image
	ring.ScaleType = Enum.ScaleType.Fit
	ring.Size = UDim2.fromOffset(54, 54)
	ring.Position = UDim2.fromOffset(8, 12)
	ring.ZIndex = 2
	ring.Parent = card
	local photo = Instance.new("ImageLabel")
	photo.Name = "Photo"
	photo.BackgroundColor3 = UiKit.ROW
	photo.Size = UDim2.fromOffset(38, 38)
	photo.Position = UDim2.fromOffset(16, 20)
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
	badge.Position = UDim2.fromOffset(2, 50)
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
		star.Position = UDim2.fromOffset(1, 49)
		star.ZIndex = 4
	end
	levelBadge = badge

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(68, 8)
	nameLabel.Size = UDim2.new(1, -80, 0, 16)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = UiKit.FONT
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = UiKit.TEXT
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = player.DisplayName
	nameLabel.ZIndex = 2
	nameLabel.Parent = card

	-- XP: a slim dark track with a green fill and the numbers inside (small on purpose: the buffs sit right under it).
	local track = Instance.new("Frame")
	track.Name = "XPTrack"
	track.BackgroundColor3 = Color3.fromRGB(150, 118, 76)
	track.Position = UDim2.fromOffset(68, 28)
	track.Size = UDim2.new(1, -82, 0, 14)
	track.ZIndex = 2
	track.Parent = card
	local trackRound = Instance.new("UICorner")
	trackRound.CornerRadius = UDim.new(0, 7)
	trackRound.Parent = track
	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Color3.fromRGB(96, 66, 36)
	trackStroke.Thickness = 2
	trackStroke.Parent = track
	local xpBarFill = Instance.new("Frame")
	xpBarFill.Name = "XPFill" -- contract names: XPFill (Frame) + LevelLabel (TextLabel)
	xpBarFill.BackgroundColor3 = Color3.fromRGB(104, 168, 64)
	xpBarFill.Size = UDim2.fromScale(0, 1)
	xpBarFill.ZIndex = 3
	xpBarFill.Parent = track
	local fillRound = Instance.new("UICorner")
	fillRound.CornerRadius = UDim.new(0, 7)
	fillRound.Parent = xpBarFill
	local xpBarLabel = Instance.new("TextLabel")
	xpBarLabel.Name = "LevelLabel"
	xpBarLabel.BackgroundTransparency = 1
	xpBarLabel.Size = UDim2.fromScale(1, 1)
	xpBarLabel.ZIndex = 4
	xpBarLabel.Font = UiKit.FONT
	xpBarLabel.TextSize = 10
	xpBarLabel.TextColor3 = UiKit.CREAM
	xpBarLabel.TextStrokeColor3 = Color3.fromRGB(60, 36, 14)
	xpBarLabel.TextStrokeTransparency = 0.25
	xpBarLabel.Parent = track

	-- The three buff slots (Config/Buffs): empty icon until the buff is on, then the full icon draining away.
	for index, def in Buffs.SLOTS do
		local slot = Instance.new("Frame")
		slot.Name = `Buff_{def.id}`
		slot.BackgroundColor3 = UiKit.DARK
		slot.BackgroundTransparency = 0.3
		slot.Position = UDim2.fromOffset(68 + (index - 1) * 34, 48)
		slot.Size = UDim2.fromOffset(30, 30)
		slot.ZIndex = 2
		slot.Parent = card
		local slotRound = Instance.new("UICorner")
		slotRound.CornerRadius = UDim.new(1, 0)
		slotRound.Parent = slot
		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = Color3.fromRGB(150, 118, 76)
		slotStroke.Thickness = 2
		slotStroke.Parent = slot

		-- 22 x 22 art box in the middle of the slot: the empty icon (a dark silhouette) under a clipped full icon.
		local box = Instance.new("Frame")
		box.Name = "Box"
		box.BackgroundTransparency = 1
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.5)
		box.Size = UDim2.fromOffset(22, 22)
		box.ZIndex = 3
		box.Parent = slot
		local empty = UiKit.icon(box, def.icon, 22)
		if empty then
			empty.Name = "Empty"
			empty.ImageColor3 = Color3.new(0, 0, 0)
			empty.ImageTransparency = 0.55
			empty.ZIndex = 3
		end
		local clip = Instance.new("Frame")
		clip.Name = "Clip"
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.AnchorPoint = Vector2.new(0, 1)
		clip.Position = UDim2.fromScale(0, 1)
		clip.Size = UDim2.fromScale(1, 0)
		clip.ZIndex = 4
		clip.Parent = box
		local full = UiKit.icon(clip, def.icon, 22)
		if full then
			full.Name = "Full"
			full.AnchorPoint = Vector2.new(0, 1)
			full.Position = UDim2.fromScale(0, 1)
			full.ZIndex = 4
		end
		-- Hover (mouse) or tap (touch) names the buff and says how long is left.
		local hit = Instance.new("TextButton")
		hit.Name = "Hit"
		hit.Text = ""
		hit.BackgroundTransparency = 1
		hit.Size = UDim2.fromScale(1, 1)
		hit.ZIndex = 6
		hit.Parent = slot
		table.insert(buffSlots, { def = def, slot = slot, stroke = slotStroke, clip = clip, hit = hit })
	end

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
		levelLabel.Text = progress -- the star on the photo already shows the level
		if xpFill then
			xpFill.Size = UDim2.fromScale(if xpNext > 0 then math.clamp(xp / xpNext, 0, 1) else 1, 1)
		end
	end
	if levelBadge and typeof(level) == "number" then
		levelBadge.Text = tostring(level)
	end
end

-- Buffs ------------------------------------------------------------------------------------

-- (seconds left, full length) of a buff, from the attributes the server sets (see Config/Buffs).
local function buffTimes(def: Buffs.Buff): (number, number)
	local ending, duration = player:GetAttribute(`Buff_{def.id}_End`), player:GetAttribute(`Buff_{def.id}_Dur`)
	if typeof(ending) ~= "number" or typeof(duration) ~= "number" or duration <= 0 then
		return 0, 1
	end
	return math.max(0, ending - Workspace:GetServerTimeNow()), duration
end

local function formatTime(seconds: number): string
	local whole = math.ceil(seconds)
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function buffTip(entry: BuffSlot): string
	local name = Locale.t(entry.def.nameKey)
	local remaining = buffTimes(entry.def)
	if remaining > 0 then
		return `{name} · {formatTime(remaining)} · {Locale.t(entry.def.descKey)}`
	end
	return `{name}: {Locale.t("buff.inactive")}`
end

local function updateBuffs()
	for _, entry in buffSlots do
		local remaining, duration = buffTimes(entry.def)
		entry.clip.Size = UDim2.fromScale(1, math.clamp(remaining / duration, 0, 1))
		entry.stroke.Color = if remaining > 0 then Color3.fromRGB(120, 200, 80) else Color3.fromRGB(150, 118, 76)
		entry.slot.BackgroundTransparency = if remaining > 0 then 0.1 else 0.3
	end
end

local function bindBuffTips()
	local gui = hudGui
	if not gui then
		return
	end
	for _, entry in buffSlots do
		entry.hit.MouseEnter:Connect(function()
			UiKit.showTip(gui, entry.slot, buffTip(entry), true)
		end)
		entry.hit.MouseLeave:Connect(function()
			UiKit.hideTip(gui)
		end)
		-- Touch has no hover: a tap shows the tip for a moment.
		entry.hit.Activated:Connect(function()
			UiKit.showTip(gui, entry.slot, buffTip(entry), true)
			task.delay(2.5, function()
				UiKit.hideTip(gui)
			end)
		end)
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
	hudGui = gui :: ScreenGui
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
	bindBuffTips()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			updateBuffs()
		end
	end)
	for _, attribute in { "Koin", "Bunga", "Level", "XP", "XPNext" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	Net.Listen("Notify", function(key: any, vars: any)
		if typeof(key) == "string" then
			HudController.Toast(Locale.t(key, resolveVars(if typeof(vars) == "table" then vars else nil)))
		end
	end)
end

return HudController
