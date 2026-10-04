--[[
	ShopScreen (ShopUI)
	Buy tools with Coins (or Gems for premium tools). Prices and requirements are
	validated by the server; the UI only reflects them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ToolConfig = require(Shared.ToolConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)
local ToolCard = require(UI.ToolCard)

local ShopScreen = {}
ShopScreen.__index = ShopScreen

function ShopScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, ShopScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Window = Components.Window(gui, {
		Name = "ShopWindow",
		Title = "🛒 SHOP",
		Color = Theme.Colors.Yellow,
		Size = UDim2.fromOffset(1000, 620),
		OnOpen = function()
			self.Signature = nil
			self:Refresh()
		end,
	})
	local content = self.Window.Content
	Components.Label({ Text = "TOOLS — peel faster, peel more at once, find more rares", Size = UDim2.new(1, 0, 0, 24), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 18, Parent = content })
	local scroll = Components.Scroll({ Name = "Tools", Size = UDim2.new(1, 0, 1, -110), Position = UDim2.fromOffset(0, 30), Direction = Enum.ScrollingDirection.X, Automatic = Enum.AutomaticSize.X, Parent = content })
	Components.List(scroll, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	Components.Padding(scroll, 6)
	self.Scroll = scroll

	local gems = Components.Frame({ Name = "Gems", Size = UDim2.new(1, 0, 0, 70), Position = UDim2.new(0, 0, 1, -70), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 14, Stroke = 2, StrokeColor = Theme.Colors.Gems, Parent = content })
	Components.Label({
		Text = "💎 GEM SHOP — trails, sticker effects, cosmetics & premium upgrades coming soon! Earn Gems from quests, level-ups, first clears and Diamond stickers.",
		Size = UDim2.new(1, -24, 1, -12),
		Position = UDim2.fromOffset(12, 6),
		Font = Theme.Fonts.Bold,
		Color = Theme.Colors.Gems,
		MaxTextSize = 17,
		XAlign = Enum.TextXAlignment.Left,
		Parent = gems,
	})
	return self
end

function ShopScreen:Refresh()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	local signature = string.format("%d|%d|%d", data.Coins, data.Gems, data.Level)
	for _, id in ipairs(ToolConfig.Order) do
		signature ..= tostring(data.UnlockedTools[id])
	end
	if signature == self.Signature then
		return
	end
	self.Signature = signature

	Components.ClearChildren(self.Scroll, { "UIListLayout", "UIPadding" })
	for index, id in ipairs(ToolConfig.Order) do
		local tool = ToolConfig.Get(id)
		if tool.Price <= 0 then
			continue
		end
		local owned = data.UnlockedTools[id] == true
		local levelMet = data.Level >= tool.RequiredLevel
		local balance = if tool.Currency == "Gems" then data.Gems else data.Coins
		local _, buttonArea = ToolCard.Build(tool, { LayoutOrder = index, Locked = not levelMet, Size = UDim2.fromOffset(200, 330), Parent = self.Scroll })
		local icon = if tool.Currency == "Gems" then "💎" else "🪙"
		local button
		if owned then
			button = Components.Button({ Text = "OWNED ✔", Color = Theme.Colors.Green })
			button.SetEnabled(false)
		elseif not levelMet then
			button = Components.Button({ Text = "🔒 LEVEL " .. tool.RequiredLevel, Color = Theme.Colors.Grey })
			button.SetEnabled(false)
		else
			button = Components.Button({
				Text = icon .. " " .. Utility.FormatNumber(tool.Price),
				Color = if tool.Currency == "Gems" then Theme.Colors.Cyan else Theme.Colors.Yellow,
				OnClick = function()
					local result = Remotes.BuyTool:InvokeServer(id)
					if result and result.Success then
						self.Ctx.Controllers.SoundManager.Play("Purchase")
						self.Ctx.Controllers.EffectsController.Confetti(30)
						self.Ctx.UI.Toast("You bought the " .. tool.Name .. "! Equipped.", "Success")
					elseif result then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end,
			})
			button.SetEnabled(balance >= tool.Price)
		end
		button.Instance.Size = UDim2.fromScale(1, 1)
		button.Instance.Parent = buttonArea
	end
end

function ShopScreen:Update()
	if self.Window.IsOpen() then
		self:Refresh()
	end
end

return ShopScreen
