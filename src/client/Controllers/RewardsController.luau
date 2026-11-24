--!strict
-- "Hadiah" panel (HUD "RewardButton"), GUI doc 6.1 (UI-3, split K-123). One sheet, four screens (tabs), nothing mixed:
--   Login Harian : Login Mingguan (Bab 15.1): 7 day cards and one Klaim button.
--   Peti Main    : playtime chests (Bab 15.2): a timeline with countdown and one Buka button.
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
local tab: string = "login" -- "login" | "chests" | "season" | "collection" (K-123)

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

-- Peti Main screen (K-123): a timeline of the chests (one cell each: done, next with a countdown, or waiting) and one large
-- Buka button for the next chest. Only the next chest in order can be opened (server: PlaytimeClaim decides).
local CHEST_COLUMNS = 5 -- one cell per chest in Config/Progression (5 peti; the owner's note said 4, see K-123)
local CHEST_CELL_HEIGHT = 118

-- "m:ss" for a number of seconds (the countdown on the next chest).
local function clock(total: number): string
	local t = math.max(0, math.ceil(total))
	return `{t // 60}:{string.format("%02d", t % 60)}`
end

local function chestCell(parent: Instance, order: number, index: number, state: string, played: number, need: number, reward: Progression.Reward)
	local cell = Instance.new("Frame")
	cell.Name = `Chest_{index}`
	cell.LayoutOrder = order
	cell.BackgroundColor3 = if state == "done" then UiKit.HEADER elseif state == "next" then UiKit.GOLD else UiKit.ROW
	cell.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UiKit.R_MD)
	corner.Parent = cell
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(222, 200, 154)
	stroke.Thickness = 1.5
	stroke.Parent = cell

	local function label(name: string, y: number, h: number, text: string, size: number)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(4, y)
		l.Size = UDim2.new(1, -8, 0, h)
		l.Font = UiKit.FONT
		l.TextSize = size
		l.TextWrapped = true
		l.TextColor3 = if state == "done" then UiKit.CREAM else UiKit.TEXT
		l.Text = text
		l.Parent = cell
	end
	label("Title", 6, 18, Locale.t("rewards.chest", { n = index }), UiKit.TEXT_BODY)
	label("Need", 26, 16, Locale.t("rewards.chest_need", { minutes = need // 60 }), UiKit.TEXT_CAPTION)
	label("Reward", 42, 16, rewardText(reward), UiKit.TEXT_CAPTION)

	-- Progress bar: played / need (full when done).
	local track = Instance.new("Frame")
	track.Name = "Progress"
	track.BackgroundColor3 = Color3.fromRGB(230, 214, 178)
	track.Position = UDim2.fromOffset(8, 66)
	track.Size = UDim2.new(1, -16, 0, 8)
	track.Parent = cell
	corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = UiKit.HEADER
	fill.Size = UDim2.fromScale(if state == "done" then 1 else math.clamp(played / need, 0, 1), 1)
	fill.Parent = track
	corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = fill

	local status = if state == "done" then Locale.t("rewards.chest_done")
		elseif state == "next" and played >= need then Locale.t("rewards.chest_ready")
		elseif state == "next" then Locale.t("rewards.chest_countdown", { t = clock(need - played) })
		else Locale.t("rewards.chest_later")
	label("Status", 80, 30, status, UiKit.TEXT_CAPTION)
end

local function renderChestScreen(nextOrder: () -> number, snapshot: any)
	UiKit.header(panel.list, Locale.t("rewards.chests"), nextOrder())
	local playtime = snapshot.playtime or { seconds = 0, claimed = 0 }
	local claimed = playtime.claimed or 0
	local played = seconds()
	local chests = Progression.PLAYTIME.CHESTS
	local grid = UiKit.grid(panel.list, nextOrder(), CHEST_COLUMNS, CHEST_CELL_HEIGHT)
	local nextIndex = claimed + 1
	for index, chest in chests do
		local state = if index <= claimed then "done" elseif index == nextIndex then "next" else "wait"
		chestCell(grid, index, index, state, played, chest.minutes * 60, chest.reward)
	end

	local next = chests[nextIndex]
	local ready = next ~= nil and played >= next.minutes * 60
	local text = if next == nil then Locale.t("rewards.chests_all")
		elseif ready then Locale.t("rewards.chest_open_n", { n = nextIndex })
		else Locale.t("rewards.chest_wait_btn", { t = clock(next.minutes * 60 - played) })
	local open = UiKit.button(panel.list, "ChestOpen", text, if ready then UiKit.BUTTON else UiKit.BUTTON_MUTED)
	open.LayoutOrder = nextOrder()
	open.Size = UDim2.new(1, -12, 0, UiKit.TOUCH_CTA) -- one large main action (GUI 3.4)
	open.Active = ready
	open.AutoButtonColor = ready
	open.Activated:Connect(function()
		if ready then
			Net.Send("PlaytimeClaim", nextIndex)
		end
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

-- Login Harian screen (K-123): 7 day cards (4 per row), the newest reached day highlighted in gold, and one large Klaim
-- button. The button claims the earliest reached day that is not claimed yet (LoginClaim; the server decides).
local LOGIN_COLUMNS = 4
local LOGIN_CELL_HEIGHT = 86

local function loginCard(parent: Instance, index: number, reward: Progression.Reward, state: string)
	local card = Instance.new("Frame")
	card.Name = `Login_{index}`
	card.LayoutOrder = index
	card.BackgroundColor3 = if state == "today" then UiKit.GOLD elseif state == "claimed" then UiKit.HEADER else UiKit.ROW
	card.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UiKit.R_MD)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = if state == "today" then UiKit.HEADER else Color3.fromRGB(222, 200, 154)
	stroke.Thickness = if state == "today" then 2.5 else 1.5
	stroke.Parent = card

	local function label(name: string, y: number, h: number, text: string, size: number)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(3, y)
		l.Size = UDim2.new(1, -6, 0, h)
		l.Font = UiKit.FONT
		l.TextSize = size
		l.TextWrapped = true
		l.TextColor3 = if state == "claimed" then UiKit.CREAM else UiKit.TEXT
		l.Text = text
		l.Parent = card
	end
	label("Day", 4, 18, Locale.t("rewards.login_day", { n = index }), UiKit.TEXT_BODY)
	label("Reward", 24, 36, rewardText(reward), UiKit.TEXT_CAPTION)
	local status = if state == "claimed" then Locale.t("rewards.claimed")
		elseif state == "today" then Locale.t("rewards.login_today")
		elseif state == "reached" then Locale.t("rewards.claim")
		else Locale.t("rewards.login_wait")
	label("Status", 62, 18, status, UiKit.TEXT_CAPTION)
end

local function renderLoginScreen(nextOrder: () -> number, rewards: any)
	UiKit.header(panel.list, Locale.t("rewards.login"), nextOrder())
	local days = rewards.login.days or 0
	local target: number? = nil
	local grid = UiKit.grid(panel.list, nextOrder(), LOGIN_COLUMNS, LOGIN_CELL_HEIGHT)
	for index, reward in Rewards.LOGIN do
		local claimed = rewards.login.claimed[tostring(index)] == true
		local reached = index <= days
		if reached and not claimed and target == nil then
			target = index
		end
		local state = if claimed then "claimed" elseif index == days then "today" elseif reached then "reached" else "wait"
		loginCard(grid, index, reward, state)
	end

	local text = if target then Locale.t("rewards.claim_day", { n = target })
		elseif days >= #Rewards.LOGIN then Locale.t("rewards.login_all")
		else Locale.t("rewards.login_none")
	local claim = UiKit.button(panel.list, "LoginClaim", text, if target then UiKit.BUTTON else UiKit.BUTTON_MUTED)
	claim.LayoutOrder = nextOrder()
	claim.Size = UDim2.new(1, -12, 0, UiKit.TOUCH_CTA) -- one large main action (GUI 3.4)
	claim.Active = target ~= nil
	claim.AutoButtonColor = target ~= nil
	claim.Activated:Connect(function()
		if target then
			Net.Send("LoginClaim", target)
		end
	end)
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
	-- K-123: four screens, nothing mixed: Login Harian, Peti Main, Musim, Koleksi.
	local defs = {}
	if rewards then
		table.insert(defs, { id = "login", text = Locale.t("rewards.tab_login") })
	end
	table.insert(defs, { id = "chests", text = Locale.t("rewards.tab_chests") })
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
	-- (the list above always has at least the Peti Main tab)

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

	if selected == "login" and rewards then
		renderLoginScreen(nextOrder, rewards)
	elseif selected == "season" and rewards then
		renderSeason(nextOrder, rewards)
	elseif selected == "collection" then
		renderCollection(nextOrder, snapshot, rewards)
	else
		renderChestScreen(nextOrder, snapshot)
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
