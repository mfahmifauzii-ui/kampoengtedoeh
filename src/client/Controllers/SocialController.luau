--!strict
-- Warga panel (HUD "SocialButton"): emotes, go home, Mampir to other players' plots.
-- Like button (ScreenGui "LikeUI" > TextButton "LikeButton"): shows only while you stand on
-- someone else's plot. Your designed UI can replace both; keep those names.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local CHECK_SECONDS = 0.5

local player = Players.LocalPlayer

local SocialController = {}

local panel: UiKit.Panel
local likeButton: TextButton
local currentOwnerId: number? = nil -- owner of the plot you're standing on (not you)

local function playEmote(name: string)
	local character = player.Character
	local animate = character and character:FindFirstChild("Animate")
	local playEmoteFn = animate and animate:FindFirstChild("PlayEmote")
	if playEmoteFn and playEmoteFn:IsA("BindableFunction") then
		task.spawn(function()
			pcall(playEmoteFn.Invoke, playEmoteFn, name)
		end)
	end
end

local function plotLikes(userId: number): number
	local plots = Workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in plots:GetChildren() do
			if plot:GetAttribute("OwnerUserId") == userId then
				local likes = plot:GetAttribute("Likes")
				return if typeof(likes) == "number" then likes else 0
			end
		end
	end
	return 0
end

local function render()
	if not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	-- Emotes: one row of small buttons.
	UiKit.header(panel.list, Locale.t("social.emotes"), nextOrder())
	local emoteRow = Instance.new("Frame")
	emoteRow.Name = "Emotes"
	emoteRow.LayoutOrder = nextOrder()
	emoteRow.BackgroundTransparency = 1
	emoteRow.Size = UDim2.new(1, -6, 0, 40)
	emoteRow.Parent = panel.list
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.Parent = emoteRow
	for _, emote in Social.EMOTES do
		local button = UiKit.button(emoteRow, emote.id, Locale.t(`emote.{emote.id}`), UiKit.ROW)
		button.Size = UDim2.new(1 / #Social.EMOTES, -6, 1, 0)
		button.Activated:Connect(function()
			if emote.anim then
				playEmote(emote.anim)
			end
		end)
	end

	UiKit.row(panel.list, nextOrder(), Locale.t("social.home"), Locale.t("social.home_sub"), Locale.t("social.go_home"), true, function()
		Net.Send("SocialVisit", player.UserId)
		panel.gui.Enabled = false
	end)

	UiKit.header(panel.list, Locale.t("social.players"), nextOrder())
	local others = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("PlotName") then
			others += 1
			UiKit.row(panel.list, nextOrder(), other.DisplayName, Locale.t("social.likes", { n = plotLikes(other.UserId) }),
				Locale.t("social.visit"), true, function()
					Net.Send("SocialVisit", other.UserId)
					panel.gui.Enabled = false
				end)
		end
	end
	if others == 0 then
		UiKit.row(panel.list, nextOrder(), Locale.t("social.alone"))
	end
end

-- Like button ------------------------------------------------------------------------

local function likedToday(ownerId: number): boolean
	local snapshot = State.current :: any
	local social = snapshot and snapshot.social
	if not social or social.likedDay ~= TimeKeys.day(math.floor(Workspace:GetServerTimeNow())) then
		return false
	end
	return social.likedToday[tostring(ownerId)] == true
end

local function plotUnderMe(): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local plots = Workspace:FindFirstChild("Plots")
	if not root or not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		local ownerId = plot:GetAttribute("OwnerUserId")
		local origin = plot:IsA("Model") and plot.PrimaryPart
		if typeof(ownerId) == "number" and ownerId ~= player.UserId and origin then
			local localPos = origin.CFrame:PointToObjectSpace(root.Position)
			if Land.contains(localPos.X, localPos.Z, Social.LIKE_MARGIN - 1) then -- a bit stricter than the server
				return ownerId
			end
		end
	end
	return nil
end

local function refreshLike()
	currentOwnerId = plotUnderMe()
	local gui = likeButton:FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
	gui.Enabled = currentOwnerId ~= nil
	if currentOwnerId then
		local liked = likedToday(currentOwnerId)
		likeButton.Text = Locale.t(if liked then "social.liked" else "social.like")
		likeButton.AutoButtonColor = not liked
		likeButton.BackgroundColor3 = if liked then UiKit.BUTTON_MUTED else UiKit.BUTTON
		likeButton:SetAttribute("Enabled", not liked)
	end
end

local function buildLikeUi()
	local gui = Instance.new("ScreenGui")
	gui.Name = "LikeUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	likeButton = UiKit.button(gui, "LikeButton", Locale.t("social.like"))
	likeButton.AnchorPoint = Vector2.new(0.5, 1)
	likeButton.Position = UDim2.new(0.5, 0, 1, -140)
	likeButton.Size = UDim2.fromOffset(220, 44)
	likeButton.TextSize = 17
	likeButton.Activated:Connect(function()
		if currentOwnerId and likeButton:GetAttribute("Enabled") == true then
			Net.Send("SocialLike", currentOwnerId)
		end
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
end

function SocialController.Init()
	panel = UiKit.panel("SocialPanel", Locale.t("ui.social"), function()
		panel.gui.Enabled = false
	end)
	buildLikeUi()
end

function SocialController.Start()
	State.Changed:Connect(function()
		render()
		refreshLike()
	end)
	Players.PlayerAdded:Connect(render)
	Players.PlayerRemoving:Connect(function()
		task.defer(render)
	end)
	task.spawn(UiKit.hudButton, "SocialButton", Locale.t("ui.social"), 7, function()
		panel.gui.Enabled = not panel.gui.Enabled
		render()
	end)
	while true do
		task.wait(CHECK_SECONDS)
		refreshLike()
	end
end

return SocialController
