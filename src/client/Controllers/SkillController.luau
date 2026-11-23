--!strict
-- Skill Tree panel (UI-4, GUI doc Bab 6.2 and the approved mockup Bab 10; Skill Tree Bab 3). Opened from the HUD (SkillButton).
--   Six branches side by side (Bertani, Mancing, Ternak, Tukang, Masak, Sosial). In each branch the Root is at the bottom,
--   the Cabang in the middle, and the Capstone at the top; lines join the tiers and light up once a node has a level.
--   Tap a node: the drawer shows the skill, its effect, its requirement or breakpoint, its cost (1 SP + Koin 1.000 x level berikutnya, K-12) and the
--   Tingkatkan button. The server decides every purchase: SkillBuy returns the reason ("ok" / "max" / "locked" / "noSP" /
--   "noKoin"), and the drawer shows it. The client only reflects the snapshot.
-- The panel is built on open and destroyed on close (UiKit.closePanel): no instance stays behind.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skills = require(ReplicatedStorage.Shared.Config.Skills)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(ReplicatedStorage.Shared.Modules.Net)
local State = require(script.Parent.Parent.State)
local UiKit = require(script.Parent.Parent.UiKit)
local FeatureClient = require(script.Parent.Parent.FeatureClient)

local player = Players.LocalPlayer

local SkillController = {}

local panel: any = nil -- the open panel (UiKit.panel), nil while closed
local selected: string? = nil -- the skill in the drawer
local message: string? = nil -- a Locale key shown in the drawer (server reason, or the requirement of a locked node)
local scrollX = 0 -- where the player left the tree (kept across re-renders)

-- Layout (px). Node = UiKit.TOUCH_CTA (40 px, GUI doc 4.4 tier, the mockup's node size). The rest is layout only.
local NODE = UiKit.TOUCH_CTA
local TIER_GAP = 30
local TIER_H = NODE + TIER_GAP
local COL_W = 120
local COL_GAP = 12
local HEAD_H = 26
local TREE_H = HEAD_H + 3 * NODE + 2 * TIER_GAP

-- Where each skill sits in its branch: tier 1 = Root (bottom), 2 = Cabang (middle), 3 = Capstone (top).
-- side: "c" = centre, "a" = left of centre, "b" = right of centre (Bertani and Mancing have two Cabang nodes).
type Slot = { id: string, tier: number, side: string }
local LAYOUT: { [string]: { Slot } } = {
	bertani = {
		{ id = "tangan_hijau", tier = 1, side = "c" },
		{ id = "bibit_hemat", tier = 2, side = "a" },
		{ id = "mata_kualitas", tier = 2, side = "b" },
		{ id = "panen_raya", tier = 3, side = "c" },
	},
	mancing = {
		{ id = "joran_kuat", tier = 1, side = "c" },
		{ id = "umpan_hemat", tier = 2, side = "a" },
		{ id = "firasat", tier = 2, side = "b" },
		{ id = "ikan_besar", tier = 3, side = "c" },
	},
	ternak = {
		{ id = "tempat_pakan_besar", tier = 1, side = "c" },
		{ id = "telur_cepat", tier = 2, side = "c" },
		{ id = "susu_melimpah", tier = 3, side = "c" },
	},
	tukang = {
		{ id = "kayu_kuat", tier = 1, side = "c" },
		{ id = "tukang_cepat", tier = 2, side = "c" },
	},
	masak = {
		{ id = "koki_cepat", tier = 1, side = "c" },
		{ id = "rasa_prima", tier = 2, side = "c" },
	},
	sosial = {
		{ id = "tetangga_baik", tier = 2, side = "c" },
	},
}

-- Server reasons (SkillService.buy) and the matching Locale key.
local REASON_KEY: { [string]: string } = {
	max = "skill.maxed",
	locked = "skill.locked",
	noSP = "skill.need_sp",
	noKoin = "skill.need_koin",
}

local function spBalance(): number
	local value = player:GetAttribute("SP")
	return if typeof(value) == "number" then value else 0
end

local function koinBalance(): number
	local value = player:GetAttribute("Koin")
	return if typeof(value) == "number" then value else 0
end

local function playerLevel(): number
	local value = player:GetAttribute("Level")
	return if typeof(value) == "number" then value else 1
end

local function levelsNow(): { [string]: number }
	local snapshot = State.current :: any
	return if snapshot and snapshot.skills then snapshot.skills else {}
end

-- The state of one node: "maxed", "locked" (with the missing requirement), "noSP", "noKoin", or "buyable".
local function nodeState(def: Skills.SkillDef, levels: { [string]: number }): (string, Skills.Missing?)
	local lv = levels[def.id] or 0
	if lv >= def.maxLevel then
		return "maxed", nil
	end
	local missing = Skills.missing(def, levels, playerLevel())
	if missing then
		return "locked", missing
	end
	if spBalance() < Skills.SP_PER_LEVEL then
		return "noSP", nil
	end
	if koinBalance() < Skills.koinForLevel(lv + 1) then
		return "noKoin", nil
	end
	return "buyable", nil
end

local function requirementText(missing: Skills.Missing): string
	if missing.kind == "level" then
		return Locale.t("skill.req_level", { n = missing.level })
	elseif missing.kind == "skill" then
		return Locale.t("skill.req_skill", { skill = Locale.t(`skill.{missing.id}`), n = missing.lv })
	elseif missing.kind == "any" then
		return Locale.t("skill.req_any", {
			a = Locale.t(`skill.{missing.a.id}`),
			na = missing.a.lv,
			b = Locale.t(`skill.{missing.b.id}`),
			nb = missing.b.lv,
		})
	end
	return Locale.t("skill.req_total", { n = missing.n })
end

-- Centre x and top y of a slot inside its column (column is COL_W wide).
local function slotCentre(slot: Slot): (number, number)
	local cx = COL_W / 2
	local x = if slot.side == "a" then cx - NODE + 10 elseif slot.side == "b" then cx + NODE - 10 else cx
	local y = HEAD_H + (3 - slot.tier) * TIER_H
	return x, y
end

-- An axis-aligned line (3 px). Lit = the branch has something bought, so the road shows as travelled.
local function line(parent: Instance, x1: number, y1: number, x2: number, y2: number, lit: boolean)
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = if lit then UiKit.HEADER else UiKit.LOCKED
	frame.Position = UDim2.fromOffset(math.min(x1, x2), math.min(y1, y2))
	frame.Size = UDim2.fromOffset(math.max(3, math.abs(x2 - x1)), math.max(3, math.abs(y2 - y1)))
	frame.ZIndex = 1
	frame.Parent = parent
end

-- Joins tier t (lower) and tier t+1 (upper) of one branch: a bar in the gap, with a line from each node.
local function connectTiers(parent: Instance, slots: { Slot }, lower: number, levels: { [string]: number })
	local lowers, uppers = {}, {}
	for _, slot in slots do
		if slot.tier == lower then
			table.insert(lowers, slot)
		elseif slot.tier == lower + 1 then
			table.insert(uppers, slot)
		end
	end
	if #lowers == 0 or #uppers == 0 then
		return
	end
	local lowerY = HEAD_H + (3 - lower) * TIER_H
	local mid = lowerY - TIER_GAP / 2
	local minX, maxX = math.huge, -math.huge
	local lit = false
	for _, slot in lowers do
		local x, _ = slotCentre(slot)
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		line(parent, x, lowerY, x, mid, true)
		if (levels[slot.id] or 0) > 0 then
			lit = true
		end
	end
	for _, slot in uppers do
		local x, y = slotCentre(slot)
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		line(parent, x, mid, x, y + NODE, (levels[slot.id] or 0) > 0)
	end
	line(parent, minX, mid, maxX, mid, lit)
end

local function nodeColour(state: string): Color3
	if state == "maxed" then
		return UiKit.HEADER
	elseif state == "locked" then
		return UiKit.LOCKED
	elseif state == "buyable" then
		return UiKit.BUTTON
	end
	return UiKit.BUTTON_MUTED -- noSP / noKoin: affordable later, not now
end

local function buildNode(column: Frame, slot: Slot, levels: { [string]: number })
	local def = Skills.byId[slot.id]
	if not def then
		return
	end
	local state = nodeState(def, levels)
	local x, y = slotCentre(slot)
	local node = Instance.new("TextButton")
	node.Name = slot.id
	node.Text = `{levels[slot.id] or 0}/{def.maxLevel}`
	node.Font = UiKit.FONT
	node.TextSize = UiKit.TEXT_CAPTION
	node.TextColor3 = if state == "locked" then UiKit.TEXT else UiKit.CREAM
	node.AutoButtonColor = false
	node.BackgroundColor3 = nodeColour(state)
	node.AnchorPoint = Vector2.new(0.5, 0)
	node.Position = UDim2.fromOffset(x, y)
	node.Size = UDim2.fromOffset(NODE, NODE)
	node.ZIndex = 3
	node.Parent = column
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, UiKit.R_ROUND)
	round.Parent = node
	if state == "maxed" then
		local gold = Instance.new("UIStroke")
		gold.Color = UiKit.GOLD
		gold.Thickness = 3
		gold.Parent = node
	end
	node.Activated:Connect(function()
		selected = slot.id
		message = nil
		SkillController.Render()
	end)
end

local function buildBranch(scroll: ScrollingFrame, index: number, cabang: string, levels: { [string]: number })
	local slots = LAYOUT[cabang] or {}
	local column = Instance.new("Frame")
	column.Name = `Branch_{cabang}`
	column.BackgroundTransparency = 1
	column.Position = UDim2.fromOffset((index - 1) * (COL_W + COL_GAP), 0)
	column.Size = UDim2.fromOffset(COL_W, TREE_H)
	column.Parent = scroll

	-- Header: the branch name and its total levels (a display sum, not a branch level).
	local total, maxTotal = 0, 0
	for _, slot in slots do
		local def = Skills.byId[slot.id]
		if def then
			total += levels[slot.id] or 0
			maxTotal += def.maxLevel
		end
	end
	local head = Instance.new("TextLabel")
	head.Name = "Head"
	head.BackgroundTransparency = 1
	head.Size = UDim2.fromOffset(COL_W, HEAD_H)
	head.Font = UiKit.FONT
	head.TextSize = UiKit.TEXT_SMALL
	head.TextColor3 = UiKit.TEXT
	head.Text = `{Locale.t(`skill.cabang.{cabang}`)} {total}/{maxTotal}`
	head.Parent = column

	-- Lines first (drawn under), then nodes.
	for lower = 1, 2 do
		connectTiers(column, slots, lower, levels)
	end
	for _, slot in slots do
		buildNode(column, slot, levels)
	end
end

-- The drawer: name, effect, level, requirement or breakpoint, cost, status, and Tingkatkan.
local function buildDrawer(parent: ScrollingFrame, order: number, levels: { [string]: number })
	local id = selected
	local def = if id then Skills.byId[id] else nil
	if not id or not def then
		return
	end
	local lv = levels[id] or 0
	local state, missing = nodeState(def, levels)

	local drawer = Instance.new("Frame")
	drawer.Name = "Drawer"
	drawer.LayoutOrder = order
	drawer.BackgroundColor3 = UiKit.ROW
	drawer.AutomaticSize = Enum.AutomaticSize.Y
	drawer.Size = UDim2.new(1, 0, 0, 0)
	drawer.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, UiKit.R_MD)
	round.Parent = drawer
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = drawer
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = drawer

	local function text(name: string, order2: number, value: string, size: number, color: Color3?)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.LayoutOrder = order2
		label.BackgroundTransparency = 1
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Size = UDim2.new(1, 0, 0, 0)
		label.Font = UiKit.FONT
		label.TextSize = size
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = color or UiKit.TEXT
		label.Text = value
		label.Parent = drawer
	end

	text("Name", 1, Locale.t(`skill.{id}`), UiKit.TEXT_HEADING)
	text("Effect", 2, Locale.t(`skill.{id}.desc`), UiKit.TEXT_SMALL)
	text("Level", 3, Locale.t("skill.level", { n = lv, max = def.maxLevel }), UiKit.TEXT_SMALL)
	if def.breakpoint and lv < def.breakpoint then
		text("From", 4, Locale.t("skill.effect_from", { n = def.breakpoint }), UiKit.TEXT_SMALL, UiKit.HEADER_DARK)
	end
	text("Cost", 5, Locale.t("skill.cost"), UiKit.TEXT_CAPTION)

	-- Status: the requirement of a locked node, or the state of a buyable one, or the last server answer.
	local status: string? = nil
	if message then
		status = Locale.t(message)
	elseif state == "locked" and missing then
		status = requirementText(missing)
	elseif state == "noSP" then
		status = Locale.t("skill.need_sp")
	elseif state == "noKoin" then
		status = Locale.t("skill.need_koin")
	elseif state == "maxed" then
		status = Locale.t("skill.maxed")
	end
	if status then
		text("Status", 6, status, UiKit.TEXT_CAPTION, UiKit.RED_TEXT)
	end

	-- Tingkatkan: the one main action of the drawer (touch tier 40, GUI doc 4.4). Enabled only when buyable.
	local buy = Instance.new("TextButton")
	buy.Name = "Tingkatkan"
	buy.LayoutOrder = 7
	buy.Size = UDim2.new(1, 0, 0, UiKit.TOUCH_CTA)
	buy.Font = UiKit.FONT
	buy.TextSize = UiKit.TEXT_BODY
	buy.Text = Locale.t("skill.tingkatkan")
	buy.TextColor3 = if state == "buyable" then UiKit.CREAM else UiKit.TEXT
	buy.BackgroundColor3 = if state == "buyable" then UiKit.BUTTON else UiKit.BUTTON_MUTED
	buy.AutoButtonColor = state == "buyable"
	buy.Active = state == "buyable"
	buy.Parent = drawer
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, UiKit.R_MD)
	buyCorner.Parent = buy
	buy.Activated:Connect(function()
		task.spawn(function()
			local ok, result = pcall(Net.Invoke, "SkillBuy", id)
			if ok and typeof(result) == "string" then
				message = REASON_KEY[result] -- "ok" and "unknown" have no key: nothing to show
			end
			SkillController.Render()
		end)
	end)
end

-- Header chips: SP and Koin (the GUI doc's chips), then the tree, then the drawer.
function SkillController.Render()
	if not panel or not panel.gui.Enabled then
		return
	end
	UiKit.clear(panel.list)
	local levels = levelsNow()

	local chips = Locale.t("skill.sp_chip", { n = spBalance() }) .. "   " .. Locale.t("skill.koin_chip", { n = Locale.formatNumber(koinBalance()) })
	UiKit.header(panel.list, chips, 1)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Tree"
	scroll.LayoutOrder = 2
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, 0, 0, TREE_H + 10)
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.fromOffset(#Skills.CABANG_ORDER * (COL_W + COL_GAP), 0)
	scroll.Parent = panel.list
	for index, cabang in Skills.CABANG_ORDER do
		buildBranch(scroll, index, cabang, levels)
	end
	scroll.CanvasPosition = Vector2.new(scrollX, 0)
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		scrollX = scroll.CanvasPosition.X
	end)

	buildDrawer(panel.list, 3, levels)
end

local function closePanel()
	if panel then
		local gui = panel.gui
		panel = nil
		UiKit.closePanel(gui)
	end
end

local function openPanel()
	if panel then
		return
	end
	panel = UiKit.panel("SkillPanel", Locale.t("skill.title"), closePanel)
	panel.gui.Enabled = true
	SkillController.Render()
end

function SkillController.Start()
	State.Changed:Connect(SkillController.Render)
	player:GetAttributeChangedSignal("SP"):Connect(SkillController.Render)
	player:GetAttributeChangedSignal("Koin"):Connect(SkillController.Render)
	player:GetAttributeChangedSignal("Level"):Connect(SkillController.Render)
	task.spawn(function()
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
		if not hud then
			return
		end
		local item = UiKit.menuItem(hud, "SkillButton", Locale.t("skill.title"), 8)
		if item then
			-- D-39: closed (Player Lv < 2) = hidden, like every gated HUD button (FeatureClient.GateHud).
			FeatureClient.GateHud("SkillButton", "skill")
			item.Activated:Connect(function()
				if panel then
					closePanel()
				else
					openPanel()
				end
			end)
		end
	end)
end

return SkillController
