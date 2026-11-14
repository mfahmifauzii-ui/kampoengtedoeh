--!strict
-- Client entry point. Controllers load in ORDER: every Init(), then every Start().
-- Client = UI, input, visuals only. All game state changes go through the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Shared")

local Controllers = script.Controllers

local ORDER = {
	"HudController",
	"GarapController",
	"LandController", -- after Garap: its "+" buttons hide while Garap mode is open
	"FarmController",
	"GuideController", -- after Garap: stays quiet while Garap mode shows its own hint
	"FishingController",
	"InventoryController",
	"ShopController",
	"DialogueController",
	"DecorController",
	"OrdersController",
	"QuestController",
	"BookController",
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
