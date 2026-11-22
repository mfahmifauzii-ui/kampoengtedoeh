--!strict
-- Buying land (R2b), the client side. Every chunk you can buy (touching your land, see Modules/Land) gets a small round
-- "+" button with its price floating above it. It only shows while your CHARACTER is within NEAR_DISTANCE of the chunk,
-- like a proximity prompt (the camera may be far away, so the camera distance is no use).
-- Tap it and the standard confirm modal (UiKit.confirm) asks "Beli lahan ini?" with the price; Setuju sends LandBuy, the
-- server validates everything again (adjacent chunk, price, Koin). The "+" buttons hide while Garap mode is open.
-- The buttons are plain ScreenGui frames that follow an invisible client-side anchor part in the world: every frame
-- the anchor is projected to the screen (WorldToViewportPoint), so they behave like billboards but are always tappable.
--
-- UI CONTRACT: the modal is UiKit's ScreenGui "ConfirmModal" (shared by every confirmation); the "+" buttons live in "LandMarks".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Land = require(ReplicatedStorage.Shared.Modules.Land)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Plots = require(ReplicatedStorage.Shared.Config.Plots)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local GarapController = require(script.Parent.GarapController)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local VALID_COLOR = Color3.fromRGB(150, 196, 120)
local NEAR_DISTANCE = 50 -- studs from the character to the chunk's center: closer shows the "+", farther hides it
local MAX_SHOWN = 3 -- at most this many "+" at once (the nearest ones), so the screen never fills with prompts
local PLUS_SIZE = 56 -- the round plate, px (same bamboo plate as the HUD buttons)
local PRICE_GAP = 4 -- px between the plate and the price chip
local PRICE_WIDTH = 84
local PRICE_HEIGHT = 26

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local LandController = {}

type Entry = { gui: Frame, anchor: Part }
local entries: { Entry } = {}
local marks: ScreenGui
local anchorsFolder: Folder? = nil
local signature = ""

local selected: { ix: number, iz: number }? = nil
local ghost: Part? = nil

local function myPlot(): Model?
	local name = player:GetAttribute("PlotName")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = if typeof(name) == "string" and plots then plots:FindFirstChild(name) else nil
	return if plot and plot:IsA("Model") and plot.PrimaryPart then plot else nil
end

local function snapshot(): any
	return State.current
end

local function koin(): number
	local value = player:GetAttribute("Koin")
	return if typeof(value) == "number" then value else 0
end

-- Popup ------------------------------------------------------------------------------------

local function hideGhost()
	if ghost then
		ghost.Transparency = 1
	end
end

local function showGhost(plot: Model, ix: number, iz: number)
	if not ghost then
		local part = Instance.new("Part")
		part.Name = "LandGhost"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = VALID_COLOR
		part.Parent = Workspace
		ghost = part
	end
	local preview = ghost :: Part
	local origin = plot.PrimaryPart :: BasePart
	local rect = Land.chunkRect(ix, iz)
	preview.Size = Vector3.new(Land.CHUNK - 0.4, 0.2, Land.CHUNK - 0.4)
	preview.Transparency = 0.5
	preview.CFrame = origin.CFrame * CFrame.new((rect.minX + rect.maxX) / 2, origin.Size.Y / 2 + 0.3, (rect.minZ + rect.maxZ) / 2)
end

local function closePopup()
	selected = nil
	UiKit.closeConfirm()
	hideGhost()
end

-- The standard confirm modal (UiKit.confirm: Batal left in red, Setuju right): price in red when you cannot pay it.
local function refreshPopup()
	local snap = snapshot()
	local pick = selected
	if not pick or not snap then
		return
	end
	if not Land.canBuyChunk(pick.ix, pick.iz, snap.landChunks) then
		closePopup() -- bought meanwhile, or no longer touching your land
		return
	end
	local price = snap.landPrice or Land.chunkPrice(0)
	local affordable = koin() >= price
	UiKit.confirm({
		title = Locale.t("land.popup_title"),
		body = Locale.t("land.popup_info", { size = Land.CHUNK, n = snap.landExtra or 0, max = Land.EXTRA_CHUNKS }),
		totalText = Locale.t("land.price", { n = Locale.formatNumber(price) }),
		totalRed = not affordable,
		canConfirm = affordable,
		confirmText = Locale.t("land.buy"),
		onConfirm = function()
			Net.Send("LandBuy", pick.ix, pick.iz)
			selected = nil
			hideGhost()
		end,
		onCancel = closePopup,
	})
end

local function openPopup(ix: number, iz: number)
	local plot = myPlot()
	if not plot then
		return
	end
	selected = { ix = ix, iz = iz }
	showGhost(plot, ix, iz)
	refreshPopup()
end

-- Floating "+" buttons --------------------------------------------------------------------

local function clearEntries()
	for _, entry in entries do
		entry.gui:Destroy()
		entry.anchor:Destroy()
	end
	table.clear(entries)
end

local function makeEntry(plot: Model, ix: number, iz: number, price: number)
	local folder = anchorsFolder :: Folder
	local origin = plot.PrimaryPart :: BasePart
	local rect = Land.chunkRect(ix, iz)

	local anchor = Instance.new("Part")
	anchor.Name = `LandAnchor_{ix}_{iz}`
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = origin.CFrame * CFrame.new((rect.minX + rect.maxX) / 2, origin.Size.Y / 2 + 6, (rect.minZ + rect.maxZ) / 2)
	anchor.Parent = folder

	local gui = Instance.new("Frame")
	gui.Name = `LandBuy_{ix}_{iz}`
	gui.AnchorPoint = Vector2.new(0.5, 0.5)
	gui.BackgroundTransparency = 1
	gui.Size = UDim2.fromOffset(PLUS_SIZE + 4, PLUS_SIZE + 4 + PRICE_GAP + PRICE_HEIGHT)
	gui.Visible = false -- the per-frame update below shows it when it is near and on screen
	gui.Parent = marks

	-- The same round bamboo plate as the HUD buttons (UiKit.plate), with a brown "+" on it.
	local button = Instance.new("TextButton")
	button.Name = "Plus"
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = UDim2.fromScale(0.5, 0)
	button.Size = UDim2.fromOffset(PLUS_SIZE, PLUS_SIZE)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = gui
	local plate = UiKit.plate(button, PLUS_SIZE)

	local sign = Instance.new("TextLabel")
	sign.Name = "Sign"
	sign.BackgroundTransparency = 1
	sign.Size = UDim2.fromScale(1, 1)
	sign.Text = "+"
	sign.TextColor3 = UiKit.TEXT
	sign.Font = UiKit.FONT
	sign.TextSize = 36
	sign.ZIndex = 2
	sign.Parent = plate

	-- The price in the same cream chip as the HUD's value chips (UiKit.chip), centered under the plate.
	local tag = UiKit.chip(gui, "Price", nil, PRICE_WIDTH, PRICE_HEIGHT)
	local tagFrame = tag.Parent :: Frame
	tagFrame.Position = UDim2.fromOffset((PLUS_SIZE + 4 - PRICE_WIDTH) / 2, PLUS_SIZE + 4 + PRICE_GAP)
	tag.Position = UDim2.fromOffset(0, 0)
	tag.Size = UDim2.fromScale(1, 1)
	tag.TextXAlignment = Enum.TextXAlignment.Center
	tag.Text = Locale.formatNumber(price)

	button.Activated:Connect(function()
		openPopup(ix, iz)
	end)
	table.insert(entries, { gui = gui, anchor = anchor })
end

-- Rebuilds the buttons when what you can buy (or its price) changed.
local function rebuild()
	local snap = snapshot()
	local plot = myPlot()
	if not snap or not plot then
		return
	end
	local chunks = snap.landChunks or {}
	local keys = {}
	for key in chunks do
		table.insert(keys, key)
	end
	table.sort(keys)
	local now = `{plot.Name}|{snap.landPrice}|{table.concat(keys, " ")}`
	if now == signature then
		return
	end
	signature = now
	clearEntries()
	local plotIndex = tonumber(string.match(plot.Name, "%d+"))
	for _, chunk in Land.buyableChunks(chunks, if plotIndex then Plots.INWARD(plotIndex) else nil) do
		makeEntry(plot, chunk.ix, chunk.iz, snap.landPrice or Land.chunkPrice(0))
	end
end

-- UI ---------------------------------------------------------------------------------------

function LandController.Init()
	local folder = Instance.new("Folder")
	folder.Name = "LandAnchors"
	folder.Parent = Workspace
	anchorsFolder = folder

	marks = Instance.new("ScreenGui")
	marks.Name = "LandMarks"
	marks.ResetOnSpawn = false
	marks.IgnoreGuiInset = true -- the projected points are viewport coordinates
	marks:SetAttribute("NoScale", true) -- UiKit.autoScale must not scale it: offsets here are real pixels
	marks.DisplayOrder = UiKit.LAYER.WORLD -- under the HUD and the popups
	marks.Parent = playerGui
end

function LandController.Start()
	State.Changed:Connect(function()
		rebuild()
		if selected then
			refreshPopup()
		end
	end)
	player:GetAttributeChangedSignal("Koin"):Connect(function()
		if selected then
			refreshPopup()
		end
	end)
	player:GetAttributeChangedSignal("PlotName"):Connect(rebuild)

	-- Every frame: put each "+" over its chunk. Hidden while Garap mode is open, when the character is far from the
	-- chunk, or when the chunk is off screen / behind the camera.
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		local hidden = GarapController.Active
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local candidates: { { entry: Entry, distance: number } } = {}
		for _, entry in entries do
			entry.gui.Visible = false
			if camera and not hidden and root and root:IsA("BasePart") then
				local distance = (root.Position - entry.anchor.Position).Magnitude
				if distance <= NEAR_DISTANCE then
					table.insert(candidates, { entry = entry, distance = distance })
				end
			end
		end
		table.sort(candidates, function(a, b)
			return a.distance < b.distance
		end)
		for index = 1, math.min(#candidates, MAX_SHOWN) do
			local entry = candidates[index].entry
			local point, onScreen = (camera :: Camera):WorldToViewportPoint(entry.anchor.Position)
			if onScreen and point.Z > 0 then
				entry.gui.Position = UDim2.fromOffset(point.X, point.Y)
				entry.gui.Visible = true
			end
		end
		if hidden and selected then
			closePopup()
		end
	end)
	rebuild()
end

return LandController
