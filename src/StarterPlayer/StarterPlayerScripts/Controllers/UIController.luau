--[[
	UIController
	Owns every screen and switches between game modes:
	  Lobby   -> LobbyUI (+ windows: PLAY, LEVELS, INVENTORY, UPGRADES, SHOP, SETTINGS, PROFILE)
	  Loading -> LoadingUI
	  Game    -> GameplayUI
	  Results -> ResultsUI
	It also scales all UI to the screen size (PC, tablet, phone).
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared.Rarity)
local StickerConfig = require(Shared.StickerConfig)
local Utility = require(Shared.Utility)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UIFolder = script.Parent.Parent:WaitForChild("UI")
local Components = require(UIFolder.Components)
local Theme = require(UIFolder.Theme)
local ScreensFolder = UIFolder:WaitForChild("Screens")

local LOCAL_PLAYER = Players.LocalPlayer

local UIController = {}

UIController.Mode = "Lobby"

local Controllers
local screens: { [string]: any } = {}
local windows: { [string]: any } = {}
local managedGuis: { ScreenGui } = {}
local playerGui: PlayerGui

local function getGui(name: string): ScreenGui
	-- StarterGui contents are copied into PlayerGui once the character first spawns,
	-- which happens after the server has loaded our data.
	local deadline = os.clock() + 60
	local gui = playerGui:FindFirstChild(name)
	while not gui and os.clock() < deadline do
		task.wait(0.2)
		gui = playerGui:FindFirstChild(name)
	end
	if not gui then
		-- Fallback so the game still works if a ScreenGui is missing from StarterGui
		local created = Instance.new("ScreenGui")
		created.Name = name
		created.ResetOnSpawn = false
		created.Parent = playerGui
		gui = created
	end
	local screenGui = gui :: ScreenGui
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if not screenGui:FindFirstChildOfClass("UIScale") then
		Instance.new("UIScale").Parent = screenGui
	end
	table.insert(managedGuis, screenGui)
	return screenGui
end

local function computeScale(): number
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1500, 860)
	local scale = math.min(viewport.X / 1500, viewport.Y / 860)
	if UserInputService.TouchEnabled and math.min(viewport.X, viewport.Y) < 520 then
		scale *= 1.12 -- phones: slightly bigger touch targets
	end
	return math.clamp(scale, 0.42, 1.25)
end

local function applyScale()
	local scale = computeScale()
	for _, gui in ipairs(managedGuis) do
		local uiScale = gui:FindFirstChildOfClass("UIScale")
		if uiScale then
			uiScale.Scale = scale
		end
	end
end

function UIController.Toast(text: string, kind: string?)
	if screens.Notification then
		screens.Notification:Toast(text, kind)
	end
end

function UIController.Announce(title: string, subtitle: string?, color: Color3?, duration: number?)
	if screens.Notification then
		screens.Notification:Announce(title, subtitle, color, duration)
	end
end

function UIController.Confirm(text: string, onConfirm: () -> ())
	screens.Notification:Confirm(text, onConfirm)
end

function UIController.CloseWindows(except: string?)
	for name, screen in pairs(windows) do
		if name ~= except and screen.Window.IsOpen() then
			screen.Window.Close()
		end
	end
end

function UIController.OpenWindow(name: string)
	if UIController.Mode ~= "Lobby" then
		return
	end
	if name == "Party" then
		screens.Party:GoToPads()
		return
	end
	local screen = windows[name]
	if not screen then
		return
	end
	UIController.CloseWindows(name)
	screen.Window.Open()
end

function UIController.ToggleWindow(name: string)
	if name == "Party" then
		screens.Party:GoToPads()
		return
	end
	local screen = windows[name]
	if screen and screen.Window.IsOpen() then
		screen.Window.Close()
	else
		UIController.OpenWindow(name)
	end
end

function UIController.OpenPartyWithLevel(levelId: string, difficultyId: string)
	local party = Controllers.DataController.Party.MyParty
	if party and party.HostUserId == LOCAL_PLAYER.UserId then
		screens.Party:SetPendingLevel(levelId, difficultyId)
		UIController.CloseWindows()
	elseif party then
		UIController.Toast("Only the HOST can change the level", "Error")
	else
		screens.Party.Pending = { LevelId = levelId, Difficulty = difficultyId }
		UIController.CloseWindows()
		screens.Party:GoToPads()
	end
end

function UIController.SetQuestsVisible(visible: boolean)
	if screens.Lobby then
		screens.Lobby:SetQuestsVisible(visible)
	end
end

local function setMode(mode: string)
	UIController.Mode = mode
	local lobby = mode == "Lobby"
	screens.Lobby:SetVisible(lobby)
	screens.Party.Gui.Enabled = lobby
	if not lobby then
		UIController.CloseWindows()
		screens.Party.Window.Close()
	end
	for _, name in ipairs({ "Levels", "Inventory", "Upgrades", "Shop", "Settings", "Profile" }) do
		windows[name].Gui.Enabled = lobby
	end
	Controllers.InteractionController.Enabled = mode == "Lobby" or mode == "Game"
	if mode ~= "Game" and mode ~= "Lobby" then
		Controllers.InteractionController.ReleaseAll()
	end
	if lobby then
		screens.Gameplay:Hide()
		screens.Results:Hide()
		screens.Party:Update()
		Controllers.SoundManager.PlayTheme("Lobby")
	elseif mode == "Game" then
		local match = Controllers.DataController.Match
		Controllers.SoundManager.PlayTheme(match and match.LevelId)
	end
end

local function onDataChanged(data)
	if not data then
		return
	end
	screens.Lobby:Update(data)
	screens.Gameplay:UpdateData(data)
	for _, screen in pairs(windows) do
		if screen.Update then
			screen:Update(data)
		end
	end
	if screens.Party.Window.IsOpen() then
		screens.Party:RefreshSetup()
	end
end

local function onMatchEvent(eventName: string, payload)
	if eventName == "Loading" then
		setMode("Loading")
		screens.Loading:Show(payload.LevelId, payload.Difficulty, payload.Total)
	elseif eventName == "Start" then
		screens.Loading:Hide()
		setMode("Game")
		screens.Gameplay:Show(Controllers.DataController.Match or payload)
		Controllers.SoundManager.Play("Countdown")
		UIController.Announce("Peel!", "Clean the whole object together", Theme.Colors.Accent, 1.6)
	elseif eventName == "Team" then
		screens.Gameplay:UpdateTeam(payload.Team)
	elseif eventName == "Complete" then
		setMode("Results")
		Controllers.SoundManager.PlayMusic("ResultsMusic")
		Controllers.SoundManager.Duck(4, 0.15)
		screens.Gameplay:StopTimer()
		Controllers.SoundManager.Play("LevelComplete")
		Controllers.EffectsController.Confetti(90)
		Controllers.EffectsController.Fireworks(Controllers.DataController.Match and Controllers.DataController.Match.Focus)
		Controllers.AnimationController.Celebrate()
		UIController.Announce("Object cleaned", payload.LevelName, Theme.Colors.Yellow, 2.4)
		task.delay(2.6, function()
			if UIController.Mode == "Results" then
				screens.Gameplay:Hide()
				screens.Results:Show(payload)
			end
		end)
	elseif eventName == "Ended" then
		screens.Loading.Gui.Enabled = false
		setMode("Lobby")
	end
end

local function onEffect(effectName: string, payload)
	if effectName == "LevelUp" then
		Controllers.SoundManager.Play("LevelUp")
		Controllers.SoundManager.Duck(2.5)
		Controllers.EffectsController.Confetti(60)
		UIController.Announce("Level up", string.format("Level %d  ·  +%d gems", payload.Level, payload.Gems), Theme.Colors.XP, 2.6)
		for _, unlock in ipairs(payload.Unlocks or {}) do
			UIController.Toast("Unlocked " .. unlock, "Success")
		end
	elseif effectName == "RareFound" then
		local info = StickerConfig.Get(payload.Type)
		if info then
			local color = Rarity.Color(info.Rarity)
			Controllers.SoundManager.Play("RareSticker")
			Controllers.EffectsController.Flash(color, 0.25)
			local subtitle = info.DisplayName .. "  •  +" .. Utility.FormatNumber(payload.Coins) .. " Coins"
			if payload.Gems and payload.Gems > 0 then
				subtitle ..= "  +" .. payload.Gems .. " gems"
			end
			UIController.Announce("✨ RARE STICKER FOUND!", subtitle, color, 2.2)
		end
	end
end

function UIController.Init(controllers)
	Controllers = controllers
end

function UIController.Start()
	playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui") :: PlayerGui
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	Components.SetSoundManager(Controllers.SoundManager)
	Components.WindowsChanged = function(count: number)
		Controllers.LightingController.SetBlur(count > 0)
	end

	local ctx = { Controllers = Controllers, UI = UIController }
	local function load(name: string)
		return require(ScreensFolder:WaitForChild(name))
	end

	screens.Notification = load("NotificationScreen").new(getGui("NotificationUI"), ctx)
	screens.Lobby = load("LobbyHUD").new(getGui("LobbyUI"), ctx)
	screens.Party = load("PartyScreen").new(getGui("PartyUI"), ctx)
	screens.Levels = load("LevelSelectScreen").new(getGui("LevelSelectUI"), ctx)
	screens.Inventory = load("InventoryScreen").new(getGui("InventoryUI"), ctx)
	screens.Upgrades = load("UpgradeScreen").new(getGui("UpgradeUI"), ctx)
	screens.Shop = load("ShopScreen").new(getGui("ShopUI"), ctx)
	screens.Settings = load("SettingsScreen").new(getGui("SettingsUI"), ctx)
	screens.Profile = load("ProfileScreen").new(getGui("ProfileUI"), ctx)
	screens.Gameplay = load("GameplayScreen").new(getGui("GameplayUI"), ctx)
	screens.Loading = load("LoadingScreen").new(getGui("LoadingUI"), ctx)
	screens.Results = load("ResultsScreen").new(getGui("ResultsUI"), ctx)

	UIController.Screens = screens -- exposed for debugging and automated tests

	windows = {
		Levels = screens.Levels,
		Inventory = screens.Inventory,
		Upgrades = screens.Upgrades,
		Shop = screens.Shop,
		Settings = screens.Settings,
		Profile = screens.Profile,
	}

	applyScale()
	local function watchCamera()
		local camera = Workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
		end
		applyScale()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()

	local DataController = Controllers.DataController
	DataController.Changed:Connect(onDataChanged)
	DataController.PartyChanged:Connect(function()
		screens.Party:Update()
	end)
	DataController.MatchEvent:Connect(onMatchEvent)
	onDataChanged(DataController.Get())

	Remotes.Notify.OnClientEvent:Connect(function(payload)
		UIController.Toast(payload.Text, payload.Kind)
		if payload.Kind == "Rare" then
			Controllers.SoundManager.Play("RareSticker", { PlaybackSpeed = 1 })
		end
	end)
	Remotes.Effect.OnClientEvent:Connect(onEffect)

	-- Lobby kiosks / portal open their windows
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local target = prompt:GetAttribute("OpenUI")
		if type(target) == "string" then
			UIController.OpenWindow(target)
		end
	end)

	-- Loading progress follows real sticker data
	local renderer = Controllers.StickerRenderer
	renderer.LoadProgress:Connect(function(session, received, total)
		if UIController.Mode == "Loading" and session.Kind == "Match" then
			screens.Loading:SetProgress(0.1 + 0.8 * received / math.max(total, 1))
		end
	end)
	renderer.SessionReady:Connect(function(session)
		if UIController.Mode == "Loading" and session.Kind == "Match" then
			screens.Loading:SetProgress(1, "Get ready...")
		end
	end)

	Controllers.PeelController.RewardReceived:Connect(function(reward)
		if UIController.Mode == "Game" then
			screens.Gameplay:OnLocalPeel()
			screens.Gameplay:ShowCombo(reward.Combo or 0, reward.ComboMultiplier or 1)
		end
	end)

	-- Escape-style close for windows (B on gamepad)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.ButtonB then
			UIController.CloseWindows()
		end
	end)

	setMode("Lobby")
	task.delay(2, function()
		if DataController.IsLoaded() then
			local data = DataController.Get()
			if data.Statistics.StickersPeeled == 0 then
				UIController.Announce("STICKER PEEL", "Peel every sticker off giant objects with your friends!", Theme.Colors.Pink, 3.5)
			end
		end
	end)
end

return UIController
