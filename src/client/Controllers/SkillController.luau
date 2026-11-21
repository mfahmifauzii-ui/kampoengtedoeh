--!strict
-- Panel Skill 16 (Bab 4.5): beli pakai SP (1 SP/level, max Lv 5). Dibuka dari HUD.
-- SP dibaca dari atribut (ProgressionService sync), level skill dari snapshot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skills = require(ReplicatedStorage.Shared.Config.Skills)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.Parent.UiKit)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer

local SkillController = {}

local panel: UiKit.Panel? = nil

local function spBalance(): number
	local sp = player:GetAttribute("SP")
	return if typeof(sp) == "number" then sp else 0
end

local function rebuild()
	local list = panel and panel.list
	if not list then
		return
	end
	UiKit.clear(list)
	local snap = State.current :: any
	local levels = (snap and snap.skills) or {}
	local order = 0
	order += 1
	UiKit.header(list, `SP: {spBalance()}`, order)
	for _, cabang in Skills.CABANG_ORDER do
		order += 1
		UiKit.header(list, Locale.t(`skill.cabang.{cabang}`), order)
		for _, def in Skills.SKILLS do
			if def.cabang == cabang then
				order += 1
				local level = levels[def.id] or 0
				local maxed = level >= def.maxLevel
				local sub = `Lv {level}/{def.maxLevel} · {Locale.t(`skill.{def.id}.desc`)}`
				UiKit.row(list, order, Locale.t(`skill.{def.id}`), sub, Locale.t("skill.buy"), not maxed and spBalance() >= Skills.SP_PER_LEVEL, function()
					Net.Send("SkillBuy", def.id)
				end)
			end
		end
	end
end

function SkillController.Init()
	panel = UiKit.panel("SkillPanel", Locale.t("skill.title"), function()
		if panel then
			panel.gui.Enabled = false
		end
	end)
end

function SkillController.Start()
	State.Changed:Connect(function()
		if panel and panel.gui.Enabled then
			rebuild()
		end
	end)
	player:GetAttributeChangedSignal("SP"):Connect(function()
		if panel and panel.gui.Enabled then
			rebuild()
		end
	end)
	task.spawn(UiKit.hudButton, "SkillButton", Locale.t("skill.title"), 8, function()
		if panel then
			panel.gui.Enabled = not panel.gui.Enabled
			rebuild()
		end
	end)
end

return SkillController
