--[[
	Components
	UI building blocks used by every screen (code-built UI that scales on any device).
	Cartoon simulator style: thick dark outlines, gradient fills, buttons with a 3D lip,
	FredokaOne text with an outline.
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

-- Thick dark outline around a surface
function Components.Stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Create("UIStroke", {
		Color = color or Theme.Colors.Outline,
		Thickness = thickness or Theme.OutlineThickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

-- Cartoon text outline
function Components.TextStroke(parent: Instance, thickness: number?): UIStroke
	return Create("UIStroke", {
		Color = Theme.Colors.Outline,
		Thickness = math.max(1.5, thickness or 2),
		Transparency = 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
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

--[[
	Panel. props: Size, Position, AnchorPoint, Color, Transparency, Corner (number|false),
	Stroke (thickness), StrokeColor, Gradient = { top, bottom, rotation? }, Clips, ...
	Panels get a soft vertical shade unless Flat = true.
]]
function Components.Frame(props: { [string]: any }): Frame
	local color = props.Color or Theme.Colors.Panel
	local frame = Create("Frame", {
		BackgroundColor3 = if props.Gradient then Color3.new(1, 1, 1) else color,
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
		Components.Stroke(frame, props.StrokeColor, math.max(2, props.Stroke))
	end
	if props.Gradient then
		local g = props.Gradient
		Components.Gradient(frame, g[1], g[2], g[3])
	elseif not props.Flat and (props.Transparency or 0) < 0.5 then
		Create("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 210, 228)),
			Rotation = 90,
			Parent = frame,
		})
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

local LIP = 4

--[[
	Chunky button: colored face with a gradient, a darker lip underneath, a thick outline
	and outlined text. props: Text, Size, Position, AnchorPoint, Color, OnClick, Icon,
	MaxTextSize, LayoutOrder, ZIndex, Visible, Parent.
]]
function Components.Button(props: { [string]: any }): Button
	local color: Color3 = props.Color or Theme.Colors.Blue
	if color == Theme.Colors.PanelLight or color == Theme.Colors.Panel then
		color = Theme.Colors.Blue
	end
	local zIndex = props.ZIndex or 1
	local button = Create("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(160, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = zIndex,
		Visible = if props.Visible == nil then true else props.Visible,
		Parent = props.Parent,
	})
	local scale = Create("UIScale", { Parent = button })
	local corner = props.Corner or 12
	local lip = Create("Frame", {
		Name = "Lip",
		Size = UDim2.new(1, 0, 1, -LIP),
		Position = UDim2.fromOffset(0, LIP),
		BackgroundColor3 = Theme.Darken(color, 0.38),
		BorderSizePixel = 0,
		ZIndex = zIndex,
		Parent = button,
	})
	Components.Corner(lip, corner)
	local lipStroke = Components.Stroke(lip, Theme.OutlineFor(color), Theme.OutlineThickness)
	local face = Create("Frame", {
		Name = "Face",
		Size = UDim2.new(1, 0, 1, -LIP),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = zIndex + 1,
		Parent = button,
	})
	Components.Corner(face, corner)
	local faceStroke = Components.Stroke(face, Theme.OutlineFor(color), Theme.OutlineThickness)
	local gradient = Components.Gradient(face, Theme.Lighten(color, 0.22), color)
	-- Glossy highlight on the top half
	local shine = Create("Frame", {
		Name = "Shine",
		Size = UDim2.new(1, -10, 0.38, 0),
		Position = UDim2.fromOffset(5, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = zIndex + 2,
		Parent = face,
	})
	Components.Corner(shine, math.max(4, corner - 4))

	local iconWidth = if props.Icon then 0.28 else 0
	if props.Icon then
		Components.Label({
			Name = "Icon",
			Text = props.Icon,
			Size = UDim2.new(iconWidth, 0, 1, -10),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ZIndex = zIndex + 3,
			Parent = face,
		})
	end
	local label = Components.Label({
		Name = "Text",
		Text = props.Text or "",
		Size = UDim2.new(1 - iconWidth, -16, 1, -12),
		Position = UDim2.new(0.5 + iconWidth / 2, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Font = props.Font or Theme.Fonts.Title,
		Color = props.TextColor or Theme.Colors.Text,
		MaxTextSize = props.MaxTextSize or 22,
		Stroke = 2,
		ZIndex = zIndex + 3,
		Parent = face,
	})

	local enabled = true
	local hovered = false
	local function paint()
		local shown = if enabled then color else Theme.Colors.Grey
		gradient.Color = ColorSequence.new(Theme.Lighten(shown, 0.22), shown)
		lip.BackgroundColor3 = Theme.Darken(shown, 0.38)
		faceStroke.Color = Theme.OutlineFor(shown)
		lipStroke.Color = Theme.OutlineFor(shown)
		label.TextTransparency = if enabled then 0 else 0.25
	end
	local function refresh()
		paint()
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = if enabled and hovered then 1.05 else 1 }):Play()
		face.Position = UDim2.new()
	end
	button.MouseEnter:Connect(function()
		hovered = true
		refresh()
		playSound("Hover")
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		refresh()
	end)
	button.MouseButton1Down:Connect(function()
		if enabled then
			face.Position = UDim2.fromOffset(0, LIP - 1)
			TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.96 }):Play()
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
			refresh()
		end,
		SetText = function(text: string)
			label.Text = text
		end,
		SetColor = function(c: Color3)
			color = c
			refresh()
		end,
	}
end

--[[
	Square menu button with a big emoji icon and a caption underneath (side menu).
	props: Icon, Text, Color, Size, OnClick, LayoutOrder, Parent, Key (shortcut shown in a corner)
]]
function Components.IconButton(props: { [string]: any }): Button
	local size = props.Size or UDim2.fromOffset(78, 78)
	local holder = Create("Frame", {
		Name = props.Name or "IconButton",
		Size = size + UDim2.fromOffset(0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	local button = Components.Button({
		Name = "Button",
		Size = size,
		Color = props.Color,
		Text = "",
		Corner = 16,
		OnClick = props.OnClick,
		Parent = holder,
	})
	local face = button.Instance:FindFirstChild("Face") :: Frame
	Components.Label({
		Name = "Icon",
		Text = props.Icon or "",
		Size = UDim2.fromScale(0.66, 0.66),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 5,
		Parent = face,
	})
	if props.Key then
		Components.Label({
			Name = "Key",
			Text = props.Key,
			Size = UDim2.fromOffset(20, 18),
			Position = UDim2.new(1, -4, 0, 2),
			AnchorPoint = Vector2.new(1, 0),
			MaxTextSize = 14,
			Stroke = 1.5,
			ZIndex = 6,
			Parent = face,
		})
	end
	local caption = Components.Label({
		Name = "Caption",
		Text = props.Text or "",
		Size = UDim2.new(1, 8, 0, 20),
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		MaxTextSize = 17,
		Stroke = 2,
		ZIndex = 6,
		Parent = holder,
	})
	button.Label = caption
	return button
end

export type ProgressBar = {
	Instance: Frame,
	Fill: Frame,
	Label: TextLabel,
	Set: (fraction: number, text: string?, animate: boolean?) -> (),
	SetColor: (color: Color3) -> (),
}

function Components.ProgressBar(props: { [string]: any }): ProgressBar
	local background = Components.Frame({
		Name = props.Name or "ProgressBar",
		Size = props.Size or UDim2.new(1, 0, 0, 20),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Color = props.BackgroundColor or Theme.Colors.PanelDark,
		Corner = props.Corner or 100,
		Stroke = props.Stroke or 2.5,
		StrokeColor = props.StrokeColor,
		LayoutOrder = props.LayoutOrder,
		Flat = true,
		Clips = true,
		Parent = props.Parent,
	})
	local color = props.Color or Theme.Colors.Accent
	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = background,
	})
	Components.Corner(fill, props.Corner or 100)
	local gradient = Components.Gradient(fill, Theme.Lighten(color, 0.3), color)
	local shine = Create("Frame", {
		Name = "Shine",
		Size = UDim2.new(1, -6, 0.3, 0),
		Position = UDim2.new(0, 3, 0.12, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Parent = fill,
	})
	Components.Corner(shine, 100)
	local label = Components.Label({
		Name = "Text",
		Text = "",
		Size = UDim2.new(1, -10, 1, -4),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Font = Theme.Fonts.Title,
		MaxTextSize = props.MaxTextSize or 16,
		Stroke = 2,
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
		SetColor = function(c: Color3)
			gradient.Color = ColorSequence.new(Theme.Lighten(c, 0.3), c)
		end,
	}
end

-- Value pill with an icon bubble ("$ 12,450")
function Components.Pill(props: { [string]: any })
	local color = props.Color or Theme.Colors.Text
	local pill = Components.Frame({
		Name = props.Name or "Pill",
		Size = props.Size or UDim2.fromOffset(170, 44),
		Color = Theme.Colors.PanelDark,
		Transparency = 0.1,
		Corner = 100,
		Stroke = 3,
		LayoutOrder = props.LayoutOrder,
		Flat = true,
		Parent = props.Parent,
	})
	local bubble = Components.Frame({
		Name = "IconBubble",
		Size = UDim2.new(0, 0, 1, 6),
		Position = UDim2.new(0, -8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Color = color,
		Corner = 100,
		Stroke = 3,
		StrokeColor = Theme.OutlineFor(color),
		Parent = pill,
	})
	Create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = bubble })
	local icon = Components.Label({
		Name = "Icon",
		Text = props.Icon or "",
		Size = UDim2.fromScale(0.72, 0.72),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Stroke = 2,
		ZIndex = 2,
		Parent = bubble,
	})
	local value = Components.Label({
		Name = "Value",
		Text = props.Text or "0",
		Size = UDim2.new(1, -60, 1, -10),
		Position = UDim2.fromOffset(46, 5),
		XAlign = Enum.TextXAlignment.Left,
		Font = Theme.Fonts.Title,
		Color = color,
		MaxTextSize = props.MaxTextSize or 24,
		Stroke = 2,
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
		Components.Stroke(image, props.StrokeColor, 1.5, 0.2)
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

-- Number of open windows; UIController hooks this to blur the world and free the cursor
local openWindows = 0
Components.WindowsChanged = nil :: ((count: number) -> ())?

local function windowsChanged(delta: number)
	openWindows = math.max(0, openWindows + delta)
	if Components.WindowsChanged then
		Components.WindowsChanged(openWindows)
	end
end

function Components.OpenWindowCount(): number
	return openWindows
end

--[[
	Window: outlined panel with a colored header ribbon, a round red close button on the
	corner and a Modal button so the first-person cursor is free while it is open.
	props: Name, Size, Title, Color (header), Icon, OnOpen, OnClose
]]
function Components.Window(screenGui: ScreenGui, props: { [string]: any }): Window
	local headerColor = props.Color or Theme.Colors.Blue
	local holder = Create("Frame", {
		Name = props.Name or "Window",
		Size = props.Size or UDim2.fromOffset(860, 540),
		Position = UDim2.fromScale(0.5, 0.53),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screenGui,
	})
	local scale = Create("UIScale", { Parent = holder })
	-- Frees the mouse in first person while the window is visible
	Create("TextButton", {
		Name = "CursorUnlock",
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Modal = true,
		Parent = holder,
	})
	local panel = Components.Frame({
		Name = "Panel",
		Color = Theme.Colors.Panel,
		Corner = 20,
		Stroke = 4,
		Parent = holder,
	})
	local header = Components.Frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 64),
		Color = Color3.new(1, 1, 1),
		Gradient = { Theme.Lighten(headerColor, 0.2), headerColor, 90 },
		Corner = 20,
		ZIndex = 2,
		Parent = panel,
	})
	-- Square off the header's bottom corners
	Components.Frame({ Name = "HeaderBase", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), Color = Color3.new(1, 1, 1), Gradient = { Theme.Lighten(headerColor, 0.05), headerColor, 90 }, Corner = false, ZIndex = 2, Parent = header })
	Components.Frame({ Name = "HeaderLine", Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 1, 0), Color = Theme.Colors.Outline, Corner = false, Flat = true, ZIndex = 3, Parent = header })
	local title = Components.Label({
		Name = "Title",
		Text = (if props.Icon then props.Icon .. "  " else "") .. string.upper(props.Title or ""),
		Size = UDim2.new(1, -140, 0, 40),
		Position = UDim2.fromOffset(24, 12),
		XAlign = Enum.TextXAlignment.Left,
		Font = Theme.Fonts.Title,
		MaxTextSize = 34,
		Stroke = 3,
		ZIndex = 4,
		Parent = header,
	})
	local content = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -48, 1, -96),
		Position = UDim2.fromOffset(24, 84),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	local isOpen = false
	local window: Window
	local close = Components.Button({
		Name = "Close",
		Text = "X",
		Size = UDim2.fromOffset(54, 54),
		Position = UDim2.new(1, 14, 0, -14),
		AnchorPoint = Vector2.new(1, 0),
		Color = Theme.Colors.Red,
		Corner = 27,
		MaxTextSize = 30,
		ZIndex = 6,
		OnClick = function()
			window.Close()
		end,
		Parent = panel,
	})
	close.Instance.ZIndex = 6

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
			windowsChanged(1)
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
			windowsChanged(-1)
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
		ScrollBarImageColor3 = Theme.Colors.Outline,
		ScrollBarImageTransparency = 0.2,
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
	scale.Scale = from or 0.7
	TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function Components.Stars(count: number, max: number?): string
	local text = ""
	for i = 1, max or 5 do
		text ..= if i <= count then "★" else "☆"
	end
	return text
end

return Components
