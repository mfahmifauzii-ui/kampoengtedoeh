--!strict
-- Collection Book panel (HUD "BookButton" / placeholder "Koleksi").
-- Unknown entries show as "???" so players feel what's left to find.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Book = require(ReplicatedStorage.Shared.Config.Book)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Locale = require(ReplicatedStorage.Shared.Locale)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local _player = Players.LocalPlayer

local PREFIX = { crops = "crop", fish = "fish", decor = "decor" }

local BookController = {}

local panel: UiKit.Panel

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	if not snapshot or not snapshot.book then
		return
	end
	local book = snapshot.book
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	local found, total = 0, 0
	for _, category in Book.CATEGORIES do
		local entries = Book.ENTRIES[category]
		local recorded = book[category]
		local categoryFound = 0
		for _, id in entries do
			if recorded[id] then
				categoryFound += 1
			end
		end
		found += categoryFound
		total += #entries

		UiKit.header(panel.list, `{Locale.t(`book.cat.{category}`)}  {categoryFound}/{#entries}`, nextOrder())
		for _, id in entries do
			local value = recorded[id]
			if value == nil then
				UiKit.row(panel.list, nextOrder(), Locale.t("book.unknown"))
			elseif category == "fish" then
				local size = FishConfig.SIZES[value]
				UiKit.row(panel.list, nextOrder(), Locale.t(`fish.{id}`), Locale.t("book.best_size", { size = Locale.t(`size.{size and size.id or "S"}`) }))
			else
				UiKit.row(panel.list, nextOrder(), Locale.t(`{PREFIX[category]}.{id}`), Locale.t("book.found"))
			end
		end
	end

	UiKit.header(panel.list, Locale.t("ui.book"), nextOrder())
	for _, milestone in Book.MILESTONES do
		local claimed = book.claimed[milestone.id] == true
		UiKit.row(panel.list, nextOrder(), Locale.t("book.milestone_row", { percent = milestone.percent }), nil,
			if claimed then Locale.t("book.claimed") else `{milestone.percent}%`, false)
	end

	local titles = {}
	for titleId in snapshot.titles or {} do
		table.insert(titles, Locale.t(`title.{titleId}`))
	end
	if #titles > 0 then
		UiKit.header(panel.list, Locale.t("book.titles", { titles = table.concat(titles, ", ") }), nextOrder())
	end

	local percent = if total > 0 then math.floor(found / total * 100) else 0
	panel.footerLabel.Text = Locale.t("book.progress", { n = found, total = total, percent = percent })
end

function BookController.Init()
	panel = UiKit.panel("BookPanel", Locale.t("ui.book"), function()
		panel.gui.Enabled = false
	end)
end

function BookController.Start()
	State.Changed:Connect(render)
	task.spawn(UiKit.hudButton, "BookButton", Locale.t("ui.book"), 4, function()
		panel.gui.Enabled = not panel.gui.Enabled
		render()
	end)
end

return BookController
