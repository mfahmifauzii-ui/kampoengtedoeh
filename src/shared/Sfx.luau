--!strict
-- Sfx: play a sound by ROLE, never by id. Every entry point is pcall-isolated and fails inert.
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local SoundBank = require(script.Parent.Config.SoundBank)
local Sfx = {}
local TEMPLATES = "SfxTemplates"
local TAIL = 0.5
local function templates(): Folder
	local folder = SoundService:FindFirstChild(TEMPLATES)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = TEMPLATES
		folder.Parent = SoundService
	end
	return folder :: Folder
end
local function template(role: string): Sound?
	local entry = SoundBank[role]
	if not entry then
		warn(`[Sfx] no such role: {role}`)
		return nil
	end
	local folder = templates()
	local existing = folder:FindFirstChild(role)
	if existing and existing:IsA("Sound") then
		return existing
	end
	local sound = Instance.new("Sound")
	sound.Name = role
	sound.SoundId = `rbxassetid://{entry.id}`
	sound.Volume = entry.volume
	sound.Looped = entry.looped
	sound.Parent = folder
	return sound
end
function Sfx.preload()
	local list = {}
	for role in SoundBank do
		local t = template(role)
		if t then table.insert(list, t) end
	end
	pcall(function() ContentProvider:PreloadAsync(list) end)
end
function Sfx.play(role: string, parent: Instance?, pitchVary: number?): Sound?
	local ok, result = pcall(function(): Sound?
		local source = template(role)
		if not source then return nil end
		local entry = SoundBank[role]
		local clone = source:Clone()
		if pitchVary and pitchVary > 0 then
			clone.PlaybackSpeed = 1 + (math.random() * 2 - 1) * pitchVary
		end
		-- Client: route through the "sfx" group (AudioController) so Atur > Efek suara really mutes it.
			local group = SoundService:FindFirstChild("KT_sfx")
			if group and group:IsA("SoundGroup") then
				clone.SoundGroup = group
			end
			clone.Parent = parent or SoundService
		clone:Play()
		if not entry.looped then
			Debris:AddItem(clone, entry.length / math.max(clone.PlaybackSpeed, 0.01) + TAIL)
		end
		return clone
	end)
	if not ok then
		warn(`[Sfx] {role} failed inert: {result}`)
		return nil
	end
	return result
end
function Sfx.stop(sound: Sound?)
	if sound then
		pcall(function()
			sound:Stop()
			sound:Destroy()
		end)
	end
end
return Sfx
