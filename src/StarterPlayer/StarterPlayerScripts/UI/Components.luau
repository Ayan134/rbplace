--[[
	Components
	Small UI building blocks used by every screen (code-built UI that scales on any device).
	Minimal style: flat surfaces, hairline strokes, one accent color.
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
		Thickness = math.min(thickness or 1, 1.5),
		Transparency = transparency or (if color then 0.55 else 0.9),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- Very soft shadow so HUD text stays readable over the 3D world
function Components.TextStroke(parent: Instance, _thickness: number?): UIStroke
	return Create("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Thickness = 1,
		Transparency = 0.8,
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
	-- Gradients are ignored in the minimal style; the base color is used flat
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

-- Flat button. Accent / danger colors are kept, everything else becomes neutral.
local function buttonFill(color: Color3): Color3
	if color == Theme.Colors.Accent or color == Theme.Colors.Red or color == Theme.Colors.Grey then
		return color
	end
	return Theme.Colors.PanelLight
end

function Components.Button(props: { [string]: any }): Button
	local color: Color3 = buttonFill(props.Color or Theme.Colors.PanelLight)
	local button = Create("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(160, 44),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Visible = if props.Visible == nil then true else props.Visible,
		Parent = props.Parent,
	})
	Components.Corner(button, props.Corner or 8)
	local scale = Create("UIScale", { Parent = button })
	local label = Components.Label({
		Name = "Text",
		Text = props.Text or "",
		Size = UDim2.new(1, -16, 1, -14),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Font = props.Font or Theme.Fonts.Title,
		Color = props.TextColor or Theme.TextOn(color),
		MaxTextSize = math.min(props.MaxTextSize or 18, 20),
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = button,
	})

	local enabled = true
	local hovered = false
	local function refresh()
		local shown = if not enabled then Theme.Colors.Grey elseif hovered then Theme.Lighten(color, 0.08) else color
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = shown }):Play()
		label.TextColor3 = if enabled then (props.TextColor or Theme.TextOn(color)) else Theme.Colors.TextDim
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = if enabled and hovered then 1.02 else 1 }):Play()
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
			TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.97 }):Play()
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
			color = if c == Theme.Colors.Accent or c == Theme.Colors.Red or c == Theme.Colors.Grey then c else Theme.Colors.PanelLight
			refresh()
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
		Color = props.BackgroundColor or Theme.Colors.PanelLight,
		Corner = props.Corner or 100,
		LayoutOrder = props.LayoutOrder,
		Clips = true,
		Parent = props.Parent,
	})
	local fill = Components.Frame({
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Color = props.Color or Theme.Colors.Accent,
		Corner = props.Corner or 100,
		Parent = background,
	})
	local label = Components.Label({
		Name = "Text",
		Text = "",
		Size = UDim2.new(1, -10, 1, -4),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Font = Theme.Fonts.Title,
		MaxTextSize = props.MaxTextSize or 14,
		Stroke = 1,
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

-- Compact value pill ("● 12,450")
function Components.Pill(props: { [string]: any })
	local pill = Components.Frame({
		Name = props.Name or "Pill",
		Size = props.Size or UDim2.fromOffset(150, 38),
		Color = Theme.Colors.Panel,
		Transparency = 0.2,
		Corner = 100,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
	})
	local icon = Components.Label({
		Name = "Icon",
		Text = props.Icon or "",
		Size = UDim2.new(0, 26, 1, -14),
		Position = UDim2.fromOffset(10, 7),
		Font = Theme.Fonts.Title,
		Color = props.Color or Theme.Colors.Text,
		Parent = pill,
	})
	local value = Components.Label({
		Name = "Value",
		Text = props.Text or "0",
		Size = UDim2.new(1, -52, 1, -14),
		Position = UDim2.fromOffset(40, 7),
		XAlign = Enum.TextXAlignment.Left,
		Font = Theme.Fonts.Title,
		Color = Theme.Colors.Text,
		MaxTextSize = 18,
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

-- Modal window: flat panel, title, hairline divider, close button.
function Components.Window(screenGui: ScreenGui, props: { [string]: any }): Window
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
		Transparency = 0.04,
		Corner = 14,
		Stroke = 1,
		Parent = holder,
	})
	local title = Components.Label({
		Name = "Title",
		Text = props.Title or "",
		Size = UDim2.new(1, -120, 0, 30),
		Position = UDim2.fromOffset(24, 18),
		XAlign = Enum.TextXAlignment.Left,
		Font = Theme.Fonts.Title,
		MaxTextSize = 24,
		ZIndex = 2,
		Parent = panel,
	})
	Components.Frame({ Name = "Divider", Size = UDim2.new(1, -48, 0, 1), Position = UDim2.fromOffset(24, 62), Color = Color3.new(1, 1, 1), Transparency = 0.92, Corner = false, Parent = panel })
	local content = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -48, 1, -88),
		Position = UDim2.fromOffset(24, 76),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	local isOpen = false
	local window: Window
	local closeButton = Create("TextButton", {
		Name = "Close",
		Text = "✕",
		Font = Theme.Fonts.Title,
		TextSize = 20,
		TextColor3 = Theme.Colors.TextDim,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -56, 0, 13),
		ZIndex = 3,
		Parent = panel,
	})
	closeButton.MouseEnter:Connect(function()
		closeButton.TextColor3 = Theme.Colors.Text
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.TextColor3 = Theme.Colors.TextDim
	end)
	closeButton.Activated:Connect(function()
		playSound("Click")
		window.Close()
	end)

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
			scale.Scale = 0.96
			TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
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
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Colors.TextDim,
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
	scale.Scale = math.max(from or 0.9, 0.9)
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function Components.Stars(count: number, max: number?): string
	local text = ""
	for i = 1, max or 5 do
		text ..= if i <= count then "★" else "☆"
	end
	return text
end

return Components
