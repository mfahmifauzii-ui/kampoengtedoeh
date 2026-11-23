--!strict
-- STUDIO-ONLY test commands typed in chat. Does nothing in live servers.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
local QuestService = require(script.Parent.QuestService)
local TutorialService = require(script.Parent.TutorialService)
local DevAccess = require(ReplicatedStorage.Shared.Config.DevAccess)
local DevScenarios = require(ReplicatedStorage.Shared.Config.DevScenarios)

local HELP = "!koin 500, !koin -200, !bunga 5, !level 10, !xp 100, !sp 2, !orders, !grow, !time malam, !rain, !cuaca terik|gerimis|deres|petir, !rod fiber, !pond (fills all your ponds; build one first via Garap > Kolam, needs Lv 2: !level 2),!inv, !receipt bunga_s, !event lebaran|off|auto, !likes 9, !buff tani 60 (UI test only: no effect yet), !give kangkung 30, !tut [reset|fast], !kakek (unlock Kolam Kakek: MQ4/Bundel placeholder)"

local DevService = {}

-- K-64: the one check for every DEV command and remote. Studio always; live only for the whitelist, while LIVE_ENABLED.
function DevService.IsAllowed(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	return DevAccess.LIVE_ENABLED and table.find(DevAccess.UserIds, player.UserId) ~= nil
end

-- "!state": printed lines (Output) with what the player has right now.
local function printState(player: Player)
	local data = DataService.Get(player)
	if not data then
		warn("[DEV] !state: data belum termuat")
		return
	end
	local profile = DataService.GetProfile(player)
	print(`[DEV] {player.Name} lv={data.level} xp={data.xp} koin={data.koin} bunga={data.bunga} sp={data.sp} rod={data.fishing.rod} bait={data.fishing.equippedBait} studioMock={tostring(profile ~= nil and profile.studioMock == true)}`)
	local features = {}
	for id, state in data.features do
		table.insert(features, `{id}={state}`)
	end
	table.sort(features)
	print(`[DEV] fitur: {table.concat(features, " ")}`)
	local active, done, items = {}, {}, {}
	for id in data.quests.active do
		table.insert(active, `{id}@{data.quests.active[id].step}`)
	end
	for id in data.quests.done do
		table.insert(done, id)
	end
	for id, count in data.inventory do
		if count > 0 then
			table.insert(items, `{id}x{count}`)
		end
	end
	table.sort(active)
	table.sort(done)
	table.sort(items)
	print(`[DEV] quest aktif: {table.concat(active, " ")}`)
	print(`[DEV] quest selesai: {table.concat(done, " ")}`)
	print(`[DEV] tas: {table.concat(items, " ")}`)
	local agendaParts = {}
	for _, task in data.quests.agenda.tasks do
		table.insert(agendaParts, `{task.id}={task.progress}{if task.claimed then "*" else ""}`)
	end
	print(`[DEV] agenda {data.quests.agenda.day}: {table.concat(agendaParts, " ")}`)
	local harianParts = {}
	for _, slot in data.quests.harian.slots do
		table.insert(harianParts, `{slot.kind}={slot.progress}{if slot.claimed then "*" else ""}`)
	end
	print(`[DEV] harian {data.quests.harian.day}: {table.concat(harianParts, " ")}`)
	local mingguanParts = {}
	for _, slot in data.quests.mingguan.slots do
		table.insert(mingguanParts, `{slot.kind}={slot.progress}{if slot.claimed then "*" else ""}`)
	end
	print(`[DEV] mingguan {data.quests.mingguan.week}: {table.concat(mingguanParts, " ")}`)
end

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

	-- Putaran 2 (task 0): state, quest, feature, equip and scenario commands, through the real server code paths.
	if normalized:match("^!state%s*$") then
		printState(player)
		return
	end
	local questId = normalized:match("^!quest%s+selesai%s+(%S+)%s*$")
	if questId then
		print(`[DEV] quest {questId}: {QuestService.DevFinish(player, questId)}`)
		return
	end
	if normalized:match("^!skip%s+tutorial%s*$") then
		print(`[DEV] {TutorialService.DevFinishAll(player)}`)
		return
	end
	local startId = normalized:match("^!quest%s+mulai%s+(%S+)%s*$")
	if startId then
		print(`[DEV] quest {startId}: {QuestService.DevStart(player, startId)}`)
		return
	end
	local event, times = normalized:match("^!lapor%s+([%w_]+)%s*(%d*)%s*$")
	if event then
		QuestService.Report(player, event, tonumber(times) or 1)
		print(`[DEV] lapor {event} x{tonumber(times) or 1}`)
		return
	end
	local feature = normalized:match("^!buka%s+(%S+)%s*$")
	if feature then
		QuestService.DevOpenFeature(player, feature)
		print(`[DEV] fitur {feature} dibuka`)
		return
	end
	local scenario = normalized:match("^!skenario%s+(%S+)%s*$")
	if scenario then
		local lines = DevScenarios[scenario]
		if not lines then
			local names = {}
			for name in DevScenarios do
				table.insert(names, name)
			end
			table.sort(names)
			warn(`[DEV] skenario tidak dikenal: {scenario}. Ada: {table.concat(names, ", ")}`)
			return
		end
		for _, line in lines do
			onChatted(player, `!{line}`)
		end
		print(`[DEV] skenario {scenario} selesai`)
		return
	end
	local equipId = normalized:match("^!equip%s+(%S+)%s*$")
	if equipId then
		local data = DataService.Get(player)
		if not data then
			return
		end
		if Fishing.rods[equipId] then
			data.fishing.ownedRods[equipId] = true
			data.fishing.rod = equipId
		elseif Fishing.baitsById[equipId] and (data.inventory[equipId] or 0) > 0 then
			data.fishing.equippedBait = equipId
		else
			warn(`[DEV] !equip: {equipId} tidak dimiliki atau tidak dikenal`)
			return
		end
		InventoryService.Sync(player)
		return
	end

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
	-- Cuma 1 buff aktif (Bab 9.4): buff lain dimatikan.
	local buffId, buffSeconds = normalized:match("^!buff%s+(%a+)%s*(%d*)%s*$")
	if buffId then
		local seconds = tonumber(buffSeconds) or 60
		local now = Workspace:GetServerTimeNow()
		for _, def in Buffs.SLOTS do
			if def.id == buffId then
				player:SetAttribute(`Buff_{def.id}_Dur`, math.max(seconds, 1))
				player:SetAttribute(`Buff_{def.id}_End`, now + seconds)
				print(`[DevService] buff {def.id} for {seconds}s (display only)`)
			else
				player:SetAttribute(`Buff_{def.id}_End`, now)
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
	elseif command == "sp" and amount and amount > 0 then
		-- DEV ONLY (playtest skill P2-4): tambah SP langsung.
		local data = DataService.Get(player)
		if data then
			data.sp += math.floor(amount)
			InventoryService.Sync(player)
			print(`[DevService] sp = {data.sp}`)
		end
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
	elseif command == "cuaca" then
		local ok = WorldService.DevSetWeather(arg)
		print(`[DevService] Weather = {WorldService.CurrentWeather()} (ok={ok})`)
	elseif command == "rod" and Fishing.rods[arg] then
		local data = DataService.Get(player)
		if data then
			data.fishing.ownedRods[arg] = true
			data.fishing.rod = arg
			InventoryService.Sync(player)
		end
	elseif command == "tool" and arg == "gembor" then
		-- Stage 2 test: "!tool gembor" owns the Gembor Plastik without paying (Studio only path, same as !rod).
		local data = DataService.Get(player)
		if data then
			data.tools.gembor_plastik = true
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
				-- the tutorial's flags go back to 'not done': the cutscenes play again, and the unlock gates are closed again
				data.guide.saleCutscene = false
				data.guide.kolamUnlocked = false
				data.guide.decorUnlocked = false
				data.guide.fishCaught = false
				InventoryService.Sync(player)
			elseif arg == "fast" then
				data.guide.fastLeft = 6
				InventoryService.Sync(player)
			end
			print(`[DevService] guide={HttpService:JSONEncode(data.guide)}`)
		end
	elseif command == "pond" then
		FishService.DevFillPond(player)
	elseif command == "kakek" then
		-- DEV ONLY (sampai MQ4/Bundel P2-7 memberi unlock-nya): pulihkan Kolam Kakek untuk playtest.
		local data = DataService.Get(player)
		if data then
			data.pond.kakekUnlocked = true
			InventoryService.Sync(player)
			print(`[DevService] Kolam Kakek pulih untuk {player.Name} (dev unlock)`)
		end
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
	-- DevCmd: the same command text from the DEV panel or a test client (IsAllowed, and the sender is the player it is for)
	Net.On("DevCmd", function(sender: Player, text: any)
		if typeof(text) == "string" and DevService.IsAllowed(sender) then
			onChatted(sender, text)
		end
	end, { rate = 4, burst = 8 })
	local function hook(player: Player)
		if not DevService.IsAllowed(player) then
			return
		end
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
