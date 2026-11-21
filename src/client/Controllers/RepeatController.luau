-- Acara Berulang panel (HUD "AcaraButton"): Gerobak Kaget, Pasar Malam, Pesanan Tamu,
-- Kerja Bakti + Kalender (Bab 13, P2-6). Semua angka baca dari server snapshot;
-- daftar slot Gerobak deterministik (Config/Repeat) jadi klien sepakat tanpa sinkronisasi.
-- Tombol hanya kirim request; harga, stok, dan level dicek ulang di server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Decor = require(ReplicatedStorage.Shared.Config.Decor)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Ranch = require(ReplicatedStorage.Shared.Config.Ranch)
local Repeat = require(ReplicatedStorage.Shared.Config.Repeat)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local RepeatController = {}

local panel: UiKit.Panel
local button: GuiButton? = nil
local tab = "gerobak" -- "gerobak" | "pasar" | "tamu" | "acara"

local function koin(): number
	local value = player:GetAttribute("Koin")
	return if typeof(value) == "number" then value else 0
end

local function bunga(): number
	local value = player:GetAttribute("Bunga")
	return if typeof(value) == "number" then value else 0
end

-- Nama + harga slot Gerobak (cerminan gerobakPrice server; server yang memutuskan).
local function slotName(slot: any): string
	if slot.kind == "seed" then
		return Locale.t(`crop.{slot.id:match("^seed_(.+)$") or slot.id}`)
	elseif slot.kind == "hewan" then
		return Locale.t(`hewan.{slot.id}`)
	elseif slot.kind == "decor" or slot.kind == "rare" then
		return Locale.t(`decor.{slot.id}`)
	end
	return Locale.t(`item.{slot.id}`)
end

local function slotPrice(slot: any): (number, string)
	if slot.kind == "seed" then
		local crop = Crops.byId[slot.id:match("^seed_(.+)$") or ""]
		if crop then
			return math.floor(crop.seedPrice * Repeat.GEROBAK.SEED_PRICE_MULT + 0.5), "koin"
		end
		return 0, "koin"
	elseif slot.kind == "hewan" then
		local varian = Ranch.VARIAN[slot.id]
		if varian then
			return varian.price, "koin"
		end
		return 0, "koin"
	elseif slot.kind == "decor" or slot.kind == "rare" then
		local def = Decor.byId[slot.id]
		if def then
			return def.price, def.currency
		end
		return 0, "koin"
	end
	return slot.price or 0, "koin"
end

local function moneyText(price: number, currency: string): string
	if currency == "bunga" then
		return Locale.t("reward.bunga", { n = Locale.formatNumber(price) })
	end
	return Locale.t("reward.koin", { n = Locale.formatNumber(price) })
end

local function renderGerobak(list: ScrollingFrame, order: number, snapshot: any): number
	UiKit.header(list, Locale.t("gerobak.title"), order)
	order += 1
	local info = snapshot.gerobak
	if not info or not info.slots then
		return order
	end
	for _, slot in info.slots do
		local bought = 0
		if info.bought and typeof(info.bought[slot.slot]) == "number" then
			bought = info.bought[slot.slot]
		end
		local price, currency = slotPrice(slot)
		local name = slotName(slot)
		if not slot.stocked then
			UiKit.row(list, order, name, Locale.t("gerobak.empty"), Locale.t("gerobak.buy"), false)
		else
			local left = Repeat.GEROBAK.MAX_PER_SLOT - bought
			local afford = if currency == "bunga" then bunga() >= price else koin() >= price
			local sub = `{moneyText(price, currency)} A· {Locale.t("gerobak.sold", { bought = bought })}`
			UiKit.row(list, order, name, sub, Locale.t("gerobak.buy"), left > 0 and afford and price > 0, function()
				Net.Send("GerobakBuy", slot.slot)
			end)
		end
		order += 1
	end
	UiKit.header(list, Locale.t("gerobak.wait"), order)
	return order + 1
end

local function pasarItemName(itemId: string): string
	local fishId = itemId:match("^fish:(.+)$")
	if fishId then
		return Locale.t(`fish.{fishId}`)
	end
	return Locale.t(`crop.{itemId}`)
end

local function renderPasar(list: ScrollingFrame, order: number, snapshot: any): number
	UiKit.header(list, Locale.t("pasar.title"), order)
	order += 1
	local info = snapshot.pasar
	if not info or info.item == "" then
		UiKit.row(list, order, Locale.t("pasar.not_night"), nil, nil, false)
		return order + 1
	end
	local base = 0
	local crop = Crops.byId[info.item]
	if crop then
		base = crop.sellPrice
	else
		local fish = FishConfig.byId[info.item:match("^fish:(.+)$") or ""]
		if fish then
			base = fish.sellPrice
		end
	end
	local price = math.floor(base * Repeat.PASAR.BUY_MULT + 0.5)
	local title = `{Locale.t(`npc.{info.trader}`)}: {pasarItemName(info.item)}`
	UiKit.row(list, order, title, `{moneyText(price, "koin")} (+50%) A· {info.sold}/{Repeat.PASAR.MAX_PER_NIGHT}`, Locale.t("pasar.jual"), info.sold < Repeat.PASAR.MAX_PER_NIGHT, function()
		Net.Send("PasarJual", 1)
	end, Locale.t("pasar.jual_semua"), function()
		Net.Send("PasarJual", 999)
	end)
	order += 1
	local throwsLeft = Repeat.PASAR.GELANG_PER_NIGHT - (info.throws or 0)
	UiKit.row(list, order, Locale.t("pasar.lempar", { n = math.max(throwsLeft, 0) }), nil, Locale.t("pasar.lempar", { n = math.max(throwsLeft, 0) }), throwsLeft > 0, function()
		Net.Send("GelangThrow")
	-- Lempar Gelang tidak mengubah snapshot barang: hadiah masuk tas, toast yang bicara.
	end)
	return order + 1
end

local function renderTamu(list: ScrollingFrame, order: number, snapshot: any): number
	UiKit.header(list, Locale.t("tamu.title"), order)
	order += 1
	local info = snapshot.tamu
	if not info or info.event == "" or not info.items or next(info.items) == nil then
		UiKit.row(list, order, Locale.t("tamu.none"), nil, nil, false)
		return order + 1
	end
	UiKit.header(list, Locale.t("tamu.event_now", { event = Locale.t(`event.{info.event}`) }), order)
	order += 1
	local ready = true
	for itemId, need in info.items do
		local have = 0
		if snapshot.items and typeof(snapshot.items[itemId]) == "number" then
			have = snapshot.items[itemId]
		end
		if have < need then
			ready = false
		end
		UiKit.row(list, order, pasarItemName(itemId), `{have}/{need}`, nil, false)
		order += 1
	end
	UiKit.row(list, order, Locale.t("tamu.deliver"), nil, Locale.t("tamu.deliver"), ready and not info.done, function()
		Net.Send("TamuDeliver")
	end)
	return order + 1
end

local function renderAcara(list: ScrollingFrame, order: number, snapshot: any): number
	UiKit.header(list, Locale.t("kb.title"), order)
	order += 1
	local active = Workspace:GetAttribute("KBActive") == true
	if active then
		local got = Workspace:GetAttribute("KBGot")
		local total = Workspace:GetAttribute("KBTotal")
		local progress = if typeof(got) == "number" and typeof(total) == "number" then ` ({got}/{total})` else ""
		UiKit.row(list, order, `{Locale.t("kb.active")}{progress}`, Locale.t("kb.how"), nil, false)
	else
		UiKit.row(list, order, Locale.t("kb.none"), Locale.t("kb.how"), nil, false)
	end
	order += 1
	local untilTime = if snapshot and typeof(snapshot.discountUntil) == "number" then snapshot.discountUntil else 0
	if untilTime > os.time() then
		local left = math.ceil((untilTime - os.time()) / 60)
		UiKit.row(list, order, Locale.t("kb.discount_on"), `{left} mnt`, nil, false)
		order += 1
	end
	local nowEvent = Workspace:GetAttribute("EventAktif")
	for _, ev in Repeat.KALENDER do
		local mark = if nowEvent == ev.id then " [*]" else ""
		UiKit.row(list, order, `{Locale.t(`event.{ev.id}`)}{mark}`, `{ev.dayStart}/{ev.monthStart}-{ev.dayEnd}/{ev.monthEnd}`, nil, false)
		order += 1
	end
	return order
end

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	if not snapshot then
		return
	end
	local order = 1
	local bar = UiKit.tabs(panel.list, {
		{ id = "gerobak", text = Locale.t("repeat.tab.gerobak") },
		{ id = "pasar", text = Locale.t("repeat.tab.pasar") },
		{ id = "tamu", text = Locale.t("repeat.tab.tamu") },
		{ id = "acara", text = Locale.t("repeat.tab.acara") },
	}, tab, function(id)
		tab = id
		render()
	end)
	bar.frame.LayoutOrder = order
	order += 1
	if tab == "pasar" then
		renderPasar(panel.list, order, snapshot)
	elseif tab == "tamu" then
		renderTamu(panel.list, order, snapshot)
	elseif tab == "acara" then
		renderAcara(panel.list, order, snapshot)
	else
		renderGerobak(panel.list, order, snapshot)
	end
end

-- Titik merah: Kerja Bakti aktif atau Tamu menunggu diantar.
local function updateDot()
	if not button then
		return
	end
	local hot = Workspace:GetAttribute("KBActive") == true
	if not hot then
		local snapshot = State.current :: any
		local tamu = snapshot and snapshot.tamu
		hot = tamu ~= nil and tamu.event ~= "" and tamu.done ~= true and tamu.items ~= nil and next(tamu.items) ~= nil
	end
	UiKit.notifyDot(button :: GuiObject, if hot then 1 else 0)
end

function RepeatController.Init()
	panel = UiKit.panel("RepeatPanel", Locale.t("ui.acara"), function()
		panel.gui.Enabled = false
	end)
end

function RepeatController.Start()
	State.Changed:Connect(function()
		render()
		updateDot()
	end)
	Workspace:GetAttributeChangedSignal("KBActive"):Connect(function()
		render()
		updateDot()
	end)
	Workspace:GetAttributeChangedSignal("EventAktif"):Connect(function()
		render()
	end)
	player:GetAttributeChangedSignal("Koin"):Connect(render)
	player:GetAttributeChangedSignal("Bunga"):Connect(render)
	task.spawn(function()
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
		if not hud then
			return
		end
		local item = UiKit.menuItem(hud, "AcaraButton", Locale.t("ui.acara"), 9)
		if item then
			button = item
			item.Activated:Connect(function()
				panel.gui.Enabled = not panel.gui.Enabled
				render()
			end)
			updateDot()
		end
	end)
end

return RepeatController
