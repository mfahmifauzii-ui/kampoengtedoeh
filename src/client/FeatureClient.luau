--!strict
-- Client side of the Q-2 feature gate. Reads State.current.features (sent by InventoryService.buildSnapshot) and listens for changes.
-- A gated feature is either closed (its HUD button is hidden, its ProximityPrompt is disabled) or open (shown again).
-- The same feature ids as the server (FeatureGate.luau): nothing here decides the gate itself, it only reflects the snapshot.
--
-- Closed = not "introduced" and not "open" (a missing entry counts as closed, so nothing gated shows before the first snapshot).
-- The server stays the authority: FeatureGate.Check rejects a gated remote or prompt with the "Belum terbuka" toast regardless.
--
-- Prompts: a server-created ProximityPrompt is gated by its attribute "Feature" (the feature id). The client only toggles Enabled.
-- While PromptGate holds the prompts (a conversation is open) this module does not write Enabled, so the dialogue rule still wins.
-- Rollback: delete this module and its calls (GarapController, MiningController, DapurController, DecorController, SocialController).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local State = require(script.Parent.State)
local PromptGate = require(script.Parent.PromptGate)

local FeatureClient = {}

-- Prompts this module turned off (so it only turns back on what it turned off).
local closedByUs: { [ProximityPrompt]: boolean } = setmetatable({}, { __mode = "k" })
local prompts: { ProximityPrompt } = {}

function FeatureClient.IsOpen(id: string): boolean
	local snapshot = State.current
	local features = if snapshot then (snapshot :: any).features else nil
	local state = if typeof(features) == "table" then features[id] else nil
	return state == "introduced" or state == "open"
end

-- While a conversation holds the prompts (PromptGate), nothing is written here. PromptGate.Released re-applies every
-- prompt once the conversation ends, so a feature that opened during the dialogue shows its prompt right after it.
local function applyPrompt(prompt: ProximityPrompt)
	if PromptGate.IsHidden() or not prompt.Parent then
		return
	end
	local id = prompt:GetAttribute("Feature")
	if typeof(id) ~= "string" then
		return
	end
	if FeatureClient.IsOpen(id) then
		if closedByUs[prompt] then
			closedByUs[prompt] = nil
			prompt.Enabled = true
		end
	elseif prompt.Enabled then
		prompt.Enabled = false
		closedByUs[prompt] = true
	end
end

local function applyAllPrompts()
	for i = #prompts, 1, -1 do
		local prompt = prompts[i]
		if not prompt.Parent then
			table.remove(prompts, i) -- destroyed (pond or ranch spot removed): forget it
		else
			applyPrompt(prompt)
		end
	end
end

local function track(instance: Instance)
	if instance:IsA("ProximityPrompt") and typeof(instance:GetAttribute("Feature")) == "string" then
		table.insert(prompts, instance)
		task.defer(applyPrompt, instance)
	end
end

-- Keeps the HUD button `name` (anywhere in HUD) visible only while feature `id` is open. Hidden buttons take no dock space.
-- `shown` (optional, K-75): a rule of its own instead of the feature; it is re-checked when players join or leave.
function FeatureClient.GateHud(name: string, id: string, shown: (() -> boolean)?)
	task.spawn(function()
		local hud = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HUD", 30)
		if not hud then
			return
		end
		local function apply()
			local button = hud:FindFirstChild(name, true)
			if button and button:IsA("GuiObject") then
				button.Visible = if shown then shown() else FeatureClient.IsOpen(id)
			end
		end
		apply()
		hud.DescendantAdded:Connect(function(descendant)
			if descendant.Name == name then
				task.defer(apply)
			end
		end)
		State.Changed:Connect(apply)
		if shown then
			Players.PlayerAdded:Connect(apply)
			Players.PlayerRemoving:Connect(function()
				task.defer(apply)
			end)
		end
	end)
end

-- Starts the prompt gate: every ProximityPrompt with a "Feature" attribute in the world follows the snapshot.
function FeatureClient.StartPrompts()
	for _, descendant in Workspace:GetDescendants() do
		track(descendant)
	end
	Workspace.DescendantAdded:Connect(track)
	State.Changed:Connect(applyAllPrompts)
	PromptGate.Released:Connect(applyAllPrompts)
end

return FeatureClient
