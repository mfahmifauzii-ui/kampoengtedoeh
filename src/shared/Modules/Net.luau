--!strict
-- Single place for all remotes. Add a name to DEFINITIONS; the server creates it.
-- Server: Net.On / Net.Fire / Net.FireAll      Client: Net.Listen / Net.Send / Net.Invoke
-- Every Net.On handler MUST validate its arguments (types, ranges, ownership).
-- The server never calls InvokeClient (a client could hang the server thread).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RateLimit = require(script.Parent.RateLimit)

type RemoteKind = "Event" | "Function"

local DEFINITIONS: { [string]: RemoteKind } = {
	Notify = "Event", -- S->C (localeKey: string, vars: {[string]: any}?)
	KualitasBanner = "Event", -- S->C (playerName: string, cropId: string, qualityId: string) Prima Late, sent to every player (FarmService)

	FarmPlant = "Event", -- C->S (tileIndex: number, cropId: string)
	FarmWater = "Event", -- C->S (tileIndex: number)
	FarmWaterArea = "Event", -- C->S (tileIndex: number) Gembor Bambu: waters the 3x3 beds around it (Stage 2)
	FarmHarvest = "Event", -- C->S (tileIndex: number)

	FishState = "Event", -- S->C ("waiting", spot: BasePart) | ("bite") | ("idle")
	FishReel = "Event", -- C->S (score: number 0..1)
	FishCancel = "Event", -- C->S ()
	FishCast = "Event", -- C->S () cast at the nearest fishing spot in reach (the server picks it; v6.2.3 Mancing button)

	StateSync = "Event", -- S->C (snapshot: items, slots, tiers, rods) — see InventoryService
	StateRequest = "Event", -- C->S () ask for a fresh snapshot
	NpcTalk = "Event", -- S->C (npcId: string) the player pressed "Ngobrol": open the dialogue
	Sell = "Event", -- C->S (npcId: string, itemId: string | "all", amount: number?)
	ShopBuy = "Event", -- C->S (npcId: string, kind: "rod"|"bait"|"upgrade"|"seed"|"fish"|"tool", id: string, amount: number?)
	ShopEquipRod = "Event", -- C->S (rodId: string)

	DecorPlace = "Event", -- C->S (itemId: string, x: number, z: number, r: number)
	DecorMove = "Event", -- C->S (uid: number, x: number, z: number, r: number)
	DecorStore = "Event", -- C->S (uid: number)

	OrderDeliver = "Event", -- C->S (orderUid: number)
	OrderReroll = "Event", -- C->S (orderUid: number) daily orders only

	SettingsSet = "Event", -- C->S (key: "music"|"ambient"|"sfx", value: boolean) or (key: "musicVol"|"sfxVol", value: 0..1) or (key: "quality", value: 1..3)

	StoreBuy = "Event", -- C->S (kind: "pass"|"product", key: string) server re-checks, then prompts

	FarmTill = "Event", -- C->S (cx: number, cz: number) turn a grass cell of your land into soil
	FarmLevel = "Event", -- C->S (tileUid: number) remove an empty bed: back to grass (menu "Hapus Petak", asks first)
	FarmMove = "Event", -- C->S (tileUid, cx, cz) move an empty bed to another free cell of your land (Pindah)

	LandBuy = "Event", -- C->S (ix: number, iz: number) buy the 32 x 32 block (plot-local chunk indices, Modules/Land)

	PondBuild = "Event", -- C->S (cx: number, cz: number) dig a pond with its min corner at this tile cell
	PondRemove = "Event", -- C->S (uid: number) fill a pond back in (refund)

	SocialVisit = "Event", -- C->S (ownerUserId: number) teleport to that plot; your own id = go home
	SocialLike = "Event", -- C->S (ownerUserId: number) like the plot you're standing on

	MineHit = "Event", -- C->S (nodeId: string, crit: boolean) pukul node (ritme di client, server validasi)
	MineCraft = "Event", -- C->S (recipeId: string, times: 1|10) craft olahan instan
	MineState = "Event", -- S->C ({ nodes: { [nodeId]: { hits, readyAt } } }) sisa pukulan per-player
	MineFx = "Event", -- S->C (nodeId: string, crit: boolean) efek pukul (suara + partikel)

	RanchKandang = "Event", -- C->S (hewanId: string, tier: number) bangun (tier 1) / upgrade (tier 2) kandang
	RanchHewan = "Event", -- C->S (hewanId: string) beli 1 ekor (kandang harus ada + ada slot)
	RanchPakan = "Event", -- C->S (hewanId: string, kind: "koin"|"jagung") isi pakan penuh (jagung: ayam saja)
	RanchAmbil = "Event", -- C->S (hewanId: string) ambil semua produk 1 kandang
	RanchOpen = "Event", -- S->C () buka panel Ternak (dari prompt Kelola di kandang)
	BreedStart = "Event", -- C->S (pondUid: number, fishId: string) mulai breeding (2 ikan + 20 Koin)
	BreedCollect = "Event", -- C->S (pondUid: number) ambil anak ikan
	BreedInstant = "Event", -- C->S (pondUid: number) instant breeding pakai Bunga (Bab 18.5)
	PondTier = "Event", -- C->S (pondUid: number, tier: string) upgrade tier kolam (semen/keramik)

	PlaytimeClaim = "Event", -- C->S (index: number) open playtime peti number index (in order, Config/Progression PLAYTIME)
	BookClaim = "Event", -- C->S (key: string) claim a Book reward: "cat:<category>" or a milestone id (Config/Book)

	GuideEvent = "Event", -- C->S (action: "start"|"step"|"skip"|"replay", tutorialId: string, n: number?) tutorial engine, see TutorialService
	HasMet = "Function", -- C->S (npcId: string) -> alreadyMet: boolean. Records the first talk with that NPC (TutorialService)
	MeetFajar = "Function", -- C->S () -> { ok, gave }. Kak Fajar's Terima Hadiah: the rod and bait once (TutorialService)
	OnFirstSellSuccess = "Event", -- S->C (npcId: string) the player's first sale went through (TutorialService, Fase 2 cutscene)
}

local FOLDER_NAME = "Remotes"
local IS_SERVER = RunService:IsServer()

local folder: Folder
if IS_SERVER then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for name, kind in DEFINITIONS do
		local remote = Instance.new(if kind == "Event" then "RemoteEvent" else "RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function getRemote(name: string): any
	assert(DEFINITIONS[name], `[Net] Unknown remote "{name}"`)
	return if IS_SERVER then folder:FindFirstChild(name) else folder:WaitForChild(name)
end

export type HandlerOptions = {
	rate: number?, -- calls per second (default 10)
	burst: number?,
}

local Net = {}

-- SERVER --------------------------------------------------------------------

function Net.On(name: string, handler: (Player, ...any) -> ...any, options: HandlerOptions?)
	assert(IS_SERVER, "[Net] On is server-only")
	local limiter = RateLimit.new(options and options.rate or 10, options and options.burst)
	local remote = getRemote(name)

	if DEFINITIONS[name] == "Event" then
		remote.OnServerEvent:Connect(function(player: Player, ...: any)
			if not limiter:Check(player) then
				return
			end
			local ok, err = pcall(handler, player, ...)
			if not ok then
				warn(`[Net] {name} from {player.Name}: {err}`)
			end
		end)
	else
		remote.OnServerInvoke = function(player: Player, ...: any)
			if not limiter:Check(player) then
				return nil
			end
			local result = table.pack(pcall(handler, player, ...))
			if not result[1] then
				warn(`[Net] {name} from {player.Name}: {result[2]}`)
				return nil
			end
			return table.unpack(result, 2, result.n)
		end
	end
end

function Net.Fire(name: string, player: Player, ...: any)
	assert(IS_SERVER, "[Net] Fire is server-only")
	getRemote(name):FireClient(player, ...)
end

function Net.FireAll(name: string, ...: any)
	assert(IS_SERVER, "[Net] FireAll is server-only")
	getRemote(name):FireAllClients(...)
end

-- CLIENT --------------------------------------------------------------------

function Net.Listen(name: string, fn: (...any) -> ()): RBXScriptConnection
	assert(not IS_SERVER, "[Net] Listen is client-only")
	return getRemote(name).OnClientEvent:Connect(fn)
end

function Net.Send(name: string, ...: any)
	assert(not IS_SERVER, "[Net] Send is client-only")
	getRemote(name):FireServer(...)
end

function Net.Invoke(name: string, ...: any): ...any
	assert(not IS_SERVER, "[Net] Invoke is client-only")
	return getRemote(name):InvokeServer(...)
end

return Net
