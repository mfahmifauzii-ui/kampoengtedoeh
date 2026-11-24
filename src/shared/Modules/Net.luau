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
	FishFirasat = "Event", -- S->C () pity >= 75% + dekat Kak Fajar: gelembung emas di pelampung (Bab 6.5)

	StateSync = "Event", -- S->C (snapshot: items, slots, tiers, rods) — see InventoryService
	StateRequest = "Event", -- C->S () ask for a fresh snapshot
	QuestReport = "Event", -- C->S (event: string) UI-only quest events: agenda_open, gerobak_view, surat_read (QuestService whitelist)
	KakekSetor = "Event", -- C->S () setor 10 Batu + 5 Kayu + 3 ikan Early untuk Kolam Kakek (Quest M3 langkah 1; server cek barang)
	NpcTalk = "Event", -- S->C (npcId: string) the player pressed "Ngobrol": open the dialogue
	NpcFace = "Event", -- C->S (npcId: string, on: boolean) the NPC turns to the talking player (on) or back (off), K-106
	QuestOffers = "Event", -- S->C (ids: { string }) quests this player can accept now (Q-3, QuestService.sendOffers)
	QuestAccept = "Event", -- C->S (questId: string) accept an offered quest after its start dialog (Q-3, QuestService.onAccept)
	QuestOffersRequest = "Event", -- C->S () ask for QuestOffers again (Q-3)
	QuestTurnIn = "Event", -- C->S (questId: string) serahkan quest siap diserahkan saat bicara dengan pemberi (K-93)
	QuestTrack = "Event", -- C->S (key: string, on: boolean) Track / Lepas di Quest Log (maks 3, GUI 6.8)
	Sell = "Event", -- C->S (npcId: string, itemId: string | "all", amount: number?)
	ShopBuy = "Event", -- C->S (npcId: string, kind: "rod"|"bait"|"upgrade"|"seed"|"fish"|"tool", id: string, amount: number?)
	ShopEquipRod = "Event", -- C->S (rodId: string)
	EquipBait = "Event", -- C->S (baitId: string): umpan yang dipakai, hanya yang masih dimiliki (K-55)
	BubuPlace = "Event", -- C->S (kind: string): pasang bubu di sungai dekat titik mancing (R2.1)
	BubuCollect = "Event", -- C->S (uid: number): ambil bubu yang sudah siap (R2.1)
	DevCmd = "Event", -- C->S (text: string): perintah DEV seperti chat "!..."; server cek DevService.IsAllowed (K-64)

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
	SocialLike = "Event", -- C->S (ownerUserId: number) like the plot you're standing on (1x selamanya)
	SocialBantu = "Event", -- C->S (ownerUserId: number, kind: "siram"|"panen") bantu di lahan pemain
	SocialGift = "Event", -- C->S (ownerUserId: number, itemId: string) kirim 1 barang sebagai hadiah
	SocialEmote = "Event", -- C->S (emoteId: string) gestur ramah (cooldown 3 dtk, server-validated)
	SocialEmoteFx = "Event", -- S->C (userId: number, emoteId: string) mainkan gestur pemain itu
	GaleriGet = "Event", -- C->S () minta papan Galeri (top 5 mingguan)
	GaleriBoard = "Event", -- S->C ({ week: string, list: {{ userId, name, likes }} }) papan Galeri

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
	PondDeposit = "Event", -- C->S (pondUid: number, itemId: string) setor 1 ikan dari tas ke stok kolam (B-3)
	PondWithdraw = "Event", -- C->S (pondUid: number, index: number) ambil 1 ikan dari stok kolam ke tas (B-3)
	PondOpen = "Event", -- S->C (pondUid: number) tombol "Kolam" ditekan: buka sheet Kolam (B-3)

	SkillBuy = "Function", -- C->S (skillId: string) -> "ok" | "max" | "locked" | "noSP" | "noKoin" | "unknown" (SkillService)
	GerobakBuy = "Event", -- C->S (slot: number) beli 1 unit slot Gerobak Kaget (max 3/slot/restock)
	TestHook = "Event", -- C->S (action: "skipTutorial" | "grant") Studio-only test hook (K-127); server ignores it outside Studio
	KBPieces = "Event", -- S->C (positions: { Vector3 }) sampah Kerja Bakti milik pemain ini; index = piece id (K-117)
	KBPick = "Event", -- C->S (pieceId: number) pungut sampah Kerja Bakti sendiri; server cek id, jarak, sekali saja (K-117)
	KBPicked = "Event", -- S->C (pieceId: number) pungutan diterima; klien menghapus sampah itu (K-117)
	PasarJual = "Event", -- C->S (count: number) jual barang malam ini ke Pedagang Tamu (+50%, max 10/malam)
	GelangThrow = "Event", -- C->S () lempar gelang (max 3/malam)
	TamuDeliver = "Event", -- C->S () serahkan semua barang Pesanan Tamu
	BungaBuy = "Event", -- C->S (itemId: string) tukar Bunga dengan dekor langka / bibit varian (AlbumService, P2-7)
	BundelGive = "Event", -- C->S (bundelId: string, itemId: string, count?: number) setor barang Bundel (BundelService, P2-7-fix)
	DapurBuild = "Event", -- C->S () bangun Inti Tier 1
	DapurUpgrade = "Event", -- C->S () upgrade ke tier berikut (refund 100% Inti lama)
	DapurCook = "Event", -- C->S (slot: number, recipeId: string) mulai masak (slot 0 = otomatis)
	DapurCollect = "Event", -- C->S (slot: number) ambil olahan jadi
	DapurEat = "Event", -- C->S (itemId: string) makan 1 Olahan = 1 buff aktif
	WarungBuild = "Event", -- C->S () bangun Warung (Lv 6, gratis)
	WarungDisplay = "Event", -- C->S (itemId: string) pajang semua unit 1 jenis olahan
	WarungTake = "Event", -- C->S () ambil kembali pajangan ke tas

	PlaytimeClaim = "Event", -- C->S (index: number) open playtime peti number index (in order, Config/Progression PLAYTIME)
	LoginClaim = "Event", -- C->S (day: number 1..7) claim a Login Mingguan day (RewardsService, Config/Rewards)
	PetiOpen = "Event", -- C->S () open one Peti Bunga (RewardsService)
	SeasonClaim = "Event", -- C->S (track: "f2p"|"premium", day: number) claim one Season day (RewardsService)
	SeasonPremium = "Event", -- C->S () buy Season Premium for the current season (150 Bunga)
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
