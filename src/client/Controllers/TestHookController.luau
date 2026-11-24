--!strict
-- Studio-only test hook, client side (K-127). Inert unless RunService:IsStudio(). The test harness sets the player
-- attribute KTTestRequest to a request; this controller then either forwards it to the server (TestHook remote:
-- skipTutorial, grant) or opens a screen by name. A screen opens by activating its own HUD button, the same handler a
-- tap runs; the menu column (≡) is opened first when the button sits inside it. No UI is added here.
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

local function openScreen(name: string)
	local buttonName = SCREENS[name]
	local hud = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	local button = if buttonName and hud then hud:FindFirstChild(buttonName, true) else nil
	if not button or not button:IsA("GuiButton") then
		warn(`[TestHook] no HUD button for screen "{name}"`)
		return
	end
	-- Inside the ≡ column: open the column first (it is collapsed on touch devices), as a tap would.
	local items = hud and hud:FindFirstChild("Items")
	if button:IsDescendantOf(items :: Instance) and items and items:IsA("GuiObject") and not items.Visible then
		local toggle = hud:FindFirstChild("MenuToggle", true)
		if toggle and toggle:IsA("GuiButton") then
			toggle:Activate()
		end
	end
	task.wait(0.1)
	button:Activate()
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
			openScreen(arg)
		else
			Net.Send("TestHook", request)
		end
	end)
end

return TestHookController
