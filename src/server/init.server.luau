--!strict
-- Server entry point. Services load in ORDER: every Init() runs, then every Start().
-- Init = wire up signals (no yielding). Start = begin work (may yield).

local Services = script.Services

local ORDER = {
	"MapService", -- first: builds the world the other services look for (Plots, Fishing, Warung)
	"DataService",
	"EconomyService",
	"AnalyticsHooks",
	"MonetizationService",
	"InventoryService",
	"ProgressionService",
	"WorldService",
	"EventService",
	"BookService",
	"QuestService", -- before the services that report to it (Fish, Pond)
	"PlotService",
	"FarmService",
	"FishService",
	"PondService", -- after FishService: gives each pond its fishing/collect spot
	"AffinityService",
	"SkillService",
	"NpcService",
	"ShopService",
	"DecorService",
	"OrderService",
	"SocialService",
	"SettingsService",
	"DevService",
}

local loaded = {}
for _, name in ORDER do
	loaded[name] = require(Services:FindFirstChild(name) :: ModuleScript) :: any
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

print("[Server] Kampung Teduh started")
