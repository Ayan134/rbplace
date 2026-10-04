--[[
	UpgradeScreen (UpgradeUI)
	Permanent upgrades: Peel Power, Peel Speed, Sticker Capacity, Luck, Reward Multiplier.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UpgradeConfig = require(Shared.UpgradeConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local UpgradeScreen = {}
UpgradeScreen.__index = UpgradeScreen

function UpgradeScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, UpgradeScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Window = Components.Window(gui, {
		Name = "UpgradeWindow",
		Title = "Upgrades",
		Color = Theme.Colors.Orange,
		Size = UDim2.fromOffset(860, 600),
		OnOpen = function()
			self.Signature = nil
			self:Refresh()
		end,
	})
	local scroll = Components.Scroll({ Name = "List", Parent = self.Window.Content })
	Components.List(scroll, Enum.FillDirection.Vertical, 10)
	Components.Padding(scroll, 4, 6)
	self.Scroll = scroll
	return self
end

function UpgradeScreen:Refresh()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	local signature = string.format("%d|%d", data.Coins, data.Level)
	for key, value in pairs(data.Upgrades) do
		signature ..= key .. value
	end
	if signature == self.Signature then
		return
	end
	self.Signature = signature

	Components.ClearChildren(self.Scroll, { "UIListLayout", "UIPadding" })
	for index, id in ipairs(UpgradeConfig.Order) do
		local upgrade = UpgradeConfig.Get(id)
		local level = data.Upgrades[id] or 0
		local maxed = level >= upgrade.MaxLevel
		local cost = UpgradeConfig.GetCost(id, level)
		local required = UpgradeConfig.GetRequiredPlayerLevel(id, level + 1)

		local row = Components.Frame({ Name = id, Size = UDim2.new(1, -12, 0, 96), Color = Theme.Colors.PanelDark, Transparency = 0.15, Corner = 14, Stroke = 2.5, StrokeColor = upgrade.Color, LayoutOrder = index, Parent = self.Scroll })
		local iconFrame = Components.Frame({ Size = UDim2.fromOffset(76, 76), Position = UDim2.fromOffset(10, 10), Color = Theme.Darken(upgrade.Color, 0.35), Corner = 14, Parent = row })
		Components.Label({ Text = upgrade.Icon, Size = UDim2.new(1, -14, 1, -14), Position = UDim2.fromOffset(7, 7), Parent = iconFrame })
		Components.Label({ Text = string.upper(upgrade.Name), Size = UDim2.new(1, -330, 0, 26), Position = UDim2.fromOffset(98, 8), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 22, Stroke = 1.5, Parent = row })
		Components.Label({ Text = upgrade.Description, Size = UDim2.new(1, -330, 0, 20), Position = UDim2.fromOffset(98, 34), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Body, Color = Theme.Colors.TextDim, MaxTextSize = 15, Parent = row })
		local bar = Components.ProgressBar({ Size = UDim2.new(1, -330, 0, 20), Position = UDim2.fromOffset(98, 62), Color = upgrade.Color, MaxTextSize = 14, Parent = row })
		local valueText = if maxed
			then UpgradeConfig.FormatValue(id, level) .. "  (MAX)"
			else UpgradeConfig.FormatValue(id, level) .. "  →  " .. UpgradeConfig.FormatValue(id, level + 1)
		bar.Set(level / upgrade.MaxLevel, string.format("Lv %d/%d   %s", level, upgrade.MaxLevel, valueText), false)

		local button
		if maxed then
			button = Components.Button({ Text = "Maxed", Color = Theme.Colors.Green })
			button.SetEnabled(false)
		elseif data.Level < required then
			button = Components.Button({ Text = "Level " .. required, Color = Theme.Colors.Grey })
			button.SetEnabled(false)
		else
			button = Components.Button({
				Text = "● " .. Utility.FormatNumber(cost),
				Color = Theme.Colors.Accent,
				OnClick = function()
					local result = Remotes.BuyUpgrade:InvokeServer(id)
					if result and result.Success then
						self.Ctx.Controllers.SoundManager.Play("Upgrade")
						self.Ctx.UI.Toast(string.format("%s upgraded to Lv %d!", upgrade.Name, result.Level), "Success")
					elseif result then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end,
			})
			button.SetEnabled(data.Coins >= cost)
		end
		button.Instance.Size = UDim2.fromOffset(200, 56)
		button.Instance.Position = UDim2.new(1, -214, 0.5, 0)
		button.Instance.AnchorPoint = Vector2.new(0, 0.5)
		button.Instance.Parent = row
	end
end

function UpgradeScreen:Update()
	if self.Window.IsOpen() then
		self:Refresh()
	end
end

return UpgradeScreen
