--!strict
-- Client side of Breeding Kolam (Bab 7.2): tombol Breeding di dekat kolam sendiri + panel
-- (tier + upgrade, mulai breeding per spesies, ambil anak, instant Bunga).
-- Server yang memutuskan semuanya; ini presentasi + input.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Ranch = require(ReplicatedStorage.Shared.Config.Ranch)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.Parent.UiKit)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local PondController = {}

local REACH = 10 -- studs ke kolam sendiri agar tombol tampil (server cek jarak spot)
local POND_TAG = "Pond"

local breedButton: TextButton? = nil
local panel: UiKit.Panel? = nil
local selectedUid: number? = nil -- kolam yang sedang dipilih untuk mulai breeding

local function ownPondNear(): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	for _, spot in CollectionService:GetTagged(POND_TAG) do
		if spot:IsA("BasePart") and spot:GetAttribute("Owner") == player.UserId then
			if (spot.Position - root.Position).Magnitude <= REACH then
				local uid = spot:GetAttribute("PondUid")
				if typeof(uid) == "number" then
					return uid
				end
			end
		end
	end
	return nil
end

local function fmtLeft(endsAt: number): string
	local left = math.max(endsAt - os.time(), 0)
	return string.format("%d:%02d", math.floor(left / 60), left % 60)
end

local function instantCost(remaining: number): number
	return math.min(Monetization.INSTANT_KOLAM_MAX_BUNGA, math.ceil(math.max(remaining, 0) / 600))
end

local function speciesCount(items: { [string]: number }, fishId: string): number
	local total = 0
	for _, size in FishConfig.SIZES do
		total += items[`{fishId}@{size.id}`] or 0
	end
	return total
end

local function costText(koin: number, mats: { { id: string, count: number } }): string
	local bits = { `{koin} Koin` }
	for _, mat in mats do
		table.insert(bits, `{mat.count} {Locale.t(`item.{mat.id}`)}`)
	end
	return table.concat(bits, " + ")
end

local function rebuild()
	local list = panel and panel.list
	if not list then
		return
	end
	UiKit.clear(list)
	local snap = State.current :: any
	local ponds = (snap and snap.pondState) or {}
	local items = (snap and snap.items) or {}
	local order = 0

	if #ponds == 0 then
		order += 1
		UiKit.header(list, Locale.t("pond.empty"), order)
		return
	end

	for _, pond in ponds do
		local uid = pond.uid
		order += 1
		local tierId = if typeof(pond.tier) == "string" then pond.tier else "tanah"
		local title = `Kolam {uid} • {Locale.t(`pond.tier.{tierId}`)}{if pond.kakek then " • Kakek" else ""}`
		UiKit.header(list, title, order)

		local breed = pond.breed
		if breed then
			order += 1
			local ready = os.time() >= (breed.endsAt or 0)
			if ready then
				UiKit.row(list, order, Locale.t(`fish.{breed.fish}`), Locale.t("pond.breed_done", { item = `fish.{breed.fish}` }), Locale.t("ranch.collect"), true, function()
					Net.Send("BreedCollect", uid)
				end)
			else
				local cost = instantCost((breed.endsAt or 0) - os.time())
				UiKit.row(list, order, Locale.t(`fish.{breed.fish}`), fmtLeft(breed.endsAt or 0), nil, false, nil, `{Locale.t("pond.instant")} {cost}B`, function()
					Net.Send("BreedInstant", uid)
				end)
			end
		elseif selectedUid == uid then
			for _, fish in FishConfig.list do
				if fish.rarity ~= "L" then
					local count = speciesCount(items, fish.id)
					if count >= 2 then
						order += 1
						UiKit.row(list, order, Locale.t(`fish.{fish.id}`), `x{count}`, Locale.t("pond.breed_start"), true, function()
							Net.Send("BreedStart", uid, fish.id)
							selectedUid = nil
						end)
					end
				end
			end
			order += 1
			UiKit.row(list, order, Locale.t("ui.close"), nil, Locale.t("ui.close"), true, function()
				selectedUid = nil
				rebuild()
			end)
		else
			order += 1
			UiKit.row(list, order, Locale.t("pond.breed_title"), `{Ranch.BREED_FEED_KOIN} Koin + 2 ikan`, Locale.t("pond.breed_start"), true, function()
				selectedUid = uid
				rebuild()
			end)
		end

		local nextTier = if tierId == "tanah" then "semen" elseif tierId == "semen" then "keramik" else nil
		if nextTier then
			local cost = Ranch.byTier[nextTier]
			order += 1
			UiKit.row(list, order, Locale.t("pond.upgrade"), costText(cost.koin, cost.mats), Locale.t("pond.upgrade"), true, function()
				Net.Send("PondTier", uid, nextTier)
			end)
		end
	end
end

local function refreshButton()
	if not breedButton then
		return
	end
	breedButton.Visible = ownPondNear() ~= nil
end

function PondController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PondUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = playerGui

	local aksi = UiKit.button(gui, "PondAksiButton", Locale.t("pond.breed_title"), UiKit.BUTTON_MUTED)
	aksi.AnchorPoint = Vector2.new(1, 1)
	aksi.Position = UDim2.new(1, -24, 1, -392)
	aksi.Size = UDim2.fromOffset(104, 64)
	aksi.TextSize = 15
	aksi.Visible = false
	aksi.Activated:Connect(function()
		if panel then
			panel.gui.Enabled = true
			selectedUid = nil
			rebuild()
		end
	end)
	breedButton = aksi

	panel = UiKit.panel("PondPanel", Locale.t("pond.breed_title"), function()
		if panel then
			panel.gui.Enabled = false
		end
	end)
end

function PondController.Start()
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
	-- Hitung mundur breeding di panel yang terbuka.
	task.spawn(function()
		while true do
			task.wait(1)
			if panel and panel.gui.Enabled then
				rebuild()
			end
		end
	end)
end

return PondController
