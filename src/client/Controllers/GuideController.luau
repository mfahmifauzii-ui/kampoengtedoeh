--!strict
-- New-player guide: a one-line hint at the top of the screen for whatever comes next in the first loop
-- (cangkul -> tanam -> siram -> panen -> jual -> beli bibit), plus a TRAIL of flowing chevrons on the ground from the player
-- to the buyer (Pak Darmo) whenever the next step is "go to him". The trail follows a real walking route (PathfindingService,
-- so it crosses the bridges, not the canal) and is drawn in the game's bamboo gold with a dark brown outline. It runs until the player has finished Onboarding.TRIES sale trips (the server counts them in
-- data.guide.sells and sends it as snapshot.guideSells), then it never shows again.
--
-- The step is worked out from what is on screen / in the bag, not from a script of its own, so it can never get out of
-- step with the game: ripe bed -> "harvest", crops in the bag -> "sell", and so on.
-- While Garap mode is open the guide stays quiet: Garap has its own hint line in the same place.
--
-- UI CONTRACT: ScreenGui "GuideUI" > TextLabel "Hint"; the trail is the Folder "GuideTrail" in Workspace (client only).

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local Locale = require(ReplicatedStorage.Shared.Locale)
local GarapController = require(script.Parent.GarapController)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)

local player = Players.LocalPlayer

local GuideController = {}

local TILE_TAG = "FarmTile"
local ARRIVED_DISTANCE = 40 -- studs: close enough to the NPC, the hint switches to "talk to him" and the trail ends

-- Trail look and size
local CHEVRONS = 16 -- pieces in the pool
local SPACING = 5 -- studs between chevrons
local START_GAP = 7 -- studs: nothing under the player's feet
local TRAIL_LENGTH = 80 -- studs of route drawn ahead of the player; it fades out toward the end
local FLOW_SPEED = 6 -- studs per second the chevrons slide toward the goal
local REPATH_SECONDS = 1.5
local GOLD = Color3.fromRGB(240, 196, 92)
local OUTLINE = Color3.fromRGB(66, 46, 30) -- UiKit.DARK

local gui: ScreenGui
local hint: TextLabel
local trailFolder: Folder
local chevrons: { { model: Model, parts: { BasePart } } } = {}
local route: { Vector3 } = {} -- walking route from the last path computation (ground-ish points, start to goal)
local pathing = false

local step = "none" -- "harvest" | "sell" | "water" | "plant" | "wait" | "till" | "buy" | "none"

local function snapshot(): any
	return State.current
end

local function active(): boolean
	local snap = snapshot()
	return snap ~= nil and typeof(snap.guideSells) == "number" and snap.guideSells < Onboarding.TRIES
end

-- Looks at my beds (tile parts carry Crop / ReadyAt / Watered attributes) and returns what exists.
local function bedStates(): (number, boolean, boolean, boolean, boolean) -- (beds, anyRipe, anyThirsty, anyGrowing, anyEmpty)
	local beds, ripe, thirsty, growing, empty = 0, false, false, false, false
	local now = Workspace:GetServerTimeNow()
	for _, instance in CollectionService:GetTagged(TILE_TAG) do
		if instance:GetAttribute("Owner") == player.UserId then
			beds += 1
			local readyAt = instance:GetAttribute("ReadyAt")
			if instance:GetAttribute("Crop") == nil or typeof(readyAt) ~= "number" then
				empty = true
			elseif now >= readyAt then
				ripe = true
			else
				growing = true
				if instance:GetAttribute("Watered") ~= true then
					thirsty = true
				end
			end
		end
	end
	return beds, ripe, thirsty, growing, empty
end

local function hasInBag(snap: any, test: (itemId: string) -> boolean): boolean
	for itemId, count in snap.items or {} do
		if count > 0 and test(itemId) then
			return true
		end
	end
	return false
end

local function computeStep(): string
	if not active() then
		return "none"
	end
	local snap = snapshot()
	local beds, ripe, thirsty, growing, empty = bedStates()
	local crops = hasInBag(snap, function(itemId)
		return Crops.byId[itemId] ~= nil
	end)
	local seeds = hasInBag(snap, function(itemId)
		return itemId:match("^seedx?_") ~= nil
	end)
	if ripe then
		return "harvest"
	elseif crops then
		return "sell"
	elseif thirsty then
		return "water"
	elseif empty and seeds then
		return "plant"
	elseif growing then
		return "wait"
	elseif beds == 0 then
		return "till"
	elseif not seeds then
		return "buy" -- beds but no bibit and nothing growing: go and buy some
	end
	return "none"
end

local function npcRoot(): BasePart?
	local folder = Workspace:FindFirstChild("Npcs")
	local model = folder and folder:FindFirstChild(Onboarding.BUYER_NPC)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function myRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Hint text + whether the arrow shows, for the current step.
local function refresh()
	step = computeStep()
	local npcName = Locale.t(`npc.{Onboarding.BUYER_NPC}`)
	local text: string? = nil
	if step == "till" then
		text = Locale.t("guide.till")
	elseif step == "plant" then
		text = Locale.t("guide.plant")
	elseif step == "water" then
		text = Locale.t("guide.water")
	elseif step == "wait" then
		text = Locale.t("guide.wait")
	elseif step == "harvest" then
		text = Locale.t("guide.harvest")
	elseif step == "sell" or step == "buy" then
		local root, npc = myRoot(), npcRoot()
		local near = root ~= nil and npc ~= nil and (root.Position - npc.Position).Magnitude <= ARRIVED_DISTANCE
		if near then
			text = Locale.t("guide.talk", { npc = npcName })
		else
			text = Locale.t(if step == "sell" then "guide.sell" else "guide.buy", { npc = npcName })
		end
	end
	hint.Visible = text ~= nil and not GarapController.Active
	hint.Text = text or ""
end

-- Trail --------------------------------------------------------------------------------------

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Where the trail ends: a few studs in front of the NPC (he stands behind a counter, so his own spot is no walking target).
local function goalPoint(npc: BasePart): Vector3
	return npc.Position + flat(npc.CFrame.LookVector) * 6
end

-- One chevron ">" pointing along its -Z: a dark outline pair under a bamboo-gold pair. Each part keeps its offset from the
-- chevron's origin, so placing the chevron is one CFrame multiply per part.
local function makeChevron(): { parts: { { part: Part, offset: CFrame } } }
	local parts = {}
	local function arm(side: number, size: Vector3, color: Color3, lift: number)
		local part = Instance.new("Part")
		part.Name = "Arm"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = color
		part.Size = size
		part.Transparency = 1
		part.Parent = trailFolder
		table.insert(parts, {
			part = part,
			offset = CFrame.new(side * 1.06, lift, 1.06) * CFrame.Angles(0, math.rad(side * 45), 0),
		})
	end
	for _, side in { -1, 1 } do
		arm(side, Vector3.new(1.6, 0.08, 3.7), OUTLINE, 0)
	end
	for _, side in { -1, 1 } do
		arm(side, Vector3.new(0.95, 0.12, 3.1), GOLD, 0.05)
	end
	return { parts = parts }
end

local function hideTrail()
	for _, chevron in chevrons do
		for _, entry in chevron.parts do
			entry.part.Transparency = 1
		end
	end
end

-- Asks for a walking route to the buyer (so the trail crosses the bridges, not the canal). Falls back to a straight line.
local function computeRoute()
	local root, npc = myRoot(), npcRoot()
	if pathing or not root or not npc then
		return
	end
	pathing = true
	local from, goal = root.Position, goalPoint(npc)
	task.spawn(function()
		local points: { Vector3 } = {}
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
		local ok = pcall(function()
			path:ComputeAsync(from, goal)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			for _, waypoint in path:GetWaypoints() do
				table.insert(points, waypoint.Position)
			end
		end
		if #points < 2 then
			points = { from, goal }
		end
		route = points
		pathing = false
	end)
end

-- Every frame: lays the chevrons along the route ahead of the player, sliding toward the goal. They sit on the ground (a ray
-- down from each spot) and fade in near the player and out toward the far end.
local function placeTrail()
	local root, npc = myRoot(), npcRoot()
	local pointing = (step == "sell" or step == "buy") and root ~= nil and npc ~= nil and #route >= 2
	if not pointing then
		hideTrail()
		return
	end
	local here = (root :: BasePart).Position
	if (here - (npc :: BasePart).Position).Magnitude <= ARRIVED_DISTANCE then
		hideTrail() -- he is right here: the E prompt and his name tag do the rest
		return
	end

	-- The route from where the player is now: start at the route point nearest to them (the one after it when they are on it).
	local nearest, best = 1, math.huge
	for index, point in route do
		local distance = flat(point - here).Magnitude
		if distance < best then
			best, nearest = distance, index
		end
	end
	if best < 3 and nearest < #route then
		nearest += 1
	end
	local line: { Vector3 } = { here }
	for index = nearest, #route do
		table.insert(line, route[index])
	end
	local lengths: { number } = { 0 }
	for index = 2, #line do
		lengths[index] = lengths[index - 1] + flat(line[index] - line[index - 1]).Magnitude
	end
	local total = lengths[#line]
	local endAt = math.min(total, TRAIL_LENGTH)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance, trailFolder }

	local flow = (os.clock() * FLOW_SPEED) % SPACING
	local seg = 1
	for index, chevron in chevrons do
		local s = START_GAP + flow + (index - 1) * SPACING
		if s >= endAt or #line < 2 then
			for _, entry in chevron.parts do
				entry.part.Transparency = 1
			end
			continue
		end
		while seg < #line - 1 and lengths[seg + 1] < s do
			seg += 1
		end
		local span = math.max(lengths[seg + 1] - lengths[seg], 1e-3)
		local point = line[seg]:Lerp(line[seg + 1], math.clamp((s - lengths[seg]) / span, 0, 1))
		local direction = flat(line[seg + 1] - line[seg])
		if direction.Magnitude < 1e-3 then
			direction = flat((npc :: BasePart).Position - here)
		end
		direction = direction.Unit

		local hit = Workspace:Raycast(point + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
		local y = if hit then hit.Position.Y + 0.1 else point.Y
		local origin = Vector3.new(point.X, y, point.Z)
		local base = CFrame.lookAt(origin, origin + direction)

		local fadeIn = math.clamp((s - START_GAP) / SPACING, 0, 1)
		local fadeOut = 1 - math.clamp((s - endAt * 0.55) / math.max(endAt * 0.45, 1), 0, 1) * 0.8
		local transparency = 1 - 0.9 * fadeIn * fadeOut
		for _, entry in chevron.parts do
			entry.part.CFrame = base * entry.offset
			entry.part.Transparency = transparency
		end
	end
end

local function darkBox(frame: GuiObject, radius: number)
	frame.BackgroundColor3 = UiKit.DARK
	frame.BackgroundTransparency = 0.08
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = frame
	local border = Instance.new("UIStroke")
	border.Color = UiKit.BAMBOO
	border.Thickness = 3
	border.Parent = frame
end

function GuideController.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "GuideUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -2 -- under the HUD and every panel
	gui:SetAttribute("NoScale", true) -- real pixels (UiKit.autoScale must not scale it)

	hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 0, 62)
	hint.Size = UDim2.fromOffset(480, 52)
	hint.TextColor3 = UiKit.CREAM
	hint.Font = UiKit.FONT_BODY
	hint.TextSize = 15
	hint.TextWrapped = true
	hint.Visible = false
	hint.Parent = gui
	darkBox(hint, 14)
	local hintPad = Instance.new("UIPadding")
	hintPad.PaddingLeft, hintPad.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
	hintPad.Parent = hint

	gui.Parent = player:WaitForChild("PlayerGui")

	trailFolder = Instance.new("Folder")
	trailFolder.Name = "GuideTrail"
	trailFolder.Parent = Workspace
	for _ = 1, CHEVRONS do
		table.insert(chevrons, makeChevron())
	end
end

function GuideController.Start()
	State.Changed:Connect(refresh)
	-- Beds change by attribute (growth, water) without a state sync: re-check a few times a second.
	task.spawn(function()
		local lastRoute = 0
		while true do
			refresh()
			if (step == "sell" or step == "buy") and os.clock() - lastRoute >= REPATH_SECONDS then
				lastRoute = os.clock()
				computeRoute()
			end
			task.wait(0.3)
		end
	end)
	RunService.RenderStepped:Connect(placeTrail)
	refresh()
end

return GuideController
