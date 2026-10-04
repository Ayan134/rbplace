--[[
	NotificationScreen (NotificationUI)
	Toasts, big center announcements ("✨ RARE STICKER FOUND!", "LEVEL UP!") and
	a confirm dialog.
]]

local TweenService = game:GetService("TweenService")

local UI = script.Parent.Parent
local Components = require(UI.Components)
local Theme = require(UI.Theme)

local NotificationScreen = {}
NotificationScreen.__index = NotificationScreen

local KIND_COLORS = {
	Info = Theme.Colors.Blue,
	Success = Theme.Colors.Green,
	Error = Theme.Colors.Red,
	Rare = Theme.Colors.Purple,
	Reward = Theme.Colors.Yellow,
}

local MAX_TOASTS = 4

function NotificationScreen.new(gui: ScreenGui, ctx)
	local self = setmetatable({}, NotificationScreen)
	self.Gui = gui
	self.Ctx = ctx
	gui.DisplayOrder = 30

	local stack = Components.Create("Frame", {
		Name = "Toasts",
		Size = UDim2.fromOffset(560, 300),
		Position = UDim2.new(0.5, 0, 0, 216),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Components.List(stack, Enum.FillDirection.Vertical, 6)
	self.Stack = stack
	self.Count = 0

	self.Announcement = Components.Create("Frame", {
		Name = "Announcement",
		Size = UDim2.fromOffset(760, 150),
		Position = UDim2.fromScale(0.5, 0.36),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	self.AnnounceTitle = Components.Label({ Text = "", Size = UDim2.new(1, 0, 0, 70), MaxTextSize = 54, Stroke = 1, Parent = self.Announcement })
	self.AnnounceSubtitle = Components.Label({ Text = "", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 74), Font = Theme.Fonts.Bold, MaxTextSize = 20, Stroke = 1, Parent = self.Announcement })
	Components.Create("UIScale", { Parent = self.Announcement })
	self.AnnounceToken = 0

	-- Confirm dialog
	local confirm = Components.Frame({
		Name = "Confirm",
		Size = UDim2.fromOffset(480, 220),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = Theme.Colors.Panel,
		Corner = 18,
		Stroke = 3,
		StrokeColor = Theme.Colors.Pink,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	self.ConfirmText = Components.Label({ Text = "", Size = UDim2.new(1, -40, 0, 110), Position = UDim2.fromOffset(20, 16), Font = Theme.Fonts.Bold, MaxTextSize = 22, ZIndex = 21, Parent = confirm })
	self.ConfirmYes = Components.Button({ Text = "YES", Size = UDim2.new(0.5, -30, 0, 54), Position = UDim2.new(0, 20, 1, -72), Color = Theme.Colors.Green, ZIndex = 21, OnClick = function()
		confirm.Visible = false
		if self.OnConfirm then
			self.OnConfirm()
		end
	end, Parent = confirm })
	Components.Button({ Text = "CANCEL", Size = UDim2.new(0.5, -30, 0, 54), Position = UDim2.new(0.5, 10, 1, -72), Color = Theme.Colors.Red, ZIndex = 21, OnClick = function()
		confirm.Visible = false
	end, Parent = confirm })
	self.ConfirmFrame = confirm
	return self
end

function NotificationScreen:Toast(text: string, kind: string?)
	local color = KIND_COLORS[kind or "Info"] or Theme.Colors.Blue
	if self.Count >= MAX_TOASTS then
		local oldest = nil
		for _, child in ipairs(self.Stack:GetChildren()) do
			if child:IsA("Frame") and (not oldest or child.LayoutOrder < oldest.LayoutOrder) then
				oldest = child
			end
		end
		if oldest then
			oldest:Destroy()
			self.Count -= 1
		end
	end
	self.Count += 1
	self.Order = (self.Order or 0) + 1
	local toast = Components.Frame({
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 44),
		Color = Theme.Colors.PanelDark,
		Transparency = 0.08,
		Corner = 12,
		Stroke = 2.5,
		StrokeColor = color,
		LayoutOrder = self.Order,
		Parent = self.Stack,
	})
	Components.Label({ Text = text, Size = UDim2.new(1, -24, 1, -10), Position = UDim2.fromOffset(12, 5), Font = Theme.Fonts.Bold, MaxTextSize = 19, Stroke = 1.5, Parent = toast })
	Components.Pop(toast, 0.8)
	if kind == "Error" then
		self.Ctx.Controllers.SoundManager.Play("Error")
	end
	task.delay(3.2, function()
		if toast.Parent then
			local fade = TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
			fade:Play()
			for _, descendant in ipairs(toast:GetDescendants()) do
				if descendant:IsA("TextLabel") then
					TweenService:Create(descendant, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
				elseif descendant:IsA("UIStroke") then
					TweenService:Create(descendant, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				end
			end
			fade.Completed:Wait()
			if toast.Parent then
				toast:Destroy()
				self.Count -= 1
			end
		end
	end)
end

function NotificationScreen:Announce(title: string, subtitle: string?, color: Color3?, duration: number?)
	self.AnnounceToken += 1
	local token = self.AnnounceToken
	local frame = self.Announcement
	self.AnnounceTitle.Text = title
	self.AnnounceTitle.TextColor3 = color or Theme.Colors.Yellow
	self.AnnounceTitle.TextTransparency = 0
	self.AnnounceSubtitle.Text = subtitle or ""
	self.AnnounceSubtitle.TextTransparency = 0
	frame.Visible = true
	Components.Pop(frame, 0.3)
	task.delay(duration or 2.2, function()
		if token ~= self.AnnounceToken then
			return
		end
		TweenService:Create(self.AnnounceTitle, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		local fade = TweenService:Create(self.AnnounceSubtitle, TweenInfo.new(0.4), { TextTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		if token == self.AnnounceToken then
			frame.Visible = false
		end
	end)
end

function NotificationScreen:Confirm(text: string, onConfirm: () -> ())
	self.ConfirmText.Text = text
	self.OnConfirm = onConfirm
	self.ConfirmFrame.Visible = true
	Components.Pop(self.ConfirmFrame, 0.8)
end

return NotificationScreen
