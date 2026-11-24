--!strict
-- Quest tracker, Quest Log and the direction arrow (GUI 6.8, GUI 4.5, Quest 03 bab 9; owner playtest 2026-11-24, butir 2-7).
--   Tracker (left column, under the player card): the rows of State.quests.tracked, in tracked order, at most 3 (+ the Surat row
--     while a letter is due). A quest row reads: its step (Berjalan), "Siap diserahkan ke <pemberi>" (ready) or "Temui <pemberi>"
--     (offered). Harian and Mingguan slot rows show only while tracked. A tap opens the Quest Log on that quest's tab.
--   Quest Log: one panel, tabs Main · Side · Harian · Pesanan. Pesanan is the order list (OrdersController.Fill).
--     Every quest row has Track / Lepas (max 3 tracked) and Tunjukkan (points the arrow at its target for a few seconds).
--   Arrow: one target at a time. Off screen it is a screen-edge arrow that points to the target; on screen it is a name label
--     over the target (the world marker). The target is the giver (ready, offered) or the step's `target` (Config/Quests).
-- UI contract (keep the names): ScreenGui "QuestUI" (DisplayOrder = UiKit.LAYER.HUD) > Frame "Tracker"; rows are named by
-- their quest id (or h:/w: slot key) and have TextLabel "Title" and "Step". ScreenGui "QuestArrow" holds the arrow.
-- The server owns quest state (QuestService); this file only reads State.current.quests and sends QuestTrack / QuestTurnIn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local State = require(script.Parent.Parent.State)
local FeatureClient = require(script.Parent.Parent.FeatureClient)
local UiKit = require(script.Parent.Parent.UiKit)
local QuestOfferController = require(script.Parent.QuestOfferController)
local OrdersController = require(script.Parent.OrdersController)

local player = Players.LocalPlayer

local QuestController = {}

local MAX_HEIGHT_PX = 200 -- top limit in px (stops above the Craft button)
local MAX_HEIGHT_SCREEN = 0.25 -- top limit as a share of the screen height (Update owner 2026-11-22, Task 5)
local POINT_SECONDS = 6 -- how long "Tunjukkan" keeps the arrow on its target
local KOLAM_QUEST = "kolam_pertama" -- hidden for the whole of T1b (v7.4 Bab 16.5), back when MQ4 opens the pond
local KB_QUEST = "side_kerjabakti" -- Kerja Bakti: shown only while the event runs (Workspace KBActive)

local tracker: Frame
local arrowGui: ScreenGui
local arrowEdge: TextLabel
local arrowMarker: TextLabel
local logPanel: any = nil -- the open Quest Log (UiKit.panel), nil while closed
local logTab: string = "main"
local pointedKey: string? = nil -- "Tunjukkan": the arrow goes to this key until pointedUntil
local pointedUntil = 0.0
local arrowTarget: (() -> Vector3?)? = nil -- where the arrow points now (nil = no arrow)
local arrowLabel = ""
local refresh: () -> ()

-- ---------------------------------------------------------------------------------------------------------------------
-- Shared rules
-- ---------------------------------------------------------------------------------------------------------------------

local function snapshot(): any
	return State.current :: any
end

-- Kerja Bakti runs only while the event is on (Workspace KBActive).
local function kbRunning(): boolean
	return Workspace:GetAttribute("KBActive") == true
end

-- Playtest 7: no quest UI (tracker, log, arrows) until the tutorial is finished or skipped.
local function tutorialDone(snap: any): boolean
	local guide = snap and snap.guide
	return guide ~= nil and (guide.done.t1b_kolam == true or guide.skipped.t1b_kolam == true)
end

local function kolamCardWanted(snap: any): boolean
	local step = snap and snap.guide and snap.guide.step
	return not (step and step.id == "t1b_kolam")
end

local function levelNow(): number
	local level = player:GetAttribute("Level")
	return if typeof(level) == "number" then level else 1
end

-- bang_jali_1 .. bang_jali_8 are ONE giver: drop the number after the last underscore.
local function giverOf(npcId: string): string
	return string.match(npcId, "^(.-)_%d+$") or npcId
end

-- The place a quest points to, by name (an NPC id, a Config step target, or KB_QUEST for the trash spot). nil = none.
--   ready / offered -> its giver (talk to them); active -> the current step's `target`, if the step has one.
local function nameOfTarget(questId: string, snap: any): string?
	local quest = Quests.byId[questId]
	if not quest or not snap or not snap.quests then
		return nil
	end
	local quests = snap.quests
	if quests.ready and quests.ready[questId] == true then
		return quest.giver
	end
	if quests.active and quests.active[questId] then
		if questId == KB_QUEST then
			return if kbRunning() then KB_QUEST else nil
		end
		local progress = quests.active[questId]
		local step = quest.steps[progress.step]
		return if step then step.target else nil
	end
	if not quests.done[questId] and table.find(QuestOfferController.Offers(), questId) then
		return quest.giver
	end
	return nil
end

-- Where a quest's arrow goes, as a function (NPCs move). nil when the quest has no place to point at.
local function targetOfQuest(questId: string, snap: any): (() -> Vector3?)?
	local name = nameOfTarget(questId, snap)
	if not name then
		return nil
	end
	return function(): Vector3?
		return QuestController.PositionOf(name)
	end
end

local function labelOfTarget(questId: string, snap: any): string
	local name = nameOfTarget(questId, snap) or ""
	if name == KB_QUEST then
		return Locale.t("kb.active")
	end
	return if Locale.has(`npc.{name}`) then Locale.t(`npc.{name}`) else name
end

-- The position of an NPC (its Head) or a named world object, nil while it is not in the world.
function QuestController.PositionOf(name: string): Vector3?
	local folder = Workspace:FindFirstChild("Npcs")
	if folder then
		for _, model in folder:GetChildren() do
			if model:IsA("Model") and giverOf(model.Name) == name then
				local head = model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					return head.Position
				end
			end
		end
	end
	if name == KB_QUEST then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local best: Vector3? = nil
		local bestDistance = math.huge
		for _, descendant in Workspace:GetDescendants() do
			if descendant.Name == "Sampah" and descendant:IsA("BasePart") then
				local here = if root and root:IsA("BasePart") then (descendant.Position - root.Position).Magnitude else 0
				if here < bestDistance then
					best, bestDistance = descendant.Position, here
				end
			end
		end
		return best
	end
	local found = Workspace:FindFirstChild(name, true)
	if found and found:IsA("BasePart") then
		return found.Position
	end
	if found and found:IsA("Model") then
		return found:GetPivot().Position
	end
	return nil
end

-- Status of one quest for the log and the tracker.
type Status = "active" | "ready" | "offer" | "done" | "later"

local function statusOf(quest: Quests.Quest, snap: any, offered: { [string]: boolean }): Status?
	local quests = snap and snap.quests
	if not quests then
		return nil
	end
	if quests.active[quest.id] then
		return "active"
	end
	if quests.ready and quests.ready[quest.id] == true then
		return "ready"
	end
	if quests.done[quest.id] == true then
		return "done"
	end
	if offered[quest.id] then
		return "offer"
	end
	if quest.kind == "main" and quest.blocked == nil and quest.auto ~= true and levelNow() < quest.unlockLevel then
		return "later"
	end
	return nil
end

-- One line under the quest's title for its status.
local function subOf(quest: Quests.Quest, status: Status, snap: any): string
	local giver = Locale.t(`npc.{quest.giver}`)
	if status == "active" then
		local progress = snap.quests.active[quest.id]
		local step = quest.steps[progress.step]
		if not step then
			return ""
		end
		local text = Locale.t(`quest.{quest.id}.s{progress.step}`, { n = step.count })
		if step.count > 1 then
			text ..= ` ({progress.count}/{step.count})`
		end
		return text
	elseif status == "ready" then
		return Locale.t("quest.ready_to", { npc = giver })
	elseif status == "offer" then
		return Locale.t("quest.offer_to", { npc = giver })
	elseif status == "done" then
		return Locale.t("banner.done")
	end
	return `Lv {quest.unlockLevel}`
end

local function offeredSet(): { [string]: boolean }
	local set: { [string]: boolean } = {}
	for _, id in QuestOfferController.Offers() do
		set[id] = true
	end
	return set
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Tracking (Track / Lepas) and the Quest Log
-- ---------------------------------------------------------------------------------------------------------------------

local function isTracked(key: string, snap: any): boolean
	return snap ~= nil and snap.quests ~= nil and snap.quests.tracked ~= nil and table.find(snap.quests.tracked, key) ~= nil
end

local function setTracked(key: string, on: boolean)
	Net.Send("QuestTrack", key, on)
end

local function closeLog()
	if logPanel then
		local gui = logPanel.gui
		logPanel = nil
		UiKit.closePanel(gui)
	end
end

-- "Tunjukkan": close the log and point the arrow at the quest's target for a few seconds.
local function pointAt(key: string)
	closeLog()
	pointedKey = key
	pointedUntil = os.clock() + POINT_SECONDS
	QuestController.Update()
end

-- Rows of one Log tab. Each row: title, sub, track key (nil = no Track button), point key (nil = no Tunjukkan).
type LogRow = { title: string, sub: string, key: string?, point: boolean }
type LogSection = { heading: string, rows: { LogRow } }

local function questRows(kind: string, snap: any): { LogSection }
	local offered = offeredSet()
	local running: { LogRow } = {}
	local offers: { LogRow } = {}
	local done: { LogRow } = {}
	local later: { LogRow } = {}
	for _, quest in Quests.list do
		if quest.kind == kind and quest.blocked == nil and (quest.id ~= KB_QUEST or kbRunning()) and (quest.id ~= KOLAM_QUEST or kolamCardWanted(snap)) then
			local status = statusOf(quest, snap, offered)
			local row: LogRow = {
				title = Locale.t(`quest.{quest.id}.title`),
				sub = if status then subOf(quest, status, snap) else "",
				key = quest.id,
				point = targetOfQuest(quest.id, snap) ~= nil,
			}
			if status == "active" or status == "ready" then
				table.insert(running, row)
			elseif status == "offer" then
				table.insert(offers, row)
			elseif status == "done" then
				row.key = nil
				row.point = false
				table.insert(done, row)
			elseif status == "later" then
				row.title = "???"
				row.key = nil
				row.point = false
				table.insert(later, row)
			end
		end
	end
	local sections: { LogSection } = {}
	if #running > 0 then
		table.insert(sections, { heading = Locale.t("quest.log.active"), rows = running })
	end
	if #offers > 0 then
		table.insert(sections, { heading = Locale.t("quest.log.offered"), rows = offers })
	end
	if #done > 0 then
		table.insert(sections, { heading = Locale.t("banner.done"), rows = done })
	end
	if kind == "main" and #later > 0 then
		table.insert(sections, { heading = Locale.t("quest.log.next"), rows = later })
	end
	return sections
end

-- Harian and Mingguan slots that are still open, as Log rows (key "h:<kind>" / "w:<kind>").
local function slotRows(label: string, slots: any, pool: { any }, keyPrefix: string): { LogRow }
	local rows: { LogRow } = {}
	if typeof(slots) ~= "table" then
		return rows
	end
	for _, slot in slots do
		if not slot.claimed then
			for _, def in pool do
				if def.id == slot.kind then
					table.insert(rows, {
						title = Locale.t(`{label}.title`),
						sub = `{Locale.t(`{label}.{def.id}`)}  {slot.progress}/{def.count}`,
						key = `{keyPrefix}:{def.id}`,
						point = false,
					})
				end
			end
		end
	end
	return rows
end

local function renderLog()
	if not logPanel then
		return
	end
	UiKit.clear(logPanel.list)
	local snap = snapshot()
	local tabs = {
		{ id = "main", text = Locale.t("quest.log.tab_main") },
		{ id = "side", text = Locale.t("quest.log.tab_side") },
		{ id = "harian", text = Locale.t("quest.log.tab_harian") },
		{ id = "pesanan", text = Locale.t("quest.log.tab_pesanan") },
	}
	local bar = UiKit.tabs(logPanel.list, tabs, logTab, function(id: string)
		logTab = id
		renderLog()
	end)
	bar.frame.LayoutOrder = 1
	local order = 2
	if logTab == "pesanan" then
		OrdersController.Fill(logPanel.list, order)
		return
	end
	local sections: { LogSection }
	if logTab == "harian" then
		local quests = snap and snap.quests
		sections = {}
		local harian = slotRows("quest_harian", quests and quests.harian and quests.harian.slots, Quests.HARIAN, "h")
		local mingguan = slotRows("quest_mingguan", quests and quests.mingguan and quests.mingguan.slots, Quests.MINGGUAN, "w")
		if #harian > 0 then
			table.insert(sections, { heading = Locale.t("quest.log.tab_harian"), rows = harian })
		end
		if #mingguan > 0 then
			table.insert(sections, { heading = Locale.t("quest.log.tab_mingguan"), rows = mingguan })
		end
	else
		sections = questRows(logTab, snap)
	end
	if #sections == 0 then
		UiKit.header(logPanel.list, "—", order)
		return
	end
	for _, section in sections do
		UiKit.header(logPanel.list, section.heading, order)
		order += 1
		for _, row in section.rows do
			local key = row.key
			local tracked = key ~= nil and isTracked(key, snap)
			local trackText = if key == nil then nil elseif tracked then Locale.t("quest.untrack") else Locale.t("quest.track")
			local onTrack = if key then function()
				setTracked(key, not tracked)
			end else nil
			local pointKey = if row.point then key else nil
			local onPoint = if pointKey then function()
				pointAt(pointKey)
			end else nil
			UiKit.row(logPanel.list, order, row.title, row.sub, trackText, true, onTrack, if onPoint then Locale.t("quest.point") else nil, onPoint)
			order += 1
		end
	end
end

local function openLog(tab: string)
	logTab = tab
	if not logPanel then
		logPanel = UiKit.panel("QuestLog", Locale.t("ui.quest"), closeLog)
		logPanel.gui.Enabled = true
	end
	renderLog()
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Tracker
-- ---------------------------------------------------------------------------------------------------------------------

local function listRow(row: Frame)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
end

local function textLabel(name: string, order: number, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextWrapped = true
	label.LayoutOrder = order
	label.Font = UiKit.FONT
	label.TextSize = size
	label.TextColor3 = UiKit.TEXT
	label.TextXAlignment = Enum.TextXAlignment.Left
	return label
end

-- One tracker row: a frame named `name`, title + step labels, and a tap that opens the log on `tab` (nil = no tap).
local function addRow(order: number, name: string, title: string, step: string, tab: string?): Frame
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	listRow(row)
	row.Parent = tracker

	local titleLabel = textLabel("Title", 1, 13)
	titleLabel.Text = title
	titleLabel.Parent = row
	local stepLabel = textLabel("Step", 2, 12)
	stepLabel.Text = step
	stepLabel.Parent = row

	if tab then
		local tap = Instance.new("TextButton")
		tap.Name = "Tap"
		tap.Text = ""
		tap.AutoButtonColor = false
		tap.BackgroundTransparency = 1
		tap.Size = UDim2.fromScale(1, 1)
		tap.ZIndex = 1
		tap.Parent = row
		tap.Activated:Connect(function()
			openLog(tab)
		end)
	end
	return row
end

-- Surat Kakek row: the letter that is due. "Baca" reads it (Quest S2 counts the read).
local function addSuratRow(order: number, surat: any)
	local row = addRow(order, "surat", `{Locale.t("surat.title")} #{surat.n}`, `{surat.progress}/{surat.need}`, nil)
	local read = UiKit.button(row, "Baca", Locale.t("quest.read"), UiKit.BUTTON)
	read.AnchorPoint = Vector2.new(1, 0)
	read.Position = UDim2.new(1, 0, 0, 0)
	read.Size = UDim2.fromOffset(52, UiKit.TOUCH_MIN)
	read.TextSize = 12
	read.ZIndex = 3
	read.Activated:Connect(function()
		Net.Send("QuestReport", "surat_read")
	end)
end

-- Tracked rows in tracked order. A quest row for an open read step also gets "Baca".
local function buildRows(snap: any)
	local quests = snap and snap.quests
	if not quests then
		return
	end
	local offered = offeredSet()
	local order = 0
	for _, key in quests.tracked or {} do
		local quest = Quests.byId[key]
		if quest then
			local status = statusOf(quest, snap, offered)
			local skip = status == nil or status == "done" or (quest.id == KB_QUEST and not kbRunning())
				or (quest.id == KOLAM_QUEST and not kolamCardWanted(snap))
			if not skip then
				order += 1
				local tab = if quest.kind == "main" then "main" else "side"
				local row = addRow(order, quest.id, Locale.t(`quest.{quest.id}.title`), subOf(quest, status :: Status, snap), tab)
				local progress = quests.active[quest.id]
				local step = if progress then quest.steps[progress.step] else nil
				if step and step.event == "surat_read" and status == "active" then
					-- Quest S2 (Surat Pertama): the step is the read itself, so the row has the explicit action.
					local read = UiKit.button(row, "Baca", Locale.t("quest.read"), UiKit.BUTTON)
					read.AnchorPoint = Vector2.new(1, 0)
					read.Position = UDim2.new(1, 0, 0, 0)
					read.Size = UDim2.fromOffset(52, UiKit.TOUCH_MIN)
					read.TextSize = 12
					read.ZIndex = 3
					read.Activated:Connect(function()
						Net.Send("QuestReport", "surat_read")
					end)
				end
			end
		else
			local label, slotKind = string.match(key, "^([hw]):(.+)$")
			if label then
				local slots = if label == "h" then quests.harian and quests.harian.slots else quests.mingguan and quests.mingguan.slots
				local pool = if label == "h" then Quests.HARIAN else Quests.MINGGUAN
				local prefix = if label == "h" then "quest_harian" else "quest_mingguan"
				for _, slot in slots or {} do
					for _, def in pool do
						if slot.kind == slotKind and def.id == slotKind and not slot.claimed then
							order += 1
							addRow(order, key, Locale.t(`{prefix}.title`), `{Locale.t(`{prefix}.{def.id}`)}  {slot.progress}/{def.count}`, "harian")
						end
					end
				end
			end
		end
	end
	local surat = quests.surat
	-- Surat row: while a letter is due and its feature is open (Q-2 gate "surat").
	if surat and surat.n > 0 and FeatureClient.IsOpen("surat") then
		addSuratRow(100, surat)
	end
end

local function fitTracker()
	if tracker then
		local content = tracker:FindFirstChildOfClass("UIListLayout")
		local height = if content then content.AbsoluteContentSize.Y + 16 else 0
		local camera = Workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize.Y else MAX_HEIGHT_PX / MAX_HEIGHT_SCREEN
		local limit = math.min(MAX_HEIGHT_PX, MAX_HEIGHT_SCREEN * viewport)
		tracker.Size = UDim2.fromOffset(UiKit.HUD.TRACKER_W, math.min(limit, math.max(height, 0)))
	end
end

-- Screen-edge arrow + world marker (one target). Runs every frame only while a target is set.
local function placeArrow()
	if not arrowGui or not arrowTarget then
		return
	end
	local camera = Workspace.CurrentCamera
	local world = arrowTarget()
	if not camera or not world then
		arrowGui.Enabled = false
		return
	end
	arrowGui.Enabled = true
	local view = camera.ViewportSize
	local screen, inFront = camera:WorldToViewportPoint(world)
	local center = view / 2
	local onScreen = inFront and screen.Z > 0 and screen.X >= 0 and screen.X <= view.X and screen.Y >= 0 and screen.Y <= view.Y
	if onScreen then
		arrowEdge.Visible = false
		arrowMarker.Visible = true
		arrowMarker.Text = arrowLabel
		arrowMarker.Position = UDim2.fromOffset(screen.X, screen.Y - 26)
	else
		arrowMarker.Visible = false
		arrowEdge.Visible = true
		local dir = Vector2.new(screen.X, screen.Y) - center
		if screen.Z < 0 then
			dir = -dir
		end
		local inset = 56
		local half = center - Vector2.new(inset, inset)
		local t = math.huge
		if math.abs(dir.X) > 0.001 then
			t = math.min(t, half.X / math.abs(dir.X))
		end
		if math.abs(dir.Y) > 0.001 then
			t = math.min(t, half.Y / math.abs(dir.Y))
		end
		if t == math.huge then
			t = 0
		end
		local at = center + dir * math.min(t, 1)
		arrowEdge.Position = UDim2.fromOffset(at.X, at.Y)
		arrowEdge.Rotation = math.deg(math.atan2(dir.Y, dir.X))
	end
end

-- Chooses the arrow target: the "Tunjukkan" key while it runs, else the first tracked quest that has a place to point at.
local function chooseArrow(snap: any)
	arrowTarget = nil
	arrowLabel = ""
	if pointedKey and os.clock() > pointedUntil then
		pointedKey = nil
	end
	local keys: { string } = if pointedKey then { pointedKey } elseif snap and snap.quests then snap.quests.tracked else {}
	for _, key in keys do
		local getter = targetOfQuest(key, snap)
		if getter then
			arrowTarget = getter
			arrowLabel = labelOfTarget(key, snap)
			break
		end
	end
end

function refresh()
	if not tracker then
		return
	end
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snap = snapshot()
	if not tutorialDone(snap) then
		tracker.Visible = false
		if logPanel then
			closeLog() -- no quest UI during the tutorial
		end
		arrowTarget = nil
		if arrowGui then
			arrowGui.Enabled = false
		end
		return
	end
	-- 2026-11-23 owner video: a build error used to stop the tracker from showing. A pcall keeps the rest running.
	local built, buildError = pcall(buildRows, snap)
	if not built then
		warn(`[QuestController] tracker rows failed: {buildError}`)
	end
	-- Readable without a panel: cream text with a dark outline on every label of the tracker.
	for _, label in tracker:GetDescendants() do
		if label:IsA("TextLabel") then
			label.TextColor3 = UiKit.CREAM
			label.TextStrokeColor3 = UiKit.DARK
			label.TextStrokeTransparency = 0
		end
	end
	local hasRows = false
	for _, child in tracker:GetChildren() do
		if child:IsA("Frame") then
			hasRows = true
		end
	end
	tracker.Visible = hasRows
	chooseArrow(snap)
	if logPanel then
		renderLog()
	end
end

-- Buttons that open the Log: the dock button (where the Pesanan button used to be) and the player card.
local function syncButtons()
	local gui = player:FindFirstChild("PlayerGui")
	local hud = gui and gui:FindFirstChild("HUD")
	local dock = hud and hud:FindFirstChild("QuestButton", true)
	if dock and dock:IsA("GuiObject") then
		dock.Visible = tutorialDone(snapshot())
	end
	local cardButton = hud and hud:FindFirstChild("QuestCardButton", true)
	if cardButton and cardButton:IsA("GuiObject") then
		cardButton.Visible = tutorialDone(snapshot())
	end
end

-- Quest button on the player card (top right of the card). Same Log as the dock button.
local function addCardButton()
	task.spawn(function()
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 30)
		local card = hud and hud:WaitForChild("StatusCard", 30)
		if not card or not card:IsA("GuiObject") then
			return
		end
		local button = UiKit.button(card, "QuestCardButton", Locale.t("ui.quest"), UiKit.BUTTON)
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, -10, 0, 8)
		button.Size = UDim2.fromOffset(58, UiKit.TOUCH_MIN)
		button.TextSize = 12
		button.ZIndex = 6
		button.Visible = false
		button.Activated:Connect(function()
			openLog(logTab)
		end)
	end)
end

function QuestController.Update()
	refresh()
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
	-- The height follows the rows (fitTracker) but never past maxHeight; the rest is clipped, so nothing draws over the buttons.
	tracker.AutomaticSize = Enum.AutomaticSize.None
	tracker.ClipsDescendants = true
	tracker.BackgroundColor3 = UiKit.BG
	tracker.BackgroundTransparency = 1 -- no panel: the text reads on its own (cream with a dark outline)
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

	arrowGui = Instance.new("ScreenGui")
	arrowGui.Name = "QuestArrow"
	arrowGui.ResetOnSpawn = false
	arrowGui.DisplayOrder = UiKit.LAYER.GUIDE
	arrowGui.IgnoreGuiInset = true
	arrowGui.Enabled = false
	arrowGui.Parent = player:WaitForChild("PlayerGui")

	arrowEdge = Instance.new("TextLabel")
	arrowEdge.Name = "Edge"
	arrowEdge.AnchorPoint = Vector2.new(0.5, 0.5)
	arrowEdge.Size = UDim2.fromOffset(40, 40)
	arrowEdge.BackgroundColor3 = UiKit.DARK
	arrowEdge.BackgroundTransparency = 0.1
	arrowEdge.Font = UiKit.FONT
	arrowEdge.TextSize = 26
	arrowEdge.TextColor3 = UiKit.CREAM
	arrowEdge.Text = ">"
	arrowEdge.Visible = false
	arrowEdge.Parent = arrowGui
	Instance.new("UICorner").Parent = arrowEdge

	arrowMarker = Instance.new("TextLabel")
	arrowMarker.Name = "Marker"
	arrowMarker.AnchorPoint = Vector2.new(0.5, 1)
	arrowMarker.Size = UDim2.fromOffset(220, 28)
	arrowMarker.BackgroundColor3 = UiKit.DARK
	arrowMarker.BackgroundTransparency = 0.1
	arrowMarker.Font = UiKit.FONT
	arrowMarker.TextSize = 14
	arrowMarker.TextColor3 = UiKit.CREAM
	arrowMarker.Visible = false
	arrowMarker.Parent = arrowGui
	Instance.new("UICorner").Parent = arrowMarker

	task.spawn(UiKit.hudButton, "QuestButton", Locale.t("ui.quest"), 3, function()
		if tutorialDone(snapshot()) then
			if logPanel then
				closeLog()
			else
				openLog(logTab)
			end
		end
	end)
	addCardButton()
end

function QuestController.Start()
	-- Max height follows the screen (25 % of the height): refit when the camera or its viewport changes.
	local function watchViewport()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitTracker)
			fitTracker()
		end
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchViewport)
	watchViewport()
	State.Changed:Connect(function()
		refresh()
		syncButtons()
	end)
	RunService.RenderStepped:Connect(placeArrow)
	refresh()
	syncButtons()
	-- Walking onto the land changes the kolam card, and an NPC or the Kerja Bakti event moves the arrow target: check a few
	-- times a second, rebuild only when the wanted set changes.
	task.spawn(function()
		local last: string? = nil
		while true do
			local snap = snapshot()
			local signature = `{tostring(kolamCardWanted(snap))}|{tostring(kbRunning())}|{tostring(pointedKey)}`
			if signature ~= last then
				last = signature
				refresh()
			end
			syncButtons()
			task.wait(0.5)
		end
	end)
end

return QuestController
