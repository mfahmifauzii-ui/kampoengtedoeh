--!strict
-- Skill Tree (docs/Skill_Tree_Kampoeng_Tedoeh_v7.7.md Bab 1, 2): beli 1 level = 1 SP + 3.000 Koin. Tidak ada reset.
-- Server authority: prasyarat, SP, Koin, dan batas maks dicek di sini. Semua pengecekan dilakukan sebelum ada yang dipotong,
-- jadi pembelian gagal tanpa mengubah saldo. Hasilnya dikembalikan ke klien sebagai alasan (SkillBuy, RemoteFunction).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skills = require(ReplicatedStorage.Shared.Config.Skills)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)

local RATE = { rate = 4, burst = 8 }

local SkillService = {}

-- Alasan yang dikembalikan ke klien: "ok" | "max" | "locked" | "noSP" | "noKoin" | "unknown".
export type BuyResult = "ok" | "max" | "locked" | "noSP" | "noKoin" | "unknown"

-- Hanya dipanggil dari SkillBuy. Urutan cek: maks, prasyarat, SP, Koin. Potong Koin dulu (satu-satunya yang bisa gagal
-- setelah cek), baru SP dan level. Tidak ada yield di antara cek dan potongan.
local function buy(player: Player, skillId: any): BuyResult
	if typeof(skillId) ~= "string" then
		return "unknown"
	end
	local def = Skills.byId[skillId]
	local data = DataService.Get(player)
	if not def or not data then
		return "unknown"
	end
	local level = data.skill[skillId] or 0
	if level >= def.maxLevel then
		return "max"
	end
	if Skills.missing(def, data.skill, data.level) ~= nil then
		return "locked"
	end
	if data.sp < Skills.SP_PER_LEVEL then
		return "noSP"
	end
	if not EconomyService.CanAfford(player, "koin", Skills.KOIN_PER_LEVEL) then
		return "noKoin"
	end
	if not EconomyService.TrySpend(player, "koin", Skills.KOIN_PER_LEVEL, `skill:{skillId}`) then
		return "noKoin"
	end
	data.sp -= Skills.SP_PER_LEVEL
	data.skill[skillId] = level + 1
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "skill.bought", { skill = `skill.{skillId}`, n = level + 1 })
	return "ok"
end

function SkillService.Init()
end

function SkillService.Start()
	Net.On("SkillBuy", function(player: Player, skillId: any)
		return buy(player, skillId)
	end, RATE)
end

return SkillService
