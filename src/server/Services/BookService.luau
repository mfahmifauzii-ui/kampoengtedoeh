--!strict
-- Collection Book: records first harvest / catch (+ best fish size) / first placement. A finished category or a
-- reached milestone is claimed by hand (BookClaim), so the reward is never a surprise.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Book = require(ReplicatedStorage.Shared.Config.Book)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local Progression = require(ReplicatedStorage.Shared.Config.Progression)

local BookService = {}

local TOTAL = 0
for _, category in Book.CATEGORIES do
	TOTAL += #Book.ENTRIES[category]
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
	local total = 0
	for _, category in Book.CATEGORIES do
		local count = countIn(data, category)
		total += count
		local key = `cat:{category}`
		if count == #Book.ENTRIES[category] and not data.book.claimed[key] then
			Net.Fire("Notify", player, "book.category_done", { category = `book.cat.{category}` })
		end
	end

	local percent = total / TOTAL * 100
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
			reward = Book.CATEGORY_REWARDS[category]
		end
	else
		for _, milestone in Book.MILESTONES do
			if milestone.id == key then
				local total = 0
				for _, c in Book.CATEGORIES do
					total += countIn(data, c)
				end
				if total / TOTAL * 100 >= milestone.percent then
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

function BookService.RecordCrop(player: Player, cropId: string)
	record(player, "crops", cropId, true, `crop.{cropId}`)
end

function BookService.RecordFish(player: Player, fishId: string, size: string)
	local sizeIndex = 1
	for index, entry in FishConfig.SIZES do
		if entry.id == size then
			sizeIndex = index
		end
	end
	record(player, "fish", fishId, sizeIndex, `fish.{fishId}`)
end

function BookService.RecordDecor(player: Player, decorId: string)
	record(player, "decor", decorId, true, `decor.{decorId}`)
end

return BookService
