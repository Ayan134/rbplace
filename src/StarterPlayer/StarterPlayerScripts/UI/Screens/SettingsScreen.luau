--[[
	SettingsScreen (SettingsUI)
	Music / SFX volume, low VFX mode, auto-chain peeling, other players' effects.
	Settings are saved in the player's data through a validated remote.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local SettingsScreen = {}
SettingsScreen.__index = SettingsScreen

local TOGGLES = {
	{ Key = "AutoChain", Title = "Auto-chain peeling", Description = "Keep peeling nearby stickers while you hold PEEL" },
	{ Key = "LowVFX", Title = "Low effects mode", Description = "Fewer particles - better for older phones" },
	{ Key = "ShowOthersVFX", Title = "Teammate effects", Description = "Show particles when other players peel" },
}

function SettingsScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, SettingsScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Pending = {}
	self.Window = Components.Window(gui, {
		Name = "SettingsWindow",
		Icon = "⚙️",
		Title = "Settings",
		Color = Theme.Colors.Purple,
		Size = UDim2.fromOffset(640, 520),
		OnOpen = function()
			self:Refresh()
		end,
		OnClose = function()
			self:Save()
		end,
	})
	local content = self.Window.Content
	local list = Components.Create("Frame", { Name = "List", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	Components.List(list, Enum.FillDirection.Vertical, 12)

	self.Sliders = {}
	self.Sliders.MusicVolume = self:BuildSlider(list, 1, "Music", "MusicVolume")
	self.Sliders.SFXVolume = self:BuildSlider(list, 2, "Sound effects", "SFXVolume")
	self.Toggles = {}
	for index, toggle in ipairs(TOGGLES) do
		self.Toggles[toggle.Key] = self:BuildToggle(list, 10 + index, toggle)
	end
	return self
end

function SettingsScreen:BuildSlider(parent: Instance, order: number, title: string, key: string)
	local row = Components.Frame({ Name = key, Size = UDim2.new(1, 0, 0, 70), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 12, LayoutOrder = order, Parent = parent })
	Components.Label({ Text = title, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromOffset(16, 0), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 22, Parent = row })
	local track = Components.Frame({ Name = "Track", Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.new(0.42, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Color = Theme.Colors.Panel, Corner = 100, Parent = row })
	local fill = Components.Frame({ Name = "Fill", Size = UDim2.fromScale(0.5, 1), Color = Theme.Colors.Purple, Corner = 100, Parent = track })
	local knob = Components.Frame({ Name = "Knob", Size = UDim2.fromOffset(30, 30), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = Color3.new(1, 1, 1), Corner = 100, Stroke = 3, StrokeColor = Theme.Colors.Purple, ZIndex = 3, Parent = track })
	local valueLabel = Components.Label({ Text = "50%", Size = UDim2.fromOffset(60, 30), Position = UDim2.new(1, -66, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Font = Theme.Fonts.Bold, MaxTextSize = 18, Parent = row })

	local function set(value: number)
		value = math.clamp(value, 0, 1)
		fill.Size = UDim2.fromScale(value, 1)
		knob.Position = UDim2.fromScale(value, 0.5)
		valueLabel.Text = string.format("%d%%", math.floor(value * 100 + 0.5))
		self.Pending[key] = value
		self:ApplyLocal()
	end

	local dragging = false
	local function updateFromInput(position: Vector3)
		local absolute = track.AbsolutePosition
		local size = track.AbsoluteSize
		set((position.X - absolute.X) / math.max(size.X, 1))
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			self:Save()
		end
	end)
	return { Set = set }
end

function SettingsScreen:BuildToggle(parent: Instance, order: number, toggle)
	local row = Components.Frame({ Name = toggle.Key, Size = UDim2.new(1, 0, 0, 70), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 12, LayoutOrder = order, Parent = parent })
	Components.Label({ Text = toggle.Title, Size = UDim2.new(1, -170, 0, 28), Position = UDim2.fromOffset(16, 8), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 20, Parent = row })
	Components.Label({ Text = toggle.Description, Size = UDim2.new(1, -170, 0, 22), Position = UDim2.fromOffset(16, 38), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Body, Color = Theme.Colors.TextDim, MaxTextSize = 15, Parent = row })
	local value = false
	local button
	button = Components.Button({
		Text = "OFF",
		Size = UDim2.fromOffset(120, 46),
		Position = UDim2.new(1, -136, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = Theme.Colors.Grey,
		OnClick = function()
			value = not value
			self.Pending[toggle.Key] = value
			button.SetText(if value then "ON" else "OFF")
			button.SetColor(if value then Theme.Colors.Green else Theme.Colors.Grey)
			self:Save()
		end,
		Parent = row,
	})
	return {
		Set = function(v: boolean)
			value = v
			button.SetText(if v then "ON" else "OFF")
			button.SetColor(if v then Theme.Colors.Green else Theme.Colors.Grey)
		end,
	}
end

function SettingsScreen:ApplyLocal()
	local data = self.Ctx.Controllers.DataController.Get()
	local settings = data and data.Settings or {}
	local music = self.Pending.MusicVolume or settings.MusicVolume or 0.5
	local sfx = self.Pending.SFXVolume or settings.SFXVolume or 0.8
	self.Ctx.Controllers.SoundManager.SetVolumes(sfx, music)
end

function SettingsScreen:Save()
	if next(self.Pending) then
		Remotes.UpdateSettings:FireServer(self.Pending)
		self.Pending = {}
	end
end

function SettingsScreen:Refresh()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	local settings = data.Settings
	self.Sliders.MusicVolume.Set(settings.MusicVolume)
	self.Sliders.SFXVolume.Set(settings.SFXVolume)
	self.Pending = {}
	for key, toggle in pairs(self.Toggles) do
		toggle.Set(settings[key] == true)
	end
end

function SettingsScreen:Update(data)
	if data and data.Settings and not self.Window.IsOpen() then
		self.Ctx.Controllers.SoundManager.SetVolumes(data.Settings.SFXVolume, data.Settings.MusicVolume)
	end
end

return SettingsScreen
