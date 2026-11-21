--!strict
-- Trading with town NPCs. Every request names an NPC (Config/Npcs) and is distance-checked to it; what an NPC
-- buys and sells comes from its config, prices from Modules/Trade. The client only sends requests.
--   Sell(npcId, itemId | "all", amount?)                NPC buys items from the player (amount: whole number 1-99, one item only)
--   ShopBuy(npcId, kind, id, amount?)                   kind: rod | bait | upgrade | seed | fish | tool
-- Bang Jali (Warung Mini, 0.9x) buys everything at 90% of the price. Every other NPC buys only what its config says.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Farm = require(ReplicatedStorage.Shared.Config.Farm)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Npcs = require(ReplicatedStorage.Shared.Config.Npcs)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Trade = require(ReplicatedStorage.Shared.Modules.Trade)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local FishService = require(script.Parent.FishService)
local PondService = require(script.Parent.PondService)
local InventoryService = require(script.Parent.InventoryService)
local NpcService = require(script.Parent.NpcService)
local TutorialService = require(script.Parent.TutorialService)
local UpgradeService = require(script.Parent.UpgradeService)

local RATE = { rate = 4, burst = 8 }

local ShopService = {}

function ShopService.Init()
	-- A pond upgrade changes every pond's capacity and look (the upgrade itself lives in UpgradeService).
	UpgradeService.Bought:Connect(function(player: Player, upgradeId: string)
		if upgradeId == "pond" then
			FishService.RefreshPond(player)
			PondService.RefreshLook(player)
		end
	end)
end

-- Returns the NPC only if the id is real and the player's character is close to it.
local function npcNear(player: Player, npcId: any): Npcs.Npc?
	local npc = if typeof(npcId) == "string" then Npcs.byId[npcId] else nil
	local position = if npc then NpcService.Position(npc.id) else nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if npc and position and root and root:IsA("BasePart") and (root.Position - position).Magnitude <= Shop.NPC_DISTANCE then
		return npc
	end
	Net.Fire("Notify", player, "shop.too_far")
	return nil
end

-- A whole number from 1 to Shop.MAX_AMOUNT (the shop's number picker).
local function validPack(amount: any): boolean
	return typeof(amount) == "number" and amount == math.floor(amount) and amount >= 1 and amount <= Shop.MAX_AMOUNT
end

local function notEnough(player: Player)
	Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.koin" })
end

-- Selling --------------------------------------------------------------------------

local function onSell(player: Player, npcId: any, target: any, amount: any)
	if typeof(target) ~= "string" then
		return
	end
	-- Optional amount (the number picker): sell only that many of one item. "all" ignores it.
	local wanted: number? = nil
	if amount ~= nil then
		if not validPack(amount) then
			return
		end
		wanted = amount
	end
	local npc = npcNear(player, npcId)
	local data = DataService.Get(player)
	if not npc or not data or next(npc.buys) == nil then
		return
	end

	-- Unit price this NPC pays for an item, nil if it doesn't buy it.
	local function unitPrice(itemId: string): number?
		local info = Items.info(itemId)
		return if info then Trade.buyPrice(npc, info) else nil
	end

	local toSell: { string } = {}
	if target == "all" then
		for itemId in data.inventory do
			if unitPrice(itemId) then
				table.insert(toSell, itemId)
			end
		end
	elseif data.inventory[target] and unitPrice(target) then
		table.insert(toSell, target)
	end

	-- Skill Panen Raya / Susu Melimpah (Bab 4.5, P2-4): +2%/lv di luar cap Dekor (Bab 17.6).
	-- Tidak ada sistem stat Dekor di src/ (P2-9), jadi skill langsung menambah harga jual.
	local cropMult = 1 + 0.02 * (data.skill.panen_raya or 0)
	local ternakMult = 1 + 0.02 * (data.skill.susu_melimpah or 0)
	local total = 0
	for _, itemId in toSell do
		local price = unitPrice(itemId) :: number
		local count = data.inventory[itemId]
		if wanted and target ~= "all" then
			count = math.min(count, wanted)
		end
		if count and count > 0 and InventoryService.Remove(player, itemId, count) then
			local info = Items.info(itemId)
			local mult = if info and info.kind == "crop" then cropMult elseif info and info.kind == "ternak" then ternakMult else 1
			total += price * count * mult
		end
	end
	total = math.floor(total + 0.5)

	if total > 0 then
		-- The first-sale cutscene follows the tutorial's state: T1 not finished (or reset with !tut reset) and the cutscene not played yet.
		local firstSale = data.guide.saleCutscene ~= true and data.guide.done.t1_awal ~= true and data.guide.skipped.t1_awal ~= true
		data.guide.sells += 1 -- one finished sale trip for the new-player guide (Config/Onboarding)
		EconomyService.Add(player, "koin", total, if target == "all" then "sell:all" else `sell:{target}`)
		Net.Fire("Notify", player, "sell.sold", { n = total }) -- (AnalyticsHooks logs first_sell from the Koin gain)
		InventoryService.Sync(player)
		if firstSale then
			data.guide.saleCutscene = true
			TutorialService.OnFirstSellSuccess(player, npc.id)
		end
	end
	if total == 0 then
		Net.Fire("Notify", player, "sell.nothing")
	end
end

-- Buying ---------------------------------------------------------------------------
-- Each function returns true when the purchase went through.

-- Koin + bahan (Bab 6.3 / 17.5). Bahan belum ada sumber (P2-1 Nambang): gagal aman, tidak belanja apa pun.
local function payMats(player: Player, mats: { { id: string, count: number } }): boolean
	for _, mat in mats do
		if InventoryService.Count(player, mat.id) < mat.count then
			return false
		end
	end
	for _, mat in mats do
		InventoryService.Remove(player, mat.id, mat.count)
	end
	return true
end

local function buyRod(player: Player, data: Types.PlayerData, rodId: string): boolean
	local rod = Fishing.rods[rodId]
	if not rod or rod.price <= 0 or data.fishing.ownedRods[rodId] then
		return false
	end
	if data.level < rod.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = rod.unlockLevel })
		return false
	end
	if not EconomyService.TrySpend(player, "koin", rod.price, `rod:{rodId}`) then
		notEnough(player)
		return false
	end
	if not payMats(player, rod.mats) then
		EconomyService.Add(player, "koin", rod.price, `rod:{rodId}:refund`)
		Net.Fire("Notify", player, "shop.no_mats")
		return false
	end
	data.fishing.ownedRods[rodId] = true
	data.fishing.rod = rodId
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "shop.bought", { item = `rod.{rodId}` })
	return true
end

-- Owned tools are checked by FarmService when the player waters (gembor garis).
local function buyTool(player: Player, data: Types.PlayerData, toolId: string): boolean
	local tool = Farm.TOOLS[toolId]
	if not tool or data.tools[toolId] == true then
		return false
	end
	if data.level < tool.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = tool.unlockLevel })
		return false
	end
	if not EconomyService.TrySpend(player, "koin", tool.price, `tool:{toolId}`) then
		notEnough(player)
		return false
	end
	if not payMats(player, tool.mats) then
		EconomyService.Add(player, "koin", tool.price, `tool:{toolId}:refund`)
		Net.Fire("Notify", player, "shop.no_mats")
		return false
	end
	data.tools[toolId] = true
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "shop.bought", { item = `tool.{toolId}` })
	return true
end

local function buyBait(player: Player, data: Types.PlayerData, baitId: string, amount: any): boolean
	local bait = Fishing.baitsById[baitId]
	if not bait or not validPack(amount) then
		return false
	end
	if bait.unlockLevel and data.level < bait.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = bait.unlockLevel })
		return false
	end
	if not InventoryService.CanAdd(player, baitId, amount) then
		return false
	end
	if not EconomyService.TrySpend(player, "koin", bait.price * amount, `bait:{baitId}`) then
		notEnough(player)
		return false
	end
	InventoryService.Add(player, baitId, amount)
	Net.Fire("Notify", player, "shop.bought", { item = `item.{baitId}` })
	return true
end

-- Bahan masak (Garam, Config/Shop SUPPLIES): pola buyBait, tanpa level gate (v7.3 tak memberi gate).
local function buySupply(player: Player, supplyId: string, amount: any): boolean
	local supply = Shop.SUPPLIES[supplyId]
	if not supply or not validPack(amount) then
		return false
	end
	if not InventoryService.CanAdd(player, supplyId, amount) then
		return false
	end
	if not EconomyService.TrySpend(player, "koin", supply.price * amount, `supply:{supplyId}`) then
		notEnough(player)
		return false
	end
	InventoryService.Add(player, supplyId, amount)
	Net.Fire("Notify", player, "shop.bought", { item = `item.{supplyId}` })
	return true
end

local function buyUpgrade(player: Player, data: Types.PlayerData, upgradeId: string): boolean
	return UpgradeService.Buy(player, data, upgradeId)
end

-- Blueprint bukan gating (Bab 8.7): dekor langsung di-craft pakai bahan. Blueprint hanya simpan / share desain (belum di-code).
-- Bibit Unggul DIHAPUS (Bab 29): yang dijual cuma bibit biasa.

-- Seeds go into the bag; planting uses them (FarmService).
local function buySeed(player: Player, data: Types.PlayerData, cropId: string, amount: any): boolean
	local crop = Crops.byId[cropId]
	if not crop or not validPack(amount) then
		return false
	end
	if data.level < crop.unlockLevel then
		Net.Fire("Notify", player, "shop.locked", { level = crop.unlockLevel })
		return false
	end
	local itemId = "seed_" .. crop.id
	if not InventoryService.CanAdd(player, itemId, amount) then
		return false
	end
	local cost = Trade.seedPrice(crop) * amount
	if not EconomyService.TrySpend(player, "koin", cost, `seed:{crop.id}`) then
		notEnough(player)
		return false
	end
	InventoryService.Add(player, itemId, amount)
	Net.Fire("Notify", player, "shop.bought_seed", { n = amount, crop = `crop.{crop.id}` })
	return true
end

-- Kak Fajar sells common/uncommon fish (size Kecil) so orders and the Book don't depend on luck.
local function buyFish(player: Player, fishId: string, amount: any): boolean
	local fish = FishConfig.byId[fishId]
	if not fish or not Npcs.FISH_FOR_SALE[fish.rarity] or not validPack(amount) then
		return false
	end
	local itemId = FishService.ItemId(fish.id, "S")
	if not InventoryService.CanAdd(player, itemId, amount) then
		return false
	end
	local cost = Trade.fishPrice(fish.sellPrice) * amount
	if not EconomyService.TrySpend(player, "koin", cost, `fish:{fish.id}`) then
		notEnough(player)
		return false
	end
	InventoryService.Add(player, itemId, amount)
	Net.Fire("Notify", player, "shop.bought_fish", { n = amount, fish = `fish.{fish.id}` })
	return true
end

local function onBuy(player: Player, npcId: any, kind: any, id: any, amount: any)
	if typeof(kind) ~= "string" or typeof(id) ~= "string" then
		return
	end
	local npc = npcNear(player, npcId)
	local data = DataService.Get(player)
	if not npc or not data then
		return
	end
	if kind == "rod" and npc.sells.rods then
		buyRod(player, data, id)
	elseif kind == "bait" and npc.sells.bait then
		buyBait(player, data, id, amount)
	elseif kind == "supply" and npc.sells.supplies then
		buySupply(player, id, amount)
	elseif kind == "upgrade" and npc.sells.upgrades then
		buyUpgrade(player, data, id)
	elseif kind == "seed" and npc.sells.seeds then
		buySeed(player, data, id, amount)
	elseif kind == "fish" and npc.sells.fish then
		buyFish(player, id, amount)
	elseif kind == "tool" and npc.sells.tools then
		buyTool(player, data, id)
	end
end

local function onEquipRod(player: Player, rodId: any)
	local data = DataService.Get(player)
	if data and typeof(rodId) == "string" and data.fishing.ownedRods[rodId] and Fishing.rods[rodId] then
		data.fishing.rod = rodId
		InventoryService.Sync(player)
	end
end

function ShopService.Start()
	Net.On("Sell", onSell, RATE)
	Net.On("ShopBuy", onBuy, RATE)
	Net.On("ShopEquipRod", onEquipRod, RATE)
end

return ShopService
