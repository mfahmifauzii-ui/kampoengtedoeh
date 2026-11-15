--!strict
-- STUDIO-ONLY test commands typed in chat. Does nothing in live servers.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Blueprints = require(ReplicatedStorage.Shared.Config.Blueprints)
local Buffs = require(ReplicatedStorage.Shared.Config.Buffs)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local FarmService = require(script.Parent.FarmService)
local FishService = require(script.Parent.FishService)
local InventoryService = require(script.Parent.InventoryService)
local OrderService = require(script.Parent.OrderService)
local ProgressionService = require(script.Parent.ProgressionService)
local WorldService = require(script.Parent.WorldService)
local MonetizationService = require(script.Parent.MonetizationService)
local EventService = require(script.Parent.EventService)

local HELP = "!koin 500, !koin -200, !bunga 5, !level 10, !xp 100, !orders, !grow, !time malam, !rain, !rod fiber, !pond (fills all your ponds; build one first via Garap > Kolam, needs Lv 2: !level 2),!inv, !pass backpack, !receipt bunga_s, !event lebaran|off|auto, !likes 9, !buff tani 60 (UI test only: no effect yet), !give kangkung 30, !sales, !quota reset, !tut [reset|fast],!blueprint all|taman|pondok_sawah"

local DevService = {}

local function currencyCommand(player: Player, currency: any, amount: number)
	local currencyName = `currency.{currency}`
	if amount > 0 then
		EconomyService.Add(player, currency, amount, "dev")
		Net.Fire("Notify", player, "notify.gain", { n = amount, currency = currencyName })
	elseif amount < 0 then
		if EconomyService.TrySpend(player, currency, -amount, "dev") then
			Net.Fire("Notify", player, "notify.spent", { n = -amount, currency = currencyName })
		else
			Net.Fire("Notify", player, "notify.not_enough", { currency = currencyName })
		end
	end
end

local function onChatted(player: Player, message: string)
	if message:sub(1, 1) ~= "!" then
		return
	end
	print(`[DevService] {player.Name}: {message}`)
	local normalized = message:gsub("\u{2212}", "-") -- typographic minus from autocorrect

	-- "!reset": wipes this player's save back to a brand-new account (Studio store only), then kicks so the next join is fresh.
	if normalized:match("^!reset%s*$") then
		local profile = DataService.GetProfile(player)
		if profile then
			for key in profile.Data do
				profile.Data[key] = nil
			end
			profile:Reconcile()
			player:Kick("Progress direset. Join ulang untuk mulai dari awal.")
		end
		return
	end

	-- "!buff tani 60": lights a buff slot on the player card for 60 seconds (0 = off). Display only, the effect is not coded.
	local buffId, buffSeconds = normalized:match("^!buff%s+(%a+)%s*(%d*)%s*$")
	if buffId then
		local seconds = tonumber(buffSeconds) or 60
		for _, def in Buffs.SLOTS do
			if def.id == buffId then
				player:SetAttribute(`Buff_{def.id}_Dur`, math.max(seconds, 1))
				player:SetAttribute(`Buff_{def.id}_End`, Workspace:GetServerTimeNow() + seconds)
				print(`[DevService] buff {def.id} for {seconds}s (display only)`)
			end
		end
		return
	end

	-- "!give kangkung 30": put items straight into the bag (any item id from Modules/Items).
	local giveItem, giveCount = normalized:match("^!give%s+(%S+)%s*(%d*)%s*$")
	if giveItem then
		local count = tonumber(giveCount) or 1
		if Items.info(giveItem) and InventoryService.CanAdd(player, giveItem, count) then
			InventoryService.Add(player, giveItem, count)
			print(`[DevService] gave {giveItem} x{count}`)
		else
			warn(`[DevService] !give: unknown item or bag full: {giveItem}`)
		end
		return
	end

	local command, arg = normalized:match("^!(%a+)%s*(%S*)%s*$")
	local amount = tonumber(arg)

	if (command == "koin" or command == "bunga") and amount then
		currencyCommand(player, command, amount)
	elseif command == "level" and amount and amount >= 1 then
		ProgressionService.DevSetLevel(player, amount)
	elseif command == "xp" and amount and amount > 0 then
		ProgressionService.AddXp(player, amount, "dev")
	elseif command == "pass" then
		MonetizationService.DevTogglePass(player, arg)
	elseif command == "receipt" then
		-- "!receipt bunga_s" twice with the same fake id must grant only once.
		print(`[DevService] receipt #1: {MonetizationService.DevReceipt(player, arg, "dev-test-1")}`)
		print(`[DevService] receipt #2 (same id): {MonetizationService.DevReceipt(player, arg, "dev-test-1")}`)
	elseif command == "event" and arg ~= "" then
		EventService.DevSet(arg)
	elseif command == "likes" and amount and amount >= 0 then
		-- Sets your received likes (milestones pay on the next real like or rejoin).
		local data = DataService.Get(player)
		if data then
			data.social.likes = math.floor(amount)
			print(`[DevService] likes = {data.social.likes}`)
		end
	elseif command == "orders" then
		OrderService.DevNewOrders(player)
	elseif command == "grow" then
		FarmService.DevFinishAll(player)
	elseif command == "time" and table.find({ "pagi", "siang", "sore", "malam" }, arg) then
		WorldService.DevSetPhase(arg)
	elseif command == "rain" then
		WorldService.DevToggleRain()
		print(`[DevService] Raining = {Workspace:GetAttribute("Raining")}`)
	elseif command == "rod" and Fishing.rods[arg] then
		local data = DataService.Get(player)
		if data then
			data.fishing.ownedRods[arg] = true
			data.fishing.rod = arg
			InventoryService.Sync(player)
		end
	elseif command == "blueprint" then
		-- "!blueprint all" or "!blueprint taman": own a blueprint without buying it.
		local data = DataService.Get(player)
		if data then
			for _, blueprint in Blueprints.list do
				if arg == "all" or arg == blueprint.id then
					data.decor.blueprints[blueprint.id] = true
				end
			end
			InventoryService.Sync(player)
		end
	elseif command == "sales" then
		-- Prints save version, Pak Darmo's quota record and the leftovers of the old systems (should be nil).
		local data = DataService.Get(player)
		if data then
			print(`[DevService] version={data.version} sales={HttpService:JSONEncode(data.sales)} npc={tostring((data :: any).npc)} skills={tostring((data :: any).skills)} koin={data.koin}`)
		end
	elseif command == "quota" and arg == "reset" then
		-- Gives Pak Darmo's daily crop quota back (for testing the sell-to-Bang-Tarno fallback).
		local data = DataService.Get(player)
		if data then
			data.sales.sold = {}
			InventoryService.Sync(player)
		end
	elseif command == "tut" then
		-- "!tut reset": forget every tutorial (step, done, skipped) so they start again; "!tut fast": 6 fast plantings; "!tut" prints the state.
		local data = DataService.Get(player)
		if data then
			if arg == "reset" then
				data.guide.step = { id = "", n = 0 }
				data.guide.done = {}
				data.guide.skipped = {}
				InventoryService.Sync(player)
			elseif arg == "fast" then
				data.guide.fastLeft = 6
				InventoryService.Sync(player)
			end
			print(`[DevService] guide={HttpService:JSONEncode(data.guide)}`)
		end
	elseif command == "pond" then
		FishService.DevFillPond(player)
	elseif command == "inv" then
		local data = DataService.Get(player)
		if data then
			for itemId, count in data.inventory do
				print(`[DevService] {itemId} x{count}`)
			end
		end
	else
		warn(`[DevService] Unknown command. Use: {HELP}`)
	end
end

function DevService.Start()
	if not RunService:IsStudio() then
		return
	end
	local function hook(player: Player)
		player.Chatted:Connect(function(message)
			onChatted(player, message)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	print(`[DevService] Studio commands: {HELP}`)
end

return DevService
