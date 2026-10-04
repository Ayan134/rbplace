--[[
	Theme
	Cartoon simulator style: chunky rounded panels with thick dark outlines, bright
	gradient buttons with a pressed "3D" lip, and FredokaOne text with a dark outline so
	it reads on top of any background.
]]

local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(20, 22, 42),
	Panel = Color3.fromRGB(44, 52, 96), -- window body
	PanelLight = Color3.fromRGB(66, 78, 136), -- cards / inner boxes
	PanelDark = Color3.fromRGB(30, 34, 66), -- wells, bar backgrounds
	Outline = Color3.fromRGB(16, 18, 38), -- thick outline around everything
	Stroke = Color3.fromRGB(16, 18, 38),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(196, 204, 240),
	TextDark = Color3.fromRGB(16, 18, 38),

	Accent = Color3.fromRGB(78, 214, 96), -- green "go" buttons
	Green = Color3.fromRGB(78, 214, 96),
	Pink = Color3.fromRGB(255, 92, 168),
	Purple = Color3.fromRGB(160, 102, 255),
	Blue = Color3.fromRGB(56, 156, 255),
	Cyan = Color3.fromRGB(70, 214, 255),
	Yellow = Color3.fromRGB(255, 204, 46),
	Orange = Color3.fromRGB(255, 140, 46),
	Red = Color3.fromRGB(240, 66, 80),
	Grey = Color3.fromRGB(120, 128, 156),

	Money = Color3.fromRGB(112, 255, 120),
	Coins = Color3.fromRGB(112, 255, 120),
	Gems = Color3.fromRGB(90, 220, 255),
	XP = Color3.fromRGB(190, 140, 255),
}

Theme.Fonts = {
	Title = Enum.Font.FredokaOne,
	Bold = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamBold,
}

Theme.Corner = 14
Theme.OutlineThickness = 3

function Theme.Darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function Theme.Lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

-- Outline color for a colored surface: a deep shade of the same hue
function Theme.OutlineFor(color: Color3): Color3
	return color:Lerp(Theme.Colors.Outline, 0.72)
end

-- Readable text color on top of `color`
function Theme.TextOn(_color: Color3): Color3
	-- Outlined white text reads on every button color in this style
	return Theme.Colors.Text
end

return Theme
