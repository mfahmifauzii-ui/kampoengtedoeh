--!strict
-- Assigns each player one village plot, spawns them there, and frees it on leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PlotsConfig = require(ReplicatedStorage.Shared.Config.Plots)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local DataService = require(script.Parent.DataService)

local PlotService = {}
PlotService.Assigned = Signal.new() -- (player, plot: Model)
PlotService.Released = Signal.new() -- (player, plot: Model)

local plots: { Model } = {}
local ownerOf: { [Model]: Player } = {}
local plotOf: { [Player]: Model } = {}

-- The gate sign ("Kebun [Nama]") stands this far along the plot's local X: negative = to the left of the gate opening for a
-- player who stands on the road facing the land (the gate is 32 studs wide, so 22 is just outside it).
local SIGN_X = -22

local function buildPlaceholderPlots(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Plots"

	for i = 1, PlotsConfig.COUNT do
		local slot = PlotsConfig.LAYOUT[i]
		local x = slot.x
		local z = slot.z
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

		-- The gate's sign: a wooden plate beside the gate (outside the opening: the gate is 32 studs wide, so the plate sits
		-- at x = 22 on the road side), facing the road. It shows "Kebun [Nama]" or "Lahan Kosong". No floating text.
		local plangTemplate = ServerStorage:FindFirstChild("MapModels") and ServerStorage.MapModels:FindFirstChild("PlangKebun")
		local plate: BasePart
		local fromTemplate = false
		if plangTemplate and plangTemplate:IsA("Model") then
			fromTemplate = true
			-- Imported plang (5 x 4.5 studs, empty board). The owner name is drawn on its board (papan_kayu).
			local plang = plangTemplate:Clone()
			plang.Name = "Sign"
			for _, d in plang:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
				end
			end
			-- On the fence line, standing on the ground (origin top = y 0), to the LEFT of the gate opening (seen from the
			-- road, facing the land): SIGN_X studs along the plot's local X. It used to stand in the middle of the gate,
			-- right in front of a player who joins or respawns, and filled the camera of the intro conversation.
			local pivotCf = origin.CFrame * CFrame.new(SIGN_X, 0, PlotsConfig.FRONT_Z + 0.3)
			plang:PivotTo(pivotCf)
			local bbox, size = plang:GetBoundingBox()
			local rel = pivotCf:PointToObjectSpace(bbox.Position)
			local delta = pivotCf:VectorToWorldSpace(Vector3.new(-rel.X, 0, -rel.Z)) + Vector3.new(0, size.Y / 2 - bbox.Position.Y, 0)
			plang:PivotTo(plang:GetPivot() + delta)
			plang.Parent = model
			-- The main board is the biggest papan_kayu (the small status board uses the same slot).
			local best: BasePart? = nil
			for _, d in plang:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "papan_kayu" and (best == nil or d.Size.X * d.Size.Y > best.Size.X * best.Size.Y) then
					best = d
				end
			end
			plate = best :: BasePart
		else
			plate = Instance.new("Part")
			plate.Name = "Sign"
			plate.Anchored = true
			plate.CanCollide = false
			plate.CanQuery = false
			plate.CanTouch = false
			plate.Material = Enum.Material.Wood
			plate.Color = Color3.fromRGB(146, 104, 66)
			plate.Size = Vector3.new(9, 4.2, 0.6)
			-- Sejajar pagar, di depan gerbang: the plate sits on the fence line, centred on the gate opening, so a player who
			-- respawns or joins (4 studs out, facing the land) sees it right in front of them.
			plate.CFrame = origin.CFrame * CFrame.new(SIGN_X, 4.5, PlotsConfig.FRONT_Z + 0.3)
			plate.Parent = model
			for _, x in { -3.5, 3.5 } do -- two posts under the plate, on the fence line, either side of its middle
				local post = Instance.new("Part")
				post.Name = "SignPost"
				post.Anchored = true
				post.CanCollide = false
				post.Material = Enum.Material.Wood
				post.Color = Color3.fromRGB(110, 76, 46)
				post.Size = Vector3.new(0.6, 3, 0.6)
				post.CFrame = origin.CFrame * CFrame.new(SIGN_X + x, 1.5, PlotsConfig.FRONT_Z)
				post.Parent = model
			end
		end

		local surface = Instance.new("SurfaceGui")
		surface.Face = Enum.NormalId.Back -- +Z: the road side
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 40
		surface.Parent = plate

		local label = Instance.new("TextLabel")
		label.Name = "OwnerLabel"
		-- One line inside the board's margins (the name must not spill over the edge).
		if fromTemplate then
			-- The imported plang's papan_kayu mesh also holds the small status board below the main board, so its
			-- face runs from the status board (bottom) to the main board top. The main board is the upper ~2/3 of that
			-- face: the name goes there, not at the centre of the whole mesh.
			label.AnchorPoint = Vector2.new(0.5, 0)
			label.Position = UDim2.fromScale(0.5, 0.06)
			label.Size = UDim2.fromScale(0.84, 0.56)
		else
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = UDim2.fromScale(0.5, 0.5)
			label.Size = UDim2.fromScale(0.84, 0.5)
		end
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(250, 240, 214)
		label.TextWrapped = false
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Text = Locale.t("plot.empty")
		label.Parent = surface

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

-- A new player: T1 not finished or skipped, and no sale yet (the same "brand-new save" the tutorial uses).
local function isNewPlayer(data: any): boolean
	local guide = data.guide
	return guide.sells == 0 and data.onboarding.first_plant ~= true and not guide.done.t1_awal and not guide.skipped.t1_awal
end

local function spawnAtPlot(player: Player)
	local plot = plotOf[player]
	local character = player.Character
	if not plot or not character or not plot.PrimaryPart then
		return
	end
	local origin = plot.PrimaryPart :: BasePart
	local data = DataService.Get(player)
	-- EVERY spawn (first join, respawn after death, rejoin, T1 start) is in front of your OWN gate, outside the fence,
	-- facing inward toward the land. Never the middle of the land, never the last bed.
	-- GateSpawn = "a new player" (T1 semantics only). The client puts the camera behind the character on every spawn.
	local newPlayer = data ~= nil and isNewPlayer(data)
	player:SetAttribute("GateSpawn", newPlayer)
	local spawn = origin.CFrame * PlotsConfig.GATE_SPAWN
	local inward = origin.CFrame * Vector3.new(0, PlotsConfig.GATE_SPAWN.Y, PlotsConfig.FRONT_Z - 6)
	character:PivotTo(CFrame.lookAt(spawn, inward))
end

-- Gives the player their last plot if it is free, else the first free one, and remembers it (data.plotSlot).
local function assign(player: Player)
	local data = DataService.Get(player)
	local target: Model? = nil
	local preferred = if data then plots[data.plotSlot] else nil
	if preferred and ownerOf[preferred] == nil then
		target = preferred
	else
		for _, plot in plots do
			if ownerOf[plot] == nil then
				target = plot
				break
			end
		end
	end
	if not target then
		warn(`[PlotService] No free plot for {player.Name}. Is Max Players > {#plots}?`)
		return
	end
	local plot = target :: Model
	ownerOf[plot] = player
	plotOf[player] = plot
	if data then
		data.plotSlot = table.find(plots, plot) :: number
	end
	plot:SetAttribute("OwnerUserId", player.UserId)
	player:SetAttribute("PlotName", plot.Name)
	setOwnerLabel(plot, Locale.t("plot.owner", { name = player.DisplayName }))
	spawnAtPlot(player)
	PlotService.Assigned:Fire(player, plot)
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
	setOwnerLabel(plot, Locale.t("plot.empty"))
end

function PlotService.GetPlot(player: Player): Model?
	return plotOf[player]
end

-- The plot's number (1 .. Plots.COUNT), the index into Config/Plots LAYOUT.
function PlotService.PlotIndex(plot: Model): number?
	return table.find(plots, plot)
end

function PlotService.GetOwner(plot: Model): Player?
	return ownerOf[plot]
end

-- Likes shown on the sign + "Likes" attribute on the plot model (for your designed UI).
function PlotService.SetLikes(player: Player, likes: number)
	local plot = plotOf[player]
	if plot then
		plot:SetAttribute("Likes", likes)
		setOwnerLabel(plot, Locale.t("plot.owner", { name = player.DisplayName })) -- the plate shows the name only
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
