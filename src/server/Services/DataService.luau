--!strict
-- Owns player saves via ProfileStore (session locking, autosave, BindToClose).
-- Other services read/modify data ONLY through DataService.Get(player) on the server.
-- In Studio with API access OFF, ProfileStore runs in mock mode (nothing persists).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
local DataTemplate = require(ReplicatedStorage.Shared.Config.DataTemplate)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

-- ⚠️ Changing STORE_NAME orphans every existing save. Never change it after launch.
-- Studio always uses its own store, so testing never touches real player saves.
-- DATA_STAGE: "playtest" during closed playtests → set to "live" ONCE, right before public
-- launch (fresh saves for everyone), then never touch it again. See docs/Launch_Checklist.md.
local DATA_STAGE = "v72" -- bumped for v7.3 (Bab 28): no real players yet, so old saves are simply not loaded; no migration code
local STORE_NAME = if RunService:IsStudio() then "KampungTeduh_Studio" else `KampungTeduh_Player_{DATA_STAGE}`

local PlayerStore = ProfileStore.New(STORE_NAME, DataTemplate)
local profiles: { [Player]: any } = {}

local DataService = {}
DataService.Loaded = Signal.new() -- (player, data) after data is ready
DataService.Releasing = Signal.new() -- (player, data) right before the session ends

-- DEV ONLY (Studio test hook, 16 Nov): a Workspace attribute "DevSaveSuffix" makes a NEW save key (fresh account) in the
-- Studio store. Set it in Edit mode, play, and change the value for another fresh account. Only active in Studio.
-- REMOVE BEFORE LAUNCH (see docs/Launch_Checklist.md).
local function saveKey(player: Player): string
	local suffix = if RunService:IsStudio() then game:GetService("Workspace"):GetAttribute("DevSaveSuffix") else nil
	return tostring(player.UserId) .. (if typeof(suffix) == "string" then "_" .. suffix else "")
end

local function onPlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(saveKey(player), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Another server holds the lock and didn't release in time, or Roblox DataStores are down.
		player:Kick(Locale.t("data.load_failed"))
		return
	end

	profile:AddUserId(player.UserId) -- GDPR / right-to-erasure support

	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick(Locale.t("data.session_ended"))
	end)

	if player.Parent ~= Players then
		profile:EndSession() -- left while loading
		return
	end

	local data = profile.Data :: Types.PlayerData
	local now = os.time()
	if data.stats.firstJoin == 0 then
		data.stats.firstJoin = now
		data.inventory.seed_kangkung = 6 -- a new save starts with 6 bibit, once (see DataTemplate: never a template default)
	end
	data.stats.lastLogin = now
	data.stats.sessions += 1

	profiles[player] = profile
	player:SetAttribute("Level", data.level)
	player:SetAttribute("DataLoaded", true)
	DataService.Loaded:Fire(player, data)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		DataService.Releasing:Fire(player, profile.Data)
		profiles[player] = nil
		profile:EndSession()
	end
end

function DataService.Get(player: Player): Types.PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- The raw ProfileStore profile; only MonetizationService needs it (save confirmation).
function DataService.GetProfile(player: Player): any
	return profiles[player]
end

-- Yields until the player's data is loaded. Returns nil if they leave first.
function DataService.WaitFor(player: Player): Types.PlayerData?
	while player.Parent == Players do
		local data = DataService.Get(player)
		if data then
			return data
		end
		task.wait(0.1)
	end
	return nil
end

function DataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return DataService
