--[[
	ProfileScreen (ProfileUI)
	Player card, level progress, statistics, rare sticker collection and best times.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DifficultyConfig = require(Shared.DifficultyConfig)
local LevelConfig = require(Shared.LevelConfig)
local Progression = require(Shared.Progression)
local Rarity = require(Shared.Rarity)
local StickerConfig = require(Shared.StickerConfig)
local Utility = require(Shared.Utility)

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local LOCAL_PLAYER = Players.LocalPlayer

local ProfileScreen = {}
ProfileScreen.__index = ProfileScreen

function ProfileScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, ProfileScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Window = Components.Window(gui, {
		Name = "ProfileWindow",
		Title = "Profile",
		Color = Theme.Colors.Cyan,
		Size = UDim2.fromOffset(980, 600),
		OnOpen = function()
			self:Refresh()
		end,
	})
	local content = self.Window.Content

	local card = Components.Frame({ Name = "Card", Size = UDim2.new(0, 280, 1, 0), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 14, Parent = content })
	Components.Avatar(LOCAL_PLAYER.UserId, { Size = UDim2.fromOffset(140, 140), Position = UDim2.new(0.5, 0, 0, 16), AnchorPoint = Vector2.new(0.5, 0), StrokeColor = Theme.Colors.Cyan, Parent = card })
	Components.Label({ Text = LOCAL_PLAYER.DisplayName, Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 164), MaxTextSize = 28, Stroke = 2, Parent = card })
	Components.Label({ Text = "@" .. LOCAL_PLAYER.Name, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 196), Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 16, Parent = card })
	self.LevelText = Components.Label({ Text = "LEVEL 1", Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 228), Color = Theme.Colors.XP, MaxTextSize = 26, Stroke = 1.5, Parent = card })
	self.XPBar = Components.ProgressBar({ Size = UDim2.new(1, -30, 0, 24), Position = UDim2.fromOffset(15, 264), Color = Theme.Colors.XP, MaxTextSize = 15, Parent = card })
	self.RareText = Components.Label({ Text = "", Size = UDim2.new(1, -24, 1, -310), Position = UDim2.fromOffset(12, 300), XAlign = Enum.TextXAlignment.Left, YAlign = Enum.TextYAlignment.Top, Font = Theme.Fonts.Bold, MaxTextSize = 16, RichText = true, Parent = card })

	local right = Components.Scroll({ Name = "Details", Size = UDim2.new(1, -296, 1, 0), Position = UDim2.fromOffset(296, 0), Parent = content })
	Components.List(right, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Left)
	self.Details = right
	return self
end

local function section(parent: Instance, order: number, title: string)
	Components.Label({ Text = title, Size = UDim2.new(1, -12, 0, 30), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 24, Stroke = 1.5, LayoutOrder = order, Parent = parent })
end

function ProfileScreen:Refresh()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	self.LevelText.Text = "LEVEL " .. data.Level
	local needed = Progression.XPToNext(data.Level)
	self.XPBar.Set(data.XP / needed, string.format("%s / %s XP", Utility.FormatNumber(math.floor(data.XP)), Utility.FormatNumber(needed)), false)

	local rareLines = { "<font size=\"18\">Rare collection</font>" }
	for _, id in ipairs(StickerConfig.Order) do
		local info = StickerConfig.Get(id)
		if info.IsRare then
			local count = data.Statistics.RareByType[id] or 0
			table.insert(rareLines, string.format("<font color=\"#%s\">%s</font>  ×%d", Rarity.Color(info.Rarity):ToHex(), info.DisplayName, count))
		end
	end
	self.RareText.Text = table.concat(rareLines, "\n")

	local details = self.Details
	Components.ClearChildren(details, { "UIListLayout" })
	section(details, 1, "Statistics")
	local stats = data.Statistics
	local grid = Components.Create("Frame", { Name = "Stats", Size = UDim2.new(1, -12, 0, 170), BackgroundTransparency = 1, LayoutOrder = 2, Parent = details })
	Components.Create("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0, 78), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	local entries = {
		{ "Stickers Peeled", Utility.FormatNumber(stats.StickersPeeled), Theme.Colors.Cyan },
		{ "Rare Found", Utility.FormatNumber(stats.RareFound), Theme.Colors.Purple },
		{ "Levels Cleared", Utility.FormatNumber(stats.LevelsCompleted), Theme.Colors.Green },
		{ "Highest Combo", "x" .. stats.HighestCombo, Theme.Colors.Yellow },
		{ "Coins Earned", Utility.Abbreviate(stats.CoinsEarned), Theme.Colors.Coins },
		{ "Gems Earned", Utility.Abbreviate(stats.GemsEarned), Theme.Colors.Gems },
		{ "Co-op Stickers", Utility.Abbreviate(stats.CoopStickers), Theme.Colors.Pink },
		{ "Play Time", string.format("%dh %02dm", math.floor(stats.PlayTime / 3600), math.floor(stats.PlayTime / 60) % 60), Theme.Colors.TextDim },
	}
	for index, entry in ipairs(entries) do
		local tile = Components.Frame({ Size = UDim2.fromScale(1, 1), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 12, Stroke = 2, StrokeColor = entry[3], LayoutOrder = index, Parent = grid })
		Components.Label({ Text = entry[2], Size = UDim2.new(1, -10, 0, 38), Position = UDim2.fromOffset(5, 6), Color = entry[3], MaxTextSize = 30, Stroke = 1.5, Parent = tile })
		Components.Label({ Text = entry[1], Size = UDim2.new(1, -10, 0, 20), Position = UDim2.fromOffset(5, 48), Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 14, Parent = tile })
	end

	section(details, 3, "Best times")
	local table_ = Components.Frame({ Name = "BestTimes", Size = UDim2.new(1, -12, 0, 0), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 12, LayoutOrder = 4, Parent = details })
	table_.AutomaticSize = Enum.AutomaticSize.Y
	Components.Padding(table_, 8)
	Components.List(table_, Enum.FillDirection.Vertical, 4)
	local header = Components.Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 0, Parent = table_ })
	Components.Label({ Text = "LEVEL", Size = UDim2.new(0.28, 0, 1, 0), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 15, Parent = header })
	for i, id in ipairs(DifficultyConfig.Order) do
		local difficulty = DifficultyConfig.Get(id)
		Components.Label({ Text = difficulty.DisplayName, Size = UDim2.new(0.18, 0, 1, 0), Position = UDim2.new(0.28 + (i - 1) * 0.18, 0, 0, 0), Font = Theme.Fonts.Bold, Color = difficulty.Color, MaxTextSize = 15, Parent = header })
	end
	for index, level in ipairs(LevelConfig.GetOrdered()) do
		local row = Components.Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = index, Parent = table_ })
		Components.Label({ Text = level.Name, Size = UDim2.new(0.28, 0, 1, 0), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 15, Parent = row })
		for i, id in ipairs(DifficultyConfig.Order) do
			local best = data.BestTimes[LevelConfig.RecordKey(level.LevelId, id)]
			Components.Label({
				Text = if best then Utility.FormatTime(best) else "—",
				Size = UDim2.new(0.18, 0, 1, 0),
				Position = UDim2.new(0.28 + (i - 1) * 0.18, 0, 0, 0),
				Font = Theme.Fonts.Bold,
				Color = if best then Theme.Colors.Text else Theme.Colors.Grey,
				MaxTextSize = 15,
				Parent = row,
			})
		end
	end
end

function ProfileScreen:Update() end

return ProfileScreen
