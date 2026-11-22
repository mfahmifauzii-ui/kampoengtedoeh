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

-- Baris slot (Quest Harian / Mingguan): 1 baris per slot yang belum selesai.
local function addSlotRows(order: number, slots: { any }?, pool: { any }, label: string, current: string, saved: string): number
	if type(slots) ~= "table" or saved ~= current then
		return order
	end
	for _, slot in slots do
		if not slot.claimed then
			local def = nil
			for _, candidate in pool do
				if candidate.id == slot.kind then
					def = candidate
					break
				end
			end
			if def then
				order += 1
				local row = Instance.new("Frame")
				row.Name = `{label}_{def.id}`
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
				title.Text = Locale.t(`{label}.title`)
				title.Parent = row

				local step = Instance.new("TextLabel")
				step.Name = "Step"
				step.BackgroundTransparency = 1
				step.Position = UDim2.fromOffset(0, 20)
				step.Size = UDim2.new(1, 0, 0, 20)
				step.Font = UiKit.FONT
				step.TextSize = 13
				step.TextColor3 = UiKit.TEXT
				step.TextXAlignment = Enum.TextXAlignment.Left
				step.Text = `{Locale.t(`{label}.{def.id}`)}  {slot.progress}/{def.count}`
				step.Parent = row
			end
		end
	end
	return order
end

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

-- The kolam quest card (kolam_pertama) is hidden for the whole of T1b (v7.4 Bab 16.5: the pond left Tutorial 1, so
-- nothing in the tutorial tells the player to dig one). It comes back the moment T1b is over, when MQ4 / Bundel opens
-- the pond for real.
local KOLAM_QUEST = "kolam_pertama"

local function kolamCardWanted(snapshot: any): boolean
	local step = snapshot and snapshot.guide and snapshot.guide.step
	return not (step and step.id == "t1b_kolam")
end

local TRACKER_MAX = 200 -- stops above the Craft button (its top sits ~200 px up from the bottom edge)
-- The tracker is as tall as its rows (plus padding), never more than TRACKER_MAX.
local function fitTracker()
	if tracker then
		local content = tracker:FindFirstChildOfClass("UIListLayout")
		local height = if content then content.AbsoluteContentSize.Y + 16 else 0
		tracker.Size = UDim2.fromOffset(220, math.min(TRACKER_MAX, math.max(height, 0)))
	end
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
	local quests = snapshot and snapshot.quests
	if quests then
		order = addSlotRows(order, quests.harian and quests.harian.slots, Quests.HARIAN, "quest_harian", TimeKeys.day(os.time() - Quests.DAILY_RESET_HOUR * 3600), quests.harian and quests.harian.day or "")
		order = addSlotRows(order, quests.mingguan and quests.mingguan.slots, Quests.MINGGUAN, "quest_mingguan", TimeKeys.week(os.time() - Quests.DAILY_RESET_HOUR * 3600), quests.mingguan and quests.mingguan.week or "")
		local surat = quests.surat
		if surat and surat.n > 0 then
			order += 1
			local row = Instance.new("Frame")
			row.Name = "surat"
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
			title.Text = `{Locale.t("surat.title")} #{surat.n}`
			title.Parent = row
			local step = Instance.new("TextLabel")
			step.Name = "Step"
			step.BackgroundTransparency = 1
			step.Position = UDim2.fromOffset(0, 20)
			step.Size = UDim2.new(1, 0, 0, 20)
			step.Font = UiKit.FONT
			step.TextSize = 13
			step.TextColor3 = UiKit.TEXT
			step.TextXAlignment = Enum.TextXAlignment.Left
			step.Text = `{surat.progress}/{surat.need}`
			step.Parent = row
		end
	end
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
	-- Owner (2026-11-22): the list ran over the Craft button and the XP card. Its height follows the rows (see
	-- fitTracker) but never goes past TRACKER_MAX, which stops above Craft (Craft sits 200 px up from the bottom); the rest
	-- is clipped, so nothing draws over the buttons.
	tracker.AutomaticSize = Enum.AutomaticSize.None
	tracker.ClipsDescendants = true
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
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitTracker)

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
