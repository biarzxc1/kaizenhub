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
	-- Try common paths first; fallback gracefully
	local ok, result = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/biarzxc1/kaizenhub/refs/heads/main/Icons.lua"))()
	end)
	if ok and type(result) == "table" then
		Icons = result
	end
end
LoadIcons()

local function ResolveIcon(IconValue)
	if not IconValue or IconValue == "" then return "" end
	if type(IconValue) ~= "string" then return "" end
	-- Already a Roblox asset id
	if string.find(IconValue, "rbxassetid://") or string.find(IconValue, "rbxasset://") then
		return IconValue
	end
	-- Lookup from Icons.lua (lucide-<name>)
	if Icons and Icons.assets then
		local key = string.find(IconValue, "lucide%-") and IconValue or ("lucide-" .. IconValue)
		return Icons.assets[key] or Icons.assets[IconValue] or ""
	end
	return ""
end

local Custom = {} do
	-- Changed from red to white-gradient base color
	Custom.ColorRGB = Color3.fromRGB(245, 245, 245)
	Custom.GradientStart = Color3.fromRGB(255, 255, 255)
	Custom.GradientEnd = Color3.fromRGB(180, 180, 180)

	function Custom:Create(Name, Properties, Parent)
		local _instance = Instance.new(Name)
		for i, v in pairs(Properties) do
			_instance[i] = v
		end
		if Parent then
			_instance.Parent = Parent
		end
		return _instance
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
end

Custom:EnabledAFK()

local function OpenClose()
	local ScreenGui = Custom:Create("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, RunService:IsStudio() and Player.PlayerGui or (gethui and gethui() or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")))

	-- Removed Kaizen logo image; using a clean circular button with icon
	local Close_ImageButton = Custom:Create("ImageButton", {
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.15,
		Position = UDim2.new(0.1021, 0, 0.0743, 0),
		Size = UDim2.new(0, 44, 0, 44),
		Image = ResolveIcon("menu"), -- Lucide menu icon
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
	}, ScreenGui)

	Custom:Create("UICorner", {
		Name = "MainCorner",
		CornerRadius = UDim.new(1, 0), -- circle
	}, Close_ImageButton)

	Custom:Create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1.2,
		Transparency = 0.5,
	}, Close_ImageButton)

	local dragging, dragStart, startPos = false, nil, nil

	local function UpdateDraggable(input)
		local delta = input.Position - dragStart
		Close_ImageButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	Close_ImageButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Close_ImageButton.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	Close_ImageButton.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateDraggable(input)
		end
	end)

	return Close_ImageButton
end

local Open_Close = OpenClose()

local function MakeDraggable(topbarobject, object)
	local dragging, dragStart, startPos = false, nil, nil

	local function UpdatePos(input)
		local delta = input.Position - dragStart
		local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		object.Position = newPos
	end

	topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	topbarobject.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdatePos(input)
		end
	end)
end

function CircleClick(Button, X, Y)
	task.spawn(function()
		Button.ClipsDescendants = true

		local Circle = Instance.new("ImageLabel")
		Circle.Image = "rbxassetid://106471194043211"
		Circle.ImageColor3 = Color3.fromRGB(220, 220, 220)
		Circle.ImageTransparency = 0.85
		Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Circle.BackgroundTransparency = 1
		Circle.ZIndex = 10
		Circle.Name = "Circle"
		Circle.Parent = Button

		local NewX = X - Button.AbsolutePosition.X
		local NewY = Y - Button.AbsolutePosition.Y
		Circle.Position = UDim2.new(0, NewX, 0, NewY)

		local Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5

		local Time = 0.5
		local Info = TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local Tween = TweenService:Create(Circle, Info, {
			Size = UDim2.new(0, Size, 0, Size),
			Position = UDim2.new(0.5, -Size / 2, 0.5, -Size / 2)
		})

		Tween:Play()

		Tween.Completed:Connect(function()
			for i = 1, 10 do
				Circle.ImageTransparency = Circle.ImageTransparency + 0.01
				wait(Time / 10)
			end
			Circle:Destroy()
		end)
	end)
end

local Speed_Library, Notification = {}, {}

Speed_Library.Unloaded = false
Speed_Library.Icons = Icons
Speed_Library.Flags = {} -- For save config

function Speed_Library:SetIcons(IconsTable)
	Icons = IconsTable
	Speed_Library.Icons = IconsTable
end

function Speed_Library:SetNotification(Config)
	local Title = Config[1] or Config.Title or ""
	local Description = Config[2] or Config.Description or ""
	local Content = Config[3] or Config.Content or ""
	local Time = Config[5] or Config.Time or 0.5
	local Delay = Config[6] or Config.Delay or 5

	local NotificationGui = Custom:Create("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, RunService:IsStudio() and Player.PlayerGui or (gethui and gethui() or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")))

	local NotificationLayout = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -30, 1, -30),
		Size = UDim2.new(0, 320, 1, 0),
		Name = "NotificationLayout"
	}, NotificationGui)

	local Count = 0
	NotificationLayout.ChildRemoved:Connect(function()
		Count = 0
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		for _, v in ipairs(NotificationLayout:GetChildren()) do
			local NewPOS = UDim2.new(0, 0, 1, -((v.Size.Y.Offset + 12) * Count))
			TweenService:Create(v, tweenInfo, { Position = NewPOS }):Play()
			Count = Count + 1
		end
	end)

	local _Count = 0
	for _, v in ipairs(NotificationLayout:GetChildren()) do
		_Count = -(v.Position.Y.Offset) + v.Size.Y.Offset + 12
	end

	local NotificationFrame = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 150),
		Name = "NotificationFrame",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -(_Count))
	}, NotificationLayout)

	local NotificationFrameReal = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 400, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Name = "NotificationFrameReal"
	}, NotificationFrame)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, NotificationFrameReal)
	Custom:Create("UIStroke", { Color = Color3.fromRGB(60, 60, 60), Thickness = 1.2, Transparency = 0.4 }, NotificationFrameReal)

	local Top = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		Name = "Top",
		Parent = NotificationFrameReal
	})

	local TextLabel = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Parent = Top
	})

	local TextLabel1 = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = Description,
		TextColor3 = Color3.fromRGB(220, 220, 220),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0),
		Parent = Top
	})

	local TLGrad = Custom:WhiteGradient(TextLabel1, 0)

	local Close = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "X",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -5, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Close",
		Parent = Top
	})

	local TextLabel2 = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		TextSize = 13,
		Text = Content,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 27),
		Size = UDim2.new(1, -20, 0, 13),
		Parent = NotificationFrameReal
	})

	TextLabel2.Size = UDim2.new(1, -20, 0, 13 + (13 * (TextLabel2.TextBounds.X // TextLabel2.AbsoluteSize.X)))
	TextLabel2.TextWrapped = true

	if TextLabel2.AbsoluteSize.Y < 27 then
		NotificationFrame.Size = UDim2.new(1, 0, 0, 65)
	else
		NotificationFrame.Size = UDim2.new(1, 0, 0, TextLabel2.AbsoluteSize.Y + 40)
	end

	local NotificationObject = {}
	local Closing = false

	local function TweenNotificationTransparency(alpha, duration)
		for _, object in ipairs(NotificationFrameReal:GetDescendants()) do
			local props = {}
			if object:IsA("GuiObject") then
				props.BackgroundTransparency = alpha
			end
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				props.TextTransparency = alpha
			end
			if object:IsA("ImageLabel") or object:IsA("ImageButton") then
				props.ImageTransparency = alpha
			end
			if object:IsA("UIStroke") then
				props.Transparency = alpha
			end
			if next(props) then
				pcall(function()
					TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
				end)
			end
		end
	end

	function NotificationObject:Close()
		if Closing then return false end
		Closing = true

		local duration = tonumber(Time) or 0.35
		TweenNotificationTransparency(1, duration)
		TweenService:Create(NotificationFrameReal, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 400, 0, 0), BackgroundTransparency = 1 }):Play()

		task.delay(duration + 0.05, function()
			if NotificationGui then
				NotificationGui:Destroy()
			elseif NotificationFrame then
				NotificationFrame:Destroy()
			end
		end)

		return true
	end

	Close.Activated:Connect(function() NotificationObject:Close() end)
	TweenService:Create(NotificationFrameReal, TweenInfo.new(tonumber(Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 0, 0, 0) }):Play()
	task.delay(tonumber(Delay) or 5, function()
		NotificationObject:Close()
	end)

	return NotificationObject
end

function Speed_Library:CreateWindow(Config)
	-- Default name format: "Kaizen Hub | Version 1.0.0 | by kaizenmeow"
	local Title = Config[1] or Config.Title or "Kaizen Hub"
	local Version = Config.Version or "Version 1.0.0"
	local Author = Config.Author or "by kaizenmeow"
	local Description = Config[2] or Config.Description or (Version .. " | " .. Author)
	local TabWidth = Config[3] or Config["Tab Width"] or 130
	local SizeUi = Config[4] or Config.SizeUi or UDim2.fromOffset(560, 330)

	local Funcs = {}

	local SpeedHubXGui = Custom:Create("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, RunService:IsStudio() and Player.PlayerGui or (gethui and gethui() or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")))

	local DropShadowHolder = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 455, 0, 350),
		ZIndex = 0,
		Name = "DropShadowHolder",
		Position = UDim2.new(0, (SpeedHubXGui.AbsoluteSize.X // 2 - 455 // 2), 0, (SpeedHubXGui.AbsoluteSize.Y // 2 - 350 // 2))
	}, SpeedHubXGui)

	local DropShadow = Custom:Create("ImageLabel", {
		Image = "",
		ImageColor3 = Color3.fromRGB(15, 15, 15),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = SizeUi,
		ZIndex = 0,
		Name = "DropShadow"
	}, DropShadowHolder)

	local Main = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = SizeUi,
		Name = "Main"
	}, DropShadow)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, Main)
	Custom:Create("UIStroke", { Color = Color3.fromRGB(60, 60, 60), Thickness = 1.4, Transparency = 0.3 }, Main)

	local Top = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38),
		Name = "Top"
	}, Main)

	-- Title in white
	local TextLabel = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 12, 0, 0)
	}, Top)

	-- Description (Version + Author) using white gradient
	local TextLabel1 = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = "| " .. Description,
		TextColor3 = Color3.fromRGB(230, 230, 230),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(TextLabel.TextBounds.X + 104), 1, 0),
		Position = UDim2.new(0, TextLabel.TextBounds.X + 18, 0, 0)
	}, Top)

	Custom:WhiteGradient(TextLabel1, 0)

	local Close = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "X",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Close"
	}, Top)

	local Min = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "-",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 22,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -42, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Min"
	}, Top)

	local LayersTab = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 9, 0, 50),
		Size = UDim2.new(0, TabWidth, 1, -59),
		Name = "LayersTab"
	}, Main)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, LayersTab)

	Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 1),
		Name = "DecideFrame"
	}, Main)

	local Layers = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, TabWidth + 18, 0, 50),
		Size = UDim2.new(1, -(TabWidth + 9 + 18), 1, -59),
		Name = "Layers"
	}, Main)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Layers)

	local NameTab = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 24,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Name = "NameTab"
	}, Layers)

	local LayersReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 1, -33),
		Name = "LayersReal"
	}, Layers)

	local LayersFolder = Custom:Create("Folder", { Name = "LayersFolder" }, LayersReal)

	local LayersPageLayout = Custom:Create("UIPageLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Name = "LayersPageLayout",
		TweenTime = 0.5,
		EasingDirection = Enum.EasingDirection.InOut,
		EasingStyle = Enum.EasingStyle.Quad
	}, LayersFolder)

	local ScrollTab = Custom:Create("ScrollingFrame", {
		CanvasSize = UDim2.new(0, 0, 2.10000002, 0),
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = 0,
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -10),
		Name = "ScrollTab"
	}, LayersTab)

	-- Tab spacing constants (used for both ScrollTab and ChooseFrame positioning)
	local TAB_HEIGHT = 30
	local TAB_PADDING = 3

	local UIListLayout = Custom:Create("UIListLayout", {
		Padding = UDim.new(0, TAB_PADDING),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, ScrollTab)

	local function UpdateSize()
		local _Total = 0
		for _, v in pairs(ScrollTab:GetChildren()) do
			if v.Name ~= "UIListLayout" then
				_Total = _Total + TAB_PADDING + v.Size.Y.Offset
			end
		end
		ScrollTab.CanvasSize = UDim2.new(0, 0, 0, _Total)
	end

	ScrollTab.ChildAdded:Connect(UpdateSize)
	ScrollTab.ChildRemoved:Connect(UpdateSize)

	Min.Activated:Connect(function()
		CircleClick(Min, Player:GetMouse().X, Player:GetMouse().Y)
		DropShadowHolder.Visible = false
		if not Open_Close.Visible then Open_Close.Visible = true end
	end)

	Open_Close.Activated:Connect(function()
		DropShadowHolder.Visible = true
		if Open_Close.Visible then Open_Close.Visible = false end
	end)

	Close.Activated:Connect(function()
		CircleClick(Close, Player:GetMouse().X, Player:GetMouse().Y)
		if SpeedHubXGui then SpeedHubXGui:Destroy() end
		if not Speed_Library.Unloaded then Speed_Library.Unloaded = true end
	end)

	DropShadowHolder.Size = UDim2.new(0, 115 + TextLabel.TextBounds.X + 1 + TextLabel1.TextBounds.X, 0, 350)
	MakeDraggable(Top, DropShadowHolder)

	-- /// Blur for dropdown overlay
	local MoreBlur = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(1, 8, 1, 8),
		Size = UDim2.new(1, 154, 1, 54),
		Visible = false,
		Name = "MoreBlur"
	}, Layers)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, MoreBlur)

	local ConnectButton = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		BackgroundTransparency = 0.999,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "ConnectButton"
	}, MoreBlur)

	local DropdownSelect = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(28, 28, 28),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Position = UDim2.new(1, 172, 0.5, 0),
		Size = UDim2.new(0, 170, 1, -16),
		Name = "DropdownSelect",
		ClipsDescendants = true
	}, MoreBlur)

	ConnectButton.Activated:Connect(function()
		if MoreBlur.Visible then
			local tweenInfo = TweenInfo.new(0.2)
			TweenService:Create(MoreBlur, tweenInfo, { BackgroundTransparency = 0.999 }):Play()
			TweenService:Create(DropdownSelect, tweenInfo, { Position = UDim2.new(1, 172, 0.5, 0) }):Play()
			task.wait(0.2)
			MoreBlur.Visible = false
		end
	end)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownSelect })
	Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.4, Transparency = 0.7, Parent = DropdownSelect })

	local DropdownSelectReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -10, 1, -10),
		Name = "DropdownSelectReal",
		Parent = DropdownSelect
	})

	local DropdownFolder = Custom:Create("Folder", { Name = "DropdownFolder", Parent = DropdownSelectReal })

	local DropPageLayout = Custom:Create("UIPageLayout", {
		EasingDirection = Enum.EasingDirection.InOut,
		EasingStyle = Enum.EasingStyle.Quad,
		TweenTime = 0.01,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Archivable = false,
		Name = "DropPageLayout",
		Parent = DropdownFolder
	})

	-- /// Create Tab
	local Tabs = {}
	local CountTab = 0
	local CountDropdown = 0

	function Tabs:CreateTab(Config)
		local _Name = Config[1] or Config.Name or ""
		local Icon = Config[2] or Config.Icon or ""
		local ResolvedIcon = ResolveIcon(Icon)

		local ScrolLayers = Custom:Create("ScrollingFrame", {
			ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
			ScrollBarThickness = 0,
			Active = true,
			LayoutOrder = CountTab,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "ScrolLayers",
			Parent = LayersFolder
		})

		Custom:Create("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ScrolLayers
		})

		local Tab = Custom:Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = CountTab == 0 and 0.92 or 0.999,
			BorderSizePixel = 0,
			LayoutOrder = CountTab,
			Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
			Name = "Tab",
			Parent = ScrollTab
		})

		Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Tab })

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

		Custom:Create("TextLabel", {
			Font = Enum.Font.GothamBold,
			Text = _Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -32, 1, 0),
			Position = UDim2.new(0, 32, 0, 0),
			Name = "TabName"
		}, Tab)

		-- Tab icon (centered vertically, uses Lucide)
		Custom:Create("ImageLabel", {
			Image = ResolvedIcon,
			ImageColor3 = Color3.fromRGB(230, 230, 230),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 9, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Name = "FeatureImg"
		}, Tab)

		if CountTab == 0 then
			LayersPageLayout:JumpToIndex(0)
			NameTab.Text = _Name

			-- Centered ChooseFrame indicator (vertically centered with anchor 0,0.5)
			local ChooseFrame = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Custom.GradientStart,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.new(0, 2, 0, 14),
				Name = "ChooseFrame"
			}, Tab)

			Custom:WhiteGradient(ChooseFrame, 90)
			Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 0.6, Transparency = 0.4 }, ChooseFrame)
			Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, ChooseFrame)
		end

		TabButton.Activated:Connect(function()
			CircleClick(TabButton, Player:GetMouse().X, Player:GetMouse().Y)
			local FrameChoose = nil

			for _, s in pairs(ScrollTab:GetChildren()) do
				for _, v in pairs(s:GetChildren()) do
					if v.Name == "ChooseFrame" then
						FrameChoose = v
						break
					end
				end
				if FrameChoose then break end
			end

			if FrameChoose and Tab.LayoutOrder ~= LayersPageLayout.CurrentPage.LayoutOrder then
				for _, TabFrame in pairs(ScrollTab:GetChildren()) do
					if TabFrame.Name == "Tab" then
						TweenService:Create(TabFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.999 }):Play()
					end
				end

				-- Reparent ChooseFrame to selected tab so it stays vertically centered
				FrameChoose.Parent = Tab
				FrameChoose.AnchorPoint = Vector2.new(0, 0.5)
				FrameChoose.Position = UDim2.new(0, 2, 0.5, 0)

				TweenService:Create(Tab, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.92 }):Play()

				LayersPageLayout:JumpToIndex(Tab.LayoutOrder)

				task.wait(0.05)
				NameTab.Text = _Name

				TweenService:Create(FrameChoose, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Size = UDim2.new(0, 2, 0, 22) }):Play()
				task.wait(0.2)
				TweenService:Create(FrameChoose, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Size = UDim2.new(0, 2, 0, 14) }):Play()
			end
		end)

		--- /// Section
		local Sections, CountSection = {}, 0

		function Sections:AddSection(TitleArg, OpenSection)
			local Title = TitleArg or ""
			local OpenSection = OpenSection or false

			local Section = Custom:Create("Frame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = CountSection,
				Size = UDim2.new(1, 0, 0, 30),
				Name = "Section"
			}, ScrolLayers)

			local SectionReal = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.935,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(1, 1, 0, 30),
				Name = "SectionReal"
			}, Section)

			Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SectionReal)

			local SectionButton = Custom:Create("TextButton", {
				Font = Enum.Font.SourceSans,
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				BackgroundTransparency = 0.999,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "SectionButton"
			}, SectionReal)

			local FeatureFrame = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 0.999,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -5, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				Name = "FeatureFrame"
			}, SectionReal)

			local FeatureImg = Custom:Create("ImageLabel", {
				Image = "rbxassetid://125609963478878",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 0.999,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = -90,
				Size = UDim2.new(1, 6, 1, 6),
				Name = "FeatureImg"
			}, FeatureFrame)

			local SectionTitle = Custom:Create("TextLabel", {
				Font = Enum.Font.GothamBold,
				Text = Title,
				TextColor3 = Color3.fromRGB(230, 230, 230),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 0.999,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.new(1, -50, 0, 13),
				Name = "SectionTitle"
			}, SectionReal)

			local SectionDecideFrame = Custom:Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 33),
				Size = UDim2.new(0, 0, 0, 2),
				Name = "SectionDecideFrame"
			}, Section)
			Custom:Create("UICorner", {}, SectionDecideFrame)
			-- White gradient (replaces red)
			Custom:Create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
				})
			}, SectionDecideFrame)

			local SectionAdd = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 0.999,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 0, 38),
				Size = UDim2.new(1, 0, 0, 100),
				Name = "SectionAdd"
			}, Section)

			Custom:Create("UICorner", { CornerRadius = UDim.new(0, 2) }, SectionAdd)

			Custom:Create("UIListLayout", {
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder
			}, SectionAdd)

			local function UpdateSizeScroll()
				local OffsetY = 0
				for _, child in pairs(ScrolLayers:GetChildren()) do
					if child.Name ~= "UIListLayout" then
						OffsetY = OffsetY + 3 + child.Size.Y.Offset
					end
				end
				ScrolLayers.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
			end

			local function UpdateSizeSection()
				if OpenSection then
					local SectionSizeYWitdh = 38
					for _, v in pairs(SectionAdd:GetChildren()) do
						if v.Name ~= "UIListLayout" and v.Name ~= "UICorner" then
							SectionSizeYWitdh = SectionSizeYWitdh + v.Size.Y.Offset + 3
						end
					end

					TweenService:Create(FeatureFrame, TweenInfo.new(0.1), { Rotation = 90 }):Play()
					TweenService:Create(Section, TweenInfo.new(0.1), { Size = UDim2.new(1, 1, 0, SectionSizeYWitdh) }):Play()
					TweenService:Create(SectionAdd, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, SectionSizeYWitdh - 38) }):Play()
					TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, 2) }):Play()

					task.wait(0.5)
					UpdateSizeScroll()
				end
			end

			local function ToggleSection()
				CircleClick(SectionButton, Player:GetMouse().X, Player:GetMouse().Y)
				if OpenSection then
					TweenService:Create(FeatureFrame, TweenInfo.new(0.1), { Rotation = 0 }):Play()
					TweenService:Create(Section, TweenInfo.new(0.1), { Size = UDim2.new(1, 1, 0, 30) }):Play()
					TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), { Size = UDim2.new(0, 0, 0, 2) }):Play()
					OpenSection = false
					task.wait(0.1)
					UpdateSizeScroll()
				else
					OpenSection = true
					UpdateSizeSection()
				end
			end

			SectionButton.Activated:Connect(ToggleSection)
			SectionAdd.ChildAdded:Connect(UpdateSizeSection)
			SectionAdd.ChildRemoved:Connect(UpdateSizeSection)

			UpdateSizeScroll()

			local Item, ItemCount = {}, 0

			function Item:AddParagraph(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local SettingFuncs = {}

				local Paragraph = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Paragraph"
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Paragraph)

				local ParagraphTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -16, 0, 13),
					Name = "ParagraphTitle"
				}, Paragraph)

				local ParagraphContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Name = "ParagraphContent"
				}, Paragraph)

				local function UpdateParagraphSize()
					ParagraphContent.TextWrapped = false
					local lineCount = math.ceil(ParagraphContent.TextBounds.X / ParagraphContent.AbsoluteSize.X)
					ParagraphContent.Size = UDim2.new(1, -16, 0, 12 + (12 * lineCount))
					Paragraph.Size = UDim2.new(1, 0, 0, ParagraphContent.AbsoluteSize.Y + 33)
					ParagraphContent.TextWrapped = true
					UpdateSizeSection()
				end

				UpdateParagraphSize()
				ParagraphContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateParagraphSize)

				function SettingFuncs:Set(Config)
					local Title = Config[1] or Config.Title or ""
					local Content = Config[2] or Config.Content or ""
					ParagraphTitle.Text = Title
					ParagraphContent.Text = Content
					UpdateParagraphSize()
				end

				return SettingFuncs
			end

			function Item:AddSeperator(Config)
				local Title = Config[1] or Config.Title or ""
				local Sep_Funcs = {}

				local Seperator = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(70, 70, 70),
					BackgroundTransparency = 0.1,
					BorderSizePixel = 1,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 30),
					Name = "Seperator"
				}, SectionAdd)

				local SeperatorTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					TextStrokeTransparency = 0.8,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -16, 1, 0),
					Name = "SeperatorTitle"
				}, Seperator)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, Seperator)

				function Sep_Funcs:Set(Config)
					local Title = Config[1] or Config.Title or ""
					SeperatorTitle.Text = Title
				end

				ItemCount += 1
				return Sep_Funcs
			end

			function Item:AddLine()
				local LineFuncs = {}
				local Line = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(90, 90, 90),
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 7),
					Name = "Line"
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 3) }, Line)
				Custom:WhiteGradient(Line, 0)

				ItemCount += 1
				return LineFuncs
			end

			function Item:AddButton(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Icon = Config[3] or Config.Icon or "play"
				local Callback = Config[4] or Config.Callback or function() end
				local Funcs_Button = {}

				local Button = Custom:Create("Frame", {
					Name = "Button",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35)
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Button)

				Custom:Create("TextLabel", {
					Name = "ButtonTitle",
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -100, 0, 13)
				}, Button)

				local ButtonContent = Custom:Create("TextLabel", {
					Name = "ButtonContent",
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -100, 0, 12)
				}, Button)

				local function UpdateButtonSize()
					local _Height = 12 + (12 * (ButtonContent.TextBounds.X // ButtonContent.AbsoluteSize.X))
					ButtonContent.Size = UDim2.new(1, -100, 0, _Height)
					Button.Size = UDim2.new(1, 0, 0, ButtonContent.AbsoluteSize.Y + 33)
				end

				ButtonContent.TextWrapped = true
				UpdateButtonSize()

				ButtonContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					ButtonContent.TextWrapped = false
					UpdateButtonSize()
					ButtonContent.TextWrapped = true
					UpdateSizeSection()
				end)

				local ButtonButton = Custom:Create("TextButton", {
					Name = "ButtonButton",
					Font = Enum.Font.SourceSans,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0)
				}, Button)

				local FeatureFrame1 = Custom:Create("Frame", {
					Name = "FeatureFrame",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -15, 0.5, 0),
					Size = UDim2.new(0, 25, 0, 25)
				}, Button)

				Custom:Create("ImageLabel", {
					Name = "FeatureImg",
					Image = ResolveIcon(Icon),
					ImageColor3 = Color3.fromRGB(230, 230, 230),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 1, 0)
				}, FeatureFrame1)

				ButtonButton.Activated:Connect(function()
					CircleClick(ButtonButton, Player:GetMouse().X, Player:GetMouse().Y)
					Callback()
				end)

				ItemCount += 1
				return Funcs_Button
			end

			function Item:AddToggle(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or false
				local Callback = Config[4] or Config.Callback or function() end
				local Flag = Config.Flag or Config[5]

				local Funcs_Toggle = { Value = Default }

				local Toggle = Custom:Create("Frame", {
					Name = "Toggle",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35)
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Toggle)

				local ToggleTitle = Custom:Create("TextLabel", {
					Name = "ToggleTitle",
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextSize = 13,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -100, 0, 13)
				}, Toggle)

				local ToggleContent = Custom:Create("TextLabel", {
					Name = "ToggleContent",
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextSize = 12,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -100, 0, 12)
				}, Toggle)

				local function UpdateToggleSize()
					ToggleContent.TextWrapped = false
					local Ratio = ToggleContent.TextBounds.X / ToggleContent.AbsoluteSize.X
					ToggleContent.Size = UDim2.new(1, -100, 0, 12 + (12 * math.ceil(Ratio)))
					Toggle.Size = UDim2.new(1, 0, 0, ToggleContent.AbsoluteSize.Y + 33)
					ToggleContent.TextWrapped = true
				end

				UpdateToggleSize()

				ToggleContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					UpdateToggleSize()
					UpdateSizeSection()
				end)

				local ToggleButton = Custom:Create("TextButton", {
					Name = "ToggleButton",
					Font = Enum.Font.SourceSans,
					Text = "",
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0)
				}, Toggle)

				local FeatureFrame2 = Custom:Create("Frame", {
					Name = "FeatureFrame2",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -15, 0.5, 0),
					Size = UDim2.new(0, 32, 0, 16)
				}, Toggle)

				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, FeatureFrame2)
				local UIStroke8 = Custom:Create("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 1.4,
					Transparency = 0.85
				}, FeatureFrame2)

				local ToggleCircle = Custom:Create("Frame", {
					Name = "ToggleCircle",
					BackgroundColor3 = Color3.fromRGB(230, 230, 230),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(0, 1, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5)
				}, FeatureFrame2)

				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, ToggleCircle)

				local function ToggleAnimation(isOn)
					local TitleColor = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(230, 230, 230)
					local CirclePosition = isOn and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 1, 0.5, 0)
					local CircleAnchor = isOn and Vector2.new(0, 0.5) or Vector2.new(0, 0.5)
					local StrokeColor = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 255, 255)
					local StrokeTransparency = isOn and 0.2 or 0.85
					local FrameColor = isOn and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(255, 255, 255)
					local FrameTransparency = isOn and 0 or 0.92

					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
					TweenService:Create(ToggleTitle, tweenInfo, { TextColor3 = TitleColor }):Play()
					TweenService:Create(ToggleCircle, tweenInfo, { Position = CirclePosition }):Play()
					TweenService:Create(UIStroke8, tweenInfo, { Color = StrokeColor, Transparency = StrokeTransparency }):Play()
					TweenService:Create(FeatureFrame2, tweenInfo, { BackgroundColor3 = FrameColor, BackgroundTransparency = FrameTransparency }):Play()
				end

				ToggleButton.Activated:Connect(function()
					CircleClick(ToggleButton, Player:GetMouse().X, Player:GetMouse().Y)
					Funcs_Toggle.Value = not Funcs_Toggle.Value
					Funcs_Toggle:Set(Funcs_Toggle.Value)
				end)

				function Funcs_Toggle:Set(Value)
					Funcs_Toggle.Value = Value
					if Flag then Speed_Library.Flags[Flag] = Value end
					Callback(Value)
					ToggleAnimation(Value)
				end
				Funcs_Toggle:Set(Funcs_Toggle.Value)

				if Flag then Speed_Library.Flags[Flag] = Funcs_Toggle end

				ItemCount += 1
				return Funcs_Toggle
			end

			-- /// IMPROVED SLIDER ///
			function Item:AddSlider(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Increment = Config[3] or Config.Increment or 1
				local MinV = Config[4] or Config.Min or 0
				local MaxV = Config[5] or Config.Max or 100
				local Default = Config[6] or Config.Default or 50
				local Callback = Config[7] or Config.Callback or function() end
				local Flag = Config.Flag

				local Funcs_Slider = { Value = Default }

				local Slider = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 50),
					Name = "Slider"
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Slider)

				local SliderTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 8),
					Size = UDim2.new(1, -70, 0, 13),
					Name = "SliderTitle"
				}, Slider)

				local SliderContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 11,
					TextTransparency = 0.55,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 22),
					Size = UDim2.new(1, -70, 0, 11),
					Name = "SliderContent"
				}, Slider)

				-- Value display TextBox (top-right)
				local ValueBox = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					Text = tostring(Default),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Center,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -10, 0, 8),
					Size = UDim2.new(0, 50, 0, 18),
					Name = "ValueBox"
				}, Slider)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, ValueBox)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.7 }, ValueBox)

				-- Slider track (full-width, bottom)
				local SliderFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					BackgroundColor3 = Color3.fromRGB(60, 60, 60),
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 1, -10),
					Size = UDim2.new(1, -20, 0, 5),
					Name = "SliderFrame"
				}, Slider)
				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, SliderFrame)

				-- Filled draggable portion with white gradient
				local SliderDraggable = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromScale(0.5, 1),
					Name = "SliderDraggable"
				}, SliderFrame)
				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, SliderDraggable)
				Custom:WhiteGradient(SliderDraggable, 0)

				-- Slider knob
				local SliderCircle = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
					Name = "SliderCircle"
				}, SliderDraggable)
				Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, SliderCircle)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(200, 200, 200), Thickness = 1, Transparency = 0.4 }, SliderCircle)

				local Dragging = false

				local function Round(Number, Factor)
					local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
					if Result < 0 then Result = Result + Factor end
					return Result
				end

				function Funcs_Slider:Set(Value)
					Value = math.clamp(Round(Value, Increment), MinV, MaxV)
					Funcs_Slider.Value = Value
					ValueBox.Text = tostring(Value)
					if Flag then Speed_Library.Flags[Flag] = Value end
					TweenService:Create(SliderDraggable, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale((Value - MinV) / (MaxV - MinV), 1) }):Play()
				end

				SliderFrame.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Dragging = true
					end
				end)

				SliderFrame.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Dragging = false
						Callback(Funcs_Slider.Value)
					end
				end)

				local _LastX = nil
				UserInputService.InputChanged:Connect(function(Input)
					if Dragging then
						local CurrPosX = Input.Position.X
						if CurrPosX ~= _LastX then
							_LastX = CurrPosX
							local SizeScale = math.clamp((CurrPosX - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
							Funcs_Slider:Set(MinV + ((MaxV - MinV) * SizeScale))
						end
					end
				end)

				ValueBox:GetPropertyChangedSignal("Text"):Connect(function()
					local Valid = ValueBox.Text:gsub("[^%d]", "")
					if Valid ~= "" then
						local ValidNumber = math.min(tonumber(Valid), MaxV)
						if tostring(ValidNumber) ~= ValueBox.Text then
							ValueBox.Text = tostring(ValidNumber)
						end
					end
				end)

				ValueBox.FocusLost:Connect(function()
					if ValueBox.Text ~= "" then
						Funcs_Slider:Set(tonumber(ValueBox.Text) or MinV)
					else
						Funcs_Slider:Set(MinV)
					end
					Callback(Funcs_Slider.Value)
				end)

				Funcs_Slider:Set(tonumber(Default))
				Callback(Funcs_Slider.Value)

				ItemCount += 1
				return Funcs_Slider
			end

			function Item:AddInput(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or ""
				local Callback = Config[4] or Config.Callback or function() end
				local Flag = Config.Flag
				local Funcs_Input = { Value = Default }

				local Input = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Input"
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Input)

				local InputTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "InputTitle"
				}, Input)

				local InputContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -180, 0, 12),
					Name = "InputContent",
					Parent = Input
				})

				local function UpdateInputSize()
					local Ratio = InputContent.TextBounds.X / InputContent.AbsoluteSize.X
					local Calculated = 12 + (12 * math.floor(Ratio))
					InputContent.Size = UDim2.new(1, -180, 0, Calculated)
					Input.Size = UDim2.new(1, 0, 0, InputContent.AbsoluteSize.Y + 33)
				end

				UpdateInputSize()
				InputContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					InputContent.TextWrapped = false
					UpdateInputSize()
					InputContent.TextWrapped = true
					UpdateSizeSection()
				end)

				local InputFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.95,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Position = UDim2.new(1, -7, 0.5, 0),
					Size = UDim2.new(0, 148, 0, 24),
					Name = "InputFrame"
				}, Input)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, InputFrame)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, InputFrame)

				local InputTextBox = Custom:Create("TextBox", {
					CursorPosition = -1,
					Font = Enum.Font.GothamBold,
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					PlaceholderText = "Write your input there",
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.new(1, -16, 1, -4),
					Name = "InputTextBox"
				}, InputFrame)

				function Funcs_Input:Set(Value)
					InputTextBox.Text = Value
					Funcs_Input.Value = Value
					if Flag then Speed_Library.Flags[Flag] = Value end
					Callback(Value)
				end

				InputTextBox.FocusLost:Connect(function()
					Funcs_Input:Set(InputTextBox.Text)
				end)

				Funcs_Input:Set(Default)

				ItemCount += 1
				return Funcs_Input
			end

			-- Internal helper to build dropdown overlay options
			local function _buildDropdown(Config, Multi)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Options = Config.Options or Config[4] or {}
				local Default = Config.Default or Config[5] or (Multi and {} or {})
				local Callback = Config.Callback or Config[6] or function() end
				local Flag = Config.Flag

				if not Multi and type(Default) == "string" then Default = { Default } end

				local Funcs_Dropdown = { Value = Default, Options = Options }

				local Dropdown = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Dropdown"
				}, SectionAdd)

				local DropdownButton = Custom:Create("TextButton", {
					Font = Enum.Font.SourceSans,
					Text = "",
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "ToggleButton"
				}, Dropdown)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Dropdown)

				Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "DropdownTitle",
					Parent = Dropdown
				})

				local DropdownContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -180, 0, 12),
					Name = "DropdownContent",
					Parent = Dropdown
				})

				DropdownContent.Size = UDim2.new(1, -180, 0, 12 + (12 * (DropdownContent.TextBounds.X // DropdownContent.AbsoluteSize.X)))
				DropdownContent.TextWrapped = true
				Dropdown.Size = UDim2.new(1, 0, 0, DropdownContent.AbsoluteSize.Y + 33)

				DropdownContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					DropdownContent.TextWrapped = false
					DropdownContent.Size = UDim2.new(1, -180, 0, 12 + (12 * (DropdownContent.TextBounds.X // DropdownContent.AbsoluteSize.X)))
					Dropdown.Size = UDim2.new(1, 0, 0, DropdownContent.AbsoluteSize.Y + 33)
					DropdownContent.TextWrapped = true
					UpdateSizeSection()
				end)

				local SelectOptionsFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.95,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -7, 0.5, 0),
					Size = UDim2.new(0, 148, 0, 26),
					Name = "SelectOptionsFrame",
					LayoutOrder = CountDropdown
				}, Dropdown)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SelectOptionsFrame)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, SelectOptionsFrame)

				DropdownButton.Activated:Connect(function()
					if not MoreBlur.Visible then
						MoreBlur.Visible = true
						local tweenInfo = TweenInfo.new(0.1)
						DropPageLayout:JumpToIndex(SelectOptionsFrame.LayoutOrder)
						TweenService:Create(MoreBlur, tweenInfo, { BackgroundTransparency = 0.7 }):Play()
						TweenService:Create(DropdownSelect, tweenInfo, { Position = UDim2.new(1, -11, 0.5, 0) }):Play()
					end
				end)

				local OptionSelecting = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = "Select Options",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.4,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.new(1, -30, 1, -8),
					Name = "OptionSelecting"
				}, SelectOptionsFrame)

				Custom:Create("ImageLabel", {
					Image = ResolveIcon("chevron-down"),
					ImageColor3 = Color3.fromRGB(231, 231, 231),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -4, 0.5, 0),
					Size = UDim2.new(0, 16, 0, 16),
					Name = "OptionImg"
				}, SelectOptionsFrame)

				local ScrollSelect = Custom:Create("ScrollingFrame", {
					CanvasSize = UDim2.new(0, 0, 0, 0),
					ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
					ScrollBarThickness = 0,
					Active = true,
					LayoutOrder = CountDropdown,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "ScrollSelect"
				}, DropdownFolder)

				Custom:Create("UIListLayout", {
					Padding = UDim.new(0, 3),
					SortOrder = Enum.SortOrder.LayoutOrder
				}, ScrollSelect)

				local SearchBar = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					PlaceholderText = "Search",
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 22),
					Name = "SearchBar"
				}, ScrollSelect)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, SearchBar)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, SearchBar)

				SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
					local SearchText = string.lower(SearchBar.Text)
					for _, v in pairs(ScrollSelect:GetChildren()) do
						if v:IsA("Frame") and v.Name == "Option" then
							local OptionText = v:FindFirstChild("OptionText")
							if OptionText then
								v.Visible = string.find(string.lower(OptionText.Text), SearchText) ~= nil
							end
						end
					end
				end)

				local DropCount = 0

				function Funcs_Dropdown:Clear()
					for _, DropFrame in pairs(ScrollSelect:GetChildren()) do
						if DropFrame.Name == "Option" then
							Funcs_Dropdown.Value = {}
							Funcs_Dropdown.Options = {}
							OptionSelecting.Text = "Select Options"
							DropFrame:Destroy()
						end
					end
				end

				function Funcs_Dropdown:Set(Value)
					Funcs_Dropdown.Value = Value or Funcs_Dropdown.Value

					for _, Drop in pairs(ScrollSelect:GetChildren()) do
						if Drop.Name == "Option" then
							local isTextFound = table.find(Funcs_Dropdown.Value, Drop.OptionText.Text)
							local tweenInfoInOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

							local Size = isTextFound and UDim2.new(0, 2, 0, 14) or UDim2.new(0, 0, 0, 0)
							local BackgroundTransparency = isTextFound and 0.92 or 0.999
							local Transparency = isTextFound and 0 or 0.999

							TweenService:Create(Drop.ChooseFrame, tweenInfoInOut, { Size = Size }):Play()
							TweenService:Create(Drop.ChooseFrame.UIStroke, tweenInfoInOut, { Transparency = Transparency }):Play()
							TweenService:Create(Drop, tweenInfoInOut, { BackgroundTransparency = BackgroundTransparency }):Play()
						end
					end

					local DropdownValueTable = table.concat(Funcs_Dropdown.Value, ", ")
					OptionSelecting.Text = DropdownValueTable ~= "" and DropdownValueTable or "Select Options"
					if Flag then Speed_Library.Flags[Flag] = Funcs_Dropdown.Value end
					Callback(Multi and Funcs_Dropdown.Value or Funcs_Dropdown.Value[1])
				end

				function Funcs_Dropdown:AddOption(OptionName)
					OptionName = OptionName or "Option"

					local Option = Custom:Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.999,
						BorderSizePixel = 0,
						LayoutOrder = DropCount,
						Size = UDim2.new(1, 0, 0, 28),
						Name = "Option"
					}, ScrollSelect)

					Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Option)

					local OptionButton = Custom:Create("TextButton", {
						Font = Enum.Font.GothamBold,
						Text = "",
						BackgroundTransparency = 0.999,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "OptionButton"
					}, Option)

					Custom:Create("TextLabel", {
						Font = Enum.Font.GothamBold,
						Text = OptionName,
						TextSize = 13,
						TextColor3 = Color3.fromRGB(230, 230, 230),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						BackgroundTransparency = 0.999,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -16, 1, 0),
						Name = "OptionText"
					}, Option)

					-- Centered selection indicator (white)
					local ChooseFrame = Custom:Create("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 3, 0.5, 0),
						Size = UDim2.new(0, 0, 0, 0),
						Name = "ChooseFrame"
					}, Option)

					Custom:WhiteGradient(ChooseFrame, 90)
					Custom:Create("UIStroke", {
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1.2,
						Transparency = 0.999
					}, ChooseFrame)

					Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, ChooseFrame)

					OptionButton.Activated:Connect(function()
						CircleClick(OptionButton, Player:GetMouse().X, Player:GetMouse().Y)
						local isOptionSelected = Option.BackgroundTransparency > 0.95

						if Multi then
							if isOptionSelected then
								if not table.find(Funcs_Dropdown.Value, OptionName) then
									table.insert(Funcs_Dropdown.Value, OptionName)
								end
							else
								for i, value in ipairs(Funcs_Dropdown.Value) do
									if value == OptionName then
										table.remove(Funcs_Dropdown.Value, i)
										break
									end
								end
							end
						else
							Funcs_Dropdown.Value = { OptionName }
						end

						Funcs_Dropdown:Set(Funcs_Dropdown.Value)
					end)

					local function UpdateCanvasSize()
						local OffsetY = 0
						for _, child in ipairs(ScrollSelect:GetChildren()) do
							if child.Name ~= "UIListLayout" and child.Name ~= "SearchBar" then
								OffsetY = OffsetY + 5 + child.Size.Y.Offset
							end
						end
						ScrollSelect.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
					end

					UpdateCanvasSize()
					DropCount += 1
				end

				function Funcs_Dropdown:Refresh(RefreshList, Selecting)
					RefreshList = RefreshList or {}
					Selecting = Selecting or {}
					Funcs_Dropdown:Clear()
					for _, Drop in ipairs(RefreshList) do
						Funcs_Dropdown:AddOption(Drop)
					end
					Funcs_Dropdown.Options = RefreshList
					Funcs_Dropdown:Set(Selecting)
				end

				Funcs_Dropdown:Refresh(Funcs_Dropdown.Options, Funcs_Dropdown.Value)

				ItemCount += 1
				CountDropdown += 1
				return Funcs_Dropdown
			end

			function Item:AddDropdown(Config)
				local Multi = Config[3]
				if Multi == nil then Multi = Config.Multi end
				if Multi == nil then Multi = false end
				return _buildDropdown(Config, Multi)
			end

			-- /// NEW: AddSelect (single-pick clean dropdown) ///
			function Item:AddSelect(Config)
				return _buildDropdown(Config, false)
			end

			-- /// NEW: AddSaveConfig (save/load config) ///
			function Item:AddSaveConfig(Config)
				Config = Config or {}
				local Title = Config.Title or "Configuration"
				local Folder = Config.Folder or "KaizenHub"
				local DefaultName = Config.Default or "default"
				local Funcs_Save = {}

				if not isfolder then
					-- environment safety
				else
					if not isfolder(Folder) then makefolder(Folder) end
				end

				local Container = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 92),
					Name = "SaveConfig"
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Container)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.88 }, Container)

				Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 8),
					Size = UDim2.new(1, -20, 0, 14),
					Name = "Title"
				}, Container)

				-- Name input
				local NameFrame = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 28),
					Size = UDim2.new(1, -20, 0, 24),
					Name = "NameFrame"
				}, Container)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, NameFrame)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.85 }, NameFrame)

				local NameBox = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					PlaceholderText = "Config Name",
					PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
					Text = DefaultName,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -16, 1, 0),
					Name = "NameBox"
				}, NameFrame)

				-- Selected config dropdown overlay (simple list, picks file)
				local SelectorFrame = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					BorderSizePixel = 0,
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
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 0.999,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -28, 1, 0),
					Name = "SelectorLabel"
				}, SelectorFrame)

				Custom:Create("ImageLabel", {
					Image = ResolveIcon("chevron-down"),
					ImageColor3 = Color3.fromRGB(230, 230, 230),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 0.999,
					Position = UDim2.new(1, -4, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
				}, SelectorFrame)

				local SelectorButton = Custom:Create("TextButton", {
					Text = "",
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "SelectorButton"
				}, SelectorFrame)

				-- Action buttons (Save / Load) using white gradient
				local function MakeActionButton(text, posXScale, posXOffset, sizeXScale, sizeXOffset)
					local Btn = Custom:Create("TextButton", {
						Font = Enum.Font.GothamBold,
						Text = text,
						TextColor3 = Color3.fromRGB(20, 20, 20),
						TextSize = 12,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						Position = UDim2.new(posXScale, posXOffset, 0, 56),
						Size = UDim2.new(sizeXScale, sizeXOffset, 0, 26),
						Name = text .. "Btn"
					}, Container)
					Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, Btn)
					Custom:WhiteGradient(Btn, 90)
					return Btn
				end

				local SaveBtn = MakeActionButton("Save", 0.5, 5, 0.25, -10)
				local LoadBtn = MakeActionButton("Load", 0.75, 5, 0.25, -15)

				-- Selector dropdown (simple toggle list)
				local DropList = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 1, 4),
					Size = UDim2.new(1, 0, 0, 0),
					Visible = false,
					ClipsDescendants = true,
					ZIndex = 5,
					Name = "DropList"
				}, SelectorFrame)
				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, DropList)
				Custom:Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.8 }, DropList)
				Custom:Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, DropList)

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
						if c:IsA("TextButton") then c:Destroy() end
					end
					local list = ListConfigs()
					if #list == 0 then
						local empty = Custom:Create("TextLabel", {
							Font = Enum.Font.GothamBold,
							Text = "No saved configs",
							TextColor3 = Color3.fromRGB(180, 180, 180),
							TextSize = 11,
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 22),
							ZIndex = 6,
							Name = "EmptyLabel"
						}, DropList)
						DropList.Size = UDim2.new(1, 0, 0, 26)
					else
						for i, name in ipairs(list) do
							local Item = Custom:Create("TextButton", {
								Font = Enum.Font.GothamBold,
								Text = "  " .. name,
								TextColor3 = Color3.fromRGB(230, 230, 230),
								TextSize = 12,
								TextXAlignment = Enum.TextXAlignment.Left,
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 0.95,
								BorderSizePixel = 0,
								LayoutOrder = i,
								Size = UDim2.new(1, -4, 0, 22),
								Position = UDim2.new(0, 2, 0, 0),
								ZIndex = 6,
								Name = "Cfg_" .. name
							}, DropList)
							Custom:Create("UICorner", { CornerRadius = UDim.new(0, 3) }, Item)
							Item.Activated:Connect(function()
								NameBox.Text = name
								SelectorLabel.Text = name
								DropList.Visible = false
							end)
						end
						DropList.Size = UDim2.new(1, 0, 0, math.min(#list, 4) * 24 + 4)
					end
				end

				SelectorButton.Activated:Connect(function()
					DropList.Visible = not DropList.Visible
					if DropList.Visible then RefreshDropList() end
				end)

				-- Save / Load functions
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
					if isfolder and not isfolder(Folder) then makefolder(Folder) end
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
						local flag = Speed_Library.Flags[k]
						if type(flag) == "table" and flag.Set then
							flag:Set(v)
						else
							Speed_Library.Flags[k] = v
						end
					end
					return true
				end

				SaveBtn.Activated:Connect(function()
					CircleClick(SaveBtn, Player:GetMouse().X, Player:GetMouse().Y)
					Funcs_Save:Save()
					SelectorLabel.Text = NameBox.Text
				end)

				LoadBtn.Activated:Connect(function()
					CircleClick(LoadBtn, Player:GetMouse().X, Player:GetMouse().Y)
					Funcs_Save:Load()
				end)

				ItemCount += 1
				return Funcs_Save
			end

			ItemCount += 1
			return Item
		end

		CountTab += 1
		return Sections
	end

	return Tabs
end

return Speed_Library
