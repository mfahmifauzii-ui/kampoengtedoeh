--!strict
-- FarmFloat: small floating "action pills" over your own beds near you. Each bed tells you what it needs, right where it is:
--   empty            -> "Kosong · Tap buat tanam"   (tap: seed picker; press and hold: Pindah / Hapus Petak, or the locked note)
--   growing, dry     -> "Siram" + time left               (tap: water, the character takes out the watering can)
--   growing, watered -> a quiet timer chip                (tap: Instant Grow panel)
--   ripe             -> "Panen!"                          (tap: harvest)
-- The pills are plain Frames on a ScreenGui that follow the bed's 3D point every frame (like LandController's "+" marks), pop
-- in with a little bounce when a bed changes state, and bob gently. At most MAX_PILLS show at once (nearest first, beds that
-- need something before quiet timers) so the screen never fills up. Hidden while Garap mode, a picker or a modal is open.
--
-- UI CONTRACT: ScreenGui "FarmFloat" > Frame "Pill" > TextButton "Hit" (named "TanamButton" / "SiramButton" / "PanenButton" on those kinds, for the tutorial ring), ImageLabel "Icon", TextLabel "Title", TextLabel "Sub".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Locale = require(ReplicatedStorage.Shared.Locale)
local UiKit = require(script.Parent.UiKit)

local TILE_TAG = "FarmTile"
local RANGE = 30 -- studs from you
local MAX_PILLS = 9 -- room for a full 3x3 of beds around you
local NEAR_GROUP = 12 -- studs: beds this close (the 3x3 around you) always show their pill
local FAR_MAX = 3 -- pills for beds further away than NEAR_GROUP
local PILL_W, PILL_H = 104, 30 -- compact (owner, 2026-11-22): the timer and Siram pills were too big over a bed
local LIFT = 3.4 -- studs above the bed
local PICK_SECONDS = 0.2

local player = Players.LocalPlayer

type Pill = {
	frame: Frame,
	hit: TextButton,
	icon: ImageLabel,
	title: TextLabel,
	sub: TextLabel,
	scale: UIScale,
	kind: string,
	part: BasePart?,
	shownKind: string,
	shownTitle: string,
	shownSub: string,
	phase: number,
}

local FarmFloat = {}

local gui: ScreenGui
local pills: { Pill } = {}
local onAction: (part: BasePart, kind: string) -> () = function(_part: BasePart, _kind: string) end
local onHold: (part: BasePart, kind: string) -> () = function(_part: BasePart, _kind: string) end -- long press: the bed menu (Pindah / Hapus Petak)
local HOLD_SECONDS = 0.45
local isBlocked: () -> boolean = function()
	return false
end
local pending: { [BasePart]: number } = {} -- bed -> os.clock() until which it ignores taps (an animation is running)
local picked: { { part: BasePart, kind: string } } = {}

-- Bed state ---------------------------------------------------------------------------------------

local function bedKind(part: BasePart, now: number): string
	if part:GetAttribute("Crop") == nil then
		return "empty"
	end
	local readyAt = part:GetAttribute("ReadyAt")
	if typeof(readyAt) ~= "number" then
		return "empty"
	end
	if now >= readyAt then
		return "ripe"
	end
	return if part:GetAttribute("Watered") == true then "grow" else "dry"
end

local function clock(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local hours, minutes, secs = seconds // 3600, (seconds % 3600) // 60, seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

-- Text + icon for a pill.
local function content(part: BasePart, kind: string, now: number): (string, string, string)
	local readyAt = part:GetAttribute("ReadyAt")
	local left = if typeof(readyAt) == "number" then readyAt - now else 0
	local cropId = part:GetAttribute("Crop")
	local cropName = if typeof(cropId) == "string" then Locale.t("crop." .. cropId) else ""
	if kind == "empty" then
		return "bibit", Locale.t("float.empty"), Locale.t("float.empty_sub")
	elseif kind == "dry" then
		return "siram", Locale.t("float.water"), `{cropName} · {clock(left)}`
	elseif kind == "ripe" then
		return "panen", Locale.t("float.harvest"), cropName
	end
	return "bibit", clock(left), cropName
end

-- Pills -------------------------------------------------------------------------------------------

local function makePill(): Pill
	local frame = Instance.new("Frame")
	frame.Name = "Pill"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Size = UDim2.fromOffset(PILL_W, PILL_H)
	frame.BackgroundColor3 = UiKit.DARK
	frame.BackgroundTransparency = 0.04
	frame.Visible = false
	frame.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 12)
	round.Parent = frame
	local border = Instance.new("UIStroke")
	border.Name = "Border"
	border.Color = UiKit.BAMBOO
	border.Thickness = 2
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- a plain stroke on a Frame is a border anyway; explicit for safety
	border.Parent = frame

	local scale = Instance.new("UIScale")
	scale.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 6, 0.5, 0)
	icon.Size = UDim2.fromOffset(20, 20)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(28, 2)
	title.Size = UDim2.new(1, -32, 0, 14)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = UiKit.FONT
	title.TextSize = 12
	title.TextColor3 = Color3.fromRGB(255, 226, 120)
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromOffset(28, 16)
	sub.Size = UDim2.new(1, -32, 0, 11)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Font = Enum.Font.FredokaOne
	sub.TextSize = 9
	sub.TextColor3 = UiKit.CREAM
	sub.TextTransparency = 0.12
	sub.Parent = frame

	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = 5
	hit.Parent = frame

	local pill: Pill = {
		frame = frame,
		hit = hit,
		icon = icon,
		title = title,
		sub = sub,
		scale = scale,
		kind = "",
		part = nil,
		shownKind = "",
		shownTitle = "",
		shownSub = "",
		phase = math.random() * 6,
	}
	-- Tap = the normal action (plant / water / harvest). Press and hold (HOLD_SECONDS) = the bed menu instead.
	local pressedAt = 0
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressedAt = os.clock()
		end
	end)
	hit.Activated:Connect(function()
		local part = pill.part
		if not part or pending[part] ~= nil then
			return
		end
		if os.clock() - pressedAt >= HOLD_SECONDS then
			onHold(part, pill.kind)
		else
			onAction(part, pill.kind)
		end
	end)
	return pill
end

local function popIn(pill: Pill)
	pill.scale.Scale = 0.55
	TweenService:Create(pill.scale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Chooses which beds get a pill: mine, near me, needing something first, nearest first.
local function pick()
	picked = {}
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or isBlocked() then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local candidates: { { part: BasePart, kind: string, order: number, distance: number } } = {}
	for _, instance in CollectionService:GetTagged(TILE_TAG) do
		if instance:IsA("BasePart") and instance:GetAttribute("Owner") == player.UserId then
			local distance = (instance.Position - root.Position).Magnitude
			local blockedUntil = pending[instance]
			if blockedUntil and os.clock() > blockedUntil then
				pending[instance] = nil
				blockedUntil = nil
			end
			if distance <= RANGE and blockedUntil == nil then
				local kind = bedKind(instance, now)
				table.insert(candidates, { part = instance, kind = kind, order = distance, distance = distance })
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.order < b.order
	end)
	-- Every bed within NEAR_GROUP studs (the 3x3 you stand in) shows its pill: the timers and the Siram / Panen prompts.
	-- Beyond that only FAR_MAX more, so the screen never fills up. Empty beds show nothing here (the seed rings do that).
	local shown, far = 0, 0
	for _, candidate in candidates do
		local near = candidate.distance <= NEAR_GROUP
		if near or far < FAR_MAX then
			if shown >= MAX_PILLS then
				break
			end
			shown += 1
			picked[shown] = candidate
			if not near then
				far += 1
			end
		end
	end
end

local function layout()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local view = camera.ViewportSize
	local now = Workspace:GetServerTimeNow()
	local t = os.clock()
	local placed: { Vector2 } = {} -- screen points (pixels) of the pills already placed this frame
	for index, pill in pills do
		local choice = picked[index]
		if not choice or choice.kind == "empty" then -- an empty bed shows the seed popup (proximity), not a pill
			pill.frame.Visible = false
			pill.part = nil
			pill.kind = ""
		else
			local part = choice.part
			local screen, onScreen = camera:WorldToViewportPoint(part.Position + Vector3.new(0, LIFT, 0))
			if not onScreen then
				pill.frame.Visible = false
			else
				pill.part = part
				pill.kind = choice.kind
				local quiet = choice.kind == "grow"
				local iconKey, title, sub = content(part, choice.kind, now)
				if pill.shownKind ~= choice.kind then
					pill.shownKind = choice.kind
					-- Named so a tutorial step can ring it (GuideController findHighlight): the Tanam (empty bed), Siram and Panen pills.
					pill.hit.Name = if choice.kind == "empty" then "TanamButton" elseif choice.kind == "dry" then "SiramButton" elseif choice.kind == "ripe" then "PanenButton" else "Hit"
					popIn(pill)
					local image = UiKit.iconId(iconKey)
					if image == "" then
						image = UiKit.iconId(if iconKey == "siram" then "kolam" elseif iconKey == "panen" then "bintang" else "bibit")
					end
					pill.icon.Image = image
					pill.icon.ImageTransparency = if quiet then 0.35 else 0
					pill.frame.BackgroundTransparency = if quiet then 0.3 else 0.04
					pill.title.TextColor3 = if quiet then UiKit.CREAM else Color3.fromRGB(255, 226, 120)
					pill.title.TextSize = if quiet then 11 else 12
					local border = pill.frame:FindFirstChild("Border") :: UIStroke
					border.Color = if choice.kind == "ripe" then Color3.fromRGB(255, 226, 120) elseif quiet then UiKit.BAMBOO_DARK else UiKit.BAMBOO
				end
				if pill.shownTitle ~= title then
					pill.shownTitle = title
					pill.title.Text = title
				end
				if pill.shownSub ~= sub then
					pill.shownSub = sub
					pill.sub.Text = sub
				end
				-- Two beds side by side would stack their pills: lift a pill above any that is already there.
				local x, y = screen.X, screen.Y
				for _, other in placed do
					if math.abs(other.X - x) < PILL_W and math.abs(other.Y - y) < PILL_H + 4 then
						y = other.Y - PILL_H - 6
					end
				end
				table.insert(placed, Vector2.new(x, y))
				local bob = math.sin(t * 3 + pill.phase) * (if quiet then 1 else 3)
				pill.frame.Position = UDim2.new(x / view.X, 0, y / view.Y, bob)
				pill.frame.Visible = true
			end
		end
	end
end

-- API ---------------------------------------------------------------------------------------------

-- A bed ignores taps (and shows no pill) for `seconds` while its planting / watering / harvest animation runs.
function FarmFloat.setPending(part: BasePart, seconds: number)
	pending[part] = os.clock() + seconds
end

function FarmFloat.Init(options: { onAction: (part: BasePart, kind: string) -> (), onHold: ((part: BasePart, kind: string) -> ())?, blocked: () -> boolean })
	onAction = options.onAction
	onHold = options.onHold or onHold
	isBlocked = options.blocked
	gui = Instance.new("ScreenGui")
	gui.Name = "FarmFloat"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = UiKit.LAYER.WORLD -- under panels and the HUD
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	for _ = 1, MAX_PILLS do
		table.insert(pills, makePill())
	end

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc >= PICK_SECONDS then
			acc = 0
			pick()
		end
		layout()
	end)
end

return FarmFloat
