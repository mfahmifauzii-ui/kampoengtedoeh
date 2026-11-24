--!strict
-- Settings panel (HUD "SettingsButton" / placeholder "Atur"): music, nature sounds, SFX.
-- Values are saved on the server and come back through the state snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local GuideController = require(script.Parent.GuideController)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local KEYS = { "music", "ambient", "sfx" }

local SettingsController = {}

local panel: UiKit.Panel
local guidePanel: UiKit.Panel

-- Atur > Panduan: every tutorial with its state; tap "Ulang" to run it again (no rewards).
local function renderGuide()
	if not guidePanel.gui.Enabled then
		return
	end
	UiKit.clear(guidePanel.list)
	local entries = GuideController.List()
	if #entries == 0 then
		UiKit.row(guidePanel.list, 1, Locale.t("tut.list_empty"), nil, nil, false, nil)
		return
	end
	local busy = GuideController.IsRunning()
	for order, entry in entries do
		UiKit.row(guidePanel.list, order, Locale.t(entry.title), Locale.t(`tut.state.{entry.state}`), Locale.t("tut.replay"), not busy, function()
			if GuideController.Replay(entry.id) then
				guidePanel.gui.Enabled = false
				panel.gui.Enabled = false
			end
		end)
	end
end

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	local settings = snapshot and snapshot.settings or {}
	-- Two columns of cards: name on the left, a switch on the right (green + knob right = on). No "Nyala/Mati" words to decode.
	local grid = UiKit.grid(panel.list, 1, 1, 52) -- one column, full width: a vertical list (Atur is a list, not a dashboard)
	local ICONS = { music = "bintang", ambient = "bunga", sfx = "koin" }
	local function card(order: number, text: string, accent: Color3): Frame
		local cell = Instance.new("Frame")
		cell.LayoutOrder = order
		cell.BackgroundColor3 = if order % 2 == 0 then UiKit.ROW_ALT else UiKit.ROW
		cell.Parent = grid
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, 10)
		round.Parent = cell
		local line = Instance.new("UIStroke")
		line.Color = Color3.fromRGB(222, 200, 154)
		line.Thickness = 1.5
		line.Parent = cell
		UiKit.accentStripe(cell, accent)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromOffset(18, 0)
		label.Size = UDim2.new(1, -90, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = UiKit.FONT
		label.TextSize = 15
		label.TextColor3 = UiKit.TEXT
		label.Text = text
		label.Parent = cell
		return cell
	end
	local accents = { UiKit.CAT.decor, UiKit.CAT.crop, UiKit.CAT.fish }
	for order, key in KEYS do
		local on = settings[key] ~= false
		local cell = card(order, Locale.t(`settings.{key}`), accents[order])
		UiKit.switch(cell, on, function(value)
			Net.Send("SettingsSet", key, value)
		end)
	end
	-- Toast Gerobak Kaget bisa dimatikan (Bab 13.1, P2-6).
	do
		local on = settings.gerobak ~= false
		local cell = card(#KEYS + 1, Locale.t("settings.gerobak"), UiKit.CAT.tool)
		UiKit.switch(cell, on, function(value)
			Net.Send("SettingsSet", "gerobak", value)
		end)
	end
	-- K-121: Kurangi gerak (off by default). On = no sliding or flashing in the UI (GUI 4.11).
	do
		local cell = card(#KEYS + 2, Locale.t("settings.reduceMotion"), UiKit.CAT.tool)
		UiKit.switch(cell, settings.reduceMotion == true, function(value)
			Net.Send("SettingsSet", "reduceMotion", value)
		end)
	end
	local guide = card(#KEYS + 3, Locale.t("settings.guide"), UiKit.CAT.tool)
	local open = UiKit.button(guide, "Open", Locale.t("settings.guide_open"), UiKit.BUTTON)
	open.AnchorPoint = Vector2.new(1, 0.5)
	open.Position = UDim2.new(1, -8, 0.5, 0)
	open.Size = UDim2.fromOffset(66, 32)
	open.TextSize = 14
	open.Activated:Connect(function()
		guidePanel.gui.Enabled = true
		renderGuide()
	end)

	-- Shrink the panel to its content (AutomaticSize behaviour for Atur only): 2 columns of cards, 58 px per row. The frame
	-- keeps the title ribbon above and a small margin below; it never grows past the screen (UISizeConstraint in UiKit).
	local rows = #KEYS + 3 -- 3 toggles + gerobak + kurangi gerak + panduan
	local body = rows * 58
	panel.list.Size = UDim2.new(1, -52, 0, body)
	panel.list.ScrollBarThickness = 0 -- the content fits: no scrollbar
	local frame = panel.gui:FindFirstChild("Panel") :: Frame?
	if frame then
		frame.Size = UDim2.new(0.88, 0, 0, 40 + body + 18)
	end
end

function SettingsController.Init()
	panel = UiKit.panel("SettingsPanel", Locale.t("ui.settings"), function()
		panel.gui.Enabled = false
	end)
	guidePanel = UiKit.panel("GuidePanel", Locale.t("ui.guide"), function()
		guidePanel.gui.Enabled = false
	end)
end

function SettingsController.Start()
	State.Changed:Connect(function()
		render()
		renderGuide()
	end)
	GuideController.Changed:Connect(renderGuide)
	task.spawn(UiKit.hudButton, "SettingsButton", Locale.t("ui.settings"), 5, function()
		panel.gui.Enabled = not panel.gui.Enabled
		render()
	end)
end

return SettingsController
