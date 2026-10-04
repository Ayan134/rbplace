--[[
	LightingConfig
	Mood presets per place. The client LightingController tweens Lighting and its
	post effects to the preset of the level when a match loads and back to `Lobby`
	when the match ends. Any field left out keeps the Lobby value.

	  ClockTime, GeographicLatitude, Brightness, ExposureCompensation
	  Ambient, OutdoorAmbient                 Color3
	  Atmosphere   { Density, Offset, Haze, Glare, Color, Decay }
	  Bloom        { Intensity, Size, Threshold }
	  Color        { Brightness, Contrast, Saturation, TintColor }   (ColorCorrection)
	  SunRays      { Intensity, Spread }
	  Clouds       { Cover, Density, Color }
]]

local LightingConfig = {}

local rgb = Color3.fromRGB

LightingConfig.Presets = {
	-- Bright, friendly afternoon
	Lobby = {
		ClockTime = 14.6,
		GeographicLatitude = 30,
		Brightness = 3,
		ExposureCompensation = 0,
		Ambient = rgb(92, 92, 108),
		OutdoorAmbient = rgb(140, 140, 156),
		Atmosphere = { Density = 0.3, Offset = 0.2, Haze = 1.4, Glare = 0.25, Color = rgb(199, 220, 245), Decay = rgb(140, 158, 204) },
		Bloom = { Intensity = 0.35, Size = 24, Threshold = 1.6 },
		Color = { Brightness = 0.01, Contrast = 0.06, Saturation = 0.12, TintColor = rgb(255, 252, 247) },
		SunRays = { Intensity = 0.06, Spread = 0.8 },
		Clouds = { Cover = 0.55, Density = 0.55, Color = rgb(255, 255, 255) },
	},

	-- Bright sunny backyard
	Pile = {
		ClockTime = 13.6,
		Brightness = 3.2,
		Ambient = rgb(98, 98, 112),
		OutdoorAmbient = rgb(146, 146, 160),
		Atmosphere = { Density = 0.24, Offset = 0.1, Haze = 0.9, Glare = 0.2, Color = rgb(200, 224, 255), Decay = rgb(130, 166, 220) },
		Bloom = { Intensity = 0.3, Size = 22, Threshold = 1.7 },
		Color = { Brightness = 0.02, Contrast = 0.08, Saturation = 0.2, TintColor = rgb(255, 253, 248) },
		SunRays = { Intensity = 0.05, Spread = 0.7 },
		Clouds = { Cover = 0.45, Density = 0.4, Color = rgb(255, 255, 255) },
	},

	-- Warm golden hour over the town square
	Fountain = {
		ClockTime = 16.6,
		Brightness = 2.8,
		Ambient = rgb(104, 92, 96),
		OutdoorAmbient = rgb(156, 138, 134),
		Atmosphere = { Density = 0.32, Offset = 0.25, Haze = 1.8, Glare = 0.5, Color = rgb(255, 222, 190), Decay = rgb(214, 150, 120) },
		Bloom = { Intensity = 0.45, Size = 26, Threshold = 1.4 },
		Color = { Brightness = 0.02, Contrast = 0.08, Saturation = 0.16, TintColor = rgb(255, 244, 230) },
		SunRays = { Intensity = 0.1, Spread = 0.9 },
		Clouds = { Cover = 0.5, Density = 0.5, Color = rgb(255, 236, 220) },
	},

	-- Dusk car show: neon, spotlights and a purple sky
	Car = {
		ClockTime = 18.6,
		Brightness = 2,
		ExposureCompensation = 0.25,
		Ambient = rgb(84, 76, 112),
		OutdoorAmbient = rgb(118, 104, 150),
		Atmosphere = { Density = 0.36, Offset = 0.3, Haze = 2.2, Glare = 0.9, Color = rgb(222, 170, 200), Decay = rgb(120, 90, 170) },
		Bloom = { Intensity = 0.8, Size = 30, Threshold = 1.1 },
		Color = { Brightness = 0.03, Contrast = 0.12, Saturation = 0.22, TintColor = rgb(250, 240, 255) },
		SunRays = { Intensity = 0.14, Spread = 1 },
		Clouds = { Cover = 0.6, Density = 0.6, Color = rgb(255, 196, 214) },
	},

	-- Fresh park morning
	Statue = {
		ClockTime = 9.4,
		Brightness = 3.1,
		Ambient = rgb(96, 104, 112),
		OutdoorAmbient = rgb(140, 152, 160),
		Atmosphere = { Density = 0.34, Offset = 0.1, Haze = 1.6, Glare = 0.3, Color = rgb(214, 232, 240), Decay = rgb(150, 186, 196) },
		Bloom = { Intensity = 0.35, Size = 24, Threshold = 1.5 },
		Color = { Brightness = 0.02, Contrast = 0.05, Saturation = 0.14, TintColor = rgb(248, 255, 250) },
		SunRays = { Intensity = 0.12, Spread = 0.7 },
		Clouds = { Cover = 0.45, Density = 0.45, Color = rgb(255, 255, 255) },
	},

	-- Sunny suburban noon
	House = {
		ClockTime = 12.8,
		Brightness = 3.2,
		Ambient = rgb(96, 96, 108),
		OutdoorAmbient = rgb(146, 146, 158),
		Atmosphere = { Density = 0.26, Offset = 0.15, Haze = 1.1, Glare = 0.2, Color = rgb(204, 226, 250), Decay = rgb(140, 170, 214) },
		Bloom = { Intensity = 0.3, Size = 22, Threshold = 1.7 },
		Color = { Brightness = 0.01, Contrast = 0.07, Saturation = 0.15, TintColor = rgb(255, 253, 248) },
		SunRays = { Intensity = 0.05, Spread = 0.7 },
		Clouds = { Cover = 0.5, Density = 0.4, Color = rgb(255, 255, 255) },
	},

	-- Late golden afternoon on the estate
	Mansion = {
		ClockTime = 17.2,
		Brightness = 2.7,
		Ambient = rgb(104, 94, 92),
		OutdoorAmbient = rgb(150, 136, 128),
		Atmosphere = { Density = 0.33, Offset = 0.25, Haze = 1.9, Glare = 0.6, Color = rgb(255, 214, 176), Decay = rgb(200, 140, 110) },
		Bloom = { Intensity = 0.5, Size = 26, Threshold = 1.35 },
		Color = { Brightness = 0.02, Contrast = 0.09, Saturation = 0.15, TintColor = rgb(255, 240, 224) },
		SunRays = { Intensity = 0.12, Spread = 0.9 },
		Clouds = { Cover = 0.5, Density = 0.5, Color = rgb(255, 228, 206) },
	},

	-- Crisp, clear airport day with a deep blue sky
	Airplane = {
		ClockTime = 11.4,
		Brightness = 3.3,
		Ambient = rgb(92, 98, 112),
		OutdoorAmbient = rgb(140, 150, 168),
		Atmosphere = { Density = 0.22, Offset = 0.05, Haze = 0.8, Glare = 0.15, Color = rgb(196, 222, 255), Decay = rgb(120, 160, 220) },
		Bloom = { Intensity = 0.3, Size = 22, Threshold = 1.7 },
		Color = { Brightness = 0.01, Contrast = 0.08, Saturation = 0.12, TintColor = rgb(250, 252, 255) },
		SunRays = { Intensity = 0.06, Spread = 0.6 },
		Clouds = { Cover = 0.35, Density = 0.35, Color = rgb(255, 255, 255) },
	},

	-- Royal sunset with pink clouds
	Palace = {
		ClockTime = 17.8,
		Brightness = 2.4,
		ExposureCompensation = 0.1,
		Ambient = rgb(108, 90, 104),
		OutdoorAmbient = rgb(156, 128, 146),
		Atmosphere = { Density = 0.36, Offset = 0.3, Haze = 2.2, Glare = 0.8, Color = rgb(255, 200, 190), Decay = rgb(196, 120, 150) },
		Bloom = { Intensity = 0.6, Size = 28, Threshold = 1.25 },
		Color = { Brightness = 0.02, Contrast = 0.1, Saturation = 0.2, TintColor = rgb(255, 238, 236) },
		SunRays = { Intensity = 0.15, Spread = 1 },
		Clouds = { Cover = 0.55, Density = 0.55, Color = rgb(255, 210, 222) },
	},
}

function LightingConfig.Get(placeId: string?)
	return LightingConfig.Presets[placeId or "Lobby"] or LightingConfig.Presets.Lobby
end

return LightingConfig
