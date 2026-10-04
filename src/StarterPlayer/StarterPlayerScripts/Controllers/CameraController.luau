--[[
	CameraController
	Camera limits per area and the level-complete orbit around the cleaned object.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LevelConfig = require(Shared.LevelConfig)

local LOCAL_PLAYER = Players.LocalPlayer
local LOBBY_ZOOM = 60

local CameraController = {}

local Controllers
local orbitConnection: RBXScriptConnection? = nil

function CameraController.StopOrbit()
	if orbitConnection then
		orbitConnection:Disconnect()
		orbitConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

-- Slowly circles the camera around `focus` for `duration` seconds.
function CameraController.Orbit(focus: Vector3, radius: number, duration: number)
	CameraController.StopOrbit()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local startTime = os.clock()
	local startAngle = math.atan2(camera.CFrame.Position.X - focus.X, camera.CFrame.Position.Z - focus.Z)
	orbitConnection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - startTime
		if t > duration then
			CameraController.StopOrbit()
			return
		end
		local angle = startAngle + t * 0.35
		local height = radius * 0.45
		local position = focus + Vector3.new(math.sin(angle) * radius, height, math.cos(angle) * radius)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(position, focus), math.min(1, t * 2 + 0.05))
	end)
end

function CameraController.Init(controllers)
	Controllers = controllers
end

function CameraController.Start()
	LOCAL_PLAYER.CameraMaxZoomDistance = LOBBY_ZOOM
	Controllers.DataController.MatchEvent:Connect(function(eventName: string, payload)
		if eventName == "Start" then
			local level = LevelConfig.Get(payload.LevelId)
			LOCAL_PLAYER.CameraMaxZoomDistance = level and level.CameraMaxZoom or 100
		elseif eventName == "Complete" then
			local match = Controllers.DataController.Match
			local level = LevelConfig.Get(payload.LevelId)
			if match and match.Focus and level then
				CameraController.Orbit(match.Focus, math.clamp(level.CameraMaxZoom * 0.6, 35, 120), 7)
			end
		elseif eventName == "Ended" then
			CameraController.StopOrbit()
			LOCAL_PLAYER.CameraMaxZoomDistance = LOBBY_ZOOM
		end
	end)
end

return CameraController
