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
local markers: { [string]: BillboardGui } = {} -- npc id -> "!" marker (a child of the NPC name billboard)
local handedIn: { [string]: boolean } = {} -- K-93: turn-in sent for this quest; cleared once the server no longer lists it ready

local function prefixOf(questId: string): string
	return string.match(questId, "^(%a+%d+)_") or questId -- side_* memakai id penuh (dlg.side_rumah_rapi.*)
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

-- bang_jali_1 .. bang_jali_8 are ONE giver (Quests: giver = "bang_jali"): drop the number after the last underscore.
local function giverOf(npcId: string): string
	return string.match(npcId, "^(.-)_%d+$") or npcId
end

local function tutorialRunning(): boolean
	local snapshot = State.current :: any
	return snapshot ~= nil and snapshot.guide ~= nil and snapshot.guide.step ~= nil and snapshot.guide.step.id ~= ""
end

-- The "!" marker: a small parchment pill with a bamboo "!" above the giver's overhead name label. The marker is a child of
-- that label's BillboardGui and sits ABOVE it in pixels (Bug 2: it used to cover the name). Without a label it falls back to
-- its own billboard on the head.
-- The "!" marker (Putaran 2 fix). One marker per GIVER, on the NPC model of that giver that is nearest to the player. It
-- shows only when the player has a real offer and has pressed Play (character spawned, data loaded, no talk/cutscene open).
-- It is a small billboard above the head: AlwaysOnTop off, MaxDistance 40 studs, so nothing shows on the title screen,
-- through the blur, or in the middle of the plaza without its NPC.
-- 2026-11-23 owner video: no "!" was seen although the Quest Log listed offers. The marker was built only for a giver within
-- 40 studs of the player (and billboards hid past 40), so from across the plaza nothing showed. Now the nearest model of each
-- wanted giver is used at any distance, and the billboard stays readable up to 200 studs.
local MARKER_MAX_DISTANCE = 200

local function makeMarker(head: BasePart): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QuestMarker"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(26, 30)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0) -- just above the overhead name label
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = MARKER_MAX_DISTANCE
	billboard.Parent = head
	local label = Instance.new("TextLabel")
	label.Name = "Bang"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(250, 240, 214)
	label.Text = "!"
	label.TextColor3 = MARKER_TEXT_COLOR
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = label
	return billboard
end

-- The player has pressed Play: the character exists, the save is loaded, and no talk or cutscene is open.
local function pressedPlay(): boolean
	return player.Character ~= nil and player:GetAttribute("DataLoaded") == true and player:GetAttribute("NpcTalkOpen") ~= true
		and player:GetAttribute("FishingActive") ~= true
end

local function refreshMarkers()
	local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
	local folder = Workspace:FindFirstChild("Npcs")
	-- givers with a real offer now (none during the tutorial, none before Play)
	local wanted: { [string]: boolean } = {}
	if pressedPlay() and not tutorialRunning() then
		for _, id in offers do
			local quest = Quests.byId[id]
			if quest and not accepting[id] then
				wanted[quest.giver] = true
			end
		end
		-- K-93: a finished quest waiting for its turn-in (siap diserahkan) also has the "!" on its giver.
		local snap = State.current :: any
		local ready = if snap and snap.quests then snap.quests.ready else nil
		for id in ready or {} do
			local quest = Quests.byId[id]
			if quest then
				wanted[quest.giver] = true
			end
		end
	end
	-- the nearest model of each wanted giver
	local chosen: { [string]: Model } = {}
	local chosenDist: { [string]: number } = {}
	if folder and root and root:IsA("BasePart") then
		for _, model in folder:GetChildren() do
			local giver = giverOf(model.Name)
			if model:IsA("Model") and wanted[giver] then
				local head = model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					local d = (head.Position - root.Position).Magnitude
					if d <= MARKER_MAX_DISTANCE and (chosenDist[giver] == nil or d < chosenDist[giver]) then -- nearest copy wins, within MARKER_MAX_DISTANCE
						chosen[giver] = model
						chosenDist[giver] = d
					end
				end
			end
		end
	end
	for giver, gui in markers do
		local model = chosen[giver]
		if model == nil or not gui:IsDescendantOf(game) or gui.Adornee ~= model:FindFirstChild("Head") then
			gui:Destroy()
			markers[giver] = nil
		end
	end
	for giver, model in chosen do
		if not markers[giver] then
			local head = model:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				markers[giver] = makeMarker(head)
			end
		end
	end
end

-- Quest ids the server offers right now (the Quest Log's "Tersedia" list).
function QuestOfferController.Offers(): { string }
	return table.clone(offers)
end

-- The quest to offer this giver now, nil when none (or a start dialog is already running / the quest was accepted here).
function QuestOfferController.ForGiver(npcId: string): string?
	if playing then
		return nil
	end
	for _, id in offers do
		local quest = Quests.byId[id]
		if quest and quest.giver == giverOf(npcId) and not accepting[id] then
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

-- K-93: the ready quest (all tasks done) of this giver, nil when none. Its turn-in plays when the player talks to the giver.
function QuestOfferController.ReadyFor(npcId: string): string?
	if playing then
		return nil
	end
	local snap = State.current :: any
	local ready = if snap and snap.quests then snap.quests.ready else nil
	for id in ready or {} do
		local quest = Quests.byId[id]
		if quest and quest.giver == giverOf(npcId) and not handedIn[id] then
			return id
		end
	end
	return nil
end

-- K-93: the giver's closing line(s) of a ready quest, then the reward is paid (QuestTurnIn). A quest with no done line is
-- turned in at once. The last Next (or the line-less turn-in) calls onDone.
function QuestOfferController.PlayTurnIn(npcId: string, questId: string, onDone: () -> ())
	local lines = linesOf(questId, "done")
	local function finish()
		playing = false
		handedIn[questId] = true -- until the server's state no longer lists it as ready (see Start)
		Net.Send("QuestTurnIn", questId)
		onDone()
	end
	if #lines == 0 then
		finish()
		return
	end
	token += 1
	local mine = token
	playing = true
	local function show(index: number)
		if mine ~= token then
			return
		end
		if index > #lines then
			finish()
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
		local snap = State.current :: any
		local ready = if snap and snap.quests then snap.quests.ready else nil
		for id in handedIn do
			if not (ready and ready[id]) then
				handedIn[id] = nil
			end
		end
		refreshMarkers()
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
