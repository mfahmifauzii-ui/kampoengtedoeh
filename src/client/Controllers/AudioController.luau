--!strict
-- Music playlist, phase-based nature ambience (crossfaded), rain bed, 3D river, and
-- one-shot SFX for notifications. Volumes follow the saved settings (music/ambient/sfx).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Audio = require(ReplicatedStorage.Shared.Config.Audio)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)

local FADE = TweenInfo.new(4, Enum.EasingStyle.Sine)

local AudioController = {}

-- Notification key -> SoundBank role: the feedback sounds for the loop (sell, order, level, shop...).
-- (Audio.SFX below is the older per-key id map and still works for any key listed there.)
local NOTIFY_ROLE: { [string]: string } = {
	["sell.sold"] = "coin_gain",
	["shop.bought"] = "coin_gain",
	["shop.bought_fish"] = "coin_gain",
	["order.done"] = "order_done",
	["quest.done"] = "order_done",
	["chest.opened"] = "order_done",
	["land.bought"] = "order_done",
	["level.up"] = "level_up",
	["level.up_unlocks"] = "level_up",
	["book.new"] = "notify_ding",
	["book.claim_done"] = "order_done",
	["quest.new"] = "notify_ding",
	["order.new_day"] = "notify_ding",
	["pond.built"] = "place_item",
	["mine.crafted"] = "place_item",
	["ranch.built"] = "place_item",
	["pond.tier_up"] = "place_item",
	["ranch.collected"] = "order_done",
	["pond.breed_done"] = "order_done",
	["pond.breed_instant"] = "order_done",
	["decor.stored"] = "place_item",
}

local groups: { [string]: SoundGroup } = {}
local ambientSounds: { [string]: Sound } = {} -- by sound id
local rainSound: Sound?
local sfxSounds: { [string]: Sound } = {}

local function makeGroup(name: string): SoundGroup
	local group = Instance.new("SoundGroup")
	group.Name = `KT_{name}`
	group.Volume = (Audio.VOLUME :: any)[name]
	group.Parent = SoundService
	groups[name] = group
	return group
end

local function makeSound(soundId: string, group: SoundGroup, looped: boolean, parent: Instance?): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Looped = looped
	sound.Volume = 0
	sound.SoundGroup = group
	sound.Parent = parent or SoundService
	return sound
end

local function fadeTo(sound: Sound, volume: number)
	if volume > 0 and not sound.IsPlaying then
		sound:Play()
	end
	local tween = TweenService:Create(sound, FADE, { Volume = volume })
	tween:Play()
	if volume == 0 then
		tween.Completed:Once(function()
			if sound.Volume == 0 then
				sound:Stop()
			end
		end)
	end
end

local function updateAmbient()
	local phase = Workspace:GetAttribute("DayPhase")
	local wanted = if typeof(phase) == "string" then Audio.AMBIENT[phase] else nil
	for soundId, sound in ambientSounds do
		fadeTo(sound, if soundId == wanted then 1 else 0)
	end
	if rainSound then
		fadeTo(rainSound, if Workspace:GetAttribute("Raining") == true then 1 else 0)
	end
end

local function applySettings()
	local snapshot = State.current :: any
	local settings = snapshot and snapshot.settings
	if not settings then
		return
	end
	for name, group in groups do
		local share = settings[`{name}Vol`] -- the slider of Pengaturan (music, sfx): 0..1 of the base volume; the others have none
		group.Volume = if settings[name] == false
			then 0
			else (Audio.VOLUME :: any)[name] * (if typeof(share) == "number" then share else 1)
	end
end

-- Live preview while a volume slider is dragged (the saved value follows when the player lets go and the state syncs).
function AudioController.Preview(name: string, share: number)
	local group = groups[name]
	if group then
		group.Volume = (Audio.VOLUME :: any)[name] * math.clamp(share, 0, 1)
	end
end

local function runMusic(group: SoundGroup)
	if #Audio.MUSIC == 0 then
		return
	end
	local sound = makeSound(Audio.MUSIC[1], group, false)
	sound.Volume = 1
	local order = table.clone(Audio.MUSIC)
	while true do
		-- Shuffle each round so it doesn't feel like a loop.
		for i = #order, 2, -1 do
			local j = math.random(1, i)
			order[i], order[j] = order[j], order[i]
		end
		for _, soundId in order do
			sound.SoundId = soundId
			sound:Play()
			-- Don't hang forever if a track fails to load (moderated / removed asset).
			local started = os.clock()
			repeat
				task.wait(1)
				local limit = if sound.TimeLength > 0 then sound.TimeLength + 2 else 15
			until not sound.Playing or os.clock() - started > limit
			sound:Stop()
			task.wait(Audio.MUSIC_GAP_SECONDS)
		end
	end
end

-- The river may stream in/out; attach the 3D loop whenever it exists.
local function runRiver(group: SoundGroup)
	local riverId = Audio.RIVER
	if not riverId then
		return
	end
	while true do
		-- Emitters: the part named "Sungai", or any part in Fishing with attribute RiverSound = true.
		local fishing = Workspace:FindFirstChild("Fishing")
		local candidates: { Instance } = if fishing then fishing:GetDescendants() else {}
		for _, emitter in candidates do
			if
				emitter:IsA("BasePart")
				and (emitter.Name == "Sungai" or emitter:GetAttribute("RiverSound") == true)
				and not emitter:FindFirstChild("KT_River")
			then
				local sound = makeSound(riverId, group, true, emitter)
				sound.Name = "KT_River"
				sound.Volume = 0.8
				sound.RollOffMode = Enum.RollOffMode.InverseTapered
				sound.RollOffMinDistance = 10
				sound.RollOffMaxDistance = 90
				sound:Play()
			end
		end
		task.wait(5)
	end
end

function AudioController.Init()
	local music = makeGroup("music")
	local ambient = makeGroup("ambient")
	local sfx = makeGroup("sfx")

	for _, soundId in Audio.AMBIENT do
		if soundId and not ambientSounds[soundId] then
			ambientSounds[soundId] = makeSound(soundId, ambient, true)
		end
	end
	if Audio.RAIN then
		rainSound = makeSound(Audio.RAIN, ambient, true)
	end
	for key, soundId in Audio.SFX do
		if soundId then
			local sound = makeSound(soundId, sfx, false)
			sound.Volume = 1
			sfxSounds[key] = sound
		end
	end

	task.spawn(runMusic, music)
	task.spawn(runRiver, ambient)
end

function AudioController.Start()
	updateAmbient()
	Workspace:GetAttributeChangedSignal("DayPhase"):Connect(updateAmbient)
	Workspace:GetAttributeChangedSignal("Raining"):Connect(updateAmbient)
	State.Changed:Connect(applySettings)
	applySettings()

	Net.Listen("Notify", function(key: any)
		local sound = typeof(key) == "string" and sfxSounds[key] or nil
		if sound then
			sound.TimePosition = 0
			sound:Play()
		elseif typeof(key) == "string" and NOTIFY_ROLE[key] then
			Sfx.play(NOTIFY_ROLE[key])
		end
	end)
end

return AudioController
