--!strict
-- Collection Book: records first harvest / catch (+ best fish size) / first placement,
-- then auto-grants category and overall milestone rewards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Book = require(ReplicatedStorage.Shared.Config.Book)
local FishConfig = require(ReplicatedStorage.Shared.Config.Fish)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

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

local function checkRewards(player: Player, data: Types.PlayerData)
	local total = 0
	for _, category in Book.CATEGORIES do
		local count = countIn(data, category)
		total += count
		local key = `cat:{category}`
		if count == #Book.ENTRIES[category] and not data.book.claimed[key] then
			data.book.claimed[key] = true
			ProgressionService.Grant(player, Book.CATEGORY_REWARDS[category], `book:{key}`)
			Net.Fire("Notify", player, "book.category_done", { category = `book.cat.{category}` })
		end
	end

	local percent = total / TOTAL * 100
	for _, milestone in Book.MILESTONES do
		if percent >= milestone.percent and not data.book.claimed[milestone.id] then
			data.book.claimed[milestone.id] = true
			ProgressionService.Grant(player, milestone.reward, `book:{milestone.id}`)
			Net.Fire("Notify", player, "book.milestone", { percent = milestone.percent })
		end
	end
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
		checkRewards(player, data)
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
