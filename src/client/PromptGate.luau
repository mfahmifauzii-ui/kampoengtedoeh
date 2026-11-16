--!strict
-- While a conversation is open (DialogueController), every ProximityPrompt in the world is hidden, so no "Ngobrol", "Mancing"
-- or pond prompt sits on top of the dialogue box (Plan v3 section 3.2).
--
-- Hide() turns prompts off and watches each one. Show() turns back on ONLY the prompts that are still ours: if another system
-- switched a prompt on while the conversation was open, that change wins and the prompt is left as it is. Nothing is restored
-- from a snapshot taken earlier.
--
-- Any change to a prompt's Enabled by another system during the conversation (on OR off) counts as taking it over, and Show()
-- leaves that prompt as it was set. Remaining gap (TODO, ticket FISH-PROMPT-OWNER): PromptGate does not know WHY another
-- system changed a prompt, so an owner that switches a prompt off temporarily and forgets to switch it back on leaves it off.
-- Proper fix: every prompt owner registers its own desired state (a reference count or an owner attribute), and PromptGate
-- only asks each owner to refresh.
--
-- Client only. Visual gate: the server still checks every action (fishing, pond, talk), so this never grants anything.
-- Rollback: delete this module and the calls in DialogueController.

local Workspace = game:GetService("Workspace")

local PromptGate = {}

type Entry = { prompt: ProximityPrompt, connection: RBXScriptConnection, changedByOthers: boolean }

local held: { Entry } = {}

local function release(entry: Entry)
	entry.connection:Disconnect()
end

function PromptGate.Hide()
	if #held > 0 then
		return -- already hidden by a conversation that is still open
	end
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and descendant.Enabled then
			local entry: Entry = { prompt = descendant, changedByOthers = false, connection = nil :: any }
			descendant.Enabled = false -- our own switch-off; the watcher below is connected after it, so it is not counted
			-- Any later change to Enabled is another system taking the prompt over (on or off). From then on it is theirs:
			-- Show() leaves it exactly as they set it.
			entry.connection = descendant:GetPropertyChangedSignal("Enabled"):Connect(function()
				entry.changedByOthers = true
			end)
			table.insert(held, entry)
		end
	end
end

function PromptGate.Show()
	for _, entry in held do
		release(entry)
		-- Restore only what is still ours: still off, and nobody switched it on while we held it.
		if entry.prompt.Parent and not entry.changedByOthers and not entry.prompt.Enabled then
			entry.prompt.Enabled = true
		end
	end
	table.clear(held)
end

function PromptGate.IsHidden(): boolean
	return #held > 0
end

return PromptGate
