--[[
	LobbyHUD (LobbyUI)
	Top bar (Coins / Gems / Level + XP), main menu (PLAY, LEVELS, INVENTORY, UPGRADES,
	SHOP, SETTINGS, PROFILE) and the daily quest tracker.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)
local QuestConfig = require(Shared.QuestConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local LobbyHUD = {}
LobbyHUD.__index = LobbyHUD

local MENU = {
	{ Id = "Party", Text = "Play" },
	{ Id = "Levels", Text = "Levels" },
	{ Id = "Inventory", Text = "Inventory" },
	{ Id = "Upgrades", Text = "Upgrades" },
	{ Id = "Shop", Text = "Shop" },
	{ Id = "Settings", Text = "Settings" },
	{ Id = "Profile", Text = "Profile" },
}

-- Top bar is shared with the gameplay HUD (coins stay visible everywhere)
function LobbyHUD.BuildTopBar(parent: Instance)
	local bar = Components.Create("Frame", {
		Name = "TopBar",
		Size = UDim2.fromOffset(620, 54),
		Position = UDim2.new(0.5, 0, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	Components.List(bar, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local coins = Components.Pill({ Name = "Coins", Icon = "●", Color = Theme.Colors.Coins, LayoutOrder = 1, Size = UDim2.fromOffset(170, 38), Parent = bar })
	local gems = Components.Pill({ Name = "Gems", Icon = "◆", Color = Theme.Colors.Gems, LayoutOrder = 2, Size = UDim2.fromOffset(130, 38), Parent = bar })

	local levelFrame = Components.Frame({
		Name = "Level",
		Size = UDim2.fromOffset(220, 38),
		Color = Theme.Colors.Panel,
		Transparency = 0.2,
		Corner = 100,
		LayoutOrder = 3,
		Parent = bar,
	})
	local levelText = Components.Label({ Name = "Level", Text = "Lv 1", Size = UDim2.fromOffset(52, 24), Position = UDim2.fromOffset(12, 7), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Title, MaxTextSize = 16, Parent = levelFrame })
	local xpBar = Components.ProgressBar({ Name = "XP", Size = UDim2.new(1, -82, 0, 14), Position = UDim2.fromOffset(68, 12), Color = Theme.Colors.XP, MaxTextSize = 10, Parent = levelFrame })

	local shownCoins = 0
	local targetCoins = 0
	RunService.Heartbeat:Connect(function(dt)
		if shownCoins ~= targetCoins then
			local diff = targetCoins - shownCoins
			local step = math.max(1, math.abs(diff) * math.min(1, dt * 8))
			if math.abs(diff) <= step then
				shownCoins = targetCoins
			else
				shownCoins += math.sign(diff) * step
			end
			coins.Value.Text = Utility.FormatNumber(shownCoins)
		end
	end)

	return {
		Instance = bar,
		Update = function(data)
			targetCoins = data.Coins
			if shownCoins == 0 then
				shownCoins = data.Coins
				coins.Value.Text = Utility.FormatNumber(shownCoins)
			end
			gems.Value.Text = Utility.FormatNumber(data.Gems)
			levelText.Text = "Lv " .. data.Level
			local needed = Progression.XPToNext(data.Level)
			xpBar.Set(data.XP / needed, string.format("%s / %s XP", Utility.Abbreviate(math.floor(data.XP)), Utility.Abbreviate(needed)))
		end,
	}
end

function LobbyHUD.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, LobbyHUD)
	self.Gui = gui
	self.Ctx = ctx

	self.TopBar = LobbyHUD.BuildTopBar(gui)

	-- Main menu: slim vertical list, only Play is accented
	local menu = Components.Create("Frame", {
		Name = "Menu",
		Size = UDim2.fromOffset(170, #MENU * 46),
		Position = UDim2.new(0, 20, 0.5, 10),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Components.List(menu, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Left)
	for index, entry in ipairs(MENU) do
		local button = Components.Button({
			Name = entry.Id,
			Text = entry.Text,
			Size = UDim2.fromOffset(170, 40),
			Color = if index == 1 then Theme.Colors.Accent else Theme.Colors.PanelLight,
			LayoutOrder = index,
			MaxTextSize = 16,
			OnClick = function()
				ctx.UI.ToggleWindow(entry.Id)
			end,
			Parent = menu,
		})
		button.Label.TextXAlignment = Enum.TextXAlignment.Left
		if index > 1 then
			button.Instance.BackgroundTransparency = 0.2
		end
	end

	-- Daily quests
	local quests = Components.Frame({
		Name = "Quests",
		Size = UDim2.fromOffset(300, 250),
		Position = UDim2.new(1, -16, 0.5, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Theme.Colors.Panel,
		Transparency = 0.15,
		Corner = 12,
		Parent = gui,
	})
	Components.Label({ Name = "Title", Text = "Daily quests", Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(12, 12), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 17, Parent = quests })
	local questList = Components.Create("Frame", { Name = "List", Size = UDim2.new(1, -20, 1, -50), Position = UDim2.fromOffset(10, 44), BackgroundTransparency = 1, Parent = quests })
	Components.List(questList, Enum.FillDirection.Vertical, 6)
	self.Quests = quests
	self.QuestList = questList

	-- Practice hint
	self.Hint = Components.Label({
		Name = "Hint",
		Text = "Hold E near the fountain to practice  ·  Step into a circle to play",
		Size = UDim2.fromOffset(700, 30),
		Position = UDim2.new(0.5, 0, 1, -24),
		AnchorPoint = Vector2.new(0.5, 1),
		Font = Theme.Fonts.Bold,
		Color = Theme.Colors.TextDim,
		MaxTextSize = 15,
		Stroke = 1,
		Parent = gui,
	})
	ctx.Controllers.InteractionController.InputModeChanged:Connect(function(mode)
		self:UpdateHint(mode)
	end)
	self:UpdateHint(ctx.Controllers.InteractionController.InputMode)
	return self
end

function LobbyHUD:UpdateHint(mode: string)
	if mode == "Touch" then
		self.Hint.Text = "Hold PEEL near the fountain to practice  ·  Step into a circle to play"
	elseif mode == "Gamepad" then
		self.Hint.Text = "Hold X near the fountain to practice  ·  Step into a circle to play"
	else
		self.Hint.Text = "Hold E near the fountain to practice  ·  Step into a circle to play"
	end
end

function LobbyHUD:SetQuestsVisible(visible: boolean)
	self.Quests.Visible = visible
end

function LobbyHUD:Update(data)
	self.TopBar.Update(data)
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
		Components.Label({ Text = string.format(template.Text, quest.Target), Size = UDim2.new(1, -96, 0, 20), Position = UDim2.fromOffset(2, 6), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 14, Parent = row })
		local bar = Components.ProgressBar({ Size = UDim2.new(1, -96, 0, 12), Position = UDim2.fromOffset(2, 34), Color = Theme.Colors.Accent, MaxTextSize = 10, Parent = row })
		bar.Set(quest.Progress / quest.Target, string.format("%s / %s", Utility.Abbreviate(quest.Progress), Utility.Abbreviate(quest.Target)), false)
		local rewardText = string.format("● %s  ◆ %d", Utility.Abbreviate(template.RewardCoins[quest.Tier]), template.RewardGems[quest.Tier])
		if quest.Claimed then
			Components.Label({ Text = "Done", Size = UDim2.fromOffset(84, 36), Position = UDim2.new(1, -86, 0, 10), Font = Theme.Fonts.Bold, Color = Theme.Colors.Accent, MaxTextSize = 14, Parent = row })
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
						self.Ctx.UI.Toast(string.format("Quest reward: +%s Coins, +%d Gems", Utility.FormatNumber(result.Coins), result.Gems), "Reward")
					elseif result then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end,
				Parent = row,
			})
		else
			Components.Label({ Text = rewardText, Size = UDim2.fromOffset(88, 36), Position = UDim2.new(1, -88, 0, 10), Font = Theme.Fonts.Bold, MaxTextSize = 12, Color = Theme.Colors.TextDim, Parent = row })
		end
	end
end

function LobbyHUD:SetVisible(visible: boolean)
	self.Gui.Enabled = visible
end

return LobbyHUD
