--[[
	InventoryScreen (InventoryUI)
	Owned tools with Equip buttons and a summary of the player's current stats.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerStats = require(Shared.PlayerStats)
local ToolConfig = require(Shared.ToolConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)
local ToolCard = require(UI.ToolCard)

local InventoryScreen = {}
InventoryScreen.__index = InventoryScreen

function InventoryScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, InventoryScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Window = Components.Window(gui, {
		Name = "InventoryWindow",
		Title = "🎒 INVENTORY",
		Color = Theme.Colors.Green,
		Size = UDim2.fromOffset(1000, 600),
		OnOpen = function()
			self.Signature = nil
			self:Refresh()
		end,
	})
	local content = self.Window.Content
	local scroll = Components.Scroll({ Name = "Tools", Size = UDim2.new(1, -270, 1, 0), Parent = content })
	Components.Create("UIGridLayout", {
		CellSize = UDim2.fromOffset(200, 300),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})
	Components.Padding(scroll, 6)
	self.Scroll = scroll

	local stats = Components.Frame({ Name = "Stats", Size = UDim2.new(0, 254, 1, 0), Position = UDim2.new(1, -254, 0, 0), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 14, Parent = content })
	Components.Padding(stats, 12)
	Components.Label({ Text = "📊 YOUR STATS", Size = UDim2.new(1, 0, 0, 30), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 24, Stroke = 1.5, Parent = stats })
	self.StatsText = Components.Label({
		Text = "",
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.fromOffset(0, 40),
		XAlign = Enum.TextXAlignment.Left,
		YAlign = Enum.TextYAlignment.Top,
		Font = Theme.Fonts.Bold,
		MaxTextSize = 18,
		RichText = true,
		Parent = stats,
	})
	return self
end

function InventoryScreen:Refresh()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	local signature = data.EquippedTool
	for _, id in ipairs(ToolConfig.Order) do
		signature ..= tostring(data.UnlockedTools[id])
	end
	for key, value in pairs(data.Upgrades) do
		signature ..= key .. value
	end
	if signature == self.Signature then
		return
	end
	self.Signature = signature

	Components.ClearChildren(self.Scroll, { "UIGridLayout", "UIPadding" })
	for index, id in ipairs(ToolConfig.Order) do
		local tool = ToolConfig.Get(id)
		local owned = data.UnlockedTools[id] == true
		local equipped = data.EquippedTool == id
		local _, buttonArea = ToolCard.Build(tool, { LayoutOrder = index, Highlight = equipped, Locked = not owned, Parent = self.Scroll })
		local button
		if equipped then
			button = Components.Button({ Text = "EQUIPPED", Color = Theme.Colors.Yellow })
			button.SetEnabled(false)
		elseif owned then
			button = Components.Button({
				Text = "EQUIP",
				Color = Theme.Colors.Green,
				OnClick = function()
					local result = Remotes.EquipTool:InvokeServer(id)
					if result and result.Success then
						self.Ctx.Controllers.SoundManager.Play("Equip")
					elseif result then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end,
			})
		else
			button = Components.Button({
				Text = "VIEW IN SHOP",
				Color = Theme.Colors.Blue,
				MaxTextSize = 18,
				OnClick = function()
					self.Ctx.UI.OpenWindow("Shop")
				end,
			})
		end
		button.Instance.Size = UDim2.fromScale(1, 1)
		button.Instance.Parent = buttonArea
	end

	local stats = PlayerStats.Compute(data)
	local tool = ToolConfig.Get(stats.ToolId)
	local lines = {
		string.format("<font color=\"#%s\">Tool</font>\n%s %s", Theme.Colors.TextDim:ToHex(), tool.Icon, tool.Name),
		string.format("<font color=\"#%s\">Peel Rate</font>\n%.2f HP/s", Theme.Colors.TextDim:ToHex(), stats.PeelRate),
		string.format("<font color=\"#%s\">Peel Time</font>\n-%d%%", Theme.Colors.TextDim:ToHex(), math.floor((1 - stats.DurationFactor) * 100 + 0.5)),
		string.format("<font color=\"#%s\">Small sticker</font>\n%.2fs", Theme.Colors.TextDim:ToHex(), PlayerStats.GetPeelDuration(stats, 1)),
		string.format("<font color=\"#%s\">Multi-Peel</font>\n%d at once", Theme.Colors.TextDim:ToHex(), stats.Capacity),
		string.format("<font color=\"#%s\">Luck</font>\n+%d%%", Theme.Colors.TextDim:ToHex(), math.floor(stats.Luck * 100 + 0.5)),
		string.format("<font color=\"#%s\">Coin Bonus</font>\nx%.2f", Theme.Colors.TextDim:ToHex(), stats.RewardMultiplier),
	}
	self.StatsText.Text = table.concat(lines, "\n\n")
end

function InventoryScreen:Update()
	if self.Window.IsOpen() then
		self:Refresh()
	end
end

return InventoryScreen
