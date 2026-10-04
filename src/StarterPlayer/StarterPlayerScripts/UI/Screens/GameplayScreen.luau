--[[
	GameplayScreen (GameplayUI)
	  Top:    level name, "347 / 1000 STICKERS", progress bar, "34.7% CLEANED", timer
	  Left:   player card (avatar, name, level, coins)
	  Right:  TEAM list with per-player peel counts
	  Bottom: current tool + "E - PEEL" hint, mobile PEEL button, combo meter
	Also shows "last stickers" markers when only a few remain.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DifficultyConfig = require(Shared.DifficultyConfig)
local LevelConfig = require(Shared.LevelConfig)
local Rarity = require(Shared.Rarity)
local ToolConfig = require(Shared.ToolConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local LOCAL_PLAYER = Players.LocalPlayer

local GameplayScreen = {}
GameplayScreen.__index = GameplayScreen

function GameplayScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, GameplayScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.ComboCount = 0
	self.ComboExpires = 0
	self.FinderMarkers = {}
	gui.Enabled = false

	-- Top progress panel
	local top = Components.Frame({
		Name = "Progress",
		Size = UDim2.fromOffset(560, 104),
		Position = UDim2.new(0.5, 0, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = Theme.Colors.Panel,
		Transparency = 0.05,
		Corner = 18,
		Stroke = 3.5,
		Parent = gui,
	})
	self.LevelName = Components.Label({ Name = "LevelName", Text = "FOUNTAIN", Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, 6), MaxTextSize = 28, Stroke = 2, Parent = top })
	self.Difficulty = Components.Label({ Name = "Difficulty", Text = "NORMAL", Size = UDim2.fromOffset(120, 22), Position = UDim2.fromOffset(14, 10), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 18, Stroke = 1.5, Parent = top })
	self.Timer = Components.Label({ Name = "Timer", Text = "0:00.0", Size = UDim2.fromOffset(120, 22), Position = UDim2.new(1, -134, 0, 10), XAlign = Enum.TextXAlignment.Right, Font = Theme.Fonts.Bold, MaxTextSize = 18, Stroke = 1.5, Parent = top })
	self.Count = Components.Label({ Name = "Count", Text = "0 / 0 stickers", Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 38), Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 18, Parent = top })
	self.Bar = Components.ProgressBar({ Name = "Bar", Size = UDim2.new(1, -28, 0, 30), Position = UDim2.fromOffset(14, 64), Color = Theme.Colors.Green, MaxTextSize = 20, Stroke = 2, StrokeColor = Theme.Colors.PanelLight, Parent = top })

	-- Team (right)
	local team = Components.Frame({
		Name = "Team",
		Size = UDim2.fromOffset(240, 60),
		Position = UDim2.new(1, -20, 0, 84),
		AnchorPoint = Vector2.new(1, 0),
		Color = Theme.Colors.Panel,
		Transparency = 0.1,
		Corner = 16,
		Stroke = 3,
		Parent = gui,
	})
	team.AutomaticSize = Enum.AutomaticSize.Y
	Components.Padding(team, 10)
	local teamList = Components.Create("Frame", { Name = "List", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = team })
	Components.List(teamList, Enum.FillDirection.Vertical, 6)
	self.TeamList = teamList

	-- Bottom right: tool + hint
	local toolPanel = Components.Frame({
		Name = "Tool",
		Size = UDim2.fromOffset(280, 66),
		Position = UDim2.new(1, -20, 1, -18),
		AnchorPoint = Vector2.new(1, 1),
		Color = Theme.Colors.Panel,
		Transparency = 0.1,
		Corner = 16,
		Stroke = 2.5,
		Parent = gui,
	})
	self.ToolIcon = Components.Label({ Text = "✋", Size = UDim2.fromOffset(50, 50), Position = UDim2.fromOffset(8, 8), Parent = toolPanel })
	self.ToolName = Components.Label({ Text = "Hand", Size = UDim2.new(1, -70, 0, 26), Position = UDim2.fromOffset(62, 6), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 22, Stroke = 1.5, Parent = toolPanel })
	self.PeelHint = Components.Label({ Text = "E — PEEL", Size = UDim2.new(1, -70, 0, 22), Position = UDim2.fromOffset(62, 36), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 17, Parent = toolPanel })
	self.ToolStroke = toolPanel:FindFirstChildOfClass("UIStroke")

	-- Multi-peel slots indicator
	self.Slots = Components.Label({ Text = "", Size = UDim2.fromOffset(280, 24), Position = UDim2.new(1, -20, 1, -92), AnchorPoint = Vector2.new(1, 1), Font = Theme.Fonts.Bold, MaxTextSize = 18, Stroke = 1.5, Parent = gui })

	-- Combo
	local combo = Components.Create("Frame", { Name = "Combo", Size = UDim2.fromOffset(220, 90), Position = UDim2.new(1, -40, 0.62, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui })
	self.ComboFrame = combo
	self.ComboText = Components.Label({ Text = "Combo x2", Size = UDim2.new(1, 0, 0, 44), Color = Theme.Colors.Yellow, MaxTextSize = 34, Stroke = 1, Parent = combo })
	self.ComboBonus = Components.Label({ Text = "", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 54), Font = Theme.Fonts.Bold, Color = Theme.Colors.Green, MaxTextSize = 18, Stroke = 1.5, Parent = combo })
	self.ComboBar = Components.ProgressBar({ Size = UDim2.new(0.8, 0, 0, 8), Position = UDim2.new(0.1, 0, 0, 78), Color = Theme.Colors.Yellow, Parent = combo })
	Components.Create("UIScale", { Parent = combo })

	-- Finder hint
	self.Finder = Components.Label({ Text = "", Size = UDim2.fromOffset(520, 28), Position = UDim2.new(0.5, 0, 0, 128), AnchorPoint = Vector2.new(0.5, 0), Font = Theme.Fonts.Bold, Color = Theme.Colors.Yellow, MaxTextSize = 20, Stroke = 2, Visible = false, Parent = gui })

	-- Mobile PEEL button
	local peelButton = Components.Create("TextButton", {
		Name = "PeelButton",
		Size = UDim2.fromOffset(150, 150),
		Position = UDim2.new(1, -36, 1, -150),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = gui,
	})
	Components.Round(peelButton)
	Components.Gradient(peelButton, Theme.Lighten(Theme.Colors.Pink, 0.2), Theme.Darken(Theme.Colors.Pink, 0.2))
	Components.Stroke(peelButton, Color3.new(1, 1, 1), 4)
	Components.Label({ Text = "PEEL", Size = UDim2.fromScale(0.8, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Stroke = 2.5, Parent = peelButton })
	local peelScale = Components.Create("UIScale", { Parent = peelButton })
	peelButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			ctx.Controllers.InteractionController.SetHold("MobileButton", true)
			TweenService:Create(peelScale, TweenInfo.new(0.08), { Scale = 0.9 }):Play()
		end
	end)
	peelButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			ctx.Controllers.InteractionController.SetHold("MobileButton", false)
			TweenService:Create(peelScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end
	end)
	self.PeelButton = peelButton

	-- Leave button
	Components.Button({
		Name = "Leave",
		Text = "Leave",
		Size = UDim2.fromOffset(120, 40),
		Position = UDim2.new(1, -20, 0, 18),
		AnchorPoint = Vector2.new(1, 0),
		Color = Theme.Colors.Red,
		MaxTextSize = 18,
		OnClick = function()
			ctx.UI.Confirm("Leave this level? Stickers in your bag are kept, but you'll miss the completion reward.", function()
				Remotes.LeaveMatch:FireServer()
			end)
		end,
		Parent = gui,
	})

	ctx.Controllers.InteractionController.InputModeChanged:Connect(function()
		self:UpdateInputMode()
	end)
	self:UpdateInputMode()

	RunService.RenderStepped:Connect(function()
		if gui.Enabled then
			self:Tick()
		end
	end)
	return self
end

function GameplayScreen:UpdateInputMode()
	local mode = self.Ctx.Controllers.InteractionController.InputMode
	self.PeelButton.Visible = mode == "Touch"
	self.PeelHint.Text = if mode == "Touch" then "HOLD PEEL" elseif mode == "Gamepad" then "X — PEEL" else "E — PEEL  (hold)"
end

function GameplayScreen:Show(matchInfo)
	local level = LevelConfig.Get(matchInfo.LevelId)
	local difficulty = DifficultyConfig.Get(matchInfo.Difficulty)
	self.LevelName.Text = string.upper(level and level.Name or matchInfo.LevelId)
	self.Difficulty.Text = difficulty and difficulty.DisplayName or ""
	self.Difficulty.TextColor3 = difficulty and difficulty.Color or Theme.Colors.Text
	self.StartClock = os.clock()
	self.Total = matchInfo.Total or 0
	self.Stopped = false
	self.MyPeeled = 0
	self.ComboCount = 0
	self.ComboFrame.Visible = false
	self:ClearFinder()
	self.Gui.Enabled = true
	self:UpdateTeam(matchInfo.Team or {})
	self:UpdateData(self.Ctx.Controllers.DataController.Get())
end

function GameplayScreen:Hide()
	self.Gui.Enabled = false
	self:ClearFinder()
end

function GameplayScreen:StopTimer()
	self.Stopped = true
end

function GameplayScreen:UpdateData(data)
	if not data then
		return
	end
	local tool = ToolConfig.Get(data.EquippedTool) or ToolConfig.Tools.Hand
	self.ToolIcon.Text = tool.Icon
	self.ToolName.Text = tool.Name
	if self.ToolStroke then
		self.ToolStroke.Color = Rarity.Color(tool.Rarity)
	end
end

function GameplayScreen:UpdateTeam(team)
	Components.ClearChildren(self.TeamList, { "UIListLayout" })
	Components.Label({ Text = "Team", Size = UDim2.new(1, 0, 0, 24), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 20, Stroke = 1.5, LayoutOrder = 0, Parent = self.TeamList })
	for index, member in ipairs(team) do
		local row = Components.Frame({ Name = "Member", Size = UDim2.new(1, 0, 0, 40), Color = Theme.Colors.PanelDark, Transparency = if member.Present == false then 0.7 else 0.25, Corner = 10, LayoutOrder = index, Parent = self.TeamList })
		Components.Avatar(member.UserId, { Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(4, 4), StrokeColor = if member.UserId == LOCAL_PLAYER.UserId then Theme.Colors.Pink else nil, Parent = row })
		Components.Label({ Text = member.Name .. (if member.Present == false then " · left" else ""), Size = UDim2.new(1, -110, 1, -10), Position = UDim2.fromOffset(42, 5), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 16, Parent = row })
		Components.Label({ Text = Utility.FormatNumber(member.Peeled), Size = UDim2.fromOffset(60, 30), Position = UDim2.new(1, -66, 0, 5), XAlign = Enum.TextXAlignment.Right, Color = Theme.Colors.Cyan, MaxTextSize = 20, Stroke = 1.5, Parent = row })
		if member.UserId == LOCAL_PLAYER.UserId then
			self.MyPeeled = member.Peeled
		end
	end
end

function GameplayScreen:OnLocalPeel()
	self.MyPeeled = (self.MyPeeled or 0) + 1
end

function GameplayScreen:ShowCombo(combo: number, multiplier: number)
	self.ComboCount = combo
	self.ComboExpires = os.clock() + Config.Combo.Window
	if combo < 2 then
		self.ComboFrame.Visible = false
		return
	end
	self.ComboFrame.Visible = true
	self.ComboText.Text = "Combo x" .. combo
	local color = if combo >= 50 then Theme.Colors.Pink elseif combo >= 25 then Theme.Colors.Orange elseif combo >= 10 then Theme.Colors.Yellow else Theme.Colors.Cyan
	self.ComboText.TextColor3 = color
	self.ComboBonus.Text = if multiplier > 1 then string.format("+%d%% coins", math.floor((multiplier - 1) * 100 + 0.5)) else ""
	local scale = self.ComboFrame:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = if combo % 5 == 0 then 1.35 else 1.15
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	if combo % 5 == 0 then
		self.Ctx.Controllers.SoundManager.Play("Combo", { PlaybackSpeed = 0.9 + math.min(combo, 60) / 60 })
	end
end

function GameplayScreen:ClearFinder()
	for _, marker in pairs(self.FinderMarkers) do
		marker:Destroy()
	end
	self.FinderMarkers = {}
	self.Finder.Visible = false
end

-- Bright markers over the last remaining stickers so nobody hunts forever.
function GameplayScreen:UpdateFinder(session)
	local threshold = math.max(Config.Match.FinderMinimum, math.floor(session.Total * Config.Match.FinderThreshold))
	if session.Alive > threshold or session.Alive <= 0 then
		if next(self.FinderMarkers) then
			self:ClearFinder()
		end
		return
	end
	self.Finder.Visible = true
	self.Finder.Text = string.format("Only %d sticker%s left — follow the markers", session.Alive, if session.Alive == 1 then "" else "s")
	local alive = self.Ctx.Controllers.StickerRenderer.GetAliveRecords(session)
	local seen = {}
	for _, record in ipairs(alive) do
		seen[record] = true
		if not self.FinderMarkers[record] and record.Part then
			local marker = Instance.new("BillboardGui")
			marker.Name = "FinderMarker"
			marker.Size = UDim2.fromOffset(36, 36)
			marker.AlwaysOnTop = true
			marker.LightInfluence = 0
			marker.Adornee = record.Part
			marker.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
			local dot = Components.Label({ Text = "⬇", Color = Theme.Colors.Yellow, Stroke = 2, Parent = marker })
			dot.Size = UDim2.fromScale(1, 1)
			marker.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
			self.FinderMarkers[record] = marker
		end
	end
	for record, marker in pairs(self.FinderMarkers) do
		if not seen[record] then
			marker:Destroy()
			self.FinderMarkers[record] = nil
		end
	end
end

function GameplayScreen:Tick()
	local renderer = self.Ctx.Controllers.StickerRenderer
	local session = renderer.GetCurrentSession()
	if session and session.Kind == "Match" then
		local total = session.Total
		local cleaned = total - session.Alive
		local fraction = if total > 0 then cleaned / total else 0
		self.Count.Text = string.format("%s / %s stickers", Utility.FormatNumber(cleaned), Utility.FormatNumber(total))
		self.Bar.Set(fraction, Utility.FormatPercent(fraction) .. " cleaned", false)
		if self.LastFinderCheck == nil or os.clock() - self.LastFinderCheck > 0.5 then
			self.LastFinderCheck = os.clock()
			self:UpdateFinder(session)
		end
	end
	if not self.Stopped and self.StartClock then
		self.Timer.Text = Utility.FormatTime(os.clock() - self.StartClock)
	end

	-- Combo countdown
	if self.ComboFrame.Visible then
		local remaining = self.ComboExpires - os.clock()
		if remaining <= 0 then
			self.ComboFrame.Visible = false
			self.ComboCount = 0
		else
			self.ComboBar.Set(remaining / Config.Combo.Window, nil, false)
		end
	end

	-- Multi-peel slots
	local stats = self.Ctx.Controllers.DataController.GetStats()
	if stats.Capacity > 1 then
		local activeCount = 0
		for _ in pairs(self.Ctx.Controllers.PeelController.GetActive()) do
			activeCount += 1
		end
		local dots = ""
		for i = 1, stats.Capacity do
			dots ..= if i <= activeCount then "●" else "○"
		end
		self.Slots.Text = "MULTI-PEEL " .. dots
	else
		self.Slots.Text = ""
	end
end

return GameplayScreen
