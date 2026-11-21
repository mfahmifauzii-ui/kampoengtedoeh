--!strict
-- Skill 16 (Bab 4.5): beli pakai SP, 1 SP per level, max Lv 5. Skill tidak bisa dibeli
-- pakai Bunga/Robux (Bab 4.3). Biaya Koin 15.000 (Bab 17.4) = USULAN: tidak di-charge.
-- CABANG lama (Bertani/Mancing/Beternak/Tukang Lv 0-10) DIHAPUS total (P2-4).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skills = require(ReplicatedStorage.Shared.Config.Skills)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local RATE = { rate = 4, burst = 8 }

local SkillService = {}

local function onBuy(player: Player, skillId: any)
	if typeof(skillId) ~= "string" then
		return
	end
	local def = Skills.byId[skillId]
	local data = DataService.Get(player)
	if not def or not data then
		return
	end
	local level = data.skill[skillId] or 0
	if level >= def.maxLevel then
		Net.Fire("Notify", player, "skill.maxed")
		return
	end
	if data.sp < Skills.SP_PER_LEVEL then
		Net.Fire("Notify", player, "skill.need_sp")
		return
	end
	data.sp -= Skills.SP_PER_LEVEL
	data.skill[skillId] = level + 1
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "skill.bought", { skill = `skill.{skillId}`, n = level + 1 })
end

function SkillService.Init()
end

function SkillService.Start()
	Net.On("SkillBuy", onBuy, RATE)
end

return SkillService
