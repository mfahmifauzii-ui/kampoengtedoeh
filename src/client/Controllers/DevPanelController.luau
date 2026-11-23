--!strict
-- DEV panel (Putaran 2, owner request): an on-screen version of the DEV chat commands. Shows only when the server set the
-- player attribute "DevAllowed" (DevService.IsAllowed: Studio, or the owner's account while LIVE_ENABLED). Every button sends
-- the same text as the chat command through the DevCmd remote; the server checks IsAllowed again.
-- Collapsed = one small "DEV" tab on the left edge (it does not cover the HUD). Expanded = a scrolling list of buttons.
-- Reset asks for a second tap.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DevScenarios = require(ReplicatedStorage.Shared.Config.DevScenarios)
local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local DevPanelController = {}

local WEATHER = { "cerah", "gerimis", "deres", "petir" }
local PHASE = { "pagi", "siang", "sore", "malam" }

local list: ScrollingFrame? = nil
local resetArmed = false
local weatherIndex = 0
local phaseIndex = 0

local function send(text: string)
	Net.Send("DevCmd", text)
end

local function button(parent: Instance, text: string, onTap: () -> ()): TextButton
	local b = UiKit.button(parent, "DevBtn", text)
	b.Size = UDim2.new(1, -8, 0, 40)
	b.TextSize = 15
	b.Activated:Connect(onTap)
	return b
end

local render: () -> ()
local showSub: (kind: string) -> ()

-- The two submenus: teleport to an NPC and run a scenario preset. Both are lists of DEV commands.
showSub = function(kind: string)
	if not list then
		return
	end
	UiKit.clear(list)
	local ids = {}
	if kind == "teleport" then
		for id in Npcs.byId do
			table.insert(ids, id)
		end
	else
		for name in DevScenarios do
			table.insert(ids, name)
		end
	end
	table.sort(ids)
	button(list, "< Kembali", function()
		render()
	end)
	for _, id in ids do
		button(list, id, function()
			if kind == "teleport" then
				send("!teleport " .. id)
			else
				send("!skenario " .. id)
			end
		end)
	end
end

render = function()
	if not list then
		return
	end
	UiKit.clear(list)
	local level = player:GetAttribute("Level")
	local nextLevel = if typeof(level) == "number" then level + 1 else 2
	button(list, "Status (!state)", function()
		send("!state")
	end)
	button(list, "Lewati tutorial", function()
		send("!skip tutorial")
	end)
	button(list, `Level +1 (ke {nextLevel})`, function()
		send(`!level {nextLevel}`)
	end)
	button(list, "Koin +1000", function()
		send("!koin 1000")
	end)
	button(list, "Buka semua fitur", function()
		send("!buka semua")
	end)
	button(list, "Cuaca: ganti", function()
		weatherIndex = weatherIndex % #WEATHER + 1
		send("!cuaca " .. WEATHER[weatherIndex])
	end)
	button(list, "Waktu: ganti", function()
		phaseIndex = phaseIndex % #PHASE + 1
		send("!time " .. PHASE[phaseIndex])
	end)
	button(list, "Tumbuh (semua)", function()
		send("!grow")
	end)
	button(list, "Hari +1", function()
		send("!hari +1")
	end)
	button(list, "Teleport ke NPC >", function()
		showSub("teleport")
	end)
	button(list, "Skenario >", function()
		showSub("scenario")
	end)
	local reset = button(list, if resetArmed then "Ketuk lagi: RESET progres" else "Reset progres", function()
		if resetArmed then
			resetArmed = false
			send("!reset")
		else
			resetArmed = true
			render()
		end
	end)
	reset.BackgroundColor3 = if resetArmed then Color3.fromRGB(190, 70, 60) else reset.BackgroundColor3
end

function DevPanelController.Init()
	if player:GetAttribute("DevAllowed") ~= true then
		return
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = "DevPanel"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = UiKit.LAYER.HUD
	screen.IgnoreGuiInset = true
	screen.Parent = player:WaitForChild("PlayerGui")

	-- the small tab on the left edge (middle height)
	local tab = Instance.new("TextButton")
	tab.Name = "DevTab"
	tab.Text = "DEV"
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 12
	tab.TextColor3 = Color3.fromRGB(255, 245, 220)
	tab.BackgroundColor3 = Color3.fromRGB(60, 46, 30)
	tab.BackgroundTransparency = 0.15
	tab.AnchorPoint = Vector2.new(0, 0.5)
	tab.Position = UDim2.new(0, 2, 0.62, 0)
	tab.Size = UDim2.fromOffset(40, 28)
	tab.Parent = screen
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tab

	-- the panel: a list of buttons on the left edge, hidden until the tab is tapped
	local frame = Instance.new("Frame")
	frame.Name = "DevBody"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.Position = UDim2.new(0, 46, 0.5, 0)
	frame.Size = UDim2.fromOffset(190, 300)
	frame.BackgroundColor3 = Color3.fromRGB(44, 34, 22)
	frame.BackgroundTransparency = 0.05
	frame.Visible = false
	frame.Parent = screen
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = frame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "DevList"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(4, 4)
	scroll.Size = UDim2.new(1, -8, 1, -8)
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 4
	scroll.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = scroll
	list = scroll

	tab.Activated:Connect(function()
		frame.Visible = not frame.Visible
		if frame.Visible then
			resetArmed = false
			render()
		end
	end)
end

return DevPanelController
