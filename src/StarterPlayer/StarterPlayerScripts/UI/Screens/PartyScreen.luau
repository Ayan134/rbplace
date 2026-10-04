--[[
	PartyScreen (PartyUI)
	Rooms are the 4 circles in the lobby.
	  * Setup panel: opens for the HOST after stepping into an empty circle -
	    number of players, "friends only", level and difficulty
	  * Room panel (docked right while in a circle): level, members, Start / Edit / Leave
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

local PADS_VIEW = CFrame.lookAt(Vector3.new(0, 4, -64), Vector3.new(0, 4, -100))

local function sectionLabel(parent: Instance, text: string, y: number)
	Components.Label({ Text = text, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, y), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 14, Parent = parent })
end

function PartyScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, PartyScreen)
	self.Gui = gui
	self.Ctx = ctx
	self.Settings = { LevelId = "Pile", Difficulty = "Easy", MaxSize = 4, FriendsOnly = false }
	self.Editing = false

	-- Setup panel
	self.Window = Components.Window(gui, {
		Name = "RoomSetup",
		Icon = "🎮",
		Color = Theme.Colors.Green,
		Title = "Create room",
		Size = UDim2.fromOffset(560, 560),
		OnClose = function()
			self.Editing = false
			if self.Confirmed then
				self.Confirmed = false
				return
			end
			-- Closing the first-time setup means "I don't want a room": step out
			local party = ctx.Controllers.DataController.Party.MyParty
			if party and party.State == "Setup" and party.HostUserId == LOCAL_PLAYER.UserId then
				Remotes.LeaveParty:FireServer()
			end
		end,
	})
	local content = self.Window.Content

	sectionLabel(content, "PLAYERS", 0)
	local sizeRow = Components.Create("Frame", { Name = "Size", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Parent = content })
	Components.List(sizeRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left)
	self.SizeRow = sizeRow
	self.SizeButtons = {}

	-- Friends-only checkbox
	local friendsRow = Components.Create("TextButton", { Name = "FriendsOnly", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 74), BackgroundTransparency = 1, Text = "", Parent = content })
	local box = Components.Frame({ Name = "Box", Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(0, 6), Color = Theme.Colors.PanelLight, Corner = 6, Parent = friendsRow })
	self.CheckMark = Components.Label({ Text = "✓", Size = UDim2.fromScale(1, 1), Font = Theme.Fonts.Title, Color = Theme.Colors.TextDark, MaxTextSize = 18, Parent = box })
	self.CheckBox = box
	Components.Label({ Text = "Friends only", Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(36, 7), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 16, Parent = friendsRow })
	friendsRow.Activated:Connect(function()
		ctx.Controllers.SoundManager.Play("Click")
		self.Settings.FriendsOnly = not self.Settings.FriendsOnly
		self:RefreshSetup()
	end)

	sectionLabel(content, "LEVEL", 122)
	local levelGrid = Components.Create("Frame", { Name = "Levels", Size = UDim2.new(1, 0, 0, 170), Position = UDim2.fromOffset(0, 144), BackgroundTransparency = 1, Parent = content })
	Components.Create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 36), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = levelGrid })
	self.LevelGrid = levelGrid

	sectionLabel(content, "DIFFICULTY", 322)
	local difficultyRow = Components.Create("Frame", { Name = "Difficulty", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 344), BackgroundTransparency = 1, Parent = content })
	Components.List(difficultyRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left)
	self.DifficultyButtons = {}
	for index, id in ipairs(DifficultyConfig.Order) do
		local difficulty = DifficultyConfig.Get(id)
		self.DifficultyButtons[id] = Components.Button({
			Text = difficulty.DisplayName,
			Size = UDim2.new(0.25, -6, 1, 0),
			LayoutOrder = index,
			MaxTextSize = 15,
			OnClick = function()
				self.Settings.Difficulty = id
				self:RefreshSetup()
			end,
			Parent = difficultyRow,
		})
	end

	self.Summary = Components.Label({ Text = "", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -76), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 14, Parent = content })
	self.ConfirmButton = Components.Button({
		Text = "Create",
		Size = UDim2.new(0.62, -4, 0, 46),
		Position = UDim2.new(0, 0, 1, -46),
		Color = Theme.Colors.Accent,
		OnClick = function()
			self:Confirm()
		end,
		Parent = content,
	})
	Components.Button({
		Text = "Leave circle",
		Size = UDim2.new(0.38, -4, 0, 46),
		Position = UDim2.new(0.62, 4, 1, -46),
		OnClick = function()
			Remotes.LeaveParty:FireServer()
			self.Window.Close()
		end,
		Parent = content,
	})

	-- Docked room panel
	local dock = Components.Frame({
		Name = "RoomPanel",
		Size = UDim2.fromOffset(280, 0),
		Position = UDim2.new(1, -16, 0.5, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Theme.Colors.Panel,
		Transparency = 0.1,
		Corner = 12,
		Visible = false,
		Parent = gui,
	})
	dock.AutomaticSize = Enum.AutomaticSize.Y
	Components.Padding(dock, 14)
	self.Dock = dock
	return self
end

-- Teleports the local character in front of the room circles.
function PartyScreen:GoToPads()
	local character = LOCAL_PLAYER.Character
	if character and not self.Ctx.Controllers.DataController.Match then
		character:PivotTo(PADS_VIEW)
	end
	self.Ctx.UI.Toast("Step into a circle to create or join a room", "Info")
end

function PartyScreen:SetPendingLevel(levelId: string, difficultyId: string?)
	self.Settings.LevelId = levelId
	if difficultyId then
		self.Settings.Difficulty = difficultyId
	end
	local party = self.Ctx.Controllers.DataController.Party.MyParty
	if party and party.HostUserId == LOCAL_PLAYER.UserId then
		self:Confirm()
	end
end

function PartyScreen:Confirm()
	task.spawn(function()
		local result = Remotes.ConfigureRoom:InvokeServer(self.Settings)
		if result and result.Success then
			self.Editing = false
			self.Confirmed = true
			self.Window.Close()
			self.Confirmed = false
		elseif result then
			self.Ctx.UI.Toast(result.Message, "Error")
		end
	end)
end

function PartyScreen:OpenSetup(editing: boolean)
	local party = self.Ctx.Controllers.DataController.Party.MyParty
	if party then
		self.Settings = {
			LevelId = party.LevelId,
			Difficulty = party.Difficulty,
			MaxSize = party.MaxSize,
			FriendsOnly = party.FriendsOnly,
		}
	end
	-- A level picked in the Levels window before stepping into a circle
	if self.Pending and not editing then
		self.Settings.LevelId = self.Pending.LevelId
		self.Settings.Difficulty = self.Pending.Difficulty
	end
	self.Pending = nil
	self.Editing = editing
	self.Window.Title.Text = if editing then "Room settings" else "Create room"
	self.ConfirmButton.SetText(if editing then "Save" else "Create")
	self:RefreshSetup()
	self.Ctx.UI.CloseWindows()
	self.Window.Open()
end

function PartyScreen:RefreshSetup()
	local data = self.Ctx.Controllers.DataController.Get()
	if not data then
		return
	end
	local settings = self.Settings
	local maxSize = self.Ctx.Controllers.DataController.Party.MaxPartySize or 4

	if #self.SizeButtons ~= maxSize then
		Components.ClearChildren(self.SizeRow, { "UIListLayout" })
		self.SizeButtons = {}
		for size = 1, maxSize do
			self.SizeButtons[size] = Components.Button({
				Text = tostring(size),
				Size = UDim2.new(1 / maxSize, -8, 1, 0),
				LayoutOrder = size,
				MaxTextSize = 16,
				OnClick = function()
					settings.MaxSize = size
					self:RefreshSetup()
				end,
				Parent = self.SizeRow,
			})
		end
	end
	for size, button in ipairs(self.SizeButtons) do
		button.SetColor(if size == settings.MaxSize then Theme.Colors.Accent else Theme.Colors.PanelLight)
	end

	self.CheckBox.BackgroundColor3 = if settings.FriendsOnly then Theme.Colors.Accent else Theme.Colors.PanelLight
	self.CheckMark.Visible = settings.FriendsOnly

	Components.ClearChildren(self.LevelGrid, { "UIGridLayout" })
	for index, level in ipairs(LevelConfig.GetOrdered()) do
		local unlocked = data.UnlockedLevels[level.LevelId] == true
		local button = Components.Button({
			Text = if unlocked then level.Name else string.format("%s  ·  Lv %d", level.Name, level.RequiredLevel),
			LayoutOrder = index,
			MaxTextSize = 14,
			OnClick = function()
				if unlocked then
					settings.LevelId = level.LevelId
					self:RefreshSetup()
				else
					self.Ctx.UI.Toast("Unlock " .. level.Name .. " in Levels first", "Error")
				end
			end,
			Parent = self.LevelGrid,
		})
		button.SetColor(if level.LevelId == settings.LevelId then Theme.Colors.Accent else Theme.Colors.PanelLight)
		if not unlocked then
			button.Label.TextColor3 = Theme.Colors.TextDim
		end
	end

	for id, button in pairs(self.DifficultyButtons) do
		local difficulty = DifficultyConfig.Get(id)
		local allowed = data.Level >= difficulty.RequiredLevel
		button.SetEnabled(allowed)
		button.SetText(if allowed then difficulty.DisplayName else difficulty.DisplayName .. " · " .. difficulty.RequiredLevel)
		if allowed then
			button.SetColor(if id == settings.Difficulty then Theme.Colors.Accent else Theme.Colors.PanelLight)
		end
	end

	local level = LevelConfig.Get(settings.LevelId)
	if level then
		self.Summary.Text = string.format(
			"%s stickers  ·  ~%s coins",
			Utility.FormatNumber(LevelConfig.GetStickerCount(level.LevelId, settings.Difficulty)),
			Utility.Abbreviate(LevelConfig.EstimateTotalReward(level.LevelId, settings.Difficulty))
		)
	end
end

function PartyScreen:RefreshDock()
	local state = self.Ctx.Controllers.DataController.Party
	local party = state.MyParty
	local dock = self.Dock
	local inMatch = self.Ctx.Controllers.DataController.Match ~= nil
	local showDock = party ~= nil and party.State == "Open" and not inMatch
	dock.Visible = showDock
	self.Ctx.UI.SetQuestsVisible(not showDock)
	if not showDock then
		self.DockSignature = nil
		return
	end

	local signature = string.format("%s|%s|%s|%d|%s|%s", party.Id, party.LevelId, party.Difficulty, party.MaxSize, tostring(party.FriendsOnly), tostring(party.HostUserId))
	for _, member in ipairs(party.Members) do
		signature ..= string.format("|%d:%d", member.UserId, member.Level)
	end
	if signature == self.DockSignature then
		return
	end
	self.DockSignature = signature
	Components.ClearChildren(dock, { "UIPadding", "UICorner", "UIStroke" })
	local list = Components.Create("Frame", { Name = "List", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = dock })
	Components.List(list, Enum.FillDirection.Vertical, 8)

	local isHost = party.HostUserId == LOCAL_PLAYER.UserId
	local level = LevelConfig.Get(party.LevelId)
	local difficulty = DifficultyConfig.Get(party.Difficulty)

	Components.Label({ Text = "Room " .. tostring(party.PadIndex), Size = UDim2.new(1, 0, 0, 22), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Title, MaxTextSize = 18, LayoutOrder = 1, Parent = list })
	Components.Label({
		Text = string.format("%s  ·  %s  ·  %d/%d%s", level and level.Name or "?", difficulty and difficulty.DisplayName or "?", #party.Members, party.MaxSize, if party.FriendsOnly then "  ·  Friends" else ""),
		Size = UDim2.new(1, 0, 0, 18),
		XAlign = Enum.TextXAlignment.Left,
		Font = Theme.Fonts.Bold,
		Color = Theme.Colors.TextDim,
		MaxTextSize = 13,
		LayoutOrder = 2,
		Parent = list,
	})

	for index, member in ipairs(party.Members) do
		local row = Components.Create("Frame", { Name = "Member", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 10 + index, Parent = list })
		Components.Avatar(member.UserId, { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(0, 2), Parent = row })
		Components.Label({ Text = member.DisplayName, Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(40, 0), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, MaxTextSize = 15, Parent = row })
		Components.Label({ Text = if member.IsHost then "Host" else "Lv " .. member.Level, Size = UDim2.fromOffset(44, 34), Position = UDim2.new(1, -78, 0, 0), XAlign = Enum.TextXAlignment.Right, Font = Theme.Fonts.Bold, Color = if member.IsHost then Theme.Colors.Accent else Theme.Colors.TextDim, MaxTextSize = 13, Parent = row })
		if isHost and not member.IsHost then
			local kick = Components.Create("TextButton", { Text = "✕", Font = Theme.Fonts.Title, TextSize = 16, TextColor3 = Theme.Colors.TextDim, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 34), Position = UDim2.new(1, -28, 0, 0), Parent = row })
			kick.Activated:Connect(function()
				task.spawn(function()
					local result = Remotes.PartyAction:InvokeServer("Kick", member.UserId)
					if result and not result.Success then
						self.Ctx.UI.Toast(result.Message, "Error")
					end
				end)
			end)
		end
	end
	for slot = #party.Members + 1, party.MaxSize do
		Components.Label({ Text = "Waiting for player…", Size = UDim2.new(1, 0, 0, 22), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Body, Color = Theme.Colors.TextDim, MaxTextSize = 13, LayoutOrder = 10 + slot, Parent = list })
	end

	local buttons = Components.Create("Frame", { Name = "Buttons", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 50, Parent = list })
	if isHost then
		Components.Button({
			Text = "Start",
			Size = UDim2.new(0.5, -4, 1, 0),
			Color = Theme.Colors.Accent,
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
		Components.Button({
			Text = "Edit",
			Size = UDim2.new(0.25, -4, 1, 0),
			Position = UDim2.new(0.5, 4, 0, 0),
			OnClick = function()
				self:OpenSetup(true)
			end,
			Parent = buttons,
		})
		Components.Button({
			Text = "Leave",
			Size = UDim2.new(0.25, -4, 1, 0),
			Position = UDim2.new(0.75, 4, 0, 0),
			OnClick = function()
				Remotes.LeaveParty:FireServer()
			end,
			Parent = buttons,
		})
	else
		Components.Label({ Text = "Waiting for the host to start", Size = UDim2.new(0.62, -4, 1, 0), XAlign = Enum.TextXAlignment.Left, Font = Theme.Fonts.Bold, Color = Theme.Colors.TextDim, MaxTextSize = 13, Parent = buttons })
		Components.Button({
			Text = "Leave",
			Size = UDim2.new(0.38, -4, 1, 0),
			Position = UDim2.new(0.62, 4, 0, 0),
			OnClick = function()
				Remotes.LeaveParty:FireServer()
			end,
			Parent = buttons,
		})
	end
end

function PartyScreen:Update()
	local party = self.Ctx.Controllers.DataController.Party.MyParty
	local isHost = party and party.HostUserId == LOCAL_PLAYER.UserId
	-- First step into an empty circle: open the setup panel for the host
	if party and isHost and party.State == "Setup" then
		if not self.Window.IsOpen() then
			self:OpenSetup(false)
		end
	elseif self.Window.IsOpen() and (not party or not isHost or (party.State ~= "Setup" and not self.Editing)) then
		self.Window.Close()
	end
	self:RefreshDock()
end

return PartyScreen
