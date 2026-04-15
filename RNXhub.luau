local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local NS, CS = 60, 30
local DAS, DAD = 150, 0.2
local State = {
speedToggled = false, autoBatToggled = false,
hittingCooldown = false, infJumpEnabled = false,
antiRagdollEnabled = false, fpsBoostEnabled = false,
guiVisible = true,
isStealing = false, stealStartTime = nil, lastStealTick = 0,
lastKnownHealth = 100,
medusaLastUsed = 0, medusaDebounce = false, medusaCounterEnabled = false,
dropActive = false,
autoLeftEnabled = false, autoRightEnabled = false,
unwalkEnabled = false,
}
local _anyKeyListening = false
local KB = {
AutoLeft  = {kb = Enum.KeyCode.Z,           gp = nil},
AutoRight = {kb = Enum.KeyCode.C,           gp = nil},
Drop      = {kb = Enum.KeyCode.X,           gp = nil},
TPDown    = {kb = Enum.KeyCode.F,           gp = nil},
AutoBat   = {kb = Enum.KeyCode.E,           gp = nil},
Speed     = {kb = Enum.KeyCode.Q,           gp = nil},
GuiHide   = {kb = Enum.KeyCode.LeftControl, gp = nil},
}
local function kbMatch(entry, kc)
return kc == entry.kb or (entry.gp and kc == entry.gp)
end
local AP_L1     = Vector3.new(-476.48, -6.28, 92.73)
local AP_L2     = Vector3.new(-483.12, -4.95, 94.80)
local AP_L_FACE = Vector3.new(-482.25, -4.96, 92.09)
local AP_R1     = Vector3.new(-476.16, -6.52, 25.62)
local AP_R2     = Vector3.new(-483.06, -5.03, 25.48)
local AP_R_FACE = Vector3.new(-482.06, -6.93, 35.47)
local Steal = {
AutoStealEnabled = false, StealRadius = 20, StealDuration = 0.25,
Data = {}, plotCache = {}, plotCacheTime = {},
cachedPrompts = {}, promptCacheTime = 0,
}
local Conns = {
autoSteal = nil, antiRag = nil,
anchor = {}, progress = nil,
}
local PLOT_CACHE_DURATION  = 2
local PROMPT_CACHE_REFRESH = 0.15
local STEAL_COOLDOWN       = 0.1
local MEDUSA_COOLDOWN      = 25
local h, hrp, speedLbl
local setAutoGrab, setAutoBat, setInfJump, setAntiRag, setFps, setMedusaCounter
local setUnwalkToggle, autoLeftSetVisual, autoRightSetVisual, autoBatSetVisual
local setupMedusaCounter, stopMedusaCounter, startAntiRagdoll, stopAntiRagdoll
local applyFPSBoost, startAutoSteal, stopAutoSteal
local saveConfig
local modeValLbl, progressFill, progressPct, progressRadLbl
local alConn, arConn = nil, nil
local alPhase, arPhase = 1, 1
local function stopAutoLeft()
if alConn then alConn:Disconnect(); alConn = nil end
alPhase = 1
local char = LP.Character
if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero, false) end end
end
local function stopAutoRight()
if arConn then arConn:Disconnect(); arConn = nil end
arPhase = 1
local char = LP.Character
if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero, false) end end
end
local function startAutoLeft()
if alConn then alConn:Disconnect() end
alPhase = 1
alConn = RunService.Heartbeat:Connect(function()
if not State.autoLeftEnabled then return end
local char = LP.Character; if not char then return end
local hrp2 = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
if not hrp2 or not hum then return end
local spd = NS
if alPhase == 1 then
local tgt = Vector3.new(AP_L1.X, hrp2.Position.Y, AP_L1.Z)
if (tgt - hrp2.Position).Magnitude < 1 then
alPhase = 2
local d = AP_L2 - hrp2.Position; local mv = Vector3.new(d.X,0,d.Z).Unit
hum:Move(mv,false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd); return
end
local d = AP_L1 - hrp2.Position; local mv = Vector3.new(d.X,0,d.Z).Unit
hum:Move(mv,false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
elseif alPhase == 2 then
local tgt = Vector3.new(AP_L2.X, hrp2.Position.Y, AP_L2.Z)
if (tgt - hrp2.Position).Magnitude < 1 then
hum:Move(Vector3.zero,false); hrp2.AssemblyLinearVelocity = Vector3.zero
State.autoLeftEnabled = false
if alConn then alConn:Disconnect(); alConn = nil end
alPhase = 1
if autoLeftSetVisual then autoLeftSetVisual(false) end
if (AP_L_FACE - hrp2.Position).Magnitude > 0.01 then
hrp2.CFrame = CFrame.new(hrp2.Position, Vector3.new(AP_L_FACE.X, hrp2.Position.Y, AP_L_FACE.Z))
end
return
end
local d = AP_L2 - hrp2.Position; local mv = Vector3.new(d.X,0,d.Z).Unit
hum:Move(mv,false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
end
end)
end
local function startAutoRight()
if arConn then arConn:Disconnect() end
arPhase = 1
arConn = RunService.Heartbeat:Connect(function()
if not State.autoRightEnabled then return end
local char = LP.Character; if not char then return end
local hrp2 = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
if not hrp2 or not hum then return end
local spd = NS
if arPhase == 1 then
local tgt = Vector3.new(AP_R1.X, hrp2.Position.Y, AP_R1.Z)
if (tgt - hrp2.Position).Magnitude < 1 then
arPhase = 2
local d = AP_R2 - hrp2.Position; local mv = Vector3.new(d.X,0,d.Z).Unit
hum:Move(mv,false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd); return
end
local d = AP_R1 - hrp2.Position; local mv = Vector3.new(d.X,0,d.Z).Unit
hum:Move(mv,false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
elseif arPhase == 2 then
local tgt = Vector3.new(AP_R2.X, hrp2.Position.Y, AP_R2.Z)
if (tgt - hrp2.Position).Magnitude < 1 then
hum:Move(Vector3.zero,false); hrp2.AssemblyLinearVelocity = Vector3.zero
State.autoRightEnabled = false
if arConn then arConn:Disconnect(); arConn = nil end
arPhase = 1
if autoRightSetVisual then autoRightSetVisual(false) end
if (AP_R_FACE - hrp2.Position).Magnitude > 0.01 then
hrp2.CFrame = CFrame.new(hrp2.Position, Vector3.new(AP_R_FACE.X, hrp2.Position.Y, AP_R_FACE.Z))
end
return
end
local d = AP_R2 - hrp2.Position; local mv = Vector3.new(d.X,0,d.Z).Unit
hum:Move(mv,false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
end
end)
end
local function runDrop()
if State.dropActive then return end
local char = LP.Character; if not char then return end
local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
if State.autoBatToggled then State.autoBatToggled = false; if autoBatSetVisual then autoBatSetVisual(false) end end
State.dropActive = true
local t0 = tick(); local conn
conn = RunService.Heartbeat:Connect(function()
local r = char and char:FindFirstChild("HumanoidRootPart")
if not r then conn:Disconnect(); State.dropActive = false; return end
if tick() - t0 >= DAD then
conn:Disconnect()
local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {char}; rp.FilterType = Enum.RaycastFilterType.Exclude
local rr = workspace:Raycast(r.Position, Vector3.new(0,-2000,0), rp)
if rr then
local hum2 = char:FindFirstChildOfClass("Humanoid")
local off = (hum2 and hum2.HipHeight or 2) + (r.Size.Y/2)
r.CFrame = CFrame.new(r.Position.X, rr.Position.Y+off, r.Position.Z)
r.AssemblyLinearVelocity = Vector3.zero
end
State.dropActive = false; return
end
end
end)
r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, DAS, r.AssemblyLinearVelocity.Z)
local function runTPDown()
pcall(function()
local char = LP.Character; if not char then return end
local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {char}; rp.FilterType = Enum.RaycastFilterType.Exclude
local rs = workspace:Raycast(root.Position, Vector3.new(0,-500,0), rp)
if rs then
root.CFrame = CFrame.new(root.Position.X, rs.Position.Y+root.Size.Y/2+0.1, root.Position.Z)
root.AssemblyLinearVelocity = Vector3.zero
end
end)
end
for _, name in pairs({"KeyraHubGUI"}) do
local old = game:GetService("CoreGui"):FindFirstChild(name)
if old then old:Destroy() end
local pg = LP:FindFirstChild("PlayerGui")
if pg then local o = pg:FindFirstChild(name); if o then o:Destroy() end end
end
local BG         = Color3.fromRGB(5, 5, 7)
local SIDEBAR_BG = Color3.fromRGB(9, 9, 13)
local CARD_BG    = Color3.fromRGB(14, 14, 18)
local CARD_HOV   = Color3.fromRGB(22, 22, 28)
local BORDER     = Color3.fromRGB(30, 30, 38)
local BORDER2    = Color3.fromRGB(55, 55, 70)
local WHITE      = Color3.fromRGB(235, 235, 235)
local DIM        = Color3.fromRGB(140, 140, 160)  -- FIXED: brighter so subtitle text is readable
local DIM2       = Color3.fromRGB(40, 40, 50)
local KB_BG      = Color3.fromRGB(10, 10, 14)
local INPUT_BG   = Color3.fromRGB(10, 10, 14)
local function makeDraggable(frame)
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
frame.InputBegan:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
dragging = true; dragStart = inp.Position; startPos = frame.Position
inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
end
end)
frame.InputChanged:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end
end)
UIS.InputChanged:Connect(function(inp)
if inp == dragInput and dragging then
local d = inp.Position - dragStart
frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
end
end)
end
local gui = Instance.new("ScreenGui")
gui.Name = "KeyraHubGUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10; gui.IgnoreGuiInset = true
if not pcall(function() gui.Parent = game:GetService("CoreGui") end) then
gui.Parent = LP:WaitForChild("PlayerGui")
end
local W, H, SW = 300, 460, 90
local CORNER = 12
local main = Instance.new("Frame", gui)
main.Name = "Main"
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0, 50, 0, 50)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, CORNER)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = BORDER2
mainStroke.Thickness = 1
makeDraggable(main)
local topbar = Instance.new("Frame", main)
topbar.Size = UDim2.new(1, 0, 0, 44)
topbar.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
topbar.BorderSizePixel = 0
topbar.ZIndex = 10
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, CORNER)
local topPatch = Instance.new("Frame", topbar)
topPatch.Size = UDim2.new(1, 0, 0, CORNER)
topPatch.Position = UDim2.new(0, 0, 1, -CORNER)
topPatch.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
topPatch.BorderSizePixel = 0
topPatch.ZIndex = 9
local topDiv = Instance.new("Frame", topbar)
topDiv.Size = UDim2.new(1, 0, 0, 1)
topDiv.Position = UDim2.new(0, 0, 1, -1)
topDiv.BackgroundColor3 = BORDER
topDiv.BorderSizePixel = 0
topDiv.ZIndex = 11
local titleLbl = Instance.new("TextLabel", topbar)
titleLbl.Size = UDim2.new(0, 160, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "KEYRA HUB"
titleLbl.TextColor3 = WHITE
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 12  -- FIXED
local verLbl = Instance.new("TextLabel", topbar)
verLbl.Size = UDim2.new(0, 130, 1, 0)
verLbl.Position = UDim2.new(0, 100, 0, 0)
verLbl.BackgroundTransparency = 1
verLbl.Text = "discord.gg/keyrahub"
verLbl.TextColor3 = DIM
verLbl.Font = Enum.Font.Gotham
verLbl.TextSize = 9
verLbl.TextXAlignment = Enum.TextXAlignment.Left
verLbl.ZIndex = 12  -- FIXED
local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -36, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.GothamBlack
minBtn.TextSize = 16
minBtn.ZIndex = 13
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", minBtn).Color = BORDER
minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(30,30,40)}):Play() end)
minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(18,18,24)}):Play() end)
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, SW, 1, -44 - CORNER)
sidebar.Position = UDim2.new(0, 0, 0, 44)
sidebar.BackgroundColor3 = SIDEBAR_BG
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 5
local sideTopPatch = Instance.new("Frame", main)
sideTopPatch.Size = UDim2.new(0, SW, 0, CORNER)
sideTopPatch.Position = UDim2.new(0, 0, 0, 44)
sideTopPatch.BackgroundColor3 = SIDEBAR_BG
sideTopPatch.BorderSizePixel = 0
sideTopPatch.ZIndex = 4
local sideDiv = Instance.new("Frame", sidebar)
sideDiv.Size = UDim2.new(0, 1, 1, 0)
sideDiv.Position = UDim2.new(1, -1, 0, 0)
sideDiv.BackgroundColor3 = BORDER
sideDiv.BorderSizePixel = 0
sideDiv.ZIndex = 6
local content = Instance.new("Frame", main)
content.Name = "ContentArea"
content.Size = UDim2.new(1, -SW-1, 1, -44 - CORNER)
content.Position = UDim2.new(0, SW+1, 0, 44)
content.BackgroundColor3 = BG
content.BackgroundTransparency = 0
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.ZIndex = 2
local mini = Instance.new("TextButton", gui)
mini.Name = "KeyraMini"
mini.Size = UDim2.new(0, 160, 0, 30)
mini.Position = UDim2.new(0, 50, 0, 50)
mini.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
mini.BorderSizePixel = 0
mini.Text = "KEYRA HUB"
mini.TextColor3 = WHITE
mini.Font = Enum.Font.GothamBold
mini.TextSize = 11
mini.TextXAlignment = Enum.TextXAlignment.Center
mini.ZIndex = 20
mini.Visible = false
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)
local miniStroke = Instance.new("UIStroke", mini)
miniStroke.Color = BORDER2
miniStroke.Thickness = 1
makeDraggable(mini)
local function showGui() main.Visible=true; mini.Visible=false; State.guiVisible=true end
local function hideGui() main.Visible=false; mini.Visible=true; State.guiVisible=false end
minBtn.MouseButton1Click:Connect(hideGui)
mini.MouseButton1Click:Connect(showGui)
mini.MouseEnter:Connect(function() TweenService:Create(mini,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(20,20,28)}):Play() end)
mini.MouseLeave:Connect(function() TweenService:Create(mini,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(9,9,13)}):Play() end)
local tabs = {}
local tabPages = {}
local activeTabName = nil
local tabDefs = {
{name="Speed"},
{name="Bat Aimbot"},
{name="Mechanics"},
{name="Movement"},
{name="Settings"},
}
local tabListFrame = Instance.new("Frame", sidebar)
tabListFrame.Size = UDim2.new(1, 0, 1, 0)
tabListFrame.Position = UDim2.new(0, 0, 0, 0)
tabListFrame.BackgroundTransparency = 1
tabListFrame.BorderSizePixel = 0
tabListFrame.ZIndex = 6
local tabLL = Instance.new("UIListLayout", tabListFrame)
tabLL.SortOrder = Enum.SortOrder.LayoutOrder
tabLL.Padding = UDim.new(0, 2)
local tabPad = Instance.new("UIPadding", tabListFrame)
tabPad.PaddingTop = UDim.new(0, 10)
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingRight = UDim.new(0, 6)
local ACTIVE_TAB_BG  = WHITE
local ACTIVE_TAB_TXT = Color3.fromRGB(5, 5, 7)
local IDLE_TAB_BG    = Color3.fromRGB(18, 18, 24)
local IDLE_TAB_TXT   = WHITE
local function switchTab(name)
activeTabName = name
for _, td in ipairs(tabDefs) do
local t = tabs[td.name]
local isA = td.name == name
TweenService:Create(t.frame, TweenInfo.new(0.14), {BackgroundColor3 = isA and ACTIVE_TAB_BG or IDLE_TAB_BG}):Play()
TweenService:Create(t.lbl,   TweenInfo.new(0.14), {TextColor3 = isA and ACTIVE_TAB_TXT or IDLE_TAB_TXT}):Play()
tabPages[td.name].Visible = isA
end
end
local pageLOs = {}
for i, td in ipairs(tabDefs) do
local btn = Instance.new("TextButton", tabListFrame)
btn.Size = UDim2.new(1, 0, 0, 34)
btn.BackgroundColor3 = IDLE_TAB_BG
btn.BorderSizePixel = 0
btn.Text = ""
btn.LayoutOrder = i
btn.ZIndex = 7
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
local lbl = Instance.new("TextLabel", btn)
lbl.Size = UDim2.new(1, 0, 1, 0)
lbl.Position = UDim2.new(0, 0, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = td.name
lbl.TextColor3 = IDLE_TAB_TXT
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 9
lbl.TextXAlignment = Enum.TextXAlignment.Center
lbl.TextWrapped = true
lbl.ZIndex = 9  -- FIXED: above btn ZIndex
tabs[td.name] = {frame=btn, lbl=lbl}
local page = Instance.new("ScrollingFrame", content)
page.Size = UDim2.new(1, 0, 1, 0)
page.BackgroundColor3 = BG
page.BackgroundTransparency = 0
page.BorderSizePixel = 0
page.ScrollBarThickness = 2
page.ScrollBarImageColor3 = BORDER2
page.AutomaticCanvasSize = Enum.AutomaticSize.Y
page.CanvasSize = UDim2.new(0, 0, 0, 0)
page.Visible = false
page.ZIndex = 3
local pll = Instance.new("UIListLayout", page)
pll.SortOrder = Enum.SortOrder.LayoutOrder
pll.Padding = UDim.new(0, 4)
local pp = Instance.new("UIPadding", page)
pp.PaddingLeft = UDim.new(0, 8)
pp.PaddingRight = UDim.new(0, 8)
pp.PaddingTop = UDim.new(0, 10)
pp.PaddingBottom = UDim.new(0, 10)
tabPages[td.name] = page
pageLOs[td.name] = 0
btn.MouseButton1Click:Connect(function() switchTab(td.name) end)
btn.MouseEnter:Connect(function()
if activeTabName ~= td.name then TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(26,26,34)}):Play() end
end)
btn.MouseLeave:Connect(function()
if activeTabName ~= td.name then TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=IDLE_TAB_BG}):Play() end
end)
end
local function lo(tabName) pageLOs[tabName] = pageLOs[tabName] + 1; return pageLOs[tabName] end
local function pg(tabName) return tabPages[tabName] end-- FIXED: Section headers with proper ZIndex
local function makeSecHeader(tabName, text)
local f = Instance.new("Frame", pg(tabName))
f.Size = UDim2.new(1, 0, 0, 18)
f.BackgroundTransparency = 1
f.BorderSizePixel = 0
f.LayoutOrder = lo(tabName)
f.ZIndex = 4
local t = Instance.new("TextLabel", f)
t.Size = UDim2.new(1, 0, 1, 0)
t.BackgroundTransparency = 1
t.Text = text:upper()
t.TextColor3 = WHITE  -- explicitly white
t.Font = Enum.Font.GothamBold
t.TextSize = 8
t.TextXAlignment = Enum.TextXAlignment.Left
t.ZIndex = 5  -- FIXED: above parent frame
local line = Instance.new("Frame", f)
line.Size = UDim2.new(1, 0, 0, 1)
line.Position = UDim2.new(0, 0, 1, -1)
line.BackgroundColor3 = BORDER
line.BorderSizePixel = 0
line.ZIndex = 4
end
local function baseCard(tabName, h2)
local c = Instance.new("Frame", pg(tabName))
c.Size = UDim2.new(1, 0, 0, h2 or 38)
c.BackgroundColor3 = CARD_BG
c.BorderSizePixel = 0
c.LayoutOrder = lo(tabName)
c.ZIndex = 4
Instance.new("UICorner", c).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", c).Color = BORDER
c.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.1), {BackgroundColor3=CARD_HOV}):Play() end)
c.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.1), {BackgroundColor3=CARD_BG}):Play() end)
return c
end-- FIXED: cLabel ZIndex 10 so labels always render above the transparent clickable overlays (ZIndex 6)
local function cLabel(p, text, x, w, sz, col, font, xa)
local l = Instance.new("TextLabel", p)
l.Size = UDim2.new(0, w or 140, 1, 0)
l.Position = UDim2.new(0, x or 10, 0, 0)
l.BackgroundTransparency = 1
l.Text = text
l.TextColor3 = col or WHITE
l.Font = font or Enum.Font.GothamBold
l.TextSize = sz or 11
l.TextXAlignment = xa or Enum.TextXAlignment.Left
l.ZIndex = 10  -- FIXED: high enough to always be visible
return l
end
local function makePillToggle(parent, defOn, onToggle)
local PW, PH = 36, 19
local pbg = Instance.new("Frame", parent)
pbg.Size = UDim2.new(0, PW, 0, PH)
pbg.Position = UDim2.new(1, -(PW+10), 0.5, -PH/2)
pbg.BackgroundColor3 = defOn and WHITE or Color3.fromRGB(18,18,24)
pbg.BorderSizePixel = 0
pbg.ZIndex = 8
Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 10)
local ps = Instance.new("UIStroke", pbg); ps.Color = defOn and WHITE or BORDER2; ps.Thickness = 1
local dot = Instance.new("Frame", pbg)
dot.Size = UDim2.new(0, 13, 0, 13)
dot.Position = defOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
dot.BackgroundColor3 = defOn and BG or DIM2
dot.BorderSizePixel = 0
dot.ZIndex = 9
Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
local isOn = defOn or false
local function setV(on)
isOn = on
TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3=on and WHITE or Color3.fromRGB(18,18,24)}):Play()
TweenService:Create(ps,  TweenInfo.new(0.18), {Color=on and WHITE or BORDER2}):Play()
TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
Position = on and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,2,0.5,-6),
BackgroundColor3 = on and BG or DIM2
topDiv.BackgroundColor3 = BORDER
topDiv.BorderSizePixel = 0
topDiv.ZIndex = 11
local titleLbl = Instance.new("TextLabel", topbar)
titleLbl.Size = UDim2.new(0, 160, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "KEYRA HUB"
titleLbl.TextColor3 = WHITE
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 12  -- FIXED
local verLbl = Instance.new("TextLabel", topbar)
verLbl.Size = UDim2.new(0, 130, 1, 0)
verLbl.Position = UDim2.new(0, 100, 0, 0)
verLbl.BackgroundTransparency = 1
verLbl.Text = "discord.gg/keyrahub"
verLbl.TextColor3 = DIM
verLbl.Font = Enum.Font.Gotham
verLbl.TextSize = 9
verLbl.TextXAlignment = Enum.TextXAlignment.Left
verLbl.ZIndex = 12  -- FIXED
local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -36, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.GothamBlack
minBtn.TextSize = 16
minBtn.ZIndex = 13
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", minBtn).Color = BORDER
minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(30,30,40)}):Play() end)
minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(18,18,24)}):Play() end)
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, SW, 1, -44 - CORNER)
sidebar.Position = UDim2.new(0, 0, 0, 44)
sidebar.BackgroundColor3 = SIDEBAR_BG
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 5
local sideTopPatch = Instance.new("Frame", main)
sideTopPatch.Size = UDim2.new(0, SW, 0, CORNER)
sideTopPatch.Position = UDim2.new(0, 0, 0, 44)
sideTopPatch.BackgroundColor3 = SIDEBAR_BG
sideTopPatch.BorderSizePixel = 0
sideTopPatch.ZIndex = 4
local sideDiv = Instance.new("Frame", sidebar)
sideDiv.Size = UDim2.new(0, 1, 1, 0)
sideDiv.Position = UDim2.new(1, -1, 0, 0)
sideDiv.BackgroundColor3 = BORDER
sideDiv.BorderSizePixel = 0
sideDiv.ZIndex = 6
local content = Instance.new("Frame", main)
content.Name = "ContentArea"
content.Size = UDim2.new(1, -SW-1, 1, -44 - CORNER)
content.Position = UDim2.new(0, SW+1, 0, 44)
content.BackgroundColor3 = BG
content.BackgroundTransparency = 0
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.ZIndex = 2
local mini = Instance.new("TextButton", gui)
mini.Name = "KeyraMini"
mini.Size = UDim2.new(0, 160, 0, 30)
mini.Position = UDim2.new(0, 50, 0, 50)
mini.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
mini.BorderSizePixel = 0
mini.Text = "KEYRA HUB"
mini.TextColor3 = WHITE
mini.Font = Enum.Font.GothamBold
mini.TextSize = 11
mini.TextXAlignment = Enum.TextXAlignment.Center
mini.ZIndex = 20
mini.Visible = false
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)
local miniStroke = Instance.new("UIStroke", mini)
miniStroke.Color = BORDER2
miniStroke.Thickness = 1
makeDraggable(mini)
local function showGui() main.Visible=true; mini.Visible=false; State.guiVisible=true end
local function hideGui() main.Visible=false; mini.Visible=true; State.guiVisible=false end
minBtn.MouseButton1Click:Connect(hideGui)
mini.MouseButton1Click:Connect(showGui)
mini.MouseEnter:Connect(function() TweenService:Create(mini,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(20,20,28)}):Play() end)
mini.MouseLeave:Connect(function() TweenService:Create(mini,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(9,9,13)}):Play() end)
local tabs = {}
local tabPages = {}
local activeTabName = nil
local tabDefs = {
{name="Speed"},
{name="Bat Aimbot"},
{name="Mechanics"},
{name="Movement"},
{name="Settings"},
}
local tabListFrame = Instance.new("Frame", sidebar)
tabListFrame.Size = UDim2.new(1, 0, 1, 0)
tabListFrame.Position = UDim2.new(0, 0, 0, 0)
tabListFrame.BackgroundTransparency = 1
tabListFrame.BorderSizePixel = 0
tabListFrame.ZIndex = 6
local tabLL = Instance.new("UIListLayout", tabListFrame)
tabLL.SortOrder = Enum.SortOrder.LayoutOrder
tabLL.Padding = UDim.new(0, 2)
local tabPad = Instance.new("UIPadding", tabListFrame)
tabPad.PaddingTop = UDim.new(0, 10)
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingRight = UDim.new(0, 6)
local ACTIVE_TAB_BG  = WHITE
local ACTIVE_TAB_TXT = Color3.fromRGB(5, 5, 7)
local IDLE_TAB_BG    = Color3.fromRGB(18, 18, 24)
local IDLE_TAB_TXT   = WHITE
local function switchTab(name)
activeTabName = name
for _, td in ipairs(tabDefs) do
local t = tabs[td.name]
local isA = td.name == name
TweenService:Create(t.frame, TweenInfo.new(0.14), {BackgroundColor3 = isA and ACTIVE_TAB_BG or IDLE_TAB_BG}):Play()
TweenService:Create(t.lbl,   TweenInfo.new(0.14), {TextColor3 = isA and ACTIVE_TAB_TXT or IDLE_TAB_TXT}):Play()
tabPages[td.name].Visible = isA
end
end
local pageLOs = {}
for i, td in ipairs(tabDefs) do
local btn = Instance.new("TextButton", tabListFrame)
btn.Size = UDim2.new(1, 0, 0, 34)
btn.BackgroundColor3 = IDLE_TAB_BG
btn.BorderSizePixel = 0
btn.Text = ""
btn.LayoutOrder = i
btn.ZIndex = 7
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
local lbl = Instance.new("TextLabel", btn)
lbl.Size = UDim2.new(1, 0, 1, 0)
lbl.Position = UDim2.new(0, 0, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = td.name
lbl.TextColor3 = IDLE_TAB_TXT
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 9
lbl.TextXAlignment = Enum.TextXAlignment.Center
lbl.TextWrapped = true
lbl.ZIndex = 9  -- FIXED: above btn ZIndex
tabs[td.name] = {frame=btn, lbl=lbl}
local page = Instance.new("ScrollingFrame", content)
page.Size = UDim2.new(1, 0, 1, 0)
page.BackgroundColor3 = BG
page.BackgroundTransparency = 0
page.BorderSizePixel = 0
page.ScrollBarThickness = 2
page.ScrollBarImageColor3 = BORDER2
page.AutomaticCanvasSize = Enum.AutomaticSize.Y
page.CanvasSize = UDim2.new(0, 0, 0, 0)
page.Visible = false
page.ZIndex = 3
local pll = Instance.new("UIListLayout", page)
pll.SortOrder = Enum.SortOrder.LayoutOrder
pll.Padding = UDim.new(0, 4)
local pp = Instance.new("UIPadding", page)
pp.PaddingLeft = UDim.new(0, 8)
pp.PaddingRight = UDim.new(0, 8)
pp.PaddingTop = UDim.new(0, 10)
pp.PaddingBottom = UDim.new(0, 10)
tabPages[td.name] = page
pageLOs[td.name] = 0
btn.MouseButton1Click:Connect(function() switchTab(td.name) end)
btn.MouseEnter:Connect(function()
if activeTabName ~= td.name then TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(26,26,34)}):Play() end
end)
btn.MouseLeave:Connect(function()
if activeTabName ~= td.name then TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=IDLE_TAB_BG}):Play() end
end)
end
local function lo(tabName) pageLOs[tabName] = pageLOs[tabName] + 1; return pageLOs[tabName] end
local function pg(tabName) return tabPages[tabName] end-- FIXED: Section headers with proper ZIndex
local function makeSecHeader(tabName, text)
local f = Instance.new("Frame", pg(tabName))
f.Size = UDim2.new(1, 0, 0, 18)
f.BackgroundTransparency = 1
f.BorderSizePixel = 0
f.LayoutOrder = lo(tabName)
f.ZIndex = 4
local t = Instance.new("TextLabel", f)
t.Size = UDim2.new(1, 0, 1, 0)
t.BackgroundTransparency = 1
t.Text = text:upper()
t.TextColor3 = WHITE  -- explicitly white
t.Font = Enum.Font.GothamBold
t.TextSize = 8
t.TextXAlignment = Enum.TextXAlignment.Left
t.ZIndex = 5  -- FIXED: above parent frame
local line = Instance.new("Frame", f)
line.Size = UDim2.new(1, 0, 0, 1)
line.Position = UDim2.new(0, 0, 1, -1)
line.BackgroundColor3 = BORDER
line.BorderSizePixel = 0
line.ZIndex = 4
end
local function baseCard(tabName, h2)
local c = Instance.new("Frame", pg(tabName))
c.Size = UDim2.new(1, 0, 0, h2 or 38)
c.BackgroundColor3 = CARD_BG
c.BorderSizePixel = 0
c.LayoutOrder = lo(tabName)
c.ZIndex = 4
Instance.new("UICorner", c).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", c).Color = BORDER
c.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.1), {BackgroundColor3=CARD_HOV}):Play() end)
c.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.1), {BackgroundColor3=CARD_BG}):Play() end)
return c
end-- FIXED: cLabel ZIndex 10 so labels always render above the transparent clickable overlays (ZIndex 6)
local function cLabel(p, text, x, w, sz, col, font, xa)
local l = Instance.new("TextLabel", p)
l.Size = UDim2.new(0, w or 140, 1, 0)
l.Position = UDim2.new(0, x or 10, 0, 0)
l.BackgroundTransparency = 1
l.Text = text
l.TextColor3 = col or WHITE
l.Font = font or Enum.Font.GothamBold
l.TextSize = sz or 11
l.TextXAlignment = xa or Enum.TextXAlignment.Left
l.ZIndex = 10  -- FIXED: high enough to always be visible
return l
end
local function makePillToggle(parent, defOn, onToggle)
local PW, PH = 36, 19
local pbg = Instance.new("Frame", parent)
pbg.Size = UDim2.new(0, PW, 0, PH)
pbg.Position = UDim2.new(1, -(PW+10), 0.5, -PH/2)
pbg.BackgroundColor3 = defOn and WHITE or Color3.fromRGB(18,18,24)
pbg.BorderSizePixel = 0
pbg.ZIndex = 8
Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 10)
local ps = Instance.new("UIStroke", pbg); ps.Color = defOn and WHITE or BORDER2; ps.Thickness = 1
local dot = Instance.new("Frame", pbg)
dot.Size = UDim2.new(0, 13, 0, 13)
dot.Position = defOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
dot.BackgroundColor3 = defOn and BG or DIM2
dot.BorderSizePixel = 0
dot.ZIndex = 9
Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
local isOn = defOn or false
local function setV(on)
isOn = on
TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3=on and WHITE or Color3.fromRGB(18,18,24)}):Play()
TweenService:Create(ps,  TweenInfo.new(0.18), {Color=on and WHITE or BORDER2}):Play()
TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
Position = on and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,2,0.5,-6),
BackgroundColor3 = on and BG or DIM2
}):Play()-- FIXED: clk ZIndex 6 — below labels (10) so text stays readable, but still clickable
local clk = Instance.new("TextButton", parent)
clk.Size = UDim2.new(1, 0, 1, 0)
clk.BackgroundTransparency = 1
clk.Text = ""
clk.ZIndex = 6
clk.MouseButton1Click:Connect(function()
if _anyKeyListening then return end
isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end
end)
return setV
end
local function makeKB(parent, kbEntry, onChange)
local b = Instance.new("TextButton", parent)
b.Size = UDim2.new(0, 44, 0, 20)
b.BackgroundColor3 = KB_BG
b.BorderSizePixel = 0
b.Text = (kbEntry.kb or Enum.KeyCode.Unknown).Name
b.TextColor3 = WHITE
b.Font = Enum.Font.GothamBold
b.TextSize = 8
b.ZIndex = 11  -- FIXED: above labels so it's clickable
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
local bs = Instance.new("UIStroke", b); bs.Color = BORDER2; bs.Thickness = 1
local li = false; local lc; local pv = b.Text
b.MouseButton1Click:Connect(function()
if li then li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end; b.Text=pv; b.TextColor3=WHITE; return end
pv=b.Text; li=true; _anyKeyListening=true; b.Text="···"; b.TextColor3=DIM
TweenService:Create(bs, TweenInfo.new(0.1), {Color=WHITE}):Play()
lc = UIS.InputBegan:Connect(function(inp)
if not li then return end
if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
if inp.KeyCode == Enum.KeyCode.Escape then
li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end
b.Text=pv; b.TextColor3=WHITE; TweenService:Create(bs,TweenInfo.new(0.1),{Color=BORDER2}):Play(); return
end
b.Text=inp.KeyCode.Name; pv=inp.KeyCode.Name; b.TextColor3=WHITE
li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end
TweenService:Create(bs, TweenInfo.new(0.1), {Color=BORDER2}):Play()
if onChange then onChange(inp.KeyCode) end
end)
end)
return b
end
local function rowToggle(tabName, label, sub, defOn, onToggle)
local c = baseCard(tabName, sub and 48 or 38)
cLabel(c, label, 10, 160, 11, WHITE, Enum.Font.GothamBold)
if sub then
local sl = cLabel(c, sub, 10, 170, 9, DIM, Enum.Font.Gotham)
sl.Size = UDim2.new(0, 170, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
end
return makePillToggle(c, defOn, onToggle)
end
local function rowToggleKB(tabName, label, sub, kbEntry, defOn, onToggle, onKeyChange)
local c = baseCard(tabName, sub and 48 or 38)
cLabel(c, label, 10, 120, 11, WHITE, Enum.Font.GothamBold)
if sub then
local sl = cLabel(c, sub, 10, 150, 9, DIM, Enum.Font.Gotham)
sl.Size = UDim2.new(0, 150, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
end
local kb = makeKB(c, kbEntry, function(k) kbEntry.kb=k; kbEntry.gp=nil; if onKeyChange then onKeyChange(k) end end)
kb.Position = UDim2.new(1, -(44+10+36+8), 0.5, -10)
kb.ZIndex = 11
local PW, PH = 36, 19
local pbg = Instance.new("Frame", c)
pbg.Size = UDim2.new(0, PW, 0, PH)
pbg.Position = UDim2.new(1, -(PW+10), 0.5, -PH/2)
pbg.BackgroundColor3 = defOn and WHITE or Color3.fromRGB(18,18,24)
pbg.BorderSizePixel = 0
pbg.ZIndex = 8
Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 10)
local ps = Instance.new("UIStroke", pbg); ps.Color = defOn and WHITE or BORDER2; ps.Thickness = 1
local dot = Instance.new("Frame", pbg)
dot.Size = UDim2.new(0, 13, 0, 13)
dot.Position = defOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
dot.BackgroundColor3 = defOn and BG or DIM2
dot.BorderSizePixel = 0
dot.ZIndex = 9
Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
local isOn = defOn or false
local function setV(on)
isOn = on
TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3=on and WHITE or Color3.fromRGB(18,18,24)}):Play()
TweenService:Create(ps,  TweenInfo.new(0.18), {Color=on and WHITE or BORDER2}):Play()
TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
Position = on and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,2,0.5,-6),
BackgroundColor3 = on and BG or DIM2
}):Play()
end-- FIXED: clk ZIndex 6, below labels (10) and KB button (11)
local clk = Instance.new("TextButton", c)
clk.Size = UDim2.new(1, 0, 1, 0)
clk.BackgroundTransparency = 1
clk.Text = ""
clk.ZIndex = 6
clk.MouseButton1Click:Connect(function()
if _anyKeyListening then return end
isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end
end)
return setV, kb
end
local function rowKBOnly(tabName, label, sub, kbEntry, onKeyChange)
local c = baseCard(tabName, sub and 48 or 38)
cLabel(c, label, 10, 160, 11, WHITE, Enum.Font.GothamBold)
if sub then
local sl = cLabel(c, sub, 10, 170, 9, DIM, Enum.Font.Gotham)
sl.Size = UDim2.new(0, 170, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
end
local kb = makeKB(c, kbEntry, function(k) kbEntry.kb=k; kbEntry.gp=nil; if onKeyChange then onKeyChange(k) end end)
kb.Position = UDim2.new(1, -(44+10), 0.5, -10)
kb.ZIndex = 11
return kb
end
local function rowInput(tabName, label, sub, default, onChange)
local c = baseCard(tabName, sub and 48 or 38)
cLabel(c, label, 10, 130, 11, WHITE, Enum.Font.GothamBold)
if sub then
local sl = cLabel(c, sub, 10, 160, 9, DIM, Enum.Font.Gotham)
sl.Size = UDim2.new(0, 160, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
end
local box = Instance.new("TextBox", c)
box.Size = UDim2.new(0, 64, 0, 24)
box.Position = UDim2.new(1, -74, 0.5, -12)
box.BackgroundColor3 = INPUT_BG
box.BorderSizePixel = 0
box.Text = tostring(default)
box.TextColor3 = WHITE
box.Font = Enum.Font.GothamBold
box.TextSize = 11
box.ClearTextOnFocus = false
box.ZIndex = 11
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
local bs = Instance.new("UIStroke", box); bs.Color = BORDER2; bs.Thickness = 1; bs.ZIndex = 12
box.Focused:Connect(function() TweenService:Create(bs, TweenInfo.new(0.1), {Color=WHITE}):Play() end)
box.FocusLost:Connect(function()
TweenService:Create(bs, TweenInfo.new(0.1), {Color=BORDER2}):Play()
if onChange then local n = tonumber(box.Text); if n then onChange(n) else box.Text = tostring(default) end end
end)
return box
end
local function rowActionBtn(tabName, label, onClick)
local b = Instance.new("TextButton", pg(tabName))
b.Size = UDim2.new(1, 0, 0, 36)
b.BackgroundColor3 = WHITE
b.BorderSizePixel = 0
b.Text = label
b.TextColor3 = BG
b.Font = Enum.Font.GothamBold
b.TextSize = 11
b.LayoutOrder = lo(tabName)
b.ZIndex = 5
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
b.MouseButton1Click:Connect(function()
TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3=Color3.fromRGB(200,200,200)}):Play()
task.delay(0.15, function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=WHITE}):Play() end)
if onClick then pcall(onClick) end
end)
b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(210,210,210)}):Play() end)
b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=WHITE}):Play() end)
return b
end
local pbFrame = Instance.new("Frame", gui)
pbFrame.Size = UDim2.new(0, 280, 0, 46)
pbFrame.Position = UDim2.new(0.5, -140, 1, -66)
pbFrame.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
pbFrame.BorderSizePixel = 0
pbFrame.Active = true
Instance.new("UICorner", pbFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", pbFrame).Color = BORDER2
makeDraggable(pbFrame)
progressPct = Instance.new("TextLabel", pbFrame)
progressPct.Size = UDim2.new(0, 40, 0, 16)
progressPct.Position = UDim2.new(0, 10, 0, 6)
progressPct.BackgroundTransparency = 1
progressPct.Text = "0%"
progressPct.TextColor3 = WHITE
progressPct.Font = Enum.Font.GothamBold
progressPct.TextSize = 11
progressPct.TextXAlignment = Enum.TextXAlignment.Left
progressPct.ZIndex = 5
progressRadLbl = Instance.new("TextLabel", pbFrame)
progressRadLbl.Size = UDim2.new(0, 110, 0, 16)
progressRadLbl.Position = UDim2.new(1, -120, 0, 6)
progressRadLbl.BackgroundTransparency = 1
progressRadLbl.Text = "Radius: "..Steal.StealRadius
progressRadLbl.TextColor3 = WHITE
progressRadLbl.Font = Enum.Font.GothamBold
progressRadLbl.TextSize = 11
progressRadLbl.TextXAlignment = Enum.TextXAlignment.Right
progressRadLbl.ZIndex = 5
local pbBg = Instance.new("Frame", pbFrame)
pbBg.Size = UDim2.new(1, -20, 0, 10)
pbBg.Position = UDim2.new(0, 10, 0, 28)
pbBg.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
pbBg.BorderSizePixel = 0
Instance.new("UICorner", pbBg).CornerRadius = UDim.new(0, 5)
progressFill = Instance.new("Frame", pbBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = WHITE
progressFill.BorderSizePixel = 0
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 5)
local function resetProgressBar() progressPct.Text = "0%"; progressFill.Size = UDim2.new(0,0,1,0) end
makeSecHeader("Speed", "Speed Configuration")
local normalBox = rowInput("Speed", "Normal Speed", "Walking / running speed", NS, function(v) if v>0 and v<=500 then NS=v end end)
local carryBox  = rowInput("Speed", "Carry Speed",  "Speed while holding an item", CS, function(v) if v>0 and v<=500 then CS=v end end)
do
local c = baseCard("Speed", 38)
cLabel(c, "Mode", 10, 80, 11, WHITE, Enum.Font.GothamBold)
modeValLbl = cLabel(c, "Normal", 88, 80, 10, DIM, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
local kb = makeKB(c, KB.Speed, function(k) KB.Speed.kb = k end)
kb.Position = UDim2.new(1, -(44+10), 0.5, -10)
kb.ZIndex = 11
local clk = Instance.new("TextButton", c)
clk.Size = UDim2.new(0.65, 0, 1, 0)
clk.BackgroundTransparency = 1
clk.Text = ""
clk.ZIndex = 6  -- FIXED: below labels
clk.MouseButton1Click:Connect(function()
if _anyKeyListening then return end
                          State.speedToggled = not State.speedToggled
modeValLbl.Text = State.speedToggled and "Carry" or "Normal"
end
makeSecHeader("Bat Aimbot", "Bat Combat")
do
local sv
sv, _ = rowToggleKB("Bat Aimbot", "Auto Bat", "Lock on & rush nearest player", KB.AutoBat, false,
function(on)
State.autoBatToggled = on
if on then
if State.autoLeftEnabled then State.autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
if State.autoRightEnabled then State.autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
local char = LP.Character
if char then
local hum = char:FindFirstChildOfClass("Humanoid")
local bp = LP:FindFirstChild("Backpack")
local bat = (bp and bp:FindFirstChild("Bat")) or char:FindFirstChild("Bat")
if bat and hum then hum:EquipTool(bat) end
end
end
autoBatSetVisual = sv
end,
function(k) KB.AutoBat.kb = k end)
autoBatSetVisual = sv
end
makeSecHeader("Mechanics", "Game Mechanics")
setAutoGrab = rowToggle("Mechanics", "Auto Grab", "Automatically steal nearby animals", false, function(on)
Steal.AutoStealEnabled = on
if on then if not pcall(startAutoSteal) then Steal.AutoStealEnabled = false; setAutoGrab(false) end
else stopAutoSteal() end
end)
do
local c = baseCard("Mechanics", 38)
cLabel(c, "Grab Radius", 10, 120, 11, WHITE, Enum.Font.GothamBold)
local radValBtn = Instance.new("TextButton", c)
radValBtn.Size = UDim2.new(0, 64, 0, 24)
radValBtn.Position = UDim2.new(1, -74, 0.5, -12)
radValBtn.BackgroundColor3 = INPUT_BG
radValBtn.BorderSizePixel = 0
radValBtn.Text = tostring(Steal.StealRadius)
radValBtn.TextColor3 = WHITE
radValBtn.Font = Enum.Font.GothamBold
radValBtn.TextSize = 11
radValBtn.ZIndex = 11
Instance.new("UICorner", radValBtn).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", radValBtn).Color = BORDER2
local typing2 = false
radValBtn.MouseButton1Click:Connect(function()
if typing2 then return end; typing2 = true
local tb = Instance.new("TextBox", c)
tb.Size = radValBtn.Size; tb.Position = radValBtn.Position
tb.BackgroundColor3 = CARD_HOV; tb.BorderSizePixel = 0
tb.Text = tostring(Steal.StealRadius)
tb.TextColor3 = WHITE; tb.Font = Enum.Font.GothamBold; tb.TextSize = 11
tb.ClearTextOnFocus = false; tb.ZIndex = 12
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", tb).Color = WHITE
tb:CaptureFocus()
tb.FocusLost:Connect(function()
local num = tonumber(tb.Text)
if num and num>=5 and num<=300 then
Steal.StealRadius = math.floor(num)
radValBtn.Text = tostring(Steal.StealRadius)
progressRadLbl.Text = "Radius: "..Steal.StealRadius
Steal.cachedPrompts = {}; Steal.promptCacheTime = 0
end
tb:Destroy(); typing2 = false
end)
end)
end
setInfJump       = rowToggle("Mechanics", "Infinite Jump",  "Jump from anywhere", false, function(on) State.infJumpEnabled = on end)
setAntiRag       = rowToggle("Mechanics", "Anti Ragdoll",   "Prevent ragdoll physics", false, function(on) State.antiRagdollEnabled=on; if on then startAntiRagdoll() else stopAntiRagdoll() end end)
setFps           = rowToggle("Mechanics", "FPS Boost",      "Reduce visuals for performance", false, function(on) State.fpsBoostEnabled=on; if on then pcall(applyFPSBoost) end end)
setMedusaCounter = rowToggle("Mechanics", "Medusa Counter", "Auto-counter medusa stone", false, function(on) State.medusaCounterEnabled=on; if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end)
setUnwalkToggle  = rowToggle("Mechanics", "Unwalk",         "Disable walk animations", false, function(on) State.unwalkEnabled=on end)
makeSecHeader("Movement", "Movement & Teleport")
do
local sv
sv, _ = rowToggleKB("Movement", "Auto Left", "Navigate to left podium", KB.AutoLeft, false,
function(on)
State.autoLeftEnabled = on
if on then
if State.autoRightEnabled then State.autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
if State.autoBatToggled then State.autoBatToggled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
startAutoLeft()
else stopAutoLeft() end
end, function(k) KB.AutoLeft.kb=k end)
autoLeftSetVisual = sv
end
do
local sv
sv, _ = rowToggleKB("Movement", "Auto Right", "Navigate to right podium", KB.AutoRight, false,
function(on)
State.autoRightEnabled = on
if on then
if State.autoLeftEnabled then State.autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
if State.autoBatToggled then State.autoBatToggled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
startAutoRight()
else stopAutoRight() end
end, function(k) KB.AutoRight.kb=k end)
autoRightSetVisual = sv
end
rowKBOnly("Movement", "Drop",    "Launch up then drop to ground", KB.Drop,   function(k) KB.Drop.kb=k end)
rowKBOnly("Movement", "TP Down", "Teleport to floor below",       KB.TPDown, function(k) KB.TPDown.kb=k end)
makeSecHeader("Settings", "Interface & Binds")
rowKBOnly("Settings", "Hide / Show GUI", "Toggle GUI visibility", KB.GuiHide, function(k) KB.GuiHide.kb=k end)
local saveBtn = rowActionBtn("Settings", "Save Config", function() saveConfig() end)
local function findMedusa()
local char = LP.Character; if not char then return nil end
for _, tool in ipairs(char:GetChildren()) do
if tool:IsA("Tool") then local tn = tool.Name:lower()
if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end
end
local bp2 = LP:FindFirstChild("Backpack")
if bp2 then for _, tool in ipairs(bp2:GetChildren()) do
if tool:IsA("Tool") then local tn = tool.Name:lower()
if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end
end end
return nil
end
local function useMedusaCounter()
if State.medusaDebounce then return end
if tick()-State.medusaLastUsed < MEDUSA_COOLDOWN then return end
local char = LP.Character; if not char then return end
State.medusaDebounce = true
local med = findMedusa(); if not med then State.medusaDebounce = false; return end
if med.Parent ~= char then local hum2 = char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
pcall(function() med:Activate() end)
State.medusaLastUsed = tick(); State.medusaDebounce = false
end
local function onAnchorChanged(part)
return part:GetPropertyChangedSignal("Anchored"):Connect(function()
if part.Anchored and part.Transparency == 1 then useMedusaCounter() 
                                end)
                            end
setupMedusaCounter = function(char)
stopMedusaCounter(); if not char then return end
for _, part in ipairs(char:GetDescendants()) do
if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
end
table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part)
if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
end))
end
stopMedusaCounter = function()
for _, c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end; Conns.anchor = {}
end
startAntiRagdoll = function()
if Conns.antiRag then return end
Conns.antiRag = RunService.Heartbeat:Connect(function()
local char = LP.Character; if not char then return end
local hum2 = char:FindFirstChildOfClass("Humanoid")
local root = char:FindFirstChild("HumanoidRootPart")
if hum2 then
local st = hum2:GetState()
if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
hum2:ChangeState(Enum.HumanoidStateType.Running)
workspace.CurrentCamera.CameraSubject = hum2
pcall(function() local pm = LP.PlayerScripts:FindFirstChild("PlayerModule"); if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
if root then root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero end
end
end
for _, obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end end
end)
end
stopAntiRagdoll = function()
if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag = nil end
end
applyFPSBoost = function()
pcall(function() setfpscap(999999999) end)
local function processObj(v)
pcall(function()
if v:IsA("Model") then v.LevelOfDetail=Enum.ModelLevelOfDetail.Disabled; v.ModelStreamingMode=Enum.ModelStreamingMode.Nonatomic
elseif v:IsA("MeshPart") then v.CastShadow=false; v.DoubleSided=false; v.RenderFidelity=Enum.RenderFidelity.Performance
elseif v:IsA("BasePart") then v.CastShadow=false; v.Material=Enum.Material.Plastic; v.Reflectance=0
elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
elseif v:IsA("SpecialMesh") then v.TextureId=""
elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false
elseif v:IsA("Explosion") then v.BlastPressure=1; v.BlastRadius=1
elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then v:Destroy()
elseif v:IsA("Attachment") then v.Visible=false end
end)
end
for _, v in pairs(workspace:GetDescendants()) do processObj(v) end
pcall(function()
local lighting = game:GetService("Lighting")
for _, v in pairs(lighting:GetDescendants()) do
pcall(function()
if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end
end)
end
pcall(function() sethiddenproperty(lighting, "Technology", Enum.Technology.Legacy) end)
lighting.GlobalShadows=false; lighting.FogEnd=9e9; lighting.Brightness=0
local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
terrain.WaterReflectance=0; terrain.WaterTransparency=0.7; terrain.WaterWaveSize=0; terrain.WaterWaveSpeed=0
end
end)
workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(processObj, v) end end)
end
local function isMyPlotByName(plotName)
local ct = tick()
if Steal.plotCache[plotName] and (ct-(Steal.plotCacheTime[plotName] or 0)) < PLOT_CACHE_DURATION then return Steal.plotCache[plotName] end
local plots = workspace:FindFirstChild("Plots")
if not plots then Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false end
local plot = plots:FindFirstChild(plotName)
if not plot then Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false end
local sign = plot:FindFirstChild("PlotSign")
if sign then
local yb = sign:FindFirstChild("YourBase")
if yb and yb:IsA("BillboardGui") then
local r = yb.Enabled==true; Steal.plotCache[plotName]=r; Steal.plotCacheTime[plotName]=ct; return r
end
end
Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false
end
local function findNearestPrompt()
local char = LP.Character; if not char then return nil end
local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
local ct = tick()
if ct-Steal.promptCacheTime < PROMPT_CACHE_REFRESH and #Steal.cachedPrompts > 0 then
local np, nd = nil, math.huge
for _, data in ipairs(Steal.cachedPrompts) do
if data.spawn then local dist=(data.spawn.Position-root.Position).Magnitude
if dist<=Steal.StealRadius and dist<nd then np=data.prompt; nd=dist end end
end
if np then return np end
end
Steal.cachedPrompts = {}; Steal.promptCacheTime = ct
local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
local np, nd = nil, math.huge
for _, plot in ipairs(plots:GetChildren()) do
if isMyPlotByName(plot.Name) then continue end
local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
for _, pod in ipairs(pods:GetChildren()) do
pcall(function()
local base = pod:FindFirstChild("Base"); local sp = base and base:FindFirstChild("Spawn")
if sp then
local att = sp:FindFirstChild("PromptAttachment")
if att then
for _, child in ipairs(att:GetChildren()) do
if child:IsA("ProximityPrompt") then
local dist = (sp.Position-root.Position).Magnitude
table.insert(Steal.cachedPrompts, {prompt=child, spawn=sp, name=pod.Name})
if dist<=Steal.StealRadius and dist<nd then np=child; nd=dist end; break
end
end
end
end
end)
end
end
return np
end
local function executeSteal(prompt)
local ct = tick()
if ct-State.lastStealTick < STEAL_COOLDOWN then return end
if State.isStealing then return end
if not Steal.Data[prompt] then
Steal.Data[prompt] = {hold={}, trigger={}, ready=true}
pcall(function()
if getconnections then
for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold, c.Function) end end
for _, c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger, c.Function) end end
else Steal.Data[prompt].useFallback = true end
end
end)
local data = Steal.Data[prompt]; if not data.ready then return end
data.ready=false; State.isStealing=true; State.stealStartTime=ct; State.lastStealTick=ct
if Conns.progress then Conns.progress:Disconnect() end
Conns.progress = RunService.Heartbeat:Connect(function()
if not State.isStealing then Conns.progress:Disconnect(); return end
local prog = math.clamp((tick()-State.stealStartTime)/Steal.StealDuration, 0, 1)
if progressFill then progressFill.Size = UDim2.new(prog,0,1,0) end
if progressPct then progressPct.Text = math.floor(prog*100).."%" end
end)
task.spawn(function()
local ok = false
pcall(function()
if not data.useFallback then
for _, fn in ipairs(data.hold) do task.spawn(fn) end
task.wait(Steal.StealDuration)
for _, fn in ipairs(data.trigger) do task.spawn(fn) end
ok = true
end
end)
if not ok and fireproximityprompt then pcall(function() fireproximityprompt(prompt); ok=true end) end
if not ok then pcall(function() prompt:InputHoldBegin(); task.wait(Steal.StealDuration); prompt:InputHoldEnd() end) end
task.wait(Steal.StealDuration*0.3)
if Conns.progress then Conns.progress:Disconnect() end
resetProgressBar(); task.wait(0.05); data.ready=true; State.isStealing=false
end)
end
startAutoSteal = function()
if Conns.autoSteal then return end
Conns.autoSteal = RunService.Heartbeat:Connect(function()
if not Steal.AutoStealEnabled or State.isStealing then return end
local p = findNearestPrompt(); if p then executeSteal(p) end
end)
end
stopAutoSteal = function()
if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal = nil end
State.isStealing=false; State.lastStealTick=0
Steal.plotCache={}; Steal.plotCacheTime={}; Steal.cachedPrompts={}; resetProgressBar()
end
local function getClosestPlayer()
if not hrp then return nil, math.huge end
local cp, cd = nil, math.huge
for _, p in pairs(Players:GetPlayers()) do
if p ~= LP and p.Character then
local tr = p.Character:FindFirstChild("HumanoidRootPart")
if tr then local d = (hrp.Position-tr.Position).Magnitude; if d<cd then cd=d; cp=p end end
end
end
return cp, cd
end
RunService.Heartbeat:Connect(function()
if not (State.autoBatToggled and h and hrp) then return end
local target, dist = getClosestPlayer()
if target and target.Character then
local tr = target.Character:FindFirstChild("HumanoidRootPart")
if tr then
local fp = tr.Position + tr.CFrame.LookVector * 1.5
local dir = (fp - hrp.Position).Unit
hrp.Velocity = Vector3.new(dir.X*56.5, dir.Y*56.5, dir.Z*56.5)
end
end
end)
saveConfig = function()
local function ks(e) return {kb=e.kb and e.kb.Name or nil, gp=e.gp and e.gp.Name or nil} end
local cfg = {
normalSpeed=NS, carrySpeed=CS,
autoLeftKey=ks(KB.AutoLeft), autoRightKey=ks(KB.AutoRight),
dropKey=ks(KB.Drop), tpDownKey=ks(KB.TPDown),
autoBatKey=ks(KB.AutoBat), speedKey=ks(KB.Speed), guiHideKey=ks(KB.GuiHide),
grabRadius=Steal.StealRadius,
infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled,
fpsBoost=State.fpsBoostEnabled, medusaCounter=State.medusaCounterEnabled,
autoStealEnabled=Steal.AutoStealEnabled, unwalkEnabled=State.unwalkEnabled,
}
local ok = pcall(function() writefile("KeyraHubConfig.json", HttpService:JSONEncode(cfg)) end)
if ok then local prev=saveBtn.Text; saveBtn.Text="✓  Saved!"; task.wait(1.5); saveBtn.Text=prev
else saveBtn.Text="✕  Failed!"; task.wait(1.5); saveBtn.Text="Save Config" end
end
local function loadConfig()
local hasFile = false; pcall(function() hasFile = isfile("KeyraHubConfig.json") end)
if not hasFile then return end
local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile("KeyraHubConfig.json")) end)
if not ok or not cfg then return end
local function lk(e, d)
if type(d)~="table" then return end
if d.kb and Enum.KeyCode[d.kb] then e.kb = Enum.KeyCode[d.kb] end
if d.gp and Enum.KeyCode[d.gp] then e.gp = Enum.KeyCode[d.gp] end
end
if cfg.normalSpeed and type(cfg.normalSpeed)=="number" then NS=cfg.normalSpeed; normalBox.Text=tostring(NS) end
if cfg.carrySpeed  and type(cfg.carrySpeed)=="number"  then CS=cfg.carrySpeed;  carryBox.Text=tostring(CS) end
if cfg.grabRadius  and type(cfg.grabRadius)=="number"  then Steal.StealRadius=cfg.grabRadius; progressRadLbl.Text="Radius: "..cfg.grabRadius end
lk(KB.AutoLeft,cfg.autoLeftKey); lk(KB.AutoRight,cfg.autoRightKey)
lk(KB.Drop,cfg.dropKey); lk(KB.TPDown,cfg.tpDownKey)
lk(KB.AutoBat,cfg.autoBatKey); lk(KB.Speed,cfg.speedKey); lk(KB.GuiHide,cfg.guiHideKey)
if cfg.infJump       then State.infJumpEnabled=true;       setInfJump(true)       end
if cfg.antiRagdoll   then State.antiRagdollEnabled=true;   setAntiRag(true); startAntiRagdoll() end
if cfg.fpsBoost      then State.fpsBoostEnabled=true;      setFps(true); applyFPSBoost()      end
if cfg.medusaCounter then State.medusaCounterEnabled=true; setMedusaCounter(true); setupMedusaCounter(LP.Character) end
if cfg.autoStealEnabled then Steal.AutoStealEnabled=true;  setAutoGrab(true); pcall(startAutoSteal) end
if cfg.unwalkEnabled then State.unwalkEnabled=true;        setUnwalkToggle(true)  end
end
local function setupChar(char)
task.wait(0.1)
h = char:WaitForChild("Humanoid", 5)
hrp = char:WaitForChild("HumanoidRootPart", 5)
if not h or not hrp then return end
State.lastKnownHealth = h.Health
local head = char:FindFirstChild("Head")
if head then
local oldBB = head:FindFirstChild("SpeedBillboard"); if oldBB then oldBB:Destroy() end
local bb = Instance.new("BillboardGui", head)
bb.Name = "SpeedBillboard"
bb.Size = UDim2.new(0, 140, 0, 25)
bb.StudsOffset = Vector3.new(0, 3, 0)
bb.AlwaysOnTop = true
speedLbl = Instance.new("TextLabel", bb)
speedLbl.Size = UDim2.new(1, 0, 1, 0)
speedLbl.BackgroundTransparency = 1
speedLbl.TextColor3 = WHITE
speedLbl.Font = Enum.Font.GothamBold
speedLbl.TextScaled = true
speedLbl.TextStrokeTransparency = 0
end
if State.antiRagdollEnabled and not Conns.antiRag then task.wait(0.5); startAntiRagdoll() end
if State.medusaCounterEnabled then setupMedusaCounter(char) end
end
LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end
RunService.Stepped:Connect(function()
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LP and p.Character then
for _, part in ipairs(p.Character:GetChildren()) do
if part:IsA("BasePart") then part.CanCollide = false end
end
end
end
end)
RunService.RenderStepped:Connect(function()
if not (h and hrp) then return end
local md = h.MoveDirection
local spd = State.speedToggled and CS or NS
if md.Magnitude > 0 and not State.autoLeftEnabled and not State.autoRightEnabled then
hrp.AssemblyLinearVelocity = Vector3.new(md.X*spd, hrp.AssemblyLinearVelocity.Y, md.Z*spd)
end
if speedLbl then
local hs = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
speedLbl.Text = "Speed: "..string.format("%.1f", hs)
end
end)
RunService.Heartbeat:Connect(function()
if not State.unwalkEnabled then return end
local char = LP.Character; if not char then return end
local hum2 = char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
local animator = hum2:FindFirstChildOfClass("Animator")
if animator then for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop() end end
end)
UIS.JumpRequest:Connect(function()
if not State.infJumpEnabled then return end
local char = LP.Character; if not char then return end
local root = char:FindFirstChild("HumanoidRootPart")
if root then root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z) end
end)
RunService.Heartbeat:Connect(function()
if not State.infJumpEnabled then return end
local char = LP.Character; if not char then return end
local root = char:FindFirstChild("HumanoidRootPart")
if root and root.Velocity.Y < -120 then root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z) end
end)
UIS.InputBegan:Connect(function(inp, gp)
if gp then return end
if _anyKeyListening then return end
if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
local kc = inp.KeyCode
if kbMatch(KB.Speed, kc) then
State.speedToggled = not State.speedToggled
if modeValLbl then modeValLbl.Text = State.speedToggled and "Carry" or "Normal" end
elseif kbMatch(KB.AutoBat, kc) then
State.autoBatToggled = not State.autoBatToggled
if State.autoBatToggled then
if State.autoLeftEnabled then State.autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
if State.autoRightEnabled then State.autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
local char = LP.Character
if char then
local hum = char:FindFirstChildOfClass("Humanoid")
local bp = LP:FindFirstChild("Backpack")
local bat = (bp and bp:FindFirstChild("Bat")) or char:FindFirstChild("Bat")
if bat and hum then hum:EquipTool(bat) end
end
end
if autoBatSetVisual then autoBatSetVisual(State.autoBatToggled) end
elseif kbMatch(KB.AutoLeft, kc) then
State.autoLeftEnabled = not State.autoLeftEnabled
if State.autoLeftEnabled then
if State.autoRightEnabled then State.autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
if State.autoBatToggled then State.autoBatToggled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
startAutoLeft()
else stopAutoLeft() end
if autoLeftSetVisual then autoLeftSetVisual(State.autoLeftEnabled) end
elseif kbMatch(KB.AutoRight, kc) then
State.autoRightEnabled = not State.autoRightEnabled
if State.autoRightEnabled then
if State.autoLeftEnabled then State.autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
if State.autoBatToggled then State.autoBatToggled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
startAutoRight()
else stopAutoRight() end
if autoRightSetVisual then autoRightSetVisual(State.autoRightEnabled) end
elseif kbMatch(KB.Drop, kc) then
task.spawn(runDrop)
elseif kbMatch(KB.TPDown, kc) then
task.spawn(runTPDown)
elseif kbMatch(KB.GuiHide, kc) then
if main.Visible then hideGui() else showGui() end
end
end)
task.spawn(function()
while task.wait(0.5) do
pcall(function() progressRadLbl.Text = "Radius: "..Steal.StealRadius end)
end
end)
switchTab("Speed")
loadConfig()
print("[Keyra Hub] Loaded!"
