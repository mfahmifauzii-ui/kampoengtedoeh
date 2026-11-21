--!strict
-- Client entry point. Controllers load in ORDER: every Init(), then every Start().
-- Client = UI, input, visuals only. All game state changes go through the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Shared")

local Controllers = script.Controllers

local ORDER = {
	"HudController",
	"FeedbackController", -- coin count-up and fly-to-Bag feedback (HUD reads its displayed coins)
	"GarapController",
	"LandController", -- after Garap: its "+" buttons hide while Garap mode is open
	"FarmController",
	"CoachmarkController", -- before GuideController: the tutorial's overlay / ring / bubble (GuideController drives it)
	"GuideController", -- after Garap: stays quiet while Garap mode shows its own hint
	"FishingController",
	"MiningController", -- after FishingController: tombol Pukul + ritme + panel craft
	"RanchController", -- Ternak: tombol Kelola + panel kandang (Bab 7.1)
	"PondController", -- Kolam: tombol Breeding + panel tier/breed/instant (Bab 7.2)
	"DapurController", -- Dapur + Warung + Makan: panel resep/slot/warung/buff (Bab 9)
	"SkillController", -- Skill 16 + SP: panel beli skill (Bab 4.5)
	"InventoryController",
	"ShopController",
	"DialogueController",
	"DecorController",
	"OrdersController",
	"QuestController",
	"BookController",
	"RewardsController", -- Hadiah: kalender harian + peti main
	"WorldController",
	"AudioController",
	"SettingsController",
	"StoreController",
	"SocialController",
}

local loaded = {}
for _, name in ORDER do
	loaded[name] = require(Controllers:WaitForChild(name) :: ModuleScript) :: any
end

for _, name in ORDER do
	if loaded[name].Init then
		loaded[name].Init()
	end
end

for _, name in ORDER do
	if loaded[name].Start then
		task.spawn(loaded[name].Start)
	end
end
