-- CodeBot V2 | Roblox Luau (Delta / mobile compatible)
-- The S: ATOM-style GUI + ESP + Orbit HVH + Auto Block + Halloween farm

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local StatsService = game:GetService("Stats")
local player = Players.LocalPlayer

-- how fast the window / floating buttons follow your finger (1 = same speed as the finger)
local DRAG_SPEED = 0.7

-- stop any previous copy of this script before starting a new one
if getgenv().TheS_Cleanup then pcall(getgenv().TheS_Cleanup) end

if not Drawing then
	warn("CodeBot: your executor has no Drawing library, ESP will not render.")
end

getgenv().Config = {
	ESPEnabled = true,
	BoxEnabled = true,
	NameEnabled = true,
	TracerEnabled = true,
	HealthBarEnabled = true,
	OrbitVisualEnabled = true,
	LaserRaysEnabled = true,
	TargetBoxEnabled = true,
	ESPMaxDistance = 3000,

	HVHEnabled = false,
	TargetClosest = true,
	TargetName = "",
	SpinSpeed = 20000, -- degrees per second (slider max 20000)
	Radius = 6,

	DoorESPEnabled = true,
	SkeletonESPEnabled = true,
	InstantInteractEnabled = true,
	AutoFarmDoors = false,
	KillAuraSkeletons = false,
	DoorShowDistance = true,
	InvisibleFarming = true,
	DoorTravelSpeed = 200,
	FlyHeight = 80,
	OpenTimeout = 6,
	KillFarmEnabled = false,
	KillFarmRole = "Killer",
	KillFarmSpeed = 385,
	UseIdleSpot = true,
	StableCamera = true,

	AutoBlockEnabled = false,
	MobileBlockButton = true,
	OnlyLockedTarget = false,
	OnlyBlockAngle = false,
	ShowAngle = false,
	OnlySelectedTarget = false,
	SelectedTarget = "None",
	BlockRange = 20,
	BlockAngle = 90,
	BlockKey = "F",
	PunishEnabled = false,
	DashPunish = true,
	PunishRange = 25,
	DashPunishDelay = 0.05,
	M1CatchRange = 30,
	DashKey = "Q",
	PumpkinESPEnabled = true,
	PlayerHighlightEnabled = true,

	SpeedHackEnabled = false,
	WalkSpeedValue = 200,
	InfJumpEnabled = false,
	NoclipEnabled = false,

	HighlightColor = Color3.fromRGB(0, 255, 120),
	PumpkinColor = Color3.fromRGB(255, 100, 0),
	DoorColor = Color3.fromRGB(255, 200, 0),
	SkeletonColor = Color3.fromRGB(255, 0, 0),
	ESPColor = Color3.fromRGB(255, 255, 255),
	BoxColor = Color3.fromRGB(0, 255, 120),
	TracerColor = Color3.fromRGB(0, 255, 120),
	HealthBarColor = Color3.fromRGB(0, 255, 0),
	OrbitColor = Color3.fromRGB(150, 0, 255),
	LaserColor = Color3.fromRGB(0, 150, 255),
	TargetLineColor = Color3.fromRGB(255, 0, 0),
}

local Character, Humanoid, HumanoidRootPart
local hvhTarget = nil -- locked target while HVH is on

local function UpdateCharacter(newChar)
	Character = newChar
	Humanoid = newChar:WaitForChild("Humanoid", 5)
	HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 5)
end
if player.Character then UpdateCharacter(player.Character) end
player.CharacterAdded:Connect(UpdateCharacter)

local function getGuiParent()
	local ok, result = pcall(function()
		if gethui then return gethui() end
		return game:GetService("CoreGui")
	end)
	if ok and result then return result end
	return player:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()

---------------------------------------------------------------------
-- ATOM-STYLE GUI SETTINGS
---------------------------------------------------------------------
local DESIGN_W, DESIGN_H = 1816, 950
local SIDE_W = 405
local HEAD_H = 125
local PROFILE_H = 120

local F = {
	Reg = Enum.Font.Gotham,
	Med = Enum.Font.GothamMedium,
	Semi = Enum.Font.GothamSemibold,
	Bold = Enum.Font.GothamBold,
	Black = Enum.Font.GothamBlack,
}

local S = {
	Logo = 40, Search = 22, Cat = 22, Sub = 26, Crumb = 28,
	SecTitle = 27, Label = 23, Value = 20, Input = 20,
}

local C = {
	Window = Color3.fromRGB(13, 14, 17),
	Side = Color3.fromRGB(16, 17, 20),
	Panel = Color3.fromRGB(21, 22, 26),
	Tile = Color3.fromRGB(15, 16, 19),
	Input = Color3.fromRGB(11, 12, 15),
	Line = Color3.fromRGB(40, 42, 50),
	Bar = Color3.fromRGB(70, 73, 90),
	BarLight = Color3.fromRGB(150, 153, 168),
	White = Color3.fromRGB(240, 240, 244),
	SubText = Color3.fromRGB(135, 138, 152),
	ToggleOff = Color3.fromRGB(42, 44, 56),
	ToggleOn = Color3.fromRGB(205, 207, 218),
	Knob = Color3.fromRGB(14, 14, 18),
	Selected = Color3.fromRGB(35, 36, 43),
	IconBox = Color3.fromRGB(28, 29, 35),
}

local connections = {}
local FarmUI = {}
local Actions = {}
local UIRefs = {}
local featureCount = 0
local hideables = {} -- labels affected by "Hide Username"
local statLabels = {}

local function create(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do inst[key] = value end
	inst.Parent = parent
	return inst
end

local function corner(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, thickness)
	return create("UIStroke", {
		Color = color or C.Line,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function txt(parent, str, size, color, font, align)
	return create("TextLabel", {
		BackgroundTransparency = 1, Text = str, TextSize = size,
		TextColor3 = color, Font = font or F.Reg,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 300, 0, size + 10),
	}, parent)
end

local function hexOf(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function loadAvatar(img)
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and url then img.Image = url end
	end)
end

local screenGui, main, minBtn, closeBtn
do -- build the window
local old = guiParent:FindFirstChild("TheS_Gui")
if old then old:Destroy() end

screenGui = create("ScreenGui", {
	Name = "TheS_Gui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

main = create("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(DESIGN_W, DESIGN_H),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, screenGui)
corner(main, 30)
stroke(main, Color3.fromRGB(46, 48, 58), 2)

local uiScale = create("UIScale", { Scale = 1 }, main)
local function updateScale()
	local s = screenGui.AbsoluteSize
	if s.X > 0 and s.Y > 0 then
		uiScale.Scale = math.min(s.X * 0.78 / DESIGN_W, s.Y * 0.88 / DESIGN_H)
	end
end
updateScale()
table.insert(connections, screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale))

-- Dragging helper: the window moves DRAG_SPEED x your finger movement, eased so it glides
local function makeDraggable(handle)
	local dragging = false
	local dragStart, startPos, goal
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			goal = startPos
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = (input.Position - dragStart) * DRAG_SPEED / uiScale.Scale
			goal = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
	table.insert(connections, RunService.RenderStepped:Connect(function()
		if dragging and goal then
			main.Position = main.Position:Lerp(goal, 0.35)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))
end

---------------------------------------------------------------------
-- SIDEBAR FRAME (logo + scroll list + profile bar)
---------------------------------------------------------------------
local sidebar = create("Frame", {
	Name = "Sidebar", Size = UDim2.new(0, SIDE_W, 1, 0),
	BackgroundColor3 = C.Side, BorderSizePixel = 0,
}, main)
create("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = C.Line, BorderSizePixel = 0, ZIndex = 2 }, sidebar)

local logoArea = create("Frame", { Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Active = true }, sidebar)
makeDraggable(logoArea)
local logo = create("TextLabel", {
	BackgroundTransparency = 1, RichText = true,
	Text = 'THE S <font color="#7A7D8A" size="30">HUB</font>',
	TextSize = S.Logo, Font = F.Black, TextColor3 = C.White,
	TextXAlignment = Enum.TextXAlignment.Left,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 40, 0, 62), Size = UDim2.new(1, -60, 0, 60),
}, logoArea)

local sideScroll = create("ScrollingFrame", {
	Position = UDim2.new(0, 0, 0, HEAD_H), Size = UDim2.new(1, 0, 1, -(HEAD_H + PROFILE_H)),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, sidebar)
create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 12) }, sideScroll)
create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sideScroll)

local profileBar = create("Frame", {
	Size = UDim2.new(1, -1, 0, PROFILE_H), Position = UDim2.new(0, 0, 1, -PROFILE_H),
	BackgroundColor3 = C.Side, BorderSizePixel = 0,
}, sidebar)
create("Frame", { Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 0, 0), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, profileBar)
local pAvatar = create("ImageLabel", {
	Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 28, 0.5, 0),
	BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Image = "",
}, profileBar)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, pAvatar)
stroke(pAvatar, Color3.fromRGB(200, 202, 212), 2)
loadAvatar(pAvatar)

local pName = txt(profileBar, player.Name, 24, C.White, F.Bold)
pName.Position = UDim2.new(0, 114, 0.5, -16)
pName.Size = UDim2.new(1, -130, 0, 32)
table.insert(hideables, { label = pName, real = player.Name, hidden = "Hidden" })

local pGame = txt(profileBar, "Roblox", 20, C.SubText, F.Reg)
pGame.Position = UDim2.new(0, 114, 0.5, 18)
pGame.Size = UDim2.new(1, -130, 0, 28)
task.spawn(function()
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	if ok and info and info.Name then pGame.Text = info.Name end
end)

---------------------------------------------------------------------
-- CONTENT AREA (header + pages)
---------------------------------------------------------------------
local CONTENT_W = DESIGN_W - SIDE_W
local content = create("Frame", {
	Name = "Content", Position = UDim2.new(0, SIDE_W, 0, 0),
	Size = UDim2.new(1, -SIDE_W, 1, 0), BackgroundTransparency = 1,
}, main)

local header = create("Frame", { Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Active = true }, content)
makeDraggable(header)

local headIcon = create("TextLabel", {
	Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, 26, 0, 30),
	BackgroundColor3 = C.IconBox, BorderSizePixel = 0,
	Text = "⌂", TextSize = 30, Font = F.Med, TextColor3 = C.White,
}, header)
corner(headIcon, 16)

local crumb = create("TextLabel", {
	BackgroundTransparency = 1, RichText = true, Text = "",
	TextSize = S.Crumb, Font = F.Med, TextColor3 = C.White,
	TextXAlignment = Enum.TextXAlignment.Left,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 112, 0, 62), Size = UDim2.new(0, 560, 0, 44),
}, header)

local search = create("Frame", {
	Name = "Search", Size = UDim2.new(0, 380, 0, 68),
	Position = UDim2.new(0, CONTENT_W - 24 - 62 - 10 - 62 - 14 - 380, 0, 29),
	BackgroundColor3 = C.Panel, BorderSizePixel = 0,
}, header)
corner(search, 20)

-- magnifier icon
local sIcon = create("Frame", { Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0, 26, 0.5, -14), BackgroundTransparency = 1 }, search)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, sIcon)
stroke(sIcon, C.SubText, 2)
create("Frame", { Size = UDim2.fromOffset(11, 2), Position = UDim2.new(0, 38, 0.5, 9), Rotation = 45, BackgroundColor3 = C.SubText, BorderSizePixel = 0 }, search)

local searchBox = create("TextBox", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 70, 0, 0),
	Text = "", PlaceholderText = "search...",
	PlaceholderColor3 = C.SubText, TextColor3 = C.White,
	TextSize = S.Search, Font = F.Reg,
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, search)

minBtn = create("TextButton", { Size = UDim2.fromOffset(62, 62), Position = UDim2.new(0, CONTENT_W - 24 - 62 - 10 - 62, 0, 32), BackgroundTransparency = 1, Text = "" }, header)
create("Frame", { Size = UDim2.new(0, 24, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = C.BarLight, BorderSizePixel = 0 }, minBtn)

closeBtn = create("TextButton", { Size = UDim2.fromOffset(62, 62), Position = UDim2.new(0, CONTENT_W - 24 - 62, 0, 32), BackgroundTransparency = 1, Text = "" }, header)
for _, rot in ipairs({ 45, -45 }) do
	create("Frame", { Size = UDim2.new(0, 30, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = rot, BackgroundColor3 = C.White, BorderSizePixel = 0 }, closeBtn)
end

local pageHolder = create("Frame", { Position = UDim2.new(0, 0, 0, HEAD_H), Size = UDim2.new(1, 0, 1, -HEAD_H), BackgroundTransparency = 1 }, content)

---------------------------------------------------------------------
-- PAGE / SECTION / ROW BUILDERS
---------------------------------------------------------------------
local pages = {}
local pageRows = {}
local currentPage = nil
local buildingPage = nil

local function applyFilter()
	local q = string.lower(searchBox.Text)
	for _, e in ipairs(pageRows[currentPage] or {}) do
		local match = (q == "") or (string.find(e.key, q, 1, true) ~= nil)
		e.frame.Visible = match and not e.sec.collapsed
	end
end
searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

local function newPage(name)
	local sf = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.Bar,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
	}, pageHolder)
	local function column(x, w)
		local col = create("Frame", { Size = UDim2.new(0, w, 0, 0), Position = UDim2.new(0, x, 0, 6), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, sf)
		create("UIListLayout", { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder }, col)
		return col
	end
	pages[name] = { frame = sf, left = column(24, 662), right = column(712, 676) }
	pageRows[name] = {}
	buildingPage = name
	return pages[name]
end

local function section(parent, title, layoutOrder, startCollapsed, icon)
	local s = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = layoutOrder or 1 }, parent)
	corner(s, 24)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, s)

	local obj = { frame = s, n = 0, collapsed = startCollapsed or false, dividers = {} }
	local hdr = create("TextButton", { Size = UDim2.new(1, 0, 0, 98), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0 }, s)

	local ib = create("TextLabel", {
		Size = UDim2.fromOffset(58, 58), Position = UDim2.new(0, 24, 0.5, -29),
		BackgroundColor3 = C.IconBox, BorderSizePixel = 0,
		Text = icon or "⌂", TextSize = 28, Font = F.Med, TextColor3 = C.White,
	}, hdr)
	corner(ib, 14)

	local title_ = txt(hdr, title, S.SecTitle, C.White, F.Bold)
	title_.Position = UDim2.new(0, 100, 0.5, 0)
	title_.Size = UDim2.new(1, -200, 0, 40)
	local chev = txt(hdr, obj.collapsed and ">" or "v", 18, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
	chev.AnchorPoint = Vector2.new(0.5, 0.5)
	chev.Size = UDim2.new(0, 30, 0, 30)
	chev.Position = UDim2.new(1, -44, 0.5, 0)
	create("Frame", { Size = UDim2.new(1, -48, 0, 2), Position = UDim2.new(0, 24, 1, -2), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, hdr)

	hdr.MouseButton1Click:Connect(function()
		obj.collapsed = not obj.collapsed
		chev.Text = obj.collapsed and ">" or "v"
		applyFilter()
	end)
	return obj
end

local function row(sec, height, key)
	local r = create("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, Visible = not sec.collapsed, LayoutOrder = sec.n + 1 }, sec.frame)
	local div = create("Frame", { Size = UDim2.new(1, -62, 0, 1), Position = UDim2.new(0, 31, 1, -1), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, r)
	table.insert(sec.dividers, div)
	sec.n = sec.n + 1
	table.insert(pageRows[buildingPage], { frame = r, key = string.lower(key), sec = sec })
	return r
end

local function finish(sec, hideDividers)
	if hideDividers then
		for _, d in ipairs(sec.dividers) do d.Visible = false end
	else
		local last = sec.dividers[#sec.dividers]
		if last then last.Visible = false end
	end
	create("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, LayoutOrder = 9999 }, sec.frame)
end

local function rowLabel(r, name, cy)
	local l = txt(r, name, S.Label, C.White, F.Semi)
	l.Position = UDim2.new(0, 31, 0, cy)
	l.Size = UDim2.new(1, -170, 0, S.Label + 10)
	return l
end

-- Atom-style checkbox (box on the left, label on the right)
local function addCheckbox(sec, name, startOn, callback)
	featureCount = featureCount + 1
	local r = row(sec, 82, name)
	local box = create("TextButton", {
		Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 31, 0, 41),
		BackgroundColor3 = startOn and Color3.fromRGB(228, 229, 235) or C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	}, r)
	corner(box, 12)
	local mark = create("Frame", { Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Visible = startOn }, box)
	local a = create("Frame", { Size = UDim2.fromOffset(10, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(6, 15), Rotation = 45, BackgroundColor3 = C.Knob, BorderSizePixel = 0 }, mark)
	corner(a, 2)
	local b = create("Frame", { Size = UDim2.fromOffset(18, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(14, 12), Rotation = -45, BackgroundColor3 = C.Knob, BorderSizePixel = 0 }, mark)
	corner(b, 2)
	local l = txt(r, name, S.Label, C.White, F.Semi)
	l.Position = UDim2.new(0, 98, 0, 41)
	l.Size = UDim2.new(1, -130, 0, S.Label + 10)

	local state = startOn
	local function apply(v)
		state = v
		mark.Visible = v
		TweenService:Create(box, TweenInfo.new(0.12), { BackgroundColor3 = v and Color3.fromRGB(228, 229, 235) or C.IconBox }):Play()
	end
	box.MouseButton1Click:Connect(function()
		apply(not state)
		if callback then callback(state) end
	end)
	-- returned setter lets code (e.g. a hotkey) flip the checkbox and run its callback
	return function(v)
		apply(v)
		if callback then callback(v) end
	end
end

local function addToggle(sec, name, startOn, callback)
	return addCheckbox(sec, name, startOn, callback)
end

local function addSlider(sec, name, minV, maxV, startV, suffix, callback, step)
	featureCount = featureCount + 1
	step = step or 1
	local r = row(sec, 124, name)
	rowLabel(r, name, 34)
	local valLabel = txt(r, "", S.Value, C.White, F.Bold, Enum.TextXAlignment.Right)
	valLabel.AnchorPoint = Vector2.new(1, 0.5)
	valLabel.Size = UDim2.new(0, 160, 0, 26)
	valLabel.Position = UDim2.new(1, -31, 0, 34)

	local trackArea = create("TextButton", { Size = UDim2.new(1, -70, 0, 44), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 35, 0, 86), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, r)
	local track = create("Frame", { Size = UDim2.new(1, 0, 0, 8), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0 }, trackArea)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	local startRel = (startV - minV) / (maxV - minV)
	local fill = create("Frame", { Size = UDim2.new(startRel, 0, 1, 0), BackgroundColor3 = C.White, BorderSizePixel = 0 }, track)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local knob = create("Frame", { Size = UDim2.new(0, 34, 0, 34), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(startRel, 0, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0 }, track)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
	valLabel.Text = tostring(startV) .. (suffix or "")

	local dragging = false
	local function update(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.floor((minV + rel * (maxV - minV)) / step + 0.5) * step
		v = math.floor(v * 1000 + 0.5) / 1000
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		valLabel.Text = tostring(v) .. (suffix or "")
		if callback then callback(v) end
	end
	trackArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; update(input.Position.X)
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))
end

local function addColor(sec, name, startColor, callback)
	featureCount = featureCount + 1
	local r = row(sec, 90, name)
	local l = rowLabel(r, name, 45)
	l.Size = UDim2.new(1, -290, 0, S.Label + 10)
	local box = create("TextButton", { Size = UDim2.new(0, 232, 0, 64), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0, 45), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = true }, r)
	corner(box, 16)
	local swatch = create("Frame", { Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 16, 0.5, -17), BackgroundColor3 = startColor, BorderSizePixel = 0 }, box)
	corner(swatch, 9)
	local hex = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -66, 1, 0), Position = UDim2.new(0, 62, 0, 0), Text = hexOf(startColor), TextSize = S.Input, Font = F.Reg, TextColor3 = C.SubText, TextXAlignment = Enum.TextXAlignment.Left }, box)

	local palette = {
		startColor,
		Color3.fromRGB(255, 140, 28),
		Color3.fromRGB(0, 255, 120),
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(80, 170, 255),
		Color3.fromRGB(150, 0, 255),
		Color3.fromRGB(255, 255, 255),
	}
	local i = 1
	box.MouseButton1Click:Connect(function()
		i = i % #palette + 1
		swatch.BackgroundColor3 = palette[i]
		hex.Text = hexOf(palette[i])
		if callback then callback(palette[i]) end
	end)
end

local function addInput(sec, name, placeholder, callback)
	featureCount = featureCount + 1
	local r = row(sec, 136, name)
	rowLabel(r, name, 34)
	local box = create("Frame", { Size = UDim2.new(1, -62, 0, 58), Position = UDim2.new(0, 31, 0, 62), BackgroundColor3 = C.Input, BorderSizePixel = 0 }, r)
	corner(box, 16)
	stroke(box, Color3.fromRGB(40, 42, 54), 1)
	local tb = create("TextBox", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 15, 0, 0),
		Text = "", PlaceholderText = placeholder, PlaceholderColor3 = C.SubText,
		TextColor3 = C.White, TextSize = S.Input, Font = F.Reg,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	}, box)
	tb.FocusLost:Connect(function()
		if callback then callback(tb.Text) end
	end)
	return tb
end

local function addDropdown(sec, name, options, default, callback)
	featureCount = featureCount + 1
	local baseH = 136
	local itemH = 56
	local r = row(sec, baseH, name)
	rowLabel(r, name, 34)
	local box = create("TextButton", { Size = UDim2.new(1, -62, 0, 64), Position = UDim2.new(0, 31, 0, 62), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, r)
	corner(box, 16)
	local cur = txt(box, default, 21, C.White, F.Reg)
	cur.Position = UDim2.new(0, 24, 0.5, 0)
	cur.Size = UDim2.new(1, -90, 0, 30)
	local arrow = txt(box, "v", 16, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.new(0, 24, 0, 24)
	arrow.Position = UDim2.new(1, -34, 0.5, 0)

	local list = create("Frame", { Size = UDim2.new(1, -62, 0, #options * itemH), Position = UDim2.new(0, 31, 0, baseH - 4), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Visible = false }, r)
	corner(list, 16)
	local open = false
	local function setOpen(v)
		open = v
		list.Visible = v
		arrow.Text = v and "^" or "v"
		r.Size = UDim2.new(1, 0, 0, v and (baseH + #options * itemH + 12) or baseH)
	end
	for i, opt in ipairs(options) do
		local b = create("TextButton", {
			Size = UDim2.new(1, 0, 0, itemH), Position = UDim2.new(0, 0, 0, (i - 1) * itemH),
			BackgroundTransparency = 1, Text = opt, TextSize = 21, Font = F.Reg, TextColor3 = C.White,
			TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
		}, list)
		create("UIPadding", { PaddingLeft = UDim.new(0, 24) }, b)
		b.MouseButton1Click:Connect(function()
			cur.Text = opt
			setOpen(false)
			if callback then callback(opt) end
		end)
	end
	box.MouseButton1Click:Connect(function() setOpen(not open) end)
end

local function addInfo(sec, text)
	local r = row(sec, 84, text)
	sec.dividers[#sec.dividers].Visible = false
	local box = create("Frame", { Size = UDim2.new(1, -62, 0, 68), Position = UDim2.new(0, 31, 0, 8), BackgroundColor3 = C.IconBox, BorderSizePixel = 0 }, r)
	corner(box, 16)
	return create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = text, TextSize = 22, Font = F.Bold, TextColor3 = C.White }, box)
end

local function addButton(sec, text, callback)
	featureCount = featureCount + 1
	local r = row(sec, 88, text)
	sec.dividers[#sec.dividers].Visible = false
	local btn = create("TextButton", {
		Size = UDim2.new(1, -62, 0, 68), Position = UDim2.new(0, 31, 0, 10), BackgroundColor3 = C.IconBox,
		BorderSizePixel = 0, Text = text, TextSize = 22, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = true,
	}, r)
	corner(btn, 16)
	btn.MouseButton1Click:Connect(function() callback(btn) end)
	return btn
end

local function addKeybind(sec, name, callback)
	featureCount = featureCount + 1
	local r = row(sec, 90, name)
	local l = rowLabel(r, name, 45)
	l.Size = UDim2.new(1, -250, 0, S.Label + 10)
	local btn = create("TextButton", {
		Size = UDim2.new(0, 190, 0, 66), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0, 45),
		BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "None", TextSize = 22, Font = F.Med,
		TextColor3 = C.White, AutoButtonColor = true,
	}, r)
	corner(btn, 16)
	local waiting, shown = false, "None"
	btn.MouseButton1Click:Connect(function()
		waiting = not waiting
		btn.Text = waiting and "press a key..." or shown
	end)
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if not waiting or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		waiting = false
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
			shown = "None"
			callback(nil)
		else
			shown = input.KeyCode.Name
			callback(input.KeyCode)
		end
		btn.Text = shown
	end))
end

-- dropdown whose list is rebuilt from the current server players every time it opens
local function addPlayerDropdown(sec, name, callback)
	featureCount = featureCount + 1
	local baseH, itemH = 136, 56
	local r = row(sec, baseH, name)
	rowLabel(r, name, 34)
	local box = create("TextButton", { Size = UDim2.new(1, -62, 0, 64), Position = UDim2.new(0, 31, 0, 62), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, r)
	corner(box, 16)
	local cur = txt(box, "None", 21, C.White, F.Reg)
	cur.Position = UDim2.new(0, 24, 0.5, 0)
	cur.Size = UDim2.new(1, -90, 0, 30)
	local arrow = txt(box, "v", 16, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.new(0, 24, 0, 24)
	arrow.Position = UDim2.new(1, -34, 0.5, 0)

	local list = create("ScrollingFrame", {
		Size = UDim2.new(1, -62, 0, itemH), Position = UDim2.new(0, 31, 0, baseH - 4), BackgroundColor3 = C.IconBox,
		BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), Visible = false,
	}, r)
	corner(list, 16)

	local open, listH = false, itemH
	local setOpen
	local function rebuild()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local names = { "None" }
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then table.insert(names, p.Name) end
		end
		for i, opt in ipairs(names) do
			local b = create("TextButton", {
				Size = UDim2.new(1, 0, 0, itemH), Position = UDim2.new(0, 0, 0, (i - 1) * itemH),
				BackgroundTransparency = 1, Text = opt, TextSize = 21, Font = F.Reg, TextColor3 = C.White,
				TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
			}, list)
			create("UIPadding", { PaddingLeft = UDim.new(0, 24) }, b)
			b.MouseButton1Click:Connect(function()
				cur.Text = opt
				setOpen(false)
				callback(opt)
			end)
		end
		list.CanvasSize = UDim2.new(0, 0, 0, #names * itemH)
		listH = math.min(#names, 5) * itemH
		list.Size = UDim2.new(1, -62, 0, listH)
	end
	setOpen = function(v)
		open = v
		if v then rebuild() end
		list.Visible = v
		arrow.Text = v and "^" or "v"
		r.Size = UDim2.new(1, 0, 0, v and (baseH + listH + 12) or baseH)
	end
	box.MouseButton1Click:Connect(function() setOpen(not open) end)
end

---------------------------------------------------------------------
-- TABS
---------------------------------------------------------------------
xpcall(function() -- Home
	local p = newPage("Home")

	local a = section(p.left, "Overview", 1, false, "⌂")

	-- welcome card
	local wr = row(a, 190, "welcome overview")
	local card = create("Frame", { Size = UDim2.new(1, -48, 0, 158), Position = UDim2.new(0, 24, 0, 16), BackgroundColor3 = C.Tile, BorderSizePixel = 0 }, wr)
	corner(card, 22)
	local av = create("ImageLabel", {
		Size = UDim2.fromOffset(112, 112), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 24, 0.5, 0),
		BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Image = "",
	}, card)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
	stroke(av, Color3.fromRGB(200, 202, 212), 2)
	loadAvatar(av)

	local wl = txt(card, "WELCOME " .. string.upper(player.Name), 30, C.White, F.Bold)
	wl.Position = UDim2.new(0, 160, 0.5, -20)
	wl.Size = UDim2.new(1, -180, 0, 40)
	table.insert(hideables, { label = wl, real = "WELCOME " .. string.upper(player.Name), hidden = "WELCOME ********" })

	local hl = txt(card, "@" .. player.Name, 24, C.SubText, F.Reg)
	hl.Position = UDim2.new(0, 160, 0.5, 24)
	hl.Size = UDim2.new(1, -180, 0, 34)
	table.insert(hideables, { label = hl, real = "@" .. player.Name, hidden = "@********" })

	-- stat tiles
	local sr = row(a, 262, "feature count ping fps animations")
	local function tile(name, x, y)
		local t = create("Frame", { Size = UDim2.new(0.5, -30, 0, 116), Position = x, BackgroundColor3 = C.Tile, BorderSizePixel = 0 }, sr)
		t.Position = UDim2.new(x.X.Scale, x.X.Offset, 0, y)
		corner(t, 20)
		local l1 = txt(t, name, 20, C.SubText, F.Reg)
		l1.Position = UDim2.new(0, 22, 0, 34)
		l1.Size = UDim2.new(1, -40, 0, 28)
		local l2 = txt(t, "-", 32, C.White, F.Bold)
		l2.Position = UDim2.new(0, 22, 0, 80)
		l2.Size = UDim2.new(1, -40, 0, 44)
		statLabels[name] = l2
	end
	tile("Feature Count", UDim2.new(0, 24, 0, 0), 8)
	tile("Ping", UDim2.new(0.5, 6, 0, 0), 8)
	tile("FPS", UDim2.new(0, 24, 0, 0), 136)
	tile("Animations", UDim2.new(0.5, 6, 0, 0), 136)
	finish(a, true)

	local b = section(p.right, "Overview · Session", 1, false, "⌂")
	addCheckbox(b, "Hide Username", false, function(v)
		for _, h in ipairs(hideables) do
			h.label.Text = v and h.hidden or h.real
		end
	end)
	finish(b)
end, function(e) warn("The S: tab \"Home\" failed: " .. tostring(e)) end)

xpcall(function() -- ESP
	local p = newPage("ESP")

	local a = section(p.left, "Player ESP", 1, false, "◎")
	addToggle(a, "Player ESP (Master)", true, function(v) getgenv().Config.ESPEnabled = v end)
	addToggle(a, "Boxes", true, function(v) getgenv().Config.BoxEnabled = v end)
	addToggle(a, "Names, HP & Distance", true, function(v) getgenv().Config.NameEnabled = v end)
	addToggle(a, "Health Bars", true, function(v) getgenv().Config.HealthBarEnabled = v end)
	addToggle(a, "Tracers", true, function(v) getgenv().Config.TracerEnabled = v end)
	addSlider(a, "Max Distance", 100, 5000, 3000, " st", function(v) getgenv().Config.ESPMaxDistance = v end)
	finish(a)

	local b = section(p.left, "Target Visuals", 2, false, "◎")
	addToggle(b, "Target Box + Name (HVH)", true, function(v) getgenv().Config.TargetBoxEnabled = v end)
	addToggle(b, "Orbit Ring", true, function(v) getgenv().Config.OrbitVisualEnabled = v end)
	addToggle(b, "Laser Rays", true, function(v) getgenv().Config.LaserRaysEnabled = v end)
	finish(b)

	local c = section(p.right, "ESP Colors", 1, false, "◐")
	addColor(c, "Name / Text Color", Color3.fromRGB(255, 255, 255), function(v) getgenv().Config.ESPColor = v end)
	addColor(c, "Box Color", Color3.fromRGB(0, 255, 120), function(v) getgenv().Config.BoxColor = v end)
	addColor(c, "Tracer Color", Color3.fromRGB(0, 255, 120), function(v) getgenv().Config.TracerColor = v end)
	addColor(c, "Health Bar Color", Color3.fromRGB(0, 255, 0), function(v) getgenv().Config.HealthBarColor = v end)
	addColor(c, "Orbit Ring Color", Color3.fromRGB(150, 0, 255), function(v) getgenv().Config.OrbitColor = v end)
	addColor(c, "Laser Color", Color3.fromRGB(0, 150, 255), function(v) getgenv().Config.LaserColor = v end)
	addColor(c, "Target Box / Line Color", Color3.fromRGB(255, 0, 0), function(v) getgenv().Config.TargetLineColor = v end)
	finish(c)
end, function(e) warn("The S: tab \"ESP\" failed: " .. tostring(e)) end)

xpcall(function() -- Halloween (Farm)
	local p = newPage("Halloween")

	local a = section(p.left, "Auto Doors", 1, false, "✧")
	addToggle(a, "Door ESP", true, function(v) getgenv().Config.DoorESPEnabled = v end)
	addToggle(a, "Show Distance", true, function(v) getgenv().Config.DoorShowDistance = v end)
	addColor(a, "ESP Colour", Color3.fromRGB(255, 200, 0), function(v) getgenv().Config.DoorColor = v end)
	addToggle(a, "Auto Doors", false, function(v) getgenv().Config.AutoFarmDoors = v end)
	addToggle(a, "Invisible While Farming", true, function(v) getgenv().Config.InvisibleFarming = v end)
	addSlider(a, "Walk Speed To Door", 16, 400, 200, " st/s", function(v) getgenv().Config.DoorTravelSpeed = v end)
	addSlider(a, "Fly Height", 10, 200, 80, " studs", function(v) getgenv().Config.FlyHeight = v end)
	addSlider(a, "Open Timeout", 1, 20, 6, "s", function(v) getgenv().Config.OpenTimeout = v end)
	finish(a)

	local e = section(p.left, "Halloween ESP", 2, false, "✧")
	addToggle(e, "Skeleton ESP (Red)", true, function(v) getgenv().Config.SkeletonESPEnabled = v end)
	addToggle(e, "Pumpkin Carrier Highlight", true, function(v) getgenv().Config.PumpkinESPEnabled = v end)
	addToggle(e, "Player Highlights", true, function(v) getgenv().Config.PlayerHighlightEnabled = v end)
	addToggle(e, "Instant Interact", true, function(v) getgenv().Config.InstantInteractEnabled = v end)
	finish(e)

	local k = section(p.right, "Kill Farm", 1, false, "✧")
	addToggle(k, "Enabled", false, function(v) getgenv().Config.KillFarmEnabled = v end)
	addDropdown(k, "Role", { "Killer", "Players" }, "Killer", function(v) getgenv().Config.KillFarmRole = v end)
	addSlider(k, "Travel Speed", 50, 1000, 385, " st/s", function(v) getgenv().Config.KillFarmSpeed = v end)
	addToggle(k, "Use Idle Spot", true, function(v) getgenv().Config.UseIdleSpot = v end)
	FarmUI.Status = addInfo(k, "Status: Idle")
	FarmUI.Kills = addInfo(k, "Kills: 0")
	finish(k)

	local kl = section(p.right, "Killer", 2, false, "✧")
	addToggle(kl, "Kill Aura Skeletons", false, function(v) getgenv().Config.KillAuraSkeletons = v end)
	finish(kl)
end, function(e) warn("The S: tab \"Halloween (Farm)\" failed: " .. tostring(e)) end)

xpcall(function() -- Combat & HVH
	local p = newPage("Combat & HVH")

	local c = section(p.left, "HVH Target", 1, false, "◆")
	addToggle(c, "Smooth Orbit HVH", false, function(v)
		getgenv().Config.HVHEnabled = v
		hvhTarget = nil
	end)
	-- ON  = always orbit the closest ALIVE player (re-picks when the target dies)
	-- OFF = orbit the player chosen below
	UIRefs.setClosest = addToggle(c, "Target Closest Player (alive)", true, function(v)
		getgenv().Config.TargetClosest = v
		hvhTarget = nil
	end)
	addPlayerDropdown(c, "Pick Target Player", function(v)
		if v == "None" then
			getgenv().Config.TargetName = ""
			if UIRefs.setClosest then UIRefs.setClosest(true) end
		else
			getgenv().Config.TargetName = v
			if UIRefs.setClosest then UIRefs.setClosest(false) end
		end
		hvhTarget = nil
	end)
	addInput(c, "Or Type Player Name", "username or display name...", function(v)
		getgenv().Config.TargetName = v
		if v ~= "" and UIRefs.setClosest then UIRefs.setClosest(false) end
		hvhTarget = nil
	end)
	addToggle(c, "Stable Camera (no shake)", true, function(v) getgenv().Config.StableCamera = v end)
	addSlider(c, "Spin Speed", 100, 20000, 20000, " deg/s", function(v) getgenv().Config.SpinSpeed = v end)
	addSlider(c, "Orbit Radius", 1, 50, 6, " st", function(v) getgenv().Config.Radius = v end)
	finish(c)

	local m = section(p.right, "Movement & Utility", 1, false, "◆")
	addToggle(m, "Speed Hack", false, function(v) getgenv().Config.SpeedHackEnabled = v end)
	addSlider(m, "Walk Speed", 16, 300, 200, "", function(v) getgenv().Config.WalkSpeedValue = v end)
	addToggle(m, "Infinite Jump", false, function(v) getgenv().Config.InfJumpEnabled = v end)
	addToggle(m, "Noclip", false, function(v) getgenv().Config.NoclipEnabled = v end)
	finish(m)
end, function(e) warn("The S: tab \"Combat & HVH\" failed: " .. tostring(e)) end)

xpcall(function() -- Auto Block (Combat)
	local p = newPage("Auto Block")
	local keys = { "F", "Q", "E", "R", "T", "G" }

	local a = section(p.left, "Main · Block", 1, false, "◈")
	UIRefs.setAutoBlock = addToggle(a, "Enabled", false, function(v)
		getgenv().Config.AutoBlockEnabled = v
		if UIRefs.refreshBlockBtn then UIRefs.refreshBlockBtn() end
	end)
	addToggle(a, "Mobile Toggle Button", true, function(v)
		getgenv().Config.MobileBlockButton = v
		if UIRefs.refreshBlockBtn then UIRefs.refreshBlockBtn() end
	end)
	addKeybind(a, "Enabled Key", function(code) getgenv().Config.AutoBlockKeyCode = code end)
	addToggle(a, "Only Locked Target", false, function(v) getgenv().Config.OnlyLockedTarget = v end)
	addToggle(a, "Only Block Angle", false, function(v) getgenv().Config.OnlyBlockAngle = v end)
	addToggle(a, "Show Angle", false, function(v) getgenv().Config.ShowAngle = v end)
	addToggle(a, "Only Block Selected Target", false, function(v) getgenv().Config.OnlySelectedTarget = v end)
	addPlayerDropdown(a, "Selected Target", function(v) getgenv().Config.SelectedTarget = v end)
	finish(a)

	local b = section(p.left, "Punish", 2, false, "◈")
	addToggle(b, "Auto Punish", false, function(v) getgenv().Config.PunishEnabled = v end)
	addToggle(b, "Dash Punish", true, function(v) getgenv().Config.DashPunish = v end)
	finish(b)

	local c = section(p.right, "Main · Configuration", 1, false, "◈")
	addSlider(c, "Block Range", 5, 60, 20, " studs", function(v) getgenv().Config.BlockRange = v end)
	addSlider(c, "Block Angle", 10, 360, 90, "°", function(v) getgenv().Config.BlockAngle = v end)
	addDropdown(c, "Block Key", keys, "F", function(v) getgenv().Config.BlockKey = v end)
	finish(c)

	local d = section(p.right, "Punish · Configuration", 2, false, "◈")
	addSlider(d, "Punish Range", 5, 60, 25, " studs", function(v) getgenv().Config.PunishRange = v end)
	addSlider(d, "Dash Punish Delay", 0, 1, 0.05, "s", function(v) getgenv().Config.DashPunishDelay = v end, 0.01)
	addSlider(d, "M1 Catch Range", 5, 60, 30, " studs", function(v) getgenv().Config.M1CatchRange = v end)
	addDropdown(d, "Dash Key", keys, "Q", function(v) getgenv().Config.DashKey = v end)
	finish(d)
end, function(e) warn("The S: tab \"Auto Block (Combat)\" failed: " .. tostring(e)) end)

xpcall(function() -- Avatar (Visuals)
	local p = newPage("Avatar")
	local a = section(p.left, "Avatar", 1, false, "◍")
	addButton(a, "Scramble Avatar", function(btn) Actions.scramble(btn) end)
	addButton(a, "Copy Random Player", function(btn) Actions.copyRandom(btn) end)
	local targetBox = addInput(a, "Target", "username or id", nil)
	addButton(a, "Copy Avatar", function(btn) Actions.copyAvatar(btn, targetBox.Text) end)
	addButton(a, "Restore Avatar", function(btn) Actions.restore(btn) end)
	finish(a)
end, function(e) warn("The S: tab \"Avatar (Visuals)\" failed: " .. tostring(e)) end)

xpcall(function() -- Colors
	local p = newPage("Colors")
	local cl = section(p.left, "Theme Colors", 1, false, "◐")
	addColor(cl, "Highlight Color", Color3.fromRGB(0, 255, 120), function(v) getgenv().Config.HighlightColor = v end)
	addColor(cl, "Pumpkin Color", Color3.fromRGB(255, 100, 0), function(v) getgenv().Config.PumpkinColor = v end)
	addColor(cl, "Door Color", Color3.fromRGB(255, 200, 0), function(v) getgenv().Config.DoorColor = v end)
	addColor(cl, "Skeleton Color", Color3.fromRGB(255, 0, 0), function(v) getgenv().Config.SkeletonColor = v end)
	finish(cl)
end, function(e) warn("The S: tab \"Colors\" failed: " .. tostring(e)) end)

---------------------------------------------------------------------
-- SIDEBAR ENTRIES
---------------------------------------------------------------------
local subButtons = {}
local catOf = {}
local iconOf = {}

local function selectPage(name)
	currentPage = name
	for n, page in pairs(pages) do page.frame.Visible = (n == name) end
	for n, b in pairs(subButtons) do
		local selected = (n == name)
		b.btn.BackgroundTransparency = selected and 0 or 1
		b.marker.Visible = selected
		b.text.TextColor3 = selected and C.White or C.SubText
		b.icon.TextColor3 = selected and C.White or C.SubText
	end
	crumb.Text = string.format('<font color="#C9CBD6">%s</font>  <font color="#6F7280">v</font>  <b>%s</b>', catOf[name] or "", name)
	headIcon.Text = iconOf[name] or "⌂"
	searchBox.Text = ""
	applyFilter()
end

local catOrder = 0
local function addCategory(title, subs)
	catOrder = catOrder + 1
	local cat = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = catOrder }, sideScroll)
	create("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, cat)

	local hdr = create("TextButton", { Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0 }, cat)
	local t = txt(hdr, string.upper(title), S.Cat, C.SubText, F.Semi)
	t.Position = UDim2.new(0, 30, 0.5, 0)
	local chev = txt(hdr, "v", 16, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
	chev.AnchorPoint = Vector2.new(0.5, 0.5)
	chev.Size = UDim2.new(0, 24, 0, 24)
	chev.Position = UDim2.new(1, -40, 0.5, 0)

	local subFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, cat)
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, subFrame)

	hdr.MouseButton1Click:Connect(function()
		subFrame.Visible = not subFrame.Visible
		chev.Text = subFrame.Visible and "v" or ">"
	end)

	for i, entry in ipairs(subs) do
		local name, icon = entry[1], entry[2]
		catOf[name] = title
		iconOf[name] = icon
		local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 86), BackgroundColor3 = C.Selected, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = i }, subFrame)
		corner(btn, 18)
		local marker = create("Frame", { Size = UDim2.new(0, 5, 0, 44), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0, Visible = false }, btn)
		corner(marker, 3)
		local ic = create("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 26, 0.5, 0), Text = icon, TextSize = 28, Font = F.Med, TextColor3 = C.SubText,
		}, btn)
		local st = txt(btn, name, S.Sub, C.SubText, F.Reg)
		st.Position = UDim2.new(0, 86, 0.5, 0)
		st.Size = UDim2.new(1, -100, 0, S.Sub + 10)
		subButtons[name] = { btn = btn, marker = marker, text = st, icon = ic }
		btn.MouseButton1Click:Connect(function() selectPage(name) end)
	end
end

addCategory("Main", { { "Home", "⌂" } })
addCategory("Visuals", { { "ESP", "◎" }, { "Avatar", "◍" } })
addCategory("Farm", { { "Halloween", "✧" } })
addCategory("Combat", { { "Auto Block", "◈" }, { "Combat & HVH", "◆" } })
addCategory("Settings", { { "Colors", "◐" } })

selectPage("Home")
end -- window built
print("The S: GUI built")

---------------------------------------------------------------------
-- DRAWING HELPERS
---------------------------------------------------------------------
local function newDrawing(kind, props)
	local d = Drawing.new(kind)
	for k, v in pairs(props) do d[k] = v end
	return d
end

local function removeAll(objs)
	for _, d in pairs(objs) do
		if typeof(d) == "table" then
			removeAll(d)
		else
			pcall(function() d:Remove() end)
		end
	end
end

local function hideAll(objs)
	for _, d in pairs(objs) do
		if typeof(d) == "table" then
			hideAll(d)
		else
			d.Visible = false
		end
	end
end

local function proj(cam, pos)
	local v = cam:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), v.Z > 0
end

---------------------------------------------------------------------
-- PLAYER ESP (box + health bar + name/HP/dist + tracer)
---------------------------------------------------------------------
local PlayerESP = {}
local Highlights = {}

local function createPlayerESP(p)
	local objs = {
		Box = newDrawing("Square", { Thickness = 1, Filled = false, Visible = false }),
		HealthBack = newDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.new(0, 0, 0), Visible = false }),
		HealthBar = newDrawing("Square", { Thickness = 1, Filled = true, Visible = false }),
		Name = newDrawing("Text", { Size = 15, Center = true, Outline = true, Font = Drawing.Fonts.UI, Visible = false }),
		Info = newDrawing("Text", { Size = 14, Center = true, Outline = true, Font = Drawing.Fonts.UI, Visible = false }),
		Tracer = newDrawing("Line", { Thickness = 1, Visible = false }),
	}
	PlayerESP[p] = objs
	return objs
end

local function removePlayerESP(p)
	if PlayerESP[p] then removeAll(PlayerESP[p]); PlayerESP[p] = nil end
	if Highlights[p] then Highlights[p]:Destroy(); Highlights[p] = nil end
end

local function isCarryingPumpkin(p)
	if p and p.Character then
		for _, item in ipairs(p.Character:GetDescendants()) do
			local n = string.lower(item.Name)
			if string.find(n, "pumpkin") or string.find(n, "bí ngô") then return true end
		end
	end
	return false
end

local function renderPlayers(cam)
	local cfg = getgenv().Config
	local vp = cam.ViewportSize
	local origin = Vector2.new(vp.X / 2, vp.Y)

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local objs = PlayerESP[p] or createPlayerESP(p)
			local char = p.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local shown = false

			if cfg.ESPEnabled and hrp and hum and hum.Health > 0 then
				local dist = (cam.CFrame.Position - hrp.Position).Magnitude
				if dist <= cfg.ESPMaxDistance then
					local top, okTop = proj(cam, hrp.Position + Vector3.new(0, 3, 0))
					local bottom, okBot = proj(cam, hrp.Position - Vector3.new(0, 3.5, 0))
					if okTop and okBot then
						shown = true
						local h = math.max(math.abs(bottom.Y - top.Y), 4)
						local w = h * 0.6
						local x, y = top.X - w / 2, top.Y
						local hasPumpkin = cfg.PumpkinESPEnabled and isCarryingPumpkin(p)
						local textColor = hasPumpkin and cfg.PumpkinColor or cfg.ESPColor

						objs.Box.Position = Vector2.new(x, y)
						objs.Box.Size = Vector2.new(w, h)
						objs.Box.Color = hasPumpkin and cfg.PumpkinColor or cfg.BoxColor
						objs.Box.Visible = cfg.BoxEnabled

						local maxHp = math.max(hum.MaxHealth, 1)
						local ratio = math.clamp(hum.Health / maxHp, 0, 1)
						objs.HealthBack.Position = Vector2.new(x - 7, y - 1)
						objs.HealthBack.Size = Vector2.new(4, h + 2)
						objs.HealthBack.Visible = cfg.HealthBarEnabled
						objs.HealthBar.Position = Vector2.new(x - 6, y + h * (1 - ratio))
						objs.HealthBar.Size = Vector2.new(2, h * ratio)
						objs.HealthBar.Color = Color3.fromRGB(255, 0, 0):Lerp(cfg.HealthBarColor, ratio)
						objs.HealthBar.Visible = cfg.HealthBarEnabled

						objs.Name.Text = p.Name .. (hasPumpkin and " [HAS PUMPKIN]" or "")
						objs.Name.Position = Vector2.new(top.X, y - 32)
						objs.Name.Color = textColor
						objs.Name.Visible = cfg.NameEnabled

						objs.Info.Text = string.format("HP: %d/%d | %dm", math.floor(hum.Health), math.floor(maxHp), math.floor(dist))
						objs.Info.Position = Vector2.new(top.X, y - 16)
						objs.Info.Color = textColor
						objs.Info.Visible = cfg.NameEnabled

						objs.Tracer.From = origin
						objs.Tracer.To = Vector2.new(top.X, y + h)
						objs.Tracer.Color = cfg.TracerColor
						objs.Tracer.Visible = cfg.TracerEnabled
					end
				end
			end

			if not shown then hideAll(objs) end
		end
	end
end

---------------------------------------------------------------------
-- TARGETING (shared by visuals + HVH orbit)
---------------------------------------------------------------------
local function isValidRoot(root)
	if not root or not root.Parent then return false end
	local hum = root.Parent:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function pickTarget()
	local cfg = getgenv().Config
	local nameQ = string.lower(cfg.TargetName or "")
	local best, bestDist
	local partial
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and isValidRoot(hrp) then -- alive players only
				if cfg.TargetClosest then
					if HumanoidRootPart then
						local d = (HumanoidRootPart.Position - hrp.Position).Magnitude
						if not bestDist or d < bestDist then best, bestDist = hrp, d end
					end
				elseif nameQ ~= "" then
					local pn, dn = string.lower(p.Name), string.lower(p.DisplayName)
					if pn == nameQ or dn == nameQ then
						return hrp -- exact match wins
					elseif not partial and (string.find(pn, nameQ, 1, true) or string.find(dn, nameQ, 1, true)) then
						partial = hrp
					end
				end
			end
		end
	end
	if cfg.TargetClosest then return best end
	return partial
end

-- while HVH is on, the target stays locked until it dies/leaves. With "Target Closest"
-- on, it is re-checked 5x per second and switches to whoever is NEAREST to you
-- (a new player must be 1.5 studs nearer, so two equal distances don't flip-flop)
local lastRepick = 0
local function getTargetRoot()
	local cfg = getgenv().Config
	if cfg.HVHEnabled then
		local now = os.clock()
		if not isValidRoot(hvhTarget) then
			hvhTarget = pickTarget()
			lastRepick = now
		elseif cfg.TargetClosest and HumanoidRootPart and now - lastRepick > 0.2 then
			lastRepick = now
			local best = pickTarget()
			if best and best ~= hvhTarget then
				local dBest = (HumanoidRootPart.Position - best.Position).Magnitude
				local dCur = (HumanoidRootPart.Position - hvhTarget.Position).Magnitude
				if dBest + 1.5 < dCur then hvhTarget = best end
			end
		end
		return hvhTarget
	end
	hvhTarget = nil
	return pickTarget()
end

---------------------------------------------------------------------
-- TARGET VISUALS (target box + name, orbit ring, laser rays, target line)
---------------------------------------------------------------------
local ORBIT_SEGMENTS = 28
local RAY_COUNT = 14
local TargetVis = { Orbit = {}, Rays = {}, Line = nil, Box = nil, Name = nil }

local function initTargetVisuals()
	for i = 1, ORBIT_SEGMENTS do
		TargetVis.Orbit[i] = newDrawing("Line", { Thickness = 1.5, Visible = false })
	end
	for i = 1, RAY_COUNT do
		TargetVis.Rays[i] = newDrawing("Line", { Thickness = 1, Visible = false })
	end
	TargetVis.Line = newDrawing("Line", { Thickness = 1.5, Visible = false })
	TargetVis.Box = newDrawing("Square", { Thickness = 2, Filled = false, Visible = false })
	TargetVis.Name = newDrawing("Text", { Size = 18, Center = true, Outline = true, Font = Drawing.Fonts.UI, Visible = false })
end

local function hideTargetVisuals()
	for _, l in ipairs(TargetVis.Orbit) do l.Visible = false end
	for _, l in ipairs(TargetVis.Rays) do l.Visible = false end
	if TargetVis.Line then TargetVis.Line.Visible = false end
	if TargetVis.Box then TargetVis.Box.Visible = false end
	if TargetVis.Name then TargetVis.Name.Visible = false end
end

local function renderTarget(cam, t)
	local cfg = getgenv().Config
	if not cfg.ESPEnabled then hideTargetVisuals(); return end
	local targetRoot = getTargetRoot()
	if not targetRoot then hideTargetVisuals(); return end

	local center = targetRoot.Position
	local r = cfg.Radius
	local centerScreen, centerOk = proj(cam, center)

	-- box + name around the HVH target
	local box, nameT = TargetVis.Box, TargetVis.Name
	local boxShown = false
	if cfg.HVHEnabled and cfg.TargetBoxEnabled then
		local top, okTop = proj(cam, center + Vector3.new(0, 3, 0))
		local bottom, okBot = proj(cam, center - Vector3.new(0, 3.5, 0))
		if okTop and okBot then
			local h = math.max(math.abs(bottom.Y - top.Y), 6)
			local w = h * 0.6
			box.Position = Vector2.new(top.X - w / 2, top.Y)
			box.Size = Vector2.new(w, h)
			box.Color = cfg.TargetLineColor
			box.Visible = true
			local tp = targetRoot.Parent and Players:GetPlayerFromCharacter(targetRoot.Parent)
			local hum = targetRoot.Parent and targetRoot.Parent:FindFirstChildOfClass("Humanoid")
			local nm = tp and tp.Name or (targetRoot.Parent and targetRoot.Parent.Name or "?")
			nameT.Text = string.format("[TARGET] %s%s", nm, hum and string.format("  %d HP", math.floor(hum.Health)) or "")
			nameT.Position = Vector2.new(top.X, top.Y - 24)
			nameT.Color = cfg.TargetLineColor
			nameT.Visible = true
			boxShown = true
		end
	end
	if not boxShown then box.Visible = false; nameT.Visible = false end

	local pts = {}
	for i = 1, ORBIT_SEGMENTS do
		local a = (i / ORBIT_SEGMENTS) * math.pi * 2
		local p2, ok = proj(cam, center + Vector3.new(math.cos(a) * r, -1, math.sin(a) * r))
		pts[i] = { p2, ok }
	end
	for i = 1, ORBIT_SEGMENTS do
		local a, b = pts[i], pts[i % ORBIT_SEGMENTS + 1]
		local line = TargetVis.Orbit[i]
		if cfg.OrbitVisualEnabled and a[2] and b[2] then
			line.From, line.To = a[1], b[1]
			line.Color = cfg.OrbitColor
			line.Visible = true
		else
			line.Visible = false
		end
	end

	for i = 1, RAY_COUNT do
		local line = TargetVis.Rays[i]
		if cfg.LaserRaysEnabled and centerOk then
			local a = (i / RAY_COUNT) * math.pi * 2 + t * 1.5
			local endPos = center + Vector3.new(math.cos(a) * r * 1.6, math.sin(a * 3 + t) * r * 0.9, math.sin(a) * r * 1.6)
			local e, ok = proj(cam, endPos)
			if ok then
				line.From, line.To = centerScreen, e
				line.Color = cfg.LaserColor
				line.Visible = true
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end

	local tl = TargetVis.Line
	if HumanoidRootPart and centerOk then
		local me, meOk = proj(cam, HumanoidRootPart.Position)
		if meOk then
			tl.From, tl.To = me, centerScreen
			tl.Color = cfg.TargetLineColor
			tl.Visible = cfg.OrbitVisualEnabled or cfg.LaserRaysEnabled
		else
			tl.Visible = false
		end
	else
		tl.Visible = false
	end
end

---------------------------------------------------------------------
-- DOORS / SKELETONS / HIGHLIGHTS
---------------------------------------------------------------------
local DoorESPObjects = {}
local SkeletonESPObjects = {}

local function isActualWoodenDoor(obj)
	if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
	local nameLower = string.lower(obj.Name)
	if string.find(nameLower, "portal") or string.find(nameLower, "candydoor") or string.find(nameLower, "teleport") or string.find(nameLower, "gate") or string.find(nameLower, "tp") then return false end
	if not (string.find(nameLower, "door") or string.find(nameLower, "wooden") or string.find(nameLower, "house")) then return false end
	return obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
end

local function registerDoor(obj)
	if not DoorESPObjects[obj] and isActualWoodenDoor(obj) then
		DoorESPObjects[obj] = not Drawing and {} or {
			Box = newDrawing("Square", { Thickness = 2, Filled = false, Visible = false }),
			Text = newDrawing("Text", { Size = 14, Center = true, Outline = true, Font = Drawing.Fonts.UI, Visible = false }),
		}
	end
end

local function getDoorTimerText(doorObj)
	for _, gui in ipairs(doorObj:GetDescendants()) do
		if gui:IsA("TextLabel") or gui:IsA("TextBox") then
			local s = gui.Text
			if s and string.match(s, "%d+:%d%d") then return s end
		end
	end
	return nil
end

local function isValidSkeleton(obj)
	local n = string.lower(obj.Name)
	return string.find(n, "skeleton") or string.find(n, "bone") or string.find(n, "undead")
end

local function registerSkeleton(obj)
	if obj:IsA("Model") and not SkeletonESPObjects[obj] and isValidSkeleton(obj) then
		local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
		if hrp then
			SkeletonESPObjects[obj] = not Drawing and {} or {
				Box = newDrawing("Square", { Thickness = 1.5, Filled = false, Visible = false }),
				Text = newDrawing("Text", { Size = 14, Center = true, Outline = true, Font = Drawing.Fonts.UI, Visible = false }),
			}
		end
	end
end

local function updatePlayerHighlight(p)
	local cfg = getgenv().Config
	if p.Character then
		local hasPumpkin = isCarryingPumpkin(p)
		if cfg.PlayerHighlightEnabled or (cfg.PumpkinESPEnabled and hasPumpkin) then
			if not Highlights[p] or not Highlights[p].Parent then
				local hl = Instance.new("Highlight")
				hl.Name = "CustomHighlight"
				hl.Adornee = p.Character
				hl.OutlineTransparency = 0
				hl.Parent = p.Character
				Highlights[p] = hl
			end
			Highlights[p].FillColor = hasPumpkin and cfg.PumpkinColor or cfg.HighlightColor
			Highlights[p].FillTransparency = hasPumpkin and 0.25 or 0.5
			Highlights[p].OutlineColor = hasPumpkin and Color3.fromRGB(255, 255, 255) or cfg.HighlightColor
		elseif Highlights[p] then
			Highlights[p]:Destroy(); Highlights[p] = nil
		end
	elseif Highlights[p] then
		Highlights[p]:Destroy(); Highlights[p] = nil
	end
end

local running = true
if Drawing then initTargetVisuals() end

task.spawn(function()
	while running do
		local cfg = getgenv().Config
		for i, v in ipairs(workspace:GetDescendants()) do
			registerDoor(v)
			registerSkeleton(v)
			if cfg.InstantInteractEnabled and v:IsA("ProximityPrompt") then v.HoldDuration = 0 end
			if i % 1000 == 0 then task.wait() end -- no lag spikes on big maps
		end
		task.wait(2)
	end
end)

table.insert(connections, Players.PlayerRemoving:Connect(removePlayerESP))

---------------------------------------------------------------------
-- HVH ORBIT (moves your real character, so the server sees it)
---------------------------------------------------------------------
local orbitAngle = 0
local wasOrbiting = false
local smoothCenter = nil
local lastNoclip = 0

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	local cfg = getgenv().Config
	dt = math.min(dt, 0.1)

	local canOrbit = cfg.HVHEnabled and HumanoidRootPart and HumanoidRootPart.Parent and Humanoid and Humanoid.Health > 0
	if canOrbit then
		local targetRoot = getTargetRoot()
		if targetRoot then
			wasOrbiting = true
			Humanoid.AutoRotate = false

			-- SpinSpeed = degrees per second
			-- snap the frame time to a steady rate (60/45/30 fps...) so every frame turns
			-- by exactly the same angle; raw dt noise is what made fast spins shake
			local fps = math.clamp(5 * math.floor((1 / math.max(dt, 0.0001)) / 5 + 0.5), 10, 240)
			orbitAngle = (orbitAngle + math.rad(cfg.SpinSpeed) / fps) % (math.pi * 2)

			-- smooth the target position so network jitter on the target doesn't shake you
			local rawCenter = targetRoot.Position
			if not smoothCenter or (smoothCenter - rawCenter).Magnitude > 40 then
				smoothCenter = rawCenter
			else
				smoothCenter = smoothCenter:Lerp(rawCenter, math.clamp(dt * 30, 0, 1))
			end
			local center = smoothCenter

			local pos = center + Vector3.new(math.cos(orbitAngle) * cfg.Radius, 0, math.sin(orbitAngle) * cfg.Radius)
			HumanoidRootPart.CFrame = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
			HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero

			-- keep the camera on the target so your view doesn't whip around the circle
			if cfg.StableCamera then
				local cam = workspace.CurrentCamera
				local th = targetRoot.Parent and targetRoot.Parent:FindFirstChildOfClass("Humanoid")
				if cam and th and cam.CameraSubject ~= th then cam.CameraSubject = th end
			end

			-- no-collide only a few times per second (doing it every frame is wasteful)
			local now = os.clock()
			if Character and now - lastNoclip > 0.25 then
				lastNoclip = now
				for _, part in ipairs(Character:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
			return
		end
	end

	if wasOrbiting then
		wasOrbiting = false
		smoothCenter = nil
		if Humanoid then Humanoid.AutoRotate = true end
		local cam = workspace.CurrentCamera
		if cam and Humanoid then cam.CameraSubject = Humanoid end
	end
end))

---------------------------------------------------------------------
-- AUTO DOORS + KILL FARM
---------------------------------------------------------------------
local farmState = { door = nil, phase = "rise", openStart = 0, lastFire = 0, visited = {}, idleSpot = nil, hold = nil, target = nil, lastAttack = 0, kills = 0 }
local savedTransparency = {}
local farmInvisible = false

table.insert(connections, player.CharacterAdded:Connect(function()
	farmInvisible = false
	savedTransparency = {}
	farmState.door, farmState.target, farmState.hold, farmState.idleSpot = nil, nil, nil, nil
end))

local function setFarmInvisible(on)
	if on == farmInvisible then return end
	farmInvisible = on
	if on then
		if not Character then return end
		for _, d in ipairs(Character:GetDescendants()) do
			if (d:IsA("BasePart") or d:IsA("Decal")) and d.Name ~= "HumanoidRootPart" then
				savedTransparency[d] = d.Transparency
				d.Transparency = 1
			end
		end
	else
		for d, t in pairs(savedTransparency) do
			if d and d.Parent then d.Transparency = t end
		end
		savedTransparency = {}
	end
end

local function holdHere()
	local hrp = HumanoidRootPart
	if not farmState.hold then farmState.hold = hrp.CFrame end
	hrp.CFrame = farmState.hold
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end

-- moves the character toward a point at `speed` studs/s; returns true when arrived
local function stepToward(targetPos, speed, dt, stopDist)
	local hrp = HumanoidRootPart
	stopDist = stopDist or 0.5
	local cur = hrp.Position
	local diff = targetPos - cur
	local dist = diff.Magnitude
	if dist <= stopDist then
		holdHere()
		return true
	end
	local step = math.min(speed * dt, dist - stopDist)
	local newPos = cur + diff.Unit * step
	local rot = hrp.CFrame - hrp.CFrame.Position
	farmState.hold = CFrame.new(newPos) * rot
	hrp.CFrame = farmState.hold
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	return (targetPos - newPos).Magnitude <= stopDist
end

local function doorPos(d)
	return d:IsA("Model") and d:GetPivot().Position or d.Position
end

local function isDoorReady(d)
	local t = getDoorTimerText(d)
	return (not t) or t == "0:00"
end

local lastStatus = ""
local function setFarmStatus(text)
	if FarmUI.Status and text ~= lastStatus then
		lastStatus = text
		FarmUI.Status.Text = "Status: " .. text
	end
end

local farmDoorBusy = false

local function pickDoor()
	local best, bestD
	for d in pairs(DoorESPObjects) do
		if d and d.Parent then
			local v = farmState.visited[d]
			if (not v or os.clock() - v > 30) and isDoorReady(d) then
				local dd = (doorPos(d) - HumanoidRootPart.Position).Magnitude
				if not bestD or dd < bestD then best, bestD = d, dd end
			end
		end
	end
	return best
end

-- a door counts as opened once its prompt is gone/disabled or its cooldown timer shows
local function doorOpened(door, prompt)
	if prompt and (not prompt.Parent or not prompt.Enabled) then return true end
	return not isDoorReady(door)
end

-- opens the door like a player: fire the prompt, then hold/tap the interact key as backup
local function pressPrompt(prompt)
	pcall(function() prompt.HoldDuration = 0 end)
	pcall(function() prompt.RequiresLineOfSight = false end)
	local fired = false
	if fireproximityprompt then
		fired = pcall(fireproximityprompt, prompt)
	end
	if not fired then
		pcall(function() prompt:InputHoldBegin() end)
		task.wait(0.1)
		pcall(function() prompt:InputHoldEnd() end)
	end
	task.wait(0.15)
	if not prompt.Parent or not prompt.Enabled then return end -- it worked
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		local key = prompt.KeyboardKeyCode
		if not key or key == Enum.KeyCode.Unknown then key = Enum.KeyCode.E end
		vim:SendKeyEvent(true, key, false, game)
		task.wait(math.max(prompt.HoldDuration, 0) + 0.1)
		vim:SendKeyEvent(false, key, false, game)
	end)
end

local function doorFarmActive()
	local cfg = getgenv().Config
	return running and cfg.AutoFarmDoors and not cfg.HVHEnabled
		and HumanoidRootPart and HumanoidRootPart.Parent and Humanoid and Humanoid.Health > 0
end

-- where the player actually has to stand: next to the prompt, not the door model's pivot
local function interactPos(door, prompt)
	if prompt then
		local par = prompt.Parent
		if par and par:IsA("BasePart") then return par.Position end
		if par and par:IsA("Attachment") then return par.WorldPosition end
	end
	return doorPos(door)
end

-- slides the character to `goal` at the Travel Speed (studs/s). The step never exceeds the
-- remaining distance, so even 1000 st/s cannot overshoot. Collision is switched off every
-- frame while sliding so walls and props can't shove you off the route.
-- `near` (optional) lets the slide stop early; otherwise it ends exactly on `goal`.
local function glideTo(goal, near, deadline)
	local hrp = HumanoidRootPart
	if not Character then return false end
	local parts = {}
	for _, d in ipairs(Character:GetDescendants()) do
		if d:IsA("BasePart") then parts[#parts + 1] = d end
	end

	local result = false
	while doorFarmActive() do
		if near and near() then result = true; break end
		if os.clock() > deadline then break end
		local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
		if not doorFarmActive() then break end

		local cur = hrp.Position
		local diff = goal - cur
		local dist = diff.Magnitude
		if dist <= 0.05 then result = true; break end

		local step = math.min(getgenv().Config.DoorTravelSpeed * dt, dist)
		local newPos = cur + diff.Unit * step
		local flatDir = Vector3.new(diff.X, 0, diff.Z)
		if flatDir.Magnitude > 0.5 then
			hrp.CFrame = CFrame.lookAt(newPos, newPos + flatDir)
		else
			hrp.CFrame = CFrame.new(newPos) * (hrp.CFrame - hrp.CFrame.Position)
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		for _, part in ipairs(parts) do part.CanCollide = false end
		-- keeps the walking animation playing while we slide
		if flatDir.Magnitude > 0.5 then pcall(function() Humanoid:Move(flatDir.Unit, false) end) end
	end
	pcall(function() Humanoid:Move(Vector3.zero, false) end)
	return result
end

-- Walk speed is raised to "Walk Speed To Door" only while walking, then put back
local origWalkSpeed = nil
local function useDoorSpeed()
	if Humanoid then
		if not origWalkSpeed then origWalkSpeed = Humanoid.WalkSpeed end
		Humanoid.WalkSpeed = getgenv().Config.DoorTravelSpeed
	end
end
local function restoreDoorSpeed()
	if origWalkSpeed and Humanoid then Humanoid.WalkSpeed = origWalkSpeed end
	origWalkSpeed = nil
end

-- FLY route (backup when walking is blocked; no pathfinding, so walls can't stop it):
--   1) rise straight up to Fly Height   2) fly level over the door   3) drop onto the prompt
local function flyTo(targetPos, reach, timeout)
	local deadline = os.clock() + timeout
	local hrp = HumanoidRootPart
	local function near() return (hrp.Position - targetPos).Magnitude <= reach end
	if near() then return true end

	local cfg = getgenv().Config
	local cruiseY = math.max(hrp.Position.Y, targetPos.Y) + cfg.FlyHeight

	setFarmStatus("Rising")
	if not glideTo(Vector3.new(hrp.Position.X, cruiseY, hrp.Position.Z), nil, deadline) then return false end

	setFarmStatus("Flying to door")
	if not glideTo(Vector3.new(targetPos.X, cruiseY, targetPos.Z), nil, deadline) then return false end

	setFarmStatus("Landing on door")
	glideTo(targetPos, nil, deadline)
	return near()
end

-- WALK route: the real humanoid walks. It picks a spot to stand IN FRONT of the door that has
-- a real path, follows it, and when stuck it escalates: jump -> side-step -> fresh path ->
-- short hop over the obstacle -> next stand spot -> straight walk (walkTo then flies over).
local DoorNav = { door = nil }

local function doorTaken()
	local d = DoorNav.door
	return d ~= nil and d.Parent ~= nil and not isDoorReady(d)
end

function DoorNav.groundBelow(pos)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { Character }
	local r = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -24, 0), rp)
	return r and r.Position or nil
end

-- spots around the door where a player could stand, nearest to you first
function DoorNav.spots(goal)
	local list = {}
	for _, radius in ipairs({ 4, 6.5 }) do
		for i = 0, 7 do
			local a = i * math.pi / 4
			local g = DoorNav.groundBelow(goal + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius))
			if g and math.abs(g.Y - goal.Y) < 10 then
				list[#list + 1] = { pos = g + Vector3.new(0, 1, 0), d = (g - HumanoidRootPart.Position).Magnitude }
			end
		end
	end
	table.sort(list, function(x, y) return x.d < y.d end)
	return list
end

function DoorNav.compute(from, to)
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = true, WaypointSpacing = 6 })
	local ok = pcall(function() path:ComputeAsync(from, to) end)
	if ok and path.Status == Enum.PathStatus.Success then return path end
	return nil
end

function DoorNav.follow(path, spot, goal, reach, deadline)
	local hrp, hum = HumanoidRootPart, Humanoid
	local function near() return (hrp.Position - goal).Magnitude <= reach end
	local blocked = false
	local conn = path.Blocked:Connect(function() blocked = true end)
	local wps = path:GetWaypoints()
	local i, best, lastProgress, stuck, recomputes = 2, math.huge, os.clock(), 0, 0
	local result = false

	while doorFarmActive() and os.clock() < deadline do
		if near() then result = true; break end
		if doorTaken() then break end
		local wp = wps[i]
		if not wp then result = near(); break end

		useDoorSpeed()
		if hum.Sit then hum.Sit = false end
		if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
		hum:MoveTo(wp.Position)

		local dx, dz = hrp.Position.X - wp.Position.X, hrp.Position.Z - wp.Position.Z
		local flat = math.sqrt(dx * dx + dz * dz)
		local now = os.clock()
		if flat <= 3.5 then
			i = i + 1
			best, lastProgress, stuck = math.huge, now, 0
		else
			if flat < best - 0.8 then best, lastProgress = flat, now end
			local needFresh = blocked
			if now - lastProgress > 0.5 then
				stuck = stuck + 1
				lastProgress, best = now, math.huge
				if stuck == 1 then
					hum.Jump = true
				elseif stuck == 2 then
					local dir = wp.Position - hrp.Position
					local side = Vector3.new(-dir.Z, 0, dir.X)
					if side.Magnitude > 0.1 then
						hum:MoveTo(hrp.Position + side.Unit * 6 * (math.random() < 0.5 and 1 or -1))
						task.wait(0.35)
					end
				elseif stuck == 3 then
					needFresh = true
				elseif stuck == 4 then
					local dir = Vector3.new(-dx, 0, -dz)
					if dir.Magnitude > 0.1 then
						hrp.CFrame = hrp.CFrame + dir.Unit * math.min(7, dir.Magnitude) + Vector3.new(0, 3, 0)
					end
				else
					break -- give up on this stand spot
				end
			end
			if needFresh then
				blocked = false
				recomputes = recomputes + 1
				if recomputes > 4 then break end
				local np = DoorNav.compute(hrp.Position, spot)
				if not np then break end
				conn:Disconnect()
				path = np
				conn = path.Blocked:Connect(function() blocked = true end)
				wps = path:GetWaypoints()
				i, best, lastProgress, stuck = 2, math.huge, os.clock(), 0
			end
		end
		RunService.Heartbeat:Wait()
	end
	conn:Disconnect()
	return result
end

-- no usable path: walk straight at the door, jumping when blocked
function DoorNav.straight(goal, reach, deadline)
	local hrp, hum = HumanoidRootPart, Humanoid
	local t0 = os.clock()
	local best, lastProgress = math.huge, t0
	while doorFarmActive() and os.clock() < deadline and os.clock() - t0 < 6 do
		useDoorSpeed()
		hum:MoveTo(goal)
		local d = (hrp.Position - goal).Magnitude
		if d <= reach then return true end
		local now = os.clock()
		if d < best - 0.8 then
			best, lastProgress = d, now
		elseif now - lastProgress > 0.6 then
			hum.Jump = true
			if now - lastProgress > 1.5 then return false end
		end
		RunService.Heartbeat:Wait()
	end
	return (hrp.Position - goal).Magnitude <= reach
end

function DoorNav.walk(goal, reach, deadline)
	local hrp = HumanoidRootPart
	if not hrp or not Humanoid then return false end
	if (hrp.Position - goal).Magnitude <= reach then return true end
	local attempts, followed = 0, 0
	for _, sp in ipairs(DoorNav.spots(goal)) do
		if not doorFarmActive() or os.clock() > deadline or attempts >= 8 or followed >= 3 then break end
		if doorTaken() then return false end
		attempts = attempts + 1
		local path = DoorNav.compute(hrp.Position, sp.pos)
		if path then
			followed = followed + 1
			if DoorNav.follow(path, sp.pos, goal, reach, deadline) then return true end
		end
	end
	if doorFarmActive() and os.clock() < deadline and not doorTaken() then
		return DoorNav.straight(goal, reach, deadline)
	end
	return false
end

local function walkTo(targetPos, reach, timeout, door)
	local hrp = HumanoidRootPart
	if (hrp.Position - targetPos).Magnitude <= reach then return true end
	local deadline = os.clock() + timeout
	DoorNav.door = door
	setFarmStatus(string.format("Walking to door (%dm)", math.floor((targetPos - hrp.Position).Magnitude)))
	if DoorNav.walk(targetPos, reach, deadline) then return true end
	if doorTaken() then return false end
	if not doorFarmActive() then return false end
	-- walking was blocked: fly over instead so the door still gets opened
	setFarmStatus("Blocked, flying over")
	return flyTo(targetPos, reach, 15)
end

local function doorLoopStep()
	local cfg = getgenv().Config
	if not doorFarmActive() then
		restoreDoorSpeed()
		farmDoorBusy = false
		task.wait(0.3)
		return
	end

	local door = pickDoor()
	if not door then
		farmDoorBusy = false
		if not cfg.KillFarmEnabled then setFarmStatus("Waiting for door") end
		task.wait(0.5)
		return
	end

	farmDoorBusy = true
	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then pcall(function() prompt.RequiresLineOfSight = false end) end
	local reach = math.clamp((prompt and prompt.MaxActivationDistance or 10) - 3, 3, 12)
	local target = interactPos(door, prompt)

	local arrived = walkTo(target, reach, 35, door) and doorFarmActive()

	if arrived then
		setFarmStatus("Opening door")
		local hrp = HumanoidRootPart
		-- freeze in place on the prompt (no falling) while it is triggered
		local holdCF = hrp.CFrame
		local flatDiff = Vector3.new(target.X - hrp.Position.X, 0, target.Z - hrp.Position.Z)
		if flatDiff.Magnitude > 0.2 then
			holdCF = CFrame.lookAt(hrp.Position, hrp.Position + flatDiff)
		end
		local parts = {}
		for _, d in ipairs(Character:GetDescendants()) do
			if d:IsA("BasePart") then parts[#parts + 1] = d end
		end
		local t0, lastPress = os.clock(), 0
		while doorFarmActive() and door.Parent and not doorOpened(door, prompt) and os.clock() - t0 < cfg.OpenTimeout do
			hrp.CFrame = holdCF
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			for _, part in ipairs(parts) do part.CanCollide = false end
			local now = os.clock()
			if prompt and prompt.Parent and now - lastPress > 0.4 then
				lastPress = now
				task.spawn(pressPrompt, prompt)
			end
			RunService.Heartbeat:Wait()
		end
	else
		setFarmStatus("Door unreachable, next")
	end
	-- a failed door is retried after 10s, an opened one after 30s
	restoreDoorSpeed()
	farmState.visited[door] = os.clock() - (arrived and 0 or 20)
end

task.spawn(function()
	while running do
		local ok = pcall(doorLoopStep)
		if not ok then task.wait(0.5) end
	end
end)

local function pickKillTarget(cfg)
	local best, bestHum, bestD
	local pos = HumanoidRootPart.Position
	if cfg.KillFarmRole == "Killer" then
		for obj in pairs(SkeletonESPObjects) do
			if obj and obj.Parent then
				local hum = obj:FindFirstChildOfClass("Humanoid")
				local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
				if hum and root and hum.Health > 0 then
					local d = (root.Position - pos).Magnitude
					if not bestD or d < bestD then best, bestHum, bestD = root, hum, d end
				end
			end
		end
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					local d = (root.Position - pos).Magnitude
					if not bestD or d < bestD then best, bestHum, bestD = root, hum, d end
				end
			end
		end
	end
	return best, bestHum
end

local function doAttack()
	if not Character or not Humanoid then return end
	local tool = Character:FindFirstChildOfClass("Tool")
	if not tool then
		local bp = player:FindFirstChildOfClass("Backpack")
		tool = bp and bp:FindFirstChildOfClass("Tool")
		if tool then pcall(function() Humanoid:EquipTool(tool) end) end
	end
	if tool then pcall(function() tool:Activate() end) end
	if mouse1click then pcall(mouse1click) end
end

local function killFarmStep(dt, cfg)
	local hrp = HumanoidRootPart
	local t = farmState.target
	if t then
		if t.hum.Health <= 0 then
			farmState.kills = farmState.kills + 1
			if FarmUI.Kills then FarmUI.Kills.Text = "Kills: " .. farmState.kills end
			farmState.target = nil; t = nil
		elseif not t.hum.Parent or not t.root.Parent then
			farmState.target = nil; t = nil
		end
	end
	if not t then
		local root, hum = pickKillTarget(cfg)
		if root then
			t = { root = root, hum = hum }
			farmState.target = t
		end
	end

	if t then
		local goal = (t.root.CFrame * CFrame.new(0, 0, 3)).Position
		stepToward(goal, cfg.KillFarmSpeed, dt, 0.5)
		local tp = t.root.Position
		farmState.hold = CFrame.lookAt(hrp.Position, Vector3.new(tp.X, hrp.Position.Y, tp.Z))
		hrp.CFrame = farmState.hold
		local now = os.clock()
		if (hrp.Position - tp).Magnitude <= 12 and now - farmState.lastAttack > 0.12 then
			farmState.lastAttack = now
			doAttack()
		end
		return "Attacking"
	end

	if cfg.UseIdleSpot and farmState.idleSpot then
		stepToward(farmState.idleSpot, cfg.KillFarmSpeed, dt, 1)
	else
		holdHere()
	end
	return "Idle"
end

local lastFarmNoclip = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	local cfg = getgenv().Config
	dt = math.min(dt, 0.1)
	local alive = HumanoidRootPart and HumanoidRootPart.Parent and Humanoid and Humanoid.Health > 0
	local farming = alive and not cfg.HVHEnabled and (cfg.AutoFarmDoors or cfg.KillFarmEnabled)
	setFarmInvisible((farming and cfg.InvisibleFarming) and true or false)

	if alive and not cfg.HVHEnabled and cfg.KillFarmEnabled and not farmDoorBusy then
		if not farmState.idleSpot then farmState.idleSpot = HumanoidRootPart.Position end
		local now = os.clock()
		if Character and now - lastFarmNoclip > 0.25 then
			lastFarmNoclip = now
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
		setFarmStatus(killFarmStep(dt, cfg))
	else
		farmState.hold = nil
		if not cfg.KillFarmEnabled then
			farmState.idleSpot, farmState.target = nil, nil
			if not cfg.AutoFarmDoors then setFarmStatus("Idle") end
		end
	end
end))

---------------------------------------------------------------------
-- AUTO BLOCK + PUNISH (Jujutsu Shenanigans style: F block, Q dash, M1)
---------------------------------------------------------------------
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local function sendKey(name, down)
	if not VIM then return end
	local code = Enum.KeyCode[name]
	if code then pcall(function() VIM:SendKeyEvent(down, code, false, game) end) end
end

local function tapKey(name)
	sendKey(name, true)
	task.delay(0.05, function() sendKey(name, false) end)
end

-- M1 click: sent at the far right edge so it never lands on this window
local function doM1()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	if VIM then
		pcall(function()
			VIM:SendMouseButtonEvent(vp.X * 0.995, vp.Y * 0.45, 0, true, game, 0)
			VIM:SendMouseButtonEvent(vp.X * 0.995, vp.Y * 0.45, 0, false, game, 0)
		end)
	elseif mouse1click then
		pcall(mouse1click)
	end
	local tool = Character and Character:FindFirstChildOfClass("Tool")
	if tool then pcall(function() tool:Activate() end) end
end

local NOT_ATTACK = { "idle", "walk", "run", "jump", "fall", "climb", "swim", "sit", "land", "emote", "dance", "pose", "block", "stun", "ragdoll" }

-- an enemy counts as attacking while an Action-priority animation (not idle/walk/block...) plays
local function isAttacking(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then return false end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		local pv = track.Priority.Value
		if track.IsPlaying and pv >= 2 and pv < 1000 and track.Length > 0 and track.Length < 3.5 then
			local nm = string.lower(track.Name)
			local skip = false
			for _, w in ipairs(NOT_ATTACK) do
				if string.find(nm, w, 1, true) then skip = true; break end
			end
			if not skip then return true end
		end
	end
	return false
end

local function flatDirOf(v) return Vector3.new(v.X, 0, v.Z) end

-- is `pos` inside the cone in front of `cf` (total cone width = angle degrees)?
local function inFront(cf, pos, angle)
	local dir = flatDirOf(pos - cf.Position)
	local look = flatDirOf(cf.LookVector)
	if dir.Magnitude < 0.01 or look.Magnitude < 0.01 then return true end
	local c = math.clamp(look.Unit:Dot(dir.Unit), -1, 1)
	return math.deg(math.acos(c)) <= angle / 2
end

local function runPunish(hrp, cfg)
	task.spawn(function()
		task.wait(cfg.DashPunishDelay)
		local me = HumanoidRootPart
		if not (me and me.Parent and hrp.Parent) then return end
		local d = (hrp.Position - me.Position).Magnitude
		if cfg.DashPunish and d > 7 and d <= cfg.PunishRange then
			me.CFrame = CFrame.lookAt(me.Position, Vector3.new(hrp.Position.X, me.Position.Y, hrp.Position.Z))
			tapKey(cfg.DashKey)
			task.wait(0.25)
		end
		local t0 = os.clock()
		while os.clock() - t0 < 0.6 and hrp.Parent and HumanoidRootPart do
			if (hrp.Position - HumanoidRootPart.Position).Magnitude > cfg.M1CatchRange then break end
			doM1()
			task.wait(0.12)
		end
	end)
end

local blockHeld, blockUntil, lastPunish = false, 0, 0
local attackState = {}

table.insert(connections, RunService.Heartbeat:Connect(function()
	local cfg = getgenv().Config
	local alive = HumanoidRootPart and HumanoidRootPart.Parent and Humanoid and Humanoid.Health > 0
	if not alive or not cfg.AutoBlockEnabled then
		if blockHeld then
			blockHeld = false
			sendKey(cfg.BlockKey, false)
		end
	end
	if not alive or not (cfg.AutoBlockEnabled or cfg.PunishEnabled) then return end

	local now = os.clock()
	local myCF = HumanoidRootPart.CFrame
	local lockRoot = cfg.OnlyLockedTarget and getTargetRoot() or nil
	local range = math.max(cfg.BlockRange, cfg.PunishRange)
	local wantBlock = false

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local dist = (hrp.Position - myCF.Position).Magnitude
				if dist <= range then
					local attacking = isAttacking(p.Character)
					local was = attackState[p]
					attackState[p] = attacking

					-- enemy's swing just finished while facing us -> punish the endlag
					if was and not attacking and cfg.PunishEnabled and dist <= cfg.PunishRange and now - lastPunish > 0.5 then
						local toMe = flatDirOf(myCF.Position - hrp.Position)
						local look = flatDirOf(hrp.CFrame.LookVector)
						if toMe.Magnitude > 0.01 and look.Magnitude > 0.01 and look.Unit:Dot(toMe.Unit) > 0.3 then
							lastPunish = now
							runPunish(hrp, cfg)
						end
					end

					if cfg.AutoBlockEnabled and attacking and dist <= cfg.BlockRange then
						local ok = true
						if cfg.OnlySelectedTarget and cfg.SelectedTarget ~= "None" then ok = (p.Name == cfg.SelectedTarget) end
						if ok and cfg.OnlyLockedTarget then ok = (lockRoot == hrp) end
						if ok and cfg.OnlyBlockAngle then ok = inFront(myCF, hrp.Position, cfg.BlockAngle) end
						if ok then wantBlock = true end
					end
				else
					attackState[p] = nil
				end
			end
		end
	end

	if wantBlock then
		blockUntil = now + 0.25
		if not blockHeld then
			blockHeld = true
			sendKey(cfg.BlockKey, true)
		end
	elseif blockHeld and now > blockUntil then
		blockHeld = false
		sendKey(cfg.BlockKey, false)
	end
end))

-- hotkey for the Enabled checkbox
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	local cfg = getgenv().Config
	if cfg.AutoBlockKeyCode and input.KeyCode == cfg.AutoBlockKeyCode and UIRefs.setAutoBlock then
		UIRefs.setAutoBlock(not cfg.AutoBlockEnabled)
	end
end))

-- "Show Angle": draws the block cone on the ground in front of you
local ANGLE_SEG = 12
local AngleLines = {}
if Drawing then
	for i = 1, ANGLE_SEG + 2 do
		AngleLines[i] = newDrawing("Line", { Thickness = 1.5, Visible = false, Color = Color3.fromRGB(255, 255, 255) })
	end
end

local function renderAngle(cam)
	local cfg = getgenv().Config
	if not cfg.ShowAngle or not HumanoidRootPart then
		for _, l in ipairs(AngleLines) do l.Visible = false end
		return
	end
	local origin = HumanoidRootPart.Position - Vector3.new(0, 2.8, 0)
	local lv = flatDirOf(HumanoidRootPart.CFrame.LookVector)
	if lv.Magnitude < 0.01 then return end
	local base = CFrame.lookAt(origin, origin + lv)
	local half = math.rad(cfg.BlockAngle / 2)
	local pts = {}
	for i = 0, ANGLE_SEG do
		local a = -half + (2 * half) * (i / ANGLE_SEG)
		pts[i + 1] = origin + (base * CFrame.Angles(0, a, 0)).LookVector * cfg.BlockRange
	end
	local lines = {}
	for i = 1, ANGLE_SEG do lines[i] = { pts[i], pts[i + 1] } end
	lines[ANGLE_SEG + 1] = { origin, pts[1] }
	lines[ANGLE_SEG + 2] = { origin, pts[ANGLE_SEG + 1] }
	for i, seg in ipairs(lines) do
		local a2, aOk = proj(cam, seg[1])
		local b2, bOk = proj(cam, seg[2])
		local l = AngleLines[i]
		if l then
			if aOk and bOk then
				l.From, l.To = a2, b2
				l.Visible = true
			else
				l.Visible = false
			end
		end
	end
end

---------------------------------------------------------------------
-- AVATAR (client-side copy: swaps clothes, accessories, body colours and face)
---------------------------------------------------------------------
local Avatar = { backup = nil }

local function flash(btn, msg, orig)
	btn.Text = msg
	task.delay(1.4, function()
		if btn.Parent then btn.Text = orig end
	end)
end

local function otherPlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then list[#list + 1] = p end
	end
	return list
end

local LOOK_CLASSES = { "Shirt", "Pants", "ShirtGraphic", "BodyColors", "CharacterMesh" }
local function isLookItem(c)
	if c:IsA("Accessory") then return true end
	for _, cls in ipairs(LOOK_CLASSES) do
		if c:IsA(cls) then return true end
	end
	return false
end

local function addLookItem(item)
	local copy = item:Clone()
	if copy:IsA("Accessory") and Humanoid then
		if not pcall(function() Humanoid:AddAccessory(copy) end) then copy.Parent = Character end
	else
		copy.Parent = Character
	end
end

-- remembers how you looked before the first change (Restore Avatar puts it back)
function Avatar.snapshot()
	if Avatar.backup or not Character then return end
	local b = { items = {} }
	for _, c in ipairs(Character:GetChildren()) do
		if isLookItem(c) then b.items[#b.items + 1] = c:Clone() end
	end
	local head = Character:FindFirstChild("Head")
	local face = head and head:FindFirstChildOfClass("Decal")
	if face then b.face = face.Texture end
	Avatar.backup = b
end

function Avatar.wipe()
	if Humanoid then pcall(function() Humanoid:RemoveAccessories() end) end
	for _, c in ipairs(Character:GetChildren()) do
		if isLookItem(c) then c:Destroy() end
	end
end

-- copies every look item (and face / head mesh) from a character or appearance model
function Avatar.add(source)
	for _, c in ipairs(source:GetChildren()) do
		if isLookItem(c) then addLookItem(c) end
	end
	local sHead, head = source:FindFirstChild("Head"), Character:FindFirstChild("Head")
	if sHead and head then
		local sFace, face = sHead:FindFirstChildOfClass("Decal"), head:FindFirstChildOfClass("Decal")
		if sFace and face then face.Texture = sFace.Texture end
		local sMesh, mesh = sHead:FindFirstChildOfClass("SpecialMesh"), head:FindFirstChildOfClass("SpecialMesh")
		if sMesh and mesh then
			pcall(function()
				mesh.MeshId = sMesh.MeshId
				mesh.TextureId = sMesh.TextureId
				mesh.Scale = sMesh.Scale
			end)
		end
	end
end

function Avatar.findPlayer(text, exactOnly)
	local q = string.lower(text)
	local partial
	for _, p in ipairs(otherPlayers()) do
		local pn, dn = string.lower(p.Name), string.lower(p.DisplayName)
		if pn == q or dn == q then return p end
		if not exactOnly and not partial and (string.find(pn, q, 1, true) or string.find(dn, q, 1, true)) then partial = p end
	end
	return partial
end

-- any Roblox user (online or not): downloads their avatar appearance by user id
function Avatar.fromUserId(uid)
	if not Character or not Humanoid then return false, "No character" end
	local ok, model = pcall(function() return Players:GetCharacterAppearanceAsync(uid) end)
	if ok and model then
		Avatar.snapshot()
		Avatar.wipe()
		Avatar.add(model)
		model:Destroy()
		return true
	end
	local okd, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(uid) end)
	if okd and desc then
		Avatar.snapshot()
		if pcall(function() Humanoid:ApplyDescription(desc) end) then return true end
	end
	return false, "Couldn't load avatar"
end

-- a player in this server: copy exactly what their character is wearing right now
function Avatar.fromPlayer(p)
	if not Character or not Humanoid then return false, "No character" end
	if p.Character then
		Avatar.snapshot()
		Avatar.wipe()
		Avatar.add(p.Character)
		return true
	end
	return Avatar.fromUserId(p.UserId)
end

Actions.copyAvatar = function(btn, text)
	task.spawn(function()
		text = string.match(text or "", "^%s*(.-)%s*$")
		if text == "" then flash(btn, "Type a name or id", "Copy Avatar"); return end
		local ok, err
		local p = Avatar.findPlayer(text, tonumber(text) ~= nil)
		if p then
			ok, err = Avatar.fromPlayer(p)
		else
			local uid = tonumber(text)
			if not uid then
				local okId, res = pcall(function() return Players:GetUserIdFromNameAsync(text) end)
				if not okId then flash(btn, "User not found", "Copy Avatar"); return end
				uid = res
			end
			ok, err = Avatar.fromUserId(uid)
		end
		flash(btn, ok and "Copied!" or (err or "Failed"), "Copy Avatar")
	end)
end

Actions.copyRandom = function(btn)
	task.spawn(function()
		local list = otherPlayers()
		if #list == 0 then flash(btn, "No other players", "Copy Random Player"); return end
		local p = list[math.random(1, #list)]
		local ok, err = Avatar.fromPlayer(p)
		flash(btn, ok and ("Copied " .. p.Name) or (err or "Failed"), "Copy Random Player")
	end)
end

Actions.scramble = function(btn)
	task.spawn(function()
		if not Character or not Humanoid then flash(btn, "No character", "Scramble Avatar"); return end
		Avatar.snapshot()
		local shirts, pants, accs = {}, {}, {}
		for _, p in ipairs(otherPlayers()) do
			if p.Character then
				for _, c in ipairs(p.Character:GetChildren()) do
					if c:IsA("Shirt") then
						shirts[#shirts + 1] = c
					elseif c:IsA("Pants") then
						pants[#pants + 1] = c
					elseif c:IsA("Accessory") then
						accs[#accs + 1] = c
					end
				end
			end
		end
		Avatar.wipe()
		local function rc() return Color3.fromHSV(math.random(), 0.45, 0.9) end
		local bc = Instance.new("BodyColors")
		bc.HeadColor3, bc.TorsoColor3 = rc(), rc()
		bc.LeftArmColor3, bc.RightArmColor3 = rc(), rc()
		bc.LeftLegColor3, bc.RightLegColor3 = rc(), rc()
		bc.Parent = Character
		if #shirts > 0 then addLookItem(shirts[math.random(1, #shirts)]) end
		if #pants > 0 then addLookItem(pants[math.random(1, #pants)]) end
		for _ = 1, math.min(3, #accs) do
			addLookItem(accs[math.random(1, #accs)])
		end
		flash(btn, "Scrambled!", "Scramble Avatar")
	end)
end

Actions.restore = function(btn)
	task.spawn(function()
		local b = Avatar.backup
		if not b or not Character or not Humanoid then flash(btn, "Nothing to restore", "Restore Avatar"); return end
		Avatar.wipe()
		for _, item in ipairs(b.items) do addLookItem(item) end
		local head = Character:FindFirstChild("Head")
		local face = head and head:FindFirstChildOfClass("Decal")
		if face and b.face then face.Texture = b.face end
		flash(btn, "Restored!", "Restore Avatar")
	end)
end

---------------------------------------------------------------------
-- MAIN RENDER LOOP
---------------------------------------------------------------------
local frameCount = 0

table.insert(connections, RunService.RenderStepped:Connect(function()
	frameCount = frameCount + 1
	local cfg = getgenv().Config
	local cam = workspace.CurrentCamera
	if not cam then return end

	if Character then
		if cfg.SpeedHackEnabled and Humanoid and not farmDoorBusy then Humanoid.WalkSpeed = cfg.WalkSpeedValue end
		if cfg.NoclipEnabled then
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end

	if cfg.KillAuraSkeletons and HumanoidRootPart then
		for skelObj in pairs(SkeletonESPObjects) do
			if skelObj and skelObj.Parent then
				local skelRoot = skelObj:FindFirstChild("HumanoidRootPart") or skelObj:FindFirstChild("Head") or skelObj.PrimaryPart
				local hum = skelObj:FindFirstChildOfClass("Humanoid")
				if skelRoot and hum and hum.Health > 0 and (HumanoidRootPart.Position - skelRoot.Position).Magnitude <= 12 then
					hum:TakeDamage(10)
				end
			end
		end
	end

	if Drawing then
		pcall(renderPlayers, cam)
		pcall(renderTarget, cam, os.clock())
		pcall(renderAngle, cam)

		for doorObj, objs in pairs(DoorESPObjects) do
			if doorObj and doorObj.Parent then
				if cfg.DoorESPEnabled then
					local dPos = doorObj:IsA("Model") and doorObj:GetPivot().Position or doorObj.Position
					local pos, ok = proj(cam, dPos)
					if ok then
						local dist = math.floor((cam.CFrame.Position - dPos).Magnitude)
						local timerStr = getDoorTimerText(doorObj)
						local status = (timerStr and timerStr ~= "0:00") and timerStr or "Ready!"
						objs.Box.Size = Vector2.new(30, 45)
						objs.Box.Position = Vector2.new(pos.X - 15, pos.Y - 22)
						objs.Box.Color = cfg.DoorColor
						objs.Box.Visible = true
						objs.Text.Color = cfg.DoorColor
						objs.Text.Text = cfg.DoorShowDistance and string.format("Wooden Door\n[%s | %dm]", status, dist) or string.format("Wooden Door\n[%s]", status)
						objs.Text.Position = Vector2.new(pos.X, pos.Y - 56)
						objs.Text.Visible = true
					else
						objs.Box.Visible = false; objs.Text.Visible = false
					end
				else
					objs.Box.Visible = false; objs.Text.Visible = false
				end
			else
				removeAll(objs); DoorESPObjects[doorObj] = nil
			end
		end

		for skelObj, objs in pairs(SkeletonESPObjects) do
			if skelObj and skelObj.Parent then
				local hrp = skelObj:FindFirstChild("HumanoidRootPart") or skelObj:FindFirstChild("Head") or skelObj.PrimaryPart
				local hum = skelObj:FindFirstChildOfClass("Humanoid")
				if cfg.SkeletonESPEnabled and hrp and (not hum or hum.Health > 0) then
					local pos, ok = proj(cam, hrp.Position)
					if ok then
						local d = (cam.CFrame.Position - hrp.Position).Magnitude
						local scale = 1000 / math.max(d, 1)
						local width, height = 3 * scale, 4.5 * scale
						objs.Box.Size = Vector2.new(width, height)
						objs.Box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
						objs.Box.Color = cfg.SkeletonColor
						objs.Box.Visible = true
						objs.Text.Color = cfg.SkeletonColor
						objs.Text.Text = string.format("Skeleton [%dm]", math.floor(d))
						objs.Text.Position = Vector2.new(pos.X, pos.Y - height / 2 - 18)
						objs.Text.Visible = true
					else
						objs.Box.Visible = false; objs.Text.Visible = false
					end
				else
					objs.Box.Visible = false; objs.Text.Visible = false
				end
			else
				removeAll(objs); SkeletonESPObjects[skelObj] = nil
			end
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then updatePlayerHighlight(p) end
	end
end))

table.insert(connections, UserInputService.JumpRequest:Connect(function()
	if getgenv().Config.InfJumpEnabled and Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

---------------------------------------------------------------------
-- HOME STATS (Feature Count / Ping / FPS / Animations)
---------------------------------------------------------------------
task.spawn(function()
	local lastFrames, lastTime = frameCount, os.clock()
	while running do
		task.wait(1)
		local now = os.clock()
		local fps = math.floor((frameCount - lastFrames) / math.max(now - lastTime, 0.001) + 0.5)
		lastFrames, lastTime = frameCount, now

		local ping = 0
		local okPing, v = pcall(function()
			return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if okPing and v then ping = math.floor(v) else ping = math.floor(player:GetNetworkPing() * 2000) end

		local anims = 0
		pcall(function()
			if Humanoid then anims = #Humanoid:GetPlayingAnimationTracks() end
		end)

		if statLabels["Feature Count"] then statLabels["Feature Count"].Text = tostring(featureCount) end
		if statLabels["Ping"] then statLabels["Ping"].Text = tostring(ping) .. " ms" end
		if statLabels["FPS"] then statLabels["FPS"].Text = tostring(fps) end
		if statLabels["Animations"] then statLabels["Animations"].Text = tostring(anims) end
	end
end)

---------------------------------------------------------------------
-- MINIMIZE / CLOSE + MOBILE BLOCK BUTTON
---------------------------------------------------------------------
-- small floating logo shown while the window is minimized (tap = restore, drag = move)
local logoBtn = create("TextButton", {
	Name = "MiniLogo", Visible = false, Text = "",
	Size = UDim2.fromOffset(96, 96), AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -110, 0, 30),
	BackgroundColor3 = C.Window, BorderSizePixel = 0, AutoButtonColor = false,
}, screenGui)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, logoBtn)
stroke(logoBtn, Color3.fromRGB(235, 236, 242), 3)
local logoRing = create("Frame", {
	Size = UDim2.fromOffset(58, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	Rotation = -28, BackgroundTransparency = 1,
}, logoBtn)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, logoRing)
stroke(logoRing, C.White, 4)
local logoDot = create("Frame", {
	Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3 = C.White, BorderSizePixel = 0,
}, logoBtn)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, logoDot)

local function showMain(v)
	main.Visible = v
	logoBtn.Visible = not v
end

-- tap = onTap, drag = move the button
local function makeTapDrag(btn, onTap)
	local dragging, moved, dragStart, startPos = false, false, nil, nil
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart, startPos = input.Position, btn.Position
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = (input.Position - dragStart) * DRAG_SPEED
			if delta.Magnitude > 8 then moved = true end
			if moved then
				btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved then onTap() end
		end
	end))
end

makeTapDrag(logoBtn, function() showMain(true) end)

-- floating Auto Block ON/OFF button for phones (no keyboard needed)
local blockBtn = create("TextButton", {
	Name = "BlockBtn", Text = "BLOCK: OFF", TextSize = 18, Font = F.Bold, TextColor3 = C.White,
	Size = UDim2.fromOffset(130, 56), AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -20, 0.4, 0),
	BackgroundColor3 = C.Window, BorderSizePixel = 0, AutoButtonColor = false,
	Visible = getgenv().Config.MobileBlockButton,
}, screenGui)
corner(blockBtn, 16)
local blockStroke = stroke(blockBtn, Color3.fromRGB(120, 122, 135), 2)

UIRefs.refreshBlockBtn = function()
	local cfg = getgenv().Config
	blockBtn.Visible = cfg.MobileBlockButton
	blockBtn.Text = cfg.AutoBlockEnabled and "BLOCK: ON" or "BLOCK: OFF"
	blockBtn.TextColor3 = cfg.AutoBlockEnabled and Color3.fromRGB(0, 255, 120) or C.White
	blockStroke.Color = cfg.AutoBlockEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(120, 122, 135)
end
makeTapDrag(blockBtn, function()
	if UIRefs.setAutoBlock then UIRefs.setAutoBlock(not getgenv().Config.AutoBlockEnabled) end
end)
UIRefs.refreshBlockBtn()

minBtn.MouseButton1Click:Connect(function() showMain(false) end)

local function cleanup()
	running = false
	if origWalkSpeed and Humanoid then Humanoid.WalkSpeed = origWalkSpeed end
	getgenv().Config.HVHEnabled = false
	getgenv().Config.AutoFarmDoors = false
	getgenv().Config.KillFarmEnabled = false
	getgenv().Config.AutoBlockEnabled = false
	setFarmInvisible(false)
	if Humanoid then Humanoid.AutoRotate = true end
	local cam = workspace.CurrentCamera
	if cam and Humanoid then cam.CameraSubject = Humanoid end
	for _, c in ipairs(connections) do c:Disconnect() end
	for _, objs in pairs(PlayerESP) do removeAll(objs) end
	for _, objs in pairs(DoorESPObjects) do removeAll(objs) end
	for _, objs in pairs(SkeletonESPObjects) do removeAll(objs) end
	removeAll(TargetVis)
	removeAll(AngleLines)
	if blockHeld then sendKey(getgenv().Config.BlockKey, false) end
	for _, hl in pairs(Highlights) do hl:Destroy() end
	screenGui:Destroy()
end

getgenv().TheS_Cleanup = cleanup
closeBtn.MouseButton1Click:Connect(cleanup)

print("CodeBot V2: The S GUI loaded (JJS mobile build)")
