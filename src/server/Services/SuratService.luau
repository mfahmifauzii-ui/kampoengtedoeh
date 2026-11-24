--!strict
-- Surat Kakek (Bab 14.3, LOCKED, P2-7-fix): 30 surat, 1 per hari login, kumulatif.
-- Login = hari WIB baru (TimeKeys.day, tanpa jam reset 05:00 — surat ikut hari kalender).
-- Surat ke-n dibuka saat login ke-n; tugas selesai via Report (event QuestService biasa);
-- hadiah otomatis, tanpa klaim. Teks surat tampil sebagai toast (locale surat.<n>.text).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Surat = require(ReplicatedStorage.Shared.Config.Surat)
local Features = require(ReplicatedStorage.Shared.Config.Features)
local TimeKeys = require(ReplicatedStorage.Shared.Modules.TimeKeys)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local FeatureGate = require(script.Parent.FeatureGate)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

local SuratService = {}

-- Surat aktif: nomor terkecil yang belum selesai (0 = semua selesai).
local function current(data: Types.PlayerData): number
	for n = 1, Surat.COUNT do
		if not data.surat.done[n] then
			return n
		end
	end
	return 0
end

local function grant(player: Player, def: Surat.Surat)
	ProgressionService.Grant(player, { koin = def.reward.koin, bunga = def.reward.bunga }, `surat:{def.n}`)
	if def.reward.bahan then
		for itemId, count in def.reward.bahan do
			InventoryService.Add(player, itemId, count)
		end
		InventoryService.Sync(player)
	end
end

-- K-77 (G3): the text key of letter n. While Bantu is hidden, a letter that asks for Bantu reads its alt text (surat.<n>.alt),
-- which is written without Bantu. With the flag on, every letter reads surat.<n>.text as before.
function SuratService.TextKey(n: number): string
	if not Features.BANTU_ENABLED and Surat.byN[n].event == "bantu" then
		return `surat.{n}.alt`
	end
	return `surat.{n}.text`
end

-- K-73: while Bantu is hidden, a letter that asks for Bantu is paid out at once, so the letters after it are not stuck.
-- Only letters already due (n <= logins). The payout toast shows the alt text and the reward, whatever the surat gate (K-83).
local function skipBantuLetters(player: Player, data: Types.PlayerData)
	if Features.BANTU_ENABLED then
		return
	end
	local skipped = false
	local n = current(data)
	while n > 0 and n <= data.surat.logins and Surat.byN[n].event == "bantu" do
		data.surat.done[n] = true
		data.surat.progress = 0
		grant(player, Surat.byN[n])
		-- K-83 (G9): the payout always shows its toast, whatever the surat gate says. The text is the letter's, the reward is what came in.
		local key = if Surat.byN[n].reward.bunga then "surat.got_bunga" else "surat.got"
		Net.Fire("Notify", player, key, {
			n = n,
			text = SuratService.TextKey(n),
			koin = Surat.byN[n].reward.koin or 0,
			bunga = Surat.byN[n].reward.bunga or 0,
		})
		skipped = true
		n = current(data)
	end
	if skipped then
		InventoryService.Sync(player)
	end
end

function SuratService.Current(data: Types.PlayerData): number
	return current(data)
end

function SuratService.Report(player: Player, event: string, add: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	skipBantuLetters(player, data)
	-- Q-2 gate "surat": gameplay events do not progress surat while the feature is closed. Silent (no toast): this is
	-- not a player request, only a side effect of a harvest/bantu/mancing event.
	if not FeatureGate.IsUsable(data, "surat") then
		return
	end
	local n = current(data)
	if n == 0 or n > data.surat.logins then
		return -- surat belum dibuka (1 per hari login)
	end
	local def = Surat.byN[n]
	if not def or def.event ~= event then
		return
	end
	data.surat.progress += add
	if data.surat.progress >= def.count then
		data.surat.done[n] = true
		data.surat.progress = 0
		grant(player, def)
		Net.Fire("Notify", player, "surat.done", { n = n })
	end
	InventoryService.Sync(player)
end

function SuratService.Init()
	DataService.Loaded:Connect(function(player: Player)
		local data = DataService.Get(player)
		if not data then
			return
		end
		local today = TimeKeys.day()
		if data.surat.lastDay ~= today then
			data.surat.lastDay = today
			data.surat.logins += 1
			InventoryService.Sync(player)
		end
		skipBantuLetters(player, data)
		local n = current(data)
		-- Q-2 gate "surat": the login toast only once the feature is open (login counting is unchanged).
		if n > 0 and n <= data.surat.logins and FeatureGate.IsUsable(data, "surat") then
			-- Surat baru hari ini (atau tertunda): tampilkan teksnya 1x per login.
			Net.Fire("Notify", player, "surat.new", { n = n, text = SuratService.TextKey(n) })
		end
	end)
end

return SuratService
