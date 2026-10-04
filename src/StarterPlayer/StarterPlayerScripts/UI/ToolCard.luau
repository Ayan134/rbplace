--[[
	ToolCard
	Card showing a tool's 3D model, rarity and stats. Shared by Inventory and Shop.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared.Rarity)
local ToolModels = require(Shared.ToolModels)

local Components = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)

local ToolCard = {}

local previewCache: { [string]: Model } = {}

local function getPreview(tool): Model
	local cached = previewCache[tool.Id]
	if not cached then
		cached = ToolModels.BuildPreview(tool)
		previewCache[tool.Id] = cached
	end
	return cached
end

function ToolCard.StatsText(tool): string
	local parts = {}
	table.insert(parts, string.format("⚡ +%d%% Peel Speed", math.floor(tool.PeelSpeed * 100 + 0.5)))
	if tool.MultiPeel > 0 then
		table.insert(parts, string.format("🖐️ +%d Multi-Peel", tool.MultiPeel))
	end
	if tool.Luck > 0 then
		table.insert(parts, string.format("🍀 +%d%% Luck", math.floor(tool.Luck * 100 + 0.5)))
	end
	table.insert(parts, "Tier " .. tool.Tier)
	return table.concat(parts, "\n")
end

-- Returns the card frame and the area where the caller places its button.
function ToolCard.Build(tool, props): (Frame, Frame)
	local rarityColor = Rarity.Color(tool.Rarity)
	local card = Components.Frame({
		Name = tool.Id,
		Size = props.Size or UDim2.fromOffset(200, 300),
		Color = Theme.Colors.PanelDark,
		Corner = 14,
		Stroke = if props.Highlight then 4 else 2.5,
		StrokeColor = if props.Highlight then Theme.Colors.Yellow else rarityColor,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
	})
	local viewport = Components.Viewport(getPreview(tool), {
		Size = UDim2.new(1, -12, 0, 110),
		Position = UDim2.fromOffset(6, 6),
		Background = Theme.Darken(rarityColor, 0.55),
		Corner = 10,
		Rotate = true,
		RotateSpeed = 0.8,
		Pitch = 20,
		Zoom = 0.9,
		Parent = card,
	})
	if props.Locked then
		viewport.ImageColor3 = Color3.fromRGB(90, 90, 100)
	end
	Components.Label({ Text = tool.Icon .. " " .. tool.Name, Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 120), MaxTextSize = 20, Stroke = 1.5, Parent = card })
	Components.Label({ Text = string.upper(tool.Rarity), Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(6, 145), Font = Theme.Fonts.Bold, Color = rarityColor, MaxTextSize = 14, Parent = card })
	Components.Label({
		Text = ToolCard.StatsText(tool),
		Size = UDim2.new(1, -16, 0, 74),
		Position = UDim2.fromOffset(8, 164),
		Font = Theme.Fonts.Bold,
		Color = Theme.Colors.TextDim,
		MaxTextSize = 14,
		YAlign = Enum.TextYAlignment.Top,
		Parent = card,
	})
	local buttonArea = Components.Create("Frame", {
		Name = "ButtonArea",
		Size = UDim2.new(1, -16, 0, 44),
		Position = UDim2.new(0, 8, 1, -52),
		BackgroundTransparency = 1,
		Parent = card,
	})
	return card, buttonArea
end

return ToolCard
