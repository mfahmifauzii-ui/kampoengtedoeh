--!strict
-- Collection Book panel (HUD "BookButton" / placeholder "Koleksi"). Two tabs (R3 17.5):
--   * Koleksi: one grid per category (Ladang, Sungai, Kandang, Rumah, Dapur, Varian). Unknown entries show as "???"
--     so players feel what's left.
--   * Hadiah: the category and overall milestone rewards. They are NOT automatic any more: a reached one has a "Klaim"
--     button that sends BookClaim (the server checks everything again and pays once).
-- Milestone = USULAN (Bab 11), bukan LOCKED.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Book = require(ReplicatedStorage.Shared.Config.Book)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local _player = Players.LocalPlayer

local TILE_HEIGHT = 58
local TILE_ROWS_GAP = 6

local BookController = {}

local panel: UiKit.Panel
local tab = "collect" -- "collect" | "rewards"

-- Entries of one category that the player has found.
local function foundIn(book: any, category: string): number
	local count = 0
	for _, id in Book.ENTRIES[category] do
		if book[category][id] ~= nil then
			count += 1
		end
	end
	return count
end

-- One cell of the collection grid (5 per row): found = the picture + name (+ Kualitas/ukuran); not found = a dimmed "?".
-- Entry id: ladang "{crop}:{kualitas}", sungai "{fish}@{size}", lain = id polos.
local CAT_OF = { ladang = "crop", sungai = "fish", kandang = "crop", rumah = "decor", dapur = "gold", varian = "gold" }
local ICON_OF = { ladang = "bibit", sungai = "ikan", kandang = "hias", rumah = "hias", dapur = "panen", varian = "bintang" }

local function tileName(category: string, id: string): (string, string?)
	if category == "ladang" then
		local cropId, quality = id:match("^(.+):(%w+)$")
		if cropId then
			return Locale.t(`crop.{cropId}`), Locale.t(`kualitas.{quality}`)
		end
		return Locale.t(`crop.{id}`), nil
	elseif category == "sungai" then
		local fishId, size = id:match("^(.+)@(%w+)$")
		if fishId then
			return Locale.t(`fish.{fishId}`), Locale.t(`size.{size}`)
		end
		return Locale.t(`fish.{id}`), nil
	elseif category == "rumah" then
		return Locale.t(`decor.{id}`), nil
	end
	return Locale.t(`{category}.{id}`), nil -- kandang/dapur/varian: nama menyusul saat sistemnya ada (P2)
end

local function tile(grid: Frame, order: number, category: string, id: string, value: any)
	local found = value ~= nil
	local name: string
	local sub: string? = nil
	if found then
		name, sub = tileName(category, id)
	else
		name = Locale.t("book.unknown")
	end
	local cell = UiKit.cell(grid, order, {
		name = name,
		sub = sub,
		accent = if found then UiKit.CAT[CAT_OF[category] or "gold"] else Color3.fromRGB(190, 172, 140),
		cropId = if found and category == "ladang" then (id:match("^(.+):") or id) else nil,
		icon = ICON_OF[category] or "bintang",
	})
	if not found then
		for _, child in cell:GetDescendants() do
			if child:IsA("ImageLabel") then
				child.ImageTransparency = 0.7
				child.ImageColor3 = Color3.fromRGB(120, 100, 80)
			end
		end
	end
end

local function renderCollect(book: any, nextOrder: () -> number)
	for _, category in Book.CATEGORIES do
		local entries = Book.ENTRIES[category]
		local recorded = book[category]
		UiKit.header(panel.list, `{Locale.t(`book.cat.{category}`)}  {foundIn(book, category)}/{#entries}`, nextOrder())
		local grid = UiKit.grid(panel.list, nextOrder(), 5, 92)
		for index, id in entries do
			tile(grid, index, category, id, recorded[id])
		end
	end
end

-- Whether a category / milestone is reached (the server checks the same thing when you claim).
-- Percent over the 214 GUI entries (kandang + rumah excluded, same as the server).
local function guiFound(book: any): (number, number)
	local found, total = 0, 0
	for _, category in Book.GUI_CATEGORIES do
		found += foundIn(book, category)
		total += #Book.ENTRIES[category]
	end
	return found, total
end

local function reached(book: any, key: string): boolean
	local category = string.match(key, "^cat:(%w+)$")
	if category then
		return Book.ENTRIES[category] ~= nil and foundIn(book, category) == #Book.ENTRIES[category]
	end
	for _, milestone in Book.MILESTONES do
		if milestone.id == key then
			local found, total = guiFound(book)
			return total > 0 and found / total * 100 >= milestone.percent
		end
	end
	return false
end

local function claimRow(order: number, key: string, title: string, sub: string?, book: any)
	local claimed = book.claimed[key] == true
	local ready = not claimed and reached(book, key)
	local buttonText = if claimed then Locale.t("book.claimed") elseif ready then Locale.t("book.claim") else "-"
	UiKit.row(panel.list, order, title, sub, buttonText, ready, function()
		Net.Send("BookClaim", key)
	end)
end

local function renderRewards(book: any, nextOrder: () -> number)
	UiKit.header(panel.list, Locale.t("book.tab.milestone"), nextOrder())
	for _, category in Book.CATEGORIES do
		if Book.CATEGORY_REWARDS[category] ~= nil then
			claimRow(nextOrder(), `cat:{category}`, Locale.t("book.cat_claim", { category = Locale.t(`book.cat.{category}`) }), nil, book)
		end
	end
	for _, milestone in Book.MILESTONES do
		claimRow(nextOrder(), milestone.id, Locale.t("book.milestone_row", { percent = milestone.percent }), nil, book)
	end
end

local function tabBar(nextOrder: () -> number)
	local holder = Instance.new("Frame")
	holder.Name = "TabBar"
	holder.LayoutOrder = nextOrder()
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 34)
	holder.Parent = panel.list
	local bar = UiKit.tabs(holder, {
		{ id = "collect", text = Locale.t("book.tab.collect") },
		{ id = "rewards", text = Locale.t("book.tab.milestone") },
	}, tab, function(id)
		tab = id
		BookController.Render()
	end)
	bar.frame.Size = UDim2.fromScale(1, 1)
end

function BookController.Render()
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

	tabBar(nextOrder)
	if tab == "rewards" then
		renderRewards(book, nextOrder)
	else
		renderCollect(book, nextOrder)
	end

	local found, total = guiFound(book)
	local percent = if total > 0 then math.floor(found / total * 100) else 0
	panel.footerLabel.Text = Locale.t("book.progress", { n = found, total = total, percent = percent })
end

function BookController.Init()
	panel = UiKit.panel("BookPanel", Locale.t("ui.book"), function()
		panel.gui.Enabled = false
	end)
end

function BookController.Start()
	State.Changed:Connect(BookController.Render)
	task.spawn(UiKit.hudButton, "BookButton", Locale.t("ui.book"), 4, function()
		panel.gui.Enabled = not panel.gui.Enabled
		BookController.Render()
	end)
end

return BookController
