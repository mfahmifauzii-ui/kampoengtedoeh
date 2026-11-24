--!strict
-- Kerja Bakti (K-117): sampah milik pemain ini. Server yang memutuskan jumlah dan posisi (KBPieces), dan menerima
-- pungutan (KBPick) dengan cek id, jarak, dan sekali saja. Gambarnya hanya di klien pemain ini: part "Sampah" dan
-- prompt "KBPungut" di Workspace.KBLitter (tidak direplikasi). Placeholder: kotak coklat kecil (R4.10 mengganti art).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local FarmFx = require(script.Parent.Parent.FarmFx)

local KerjaBaktiController = {}

local folder: Folder? = nil
local visuals: { [number]: BasePart } = {} -- piece id -> part yang tampil
local sent: { [number]: boolean } = {} -- piece id yang sudah dikirim ke server (tidak dikirim dua kali)

local function clear()
	if folder then
		folder:Destroy()
		folder = nil
	end
	visuals = {}
	sent = {}
end

local function onPieces(positions: any)
	clear()
	if typeof(positions) ~= "table" then return end
	local shown = Instance.new("Folder")
	shown.Name = "KBLitter"
	shown.Parent = Workspace
	folder = shown
	for id, position in positions do
		if typeof(position) ~= "Vector3" then continue end
		local part = Instance.new("Part")
		part.Name = "Sampah"
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(1.2, 0.8, 1.2)
		part.Position = position
		part.Color = Color3.fromRGB(110, 85, 60)
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = shown
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "KBPungut"
		prompt.ActionText = Locale.t("prompt.kb_collect")
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Feature", "gerobak") -- Q-2: FeatureGate.client hides it while the gerobak feature is closed
		prompt.Parent = part
		visuals[id] = part
		prompt.Triggered:Connect(function()
			if sent[id] then return end
			sent[id] = true
			prompt.Enabled = false
			FarmFx.pickUp(part)
			Net.Send("KBPick", id)
		end)
	end
end

local function onPicked(id: any)
	local part = if typeof(id) == "number" then visuals[id] else nil
	if part then
		part:Destroy()
		visuals[id] = nil
	end
end

function KerjaBaktiController.Start()
	Net.Listen("KBPieces", onPieces)
	Net.Listen("KBPicked", onPicked)
	-- Event berakhir (habis, selesai, atau waktu habis): sampah klien ikut hilang.
	Workspace:GetAttributeChangedSignal("KBActive"):Connect(function()
		if Workspace:GetAttribute("KBActive") ~= true then
			clear()
		end
	end)
end

return KerjaBaktiController
