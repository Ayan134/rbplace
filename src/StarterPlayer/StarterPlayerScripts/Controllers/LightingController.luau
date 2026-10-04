--[[
	LightingController
	Gives every place its own mood: when a match loads, Lighting, the sky and the post
	effects tween to the level's preset from Shared.LightingConfig; when the match ends
	they tween back to the lobby. Also blurs the world softly behind open windows.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LightingConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LightingConfig"))

local LightingController = {}

local Controllers
local blur: BlurEffect
local current: string? = nil
local activeTweens: { Tween } = {}

local function findEffect(className: string): Instance?
	return Lighting:FindFirstChildOfClass(className)
end

local function tween(instance: Instance?, goals: { [string]: any }?, info: TweenInfo)
	if not instance or not goals then
		return
	end
	local filtered = {}
	for key, value in pairs(goals) do
		if type(value) ~= "table" then
			filtered[key] = value
		end
	end
	local ok, created = pcall(TweenService.Create, TweenService, instance, info, filtered)
	if ok then
		created:Play()
		table.insert(activeTweens, created)
	end
end

local function merged(placeId: string?)
	local base = LightingConfig.Presets.Lobby
	local preset = LightingConfig.Get(placeId)
	local result = {}
	for key, value in pairs(base) do
		if type(value) == "table" then
			local section = {}
			for k, v in pairs(value) do
				section[k] = v
			end
			for k, v in pairs(preset[key] or {}) do
				section[k] = v
			end
			result[key] = section
		else
			result[key] = if preset[key] ~= nil then preset[key] else value
		end
	end
	return result
end

-- Tweens the whole scene to a place's mood ("Lobby" or a LevelId)
function LightingController.Apply(placeId: string?, duration: number?)
	if current == placeId then
		return
	end
	current = placeId
	for _, active in ipairs(activeTweens) do
		active:Cancel()
	end
	table.clear(activeTweens)

	local preset = merged(placeId)
	local info = TweenInfo.new(duration or 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	-- Every preset sits between morning and dusk, so ClockTime never wraps past midnight
	local lighting = {
		Brightness = preset.Brightness,
		ExposureCompensation = preset.ExposureCompensation,
		Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient,
		ClockTime = preset.ClockTime,
		GeographicLatitude = preset.GeographicLatitude,
	}
	tween(Lighting, lighting, info)
	tween(findEffect("Atmosphere"), preset.Atmosphere, info)
	tween(findEffect("BloomEffect"), preset.Bloom, info)
	tween(findEffect("ColorCorrectionEffect"), preset.Color, info)
	tween(findEffect("SunRaysEffect"), preset.SunRays, info)
	tween(Workspace.Terrain:FindFirstChildOfClass("Clouds"), preset.Clouds, info)
end

function LightingController.SetBlur(enabled: boolean)
	if not blur then
		return
	end
	TweenService:Create(blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = if enabled then 10 else 0 }):Play()
end

function LightingController.Init(controllers)
	Controllers = controllers
end

function LightingController.Start()
	blur = Instance.new("BlurEffect")
	blur.Name = "WindowBlur"
	blur.Size = 0
	blur.Parent = Lighting

	LightingController.Apply("Lobby", 0.01)
	-- Clouds are created by the server after the lobby is built; tint them once they exist
	task.delay(3, function()
		if current == "Lobby" then
			current = nil
			LightingController.Apply("Lobby", 1)
		end
	end)

	Controllers.DataController.MatchEvent:Connect(function(eventName: string, payload)
		if eventName == "Loading" then
			-- Mostly hidden behind the loading screen, so the change can be quick
			LightingController.Apply(payload.LevelId, 1.2)
		elseif eventName == "Ended" then
			LightingController.Apply("Lobby", 2.5)
		end
	end)
end

return LightingController
