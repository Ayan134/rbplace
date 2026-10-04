--[[
	Components
	Small UI building blocks used by every screen (code-built UI that scales on any device).
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Components = {}

local soundManager = nil

function Components.SetSoundManager(manager)
	soundManager = manager
end

local function playSound(name: string)
	if soundManager then
		soundManager.Play(name)
	end
end

-- Generic instance factory: Create("Frame", { Size = ..., Parent = ... }, { children })
function Components.Create(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	local parent = nil
	if props then
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			else
				(instance :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local Create = Components.Create

function Components.Corner(parent: Instance, radius: number?): UICorner
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Corner), Parent = parent })
end

function Components.Round(parent: Instance): UICorner
	return Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = parent })
end

function Components.Stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Create("UIStroke", {
		Color = color or Theme.Colors.Stroke,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Components.TextStroke(parent: Instance, thickness: number?): UIStroke
	return Create("UIStroke", {
		Color = Color3.fromRGB(30, 20, 50),
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = parent,
	})
end

function Components.Gradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?): UIGradient
	return Create("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = rotation or 90,
		Parent = parent,
	})
end

function Components.Padding(parent: Instance, all: number, horizontal: number?): UIPadding
	local h = horizontal or all
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, h),
		PaddingRight = UDim.new(0, h),
		Parent = parent,
	})
end

function Components.List(parent: Instance, direction: Enum.FillDirection?, padding: number?, hAlign: Enum.HorizontalAlignment?, vAlign: Enum.VerticalAlignment?): UIListLayout
	return Create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 8),
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function Components.Frame(props: { [string]: any }): Frame
	local frame = Create("Frame", {
		BackgroundColor3 = props.Color or Theme.Colors.Panel,
		BackgroundTransparency = props.Transparency or 0,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		Name = props.Name or "Frame",
		Visible = if props.Visible == nil then true else props.Visible,
		ZIndex = props.ZIndex or 1,
		ClipsDescendants = props.Clips or false,
		Parent = props.Parent,
	})
	if props.Corner ~= false then
		Components.Corner(frame, props.Corner)
	end
	if props.Stroke then
		Components.Stroke(frame, props.StrokeColor, props.Stroke)
	end
	if props.Gradient then
		Components.Gradient(frame, props.Gradient[1], props.Gradient[2], props.Gradient[3])
	end
	return frame
end

function Components.Label(props: { [string]: any }): TextLabel
	local label = Create("TextLabel", {
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Text = props.Text or "",
		Font = props.Font or Theme.Fonts.Title,
		TextColor3 = props.Color or Theme.Colors.Text,
		TextScaled = if props.TextSize then false else true,
		TextSize = props.TextSize or 14,
		TextWrapped = true,
		RichText = props.RichText or false,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Visible = if props.Visible == nil then true else props.Visible,
		Parent = props.Parent,
	})
	if props.MaxTextSize then
		Create("UITextSizeConstraint", { MaxTextSize = props.MaxTextSize, MinTextSize = props.MinTextSize or 6, Parent = label })
	end
	if props.Stroke then
		Components.TextStroke(label, props.Stroke)
	end
	return label
end

export type Button = {
	Instance: TextButton,
	Label: TextLabel,
	SetEnabled: (enabled: boolean) -> (),
	SetText: (text: string) -> (),
	SetColor: (color: Color3) -> (),
}

-- Big candy-style button with hover/press animation and click sound.
function Components.Button(props: { [string]: any }): Button
	local color: Color3 = props.Color or Theme.Colors.Pink
	local button = Create("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(160, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Visible = if props.Visible == nil then true else props.Visible,
		Parent = props.Parent,
	})
	Components.Corner(button, props.Corner or 12)
	local gradient = Components.Gradient(button, Theme.Lighten(color, 0.15), Theme.Darken(color, 0.15))
	local stroke = Components.Stroke(button, Theme.Darken(color, 0.45), 2.5)
	local scale = Create("UIScale", { Parent = button })
	local label = Components.Label({
		Name = "Text",
		Text = props.Text or "",
		Size = UDim2.new(1, -12, 1, -10),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Font = props.Font or Theme.Fonts.Title,
		Color = props.TextColor or Theme.Colors.Text,
		MaxTextSize = props.MaxTextSize or 26,
		Stroke = 1.5,
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = button,
	})

	local enabled = true
	local hovered = false
	local function refresh()
		local target = if not enabled then 1 elseif hovered then 1.05 else 1
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = target }):Play()
	end
	local function applyColor(c: Color3)
		color = c
		local shown = if enabled then c else Theme.Colors.Grey
		gradient.Color = ColorSequence.new(Theme.Lighten(shown, 0.15), Theme.Darken(shown, 0.15))
		stroke.Color = Theme.Darken(shown, 0.45)
	end
	button.MouseEnter:Connect(function()
		hovered = true
		refresh()
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		refresh()
	end)
	button.MouseButton1Down:Connect(function()
		if enabled then
			TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.94 }):Play()
		end
	end)
	button.MouseButton1Up:Connect(refresh)
	button.Activated:Connect(function()
		if not enabled then
			playSound("Error")
			return
		end
		playSound("ButtonClick")
		refresh()
		if props.OnClick then
			props.OnClick()
		end
	end)

	return {
		Instance = button,
		Label = label,
		SetEnabled = function(value: boolean)
			enabled = value
			applyColor(color)
			refresh()
		end,
		SetText = function(text: string)
			label.Text = text
		end,
		SetColor = function(c: Color3)
			applyColor(c)
		end,
	}
end

export type ProgressBar = {
	Instance: Frame,
	Fill: Frame,
	Label: TextLabel,
	Set: (fraction: number, text: string?, animate: boolean?) -> (),
}

function Components.ProgressBar(props: { [string]: any }): ProgressBar
	local background = Components.Frame({
		Name = props.Name or "ProgressBar",
		Size = props.Size or UDim2.new(1, 0, 0, 20),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Color = props.BackgroundColor or Theme.Colors.PanelDark,
		Corner = props.Corner or 100,
		LayoutOrder = props.LayoutOrder,
		Stroke = props.Stroke,
		StrokeColor = props.StrokeColor,
		Clips = true,
		Parent = props.Parent,
	})
	local fill = Components.Frame({
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Color = Color3.new(1, 1, 1),
		Corner = props.Corner or 100,
		Parent = background,
	})
	local color: Color3 = props.Color or Theme.Colors.Green
	Components.Gradient(fill, Theme.Lighten(color, 0.2), Theme.Darken(color, 0.1))
	local label = Components.Label({
		Name = "Text",
		Text = "",
		Size = UDim2.new(1, -10, 1, -4),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = props.MaxTextSize or 20,
		Stroke = 1.5,
		ZIndex = 3,
		Parent = background,
	})
	return {
		Instance = background,
		Fill = fill,
		Label = label,
		Set = function(fraction: number, text: string?, animate: boolean?)
			local size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
			if animate == false then
				fill.Size = size
			else
				TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = size }):Play()
			end
			if text then
				label.Text = text
			end
		end,
	}
end

-- Rounded pill with an icon and value ("🪙 12,450")
function Components.Pill(props: { [string]: any })
	local pill = Components.Frame({
		Name = props.Name or "Pill",
		Size = props.Size or UDim2.fromOffset(170, 44),
		Color = Theme.Colors.PanelDark,
		Transparency = 0.1,
		Corner = 100,
		Stroke = 2.5,
		StrokeColor = props.Color or Theme.Colors.Stroke,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
	})
	local icon = Components.Label({
		Name = "Icon",
		Text = props.Icon or "",
		Size = UDim2.new(0, 36, 1, -8),
		Position = UDim2.fromOffset(6, 4),
		Font = Theme.Fonts.Title,
		Parent = pill,
	})
	local value = Components.Label({
		Name = "Value",
		Text = props.Text or "0",
		Size = UDim2.new(1, -52, 1, -10),
		Position = UDim2.fromOffset(44, 5),
		XAlign = Enum.TextXAlignment.Left,
		Color = props.Color or Theme.Colors.Text,
		MaxTextSize = 26,
		Stroke = 1.5,
		Parent = pill,
	})
	return { Instance = pill, Icon = icon, Value = value }
end

function Components.Avatar(userId: number, props: { [string]: any }): ImageLabel
	local image = Create("ImageLabel", {
		Name = "Avatar",
		Size = props.Size or UDim2.fromOffset(48, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = props.Background or Theme.Colors.PanelLight,
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId),
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	Components.Round(image)
	if props.StrokeColor then
		Components.Stroke(image, props.StrokeColor, 2.5)
	end
	return image
end

-- 3D model preview. `rotate` spins it while the viewport is visible.
function Components.Viewport(model: Model?, props: { [string]: any }): ViewportFrame
	local viewport = Create("ViewportFrame", {
		Name = "Viewport",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundTransparency = if props.Background then 0 else 1,
		BackgroundColor3 = props.Background or Color3.new(),
		Ambient = Color3.fromRGB(170, 170, 190),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-1, -1.4, -0.6),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	if props.Background then
		Components.Corner(viewport, props.Corner)
	end
	if not model then
		return viewport
	end
	local clone = model:Clone()
	clone.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local cf, size = clone:GetBoundingBox()
	local radius = size.Magnitude / 2
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * (props.Zoom or 1.0)
	local center = cf.Position
	local pitch = math.rad(props.Pitch or 25)
	local angle = math.rad(props.Yaw or 35)
	local function place()
		local offset = Vector3.new(math.sin(angle) * math.cos(pitch), math.sin(pitch), math.cos(angle) * math.cos(pitch)) * distance
		camera.CFrame = CFrame.lookAt(center + offset, center)
	end
	place()
	if props.Rotate then
		local connection
		connection = RunService.RenderStepped:Connect(function(dt)
			if not viewport.Parent then
				connection:Disconnect()
				return
			end
			if viewport.Visible and viewport:FindFirstAncestorWhichIsA("LayerCollector") then
				angle += dt * (props.RotateSpeed or 0.5)
				place()
			end
		end)
	end
	return viewport
end

export type Window = {
	Gui: Frame,
	Content: Frame,
	Title: TextLabel,
	Open: () -> (),
	Close: () -> (),
	IsOpen: () -> boolean,
}

-- Modal window with a title bar and close button.
function Components.Window(screenGui: ScreenGui, props: { [string]: any }): Window
	local accent: Color3 = props.Color or Theme.Colors.Pink
	local holder = Create("Frame", {
		Name = props.Name or "Window",
		Size = props.Size or UDim2.fromOffset(860, 540),
		Position = UDim2.fromScale(0.5, 0.52),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screenGui,
	})
	local scale = Create("UIScale", { Parent = holder })
	local panel = Components.Frame({
		Name = "Panel",
		Color = Theme.Colors.Panel,
		Corner = 20,
		Stroke = 4,
		StrokeColor = Theme.Darken(accent, 0.3),
		Gradient = { Theme.Colors.PanelLight, Theme.Colors.Panel, 90 },
		Parent = holder,
	})
	local header = Components.Frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 64),
		Color = Color3.new(1, 1, 1),
		Corner = 20,
		Gradient = { Theme.Lighten(accent, 0.1), Theme.Darken(accent, 0.15), 90 },
		Parent = panel,
	})
	-- Square off the header's bottom corners
	Components.Frame({ Name = "HeaderFill", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), Color = Color3.new(1, 1, 1), Corner = false, Gradient = { Theme.Darken(accent, 0.1), Theme.Darken(accent, 0.15), 90 }, Parent = header })
	local title = Components.Label({
		Name = "Title",
		Text = props.Title or "",
		Size = UDim2.new(1, -140, 0, 46),
		Position = UDim2.fromOffset(24, 9),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 36,
		Stroke = 2.5,
		ZIndex = 2,
		Parent = header,
	})
	local content = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -32, 1, -84),
		Position = UDim2.fromOffset(16, 72),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	local isOpen = false
	local window: Window
	local closeButton = Components.Button({
		Name = "Close",
		Text = "✕",
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(1, -56, 0, 9),
		Color = Theme.Colors.Red,
		ZIndex = 3,
		OnClick = function()
			window.Close()
		end,
		Parent = header,
	})
	closeButton.Instance.ZIndex = 3

	window = {
		Gui = holder,
		Content = content,
		Title = title,
		Open = function()
			if isOpen then
				return
			end
			isOpen = true
			holder.Visible = true
			scale.Scale = 0.85
			TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			playSound("Open")
			if props.OnOpen then
				props.OnOpen()
			end
		end,
		Close = function()
			if not isOpen then
				return
			end
			isOpen = false
			holder.Visible = false
			if props.OnClose then
				props.OnClose()
			end
		end,
		IsOpen = function()
			return isOpen
		end,
	}
	return window
end

function Components.Scroll(props: { [string]: any }): ScrollingFrame
	return Create("ScrollingFrame", {
		Name = props.Name or "Scroll",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Theme.Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = props.Automatic or Enum.AutomaticSize.Y,
		ScrollingDirection = props.Direction or Enum.ScrollingDirection.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
end

function Components.ClearChildren(parent: Instance, keepClass: { string }?)
	for _, child in ipairs(parent:GetChildren()) do
		local keep = false
		if keepClass then
			for _, className in ipairs(keepClass) do
				if child:IsA(className) then
					keep = true
					break
				end
			end
		end
		if not keep then
			child:Destroy()
		end
	end
end

-- Pops a GuiObject in with a bouncy scale animation.
function Components.Pop(guiObject: GuiObject, from: number?)
	local scale = guiObject:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = guiObject })
	scale.Scale = from or 0.6
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function Components.Stars(count: number, max: number?): string
	local text = ""
	for i = 1, max or 5 do
		text ..= if i <= count then "★" else "☆"
	end
	return text
end

return Components
