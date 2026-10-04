--[[
	PeelController
	Runs the local player's peeling:

	  * holding PEEL starts the targeted sticker; with Sticker Capacity > 1 nearby
	    stickers are chained in one after another (1 -> 2 -> 3 -> 4), each with its own
	    animation and numbered progress marker
	  * the animation is predicted locally from PlayerStats (same formula as the server)
	    so it feels instant; the server still validates Start and Complete
	  * releasing PEEL cancels unfinished stickers - their progress is kept on the server
	  * rejected requests are rolled back (e.g. "TooFast" completions are retried)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerStats = require(Shared.PlayerStats)
local Signal = require(Shared.Signal)
local ToolConfig = require(Shared.ToolConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local LOCAL_PLAYER = Players.LocalPlayer

local PeelController = {}

PeelController.ActiveChanged = Signal.new() -- (activeCount, capacity)
PeelController.RewardReceived = Signal.new() -- (reward, record)

local Controllers
local holding = false
local active: { [any]: { Session: any, Slot: number, Started: number } } = {}
local awaiting: { [any]: { Session: any, Sent: number, Retries: number } } = {}
local markers: { [number]: BillboardGui } = {}
local lastStart = 0
local lastPeelSound = 0
local lastHint = 0
local chainAnchor: Vector3? = nil

local function getRoot(): BasePart?
	local character = LOCAL_PLAYER.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function activeCount(): number
	local n = 0
	for _ in pairs(active) do
		n += 1
	end
	return n
end

local function freeSlot(capacity: number): number
	for slot = 1, capacity do
		local used = false
		for _, entry in pairs(active) do
			if entry.Slot == slot then
				used = true
				break
			end
		end
		if not used then
			return slot
		end
	end
	return capacity
end

local function hint(text: string)
	if os.clock() - lastHint > 2 then
		lastHint = os.clock()
		Controllers.UIController.Toast(text, "Error")
	end
end

------------------------------------------------------------------------
-- Progress markers ("Sticker Targets")
------------------------------------------------------------------------

local function getMarker(slot: number): BillboardGui
	local marker = markers[slot]
	if marker then
		return marker
	end
	marker = Instance.new("BillboardGui")
	marker.Name = "PeelMarker" .. slot
	marker.Size = UDim2.fromOffset(86, 44)
	marker.StudsOffsetWorldSpace = Vector3.new(0, 1.4, 0)
	marker.AlwaysOnTop = true
	marker.LightInfluence = 0
	marker.Enabled = false
	marker.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	background.BackgroundTransparency = 0.15
	background.Parent = marker
	Instance.new("UICorner", background).CornerRadius = UDim.new(0, 10)

	local index = Instance.new("TextLabel")
	index.Name = "Index"
	index.Size = UDim2.fromOffset(26, 26)
	index.Position = UDim2.fromOffset(4, 4)
	index.BackgroundColor3 = Color3.fromRGB(110, 222, 164)
	index.Font = Enum.Font.GothamBold
	index.TextScaled = true
	index.TextColor3 = Color3.fromRGB(18, 18, 22)
	index.Text = tostring(slot)
	index.Parent = background
	Instance.new("UICorner", index).CornerRadius = UDim.new(1, 0)

	local percent = Instance.new("TextLabel")
	percent.Name = "Percent"
	percent.Size = UDim2.new(1, -36, 0, 26)
	percent.Position = UDim2.fromOffset(34, 4)
	percent.BackgroundTransparency = 1
	percent.Font = Enum.Font.GothamBold
	percent.TextScaled = true
	percent.TextColor3 = Color3.new(1, 1, 1)
	percent.Text = "0%"
	percent.Parent = background

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, -8, 0, 8)
	bar.Position = UDim2.new(0, 4, 1, -12)
	bar.BackgroundColor3 = Color3.fromRGB(70, 60, 110)
	bar.Parent = background
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(120, 230, 120)
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	markers[slot] = marker
	return marker
end

local function updateMarkers(capacity: number)
	local used: { [number]: boolean } = {}
	for record, entry in pairs(active) do
		local marker = getMarker(entry.Slot)
		used[entry.Slot] = true
		marker.Adornee = record.Part
		marker.Enabled = record.Part ~= nil
		local progress = Controllers.StickerRenderer.GetCurrentProgress(record)
		local background = marker:FindFirstChild("Background") :: Frame
		local index = background:FindFirstChild("Index") :: TextLabel
		index.Visible = capacity > 1
		local percent = background:FindFirstChild("Percent") :: TextLabel
		-- Live PEEL PROGRESS: 0% -> 25% -> 50% -> 75% -> 100%
		percent.Text = string.format("%d%%", math.floor(progress * 100))
		local fill = (background:FindFirstChild("Bar") :: Frame):FindFirstChild("Fill") :: Frame
		fill.Size = UDim2.fromScale(progress, 1)
		fill.BackgroundColor3 = Color3.fromRGB(255, 200, 80):Lerp(Color3.fromRGB(110, 235, 120), progress)
	end
	for slot, marker in pairs(markers) do
		if not used[slot] then
			marker.Enabled = false
			marker.Adornee = nil
		end
	end
end

------------------------------------------------------------------------
-- Peel lifecycle
------------------------------------------------------------------------

local function stopLocal(record, sendCancel: boolean)
	local entry = active[record]
	if not entry then
		return
	end
	active[record] = nil
	local progress = Controllers.StickerRenderer.GetCurrentProgress(record)
	if sendCancel then
		Remotes.PeelSticker:FireServer("Cancel", record.Id)
	end
	Controllers.StickerRenderer.StopPeel(record, math.min(progress, Config.Peel.MaxStoredProgress))
end

local function startPeel(session, record, capacity: number)
	local stats = Controllers.DataController.GetStats()
	local fullDuration = PlayerStats.GetPeelDuration(stats, record.Health)
	local duration = math.max(0.1, fullDuration * (1 - record.Progress))
	local slot = freeSlot(capacity)
	active[record] = { Session = session, Slot = slot, Started = os.clock() }
	lastStart = os.clock()
	Controllers.StickerRenderer.BeginPeel(record, os.clock(), duration, record.Progress, LOCAL_PLAYER.UserId, true)
	Remotes.PeelSticker:FireServer("Start", record.Id)
	Controllers.SoundManager.Play("PeelStart", { Position = record.Position })
	Controllers.AnimationController.PeelPulse()
	PeelController.ActiveChanged:Fire(activeCount(), capacity)
end

local function completePeel(session, record)
	active[record] = nil
	awaiting[record] = { Session = session, Sent = os.clock(), Retries = 0 }
	Remotes.PeelSticker:FireServer("Complete", record.Id)
	-- Predict the tear-off immediately; restored if the server disagrees
	Controllers.StickerRenderer.Detach(session, record)
	chainAnchor = record.Position
end

local function canStart(record, rootPosition: Vector3): boolean
	if not record or not record.Alive or record.Detached or not record.Part then
		return false
	end
	if active[record] or awaiting[record] then
		return false
	end
	if record.State == "Peeling" then
		return false
	end
	if (record.Position - rootPosition).Magnitude > Config.Peel.ClientReach then
		return false
	end
	local canPeel = Controllers.InteractionController.CanPeel(record)
	return canPeel
end

local function tryFill()
	local renderer = Controllers.StickerRenderer
	local session = renderer.GetCurrentSession()
	local root = getRoot()
	if not session or not session.Ready or not root then
		return
	end
	local stats = Controllers.DataController.GetStats()
	local capacity = stats.Capacity
	if activeCount() >= capacity then
		return
	end
	if os.clock() - lastStart < (if activeCount() == 0 then 0 else Config.Peel.ChainStagger) then
		return
	end

	local rootPosition = root.Position
	local target = Controllers.InteractionController.Target
	if target and not target.Detached and target.Alive and not active[target] and not awaiting[target] then
		local canPeel, required = Controllers.InteractionController.CanPeel(target)
		if not canPeel then
			local tool = ToolConfig.GetByTier(required)
			hint("This sticker needs the " .. (tool and tool.Name or "a better tool") .. "!")
		elseif canStart(target, rootPosition) then
			chainAnchor = target.Position
			startPeel(session, target, capacity)
			return
		end
	end

	-- Chain into nearby stickers (also keeps peeling while the button is held)
	local data = Controllers.DataController.Get()
	local autoChain = not data or not data.Settings or data.Settings.AutoChain ~= false
	if not autoChain and activeCount() == 0 and not target then
		return
	end
	if not autoChain and target then
		return
	end
	local anchor = chainAnchor or (target and target.Position)
	if not anchor or (anchor - rootPosition).Magnitude > Config.Peel.ClientReach + Config.Peel.ChainRadius then
		anchor = rootPosition
	end
	local candidates = renderer.QueryRadius(session, anchor, Config.Peel.ChainRadius, function(record)
		return canStart(record, rootPosition)
	end)
	local candidate = candidates[1]
	if not candidate and anchor ~= rootPosition then
		candidates = renderer.QueryRadius(session, rootPosition, Config.Peel.ClientReach, function(record)
			return canStart(record, rootPosition)
		end)
		candidate = candidates[1]
	end
	if candidate then
		startPeel(session, candidate, capacity)
	end
end

function PeelController.SetHolding(value: boolean)
	if holding == value then
		return
	end
	holding = value
	if not holding then
		for record in pairs(active) do
			stopLocal(record, true)
		end
		chainAnchor = nil
		PeelController.ActiveChanged:Fire(0, Controllers.DataController.GetStats().Capacity)
	else
		tryFill()
	end
end

function PeelController.IsPeeling(): boolean
	return next(active) ~= nil
end

function PeelController.GetActive()
	return active
end

local function update()
	local renderer = Controllers.StickerRenderer
	local stats = Controllers.DataController.GetStats()
	local now = os.clock()

	for record, entry in pairs(active) do
		if not record.Part or record.Detached or not record.Alive then
			active[record] = nil
		elseif renderer.GetCurrentProgress(record) >= 1 then
			completePeel(entry.Session, record)
		end
	end

	-- Unanswered completions: roll back after a timeout
	for record, entry in pairs(awaiting) do
		if not record.Alive then
			awaiting[record] = nil
		elseif now - entry.Sent > 4 then
			awaiting[record] = nil
			renderer.Restore(entry.Session, record)
			renderer.StopPeel(record, record.Progress)
		end
	end

	if holding then
		tryFill()
	end

	local count = activeCount()
	if count > 0 then
		local root = getRoot()
		local nearest: any = nil
		local nearestDistance = math.huge
		for record in pairs(active) do
			if root then
				local distance = (record.Position - root.Position).Magnitude
				if distance < nearestDistance then
					nearest, nearestDistance = record, distance
				end
				-- Walked away: cancel
				if distance > Config.Peel.ClientReach + 4 then
					stopLocal(record, true)
				end
			end
		end
		if nearest then
			Controllers.AnimationController.SetPeelTarget(nearest.Position)
		end
		if now - lastPeelSound > 0.32 then
			lastPeelSound = now
			Controllers.SoundManager.Play("Peel", { Position = nearest and nearest.Position })
		end
	else
		Controllers.AnimationController.SetPeelTarget(nil)
	end
	updateMarkers(stats.Capacity)
end

function PeelController.Init(controllers)
	Controllers = controllers
end

function PeelController.Start()
	local renderer = Controllers.StickerRenderer

	renderer.PeelRejected:Connect(function(session, record, reason: string)
		local waiting = awaiting[record]
		if waiting and reason == "TooFast" and waiting.Retries < 6 then
			waiting.Retries += 1
			task.delay(0.15, function()
				if awaiting[record] then
					awaiting[record].Sent = os.clock()
					Remotes.PeelSticker:FireServer("Complete", record.Id)
				end
			end)
			return
		end
		if waiting then
			awaiting[record] = nil
			renderer.Restore(session, record)
			renderer.StopPeel(record, record.Progress)
		end
		if active[record] then
			stopLocal(record, false)
		end
		if reason == "Gone" and record.Alive then
			-- The server already removed it (we missed the update): drop it locally too
			record.Alive = false
			renderer.Detach(session, record, true)
		end
		if reason == "TooFar" then
			hint("Get closer to peel that sticker!")
		elseif reason == "Capacity" then
			hint("Upgrade Sticker Capacity to peel more at once!")
		elseif reason:sub(1, 5) == "Tool:" then
			local tool = ToolConfig.GetByTier(tonumber(reason:sub(6)) or 0)
			hint("This sticker needs the " .. (tool and tool.Name or "a better tool") .. "!")
		end
	end)

	renderer.PeelCancelled:Connect(function(_session, record)
		if active[record] then
			active[record] = nil
		end
		awaiting[record] = nil
	end)

	renderer.Peeled:Connect(function(session, record, userId: number, reward)
		awaiting[record] = nil
		active[record] = nil
		if userId ~= LOCAL_PLAYER.UserId then
			return
		end
		local effects = Controllers.EffectsController
		local isPractice = session.Kind == "Showcase"
		local position = record.Position + record.Normal * 0.6
		if isPractice then
			effects.FloatingText(position, "Practice!", Color3.fromRGB(200, 220, 255), 0.8)
		elseif reward.Coins > 0 then
			local text = "+" .. Utility.FormatNumber(reward.Coins) .. " Coins"
			local color = Color3.fromRGB(255, 220, 70)
			local size = 1
			if record.Info.IsRare then
				size = 1.35
				color = record.Info.Color or color
			end
			effects.FloatingText(position, text, color, size)
			effects.CoinBurst(position, reward.Coins)
			Controllers.SoundManager.Play("Reward", { PlaybackSpeed = 1.6 + math.min(reward.Combo or 0, 30) * 0.015 })
			if reward.Lucky then
				task.delay(0.15, function()
					effects.FloatingText(position + Vector3.new(0, 1.2, 0), "🍀 LUCKY x2!", Color3.fromRGB(120, 255, 140), 1.1)
					Controllers.SoundManager.Play("Lucky")
				end)
			end
		end
		PeelController.RewardReceived:Fire(reward, record)
	end)

	renderer.SessionCleared:Connect(function()
		table.clear(active)
		table.clear(awaiting)
		chainAnchor = nil
	end)

	RunService.Heartbeat:Connect(update)
end

return PeelController
