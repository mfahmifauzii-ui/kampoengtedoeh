--!strict
-- Quest offers on the client (Q-3). The server decides what is offered (QuestService.offeredIds, sent as "QuestOffers").
-- This controller only reflects it:
--   * "!" marker over each giver that has an offer (client only, hidden during a tutorial).
--   * Start dialog from the Naskah (dlg.<prefix>.start.n) when the player talks to that giver; the last Next sends
--     "QuestAccept" and the server starts the quest (the Dimulai banner and the tracker come from the snapshot).
--   * Selesai dialog (dlg.<prefix>.done.n) for a finished Main quest, through the one dialog box (T1Dialog queue).
--   * SideDoneText: the giver's one-line Naskah text, which HudController shows as the toast of a finished side quest.
-- No toast fallback for dialog text: a quest with no Naskah line has no offer and no dialog (see QuestService.hasDialog).
-- Rollback: remove this controller from init.client.luau, the calls in DialogueController and HudController, and the
-- "QuestOffers" / "QuestAccept" / "QuestOffersRequest" remotes in QuestService.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local T1Dialog = require(script.Parent.Parent.T1Dialog)

local player = Players.LocalPlayer
local MARKER_TEXT_COLOR = Color3.fromRGB(214, 164, 64)

local QuestOfferController = {}

local offers: { string } = {}
local accepting: { [string]: boolean } = {} -- accepted here, waiting for the server's next QuestOffers
local playing = false -- the start dialog is on screen
local token = 0 -- bumped by Cancel(): a running start dialog stops at its next Next
local markers: { [string]: BillboardGui } = {} -- npc id -> "!" marker
local seenDone: { [string]: boolean } = {}
local doneSeeded = false

local function prefixOf(questId: string): string
	return string.match(questId, "^(.-)_") or questId
end

-- Naskah keys of one quest: dlg.<prefix>.<kind>.1, .2, ... (stops at the first missing number).
local function linesOf(questId: string, kind: string): { string }
	local lines = {}
	local n = 1
	while Locale.has(`dlg.{prefixOf(questId)}.{kind}.{n}`) do
		table.insert(lines, `dlg.{prefixOf(questId)}.{kind}.{n}`)
		n += 1
	end
	return lines
end

local function tutorialRunning(): boolean
	local snapshot = State.current :: any
	return snapshot ~= nil and snapshot.guide ~= nil and snapshot.guide.step ~= nil and snapshot.guide.step.id ~= ""
end

-- The "!" marker: a small parchment pill with a bamboo "!" over the giver's head.
local function makeMarker(head: BasePart): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "QuestMarker"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(34, 40)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head
	local label = Instance.new("TextLabel")
	label.Name = "Bang"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(250, 240, 214)
	label.Text = "!"
	label.TextColor3 = MARKER_TEXT_COLOR
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = label
	return gui
end

local function refreshMarkers()
	local wanted: { [string]: boolean } = {}
	if not tutorialRunning() then
		for _, id in offers do
			local quest = Quests.byId[id]
			if quest and not accepting[id] then
				wanted[quest.giver] = true
			end
		end
	end
	for npcId, gui in markers do
		if not wanted[npcId] or gui.Adornee == nil or gui.Adornee.Parent == nil then
			gui:Destroy()
			markers[npcId] = nil
		end
	end
	local folder = Workspace:FindFirstChild("Npcs")
	for npcId in wanted do
		if not markers[npcId] then
			local model = folder and folder:FindFirstChild(npcId)
			if model and model:IsA("Model") then
				local head = model:FindFirstChild("Head") or model.PrimaryPart
				if head and head:IsA("BasePart") then
					markers[npcId] = makeMarker(head)
				end
			end
		end
	end
end

-- The quest to offer this giver now, nil when none (or a start dialog is already running / the quest was accepted here).
function QuestOfferController.ForGiver(npcId: string): string?
	if playing then
		return nil
	end
	for _, id in offers do
		local quest = Quests.byId[id]
		if quest and quest.giver == npcId and not accepting[id] then
			return id
		end
	end
	return nil
end

-- Plays the start lines one Next at a time. The last Next accepts the quest (QuestAccept) and then calls onDone.
function QuestOfferController.PlayStart(npcId: string, questId: string, onDone: () -> ())
	local lines = linesOf(questId, "start")
	if #lines == 0 then
		return -- the server only offers quests with a line; nothing to play
	end
	token += 1
	local mine = token
	playing = true
	local function show(index: number)
		if mine ~= token then
			return
		end
		if index > #lines then
			playing = false
			accepting[questId] = true
			Net.Send("QuestAccept", questId)
			onDone()
			return
		end
		T1Dialog.Show({
			name = Locale.t(`npc.{npcId}`),
			text = Locale.t(lines[index], { name = player.DisplayName }),
			avatar = T1Dialog.NpcModel(npcId),
			showNext = true,
			bottom = 16,
			onNext = function()
				show(index + 1)
			end,
		})
	end
	show(1)
end

-- The talk was closed: a start dialog that is still running stops (the quest is not accepted).
function QuestOfferController.Cancel()
	token += 1
	playing = false
end

-- One-line text of a finished SIDE quest (its giver's Naskah line), nil when there is none.
function QuestOfferController.SideDoneText(questId: string): string?
	local quest = Quests.byId[questId]
	if not quest or quest.kind ~= "side" then
		return nil
	end
	local lines = linesOf(questId, "done")
	if #lines == 0 then
		return nil
	end
	return `{Locale.t(`npc.{quest.giver}`)}: {Locale.t(lines[1], { name = player.DisplayName })}`
end

-- A finished MAIN quest: its giver's closing line in the dialog box, one Next to close.
local function playDone(questId: string)
	local quest = Quests.byId[questId]
	local lines = linesOf(questId, "done")
	if not quest or #lines == 0 then
		return
	end
	task.spawn(function()
		local held = T1Dialog.Acquire(quest.giver, T1Dialog.AMBIENT)
		if not held then
			return
		end
		local function show(index: number)
			T1Dialog.Show({
				name = Locale.t(`npc.{quest.giver}`),
				text = Locale.t(lines[index], { name = player.DisplayName }),
				avatar = T1Dialog.NpcModel(quest.giver),
				showNext = true,
				bottom = 16,
				onNext = function()
					if lines[index + 1] then
						show(index + 1)
					else
						T1Dialog.Hide() -- gives the box back
					end
				end,
			})
		end
		show(1)
	end)
end

local function refreshDone()
	local snapshot = State.current :: any
	local quests = snapshot and snapshot.quests
	if not quests then
		return
	end
	local nowDone: { [string]: boolean } = {}
	for id, value in quests.done do
		if value == true then
			nowDone[id] = true
		end
	end
	if doneSeeded then
		for id in nowDone do
			local quest = Quests.byId[id]
			if not seenDone[id] and quest and quest.kind == "main" then
				playDone(id)
			end
		end
	end
	doneSeeded = true
	seenDone = nowDone
end

function QuestOfferController.Init()
	Net.Listen("QuestOffers", function(ids: any)
		if typeof(ids) ~= "table" then
			return
		end
		offers = {}
		for _, id in ids do
			if typeof(id) == "string" then
				table.insert(offers, id)
			end
		end
		accepting = {} -- the server has answered: what it offers now is the truth
		refreshMarkers()
	end)
end

function QuestOfferController.Start()
	State.Changed:Connect(function()
		refreshMarkers()
		refreshDone()
	end)
	-- The NPC model can stream in after the offer: check again every second (cheap: a few names).
	task.spawn(function()
		while true do
			refreshMarkers()
			task.wait(1)
		end
	end)
	Net.Send("QuestOffersRequest")
end

return QuestOfferController
