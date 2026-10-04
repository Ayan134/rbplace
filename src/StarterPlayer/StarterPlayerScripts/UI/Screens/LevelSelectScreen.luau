--[[
	LevelSelectScreen (LevelSelectUI)
	Big level cards: 3D preview, name, stars, sticker count, recommended players, reward,
	best time and lock / unlock state. Difficulty tabs update counts and rewards.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DifficultyConfig = require(Shared.DifficultyConfig)
local LevelConfig = require(Shared.LevelConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local LOCAL_PLAYER = Players.LocalPlayer

local LevelSelectScreen = {}
LevelSelectScreen.__index = LevelSelectScreen

function LevelSelectScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, LevelSelectScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Difficulty = "Normal"
	self.Window = Components.Window(gui, {
		Name = "LevelsWindow",
		Title = "🗺️ LEVELS",
		Color = Theme.Colors.Blue,
		Size = UDim2.fromOffset(1000, 640),
		OnOpen = function()
			self:Refresh()
		end,
	})
	local content = self.Window.Content

	local tabs = Components.Create("Frame", { Name = "Tabs", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = content })
	Components.List(tabs, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center)
	self.Tabs = {}
	for index, id in ipairs(DifficultyConfig.Order) do
		local difficulty = DifficultyConfig.Get(id)
		self.Tabs[id] = Components.Button({
			Text = difficulty.DisplayName,
			Size = UDim2.fromOffset(170, 44),
			Color = difficulty.Color,
			LayoutOrder = index,
			MaxTextSize = 22,
			OnClick = function()
				self.Difficulty = id
				self:Refresh()
			end,
			Parent = tabs,
		})
	end

	local scroll = Components.Scroll({ Name = "Cards", Size = UDim2.new(1, 0, 1, -58), Position = UDim2.fromOffset(0, 58), Direction = Enum.ScrollingDirection.X, Automatic = Enum.AutomaticSize.X, Parent = content })
	Components.List(scroll, Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	Components.Padding(scroll, 6, 6)
	self.Scroll = scroll
	return self
end

function LevelSelectScreen:Select(levelId: string)
	local controllers = self.Ctx.Controllers
	local party = controllers.DataController.Party.MyParty
	if party and party.HostUserId == LOCAL_PLAYER.UserId then
		task.spawn(function()
			local result = Remotes.PartyAction:InvokeServer("SetLevel", levelId)
			if result and not result.Success then
				self.Ctx.UI.Toast(result.Message, "Error")
				return
			end
			if party.Difficulty ~= self.Difficulty then
				local diffResult = Remotes.PartyAction:InvokeServer("SetDifficulty", self.Difficulty)
				if diffResult and not diffResult.Success then
					self.Ctx.UI.Toast(diffResult.Message, "Error")
				end
			end
		end)
		self.Window.Close()
		return
	end
	if party then
		self.Ctx.UI.Toast("Only the HOST can change the level", "Error")
		return
	end
	self.Ctx.UI.OpenPartyWithLevel(levelId, self.Difficulty)
end

function LevelSelectScreen:Refresh()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	for id, button in pairs(self.Tabs) do
		local difficulty = DifficultyConfig.Get(id)
		button.SetText((if id == self.Difficulty then "✔ " else "") .. difficulty.DisplayName .. (if data.Level >= difficulty.RequiredLevel then "" else " 🔒"))
	end
	Components.ClearChildren(self.Scroll, { "UIListLayout", "UIPadding" })

	for index, level in ipairs(LevelConfig.GetOrdered()) do
		local unlocked = data.UnlockedLevels[level.LevelId] == true
		local levelMet = data.Level >= level.RequiredLevel
		local card = Components.Frame({
			Name = level.LevelId,
			Size = UDim2.fromOffset(270, 470),
			Color = Theme.Colors.PanelDark,
			Corner = 16,
			Stroke = 3,
			StrokeColor = if unlocked then level.ThemeColor else Theme.Colors.Grey,
			LayoutOrder = index,
			Parent = self.Scroll,
		})
		local preview = ReplicatedStorage.Assets.LevelPreviews:FindFirstChild(level.LevelId)
		local viewport = Components.Viewport(preview, {
			Size = UDim2.new(1, -16, 0, 170),
			Position = UDim2.fromOffset(8, 8),
			Background = Theme.Lighten(level.ThemeColor, 0.55),
			Corner = 12,
			Rotate = true,
			RotateSpeed = 0.4,
			Parent = card,
		})
		if not unlocked then
			viewport.ImageColor3 = Color3.fromRGB(110, 110, 120)
			Components.Label({ Text = "🔒", Size = UDim2.fromOffset(70, 70), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3, Parent = viewport })
		end

		local y = 184
		local function line(text: string, color: Color3?, height: number?, font: Enum.Font?)
			Components.Label({
				Text = text,
				Size = UDim2.new(1, -20, 0, height or 22),
				Position = UDim2.fromOffset(10, y),
				Font = font or Theme.Fonts.Bold,
				Color = color or Theme.Colors.Text,
				MaxTextSize = (height or 22) - 2,
				RichText = true,
				Stroke = if font == Theme.Fonts.Title then 1.5 else nil,
				Parent = card,
			})
			y += (height or 22) + 4
		end
		line(string.upper(level.Name), Theme.Colors.Text, 32, Theme.Fonts.Title)
		line(Components.Stars(level.Stars), Theme.Colors.Yellow, 24)
		line(Utility.FormatNumber(LevelConfig.GetStickerCount(level.LevelId, self.Difficulty)) .. " STICKERS", Theme.Colors.Cyan)
		local players = level.RecommendedPlayers
		line(if players[1] == players[2] then players[1] .. " PLAYERS" else string.format("%d-%d PLAYERS", players[1], players[2]), Theme.Colors.TextDim)
		line("REWARD: " .. Utility.FormatNumber(LevelConfig.EstimateTotalReward(level.LevelId, self.Difficulty)) .. " COINS", Theme.Colors.Coins)
		local best = data.BestTimes[LevelConfig.RecordKey(level.LevelId, self.Difficulty)]
		line("BEST: " .. (if best then Utility.FormatTime(best) else "--:--"), Theme.Colors.Green)
		line(level.Description, Theme.Colors.TextDim, 40, Theme.Fonts.Body)

		local button
		if unlocked then
			button = Components.Button({ Text = "SELECT", Color = Theme.Colors.Green, OnClick = function()
				self:Select(level.LevelId)
			end })
		elseif levelMet then
			button = Components.Button({
				Text = "UNLOCK 🪙 " .. Utility.FormatNumber(level.UnlockCost),
				Color = Theme.Colors.Yellow,
				OnClick = function()
					local result = Remotes.UnlockLevel:InvokeServer(level.LevelId)
					if result and result.Success then
						self.Ctx.Controllers.SoundManager.Play("Purchase")
						self.Ctx.UI.Toast(level.Name .. " unlocked!", "Success")
						task.delay(0.2, function()
							self:Refresh()
						end)
					elseif result then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end,
			})
			button.SetEnabled(data.Coins >= level.UnlockCost)
		else
			button = Components.Button({ Text = "🔒 LEVEL " .. level.RequiredLevel, Color = Theme.Colors.Grey })
			button.SetEnabled(false)
		end
		button.Instance.Size = UDim2.new(1, -20, 0, 50)
		button.Instance.Position = UDim2.new(0, 10, 1, -60)
		button.Instance.Parent = card
	end
end

function LevelSelectScreen:Update()
	local data = self.Ctx.Controllers.DataController.Get()
	if not self.Window.IsOpen() or not data then
		return
	end
	-- Rebuild only when something shown on the cards changed
	local signature = tostring(data.Level)
	for _, level in ipairs(LevelConfig.GetOrdered()) do
		local affordable = data.Coins >= level.UnlockCost
		signature ..= string.format("|%s%s%s", tostring(data.UnlockedLevels[level.LevelId]), tostring(affordable), tostring(data.BestTimes[LevelConfig.RecordKey(level.LevelId, self.Difficulty)]))
	end
	if signature ~= self.Signature then
		self.Signature = signature
		self:Refresh()
	end
end

return LevelSelectScreen
