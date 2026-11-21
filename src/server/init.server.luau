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
	"PlaytimeService", -- after ProgressionService (it grants the peti rewards)
	"WorldService",
	"EventService",
	"BookService",
	"QuestService", -- before the services that report to it (Fish, Pond)
	"PlotService",
	"LandService", -- before FarmService: owned chunks are painted before the soil is rebuilt on top of them
	"TutorialService", -- before FarmService: it asks TutorialService.ConsumeFast on every planting
	"FarmService",
	"FishService",
	"PondService", -- after FishService: gives each pond its fishing/collect spot
	"MiningService", -- after QuestService (reports "mine") + PondService: Nambang + Crafting (Bab 8)
	"RanchService", -- after QuestService + PlotService + WorldService: Ternak (Bab 7.1)
	"SkillService", -- after DataService: Skill 16 + SP (Bab 4.5)
	"DapurService", -- after RanchService + QuestService (reports "cook"): Dapur + Buff (Bab 9)
	"WarungService", -- after DapurService + EconomyService: Warung Player (Bab 9.3)
	"NpcService",
	"ShopService",
	"RepeatService", -- Event Berulang (P2-6): Gerobak/Pasar/Kerja Bakti/Tamu; butuh NpcService + WorldService (di atas)
	"AgendaService", -- Agenda Harian (P2-7): 5 tugas dipilih player
	"AlbumService", -- Toko Bunga + delegasi klaim Album (P2-7)
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
