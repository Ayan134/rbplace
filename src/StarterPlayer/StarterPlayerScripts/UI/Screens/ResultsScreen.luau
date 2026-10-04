--[[
	ResultsScreen (ResultsUI)
	LEVEL COMPLETE summary: time, stickers, coins (stickers + completion + co-op + speed),
	XP, gems, first completion, new record, rare stickers found and team stats.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DifficultyConfig = require(Shared.DifficultyConfig)
local Rarity = require(Shared.Rarity)
local StickerConfig = require(Shared.StickerConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local ResultsScreen = {}
ResultsScreen.__index = ResultsScreen

function ResultsScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, ResultsScreen)
	self.Gui = gui
	self.Ctx = ctx
	gui.Enabled = false
	gui.DisplayOrder = 15

	local panel = Components.Frame({
		Name = "Panel",
		Size = UDim2.fromOffset(820, 560),
		Position = UDim2.fromScale(0.5, 0.53),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = Theme.Colors.Panel,
		Corner = 22,
		Stroke = 4,
		StrokeColor = Theme.Colors.Yellow,
		Gradient = { Theme.Colors.PanelLight, Theme.Colors.Panel, 90 },
		Parent = gui,
	})
	Components.Create("UIScale", { Parent = panel })
	self.Panel = panel
	self.Title = Components.Label({ Text = "Level complete", Size = UDim2.new(1, -40, 0, 64), Position = UDim2.fromOffset(20, 10), Color = Theme.Colors.Yellow, MaxTextSize = 58, Stroke = 3, Parent = panel })
	self.Subtitle = Components.Label({ Text = "", Size = UDim2.new(1, -40, 0, 28), Position = UDim2.fromOffset(20, 72), Font = Theme.Fonts.Bold, MaxTextSize = 22, Stroke = 1.5, RichText = true, Parent = panel })
	self.Badges = Components.Label({ Text = "", Size = UDim2.new(1, -40, 0, 26), Position = UDim2.fromOffset(20, 102), Color = Theme.Colors.Green, MaxTextSize = 22, Stroke = 1.5, Parent = panel })

	local left = Components.Frame({ Name = "Rewards", Size = UDim2.new(0.5, -30, 0, 330), Position = UDim2.fromOffset(20, 138), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 14, Parent = panel })
	Components.Padding(left, 12)
	Components.List(left, Enum.FillDirection.Vertical, 4)
	self.RewardList = left

	local right = Components.Frame({ Name = "Team", Size = UDim2.new(0.5, -30, 0, 330), Position = UDim2.new(0.5, 10, 0, 138), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 14, Parent = panel })
	Components.Padding(right, 12)
	Components.List(right, Enum.FillDirection.Vertical, 6)
	self.TeamList = right

	self.Continue = Components.Button({
		Text = "Continue",
		Size = UDim2.fromOffset(300, 58),
		Position = UDim2.new(0.5, 0, 1, -72),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = Theme.Colors.Green,
		MaxTextSize = 30,
		OnClick = function()
			Remotes.LeaveMatch:FireServer()
		end,
		Parent = panel,
	})
	self.Countdown = Components.Label({ Text = "", Size = UDim2.fromOffset(300, 18), Position = UDim2.new(0.5, 0, 1, -12), AnchorPoint = Vector2.new(0.5, 1), Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 14, Parent = panel })
	return self
end

local function rewardRow(parent: Instance, order: number, label: string, value: number, color: Color3, prefix: string?)
	local row = Components.Create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	Components.Label({ Text = label, Size = UDim2.new(0.6, 0, 1, 0), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 18, Parent = row })
	local valueLabel = Components.Label({ Text = "0", Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromScale(0.6, 0), XAlign = Enum.TextXAlignment.Right, Color = color, MaxTextSize = 22, Stroke = 1.5, Parent = row })
	-- Count up for a satisfying reveal
	local counter = Instance.new("NumberValue")
	counter.Changed:Connect(function(v)
		valueLabel.Text = (prefix or "+") .. Utility.FormatNumber(math.floor(v + 0.5))
	end)
	task.delay(0.15 * order, function()
		TweenService:Create(counter, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = value }):Play()
	end)
	valueLabel.Text = (prefix or "+") .. "0"
end

function ResultsScreen:Show(summary)
	local difficulty = DifficultyConfig.Get(summary.Difficulty)
	self.Title.Text = "Level complete"
	self.Subtitle.Text = string.format(
		"%s  ·  <font color=\"#%s\">%s</font>  ·  %s  ·  %s stickers",
		summary.LevelName,
		difficulty and difficulty.Color:ToHex() or "ffffff",
		difficulty and difficulty.DisplayName or summary.Difficulty,
		Utility.FormatTime(summary.Time),
		Utility.FormatNumber(summary.StickersTotal)
	)
	local badges = {}
	if summary.FirstCompletion then
		table.insert(badges, "First clear")
	end
	if summary.NewRecord then
		table.insert(badges, "New record")
	end
	if summary.SpeedBonus > 0 then
		table.insert(badges, "Speed bonus")
	end
	if summary.Afk then
		table.insert(badges, "Low contribution · half completion reward")
	end
	self.Badges.Text = table.concat(badges, "   ")
	self.Badges.TextColor3 = if summary.Afk then Theme.Colors.Orange else Theme.Colors.Green

	local list = self.RewardList
	Components.ClearChildren(list, { "UIPadding", "UIListLayout" })
	Components.Label({ Text = "Rewards", Size = UDim2.new(1, 0, 0, 30), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 24, Stroke = 1.5, LayoutOrder = 0, Parent = list })
	rewardRow(list, 1, "Stickers peeled", summary.StickersPeeled, Theme.Colors.Cyan, "")
	rewardRow(list, 2, "Sticker coins", summary.StickerCoins, Theme.Colors.Coins)
	rewardRow(list, 3, "Completion", summary.CompletionCoins, Theme.Colors.Coins)
	rewardRow(list, 4, "Co-op bonus", summary.CoopBonus, Theme.Colors.Pink)
	rewardRow(list, 5, "Speed bonus", summary.SpeedBonus, Theme.Colors.Orange)
	rewardRow(list, 6, "TOTAL COINS", summary.TotalCoins, Theme.Colors.Yellow)
	rewardRow(list, 7, "XP", summary.XP, Theme.Colors.XP)
	if summary.Gems > 0 then
		rewardRow(list, 8, "Gems", summary.Gems, Theme.Colors.Gems)
	end

	local team = self.TeamList
	Components.ClearChildren(team, { "UIPadding", "UIListLayout" })
	Components.Label({ Text = "Team", Size = UDim2.new(1, 0, 0, 30), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 24, Stroke = 1.5, LayoutOrder = 0, Parent = team })
	for index, member in ipairs(summary.Team or {}) do
		local row = Components.Frame({ Size = UDim2.new(1, 0, 0, 40), Color = Theme.Colors.Panel, Transparency = 0.3, Corner = 10, LayoutOrder = index, Parent = team })
		Components.Avatar(member.UserId, { Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(4, 4), Parent = row })
		Components.Label({ Text = member.Name, Size = UDim2.new(1, -120, 1, -10), Position = UDim2.fromOffset(42, 5), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 17, Parent = row })
		Components.Label({ Text = Utility.FormatNumber(member.Peeled), Size = UDim2.fromOffset(70, 30), Position = UDim2.new(1, -76, 0, 5), XAlign = Enum.TextXAlignment.Right, Color = Theme.Colors.Cyan, MaxTextSize = 20, Stroke = 1.5, Parent = row })
	end
	if #(summary.RareFound or {}) > 0 then
		Components.Label({ Text = "Rare stickers", Size = UDim2.new(1, 0, 0, 24), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 18, Stroke = 1.5, LayoutOrder = 20, Parent = team })
		local parts = {}
		for _, entry in ipairs(summary.RareFound) do
			local info = StickerConfig.Get(entry.Type)
			if info then
				table.insert(parts, string.format("<font color=\"#%s\">%s ×%d</font>", Rarity.Color(info.Rarity):ToHex(), info.DisplayName, entry.Count))
			end
		end
		Components.Label({ Text = table.concat(parts, "   "), RichText = true, Size = UDim2.new(1, 0, 0, 44), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 15, LayoutOrder = 21, Parent = team })
	end

	self.Gui.Enabled = true
	Components.Pop(self.Panel, 0.5)
	local returnAt = os.clock() + (summary.ReturnIn or 30)
	self.Token = (self.Token or 0) + 1
	local token = self.Token
	task.spawn(function()
		while self.Gui.Enabled and token == self.Token do
			local remaining = math.max(0, math.ceil(returnAt - os.clock()))
			self.Countdown.Text = string.format("Returning to lobby in %ds", remaining)
			task.wait(0.25)
		end
	end)
end

function ResultsScreen:Hide()
	self.Gui.Enabled = false
end

return ResultsScreen
