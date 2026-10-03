--[[
    RESIDENCE MASSACRE - DEV TEST MENU
    Tasta K = deschide / inchide meniul
    Rulat cu Xeno (client-side). Efecte doar locale.
]]

---------------------------------------------------------------------
-- CONFIG (editeaza cu numele reale din Residence Massacre)
---------------------------------------------------------------------
local CFG = {
    ToggleKey = Enum.KeyCode.K,

    -- Cuvinte-cheie pentru NPC-uri (modele cu Humanoid care nu sunt playeri sunt oricum detectate)
    NPCKeywords = { "killer", "monster", "zombie", "enemy", "stalker", "massacre", "npc", "mob" },
    -- Nume exacte de NPC-uri (optional), ex: { "Butcher", "Jason" }
    NPCExactNames = {},

    -- Cuvinte-cheie pentru obiective / iteme importante
    ObjectiveKeywords = { "key", "keycard", "fuse", "battery", "generator", "lever", "exit",
        "escape", "gate", "door", "medkit", "fusebox", "objective", "crowbar", "code", "note" },
    -- Nume exacte de obiective (optional)
    ObjectiveExactNames = {},

    ESPMaxDistance = 2000,

    -- Itemele de dat (numele trebuie sa existe ca Tool in ServerStorage, vezi RM_GiveServer.lua)
    GiveItems = { "Bloxy Cola", "Hammer" },

    Defaults = {
        WalkSpeed = 16, JumpPower = 50, FlySpeed = 60, FOV = 70, TPForwardDistance = 25,
    },
}

---------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Mouse  = LP:GetMouse()
local Camera = Workspace.CurrentCamera

-- evita dubla incarcare
if getgenv then
    local g = getgenv()
    if g.RM_DEVMENU_CLEANUP then pcall(g.RM_DEVMENU_CLEANUP) end
end

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------
local S = {
    noclip = false, fly = false, speed = false, jump = false, infjump = false,
    teleport = false, fov = false, fullbright = false,
    esp = false, espNPC = true, espPlayers = true, espObj = true,
}
local V = {
    walk = CFG.Defaults.WalkSpeed, jump = CFG.Defaults.JumpPower,
    fly = CFG.Defaults.FlySpeed, fov = CFG.Defaults.FOV,
    tpDist = CFG.Defaults.TPForwardDistance,
}
local Registry   = {}   -- key -> {set=function(bool), label=string}
local Order      = {}   -- ordine pentru HUD
local Connections = {}
local function connect(sig, fn) local c = sig:Connect(fn); table.insert(Connections, c); return c end

local function char() return LP.Character end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = char(); return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart) end

local Orig = { walk = 16, jumpPower = 50, jumpHeight = 7.2, useJumpPower = true }
local function captureOriginals()
    local h = hum()
    if h then
        if h.WalkSpeed > 0 then Orig.walk = h.WalkSpeed end
        Orig.useJumpPower = h.UseJumpPower
        Orig.jumpPower = h.JumpPower
        Orig.jumpHeight = h.JumpHeight
    end
end
captureOriginals()

---------------------------------------------------------------------
-- GUI ROOT
---------------------------------------------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "RM_DevMenu_" .. tostring(math.random(1000, 9999))
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999
do
    local ok = pcall(function()
        Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not ok then Gui.Parent = LP:WaitForChild("PlayerGui") end
end
local ESPFolder = Instance.new("Folder"); ESPFolder.Name = "ESP"; ESPFolder.Parent = Gui

---------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------
local T = {
    bg = Color3.fromRGB(16, 16, 20), panel = Color3.fromRGB(24, 24, 30),
    item = Color3.fromRGB(30, 30, 38), stroke = Color3.fromRGB(48, 48, 60),
    text = Color3.fromRGB(230, 230, 238), dim = Color3.fromRGB(140, 140, 155),
    accent = Color3.fromRGB(205, 45, 60), accent2 = Color3.fromRGB(255, 90, 100),
    off = Color3.fromRGB(55, 55, 66), on = Color3.fromRGB(70, 200, 110),
}
local FONT, FONTB = Enum.Font.Gotham, Enum.Font.GothamBold
local function tw(o, t, p) return TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p) end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
local function stroke(o, c, th) return new("UIStroke", { Color = c or T.stroke, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end

---------------------------------------------------------------------
-- MAIN WINDOW
---------------------------------------------------------------------
local Main = new("Frame", {
    Name = "Main", Size = UDim2.fromOffset(340, 440), Position = UDim2.new(0.5, -170, 0.5, -220),
    BackgroundColor3 = T.bg, BorderSizePixel = 0, Visible = false,
}, Gui)
corner(Main, 10); stroke(Main, T.stroke)

local Title = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.panel, BorderSizePixel = 0 }, Main)
corner(Title, 10)
new("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = T.panel, BorderSizePixel = 0 }, Title)
new("Frame", { Size = UDim2.fromOffset(3, 16), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, Title)
new("TextLabel", {
    Text = "RESIDENCE MASSACRE  |  DEV MENU", Font = FONTB, TextSize = 13, TextColor3 = T.text,
    BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -90, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
}, Title)
local ActiveCount = new("TextLabel", {
    Text = "0 ACTIVE", Font = FONTB, TextSize = 11, TextColor3 = T.dim, BackgroundTransparency = 1,
    Position = UDim2.new(1, -90, 0, 0), Size = UDim2.fromOffset(80, 36), TextXAlignment = Enum.TextXAlignment.Right,
}, Title)

-- Draggable
do
    local dragging, dragStart, startPos
    connect(Title.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, Main.Position
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- Tabs
local TabBar = new("Frame", { Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 0, 28), BackgroundTransparency = 1 }, Main)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, TabBar)
local Pages, TabButtons = {}, {}

local function makePage(name)
    local p = new("ScrollingFrame", {
        Name = name, Position = UDim2.fromOffset(8, 76), Size = UDim2.new(1, -16, 1, -84),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, Main)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, p)
    new("UIPadding", { PaddingRight = UDim.new(0, 5) }, p)
    Pages[name] = p

    local b = new("TextButton", {
        Text = name, Font = FONTB, TextSize = 11, TextColor3 = T.dim, BackgroundColor3 = T.panel,
        Size = UDim2.new(1 / 3, -4, 1, 0), AutoButtonColor = false, BorderSizePixel = 0,
    }, TabBar)
    corner(b, 6)
    TabButtons[name] = b
    b.MouseButton1Click:Connect(function()
        for n, pg in pairs(Pages) do
            pg.Visible = (n == name)
            tw(TabButtons[n], 0.15, { BackgroundColor3 = n == name and T.accent or T.panel,
                TextColor3 = n == name and Color3.new(1, 1, 1) or T.dim }):Play()
        end
    end)
    return p
end
local PMove, PVisual, PUtil = makePage("MOVEMENT"), makePage("VISUAL"), makePage("UTILITY")

---------------------------------------------------------------------
-- HUD (lista functiilor active, ramane vizibila si cu meniul inchis)
---------------------------------------------------------------------
local HUD = new("Frame", {
    Size = UDim2.fromOffset(150, 20), Position = UDim2.fromOffset(10, 200), BackgroundColor3 = T.bg,
    BackgroundTransparency = 0.2, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, Visible = false,
}, Gui)
corner(HUD, 6); stroke(HUD, T.accent)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }, HUD)
new("UIListLayout", { Padding = UDim.new(0, 2) }, HUD)
local HUDList = {}
local function refreshHUD()
    for _, l in pairs(HUDList) do l:Destroy() end
    HUDList = {}
    local n = 0
    for _, key in ipairs(Order) do
        if S[key] then
            n += 1
            local l = new("TextLabel", {
                Text = "● " .. Registry[key].label, Font = FONT, TextSize = 11, TextColor3 = T.on,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
            }, HUD)
            table.insert(HUDList, l)
        end
    end
    HUD.Visible = n > 0
    ActiveCount.Text = n .. " ACTIVE"
    ActiveCount.TextColor3 = n > 0 and T.on or T.dim
end

---------------------------------------------------------------------
-- UI COMPONENTS
---------------------------------------------------------------------
local function section(page, text)
    new("TextLabel", { Text = text, Font = FONTB, TextSize = 10, TextColor3 = T.accent2, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left }, page)
end

local function card(page, height)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = T.item, BorderSizePixel = 0 }, page)
    corner(f, 8); stroke(f, T.stroke)
    return f
end

-- toggle: returneaza card-ul (sa poti adauga slidere dedesubt)
local function addToggle(page, key, label, onChange, height)
    local c = card(page, height or 34)
    new("TextLabel", { Text = label, Font = FONTB, TextSize = 12, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -70, 0, 34), TextXAlignment = Enum.TextXAlignment.Left }, c)
    local sw = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = T.off,
        Size = UDim2.fromOffset(38, 18), Position = UDim2.new(1, -48, 0, 8), BorderSizePixel = 0 }, c)
    corner(sw, 9)
    local knob = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, sw)
    corner(knob, 7)

    local function render(v)
        tw(sw, 0.18, { BackgroundColor3 = v and T.on or T.off }):Play()
        tw(knob, 0.18, { Position = v and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) }):Play()
    end
    Registry[key] = {
        label = label,
        set = function(v)
            if S[key] == v then render(v) return end
            S[key] = v
            render(v)
            local ok, err = pcall(onChange, v)
            if not ok then warn("[RM DevMenu] " .. key .. ": " .. tostring(err)) end
            refreshHUD()
        end,
    }
    table.insert(Order, key)
    sw.MouseButton1Click:Connect(function() Registry[key].set(not S[key]) end)
    return c
end

local function addSlider(parent, y, label, min, max, default, step, onChange)
    local lab = new("TextLabel", { Text = label, Font = FONT, TextSize = 11, TextColor3 = T.dim, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -70, 0, 14), TextXAlignment = Enum.TextXAlignment.Left }, parent)
    local val = new("TextLabel", { Text = tostring(default), Font = FONTB, TextSize = 11, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, y), Size = UDim2.fromOffset(50, 14), TextXAlignment = Enum.TextXAlignment.Right }, parent)
    local bar = new("Frame", { Position = UDim2.fromOffset(10, y + 20), Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = T.off, BorderSizePixel = 0 }, parent)
    corner(bar, 3)
    local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, bar)
    corner(fill, 3)
    local knob = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
    corner(knob, 6)
    local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, y + 12),
        Size = UDim2.new(1, -20, 0, 22) }, parent)

    local current = default
    local function setValue(v, silent)
        v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        current = v
        local a = (v - min) / (max - min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        val.Text = tostring(v)
        if not silent then onChange(v) end
    end
    local dragging = false
    local function fromInput(i)
        local a = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        setValue(min + (max - min) * a)
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; fromInput(i)
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromInput(i) end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    setValue(default, true)
    return { set = setValue, get = function() return current end }
end

local function addPresets(parent, y, presets, onPick)
    local row = new("Frame", { Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, 22), BackgroundTransparency = 1 }, parent)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, row)
    local n = #presets
    for _, p in ipairs(presets) do
        local b = new("TextButton", { Text = p.name, Font = FONTB, TextSize = 10, TextColor3 = T.text, BackgroundColor3 = T.panel,
            Size = UDim2.new(1 / n, -4, 1, 0), AutoButtonColor = false, BorderSizePixel = 0 }, row)
        corner(b, 5); stroke(b, T.stroke)
        b.MouseEnter:Connect(function() tw(b, 0.12, { BackgroundColor3 = T.accent }):Play() end)
        b.MouseLeave:Connect(function() tw(b, 0.12, { BackgroundColor3 = T.panel }):Play() end)
        b.MouseButton1Click:Connect(function() onPick(p.value) end)
    end
end

local function addButton(page, text, onClick, color)
    local b = new("TextButton", { Text = text, Font = FONTB, TextSize = 12, TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = color or T.panel, Size = UDim2.new(1, 0, 0, 30), AutoButtonColor = false, BorderSizePixel = 0 }, page)
    corner(b, 8); stroke(b, T.stroke)
    local base = color or T.panel
    b.MouseEnter:Connect(function() tw(b, 0.12, { BackgroundColor3 = T.accent }):Play() end)
    b.MouseLeave:Connect(function() tw(b, 0.12, { BackgroundColor3 = base }):Play() end)
    b.MouseButton1Click:Connect(onClick)
    return b
end

---------------------------------------------------------------------
-- LOGIC: NOCLIP
---------------------------------------------------------------------
local noclipChanged = {}
local function restoreCollisions()
    for part in pairs(noclipChanged) do
        if part and part.Parent then part.CanCollide = true end
    end
    table.clear(noclipChanged)
end
connect(RunService.Stepped, function()
    if not S.noclip then return end
    local c = char(); if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            noclipChanged[p] = true
            p.CanCollide = false
        end
    end
end)

---------------------------------------------------------------------
-- LOGIC: FLY
---------------------------------------------------------------------
local flyBV, flyBG
local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local h = hum()
    if h then
        h.PlatformStand = false
        h:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end
local function startFly()
    local r, h = root(), hum()
    if not (r and h) then return end
    stopFly()
    flyBV = new("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero }, r)
    flyBG = new("BodyGyro", { MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 9e4, CFrame = Camera.CFrame }, r)
    h.PlatformStand = true
end
connect(RunService.RenderStepped, function()
    if not S.fly then return end
    if not (flyBV and flyBV.Parent) then startFly() end
    if not flyBV then return end
    local dir = Vector3.zero
    if not UIS:GetFocusedTextBox() then
        local cf = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
    end
    flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * V.fly or Vector3.zero
    flyBG.CFrame = Camera.CFrame
end)

---------------------------------------------------------------------
-- LOGIC: SPEED / JUMP / INFINITE JUMP
---------------------------------------------------------------------
local function applyJump(on)
    local h = hum(); if not h then return end
    if on then
        h.UseJumpPower = true
        h.JumpPower = V.jump
    else
        h.UseJumpPower = Orig.useJumpPower
        h.JumpPower = Orig.jumpPower
        h.JumpHeight = Orig.jumpHeight
    end
end
connect(RunService.Heartbeat, function()
    local h = hum(); if not h then return end
    if S.speed and h.WalkSpeed ~= V.walk then h.WalkSpeed = V.walk end
    if S.jump then
        if not h.UseJumpPower then h.UseJumpPower = true end
        if h.JumpPower ~= V.jump then h.JumpPower = V.jump end
    end
end)
connect(UIS.JumpRequest, function()
    if S.infjump then
        local h = hum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

---------------------------------------------------------------------
-- LOGIC: FOV / FULLBRIGHT
---------------------------------------------------------------------
connect(RunService.RenderStepped, function()
    Camera = Workspace.CurrentCamera or Camera
    if S.fov and Camera.FieldOfView ~= V.fov then Camera.FieldOfView = V.fov end
end)

local LightOrig, AtmoOrig
local function saveLighting()
    if LightOrig then return end
    LightOrig = {
        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
    AtmoOrig = {}
    for _, a in ipairs(Lighting:GetChildren()) do
        if a:IsA("Atmosphere") then AtmoOrig[a] = a.Density end
    end
end
local function applyFB()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1e6
    Lighting.FogStart = 1e6
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(190, 190, 190)
    Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
    for a in pairs(AtmoOrig or {}) do if a.Parent then a.Density = 0 end end
end
local function restoreLighting()
    if not LightOrig then return end
    for k, v in pairs(LightOrig) do pcall(function() Lighting[k] = v end) end
    for a, d in pairs(AtmoOrig or {}) do if a.Parent then a.Density = d end end
    LightOrig, AtmoOrig = nil, nil
end
connect(RunService.RenderStepped, function() if S.fullbright then applyFB() end end)

---------------------------------------------------------------------
-- LOGIC: ESP (NPC / Players / Objectives)
---------------------------------------------------------------------
local ESPColors = { npc = Color3.fromRGB(255, 70, 70), player = Color3.fromRGB(80, 170, 255), obj = Color3.fromRGB(255, 220, 70) }
local ESPEntries = {} -- inst -> {cat, part, gui, label, hl}

local function lowerHas(name, list)
    name = name:lower()
    for _, k in ipairs(list) do if name:find(k, 1, true) then return true end end
    return false
end
local function inList(name, list)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end
local function anyPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end
local function catEnabled(cat)
    if not S.esp then return false end
    return (cat == "npc" and S.espNPC) or (cat == "player" and S.espPlayers) or (cat == "obj" and S.espObj)
end

local function removeESP(inst)
    local e = ESPEntries[inst]
    if not e then return end
    if e.gui then e.gui:Destroy() end
    if e.hl then e.hl:Destroy() end
    ESPEntries[inst] = nil
end
local function addESP(inst, cat, displayName)
    if ESPEntries[inst] then return end
    local part = anyPart(inst); if not part then return end
    local gui = new("BillboardGui", { Adornee = part, AlwaysOnTop = true, Size = UDim2.fromOffset(140, 34),
        StudsOffset = Vector3.new(0, 2.5, 0), ResetOnSpawn = false }, ESPFolder)
    local lab = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONTB, TextSize = 12,
        TextColor3 = ESPColors[cat], TextStrokeTransparency = 0.3, Text = displayName }, gui)
    local hl
    if cat ~= "obj" and inst:IsA("Model") then
        hl = new("Highlight", { Adornee = inst, FillColor = ESPColors[cat], FillTransparency = 0.75,
            OutlineColor = ESPColors[cat], DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, ESPFolder)
    end
    ESPEntries[inst] = { cat = cat, part = part, gui = gui, label = lab, hl = hl, name = displayName }
end

local ObjectiveCache = {} -- inst -> name (folosit si de teleport)
local function scanWorld()
    local found = {}
    local charModels = {}
    for _, p in ipairs(Players:GetPlayers()) do if p.Character then charModels[p.Character] = true end end

    -- Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then found[p.Character] = { "player", p.DisplayName } end
    end

    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Humanoid") then
            local m = d.Parent
            if m and m:IsA("Model") and not charModels[m] and not found[m] then
                found[m] = { "npc", m.Name }
            end
        elseif d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
            local tgt = d.Parent
            if tgt then
                local mdl = tgt:FindFirstAncestorOfClass("Model")
                local obj = (mdl and mdl ~= Workspace and not charModels[mdl]) and mdl or tgt
                if not found[obj] and not charModels[obj] then
                    local nm = (d:IsA("ProximityPrompt") and d.ObjectText ~= "" and d.ObjectText) or obj.Name
                    found[obj] = { "obj", nm }
                end
            end
        elseif (d:IsA("Model") or d:IsA("Tool")) and not found[d] and not charModels[d] then
            if inList(d.Name, CFG.NPCExactNames) then
                found[d] = { "npc", d.Name }
            elseif inList(d.Name, CFG.ObjectiveExactNames) or lowerHas(d.Name, CFG.ObjectiveKeywords) then
                if not d:FindFirstChildOfClass("Humanoid") then found[d] = { "obj", d.Name } end
            elseif lowerHas(d.Name, CFG.NPCKeywords) and d:FindFirstChildOfClass("Humanoid") then
                found[d] = { "npc", d.Name }
            end
        end
    end

    table.clear(ObjectiveCache)
    for inst, info in pairs(found) do
        if info[1] == "obj" then ObjectiveCache[inst] = info[2] end
    end
    return found
end

local function refreshESP()
    -- sterge categorii dezactivate / obiecte disparute
    for inst, e in pairs(ESPEntries) do
        if not inst:IsDescendantOf(Workspace) or not catEnabled(e.cat) then removeESP(inst) end
    end
    if not S.esp then return end
    local found = scanWorld()
    for inst, info in pairs(found) do
        if catEnabled(info[1]) then addESP(inst, info[1], info[2]) end
    end
end

local espAcc, scanAcc = 0, 0
connect(RunService.Heartbeat, function(dt)
    if not S.esp then return end
    espAcc += dt; scanAcc += dt
    if scanAcc >= 2.5 then scanAcc = 0; pcall(refreshESP) end
    if espAcc >= 0.1 then
        espAcc = 0
        local cp = Camera.CFrame.Position
        for inst, e in pairs(ESPEntries) do
            if e.part and e.part.Parent then
                local dist = (e.part.Position - cp).Magnitude
                e.gui.Enabled = dist <= CFG.ESPMaxDistance
                e.label.Text = string.format("%s\n[%d m]", e.name, dist)
            else
                removeESP(inst)
            end
        end
    end
end)

---------------------------------------------------------------------
-- LOGIC: TELEPORT
---------------------------------------------------------------------
local savedPos
local function tpTo(cf)
    local r = root(); if r then r.CFrame = cf end
end
local function tpForward()
    local r = root(); if r then r.CFrame = r.CFrame + r.CFrame.LookVector * V.tpDist end
end
local function findSpawn()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("SpawnLocation") then return d end
    end
end
local function tpNearestObjective()
    scanWorld()
    local r = root(); if not r then return end
    local best, bd
    for inst in pairs(ObjectiveCache) do
        local p = anyPart(inst)
        if p then
            local d = (p.Position - r.Position).Magnitude
            if d > 8 and (not bd or d < bd) then best, bd = p, d end
        end
    end
    if best then tpTo(best.CFrame + Vector3.new(0, 4, 0)) end
end
connect(UIS.InputBegan, function(i, gp)
    if gp or not S.teleport then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        local pos = Mouse.Hit and Mouse.Hit.Position
        if pos then tpTo(CFrame.new(pos + Vector3.new(0, 3.5, 0))) end
    end
end)

---------------------------------------------------------------------
-- BUILD UI: MOVEMENT
---------------------------------------------------------------------
section(PMove, "MOVEMENT")

-- Speed
local cSpeed = addToggle(PMove, "speed", "Speed Hack", function(on)
    local h = hum(); if not h then return end
    h.WalkSpeed = on and V.walk or Orig.walk
end, 118)
local walkSlider = addSlider(cSpeed, 38, "WalkSpeed", 16, 200, V.walk, 1, function(v)
    V.walk = v
    if S.speed then local h = hum(); if h then h.WalkSpeed = v end end
end)
addPresets(cSpeed, 84, {
    { name = "16", value = 16 }, { name = "25", value = 25 }, { name = "50", value = 50 },
    { name = "100", value = 100 }, { name = "200", value = 200 },
}, function(v) walkSlider.set(v) end)

-- Jump
local cJump = addToggle(PMove, "jump", "Jump Hack", function(on) applyJump(on) end, 118)
local jumpSlider = addSlider(cJump, 38, "JumpPower", 50, 400, V.jump, 1, function(v)
    V.jump = v
    if S.jump then applyJump(true) end
end)
addPresets(cJump, 84, {
    { name = "Normal", value = 50 }, { name = "High", value = 120 }, { name = "Extreme", value = 300 },
}, function(v) jumpSlider.set(v) end)

addToggle(PMove, "infjump", "Infinite Jump", function() end)

-- Fly
local cFly = addToggle(PMove, "fly", "Fly  (WASD / Space / LCtrl)", function(on)
    if on then startFly() else stopFly() end
end, 82)
addSlider(cFly, 38, "Fly Speed", 10, 300, V.fly, 1, function(v) V.fly = v end)

addToggle(PMove, "noclip", "NoClip", function(on)
    if not on then restoreCollisions() end
end)

-- Teleport
local cTP = addToggle(PMove, "teleport", "Teleport  (Ctrl + Click)", function() end, 150)
addSlider(cTP, 38, "Forward Distance", 5, 150, V.tpDist, 1, function(v) V.tpDist = v end)
do
    local row1 = new("Frame", { Position = UDim2.fromOffset(10, 84), Size = UDim2.new(1, -20, 0, 24), BackgroundTransparency = 1 }, cTP)
    local row2 = new("Frame", { Position = UDim2.fromOffset(10, 114), Size = UDim2.new(1, -20, 0, 24), BackgroundTransparency = 1 }, cTP)
    local function mini(parent, text, x, w, fn)
        local b = new("TextButton", { Text = text, Font = FONTB, TextSize = 10, TextColor3 = T.text, BackgroundColor3 = T.panel,
            Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(w, -4, 1, 0), AutoButtonColor = false, BorderSizePixel = 0 }, parent)
        corner(b, 5); stroke(b, T.stroke)
        b.MouseEnter:Connect(function() tw(b, 0.12, { BackgroundColor3 = T.accent }):Play() end)
        b.MouseLeave:Connect(function() tw(b, 0.12, { BackgroundColor3 = T.panel }):Play() end)
        b.MouseButton1Click:Connect(fn)
    end
    mini(row1, "TP Forward", 0, 0.5, tpForward)
    mini(row1, "Spawn", 0.5, 0.5, function()
        local s = findSpawn()
        if s then tpTo(s.CFrame + Vector3.new(0, 4, 0)) end
    end)
    mini(row2, "Save Pos", 0, 1 / 3, function() local r = root(); if r then savedPos = r.CFrame end end)
    mini(row2, "Load Pos", 1 / 3, 1 / 3, function() if savedPos then tpTo(savedPos) end end)
    mini(row2, "Nearest Obj", 2 / 3, 1 / 3, tpNearestObjective)
end

---------------------------------------------------------------------
-- BUILD UI: VISUAL
---------------------------------------------------------------------
section(PVisual, "VISUAL")
local cESP = addToggle(PVisual, "esp", "ESP", function(on)
    if on then pcall(refreshESP) else for i in pairs(ESPEntries) do removeESP(i) end end
end, 34)
local function espSub(key, label)
    addToggle(PVisual, key, "   ↳ " .. label, function() if S.esp then pcall(refreshESP) end end)
end
espSub("espNPC", "NPCs")
espSub("espPlayers", "Players")
espSub("espObj", "Objectives")

addToggle(PVisual, "fullbright", "FullBright", function(on)
    if on then saveLighting(); applyFB() else restoreLighting() end
end)

local cFOV = addToggle(PVisual, "fov", "FOV Changer", function(on)
    if not on then Camera.FieldOfView = CFG.Defaults.FOV end
end, 66)
addSlider(cFOV, 34, "Field of View", 30, 120, V.fov, 1, function(v)
    V.fov = v
    if S.fov then Camera.FieldOfView = v end
end)

---------------------------------------------------------------------
-- BUILD UI: UTILITY
---------------------------------------------------------------------
section(PUtil, "UTILITY")
local function disableAll()
    for _, key in ipairs(Order) do
        if S[key] and key ~= "espNPC" and key ~= "espPlayers" and key ~= "espObj" then Registry[key].set(false) end
    end
    -- sub-toggles raman in starea lor, dar ESP master e oprit
end
section(PUtil, "GIVE ITEMS")
for _, itemName in ipairs(CFG.GiveItems) do
    addButton(PUtil, "Give " .. itemName, function()
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RM_DevGive")
        if remote then
            remote:FireServer(itemName)
        else
            warn("[RM DevMenu] RM_DevGive lipseste. Pune RM_GiveServer.lua in ServerScriptService.")
        end
    end)
end

section(PUtil, "CHARACTER")
addButton(PUtil, "Reset Character", function()
    disableAll()
    local h = hum(); if h then h.Health = 0 end
end)
addButton(PUtil, "Disable All", disableAll, Color3.fromRGB(120, 30, 40))
addButton(PUtil, "Reopen Menu (reset pozitie)", function()
    Main.Position = UDim2.new(0.5, -170, 0.5, -220)
    Main.Visible = true
end)
new("TextLabel", { Text = "K = deschide/inchide meniul\nCtrl+Click = teleport (cand Teleport e ON)",
    Font = FONT, TextSize = 11, TextColor3 = T.dim, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34),
    TextXAlignment = Enum.TextXAlignment.Left }, PUtil)

---------------------------------------------------------------------
-- OPEN / CLOSE + KEYBIND
---------------------------------------------------------------------
local function setMenu(open)
    if open then
        Main.Visible = true
        Main.BackgroundTransparency = 1
        tw(Main, 0.15, { BackgroundTransparency = 0 }):Play()
    else
        Main.Visible = false
    end
end
connect(UIS.InputBegan, function(i, gp)
    if i.KeyCode == CFG.ToggleKey and not UIS:GetFocusedTextBox() then
        setMenu(not Main.Visible)
    end
end)

-- Respawn: reaplica functiile active
connect(LP.CharacterAdded, function(c)
    c:WaitForChild("Humanoid", 10); c:WaitForChild("HumanoidRootPart", 10)
    task.wait(0.5)
    captureOriginals()
    table.clear(noclipChanged)
    flyBV, flyBG = nil, nil
    if S.fly then startFly() end
    if S.jump then applyJump(true) end
    if S.speed then local h = hum(); if h then h.WalkSpeed = V.walk end end
end)

-- Tab initial
TabButtons["MOVEMENT"].BackgroundColor3 = T.accent
TabButtons["MOVEMENT"].TextColor3 = Color3.new(1, 1, 1)
Pages["MOVEMENT"].Visible = true
setMenu(true)
refreshHUD()

---------------------------------------------------------------------
-- CLEANUP
---------------------------------------------------------------------
if getgenv then
    getgenv().RM_DEVMENU_CLEANUP = function()
        disableAll()
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        for i in pairs(ESPEntries) do removeESP(i) end
        restoreLighting(); restoreCollisions(); stopFly()
        Gui:Destroy()
    end
end
