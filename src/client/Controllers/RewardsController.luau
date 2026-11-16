--!strict
-- "Hadiah" panel (HUD "RewardButton"): two parts, both read from the server snapshot.
--   * Kalender Harian (R3 17.3): the 7 daily cards of Kunjungan Harian. The reward itself is automatic (granted on the
--     first join of each WIB day, ProgressionService); this only shows where you are in the cycle.
--   * Peti Main (R3 17.4): six peti a day, opened in order by hand (PlaytimeClaim) once you have played long enough.
-- The red dot on the button means a peti is ready to open.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progression = require(ReplicatedStorage.Shared.Config.Progression)
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

-- Calendar: seven cards, the first `last` ones done, `last` = today, `last + 1` = tomorrow.
local function renderCalendar(order: number, visitCount: number)
	local strip = Instance.new("Frame")
	strip.Name = "Calendar"
	strip.LayoutOrder = order
	strip.BackgroundTransparency = 1
	strip.Size = UDim2.new(1, 0, 0, 132)
	strip.Parent = panel.list

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = strip

	local last = if visitCount > 0 then (visitCount - 1) % #Progression.VISIT_REWARDS + 1 else 0
	local days = #Progression.VISIT_REWARDS
	for step, reward in Progression.VISIT_REWARDS do
		local today = step == last
		local tomorrow = step == (last % days) + 1
		local card = Instance.new("Frame")
		card.Name = `Day{step}`
		card.LayoutOrder = step
		card.Size = UDim2.new(1 / days, -4, 1, 0)
		card.BackgroundColor3 = if today then UiKit.BUTTON else UiKit.ROW
		card.Parent = strip
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = card
		local border = Instance.new("UIStroke")
		border.Color = if today then UiKit.HEADER_DARK else Color3.fromRGB(228, 208, 164)
		border.Thickness = 2
		border.Parent = card

		local day = Instance.new("TextLabel")
		day.BackgroundTransparency = 1
		day.Position = UDim2.fromOffset(2, 6)
		day.Size = UDim2.new(1, -4, 0, 20)
		day.Font = UiKit.FONT
		day.TextSize = 14
		day.TextColor3 = if today then UiKit.CREAM else UiKit.TEXT
		day.TextTruncate = Enum.TextTruncate.AtEnd
		day.Text = Locale.t("rewards.day", { n = step })
		day.Parent = card

		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Position = UDim2.fromOffset(4, 30)
		body.Size = UDim2.new(1, -8, 0, 50)
		body.Font = UiKit.FONT
		body.TextSize = 13
		body.TextWrapped = true
		body.TextColor3 = if today then UiKit.CREAM else UiKit.TEXT
		body.Text = rewardText(reward)
		body.Parent = card

		local status = Instance.new("TextLabel")
		status.BackgroundTransparency = 1
		status.Position = UDim2.new(0, 2, 1, -24)
		status.Size = UDim2.new(1, -4, 0, 20)
		status.Font = UiKit.FONT_BODY
		status.TextSize = 12
		status.TextColor3 = if today then UiKit.CREAM elseif step < last then UiKit.HEADER else Color3.fromRGB(128, 100, 66)
		status.Text = if today then Locale.t("rewards.today") elseif tomorrow then Locale.t("rewards.next") elseif step < last then Locale.t("rewards.got") else ""
		status.Parent = card
	end
end

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

	UiKit.header(panel.list, Locale.t("rewards.calendar"), nextOrder())
	renderCalendar(nextOrder(), snapshot.visits or 0)
	if snapshot.visitPending == true then
		-- Stage fix (user, 16 Nov): today's bonus waits for a tap here (only after T1).
		local claim = UiKit.button(panel.list, "VisitClaim", Locale.t("rewards.visit_claim"), UiKit.BUTTON)
		claim.LayoutOrder = nextOrder()
		claim.Size = UDim2.new(1, 0, 0, UiKit.TOUCH)
		claim.Activated:Connect(function()
			Net.Send("VisitClaim")
		end)
	end
	local note = Instance.new("TextLabel")
	note.Name = "Hint"
	note.BackgroundTransparency = 1
	note.LayoutOrder = nextOrder()
	note.Size = UDim2.new(1, 0, 0, 22)
	note.Font = UiKit.FONT_BODY
	note.TextSize = 13
	note.TextColor3 = Color3.fromRGB(128, 100, 66)
	note.TextWrapped = true
	note.Text = Locale.t("rewards.calendar_hint")
	note.Parent = panel.list

	local playtime = snapshot.playtime or { seconds = 0, claimed = 0 }
	local played = seconds()
	UiKit.header(panel.list, Locale.t("rewards.chests"), nextOrder())
	for index in Progression.PLAYTIME.CHESTS do
		renderChest(nextOrder(), index, playtime.claimed or 0, played)
	end

	panel.footerLabel.Text = Locale.t("rewards.played", { m = math.floor(played / 60) })
end

-- The red dot: the next peti is ready to open right now.
local function updateDot()
	if not button then
		return
	end
	local snapshot = State.current :: any
	local claimed = if snapshot and snapshot.playtime then snapshot.playtime.claimed or 0 else 0
	local next = Progression.PLAYTIME.CHESTS[claimed + 1]
	local ready = next ~= nil and seconds() >= next.minutes * 60
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
