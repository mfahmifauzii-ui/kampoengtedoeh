--!strict
-- "Hadiah" panel (HUD "RewardButton"): two parts, both read from the server snapshot.
--   * Peti Main (Bab 15.2): three peti a day, opened in order by hand (PlaytimeClaim) once you have played long enough.
--     Kalender Harian was removed in v6.2 (T-28); Login Mingguan (Bab 15.1) will be the only login reward (Fase 6).
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
