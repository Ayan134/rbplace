--[[
	CameraController
	The game is first person (StarterPlayer.CameraMode = LockFirstPerson); this controller
	only runs the level-complete orbit around the cleaned object and then hands the
	camera back.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LevelConfig = require(Shared.LevelConfig)

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
	Controllers.DataController.MatchEvent:Connect(function(eventName: string, payload)
		if eventName == "Complete" then
			local match = Controllers.DataController.Match
			local level = LevelConfig.Get(payload.LevelId)
			if match and match.Focus and level then
				CameraController.Orbit(match.Focus, math.clamp(level.CameraMaxZoom * 0.6, 35, 120), 7)
			end
		elseif eventName == "Ended" then
			CameraController.StopOrbit()
		end
	end)
end

return CameraController
