--!strict
-- Where the bobber lands (K-108, owner 2026-11-24 butir 4): on the WATER surface, never on the bank.
-- Bobber.landing(spot): a ray from above the fishing spot, with water counted (IgnoreWater = false). The first water hit is the
-- surface. If the ray hits no water, the spot's attribute "WaterY" (a number, set in Studio on a spot by the river) is used.
-- If neither exists, the spot's top is used and a warning is logged, so a spot with no water is found in the output.
-- Used on the server (FishService, the visuals every player sees) and on the client (the tutorial's local bobber).

local Workspace = game:GetService("Workspace")

local Bobber = {}

local TOP_ABOVE = 30 -- studs above the spot the ray starts
local DEPTH = 60 -- studs the ray goes down
local SURFACE_LIFT = 0.05 -- studs above the water hit (no z-fighting with the surface)

function Bobber.landing(spot: BasePart): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { spot }
	params.IgnoreWater = false
	local hit = Workspace:Raycast(spot.Position + Vector3.new(0, TOP_ABOVE, 0), Vector3.new(0, -DEPTH, 0), params)
	if hit and hit.Material == Enum.Material.Water then
		return hit.Position + Vector3.new(0, SURFACE_LIFT, 0)
	end
	local level = spot:GetAttribute("WaterY")
	if typeof(level) == "number" then
		return Vector3.new(spot.Position.X, level + SURFACE_LIFT, spot.Position.Z)
	end
	warn(`[Bobber] no water under spot {spot:GetFullName()}; set WaterY on it`)
	return spot.Position + Vector3.new(0, spot.Size.Y / 2 + 0.3, 0)
end

return Bobber
