--[[
	DataController
	Client-side read-only cache of the player's data, party state and match state.
	The server pushes snapshots through UpdateUI / PartyUpdate / MatchEvent;
	nothing here is trusted by the server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerStats = require(Shared.PlayerStats)
local Signal = require(Shared.Signal)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataController = {}

DataController.Changed = Signal.new() -- (data, previous)
DataController.PartyChanged = Signal.new() -- (partyState)
DataController.MatchEvent = Signal.new() -- (eventName, payload)

DataController.Data = nil :: any
DataController.Party = { Rooms = {}, MyParty = nil, MaxPartySize = 4 } :: any
DataController.Match = nil :: any -- { State, LevelId, Difficulty, Total, ... } while in a match

function DataController.Get()
	return DataController.Data
end

function DataController.GetStats(): PlayerStats.Stats
	return PlayerStats.Compute(DataController.Data)
end

function DataController.IsLoaded(): boolean
	return DataController.Data ~= nil
end

function DataController.WaitForData()
	while not DataController.Data do
		task.wait(0.1)
	end
	return DataController.Data
end

local function setData(data)
	local previous = DataController.Data
	DataController.Data = data
	DataController.Changed:Fire(data, previous)
end

function DataController.Init() end

function DataController.Start()
	Remotes.UpdateUI.OnClientEvent:Connect(setData)
	Remotes.PartyUpdate.OnClientEvent:Connect(function(state)
		DataController.Party = state
		DataController.PartyChanged:Fire(state)
	end)
	Remotes.MatchEvent.OnClientEvent:Connect(function(eventName: string, payload)
		if eventName == "Loading" then
			DataController.Match = { State = "Loading", LevelId = payload.LevelId, Difficulty = payload.Difficulty, Total = payload.Total, Team = {} }
		elseif eventName == "Start" and DataController.Match then
			DataController.Match.State = "Playing"
			DataController.Match.Total = payload.Total
			DataController.Match.ServerStart = payload.ServerStart
			DataController.Match.Focus = payload.Focus
			DataController.Match.Team = payload.Team
		elseif eventName == "Team" and DataController.Match then
			DataController.Match.Team = payload.Team
		elseif eventName == "Complete" and DataController.Match then
			DataController.Match.State = "Complete"
			DataController.Match.Summary = payload
		elseif eventName == "Ended" then
			DataController.Match = nil
		end
		DataController.MatchEvent:Fire(eventName, payload)
	end)

	-- Initial fetch (the server may still be loading our save)
	task.spawn(function()
		while not DataController.Data do
			local ok, data = pcall(function()
				return Remotes.GetData:InvokeServer()
			end)
			if ok and data and not DataController.Data then
				setData(data)
				break
			end
			task.wait(1)
		end
	end)
end

return DataController
