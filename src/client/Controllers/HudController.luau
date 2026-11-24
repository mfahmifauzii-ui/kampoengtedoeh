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
--   Toasts go to UiKit.toastStack (one anchor, up to 3 chips), not to a HUD child.
--   Buttons "BagButton", "DecorButton", "QuestButton", "BookButton" are bound by their controllers.
-- If no "HUD" exists, a plain placeholder is built so the game is testable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local State = require(script.Parent.Parent.State)
local Workspace = game:GetService("Workspace")

local Buffs = require(ReplicatedStorage.Shared.Config.Buffs)
local FeedbackController = require(script.Parent.FeedbackController)
local QuestOfferController = require(script.Parent.QuestOfferController)
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
local levelPill: TextLabel? -- A4 (K-53): "Lv n" pill next to the name on phones
local toastStack: Frame? -- the one toast anchor (UiKit.toastStack)
local visibleToasts = 0
local hudGui: ScreenGui? = nil
type BuffSlot = { def: Buffs.Buff, slot: Frame, stroke: UIStroke, clip: Frame, hit: TextButton }
local buffSlots: { BuffSlot } = {} -- the four buff icons on the player card (empty = off, full and draining = on)
local toastQueue: { string } = {}


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

	-- BOTTOM LEFT: the player card = photo + level star + name + a slim XP bar, and under it the four buff slots.
	-- The bamboo frame of the card is thick, so everything inside keeps a 14 px inset from its edges (nothing touches it).
	local card = UiKit.pill(gui, "StatusCard", 248, 92)
	card.AnchorPoint = Vector2.new(0, 1)
	card.Position = UDim2.new(0, 8, 1, -6)

	local ring = Instance.new("ImageLabel") -- bamboo ring behind the photo
	ring.Name = "PhotoRing"
	ring.BackgroundTransparency = 1
	ring.Image = UiAssets.PLATE.image
	ring.ScaleType = Enum.ScaleType.Fit
	ring.Size = UDim2.fromOffset(46, 46)
	ring.Position = UDim2.fromOffset(22, 23)
	ring.ZIndex = 2
	ring.Parent = card
	local photo = Instance.new("ImageLabel")
	photo.Name = "Photo"
	photo.BackgroundColor3 = UiKit.ROW
	photo.Size = UDim2.fromOffset(32, 32)
	photo.Position = UDim2.fromOffset(29, 30)
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
	badge.Size = UDim2.fromOffset(22, 22)
	badge.Position = UDim2.fromOffset(16, 52)
	badge.ZIndex = 5
	badge.Font = UiKit.FONT
	badge.TextSize = 12
	badge.TextColor3 = UiKit.CREAM
	badge.TextStrokeColor3 = Color3.fromRGB(110, 64, 16)
	badge.TextStrokeTransparency = 0.2
	badge.Text = "1"
	badge.Parent = card
	local star = UiKit.icon(card, "bintang", 22)
	if star then
		star.Position = UDim2.fromOffset(16, 52)
		star.ZIndex = 4
	end
	levelBadge = badge

	-- A4 (K-53): on phones the star is hidden, so the level is a pill next to the name (always visible).
	local pill = Instance.new("TextLabel")
	pill.Name = "LvPill"
	pill.BackgroundColor3 = UiKit.DARK
	pill.BackgroundTransparency = 0.15
	pill.Size = UDim2.fromOffset(40, 18)
	pill.Position = UDim2.fromOffset(80, 16)
	pill.Font = UiKit.FONT
	pill.TextSize = 11
	pill.TextColor3 = UiKit.CREAM
	pill.Text = "Lv 1"
	pill.Visible = false
	pill.ZIndex = 3
	local pillRound = Instance.new("UICorner")
	pillRound.CornerRadius = UDim.new(1, 0)
	pillRound.Parent = pill
	pill.Parent = card
	levelPill = pill

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(76, 12)
	nameLabel.Size = UDim2.new(1, -104, 0, 14)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = UiKit.FONT
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = UiKit.TEXT
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = player.DisplayName
	nameLabel.ZIndex = 2
	nameLabel.Parent = card

	-- XP: a slim dark track with a green fill and the numbers inside (small on purpose: the buffs sit right under it).
	local track = Instance.new("Frame")
	track.Name = "XPTrack"
	track.BackgroundColor3 = Color3.fromRGB(150, 118, 76)
	track.Position = UDim2.fromOffset(76, 30)
	track.Size = UDim2.new(1, -104, 0, 12)
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
	xpBarLabel.TextSize = 9
	xpBarLabel.TextColor3 = UiKit.CREAM
	xpBarLabel.TextStrokeColor3 = Color3.fromRGB(60, 36, 14)
	xpBarLabel.TextStrokeTransparency = 0.25
	xpBarLabel.Parent = track

	-- The four buff slots (Config/Buffs): empty icon until the buff is on, then the full icon draining away.
	for index, def in Buffs.SLOTS do
		local slot = Instance.new("Frame")
		slot.Name = `Buff_{def.id}`
		slot.BackgroundColor3 = UiKit.DARK
		slot.BackgroundTransparency = 0.3
		-- spread evenly under the XP bar: first slot at its left edge, last one at its right edge
		local along = (index - 1) / (#Buffs.SLOTS - 1) -- 0 .. 1 across the bar (bar = card width - 104, slot = 23)
		slot.Position = UDim2.new(along, 76 - 127 * along, 0, 49)
		slot.Size = UDim2.fromOffset(23, 23)
		slot.ZIndex = 2
		slot.Parent = card
		local slotRound = Instance.new("UICorner")
		slotRound.CornerRadius = UDim.new(1, 0)
		slotRound.Parent = slot
		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = Color3.fromRGB(150, 118, 76)
		slotStroke.Thickness = 1.5
		slotStroke.Parent = slot

		-- 16 x 16 art box in the middle of the slot: the empty icon (a dark silhouette) under a clipped full icon.
		local box = Instance.new("Frame")
		box.Name = "Box"
		box.BackgroundTransparency = 1
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.5)
		box.Size = UDim2.fromOffset(16, 16)
		box.ZIndex = 3
		box.Parent = slot
		local empty = UiKit.icon(box, def.icon, 16)
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
		local full = UiKit.icon(clip, def.icon, 16)
		if full then
			full.Name = "Full"
			full.AnchorPoint = Vector2.new(0, 1)
			full.Position = UDim2.fromScale(0, 1)
			full.ZIndex = 4
		end
		-- Click or tap names the buff and says how long is left.
		local hit = Instance.new("TextButton")
		hit.Name = "Hit"
		hit.Text = ""
		hit.BackgroundTransparency = 1
		hit.Size = UDim2.fromScale(1, 1)
		hit.ZIndex = 6
		hit.Parent = slot
		table.insert(buffSlots, { def = def, slot = slot, stroke = slotStroke, clip = clip, hit = hit })
	end

	-- PHONE: the player card is compact (180 x 60, avatar 36, XP bar 8 px, name 14 px) and the four buff icons are hidden,
	-- so the card never takes a quarter of the width. Desktop keeps the full card. Sits 12 px in from the safe edges.
	local function layoutCard()
		local camera = Workspace.CurrentCamera :: Camera
		local view = camera.ViewportSize
		local phone = view.X < 900 or view.Y < 450
		-- Phone size (the middle size the player asked for): card 220 x 70, 8 px inner padding, avatar 48, name 14 px,
		-- XP bar 8 px, four buff icons 28 px with 4 px gaps, all visible. Desktop keeps the full card.
		card.Position = if phone then UDim2.new(0, 12, 1, -12) else UDim2.new(0, 8, 1, -6)
		card.Size = if phone then UDim2.fromOffset(250, 100) else UDim2.fromOffset(248, 92) -- the bamboo frame keeps a 14 px inset: every element sits inside it
		local function set(name: string, props: { [string]: any })
			local child = card:FindFirstChild(name, true)
			if child then
				for key, value in props do
					(child :: any)[key] = value
				end
			end
		end
		set("PhotoRing", { Size = if phone then UDim2.fromOffset(60, 60) else UDim2.fromOffset(46, 46), Position = if phone then UDim2.fromOffset(12, 16) else UDim2.fromOffset(22, 23) })
		set("Photo", { Size = if phone then UDim2.fromOffset(48, 48) else UDim2.fromOffset(32, 32), Position = if phone then UDim2.fromOffset(18, 22) else UDim2.fromOffset(29, 30) })
		set("PlayerName", { Position = if phone then UDim2.fromOffset(80, 16) else UDim2.fromOffset(76, 12), Size = if phone then UDim2.new(1, -94, 0, 18) else UDim2.new(1, -104, 0, 14), TextSize = if phone then 14 else 12 })
		set("XPTrack", { Position = if phone then UDim2.fromOffset(80, 40) else UDim2.fromOffset(76, 30), Size = if phone then UDim2.new(1, -94, 0, 8) else UDim2.new(1, -104, 0, 12) })
		set("LevelBadge", { Visible = not phone })
		set("LvPill", { Visible = phone })
		set("PlayerName", { Position = if phone then UDim2.fromOffset(126, 16) else UDim2.fromOffset(76, 12), Size = if phone then UDim2.new(1, -140, 0, 18) else UDim2.new(1, -104, 0, 14) })
		set("Icon_bintang", { Visible = not phone }) -- the star under the photo: desktop only
		for index, entry in buffSlots do
			if phone then
				-- row under the name, spread across the card like the PC layout (space between the four icons)
				local along = (index - 1) / (#Buffs.SLOTS - 1)
				entry.slot.Position = UDim2.fromOffset(80 + along * 132, 56) -- four 28 px icons, evenly spaced inside the frame
				entry.slot.Size = UDim2.fromOffset(28, 28)
			else
				local along = (index - 1) / (#Buffs.SLOTS - 1)
				entry.slot.Position = UDim2.new(along, 76 - 127 * along, 0, 49)
				entry.slot.Size = UDim2.fromOffset(23, 23)
			end
		end
	end
	layoutCard()
	local viewCamera = Workspace.CurrentCamera :: Camera
	viewCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutCard)


	gui.Parent = playerGui
	return gui
end

local function find(gui: Instance, name: string, class: string): any
	local found = gui:FindFirstChild(name, true)
	return if found and found:IsA(class) then found else nil
end

-- K-121: XP feedback. A gain shows "+N XP" rising from the XP bar (inside the player card), the fill slides to the new
-- value and the bar flashes once. "Kurangi gerak" (settings.reduceMotion, GUI 4.11): no slide, no rise, no flash; the
-- "+N XP" text stays still for a moment and goes away.
local XP_FLOAT_SECONDS = 0.9
local XP_FILL_SECONDS = 0.35
local XP_FLASH_COLOR = Color3.fromRGB(204, 242, 130)
local XP_FILL_COLOR = Color3.fromRGB(104, 168, 64)
local lastXp: { level: number, xp: number, xpNext: number }? = nil

local function reduceMotion(): boolean
	local snapshot = State.current :: any
	return snapshot ~= nil and snapshot.settings ~= nil and snapshot.settings.reduceMotion == true
end

local function xpFraction(xp: number, xpNext: number): number
	return if xpNext > 0 then math.clamp(xp / xpNext, 0, 1) else 1
end

-- The gain since the last refresh (a level-up counts the rest of the old bar plus the new XP; one level at a time).
local function xpGainedSince(level: number, xp: number, xpNext: number): (number?, boolean)
	local before = lastXp
	lastXp = { level = level, xp = xp, xpNext = xpNext }
	if not before then
		return nil, false
	end
	if level > before.level then
		return (before.xpNext - before.xp) + xp, true
	end
	local gained = xp - before.xp
	return if gained > 0 then gained else nil, false
end

local function showXpGain(gained: number)
	local track = xpFill and xpFill.Parent
	if not track or not track:IsA("GuiObject") then
		return
	end
	local still = reduceMotion()
	local float = Instance.new("TextLabel")
	float.Name = "XpGain"
	float.AnchorPoint = Vector2.new(1, 1)
	float.Position = UDim2.new(1, 0, 0, -4)
	float.Size = UDim2.fromOffset(80, 16)
	float.BackgroundTransparency = 1
	float.Font = UiKit.FONT
	float.TextSize = 13
	float.TextColor3 = Color3.fromRGB(204, 242, 130)
	float.TextStrokeColor3 = Color3.fromRGB(60, 36, 14)
	float.TextStrokeTransparency = 0.25
	float.TextXAlignment = Enum.TextXAlignment.Right
	float.ZIndex = 8
	float.Text = Locale.t("hud.xp_gain", { n = Locale.formatNumber(gained) })
	float.Parent = track
	if still then
		task.delay(XP_FLOAT_SECONDS, function()
			float:Destroy()
		end)
		return
	end
	local info = TweenInfo.new(XP_FLOAT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(float, info, { Position = UDim2.new(1, 0, 0, -26), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(XP_FLOAT_SECONDS, function()
		float:Destroy()
	end)
end

local function flashXpBar()
	if not xpFill or reduceMotion() then
		return
	end
	local flash = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local settle = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local up = TweenService:Create(xpFill, flash, { BackgroundColor3 = XP_FLASH_COLOR })
	up.Completed:Connect(function()
		if xpFill then
			TweenService:Create(xpFill, settle, { BackgroundColor3 = XP_FILL_COLOR }):Play()
		end
	end)
	up:Play()
end

local function refresh()
	local koin = player:GetAttribute("Koin")
	local bunga = player:GetAttribute("Bunga")
	local shown = FeedbackController.DisplayKoin() or koin -- while the coin counter counts up, show its value
	koinLabel.Text = if typeof(shown) == "number"
		then Locale.formatNumber(shown) -- number only: the coin icon says what it is (saves width on phones)
		else Locale.t("hud.loading")
	bungaLabel.Text = if typeof(bunga) == "number"
		then Locale.formatNumber(bunga)
		else Locale.t("hud.loading")

	local level, xp, xpNext = player:GetAttribute("Level"), player:GetAttribute("XP"), player:GetAttribute("XPNext")
	if levelLabel and typeof(level) == "number" and typeof(xp) == "number" and typeof(xpNext) == "number" then
		local progress = if xpNext > 0 then Locale.t("hud.xp", { xp = Locale.formatNumber(xp), next = Locale.formatNumber(xpNext) }) else Locale.t("hud.xp_max")
		levelLabel.Text = progress -- the star on the photo already shows the level
		local frac = xpFraction(xp, xpNext)
		local gained, levelUp = xpGainedSince(level, xp, xpNext)
		if xpFill then
			-- A gain slides the fill (a level-up jumps: the bar starts again from the bottom); no gain = set directly.
			if gained and not levelUp and not reduceMotion() then
				TweenService:Create(xpFill, TweenInfo.new(XP_FILL_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale(frac, 1) }):Play()
			else
				xpFill.Size = UDim2.fromScale(frac, 1)
			end
		end
		if gained then
			showXpGain(math.floor(gained + 0.5))
			flashXpBar()
		end
	end
	if levelBadge and typeof(level) == "number" then
		levelBadge.Text = tostring(level)
	end
	if levelPill and typeof(level) == "number" then
		levelPill.Text = `Lv {level}`
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
		-- A4 (K-53): an empty buff chip is hidden; it shows only while that buff runs.
		entry.slot.Visible = remaining > 0
	end
end

local tipToken = 0
local tipOwner: BuffSlot? = nil

local function bindBuffTips()
	local gui = hudGui
	if not gui then
		return
	end
	for _, entry in buffSlots do
		-- No hover: clicking / tapping a buff icon shows its info for a moment (click it again to close).
		entry.hit.Activated:Connect(function()
			tipToken += 1
			local token = tipToken
			if tipOwner == entry then
				tipOwner = nil
				UiKit.hideTip(gui)
				return
			end
			tipOwner = entry
			UiKit.showTip(gui, entry.slot, buffTip(entry), true)
			task.delay(3, function()
				if tipToken == token then
					tipOwner = nil
					UiKit.hideTip(gui)
				end
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

-- F-2: every toast goes to the one anchor (UiKit.toastStack). Up to TOAST_MAX_VISIBLE chips show at once, each for
-- TOAST_SECONDS; the rest wait in the queue (capped at MAX_QUEUED_TOASTS, the oldest waiting one is dropped).
local function pumpToasts()
	local stack = toastStack
	if not stack then
		return
	end
	while visibleToasts < UiKit.TOAST_MAX_VISIBLE and #toastQueue > 0 do
		local text = table.remove(toastQueue, 1) :: string
		visibleToasts += 1
		local chip = UiKit.toastChip(stack, text)
		task.delay(TOAST_SECONDS, function()
			UiKit.toastFadeOut(chip, function()
				visibleToasts -= 1
				pumpToasts()
			end)
		end)
	end
end

function HudController.Toast(text: string)
	if #toastQueue >= MAX_QUEUED_TOASTS then
		table.remove(toastQueue, 1)
	end
	table.insert(toastQueue, text)
	pumpToasts()
end

-- GUI 4.2 (the only toast rule). Kinds, all in the ONE stack under the Koin/Bunga bar:
--   transient   HudController.Toast(text): auto-hides after TOAST_SECONDS, at most TOAST_MAX_VISIBLE, rest queued.
--   pinned      SetPinned(key, template, n?, N?) / UpdatePinned(key, n, N) / ClearPinned(key): never evicted, never
--               auto-dismissed, never counted toward TOAST_MAX_VISIBLE; sits ABOVE every transient chip. Only ClearPinned
--               removes it. Template tokens {n} and {N} are filled from n and N (progress such as "2/5").
--   dismissible  ToastDismissible(key, text): same style plus an "Ok" button; it stays until Ok or ClearDismissible(key).
-- Updates re-render the chip at once (no polling, no fade-in); a key is one chip.
type PinnedEntry = { chip: CanvasGroup?, template: string, n: number?, total: number?, dismissible: boolean }
local pinnedEntries: { [string]: PinnedEntry } = {}
local pinnedOrder: { string } = {}
local PINNED_BASE = -1000000

local function renderPinned(key: string)
	local entry = pinnedEntries[key]
	if not entry or not toastStack then
		return
	end
	if entry.chip then
		entry.chip:Destroy()
		entry.chip = nil
	end
	-- Guard: a token with no value shows "?" instead of the raw {n} / {N} text.
	local text = entry.template:gsub("{n}", tostring(entry.n or "?")):gsub("{N}", tostring(entry.total or "?"))
	local onOk = if entry.dismissible then function()
		HudController.ClearDismissible(key)
	end else nil
	local chip = UiKit.toastChip(toastStack, text, { instant = true, onOk = onOk })
	local index = table.find(pinnedOrder, key) or 1
	chip.LayoutOrder = PINNED_BASE + index -- pinned chips first, in the order they were set
	entry.chip = chip
end

function HudController.SetPinned(key: string, template: string, n: number?, total: number?)
	local entry = pinnedEntries[key]
	if not entry then
		entry = { chip = nil, template = template, n = n, total = total, dismissible = false }
		pinnedEntries[key] = entry
		table.insert(pinnedOrder, key)
	else
		if entry.template == template and entry.n == n and entry.total == total and not entry.dismissible then
			return -- unchanged (the tutorial re-states its pin on every refresh): no re-render
		end
		entry.template = template
		entry.n = n
		entry.total = total
		entry.dismissible = false
	end
	renderPinned(key)
end

function HudController.UpdatePinned(key: string, n: number, total: number)
	local entry = pinnedEntries[key]
	if not entry then
		return
	end
	if entry.n == n and entry.total == total then
		return
	end
	entry.n = n
	entry.total = total
	renderPinned(key)
end

function HudController.ClearPinned(key: string)
	local entry = pinnedEntries[key]
	if not entry then
		return
	end
	if entry.chip then
		entry.chip:Destroy()
	end
	pinnedEntries[key] = nil
	table.remove(pinnedOrder, table.find(pinnedOrder, key) or 1)
	for index, other in pinnedOrder do
		local kept = pinnedEntries[other]
		if kept and kept.chip then
			kept.chip.LayoutOrder = PINNED_BASE + index
		end
	end
end

-- Dismissible toast: stays until its Ok button (or ClearDismissible). Same key rules as SetPinned.
function HudController.ToastDismissible(key: string, text: string)
	HudController.SetPinned(key, text)
	pinnedEntries[key].dismissible = true
	renderPinned(key)
end

function HudController.ClearDismissible(key: string)
	HudController.ClearPinned(key)
end

-- Tutorial guidance (MS-2) keeps its old name; it is the pinned kind under the key "guide".
function HudController.PinGuide(text: string)
	HudController.SetPinned("guide", text)
end

function HudController.UnpinGuide()
	HudController.ClearPinned("guide")
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
	toastStack = UiKit.toastStack(gui)
	for key in pinnedEntries do
		renderPinned(key) -- pins set before the anchor existed (Init order)
	end
	UiKit.autoScale() -- every ScreenGui (now and later) gets a responsive UIScale
end

-- Level-up banner: a big "LEVEL n" that pops in at the top centre, holds, fades. (The toast still lists what unlocked.)
local function showLevelUp(level: number)
	local screen = Instance.new("ScreenGui")
	screen.Name = "LevelUpUI"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = UiKit.LAYER.HUD
	screen.IgnoreGuiInset = true
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.27)
	box.Size = UDim2.fromOffset(300, 84)
	box.BackgroundColor3 = UiKit.DARK
	box.BackgroundTransparency = 0.05
	box.Parent = screen
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 20)
	round.Parent = box
	local border = Instance.new("UIStroke")
	border.Color = UiKit.BAMBOO
	border.Thickness = 4
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = box
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = UiKit.FONT
	text.TextSize = 44
	text.TextColor3 = Color3.fromRGB(255, 226, 120)
	text.Text = Locale.t("hud.level_banner", { level = level })
	text.Parent = box
	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = box
	screen.Parent = playerGui
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.0, function()
		local fade = TweenInfo.new(0.4)
		TweenService:Create(box, fade, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.22) }):Play()
		TweenService:Create(text, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(border, fade, { Transparency = 1 }):Play()
		task.delay(0.45, function()
			screen:Destroy()
		end)
	end)
end

-- Owner 2026-11-24 (item 6, K-89): the level-up toast and the "terbuka" lines are ONE sequence in the toast stack, one chip
-- at a time: "Naik ke Level n!" first, then one line per unlock. Each chip stays min 1.8 s, +0.05 s per character, max 5 s.
local LEVEL_MIN_SECONDS, LEVEL_PER_CHAR, LEVEL_MAX_SECONDS = 1.8, 0.05, 5
local levelLines: { string } = {}
local levelBusy = false -- one level chip on screen at a time (the sequence's one slot)

local function levelSeconds(text: string): number
	return math.clamp(LEVEL_MIN_SECONDS + LEVEL_PER_CHAR * (utf8.len(text) or #text), LEVEL_MIN_SECONDS, LEVEL_MAX_SECONDS)
end

local function pumpLevel()
	if levelBusy or #levelLines == 0 or not toastStack then
		return
	end
	levelBusy = true
	local text = table.remove(levelLines, 1) :: string
	local chip = UiKit.toastChip(toastStack, text)
	task.delay(levelSeconds(text), function()
		UiKit.toastFadeOut(chip, function()
			levelBusy = false
			pumpLevel()
		end)
	end)
end

local function queueLevelLines(vars: { [string]: any }?)
	local level = if vars then vars.level else nil
	if typeof(level) == "number" then
		table.insert(levelLines, Locale.t("level.up", { level = Locale.formatNumber(level) }))
	end
	if vars and typeof(vars.unlocks) == "table" then
		for _, key in vars.unlocks do
			if typeof(key) == "string" then
				table.insert(levelLines, Locale.t("level.unlock_line", { item = Locale.t(key) }))
			end
		end
	end
	pumpLevel()
end

function HudController.Start()
	local shownLevel = player:GetAttribute("Level")
	player:GetAttributeChangedSignal("Level"):Connect(function()
		local level = player:GetAttribute("Level")
		if typeof(level) == "number" and typeof(shownLevel) == "number" and level > shownLevel then
			showLevelUp(level)
		end
		shownLevel = level
	end)
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
			-- Redundant feedback is not shown as text: the soil and the moved bed are seen on screen, a harvest / catch / coin
			-- gain already FLIES to its place (FeedbackController). "Tanah dicangkul", "Petak dipindah", "+N Koin" and
			-- "+N kangkung" would only repeat that.
			if key == "farm.tilled" or key == "farm.moved" or key == "notify.gain" or key == "farm.harvested" then
				return
			end
			if key == "quest.done" and typeof(vars) == "table" and typeof(vars.title) == "string" then
				-- Q-3: a finished SIDE quest with a Naskah line shows its giver's line as the toast (not the title).
				local id = string.match(vars.title, "^quest%.(.+)%.title$")
				local line = if id then QuestOfferController.SideDoneText(id) else nil
				if line then
					HudController.Toast(line)
					return
				end
			end
			if key == "fish.caught" then
				-- the catch flies from the water (the middle of the screen, where the bobber is) to the Bag
				local view = (workspace.CurrentCamera :: Camera).ViewportSize
				FeedbackController.FlyToBag(Vector2.new(view.X / 2, view.Y * 0.45), Color3.fromRGB(60, 140, 176), { key = "", icon = "ikan", name = "~" })
			end
			if key == "level.up" or key == "level.up_unlocks" then
				queueLevelLines(if typeof(vars) == "table" then vars else nil)
				return
			end
			local text = Locale.t(key, resolveVars(if typeof(vars) == "table" then vars else nil))
			if key == "farm.no_seed" then
				-- T3 (K-72): out of seeds for this crop. One dismissible chip: it stays until Ok, or until seeds are bought.
				HudController.ToastDismissible("seed_out", text)
				return
			end
			if key == "shop.bought_seed" then
				HudController.ClearDismissible("seed_out")
			end
			HudController.Toast(text)
		end
	end)
end

return HudController
