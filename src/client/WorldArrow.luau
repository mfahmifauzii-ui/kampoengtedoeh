--!strict
-- A big arrow label that sits ABOVE a world part (a bed, the pond). It is a ScreenGui label placed at the part's screen
-- point every frame, the same way the farm popup is placed (FarmController). BillboardGui arrows did not draw in the
-- Studio test (16 Nov), so the T1 and Misi arrows use this instead.
--   local arrow = WorldArrow.new("TutArrow", 9)
--   arrow.show(part, "Tunggu matang")   arrow.hide()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local UiKit = require(script.Parent.UiKit)

local WorldArrow = {}

function WorldArrow.new(name: string, studsAbove: number)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Size = UDim2.fromOffset(280, 46)
	label.BackgroundColor3 = UiKit.DARK
	label.BackgroundTransparency = 0.05
	label.Font = UiKit.FONT
	label.TextSize = 19
	label.TextColor3 = UiKit.CREAM
	label.Text = ""
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	local target: BasePart? = nil
	local baseText = ""
	local EDGE = 150 -- px: an off-screen target's arrow is pinned this far inside the screen edge
	local connection: RBXScriptConnection? = RunService.RenderStepped:Connect(function()
		-- Nothing of the game's UI runs behind the loading / play screen (MenuFlow sets KTMenu "loading" -> "play" -> "done").
		local menu = player:GetAttribute("KTMenu")
		if menu == "loading" or menu == "play" then
			gui.Enabled = false
			return
		end
		if not target or not target.Parent then
			gui.Enabled = false
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local point = target.Position + Vector3.new(0, studsAbove, 0)
		local screen, onScreen = camera:WorldToViewportPoint(point)
		local inset = game:GetService("GuiService"):GetGuiInset().Y
		local size = camera.ViewportSize
		gui.Enabled = true
		if onScreen and screen.Z > 0 then
			-- on screen: the arrow sits right above the target
			label.Text = "▼ " .. baseText
			label.Position = UDim2.fromOffset(screen.X, screen.Y + inset)
			return
		end
		-- off screen (or behind the camera): pin the arrow to the screen edge, pointing toward the target
		local cx, cy = size.X / 2, size.Y / 2
		local dx, dy = screen.X - cx, screen.Y - cy
		if screen.Z < 0 then
			dx, dy = -dx, -dy
		end
		if dx == 0 and dy == 0 then
			dy = 1
		end
		local scale = math.min(
			if math.abs(dx) > 0 then (cx - EDGE) / math.abs(dx) else math.huge,
			if math.abs(dy) > 0 then (cy - EDGE) / math.abs(dy) else math.huge
		)
		local x = math.clamp(cx + dx * scale, EDGE / 2, size.X - EDGE / 2)
		local y = math.clamp(cy + dy * scale, EDGE / 2, size.Y - EDGE)
		local glyph = if math.abs(dx) > math.abs(dy) then (if dx > 0 then "▶" else "◀") else (if dy > 0 then "▼" else "▲")
		label.Text = glyph .. " " .. baseText
		label.Position = UDim2.fromOffset(x, y + inset)
	end)

	local api = {}
	function api.show(part: BasePart, text: string)
		target = part
		baseText = text
		gui.Enabled = true
	end
	function api.hide()
		target = nil
		gui.Enabled = false
	end
	function api.setText(text: string)
		baseText = text
	end
	function api.target(): BasePart?
		return target
	end
	function api.destroy()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		gui:Destroy()
	end
	return api
end

return WorldArrow
