--!strict
-- Quest tracker: a small card under the HUD level bar listing every active quest with its current step.
-- UI contract (replace with your designed UI, keep the names):
--   ScreenGui "QuestUI" > Frame "Tracker" (rows are rebuilt from State; each row has TextLabel "Title" and "Step").
-- The server owns quest state (QuestService); this only displays State.current.quests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local QuestController = {}

local tracker: Frame

-- Stage 7: the Daily row ("Misi Harian  2/5"). Shown only for today's daily; the server re-rolls it after 05:00 WIB.
local function addDailyRow(order: number)
	local snapshot = State.current :: any
	local daily = snapshot and snapshot.quests and snapshot.quests.daily
	if not daily or daily.kind == nil or daily.kind == "" then
		return
	end
	if daily.day ~= TimeKeys.day(os.time() - Quests.DAILY_RESET_HOUR * 3600) then
		return
	end
	local def = nil
	for _, candidate in Quests.DAILY do
		if candidate.id == daily.kind then
			def = candidate
		end
	end
	if not def then
		return
	end

	local row = Instance.new("Frame")
	row.Name = "daily"
	row.LayoutOrder = order
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 46)
	row.Parent = tracker

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Font = UiKit.FONT
	title.TextSize = 14
	title.TextColor3 = UiKit.TEXT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = Locale.t("daily.title")
	title.Parent = row

	local step = Instance.new("TextLabel")
	step.Name = "Step"
	step.BackgroundTransparency = 1
	step.Position = UDim2.new(0, 0, 0, 20)
	step.Size = UDim2.new(1, 0, 0, 20)
	step.Font = UiKit.FONT
	step.TextSize = 13
	step.TextColor3 = UiKit.TEXT
	step.TextXAlignment = Enum.TextXAlignment.Left
	step.Text = `{Locale.t("daily." .. def.id)}  {daily.progress}/{def.count}`
	step.Parent = row
end

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

-- The kolam quest card (kolam_pertama) is part of the t1b land step: it shows only once the player stands on his land
-- (bangun_kolam, 60 studs from the plot centre), together with Mak Sari's line. Before that there is no card at all.
local KOLAM_QUEST = "kolam_pertama"
local function inOwnLand(): boolean
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	for _, plot in workspace.Plots:GetChildren() do
		if plot:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
			local center = plot:GetPivot().Position
			return (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude <= 60
		end
	end
	return false
end

local function kolamCardWanted(snapshot: any): boolean
	local step = snapshot and snapshot.guide and snapshot.guide.step
	if not step or step.id ~= "t1b_kolam" then
		return true
	end
	if (step.n or 0) < 4 then
		return false -- before bangun_kolam (warung, Kak Fajar, mancing, after_catch)
	end
	if (step.n or 0) == 4 then
		return inOwnLand() -- bangun_kolam is the current step: only on the land
	end
	return true -- bangun_kolam done: the card stays
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
			if progress and (quest.id ~= KOLAM_QUEST or kolamCardWanted(snapshot)) then
				order += 1
				addRow(order, quest.id, progress)
			end
		end
	end
	addDailyRow(order + 1)
	tracker.Visible = order > 0 or tracker:FindFirstChild("daily") ~= nil
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
	-- Walking onto the land changes the kolam card without a state sync: check a few times a second, rebuild only on a change.
	task.spawn(function()
		local last: boolean? = nil
		while true do
			local wanted = kolamCardWanted(State.current)
			if wanted ~= last then
				last = wanted
				refresh()
			end
			task.wait(0.5)
		end
	end)
end

return QuestController
