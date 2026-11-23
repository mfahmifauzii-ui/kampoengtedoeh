--!strict
-- Papan Hari Ini, bagian Agenda (GDD 14.5, GUI 6.9, Putaran 2 R2.2). One HUD button ("Papan") opens the panel: today's
-- Agenda tasks with progress. Rewards are paid by the server when a task completes; the panel only shows them.
-- Opening the panel reports "agenda_open" (quest M1 step 1), which reveals the Agenda feature.
--
-- UI CONTRACT: HUD button "PapanButton" (gated by the "agenda" feature). Data: snapshot.quests.agenda = { day, tasks }.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local FeatureClient = require(script.Parent.Parent.FeatureClient)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local AgendaController = {}

local panel: UiKit.Panel? = nil

local function defOf(id: string): Quests.Daily?
	for _, def in Quests.AGENDA do
		if def.id == id then
			return def
		end
	end
	return nil
end

local function render()
	if not panel or not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	local agenda = if snapshot and snapshot.quests then snapshot.quests.agenda else nil
	local tasks = if agenda and agenda.tasks then agenda.tasks else {}
	if #tasks == 0 then
		UiKit.header(panel.list, Locale.t("agenda.empty"), 1)
		return
	end
	UiKit.header(panel.list, Locale.t("agenda.today"), 1)
	for index, task in tasks do
		local def = defOf(task.id)
		if def then
			local status = if task.claimed then Locale.t("agenda.done") else Locale.t("agenda.progress", { n = task.progress, max = def.count })
			UiKit.row(panel.list, index + 1, Locale.t(`agenda.{def.id}.title`), status, nil, false, nil)
		end
	end
	UiKit.header(panel.list, Locale.t("agenda.rewards_note"), #tasks + 2)
end

local function openPanel()
	if not panel then
		return
	end
	local opening = not panel.gui.Enabled
	panel.gui.Enabled = not panel.gui.Enabled
	if opening then
		Net.Send("QuestReport", "agenda_open")
	end
	render()
end

function AgendaController.Init()
	panel = UiKit.panel("PapanPanel", Locale.t("agenda.title"), function()
		if panel then
			panel.gui.Enabled = false
		end
	end)
end

function AgendaController.Start()
	State.Changed:Connect(render)
	task.spawn(function()
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
		if not hud then
			return
		end
		local item = UiKit.menuItem(hud, "PapanButton", Locale.t("agenda.button"), 10)
		if item then
			FeatureClient.GateHud("PapanButton", "agenda")
			item.Activated:Connect(openPanel)
		end
	end)
end

return AgendaController
