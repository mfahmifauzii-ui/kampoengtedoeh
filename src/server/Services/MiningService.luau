--!strict
-- Nambang + Crafting (Kampoeng_Tedoeh_v7.3 Bab 8.1 / 8.2, LOCKED).
-- 6 node per-player (instanced): tiap player punya sisa pukulan + respawn sendiri, jadi tidak
-- rebutan walau part nodenya dipakai bersama. 1 node = 4 pukulan: biasa +1 bahan, Critical +2.
-- Player selalu dapat bahan tiap pukulan yang diterima (tidak ada fail). Node habis -> respawn 4 menit.
-- Ritme (lingkaran mengecil) jalan di client (MiningController); server memvalidasi semua yang
-- penting: gate level, jarak, sisa pukulan, jeda antar pukulan, bahan craft.
-- Agenda "Nambang 10 bahan" (Config/Quests DAILY event "mine") terhitung dari tiap pukulan di sini.
-- XP per pukulan = 0: v7.3 tidak memberi angka, final ikut playtest Bab 17.8.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CollectionService = game:GetService("CollectionService")

local Buffs = require(ReplicatedStorage.Shared.Config.Buffs)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Mining = require(ReplicatedStorage.Shared.Config.Mining)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local QuestService = require(script.Parent.QuestService)

local NODE_TAG = "MiningNode"
local RATE = { rate = 6, burst = 12 }

local MiningService = {}

local parts: { [string]: BasePart } = {} -- nodeId -> part (bersama), state-nya per-player di data
local lastHit: { [Player]: number } = {}

-- Node state ----------------------------------------------------------------

local function nodeState(data: Types.PlayerData, nodeId: string): Types.MiningNodeState
	local entry = data.mining.nodes[nodeId]
	if not entry then
		entry = { hits = Mining.HITS_PER_NODE, readyAt = 0 }
		data.mining.nodes[nodeId] = entry
	end
	return entry
end

-- Siap dipukul? Node yang waktu respawn-nya lewat diisi ulang penuh.
local function ensureReady(data: Types.PlayerData, nodeId: string, now: number): Types.MiningNodeState
	local entry = nodeState(data, nodeId)
	if entry.readyAt > 0 and now >= entry.readyAt then
		entry.hits = Mining.HITS_PER_NODE
		entry.readyAt = 0
	end
	return entry
end

function MiningService.StateFor(data: Types.PlayerData): { [string]: Types.MiningNodeState }
	local now = os.time()
	local out = {}
	for _, node in Mining.NODES do
		local entry = ensureReady(data, node.id, now)
		out[node.id] = { hits = entry.hits, readyAt = entry.readyAt }
	end
	return out
end

local function pushState(player: Player)
	local data = DataService.Get(player)
	if data then
		Net.Fire("MineState", player, { nodes = MiningService.StateFor(data) })
	end
end

-- Kapak: bonus bahan PER NODE TOTAL, bukan per pukulan (Config/Farm TOOLS bonusBahan). Kapak
-- terbaik yang dipunyai menang, diberikan SEKALI saat node habis (lihat onHit: blok `entry.hits <= 0`).
-- Cara hitung: 1 node = 4 pukulan x NORMAL_YIELD(1) = 4 bahan; + axeBonus Sekali. Contoh: 4x normal +
-- Kapak Besi (bonusBahan 1) = 5 bahan, bukan 8. Critical hanya mengganti yield pukulan itu (2).
local function axeBonus(data: Types.PlayerData): number
	local best = 0
	for toolId, owned in data.tools do
		if owned == true then
			local tool = Farm.TOOLS[toolId]
			if tool and toolId:sub(1, 6) == "kapak_" and typeof(tool.bonusBahan) == "number" then
				best = math.max(best, tool.bonusBahan)
			end
		end
	end
	return best
end

local function characterRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Requests ------------------------------------------------------------------

local function onHit(player: Player, nodeId: any, crit: any)
	if typeof(nodeId) ~= "string" then
		return
	end
	local node = Mining.byNode[nodeId]
	local part = parts[nodeId]
	local data = DataService.Get(player)
	local root = characterRoot(player)
	if not node or not part or not data or not root then
		return
	end
	if data.level < Mining.FOREST_UNLOCK then
		Net.Fire("Notify", player, "fish.locked", { level = Mining.FOREST_UNLOCK })
		return
	end
	if data.level < node.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = node.unlockLevel })
		return
	end
	if (part.Position - root.Position).Magnitude > Mining.REACH then
		return
	end
	local now = os.clock()
	if lastHit[player] and now - lastHit[player] < Mining.HIT_MIN_INTERVAL then
		return -- terlalu cepat untuk pukulan sungguhan
	end
	lastHit[player] = now

	local entry = ensureReady(data, nodeId, os.time())
	if entry.hits <= 0 then
		Net.Fire("Notify", player, "mine.depleted")
		pushState(player)
		return
	end

	local isCrit = crit == true
	local gained = if isCrit then Mining.CRIT_YIELD else Mining.NORMAL_YIELD
	-- Buff Tebang/Tukang (Bab 9.4): +1 bahan saat Critical. Tebang hanya Kayu, Tukang non-Kayu.
	if isCrit then
		local nowBuff = os.time()
		local buffed = (node.itemId == "kayu" and Buffs.active(data.buff, "tebang", nowBuff))
			or (node.itemId ~= "kayu" and Buffs.active(data.buff, "tukang", nowBuff))
		if buffed then
			gained += 1
		end
	end
	if not InventoryService.Add(player, node.itemId, gained) then
		return -- item tak dikenal: pukulan tidak dihitung (server tetap sumber kebenaran)
	end
	entry.hits -= 1
	if entry.hits <= 0 then
		entry.readyAt = os.time() + Mining.RESPAWN_SECONDS
		local bonus = axeBonus(data)
		if bonus > 0 then
			if InventoryService.Add(player, node.itemId, bonus) then
				gained += bonus
			end
		end
	end
	QuestService.Report(player, "mine", gained)
	Net.Fire(
		"Notify",
		player,
		if isCrit then "mine.crit" else "mine.done",
		{ n = gained, item = `item.{node.itemId}` }
	)
	Net.Fire("MineFx", player, nodeId, isCrit)
	pushState(player)
end

local function onCraft(player: Player, recipeId: any, times: any)
	if typeof(recipeId) ~= "string" or (times ~= 1 and times ~= 10) then
		return
	end
	local recipe = Mining.byRecipe[recipeId]
	local data = DataService.Get(player)
	if not recipe or not data then
		return
	end
	if data.level < recipe.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = recipe.unlockLevel })
		return
	end
	for _, input in recipe.inputs do
		if InventoryService.Count(player, input.id) < input.count * (times :: number) then
			Net.Fire("Notify", player, "mine.no_mats")
			return
		end
	end
	-- Pre-check di atas menjamin semua bahan cukup; tidak ada yield di antara cek dan ambil.
	for _, input in recipe.inputs do
		InventoryService.Remove(player, input.id, input.count * (times :: number))
	end
	if not InventoryService.Add(player, recipe.itemId, times :: number) then
		return
	end
	Net.Fire("Notify", player, "mine.crafted", { n = times, item = `item.{recipe.itemId}` })
end

-- Node parts ------------------------------------------------------------------
-- Part node dibaca dari Workspace (map Studio, JANGAN diubah dari sini): folder "Mining" mana pun
-- yang punya part dengan attribute NodeId = salah satu Mining.NODES. Kalau tidak ada sama sekali
-- (map lama), placeholder dibangun di sudut hutan supaya playtest tetap jalan.

local PLACEHOLDER_COLORS: { [string]: Color3 } = {
	pohon = Color3.fromRGB(96, 72, 52),
	rumpun_bambu = Color3.fromRGB(86, 168, 72),
	batu_kali = Color3.fromRGB(150, 146, 138),
	tebing_tanah = Color3.fromRGB(176, 136, 94),
	pinggir_kali = Color3.fromRGB(208, 180, 126),
	pohon_aren = Color3.fromRGB(70, 120, 52),
}

local function registerPart(part: BasePart, nodeId: string)
	part:SetAttribute("NodeId", nodeId)
	CollectionService:AddTag(part, NODE_TAG)
	parts[nodeId] = part
end

local function findStudioNodes()
	for _, folder in Workspace:GetChildren() do
		if folder.Name == "Mining" then
			for _, child in folder:GetDescendants() do
				if child:IsA("BasePart") then
					local nodeId = child:GetAttribute("NodeId")
					if typeof(nodeId) == "string" and Mining.byNode[nodeId] and parts[nodeId] == nil then
						registerPart(child, nodeId)
					end
				end
			end
		end
	end
end

local function groundY(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	local hit = Workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), params)
	return if hit then hit.Position.Y else 2
end

local function buildPlaceholders()
	local folder = Instance.new("Folder")
	folder.Name = "Mining"
	-- DEV ONLY: sudut hutan (pojok map, di luar jalan dan lahan). Fallback bila map Studio belum punya
	-- 6 part Mining + NodeId. HAPUS SEBELUM RILIS bila Hutan Nambang asli sudah ada (lihat Roadmap §6).
	local baseX, baseZ = 268, 268
	for index, node in Mining.NODES do
		local x = baseX + ((index - 1) % 3) * 12
		local z = baseZ + math.floor((index - 1) / 3) * 12
		local part = Instance.new("Part")
		part.Name = `Node_{node.id}`
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(4, 3, 4)
		part.Position = Vector3.new(x, groundY(x, z) + 1.5, z)
		part.Color = PLACEHOLDER_COLORS[node.id] or Color3.fromRGB(150, 146, 138)
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = folder
		registerPart(part, node.id)
	end
	folder.Parent = Workspace
end

function MiningService.Init()
	findStudioNodes()
	local missing = false
	for _, node in Mining.NODES do
		if parts[node.id] == nil then
			missing = true
			break
		end
	end
	if missing then
		buildPlaceholders()
	end
end

function MiningService.Start()
	DataService.Loaded:Connect(pushState)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastHit[player] = nil
	end)
	Net.On("MineHit", onHit, RATE)
	Net.On("MineCraft", onCraft, RATE)
end

return MiningService
