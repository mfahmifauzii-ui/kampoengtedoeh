--!strict
-- Album + Toko Bunga (Bab 9-10, P2-7).
-- Album milestone + claim tetap di BookService (Record* + Claim); AlbumService TIDAK duplikat itu.
-- AlbumService di sini menangani: (a) helper klaim milestone delegasi, (b) Toko Bunga
-- (Net "BungaBuy": tukar Bunga dengan dekor langka / bibit varian, harga USULAN Config/Shop).
-- Bunga TIDAK bisa dihadiahkan (SocialService onGift menolak "bunga") dan tidak bisa dibeli pakai Robux
-- sebagai barang (Monetization IAP terpisah, bukan hadiah antar-player).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Types = require(ReplicatedStorage.Shared.Types)
local BookService = require(script.Parent.BookService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)

local AlbumService = {}

local RATE = { rate = 4, burst = 8 }

local function bungaGood(id: string): { id: string, kind: string, bunga: number }?
	for _, good in Shop.BUNGA_GOODS do
		if good.id == id then
			return good
		end
	end
	return nil
end

local function onBungaBuy(player: Player, itemId: any)
	if typeof(itemId) ~= "string" then
		return
	end
	local data: Types.PlayerData? = DataService.Get(player)
	if not data then
		return
	end
	local good = bungaGood(itemId)
	if not good then
		return
	end
	if good.kind == "decor" then
		if not EconomyService.TrySpend(player, "bunga", good.bunga, `bunga:decor:{good.id}`) then
			Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.bunga" })
			return
		end
		data.decor.stock[good.id] = (data.decor.stock[good.id] or 0) + 1
		InventoryService.Sync(player)
		Net.Fire("Notify", player, "bunga.bought", { item = `decor.{good.id}` })
	else -- seed varian: masuk tas (pola Gerobak), perlu cek level seperti belanja biasa
		local cropId = good.id:match("^seed_(.+)$")
		if not cropId then
			return
		end
		if not InventoryService.CanAdd(player, good.id, 1) then
			return
		end
		if not EconomyService.TrySpend(player, "bunga", good.bunga, `bunga:{good.id}`) then
			Net.Fire("Notify", player, "notify.not_enough", { currency = "currency.bunga" })
			return
		end
		InventoryService.Add(player, good.id, 1)
		BookService.RecordVarian(player, good.id)
		Net.Fire("Notify", player, "bunga.bought", { item = `crop.{cropId}` })
	end
end

-- Delegasi klaim milestone/kategori ke BookService (pemilik data Album).
function AlbumService.Claim(player: Player, key: string): boolean
	return BookService.Claim(player, key)
end

function AlbumService.Start()
	Net.On("BungaBuy", onBungaBuy, RATE)
end

return AlbumService
