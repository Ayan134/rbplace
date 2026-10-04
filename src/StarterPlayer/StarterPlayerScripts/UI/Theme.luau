--[[
	Theme
	Colors, fonts and sizes shared by every screen.
]]

local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(24, 20, 44),
	Panel = Color3.fromRGB(38, 32, 70),
	PanelLight = Color3.fromRGB(54, 46, 96),
	PanelDark = Color3.fromRGB(28, 23, 52),
	Stroke = Color3.fromRGB(110, 96, 190),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(186, 180, 220),
	TextDark = Color3.fromRGB(30, 24, 54),

	Pink = Color3.fromRGB(255, 92, 170),
	Purple = Color3.fromRGB(150, 100, 255),
	Blue = Color3.fromRGB(70, 170, 255),
	Cyan = Color3.fromRGB(80, 220, 255),
	Green = Color3.fromRGB(96, 214, 112),
	Yellow = Color3.fromRGB(255, 210, 60),
	Orange = Color3.fromRGB(255, 150, 56),
	Red = Color3.fromRGB(255, 76, 96),
	Grey = Color3.fromRGB(120, 116, 140),

	Coins = Color3.fromRGB(255, 205, 60),
	Gems = Color3.fromRGB(110, 220, 255),
	XP = Color3.fromRGB(150, 110, 255),
}

Theme.Fonts = {
	Title = Enum.Font.FredokaOne,
	Bold = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
}

Theme.Corner = 14

function Theme.Darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function Theme.Lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

return Theme
