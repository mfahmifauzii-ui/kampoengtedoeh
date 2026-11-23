--!strict
-- Bubu (GDD 6.6, R2.1): place a trap in the river, come back after 6 hours, collect the catch. Progress is wall-clock (no
-- instant finish, offline collect: the record stays in the save). Placing reports "bubu_place" (quest M8 step 1).
-- R2.1b (2026-11-23): a bubu is a visible post in the river with a label "belum siap" / "SIAP!". Buy at Pak Udin, place and
-- collect from the Aksi button (BubuController). The post is rebuilt from the saved position on join.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Bubu = require(ReplicatedStorage.Shared.Config.Bubu)
local Fish = require(ReplicatedStorage.Shared.Config.Fish)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local QuestService = require(script.Parent.QuestService)

local BubuService = {}

local SPOT_TAG = "FishingSpot"
local RIVER = { sungai_lahan = true, sungai = true }
local FOLDER = "BubuMarkers"

-- The river spot the player stands next to, or nil.
local function riverSpotNear(player: Player): (BasePart?, string?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil, nil
	end
	for _, spot in CollectionService:GetTagged(SPOT_TAG) do
		local location = spot:GetAttribute("Location")
		if spot:IsA("BasePart") and typeof(location) == "string" and RIVER[location] and (spot.Position - root.Position).Magnitude <= Bubu.PLACE_DISTANCE then
			return spot, location
		end
	end
	return nil, nil
end

-- Fish that a bubu of this type catches: the Sungai Lahan fish of the type's rarities.
local function pool(rarities: { string }): { string }
	local ids = {}
	for _, fish in Fish.list do
		if table.find(rarities, fish.rarity) and table.find(fish.locations, "sungai_lahan") then
			table.insert(ids, fish.id)
		end
	end
	return ids
end

-- Markers: one post per placed bubu, named Bubu_<userId>_<uid>. Only the server makes them (not saved; rebuilt from data).
local function markerFolder(): Folder
	local folder = Workspace:FindFirstChild(FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = Workspace
	end
	return folder :: Folder
end

local function markerName(player: Player, uid: number): string
	return `Bubu_{player.UserId}_{uid}`
end

local function destroyMarker(player: Player, uid: number)
	local folder = Workspace:FindFirstChild(FOLDER)
	local part = folder and folder:FindFirstChild(markerName(player, uid))
	if part then
		part:Destroy()
	end
end

local function clearMarkers(player: Player)
	local folder = Workspace:FindFirstChild(FOLDER)
	if folder then
		local prefix = `Bubu_{player.UserId}_`
		for _, child in folder:GetChildren() do
			if string.sub(child.Name, 1, #prefix) == prefix then
				child:Destroy()
			end
		end
	end
end

local function setMarker(player: Player, entry: { uid: number, pos: { number }? }, ready: boolean)
	if not entry.pos then
		return -- saved before R2.1b: no position, no post (the bubu still works; the save keeps it)
	end
	local folder = markerFolder()
	local part = folder:FindFirstChild(markerName(player, entry.uid))
	if not part then
		local post = Instance.new("Part")
		post.Name = markerName(player, entry.uid)
		post.Anchored = true
		post.CanCollide = false
		post.CanQuery = false
		post.CanTouch = false
		post.Size = Vector3.new(1.2, 2.2, 1.2)
		post.Color = Color3.fromRGB(150, 118, 70)
		post.Material = Enum.Material.Wood
		post.CFrame = CFrame.new(entry.pos[1], entry.pos[2] + 1.1, entry.pos[3])
		post.Parent = folder
		local gui = Instance.new("BillboardGui")
		gui.Name = "Label"
		gui.Size = UDim2.fromOffset(170, 30)
		gui.StudsOffset = Vector3.new(0, 2, 0)
		gui.AlwaysOnTop = true
		gui.Parent = post
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = gui
		part = post
	end
	local label = part:FindFirstChild("Label", true)
	local text = label and label:FindFirstChild("Text") :: TextLabel?
	if text then
		-- Siap = leaf green with white text; waiting = tan with dark text (the state is visible without reading).
		text.Text = if ready then Locale.t("bubu.marker_ready") else Locale.t("bubu.marker_wait")
		text.BackgroundColor3 = if ready then Color3.fromRGB(112, 160, 70) else Color3.fromRGB(206, 196, 176)
		text.TextColor3 = if ready then Color3.new(1, 1, 1) else Color3.fromRGB(60, 45, 30)
		text.BackgroundTransparency = 0.1
	end
end

local function refreshMarkers(player: Player, data: any)
	local now = os.time()
	for _, entry in data.bubu.list do
		setMarker(player, entry, Bubu.isReady(entry.placedAt, now))
	end
end

-- Wake the label and the Ambil button when the 6 hours run out (no need to rejoin).
local function scheduleReady(player: Player, placedAt: number)
	local wait = math.max(1, placedAt + Bubu.HOURS * 3600 - os.time() + 1)
	task.delay(wait, function()
		local data = DataService.Get(player)
		if player.Parent and data then
			refreshMarkers(player, data)
			InventoryService.Sync(player)
		end
	end)
end

function BubuService.Place(player: Player, kind: any): string
	local data = DataService.Get(player)
	local def = if typeof(kind) == "string" then Bubu.TYPES[kind] else nil
	if not data or not def then
		return "jenis tidak dikenal"
	end
	if #data.bubu.list >= Bubu.MAX then
		return "maks 3 bubu"
	end
	if (data.inventory[def.item] or 0) < 1 then
		return "tidak punya bubu"
	end
	local spot, location = riverSpotNear(player)
	if not spot or not location then
		return "pasang di sungai dekat titik mancing"
	end
	InventoryService.Remove(player, def.item, 1)
	local uid = data.bubu.nextUid
	data.bubu.nextUid += 1
	local pos = { spot.Position.X, spot.Position.Y, spot.Position.Z }
	local entry = { uid = uid, kind = kind, spot = location, placedAt = os.time(), pos = pos }
	table.insert(data.bubu.list, entry)
	setMarker(player, entry, false)
	scheduleReady(player, entry.placedAt)
	InventoryService.Sync(player)
	QuestService.Report(player, "bubu_place", 1) -- M8 step 1
	return "terpasang"
end

-- Collect a ready bubu. Not ready = nothing happens (no instant finish). Works offline too: no distance check here
-- (the Ambil button only shows near the post).
function BubuService.Collect(player: Player, uid: any): string
	local data = DataService.Get(player)
	if not data or typeof(uid) ~= "number" then
		return "tidak ada"
	end
	for index, entry in data.bubu.list do
		if entry.uid == uid then
			local def = Bubu.TYPES[entry.kind]
			if not Bubu.isReady(entry.placedAt, os.time()) then
				return "belum siap"
			end
			local ids = pool(def.fishRarities)
			local count = math.random(def.countMin, def.countMax)
			local caught = 0
			for _ = 1, count do
				if #ids > 0 then
					local fishId = ids[math.random(1, #ids)]
					InventoryService.Add(player, `{fishId}@S`, 1)
					caught += 1
				end
			end
			table.remove(data.bubu.list, index)
			destroyMarker(player, uid)
			InventoryService.Sync(player)
			return `diambil {caught}`
		end
	end
	return "tidak ada"
end

-- DEV (K-64): "!tumbuh" also makes ready bubu ready (the wall clock is moved back), so a test does not wait 6 hours.
function BubuService.DevFinishAll(player: Player)
	local data = DataService.Get(player)
	if data then
		for _, entry in data.bubu.list do
			entry.placedAt = os.time() - Bubu.HOURS * 3600
		end
		refreshMarkers(player, data)
		InventoryService.Sync(player)
	end
end

function BubuService.Start()
	Net.On("BubuPlace", function(player: Player, kind: any)
		local result = BubuService.Place(player, kind)
		Net.Fire("Notify", player, "bubu.result", { text = result })
	end, { rate = 2, burst = 4 })
	Net.On("BubuCollect", function(player: Player, uid: any)
		local result = BubuService.Collect(player, uid)
		Net.Fire("Notify", player, "bubu.result", { text = result })
	end, { rate = 2, burst = 4 })

	-- Posts for bubu already in the save (join, or a server that started with players in it).
	local function restore(player: Player, data: any)
		refreshMarkers(player, data)
		for _, entry in data.bubu.list do
			if not Bubu.isReady(entry.placedAt, os.time()) then
				scheduleReady(player, entry.placedAt)
			end
		end
	end
	DataService.Loaded:Connect(restore)
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			restore(player, data)
		end
	end
	Players.PlayerRemoving:Connect(clearMarkers)
end

return BubuService
