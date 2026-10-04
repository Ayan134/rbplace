--[[
	Theme
	Minimal style: flat dark panels, white text, one mint accent.
]]

local Theme = {}

local ACCENT = Color3.fromRGB(110, 222, 164)

Theme.Colors = {
	Background = Color3.fromRGB(12, 12, 16),
	Panel = Color3.fromRGB(22, 22, 28),
	PanelLight = Color3.fromRGB(40, 40, 48),
	PanelDark = Color3.fromRGB(16, 16, 20),
	Stroke = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(245, 245, 248),
	TextDim = Color3.fromRGB(150, 150, 164),
	TextDark = Color3.fromRGB(18, 18, 22),

	Accent = ACCENT,
	-- Legacy names map onto the minimal palette
	Pink = ACCENT,
	Green = ACCENT,
	Purple = Color3.fromRGB(160, 150, 255),
	Blue = Color3.fromRGB(130, 176, 255),
	Cyan = Color3.fromRGB(150, 214, 255),
	Yellow = Color3.fromRGB(255, 214, 120),
	Orange = Color3.fromRGB(255, 176, 120),
	Red = Color3.fromRGB(240, 96, 110),
	Grey = Color3.fromRGB(70, 70, 80),

	Coins = Color3.fromRGB(255, 214, 120),
	Gems = Color3.fromRGB(150, 214, 255),
	XP = Color3.fromRGB(170, 156, 255),
}

Theme.Fonts = {
	Title = Enum.Font.GothamBold,
	Bold = Enum.Font.GothamMedium,
	Body = Enum.Font.Gotham,
}

Theme.Corner = 10

function Theme.Darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function Theme.Lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

-- Readable text color on top of `color`
function Theme.TextOn(color: Color3): Color3
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return if luminance > 0.6 then Theme.Colors.TextDark else Theme.Colors.Text
end

return Theme
