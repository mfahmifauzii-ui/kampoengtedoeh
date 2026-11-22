--!strict
-- Quest tracker and Quest Log (Q-4, GUI doc v0.1 Bab 4.5 / 6.8).
--   Tracker: a small card under the HUD level bar. Main quests on top, then Side, then Harian / Mingguan / surat.
--            A row is 32 px (UiKit.TOUCH_ROW) and a tap on it opens the Quest Log on that quest's tab.
--            "Tunjukkan" is a 24 px link (UiKit.TOUCH_MIN) on the top row. At most 3 rows, the rest is "+N lainnya".
--   Quest Log: UiKit.panel with tabs Main / Side. A tab with no quest is not drawn. Built when opened and destroyed when
--            closed (no invisible instance is kept). Sections: Aktif, Tersedia (server offers), Selesai, Berikutnya (??? until level).
-- UI contract (keep the names): ScreenGui "QuestUI" (DisplayOrder = UiKit.LAYER.HUD) > Frame "Tracker"; rows have
-- TextLabel "Title" and "Step".
-- The server owns quest state (QuestService); this only displays State.current.quests and the QuestOffers list.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local State = require(script.Parent.Parent.State)
local FeatureClient = require(script.Parent.Parent.FeatureClient)
local UiKit = require(script.Parent.Parent.UiKit)
local QuestOfferController = require(script.Parent.QuestOfferController)
local WorldArrow = require(script.Parent.Parent.WorldArrow)

local player = Players.LocalPlayer

local QuestController = {}

local tracker: Frame

-- A tracker row stacks its title and its step on a vertical list. Text wraps and the row grows to fit, so nothing is cut
-- at the edge (Bug: "Ikut 10 Kerja Bakti" was clipped). "Tunjukkan" sits over the top-right corner (see refresh).
local function listRow(row: Frame)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
end
local refresh: () -> ()
local logPanel: any = nil -- the open Quest Log (UiKit.panel), nil while closed
local logTab: string = "main"
-- Bug 6: Kerja Bakti (side_kerjabakti) has no step hint of its own. Its existing copy (kb.active / kb.none, kb.how) tells what
-- to do and when; "Tunjukkan" on it points at a trash spot while the event runs.
local KB_QUEST = "side_kerjabakti"
local kbArrow: any = nil

local pointedQuest: string? = nil -- the quest whose step is pointed at ("Tunjukkan"), until its timer ends

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
				row.Size = UDim2.new(1, 0, 0, 0)
				row.AutomaticSize = Enum.AutomaticSize.Y
				listRow(row)
				row.Parent = tracker

				local title = Instance.new("TextLabel")
				title.Name = "Title"
				title.BackgroundTransparency = 1
				title.Size = UDim2.new(1, 0, 0, 0)
				title.AutomaticSize = Enum.AutomaticSize.Y
				title.TextWrapped = true
				title.LayoutOrder = 1
				title.Font = UiKit.FONT
				title.TextSize = 13
				title.TextColor3 = UiKit.TEXT
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.Text = Locale.t(`{label}.title`)
				title.Parent = row

				local step = Instance.new("TextLabel")
				step.Name = "Step"
				step.BackgroundTransparency = 1
				step.Size = UDim2.new(1, 0, 0, 0)
				step.AutomaticSize = Enum.AutomaticSize.Y
				step.TextWrapped = true
				step.LayoutOrder = 2
				step.Font = UiKit.FONT
				step.TextSize = 12
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
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	listRow(row)
	row.Parent = tracker

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.TextWrapped = true
	title.LayoutOrder = 1
	title.Font = UiKit.FONT
	title.TextSize = 13
	title.TextColor3 = UiKit.TEXT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = Locale.t("daily.title")
	title.Parent = row

	local step = Instance.new("TextLabel")
	step.Name = "Step"
	step.BackgroundTransparency = 1
	step.Size = UDim2.new(1, 0, 0, 0)
	step.AutomaticSize = Enum.AutomaticSize.Y
	step.TextWrapped = true
	step.LayoutOrder = 2
	step.Font = UiKit.FONT
	step.TextSize = 12
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
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	listRow(row)
	row.Parent = tracker

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.TextWrapped = true
	title.LayoutOrder = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = UiKit.TEXT
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 13
	title.Text = Locale.t(`quest.{questId}.title`)
	title.Parent = row

	local text = Instance.new("TextLabel")
	text.Name = "Step"
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 0, 0)
	text.AutomaticSize = Enum.AutomaticSize.Y
	text.TextWrapped = true
	text.LayoutOrder = 2
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.TextColor3 = UiKit.TEXT
	text.TextTransparency = 0.15
	text.Font = Enum.Font.FredokaOne
	text.TextSize = 12
	text.Text = Locale.t(`quest.{questId}.s{progress.step}`, { n = step.count })
		.. (if step.count > 1 then ` ({progress.count}/{step.count})` else "")
	text.Parent = row
end

-- The kolam quest card (kolam_pertama) is hidden for the whole of T1b (v7.4 Bab 16.5: the pond left Tutorial 1, so
-- nothing in the tutorial tells the player to dig one). It comes back the moment T1b is over, when MQ4 / Bundel opens
-- the pond for real.
local KOLAM_QUEST = "kolam_pertama"

-- Playtest 7: no quest UI (tracker, Harian/Mingguan rows, Agenda, Surat) until the tutorial is finished or skipped.
local function tutorialDone(snapshot: any): boolean
	local guide = snapshot and snapshot.guide
	return guide ~= nil and (guide.done.t1b_kolam == true or guide.skipped.t1b_kolam == true)
end

local function kolamCardWanted(snapshot: any): boolean
	local step = snapshot and snapshot.guide and snapshot.guide.step
	return not (step and step.id == "t1b_kolam")
end

local MAX_HEIGHT_PX = 200 -- top limit in px (stops above the Craft button)
local MAX_HEIGHT_SCREEN = 0.25 -- top limit as a share of the screen height (Update owner 2026-11-22, Task 5)
local MAX_ROWS = 3 -- at most 3 quest rows; the rest collapse into one "+N lainnya" row

-- The tracker is as tall as its rows (plus padding), never more than min(MAX_HEIGHT_PX, MAX_HEIGHT_SCREEN x screen height).
local function maxHeight(): number
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize.Y else MAX_HEIGHT_PX / MAX_HEIGHT_SCREEN
	return math.min(MAX_HEIGHT_PX, MAX_HEIGHT_SCREEN * viewport)
end

local function fitTracker()
	if tracker then
		local content = tracker:FindFirstChildOfClass("UIListLayout")
		local height = if content then content.AbsoluteContentSize.Y + 16 else 0
		tracker.Size = UDim2.fromOffset(UiKit.HUD.TRACKER_W, math.min(maxHeight(), math.max(height, 0)))
	end
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Quest Log
-- ---------------------------------------------------------------------------------------------------------------------

type LogRow = { title: string, sub: string, pointable: boolean, questId: string? }
type LogSection = { heading: string, rows: { LogRow } }

-- The sections of one kind ("main" / "side"): Aktif, Tersedia, Selesai, Berikutnya. Empty sections are left out.
local function logSections(kind: string, snapshot: any): { LogSection }
	local quests = snapshot and snapshot.quests
	local levelValue = player:GetAttribute("Level")
	local level = if typeof(levelValue) == "number" then levelValue else 1
	local offerSet: { [string]: boolean } = {}
	for _, id in QuestOfferController.Offers() do
		offerSet[id] = true
	end
	local active: { LogRow } = {}
	local offered: { LogRow } = {}
	local done: { LogRow } = {}
	local later: { LogRow } = {}
	for _, quest in Quests.list do
		if quest.kind == kind and quest.blocked == nil then
			local progress = if quests and quests.active then quests.active[quest.id] else nil
			if progress then
				local step = quest.steps[progress.step]
				local sub = ""
				if step then
					sub = Locale.t(`quest.{quest.id}.s{progress.step}`, { n = step.count })
						.. (if step.count > 1 then ` ({progress.count}/{step.count})` else "")
				end
				table.insert(active, { title = Locale.t(`quest.{quest.id}.title`), sub = sub, pointable = true, questId = quest.id })
				if quest.id == KB_QUEST then
					-- Bug 6: the hint row. Status (running / not now) and the existing how-to line.
					local running = Workspace:GetAttribute("KBActive") == true
					table.insert(active, { title = Locale.t(if running then "kb.active" else "kb.none"), sub = Locale.t("kb.how"), pointable = false, questId = nil })
				end
			elseif quests and quests.done and quests.done[quest.id] == true then
				table.insert(done, { title = Locale.t(`quest.{quest.id}.title`), sub = Locale.t("banner.done"), pointable = false, questId = nil })
			elseif offerSet[quest.id] then
				table.insert(offered, { title = Locale.t(`quest.{quest.id}.title`), sub = Locale.t(`npc.{quest.giver}`), pointable = false, questId = nil })
			elseif kind == "main" and quest.auto ~= true and level < quest.unlockLevel then
				-- GUI doc 6.8: the next Main quest is shown as ??? until the level reaches it.
				table.insert(later, { title = "???", sub = `Lv {quest.unlockLevel}`, pointable = false, questId = nil })
			end
		end
	end
	local sections: { LogSection } = {}
	if #active > 0 then
		table.insert(sections, { heading = Locale.t("quest.log.active"), rows = active })
	end
	if #offered > 0 then
		table.insert(sections, { heading = Locale.t("quest.log.offered"), rows = offered })
	end
	if #done > 0 then
		table.insert(sections, { heading = Locale.t("banner.done"), rows = done })
	end
	if kind == "main" and #later > 0 then
		table.insert(sections, { heading = Locale.t("quest.log.next"), rows = later })
	end
	return sections
end

local function closeLog()
	if logPanel then
		local gui = logPanel.gui
		logPanel = nil
		UiKit.closePanel(gui)
	end
end

-- "Tunjukkan" from the Quest Log: close the log and point at the quest's step on the tracker.
local function kbSpot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, descendant in Workspace:GetDescendants() do
		if descendant.Name == "Sampah" and descendant:IsA("BasePart") then
			local distance = if root and root:IsA("BasePart") then (descendant.Position - root.Position).Magnitude else 0
			if distance < bestDistance then
				best, bestDistance = descendant, distance
			end
		end
	end
	return best
end

local function pointAt(questId: string)
	closeLog()
	pointedQuest = questId
	-- Bug 6: while Kerja Bakti runs, the arrow points at the nearest trash spot.
	if questId == KB_QUEST and Workspace:GetAttribute("KBActive") == true then
		local spot = kbSpot()
		if spot then
			if not kbArrow then
				kbArrow = WorldArrow.new("KBArrow", 4)
			end
			kbArrow.show(spot, Locale.t("kb.active"))
		end
	end
	refresh()
	task.delay(4, function()
		pointedQuest = nil
		if kbArrow then
			kbArrow.hide()
		end
		refresh()
	end)
end

local function renderLog()
	if not logPanel then
		return
	end
	UiKit.clear(logPanel.list)
	local snapshot = State.current :: any
	local mainSections = logSections("main", snapshot)
	local sideSections = logSections("side", snapshot)
	local defs = {}
	if #mainSections > 0 then
		table.insert(defs, { id = "main", text = Locale.t("quest.log.tab_main") })
	end
	if #sideSections > 0 then
		table.insert(defs, { id = "side", text = Locale.t("quest.log.tab_side") })
	end
	if #defs == 0 then
		UiKit.header(logPanel.list, "—", 1)
		return
	end
	-- Only tabs with quests are drawn; the open tab falls back to the first one that has any.
	local hasTab = false
	for _, def in defs do
		if def.id == logTab then
			hasTab = true
		end
	end
	if not hasTab then
		logTab = defs[1].id
	end
	local order = 1
	if #defs > 1 then
		local bar = UiKit.tabs(logPanel.list, defs, logTab, function(id: string)
			logTab = id
			renderLog()
		end)
		bar.frame.LayoutOrder = order
		order += 1
	end
	for _, section in (if logTab == "side" then sideSections else mainSections) do
		UiKit.header(logPanel.list, section.heading, order)
		order += 1
		for _, row in section.rows do
			local questId = row.questId
			local point = if row.pointable and questId then function()
				pointAt(questId)
			end else nil
			UiKit.row(logPanel.list, order, row.title, row.sub, if point then Locale.t("quest.point") else nil, true, point)
			order += 1
		end
	end
end

local function openLog(kind: string)
	logTab = kind
	if not logPanel then
		logPanel = UiKit.panel("QuestLog", Locale.t("quest.log.title"), closeLog)
		logPanel.gui.Enabled = true
	end
	renderLog()
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Tracker
-- ---------------------------------------------------------------------------------------------------------------------

-- The tracker shows when it has at least one row (a quest, a slot row, the daily or surat row).
local function hasRows(): boolean
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") then
			return true
		end
	end
	return false
end

-- A tap on a quest row opens the Quest Log on that quest's tab. The row's text stays on top (drawn after the tap area).
local function addTapArea(row: Frame, kind: string)
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.Text = ""
	tap.AutoButtonColor = false
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = 1
	tap.Parent = row
	tap.Activated:Connect(function()
		openLog(kind)
	end)
end

local function buildRows()
	local snapshot = State.current :: any
	local active = snapshot and snapshot.quests and snapshot.quests.active
	local order = 0
	-- Stable order: follow the definition list, not pairs() order.
	-- Playtest item 6: the active MAIN quest is always the top row (then side quests, in list order). The top row gets the
	-- "Tunjukkan" button: it points at that quest's step for a few seconds (the step text turns gold).
	if active then
		local mains: { string } = {}
		local sides: { string } = {}
		for _, quest in Quests.list do
			local progress = active[quest.id]
			if progress and (quest.id ~= KOLAM_QUEST or kolamCardWanted(snapshot)) then
				if quest.kind == "main" then
					table.insert(mains, quest.id)
				else
					table.insert(sides, quest.id)
				end
			end
		end
		for _, questId in mains do
			order += 1
			addRow(order, questId, active[questId])
		end
		for _, questId in sides do
			order += 1
			addRow(order, questId, active[questId])
		end
	end
	addDailyRow(order + 1)
	local quests = snapshot and snapshot.quests
	if quests then
		order = addSlotRows(order, quests.harian and quests.harian.slots, Quests.HARIAN, "quest_harian", TimeKeys.day(os.time() - Quests.DAILY_RESET_HOUR * 3600), quests.harian and quests.harian.day or "")
		order = addSlotRows(order, quests.mingguan and quests.mingguan.slots, Quests.MINGGUAN, "quest_mingguan", TimeKeys.week(os.time() - Quests.DAILY_RESET_HOUR * 3600), quests.mingguan and quests.mingguan.week or "")
		local surat = quests.surat
		-- Q-2 gate "surat" (client only: the server has no FeatureGate check for surat): row not built while closed.
		if surat and surat.n > 0 and FeatureClient.IsOpen("surat") then
			order += 1
			local row = Instance.new("Frame")
			row.Name = "surat"
			row.LayoutOrder = order
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			listRow(row)
			row.Parent = tracker
			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.BackgroundTransparency = 1
			title.Size = UDim2.new(1, 0, 0, 0)
			title.AutomaticSize = Enum.AutomaticSize.Y
			title.TextWrapped = true
			title.LayoutOrder = 1
			title.Font = UiKit.FONT
			title.TextSize = 13
			title.TextColor3 = UiKit.TEXT
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Text = `{Locale.t("surat.title")} #{surat.n}`
			title.Parent = row
			local step = Instance.new("TextLabel")
			step.Name = "Step"
			step.BackgroundTransparency = 1
			step.Size = UDim2.new(1, 0, 0, 0)
			step.AutomaticSize = Enum.AutomaticSize.Y
			step.TextWrapped = true
			step.LayoutOrder = 2
			step.Font = UiKit.FONT
			step.TextSize = 12
			step.TextColor3 = UiKit.TEXT
			step.TextXAlignment = Enum.TextXAlignment.Left
			step.Text = `{surat.progress}/{surat.need}`
			step.Parent = row
		end
	end
end

function refresh()
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snapshot = State.current :: any
	if not tutorialDone(snapshot) then
		tracker.Visible = false
		if logPanel then
			closeLog() -- no quest UI during the tutorial
		end
		return
	end
	buildRows()
	-- Show at most MAX_ROWS rows; the rest collapse into one "+N lainnya" row.
	local rows = {} :: { Instance }
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") then
			table.insert(rows, child)
		end
	end
	table.sort(rows, function(a, b)
		return (a :: any).LayoutOrder < (b :: any).LayoutOrder
	end)
	if #rows > MAX_ROWS then
		for index = MAX_ROWS + 1, #rows do
			rows[index]:Destroy()
		end
		local more = Instance.new("Frame")
		more.Name = "more"
		more.LayoutOrder = MAX_ROWS + 1
		more.BackgroundTransparency = 1
		more.Size = UDim2.new(1, 0, 0, UiKit.TOUCH_ROW)
		more.Parent = tracker
		local text = Instance.new("TextLabel")
		text.Name = "Title"
		text.BackgroundTransparency = 1
		text.Size = UDim2.new(1, 0, 1, 0)
		text.Font = UiKit.FONT
		text.TextSize = 12
		text.TextColor3 = UiKit.TEXT
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Text = Locale.t("quest.more", { n = #rows - MAX_ROWS })
		text.Parent = more
	end
	-- Tap area on every quest row (not on Harian / Mingguan / surat rows).
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") then
			local quest = Quests.byId[child.Name]
			if quest and not child:FindFirstChild("Tap") then
				addTapArea(child, quest.kind)
			end
		end
	end
	-- The top row gets the "Tunjukkan" button (once; rebuilt with the rows).
	local topRow = nil
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") and child.LayoutOrder == 1 and child.Name ~= "daily" and child.Name ~= "surat" then
			topRow = child
		end
	end
	if topRow then
		local point = Instance.new("TextButton")
		point.Name = "PointButton"
		point.AnchorPoint = Vector2.new(1, 0)
		point.Position = UDim2.new(1, 0, 0, 0)
		point.Size = UDim2.fromOffset(74, UiKit.TOUCH_MIN)
		point.BackgroundTransparency = 0.25
		point.BackgroundColor3 = UiKit.DARK
		point.Font = UiKit.FONT
		point.TextSize = 12
		point.TextColor3 = UiKit.CREAM
		point.Text = Locale.t("quest.point")
		point.ZIndex = 3
		point.Parent = topRow
		local topName: string = topRow.Name
		-- Bug 10: the step and title text stop before the Tunjukkan button (74 px + 8 px gap), so they never run under it.
		for _, label in topRow:GetChildren() do
			if label:IsA("TextLabel") then
				label.Size = UDim2.new(1, -82, 0, 0) -- keeps clear of the Tunjukkan button; the height follows the wrapped text
			end
		end
		point.Activated:Connect(function()
			pointAt(topName)
		end)
	end
	-- Readable without a panel: cream text with a dark outline on every label of the tracker.
	for _, label in tracker:GetDescendants() do
		if label:IsA("TextLabel") then
			label.TextColor3 = UiKit.CREAM
			label.TextStrokeColor3 = UiKit.DARK
			label.TextStrokeTransparency = 0
		end
	end
	-- Tunjukkan: the pointed quest's step text turns gold while its timer runs.
	if pointedQuest then
		local pointed = tracker:FindFirstChild(pointedQuest)
		local stepLabel = pointed and pointed:FindFirstChild("Step")
		if stepLabel and stepLabel:IsA("TextLabel") then
			stepLabel.TextColor3 = Color3.fromRGB(255, 226, 120)
		end
	end
	tracker.Visible = hasRows()
	if logPanel then
		renderLog()
	end
end

function QuestController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "QuestUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = UiKit.LAYER.HUD -- GUI doc 4.5: quest tracker is a HUD layer (20)

	tracker = Instance.new("Frame")
	tracker.Name = "Tracker"
	tracker.Position = UDim2.fromOffset(UiKit.HUD.MARGIN, UiKit.HUD.TRACKER_TOP) -- HUD map: left column
	tracker.Size = UDim2.fromOffset(UiKit.HUD.TRACKER_W, 0)
	-- Owner (2026-11-22): the list ran over the Craft button and the XP card. Its height follows the rows (see
	-- fitTracker) but never goes past maxHeight (200 px or 25 % of the screen), which stops above Craft (Craft sits 200 px up from the bottom); the rest
	-- is clipped, so nothing draws over the buttons.
	tracker.AutomaticSize = Enum.AutomaticSize.None
	tracker.ClipsDescendants = true
	tracker.BackgroundColor3 = UiKit.BG
	tracker.BackgroundTransparency = 1 -- no panel: the text reads on its own (cream with a dark outline), like The Forge's quest list
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
	-- Max height follows the screen (25 % of the height, Task 5): refit when the camera or its viewport changes.
	local function watchViewport()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitTracker)
			fitTracker()
		end
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchViewport)
	watchViewport()
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
