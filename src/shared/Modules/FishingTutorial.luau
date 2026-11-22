--!strict
-- B-5 (2026-11-22): pancing tutorial Kak Fajar (T1b, langkah "mancing") tetap salinan lokal di klien (T1Ghost / KakFajarTutorial).
-- Server dan klien memakai fungsi yang sama: selama langkah itu server tidak membuat visual bersama (Workspace.FishingVisuals),
-- dan klien yang menggambar joran + pelampung sendiri.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Onboarding = require(ReplicatedStorage.Shared.Config.Onboarding)

local FishingTutorial = {}

-- guide = data.guide (server) atau snapshot guide (klien): { step = { id, n } }
function FishingTutorial.isActive(guide: any): boolean
	local step = if typeof(guide) == "table" then guide.step else nil
	if typeof(step) ~= "table" or step.id == nil or step.id == "" then
		return false
	end
	for _, tutorial in Onboarding.TUTORIALS do
		if tutorial.id == step.id then
			local nextStep = tutorial.steps[(step.n or 0) + 1]
			return nextStep ~= nil and nextStep.id == "mancing"
		end
	end
	return false
end

return FishingTutorial
