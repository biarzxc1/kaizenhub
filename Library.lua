-- Kaizen Hub UI Library (modified from SpeedHubX)
-- Version 1.0.0 | by kaizenmeow
-- Uses Lucide icons via Icons.lua

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

-- /// Icon Resolver (uses Icons.lua)
local Icons = nil
local function LoadIcons()
	local ok, result = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/biarzxc1/kaizenhub/refs/heads/main/Icons.lua"))()
	end)
	if ok and type(result) == "table" then
		Icons = result
	end
end
LoadIcons()

-- Built-in Lucide fallbacks so the core UI never loses its icons if Icons.lua fails to load
local IconFallback = {
	["lucide-x"] = "rbxassetid://10747384394",
	["lucide-minus"] = "rbxassetid://10734896206",
	["lucide-menu"] = "rbxassetid://10734887784",
	["lucide-check"] = "rbxassetid://10709790644",
	["lucide-chevron-down"] = "rbxassetid://10709790948",
	["lucide-chevron-right"] = "rbxassetid://10709791437",
	["lucide-mouse-pointer-click"] = "rbxassetid://10734898355",
}

local function ResolveIcon(IconValue)
	if type(IconValue) == "number" then return "rbxassetid://" .. IconValue end
	if type(IconValue) ~= "string" or IconValue == "" then return "" end
	if string.find(IconValue, "rbxassetid://", 1, true) or string.find(IconValue, "rbxasset://", 1, true) then
		return IconValue
	end
	local key = (string.sub(IconValue, 1, 7) == "lucide-") and IconValue or ("lucide-" .. IconValue)
	if Icons and Icons.assets then
		local found = Icons.assets[key] or Icons.assets[IconValue]
		if found then return found end
	end
	return IconFallback[key] or ""
end

local function GetGuiParent()
	if RunService:IsStudio() then
		return Player:WaitForChild("PlayerGui")
	end
	return (gethui and gethui()) or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
end

local function GetViewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function Pointer()
	local loc = UserInputService:GetMouseLocation()
	return loc.X, loc.Y
end

local Custom = {} do
	Custom.ColorRGB = Color3.fromRGB(245, 245, 245)
	Custom.GradientStart = Color3.fromRGB(255, 255, 255)
	Custom.GradientEnd = Color3.fromRGB(180, 180, 180)

	function Custom:Create(Name, Properties, Parent)
		local _instance = Instance.new(Name)
		if _instance:IsA("GuiObject") then
			_instance.BorderSizePixel = 0
		end
		if Name == "TextLabel" then
			_instance.BackgroundTransparency = 1
		elseif Name == "TextButton" or Name == "ImageButton" then
			_instance.AutoButtonColor = false
		end
		for i, v in pairs(Properties) do
			_instance[i] = v
		end
		if Parent then
			_instance.Parent = Parent
		end
		return _instance
	end

	function Custom:Tween(Object, Time, Props, Style, Direction)
		local t = TweenService:Create(Object, TweenInfo.new(Time, Style or Enum.EasingStyle.Quad, Direction or Enum.EasingDirection.Out), Props)
		t:Play()
		return t
	end

	function Custom:Hover(Button, Target, Idle, Over, Down)
		Button.MouseEnter:Connect(function()
			Custom:Tween(Target, 0.15, { BackgroundTransparency = Over })
		end)
		Button.MouseLeave:Connect(function()
			Custom:Tween(Target, 0.2, { BackgroundTransparency = Idle })
		end)
		Button.MouseButton1Down:Connect(function()
			Custom:Tween(Target, 0.08, { BackgroundTransparency = Down })
		end)
		Button.MouseButton1Up:Connect(function()
			Custom:Tween(Target, 0.15, { BackgroundTransparency = Over })
		end)
	end

	function Custom:EnabledAFK()
		Player.Idled:Connect(function()
			VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
			task.wait(1)
			VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		end)
	end

	function Custom:WhiteGradient(parent, rotation)
		return Custom:Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Custom.GradientStart),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 220, 220)),
				ColorSequenceKeypoint.new(1, Custom.GradientEnd)
			}),
			Rotation = rotation or 90,
		}, parent)
	end

	-- Soft white sheen used on card rows (buttons, toggles, sliders...)
	function Custom:RowGradient(parent)
		return Custom:Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 185, 185))
			}),
			Rotation = 0,
		}, parent)
	end
end

Custom:EnabledAFK()

-- Keeps a draggable object inside the screen (works with any anchor point)
local function ClampPosition(Object, Pos)
	local vp = GetViewport()
	local size, ap = Object.AbsoluteSize, Object.AnchorPoint
	local x = Pos.X.Scale * vp.X + Pos.X.Offset
	local y = Pos.Y.Scale * vp.Y + Pos.Y.Offset
	x = math.clamp(x, 80 - (1 - ap.X) * size.X, vp.X - 80 + ap.X * size.X)
	y = math.clamp(y, ap.Y * size.Y, vp.Y - 40 + ap.Y * size.Y)
	return UDim2.new(Pos.X.Scale, x - Pos.X.Scale * vp.X, Pos.Y.Scale, y - Pos.Y.Scale * vp.Y)
end

-- Mouse + touch dragging. Keeps tracking even when the pointer leaves the handle.
local function MakeDraggable(Handle, Object)
	local State = { Moved = false }

	Handle.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end

		State.Moved = false
		local DragStart, StartPos = Input.Position, Object.Position
		local Move

		Move = UserInputService.InputChanged:Connect(function(Changed)
			if Changed.UserInputType == Enum.UserInputType.MouseMovement or Changed == Input then
				local Delta = Changed.Position - DragStart
				if Delta.Magnitude > 5 then State.Moved = true end
				Object.Position = ClampPosition(Object, UDim2.new(
					StartPos.X.Scale, StartPos.X.Offset + Delta.X,
					StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
				))
			end
		end)

		Input.Changed:Connect(function()
			if Input.UserInputState == Enum.UserInputState.End then
				if Move then Move:Disconnect() end
			end
		end)
	end)

	return State
end

-- Material-style ripple (kept global so existing scripts calling CircleClick still work)
function CircleClick(Button, X, Y)
	task.spawn(function()
		if not Button or not Button.Parent then return end
		if not X then X, Y = Pointer() end

		Button.ClipsDescendants = true

		local abs, size = Button.AbsolutePosition, Button.AbsoluteSize
		local px = math.clamp(X - abs.X, 0, size.X)
		local py = math.clamp(Y - abs.Y, 0, size.Y)

		local Circle = Custom:Create("ImageLabel", {
			Image = "rbxassetid://106471194043211",
			ImageColor3 = Color3.fromRGB(235, 235, 235),
			ImageTransparency = 0.8,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(px, py),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = 10,
			Name = "Circle",
		}, Button)

		local d = math.max(size.X, size.Y) * 2.2
		Custom:Tween(Circle, 0.55, { Size = UDim2.fromOffset(d, d), ImageTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.6, function()
			if Circle then Circle:Destroy() end
		end)
	end)
end

local Speed_Library, Notification = {}, {}

Speed_Library.Unloaded = false
Speed_Library.Icons = Icons
Speed_Library.Flags = {} -- For save config
Speed_Library.Objects = {} -- Flag -> component (used by config loading)

function Speed_Library:SetIcons(IconsTable)
	Icons = IconsTable
	Speed_Library.Icons = IconsTable
end

-- /// Notifications (one shared, stacking layout; adapts to narrow screens)
local NotificationGui, NotificationLayout
local NotificationOrder = 0

local function GetNotificationLayout()
	if NotificationGui and NotificationGui.Parent then
		return NotificationLayout
	end

	NotificationGui = Custom:Create("ScreenGui", {
		Name = "KaizenNotifications",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
	}, GetGuiParent())

	NotificationLayout = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(1, -32, 1, -32),
		Name = "NotificationLayout"
	}, NotificationGui)

	Custom:Create("UISizeConstraint", { MaxSize = Vector2.new(320, math.huge) }, NotificationLayout)
	Custom:Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, NotificationLayout)

	return NotificationLayout
end

function Speed_Library:SetNotification(Config)
	Config = Config or {}
	local Title = Config[1] or Config.Title or ""
	local Description = Config[2] or Config.Description or ""
	local Content = Config[3] or Config.Content or ""
	local Time = tonumber(Config[5] or Config.Time) or 0.5
	local Delay = tonumber(Config[6] or Config.Delay) or 5

	local Layout = GetNotificationLayout()
	NotificationOrder += 1

	local Holder = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = NotificationOrder,
		Size = UDim2.new(1, 0, 0, 44),
		Name = "NotificationFrame"
	}, Layout)

	local Real = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundTransparency = 0.05,
		Position = UDim2.new(1, 60, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		Name = "NotificationFrameReal"
	}, Holder)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, Real)
	Custom:Create("UIStroke", { Color = Color3.fromRGB(60, 60, 60), Thickness = 1.2, Transparency = 0.4 }, Real)

	local Top = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -34, 0, 32),
		Name = "Top"
	}, Real)

	Custom:Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, Top)
	Custom:Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }, Top)

	Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		Name = "Title"
	}, Top)

	if Description ~= "" then
		local DescLabel = Custom:Create("TextLabel", {
			Font = Enum.Font.GothamBold,
			Text = Description,
			TextColor3 = Color3.fromRGB(220, 220, 220),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			LayoutOrder = 2,
			Name = "Description"
		}, Top)
		Custom:WhiteGradient(DescLabel, 0)
	end

	local Close = Custom:Create("ImageButton", {
		Image = ResolveIcon("x"),
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageTransparency = 0.4,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, 16),
		Size = UDim2.fromOffset(16, 16),
		Name = "Close"
	}, Real)

	Close.MouseEnter:Connect(function() Custom:Tween(Close, 0.15, { ImageTransparency = 0 }) end)
	Close.MouseLeave:Connect(function() Custom:Tween(Close, 0.15, { ImageTransparency = 0.4 }) end)

	local ContentLabel = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		TextSize = 13,
		Text = Content,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 10, 0, 30),
		Size = UDim2.new(1, -20, 0, 0),
		Visible = Content ~= "",
		Name = "Content"
	}, Real)

	local NotificationObject = {}
	local Closing = false

	local function Fit()
		if Closing then return end
		if Content == "" then
			Holder.Size = UDim2.new(1, 0, 0, 40)
		else
			Holder.Size = UDim2.new(1, 0, 0, 30 + math.ceil(ContentLabel.AbsoluteSize.Y) + 14)
		end
	end
	ContentLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
	Fit()

	function NotificationObject:Close()
		if Closing then return false end
		Closing = true

		Custom:Tween(Real, Time, { Position = UDim2.new(1, 60, 0, 1) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(Time, function()
			if not Holder.Parent then return end
			Custom:Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.25, function()
				if Holder then Holder:Destroy() end
			end)
		end)

		return true
	end

	Close.Activated:Connect(function() NotificationObject:Close() end)
	Custom:Tween(Real, Time, { Position = UDim2.new(0, 1, 0, 1) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	task.delay(Delay, function()
		NotificationObject:Close()
	end)

	return NotificationObject
end

function Speed_Library:CreateWindow(Config)
	Config = Config or {}
	-- Default name format: "Kaizen Hub | Version 1.0.0 | by kaizenmeow"
	local Title = Config[1] or Config.Title or "Kaizen Hub"
	local Version = Config.Version or "Version 1.0.0"
	local Author = Config.Author or "by kaizenmeow"
	local Description = Config[2] or Config.Description or (Version .. " | " .. Author)
	local TabWidth = Config[3] or Config["Tab Width"] or 130
	local SizeUi = Config[4] or Config.SizeUi or UDim2.fromOffset(560, 330)

	local BaseW = SizeUi.X.Offset > 0 and SizeUi.X.Offset or 560
	local BaseH = SizeUi.Y.Offset > 0 and SizeUi.Y.Offset or 330

	local Connections = {}
	local function Track(Connection)
		table.insert(Connections, Connection)
		return Connection
	end

	-- Responsive window metrics: never bigger than the screen, tab list shrinks on small screens
	local function Dims()
		local vp = GetViewport()
		local w = math.max(260, math.min(BaseW, vp.X - 24))
		local h = math.max(200, math.min(BaseH, vp.Y - 24))
		local tw = TabWidth
		if w < 480 then tw = math.floor(w * 0.28) end
		tw = math.clamp(tw, 84, math.floor(w * 0.4))
		return w, h, tw
	end

	local W0, H0, TW0 = Dims()

	local SpeedHubXGui = Custom:Create("ScreenGui", {
		Name = "KaizenHub",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	}, GetGuiParent())

	local DropShadowHolder = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(W0, H0),
		ZIndex = 0,
		Name = "DropShadowHolder"
	}, SpeedHubXGui)

	-- Used for open / minimize / close animations (always 1 at rest)
	local Scaler = Custom:Create("UIScale", { Scale = 0.9, Name = "KaizenScale" }, DropShadowHolder)

	local DropShadow = Custom:Create("ImageLabel", {
		Image = "",
		ImageColor3 = Color3.fromRGB(15, 15, 15),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 0,
		Name = "DropShadow"
	}, DropShadowHolder)

	local Main = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "Main"
	}, DropShadow)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, Main)
	Custom:Create("UIStroke", { Color = Color3.fromRGB(60, 60, 60), Thickness = 1.4, Transparency = 0.3 }, Main)

	local Top = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		Name = "Top"
	}, Main)

	-- Title + description share a clipped row so long text never runs under the buttons
	local TitleRow = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -84, 1, 0),
		Name = "TitleRow"
	}, Top)

	Custom:Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, TitleRow)

	Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		Name = "Title"
	}, TitleRow)

	local TextLabel1 = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = "| " .. Description,
		TextColor3 = Color3.fromRGB(230, 230, 230),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Name = "Description"
	}, TitleRow)

	Custom:WhiteGradient(TextLabel1, 0)

	local function MakeTopButton(IconName, Name, OffsetX)
		local Btn = Custom:Create("ImageButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, OffsetX, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			Name = Name
		}, Top)
		Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, Btn)
		Custom:Create("ImageLabel", {
			Image = ResolveIcon(IconName),
			ImageColor3 = Color3.fromRGB(235, 235, 235),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Name = "Icon"
		}, Btn)
		Custom:Hover(Btn, Btn, 1, 0.9, 0.82)
		return Btn
	end

	local Close = MakeTopButton("x", "Close", -8)
	local Min = MakeTopButton("minus", "Min", -38)

	local LayersTab = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 9, 0, 50),
		Size = UDim2.new(0, TW0, 1, -59),
		Name = "LayersTab"
	}, Main)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, LayersTab)

	Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
		Position = UDim2.new(0.5, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 1),
		Name = "DecideFrame"
	}, Main)

	local Layers = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, TW0 + 18, 0, 50),
		Size = UDim2.new(1, -(TW0 + 27), 1, -59),
		Name = "Layers"
	}, Main)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Layers)

	local NameTab = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 24,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 30),
		Name = "NameTab"
	}, Layers)

	local LayersReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 1, -33),
		Name = "LayersReal"
	}, Layers)

	local LayersFolder = Custom:Create("Folder", { Name = "LayersFolder" }, LayersReal)

	local LayersPageLayout = Custom:Create("UIPageLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Name = "LayersPageLayout",
		TweenTime = 0.45,
		EasingDirection = Enum.EasingDirection.InOut,
		EasingStyle = Enum.EasingStyle.Quad,
		ScrollWheelInputEnabled = false,
		TouchInputEnabled = false,
		GamepadInputEnabled = false,
	}, LayersFolder)

	local ScrollTab = Custom:Create("ScrollingFrame", {
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		Active = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "ScrollTab"
	}, LayersTab)

	local TAB_HEIGHT = 30
	local TAB_PADDING = 3

	Custom:Create("UIListLayout", {
		Padding = UDim.new(0, TAB_PADDING),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, ScrollTab)

	-- /// Window state: minimize / restore / close with animations
	local Open_Close = Custom:Create("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.15,
		Position = UDim2.new(0.1021, 0, 0.0743, 0),
		Size = UDim2.fromOffset(44, 44),
		Visible = false,
		Name = "OpenClose"
	}, SpeedHubXGui)

	Custom:Create("UICorner", { Name = "MainCorner", CornerRadius = UDim.new(1, 0) }, Open_Close)
	Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.2, Transparency = 0.5 }, Open_Close)
	Custom:Create("ImageLabel", {
		Image = ResolveIcon("menu"),
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		Name = "Icon"
	}, Open_Close)

	Open_Close.MouseEnter:Connect(function() Custom:Tween(Open_Close, 0.15, { BackgroundTransparency = 0.05 }) end)
	Open_Close.MouseLeave:Connect(function() Custom:Tween(Open_Close, 0.2, { BackgroundTransparency = 0.15 }) end)

	local OpenDrag = MakeDraggable(Open_Close, Open_Close)
	local WindowDrag = MakeDraggable(Top, DropShadowHolder)

	local Busy, Closed = false, false

	local function Minimize()
		if Busy or Closed then return end
		Busy = true
		Custom:Tween(Scaler, 0.16, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.16, function()
			DropShadowHolder.Visible = false
			Scaler.Scale = 1
			Open_Close.Size = UDim2.fromOffset(0, 0)
			Open_Close.Visible = true
			Custom:Tween(Open_Close, 0.3, { Size = UDim2.fromOffset(44, 44) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			Busy = false
		end)
	end

	local function Restore()
		if Busy or Closed then return end
		Busy = true
		Open_Close.Visible = false
		Scaler.Scale = 0.9
		DropShadowHolder.Visible = true
		Custom:Tween(Scaler, 0.3, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.delay(0.3, function() Busy = false end)
	end

	local function CloseWindow()
		if Closed then return end
		Closed = true
		Custom:Tween(Scaler, 0.18, { Scale = 0.88 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.2, function()
			for _, c in ipairs(Connections) do
				pcall(function() c:Disconnect() end)
			end
			if SpeedHubXGui then SpeedHubXGui:Destroy() end
			Speed_Library.Unloaded = true
		end)
	end

	Min.Activated:Connect(Minimize)
	Close.Activated:Connect(CloseWindow)
	Open_Close.Activated:Connect(function()
		if OpenDrag.Moved then return end
		Restore()
	end)

	-- /// Dropdown overlay (covers the whole window; panel slides in from the right)
	local MoreBlur = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = 10,
		Name = "MoreBlur"
	}, Main)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, MoreBlur)

	local ConnectButton = Custom:Create("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "ConnectButton"
	}, MoreBlur)

	local DropdownSelect = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		LayoutOrder = 1,
		Position = UDim2.new(1, 260, 0.5, 0),
		Size = UDim2.new(0.5, 0, 1, -24),
		Active = true,
		ClipsDescendants = true,
		Name = "DropdownSelect"
	}, MoreBlur)

	Custom:Create("UISizeConstraint", { MinSize = Vector2.new(170, 0), MaxSize = Vector2.new(240, math.huge) }, DropdownSelect)
	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, DropdownSelect)
	Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.4, Transparency = 0.7 }, DropdownSelect)

	local DropdownSelectReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -10, 1, -10),
		Name = "DropdownSelectReal"
	}, DropdownSelect)

	local DropdownFolder = Custom:Create("Folder", { Name = "DropdownFolder" }, DropdownSelectReal)

	local DropPageLayout = Custom:Create("UIPageLayout", {
		EasingDirection = Enum.EasingDirection.InOut,
		EasingStyle = Enum.EasingStyle.Quad,
		TweenTime = 0.01,
		SortOrder = Enum.SortOrder.LayoutOrder,
		ScrollWheelInputEnabled = false,
		TouchInputEnabled = false,
		GamepadInputEnabled = false,
		Archivable = false,
		Name = "DropPageLayout"
	}, DropdownFolder)

	local DropdownClosing = false

	local function OpenDropdown(Page)
		if MoreBlur.Visible then return end
		DropPageLayout:JumpTo(Page)
		DropdownSelect.Position = UDim2.new(1, 260, 0.5, 0)
		MoreBlur.Visible = true
		Custom:Tween(MoreBlur, 0.2, { BackgroundTransparency = 0.55 })
		Custom:Tween(DropdownSelect, 0.3, { Position = UDim2.new(1, -12, 0.5, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end

	local function CloseDropdown()
		if not MoreBlur.Visible or DropdownClosing then return end
		DropdownClosing = true
		Custom:Tween(MoreBlur, 0.2, { BackgroundTransparency = 1 })
		Custom:Tween(DropdownSelect, 0.22, { Position = UDim2.new(1, 260, 0.5, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.22, function()
			MoreBlur.Visible = false
			DropdownClosing = false
		end)
	end

	ConnectButton.Activated:Connect(CloseDropdown)

	-- /// Tabs
	local Tabs = {}
	local CountTab = 0
	local CountDropdown = 0
	local TabList = {}
	local SelectedTab = nil

	local ChooseFrame = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Custom.GradientStart,
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0, 2, 0, 14),
		Name = "ChooseFrame"
	})

	Custom:WhiteGradient(ChooseFrame, 90)
	Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 0.6, Transparency = 0.4 }, ChooseFrame)
	Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, ChooseFrame)

	local function SelectTab(T, Instant)
		if SelectedTab == T then return end
		SelectedTab = T

		for _, o in ipairs(TabList) do
			local on = o == T
			local info = Instant and 0 or 0.2
			Custom:Tween(o.Frame, info, { BackgroundTransparency = on and 0.92 or 0.999 })
			Custom:Tween(o.Label, info, { TextTransparency = on and 0 or 0.35 })
			Custom:Tween(o.Icon, info, { ImageTransparency = on and 0 or 0.35 })
		end

		ChooseFrame.Parent = T.Frame
		LayersPageLayout:JumpTo(T.Page)

		NameTab.Text = T.Title
		if not Instant then
			NameTab.TextTransparency = 1
			NameTab.Position = UDim2.new(0, 10, 0, 0)
			Custom:Tween(NameTab, 0.3, { TextTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

			task.spawn(function()
				ChooseFrame.Size = UDim2.new(0, 2, 0, 6)
				Custom:Tween(ChooseFrame, 0.25, { Size = UDim2.new(0, 2, 0, 22) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				task.wait(0.25)
				Custom:Tween(ChooseFrame, 0.2, { Size = UDim2.new(0, 2, 0, 14) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			end)
		end
	end

	function Tabs:CreateTab(Config)
		Config = Config or {}
		local _Name = Config[1] or Config.Name or ""
		local Icon = Config[2] or Config.Icon or ""
		local ResolvedIcon = ResolveIcon(Icon)
		local Order = CountTab

		local ScrolLayers = Custom:Create("ScrollingFrame", {
			ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
			ScrollBarImageTransparency = 0.7,
			ScrollBarThickness = 2,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Active = true,
			LayoutOrder = Order,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "ScrolLayers",
		}, LayersFolder)

		Custom:Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, ScrolLayers)

		Custom:Create("UIPadding", {
			PaddingBottom = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 4),
		}, ScrolLayers)

		local Tab = Custom:Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			LayoutOrder = Order,
			Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
			Name = "Tab",
		}, ScrollTab)

		Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Tab)

		local TabButton = Custom:Create("TextButton", {
			Font = Enum.Font.GothamBold,
			Text = "",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "TabButton"
		}, Tab)

		local TabLabel = Custom:Create("TextLabel", {
			Font = Enum.Font.GothamBold,
			Text = _Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0.35,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, ResolvedIcon ~= "" and -36 or -16, 1, 0),
			Position = UDim2.new(0, ResolvedIcon ~= "" and 32 or 12, 0, 0),
			Name = "TabName"
		}, Tab)

		local TabIcon = Custom:Create("ImageLabel", {
			Image = ResolvedIcon,
			ImageColor3 = Color3.fromRGB(230, 230, 230),
			ImageTransparency = 0.35,
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 9, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Visible = ResolvedIcon ~= "",
			Name = "FeatureImg"
		}, Tab)

		local TabData = { Frame = Tab, Label = TabLabel, Icon = TabIcon, Page = ScrolLayers, Title = _Name, Order = Order }
		table.insert(TabList, TabData)

		TabButton.MouseEnter:Connect(function()
			if SelectedTab ~= TabData then Custom:Tween(Tab, 0.15, { BackgroundTransparency = 0.96 }) end
		end)
		TabButton.MouseLeave:Connect(function()
			if SelectedTab ~= TabData then Custom:Tween(Tab, 0.2, { BackgroundTransparency = 0.999 }) end
		end)

		if Order == 0 then
			SelectTab(TabData, true)
		end

		TabButton.Activated:Connect(function()
			CircleClick(TabButton)
			SelectTab(TabData)
		end)

		--- /// Section
		local Sections, CountSection = {}, 0

		function Sections:AddSection(TitleArg, OpenSection)
			local Title = TitleArg or ""
			local Opened = OpenSection or false

			CountSection += 1

			local Section = Custom:Create("Frame", {
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				LayoutOrder = CountSection,
				Size = UDim2.new(1, 0, 0, 30),
				Name = "Section"
			}, ScrolLayers)

			local SectionReal = Custom:Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.935,
				Size = UDim2.new(1, 0, 0, 30),
				Name = "SectionReal"
			}, Section)

			Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SectionReal)
			Custom:RowGradient(SectionReal)

			local SectionButton = Custom:Create("TextButton", {
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "SectionButton"
			}, SectionReal)

			Custom:Hover(SectionButton, SectionReal, 0.935, 0.9, 0.87)

			local FeatureFrame = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.new(0, 18, 0, 18),
				Name = "FeatureFrame"
			}, SectionReal)

			local FeatureImg = Custom:Create("ImageLabel", {
				Image = ResolveIcon("chevron-right"),
				ImageColor3 = Color3.fromRGB(230, 230, 230),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = Opened and 90 or 0,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "FeatureImg"
			}, FeatureFrame)

			Custom:Create("TextLabel", {
				Font = Enum.Font.GothamBold,
				Text = Title,
				TextColor3 = Color3.fromRGB(230, 230, 230),
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.new(1, -40, 0, 16),
				Name = "SectionTitle"
			}, SectionReal)

			local SectionDecideFrame = Custom:Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 33),
				Size = Opened and UDim2.new(1, 0, 0, 2) or UDim2.new(0, 0, 0, 2),
				Name = "SectionDecideFrame"
			}, Section)
			Custom:Create("UICorner", {}, SectionDecideFrame)
			Custom:Create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
				})
			}, SectionDecideFrame)

			local SectionAdd = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Position = UDim2.new(0.5, 0, 0, 38),
				Size = UDim2.new(1, 0, 0, 0),
				Name = "SectionAdd"
			}, Section)

			local ItemList = Custom:Create("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder
			}, SectionAdd)

			-- Section height always follows its real content, so any item can grow / shrink
			local function ApplySection()
				if not Opened then return end
				local ContentH = ItemList.AbsoluteContentSize.Y
				Custom:Tween(Section, 0.22, { Size = UDim2.new(1, 0, 0, 38 + ContentH + 2) })
				Custom:Tween(SectionAdd, 0.22, { Size = UDim2.new(1, 0, 0, ContentH) })
			end

			ItemList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ApplySection)

			SectionButton.Activated:Connect(function()
				CircleClick(SectionButton)
				Opened = not Opened
				Custom:Tween(FeatureImg, 0.2, { Rotation = Opened and 90 or 0 })
				Custom:Tween(SectionDecideFrame, 0.25, { Size = Opened and UDim2.new(1, 0, 0, 2) or UDim2.new(0, 0, 0, 2) })
				if Opened then
					ApplySection()
				else
					Custom:Tween(Section, 0.2, { Size = UDim2.new(1, 0, 0, 30) })
				end
			end)

			local Item, ItemCount = {}, 0

			local function NewRow(Name, Height)
				ItemCount += 1
				local Row = Custom:Create("Frame", {
					Name = Name,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, Height or 35)
				}, SectionAdd)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Row)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.93 }, Row)
				Custom:RowGradient(Row)
				return Row
			end

			-- Title + wrapping description. Row height follows the text, whatever the window width.
			local function BuildText(Row, TitleText, ContentText, RScale, ROffset, Stack, Extra)
				RScale = RScale or 0
				ROffset = ROffset or 0
				Extra = Extra or 0

				local TitleLabel = Custom:Create("TextLabel", {
					Name = "Title",
					Font = Enum.Font.GothamBold,
					Text = TitleText,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 9),
					Size = UDim2.new(1 - RScale, -(ROffset + 20), 0, 14)
				}, Row)

				local ContentLabel = Custom:Create("TextLabel", {
					Name = "Content",
					Font = Enum.Font.GothamBold,
					Text = ContentText,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					AutomaticSize = Enum.AutomaticSize.Y,
					Position = UDim2.new(0, 10, 0, 25),
					Size = UDim2.new(1 - RScale, -(ROffset + 20), 0, 0)
				}, Row)

				local function Fit()
					if not Row.Parent then return end
					local has = ContentLabel.Text ~= ""
					ContentLabel.Visible = has
					local h
					if has then
						TitleLabel.AnchorPoint = Vector2.new(0, 0)
						TitleLabel.Position = UDim2.new(0, 10, 0, 9)
						h = 25 + math.ceil(ContentLabel.AbsoluteSize.Y / Scaler.Scale) + (Stack and 0 or 10) + Extra
					elseif Stack then
						TitleLabel.AnchorPoint = Vector2.new(0, 0)
						TitleLabel.Position = UDim2.new(0, 10, 0, 9)
						h = 23 + Extra
					else
						TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
						TitleLabel.Position = UDim2.new(0, 10, 0.5, 0)
						h = 35
					end
					Row.Size = UDim2.new(1, 0, 0, math.max(35, h))
				end

				ContentLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
				ContentLabel:GetPropertyChangedSignal("Text"):Connect(Fit)
				Fit()

				return TitleLabel, ContentLabel, Fit
			end

			local function Safe(Callback, ...)
				local ok, err = pcall(Callback, ...)
				if not ok then warn("[KaizenHub] callback error: " .. tostring(err)) end
			end

			function Item:AddParagraph(Config)
				Config = Config or {}
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local SettingFuncs = {}

				local Paragraph = NewRow("Paragraph")
				local ParagraphTitle, ParagraphContent = BuildText(Paragraph, Title, Content, 0, 0, true)

				function SettingFuncs:Set(Config)
					Config = Config or {}
					ParagraphTitle.Text = Config[1] or Config.Title or ""
					ParagraphContent.Text = Config[2] or Config.Content or ""
				end

				return SettingFuncs
			end

			function Item:AddSeperator(Config)
				Config = Config or {}
				local Title = Config[1] or Config.Title or ""
				local Sep_Funcs = {}

				local Seperator = NewRow("Seperator", 30)
				Seperator.BackgroundTransparency = 0.88

				local SeperatorTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(240, 240, 240),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Name = "SeperatorTitle"
				}, Seperator)

				function Sep_Funcs:Set(Config)
					Config = Config or {}
					SeperatorTitle.Text = Config[1] or Config.Title or ""
				end

				return Sep_Funcs
			end

			function Item:AddLine()
				local LineFuncs = {}
				ItemCount += 1

				local Holder = Custom:Create("Frame", {
					BackgroundTransparency = 1,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 7),
					Name = "Line"
				}, SectionAdd)

				local Line = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 0, 2),
					Name = "LineFill"
				}, Holder)

				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, Line)
				Custom:Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
					})
				}, Line)

				return LineFuncs
			end

			function Item:AddButton(Config)
				Config = Config or {}
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Icon = Config[3] or Config.Icon or "mouse-pointer-click"
				local Callback = Config[4] or Config.Callback or function() end
				local Funcs_Button = {}

				local Button = NewRow("Button")
				BuildText(Button, Title, Content, 0, 50)

				local ButtonButton = Custom:Create("TextButton", {
					Name = "ButtonButton",
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0)
				}, Button)

				Custom:Create("ImageLabel", {
					Name = "FeatureImg",
					Image = ResolveIcon(Icon),
					ImageColor3 = Color3.fromRGB(230, 230, 230),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.new(0, 18, 0, 18)
				}, Button)

				Custom:Hover(ButtonButton, Button, 0.935, 0.9, 0.85)

				ButtonButton.Activated:Connect(function()
					CircleClick(ButtonButton)
					Safe(Callback)
				end)

				return Funcs_Button
			end

			function Item:AddToggle(Config)
				Config = Config or {}
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or false
				local Callback = Config[4] or Config.Callback or function() end
				local Flag = Config.Flag or Config[5]

				local Funcs_Toggle = { Value = Default }

				local Toggle = NewRow("Toggle")
				local ToggleTitle = BuildText(Toggle, Title, Content, 0, 56)

				local ToggleButton = Custom:Create("TextButton", {
					Name = "ToggleButton",
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0)
				}, Toggle)

				Custom:Hover(ToggleButton, Toggle, 0.935, 0.9, 0.86)

				local Switch = Custom:Create("Frame", {
					Name = "FeatureFrame2",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.new(0, 36, 0, 20)
				}, Toggle)

				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, Switch)
				Custom:WhiteGradient(Switch, 90)
				local SwitchStroke = Custom:Create("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 1.4,
					Transparency = 0.85
				}, Switch)

				local ToggleCircle = Custom:Create("Frame", {
					Name = "ToggleCircle",
					BackgroundColor3 = Color3.fromRGB(230, 230, 230),
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(0, 2, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5)
				}, Switch)

				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, ToggleCircle)

				local function ToggleAnimation(isOn)
					local info = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					TweenService:Create(ToggleTitle, info, { TextColor3 = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(231, 231, 231) }):Play()
					TweenService:Create(ToggleCircle, info, {
						Position = isOn and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
						BackgroundColor3 = isOn and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(230, 230, 230)
					}):Play()
					TweenService:Create(SwitchStroke, info, { Transparency = isOn and 0.2 or 0.85 }):Play()
					TweenService:Create(Switch, info, { BackgroundTransparency = isOn and 0 or 0.92 }):Play()
				end

				ToggleButton.MouseButton1Down:Connect(function()
					Custom:Tween(ToggleCircle, 0.1, { Size = UDim2.new(0, 20, 0, 16) })
				end)
				ToggleButton.MouseButton1Up:Connect(function()
					Custom:Tween(ToggleCircle, 0.15, { Size = UDim2.new(0, 16, 0, 16) })
				end)
				ToggleButton.MouseLeave:Connect(function()
					Custom:Tween(ToggleCircle, 0.15, { Size = UDim2.new(0, 16, 0, 16) })
				end)

				ToggleButton.Activated:Connect(function()
					CircleClick(ToggleButton)
					Funcs_Toggle:Set(not Funcs_Toggle.Value)
				end)

				function Funcs_Toggle:Set(Value)
					Value = Value and true or false
					Funcs_Toggle.Value = Value
					if Flag then Speed_Library.Flags[Flag] = Value end
					ToggleAnimation(Value)
					Safe(Callback, Value)
				end

				Funcs_Toggle:Set(Funcs_Toggle.Value)
				if Flag then Speed_Library.Objects[Flag] = Funcs_Toggle end

				return Funcs_Toggle
			end

			-- /// IMPROVED SLIDER ///
			function Item:AddSlider(Config)
				Config = Config or {}
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Increment = Config[3] or Config.Increment or 1
				local MinV = Config[4] or Config.Min or 0
				local MaxV = Config[5] or Config.Max or 100
				local Default = Config[6] or Config.Default or MinV
				local Callback = Config[7] or Config.Callback or function() end
				local Flag = Config.Flag

				if MaxV <= MinV then MaxV = MinV + 1 end
				if Increment <= 0 then Increment = 1 end

				local Funcs_Slider = { Value = MinV }

				local Slider = NewRow("Slider", 48)
				-- Stack = true keeps the title on top; Extra reserves the room for the track under the text
				BuildText(Slider, Title, Content, 0, 64, true, 25)

				-- Editable value box (top-right)
				local ValueBox = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					Text = tostring(Default),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Center,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.88,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -10, 0, 6),
					Size = UDim2.new(0, 48, 0, 20),
					Name = "ValueBox"
				}, Slider)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, ValueBox)
				local ValueStroke = Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.8 }, ValueBox)

				-- Big invisible hit area so the track is easy to grab with a thumb
				local Hit = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 1, -5),
					Size = UDim2.new(1, -20, 0, 22),
					Name = "SliderHit"
				}, Slider)

				local SliderFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(60, 60, 60),
					BackgroundTransparency = 0.2,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 0, 6),
					Name = "SliderFrame"
				}, Hit)
				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, SliderFrame)

				-- Filled portion with the white gradient
				local SliderDraggable = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.new(0, 0, 1, 0),
					Name = "SliderDraggable"
				}, SliderFrame)
				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, SliderDraggable)
				Custom:WhiteGradient(SliderDraggable, 0)

				-- Knob
				local SliderCircle = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
					ZIndex = 2,
					Name = "SliderCircle"
				}, SliderDraggable)
				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, SliderCircle)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(200, 200, 200), Thickness = 1, Transparency = 0.3 }, SliderCircle)

				local Dragging, Hovering = false, false

				local function KnobState()
					local big = Dragging or Hovering
					Custom:Tween(SliderCircle, 0.15, { Size = big and UDim2.new(0, 18, 0, 18) or UDim2.new(0, 14, 0, 14) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end

				local function Snap(Number)
					Number = tonumber(Number) or MinV
					Number = MinV + math.floor((Number - MinV) / Increment + 0.5) * Increment
					local decimals = #((tostring(Increment):match("%.(%d+)")) or "")
					Number = tonumber(string.format("%." .. decimals .. "f", Number)) or Number
					return math.clamp(Number, MinV, MaxV)
				end

				local function Render(Value, Instant)
					local size = UDim2.new((Value - MinV) / (MaxV - MinV), 0, 1, 0)
					if Instant then
						SliderDraggable.Size = size
					else
						Custom:Tween(SliderDraggable, 0.15, { Size = size }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					end
				end

				function Funcs_Slider:Set(Value, Instant)
					local v = Snap(Value)
					local changed = v ~= Funcs_Slider.Value
					Funcs_Slider.Value = v
					ValueBox.Text = tostring(v)
					if Flag then Speed_Library.Flags[Flag] = v end
					Render(v, Instant)
					if changed then Safe(Callback, v) end
				end

				local function FromX(X)
					local rel = math.clamp((X - SliderFrame.AbsolutePosition.X) / math.max(SliderFrame.AbsoluteSize.X, 1), 0, 1)
					return MinV + (MaxV - MinV) * rel
				end

				local function StopDrag()
					if not Dragging then return end
					Dragging = false
					ScrolLayers.ScrollingEnabled = true
					KnobState()
				end

				Hit.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Dragging = true
						ScrolLayers.ScrollingEnabled = false -- stops the page scrolling while you slide on touch
						KnobState()
						Funcs_Slider:Set(FromX(Input.Position.X), true)

						local Move
						Move = UserInputService.InputChanged:Connect(function(Changed)
							if not Dragging then
								Move:Disconnect()
								return
							end
							if Changed.UserInputType == Enum.UserInputType.MouseMovement or Changed == Input then
								Funcs_Slider:Set(FromX(Changed.Position.X), true)
							end
						end)

						Input.Changed:Connect(function()
							if Input.UserInputState == Enum.UserInputState.End then
								StopDrag()
								if Move then Move:Disconnect() end
							end
						end)
					end
				end)

				Hit.MouseEnter:Connect(function()
					Hovering = true
					KnobState()
				end)
				Hit.MouseLeave:Connect(function()
					Hovering = false
					KnobState()
				end)

				ValueBox.Focused:Connect(function()
					Custom:Tween(ValueStroke, 0.15, { Transparency = 0.3 })
				end)

				ValueBox.FocusLost:Connect(function()
					Custom:Tween(ValueStroke, 0.2, { Transparency = 0.8 })
					local typed = tonumber(ValueBox.Text)
					if typed then
						Funcs_Slider:Set(typed)
					else
						ValueBox.Text = tostring(Funcs_Slider.Value)
					end
				end)

				-- Initial state (fires the callback once, like before)
				Funcs_Slider.Value = Snap(Default)
				ValueBox.Text = tostring(Funcs_Slider.Value)
				Render(Funcs_Slider.Value, true)
				if Flag then
					Speed_Library.Flags[Flag] = Funcs_Slider.Value
					Speed_Library.Objects[Flag] = Funcs_Slider
				end
				Safe(Callback, Funcs_Slider.Value)

				return Funcs_Slider
			end

			function Item:AddInput(Config)
				Config = Config or {}
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or ""
				local Callback = Config[4] or Config.Callback or function() end
				local Flag = Config.Flag
				local Funcs_Input = { Value = Default }

				local Input = NewRow("Input")
				BuildText(Input, Title, Content, 0.42, 4)

				local InputFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.95,
					ClipsDescendants = true,
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0.42, 0, 0, 24),
					Name = "InputFrame"
				}, Input)

				Custom:Create("UISizeConstraint", { MinSize = Vector2.new(100, 0), MaxSize = Vector2.new(220, math.huge) }, InputFrame)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, InputFrame)
				local InputStroke = Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, InputFrame)

				local InputTextBox = Custom:Create("TextBox", {
					CursorPosition = -1,
					Font = Enum.Font.GothamBold,
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					PlaceholderText = "Write your input there",
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.new(1, -16, 1, -4),
					Name = "InputTextBox"
				}, InputFrame)

				-- shadcn style focus ring
				InputTextBox.Focused:Connect(function()
					Custom:Tween(InputStroke, 0.15, { Transparency = 0.35 })
					Custom:Tween(InputFrame, 0.15, { BackgroundTransparency = 0.9 })
				end)

				function Funcs_Input:Set(Value)
					Value = tostring(Value or "")
					InputTextBox.Text = Value
					Funcs_Input.Value = Value
					if Flag then Speed_Library.Flags[Flag] = Value end
					Safe(Callback, Value)
				end

				InputTextBox.FocusLost:Connect(function()
					Custom:Tween(InputStroke, 0.2, { Transparency = 0.85 })
					Custom:Tween(InputFrame, 0.2, { BackgroundTransparency = 0.95 })
					Funcs_Input:Set(InputTextBox.Text)
				end)

				Funcs_Input:Set(Default)
				if Flag then Speed_Library.Objects[Flag] = Funcs_Input end

				return Funcs_Input
			end

			-- Internal helper to build dropdown overlay options
			local function _buildDropdown(Config, Multi)
				Config = Config or {}
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Options = Config.Options or Config[4] or {}
				local Default = Config.Default or Config[5] or {}
				local Callback = Config.Callback or Config[6] or function() end
				local Flag = Config.Flag

				if type(Default) == "string" then Default = { Default } end

				local function Copy(list)
					local out = {}
					for _, v in ipairs(list or {}) do table.insert(out, v) end
					return out
				end

				local Funcs_Dropdown = { Value = Copy(Default), Options = Options }
				if not Multi and #Funcs_Dropdown.Value > 1 then Funcs_Dropdown.Value = { Funcs_Dropdown.Value[1] } end

				local Dropdown = NewRow("Dropdown")
				BuildText(Dropdown, Title, Content, 0.42, 4)

				local DropdownButton = Custom:Create("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "ToggleButton"
				}, Dropdown)

				Custom:Hover(DropdownButton, Dropdown, 0.935, 0.9, 0.86)

				local SelectOptionsFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.95,
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0.42, 0, 0, 26),
					Name = "SelectOptionsFrame",
					LayoutOrder = CountDropdown
				}, Dropdown)

				Custom:Create("UISizeConstraint", { MinSize = Vector2.new(100, 0), MaxSize = Vector2.new(220, math.huge) }, SelectOptionsFrame)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SelectOptionsFrame)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, SelectOptionsFrame)

				local OptionSelecting = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = "Select Options",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.4,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.new(1, -30, 1, -8),
					Name = "OptionSelecting"
				}, SelectOptionsFrame)

				local Chevron = Custom:Create("ImageLabel", {
					Image = ResolveIcon("chevron-down"),
					ImageColor3 = Color3.fromRGB(231, 231, 231),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -4, 0.5, 0),
					Size = UDim2.new(0, 16, 0, 16),
					Name = "OptionImg"
				}, SelectOptionsFrame)

				local ScrollSelect = Custom:Create("ScrollingFrame", {
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
					ScrollBarImageTransparency = 0.7,
					ScrollBarThickness = 2,
					Active = true,
					LayoutOrder = CountDropdown,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "ScrollSelect"
				}, DropdownFolder)

				Custom:Create("UIListLayout", {
					Padding = UDim.new(0, 3),
					SortOrder = Enum.SortOrder.LayoutOrder
				}, ScrollSelect)

				DropdownButton.Activated:Connect(function()
					OpenDropdown(ScrollSelect)
					Custom:Tween(Chevron, 0.2, { Rotation = 180 })
					task.delay(0.35, function()
						Custom:Tween(Chevron, 0.2, { Rotation = 0 })
					end)
				end)

				local SearchBar = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					PlaceholderText = "Search",
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					ClearTextOnFocus = false,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.6,
					LayoutOrder = -1,
					Size = UDim2.new(1, 0, 0, 24),
					Name = "SearchBar"
				}, ScrollSelect)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SearchBar)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, SearchBar)

				local OptionObjs = {}
				local DropCount = 0

				SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
					local SearchText = string.lower(SearchBar.Text)
					for name, o in pairs(OptionObjs) do
						o.Frame.Visible = string.find(string.lower(name), SearchText, 1, true) ~= nil
					end
				end)

				local function RenderSelection()
					for name, o in pairs(OptionObjs) do
						local on = table.find(Funcs_Dropdown.Value, name) ~= nil
						Custom:Tween(o.Choose, 0.2, { Size = on and UDim2.new(0, 2, 0, 14) or UDim2.new(0, 0, 0, 0) })
						Custom:Tween(o.Frame, 0.2, { BackgroundTransparency = on and 0.9 or 0.999 })
						Custom:Tween(o.Label, 0.2, { TextTransparency = on and 0 or 0.25 })
					end
					local text = table.concat(Funcs_Dropdown.Value, ", ")
					OptionSelecting.Text = text ~= "" and text or "Select Options"
				end

				local function CreateOption(OptionName)
					OptionName = tostring(OptionName or "Option")
					DropCount += 1

					local Option = Custom:Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.999,
						LayoutOrder = DropCount,
						Size = UDim2.new(1, 0, 0, 28),
						Name = "Option"
					}, ScrollSelect)

					Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Option)

					local OptionButton = Custom:Create("TextButton", {
						Text = "",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "OptionButton"
					}, Option)

					local OptionText = Custom:Create("TextLabel", {
						Font = Enum.Font.GothamBold,
						Text = OptionName,
						TextSize = 13,
						TextColor3 = Color3.fromRGB(230, 230, 230),
						TextTransparency = 0.25,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -16, 1, 0),
						Name = "OptionText"
					}, Option)

					local Choose = Custom:Create("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						Position = UDim2.new(0, 3, 0.5, 0),
						Size = UDim2.new(0, 0, 0, 0),
						Name = "ChooseFrame"
					}, Option)

					Custom:WhiteGradient(Choose, 90)
					Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, Choose)

					OptionButton.MouseEnter:Connect(function()
						if table.find(Funcs_Dropdown.Value, OptionName) == nil then
							Custom:Tween(Option, 0.12, { BackgroundTransparency = 0.95 })
						end
					end)
					OptionButton.MouseLeave:Connect(function()
						if table.find(Funcs_Dropdown.Value, OptionName) == nil then
							Custom:Tween(Option, 0.15, { BackgroundTransparency = 0.999 })
						end
					end)

					OptionButton.Activated:Connect(function()
						CircleClick(OptionButton)
						local list = Copy(Funcs_Dropdown.Value)
						local index = table.find(list, OptionName)

						if Multi then
							if index then table.remove(list, index) else table.insert(list, OptionName) end
						else
							list = { OptionName }
						end

						Funcs_Dropdown:Set(list)
						if not Multi then CloseDropdown() end
					end)

					OptionObjs[OptionName] = { Frame = Option, Choose = Choose, Label = OptionText }
				end

				function Funcs_Dropdown:Clear()
					for _, o in pairs(OptionObjs) do
						o.Frame:Destroy()
					end
					OptionObjs = {}
					DropCount = 0
					Funcs_Dropdown.Value = {}
					Funcs_Dropdown.Options = {}
					OptionSelecting.Text = "Select Options"
				end

				function Funcs_Dropdown:Set(Value)
					if type(Value) == "string" then Value = { Value } end
					local list = Copy(Value or Funcs_Dropdown.Value)
					if not Multi and #list > 1 then list = { list[1] } end

					Funcs_Dropdown.Value = list
					RenderSelection()
					if Flag then Speed_Library.Flags[Flag] = Funcs_Dropdown.Value end
					Safe(Callback, Multi and Funcs_Dropdown.Value or Funcs_Dropdown.Value[1])
				end

				function Funcs_Dropdown:AddOption(OptionName)
					table.insert(Funcs_Dropdown.Options, OptionName)
					CreateOption(OptionName)
					RenderSelection()
				end

				function Funcs_Dropdown:Refresh(RefreshList, Selecting)
					RefreshList = RefreshList or {}
					Selecting = Selecting or {}
					Funcs_Dropdown:Clear()
					for _, Drop in ipairs(RefreshList) do
						CreateOption(Drop)
					end
					Funcs_Dropdown.Options = RefreshList
					Funcs_Dropdown:Set(Selecting)
				end

				Funcs_Dropdown:Refresh(Funcs_Dropdown.Options, Funcs_Dropdown.Value)
				if Flag then Speed_Library.Objects[Flag] = Funcs_Dropdown end

				CountDropdown += 1
				return Funcs_Dropdown
			end

			function Item:AddDropdown(Config)
				Config = Config or {}
				local Multi = Config[3]
				if Multi == nil then Multi = Config.Multi end
				if Multi == nil then Multi = false end
				return _buildDropdown(Config, Multi)
			end

			-- /// AddSelect (single-pick clean dropdown) ///
			function Item:AddSelect(Config)
				return _buildDropdown(Config, false)
			end

			-- /// AddSaveConfig (save/load config) ///
			function Item:AddSaveConfig(Config)
				Config = Config or {}
				local Title = Config.Title or "Configuration"
				local Folder = Config.Folder or "KaizenHub"
				local DefaultName = Config.Default or "default"
				local Funcs_Save = {}

				if isfolder and makefolder and not isfolder(Folder) then
					makefolder(Folder)
				end

				local Container = NewRow("SaveConfig", 92)
				Container.ClipsDescendants = true

				Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 8),
					Size = UDim2.new(1, -20, 0, 14),
					Name = "Title"
				}, Container)

				local NameFrame = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					Position = UDim2.new(0, 10, 0, 28),
					Size = UDim2.new(1, -20, 0, 24),
					Name = "NameFrame"
				}, Container)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, NameFrame)
				local NameStroke = Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, NameFrame)

				local NameBox = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					PlaceholderText = "Config Name",
					PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
					Text = DefaultName,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -16, 1, 0),
					Name = "NameBox"
				}, NameFrame)

				NameBox.Focused:Connect(function() Custom:Tween(NameStroke, 0.15, { Transparency = 0.35 }) end)
				NameBox.FocusLost:Connect(function() Custom:Tween(NameStroke, 0.2, { Transparency = 0.85 }) end)

				local SelectorFrame = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					Position = UDim2.new(0, 10, 0, 56),
					Size = UDim2.new(0.5, -15, 0, 26),
					Name = "SelectorFrame"
				}, Container)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SelectorFrame)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, SelectorFrame)

				local SelectorLabel = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = "Select config",
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -28, 1, 0),
					Name = "SelectorLabel"
				}, SelectorFrame)

				local SelectorChevron = Custom:Create("ImageLabel", {
					Image = ResolveIcon("chevron-down"),
					ImageColor3 = Color3.fromRGB(230, 230, 230),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -4, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
				}, SelectorFrame)

				local SelectorButton = Custom:Create("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "SelectorButton"
				}, SelectorFrame)

				Custom:Hover(SelectorButton, SelectorFrame, 0.92, 0.88, 0.84)

				-- Save / Load buttons with the white gradient
				local function MakeActionButton(text, posXScale, posXOffset, sizeXScale, sizeXOffset)
					local Btn = Custom:Create("TextButton", {
						Font = Enum.Font.GothamBold,
						Text = text,
						TextColor3 = Color3.fromRGB(20, 20, 20),
						TextSize = 12,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0,
						Position = UDim2.new(posXScale, posXOffset, 0, 56),
						Size = UDim2.new(sizeXScale, sizeXOffset, 0, 26),
						Name = text .. "Btn"
					}, Container)
					Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Btn)
					Custom:WhiteGradient(Btn, 90)
					Custom:Hover(Btn, Btn, 0, 0.12, 0.25)
					return Btn
				end

				local SaveBtn = MakeActionButton("Save", 0.5, 5, 0.25, -10)
				local LoadBtn = MakeActionButton("Load", 0.75, 5, 0.25, -15)

				-- The list lives inside the card (it grows the card) so the section never clips it
				local DropList = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					Position = UDim2.new(0, 10, 0, 90),
					Size = UDim2.new(0.5, -15, 0, 0),
					Visible = false,
					ClipsDescendants = true,
					Name = "DropList"
				}, Container)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, DropList)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.8 }, DropList)
				Custom:Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, DropList)
				Custom:Create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }, DropList)

				local ListOpen = false
				local function SetListOpen(state, listH)
					ListOpen = state
					Custom:Tween(SelectorChevron, 0.2, { Rotation = state and 180 or 0 })
					if state then
						DropList.Visible = true
						DropList.Size = UDim2.new(0.5, -15, 0, 0)
						Custom:Tween(DropList, 0.2, { Size = UDim2.new(0.5, -15, 0, listH) })
						Custom:Tween(Container, 0.2, { Size = UDim2.new(1, 0, 0, 92 + listH + 6) })
					else
						Custom:Tween(DropList, 0.15, { Size = UDim2.new(0.5, -15, 0, 0) })
						Custom:Tween(Container, 0.2, { Size = UDim2.new(1, 0, 0, 92) })
						task.delay(0.2, function()
							if not ListOpen then DropList.Visible = false end
						end)
					end
				end

				local function ListConfigs()
					if not listfiles or not isfolder then return {} end
					if not isfolder(Folder) then return {} end
					local files = {}
					for _, f in ipairs(listfiles(Folder)) do
						local name = f:match("([^/\\]+)%.kfg$")
						if name then table.insert(files, name) end
					end
					return files
				end

				local function RefreshDropList()
					for _, c in ipairs(DropList:GetChildren()) do
						if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
					end
					local list = ListConfigs()
					local listH
					if #list == 0 then
						Custom:Create("TextLabel", {
							Font = Enum.Font.GothamBold,
							Text = "No saved configs",
							TextColor3 = Color3.fromRGB(180, 180, 180),
							TextSize = 11,
							Size = UDim2.new(1, 0, 0, 22),
							Name = "EmptyLabel"
						}, DropList)
						listH = 26
					else
						for i, name in ipairs(list) do
							local Cfg = Custom:Create("TextButton", {
								Font = Enum.Font.GothamBold,
								Text = "  " .. name,
								TextColor3 = Color3.fromRGB(230, 230, 230),
								TextSize = 12,
								TextTruncate = Enum.TextTruncate.AtEnd,
								TextXAlignment = Enum.TextXAlignment.Left,
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 0.95,
								LayoutOrder = i,
								Size = UDim2.new(1, 0, 0, 22),
								Name = "Cfg_" .. name
							}, DropList)
							Custom:Create("UICorner", { CornerRadius = UDim.new(0, 3) }, Cfg)
							Custom:Hover(Cfg, Cfg, 0.95, 0.88, 0.8)
							Cfg.Activated:Connect(function()
								NameBox.Text = name
								SelectorLabel.Text = name
								SetListOpen(false)
							end)
						end
						listH = math.min(#list * 24 + 6, 102)
					end
					return listH
				end

				SelectorButton.Activated:Connect(function()
					if ListOpen then
						SetListOpen(false)
					else
						SetListOpen(true, RefreshDropList())
					end
				end)

				local function GetData()
					local data = {}
					for k, v in pairs(Speed_Library.Flags) do
						if type(v) == "table" and v.Value ~= nil then
							data[k] = v.Value
						else
							data[k] = v
						end
					end
					return data
				end

				function Funcs_Save:Save(name)
					name = name or NameBox.Text
					if name == "" then return false, "name empty" end
					if not writefile then return false, "no writefile" end
					local ok, encoded = pcall(function()
						return HttpService:JSONEncode(GetData())
					end)
					if not ok then return false, encoded end
					if isfolder and makefolder and not isfolder(Folder) then makefolder(Folder) end
					writefile(Folder .. "/" .. name .. ".kfg", encoded)
					return true
				end

				function Funcs_Save:Load(name)
					name = name or NameBox.Text
					if name == "" then return false, "name empty" end
					if not readfile or not isfile then return false, "no readfile" end
					local path = Folder .. "/" .. name .. ".kfg"
					if not isfile(path) then return false, "not found" end
					local content = readfile(path)
					local ok, decoded = pcall(function()
						return HttpService:JSONDecode(content)
					end)
					if not ok then return false, decoded end
					for k, v in pairs(decoded) do
						local obj = Speed_Library.Objects[k]
						if obj and obj.Set then
							obj:Set(v)
						else
							Speed_Library.Flags[k] = v
						end
					end
					return true
				end

				local function Flash(Btn, text, ok)
					local original = (Btn.Name:gsub("Btn$", ""))
					Btn.Text = ok and text or "Failed"
					task.delay(1, function()
						if Btn then Btn.Text = original end
					end)
				end

				SaveBtn.Activated:Connect(function()
					CircleClick(SaveBtn)
					local ok = Funcs_Save:Save()
					if ok then SelectorLabel.Text = NameBox.Text end
					Flash(SaveBtn, "Saved", ok)
				end)

				LoadBtn.Activated:Connect(function()
					CircleClick(LoadBtn)
					local ok = Funcs_Save:Load()
					Flash(LoadBtn, "Loaded", ok)
				end)

				return Funcs_Save
			end

			return Item
		end

		CountTab += 1
		return Sections
	end

	-- /// Responsive: re-fit the window whenever the screen size changes
	local function Relayout()
		local w, h, tw = Dims()
		DropShadowHolder.Size = UDim2.fromOffset(w, h)
		LayersTab.Size = UDim2.new(0, tw, 1, -59)
		Layers.Position = UDim2.new(0, tw + 18, 0, 50)
		Layers.Size = UDim2.new(1, -(tw + 27), 1, -59)
		NameTab.TextSize = w < 420 and 20 or 24
		DropShadowHolder.Position = ClampPosition(DropShadowHolder, DropShadowHolder.Position)
		Open_Close.Position = ClampPosition(Open_Close, Open_Close.Position)
	end

	local function HookCamera()
		local cam = workspace.CurrentCamera
		if cam then
			Track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(Relayout))
		end
	end
	HookCamera()
	Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		HookCamera()
		Relayout()
	end))
	Relayout()

	-- Open animation
	Custom:Tween(Scaler, 0.4, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	return Tabs
end

return Speed_Library
