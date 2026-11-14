--!strict
-- Mampir (teleport to a plot in this server) and Suka (like a plot once per WIB day).
-- Visitors can look but never touch: farm/decor/pond actions always use the actor's OWN plot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotsConfig = require(ReplicatedStorage.Shared.Config.Plots)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local FishService = require(script.Parent.FishService)

local SocialService = {}

local lastVisit: { [Player]: number } = {}

local function playerById(userId: any): Player?
	if typeof(userId) ~= "number" or userId % 1 ~= 0 then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isOnPlot(player: Player, plot: Model): boolean
	local root = rootOf(player)
	local origin = plot.PrimaryPart
	if not root or not origin then
		return false
	end
	local localPos = origin.CFrame:PointToObjectSpace(root.Position)
	return Land.contains(localPos.X, localPos.Z, Social.LIKE_MARGIN)
end

local function onVisit(player: Player, ownerUserId: any)
	local owner = playerById(ownerUserId)
	local plot = owner and PlotService.GetPlot(owner)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not owner or not plot or not plot.PrimaryPart or not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()
	if now - (lastVisit[player] or 0) < Social.VISIT_COOLDOWN then
		return
	end
	lastVisit[player] = now

	FishService.Cancel(player)
	humanoid.Sit = false
	local offset = if owner == player then PlotsConfig.SPAWN_OFFSET else Social.VISIT_OFFSET
	-- Face the plot center from the visit spot.
	local origin = (plot.PrimaryPart :: BasePart).CFrame
	local spot = origin * CFrame.new(offset)
	local lookAt = Vector3.new(origin.Position.X, spot.Position.Y, origin.Position.Z)
	character:PivotTo(if owner == player then spot else CFrame.lookAt(spot.Position, lookAt))
	if owner ~= player then
		Net.Fire("Notify", player, "social.visiting", { name = owner.DisplayName })
	end
end

local function grantMilestones(owner: Player)
	local data = DataService.Get(owner)
	if not data then
		return
	end
	for _, milestone in Social.LIKE_MILESTONES do
		local key = tostring(milestone.likes)
		if data.social.likes >= milestone.likes and not data.social.milestones[key] then
			data.social.milestones[key] = true
			ProgressionService.Grant(owner, milestone.reward, "social_likes")
			Net.Fire("Notify", owner, "social.milestone", { n = milestone.likes })
		end
	end
end

local function onLike(player: Player, ownerUserId: any)
	local owner = playerById(ownerUserId)
	local plot = owner and PlotService.GetPlot(owner)
	local data = DataService.Get(player)
	local ownerData = owner and DataService.Get(owner)
	if not owner or owner == player or not plot or not data or not ownerData then
		return
	end
	if not isOnPlot(player, plot) then
		Net.Fire("Notify", player, "social.too_far")
		return
	end

	local today = TimeKeys.day()
	if data.social.likedDay ~= today then
		data.social.likedDay = today
		data.social.likedToday = {}
	end
	local key = tostring(owner.UserId)
	if data.social.likedToday[key] then
		return -- already liked today; the button is hidden client-side anyway
	end
	data.social.likedToday[key] = true
	ownerData.social.likes += 1

	PlotService.SetLikes(owner, ownerData.social.likes)
	Net.Fire("Notify", player, "social.like_sent", { name = owner.DisplayName })
	Net.Fire("Notify", owner, "social.got_like", { name = player.DisplayName })
	grantMilestones(owner)
	InventoryService.Sync(player)
	InventoryService.Sync(owner)
end

function SocialService.Init()
	PlotService.Assigned:Connect(function(player: Player)
		local data = DataService.Get(player)
		if data then
			PlotService.SetLikes(player, data.social.likes)
			grantMilestones(player) -- catches up if a threshold changed in config
		end
	end)
end

function SocialService.Start()
	Net.On("SocialVisit", onVisit, { rate = 1, burst = 2 })
	Net.On("SocialLike", onLike, { rate = 1, burst = 3 })
	Players.PlayerRemoving:Connect(function(player)
		lastVisit[player] = nil
	end)
end

return SocialService
