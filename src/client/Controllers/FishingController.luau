--!strict
-- Client side of fishing: bobber, "waiting" status, the reel mini-game, and your pond's
-- fish counter. The server decides everything that matters; this is presentation + input.
--
-- REEL MINI-GAME (calm, can't fail): a fish marker drifts along a bar. Hold "Tarik!"
-- (or Space / click-hold) to slide the catch zone right; release to let it drift left.
-- Score = share of time the fish was inside the zone -> size S / M / L / Jumbo.
--
-- UI: ScreenGui "FishingUI" > Frame "Status" (waiting, Batal) and Frame "Reel" (track, zone, fish, progress, "Pull") in the bamboo style.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local FishingTutorial = require(ReplicatedStorage.Shared.Modules.FishingTutorial)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiAssets = require(ReplicatedStorage.Shared.Config.UiAssets)
local UiKit = require(script.Parent.Parent.UiKit)
local PlayerLock = require(script.Parent.Parent.PlayerLock)
local State = require(script.Parent.Parent.State)
local FeatureClient = require(script.Parent.Parent.FeatureClient)

local REEL_ACTION = "FishingReel"
local ZONE_WIDTH = 0.3
local ZONE_SPEED = 0.9 -- bar widths per second, moving RIGHT (holding): owner says this speed is right
local ZONE_SPEED_LEFT = 0.55 -- moving LEFT (released): slower, owner 2026-11-22
local FILL_GAIN = 0.28 -- progress per second inside the box (was 0.15): the catch fills faster
local FILL_DRAIN = 0.06 -- progress lost per second outside the box (was 0.10): a short miss is forgiven

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
	l.Font = Enum.Font.FredokaOne
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
	statusFrame.Size = UDim2.fromOffset(196, 54)
	statusFrame.Visible = false
	statusFrame.Parent = gui
	darkBox(statusFrame, 16)

	local rodIcon = UiKit.icon(statusFrame, "pancing", 24)
	if rodIcon then
		rodIcon.Position = UDim2.fromOffset(8, 6)
	end
	statusLabel = label(statusFrame, "", 13, Color3.fromRGB(255, 226, 120))
	statusLabel.Position = UDim2.fromOffset(38, 4)
	statusLabel.Size = UDim2.new(1, -72, 0, 22) -- B-4: room for the X button at the right
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- B-4: X button, top right of the fishing status (cancels the fishing; the server then sends the idle state).
	local cancel = UiKit.button(statusFrame, "Cancel", "✕", UiKit.BUTTON_MUTED)
	cancel.AnchorPoint = Vector2.new(1, 0)
	cancel.Position = UDim2.new(1, -4, 0, 4)
	cancel.Size = UDim2.fromOffset(26, 26)
	cancel.TextSize = 14
	cancel.Activated:Connect(function()
		Net.Send("FishCancel")
	end)

	reelFrame = Instance.new("Frame")
	reelFrame.Name = "Reel"
	reelFrame.AnchorPoint = Vector2.new(0.5, 1)
	reelFrame.Position = UDim2.new(0.5, 0, 1, -92)
	reelFrame.Size = UDim2.fromOffset(260, 108) -- 8 px gaps between track, progress and Tarik (layout rule) -- compact: it must not cover the player (owner, 2026-11-22)
	reelFrame.Visible = false
	reelFrame.Parent = gui
	darkBox(reelFrame, 18)

	-- The bamboo frame's hollow is x 3.3 .. 96.8 %, y 13.7 .. 86.3 % of the picture: the water track sits exactly inside it,
	-- so no blue shows outside the bamboo.
	local holder = Instance.new("Frame")
	holder.Name = "TrackHolder"
	holder.Position = UDim2.fromOffset(14, 10)
	holder.Size = UDim2.new(1, -28, 0, 34)
	holder.BackgroundTransparency = 1
	holder.Parent = reelFrame
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromScale(0.033, 0.137)
	track.Size = UDim2.fromScale(0.935, 0.726)
	track.BackgroundColor3 = Color3.fromRGB(46, 104, 128) -- water
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = holder
	-- The bamboo frame of the Loading bar (UiAssets.LOADING_BAR, the same picture as the loading screen), drawn over the track.
	local trackFrame = Instance.new("ImageLabel")
	trackFrame.Name = "BambooFrame"
	trackFrame.BackgroundTransparency = 1
	trackFrame.Size = UDim2.fromScale(1, 1)
	trackFrame.Image = UiAssets.LOADING_BAR.image
	trackFrame.ScaleType = Enum.ScaleType.Stretch
	trackFrame.ZIndex = 6
	trackFrame.Parent = holder

	zone = Instance.new("Frame")
	zone.Name = "Zone"
	zone.Size = UDim2.fromScale(ZONE_WIDTH, 1)
	zone.BackgroundColor3 = Color3.fromRGB(120, 204, 96) -- the green catch zone
	zone.BackgroundTransparency = 0.15
	zone.Parent = track
	local zoneRound = Instance.new("UICorner")
	zoneRound.CornerRadius = UDim.new(0, 10)
	zoneRound.Parent = zone
	-- Glossy like the loading bar: a light-to-deep green gradient and a soft white sheen over the top half.
	local zoneShade = Instance.new("UIGradient")
	zoneShade.Rotation = 90
	zoneShade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 236, 150)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 204, 96)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 136, 50)),
	})
	zoneShade.Parent = zone
	local zoneGloss = Instance.new("Frame")
	zoneGloss.Name = "Gloss"
	zoneGloss.Size = UDim2.fromScale(1, 0.5)
	zoneGloss.BackgroundColor3 = Color3.new(1, 1, 1)
	zoneGloss.BackgroundTransparency = 0.35
	zoneGloss.BorderSizePixel = 0
	zoneGloss.Parent = zone
	local zoneGlossRound = Instance.new("UICorner")
	zoneGlossRound.CornerRadius = UDim.new(0, 10)
	zoneGlossRound.Parent = zoneGloss
	local zoneGlossFade = Instance.new("UIGradient")
	zoneGlossFade.Rotation = 90
	zoneGlossFade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	zoneGlossFade.Parent = zoneGloss

	marker = Instance.new("Frame")
	marker.Name = "Fish"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromOffset(22, 22)
	marker.Position = UDim2.fromScale(0.5, 0.5)
	marker.BackgroundTransparency = 1
	marker.Parent = track
	local fishIcon = UiKit.icon(marker, "ikan", 22)
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
	progress.Position = UDim2.fromOffset(14, 52)
	progress.Size = UDim2.new(1, -28, 0, 8)
	progress.BackgroundColor3 = Color3.fromRGB(40, 28, 18)
	progress.Parent = reelFrame
	local progressRound = Instance.new("UICorner")
	progressRound.CornerRadius = UDim.new(1, 0)
	progressRound.Parent = progress

	progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = UiKit.BAMBOO -- the bamboo gold as before, now glossy
	progressFill.BorderSizePixel = 0
	progressFill.ClipsDescendants = true
	progressFill.Parent = progress
	local progressShade = Instance.new("UIGradient")
	progressShade.Rotation = 90
	progressShade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(242, 208, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(214, 164, 64)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 104, 40)),
	})
	progressShade.Parent = progressFill
	local progressGloss = Instance.new("Frame")
	progressGloss.Name = "Gloss"
	progressGloss.Size = UDim2.fromScale(1, 0.5)
	progressGloss.BackgroundColor3 = Color3.new(1, 1, 1)
	progressGloss.BackgroundTransparency = 0.35
	progressGloss.BorderSizePixel = 0
	progressGloss.Parent = progressFill
	local glossFade = Instance.new("UIGradient")
	glossFade.Rotation = 90
	glossFade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	glossFade.Parent = progressGloss
	local fillRound = Instance.new("UICorner")
	fillRound.CornerRadius = UDim.new(1, 0)
	fillRound.Parent = progressFill

	local pull = UiKit.button(reelFrame, "Pull", Locale.t("fish.reel_button"), UiKit.BUTTON)
	pull.AnchorPoint = Vector2.new(0.5, 1)
	pull.Position = UDim2.new(0.5, 0, 1, -8)
	pull.Size = UDim2.new(1, -28, 0, 32)
	pull.TextSize = 16
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

-- B-5 (2026-11-22): joran dan pelampung pancing sungguhan digambar SERVER (Workspace.FishingVisuals) untuk semua pemain.
-- Klien menggambar sendiri hanya saat pancing tutorial Kak Fajar (salinan lokal, langkah mancing).
local function tutorialFishing(): boolean
	local snap = State.current :: any
	return FishingTutorial.isActive(snap and snap.guide)
end

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

-- Gelembung emas di pelampung (Bab 6.5 Firasat, P2-4-fix): pity >= 75% + dekat Kak Fajar.
-- Tanpa angka pity di UI; warna kembali normal saat sesi selesai (showIdle hapus bobber).
local function gildBobber()
	if bobber then
		bobber.Color = Color3.fromRGB(255, 206, 92)
	end
end

-- States --------------------------------------------------------------------------

-- B-4: from the bite-wait until the fishing ends, the player cannot walk or jump (humanoid-only lock: camera stays free).
-- Every end path calls holdForFishing(false): idle (caught, escaped, cancelled), the X button, a panel opening, death.
local releaseFishingHold: (() -> ())? = nil
local function holdForFishing(on: boolean)
	if on then
		if not releaseFishingHold then
			releaseFishingHold = PlayerLock.Acquire("fishing", true)
		end
	elseif releaseFishingHold then
		local release = releaseFishingHold
		releaseFishingHold = nil
		release()
	end
end

local function showIdle()
	player:SetAttribute("FishingActive", nil) -- Plan 3.6: dialog and coachmark come back
	holdForFishing(false)
	reeling = false
	holding = false
	statusFrame.Visible = false
	reelFrame.Visible = false
	removeBobber()
end

-- Kotak tarik dari joran (Bab 6.3): Bambu 30% s/d Pusaka 45%. Default = ZONE_WIDTH saat joran tak dikenal.
-- Buff Pancing (Bab 9.4): kotak +10% lebih lebar (baca atribut server, real-time).
local function zoneWidth(): number
	local snap = State.current :: any
	local rodId = snap and snap.rod
	local rod = if typeof(rodId) == "string" then Fishing.rods[rodId] else nil
	local width = if rod and typeof(rod.box) == "number" then rod.box / 100 else ZONE_WIDTH
	local endsAt = player:GetAttribute("Buff_pancing_End")
	if typeof(endsAt) == "number" and endsAt > Workspace:GetServerTimeNow() then
		width *= Dapur.BUFF_PANCING_BOX
	end
	-- Skill Joran Kuat (Bab 4.5, P2-4): Kotak tarik +2%/lv.
	local snapSkills = snap and snap.skills
	width *= 1 + 0.02 * (if snapSkills then snapSkills.joran_kuat or 0 else 0)
	return width
end

local function runReel()
	reeling = true
	statusFrame.Visible = false
	reelFrame.Visible = true
	if bobber then
		bobber.Position -= Vector3.new(0, 0.4, 0) -- dip
	end

	local zoneW = zoneWidth()
	zone.Size = UDim2.fromScale(zoneW, 1)
	-- Mini-game Tarik (Bab 6.2, P2-5-fix): progress mulai 30%. Ikan di kotak +15%/detik,
	-- di luar -10%/detik. 100% = dapat (skor = porsi waktu di kotak, untuk ukuran).
	-- 0% = lepas, umpan hilang, tanpa hukuman lain. Skor 0 = server anggap lepas.
	local elapsed, inZone, zoneX = 0, 0, 0.35
	local progress = 0.3
	local phase = math.random() * math.pi * 2

	local connection: RBXScriptConnection? = nil
	local function finish(score: number)
		if connection then
			connection:Disconnect()
		end
		ContextActionService:UnbindAction(REEL_ACTION)
		reeling = false
		Net.Send("FishReel", score)
	end

	-- Space / gamepad A reel instead of jumping while the mini-game runs.
	ContextActionService:BindActionAtPriority(REEL_ACTION, function(_, inputState)
		holding = inputState == Enum.UserInputState.Begin
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

	connection = RunService.RenderStepped:Connect(function(dt)
		if not reeling then
			connection:Disconnect()
			ContextActionService:UnbindAction(REEL_ACTION)
			return
		end
		elapsed += dt
		local fishX = 0.5 + 0.35 * math.sin(elapsed * 1.6 + phase) + 0.08 * math.sin(elapsed * 4.1)
		zoneX = math.clamp(zoneX + (if holding then ZONE_SPEED else -ZONE_SPEED_LEFT) * dt, 0, 1 - zoneW)
		local inside = fishX >= zoneX and fishX <= zoneX + zoneW
		if inside then
			inZone += dt
			progress = math.min(progress + FILL_GAIN * dt, 1)
		else
			progress = math.max(progress - FILL_DRAIN * dt, 0)
		end

		marker.Position = UDim2.fromScale(fishX, 0.5)
		zone.Position = UDim2.fromScale(zoneX, 0)
		progressFill.Size = UDim2.fromScale(progress, 1)

		if progress >= 1 then
			finish(if elapsed > 0 then math.clamp(inZone / elapsed, 0, 1) else 1)
		elseif progress <= 0 then
			finish(0) -- lepas: server anggap skor 0 = ikan lepas
		end
	end)
end

-- Pond counter (your own kolam) ---------------------------------------------------------

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

	-- Round, with the rod icon (owner, 2026-11-22: "button bulat pakai icon joran, posisi yang gue tandai"). Same bamboo
	-- frame and leaf-green fill as the other round buttons. Name kept: the tutorial rings "AksiButton".
	local button = Instance.new("TextButton")
	button.Name = "AksiButton"
	button.Text = ""
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.8, 0.67) -- the spot the owner circled on the playtest screenshot (2026-11-22, red line)
	button.Size = UDim2.fromOffset(84, 84)
	button.BackgroundTransparency = 1
	button.Visible = false
	button.Parent = aksiGui
	-- Same round plate as the other round buttons (HUD menu, dock): cream disc, bamboo ring, rod icon.
	UiKit.plate(button, 84, "pancing")
	button.Activated:Connect(function()
		Net.Send("FishCast")
	end)
	aksiButton = button
end

-- Q-2 gates per spot Location, the same map as FishService.SPOT_FEATURE (server). A spot whose feature is closed
-- gives no button: sungai = kanal_barat, empang = empang, kolam = kolam.
local SPOT_GATE: { [string]: string } = { sungai = "kanal_barat", empang = "empang", kolam = "kolam" }

local function nearSpot(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	for _, spot in CollectionService:GetTagged("FishingSpot") do
		if spot:IsA("BasePart") and (spot.Position - root.Position).Magnitude <= REACH then
			local loc = spot:GetAttribute("Location")
			local feature = if typeof(loc) == "string" then SPOT_GATE[loc] else nil
			if feature == nil or FeatureClient.IsOpen(feature) then
				return true
			end
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
			holdForFishing(true) -- B-4: movement off until the fishing ends
			if tutorialFishing() then
				placeBobber(spot)
			end
		elseif state == "bite" then
			statusLabel.Text = Locale.t("fish.bite")
			task.delay(0.4, runReel)
		elseif state == "idle" then
			showIdle()
		end
	end)
	Net.Listen("FishFirasat", function()
		gildBobber()
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

	-- B-4: a panel opening ends the fishing (its lock goes with it); death and removal end it too.
	player.CharacterRemoving:Connect(function()
		if player:GetAttribute("FishingActive") == true then
			Net.Send("FishCancel")
		end
		holdForFishing(false)
	end)

	task.spawn(function()
		while true do
			refreshAksi()
			if player:GetAttribute("FishingActive") == true and UiKit.anyPanelOpen() then
				Net.Send("FishCancel")
				holdForFishing(false)
			end
			task.wait(0.25)
		end
	end)

	CollectionService:GetInstanceAddedSignal("Pond"):Connect(onPondAdded)
	for _, pond in CollectionService:GetTagged("Pond") do
		onPondAdded(pond)
	end
end

return FishingController
