--!strict
-- Client side of Ternak (Bab 7.1): tombol Kelola di dekat kandang sendiri + panel kandang
-- (bangun / upgrade / beli hewan / isi pakan / pakan jagung / ambil semua) + badge Mood Hujan.
-- Server yang memutuskan semuanya; ini presentasi + input.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ranch = require(ReplicatedStorage.Shared.Config.Ranch)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.Parent.UiKit)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local RanchController = {}

local REACH = 10 -- studs ke kandang sendiri agar tombol tampil (server cek 18)
local RANCH_TAG = "Ranch"

local kelolaButton: TextButton? = nil
local panel: UiKit.Panel? = nil

local function ownKandangNear(): string?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	for _, spot in CollectionService:GetTagged(RANCH_TAG) do
		if spot:IsA("BasePart") and spot:GetAttribute("Owner") == player.UserId then
			local hewanId = spot:GetAttribute("HewanId")
			if typeof(hewanId) == "string" and Ranch.byHewan[hewanId] then
				if (spot.Position - root.Position).Magnitude <= REACH then
					return hewanId
				end
			end
		end
	end
	return nil
end

local function costText(koin: number, mats: { { id: string, count: number } }): string
	local bits = { `{koin} Koin` }
	for _, mat in mats do
		table.insert(bits, `{mat.count} {Locale.t(`item.{mat.id}`)}`)
	end
	return table.concat(bits, " + ")
end

local function statusText(hewan: Ranch.Hewan, animals: { any }): string
	local feed, prod = 0, 0
	for _, animal in animals do
		feed += if typeof(animal.feed) == "number" then animal.feed else 0
		prod += if typeof(animal.prod) == "number" then animal.prod else 0
	end
	return `{hewan.product.minutes} mnt/siklus | pakan {feed} | siap {prod}`
end

local function rebuild()
	local list = panel and panel.list
	if not list then
		return
	end
	UiKit.clear(list)
	local snap = State.current :: any
	local ranch = snap and snap.ranch
	local kandang = (ranch and ranch.kandang) or {}
	local order = 0

	-- Badge Mood Hujan (Bab 7.1): jendela 5 menit setelah hujan.
	if ranch and typeof(ranch.moodUntil) == "number" and ranch.moodUntil > os.time() then
		order += 1
		UiKit.header(list, Locale.t("ranch.mood_on"), order)
	end

	for _, hewan in Ranch.HEWAN do
		order += 1
		local entry = kandang[hewan.id]
		if entry then
			local cap = hewan.maxAnimals[math.clamp(entry.tier or 1, 1, #hewan.maxAnimals)]
			local title = `{Locale.t(`hewan.{hewan.id}`)} Lv{entry.tier or 1} ({#(entry.animals or {})}/{cap})`
			UiKit.header(list, title, order)
			order += 1
			local sub = statusText(hewan, entry.animals or {})
			UiKit.row(list, order, Locale.t("ranch.collect"), sub, Locale.t("ranch.collect"), true, function()
				Net.Send("RanchAmbil", hewan.id)
			end)
			order += 1
			local tpb = (snap and snap.skills and snap.skills.tempat_pakan_besar) or 0
			local maxFeed = if tpb >= 1 then 5 else Ranch.FEED_MAX
			local missing = 0
			for _, animal in entry.animals or {} do
				missing += math.max(maxFeed - (animal.feed or 0), 0)
			end
			local feedCost = `{missing * hewan.feedPrice} Koin`
			UiKit.row(list, order, Locale.t("ranch.feed"), feedCost, Locale.t("ranch.feed"), missing > 0, function()
				Net.Send("RanchPakan", hewan.id, "koin")
			end, if hewan.id == "ayam" then Locale.t("ranch.jagung_btn") else nil, if hewan.id == "ayam"
				then function()
					Net.Send("RanchPakan", hewan.id, "jagung")
				end
				else nil)
			if hewan.id == "ayam" then
				order += 1
				local snapItems = (snap and snap.items) or {}
				UiKit.row(list, order, Locale.t("item.pakan_jagung"), `x{snapItems.pakan_jagung or 0}`, Locale.t("ranch.pakan_btn"), (snapItems.pakan_jagung or 0) > 0, function()
					Net.Send("RanchPakan", hewan.id, "pakan")
				end)
			end
			order += 1
			UiKit.row(list, order, Locale.t("ranch.buy"), `{hewan.price} Koin`, Locale.t("ranch.buy"), true, function()
				Net.Send("RanchHewan", hewan.id)
			end)
			if (entry.tier or 1) < 2 then
				local cost = Ranch.KANDANG[hewan.id].upgrade
				order += 1
				UiKit.row(list, order, Locale.t("ranch.upgrade"), costText(cost.koin, cost.mats), Locale.t("ranch.upgrade"), true, function()
					Net.Send("RanchKandang", hewan.id, 2)
				end)
			end
		else
			local cost = Ranch.KANDANG[hewan.id].build
			UiKit.row(list, order, `{Locale.t("ranch.title")}: {Locale.t(`hewan.{hewan.id}`)}`, costText(cost.koin, cost.mats), Locale.t("ranch.buy"), true, function()
				Net.Send("RanchKandang", hewan.id, 1)
			end)
		end
	end
end

local function refreshButton()
	if not kelolaButton then
		return
	end
	kelolaButton.Visible = ownKandangNear() ~= nil
end

function RanchController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RanchUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = playerGui

	local kelola = UiKit.button(gui, "RanchAksiButton", Locale.t("ranch.manage"), UiKit.BUTTON_MUTED)
	kelola.AnchorPoint = Vector2.new(1, 1)
	kelola.Position = UDim2.new(1, -24, 1, -316)
	kelola.Size = UDim2.fromOffset(104, 64)
	kelola.TextSize = 16
	kelola.Visible = false
	kelola.Activated:Connect(function()
		if panel then
			panel.gui.Enabled = true
			rebuild()
		end
	end)
	kelolaButton = kelola

	panel = UiKit.panel("RanchPanel", Locale.t("ranch.title"), function()
		if panel then
			panel.gui.Enabled = false
		end
	end)
end

function RanchController.Start()
	Net.Listen("RanchOpen", function()
		if panel then
			panel.gui.Enabled = true
			rebuild()
		end
	end)
	State.Changed:Connect(function()
		if panel and panel.gui.Enabled then
			rebuild()
		end
	end)
	task.spawn(function()
		while true do
			refreshButton()
			task.wait(0.25)
		end
	end)
end

return RanchController
