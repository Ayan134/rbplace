--[[
	ShopScreen (ShopUI)
	Bags (how many stickers you carry) and tools (how fast you peel). Prices and
	requirements are validated by the server; the UI only reflects them. The same items
	are on display in the lobby shop, where they can be bought by walking up to them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BagConfig = require(Shared.BagConfig)
local BagModels = require(Shared.BagModels)
local ToolConfig = require(Shared.ToolConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)
local ToolCard = require(UI.ToolCard)

local ShopScreen = {}
ShopScreen.__index = ShopScreen

local bagPreviews: { [string]: Model } = {}

local function priceText(price: number, currency: string): string
	return if currency == "Gems" then "💎 " .. Utility.FormatNumber(price) else Utility.FormatMoney(price)
end

function ShopScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, ShopScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Tab = "Bags"
	self.Window = Components.Window(gui, {
		Name = "ShopWindow",
		Icon = "🛒",
		Title = "Shop",
		Color = Theme.Colors.Yellow,
		Size = UDim2.fromOffset(1000, 620),
		OnOpen = function()
			self.Signature = nil
			self:Refresh()
		end,
	})
	local content = self.Window.Content

	-- Tabs
	local tabs = Components.Create("Frame", { Name = "Tabs", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = content })
	Components.List(tabs, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	self.TabButtons = {}
	for index, def in ipairs({ { "Bags", "🎒", Theme.Colors.Green }, { "Tools", "🔧", Theme.Colors.Blue } }) do
		self.TabButtons[def[1]] = Components.Button({
			Text = def[1],
			Icon = def[2],
			Size = UDim2.fromOffset(170, 50),
			Color = def[3],
			LayoutOrder = index,
			OnClick = function()
				self.Tab = def[1]
				self.Signature = nil
				self:Refresh()
			end,
			Parent = tabs,
		})
	end
	self.Subtitle = Components.Label({ Text = "", Size = UDim2.new(1, -380, 0, 40), Position = UDim2.new(1, 0, 0, 6), AnchorPoint = Vector2.new(1, 0), XAlign = Enum.TextXAlignment.Right, Color = Theme.Colors.TextDim, MaxTextSize = 18, Stroke = 1.5, Parent = content })

	local scroll = Components.Scroll({ Name = "Items", Size = UDim2.new(1, 0, 1, -66), Position = UDim2.fromOffset(0, 64), Direction = Enum.ScrollingDirection.X, Automatic = Enum.AutomaticSize.X, Parent = content })
	Components.List(scroll, Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	Components.Padding(scroll, 8)
	self.Scroll = scroll
	return self
end

function ShopScreen:BuildBagCard(bag, data, index: number)
	local owned = data.UnlockedBags and data.UnlockedBags[bag.Id] == true
	local equipped = data.EquippedBag == bag.Id
	local card = Components.Frame({
		Name = bag.Id,
		Size = UDim2.fromOffset(200, 360),
		Color = Theme.Colors.PanelLight,
		Corner = 16,
		Stroke = if equipped then 4 else 3,
		StrokeColor = if equipped then Theme.Colors.Yellow else nil,
		LayoutOrder = index,
		Parent = self.Scroll,
	})
	if not bagPreviews[bag.Id] then
		bagPreviews[bag.Id] = BagModels.Build(bag)
	end
	Components.Viewport(bagPreviews[bag.Id], {
		Size = UDim2.new(1, -16, 0, 140),
		Position = UDim2.fromOffset(8, 8),
		Background = Theme.Darken(bag.Color, 0.5),
		Corner = 12,
		Rotate = true,
		RotateSpeed = 0.7,
		Pitch = 18,
		Zoom = 0.85,
		Parent = card,
	})
	Components.Label({ Text = bag.Name, Size = UDim2.new(1, -12, 0, 30), Position = UDim2.fromOffset(6, 154), MaxTextSize = 26, Stroke = 2, Parent = card })
	Components.Label({ Text = "🧺 " .. Utility.FormatNumber(bag.Capacity) .. " stickers", Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 188), Color = Theme.Colors.Money, MaxTextSize = 22, Stroke = 2, Parent = card })
	Components.Label({ Text = bag.Description, Size = UDim2.new(1, -20, 0, 70), Position = UDim2.fromOffset(10, 220), Font = Theme.Fonts.Body, Color = Theme.Colors.TextDim, MaxTextSize = 15, YAlign = Enum.TextYAlignment.Top, Parent = card })

	local button
	if equipped then
		button = Components.Button({ Text = "Equipped", Color = Theme.Colors.Grey })
		button.SetEnabled(false)
	elseif owned then
		button = Components.Button({
			Text = "Equip",
			Color = Theme.Colors.Blue,
			OnClick = function()
				local result = Remotes.EquipBag:InvokeServer(bag.Id)
				if result and result.Success then
					self.Ctx.Controllers.SoundManager.Play("Equip")
				elseif result then
					self.Ctx.UI.Toast(result.Message, "Error")
				end
			end,
		})
	else
		local balance = if bag.Currency == "Gems" then data.Gems else data.Coins
		button = Components.Button({
			Text = priceText(bag.Price, bag.Currency),
			Color = Theme.Colors.Accent,
			OnClick = function()
				local result = Remotes.BuyBag:InvokeServer(bag.Id)
				if result and result.Success then
					self.Ctx.Controllers.SoundManager.Play("Purchase")
					self.Ctx.Controllers.EffectsController.Confetti(30)
					self.Ctx.UI.Toast("You bought the " .. bag.Name .. "! Equipped.", "Success")
				elseif result then
					self.Ctx.UI.Toast(result.Message, "Error")
				end
			end,
		})
		button.SetEnabled(balance >= bag.Price)
	end
	button.Instance.Size = UDim2.new(1, -16, 0, 52)
	button.Instance.Position = UDim2.new(0, 8, 1, -60)
	button.Instance.Parent = card
end

function ShopScreen:BuildToolCard(tool, data, index: number)
	local owned = data.UnlockedTools[tool.Id] == true
	local levelMet = data.Level >= tool.RequiredLevel
	local balance = if tool.Currency == "Gems" then data.Gems else data.Coins
	local _, buttonArea = ToolCard.Build(tool, { LayoutOrder = index, Locked = not levelMet, Size = UDim2.fromOffset(200, 360), Highlight = data.EquippedTool == tool.Id, Parent = self.Scroll })
	local button
	if data.EquippedTool == tool.Id then
		button = Components.Button({ Text = "Equipped", Color = Theme.Colors.Grey })
		button.SetEnabled(false)
	elseif owned then
		button = Components.Button({
			Text = "Equip",
			Color = Theme.Colors.Blue,
			OnClick = function()
				local result = Remotes.EquipTool:InvokeServer(tool.Id)
				if result and result.Success then
					self.Ctx.Controllers.SoundManager.Play("Equip")
				elseif result then
					self.Ctx.UI.Toast(result.Message, "Error")
				end
			end,
		})
	elseif not levelMet then
		button = Components.Button({ Text = "Level " .. tool.RequiredLevel, Color = Theme.Colors.Grey })
		button.SetEnabled(false)
	else
		button = Components.Button({
			Text = priceText(tool.Price, tool.Currency),
			Color = Theme.Colors.Accent,
			OnClick = function()
				local result = Remotes.BuyTool:InvokeServer(tool.Id)
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

function ShopScreen:Refresh()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	local signature = string.format("%s|%d|%d|%d|%s|%s", self.Tab, data.Coins, data.Gems, data.Level, tostring(data.EquippedBag), tostring(data.EquippedTool))
	for _, id in ipairs(ToolConfig.Order) do
		signature ..= tostring(data.UnlockedTools[id])
	end
	for _, id in ipairs(BagConfig.Order) do
		signature ..= tostring(data.UnlockedBags and data.UnlockedBags[id])
	end
	if signature == self.Signature then
		return
	end
	self.Signature = signature

	for name, button in pairs(self.TabButtons) do
		button.Instance.Size = if name == self.Tab then UDim2.fromOffset(190, 54) else UDim2.fromOffset(160, 46)
	end
	Components.ClearChildren(self.Scroll, { "UIListLayout", "UIPadding" })
	self.Scroll.CanvasPosition = Vector2.zero
	if self.Tab == "Bags" then
		self.Subtitle.Text = "Bigger bag = fewer trips to the trash can"
		for index, id in ipairs(BagConfig.Order) do
			self:BuildBagCard(BagConfig.Get(id), data, index)
		end
	else
		self.Subtitle.Text = "Peel faster, peel more at once, find more rares"
		for index, id in ipairs(ToolConfig.Order) do
			self:BuildToolCard(ToolConfig.Get(id), data, index)
		end
	end
end

function ShopScreen:Update()
	if self.Window.IsOpen() then
		self:Refresh()
	end
end

return ShopScreen
