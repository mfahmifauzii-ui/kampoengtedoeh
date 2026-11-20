--!strict
-- Gives every town NPC (Workspace.Npcs.<id>) the relaxed idle of NpcPose, on this client only. Mak Sari's local copy for the
-- tutorial (T1Ghost) is not in that folder and poses herself.

local Workspace = game:GetService("Workspace")

local NpcPose = require(script.Parent:WaitForChild("NpcPose"))

local function adopt(child: Instance)
	if not child:IsA("Model") then
		return
	end
	task.spawn(function()
		-- The rig and its joints arrive with the model; wait for the root, then a moment for the constraints.
		if child:WaitForChild("HumanoidRootPart", 15) then
			task.wait(0.5)
			if child.Parent then
				NpcPose.Manage(child)
			end
		end
	end)
end

local folder = Workspace:WaitForChild("Npcs")
for _, child in folder:GetChildren() do
	adopt(child)
end
folder.ChildAdded:Connect(adopt)
