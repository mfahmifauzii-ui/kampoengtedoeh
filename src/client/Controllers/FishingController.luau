--!strict
-- Client side of fishing: bobber, "waiting" status, the reel mini-game, and your pond's
-- fish counter. The server decides everything that matters; this is presentation + input.
--
-- REEL MINI-GAME (calm, can't fail): a fish marker drifts along a bar. Hold "Tarik!"
-- (or Space / click-hold) to slide the catch zone right; release to let it drift left.
-- Score = share of time the fish was inside the zone -> size S / M / L.
--
-- UI: ScreenGui "FishingUI" > Frame "Status" (waiting, Batal) and Frame "Reel" (track, zone, fish, progress, "Pull") in the bamboo style.

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
local UiKit = require(script.Parent.Parent.UiKit)
local State = require(script.Parent.Parent.State)

local REEL_ACTION = "FishingReel"
local ZONE_WIDTH = 0.3
local ZONE_SPEED = 0.9 -- bar widths per second

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

local function darkBox(frame: GuiObject, radius: number)
	frame.BackgroundColor3 = UiKit.DARK
	frame.BackgroundTransparency = 0.06
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = frame
	local border = Instance.new("UIStroke")
	border.Color = UiKit.BAMBOO
	border.Thickness = 3
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = frame
end

local function label(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = size
	l.TextColor3 = color or UiKit.CREAM
	l.Text = text
	l.Parent = parent
	return l
end

-- Two small bamboo-brown cards at the bottom centre: STATUS (waiting / bite, with Batal) and REEL (the mini-game). Only one is
-- visible at a time. The reel bar is a wide, thick track so the fish and the zone read at a glance on a phone.
local function buildUi()
	gui = Instance.new("ScreenGui")
	gui.Name = "FishingUI"
	gui.ResetOnSpawn = false

	statusFrame = Instance.new("Frame")
	statusFrame.Name = "Status"
	statusFrame.AnchorPoint = Vector2.new(0.5, 1)
	statusFrame.Position = UDim2.new(0.5, 0, 1, -92)
	statusFrame.Size = UDim2.fromOffset(240, 78)
	statusFrame.Visible = false
	statusFrame.Parent = gui
	darkBox(statusFrame, 16)

	local rodIcon = UiKit.icon(statusFrame, "pancing", 34)
	if rodIcon then
		rodIcon.Position = UDim2.fromOffset(10, 8)
	end
	statusLabel = label(statusFrame, "", 17, Color3.fromRGB(255, 226, 120))
	statusLabel.Position = UDim2.fromOffset(52, 6)
	statusLabel.Size = UDim2.new(1, -62, 0, 34)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left

	local cancel = UiKit.button(statusFrame, "Cancel", Locale.t("fish.cancel"), UiKit.BUTTON_MUTED)
	cancel.AnchorPoint = Vector2.new(0.5, 1)
	cancel.Position = UDim2.new(0.5, 0, 1, -7)
	cancel.Size = UDim2.new(1, -24, 0, 30)
	cancel.TextSize = 14
	cancel.Activated:Connect(function()
		Net.Send("FishCancel")
	end)

	reelFrame = Instance.new("Frame")
	reelFrame.Name = "Reel"
	reelFrame.AnchorPoint = Vector2.new(0.5, 1)
	reelFrame.Position = UDim2.new(0.5, 0, 1, -92)
	reelFrame.Size = UDim2.fromOffset(330, 150)
	reelFrame.Visible = false
	reelFrame.Parent = gui
	darkBox(reelFrame, 18)

	local hint = label(reelFrame, Locale.t("fish.reel_hint"), 14)
	hint.Position = UDim2.fromOffset(12, 8)
	hint.Size = UDim2.new(1, -24, 0, 20)

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(16, 36)
	track.Size = UDim2.new(1, -32, 0, 34)
	track.BackgroundColor3 = Color3.fromRGB(46, 104, 128) -- water
	track.ClipsDescendants = true
	track.Parent = reelFrame
	local trackRound = Instance.new("UICorner")
	trackRound.CornerRadius = UDim.new(0, 12)
	trackRound.Parent = track
	local trackBorder = Instance.new("UIStroke")
	trackBorder.Color = UiKit.BAMBOO_DARK
	trackBorder.Thickness = 2
	trackBorder.Parent = track

	zone = Instance.new("Frame")
	zone.Name = "Zone"
	zone.Size = UDim2.fromScale(ZONE_WIDTH, 1)
	zone.BackgroundColor3 = Color3.fromRGB(120, 204, 96) -- the green catch zone
	zone.BackgroundTransparency = 0.15
	zone.Parent = track
	local zoneRound = Instance.new("UICorner")
	zoneRound.CornerRadius = UDim.new(0, 10)
	zoneRound.Parent = zone

	marker = Instance.new("Frame")
	marker.Name = "Fish"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromOffset(26, 26)
	marker.Position = UDim2.fromScale(0.5, 0.5)
	marker.BackgroundTransparency = 1
	marker.Parent = track
	local fishIcon = UiKit.icon(marker, "ikan", 26)
	if fishIcon then
		fishIcon.Position = UDim2.fromScale(0, 0)
	else
		marker.BackgroundTransparency = 0
		marker.BackgroundColor3 = Color3.fromRGB(255, 226, 120)
		local fishRound = Instance.new("UICorner")
		fishRound.CornerRadius = UDim.new(1, 0)
		fishRound.Parent = marker
	end

	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.Position = UDim2.fromOffset(16, 78)
	progress.Size = UDim2.new(1, -32, 0, 8)
	progress.BackgroundColor3 = Color3.fromRGB(40, 28, 18)
	progress.Parent = reelFrame
	local progressRound = Instance.new("UICorner")
	progressRound.CornerRadius = UDim.new(1, 0)
	progressRound.Parent = progress

	progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = UiKit.BAMBOO
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progress
	local fillRound = Instance.new("UICorner")
	fillRound.CornerRadius = UDim.new(1, 0)
	fillRound.Parent = progressFill

	local pull = UiKit.button(reelFrame, "Pull", Locale.t("fish.reel_button"), UiKit.BUTTON)
	pull.AnchorPoint = Vector2.new(0.5, 1)
	pull.Position = UDim2.new(0.5, 0, 1, -10)
	pull.Size = UDim2.new(1, -32, 0, 48)
	pull.TextSize = 22
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
	player:SetAttribute("FishingActive", nil) -- Plan 3.6: dialog and coachmark come back
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

-- Mancing button (v6.2.3 A3, Bab 23.2 AKSI): a big button at the right edge while you stand within reach of a dock or a
-- pond of yours, once the fishing gift is taken. Before this, the only cast was a ProximityPrompt (4 studs): no button at all.
-- Named "AksiButton" so the tutorial can ring it (GuideController findHighlight). The server does the cast (FishCast).
local REACH = 10 -- studs from the player to a spot for the button to show (client hint only; the server checks CAST_DISTANCE)
local aksiGui: ScreenGui? = nil
local aksiButton: TextButton? = nil

local function buildAksi()
	aksiGui = Instance.new("ScreenGui")
	aksiGui.Name = "FishAksi"
	aksiGui.ResetOnSpawn = false
	aksiGui.DisplayOrder = 6
	aksiGui.Parent = player:WaitForChild("PlayerGui")

	local button = UiKit.button(aksiGui, "AksiButton", Locale.t("prompt.fish"), UiKit.BUTTON)
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -24, 1, -200)
	button.Size = UDim2.fromOffset(104, 104) -- 104 px: well above the 48 dp minimum
	button.Visible = false
	button.Activated:Connect(function()
		Net.Send("FishCast")
	end)
	aksiButton = button
end

local function nearSpot(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	for _, spot in CollectionService:GetTagged("FishingSpot") do
		if spot:IsA("BasePart") and (spot.Position - root.Position).Magnitude <= REACH then
			return true
		end
	end
	return false
end

local function refreshAksi()
	if not aksiButton then
		return
	end
	local snap = State.current :: any
	local gifted = snap ~= nil and snap.guide ~= nil and snap.guide.rodGift == true
	local fishing = player:GetAttribute("FishingActive") == true
	aksiButton.Visible = gifted and not fishing and nearSpot()
end

function FishingController.Init()
	buildUi()
	buildAksi()
end

function FishingController.Start()
	Net.Listen("FishState", function(state: any, spot: any)
		if state == "waiting" and typeof(spot) == "Instance" and spot:IsA("BasePart") then
			reelFrame.Visible = false
			statusLabel.Text = Locale.t("fish.waiting")
			statusFrame.Visible = true
			player:SetAttribute("FishingActive", true) -- Plan 3.6: the fishing GUI is on top, the dialog steps aside
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

	task.spawn(function()
		while true do
			refreshAksi()
			task.wait(0.25)
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
