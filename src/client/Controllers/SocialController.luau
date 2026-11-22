--!strict
-- Warga panel (HUD "SocialButton"): emotes, go home, Mampir to other players' plots.
-- Like button (ScreenGui "LikeUI" > TextButton "LikeButton"): shows only while you stand on
-- someone else's plot. Your designed UI can replace both; keep those names.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Skills = require(ReplicatedStorage.Shared.Config.Skills)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local FeatureClient = require(script.Parent.Parent.FeatureClient)
local UiKit = require(script.Parent.Parent.UiKit)

local CHECK_SECONDS = 0.2 -- B-2: the like button follows the player every 0.2 s
local LIKE_SIGN_RADIUS = 12 -- B-2: studs from the plot's sign ("Kebun <nama>", beside the gate). Not the whole plot, not the river.

local player = Players.LocalPlayer

local SocialController = {}

local panel: UiKit.Panel
local likeButton: TextButton
local currentOwnerId: number? = nil -- owner of the plot you're standing on (not you)
local galeriList: { { userId: number, name: string, likes: number } } = {}
local galeriWeek: string = ""

-- Satu banner emote di karakter mana pun (server memvalidasi + cooldown; playback jalan di
-- tiap client via SocialEmoteFx. Animate yang tidak punya PlayEmote: no-op, aman).
local function playEmoteOn(character: Model?, name: string?)
	if not character or not name then
		return
	end
	local animate = character:FindFirstChild("Animate")
	local playEmoteFn = animate and animate:FindFirstChild("PlayEmote")
	if playEmoteFn and playEmoteFn:IsA("BindableFunction") then
		task.spawn(function()
			pcall(playEmoteFn.Invoke, playEmoteFn, name)
		end)
	end
end

local function playEmote(name: string)
	playEmoteOn(player.Character, name)
end

local function findAnim(emoteId: string): string?
	for _, def in Social.EMOTES do
		if def.id == emoteId then
			return def.anim
		end
	end
	return nil
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

local function plotUnderMe(): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local plots = Workspace:FindFirstChild("Plots")
	if not root or not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		local ownerId = plot:GetAttribute("OwnerUserId")
		local sign = plot:FindFirstChild("Sign")
		if typeof(ownerId) == "number" and ownerId ~= player.UserId and sign then
			-- B-2: only next to the sign of someone else's plot (PlotService draws "Kebun <nama>" there).
			local signPos = sign:GetPivot().Position
			local flat = Vector3.new(root.Position.X - signPos.X, 0, root.Position.Z - signPos.Z)
			if flat.Magnitude <= LIKE_SIGN_RADIUS then
				return ownerId
			end
		end
	end
	return nil
end

-- Like 1x per lahan selamanya (Bab 12.7, P2-5).
local function likedEver(ownerId: number): boolean
	local snapshot = State.current :: any
	local social = snapshot and snapshot.social
	if not social or not social.likedEver then
		return false
	end
	return social.likedEver[tostring(ownerId)] == true
end

local function giftableIds(items: { [string]: number }): { string }
	local ids = {}
	for itemId, count in items do
		local info = Items.info(itemId)
		if info and count > 0 then
			local baseId = itemId:match("^(.+)@") or itemId
			local fish = FishConfig.byId[baseId]
			local legendary = fish ~= nil and fish.rarity == "L"
			if not legendary and (info.sellPrice or 0) <= Social.GIFT_MAX_VALUE then
				table.insert(ids, itemId)
			end
		end
	end
	return Items.sortIds(ids)
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
				playEmote(emote.anim) -- langsung (responsif) + server broadcast ke yang lain
			end
			Net.Send("SocialEmote", emote.id)
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

	-- Bantu + Hadiah di lahan yang sedang dikunjungi (Bab 12.2/12.3, P2-5).
	local here = plotUnderMe()
	local snap = State.current :: any
	if here then
		UiKit.header(panel.list, Locale.t("bantu.title"), nextOrder())
		local helpGiven = (snap and snap.social and snap.social.helpGiven) or {}
		local doneCount = 0
		for _ in (helpGiven.plots or {}) do
			doneCount += 1
		end
		local skills = (snap and snap.skills) or {}
		local maxPlots = Social.BANTU_MAX_DAY + Skills.tetanggaBonus(skills.tetangga_baik or 0)
		UiKit.row(panel.list, nextOrder(), Locale.t("bantu.siram"), `{doneCount}/{maxPlots}`, Locale.t("bantu.siram"), true, function()
			Net.Send("SocialBantu", here, "siram")
		end)
		UiKit.row(panel.list, nextOrder(), Locale.t("bantu.panen"), `{doneCount}/{maxPlots}`, Locale.t("bantu.panen"), true, function()
			Net.Send("SocialBantu", here, "panen")
		end)

		UiKit.header(panel.list, Locale.t("gift.title"), nextOrder())
		local items = (snap and snap.items) or {}
		for _, itemId in giftableIds(items) do
			local info = Items.info(itemId)
			UiKit.row(panel.list, nextOrder(), if info then Items.displayName(info) else itemId, `x{items[itemId]}`, Locale.t("gift.send"), true, function()
				Net.Send("SocialGift", here, itemId)
			end)
		end
	end

	-- Galeri Kampung: top 5 like mingguan (global). Pencet = visit (Bab 8.7/12.7, P2-5).
	UiKit.header(panel.list, Locale.t("social.galeri"), nextOrder())
	UiKit.row(panel.list, nextOrder(), Locale.t("social.galeri_show"), galeriWeek, Locale.t("social.galeri_show"), true, function()
		Net.Send("GaleriGet")
	end)
	for _, entry in galeriList do
		UiKit.row(panel.list, nextOrder(), entry.name, Locale.t("social.likes", { n = entry.likes }), Locale.t("social.visit"), true, function()
			Net.Send("SocialVisit", entry.userId)
			panel.gui.Enabled = false
		end)
	end
	if #galeriList == 0 then
		UiKit.row(panel.list, nextOrder(), Locale.t("social.galeri_empty"))
	end
end

-- Like button ------------------------------------------------------------------------

local function refreshLike()
	currentOwnerId = plotUnderMe()
	local gui = likeButton:FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
	-- B-2: hidden while fishing (the "Tarik!" prompt owns that spot), while any panel is open, and while a dialog runs.
	local busy = player:GetAttribute("FishingActive") == true or UiKit.anyPanelOpen() or player:GetAttribute("KTBeatBusy") == true
	gui.Enabled = currentOwnerId ~= nil and not busy
	if currentOwnerId then
		local liked = likedEver(currentOwnerId)
		likeButton.Text = Locale.t(if liked then "social.liked" else "social.like")
		likeButton.AutoButtonColor = not liked
		likeButton.BackgroundColor3 = if liked then UiKit.BUTTON_MUTED else UiKit.BUTTON
		likeButton:SetAttribute("Enabled", not liked)
	end
end

local function buildLikeUi()
	local gui = Instance.new("ScreenGui")
	gui.Name = "LikeUI"
	gui.DisplayOrder = UiKit.LAYER.ACTION -- B-2: GUI doc Bab 4.5, layer Aksi (10)
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
	Net.Listen("SocialEmoteFx", function(userId: any, emoteId: any)
		if typeof(userId) ~= "number" or typeof(emoteId) ~= "string" then
			return
		end
		local who = Players:GetPlayerByUserId(userId)
		playEmoteOn(who and who.Character or nil, findAnim(emoteId))
	end)
	Net.Listen("GaleriBoard", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.list) == "table" then
			galeriList = payload.list
			galeriWeek = if typeof(payload.week) == "string" then payload.week else ""
			if panel.gui.Enabled then
				render()
			end
		end
	end)
	State.Changed:Connect(function()
		render()
		refreshLike()
	end)
	Players.PlayerAdded:Connect(render)
	Players.PlayerRemoving:Connect(function()
		task.defer(render)
	end)
	FeatureClient.GateHud("SocialButton", "bantu") -- Q-2: hidden until the bantu feature is open
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
