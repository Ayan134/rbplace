--[[
	Notifier
	Server -> client notification helpers (toasts, big announcements, effects).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Notifier = {}

-- kind: "Info" | "Success" | "Error" | "Rare" | "Reward"
function Notifier.Toast(player: Player, text: string, kind: string?)
	Remotes.Notify:FireClient(player, { Text = text, Kind = kind or "Info" })
end

function Notifier.ToastMany(players: { Player }, text: string, kind: string?)
	for _, player in ipairs(players) do
		Notifier.Toast(player, text, kind)
	end
end

function Notifier.Effect(player: Player, effectName: string, payload: any)
	Remotes.Effect:FireClient(player, effectName, payload)
end

return Notifier
