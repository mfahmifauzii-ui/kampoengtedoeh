--!strict
-- "Hadiah" panel (HUD "RewardButton"), all read from the server snapshot:
--   * Peti Main (Bab 15.2): five peti a day, opened in order by hand (PlaytimeClaim) once you have played long enough.
--   * Login Mingguan (Bab 15.1): 7 days per week (Config/Rewards.LOGIN), claimed by hand (LoginClaim).
--   * Peti Bunga (Bab 15.3): unopened peti count (snapshot.rewards.peti), opened by hand (PetiOpen).
--   * Title (Bab 15.4): all titles, got / not yet.
--   * Season (Bab 19): 30 days, F2P track and Premium track (bought with Bunga, SeasonPremium).
-- The red dot on the button means something is ready to claim or open.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local Rewards = require(ReplicatedStorage.Shared.Config.Rewards)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local RewardsController = {}

local panel: UiKit.Panel
local button: GuiButton? = nil

local function seconds(): number
	local value = player:GetAttribute("PlaytimeSec")
	if typeof(value) == "number" then
		return value
	end
	local snapshot = State.current :: any
	return if snapshot and snapshot.playtime then snapshot.playtime.seconds else 0
end

-- "+50 Koin, +1 Bunga" style text for a reward table.
local function rewardText(reward: Progression.Reward): string
	local parts: { string } = {}
	if reward.koin then
		table.insert(parts, Locale.t("reward.koin", { n = Locale.formatNumber(reward.koin) }))
	end
	if reward.bunga then
		table.insert(parts, Locale.t("reward.bunga", { n = reward.bunga }))
	end
	if reward.items then
		for itemId, amount in reward.items do
			table.insert(parts, `{amount} {Locale.t(`item.{itemId}`)}`)
		end
	end
	return table.concat(parts, ", ")
end

-- Peti Main ----------------------------------------------------------------------------------

-- One peti row. Only the next peti in order can be opened, and only once its minutes are played today.
local function renderChest(order: number, index: number, claimed: number, played: number)
	local chest = Progression.PLAYTIME.CHESTS[index]
	local need = chest.minutes * 60
	local title = Locale.t("rewards.chest", { n = index })
	local sub = `{Locale.t("rewards.chest_need", { minutes = chest.minutes })} · {rewardText(chest.reward)}`
	if index <= claimed then
		UiKit.row(panel.list, order, title, sub, Locale.t("rewards.chest_done"), false)
		return
	end
	local isNext = index == claimed + 1
	local remaining = math.max(0, math.ceil((need - played) / 60))
	local ready = isNext and remaining == 0
	local buttonText = if ready then Locale.t("rewards.chest_open") else Locale.t("rewards.chest_wait", { m = remaining })
	UiKit.row(panel.list, order, title, sub, buttonText, ready, function()
		Net.Send("PlaytimeClaim", index)
	end)
end

-- Login / Peti / Title / Season ---------------------------------------------------------------

local function loginReady(rewards: any): number
	local count = 0
	for index in Rewards.LOGIN do
		if index <= rewards.login.days and rewards.login.claimed[tostring(index)] ~= true then
			count += 1
		end
	end
	return count
end

local function renderLogin(nextOrder: () -> number, rewards: any)
	UiKit.header(panel.list, Locale.t("rewards.login"), nextOrder())
	for index, reward in Rewards.LOGIN do
		local claimed = rewards.login.claimed[tostring(index)] == true
		local ready = not claimed and index <= rewards.login.days
		local buttonText = if claimed then Locale.t("rewards.claimed") elseif ready then Locale.t("rewards.claim") else Locale.t("rewards.login_wait")
		UiKit.row(panel.list, nextOrder(), Locale.t("rewards.login_day", { n = index }), rewardText(reward), buttonText, ready, function()
			Net.Send("LoginClaim", index)
		end)
	end
end

local function renderPeti(nextOrder: () -> number, rewards: any)
	UiKit.header(panel.list, Locale.t("rewards.peti"), nextOrder())
	local peti = rewards.peti or 0
	local sub = Locale.t("rewards.peti_each", { n = Rewards.PETI_BUNGA })
	UiKit.row(panel.list, nextOrder(), if peti > 0 then Locale.t("rewards.peti_count", { n = peti }) else Locale.t("rewards.peti_none"), sub, Locale.t("rewards.peti_open"), peti > 0, function()
		Net.Send("PetiOpen")
	end)
end

local function renderTitles(nextOrder: () -> number, titles: any)
	UiKit.header(panel.list, Locale.t("rewards.titles"), nextOrder())
	for _, title in Rewards.TITLES do
		local got = titles and titles[title.id] == true
		local sub = if title.album then Locale.t("rewards.title_album", { n = title.album }) else Locale.t("rewards.title_quest")
		UiKit.row(panel.list, nextOrder(), Locale.t(`title.{title.id}`), sub, if got then Locale.t("rewards.title_got") else Locale.t("rewards.title_no"), false)
	end
end

local function renderSeason(nextOrder: () -> number, rewards: any)
	local season = rewards.season
	local today = rewards.seasonDay or 1
	UiKit.header(panel.list, Locale.t("rewards.season", { id = rewards.seasonId or "", day = today }), nextOrder())
	if season.premium ~= true then
		UiKit.row(panel.list, nextOrder(), Locale.t("rewards.season_premium"), Locale.t("rewards.season_premium_sub"), Locale.t("rewards.season_buy", { n = Rewards.SEASON.PREMIUM_PRICE }), true, function()
			Net.Send("SeasonPremium")
		end)
	end
	local tracks = { "f2p" } :: { Rewards.Track }
	if season.premium == true then
		table.insert(tracks, "premium")
	end
	for _, track in tracks do
		local claimedMap = if track == "premium" then season.premiumClaimed else season.f2p
		local tag = if track == "premium" then Locale.t("rewards.season_premium") else Locale.t("rewards.season_f2p")
		for day = 1, Rewards.SEASON.DAYS do
			local claimed = claimedMap[tostring(day)] == true
			local ready = not claimed and day <= today
			local buttonText = if claimed then Locale.t("rewards.claimed") elseif ready then Locale.t("rewards.claim") else Locale.t("rewards.login_wait")
			local title = `{Locale.t("rewards.season_day", { n = day })} · {tag}`
			UiKit.row(panel.list, nextOrder(), title, rewardText(Rewards.seasonReward(track, day)), buttonText, ready, function()
				Net.Send("SeasonClaim", track, day)
			end)
		end
	end
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
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	local playtime = snapshot.playtime or { seconds = 0, claimed = 0 }
	local played = seconds()
	UiKit.header(panel.list, Locale.t("rewards.chests"), nextOrder())
	for index in Progression.PLAYTIME.CHESTS do
		renderChest(nextOrder(), index, playtime.claimed or 0, played)
	end

	local rewards = snapshot.rewards
	if rewards then
		renderLogin(nextOrder, rewards)
		renderPeti(nextOrder, rewards)
		renderTitles(nextOrder, snapshot.titles)
		renderSeason(nextOrder, rewards)
	end

	panel.footerLabel.Text = Locale.t("rewards.played", { m = math.floor(played / 60) })
end

-- The red dot: something is ready (a peti, a login day, a peti of Bunga, a season day).
local function updateDot()
	if not button then
		return
	end
	local snapshot = State.current :: any
	local claimed = if snapshot and snapshot.playtime then snapshot.playtime.claimed or 0 else 0
	local next = Progression.PLAYTIME.CHESTS[claimed + 1]
	local ready = next ~= nil and seconds() >= next.minutes * 60
	local rewards = snapshot and snapshot.rewards
	if rewards then
		ready = ready or (rewards.peti or 0) > 0 or loginReady(rewards) > 0
	end
	UiKit.notifyDot(button :: GuiObject, if ready then 1 else 0)
end

function RewardsController.Init()
	panel = UiKit.panel("RewardsPanel", Locale.t("ui.rewards"), function()
		panel.gui.Enabled = false
	end)
end

function RewardsController.Start()
	State.Changed:Connect(function()
		render()
		updateDot()
	end)
	player:GetAttributeChangedSignal("PlaytimeSec"):Connect(function()
		render()
		updateDot()
	end)
	task.spawn(function()
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
		if not hud then
			return
		end
		local item = UiKit.menuItem(hud, "RewardButton", Locale.t("ui.rewards"), 8)
		if item then
			button = item
			item.Activated:Connect(function()
				panel.gui.Enabled = not panel.gui.Enabled
				render()
			end)
		end
		updateDot()
	end)
end

return RewardsController
