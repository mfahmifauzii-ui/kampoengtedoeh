--!strict
-- The bobber of every fishing player, animated on each client (K-108, owner 2026-11-24 butir 4). The server makes the model
-- (rod, line, a Bobber part that is anchored and does not collide) and sets these attributes on it:
--   From    Vector3  the rod tip when the cast starts        Land   Vector3  the water point (Bobber.landing)
--   CastAt  number   server time of the cast                  BiteAt number   server time of a bite (optional)
-- Each client moves ONLY its own view of the bobber (CFrame of an anchored part), so it looks the same everywhere:
--   0.0-0.5 s   a parabola from the rod tip to the landing point
--   landing     a small splash ring (a part of its own, destroyed after 1 s)
--   after       floats at the water height with a slight bob
--   on a bite   dips 0.4 studs and back over 0.25 s
-- No Touched, no physics. Every part made here has a lifetime (Debris or a delayed Destroy). The model is destroyed by the
-- server at every end (reel, cancel, death, leaving); this loop forgets it when it is gone.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BobberVisuals = {}

local FLIGHT = 0.5 -- s: the cast flight
local ARC = 2.5 -- studs: the height of the parabola above the straight line
local BOB = 0.06 -- studs: the float's bob
local BOB_RATE = 2 -- rad per second
local DIP = 0.4 -- studs
local DIP_SECONDS = 0.25
local SPLASH_SECONDS = 0.9
local FOLDER = "FishingVisuals"

type Anim = { splashed: boolean }
local anims: { [Model]: Anim } = {}

local function splash(at: Vector3)
	local ring = Instance.new("Part")
	ring.Name = "Splash"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = Color3.fromRGB(230, 245, 255)
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.1, 1, 1)
	ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(SPLASH_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, 6, 6),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, SPLASH_SECONDS + 0.2)
end

local function animate(model: Model, bobber: BasePart, now: number)
	local from = model:GetAttribute("From")
	local land = model:GetAttribute("Land")
	local castAt = model:GetAttribute("CastAt")
	if typeof(from) ~= "Vector3" or typeof(land) ~= "Vector3" or typeof(castAt) ~= "number" then
		return
	end
	local anim = anims[model]
	if not anim then
		anim = { splashed = false }
		anims[model] = anim
	end
	local age = now - castAt
	local position: Vector3
	if age < FLIGHT then
		local k = math.max(age, 0) / FLIGHT
		position = from:Lerp(land, k) + Vector3.new(0, ARC * 4 * k * (1 - k), 0)
	else
		if not anim.splashed then
			anim.splashed = true
			splash(land)
		end
		position = land + Vector3.new(0, math.sin((age - FLIGHT) * BOB_RATE) * BOB, 0)
	end
	local biteAt = model:GetAttribute("BiteAt")
	if typeof(biteAt) == "number" and now - biteAt >= 0 and now - biteAt < DIP_SECONDS then
		position -= Vector3.new(0, DIP * math.sin(math.pi * (now - biteAt) / DIP_SECONDS), 0)
	end
	bobber.CFrame = CFrame.new(position)
end

-- Starts the per-frame animation for every fishing visual in the world (every player's, not only one's own).
function BobberVisuals.Start()
	RunService.RenderStepped:Connect(function()
		local folder = Workspace:FindFirstChild(FOLDER)
		if not folder then
			return
		end
		local now = Workspace:GetServerTimeNow()
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				local bobber = child:FindFirstChild("Bobber")
				if bobber and bobber:IsA("BasePart") then
					animate(child, bobber, now)
				end
			end
		end
		for model in anims do
			if not model.Parent then
				anims[model] = nil
			end
		end
	end)
end

return BobberVisuals
