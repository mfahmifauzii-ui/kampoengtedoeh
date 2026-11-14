--!strict
-- Client side of fishing: bobber, "waiting" status, the reel mini-game, and your pond's
-- fish counter. The server decides everything that matters; this is presentation + input.
--
-- REEL MINI-GAME (calm, can't fail): a fish marker drifts along a bar. Hold "Tarik!"
-- (or Space / click-hold) to slide the catch zone right; release to let it drift left.
-- Score = share of time the fish was inside the zone -> size S / M / L.
--
-- UI is a plain placeholder ("FishingUI"); tell me your instance names to bind real UI.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)

local REEL_ACTION = "FishingReel"
local ZONE_WIDTH = 0.3
local ZONE_SPEED = 0.9 -- bar widths per second
local BG = Color3.fromRGB(58, 52, 44)
local TEXT = Color3.fromRGB(240, 230, 210)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local FishingController = {}

local gui: ScreenGui
local statusFrame: Frame
local statusLabel: TextLabel
local reelFrame: Frame
local zone: Frame
local marker: Frame
local progressFill: Frame
local bobber: Part?
local holding = false
local reeling = false

-- UI ------------------------------------------------------------------------------

local function corner(parent: Instance)
	Instance.new("UICorner").Parent = parent
end

local function buildUi()
	gui = Instance.new("ScreenGui")
	gui.Name = "FishingUI"
	gui.ResetOnSpawn = false

	statusFrame = Instance.new("Frame")
	statusFrame.Name = "Status"
	statusFrame.AnchorPoint = Vector2.new(0.5, 1)
	statusFrame.Position = UDim2.new(0.5, 0, 1, -24)
	statusFrame.Size = UDim2.fromOffset(300, 92)
	statusFrame.BackgroundColor3 = BG
	statusFrame.BackgroundTransparency = 0.1
	statusFrame.Visible = false
	statusFrame.Parent = gui
	corner(statusFrame)

	statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(0, 8)
	statusLabel.Size = UDim2.new(1, 0, 0, 30)
	statusLabel.TextColor3 = TEXT
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.TextSize = 18
	statusLabel.Parent = statusFrame

	local cancel = Instance.new("TextButton")
	cancel.Name = "Cancel"
	cancel.AnchorPoint = Vector2.new(0.5, 1)
	cancel.Position = UDim2.new(0.5, 0, 1, -8)
	cancel.Size = UDim2.fromOffset(120, 36)
	cancel.BackgroundColor3 = Color3.fromRGB(92, 82, 68)
	cancel.TextColor3 = TEXT
	cancel.Font = Enum.Font.GothamMedium
	cancel.TextSize = 16
	cancel.Text = Locale.t("fish.cancel")
	cancel.Parent = statusFrame
	corner(cancel)
	cancel.Activated:Connect(function()
		Net.Send("FishCancel")
	end)

	reelFrame = Instance.new("Frame")
	reelFrame.Name = "Reel"
	reelFrame.AnchorPoint = Vector2.new(0.5, 1)
	reelFrame.Position = UDim2.new(0.5, 0, 1, -24)
	reelFrame.Size = UDim2.fromOffset(340, 150)
	reelFrame.BackgroundColor3 = BG
	reelFrame.BackgroundTransparency = 0.1
	reelFrame.Visible = false
	reelFrame.Parent = gui
	corner(reelFrame)

	local hint = statusLabel:Clone()
	hint.Text = Locale.t("fish.reel_hint")
	hint.TextSize = 14
	hint.Parent = reelFrame

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(20, 44)
	track.Size = UDim2.new(1, -40, 0, 28)
	track.BackgroundColor3 = Color3.fromRGB(92, 128, 128)
	track.Parent = reelFrame
	corner(track)

	zone = Instance.new("Frame")
	zone.Name = "Zone"
	zone.Size = UDim2.fromScale(ZONE_WIDTH, 1)
	zone.BackgroundColor3 = Color3.fromRGB(214, 196, 150)
	zone.BackgroundTransparency = 0.35
	zone.Parent = track
	corner(zone)

	marker = Instance.new("Frame")
	marker.Name = "Fish"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromOffset(14, 20)
	marker.Position = UDim2.fromScale(0.5, 0.5)
	marker.BackgroundColor3 = Color3.fromRGB(176, 120, 80)
	marker.Parent = track
	corner(marker)

	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.Position = UDim2.fromOffset(20, 78)
	progress.Size = UDim2.new(1, -40, 0, 6)
	progress.BackgroundColor3 = Color3.fromRGB(92, 82, 68)
	progress.Parent = reelFrame

	progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = TEXT
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progress

	local pull = Instance.new("TextButton")
	pull.Name = "Pull"
	pull.AnchorPoint = Vector2.new(0.5, 1)
	pull.Position = UDim2.new(0.5, 0, 1, -10)
	pull.Size = UDim2.fromOffset(160, 44)
	pull.BackgroundColor3 = Color3.fromRGB(118, 148, 86)
	pull.TextColor3 = TEXT
	pull.Font = Enum.Font.GothamBold
	pull.TextSize = 20
	pull.Text = Locale.t("fish.reel_button")
	pull.Parent = reelFrame
	corner(pull)
	pull.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = true
		end
	end)
	pull.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = false
		end
	end)

	gui.Parent = playerGui
end

-- Bobber --------------------------------------------------------------------------

local function removeBobber()
	if bobber then
		bobber:Destroy()
		bobber = nil
	end
end

local function placeBobber(spot: BasePart)
	removeBobber()
	local part = Instance.new("Part")
	part.Name = "Bobber"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * 0.8
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Color = Color3.fromRGB(196, 92, 72)
	part.Position = spot.Position + Vector3.new(0, spot.Size.Y / 2 + 0.3, 0)
	part.Parent = Workspace
	bobber = part
end

-- States --------------------------------------------------------------------------

local function showIdle()
	reeling = false
	holding = false
	statusFrame.Visible = false
	reelFrame.Visible = false
	removeBobber()
end

local function runReel()
	reeling = true
	statusFrame.Visible = false
	reelFrame.Visible = true
	if bobber then
		bobber.Position -= Vector3.new(0, 0.4, 0) -- dip
	end

	local duration = Fishing.REEL_SECONDS
	local elapsed, inZone, zoneX = 0, 0, 0.35
	local phase = math.random() * math.pi * 2

	-- Space / gamepad A reel instead of jumping while the mini-game runs.
	ContextActionService:BindActionAtPriority(REEL_ACTION, function(_, inputState)
		holding = inputState == Enum.UserInputState.Begin
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not reeling then
			connection:Disconnect()
			ContextActionService:UnbindAction(REEL_ACTION)
			return
		end
		elapsed += dt
		local fishX = 0.5 + 0.35 * math.sin(elapsed * 1.6 + phase) + 0.08 * math.sin(elapsed * 4.1)
		zoneX = math.clamp(zoneX + (if holding then ZONE_SPEED else -ZONE_SPEED) * dt, 0, 1 - ZONE_WIDTH)
		if fishX >= zoneX and fishX <= zoneX + ZONE_WIDTH then
			inZone += dt
		end

		marker.Position = UDim2.fromScale(fishX, 0.5)
		zone.Position = UDim2.fromScale(zoneX, 0)
		progressFill.Size = UDim2.fromScale(math.min(elapsed / duration, 1), 1)

		if elapsed >= duration then
			connection:Disconnect()
			ContextActionService:UnbindAction(REEL_ACTION)
			reeling = false
			Net.Send("FishReel", inZone / duration)
		end
	end)
end

-- Pond counter (your own kolam) ---------------------------------------------------------

local function updatePond(pond: BasePart)
	local collect = pond:FindFirstChild("CollectPrompt")
	local lastCollect = pond:GetAttribute("LastCollect")
	local cap = pond:GetAttribute("Cap")
	if not collect or not collect:IsA("ProximityPrompt") or typeof(lastCollect) ~= "number" or typeof(cap) ~= "number" then
		return
	end
	local count = math.min(cap, (Workspace:GetServerTimeNow() - lastCollect) // Fishing.POND.INTERVAL)
	collect.ObjectText = Locale.t("pond.count", { n = math.max(count, 0), cap = cap })
end

local function onPondAdded(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	if instance:GetAttribute("Owner") ~= player.UserId then
		-- Other players' ponds: hide their prompts locally.
		for _, child in instance:GetChildren() do
			if child:IsA("ProximityPrompt") then
				child.Enabled = false
			end
		end
	end
end

function FishingController.Init()
	buildUi()
end

function FishingController.Start()
	Net.Listen("FishState", function(state: any, spot: any)
		if state == "waiting" and typeof(spot) == "Instance" and spot:IsA("BasePart") then
			reelFrame.Visible = false
			statusLabel.Text = Locale.t("fish.waiting")
			statusFrame.Visible = true
			placeBobber(spot)
		elseif state == "bite" then
			statusLabel.Text = Locale.t("fish.bite")
			task.delay(0.4, runReel)
		elseif state == "idle" then
			showIdle()
		end
	end)

	-- Click-and-hold anywhere on screen also reels (desktop).
	UserInputService.InputBegan:Connect(function(input, processed)
		if reeling and not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			holding = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holding = false
		end
	end)

	CollectionService:GetInstanceAddedSignal("Pond"):Connect(onPondAdded)
	for _, pond in CollectionService:GetTagged("Pond") do
		onPondAdded(pond)
	end

	while true do
		task.wait(1)
		for _, pond in CollectionService:GetTagged("Pond") do
			if pond:IsA("BasePart") and pond:GetAttribute("Owner") == player.UserId then
				updatePond(pond)
			end
		end
	end
end

return FishingController
