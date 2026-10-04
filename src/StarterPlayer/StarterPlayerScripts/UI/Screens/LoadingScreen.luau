--[[
	LoadingScreen (LoadingUI)
	Shown while the server builds the arena and streams the stickers.
	The progress bar reflects sticker chunks actually received and built.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DifficultyConfig = require(Shared.DifficultyConfig)
local LevelConfig = require(Shared.LevelConfig)
local Utility = require(Shared.Utility)

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

local TIPS = {
	"Hold PEEL to keep peeling - nearby stickers are chained automatically!",
	"Golden, Rainbow and Diamond stickers pay x5, x10 and x25!",
	"Peel quickly to build a COMBO and earn bonus coins.",
	"Hard-to-reach stickers on roofs and undersides give +25% coins.",
	"Upgrade Sticker Capacity to peel several stickers at once.",
	"Climb the yellow trusses and scaffolding to reach high spots.",
	"Playing with friends gives a co-op bonus on completion.",
	"Beat the par time for a speed bonus!",
	"Extreme difficulty spawns special Diamond and Legendary stickers.",
}

function LoadingScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, LoadingScreen)
	self.Gui = gui
	self.Ctx = ctx
	gui.Enabled = false
	gui.DisplayOrder = 20
	gui.IgnoreGuiInset = true

	local background = Components.Frame({ Name = "Background", Size = UDim2.fromScale(1, 1), Color = Color3.new(1, 1, 1), Corner = false, Gradient = { Color3.fromRGB(60, 40, 120), Color3.fromRGB(20, 16, 40), 90 }, Parent = gui })
	self.Background = background
	self.Preview = Components.Create("Frame", { Name = "PreviewHolder", Size = UDim2.fromOffset(420, 260), Position = UDim2.new(0.5, 0, 0.36, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = background })
	self.Title = Components.Label({ Text = "LOADING", Size = UDim2.fromOffset(800, 70), Position = UDim2.new(0.5, 0, 0.62, 0), AnchorPoint = Vector2.new(0.5, 0.5), MaxTextSize = 64, Stroke = 3, Parent = background })
	self.Subtitle = Components.Label({ Text = "", Size = UDim2.fromOffset(800, 32), Position = UDim2.new(0.5, 0, 0.69, 0), AnchorPoint = Vector2.new(0.5, 0.5), Font = Theme.Fonts.Bold, MaxTextSize = 26, Stroke = 2, Parent = background })
	self.Bar = Components.ProgressBar({ Size = UDim2.fromOffset(560, 30), Position = UDim2.new(0.5, 0, 0.77, 0), AnchorPoint = Vector2.new(0.5, 0.5), Color = Theme.Colors.Pink, MaxTextSize = 18, Stroke = 2, StrokeColor = Color3.new(1, 1, 1), Parent = background })
	self.Tip = Components.Label({ Text = "", Size = UDim2.fromOffset(820, 30), Position = UDim2.new(0.5, 0, 0.86, 0), AnchorPoint = Vector2.new(0.5, 0.5), Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 20, Parent = background })
	return self
end

function LoadingScreen:Show(levelId: string, difficultyId: string, total: number?)
	local level = LevelConfig.Get(levelId)
	local difficulty = DifficultyConfig.Get(difficultyId)
	Components.ClearChildren(self.Preview)
	local preview = ReplicatedStorage.Assets.LevelPreviews:FindFirstChild(levelId)
	Components.Viewport(preview, { Rotate = true, RotateSpeed = 0.6, Parent = self.Preview })
	self.Title.Text = string.upper(level and level.Name or levelId)
	self.Subtitle.Text = string.format("%s • %s stickers", difficulty and difficulty.DisplayName or difficultyId, Utility.FormatNumber(total or 0))
	self.Subtitle.TextColor3 = difficulty and difficulty.Color or Theme.Colors.Text
	self.Tip.Text = "💡 " .. TIPS[math.random(1, #TIPS)]
	self.Bar.Set(0, "Building the level...", false)
	self.Background.BackgroundTransparency = 0
	self.Gui.Enabled = true
end

function LoadingScreen:SetProgress(fraction: number, text: string?)
	self.Bar.Set(fraction, text or string.format("Placing stickers... %d%%", math.floor(fraction * 100)))
end

function LoadingScreen:Hide()
	if not self.Gui.Enabled then
		return
	end
	self.Bar.Set(1, "Ready!")
	task.delay(0.25, function()
		local fade = TweenService:Create(self.Background, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		self.Gui.Enabled = false
	end)
end

return LoadingScreen
