--!strict
-- Studio-only test hook, client side (K-127). Inert unless RunService:IsStudio(). The test harness sets the player
-- attribute KTTestRequest to a request; this controller then either forwards it to the server (TestHook remote:
-- skipTutorial, grant) or readies a screen by name (see openScreen: the harness taps the button). No UI is added here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Modules.Net)

local TestHookController = {}

-- Screen name -> the HUD button that opens it (name as the controllers create it).
local SCREENS: { [string]: string } = {
	hadiah = "RewardButton",
	atur = "SettingsButton",
	bag = "BagButton",
	toko = "StoreButton",
	skill = "SkillButton",
	papan = "PapanButton",
	acara = "AcaraButton",
}

-- GuiButton:Activate() does not exist in this Studio build, so the hook cannot press a button itself. It opens the ≡
-- column when the button sits inside it (as the column's own toggle would) and names the button in KTTestTarget; the
-- harness then taps it with real input (instance path). Anything a tap does after that is the UI's own code path.
local function openScreen(name: string, player: Player)
	local buttonName = SCREENS[name]
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	local button = if buttonName and hud then hud:FindFirstChild(buttonName, true) else nil
	if not button or not button:IsA("GuiButton") then
		warn(`[TestHook] no HUD button for screen "{name}"`)
		return
	end
	local items = hud and hud:FindFirstChild("Items")
	if button:IsDescendantOf(items :: Instance) and items and items:IsA("GuiObject") then
		items.Visible = true
		local bars = hud:FindFirstChild("Bars", true)
		if bars and bars:IsA("GuiObject") then
			bars.Rotation = 90
		end
	end
	player:SetAttribute("KTTestTarget", buttonName)
end

function TestHookController.Start()
	if not RunService:IsStudio() then
		return
	end
	local player = Players.LocalPlayer
	player:GetAttributeChangedSignal("KTTestRequest"):Connect(function()
		local request = player:GetAttribute("KTTestRequest")
		if typeof(request) ~= "string" then
			return
		end
		local kind, arg = string.match(request, "^(%a+):(.*)$")
		if kind == "open" and arg then
			openScreen(string.match(arg, "^(%a+)") or arg, player) -- "hadiah#2" -> "hadiah"
		else
			-- "grant#2" -> "grant": the #n suffix only makes each request a new attribute value.
			Net.Send("TestHook", string.match(request, "^([%w_:]+)") or request) -- keeps "weather:rain" and "weather:puddles_clear"
		end
	end)
end

return TestHookController
