--!strict
-- Assigns each player one village plot, spawns them there, and frees it on leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlotsConfig = require(ReplicatedStorage.Shared.Config.Plots)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local DataService = require(script.Parent.DataService)
local MapService = require(script.Parent.MapService)

local PlotService = {}
PlotService.Assigned = Signal.new() -- (player, plot: Model)
PlotService.Released = Signal.new() -- (player, plot: Model)

local plots: { Model } = {}
local ownerOf: { [Model]: Player } = {}
local plotOf: { [Player]: Model } = {}

local function buildPlaceholderPlots(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Plots"

	for i = 1, PlotsConfig.COUNT do
		local slot = PlotsConfig.LAYOUT[i]
		local x = slot.x * PlotsConfig.DISTANCE
		local z = slot.z * PlotsConfig.DISTANCE
		-- Local +Z (spawn side) faces the map center (the bridge town).
		local rotation = CFrame.Angles(0, slot.yaw, 0)

		local model = Instance.new("Model")
		model.Name = `Plot{i}`

		local origin = Instance.new("Part")
		origin.Name = "Origin"
		origin.Anchored = true
		origin.Size = Vector3.new(PlotsConfig.SIZE, 1, PlotsConfig.SIZE)
		-- Origin is only the plot's coordinate anchor (invisible): the land itself is terrain, painted by MapService.
		-- Its top surface is the terrain top (y = 0).
		origin.CFrame = CFrame.new(x, -origin.Size.Y / 2, z) * rotation
		origin.Transparency = 1
		origin.CanCollide = false
		origin.CanQuery = false
		origin.CanTouch = false
		origin.Parent = model
		model.PrimaryPart = origin

		local sign = Instance.new("Part")
		sign.Name = "Sign"
		sign.Anchored = true
		sign.CanCollide = false
		sign.Transparency = 1
		sign.Size = Vector3.one
		sign.CFrame = origin.CFrame * CFrame.new(0, 6, PlotsConfig.FRONT_Z - 4) -- just inside the front edge of the land
		sign.Parent = model

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(200, 40)
		billboard.MaxDistance = 120
		billboard.Parent = sign

		local label = Instance.new("TextLabel")
		label.Name = "OwnerLabel"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(245, 236, 214)
		label.TextStrokeTransparency = 0.6
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 20
		label.Text = ""
		label.Parent = billboard

		MapService.AddHouse(model)
		model.Parent = folder
	end

	folder.Parent = Workspace
	return folder
end

local function setOwnerLabel(plot: Model, text: string)
	local label = plot:FindFirstChild("OwnerLabel", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function spawnAtPlot(player: Player)
	local plot = plotOf[player]
	local character = player.Character
	if not plot or not character or not plot.PrimaryPart then
		return
	end
	local origin = plot.PrimaryPart :: BasePart
	character:PivotTo(origin.CFrame * CFrame.new(PlotsConfig.SPAWN_OFFSET))
end

local function assign(player: Player)
	for _, plot in plots do
		if ownerOf[plot] == nil then
			ownerOf[plot] = player
			plotOf[player] = plot
			plot:SetAttribute("OwnerUserId", player.UserId)
			player:SetAttribute("PlotName", plot.Name)
			setOwnerLabel(plot, Locale.t("plot.owner", { name = player.DisplayName }))
			spawnAtPlot(player)
			PlotService.Assigned:Fire(player, plot)
			return
		end
	end
	warn(`[PlotService] No free plot for {player.Name}. Is Max Players > {#plots}?`)
end

local function release(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	PlotService.Released:Fire(player, plot)
	plotOf[player] = nil
	ownerOf[plot] = nil
	plot:SetAttribute("OwnerUserId", nil)
	plot:SetAttribute("Likes", nil)
	setOwnerLabel(plot, "")
end

function PlotService.GetPlot(player: Player): Model?
	return plotOf[player]
end

function PlotService.GetOwner(plot: Model): Player?
	return ownerOf[plot]
end

-- Likes shown on the sign + "Likes" attribute on the plot model (for your designed UI).
function PlotService.SetLikes(player: Player, likes: number)
	local plot = plotOf[player]
	if plot then
		plot:SetAttribute("Likes", likes)
		setOwnerLabel(plot, Locale.t("plot.owner_likes", { name = player.DisplayName, likes = likes }))
	end
end

function PlotService.Init()
	local folder = Workspace:FindFirstChild("Plots") or buildPlaceholderPlots()
	for i = 1, PlotsConfig.COUNT do
		local plot = folder:FindFirstChild(`Plot{i}`)
		assert(plot and plot:IsA("Model") and plot.PrimaryPart, `[PlotService] Plot{i} missing or has no PrimaryPart`)
		table.insert(plots, plot)
	end

	DataService.Loaded:Connect(assign)
end

function PlotService.Start()
	Players.PlayerRemoving:Connect(release)

	local function onCharacter(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 5)
			task.defer(spawnAtPlot, player)
		end)
	end
	Players.PlayerAdded:Connect(onCharacter)
	for _, player in Players:GetPlayers() do
		onCharacter(player)
	end
end

return PlotService
