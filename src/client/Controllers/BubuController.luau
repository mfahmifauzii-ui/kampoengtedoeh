--!strict
-- Bubu (GDD 6.6, R2.1b): one round button in the Tombol Aksi row, left of the Pancing button.
--   "Ambil" when a placed bubu is SIAP and the player stands within reach of its post.
--   "Pasang" when the player stands in the river near a fishing spot, owns a bubu and has fewer than the max placed.
-- The server decides everything (rules, price, timer); this is presentation and input only.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bubu = require(ReplicatedStorage.Shared.Config.Bubu)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local UiKit = require(script.Parent.Parent.UiKit)
local AksiSlot = require(script.Parent.Parent.AksiSlot)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local BubuController = {}

local REACH = Bubu.PLACE_DISTANCE -- studs, same as the server's check
local RIVER = { sungai_lahan = true, sungai = true }
local KINDS = { "bambu", "kayu", "besi" } -- order of the Pasang choice: the cheapest bubu the player owns

local button: TextButton? = nil
local pendingAction: (() -> ())? = nil

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- Distance to the nearest river spot in reach, nil when none (K-104: it is the Aksi slot's distance for Pasang).
local function nearRiver(pos: Vector3): number?
	local best: number? = nil
	for _, spot in CollectionService:GetTagged("FishingSpot") do
		local location = spot:GetAttribute("Location")
		if spot:IsA("BasePart") and typeof(location) == "string" and RIVER[location] then
			local distance = (spot.Position - pos).Magnitude
			if distance <= REACH and (best == nil or distance < best) then
				best = distance
			end
		end
	end
	return best
end

local function ownedKind(snap: any): string?
	for _, kind in KINDS do
		local def = Bubu.TYPES[kind]
		if (snap.items[def.item] or 0) > 0 then
			return kind
		end
	end
	return nil
end

-- Decides what the button does right now. Ambil wins over Pasang. Also returns the distance to the object it acts on
-- (the Aksi slot's probe, K-104). Nothing (nil text) when no action is possible.
local function decide(): (string?, (() -> ())?, number?)
	local snap = State.current
	local pos = rootPosition()
	local fishing = player:GetAttribute("FishingActive") == true
	if snap and snap.bubu and pos and not fishing and not UiKit.anyPanelOpen() then
		for _, entry in snap.bubu.list do
			if entry.ready and entry.pos then
				local post = Vector3.new(entry.pos[1], entry.pos[2], entry.pos[3])
				if (post - pos).Magnitude <= REACH then
					local uid = entry.uid
					return Locale.t("bubu.btn_collect"), function()
						Net.Send("BubuCollect", uid)
					end, (post - pos).Magnitude
				end
			end
		end
		local river = nearRiver(pos)
		if river and #snap.bubu.list < snap.bubu.max then
			local kind = ownedKind(snap)
			if kind then
				return Locale.t("bubu.btn_place"), function()
					Net.Send("BubuPlace", kind)
				end, river
			end
		end
	end
	return nil, nil, nil
end

local function refresh()
	if not button then
		return
	end
	local text, action = decide()
	pendingAction = action
	if text then
		button.Text = text
	end
end

-- K-104: the Aksi slot's probe for Bubu (visibility is AksiSlot's, see AksiSlot.luau).
local function bubuProbe(): (number?, string?)
	local text, _action, distance = decide()
	return if text then distance else nil, nil
end

AksiSlot.register("bubu", 3, bubuProbe, function(visible: boolean)
	if button then
		button.Visible = visible
	end
end)

function BubuController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BubuAksi"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = UiKit.LAYER.ACTION
	gui.Parent = playerGui

	local b = UiKit.button(gui, "BubuButton", "", UiKit.BUTTON)
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.fromScale(0.68, 0.67) -- left of the Pancing round button (0.8, 0.67)
	b.Size = UDim2.fromOffset(84, 84)
	b.TextSize = 18
	b.Visible = false
	b.Activated:Connect(function()
		if pendingAction then
			pendingAction()
		end
	end)
	button = b
end

function BubuController.Start()
	State.Changed:Connect(refresh)
	task.spawn(function()
		while true do
			refresh()
			task.wait(0.25)
		end
	end)
end

return BubuController
