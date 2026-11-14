--!strict
-- Quest tracker: a small card under the HUD level bar listing every active quest with its current step.
-- UI contract (replace with your designed UI, keep the names):
--   ScreenGui "QuestUI" > Frame "Tracker" (rows are rebuilt from State; each row has TextLabel "Title" and "Step").
-- The server owns quest state (QuestService); this only displays State.current.quests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local QuestController = {}

local tracker: Frame

local function addRow(order: number, questId: string, progress: { step: number, count: number })
	local quest = Quests.byId[questId]
	local step = quest and quest.steps[progress.step]
	if not quest or not step then
		return
	end

	local row = Instance.new("Frame")
	row.Name = questId
	row.LayoutOrder = order
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 46)
	row.Parent = tracker

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 20)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = UiKit.TEXT
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.Text = Locale.t(`quest.{questId}.title`)
	title.Parent = row

	local text = Instance.new("TextLabel")
	text.Name = "Step"
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(0, 20)
	text.Size = UDim2.new(1, 0, 0, 24)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.TextColor3 = UiKit.TEXT
	text.TextTransparency = 0.15
	text.Font = Enum.Font.Gotham
	text.TextSize = 13
	text.Text = Locale.t(`quest.{questId}.s{progress.step}`, { n = step.count })
		.. (if step.count > 1 then ` ({progress.count}/{step.count})` else "")
	text.Parent = row
end

local function refresh()
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snapshot = State.current :: any
	local active = snapshot and snapshot.quests and snapshot.quests.active
	local order = 0
	-- Stable order: follow the definition list, not pairs() order.
	if active then
		for _, quest in Quests.list do
			local progress = active[quest.id]
			if progress then
				order += 1
				addRow(order, quest.id, progress)
			end
		end
	end
	tracker.Visible = order > 0
end

function QuestController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "QuestUI"
	gui.ResetOnSpawn = false

	tracker = Instance.new("Frame")
	tracker.Name = "Tracker"
	tracker.Position = UDim2.fromOffset(12, 118) -- under the status row and the goal chip
	tracker.Size = UDim2.fromOffset(220, 0)
	tracker.AutomaticSize = Enum.AutomaticSize.Y
	tracker.BackgroundColor3 = UiKit.BG
	tracker.BackgroundTransparency = 0.25
	tracker.Visible = false
	tracker.Parent = gui
	Instance.new("UICorner").Parent = tracker

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = tracker

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = tracker

	gui.Parent = player:WaitForChild("PlayerGui")
end

function QuestController.Start()
	State.Changed:Connect(refresh)
	refresh()
end

return QuestController
