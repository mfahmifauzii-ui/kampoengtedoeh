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
-- TUTORIAL ENGINE (on top of the above): runs the tutorials of Config/Onboarding TUTORIALS, one at a time. While one runs
-- it owns the hint bar (text of the current step; there is no skip button), the ground trail (step.target), and a pulsing ring on
-- a HUD button (step.highlight); the old guide stays quiet. Steps are NEVER blocking: every step whose condition already
-- holds is ticked at once, conditions are ">=". The server (TutorialService) saves the step counter, pays rewards and logs
-- analytics; this side only watches the world and asks. No progress for 45 s = stronger ring, 90 s = the explicit text.
-- Replay (Atur > Panduan) runs the same steps with no save and no reward.
--
-- UI CONTRACT: ScreenGui "GuideUI" > TextLabel "Hint"; the trail is the Folder "GuideTrail" in Workspace
-- (client only); the ring is a Frame "GuideRing" parented to the highlighted HUD button.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local GarapController = require(script.Parent.GarapController)
local CoachmarkController = require(script.Parent.CoachmarkController)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)
local WorldArrow = require(script.Parent.Parent.WorldArrow)

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
local hint: Frame -- the parchment chip (see hintText for the words)
local hintText: TextLabel
local trailFolder: Folder
local chevrons: { { model: Model, parts: { BasePart } } } = {}
local route: { Vector3 } = {} -- walking route from the last path computation (ground-ish points, start to goal)
local pathing = false

local step = "none" -- old guide: "harvest" | "sell" | "water" | "plant" | "wait" | "till" | "buy" | "none"

-- Tutorial engine state -------------------------------------------------------------------------
type Running = {
	def: Onboarding.Tutorial,
	n: number, -- steps done
	replay: boolean,
	stepAt: number, -- os.clock() when the current step became current
	progressAt: number, -- os.clock() of the last progress (stuck timers)
	introUntil: number,
}
local running: Running? = nil
local lastFinish: number? = nil -- os.clock() when the last tutorial ended (queue gap)
local firstSnapshotAt: number? = nil
local closed: { [string]: string } = {} -- "done" | "skipped" in this session (the snapshot may still be stale)
local acked: { [string]: boolean } = {} -- welcome modal "Mulai" pressed, per step id (kind "ack"); reset on every run
local welcomeShown = false -- the welcome modal of the current run has been opened
local defs: { Onboarding.Tutorial } = {}
local defById: { [string]: Onboarding.Tutorial } = {}
local hintPad: UIPadding
local ring: Frame? = nil
local ringFor: string? = nil
local ringStrong = false

GuideController.Changed = Signal.new() -- () a tutorial started or ended

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
	local snap = snapshot()
	if not snap then
		return "none"
	end
	local beds, ripe, thirsty, growing, empty = bedStates()
	local crops = hasInBag(snap, function(itemId)
		return Crops.byId[itemId] ~= nil
	end)
	local seeds = hasInBag(snap, function(itemId)
		return itemId:match("^seedx?_") ~= nil
	end)
	if not active() then
		-- After the first sale trips the guide is quiet, except for the one thing that stops the loop dead: no bibit and nothing
		-- growing. (The beds and the "Siram / Panen" pills say the rest.)
		if beds > 0 and not seeds and not growing and not ripe and not crops then
			return "buy"
		end
		return "none"
	end
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

local function npcRootOf(npcId: string): BasePart?
	local folder = Workspace:FindFirstChild("Npcs")
	local model = folder and folder:FindFirstChild(npcId)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function npcRoot(): BasePart?
	return npcRootOf(Onboarding.BUYER_NPC)
end

local function myRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Instruction sink (set by T1Ghost.client): while Mbok Minah's local copy stands at the gate, a T1 step's instruction is
-- SPOKEN in her bubble. The sink gets a step key ("cangkul", "cangkul_ground", "tanam", "siram", "panen_wait", "panen_harvest",
-- "panen_sell") and whether the player has been stuck for a while; it returns true when it spoke. Then no instruction text
-- shows in the hint bar or the coachmark bubble: the coachmark keeps only its glow / ring / arrows. No sink (or false) =
-- the old text behaviour, so a replay without her, or a failed build, still teaches.
local instructionSink: ((key: string, stuck: boolean) -> boolean)? = nil

local function say(key: string, stuck: boolean): boolean
	local sink = instructionSink
	return sink ~= nil and sink(key, stuck)
end

-- Hint text + whether the arrow shows, for the current step.
local refreshTutorial: () -> ()
local findHighlight: (name: string) -> GuiObject?

local function refresh()
	if running then
		step = "none"
		refreshTutorial()
		return
	end
	hintPad.PaddingRight = UDim.new(0, 14)
	hint.Position = UDim2.new(0.5, 0, 0.12, 0) -- top of the screen, under the coin bar (not the middle)
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
			text = Locale.t(if step == "sell" then "guide.sell" elseif active() then "guide.buy" else "guide.buy_plain", { npc = npcName })
		end
	end
	hint.Visible = text ~= nil and not GarapController.Active
	hintText.Text = text or ""
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

type Goal = { key: string, target: Vector3, point: Vector3, radius: number, part: BasePart? }
local routeKey = ""

-- T1 panen step (user, 16 Nov): what the player must do NOW.
--   "wait"    a planted bed is still growing: text "Tunggu matang", arrow to that bed (never to Pak Darmo)
--   "harvest" a bed is ripe: text "Tap Panen", arrow to the ripe bed
--   "sell"    the harvest is in the Tas: text "Jual ke Pak Darmo", arrow to Pak Darmo (only now)
local function t1Phase(): string
	local snap = snapshot()
	local kangkung = if snap and snap.items then snap.items.kangkung else nil
	if typeof(kangkung) == "number" and kangkung > 0 then
		return "sell"
	end
	local now = Workspace:GetServerTimeNow()
	for _, instance in CollectionService:GetTagged(TILE_TAG) do
		if instance:IsA("BasePart") and instance:GetAttribute("Owner") == player.UserId and instance:GetAttribute("Crop") ~= nil then
			local readyAt = instance:GetAttribute("ReadyAt")
			if typeof(readyAt) == "number" and now >= readyAt then
				return "harvest"
			end
		end
	end
	return "wait"
end

-- The nearest of MY beds that matches kind: "empty" (no crop), "dry" (crop, not watered), "ripe", "growing".
local function t1BedGoal(kind: string): Goal?
	local root = myRoot()
	local now = Workspace:GetServerTimeNow()
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, instance in CollectionService:GetTagged(TILE_TAG) do
		if instance:IsA("BasePart") and instance:GetAttribute("Owner") == player.UserId then
			local crop = instance:GetAttribute("Crop") ~= nil
			local readyAt = instance:GetAttribute("ReadyAt")
			local ripe = crop and typeof(readyAt) == "number" and now >= readyAt
			local match = (kind == "empty" and not crop)
				or (kind == "dry" and crop and instance:GetAttribute("Watered") ~= true)
				or (kind == "ripe" and ripe)
				or (kind == "growing" and crop and not ripe)
			if match then
				local distance = if root then (instance.Position - root.Position).Magnitude else 0
				if distance < bestDistance then
					bestDistance = distance
					best = instance
				end
			end
		end
	end
	if not best then
		return nil
	end
	return { key = `bed:{best:GetAttribute("Index")}:{kind}`, target = best.Position, point = best.Position, radius = 5, part = best }
end

-- The centre of the player's own land (plot), the "land" target. Nil when the player has no plot yet.
local function myLandCenter(): Vector3?
	for _, plot in Workspace.Plots:GetChildren() do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot:GetPivot().Position
		end
	end
	return nil
end

-- Where the trail leads right now: the current tutorial step's target, else (old guide) the buyer when there is something to sell/buy.
local function currentGoal(): Goal?
	if running then
		local current = running.def.steps[running.n + 1]
		-- T1 bed steps: the arrow is ONLY on the bed the step needs (never to Pak Darmo before the harvest is in the Tas).
		if current and current.id == "tanam" then
			return t1BedGoal("empty")
		elseif current and current.id == "siram" then
			return t1BedGoal("dry")
		elseif current and current.id == "panen_jual" then
			local phase = t1Phase()
			if phase ~= "sell" then
				return t1BedGoal(if phase == "harvest" then "ripe" else "growing")
			end
		end
		local target = current and current.target
		if not current or not target then
			return nil
		end
		local radius = current.arrive or 25
		if target.npc then
			local npc = npcRootOf(target.npc)
			if npc then
				return { key = `npc:{target.npc}`, target = npc.Position, point = goalPoint(npc), radius = radius }
			end
		elseif target.pos then
			return { key = `pos:{target.pos}`, target = target.pos, point = target.pos, radius = radius }
		elseif target.land then
			local center = myLandCenter()
			if center then
				return { key = `land:{player.UserId}`, target = center, point = center, radius = radius }
			end
		elseif target.spot then
			-- The nearest fishing spot of that Location (e.g. the river dock "sungai").
			local here = myRoot()
			local best: BasePart? = nil
			local bestDistance = math.huge
			for _, part in CollectionService:GetTagged("FishingSpot") do
				if part:IsA("BasePart") and part:GetAttribute("Location") == target.spot then
					local distance = if here then (part.Position - here.Position).Magnitude else 0
					if distance < bestDistance then
						best, bestDistance = part, distance
					end
				end
			end
			if best then
				return { key = `spot:{best:GetFullName()}`, target = best.Position, point = best.Position, radius = radius }
			end
		end
		return nil
	end
	if (step == "sell" or step == "buy") and active() then -- the ground arrow is for the first trips only
		local npc = npcRoot()
		if npc then
			return { key = `npc:{Onboarding.BUYER_NPC}`, target = npc.Position, point = goalPoint(npc), radius = ARRIVED_DISTANCE }
		end
	end
	return nil
end

-- Asks for a walking route to the goal (so the trail crosses the bridges, not the canal). Falls back to a straight line.
local function computeRoute(wanted: Goal)
	local root = myRoot()
	if pathing or not root then
		return
	end
	pathing = true
	local from, goal, key = root.Position, wanted.point, wanted.key
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
		routeKey = key
		pathing = false
	end)
end

-- Big arrow above the target bed of a T1 step (user, 16 Nov: the arrow must be visible in the screenshot).
-- The arrow is a screen label placed over the bed (WorldArrow), 9 studs up so it clears the bed's own pill (FarmFloat).
local bedArrow: any = nil
local function updateTutorialBedArrow()
	-- Removed (user, 16 Nov): "arrow coklat" over the T1 beds and Pak Darmo is not needed, the hint text is clear enough.
	-- The hint bar and the ground trail stay. Quest (Misi) arrows are separate (QuestController).
	if bedArrow then
		bedArrow.hide()
	end
	if true then
		return
	end
	local goal = if running then currentGoal() else nil
	local part: BasePart? = goal and goal.part
	local text: string? = nil
	if goal and part then
		text = if string.find(goal.key, ":ripe") then Locale.t("tut.arrow.panen")
			elseif string.find(goal.key, ":growing") then Locale.t("tut.arrow.tunggu")
			elseif string.find(goal.key, ":dry") then Locale.t("tut.arrow.siram")
			else Locale.t("tut.arrow.tanam")
	elseif running and running.def.steps[running.n + 1] and running.def.steps[running.n + 1].id == "panen_jual" and t1Phase() == "sell" then
		-- the harvest is in the Tas: the arrow moves to Pak Darmo (never before)
		part = npcRootOf("pak_darmo")
		text = Locale.t("tut.arrow.jual")
	end
	if not part or not text then
		if bedArrow then
			bedArrow.hide()
		end
		return
	end
	if not bedArrow then
		bedArrow = WorldArrow.new("TutArrow", 9)
	end
	bedArrow.show(part, text)
end

-- Every frame: lays the chevrons along the route ahead of the player, sliding toward the goal. They sit on the ground (a ray
-- down from each spot) and fade in near the player and out toward the far end.
local function placeTrail()
	local root, goal = myRoot(), currentGoal()
	if not root or not goal or routeKey ~= goal.key or #route < 2 then
		hideTrail()
		return
	end
	local here = root.Position
	if (here - goal.target).Magnitude <= goal.radius then
		hideTrail() -- arrived: the E prompt / the next step do the rest
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
			direction = flat(goal.target - here)
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

local parchmentBox = UiKit.parchmentBox

local function darkBox(frame: GuiObject, radius: number)
	frame.BackgroundColor3 = UiKit.DARK
	frame.BackgroundTransparency = 0.08
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = frame
	local border = Instance.new("UIStroke")
	border.Color = UiKit.BAMBOO
	border.Thickness = 3
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- on a TextLabel the default (Contextual) outlines the LETTERS in gold
	border.Parent = frame
end

-- Tutorial engine ---------------------------------------------------------------------------------

local function guideData(): any
	local snap = snapshot()
	return snap and snap.guide
end

local function isFinished(id: string): boolean
	local guide = guideData()
	return closed[id] ~= nil or (guide ~= nil and (guide.done[id] == true or guide.skipped[id] == true))
end

local function ownedBeds(): { BasePart }
	local beds = {}
	for _, instance in CollectionService:GetTagged(TILE_TAG) do
		if instance:IsA("BasePart") and instance:GetAttribute("Owner") == player.UserId then
			table.insert(beds, instance)
		end
	end
	return beds
end

local function countBeds(test: (bed: BasePart, now: number) -> boolean): number
	local now, count = Workspace:GetServerTimeNow(), 0
	for _, bed in ownedBeds() do
		if test(bed, now) then
			count += 1
		end
	end
	return count
end

-- True when the condition holds (always ">=": more than asked is fine).
local function evalCondition(condition: Onboarding.Condition): boolean
	local need = condition.n or 1
	local kind = condition.kind
	if kind == "always" then
		return true
	elseif kind == "tiles" then
		return #ownedBeds() >= need
	elseif kind == "planted" then
		return countBeds(function(bed)
			return bed:GetAttribute("Crop") ~= nil
		end) >= need
	elseif kind == "watered" then
		return countBeds(function(bed)
			return bed:GetAttribute("Crop") ~= nil and bed:GetAttribute("Watered") == true
		end) >= need
	elseif kind == "ripe" then
		return countBeds(function(bed, now)
			local readyAt = bed:GetAttribute("ReadyAt")
			return bed:GetAttribute("Crop") ~= nil and typeof(readyAt) == "number" and now >= readyAt
		end) >= need
	elseif kind == "item" then
		local snap, total = snapshot(), 0
		local prefix = condition.id or ""
		local items = if snap then snap.items or {} else {}
		for itemId, count in items do
			if itemId:sub(1, #prefix) == prefix then
				total += count
			end
		end
		return total >= need
	elseif kind == "level" then
		local level = player:GetAttribute("Level")
		return typeof(level) == "number" and level >= need
	elseif kind == "near" then
		local root, npc = myRoot(), npcRootOf(condition.id or "")
		return root ~= nil and npc ~= nil and (root.Position - npc.Position).Magnitude <= (condition.dist or 25)
	elseif kind == "panel" then
		local panel = player:WaitForChild("PlayerGui"):FindFirstChild(condition.id or "")
		return panel ~= nil and panel:IsA("ScreenGui") and panel.Enabled
	elseif kind == "garap" then
		return GarapController.Active
	elseif kind == "sells" then
		local snap = snapshot()
		return snap ~= nil and typeof(snap.guideSells) == "number" and snap.guideSells >= need
	elseif kind == "rodgift" then
		-- Mas Joko's Terima Hadiah was taken (the server gives the rod and the bait once)
		local snap = snapshot()
		return snap ~= nil and snap.guide ~= nil and snap.guide.rodGift == true
	elseif kind == "ack" then
		return acked[condition.id or ""] == true
	elseif kind == "pondmode" then
		return GarapController.Active and GarapController.Mode == "pond"
	elseif kind == "ponds" then
		local snap = snapshot()
		return snap ~= nil and typeof(snap.ponds) == "table" and #snap.ponds >= need
	elseif kind == "fish" then
		local snap, total = snapshot(), 0
		local items = if snap then snap.items or {} else {}
		for itemId, count in items do
			if string.find(itemId, "@", 1, true) then -- fish items are written <fish>@<size>
				total += count
			end
		end
		return total >= need
	elseif kind == "quest" then
		local snap = snapshot()
		return snap ~= nil and snap.quests ~= nil and snap.quests.done[condition.id or ""] == true
	end
	warn(`[Guide] unknown condition kind {kind}`)
	return false
end

local function triggerHolds(trigger: Onboarding.Trigger): boolean
	local guide = guideData()
	if trigger.kind == "newPlayer" then
		return guide ~= nil and guide.fresh == true
	elseif trigger.kind == "level" then
		local level = player:GetAttribute("Level")
		return typeof(level) == "number" and level >= (trigger.n or 1)
	elseif trigger.kind == "done" then
		return trigger.id ~= nil and isFinished(trigger.id)
	end
	return false -- "manual" and anything unknown never starts by itself
end

local function beginTutorial(def: Onboarding.Tutorial, n: number, replay: boolean)
	local now = os.clock()
	if n == 0 then
		-- A new run (or a replay) asks again: the welcome modal is shown and must be acknowledged once more.
		for _, step in def.steps do
			if step.done.kind == "ack" then
				acked[step.done.id or ""] = nil
			end
		end
		welcomeShown = false
	end
	running = {
		def = def,
		n = n,
		replay = replay,
		stepAt = now,
		progressAt = now,
		introUntil = if n == 0 and def.intro then now + 4 else 0,
	}
	GuideController.Changed:Fire()
	refresh()
end

local function clearRing()
	if ring then
		ring:Destroy()
		ring = nil
	end
	ringFor = nil
end

local function endTutorial()
	running = nil
	lastFinish = os.clock()
	clearRing()
	CoachmarkController.Hide()
	GuideController.Changed:Fire()
	refresh()
end

-- Garap and Decor mode show their own hint line at the top: the tutorial bar goes just under it (GuideUI ignores the inset, they do not).
local function hintTop(): number
	local top = math.floor((Workspace.CurrentCamera :: Camera).ViewportSize.Y * 0.12)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	for _, name in { "GarapUI", "DecorUI" } do
		local other = playerGui and playerGui:FindFirstChild(name)
		local line = other and other:FindFirstChild("Hint")
		local shown = other ~= nil and other:IsA("ScreenGui") and other.Enabled
		if shown and line and line:IsA("GuiObject") and line.Visible then
			top = math.max(top, line.AbsolutePosition.Y + line.AbsoluteSize.Y + GuiService:GetGuiInset().Y + 6)
		end
	end
	return top
end

-- A button (or any GuiObject) by name in any open screen: the HUD, or a panel/bar such as Garap's "TillButton".
function findHighlight(name: string): GuiObject?
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end
	for _, screen in playerGui:GetChildren() do
		if screen:IsA("ScreenGui") and screen.Enabled and screen ~= gui then
			local found = screen:FindFirstChild(name, true)
			if found and found:IsA("GuiObject") and found.Visible and found.AbsoluteSize.X > 0 then
				return found
			end
		end
	end
	return nil
end

-- A modal or a big panel is open: the tutorial hint bar steps aside (only one instruction on screen at a time).
local function uiBusy(): boolean
	if UiKit.confirmOpen() then
		return true
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return false
	end
	for _, name in { "SettingsPanel", "GuidePanel", "BookPanel", "OrdersPanel", "RewardsPanel", "SocialPanel", "StorePanel", "SeedPicker", "TilePanel", "ShopPanel", "InventoryPanel" } do
		local screen = playerGui:FindFirstChild(name)
		if screen and screen:IsA("ScreenGui") and screen.Enabled then
			return true
		end
	end
	return false
end

-- The hint bar + ring for the running tutorial. A step with an action shows the coachmark instead (CoachmarkController).
function refreshTutorial()
	local current = running
	if not current then
		return
	end
	local steps = current.def.steps
	local stepDef = steps[math.min(current.n + 1, #steps)]
	local now = os.clock()
	local stuckFor = now - current.progressAt
	local text: string
	if now < current.introUntil and current.def.intro then
		text = Locale.t(current.def.intro)
	elseif stuckFor >= Onboarding.STUCK_TEXT then
		text = if stepDef.textStuck then Locale.t(stepDef.textStuck) else Locale.t(stepDef.text) .. Locale.t("tut.stuck_suffix")
	else
		text = Locale.t(stepDef.text)
	end
	-- T1 panen step: the wording and the target follow the phase (wait / harvest / sell), so "Tap Panen" never shows
	-- before the crop is ripe, and Pak Darmo is named only after the harvest is in the Tas (user, 16 Nov).
	local phase = if stepDef.id == "panen_jual" then t1Phase() else nil
	if phase == "wait" then
		text = Locale.t("tut.t1.s4_wait")
	elseif phase == "harvest" then
		text = Locale.t("tut.t1.s4_harvest")
	elseif phase == "sell" then
		text = Locale.t("tut.t1.s4_sell")
	end
	-- Waiting for a crop or walking to Pak Darmo: no coachmark (its dark overlay hides the bed and the arrow). The hint bar
	-- carries the text and the ground trail / bed arrow point the way (user, 16 Nov).
	if phase ~= nil then -- wait / harvest / sell (the T1 panen step)
		CoachmarkController.Hide()
		clearRing()
		GarapController.SetHintHidden(true)
		local spoken = say(`panen_{phase}`, stuckFor >= Onboarding.STUCK_TEXT) -- Mbok Minah says it: no text in the hint bar
		if spoken then
			-- No text anywhere, but still something to look at: glow on Panen when ripe, an arrow over Pak Darmo to sell.
			-- (block = false: no dark overlay, the bed and the way stay clear.)
			CoachmarkController.SetPaused(uiBusy())
			if phase == "harvest" then
				CoachmarkController.Show({
					mode = "button",
					text = nil,
					block = false,
					findButton = function(): GuiObject?
						return findHighlight("PanenButton")
					end,
				})
			elseif phase == "sell" then
				CoachmarkController.Show({
					mode = "ground",
					text = nil,
					block = false,
					npcPoint = function(): Vector3?
						local npc = npcRootOf("pak_darmo")
						return if npc then npc.Position + Vector3.new(0, 5, 0) else nil
					end,
				})
			end
		end
		hint.Visible = not spoken and not GarapController.Active
		hintText.Text = text
		return
	end
	-- Coachmark (CoachmarkController): ONE instruction per step. The hint bar is hidden while it shows, and the Garap hint
	-- line too. The welcome step (ack) keeps the modal instead.
	if stepDef.done.kind ~= "ack" then
		local highlight = stepDef.highlight
		local kind = stepDef.done.kind
		-- A land step (walk back home): the button glow waits until the player is in the land zone; the trail leads there.
		if stepDef.target and stepDef.target.land then
			local center, root = myLandCenter(), myRoot()
			local inside = center ~= nil and root ~= nil and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude <= (stepDef.arrive or 60)
			if not inside then
				highlight = nil
			end
		end
		local groundKind = kind == "tiles" or kind == "ponds" -- steps done by tapping the ground in Garap mode
		local onGround = groundKind and GarapController.Active
		-- Past the tilling / pond steps, Garap mode must be closed: its open state hides the bed pills the next step points at.
		if not (groundKind or kind == "pondmode") and GarapController.Active then
			GarapController.Stop()
		end
		local coachText = if onGround then Locale.t("tut.coach.ground") elseif stepDef.coach then Locale.t(stepDef.coach) else Locale.t(stepDef.text)
		if phase == "wait" then
			-- no ring on the Panen button while the crop grows: the bed arrow is the only pointer
			highlight = nil
			coachText = Locale.t("tut.coach.tunggu")
		elseif phase == "harvest" then
			coachText = Locale.t("tut.coach.panen_tap")
		elseif phase == "sell" then
			highlight = nil
			coachText = Locale.t("tut.coach.jual")
		end
		hint.Visible = false
		clearRing()
		GarapController.SetHintHidden(true)
		-- A panel or modal is open (seed picker, Atur, a confirm): the coachmark steps aside until it closes.
		CoachmarkController.SetPaused(uiBusy())
		-- Pak Darmo is pointed at ONLY in the sell phase (the crop is in the Tas), never while the crop is still growing.
	local npcId = if stepDef.target and (phase == nil or phase == "sell") then stepDef.target.npc else nil
		-- Mbok Minah says the instruction; the coachmark then shows no text at all (glow, ring and arrows only).
		local spoken = say(if onGround then `{stepDef.id}_ground` else stepDef.id, stuckFor >= Onboarding.STUCK_TEXT)
		CoachmarkController.Show({
			mode = if onGround then "ground" else "button",
			text = if spoken then nil else coachText,
			block = stepDef.block ~= false,
			findButton = if not onGround and highlight then function(): GuiObject? return findHighlight(highlight) end else nil,
			npcPoint = if npcId then function(): Vector3?
				local root = npcRootOf(npcId)
				return if root then root.Position + Vector3.new(0, 5, 0) else nil
			end else nil,
		})
		return
	end
	CoachmarkController.Hide()
	GarapController.SetHintHidden(false)

	-- A step that is a dialog of the intro (kind "ack"): T1Ghost speaks it in the dialog box, so no hint bar here.
	local spoken = say(stepDef.id, false)
	hintText.Text = text
	hint.Visible = not spoken and not uiBusy() -- one instruction at a time: a modal or Atur / Panduan on screen hides this line
	hint.Position = UDim2.new(0.5, 0, 0, hintTop())
	hintPad.PaddingRight = UDim.new(0, 14)

	-- Ring on a HUD button (created once per button, pulsed in RenderStepped).
	local wanted = stepDef.highlight
	ringStrong = stuckFor >= Onboarding.STUCK_STRONG
	if wanted ~= ringFor or (ring and not ring.Parent) then
		clearRing()
		if wanted then
			local button = findHighlight(wanted)
			if button then
				local frame = Instance.new("Frame")
				frame.Name = "GuideRing"
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.Position = UDim2.fromScale(0.5, 0.5)
				frame.Size = UDim2.new(1, 8, 1, 8)
				frame.BackgroundTransparency = 1
				frame.ZIndex = 50
				local round = Instance.new("UICorner")
				round.CornerRadius = UDim.new(0.5, 0)
				round.Parent = frame
				local line = Instance.new("UIStroke")
				line.Name = "Line"
				line.Color = UiKit.BAMBOO
				line.Thickness = 3
				line.Parent = frame
				-- A bobbing arrow on the side with room, so the eye finds the button even in a crowded menu.
				local view = (Workspace.CurrentCamera :: Camera).ViewportSize
				local center = button.AbsolutePosition + button.AbsoluteSize / 2
				local side = if center.Y < 110 then "below" elseif center.X > view.X * 0.8 then "left" else "above"
				local arrow = Instance.new("TextLabel")
				arrow.Name = "Arrow"
				arrow:SetAttribute("Side", side)
				arrow.BackgroundTransparency = 1
				arrow.Size = UDim2.fromOffset(30, 26)
				arrow.Font = UiKit.FONT
				arrow.TextSize = 26
				arrow.Text = if side == "above" then "▼" elseif side == "below" then "▲" else "▶"
				arrow.TextColor3 = Color3.fromRGB(255, 226, 120)
				arrow.ZIndex = 51
				local arrowLine = Instance.new("UIStroke")
				arrowLine.Color = OUTLINE
				arrowLine.Thickness = 2
				arrowLine.Parent = arrow
				arrow.Parent = frame
				frame.Parent = button
				ring, ringFor = frame, wanted
			end
		end
	end
end

local function autoStart(snap: any)
	local guide = snap.guide
	if running or not guide then
		return
	end
	local now = os.clock()
	if not firstSnapshotAt then
		firstSnapshotAt = now
	end
	if now - firstSnapshotAt < 2 then
		return -- let the HUD finish building
	end
	-- Resume the tutorial this save was in the middle of (no gap: the player left mid-way).
	local savedId = guide.step.id
	if savedId ~= "" and defById[savedId] and not isFinished(savedId) then
		beginTutorial(defById[savedId], guide.step.n, false)
		return
	end
	if lastFinish and now - lastFinish < Onboarding.GAP_SECONDS then
		return
	end
	for _, def in defs do
		if def.auto ~= false and not isFinished(def.id) and triggerHolds(def.trigger) then
			Net.Send("GuideEvent", "start", def.id)
			beginTutorial(def, 0, false)
			return
		end
	end
end

-- Moves the running tutorial forward over every step whose condition already holds.
local function advance()
	local current = running
	if not current then
		return
	end
	local steps, n, now = current.def.steps, current.n, os.clock()
	while n < #steps do
		local condition = steps[n + 1].done
		if (current.replay or condition.kind == "always") and now - current.stepAt < Onboarding.REPLAY_MIN_SECONDS then
			break
		end
		if not evalCondition(condition) then
			break
		end
		n += 1
		current.stepAt, current.progressAt = now, now
	end
	if n == current.n then
		return
	end
	current.n = n
	local finished = n >= #steps
	if not current.replay then
		Net.Send("GuideEvent", "step", current.def.id, n)
		if finished then
			closed[current.def.id] = "done"
		end
	end
	if finished then
		endTutorial()
	else
		refresh()
	end
end

-- The welcome modal of a step that waits for "ack" (T1 step 0). It has only Mulai (acks, step 0 completes); there is no way to
-- skip the tutorial. Opened once per run; never closes by itself.
local function showWelcome()
	local current = running
	if not current or welcomeShown or current.n ~= 0 then
		return
	end
	local stepDef = current.def.steps[1]
	if stepDef.done.kind ~= "ack" or not stepDef.modal then
		return
	end
	local id = stepDef.done.id or ""
	if acked[id] or UiKit.confirmOpen() then
		return
	end
	-- The intro cutscene (T1Ghost.client) plays first; the modal waits. The hold expires on its own
	-- (os.clock deadline), so a cutscene that dies can never leave the welcome modal blocked.
	local hold = player:GetAttribute("T1CutsceneUntil")
	if typeof(hold) == "number" and os.clock() < hold then
		return
	end
	welcomeShown = true
	if not current.replay then
		-- The intro cutscene is not playing (it was not needed, or it failed): the welcome step is acknowledged without a modal.
		-- The welcome step is simply acknowledged and the tutorial goes on.
		acked[id] = true
		advance()
		return
	end
	UiKit.confirm({
		title = Locale.t(stepDef.modal.title),
		body = Locale.t(stepDef.modal.body),
		confirmText = Locale.t("tut.start"),
		noCancel = true, -- Mulai is the only button: no Lewati, a tap outside does nothing
		confirmColor = Color3.fromRGB(96, 150, 70), -- Mulai: the main action, solid leaf green (UIUX_Spec)
		onConfirm = function()
			acked[id] = true
			advance()
		end,
	})
end

local function tutorialTick()
	local snap = snapshot()
	if not snap or not snap.guide then
		return
	end
	autoStart(snap)
	advance()
	showWelcome()
end

-- For Atur > Panduan.
function GuideController.IsRunning(): boolean
	return running ~= nil
end

function GuideController.List(): { { id: string, title: string, state: string } }
	local list = {}
	local guide = guideData()
	for _, def in defs do
		local state = "new"
		if closed[def.id] then
			state = closed[def.id]
		elseif guide and guide.done[def.id] then
			state = "done"
		elseif guide and guide.skipped[def.id] then
			state = "skipped"
		elseif running and running.def.id == def.id then
			state = "active"
		end
		table.insert(list, { id = def.id, title = def.title, state = state })
	end
	return list
end

-- Runs a tutorial again, with no save and no reward. False if another one is running.
function GuideController.Replay(id: string): boolean
	local def = defById[id]
	if running or not def then
		return false
	end
	Net.Send("GuideEvent", "replay", id)
	beginTutorial(def, 0, true)
	return true
end

function GuideController.Init()
	-- (The Studio-only test tutorial is not listed any more: the playtest build shows T1 only.)
	for _, def in Onboarding.TUTORIALS do
		table.insert(defs, def)
	end
	for _, def in defs do
		defById[def.id] = def
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "GuideUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -2 -- under the HUD and every panel
	gui:SetAttribute("NoScale", true) -- real pixels (UiKit.autoScale must not scale it)

	-- The parchment chip is the frame (UiKit.parchmentBox: rounded ends, bamboo skin); the text is a label on top of it.
	hint = Instance.new("Frame")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 0.12, 0) -- top of the screen, under the coin bar (not the middle)
	hint.Size = UDim2.new(0.4, 0, 0, 36) -- tutorial toast: at most 40 % of the width, 36 px tall
	hint.Visible = false
	hint.Parent = gui
	parchmentBox(hint, 22)
	hintText = Instance.new("TextLabel")
	hintText.Name = "Text"
	hintText.BackgroundTransparency = 1
	hintText.Size = UDim2.fromScale(1, 1)
	hintText.ZIndex = 2 -- above the parchment skin
	hintText.TextColor3 = UiKit.TEXT -- dark brown ink
	hintText.Font = Enum.Font.GothamBlack -- heavier weight so the ink reads on the parchment
	hintText.TextSize = 14
	hintText.TextWrapped = true
	hintText.Parent = hint
	hintPad = Instance.new("UIPadding")
	hintPad.PaddingLeft, hintPad.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
	hintPad.Parent = hintText

	gui.Parent = player:WaitForChild("PlayerGui")

	trailFolder = Instance.new("Folder")
	trailFolder.Name = "GuideTrail"
	trailFolder.Parent = Workspace
	for _ = 1, CHEVRONS do
		table.insert(chevrons, makeChevron())
	end
end

function GuideController.Start()
	State.Changed:Connect(function()
		tutorialTick()
		refresh()
	end)
	-- Beds change by attribute (growth, water) without a state sync: re-check a few times a second.
	task.spawn(function()
		local lastRoute = 0
		while true do
			tutorialTick()
			refresh()
			updateTutorialBedArrow() -- the T1 bed arrow follows the crop (wait -> harvest) without a state sync
			local goal = currentGoal()
			if goal and os.clock() - lastRoute >= REPATH_SECONDS then
				lastRoute = os.clock()
				computeRoute(goal)
			end
			task.wait(0.3)
		end
	end)
	RunService.RenderStepped:Connect(function()
		placeTrail()
		local frame = ring
		if frame and frame.Parent then
			local strong = ringStrong
			local pulse = (math.sin(os.clock() * (if strong then 7 else 4.5)) + 1) / 2
			local pad = (if strong then 14 else 10) + pulse * (if strong then 12 else 8)
			frame.Size = UDim2.new(1, pad, 1, pad)
			local arrow = frame:FindFirstChild("Arrow") :: TextLabel?
			if arrow then
				local bob = 2 + pulse * 7
				local side = arrow:GetAttribute("Side")
				if side == "above" then
					arrow.AnchorPoint, arrow.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 0, -bob)
				elseif side == "below" then
					arrow.AnchorPoint, arrow.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 1, bob)
				else
					arrow.AnchorPoint, arrow.Position = Vector2.new(1, 0.5), UDim2.new(0, -bob, 0.5, 0)
				end
			end
			local line = frame:FindFirstChild("Line") :: UIStroke?
			if line then
				line.Thickness = (if strong then 6 else 4) + pulse * 2
				line.Color = if strong then Color3.fromRGB(255, 226, 120) else UiKit.BAMBOO
				line.Transparency = 0.2 - pulse * 0.2
			end
		end
	end)
	refresh()
end

-- Used by the intro cutscene (T1Ghost.client): "Mulai Garap" = the welcome modal's Mulai. Returns false while the tutorial
-- is not at its welcome step yet (the caller retries).
function GuideController.AckWelcome(): boolean
	local current = running
	if not current or current.n ~= 0 then
		return false
	end
	local stepDef = current.def.steps[1]
	if stepDef.done.kind ~= "ack" then
		return false
	end
	acked[stepDef.done.id or ""] = true
	welcomeShown = true
	advance()
	return true
end

-- The running tutorial and its step number (steps done), or nil: for T1Ghost, which plays the dialogs of the "ack" steps.
function GuideController.Current(): (string?, number)
	local current = running
	if not current or current.replay then
		return nil, 0
	end
	return current.def.id, current.n
end

-- Acknowledges the "ack" step `id` of the running tutorial (the player pressed Next on its last line). False if that step
-- is not the one running.
function GuideController.AckStep(id: string): boolean
	local current = running
	if not current then
		return false
	end
	local stepDef = current.def.steps[current.n + 1]
	if not stepDef or stepDef.done.kind ~= "ack" or stepDef.done.id ~= id then
		return false
	end
	acked[id] = true
	advance()
	return true
end

-- Used by T1Ghost.client: see instructionSink above. Pass nil to go back to the text GUI.
function GuideController.SetInstructionSink(sink: ((key: string, stuck: boolean) -> boolean)?)
	instructionSink = sink
end

return GuideController
