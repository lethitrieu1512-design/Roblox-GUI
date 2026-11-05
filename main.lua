-- CodeBot V1 | Roblox Luau (Delta compatible)
-- The S: ATOM-style GUI + full ESP + Server-visible Orbit HVH

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local StatsService = game:GetService("Stats")
local player = Players.LocalPlayer

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
	ESPMaxDistance = 3000,

	HVHEnabled = false,
	TargetClosest = true,
	TargetName = "",
	SpinSpeed = 5000, -- degrees per second (slider max 10000)
	Radius = 6,

	DoorESPEnabled = true,
	SkeletonESPEnabled = true,
	InstantInteractEnabled = true,
	AutoFarmDoors = false,
	KillAuraSkeletons = false,
	DoorShowDistance = true,
	InvisibleFarming = true,
	DoorTravelSpeed = 40,
	OpenTimeout = 6,
	KillFarmEnabled = false,
	KillFarmRole = "Killer",
	KillFarmSpeed = 385,
	UseIdleSpot = true,
	StableCamera = true,
	PumpkinESPEnabled = true,
	PlayerHighlightEnabled = true,

	SpeedHackEnabled = false,
	WalkSpeedValue = 32,
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

local old = guiParent:FindFirstChild("TheS_Gui")
if old then old:Destroy() end

local screenGui = create("ScreenGui", {
	Name = "TheS_Gui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local main = create("Frame", {
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

-- Dragging helper
local function makeDraggable(handle)
	local dragging = false
	local dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = (input.Position - dragStart) / uiScale.Scale
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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

local minBtn = create("TextButton", { Size = UDim2.fromOffset(62, 62), Position = UDim2.new(0, CONTENT_W - 24 - 62 - 10 - 62, 0, 32), BackgroundTransparency = 1, Text = "" }, header)
create("Frame", { Size = UDim2.new(0, 24, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = C.BarLight, BorderSizePixel = 0 }, minBtn)

local closeBtn = create("TextButton", { Size = UDim2.fromOffset(62, 62), Position = UDim2.new(0, CONTENT_W - 24 - 62, 0, 32), BackgroundTransparency = 1, Text = "" }, header)
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
	box.MouseButton1Click:Connect(function()
		state = not state
		mark.Visible = state
		TweenService:Create(box, TweenInfo.new(0.12), { BackgroundColor3 = state and Color3.fromRGB(228, 229, 235) or C.IconBox }):Play()
		if callback then callback(state) end
	end)
end

local function addToggle(sec, name, startOn, callback)
	return addCheckbox(sec, name, startOn, callback)
end

local function addSlider(sec, name, minV, maxV, startV, suffix, callback)
	featureCount = featureCount + 1
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
		local v = math.floor(minV + rel * (maxV - minV) + 0.5)
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

---------------------------------------------------------------------
-- TABS
---------------------------------------------------------------------
do -- Home
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
end

do -- ESP
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
	addToggle(b, "Orbit Ring", true, function(v) getgenv().Config.OrbitVisualEnabled = v end)
	addToggle(b, "Laser Rays", true, function(v) getgenv().Config.LaserRaysEnabled = v end)
	addToggle(b, "Target Closest Player", true, function(v)
		getgenv().Config.TargetClosest = v
		hvhTarget = nil
	end)
	addInput(b, "Target Name (optional)", "Type part of a username...", function(v)
		getgenv().Config.TargetName = v
		hvhTarget = nil
	end)
	finish(b)

	local c = section(p.right, "ESP Colors", 1, false, "◐")
	addColor(c, "Name / Text Color", Color3.fromRGB(255, 255, 255), function(v) getgenv().Config.ESPColor = v end)
	addColor(c, "Box Color", Color3.fromRGB(0, 255, 120), function(v) getgenv().Config.BoxColor = v end)
	addColor(c, "Tracer Color", Color3.fromRGB(0, 255, 120), function(v) getgenv().Config.TracerColor = v end)
	addColor(c, "Health Bar Color", Color3.fromRGB(0, 255, 0), function(v) getgenv().Config.HealthBarColor = v end)
	addColor(c, "Orbit Ring Color", Color3.fromRGB(150, 0, 255), function(v) getgenv().Config.OrbitColor = v end)
	addColor(c, "Laser Color", Color3.fromRGB(0, 150, 255), function(v) getgenv().Config.LaserColor = v end)
	addColor(c, "Target Line Color", Color3.fromRGB(255, 0, 0), function(v) getgenv().Config.TargetLineColor = v end)
	finish(c)
end

do -- Halloween (Farm)
	local p = newPage("Halloween")

	local a = section(p.left, "Auto Doors", 1, false, "✧")
	addToggle(a, "Door ESP", true, function(v) getgenv().Config.DoorESPEnabled = v end)
	addToggle(a, "Show Distance", true, function(v) getgenv().Config.DoorShowDistance = v end)
	addColor(a, "ESP Colour", Color3.fromRGB(255, 200, 0), function(v) getgenv().Config.DoorColor = v end)
	addToggle(a, "Auto Doors", false, function(v) getgenv().Config.AutoFarmDoors = v end)
	addToggle(a, "Invisible While Farming", true, function(v) getgenv().Config.InvisibleFarming = v end)
	addSlider(a, "Travel Speed", 16, 150, 40, " st/s", function(v) getgenv().Config.DoorTravelSpeed = v end)
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
end

do -- Combat & HVH
	local p = newPage("Combat & HVH")

	local c = section(p.left, "HVH Target", 1, false, "◆")
	addToggle(c, "Smooth Orbit HVH", false, function(v)
		getgenv().Config.HVHEnabled = v
		hvhTarget = nil
	end)
	addToggle(c, "Stable Camera (no shake)", true, function(v) getgenv().Config.StableCamera = v end)
	addSlider(c, "Spin Speed", 100, 10000, 5000, " deg/s", function(v) getgenv().Config.SpinSpeed = v end)
	addSlider(c, "Orbit Radius", 1, 50, 6, " st", function(v) getgenv().Config.Radius = v end)
	finish(c)

	local m = section(p.right, "Movement & Utility", 1, false, "◆")
	addToggle(m, "Speed Hack", false, function(v) getgenv().Config.SpeedHackEnabled = v end)
	addSlider(m, "Walk Speed", 16, 150, 32, "", function(v) getgenv().Config.WalkSpeedValue = v end)
	addToggle(m, "Infinite Jump", false, function(v) getgenv().Config.InfJumpEnabled = v end)
	addToggle(m, "Noclip", false, function(v) getgenv().Config.NoclipEnabled = v end)
	finish(m)
end

do -- Colors
	local p = newPage("Colors")
	local cl = section(p.left, "Theme Colors", 1, false, "◐")
	addColor(cl, "Highlight Color", Color3.fromRGB(0, 255, 120), function(v) getgenv().Config.HighlightColor = v end)
	addColor(cl, "Pumpkin Color", Color3.fromRGB(255, 100, 0), function(v) getgenv().Config.PumpkinColor = v end)
	addColor(cl, "Door Color", Color3.fromRGB(255, 200, 0), function(v) getgenv().Config.DoorColor = v end)
	addColor(cl, "Skeleton Color", Color3.fromRGB(255, 0, 0), function(v) getgenv().Config.SkeletonColor = v end)
	finish(cl)
end

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
addCategory("Visuals", { { "ESP", "◎" } })
addCategory("Farm", { { "Halloween", "✧" } })
addCategory("Combat", { { "Combat & HVH", "◆" } })
addCategory("Settings", { { "Colors", "◐" } })

selectPage("Home")

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
	local best, bestDist
	local nameQ = string.lower(cfg.TargetName or "")
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and isValidRoot(hrp) then
				if nameQ ~= "" then
					if string.find(string.lower(p.Name), nameQ, 1, true) or string.find(string.lower(p.DisplayName), nameQ, 1, true) then
						return hrp
					end
				elseif cfg.TargetClosest and HumanoidRootPart then
					local d = (HumanoidRootPart.Position - hrp.Position).Magnitude
					if not bestDist or d < bestDist then best, bestDist = hrp, d end
				end
			end
		end
	end
	return best
end

-- while HVH is on the target stays locked until it dies/leaves
local function getTargetRoot()
	if getgenv().Config.HVHEnabled then
		if not isValidRoot(hvhTarget) then
			hvhTarget = pickTarget()
		end
		return hvhTarget
	end
	hvhTarget = nil
	return pickTarget()
end

---------------------------------------------------------------------
-- TARGET VISUALS (orbit ring + laser rays + red target line)
---------------------------------------------------------------------
local ORBIT_SEGMENTS = 28
local RAY_COUNT = 14
local TargetVis = { Orbit = {}, Rays = {}, Line = nil }

local function initTargetVisuals()
	for i = 1, ORBIT_SEGMENTS do
		TargetVis.Orbit[i] = newDrawing("Line", { Thickness = 1.5, Visible = false })
	end
	for i = 1, RAY_COUNT do
		TargetVis.Rays[i] = newDrawing("Line", { Thickness = 1, Visible = false })
	end
	TargetVis.Line = newDrawing("Line", { Thickness = 1.5, Visible = false })
end

local function hideTargetVisuals()
	for _, l in ipairs(TargetVis.Orbit) do l.Visible = false end
	for _, l in ipairs(TargetVis.Rays) do l.Visible = false end
	if TargetVis.Line then TargetVis.Line.Visible = false end
end

local function renderTarget(cam, t)
	local cfg = getgenv().Config
	if not cfg.ESPEnabled then hideTargetVisuals(); return end
	local targetRoot = getTargetRoot()
	if not targetRoot then hideTargetVisuals(); return end

	local center = targetRoot.Position
	local r = cfg.Radius
	local centerScreen, centerOk = proj(cam, center)

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

			-- SpinSpeed = degrees per second (max 10000)
			orbitAngle = (orbitAngle + math.rad(cfg.SpinSpeed) * dt) % (math.pi * 2)

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

local PathfindingService = game:GetService("PathfindingService")
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

-- opens the door like a player: prompt trigger, or a held "E" key macro as fallback
local function pressPrompt(prompt)
	if fireproximityprompt then
		pcall(fireproximityprompt, prompt)
		return
	end
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(math.max(prompt.HoldDuration, 0) + 0.1)
		vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	end)
end

local function doorFarmActive()
	local cfg = getgenv().Config
	return running and cfg.AutoFarmDoors and not cfg.HVHEnabled
		and HumanoidRootPart and HumanoidRootPart.Parent and Humanoid and Humanoid.Health > 0
end

local function flat(v) return Vector3.new(v.X, 0, v.Z) end

-- real walking: pathfinding + jumps, falls back to walking straight at the point
local function walkTo(targetPos, stopDist, timeout)
	local started = os.clock()
	local function arrived() return (HumanoidRootPart.Position - targetPos).Magnitude <= stopDist end

	local waypoints
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
	local ok = pcall(function() path:ComputeAsync(HumanoidRootPart.Position, targetPos) end)
	if ok and path.Status == Enum.PathStatus.Success then waypoints = path:GetWaypoints() end

	if waypoints then
		for _, wp in ipairs(waypoints) do
			if wp.Action == Enum.PathWaypointAction.Jump then Humanoid.Jump = true end
			Humanoid:MoveTo(wp.Position)
			local t0 = os.clock()
			while doorFarmActive() do
				if arrived() then return true end
				if (flat(HumanoidRootPart.Position) - flat(wp.Position)).Magnitude < 3.5 then break end
				if os.clock() - t0 > 2.5 or os.clock() - started > timeout then break end
				task.wait(0.05)
			end
			if not doorFarmActive() or os.clock() - started > timeout then return false end
		end
		return arrived()
	end

	local lastPos, lastMove = HumanoidRootPart.Position, os.clock()
	while doorFarmActive() and os.clock() - started < timeout do
		if arrived() then return true end
		Humanoid:MoveTo(targetPos)
		task.wait(0.1)
		if (HumanoidRootPart.Position - lastPos).Magnitude > 1 then
			lastPos, lastMove = HumanoidRootPart.Position, os.clock()
		elseif os.clock() - lastMove > 0.6 then
			Humanoid.Jump = true
			lastMove = os.clock()
		end
	end
	return arrived()
end

local origWalkSpeed = nil
local function doorLoopStep()
	local cfg = getgenv().Config
	if not doorFarmActive() then
		farmDoorBusy = false
		if origWalkSpeed and Humanoid then Humanoid.WalkSpeed = origWalkSpeed end
		origWalkSpeed = nil
		task.wait(0.3)
		return
	end

	local door = pickDoor()
	if not door then
		farmDoorBusy = false
		if origWalkSpeed then Humanoid.WalkSpeed = origWalkSpeed; origWalkSpeed = nil end
		if not cfg.KillFarmEnabled then setFarmStatus("Waiting for door") end
		task.wait(0.5)
		return
	end

	farmDoorBusy = true
	if not origWalkSpeed then origWalkSpeed = Humanoid.WalkSpeed end
	Humanoid.WalkSpeed = cfg.DoorTravelSpeed
	setFarmStatus("Walking to door")

	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
	local reach = math.clamp((prompt and prompt.MaxActivationDistance or 10) - 3, 3, 12)
	local dp = doorPos(door)

	if walkTo(dp, reach, 25) and doorFarmActive() then
		setFarmStatus("Opening door")
		Humanoid:MoveTo(HumanoidRootPart.Position)
		HumanoidRootPart.CFrame = CFrame.lookAt(HumanoidRootPart.Position, Vector3.new(dp.X, HumanoidRootPart.Position.Y, dp.Z))
		local t0 = os.clock()
		while doorFarmActive() and door.Parent and isDoorReady(door) and os.clock() - t0 < cfg.OpenTimeout do
			if prompt and prompt.Parent then pressPrompt(prompt) end
			task.wait(0.4)
		end
	end
	farmState.visited[door] = os.clock()
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
-- MAIN RENDER LOOP
---------------------------------------------------------------------
local frameCount = 0

table.insert(connections, RunService.RenderStepped:Connect(function()
	frameCount = frameCount + 1
	local cfg = getgenv().Config
	local cam = workspace.CurrentCamera
	if not cam then return end

	if Character then
		if cfg.SpeedHackEnabled and Humanoid then Humanoid.WalkSpeed = cfg.WalkSpeedValue end
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

		for doorObj, objs in pairs(DoorESPObjects) do
			if doorObj and doorObj.Parent then
				if cfg.DoorESPEnabled then
					local doorPos = doorObj:IsA("Model") and doorObj:GetPivot().Position or doorObj.Position
					local pos, ok = proj(cam, doorPos)
					if ok then
						local dist = math.floor((cam.CFrame.Position - doorPos).Magnitude)
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
-- MINIMIZE / CLOSE
---------------------------------------------------------------------
local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	sideScroll.Visible = not minimized
	profileBar.Visible = not minimized
	pageHolder.Visible = not minimized
	local target = minimized and UDim2.fromOffset(DESIGN_W, HEAD_H) or UDim2.fromOffset(DESIGN_W, DESIGN_H)
	TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = target }):Play()
end)

local function cleanup()
	running = false
	if origWalkSpeed and Humanoid then Humanoid.WalkSpeed = origWalkSpeed end
	getgenv().Config.HVHEnabled = false
	getgenv().Config.AutoFarmDoors = false
	getgenv().Config.KillFarmEnabled = false
	setFarmInvisible(false)
	if Humanoid then Humanoid.AutoRotate = true end
	local cam = workspace.CurrentCamera
	if cam and Humanoid then cam.CameraSubject = Humanoid end
	for _, c in ipairs(connections) do c:Disconnect() end
	for _, objs in pairs(PlayerESP) do removeAll(objs) end
	for _, objs in pairs(DoorESPObjects) do removeAll(objs) end
	for _, objs in pairs(SkeletonESPObjects) do removeAll(objs) end
	removeAll(TargetVis)
	for _, hl in pairs(Highlights) do hl:Destroy() end
	screenGui:Destroy()
end

getgenv().TheS_Cleanup = cleanup
closeBtn.MouseButton1Click:Connect(cleanup)

print("CodeBot V1: The S GUI loaded with ESP + Orbit HVH!")
