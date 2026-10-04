--[[
	PartyScreen (PartyUI)
	  * PLAY window: create a room (level, difficulty, party size) or join an open room
	  * Room panel (docked right while in a room): host, members with avatars and ready
	    state, level / difficulty / size controls for the host, Ready, Start, Kick, Leave
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DifficultyConfig = require(Shared.DifficultyConfig)
local LevelConfig = require(Shared.LevelConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local LOCAL_PLAYER = Players.LocalPlayer

local PartyScreen = {}
PartyScreen.__index = PartyScreen

local function unlockedLevels(data): { any }
	local list = {}
	for _, level in ipairs(LevelConfig.GetOrdered()) do
		if data and data.UnlockedLevels[level.LevelId] then
			table.insert(list, level)
		end
	end
	return list
end

local function cycle(list: { any }, current: any, step: number): any
	local index = table.find(list, current) or 1
	index = ((index - 1 + step) % #list) + 1
	return list[index]
end

function PartyScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, PartyScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.SelectedLevel = "Fountain"
	self.SelectedDifficulty = "Easy"
	self.SelectedSize = 2

	self.Window = Components.Window(gui, {
		Name = "PlayWindow",
		Title = "▶ PLAY",
		Color = Theme.Colors.Pink,
		Size = UDim2.fromOffset(960, 560),
		OnOpen = function()
			self:RefreshCreate()
			self:RefreshRooms()
		end,
	})
	local content = self.Window.Content

	-- Create room (left)
	local create = Components.Frame({ Name = "Create", Size = UDim2.new(0.56, -8, 1, 0), Color = Theme.Colors.PanelDark, Transparency = 0.3, Corner = 14, Parent = content })
	Components.Padding(create, 12)
	Components.Label({ Text = "CREATE ROOM", Size = UDim2.new(1, 0, 0, 30), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 26, Stroke = 1.5, Parent = create })

	Components.Label({ Text = "LEVEL", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 36), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 16, Parent = create })
	local levelScroll = Components.Scroll({ Name = "Levels", Size = UDim2.new(1, 0, 0, 150), Position = UDim2.fromOffset(0, 58), Direction = Enum.ScrollingDirection.X, Automatic = Enum.AutomaticSize.X, Parent = create })
	Components.List(levelScroll, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	self.LevelScroll = levelScroll

	Components.Label({ Text = "DIFFICULTY", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 216), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 16, Parent = create })
	local difficultyRow = Components.Create("Frame", { Name = "Difficulty", Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 238), BackgroundTransparency = 1, Parent = create })
	Components.List(difficultyRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left)
	self.DifficultyButtons = {}
	for index, id in ipairs(DifficultyConfig.Order) do
		local difficulty = DifficultyConfig.Get(id)
		self.DifficultyButtons[id] = Components.Button({
			Text = difficulty.DisplayName,
			Size = UDim2.new(0.25, -6, 1, 0),
			Color = difficulty.Color,
			LayoutOrder = index,
			MaxTextSize = 20,
			OnClick = function()
				self.SelectedDifficulty = id
				self:RefreshCreate()
			end,
			Parent = difficultyRow,
		})
	end
	self.DifficultyInfo = Components.Label({ Text = "", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 292), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Body, Color = Theme.Colors.TextDim, MaxTextSize = 15, Parent = create })

	Components.Label({ Text = "PLAYERS", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 332), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 16, Parent = create })
	local sizeRow = Components.Create("Frame", { Name = "Size", Size = UDim2.new(1, 0, 0, 46), Position = UDim2.fromOffset(0, 354), BackgroundTransparency = 1, Parent = create })
	Components.List(sizeRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left)
	self.SizeRow = sizeRow
	self.SizeButtons = {}

	self.Summary = Components.Label({ Text = "", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -82), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.Yellow, MaxTextSize = 17, Parent = create })
	self.CreateButton = Components.Button({
		Text = "CREATE ROOM",
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 1, -52),
		Color = Theme.Colors.Green,
		MaxTextSize = 28,
		OnClick = function()
			self:CreateRoom()
		end,
		Parent = create,
	})

	-- Open rooms (right)
	local rooms = Components.Frame({ Name = "Rooms", Size = UDim2.new(0.44, -8, 1, 0), Position = UDim2.new(0.56, 8, 0, 0), Color = Theme.Colors.PanelDark, Transparency = 0.3, Corner = 14, Parent = content })
	Components.Padding(rooms, 12)
	Components.Label({ Text = "OPEN ROOMS", Size = UDim2.new(1, 0, 0, 30), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 26, Stroke = 1.5, Parent = rooms })
	local roomScroll = Components.Scroll({ Name = "List", Size = UDim2.new(1, 0, 1, -40), Position = UDim2.fromOffset(0, 40), Parent = rooms })
	Components.List(roomScroll, Enum.FillDirection.Vertical, 8)
	self.RoomScroll = roomScroll

	-- Docked room panel
	local dock = Components.Frame({
		Name = "RoomPanel",
		Size = UDim2.fromOffset(320, 470),
		Position = UDim2.new(1, -16, 0.5, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Theme.Colors.Panel,
		Transparency = 0.05,
		Corner = 18,
		Stroke = 3,
		StrokeColor = Theme.Colors.Pink,
		Visible = false,
		Parent = gui,
	})
	Components.Padding(dock, 12)
	dock.Size = UDim2.fromOffset(320, 0)
	dock.AutomaticSize = Enum.AutomaticSize.Y
	self.Dock = dock
	return self
end

function PartyScreen:SetPendingLevel(levelId: string)
	self.SelectedLevel = levelId
	self:RefreshCreate()
end

function PartyScreen:CreateRoom()
	local result = Remotes.CreateParty:InvokeServer(self.SelectedLevel, self.SelectedDifficulty, self.SelectedSize)
	if result and result.Success then
		self.Window.Close()
	elseif result then
		self.Ctx.UI.Toast(result.Message, "Error")
	end
end

function PartyScreen:RefreshCreate()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	local maxSize = self.Ctx.Controllers.DataController.Party.MaxPartySize or 4

	-- Level cards
	Components.ClearChildren(self.LevelScroll, { "UIListLayout" })
	for index, level in ipairs(LevelConfig.GetOrdered()) do
		local unlocked = data.UnlockedLevels[level.LevelId] == true
		local selected = level.LevelId == self.SelectedLevel
		local card = Components.Create("TextButton", {
			Name = level.LevelId,
			Size = UDim2.fromOffset(128, 140),
			BackgroundColor3 = if selected then Theme.Colors.PanelLight else Theme.Colors.Panel,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			Parent = self.LevelScroll,
		})
		Components.Corner(card, 12)
		Components.Stroke(card, if selected then Theme.Colors.Yellow else Theme.Colors.Stroke, if selected then 3 else 1.5)
		local preview = ReplicatedStorage.Assets.LevelPreviews:FindFirstChild(level.LevelId)
		Components.Viewport(preview, { Size = UDim2.new(1, -8, 0, 84), Position = UDim2.fromOffset(4, 4), Background = Theme.Lighten(level.ThemeColor, 0.5), Corner = 10, Parent = card })
		Components.Label({ Text = level.Name, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 90), MaxTextSize = 16, Stroke = 1, Parent = card })
		Components.Label({
			Text = if unlocked then Components.Stars(level.Stars) else "🔒 LV " .. level.RequiredLevel,
			Size = UDim2.new(1, -8, 0, 18),
			Position = UDim2.fromOffset(4, 114),
			Font = Theme.Fonts.Bold,
			Color = if unlocked then Theme.Colors.Yellow else Theme.Colors.TextDim,
			MaxTextSize = 14,
			Parent = card,
		})
		card.Activated:Connect(function()
			if unlocked then
				self.Ctx.Controllers.SoundManager.Play("Click")
				self.SelectedLevel = level.LevelId
				self:RefreshCreate()
			else
				self.Ctx.Controllers.SoundManager.Play("Error")
				self.Ctx.UI.Toast("Unlock " .. level.Name .. " in LEVELS first", "Error")
			end
		end)
	end

	-- Difficulty buttons
	for id, button in pairs(self.DifficultyButtons) do
		local difficulty = DifficultyConfig.Get(id)
		local allowed = data.Level >= difficulty.RequiredLevel
		button.SetEnabled(allowed)
		button.SetText((if id == self.SelectedDifficulty then "✔ " else "") .. difficulty.DisplayName .. (if allowed then "" else " 🔒"))
	end
	local difficulty = DifficultyConfig.Get(self.SelectedDifficulty)
	self.DifficultyInfo.Text = difficulty.Description

	-- Size buttons (generated from MaxPartySize so bigger rooms need no UI changes)
	if #self.SizeButtons ~= maxSize then
		Components.ClearChildren(self.SizeRow, { "UIListLayout" })
		self.SizeButtons = {}
		for size = 1, maxSize do
			self.SizeButtons[size] = Components.Button({
				Text = tostring(size),
				Size = UDim2.new(1 / maxSize, -8, 1, 0),
				Color = Theme.Colors.Blue,
				LayoutOrder = size,
				MaxTextSize = 22,
				OnClick = function()
					self.SelectedSize = size
					self:RefreshCreate()
				end,
				Parent = self.SizeRow,
			})
		end
	end
	for size, button in ipairs(self.SizeButtons) do
		button.SetText((if size == self.SelectedSize then "✔ " else "") .. size .. (if size == 1 then " SOLO" else " 👥"))
		button.SetColor(if size == self.SelectedSize then Theme.Colors.Cyan else Theme.Colors.Blue)
	end

	local level = LevelConfig.Get(self.SelectedLevel)
	if level then
		self.Summary.Text = string.format(
			"%s • %s stickers • ~%s coins",
			level.Name,
			Utility.FormatNumber(LevelConfig.GetStickerCount(level.LevelId, self.SelectedDifficulty)),
			Utility.Abbreviate(LevelConfig.EstimateTotalReward(level.LevelId, self.SelectedDifficulty))
		)
	end
	local inParty = self.Ctx.Controllers.DataController.Party.MyParty ~= nil
	self.CreateButton.SetText(if inParty then "CREATE NEW ROOM" else "CREATE ROOM")
end

function PartyScreen:RefreshRooms()
	local state = self.Ctx.Controllers.DataController.Party
	Components.ClearChildren(self.RoomScroll, { "UIListLayout" })
	local any = false
	for index, room in ipairs(state.Rooms or {}) do
		local level = LevelConfig.Get(room.LevelId)
		local difficulty = DifficultyConfig.Get(room.Difficulty)
		if not level or not difficulty then
			continue
		end
		any = true
		local row = Components.Frame({ Name = "Room", Size = UDim2.new(1, -10, 0, 74), Color = Theme.Colors.Panel, Corner = 12, Stroke = 1.5, LayoutOrder = index, Parent = self.RoomScroll })
		Components.Avatar(room.HostUserId, { Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(10, 10), Parent = row })
		Components.Label({ Text = room.HostName .. "'s room", Size = UDim2.new(1, -180, 0, 24), Position = UDim2.fromOffset(72, 8), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 18, Parent = row })
		Components.Label({
			Text = string.format("%s • <font color=\"#%s\">%s</font> • %d/%d", level.Name, difficulty.Color:ToHex(), difficulty.DisplayName, room.Count, room.MaxSize),
			RichText = true,
			Size = UDim2.new(1, -180, 0, 20),
			Position = UDim2.fromOffset(72, 38),
			XAlign = Enum.TextXAlignment.Left,
			Font = Theme.Fonts.Bold,
			Color = Theme.Colors.TextDim,
			MaxTextSize = 15,
			Parent = row,
		})
		local full = room.Count >= room.MaxSize
		local playing = room.State ~= "Lobby"
		local mine = state.MyParty and state.MyParty.Id == room.Id
		local join = Components.Button({
			Text = if mine then "YOURS" elseif playing then "PLAYING" elseif full then "FULL" else "JOIN",
			Size = UDim2.fromOffset(92, 44),
			Position = UDim2.new(1, -102, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Color = Theme.Colors.Green,
			MaxTextSize = 20,
			OnClick = function()
				local result = Remotes.JoinParty:InvokeServer(room.Id)
				if result and result.Success then
					self.Window.Close()
				elseif result then
					self.Ctx.UI.Toast(result.Message, "Error")
				end
			end,
			Parent = row,
		})
		join.SetEnabled(not full and not playing and not mine)
	end
	if not any then
		Components.Label({ Text = "No open rooms yet.\nCreate one and invite friends!", Size = UDim2.new(1, 0, 0, 80), Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 18, Parent = self.RoomScroll })
	end
end

local function control(parent: Instance, order: number, labelText: string, valueText: string, enabled: boolean, onChange: (number) -> ())
	local row = Components.Create("Frame", { Name = labelText, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	Components.Label({ Text = labelText, Size = UDim2.new(0, 70, 1, 0), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 14, Parent = row })
	local left = Components.Button({ Text = "◀", Size = UDim2.fromOffset(34, 32), Position = UDim2.fromOffset(72, 1), Color = Theme.Colors.Purple, MaxTextSize = 16, OnClick = function()
		onChange(-1)
	end, Parent = row })
	Components.Label({ Text = valueText, Size = UDim2.new(1, -154, 1, 0), Position = UDim2.fromOffset(112, 0), MaxTextSize = 17, Stroke = 1, Parent = row })
	local right = Components.Button({ Text = "▶", Size = UDim2.fromOffset(34, 32), Position = UDim2.new(1, -36, 0, 1), Color = Theme.Colors.Purple, MaxTextSize = 16, OnClick = function()
		onChange(1)
	end, Parent = row })
	left.Instance.Visible = enabled
	right.Instance.Visible = enabled
end

function PartyScreen:RefreshDock()
	local state = self.Ctx.Controllers.DataController.Party
	local party = state.MyParty
	local dock = self.Dock
	local inMatch = self.Ctx.Controllers.DataController.Match ~= nil
	dock.Visible = party ~= nil and not inMatch
	self.Ctx.UI.SetQuestsVisible(party == nil)
	if not party or inMatch then
		self.DockSignature = nil
		return
	end
	-- Rebuild only when the room actually changed
	local signature = string.format("%s|%s|%s|%d|%s", party.Id, party.LevelId, party.Difficulty, party.MaxSize, tostring(party.HostUserId))
	for _, member in ipairs(party.Members) do
		signature ..= string.format("|%d:%s:%d", member.UserId, tostring(member.Ready), member.Level)
	end
	if signature == self.DockSignature then
		return
	end
	self.DockSignature = signature
	Components.ClearChildren(dock, { "UIPadding", "UICorner", "UIStroke" })
	local list = Components.Create("Frame", { Name = "List", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = dock })
	Components.List(list, Enum.FillDirection.Vertical, 6)

	local isHost = party.HostUserId == LOCAL_PLAYER.UserId
	local level = LevelConfig.Get(party.LevelId)
	local difficulty = DifficultyConfig.Get(party.Difficulty)
	local data = self.Ctx.Controllers.DataController.Get()

	Components.Label({ Text = "🏠 ROOM", Size = UDim2.new(1, 0, 0, 30), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 24, Stroke = 1.5, LayoutOrder = 1, Parent = list })
	Components.Label({
		Text = string.format("%s • <font color=\"#%s\">%s</font> • %d/%d players", level and level.Name or "?", difficulty and difficulty.Color:ToHex() or "ffffff", difficulty and difficulty.DisplayName or "?", #party.Members, party.MaxSize),
		RichText = true,
		Size = UDim2.new(1, 0, 0, 20),
		XAlign = Enum.TextXAlignment.Left,
		Font = Theme.Fonts.Bold,
		Color = Theme.Colors.TextDim,
		MaxTextSize = 15,
		LayoutOrder = 2,
		Parent = list,
	})

	-- Members
	local allReady = true
	for index, member in ipairs(party.Members) do
		if not member.Ready then
			allReady = false
		end
		local row = Components.Frame({ Name = "Member", Size = UDim2.new(1, 0, 0, 48), Color = Theme.Colors.PanelDark, Transparency = 0.2, Corner = 10, LayoutOrder = 10 + index, Parent = list })
		Components.Avatar(member.UserId, { Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(4, 4), StrokeColor = if member.IsHost then Theme.Colors.Yellow else nil, Parent = row })
		Components.Label({ Text = (if member.IsHost then "👑 " else "") .. member.DisplayName, Size = UDim2.new(1, -150, 0, 22), Position = UDim2.fromOffset(52, 4), XAlign = Enum.TextXAlignment.Left, MaxTextSize = 17, Parent = row })
		Components.Label({ Text = "Level " .. member.Level, Size = UDim2.new(1, -150, 0, 16), Position = UDim2.fromOffset(52, 27), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 13, Parent = row })
		Components.Label({
			Text = if member.IsHost then "HOST" elseif member.Ready then "✅ READY" else "⏳ WAIT",
			Size = UDim2.fromOffset(70, 30),
			Position = UDim2.new(1, -112, 0, 9),
			Color = if member.Ready then Theme.Colors.Green else Theme.Colors.Orange,
			MaxTextSize = 14,
			Parent = row,
		})
		if isHost and not member.IsHost then
			Components.Button({
				Text = "✕",
				Size = UDim2.fromOffset(34, 34),
				Position = UDim2.new(1, -38, 0, 7),
				Color = Theme.Colors.Red,
				MaxTextSize = 16,
				OnClick = function()
					local result = Remotes.PartyAction:InvokeServer("Kick", member.UserId)
					if result and not result.Success then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end,
				Parent = row,
			})
		end
	end
	for slot = #party.Members + 1, party.MaxSize do
		local row = Components.Frame({ Name = "Empty", Size = UDim2.new(1, 0, 0, 34), Color = Theme.Colors.PanelDark, Transparency = 0.6, Corner = 10, LayoutOrder = 10 + slot, Parent = list })
		Components.Label({ Text = "Waiting for player...", Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Body, Color = Theme.Colors.TextDim, MaxTextSize = 14, Parent = row })
	end

	local function act(action: string, value: any)
		task.spawn(function()
			local result = Remotes.PartyAction:InvokeServer(action, value)
			if result and not result.Success then
				self.Ctx.UI.Toast(result.Message, "Error")
			end
		end)
	end

	-- Host controls
	if isHost and data then
		control(list, 30, "LEVEL", level and level.Name or "?", true, function(step)
			local levels = unlockedLevels(data)
			local current = LevelConfig.Get(party.LevelId)
			local nextLevel = cycle(levels, current, step)
			if nextLevel then
				act("SetLevel", nextLevel.LevelId)
			end
		end)
		control(list, 31, "MODE", difficulty and difficulty.DisplayName or "?", true, function(step)
			act("SetDifficulty", cycle(DifficultyConfig.Order, party.Difficulty, step))
		end)
		control(list, 32, "SIZE", party.MaxSize .. " players", true, function(step)
			local maxSize = state.MaxPartySize or 4
			local size = math.clamp(party.MaxSize + step, math.max(1, #party.Members), maxSize)
			act("SetSize", size)
		end)
	end

	local buttons = Components.Create("Frame", { Name = "Buttons", Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, LayoutOrder = 50, Parent = list })
	if isHost then
		local start = Components.Button({
			Text = "START",
			Size = UDim2.new(0.62, -4, 1, 0),
			Color = Theme.Colors.Green,
			MaxTextSize = 26,
			OnClick = function()
				task.spawn(function()
					local result = Remotes.StartParty:InvokeServer()
					if result and not result.Success then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end)
			end,
			Parent = buttons,
		})
		start.SetEnabled(allReady)
	else
		local me = nil
		for _, member in ipairs(party.Members) do
			if member.UserId == LOCAL_PLAYER.UserId then
				me = member
			end
		end
		local ready = me and me.Ready
		Components.Button({
			Text = if ready then "UNREADY" else "READY",
			Size = UDim2.new(0.62, -4, 1, 0),
			Color = if ready then Theme.Colors.Orange else Theme.Colors.Green,
			MaxTextSize = 26,
			OnClick = function()
				act("SetReady", not ready)
			end,
			Parent = buttons,
		})
	end
	Components.Button({
		Text = "LEAVE",
		Size = UDim2.new(0.38, -4, 1, 0),
		Position = UDim2.new(0.62, 4, 0, 0),
		Color = Theme.Colors.Red,
		MaxTextSize = 22,
		OnClick = function()
			Remotes.LeaveParty:FireServer()
		end,
		Parent = buttons,
	})
	if isHost and not allReady then
		Components.Label({ Text = "Waiting for everyone to be READY", Size = UDim2.new(1, 0, 0, 18), Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 13, LayoutOrder = 51, Parent = list })
	end
end

function PartyScreen:Update()
	self:RefreshDock()
	if self.Window.IsOpen() then
		self:RefreshRooms()
	end
end

return PartyScreen
