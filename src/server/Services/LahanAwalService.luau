--!strict
-- Objek awal lahan (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 3.4): ilalang, semak, batu, tunggul.
-- The objects are parts in the plot's "LahanAwal" folder, with a ClickDetector each. A tap is counted on the server per
-- player; when the count reaches the object's taps, its bit is cleared in PlayerData and its part is removed.
-- Clearing never costs anything and nothing blocks placement: the parts have no collision (Prinsip #8).
-- Materials (Jerami, Kayu, Bambu, Batu) are not items in the game yet, so clearing gives no reward yet (TODO T-26).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LahanAwal = require(ReplicatedStorage.Shared.Config.LahanAwal)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local PlotService = require(script.Parent.PlotService)
local Net = require(ReplicatedStorage.Shared.Modules.Net)

local FOLDER_NAME = "LahanAwal"

-- The part of PlayerData.land this service reads and writes.
type LandData = {
	chunks: { [string]: boolean },
	lahanAwal: { lo: number, hi: number },
	chunkLahan: { [string]: number },
}

-- Look and size of each object kind (simple placeholder shapes until the real models exist).
local LOOK = {
	ilalang = { size = Vector3.new(1.6, 1.6, 1.6), color = Color3.fromRGB(122, 150, 66) },
	semak = { size = Vector3.new(2.6, 2.0, 2.6), color = Color3.fromRGB(70, 110, 48) },
	batu = { size = Vector3.new(1.8, 1.1, 1.6), color = Color3.fromRGB(140, 136, 128) },
	tunggul = { size = Vector3.new(1.6, 1.0, 1.6), color = Color3.fromRGB(110, 78, 50) },
}

local LahanAwalService = {}

-- Taps counted so far per player per object key (memory only: a rejoin starts the count again).
local hits: { [Player]: { [string]: number } } = {}

-- Object keys: "s<i>" = starting object i (bit i of land.lahanAwal); "c<ix>,<iz>:<k>" = object k of a bought chunk.
local function resolve(key: string): (LahanAwal.Object?, string?)
	local i = string.match(key, "^s(%d+)$")
	if i then
		return LahanAwal.START_OBJECTS[tonumber(i) :: number], nil
	end
	local ix, iz, k = string.match(key, "^c(%-?%d+),(%-?%d+):(%d+)$")
	if ix and iz and k then
		local list = LahanAwal.chunkObjects(tonumber(ix) :: number, tonumber(iz) :: number)
		return list[tonumber(k) :: number], `{ix},{iz}`
	end
	return nil, nil
end

-- Bits: starting objects use two 32-bit halves (1..32 in lo, 33..64 in hi). A set bit = the object is still there.
local function startPresent(land: LandData, i: number): boolean
	if i <= 32 then
		return bit32.extract(land.lahanAwal.lo, i - 1) == 1
	end
	return bit32.extract(land.lahanAwal.hi, i - 33) == 1
end

local function clearStart(land: LandData, i: number)
	if i <= 32 then
		land.lahanAwal.lo = bit32.replace(land.lahanAwal.lo, 0, i - 1)
	else
		land.lahanAwal.hi = bit32.replace(land.lahanAwal.hi, 0, i - 33)
	end
end

local function startCleared(land: LandData): boolean
	return land.lahanAwal.lo == 0 and land.lahanAwal.hi == 0
end

local function chunkBits(land: LandData, chunkKey: string): number
	return land.chunkLahan[chunkKey] or LahanAwal.CHUNK_FULL_BITS
end

local function spawn(folder: Folder, origin: BasePart, obj: LahanAwal.Object, key: string)
	local look = LOOK[obj.kind]
	local part = Instance.new("Part")
	part.Name = key
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = look.size
	part.Color = look.color
	part.Material = Enum.Material.Grass
	part.CFrame = origin.CFrame * CFrame.new(obj.x, look.size.Y / 2, obj.z)
	part:SetAttribute("Kind", obj.kind)

	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = LahanAwal.INTERACT_DISTANCE
	detector.Parent = part
	detector.MouseClick:Connect(function(player: Player)
		LahanAwalService.Tap(player, part, key)
	end)
	part.Parent = folder
end

-- Rebuilds every object still standing on this player's plot (their starting objects + their bought chunks).
function LahanAwalService.Rebuild(player: Player, plot: Model)
	local data = DataService.Get(player)
	local origin = plot.PrimaryPart
	if not data or not origin then
		return
	end
	local folder = plot:FindFirstChild(FOLDER_NAME)
	if folder then
		folder:ClearAllChildren()
	else
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = plot
	end
	for i, obj in LahanAwal.START_OBJECTS do
		if startPresent(data.land, i) then
			spawn(folder :: Folder, origin, obj, `s{i}`)
		end
	end
	for chunkKey, owned in data.land.chunks do
		if owned == true then
			local ix, iz = string.match(chunkKey, "^(%-?%d+),(%-?%d+)$")
			if ix and iz then
				local bits = chunkBits(data.land, chunkKey)
				local list = LahanAwal.chunkObjects(tonumber(ix) :: number, tonumber(iz) :: number)
				for k, obj in list do
					if bit32.extract(bits, k - 1) == 1 then
						spawn(folder :: Folder, origin, obj, `c{ix},{iz}:{k}`)
					end
				end
			end
		end
	end
end

-- A tap on one object, validated on the server: the plot must be the player's, the player must be near it, and the
-- object must still be there.
function LahanAwalService.Tap(player: Player, part: BasePart, key: string)
	local plot = part.Parent and part.Parent.Parent
	if not plot or not plot:IsA("Model") or PlotService.GetOwner(plot) ~= player then
		return
	end
	local data = DataService.Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - part.Position).Magnitude > LahanAwal.INTERACT_DISTANCE then
		return
	end
	local obj, chunkKey = resolve(key)
	if not obj then
		return
	end

	local count = ((hits[player] or {})[key] or 0) + 1
	hits[player] = hits[player] or {}
	hits[player][key] = count
	if count < obj.taps then
		return
	end
	hits[player][key] = nil

	if chunkKey then
		local k = tonumber(string.match(key, ":(%d+)$")) :: number
		data.land.chunkLahan[chunkKey] = bit32.replace(chunkBits(data.land, chunkKey), 0, k - 1)
	else
		local i = tonumber(string.match(key, "^s(%d+)$")) :: number
		if not startPresent(data.land, i) then
			return
		end
		clearStart(data.land, i)
	end
	part:Destroy()

	if chunkKey == nil and startCleared(data.land) then
		EconomyService.Add(player, "koin", LahanAwal.CLEAN_REWARD.koin, "lahan:bersih")
		Net.Fire("Notify", player, "lahan.bersih", { n = LahanAwal.CLEAN_REWARD.koin })
	end
end

function LahanAwalService.Init()
	PlotService.Assigned:Connect(function(player: Player, plot: Model)
		LahanAwalService.Rebuild(player, plot)
	end)
	PlotService.Released:Connect(function(player: Player, plot: Model)
		hits[player] = nil
		local folder = plot:FindFirstChild(FOLDER_NAME)
		if folder then
			folder:ClearAllChildren()
		end
	end)
end

function LahanAwalService.Start() end

return LahanAwalService
