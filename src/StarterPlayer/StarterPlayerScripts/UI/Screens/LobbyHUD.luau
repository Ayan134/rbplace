--[[
	LobbyHUD (LobbyUI)
	Side menu of big icon buttons (Play, Shop, Upgrades, Tools, Levels, Profile, Settings)
	with keyboard shortcuts, the daily quest tracker and a short hint.
	Money, gems, level and the bag live in the HUD screen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestConfig = require(Shared.QuestConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local LobbyHUD = {}
LobbyHUD.__index = LobbyHUD

-- Key shortcuts are handled by UIController (UIController.Shortcuts)
LobbyHUD.Menu = {
	{ Id = "Party", Text = "Play", Icon = "🎮", Color = Theme.Colors.Green, Key = "Q" },
	{ Id = "Shop", Text = "Shop", Icon = "🛒", Color = Theme.Colors.Yellow, Key = "B" },
	{ Id = "Upgrades", Text = "Upgrade", Icon = "⬆️", Color = Theme.Colors.Orange, Key = "U" },
	{ Id = "Inventory", Text = "Tools", Icon = "🧰", Color = Theme.Colors.Blue, Key = "T" },
	{ Id = "Levels", Text = "Levels", Icon = "🗺️", Color = Theme.Colors.Cyan, Key = "L" },
	{ Id = "Profile", Text = "Profile", Icon = "👤", Color = Theme.Colors.Pink, Key = "P" },
	{ Id = "Settings", Text = "Settings", Icon = "⚙️", Color = Theme.Colors.Purple, Key = "M" },
}

function LobbyHUD.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, LobbyHUD)
	self.Gui = gui
	self.Ctx = ctx

	-- Side menu: two columns of icon buttons
	local menu = Components.Create("Frame", {
		Name = "Menu",
		Size = UDim2.fromOffset(190, 420),
		Position = UDim2.new(0, 28, 0.5, 60),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Components.Create("UIGridLayout", {
		CellSize = UDim2.fromOffset(80, 98),
		CellPadding = UDim2.fromOffset(16, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = menu,
	})
	local keyboard = ctx.Controllers.InteractionController.InputMode == "KeyboardMouse"
	for index, entry in ipairs(LobbyHUD.Menu) do
		Components.IconButton({
			Name = entry.Id,
			Icon = entry.Icon,
			Text = entry.Text,
			Color = entry.Color,
			Key = if keyboard then entry.Key else nil,
			Size = UDim2.fromOffset(80, 78),
			LayoutOrder = index,
			OnClick = function()
				ctx.UI.ToggleWindow(entry.Id)
			end,
			Parent = menu,
		})
	end

	-- Daily quests
	local quests = Components.Frame({
		Name = "Quests",
		Size = UDim2.fromOffset(310, 270),
		Position = UDim2.new(1, -20, 0.5, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Theme.Colors.Panel,
		Transparency = 0.08,
		Corner = 18,
		Stroke = 3.5,
		Parent = gui,
	})
	local questHeader = Components.Frame({ Name = "Header", Size = UDim2.new(1, 0, 0, 44), Color = Color3.new(1, 1, 1), Gradient = { Theme.Lighten(Theme.Colors.Purple, 0.2), Theme.Colors.Purple, 90 }, Corner = 18, Parent = quests })
	Components.Frame({ Name = "HeaderBase", Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), Color = Theme.Colors.Purple, Corner = false, Flat = true, Parent = questHeader })
	Components.Label({ Name = "Title", Text = "📜 DAILY QUESTS", Size = UDim2.new(1, -24, 0, 32), Position = UDim2.fromOffset(14, 6), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 22, Stroke = 2.5, ZIndex = 2, Parent = questHeader })
	local questList = Components.Create("Frame", { Name = "List", Size = UDim2.new(1, -24, 1, -60), Position = UDim2.fromOffset(12, 54), BackgroundTransparency = 1, Parent = quests })
	Components.List(questList, Enum.FillDirection.Vertical, 6)
	self.Quests = quests
	self.QuestList = questList

	-- Hint
	self.Hint = Components.Label({
		Name = "Hint",
		Text = "",
		Size = UDim2.fromOffset(760, 30),
		Position = UDim2.new(0.5, 0, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = Theme.Colors.Text,
		MaxTextSize = 20,
		Stroke = 2,
		Parent = gui,
	})
	ctx.Controllers.InteractionController.InputModeChanged:Connect(function(mode)
		self:UpdateHint(mode)
	end)
	self:UpdateHint(ctx.Controllers.InteractionController.InputMode)
	return self
end

function LobbyHUD:UpdateHint(mode: string)
	local action = if mode == "Touch" then "Hold PEEL" elseif mode == "Gamepad" then "Hold X" else "Hold E"
	self.Hint.Text = action .. " on the sticker pile to collect  •  Empty your bag in a 🗑️ trash can  •  Step into a circle to play"
end

function LobbyHUD:SetQuestsVisible(visible: boolean)
	self.Quests.Visible = visible
end

function LobbyHUD:Update(data)
	-- Only rebuild the quest rows when quest state actually changed
	local signature = ""
	for _, quest in ipairs(data.Quests and data.Quests.List or {}) do
		signature ..= string.format("%s:%d:%s;", quest.Id, quest.Progress, tostring(quest.Claimed))
	end
	if signature == self.QuestSignature then
		return
	end
	self.QuestSignature = signature
	local list = self.QuestList
	Components.ClearChildren(list, { "UIListLayout" })
	for index, quest in ipairs(data.Quests and data.Quests.List or {}) do
		local template = QuestConfig.Get(quest.Id)
		if not template then
			continue
		end
		local row = Components.Create("Frame", { Name = "Quest", Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, LayoutOrder = index, Parent = list })
		Components.Label({ Text = string.format(template.Text, quest.Target), Size = UDim2.new(1, -96, 0, 20), Position = UDim2.fromOffset(2, 6), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 16, Stroke = 1.5, Parent = row })
		local bar = Components.ProgressBar({ Size = UDim2.new(1, -96, 0, 12), Position = UDim2.fromOffset(2, 34), Color = Theme.Colors.Accent, MaxTextSize = 10, Parent = row })
		bar.Set(quest.Progress / quest.Target, string.format("%s / %s", Utility.Abbreviate(quest.Progress), Utility.Abbreviate(quest.Target)), false)
		local rewardText = string.format("%s  💎%d", Utility.FormatMoney(template.RewardCoins[quest.Tier]), template.RewardGems[quest.Tier])
		if quest.Claimed then
			Components.Label({ Text = "✔ Done", Size = UDim2.fromOffset(84, 36), Position = UDim2.new(1, -86, 0, 10), Font = Theme.Fonts.Bold, Color = Theme.Colors.Accent, MaxTextSize = 18, Stroke = 2, Parent = row })
		elseif quest.Progress >= quest.Target then
			Components.Button({
				Text = "Claim",
				Size = UDim2.fromOffset(84, 36),
				Position = UDim2.new(1, -86, 0, 10),
				Color = Theme.Colors.Accent,
				MaxTextSize = 14,
				OnClick = function()
					local result = Remotes.ClaimQuest:InvokeServer(index)
					if result and result.Success then
						self.Ctx.Controllers.SoundManager.Play("Purchase")
						self.Ctx.UI.Toast(string.format("Quest reward: +%s, +%d gems", Utility.FormatMoney(result.Coins), result.Gems), "Reward")
					elseif result then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end,
				Parent = row,
			})
		else
			Components.Label({ Text = rewardText, Size = UDim2.fromOffset(88, 36), Position = UDim2.new(1, -88, 0, 10), Font = Theme.Fonts.Bold, MaxTextSize = 14, Color = Theme.Colors.Money, Stroke = 1.5, Parent = row })
		end
	end
end

function LobbyHUD:SetVisible(visible: boolean)
	self.Gui.Enabled = visible
end

return LobbyHUD
