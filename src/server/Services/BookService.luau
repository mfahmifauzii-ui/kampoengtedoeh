--!strict
-- Collection Book (Bab 11 v7.3): 214 entri GUI (ladang 54 + sungai 80 + dapur 72 + varian 8) + tab kandang/rumah.
-- Records first harvest per Kualitas / catch per size / first placement. A finished category or a
-- reached milestone is claimed by hand (BookClaim), so the reward is never a surprise.
-- Milestone = USULAN, bukan LOCKED (BUTUH LOCK OWNER).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Book = require(ReplicatedStorage.Shared.Config.Book)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local Progression = require(ReplicatedStorage.Shared.Config.Progression)

local BookService = {}

-- Milestone dihitung dari 214 entri GUI (kandang + rumah tab terpisah, tidak dihitung).
local TOTAL = 0
for _, category in Book.GUI_CATEGORIES do
	TOTAL += #Book.ENTRIES[category]
end

local function guiTotal(data: Types.PlayerData): number
	local total = 0
	for _, category in Book.GUI_CATEGORIES do
		local recorded = (data.book :: any)[category]
		for _, id in Book.ENTRIES[category] do
			if recorded[id] then
				total += 1
			end
		end
	end
	return total
end

function BookService.AlbumPercent(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	return guiTotal(data) / TOTAL * 100
end

local function countIn(data: Types.PlayerData, category: string): number
	local recorded = (data.book :: any)[category]
	local count = 0
	for _, id in Book.ENTRIES[category] do
		if recorded[id] then
			count += 1
		end
	end
	return count
end

-- Rewards are NOT granted here any more (R3 17.5): a finished category or a reached milestone waits for the player to
-- press "Klaim" (BookService.Claim). This only tells the player once that something is ready to claim.
local function checkReached(player: Player, data: Types.PlayerData)
	for _, category in Book.CATEGORIES do
		local key = `cat:{category}`
		if countIn(data, category) == #Book.ENTRIES[category] and not data.book.claimed[key] then
			Net.Fire("Notify", player, "book.category_done", { category = `book.cat.{category}` })
		end
	end

	local percent = guiTotal(data) / TOTAL * 100
	for _, milestone in Book.MILESTONES do
		if percent >= milestone.percent and not data.book.claimed[milestone.id] then
			Net.Fire("Notify", player, "book.milestone", { percent = milestone.percent })
		end
	end
end

-- Claim a reached category ("cat:<category>") or milestone (its id). Each one pays once.
function BookService.Claim(player: Player, key: string): boolean
	local data = DataService.Get(player)
	if not data or data.book.claimed[key] then
		return false
	end
	local reward: Progression.Reward? = nil
	local category = string.match(key, "^cat:(%w+)$")
	if category and table.find(Book.CATEGORIES, category) then
		if countIn(data, category) == #Book.ENTRIES[category] then
			reward = Book.CATEGORY_REWARDS[category] -- nil untuk kandang/dapur/varian: tidak ada hadiah kategori, klaim tidak membayar
		end
	else
		for _, milestone in Book.MILESTONES do
			if milestone.id == key then
				if guiTotal(data) / TOTAL * 100 >= milestone.percent then
					reward = milestone.reward
				end
			end
		end
	end
	if not reward then
		return false
	end
	data.book.claimed[key] = true
	ProgressionService.Grant(player, reward, `book:{key}`)
	Net.Fire("Notify", player, "book.claim_done")
	return true
end

function BookService.Start()
	Net.On("BookClaim", function(player: Player, key: any)
		if typeof(key) == "string" then
			BookService.Claim(player, key)
		end
	end, { rate = 3, burst = 6 })
end

local function record(player: Player, category: string, id: string, value: any, nameKey: string)
	local data = DataService.Get(player)
	if not data or not table.find(Book.ENTRIES[category], id) then
		return
	end
	local recorded = (data.book :: any)[category]
	local previous = recorded[id]
	if previous ~= nil and (typeof(value) ~= "number" or previous >= value) then
		return
	end
	recorded[id] = value
	if previous == nil then
		Net.Fire("Notify", player, "book.new", { item = nameKey })
		checkReached(player, data)
	end
	InventoryService.Sync(player)
end

function BookService.RecordCrop(player: Player, cropId: string, qualityId: string?)
	local quality = qualityId or "biasa"
	record(player, "ladang", `{cropId}:{quality}`, true, `crop.{cropId}`)
end

function BookService.RecordFish(player: Player, fishId: string, size: string)
	record(player, "sungai", `{fishId}@{size}`, true, `fish.{fishId}`)
end

-- Album Dapur: 24 resep x 3 Kualitas (Bab 11). Direkam saat Olahan diambil (P2-3 Dapur).
function BookService.RecordDapur(player: Player, recipeId: string, quality: string)
	record(player, "dapur", `{recipeId}:{quality}`, true, `olahan.{recipeId}`)
end

-- Album Varian: 6 Bibit + 2 Hewan Varian (Bab 11/13.1, Gerobak Kaget P2-6).
-- id polos (tanpa Kualitas): varian dicatat sekali saat pertama didapat.
function BookService.RecordVarian(player: Player, id: string)
	local nameKey = if Crops.byId[id] then `crop.{id}` else `hewan.{id}`
	record(player, "varian", id, true, nameKey)
end

function BookService.RecordDecor(player: Player, decorId: string)
	record(player, "rumah", decorId, true, `decor.{decorId}`)
end

return BookService
