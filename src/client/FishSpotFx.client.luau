-- Fishing spots on the dock (client only, fails inert):
--   * a sign above every spot: name (Basic / Pro Mancing), level line, and a padlock while the spot is still locked
--   * fish marks on the water in front of every OPEN spot: a thin ring spreading in pairs, so you can see where the fish are
-- The sign is per player (depends on Level), so it is drawn here, not baked into the map. Any old sign from the map is removed.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Locale = require(RS.Shared.Locale)
local Fishing = require(RS.Shared.Config.Fishing)
local Vfx = require(RS.Shared.Vfx)

local player = Players.LocalPlayer

local CREAM = Color3.fromRGB(245, 236, 214)
local OPEN = Color3.fromRGB(170, 230, 140)
local LOCKED = Color3.fromRGB(240, 170, 120)
local PLATE = Color3.fromRGB(44, 30, 20)
local MARK_RANGE = 110 -- studs: marks only near the player
local MARK_EVERY = 2.6 -- seconds between fish-mark pairs on one spot
local MARK_GAP = 0.9 -- seconds between the two rings of a pair

type Spot = {
	part: BasePart,
	location: string,
	unlock: number,
	sign: BillboardGui,
	sub: TextLabel,
	lock: Frame,
	water: Vector3?,
	nextWater: number,
	nextMark: number,
	pendingMark: number?,
}

local spots: { [BasePart]: Spot } = {}

-- Padlock drawn with frames (no icon asset yet): a body and a shackle.
local function buildLock(parent: Instance): Frame
	local lock = Instance.new("Frame")
	lock.Name = "Lock"
	lock.Size = UDim2.fromOffset(14, 16)
	lock.Position = UDim2.new(0, 8, 0.5, -3)
	lock.BackgroundTransparency = 1
	lock.Parent = parent

	local shackle = Instance.new("Frame")
	shackle.Size = UDim2.fromOffset(9, 9)
	shackle.Position = UDim2.fromOffset(2, 0)
	shackle.BackgroundTransparency = 1
	shackle.Parent = lock
	local shackleCorner = Instance.new("UICorner")
	shackleCorner.CornerRadius = UDim.new(1, 0)
	shackleCorner.Parent = shackle
	local stroke = Instance.new("UIStroke")
	stroke.Color = CREAM
	stroke.Thickness = 2.2
	stroke.Parent = shackle

	local body = Instance.new("Frame")
	body.Size = UDim2.fromOffset(14, 9)
	body.Position = UDim2.fromOffset(0, 7)
	body.BackgroundColor3 = CREAM
	body.BorderSizePixel = 0
	body.Parent = lock
	local bodyCorner = Instance.new("UICorner")
	bodyCorner.CornerRadius = UDim.new(0, 3)
	bodyCorner.Parent = body
	return lock
end

-- Makes (or reuses) the sign above a spot and removes the old baked billboard that only had the name.
local function buildSign(part: BasePart): (BillboardGui, TextLabel, Frame)
	for _, child in part:GetChildren() do
		if child:IsA("BillboardGui") and child.Name ~= "SpotSign" then
			child:Destroy()
		end
	end
	local existing = part:FindFirstChild("SpotSign")
	if existing and existing:IsA("BillboardGui") then
		local sub = existing:FindFirstChild("Sub", true) :: TextLabel
		local lock = existing:FindFirstChild("Lock", true) :: Frame
		if sub and lock then
			return existing, sub, lock
		end
		existing:Destroy()
	end

	local sign = Instance.new("BillboardGui")
	sign.Name = "SpotSign"
	sign.Size = UDim2.fromOffset(124, 36)
	sign.StudsOffset = Vector3.new(0, 2.6, 0)
	sign.MaxDistance = 45
	sign.AlwaysOnTop = false
	sign.Parent = part

	local plate = Instance.new("Frame")
	plate.Size = UDim2.fromScale(1, 1)
	plate.BackgroundColor3 = PLATE
	plate.BackgroundTransparency = 0.2
	plate.BorderSizePixel = 0
	plate.Parent = sign
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = plate

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -10, 0.5, 0)
	title.Position = UDim2.fromOffset(5, 2)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = CREAM
	title.TextStrokeTransparency = 0.5
	title.Parent = plate

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Size = UDim2.new(1, -12, 0.45, 0)
	sub.Position = UDim2.new(0, 6, 0.52, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextScaled = true
	sub.TextXAlignment = Enum.TextXAlignment.Center
	sub.Parent = plate

	local lock = buildLock(plate)
	return sign, sub, lock
end

local function levelNow(): number
	local level = player:GetAttribute("Level")
	return if typeof(level) == "number" then level else 1
end

-- Finds the water in front of the dock tip. The spot sits 2 studs inside the planks' tip (MapService sets its "Dir" to the
-- way the dock points out). The planks hide the water under them, so the mark goes only PAST the tip, out over open water:
-- we walk outward from the tip and take the first water we hit. Nothing is searched sideways or back toward the land.
local TIP_DISTANCE = 2 -- studs from the spot's center to the planks' tip
local REACH = { 1, 2.5, 4, 5.5, 7 } -- studs past the tip to try, in order

local function findWater(part: BasePart): Vector3?
	local dirValue = part:GetAttribute("Dir")
	if typeof(dirValue) ~= "Vector3" then
		return nil
	end
	local dir = Vector3.new(dirValue.X, 0, dirValue.Z)
	if dir.Magnitude < 0.1 then
		return nil
	end
	dir = dir.Unit
	local tip = part.Position + dir * TIP_DISTANCE

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	params.IgnoreWater = false
	for _, reach in REACH do
		local origin = tip + dir * reach + Vector3.new(0, 12, 0)
		local hit = Workspace:Raycast(origin, Vector3.new(0, -48, 0), params)
		if hit and hit.Material == Enum.Material.Water then
			return hit.Position + Vector3.new(0, 0.3, 0) -- clear of the water surface, so the ring is not hidden inside it
		end
	end
	return nil
end

local function applySign(s: Spot)
	local level = levelNow()
	local locked = level < s.unlock
	s.sub.Text = if locked then Locale.t("spot.need", { level = s.unlock }) else Locale.t("spot.open")
	s.sub.TextColor3 = if locked then LOCKED else OPEN
	s.lock.Visible = locked
	s.sub.Position = if locked then UDim2.new(0, 26, 0.52, 0) else UDim2.new(0, 5, 0.52, 0)
	s.sub.Size = if locked then UDim2.new(1, -30, 0.45, 0) else UDim2.new(1, -10, 0.45, 0)
end

local function track(part: BasePart, location: string)
	if spots[part] then
		return
	end
	local unlock = Fishing.LOCATIONS[location] and Fishing.LOCATIONS[location].unlockLevel or 1
	local sign, sub, lock = buildSign(part)
	local titleLabel = sign:FindFirstChild("Title", true) :: TextLabel?
	if titleLabel then
		titleLabel.Text = if location == "kolam" then Locale.t("location.kolam") else Locale.t(`spot.{location}`)
	end
	local s: Spot = {
		part = part,
		location = location,
		unlock = unlock,
		sign = sign,
		sub = sub,
		lock = lock,
		water = nil,
		nextWater = 0,
		nextMark = os.clock() + math.random() * MARK_EVERY,
		pendingMark = nil,
	}
	spots[part] = s
	applySign(s)
end

-- Scan the dock spots (and our own ponds) every few seconds: picks up new ponds and retries water searches.
local function scan()
	local fishing = Workspace:FindFirstChild("Fishing")
	if not fishing then
		return
	end
	for _, child in fishing:GetChildren() do
		if child:IsA("BasePart") then
			local location = child:GetAttribute("Location")
			if location == "sungai" or location == "empang" then
				track(child, location)
			elseif location == "kolam" and child:GetAttribute("Owner") == player.UserId then
				track(child, location)
			end
		end
	end
end

local function rootPosition(): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

player:GetAttributeChangedSignal("Level"):Connect(function()
	for _, s in spots do
		applySign(s)
	end
end)

task.spawn(function()
	while true do
		scan()
		task.wait(3)
	end
end)

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local me = rootPosition()
	for part, s in spots do
		if not part.Parent then
			spots[part] = nil
			continue
		end
		if not s.water and now >= s.nextWater then
			s.water = findWater(part)
			s.nextWater = now + 6
		end
		if not s.water or not me then
			continue
		end
		local locked = levelNow() < s.unlock
		if locked or (s.water - me).Magnitude > MARK_RANGE then
			s.pendingMark = nil
			continue
		end
		if s.pendingMark and now >= s.pendingMark then
			s.pendingMark = nil
			Vfx.ring("fishmark", CFrame.new(s.water))
		end
		if now >= s.nextMark then
			s.nextMark = now + MARK_EVERY + math.random() * 0.4
			Vfx.ring("fishmark", CFrame.new(s.water))
			s.pendingMark = now + MARK_GAP
		end
	end
end)
