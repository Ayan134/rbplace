--[[
	LightingConfig
	Mood presets per place. The client LightingController tweens Lighting and its
	post effects to the preset of the level when a match loads and back to `Lobby`
	when the match ends. Any field left out keeps the Lobby value.

	The look comes from contrast: a strong low sun with crisp shadows, little flat fill
	light (Ambient / OutdoorAmbient), reflections of the sky on every surface
	(EnvironmentDiffuse/SpecularScale), haze that pushes the horizon back and a light
	color grade.

	  ClockTime, GeographicLatitude, Brightness, ExposureCompensation, ShadowSoftness
	  EnvironmentDiffuseScale, EnvironmentSpecularScale
	  Ambient, OutdoorAmbient                 Color3
	  Atmosphere   { Density, Offset, Haze, Glare, Color, Decay }
	  Bloom        { Intensity, Size, Threshold }
	  Color        { Brightness, Contrast, Saturation, TintColor }   (ColorCorrection)
	  SunRays      { Intensity, Spread }
	  Depth        { FarIntensity, FocusDistance, InFocusRadius, NearIntensity }  (DepthOfField)
	  Clouds       { Cover, Density, Color }
]]

local LightingConfig = {}

local rgb = Color3.fromRGB

LightingConfig.Presets = {
	-- Sunny early afternoon with long-ish shadows
	Lobby = {
		ClockTime = 14.3,
		GeographicLatitude = 38,
		Brightness = 2.9,
		ExposureCompensation = 0.1,
		ShadowSoftness = 0.12,
		EnvironmentDiffuseScale = 0.65,
		EnvironmentSpecularScale = 1,
		Ambient = rgb(58, 60, 74),
		OutdoorAmbient = rgb(112, 118, 136),
		Atmosphere = { Density = 0.33, Offset = 0.18, Haze = 1.7, Glare = 0.4, Color = rgb(199, 218, 244), Decay = rgb(104, 128, 176) },
		Bloom = { Intensity = 0.55, Size = 26, Threshold = 1.25 },
		Color = { Brightness = 0, Contrast = 0.15, Saturation = 0.2, TintColor = rgb(255, 250, 242) },
		SunRays = { Intensity = 0.1, Spread = 0.65 },
		Depth = { FarIntensity = 0.12, FocusDistance = 40, InFocusRadius = 80, NearIntensity = 0 },
		Clouds = { Cover = 0.55, Density = 0.55, Color = rgb(255, 255, 255) },
	},

	-- Bright sunny backyard
	Pile = {
		ClockTime = 13.4,
		Brightness = 3,
		Ambient = rgb(60, 62, 76),
		OutdoorAmbient = rgb(116, 122, 140),
		Atmosphere = { Density = 0.28, Offset = 0.12, Haze = 1.3, Glare = 0.3, Color = rgb(200, 222, 255), Decay = rgb(110, 140, 196) },
		Color = { Brightness = 0, Contrast = 0.15, Saturation = 0.24, TintColor = rgb(255, 251, 244) },
	},

	-- Warm golden hour over the town square
	Fountain = {
		ClockTime = 16.7,
		Brightness = 2.7,
		Ambient = rgb(66, 56, 60),
		OutdoorAmbient = rgb(124, 104, 100),
		Atmosphere = { Density = 0.34, Offset = 0.25, Haze = 1.9, Glare = 0.6, Color = rgb(255, 216, 180), Decay = rgb(200, 132, 104) },
		Bloom = { Intensity = 0.65, Size = 28, Threshold = 1.15 },
		Color = { Brightness = 0.01, Contrast = 0.17, Saturation = 0.2, TintColor = rgb(255, 238, 220) },
		SunRays = { Intensity = 0.16, Spread = 0.8 },
		Clouds = { Cover = 0.5, Density = 0.5, Color = rgb(255, 232, 212) },
	},

	-- Dusk car show: neon, spotlights and a purple sky
	Car = {
		ClockTime = 18.5,
		Brightness = 1.8,
		ExposureCompensation = 0.3,
		Ambient = rgb(58, 50, 82),
		OutdoorAmbient = rgb(96, 82, 128),
		Atmosphere = { Density = 0.38, Offset = 0.3, Haze = 2.3, Glare = 1, Color = rgb(222, 164, 196), Decay = rgb(110, 80, 168) },
		Bloom = { Intensity = 0.95, Size = 32, Threshold = 0.95 },
		Color = { Brightness = 0.02, Contrast = 0.18, Saturation = 0.26, TintColor = rgb(248, 236, 255) },
		SunRays = { Intensity = 0.18, Spread = 1 },
		Clouds = { Cover = 0.6, Density = 0.6, Color = rgb(255, 190, 210) },
	},

	-- Fresh park morning
	Statue = {
		ClockTime = 9.2,
		Brightness = 3,
		Ambient = rgb(60, 66, 74),
		OutdoorAmbient = rgb(112, 126, 136),
		Atmosphere = { Density = 0.36, Offset = 0.1, Haze = 1.8, Glare = 0.35, Color = rgb(212, 232, 242), Decay = rgb(140, 180, 194) },
		Color = { Brightness = 0.01, Contrast = 0.14, Saturation = 0.18, TintColor = rgb(246, 255, 250) },
		SunRays = { Intensity = 0.16, Spread = 0.7 },
		Clouds = { Cover = 0.45, Density = 0.45, Color = rgb(255, 255, 255) },
	},

	-- Sunny suburban noon
	House = {
		ClockTime = 12.6,
		Brightness = 3.1,
		Ambient = rgb(60, 62, 72),
		OutdoorAmbient = rgb(118, 122, 138),
		Atmosphere = { Density = 0.27, Offset = 0.14, Haze = 1.2, Glare = 0.25, Color = rgb(204, 226, 252), Decay = rgb(130, 164, 214) },
		Color = { Brightness = 0, Contrast = 0.15, Saturation = 0.2, TintColor = rgb(255, 252, 246) },
		SunRays = { Intensity = 0.08, Spread = 0.6 },
	},

	-- Late golden afternoon on the estate
	Mansion = {
		ClockTime = 17.1,
		Brightness = 2.6,
		Ambient = rgb(66, 58, 58),
		OutdoorAmbient = rgb(122, 108, 102),
		Atmosphere = { Density = 0.34, Offset = 0.25, Haze = 2, Glare = 0.65, Color = rgb(255, 210, 172), Decay = rgb(196, 134, 104) },
		Bloom = { Intensity = 0.65, Size = 28, Threshold = 1.15 },
		Color = { Brightness = 0.01, Contrast = 0.17, Saturation = 0.18, TintColor = rgb(255, 236, 218) },
		SunRays = { Intensity = 0.16, Spread = 0.85 },
		Clouds = { Cover = 0.5, Density = 0.5, Color = rgb(255, 226, 204) },
	},

	-- Crisp, clear airport day with a deep blue sky
	Airplane = {
		ClockTime = 11.2,
		Brightness = 3.2,
		Ambient = rgb(58, 62, 74),
		OutdoorAmbient = rgb(110, 120, 140),
		Atmosphere = { Density = 0.24, Offset = 0.05, Haze = 0.9, Glare = 0.2, Color = rgb(194, 222, 255), Decay = rgb(110, 152, 220) },
		Color = { Brightness = 0, Contrast = 0.16, Saturation = 0.16, TintColor = rgb(248, 252, 255) },
		SunRays = { Intensity = 0.08, Spread = 0.55 },
		Clouds = { Cover = 0.35, Density = 0.35, Color = rgb(255, 255, 255) },
	},

	-- Royal sunset with pink clouds
	Palace = {
		ClockTime = 17.8,
		Brightness = 2.3,
		ExposureCompensation = 0.15,
		Ambient = rgb(70, 54, 66),
		OutdoorAmbient = rgb(128, 100, 118),
		Atmosphere = { Density = 0.38, Offset = 0.3, Haze = 2.3, Glare = 0.9, Color = rgb(255, 196, 186), Decay = rgb(194, 112, 146) },
		Bloom = { Intensity = 0.8, Size = 30, Threshold = 1.05 },
		Color = { Brightness = 0.01, Contrast = 0.18, Saturation = 0.24, TintColor = rgb(255, 234, 232) },
		SunRays = { Intensity = 0.2, Spread = 1 },
		Clouds = { Cover = 0.55, Density = 0.55, Color = rgb(255, 206, 220) },
	},
}

-- Hour range in which lamps, string lights and neon signs switch on
LightingConfig.NightFrom = 17.3
LightingConfig.NightTo = 6.5

function LightingConfig.Get(placeId: string?)
	return LightingConfig.Presets[placeId or "Lobby"] or LightingConfig.Presets.Lobby
end

function LightingConfig.IsNight(clockTime: number): boolean
	return clockTime >= LightingConfig.NightFrom or clockTime <= LightingConfig.NightTo
end

return LightingConfig
