--!strict
-- Client side of Dapur + Warung + Makan (Bab 9.1/9.2/9.3/9.4): panel resep/slot/warung/buff.
-- Tombol "Dapur" di HUD. Server yang memutuskan semuanya; ini presentasi + input.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.Parent.UiKit)
local State = require(script.Parent.Parent.State)
local FeatureClient = require(script.Parent.Parent.FeatureClient)

local DapurController = {}

local panel: UiKit.Panel? = nil

local function fmtCountdown(endsAt: number): string
	local left = math.max(endsAt - os.time(), 0)
	return string.format("%d:%02d", math.floor(left / 60), left % 60)
end

local function costText(recipe: Dapur.Recipe): string
	local bits = {}
	for _, input in recipe.inputs do
		if input.kind == "crop" and input.id then
			table.insert(bits, `{input.count} {Locale.t(`crop.{input.id}`)}`)
		elseif input.kind == "fish" and input.cat then
			table.insert(bits, `{input.count} Ikan {string.upper(string.sub(input.cat, 1, 1))}{string.sub(input.cat, 2)}`)
		elseif input.kind == "garam" then
			table.insert(bits, `{input.count} {Locale.t("item.garam")}`)
		elseif (input.kind == "bahan" or input.kind == "ternak") and input.id then
			table.insert(bits, `{input.count} {Locale.t(`item.{input.id}`)}`)
		elseif input.kind == "olahan" and input.id then
			table.insert(bits, `{input.count} {Locale.t(`olahan.{input.id}`)}`)
		end
	end
	return table.concat(bits, " + ")
end

-- Bahan tanaman yang belum terbuka di level pemain (R1.1, K-02): ditampilkan di kartu resep.
local function lockedIngredientsText(recipe: Dapur.Recipe): string?
	local value = game:GetService("Players").LocalPlayer:GetAttribute("Level")
	local level = if typeof(value) == "number" then value else 1
	local bits = {}
	for _, input in recipe.inputs do
		local crop = input.kind == "crop" and input.id and Crops.byId[input.id]
		if crop and crop.unlockLevel > level then
			table.insert(bits, `{Locale.t(`crop.{crop.id}`)} ({Locale.t("ui.locked", { level = crop.unlockLevel })})`)
		end
	end
	if #bits == 0 then
		return nil
	end
	return Locale.t("dapur.locked_ingredients", { list = table.concat(bits, ", ") })
end

local function recipeName(recipe: Dapur.Recipe): string
	if recipe.id == "pakan_jagung" then
		return Locale.t("item.pakan_jagung")
	end
	return Locale.t(`olahan.{recipe.id}`)
end

local function rebuild()
	local list = panel and panel.list
	if not list then
		return
	end
	UiKit.clear(list)
	local snap = State.current :: any
	if not snap then
		return
	end
	local items = snap.items or {}
	local dapur = snap.dapur or { tier = 0, slots = {} }
	local warung = snap.warung or {}
	local buff = snap.buff
	local order = 0

	-- Buff aktif (Bab 9.4).
	if buff and typeof(buff.id) == "string" and typeof(buff.endsAt) == "number" and buff.endsAt > os.time() then
		order += 1
		UiKit.header(list, `{Locale.t(`buff.{buff.id}`)} · {fmtCountdown(buff.endsAt)}`, order)
	end

	-- Dapur.
	order += 1
	if dapur.tier < 1 then
		local cost = Dapur.TIERS[1]
		local bits = {}
		for _, mat in cost.mats do
			table.insert(bits, `{mat.count} {Locale.t(`item.{mat.id}`)}`)
		end
		UiKit.row(list, order, Locale.t("dapur.build"), `{Locale.t("dapur.title")} Tier 1 (Lv 6): {table.concat(bits, " + ")}`, Locale.t("dapur.build"), true, function()
			Net.Send("DapurBuild")
		end)
	else
		UiKit.header(list, `{Locale.t("dapur.title")} Tier {dapur.tier}`, order)
		if dapur.tier < #Dapur.TIERS then
			local cost = Dapur.TIERS[dapur.tier + 1]
			local bits = {}
			for _, mat in cost.mats do
				table.insert(bits, `{mat.count} {Locale.t(`item.{mat.id}`)}`)
			end
			order += 1
			UiKit.row(list, order, Locale.t("dapur.upgrade"), `Tier {dapur.tier + 1} (Lv {cost.unlockLevel}): {table.concat(bits, " + ")} + refund 100%`, Locale.t("dapur.upgrade"), true, function()
				Net.Send("DapurUpgrade")
			end)
		end
		for slot = 1, Dapur.TIERS[dapur.tier].slots do
			order += 1
			local entry = dapur.slots and dapur.slots[slot]
			local recipe = entry and Dapur.byId[entry.recipe]
			if entry and recipe then
				local ready = os.time() >= (entry.endsAt or 0)
				local sub = if ready then Locale.t("dapur.collect") else fmtCountdown(entry.endsAt or 0)
				UiKit.row(list, order, `Slot {slot}: {recipeName(recipe)}`, sub, Locale.t("dapur.collect"), ready, function()
					Net.Send("DapurCollect", slot)
				end)
			else
				UiKit.header(list, `Slot {slot}: {Locale.t("warung.empty")}`, order)
			end
		end
	end

	-- Resep (Bab 9.2).
	order += 1
	UiKit.header(list, `Resep ({#Dapur.RECIPES})`, order)
	for _, recipe in Dapur.RECIPES do
		order += 1
		local locked = dapur.tier < recipe.tier
		local sub = `{math.floor(recipe.minutes * Dapur.TIERS[recipe.tier].timeMult + 0.5)} mnt · {costText(recipe)} · {recipe.xp} XP`
		local lockedText = lockedIngredientsText(recipe)
		if lockedText then
			sub ..= ` · {lockedText}`
		end
		UiKit.row(list, order, recipeName(recipe), sub, Locale.t("dapur.cook"), not locked, function()
			Net.Send("DapurCook", 0, recipe.id)
		end)
	end

	-- Tas Olahan: makan = buff.
	order += 1
	UiKit.header(list, Locale.t("dapur.eat"), order)
	local anyOlahan = false
	for itemId, count in items do
		local info = Items.info(itemId)
		if info and info.kind == "olahan" and count > 0 then
			anyOlahan = true
			order += 1
			UiKit.row(list, order, Items.displayName(info), `x{count}`, Locale.t("dapur.eat"), true, function()
				Net.Send("DapurEat", itemId)
			end)
		end
	end
	if not anyOlahan then
		order += 1
		UiKit.header(list, "—", order)
	end

	-- Warung (Q-2 gate "warung"): not built in this panel while the feature is closed; the block is last in rebuild().
	if not FeatureClient.IsOpen("warung") then
		return
	end
	-- Warung.
	order += 1
	if not warung.spot then
		UiKit.row(list, order, Locale.t("warung.title"), "Lv 6 · gratis", Locale.t("warung.title"), true, function()
			Net.Send("WarungBuild")
		end)
	else
		UiKit.header(list, Locale.t("warung.title"), order)
		local slot = warung.item
		if slot then
			order += 1
			local info = Items.info(slot.id)
			UiKit.row(list, order, if info then Items.displayName(info) else slot.id, `x{slot.count}`, Locale.t("warung.take"), true, function()
				Net.Send("WarungTake")
			end)
		else
			order += 1
			UiKit.header(list, Locale.t("warung.empty"), order)
		end
		for itemId, count in items do
			local info = Items.info(itemId)
			if info and info.kind == "olahan" and count > 0 and (not slot or slot.id ~= itemId) then
				order += 1
				UiKit.row(list, order, Items.displayName(info), `x{count}`, Locale.t("warung.display"), slot == nil, function()
					Net.Send("WarungDisplay", itemId)
				end)
			end
		end
	end
end

function DapurController.Init()
	panel = UiKit.panel("DapurPanel", `{Locale.t("dapur.title")} + {Locale.t("warung.title")}`, function()
		if panel then
			panel.gui.Enabled = false
		end
	end)
end

function DapurController.Start()
	State.Changed:Connect(function()
		if panel and panel.gui.Enabled then
			rebuild()
		end
	end)
	FeatureClient.GateHud("DapurButton", "dapur") -- Q-2: hidden until the dapur feature is open
	task.spawn(UiKit.hudButton, "DapurButton", Locale.t("dapur.title"), 4, function()
		if panel then
			panel.gui.Enabled = not panel.gui.Enabled
			rebuild()
		end
	end)
	-- Hitung mundur slot + kunjungan warung.
	task.spawn(function()
		while true do
			task.wait(1)
			if panel and panel.gui.Enabled then
				rebuild()
			end
		end
	end)
end

return DapurController
