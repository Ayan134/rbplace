--[[
	BagController
	Client side of the bag loop:
	  * when the bag is full, the nearest trash can is outlined, a glowing guide line
	    leads to it and a reminder stays on screen until the bag is emptied
	  * selling plays the cash sound, throws a burst of stickers into the can and pops
	    "+$123" above it
	  * shop purchases get a little celebration
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerStats = require(Shared.PlayerStats)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local LOCAL_PLAYER = Players.LocalPlayer
local GUIDE_COLOR = Color3.fromRGB(110, 255, 130)

local BagController = {}

local Controllers
local guideTarget: BasePart? = nil
local highlight: Highlight
local beam: Beam
local playerAttachment: Attachment
local targetAttachment: Attachment

local function sellPoints(): { BasePart }
	local points = {}
	for _, root in ipairs({ Workspace:FindFirstChild("Lobby"), Workspace:FindFirstChild("Arenas") }) do
		if root then
			for _, descendant in ipairs(root:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant:GetAttribute("SellPoint") == true then
					table.insert(points, descendant)
				end
			end
		end
	end
	return points
end

local function nearestSellPoint(): BasePart?
	local character = LOCAL_PLAYER.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, point in ipairs(sellPoints()) do
		local distance = (point.Position - root.Position).Magnitude
		if distance < bestDistance then
			best, bestDistance = point, distance
		end
	end
	return best
end

local function clearGuide()
	guideTarget = nil
	highlight.Adornee = nil
	highlight.Enabled = false
	beam.Enabled = false
	targetAttachment.Parent = nil
	Controllers.UIController.SetBagHint(false)
end

local function showGuide()
	local point = nearestSellPoint()
	if not point then
		return
	end
	guideTarget = point
	highlight.Adornee = point.Parent
	highlight.Enabled = true
	targetAttachment.Parent = point
	targetAttachment.Position = Vector3.new(point.Size.X / 2 + 1, 0, 0)
	local character = LOCAL_PLAYER.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		playerAttachment.Parent = root
		beam.Enabled = true
	end
	Controllers.UIController.SetBagHint(true)
end

local function onBagFull()
	Controllers.SoundManager.Play("BagFull")
	showGuide()
end

local function onSold(payload)
	clearGuide()
	local SoundManager = Controllers.SoundManager
	SoundManager.Play("TrashLid")
	SoundManager.Play("Sell")
	local position = payload.Position
	if typeof(position) == "Vector3" then
		Controllers.EffectsController.SellBurst(position + Vector3.new(0, 5.5, 0), payload.Count)
		task.delay(0.35, function()
			Controllers.EffectsController.FloatingText(position + Vector3.new(0, 9, 0), "+" .. Utility.FormatMoney(payload.Coins), Color3.fromRGB(110, 255, 130), 1.6)
		end)
	end
	Controllers.UIController.Toast(string.format("Sold %d stickers for %s", payload.Count, Utility.FormatMoney(payload.Coins)), "Success")
end

local function onPurchased(payload)
	Controllers.SoundManager.Play("Purchase")
	Controllers.EffectsController.Confetti(40)
	Controllers.UIController.Announce("New " .. string.lower(payload.Kind or "item") .. "!", tostring(payload.Name), Color3.fromRGB(110, 255, 130), 1.8)
end

function BagController.Init(controllers)
	Controllers = controllers
end

function BagController.Start()
	highlight = Instance.new("Highlight")
	highlight.Name = "TrashCanHighlight"
	highlight.FillColor = GUIDE_COLOR
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = GUIDE_COLOR
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false
	highlight.Parent = Workspace

	playerAttachment = Instance.new("Attachment")
	playerAttachment.Name = "BagGuideFrom"
	targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "BagGuideTo"
	beam = Instance.new("Beam")
	beam.Name = "BagGuide"
	beam.Attachment0 = playerAttachment
	beam.Attachment1 = targetAttachment
	beam.Color = ColorSequence.new(GUIDE_COLOR)
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(1, 0.2) })
	beam.Width0 = 0.25
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.Segments = 12
	beam.CurveSize0 = 4
	beam.CurveSize1 = -4
	beam.Enabled = false
	beam.Parent = Workspace.Terrain

	Controllers.PeelController.BagFull:Connect(onBagFull)
	Remotes.Effect.OnClientEvent:Connect(function(effectName: string, payload)
		if effectName == "Sold" then
			onSold(payload)
		elseif effectName == "Purchased" then
			onPurchased(payload)
		end
	end)

	-- The guide goes away once the bag is emptied (or after a match ends)
	Controllers.DataController.Changed:Connect(function(data)
		if guideTarget and PlayerStats.GetBagCount(data) == 0 then
			clearGuide()
		end
	end)
	Controllers.DataController.MatchEvent:Connect(function(eventName: string)
		if eventName == "Loading" or eventName == "Ended" then
			clearGuide()
		end
	end)
	LOCAL_PLAYER.CharacterAdded:Connect(function()
		if guideTarget then
			task.wait(0.5)
			showGuide()
		end
	end)
end

return BagController
