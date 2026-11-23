--!strict
-- Dapur (docs/01_GDD_Kampoeng_Tedoeh_v8.4.md Bab 9.1 / 9.2 / 9.4, LOCKED): bangun/upgrade Inti, slot masak,
-- 24 resep, Kualitas Olahan dari bahan tertinggi, makan = 1 buff aktif (ganti lama, tidak stack).
-- 1 resep per slot, TIDAK ada antrean. Olahan jalan walau offline, tidak gosong/gagal.
-- Pakan Jagung = pakan Ayam (bahan), BUKAN Olahan: tidak dijual di Warung, tidak memberi buff.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Buffs = require(ReplicatedStorage.Shared.Config.Buffs)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Dapur = require(ReplicatedStorage.Shared.Config.Dapur)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Items = require(ReplicatedStorage.Shared.Modules.Items)
local Land = require(ReplicatedStorage.Shared.Modules.Land)
local DecorGrid = require(ReplicatedStorage.Shared.Modules.DecorGrid)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local random = Random.new()
local DataService = require(script.Parent.DataService)
local FeatureGate = require(script.Parent.FeatureGate)
local InventoryService = require(script.Parent.InventoryService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local BookService = require(script.Parent.BookService)

local RATE = { rate = 4, burst = 8 }
local QUALITY_RANK = { biasa = 1, bagus = 2, prima = 3 }
-- K-05: ukuran ikan = kualitas bahan (Kecil/Sedang = Biasa, Besar = Bagus, Jumbo = Prima).
local FISH_SIZE_QUALITY: { [string]: string } = { S = "biasa", M = "biasa", L = "bagus", Jumbo = "prima" }

local DapurService = {}

-- Bahan -----------------------------------------------------------------------

local function qualityRank(quality: string): number
	return QUALITY_RANK[quality] or 0
end

local function fishItemId(fishId: string, size: string): string
	return `{fishId}@{size}`
end

-- "{kualitas}_{resep}" atau "{kualitas}_{resep}_{base}" -> (resep, kualitas). Nil bila bukan olahan.
local function parseOlahanId(itemId: string): (string?, string?)
	local quality, rest = itemId:match("^(biasa|bagus|prima)_(.+)$")
	if not quality then
		return nil, nil
	end
	if Dapur.byId[rest] then
		return rest, quality
	end
	local recipe = rest:match("^(.+)_([0-9]+)$")
	if recipe and Dapur.byId[recipe] then
		return recipe, quality
	end
	return nil, nil
end

-- Hitung bahan: kembalikan (bisa, kualitasTertinggi, nilaiBase). Konsumsi yang termurah dulu
-- (Biasa -> Bagus -> Prima). Nilai = base tanpa mult (kecuali olahan: base resepnya).
local function takeInputs(player: Player, data: Types.PlayerData, recipe: Dapur.Recipe): (boolean, string, number)
	local best, value = "biasa", 0
	local takes: { { id: string, count: number } } = {}

	local function needCrop(cropId: string, count: number): boolean
		local crop = Crops.byId[cropId]
		if not crop then
			return false
		end
		local variants: { { id: string, quality: string } } = {
			{ id = cropId, quality = "biasa" },
			{ id = `bagus_{cropId}`, quality = "bagus" },
			{ id = `prima_{cropId}`, quality = "prima" },
		}
		local have = 0
		for _, variant in variants do
			have += InventoryService.Count(player, variant.id)
		end
		if have < count then
			return false
		end
		local left = count
		for _, variant in variants do
			if left <= 0 then
				break
			end
			local take = math.min(left, InventoryService.Count(player, variant.id))
			if take > 0 then
				table.insert(takes, { id = variant.id, count = take })
				left -= take
				if qualityRank(variant.quality) > qualityRank(best) then
					best = variant.quality
				end
			end
		end
		value += crop.sellPrice * count
		return true
	end

	local function needFish(cat: string, count: number): boolean
		local rarity = Dapur.FISH_CAT[cat]
		if not rarity then
			return false
		end
		local left = count
		for _, fish in FishConfig.list do
			if left <= 0 then
				break
			end
			if fish.rarity == rarity then
				for _, size in FishConfig.SIZES do
					if left <= 0 then
						break
					end
					local id = fishItemId(fish.id, size.id)
					local take = math.min(left, InventoryService.Count(player, id))
					if take > 0 then
						table.insert(takes, { id = id, count = take })
						left -= take
						value += fish.sellPrice * take
						local sizeQ = FISH_SIZE_QUALITY[size.id] or "biasa"
						if qualityRank(sizeQ) > qualityRank(best) then
							best = sizeQ
						end
					end
				end
			end
		end
		return left <= 0
	end

	for _, input in recipe.inputs do
		if input.kind == "crop" and input.id then
			if not needCrop(input.id, input.count) then
				return false, best, 0
			end
		elseif input.kind == "fish" and input.cat then
			if not needFish(input.cat, input.count) then
				return false, best, 0
			end
		elseif input.kind == "garam" then
			if InventoryService.Count(player, "garam") < input.count then
				return false, best, 0
			end
			table.insert(takes, { id = "garam", count = input.count })
			value += Dapur.GARAM_PRICE * input.count
		elseif input.kind == "bahan" and input.id then
			if InventoryService.Count(player, input.id) < input.count then
				return false, best, 0
			end
			table.insert(takes, { id = input.id, count = input.count })
		elseif input.kind == "ternak" and input.id then
			-- K-05: telur/susu biasa dulu, lalu Bagus (Mood Hujan). Kualitas tertinggi ikut ke olahan.
			local bagusId = `bagus_{input.id}`
			local haveBiasa = InventoryService.Count(player, input.id)
			local haveBagus = InventoryService.Count(player, bagusId)
			if haveBiasa + haveBagus < input.count then
				return false, best, 0
			end
			local leftT = input.count
			local takeBiasa = math.min(leftT, haveBiasa)
			if takeBiasa > 0 then
				table.insert(takes, { id = input.id, count = takeBiasa })
				leftT -= takeBiasa
			end
			if leftT > 0 then
				table.insert(takes, { id = bagusId, count = leftT })
				if qualityRank("bagus") > qualityRank(best) then
					best = "bagus"
				end
			end
			local info = Items.info(input.id)
			value += (if info and info.sellPrice then info.sellPrice else 0) * input.count
		elseif input.kind == "olahan" and input.id then
			local target = Dapur.byId[input.id]
			if not target or not target.sell then
				return false, best, 0 -- hanya olahan base FIXED yang bisa jadi bahan
			end
			local left = input.count
			for _, q in { "biasa", "bagus", "prima" } do
				if left <= 0 then
					break
				end
				-- Id olahan bisa berekor base ("{q}_{resep}_{base}"): cocokkan semua variannya.
				for itemId, n in data.inventory do
					if left <= 0 then
						break
					end
					local rr, rq = parseOlahanId(itemId)
					if rq == q and rr == input.id and n > 0 then
						local take = math.min(left, n)
						table.insert(takes, { id = itemId, count = take })
						left -= take
						if qualityRank(q) > qualityRank(best) then
							best = q
						end
					end
				end
			end
			if left > 0 then
				return false, best, 0
			end
			value += target.sell * input.count
		else
			return false, best, 0
		end
	end

	for _, take in takes do
		InventoryService.Remove(player, take.id, take.count)
	end
	return true, best, value
end

-- parseOlahanId dipakai lintas fungsi (Eat + panel): expose lewat DapurService.
function DapurService.ParseOlahan(itemId: string): (string?, string?)
	return parseOlahanId(itemId)
end

local function nearPlot(player: Player): boolean
	local plot = PlotService.GetPlot(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not plot.PrimaryPart or not root or not root:IsA("BasePart") then
		return false
	end
	return (plot:GetPivot().Position - root.Position).Magnitude <= 60
end

-- Bangunan --------------------------------------------------------------------

local WOOD = Color3.fromRGB(150, 110, 70)
local STONE = Color3.fromRGB(150, 146, 138)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function getFolder(plot: Model): Folder
	local existing = plot:FindFirstChild("Dapur")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Dapur"
	folder.Parent = plot
	return folder
end

local function decorRects(data: Types.PlayerData): { Land.Rect }
	local rects: { Land.Rect } = Land.takenRects(data.pond.list, Dapur.buildings(data.ranch.kandang, data.dapur.spot, data.warung.spot), Dapur.BUILDING_SIZES)
	for _, entry in data.decor.placed do
		local rect = DecorGrid.entryRect(entry)
		if rect then
			table.insert(rects, rect)
		end
	end
	return rects
end

local function findSpot(data: Types.PlayerData): (number?, number?)
	local existing = Land.ranchRects(Dapur.buildings(data.ranch.kandang, data.dapur.spot, data.warung.spot), Dapur.BUILDING_SIZES)
	local half = Land.REGION_HALF // Land.TILE
	for cz = -half, half do
		for cx = -half, half do
			if Land.canRanch(cx, cz, Dapur.DAPUR_SIZE[1], Dapur.DAPUR_SIZE[2], data.farm.tiles, data.pond.list, existing, decorRects(data), data.land.chunks) then
				return cx, cz
			end
		end
	end
	return nil, nil
end

local function buildLook(plot: Model, entry: { cx: number, cz: number })
	local origin = plot.PrimaryPart
	if not origin then
		return
	end
	local folder = getFolder(plot)
	local old = folder:FindFirstChild("Tungku")
	if old then
		old:Destroy()
	end
	local size = Dapur.DAPUR_SIZE
	local rect = Land.ranchRect(entry.cx, entry.cz, size[1], size[2])
	local topY = origin.Position.Y + origin.Size.Y / 2
	local center = origin.CFrame * Vector3.new((rect.minX + rect.maxX) / 2, 0, (rect.minZ + rect.maxZ) / 2)
	local look = Instance.new("Folder")
	look.Name = "Tungku"
	part(look, "Floor", Vector3.new(16, 0.5, 16), CFrame.new(center.X, topY + 0.25, center.Z), STONE)
	part(look, "Stove", Vector3.new(3, 2, 3), CFrame.new(center.X - 3, topY + 1, center.Z), STONE)
	part(look, "Table", Vector3.new(5, 0.4, 3), CFrame.new(center.X + 3.5, topY + 1.6, center.Z), WOOD)
	part(look, "Sign", Vector3.new(3, 1, 0.3), CFrame.new(center.X, topY + 3.4, center.Z + 8), WOOD)
	look.Parent = folder
end

local function buildAll(player: Player, plot: Model)
	local data = DataService.Get(player)
	if data and data.dapur.spot then
		buildLook(plot, data.dapur.spot)
	end
end

local function clearPlot(plot: Model)
	local folder = plot:FindFirstChild("Dapur")
	if folder then
		folder:Destroy()
	end
end

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

-- Aksi --------------------------------------------------------------------------

-- Bangun Inti Tier 1 (Lv 6). Tanpa Koin, hanya bahan (v7.3 tak memberi harga Koin).
local function onBuild(player: Player)
	if not FeatureGate.Check(player, "dapur") then return end
	local data = DataService.Get(player)
	if not data or data.dapur.tier > 0 then
		return
	end
	if not nearPlot(player) then
		return
	end
	local tierDef = Dapur.TIERS[1]
	if data.level < tierDef.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = tierDef.unlockLevel })
		return
	end
	if not payMats(player, tierDef.mats) then
		Net.Fire("Notify", player, "dapur.no_mats")
		return
	end
	local cx, cz = findSpot(data)
	if cx == nil or cz == nil then
		Net.Fire("Notify", player, "ranch.no_space")
		return
	end
	data.dapur.tier = 1
	data.dapur.slots = { false, false, false }
	data.dapur.spot = { cx = cx :: number, cz = cz :: number }
	local plot = PlotService.GetPlot(player)
	if plot then
		buildLook(plot, data.dapur.spot)
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "dapur.built")
	QuestService.Report(player, "dapur_built") -- MQ7 Dapur Pertama (Bab 14.2)
end

-- Upgrade: craft Inti baru, ganti lama, refund 100% mats lama. Olahan berjalan tidak hilang.
local function onUpgrade(player: Player)
	local data = DataService.Get(player)
	if not data or data.dapur.tier < 1 or data.dapur.tier >= #Dapur.TIERS then
		return
	end
	if not nearPlot(player) then
		return
	end
	local nextDef = Dapur.TIERS[data.dapur.tier + 1]
	if data.level < nextDef.unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = nextDef.unlockLevel })
		return
	end
	if not payMats(player, nextDef.mats) then
		Net.Fire("Notify", player, "dapur.no_mats")
		return
	end
	local oldDef = Dapur.TIERS[data.dapur.tier]
	for _, mat in oldDef.mats do
		InventoryService.Add(player, mat.id, mat.count)
	end
	data.dapur.tier += 1
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "dapur.upgraded", { n = data.dapur.tier })
end

local function outputId(recipe: Dapur.Recipe, quality: string, base: number): string
	if recipe.id == "pakan_jagung" then
		return "pakan_jagung"
	end
	if recipe.mult then
		return `{quality}_{recipe.id}_{base}`
	end
	return `{quality}_{recipe.id}`
end

-- Masak: slot 0 = otomatis (slot kosong pertama). Kualitas dihitung saat mulai.
local function onCook(player: Player, slot: any, recipeId: any)
	if not FeatureGate.Check(player, "dapur") then return end
	if typeof(slot) ~= "number" or typeof(recipeId) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	local recipe = Dapur.byId[recipeId]
	if not data or not recipe then
		return
	end
	if data.dapur.tier < 1 then
		Net.Fire("Notify", player, "dapur.need_build")
		return
	end
	if recipe.tier > data.dapur.tier then
		Net.Fire("Notify", player, "fish.locked", { level = Dapur.TIERS[recipe.tier].unlockLevel })
		return
	end
	if data.level < Dapur.TIERS[recipe.tier].unlockLevel then
		Net.Fire("Notify", player, "fish.locked", { level = Dapur.TIERS[recipe.tier].unlockLevel })
		return
	end
	local maxSlots = Dapur.TIERS[data.dapur.tier].slots
	if slot <= 0 then
		slot = nil
		for i = 1, maxSlots do
			if not data.dapur.slots[i] then
				slot = i
				break
			end
		end
		if slot == nil then
			Net.Fire("Notify", player, "dapur.busy")
			return
		end
	elseif slot ~= math.floor(slot) or slot < 1 or slot > maxSlots or data.dapur.slots[slot] then
		Net.Fire("Notify", player, "dapur.busy")
		return
	end
	local ok, quality, value = takeInputs(player, data, recipe)
	if not ok then
		Net.Fire("Notify", player, "dapur.no_mats")
		return
	end
	-- Skill Koki Cepat (Bab 4.5, P2-4): waktu olah -3%/lv.
	local cookMult = Dapur.TIERS[data.dapur.tier].timeMult * (1 - 0.03 * (data.skill.koki_cepat or 0))
	local dur = math.floor(recipe.minutes * 60 * cookMult + 0.5)
	local now = os.time()
	-- Resep 1.6x: base dihitung dari bahan YANG DIPAKAI (contoh Wader 70x1.6=112->110).
	local base = 0
	if recipe.mult then
		base = math.floor(value * recipe.mult / 10 + 0.5) * 10
	end
	-- Skill Rasa Prima (Bab 4.5, P2-4): peluang Olahan Prima +1%/lv (dari bahan tertinggi).
	if quality ~= "prima" and random:NextNumber() < 0.01 * (data.skill.rasa_prima or 0) then
		quality = if quality == "biasa" then "bagus" else "prima" -- K-05 (a): naik 1 tingkat, bukan langsung Prima
	end
	data.dapur.slots[slot :: number] = { recipe = recipe.id, startedAt = now, endsAt = now + dur, quality = quality, base = base }
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "dapur.cooking", { item = `olahan.{recipe.id}` })
end

local function onCollect(player: Player, slot: any)
	if typeof(slot) ~= "number" then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local entry = data.dapur.slots[slot]
	if not entry then
		return
	end
	if os.time() < entry.endsAt then
		Net.Fire("Notify", player, "dapur.wait", { s = entry.endsAt - os.time() })
		return
	end
	local recipe = Dapur.byId[entry.recipe]
	if not recipe then
		data.dapur.slots[slot] = false
		return
	end
	local count = recipe.outputCount or 1
	local id = outputId(recipe, entry.quality, entry.base or 0)
	if not InventoryService.Add(player, id, count) then
		return
	end
	data.dapur.slots[slot] = false
	ProgressionService.AddXp(player, recipe.xp, `cook:{recipe.id}`)
	QuestService.Report(player, "cook") -- Agenda "Masak 1 olahan" (Bab 14.5)
	if recipe.id ~= "pakan_jagung" then
		BookService.RecordDapur(player, recipe.id, entry.quality)
	end
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "dapur.done", { n = count, item = if recipe.id == "pakan_jagung" then "item.pakan_jagung" else `olahan.{recipe.id}` })
end

-- Makan 1 Olahan = 1 buff aktif (ganti lama, tidak stack). Dijual ATAU dimakan, tidak dua-duanya.
-- Pakan Jagung bukan Olahan: tidak bisa dimakan jadi buff.
local function publishBuff(player: Player, buffId: string?, dur: number, endsAt: number)
	local now = Workspace:GetServerTimeNow()
	for _, def in Buffs.SLOTS do
		if buffId and def.id == buffId then
			player:SetAttribute(`Buff_{def.id}_End`, endsAt)
			player:SetAttribute(`Buff_{def.id}_Dur`, dur)
		else
			player:SetAttribute(`Buff_{def.id}_End`, now)
			player:SetAttribute(`Buff_{def.id}_Dur`, 0)
		end
	end
end

local function onEat(player: Player, itemId: any)
	if typeof(itemId) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local info = Items.info(itemId)
	if not info or info.kind ~= "olahan" then
		Net.Fire("Notify", player, "dapur.not_food")
		return
	end
	local recipeId = parseOlahanId(itemId)
	local buffId = recipeId and Dapur.BUFF_BY_RECIPE[recipeId] or nil
	if not recipeId or not buffId then
		Net.Fire("Notify", player, "dapur.no_buff")
		return
	end
	if InventoryService.Count(player, itemId) < 1 then
		return
	end
	local quality = itemId:match("^(biasa|bagus|prima)_") or "biasa"
	InventoryService.Remove(player, itemId, 1)
	local dur = Dapur.BUFF_DURATION[quality] or Dapur.BUFF_DURATION.biasa
	local endsAt = os.time() + dur
	data.buff = { id = buffId, endsAt = endsAt }
	publishBuff(player, buffId, dur, endsAt)
	InventoryService.Sync(player)
	Net.Fire("Notify", player, "dapur.buff", { buff = `buff.{buffId}` })
	QuestService.Report(player, "eat") -- Quest M6 langkah 3: Makan 1 olahan
end

function DapurService.Init()
	PlotService.Assigned:Connect(function(player: Player, plot: Model)
		clearPlot(plot) -- sisa pemilik lama
		buildAll(player, plot)
	end)
	PlotService.Released:Connect(function(_player: Player, plot: Model)
		clearPlot(plot)
	end)
end

function DapurService.Start()
	Net.On("DapurBuild", function(player: Player)
		onBuild(player)
	end, RATE)
	Net.On("DapurUpgrade", function(player: Player)
		onUpgrade(player)
	end, RATE)
	Net.On("DapurCook", onCook, RATE)
	Net.On("DapurCollect", onCollect, RATE)
	Net.On("DapurEat", onEat, RATE)
end

return DapurService