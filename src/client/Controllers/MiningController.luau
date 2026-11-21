--!strict
-- Client side of Nambang + Crafting (Bab 8.1 / 8.2): tombol Pukul di dekat node, ritme
-- lingkaran mengecil (tap pas = Critical), panel Meja Crafting (buat x1 / x10), dan
-- efek pukul (suara + partikel) dari server. Server yang memutuskan semuanya; ini presentasi + input.
--
-- UI: ScreenGui "MiningUI" > "AksiButton" (Pukul, tepi kanan) + "Ring" (ritme) + tombol "Craft".
-- Panel craft: UiKit.panel "MineCraft" (daftar resep + Buat + x10).

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Mining = require(ReplicatedStorage.Shared.Config.Mining)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.Parent.UiKit)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local MiningController = {}

local REACH = 10 -- studs ke node agar tombol tampil (petunjuk client; server cek Mining.REACH)
local SWING = 1.4 -- detik lingkaran mengecil per pukulan
local START_D = 220 -- px diameter awal lingkaran luar
local END_D = 40 -- px diameter akhir lingkaran luar
local TARGET_D = 100 -- px diameter zona hijau: tap saat lingkaran luar masuk zona = Critical

local states: { [string]: { hits: number, readyAt: number } } = {}

local aksiButton: TextButton? = nil
local ringFrame: Frame? = nil
local ringOuter: Frame? = nil
local nodeLabel: TextLabel? = nil
local panel: UiKit.Panel? = nil

local activeNode: string? = nil -- node yang sedang dipukul (ritme jalan)
local ringT = 0 -- 0..1 progres pukulan ini
local ringing = false

-- UI --------------------------------------------------------------------------

local function fmtCountdown(readyAt: number): string
	local left = math.max(readyAt - os.time(), 0)
	return string.format("%d:%02d", math.floor(left / 60), left % 60)
end

local function nodePart(nodeId: string): BasePart?
	for _, part in CollectionService:GetTagged("MiningNode") do
		if part:IsA("BasePart") and part:GetAttribute("NodeId") == nodeId then
			return part
		end
	end
	return nil
end

local function nearestNode(): (string?, BasePart?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil, nil
	end
	local bestId: string? = nil
	local bestPart: BasePart? = nil
	local bestDistance = REACH
	for _, part in CollectionService:GetTagged("MiningNode") do
		if part:IsA("BasePart") then
			local nodeId = part:GetAttribute("NodeId")
			if typeof(nodeId) == "string" and Mining.byNode[nodeId] then
				local distance = (part.Position - root.Position).Magnitude
				if distance <= bestDistance then
					bestDistance, bestId, bestPart = distance, nodeId, part
				end
			end
		end
	end
	return bestId, bestPart
end

local function nodeReady(nodeId: string): boolean
	local entry = states[nodeId]
	if not entry then
		return true -- state belum datang: anggap siap, server yang menolak kalau tidak
	end
	if entry.readyAt > 0 and os.time() >= entry.readyAt then
		return true
	end
	return entry.hits > 0
end

-- Ritme ------------------------------------------------------------------------

local function stopRing()
	ringing = false
	activeNode = nil
	if ringFrame then
		ringFrame.Visible = false
	end
end

local function startRing(nodeId: string)
	activeNode = nodeId
	ringT = 0
	ringing = true
	if ringFrame then
		ringFrame.Visible = true
	end
	if nodeLabel then
		nodeLabel.Text = Locale.t(`mine.node.{nodeId}`)
	end
end

local function ringD(): number
	return START_D - ringT * (START_D - END_D)
end

local function sendHit(nodeId: string, crit: boolean)
	Net.Send("MineHit", nodeId, crit)
end

local function tapPukul()
	local nodeId = activeNode
	if not nodeId or not ringing or not nodeReady(nodeId) then
		return
	end
	local crit = ringD() <= TARGET_D
	sendHit(nodeId, crit)
	ringT = 0 -- pukulan berikutnya mulai dari lingkaran penuh
end

-- Efek pukul (server -> client): suara woody + semburan partikel (besar saat Critical).

local function burst(part: BasePart, big: boolean)
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, part.Size.Y / 2, 0)
	attachment.Parent = part
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Emitting = false
	emitter.Speed = NumberRange.new(if big then 10 else 6, if big then 16 else 10)
	emitter.Lifetime = NumberRange.new(0.3, 0.7)
	emitter.Size = NumberSequence.new(if big then 0.7 else 0.4)
	emitter.Transparency = NumberSequence.new(0.1, 1)
	emitter.Color = ColorSequence.new(Color3.fromRGB(214, 186, 130))
	emitter.Parent = attachment
	emitter:Emit(if big then 24 else 8)
	Debris:AddItem(attachment, 2)
end

-- Craft --------------------------------------------------------------------------

local function matsText(recipe: Mining.Recipe, items: { [string]: number }): string
	local bits = {}
	for _, input in recipe.inputs do
		local have = items[input.id] or 0
		table.insert(bits, `{input.count} {Locale.t(`item.{input.id}`)} ({have})`)
	end
	if recipe.unlockLevel > 1 then
		table.insert(bits, `Lv {recipe.unlockLevel}`)
	end
	return table.concat(bits, " + ")
end

local function canCraft(recipe: Mining.Recipe, items: { [string]: number }, times: number): boolean
	for _, input in recipe.inputs do
		if (items[input.id] or 0) < input.count * times then
			return false
		end
	end
	return true
end

local function rebuildCraft()
	local list = panel and panel.list
	if not list then
		return
	end
	UiKit.clear(list)
	local snap = State.current :: any
	local items = (snap and snap.items) or {}
	local order = 0
	for _, recipe in Mining.RECIPES do
		order += 1
		local text = Locale.t(`item.{recipe.itemId}`)
		local sub = matsText(recipe, items)
		local ok = canCraft(recipe, items, 1)
		local ok10 = canCraft(recipe, items, 10)
		UiKit.row(list, order, text, sub, Locale.t("mine.make"), ok, function()
			Net.Send("MineCraft", recipe.id, 1)
		end, if ok10 then "x10" else nil, if ok10
			then function()
				Net.Send("MineCraft", recipe.id, 10)
			end
			else nil)
	end
end

-- Build --------------------------------------------------------------------------

local function buildUi()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MiningUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = playerGui

	local aksi = UiKit.button(gui, "MineAksiButton", Locale.t("prompt.mine"), UiKit.BUTTON)
	aksi.AnchorPoint = Vector2.new(1, 1)
	aksi.Position = UDim2.new(1, -24, 1, -200)
	aksi.Size = UDim2.fromOffset(104, 104)
	aksi.TextSize = 22
	aksi.Visible = false
	aksi.Activated:Connect(tapPukul)
	aksiButton = aksi

	local craft = UiKit.button(gui, "CraftButton", Locale.t("mine.craft"), UiKit.BUTTON_MUTED)
	craft.AnchorPoint = Vector2.new(0, 1)
	craft.Position = UDim2.new(0, 24, 1, -200)
	craft.Size = UDim2.fromOffset(104, 48)
	craft.TextSize = 16
	craft.Visible = true
	craft.Activated:Connect(function()
		if panel then
			panel.gui.Enabled = not panel.gui.Enabled
			if panel.gui.Enabled then
				rebuildCraft()
			end
		end
	end)

	-- Lingkaran ritme: lingkaran luar mengecil ke arah lingkaran target (tetap).
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 1)
	ring.Position = UDim2.new(0.5, 0, 1, -230)
	ring.Size = UDim2.fromOffset(START_D + 48, START_D + 88)
	ring.BackgroundTransparency = 1
	ring.Visible = false
	ring.Parent = gui
	ringFrame = ring

	local target = Instance.new("Frame")
	target.Name = "Target"
	target.AnchorPoint = Vector2.new(0.5, 0.5)
	target.Position = UDim2.fromScale(0.5, 0.5)
	target.Size = UDim2.fromOffset(TARGET_D, TARGET_D)
	target.BackgroundTransparency = 0.4
	target.BackgroundColor3 = Color3.fromRGB(120, 204, 96)
	target.Parent = ring
	local targetRound = Instance.new("UICorner")
	targetRound.CornerRadius = UDim.new(1, 0)
	targetRound.Parent = target

	local outer = Instance.new("Frame")
	outer.Name = "Outer"
	outer.AnchorPoint = Vector2.new(0.5, 0.5)
	outer.Position = UDim2.fromScale(0.5, 0.5)
	outer.Size = UDim2.fromOffset(START_D, START_D)
	outer.BackgroundTransparency = 0.2
	outer.BackgroundColor3 = Color3.fromRGB(255, 226, 120)
	outer.Parent = ring
	local outerRound = Instance.new("UICorner")
	outerRound.CornerRadius = UDim.new(1, 0)
	outerRound.Parent = outer
	ringOuter = outer

	local name = Instance.new("TextLabel")
	name.Name = "NodeName"
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.TextColor3 = UiKit.CREAM
	name.Size = UDim2.new(1, 0, 0, 24)
	name.Position = UDim2.new(0, 0, 1, -28)
	name.Text = ""
	name.Parent = ring
	nodeLabel = name
end

local function refreshAksi()
	if not aksiButton then
		return
	end
	local nodeId, _part = nearestNode()
	if nodeId == nil then
		aksiButton.Visible = false
		stopRing()
		return
	end
	if not nodeReady(nodeId) then
		-- Node habis (respawn per-player): tombol tampil sebagai hitungan mundur, tidak bisa dipukul.
		local entry = states[nodeId]
		aksiButton.Text = if entry then fmtCountdown(entry.readyAt) else Locale.t("prompt.mine")
		aksiButton.Visible = true
		if activeNode == nodeId then
			stopRing()
		end
		return
	end
	aksiButton.Text = Locale.t("prompt.mine")
	aksiButton.Visible = true
	if activeNode ~= nodeId then
		startRing(nodeId)
	end
end

function MiningController.Init()
	buildUi()
	panel = UiKit.panel("MineCraft", Locale.t("mine.craft_title"), function()
		if panel then
			panel.gui.Enabled = false
		end
	end)
end

function MiningController.Start()
	Net.Listen("MineState", function(payload: any)
		local nodes = payload and payload.nodes
		if typeof(nodes) == "table" then
			states = nodes
		end
		-- Node habis di tengah ritme: berhenti sebelum hit berikutnya terkirim (anti-spam "habis").
		if activeNode and not nodeReady(activeNode) then
			stopRing()
		end
		if panel and panel.gui.Enabled then
			rebuildCraft()
		end
	end)

	Net.Listen("MineFx", function(nodeId: any, crit: any)
		if typeof(nodeId) ~= "string" then
			return
		end
		local part = nodePart(nodeId)
		local isCrit = crit == true
		if part then
			Sfx.play("place_item", part, if isCrit then 0.2 else 0.05)
			burst(part, isCrit)
		else
			Sfx.play("place_item", nil, if isCrit then 0.2 else 0.05)
		end
	end)

	State.Changed:Connect(function()
		if panel and panel.gui.Enabled then
			rebuildCraft()
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if not ringing or activeNode == nil then
			return
		end
		ringT += dt / SWING
		if ringT >= 1 then
			-- Ritme selesai tanpa tap: tetap dapat bahan (normal). Tanpa fail.
			sendHit(activeNode, false)
			ringT = 0
		end
		local outer = ringOuter
		if outer then
			local diameter = math.max(ringD(), END_D)
			outer.Size = UDim2.fromOffset(diameter, diameter)
		end
	end)

	task.spawn(function()
		while true do
			refreshAksi()
			task.wait(0.25)
		end
	end)
end

return MiningController
