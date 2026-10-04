--[[
	HUDScreen (HUDUI)
	Always-on HUD in the lobby and in levels:
	  Top left:      money, gems, level + XP
	  Bottom center: the bag ("12 / 25"), red and pulsing when full, with a reminder to
	                 throw the stickers into a trash can
	  Bottom left:   "Hold ALT for the mouse" on PC (the game is first person)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BagConfig = require(Shared.BagConfig)
local PlayerStats = require(Shared.PlayerStats)
local Progression = require(Shared.Progression)
local Utility = require(Shared.Utility)

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local HUDScreen = {}
HUDScreen.__index = HUDScreen

function HUDScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, HUDScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.ShownMoney = nil
	self.TargetMoney = 0

	-- Currency stack
	local stack = Components.Create("Frame", {
		Name = "Currency",
		Size = UDim2.fromOffset(230, 160),
		Position = UDim2.fromOffset(28, 64),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Components.List(stack, Enum.FillDirection.Vertical, 12, Enum.HorizontalAlignment.Left)
	self.Money = Components.Pill({ Name = "Money", Icon = "$", Color = Theme.Colors.Money, Size = UDim2.fromOffset(220, 48), MaxTextSize = 28, LayoutOrder = 1, Parent = stack })
	self.Gems = Components.Pill({ Name = "Gems", Icon = "💎", Color = Theme.Colors.Gems, Size = UDim2.fromOffset(170, 42), LayoutOrder = 2, Parent = stack })
	local level = Components.Frame({ Name = "Level", Size = UDim2.fromOffset(220, 42), Color = Theme.Colors.PanelDark, Transparency = 0.1, Corner = 100, Stroke = 3, Flat = true, LayoutOrder = 3, Parent = stack })
	self.LevelText = Components.Label({ Text = "1", Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, -8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Color = Theme.Colors.Text, MaxTextSize = 24, Stroke = 2.5, ZIndex = 3, Parent = level })
	local star = Components.Frame({ Name = "Star", Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, -8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Color = Theme.Colors.XP, Corner = 100, Stroke = 3, StrokeColor = Theme.OutlineFor(Theme.Colors.XP), Parent = level })
	star.ZIndex = 2
	self.XP = Components.ProgressBar({ Name = "XP", Size = UDim2.new(1, -60, 0, 18), Position = UDim2.fromOffset(48, 12), Color = Theme.Colors.XP, MaxTextSize = 13, Stroke = 2, Parent = level })

	-- Bag
	local bag = Components.Create("Frame", {
		Name = "Bag",
		Size = UDim2.fromOffset(420, 96),
		Position = UDim2.new(0.5, 0, 1, -18),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Components.Create("UIScale", { Parent = bag })
	self.BagFrame = bag
	self.BagBar = Components.ProgressBar({ Name = "BagBar", Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 40, 1, -44), Color = Theme.Colors.Accent, MaxTextSize = 24, Stroke = 3.5, Parent = bag })
	local icon = Components.Frame({ Name = "BagIcon", Size = UDim2.fromOffset(68, 68), Position = UDim2.new(0, 0, 1, -2), AnchorPoint = Vector2.new(0, 1), Color = Theme.Colors.Yellow, Corner = 100, Stroke = 3.5, StrokeColor = Theme.OutlineFor(Theme.Colors.Yellow), Parent = bag })
	icon.ZIndex = 4
	self.BagIcon = Components.Label({ Text = "🎒", Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5, Parent = icon })
	self.BagName = Components.Label({ Text = "Pockets", Size = UDim2.new(1, -80, 0, 26), Position = UDim2.fromOffset(76, 0), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 22, Stroke = 2, Parent = bag })
	self.BagValue = Components.Label({ Text = "", Size = UDim2.fromOffset(160, 26), Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0), XAlign = Enum.TextXAlignment.Right, Color = Theme.Colors.Money, MaxTextSize = 22, Stroke = 2, Parent = bag })

	-- Full bag reminder
	self.BagHint = Components.Label({
		Name = "BagHint",
		Text = "BAG FULL!  Throw your stickers in a 🗑️ trash can",
		Size = UDim2.fromOffset(640, 40),
		Position = UDim2.new(0.5, 0, 1, -126),
		AnchorPoint = Vector2.new(0.5, 1),
		Color = Theme.Colors.Yellow,
		MaxTextSize = 30,
		Stroke = 3,
		Visible = false,
		Parent = gui,
	})
	Components.Create("UIScale", { Parent = self.BagHint })

	self.AltHint = Components.Label({
		Name = "AltHint",
		Text = "Hold ALT to use the mouse",
		Size = UDim2.fromOffset(300, 24),
		Position = UDim2.new(0, 24, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		XAlign = Enum.TextXAlignment.Left,
		Color = Theme.Colors.TextDim,
		MaxTextSize = 18,
		Stroke = 2,
		Parent = gui,
	})
	ctx.Controllers.InteractionController.InputModeChanged:Connect(function(mode)
		self.AltHint.Visible = mode == "KeyboardMouse"
	end)
	self.AltHint.Visible = ctx.Controllers.InteractionController.InputMode == "KeyboardMouse"

	RunService.Heartbeat:Connect(function(dt)
		self:Tick(dt)
	end)
	return self
end

function HUDScreen:Tick(dt: number)
	if not self.Gui.Enabled then
		return
	end
	-- Count the money up smoothly
	if self.ShownMoney and self.ShownMoney ~= self.TargetMoney then
		local diff = self.TargetMoney - self.ShownMoney
		local step = math.max(1, math.abs(diff) * math.min(1, dt * 8))
		if math.abs(diff) <= step then
			self.ShownMoney = self.TargetMoney
		else
			self.ShownMoney += math.sign(diff) * step
		end
		self.Money.Value.Text = Utility.FormatMoney(self.ShownMoney)
	end
	-- Pulse the reminder
	if self.BagHint.Visible then
		local scale = self.BagHint:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1 + math.sin(os.clock() * 6) * 0.05
		end
	end
end

function HUDScreen:SetBagHint(visible: boolean)
	self.BagHint.Visible = visible
end

function HUDScreen:Update(data)
	if not data then
		return
	end
	self.TargetMoney = data.Coins
	if self.ShownMoney == nil then
		self.ShownMoney = data.Coins
		self.Money.Value.Text = Utility.FormatMoney(data.Coins)
	elseif data.Coins > self.ShownMoney then
		-- Little bounce when money comes in
		local pill = self.Money.Instance
		local scale = pill:FindFirstChildOfClass("UIScale") or Components.Create("UIScale", { Parent = pill })
		scale.Scale = 1.12
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	self.Gems.Value.Text = Utility.FormatNumber(data.Gems)
	self.LevelText.Text = tostring(data.Level)
	local needed = Progression.XPToNext(data.Level)
	self.XP.Set(data.XP / needed, string.format("%s / %s XP", Utility.Abbreviate(math.floor(data.XP)), Utility.Abbreviate(needed)))

	local stats = PlayerStats.Compute(data)
	local count = PlayerStats.GetBagCount(data)
	local capacity = stats.BagCapacity
	local fraction = if capacity > 0 then count / capacity else 0
	local bag = BagConfig.Get(stats.BagId) or BagConfig.Bags.Pocket
	self.BagName.Text = bag.Name
	self.BagIcon.Text = bag.Icon
	self.BagValue.Text = if count > 0 then Utility.FormatMoney(data.Bag.Value) else ""
	local color = if fraction >= 1 then Theme.Colors.Red elseif fraction >= 0.75 then Theme.Colors.Orange else Theme.Colors.Accent
	self.BagBar.SetColor(color)
	self.BagBar.Set(fraction, string.format("%s / %s", Utility.FormatNumber(count), Utility.FormatNumber(capacity)))
	if count ~= self.LastCount then
		self.LastCount = count
		local scale = self.BagFrame:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1.06
			TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	if fraction < 1 then
		self.BagHint.Visible = false
	end
end

function HUDScreen:SetVisible(visible: boolean)
	self.Gui.Enabled = visible
end

return HUDScreen
