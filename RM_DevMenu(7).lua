--[[
    RESIDENCE MASSACRE - DEV MENU (fisier unic)
    - Pe GitHub / Xeno: ruleaza partea de CLIENT (meniul, tasta K).
    - In Roblox Studio (Script in ServerScriptService): ruleaza partea de SERVER
      (Give Items + God Mode). Editeaza OWNER_USERID mai jos DOAR in copia din Studio.
]]
if game:GetService("RunService"):IsServer() then
    do
        -- !!! UserId-ul TAU (numarul din link-ul profilului Roblox) !!!
        local OWNER_USERID = 0
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local ServerStorage = game:GetService("ServerStorage")

        -- !!! Pune aici UserId-ul TAU (numarul din link-ul profilului Roblox) !!!
        local ALLOWED = {
        	[OWNER_USERID] = true,
        }

        local ITEM_SOURCE = ServerStorage:FindFirstChild("Items") or ServerStorage

        ---------------------------------------------------------------- GIVE
        local give = Instance.new("RemoteEvent")
        give.Name = "RM_DevGive"
        give.Parent = ReplicatedStorage

        local lastUse = {}
        give.OnServerEvent:Connect(function(player, itemName)
        	if not ALLOWED[player.UserId] then return end
        	if typeof(itemName) ~= "string" then return end
        	if os.clock() - (lastUse[player] or 0) < 0.5 then return end
        	lastUse[player] = os.clock()

        	local template = ITEM_SOURCE:FindFirstChild(itemName)
        	if template and template:IsA("Tool") then
        		template:Clone().Parent = player:WaitForChild("Backpack")
        	end
        end)

        ---------------------------------------------------------------- GOD MODE
        -- Functioneaza pentru damage care trece prin Humanoid. Daca jocul tau are un sistem
        -- de damage custom, verifica acolo "if godMode[player] then return end".
        local god = Instance.new("RemoteEvent")
        god.Name = "RM_DevGod"
        god.Parent = ReplicatedStorage

        local godMode, godConn = {}, {}

        local function applyGod(player, on)
        	if godConn[player] then godConn[player]:Disconnect() godConn[player] = nil end
        	local char = player.Character
        	if char then
        		local old = char:FindFirstChild("RM_God")
        		if old then old:Destroy() end
        	end
        	local hum = char and char:FindFirstChildOfClass("Humanoid")
        	if not (on and hum) then return end
        	local ff = Instance.new("ForceField")
        	ff.Name = "RM_God"
        	ff.Visible = false
        	ff.Parent = char
        	godConn[player] = hum.HealthChanged:Connect(function()
        		if hum.Health > 0 and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        	end)
        end

        god.OnServerEvent:Connect(function(player, on)
        	if not ALLOWED[player.UserId] or typeof(on) ~= "boolean" then return end
        	godMode[player] = on
        	applyGod(player, on)
        end)

        local function hook(player)
        	player.CharacterAdded:Connect(function()
        		task.wait(0.5)
        		if godMode[player] then applyGod(player, true) end
        	end)
        end
        for _, p in ipairs(Players:GetPlayers()) do hook(p) end
        Players.PlayerAdded:Connect(hook)

        Players.PlayerRemoving:Connect(function(p)
        	lastUse[p] = nil
        	godMode[p] = nil
        	if godConn[p] then godConn[p]:Disconnect() godConn[p] = nil end
        end)
    end
    return
end

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

    -- Obiective generale (galben). Foarte putine, ca sa nu apara gunoi (usi, rame etc.)
    ObjectiveKeywords = { "fuse", "generator", "lever", "exit", "escape", "fusebox", "objective",
        "crowbar", "elevator", "breaker", "switch" },
    ObjectiveExactNames = {},
    -- Ce NU vrei sa apara ca obiectiv (potrivire pe nume)
    ObjectiveExclude = { "frame", "lattice", "seat", "drawer", "wardrobe", "door", "bed", "table",
        "chair", "lamp", "curtain", "window", "shelf", "bookcase", "painting" },

    ESPMaxDistance = 300,
    NearestLimit = 25,          -- cate iteme/obiecte (cele mai apropiate) sa arate, ca sa nu fie aglomerat

    -- ESP iteme (toate rosii). 3 optiuni: Items / Door Keys / Coins. Adauga numele reale din joc.
    ItemKeywords = {
        item = { "crucifix", "lockpick", "lockpic", "flashlight", "lighter", "brichet", "zippo",
                 "vitamin", "candle", "lumanare", "moonlight", "bandage", "battery", "herb", "viridis",
                 "alarm", "clock", "fuse", "breaker", "donut", "smoothie", "soda", "gween", "bread", "cheese",
                 "float", "jar", "compass", "lantern", "shears" },
        key  = { "key", "cheie" },
        chest = { "chest", "trunk", "cufar" },
        puzzle = { "book", "bulb", "lightbulb", "paper", "solution" },   -- carti, becuri, foi
        hide  = { "wardrobe", "closet", "locker", "hidingspot" },
        coin = { "coin", "gold", "moneda", "moned" },
    },
    -- Obiecte care NU sunt iteme (decor, spawn-uri, hitbox-uri). Potrivire pe nume.
    ItemExclude = { "wall", "decor", "bookshelf", "bookcase", "shelf", "lattice", "drawer", "seat", "painting", "wood", "log", "fireplace", "chimney", "hearth", "firewood",
                    "keypad", "keyhole", "keyboard", "hitbox", "spawn", "zone", "trigger", "statue" },
    ItemMaxSize = 10,               -- ignora obiecte mai mari (mobila, spawn-uri uriase)
    RequirePromptForItems = true,   -- un item real are ProximityPrompt/ClickDetector sau e Tool

    -- Entitati custom (Rush, Ambush etc.). Potrivire pe nume (contine). Pune numele reale din jocul tau.
    DoorExclude = { "frame", "lattice", "knob", "hinge", "sign", "handle", "lock", "mat" },
    FakeDoorKeywords = { "fake", "dupe" },     -- usi false: numele (sau parintii) contin aceste cuvinte
    NotifyDistance = 30,                        -- notificare cand ajungi aproape de iteme

    -- Foldere unde sunt camerele (pentru "found in door N"). Adauga numele din jocul tau.
    RoomFolderNames = { "CurrentRooms", "Rooms" },
    -- Piese ajutatoare / decor care contin numele entitatii dar NU sunt entitatea (ignorate peste tot)
    EntityExclude = { "painting", "arm", "puddle", "pos", "collision", "cam", "teleport", "broke", "first",
                      "arti", "anti", "hitbox", "trigger", "spawn", "gui", "sound" },
    DangerCooldown = 20,        -- secunde intre doua alerte pentru aceeasi entitate (fara spam)
    TrapKeywords = { "trap", "hatch", "drain", "grate", "spikes" },   -- capcane (adauga numele din jocul tau)
    EntityNames = { "rush", "ambush", "seek", "figure", "halt", "screech", "eyes", "giggle", "grumble" },

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
    esp = false, espNPC = true, espPlayers = true, espObj = false,
    espBox = false, espTracers = false, espHealth = false,
    espItems = true, espKeys = true, espCoins = true, espChests = true,
    dangerAlert = true, rainbow = false, thirdPerson = false, god = false,
    espDoors = true, espPuzzle = true, espHide = false,
    rainbowLoot = false, espDist = true, espFill = true, espNearest = true, espTraps = true,
    nearNotify = false, antiAfk = false, statsHud = false, zoom = false, zoomHeld = false,
}
local V = {
    walk = CFG.Defaults.WalkSpeed, jump = CFG.Defaults.JumpPower,
    fly = CFG.Defaults.FlySpeed, fov = CFG.Defaults.FOV,
    tpDist = CFG.Defaults.TPForwardDistance, espText = 12, tpCam = 14, dangerDist = 300,
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
Gui.IgnoreGuiInset = true
do
    local ok = pcall(function()
        Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not ok then Gui.Parent = LP:WaitForChild("PlayerGui") end
end
local ESPFolder = Instance.new("Folder"); ESPFolder.Name = "ESP"; ESPFolder.Parent = Gui
local TracerLayer = Instance.new("Frame")
TracerLayer.Name = "Tracers"; TracerLayer.BackgroundTransparency = 1; TracerLayer.Size = UDim2.fromScale(1, 1)
TracerLayer.Active = false; TracerLayer.Parent = Gui

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
-- DANGER ALERT (colt dreapta-sus, mai multe alerte in stiva)
local DangerHolder = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
    Size = UDim2.fromOffset(420, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, Gui)
new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder }, DangerHolder)
local lastDanger, dangerOrder = {}, 0

-- gaseste camera/usa in care se afla entitatea
local function roomOf(inst)
    if inst then
        local p = inst
        while p and p ~= Workspace do
            local par = p.Parent
            if par then
                local pl = par.Name:lower()
                for _, f in ipairs(CFG.RoomFolderNames) do
                    if pl == f:lower() then
                        local num = p.Name:match("%d+")
                        return num or p.Name, "in"
                    end
                end
            end
            if tonumber(p.Name) then return p.Name, "in" end
            p = p.Parent
        end
    end
    local gd = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
    local lr = gd and gd:FindFirstChild("LatestRoom")
    if lr and lr.Value ~= nil then return tostring(lr.Value), "near" end
end

local function dangerText(name, inst)
    local txt = tostring(name)
    local room, mode = roomOf(inst)
    if room then
        txt = txt .. (mode == "in" and " found in door " or " spawned near door ") .. room
    else
        txt = txt .. " spawned"
    end
    local r = root()
    if r and inst then
        local part = inst:IsA("BasePart") and inst
            or (inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)))
        if part then txt = txt .. string.format("  (%d m)", math.floor((part.Position - r.Position).Magnitude)) end
    end
    return txt
end

local function showDanger(name, inst)
    if not S.dangerAlert then return end
    if os.clock() - (lastDanger[name] or 0) < CFG.DangerCooldown then return end
    lastDanger[name] = os.clock()
    dangerOrder = dangerOrder + 1
    local row = new("Frame", { Size = UDim2.fromOffset(420, 70), BackgroundColor3 = Color3.fromRGB(55, 10, 14),
        BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = dangerOrder }, DangerHolder)
    corner(row, 8)
    local st = stroke(row, T.accent, 3)
    st.Transparency = 1
    local t1 = new("TextLabel", { Text = "!! DANGER DETECTED !!", Font = FONTB, TextSize = 22,
        TextColor3 = Color3.fromRGB(255, 70, 80), BackgroundTransparency = 1, TextTransparency = 1,
        Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 28), TextXAlignment = Enum.TextXAlignment.Left }, row)
    local t2 = new("TextLabel", { Text = dangerText(name, inst), Font = FONTB, TextSize = 17, TextColor3 = T.text,
        BackgroundTransparency = 1, TextTransparency = 1, Position = UDim2.fromOffset(14, 38),
        Size = UDim2.new(1, -28, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
    tw(row, 0.2, { BackgroundTransparency = 0 }):Play()
    tw(st, 0.2, { Transparency = 0 }):Play()
    tw(t1, 0.2, { TextTransparency = 0 }):Play()
    tw(t2, 0.2, { TextTransparency = 0 }):Play()
    task.delay(6, function()
        if not row.Parent then return end
        tw(row, 0.3, { BackgroundTransparency = 1 }):Play()
        tw(st, 0.3, { Transparency = 1 }):Play()
        tw(t1, 0.3, { TextTransparency = 1 }):Play()
        tw(t2, 0.3, { TextTransparency = 1 }):Play()
        task.delay(0.35, function() row:Destroy() end)
    end)
end

-- NOTIFICARI (colt dreapta-jos): iteme aproape
local NoteHolder = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.fromOffset(280, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, Gui)
new("UIListLayout", { Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }, NoteHolder)
local noteOrder = 0
local function pushNote(text, color)
    noteOrder = noteOrder + 1
    local row = new("Frame", { Size = UDim2.fromOffset(280, 28), BackgroundColor3 = T.bg, BackgroundTransparency = 1,
        BorderSizePixel = 0, LayoutOrder = noteOrder }, NoteHolder)
    corner(row, 6)
    local st = stroke(row, color or T.accent, 1.5)
    st.Transparency = 1
    local lab = new("TextLabel", { Text = text, Font = FONTB, TextSize = 12, TextColor3 = color or T.text,
        BackgroundTransparency = 1, TextTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
    tw(row, 0.2, { BackgroundTransparency = 0.1 }):Play()
    tw(st, 0.2, { Transparency = 0 }):Play()
    tw(lab, 0.2, { TextTransparency = 0 }):Play()
    task.delay(4, function()
        if not row.Parent then return end
        tw(row, 0.3, { BackgroundTransparency = 1 }):Play()
        tw(st, 0.3, { Transparency = 1 }):Play()
        tw(lab, 0.3, { TextTransparency = 1 }):Play()
        task.delay(0.35, function() row:Destroy() end)
    end)
end

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
    if S[key] then render(true) end
    sw.MouseButton1Click:Connect(function() Registry[key].set(not S[key]) end)
    return c
end

local SliderReg = {}
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
    local obj = { set = setValue, get = function() return current end }
    SliderReg[label] = obj
    return obj
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
    if S.fov and not S.zoomHeld and Camera.FieldOfView ~= V.fov then Camera.FieldOfView = V.fov end
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
local ITEM_RED = Color3.fromRGB(255, 40, 40)
local ESPColors = {
    npc = Color3.fromRGB(120, 255, 140),      -- entitati: verde deschis
    player = Color3.fromRGB(80, 170, 255),
    obj = Color3.fromRGB(255, 220, 70),
    item = ITEM_RED, key = ITEM_RED, coin = ITEM_RED, chest = ITEM_RED,
    door = Color3.fromRGB(255, 220, 70), fakedoor = Color3.fromRGB(190, 190, 190),
    puzzle = Color3.fromRGB(255, 150, 30), hide = Color3.fromRGB(190, 120, 255), trap = Color3.fromRGB(255, 110, 40),
}
local CatFlag = { npc = "espNPC", player = "espPlayers", obj = "espObj",
    item = "espItems", key = "espKeys", coin = "espCoins", chest = "espChests",
    door = "espDoors", fakedoor = "espDoors", puzzle = "espPuzzle", hide = "espHide", trap = "espTraps" }
local ItemOrder = { "coin", "key", "chest", "puzzle", "item", "hide" }
local function itemCat(name)
    name = name:lower()
    for _, cat in ipairs(ItemOrder) do
        for _, k in ipairs(CFG.ItemKeywords[cat] or {}) do
            if name:find(k, 1, true) then return cat end
        end
    end
end
local function isEntityName(name)
    name = name:lower()
    for _, x in ipairs(CFG.EntityExclude) do
        if name:find(x, 1, true) then return false end
    end
    for _, n in ipairs(CFG.EntityNames) do
        if name:find(n:lower(), 1, true) then return true end
    end
    return false
end
local function entityFamily(name)
    local l = name:lower()
    for _, n in ipairs(CFG.EntityNames) do
        if l:find(n:lower(), 1, true) then return n:sub(1, 1):upper() .. n:sub(2) end
    end
    return name
end
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
local function validItem(d)
    local l = d.Name:lower()
    for _, x in ipairs(CFG.ItemExclude) do if l:find(x, 1, true) then return false end end
    if d:IsA("Tool") then return true end
    if d:IsA("Model") then
        local ok, sz = pcall(function() return d:GetExtentsSize() end)
        if ok and sz.Magnitude > CFG.ItemMaxSize then return false end
    elseif d:IsA("BasePart") then
        if d.Size.Magnitude > CFG.ItemMaxSize then return false end
    end
    local hasPrompt = d:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
        or d:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
    if hasPrompt then return true end       -- interactiv: il accept si daca e invizibil (ascuns in sertar)
    if CFG.RequirePromptForItems then return false end
    return not (d:IsA("BasePart") and d.Transparency >= 0.95)
end

local function catEnabled(cat)
    if not S.esp then return false end
    return S[CatFlag[cat]] == true
end

local function removeESP(inst)
    local e = ESPEntries[inst]
    if not e then return end
    if e.gui then e.gui:Destroy() end
    if e.hl then e.hl:Destroy() end
    if e.box then e.box:Destroy() end
    if e.tracer then e.tracer:Destroy() end
    ESPEntries[inst] = nil
end
local function addESP(inst, cat, displayName)
    if ESPEntries[inst] then return end
    local part = anyPart(inst); if not part then return end
    local gui = new("BillboardGui", { Adornee = part, AlwaysOnTop = true, Size = UDim2.fromOffset(180, 34),
        StudsOffset = Vector3.new(0, 2.5, 0), ResetOnSpawn = false }, ESPFolder)
    local lab = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONTB, TextSize = 12,
        TextColor3 = ESPColors[cat], TextStrokeTransparency = 0.3, Text = displayName }, gui)
    local hl
    if cat ~= "obj" and (inst:IsA("Model") or inst:IsA("BasePart")) then
        local strong = (cat == "npc")
        hl = new("Highlight", { Adornee = inst, FillColor = ESPColors[cat],
            FillTransparency = strong and 0.3 or 0.65, OutlineColor = ESPColors[cat], OutlineTransparency = 0,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, ESPFolder)
    end
    if cat == "npc" then lab.TextSize = 15 end
    local box = new("SelectionBox", { Adornee = inst, Color3 = ESPColors[cat], SurfaceColor3 = ESPColors[cat],
        LineThickness = (cat == "npc") and 0.07 or 0.03, Visible = false }, ESPFolder)
    local tracer = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = ESPColors[cat],
        BorderSizePixel = 0, Visible = false, Size = UDim2.fromOffset(0, 1) }, TracerLayer)
    ESPEntries[inst] = { inst = inst, cat = cat, part = part, gui = gui, label = lab, hl = hl, box = box, tracer = tracer, name = displayName }
end

local Known = {}            -- inst -> {cat, name}  (registru incremental, fara rescanari complete)
local ObjectiveCache = {}

local function charAncestor(inst)
    local p = inst
    while p and p ~= Workspace do
        if p:IsA("Model") and Players:GetPlayerFromCharacter(p) then return true end
        p = p.Parent
    end
    return false
end

-- numarul de pe placuta usii (ex "0004") -> "Door 4". Fara placuta cu numar = nu e usa oficiala.
local function plateNumber(root_)
    for _, t in ipairs(root_:GetDescendants()) do
        if t:IsA("TextLabel") or t:IsA("TextBox") then
            local n = t.Text:match("^%s*(%d%d%d%d?)%s*$")
            if n then return tonumber(n) end
        end
    end
end
local function doorModelOf(inst)
    local node, lvl, fallback = inst, 0, nil
    while node and node ~= Workspace and lvl < 7 do
        if node:IsA("Model") then
            local ln = node.Name:lower()
            if not lowerHas(ln, CFG.DoorExclude) then
                if ln:find("door", 1, true) then return node end
                if not fallback then fallback = node end
            end
        end
        node = node.Parent
        lvl = lvl + 1
    end
    return fallback
end

-- returneaza inst, cat, nume (sau nil)
local function classify(d)
    if d:IsA("TextLabel") then
        local n = d.Text:match("^%s*(%d%d%d%d?)%s*$")
        if n then
            local dm = doorModelOf(d)
            if dm and not charAncestor(dm) then
                local okSz, sz = pcall(function() return dm:GetExtentsSize() end)
                if okSz and sz.Magnitude <= 30 then
                    if lowerHas(dm.Name, CFG.FakeDoorKeywords) then return dm, "fakedoor", "FAKE DOOR" end
                    return dm, "door", "Door " .. tostring(tonumber(n))
                end
            end
        end
        return
    end
    if d:IsA("Humanoid") then
        local m = d.Parent
        if m and m:IsA("Model") and not charAncestor(m) then return m, "npc", m.Name end
        return
    end
    if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
        local tgt = d.Parent
        if not tgt or charAncestor(tgt) then return end
        -- cauta (max 3 nivele in sus) un nod cu nume de item -> rosu
        local node, lvl = tgt, 0
        while node and node ~= Workspace and lvl < 3 do
            local ic = itemCat(node.Name)
            if ic and not lowerHas(node.Name, CFG.ItemExclude) then return node, ic, node.Name end
            node = node.Parent; lvl = lvl + 1
        end
        if d:IsA("ProximityPrompt") and d.ObjectText ~= "" then
            local ic = itemCat(d.ObjectText)
            if ic then return tgt, ic, d.ObjectText end
        end
        -- obiectiv generic (galben), doar daca nu e gunoi
        local mdl = tgt:FindFirstAncestorOfClass("Model")
        local obj = (mdl and mdl ~= Workspace) and mdl or tgt
        if lowerHas(obj.Name, CFG.ObjectiveExclude) or lowerHas(tgt.Name, CFG.ObjectiveExclude) then return end
        if inList(obj.Name, CFG.ObjectiveExactNames) or lowerHas(obj.Name, CFG.ObjectiveKeywords) then
            return obj, "obj", obj.Name
        end
        return
    end
    if d:IsA("Model") or d:IsA("Tool") or d:IsA("BasePart") then
        if d:IsA("Model") and isEntityName(d.Name) then
            if charAncestor(d) then return end
            return d, "npc", d.Name
        end
        if (d:IsA("Model") or d:IsA("BasePart")) and lowerHas(d.Name, CFG.TrapKeywords) and not charAncestor(d) then
            local okT, szT
            if d:IsA("Model") then okT, szT = pcall(function() return d:GetExtentsSize().Magnitude end)
            else okT, szT = true, d.Size.Magnitude end
            if okT and szT <= 30 and not lowerHas(d.Name, CFG.DoorExclude) then return d, "trap", d.Name end
        end
        if d:IsA("Model") then
            local ln = d.Name:lower()
            if ln:find("door", 1, true) and not lowerHas(ln, CFG.DoorExclude) and not charAncestor(d) then
                local okSz, sz = pcall(function() return d:GetExtentsSize() end)
                if okSz and sz.Magnitude <= 30 then
                    local fake = false
                    local node, lvl = d, 0
                    while node and node ~= Workspace and lvl < 3 do
                        if lowerHas(node.Name, CFG.FakeDoorKeywords) then fake = true; break end
                        node = node.Parent
                        lvl = lvl + 1
                    end
                    if fake then return d, "fakedoor", "FAKE DOOR" end
                    local num = plateNumber(d)
                    if num then return d, "door", "Door " .. tostring(num) end
                end
            end
        end
        if not d:IsA("BasePart") and inList(d.Name, CFG.NPCExactNames) and not charAncestor(d) then
            return d, "npc", d.Name
        end
        local ic = itemCat(d.Name)
        if ic and not d:FindFirstChildOfClass("Humanoid") and validItem(d) and not charAncestor(d) then
            return d, ic, d.Name
        end
    end
end

local function register(d)
    local inst, cat, name = classify(d)
    if inst and not Known[inst] then Known[inst] = { cat = cat, name = name } end
end

local scanning, scannedOnce = false, false
local function fullScan()
    if scanning then return end
    scanning, scannedOnce = true, true
    task.spawn(function()
        local list = Workspace:GetDescendants()
        for i, d in ipairs(list) do
            pcall(register, d)
            if i % 600 == 0 then task.wait() end     -- scanare pe felii: fara freeze
        end
        scanning = false
    end)
end
connect(Workspace.DescendantAdded, function(d)
    task.defer(function() if d.Parent then pcall(register, d) end end)
end)
connect(Workspace.DescendantRemoving, function(d) Known[d] = nil end)

local BlockCats = { npc = true, item = true, key = true, coin = true, puzzle = true }
local function knownAncestor(inst)
    local p = inst.Parent
    while p and p ~= Workspace do
        local k = Known[p]
        if k and BlockCats[k.cat] then return true end
        p = p.Parent
    end
    return false
end

local function rebuildObjectiveCache()
    table.clear(ObjectiveCache)
    for inst, info in pairs(Known) do
        if inst.Parent and info.cat ~= "npc" then ObjectiveCache[inst] = info.name end
    end
end

local function refreshESP()
    for inst, e in pairs(ESPEntries) do
        if not inst:IsDescendantOf(Workspace) or not catEnabled(e.cat) then removeESP(inst) end
    end
    if not S.esp then return end
    if catEnabled("player") then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then addESP(p.Character, "player", p.DisplayName) end
        end
    end
    for inst, info in pairs(Known) do
        if not inst.Parent then
            Known[inst] = nil
        elseif catEnabled(info.cat) and not ESPEntries[inst] and not knownAncestor(inst) then
            addESP(inst, info.cat, info.name)
        end
    end
end

local NotifyCats = { item = true, key = true, puzzle = true }
local notified = setmetatable({}, { __mode = "k" })
local noteAcc = 0
connect(RunService.Heartbeat, function(dt)
    if not S.nearNotify then return end
    noteAcc = noteAcc + dt
    if noteAcc < 0.5 then return end
    noteAcc = 0
    local r = root(); if not r then return end
    for inst, info in pairs(Known) do
        if NotifyCats[info.cat] and inst.Parent then
            local part = anyPart(inst)
            if part then
                local dist = (part.Position - r.Position).Magnitude
                if dist <= CFG.NotifyDistance then
                    if not notified[inst] then
                        notified[inst] = true
                        pushNote(string.format("Near: %s  (%d m)", info.name, math.floor(dist)), ESPColors[info.cat])
                    end
                elseif dist > CFG.NotifyDistance + 10 then
                    notified[inst] = nil
                end
            end
        end
    end
end)

local lastRefresh = 0
connect(Workspace.DescendantAdded, function(d)
    task.defer(function()
        if not d.Parent then return end
        local entName, entInst
        if d:IsA("Model") and isEntityName(d.Name) then
            entName, entInst = entityFamily(d.Name), d
        elseif d:IsA("Humanoid") then
            local m = d.Parent
            if m and m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then entName, entInst = m.Name, m end
        end
        if entName then
            local r = root()
            local part = entInst:IsA("BasePart") and entInst or entInst:FindFirstChildWhichIsA("BasePart", true)
            local near = true
            if r and part then near = (part.Position - r.Position).Magnitude <= V.dangerDist end
            if near then showDanger(entName, entInst) end
            if S.esp and os.clock() - lastRefresh > 0.3 then
                lastRefresh = os.clock()
                task.wait(0.1)
                pcall(refreshESP)
            end
        end
    end)
end)

connect(RunService.RenderStepped, function()
    local vp = Camera.ViewportSize
    local origin = Vector2.new(vp.X / 2, vp.Y)
    for _, e in pairs(ESPEntries) do
        local ln = e.tracer
        if ln then
            local shown = false
            if S.esp and S.espTracers and e.part and e.part.Parent then
                local pos, onScreen = Camera:WorldToViewportPoint(e.part.Position)
                if onScreen and pos.Z > 0 then
                    local target = Vector2.new(pos.X, pos.Y)
                    local delta = target - origin
                    ln.Size = UDim2.fromOffset(delta.Magnitude, 1)
                    ln.Position = UDim2.fromOffset((origin.X + target.X) / 2, (origin.Y + target.Y) / 2)
                    ln.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                    shown = true
                end
            end
            ln.Visible = shown
        end
    end
end)

local LootCats = { item = true, key = true, coin = true, puzzle = true, chest = true }
local espAcc, scanAcc = 0, 0
connect(RunService.Heartbeat, function(dt)
    if not S.esp then return end
    espAcc += dt; scanAcc += dt
    if scanAcc >= 1.0 then scanAcc = 0; pcall(refreshESP) end
    if espAcc >= 0.1 then
        espAcc = 0
        local cp = Camera.CFrame.Position
        local rb = S.rainbow and Color3.fromHSV((os.clock() * 0.3) % 1, 1, 1) or nil
        local ranked = {}
        for inst, e in pairs(ESPEntries) do
            if e.part and e.part.Parent then
                local dist = (e.part.Position - cp).Magnitude
                e.gui.Enabled = dist <= CFG.ESPMaxDistance
                e._d = dist
                if e.cat ~= "npc" and e.cat ~= "player" and e.gui.Enabled then ranked[#ranked + 1] = e end
                if e.hl then e.hl.Enabled = e.gui.Enabled end
                local col = rb or ESPColors[e.cat]
                if S.rainbowLoot and LootCats[e.cat] then
                    col = Color3.fromHSV((os.clock() * 0.3 + #e.name * 0.07) % 1, 1, 1)
                end
                if e.hl then e.hl.FillTransparency = S.espFill and (e.cat == "npc" and 0.3 or 0.65) or 1 end
                e.label.TextColor3 = col
                e.label.TextSize = V.espText + (e.cat == "npc" and 3 or 0)
                if e.hl then e.hl.FillColor = col; e.hl.OutlineColor = col end
                if e.box then e.box.Color3 = col end
                if e.tracer then e.tracer.BackgroundColor3 = col end
                local txt = S.espDist and string.format("%s\n[%d m]", e.name, math.floor(dist)) or e.name
                if S.espHealth then
                    local hmn = e.inst:IsA("Model") and e.inst:FindFirstChildOfClass("Humanoid")
                    if hmn then txt = txt .. string.format("  HP %d/%d", math.floor(hmn.Health), math.floor(hmn.MaxHealth)) end
                end
                e.label.Text = txt
                if e.box then e.box.Visible = (S.espBox or e.cat == "npc") and e.gui.Enabled end
            else
                removeESP(inst)
            end
        end
        if S.espNearest and #ranked > CFG.NearestLimit then
            table.sort(ranked, function(a, b) return a._d < b._d end)
            for i = CFG.NearestLimit + 1, #ranked do
                local e = ranked[i]
                e.gui.Enabled = false
                if e.hl then e.hl.Enabled = false end
                if e.box then e.box.Visible = false end
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
    rebuildObjectiveCache()
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
    if on then
        if not scannedOnce then fullScan() end
        pcall(refreshESP)
    else
        for i in pairs(ESPEntries) do removeESP(i) end
    end
end, 34)
local function espSub(key, label)
    addToggle(PVisual, key, "   - " .. label, function() if S.esp then pcall(refreshESP) end end)
end
espSub("espNPC", "Entities (verde)")
espSub("espPlayers", "Players")
espSub("espObj", "Objectives")
espSub("espItems", "Items (rosu)")
espSub("espKeys", "Door Keys (rosu)")
espSub("espCoins", "Coins (rosu)")
espSub("espChests", "Chests (rosu)")
espSub("espDoors", "Doors (galben) + fake")
espSub("espPuzzle", "Puzzle: carti / becuri")
espSub("espHide", "Hiding spots")
espSub("espTraps", "Traps / capcane")
espSub("espBox", "Boxes")
espSub("espTracers", "Tracers")
espSub("espHealth", "Health (HP)")
local cDanger = addToggle(PVisual, "dangerAlert", "Danger Alert (entitati)", function() end, 66)
addSlider(cDanger, 34, "Danger Distance", 50, 1000, V.dangerDist, 10, function(v) V.dangerDist = v end)
addToggle(PVisual, "rainbow", "Rainbow ESP", function() end)
addToggle(PVisual, "rainbowLoot", "Loot ESP: Rainbow (toate itemele)", function(on)
    if on then
        for _, k in ipairs({ "esp", "espItems", "espKeys", "espCoins", "espPuzzle", "espChests" }) do
            if Registry[k] then Registry[k].set(true) end
        end
    end
end)
addToggle(PVisual, "espDist", "ESP: arata distanta", function() end)
addToggle(PVisual, "espNearest", "ESP: doar cele mai apropiate (25)", function() end)
addToggle(PVisual, "espFill", "ESP: umplere (fill)", function() end)
local cNear = addToggle(PVisual, "nearNotify", "Item Notifier (cand ajungi aproape)", function(on)
    if on then
        fullScan()
        pushNote("Item Notifier ON", T.on)
    end
end, 66)
addSlider(cNear, 34, "Notify Distance", 5, 80, CFG.NotifyDistance, 1, function(v) CFG.NotifyDistance = v end)
local cESPset = card(PVisual, 86)
addSlider(cESPset, 6, "ESP Render Distance", 100, 5000, CFG.ESPMaxDistance, 50, function(v) CFG.ESPMaxDistance = v end)
addSlider(cESPset, 46, "ESP Text Size", 8, 24, V.espText, 1, function(v) V.espText = v end)

-- Third Person
local tpOrigCam
local function applyTP()
    pcall(function()
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = V.tpCam + 1
        LP.CameraMinZoomDistance = V.tpCam
        local h = hum()
        if Camera.CameraType ~= Enum.CameraType.Custom then Camera.CameraType = Enum.CameraType.Custom end
        if h and Camera.CameraSubject ~= h then Camera.CameraSubject = h end
        local c = char()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
            end
        end
    end)
end
local cTPV = addToggle(PVisual, "thirdPerson", "Third Person", function(on)
    if on then
        tpOrigCam = { LP.CameraMode, LP.CameraMinZoomDistance, LP.CameraMaxZoomDistance }
        applyTP()
    elseif tpOrigCam then
        pcall(function()
            LP.CameraMinZoomDistance = tpOrigCam[2]
            LP.CameraMaxZoomDistance = tpOrigCam[3]
            LP.CameraMode = tpOrigCam[1]
        end)
        tpOrigCam = nil
    end
end, 66)
addSlider(cTPV, 34, "Camera Distance", 6, 40, V.tpCam, 1, function(v)
    V.tpCam = v
    if S.thirdPerson then applyTP() end
end)
pcall(function() RunService:UnbindFromRenderStep("RM_TP") end)
RunService:BindToRenderStep("RM_TP", Enum.RenderPriority.Camera.Value + 1, function()
    if S.thirdPerson then applyTP() end
end)

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
local CatFlagSet = {}
for _, f in pairs(CatFlag) do CatFlagSet[f] = true end
local function disableAll()
    for _, key in ipairs(Order) do
        if S[key] and key ~= "espNPC" and key ~= "espPlayers" and key ~= "espObj" and not CatFlagSet[key] then Registry[key].set(false) end
    end
    -- sub-toggles raman in starea lor, dar ESP master e oprit
end
addToggle(PUtil, "god", "God Mode (server, owner)", function(on)
    local r = game:GetService("ReplicatedStorage"):FindFirstChild("RM_DevGod")
    if r then r:FireServer(on) else warn("[RM DevMenu] RM_DevGod lipseste. Pune RM_GiveServer.lua in ServerScriptService.") end
end)

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

local StatsLabel = new("TextLabel", { Size = UDim2.fromOffset(170, 22), Position = UDim2.new(0, 10, 1, -34),
    BackgroundColor3 = T.bg, BackgroundTransparency = 0.25, BorderSizePixel = 0, Font = FONTB, TextSize = 12,
    TextColor3 = T.text, Text = "", Visible = false }, Gui)
corner(StatsLabel, 6)
local fpsAcc, fpsFrames = 0, 0
connect(RunService.RenderStepped, function(dt)
    if not S.statsHud then return end
    fpsAcc = fpsAcc + dt; fpsFrames = fpsFrames + 1
    if fpsAcc >= 0.5 then
        local ping = 0
        pcall(function() ping = math.floor(LP:GetNetworkPing() * 1000) end)
        StatsLabel.Text = string.format("FPS %d  |  Ping %d ms", math.floor(fpsFrames / fpsAcc), ping)
        fpsAcc, fpsFrames = 0, 0
    end
end)
connect(LP.Idled, function()
    if not S.antiAfk then return end
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)
local zoomPrev
connect(RunService.RenderStepped, function()
    local held = S.zoom and UIS:IsKeyDown(Enum.KeyCode.Z) and not UIS:GetFocusedTextBox()
    if held then
        if not S.zoomHeld then S.zoomHeld = true; zoomPrev = Camera.FieldOfView end
        Camera.FieldOfView = 20
    elseif S.zoomHeld then
        S.zoomHeld = false
        Camera.FieldOfView = (S.fov and V.fov) or zoomPrev or 70
    end
end)

section(PUtil, "EXTRA")
addToggle(PUtil, "statsHud", "Stats HUD (FPS / Ping)", function(on) StatsLabel.Visible = on end)
addToggle(PUtil, "antiAfk", "Anti-AFK", function() end)
addToggle(PUtil, "zoom", "Zoom (tine apasat Z)", function() end)

section(PUtil, "DEBUG")
addButton(PUtil, "Print Nearby Names (40m)", function()
    local r = root(); if not r then return end
    local n = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if n >= 150 then break end
        if d:IsA("Model") or d:IsA("Tool") or d:IsA("BasePart") then
            local part = anyPart(d)
            if part and (part.Position - r.Position).Magnitude <= 40 then
                local prompt = d:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
                print(string.format("[RM] %s | %s | prompt=%s | %s", d.ClassName, d.Name, tostring(prompt), d:GetFullName()))
                n += 1
            end
        end
    end
    print("[RM] gata: " .. n .. " obiecte (max 150)")
end)

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
---------------------------------------------------------------------
-- SAVE / LOAD SETTINGS (necesita writefile/readfile in executor)
---------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local SAVE_FILE = "RM_DevMenu_settings.json"
local function canFS()
    return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end
local function saveSettings()
    if not canFS() then pushNote("Executorul nu suporta writefile", T.accent) return end
    local data = { toggles = {}, sliders = {} }
    for _, key in ipairs(Order) do
        if key ~= "god" then data.toggles[key] = S[key] end
    end
    for label, sl in pairs(SliderReg) do data.sliders[label] = sl.get() end
    local ok, err = pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(data)) end)
    pushNote(ok and "Setari salvate" or ("Eroare salvare: " .. tostring(err)), ok and T.on or T.accent)
end
local function loadSettings(silent)
    if not canFS() then
        if not silent then pushNote("Executorul nu suporta readfile", T.accent) end
        return
    end
    local ok, raw = pcall(function() return isfile(SAVE_FILE) and readfile(SAVE_FILE) or nil end)
    if not ok or not raw then
        if not silent then pushNote("Nu exista setari salvate", T.dim) end
        return
    end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end
    for label, v in pairs(data.sliders or {}) do
        if SliderReg[label] and type(v) == "number" then pcall(SliderReg[label].set, v) end
    end
    for key, v in pairs(data.toggles or {}) do
        if Registry[key] and type(v) == "boolean" then pcall(Registry[key].set, v) end
    end
    if not silent then pushNote("Setari incarcate", T.on) end
end
section(PUtil, "SETARI")
addButton(PUtil, "Save Settings", saveSettings)
addButton(PUtil, "Load Settings", function() loadSettings(false) end)
addButton(PUtil, "Delete Saved Settings", function()
    if canFS() and typeof(delfile) == "function" and isfile(SAVE_FILE) then
        pcall(delfile, SAVE_FILE)
        pushNote("Setari sterse", T.dim)
    end
end)
task.defer(function() task.wait(0.8); loadSettings(true) end)   -- incarca automat la pornire

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
        pcall(function() RunService:UnbindFromRenderStep("RM_TP") end)
        Gui:Destroy()
    end
end
