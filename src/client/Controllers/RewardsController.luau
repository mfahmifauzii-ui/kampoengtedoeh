--!strict
-- "Hadiah" panel (HUD "RewardButton"), GUI doc 6.1 (UI-3). One sheet, three tabs:
--   Harian  : Peti Main (playtime chests, Bab 15.2) and Login Mingguan (Bab 15.1), as rows.
--   Musim   : Season Pass (Bab 19) as two horizontal tracks: Gratis (F2P) and Premium. Premium is locked while
--             Rewards.SEASON.PREMIUM_OPEN is false: shown as locked, no purchase.
--   Koleksi : Peti Bunga (Bab 15.3), Title (Bab 15.4), and the Album category / milestone claims (BookController).
-- Presentation only. Every claim is the same Net.Send as before (PlaytimeClaim, LoginClaim, PetiOpen, SeasonClaim,
-- SeasonPremium, BookClaim); the server decides what is ready and grants it.
-- The panel is built when it opens and destroyed when it closes (UiKit.closePanel): no instance stays behind.
-- The HUD button is the only entry.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local Rewards = require(ReplicatedStorage.Shared.Config.Rewards)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)
local BookController = require(script.Parent.BookController)

local player = Players.LocalPlayer

local RewardsController = {}

local panel: any = nil -- the open panel (UiKit.panel), nil while closed
local button: GuiButton? = nil
local tab: string = "daily" -- "daily" | "season" | "collection"

-- Season track layout (GUI doc 6.1): node 64 x 64; a milestone day (a reward with Bunga) is larger.
-- The doc does not give the milestone size; NODE_MILESTONE is a layout choice (Lampiran D #34).
local NODE = 64
local NODE_MILESTONE = 80
local NODE_GAP = 8 -- GUI doc 4.3 spacing step
local TRACK_HEIGHT = NODE_MILESTONE + 8

-- Scroll position of each track, so a re-render keeps where the player scrolled.
local scrollMemory: { [string]: number } = {}

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

-- Harian: Peti Main ---------------------------------------------------------------------------

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

-- Harian: Login Mingguan ----------------------------------------------------------------------

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

-- Koleksi: Peti Bunga, Title ------------------------------------------------------------------

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
		local sub = Locale.t("rewards.title_how")
		UiKit.row(panel.list, nextOrder(), Locale.t(`title.{title.id}`), sub, if got then Locale.t("rewards.title_got") else Locale.t("rewards.title_no"), false)
	end
end

-- Musim: Season Pass tracks -------------------------------------------------------------------

-- One day node: a 64 px square (larger on a milestone day). Ready = gold and tappable (SeasonClaim); claimed = green with
-- "Sudah"; not reached yet or locked = grey, no tap.
local function seasonNode(parent: Instance, track: Rewards.Track, day: number, today: number, claimed: boolean, locked: boolean)
	local reward = Rewards.seasonReward(track, day)
	local size = if reward.bunga ~= nil then NODE_MILESTONE else NODE
	local ready = not locked and not claimed and day <= today

	local node = Instance.new("TextButton")
	node.Name = `{track}_{day}`
	node.LayoutOrder = day
	node.Size = UDim2.fromOffset(size, size)
	node.Text = ""
	node.AutoButtonColor = false
	node.Active = ready
	node.BackgroundColor3 = if claimed then UiKit.HEADER elseif ready then UiKit.GOLD elseif locked then UiKit.LOCKED else UiKit.ROW
	node.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, UiKit.R_MD)
	round.Parent = node

	local dayLabel = Instance.new("TextLabel")
	dayLabel.Name = "Day"
	dayLabel.BackgroundTransparency = 1
	dayLabel.Position = UDim2.fromScale(0, 0.06)
	dayLabel.Size = UDim2.fromScale(1, 0.4)
	dayLabel.Font = UiKit.FONT
	dayLabel.TextSize = UiKit.TEXT_BODY
	dayLabel.TextColor3 = if claimed then UiKit.CREAM else UiKit.TEXT
	dayLabel.Text = Locale.t("rewards.season_day", { n = day })
	dayLabel.Parent = node

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name = "Reward"
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Size = UDim2.new(1, -4, 0.52, -4)
	rewardLabel.Position = UDim2.new(0, 2, 0.45, 0)
	rewardLabel.Font = UiKit.FONT
	rewardLabel.TextSize = UiKit.TEXT_CAPTION
	rewardLabel.TextWrapped = true
	rewardLabel.TextColor3 = if claimed then UiKit.CREAM else UiKit.TEXT
	rewardLabel.Text = if claimed then Locale.t("rewards.claimed") else rewardText(reward)
	rewardLabel.Parent = node

	if ready then
		node.Activated:Connect(function()
			Net.Send("SeasonClaim", track, day)
		end)
	end
end

-- One horizontal track (Gratis or Premium): a header band, then a scrolling row of day nodes. The track opens scrolled to
-- today (or to where the player left it).
local function seasonTrack(nextOrder: () -> number, track: Rewards.Track, title: string, locked: boolean, claimedMap: any, today: number)
	UiKit.header(panel.list, title, nextOrder())

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = `Track_{track}`
	scroll.LayoutOrder = nextOrder()
	scroll.Size = UDim2.new(1, 0, 0, TRACK_HEIGHT)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = panel.list

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, NODE_GAP)
	layout.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, NODE_GAP)
	pad.PaddingRight = UDim.new(0, NODE_GAP)
	pad.Parent = scroll

	for day = 1, Rewards.SEASON.DAYS do
		seasonNode(scroll, track, day, today, claimedMap[tostring(day)] == true, locked)
	end

	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		scrollMemory[track] = scroll.CanvasPosition.X
	end)
	task.defer(function()
		if not scroll.Parent then
			return
		end
		local x = scrollMemory[track]
		if x == nil then
			x = math.max(0, (today - 1) * (NODE + NODE_GAP) - scroll.AbsoluteSize.X / 2 + NODE / 2)
		end
		scroll.CanvasPosition = Vector2.new(x, 0)
	end)
end

local function renderSeason(nextOrder: () -> number, rewards: any)
	local season = rewards.season
	local today = rewards.seasonDay or 1
	UiKit.header(panel.list, Locale.t("rewards.season", { id = rewards.seasonId or "", day = today }), nextOrder())
	seasonTrack(nextOrder, "f2p", Locale.t("rewards.season_f2p"), false, season.f2p, today)

	-- Premium: locked while the track is not open (PREMIUM_OPEN). The purchase row shows only when it is open.
	local open = Rewards.SEASON.PREMIUM_OPEN == true
	local owned = season.premium == true
	if owned then
		UiKit.row(panel.list, nextOrder(), Locale.t("rewards.season_premium"), Locale.t("rewards.season_premium_sub"), Locale.t("rewards.season_on"), false)
	elseif open then
		UiKit.row(panel.list, nextOrder(), Locale.t("rewards.season_premium"), Locale.t("rewards.season_premium_sub"), Locale.t("rewards.season_buy", { n = Rewards.SEASON.PREMIUM_PRICE }), true, function()
			Net.Send("SeasonPremium")
		end)
	else
		UiKit.row(panel.list, nextOrder(), Locale.t("rewards.season_premium"), Locale.t("rewards.season_premium_sub"), Locale.t("rewards.season_soon"), false)
	end
	seasonTrack(nextOrder, "premium", Locale.t("rewards.season_premium"), not owned or not open, season.premiumClaimed, today)
end

-- Panel -----------------------------------------------------------------------------------------

local function renderDaily(nextOrder: () -> number, snapshot: any, rewards: any)
	local playtime = snapshot.playtime or { seconds = 0, claimed = 0 }
	UiKit.header(panel.list, Locale.t("rewards.chests"), nextOrder())
	for index in Progression.PLAYTIME.CHESTS do
		renderChest(nextOrder(), index, playtime.claimed or 0, seconds())
	end
	if rewards then
		renderLogin(nextOrder, rewards)
	end
end

local function renderCollection(nextOrder: () -> number, snapshot: any, rewards: any)
	if rewards then
		renderPeti(nextOrder, rewards)
	end
	renderTitles(nextOrder, snapshot.titles)
	if snapshot.book then
		UiKit.header(panel.list, Locale.t("rewards.album_milestone"), nextOrder())
		BookController.RenderClaims(panel.list, nextOrder, snapshot.book)
	end
end

local function render()
	if not panel then
		return
	end
	UiKit.clear(panel.list)
	local snapshot = State.current :: any
	if not snapshot then
		return
	end
	local rewards = snapshot.rewards

	-- Tabs: a tab with nothing to show is not drawn (Musim needs the season data from the server).
	local defs = { { id = "daily", text = Locale.t("rewards.tab_daily") } }
	if rewards then
		table.insert(defs, { id = "season", text = Locale.t("rewards.tab_season") })
	end
	table.insert(defs, { id = "collection", text = Locale.t("rewards.tab_collection") })
	local selected = tab
	local known = false
	for _, def in defs do
		if def.id == selected then
			known = true
		end
	end
	if not known then
		selected = defs[1].id
		tab = selected
	end

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local bar = UiKit.tabs(panel.list, defs, selected, function(id: string)
		tab = id
		render()
	end)
	bar.frame.LayoutOrder = nextOrder()

	if selected == "season" and rewards then
		renderSeason(nextOrder, rewards)
	elseif selected == "collection" then
		renderCollection(nextOrder, snapshot, rewards)
	else
		renderDaily(nextOrder, snapshot, rewards)
	end

	panel.footerLabel.Text = Locale.t("rewards.played", { m = math.floor(seconds() / 60) })
end

local function closePanel()
	if panel then
		local gui = panel.gui
		panel = nil
		UiKit.closePanel(gui)
	end
end

local function openPanel()
	if panel then
		return
	end
	panel = UiKit.panel("RewardsPanel", Locale.t("ui.rewards"), closePanel)
	panel.gui.Enabled = true
	render()
end

-- The red dot on the button: something is ready (a peti, a login day, a peti of Bunga).
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
				if panel then
					closePanel()
				else
					openPanel()
				end
			end)
		end
		updateDot()
	end)
end

return RewardsController
