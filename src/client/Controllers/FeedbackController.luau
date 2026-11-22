--!strict
-- Feedback that tells the player something arrived: a harvested crop or a fish flies to the Bag, and coins fly to the coin
-- counter and count up. Visual only (client). The numbers themselves come from the server; this controller just shows them.
--
-- Rules:
--   * Fly: a clone flies from the source point on screen to the target GUI, 0.6 s, OutQuad, shrinking and fading. Then the
--     target pulses (scale 1 -> 1.15 -> 1) for 0.2 s.
--   * Coin count-up: the total duration is ALWAYS COIN_COUNT_SECONDS (0.8 s), whether the gain is 10 or 1000 coins. The
--     displayed number is interpolated from the start to the target over that fixed time (no per-coin steps). A "+N" tag
--     floats beside the counter while it runs.
--   * Queue: gains are played one after another (a second gain never stacks on the first).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local WeatherConfig = require(ReplicatedStorage.Shared.Config.Weather)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local FeedbackController = {}

local FLY_SECONDS = 0.6
local PULSE_SECONDS = 0.2
local COIN_COUNT_SECONDS = 0.8
local BANNER_SECONDS = 3 -- server banner for Prima Late (Bab 5.4): slides in from the top, stays 3 s, does not block
local BANNER_SLIDE_SECONDS = 0.3

local fxGui: ScreenGui
local plusTag: TextLabel
local bannerLabel: TextLabel
local bannerToken = 0 -- a newer banner cancels the hide of the older one
local queue: { { amount: number, from: Vector2, start: number } } = {}
local busy = false
local lastKoin: number? = nil
local lastSource: Vector2? = nil -- where the last harvest / catch happened (screen px): the coins fly from there
local displayKoin: number? = nil -- while the counter counts up, the HUD shows this instead of the server value

-- The displayed coin value, or nil when the HUD should show the server value.
function FeedbackController.DisplayKoin(): number?
	return displayKoin
end

local function guiInsetY(): number
	return game:GetService("GuiService"):GetGuiInset().Y
end

local function guiCenter(gui: GuiObject): Vector2
	return gui.AbsolutePosition + gui.AbsoluteSize / 2 + Vector2.new(0, guiInsetY())
end


local function hudObject(name: string): GuiObject?
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local found = playerGui and playerGui:FindFirstChild(name, true)
	return if found and found:IsA("GuiObject") then found else nil
end

-- Pulses a target (its UIScale goes 1 -> 1.15 -> 1 over PULSE_SECONDS). Creates a UIScale if needed.
local function pulse(target: GuiObject)
	local scale = target:FindFirstChild("FeedbackScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "FeedbackScale"
		scale.Parent = target
	end
	local up = TweenService:Create(scale, TweenInfo.new(PULSE_SECONDS / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.15 })
	up.Completed:Connect(function()
		TweenService:Create(scale, TweenInfo.new(PULSE_SECONDS / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1 }):Play()
	end)
	up:Play()
end

-- Flies a clone (an icon or a label) from a screen point to a target GUI, then pulses the target.
local function flyTo(from: Vector2, target: GuiObject, makeClone: () -> GuiObject, done: (() -> ())?)
	local clone = makeClone()
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Position = UDim2.fromOffset(from.X, from.Y)
	clone.Parent = fxGui
	local to = guiCenter(target)
	local tween = TweenService:Create(clone, TweenInfo.new(FLY_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(to.X, to.Y),
		Size = UDim2.fromOffset(18, 18),
	})
	tween:Play()
	-- fade in the last part of the flight
	task.delay(FLY_SECONDS * 0.6, function()
		local fade = TweenService:Create(clone, TweenInfo.new(FLY_SECONDS * 0.4, Enum.EasingStyle.Linear), { GroupTransparency = 1 })
		fade:Play()
	end)
	task.delay(FLY_SECONDS, function()
		clone:Destroy()
		pulse(target)
		if done then
			done()
		end
	end)
end

-- A small round token for a harvested crop / a fish: its colour and its first letter (no per-item art needed here).
local function token(color: Color3, letter: string): () -> GuiObject
	return function()
		local frame = Instance.new("CanvasGroup") -- a CanvasGroup can fade as one (GroupTransparency)
		frame.Size = UDim2.fromOffset(34, 34)
		frame.BackgroundColor3 = color
		frame.BorderSizePixel = 0
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = frame
		local edge = Instance.new("UIStroke")
		edge.Color = Color3.fromRGB(110, 60, 30)
		edge.Thickness = 2
		edge.Parent = frame
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = letter
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.Font = UiKit.FONT
		text.TextSize = 16
		text.Parent = frame
		return frame
	end
end

-- Harvest or catch: a token flies from the bed / the water to the Bag.
function FeedbackController.FlyToBag(from: Vector2, color: Color3, letter: string)
	local bag = hudObject("BagButton")
	lastSource = from
	if not bag then
		return
	end
	flyTo(from, bag, token(color, letter))
end

-- A harvest point is remembered so the coins of that harvest fly from the same spot.
function FeedbackController.SetSource(point: Vector2)
	lastSource = point
end

-- Coin count-up: runs one gain at a time. Total time is fixed (COIN_COUNT_SECONDS) for any amount.
local function playNext()
	if busy then
		return
	end
	local item = table.remove(queue, 1)
	if not item then
		-- Queue drained: the top bar must show the SERVER total now (it can differ from the last count-up step).
		displayKoin = nil
		local label = hudObject("KoinLabel")
		local server = player:GetAttribute("Koin")
		if label and typeof(server) == "number" then
			label.Text = Locale.formatNumber(server)
		end
		return
	end
	busy = true
	local koinLabel = hudObject("KoinLabel")
	local coinChip = koinLabel and koinLabel.Parent :: GuiObject?
	local target = koinLabel
	local startValue = item.start -- the total BEFORE this gain (fixed when queued)
	local endValue = startValue + item.amount

	local function count()
		-- the "+N" tag beside the counter
		if target and plusTag then
			plusTag.Text = `+{Locale.formatNumber(item.amount)}`
			plusTag.Position = UDim2.fromOffset(guiCenter(target).X + 36, guiCenter(target).Y - 4)
			plusTag.Visible = true
		end
		local startedAt = os.clock() -- real time, so one long frame cannot end the count early
		displayKoin = startValue
		local connection: RBXScriptConnection? = nil
		connection = RunService.RenderStepped:Connect(function()

			local t = math.min(1, (os.clock() - startedAt) / COIN_COUNT_SECONDS)
			displayKoin = math.floor(startValue + (endValue - startValue) * t + 0.5)
			if target then
				target.Text = Locale.formatNumber(displayKoin) -- the HUD only refreshes on state changes; the counter writes itself
			end
			if t >= 1 then
				(connection :: RBXScriptConnection):Disconnect()
				displayKoin = nil -- hand back to the server value (it equals endValue)
				if target then
					-- Only when nothing else is queued: then the server value is the truth (it may already include a
					-- later gain, e.g. the T1 reward after a sale). The queue-drain branch in playNext sets it too.
					local server = player:GetAttribute("Koin")
					target.Text = Locale.formatNumber(if #queue == 0 and typeof(server) == "number" then server else endValue)
				end
				plusTag.Visible = false
				busy = false
				playNext()
			end
		end)
	end

	if target and coinChip then
		local from = item.from
		flyTo(from, target, token(Color3.fromRGB(240, 196, 92), "$"), count)
	else
		count()
	end
end

-- A coin gain (from the server Koin attribute): queued, flies from the last source point, then counts up.
local function queueCoins(amount: number, start: number)
	if amount <= 0 then
		return
	end
	local from = lastSource or Vector2.new(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y / 2)
	table.insert(queue, { amount = amount, from = from, start = start })
	playNext()
end

function FeedbackController.Init()
	fxGui = Instance.new("ScreenGui")
	fxGui.Name = "FeedbackFx"
	fxGui.ResetOnSpawn = false
	fxGui.IgnoreGuiInset = true
	fxGui.DisplayOrder = UiKit.LAYER.TOAST -- 60 (GUI doc 4.5, Toast & hadiah): above the panels, below the banner
	fxGui:SetAttribute("NoScale", true)
	fxGui.Parent = player:WaitForChild("PlayerGui")

	plusTag = Instance.new("TextLabel")
	plusTag.Name = "PlusTag"
	plusTag.AnchorPoint = Vector2.new(0, 0.5)
	plusTag.Size = UDim2.fromOffset(90, 26)
	plusTag.BackgroundTransparency = 1
	plusTag.TextColor3 = Color3.fromRGB(255, 226, 120)
	plusTag.Font = UiKit.FONT
	plusTag.TextSize = 18
	plusTag.TextXAlignment = Enum.TextXAlignment.Left
	plusTag.Visible = false
	plusTag.Parent = fxGui

	bannerLabel = Instance.new("TextLabel")
	bannerLabel.Name = "KualitasBanner"
	bannerLabel.AnchorPoint = Vector2.new(0.5, 0)
	bannerLabel.Position = UDim2.new(0.5, 0, 0, -40)
	bannerLabel.Size = UDim2.new(0.8, 0, 0, 36)
	bannerLabel.BackgroundColor3 = Color3.fromRGB(40, 32, 24)
	bannerLabel.BackgroundTransparency = 0.25
	bannerLabel.TextColor3 = Color3.fromRGB(255, 226, 120)
	bannerLabel.Font = UiKit.FONT
	bannerLabel.TextSize = 20
	bannerLabel.TextScaled = false
	bannerLabel.Visible = false
	bannerLabel.Parent = fxGui
	Net.Listen("KualitasBanner", FeedbackController.ShowKualitasBanner)
end

-- Banner Prima Late from the server (FarmService): a line at the top of every player's screen for BANNER_SECONDS.
-- Phones get half-length animations (Bab 21 limits).
function FeedbackController.ShowKualitasBanner(playerName: string, cropId: string, qualityId: string)
	bannerToken += 1
	local myToken = bannerToken
	local scale = if UserInputService.TouchEnabled then WeatherConfig.UI_ANIMATION_SCALE else 1
	bannerLabel.Text = Locale.t("banner.kualitas", {
		player = playerName,
		crop = Locale.t(`crop.{cropId}`),
		quality = Locale.t(`kualitas.{qualityId}`),
	})
	bannerLabel.Position = UDim2.new(0.5, 0, 0, -40)
	bannerLabel.TextTransparency = 0
	bannerLabel.BackgroundTransparency = 0.25
	bannerLabel.Visible = true
	TweenService:Create(bannerLabel, TweenInfo.new(BANNER_SLIDE_SECONDS * scale, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 70),
	}):Play()
	task.delay(BANNER_SECONDS, function()
		if myToken ~= bannerToken then
			return
		end
		TweenService:Create(bannerLabel, TweenInfo.new(BANNER_SLIDE_SECONDS * scale), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
	end)
end

function FeedbackController.Start()
	lastKoin = player:GetAttribute("Koin") :: number?
	player:GetAttributeChangedSignal("Koin"):Connect(function()
		local koin = player:GetAttribute("Koin")
		if typeof(koin) ~= "number" then
			return
		end
		local previous = lastKoin
		lastKoin = koin
		if previous ~= nil and koin > previous then
			-- the counter keeps showing the OLD total until the gain flies in and counts up (no jump to the final number)
			displayKoin = previous
			local label = hudObject("KoinLabel")
			if label then
				label.Text = Locale.formatNumber(previous)
			end
			queueCoins(koin - previous, previous)
		end
	end)
end

return FeedbackController
