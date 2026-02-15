--[[ 
    ASYLUM ELITE V11.0 (PREMIUM UI OVERHAUL)
    - NEW: Modern Sidebar UI with Tabs
    - NEW: Animated UI Transitions
    - FEATURE: Hybrid Aimbot, Skeleton ESP, Hitbox Expander
    - FEATURE: Yellow Locked-Target Priority
    - TOGGLE: F5 | LOCK: Right Click
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

--// Global Settings
getgenv().Config = {
    CameraAim = false,
    Method1_Silent = false,
    Method2_Silent = false,
    WallCheck = true,
    TeamCheck = false,
    HitboxEnabled = false,
    ESPEnabled = false,
    SkeletonEnabled = false,
    GlowEnabled = false,
    FOVRadius = 150,
    Smoothness = 0.15,
    HitboxSize = 10,
    VisualTransparency = 0.7,
    AimPart = "Head",
    TargetMode = "NPCs", 
}

--// CONFIG SYSTEM
local filename = "AsylumElite_V11.json"
local function SaveConfig() pcall(function() writefile(filename, HttpService:JSONEncode(getgenv().Config)) end) end
local function LoadConfig()
    if isfile(filename) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(filename))
            for i, v in pairs(data) do getgenv().Config[i] = v end
        end)
    end
end
LoadConfig()

local lastChange, needsSave = tick(), false
task.spawn(function()
    while task.wait(1) do if needsSave and tick() - lastChange >= 1 then SaveConfig(); needsSave = false end end
end)
local function TriggerSave() lastChange = tick(); needsSave = true end

--// GUI CORE CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumV11"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 550, 0, 350)
Main.Position = UDim2.new(0.5, -275, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SidebarTitle = Instance.new("TextLabel", Sidebar)
SidebarTitle.Size = UDim2.new(1, 0, 0, 50)
SidebarTitle.Text = "ASYLUM"; SidebarTitle.TextColor3 = Color3.fromRGB(0, 150, 255); SidebarTitle.Font = Enum.Font.GothamBold; SidebarTitle.TextSize = 20; SidebarTitle.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -150, 1, -10)
Container.Position = UDim2.new(0, 145, 0, 5)
Container.BackgroundTransparency = 1

-- Tabs
local Tabs = { Aim = {}, Visuals = {}, Misc = {} }
local TabButtons = {}

local function CreateTabFrame(name)
    local f = Instance.new("ScrollingFrame", Container)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.ScrollBarThickness = 2
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local list = Instance.new("UIListLayout", f)
    list.Padding = UDim.new(0, 10)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return f
end

Tabs.Aim.Frame = CreateTabFrame("Aim")
Tabs.Visuals.Frame = CreateTabFrame("Visuals")
Tabs.Misc.Frame = CreateTabFrame("Misc")

local function ShowTab(name)
    for i, v in pairs(Tabs) do
        v.Frame.Visible = (i == name)
    end
end

-- Sidebar Button Logic
local buttonCount = 0
local function CreateSidebarBtn(name)
    local b = Instance.new("TextButton", Sidebar)
    b.Size = UDim2.new(0.9, 0, 0, 40)
    b.Position = UDim2.new(0.05, 0, 0, 60 + (buttonCount * 45))
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamSemibold; b.TextSize = 14
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() ShowTab(name) end)
    buttonCount = buttonCount + 1
end

CreateSidebarBtn("Aim")
CreateSidebarBtn("Visuals")
CreateSidebarBtn("Misc")
ShowTab("Aim") -- Default

--// NEW STYLED COMPONENTS
local function AddToggle(parent, txt, key)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.95, 0, 0, 40); f.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0, 35, 0, 20); btn.Position = UDim2.new(1, -40, 0.5, -10)
    btn.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60)
    btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local label = Instance.new("TextLabel", f)
    label.Size = UDim2.new(1, -50, 1, 0); label.Text = txt; label.TextColor3 = Color3.new(1,1,1); label.Font = Enum.Font.Gotham; label.TextXAlignment = "Left"; label.BackgroundTransparency = 1

    btn.MouseButton1Click:Connect(function()
        getgenv().Config[key] = not getgenv().Config[key]
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60)}):Play()
        TriggerSave()
    end)
end

local function AddSlider(parent, txt, min, max, key, decimal)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 50); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, 0, 0, 20); l.Text = txt .. ": " .. getgenv().Config[key]; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.Font = "Gotham"
    local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0,0,0.7,0); bar.BackgroundColor3 = Color3.fromRGB(40,40,50); Instance.new("UICorner", bar)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().Config[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255); Instance.new("UICorner", fill)
    
    local sliding = false
    local function up(i)
        local per = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * per
        if decimal then val = math.round(val * 100) / 100 else val = math.floor(val) end
        getgenv().Config[key] = val; l.Text = txt .. ": " .. val; fill.Size = UDim2.new(per, 0, 1, 0); TriggerSave()
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; up(i) end end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then up(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
end

-- Populate Aim Tab
AddToggle(Tabs.Aim.Frame, "Camera Snap", "CameraAim")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 1)", "Method1_Silent")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 2)", "Method2_Silent")
AddToggle(Tabs.Aim.Frame, "Wall Check", "WallCheck")
AddSlider(Tabs.Aim.Frame, "Smoothness", 0.01, 1, "Smoothness", true)
AddSlider(Tabs.Aim.Frame, "FOV Radius", 10, 800, "FOVRadius")

-- Populate Visuals Tab
AddToggle(Tabs.Visuals.Frame, "Box ESP", "ESPEnabled")
AddToggle(Tabs.Visuals.Frame, "Skeleton ESP", "SkeletonEnabled")
AddToggle(Tabs.Visuals.Frame, "Chams / Glow", "GlowEnabled")

-- Populate Misc Tab
AddToggle(Tabs.Misc.Frame, "Hitbox Expander", "HitboxEnabled")
AddSlider(Tabs.Misc.Frame, "Hitbox Size", 2, 50, "HitboxSize")

-- Target Switcher (In Aim Tab)
local modeBtn = Instance.new("TextButton", Tabs.Aim.Frame)
modeBtn.Size = UDim2.new(0.95, 0, 0, 35); modeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50); modeBtn.TextSize = 14; modeBtn.Font = "GothamBold"; Instance.new("UICorner", modeBtn)
local function updateModeUI()
    modeBtn.Text = "TARGETING: " .. getgenv().Config.TargetMode
    modeBtn.TextColor3 = (getgenv().Config.TargetMode == "NPCs" and Color3.new(0,1,0.5)) or (getgenv().Config.TargetMode == "Players" and Color3.new(0,0.6,1)) or Color3.new(1,0.3,0.3)
end
modeBtn.MouseButton1Click:Connect(function()
    local m = getgenv().Config.TargetMode
    getgenv().Config.TargetMode = (m == "NPCs" and "Players") or (m == "Players" and "All") or "NPCs"
    updateModeUI(); TriggerSave()
end)
updateModeUI()

--// CORE ENGINE (Unified Logic)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(0, 150, 255); FOVCircle.Visible = true

local LockedTarget = nil
local ESP_Cache = {}

local function CreateLine() local l = Drawing.new("Line"); l.Thickness = 1.5; l.Visible = false; return l end
local function CreateSkeleton() return { H2T = CreateLine(), T2LA = CreateLine(), T2RA = CreateLine(), T2LL = CreateLine(), T2RL = CreateLine() } end
local function CreateExtras(model)
    local d = { Box = Drawing.new("Square"), HL = Instance.new("Highlight"), Skel = CreateSkeleton() }
    d.Box.Thickness = 1; d.Box.Visible = false; d.Box.Color = Color3.new(1,1,1)
    d.HL.FillTransparency = 0.5; d.HL.OutlineColor = Color3.new(1,1,1); d.HL.Parent = model; d.HL.Enabled = false
    return d
end

local function IsValid(m)
    local hum = m:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or m == LP.Character then return false end
    local isP = Players:GetPlayerFromCharacter(m)
    local mode = getgenv().Config.TargetMode
    if mode == "NPCs" and isP then return false end
    if mode == "Players" and not isP then return false end
    return true
end

local function UpdateSkeleton(skel, char, color)
    local parts = {
        H = char:FindFirstChild("Head"), T = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
        LA = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"),
        RA = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"),
        LL = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"),
        RL = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
    }
    local function Connect(line, p1, p2)
        if p1 and p2 then
            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
            if vis1 and vis2 then
                line.From = Vector2.new(pos1.X, pos1.Y); line.To = Vector2.new(pos2.X, pos2.Y)
                line.Color = color; line.Visible = true; return
            end
        end
        line.Visible = false
    end
    Connect(skel.H2T, parts.H, parts.T); Connect(skel.T2LA, parts.T, parts.LA); Connect(skel.T2RA, parts.T, parts.RA); Connect(skel.T2LL, parts.T, parts.LL); Connect(skel.T2RL, parts.T, parts.RL)
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Radius = getgenv().Config.FOVRadius; FOVCircle.Position = UIS:GetMouseLocation()
    local potential, dist = nil, getgenv().Config.FOVRadius

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and IsValid(v) then
            local root = v:FindFirstChild(getgenv().Config.AimPart) or v:FindFirstChild("HumanoidRootPart")
            if root then
                if not ESP_Cache[v] then ESP_Cache[v] = CreateExtras(v) end
                local cache = ESP_Cache[v]
                local sPos, onScr = Camera:WorldToViewportPoint(root.Position)
                
                -- Hitboxes
                if getgenv().Config.HitboxEnabled then
                    root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
                    root.Transparency = 0.7; root.CanCollide = false
                else root.Size = Vector3.new(2,2,1); root.Transparency = 1 end

                -- Selection Logic
                if onScr and (#Camera:GetPartsObscuringTarget({root.Position}, {LP.Character, Camera}) == 0 or not getgenv().Config.WallCheck) then
                    local mDist = (Vector2.new(sPos.X, sPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then potential = root; dist = mDist end
                end
            end
        end
    end
    
    LockedTarget = potential
    
    -- Visuals Cleanup & Priority
    for model, cache in pairs(ESP_Cache) do
        if model.Parent == nil then ESP_Cache[model] = nil 
        else
            local isLocked = (LockedTarget and LockedTarget.Parent == model)
            local color = isLocked and Color3.new(1,1,0) or Color3.new(1,1,1)
            
            cache.HL.Enabled = (getgenv().Config.GlowEnabled or isLocked)
            cache.HL.FillColor = color
            
            if getgenv().Config.SkeletonEnabled then UpdateSkeleton(cache.Skel, model, color)
            else for _, l in pairs(cache.Skel) do l.Visible = false end end
            
            if getgenv().Config.ESPEnabled then
                local r = model:FindFirstChild("HumanoidRootPart")
                local sP, onS = Camera:WorldToViewportPoint(r.Position)
                if onS then
                    local scale = 1000 / sP.Z
                    cache.Box.Size = Vector2.new(scale, scale); cache.Box.Position = Vector2.new(sP.X - scale/2, sP.Y - scale/2)
                    cache.Box.Color = color; cache.Box.Visible = true
                else cache.Box.Visible = false end
            else cache.Box.Visible = false end
        end
    end

    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

--// DRAGGING
local dStart, sPos, dragging
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dStart = i.Position; sPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UIS.InputBegan:Connect(function(i, c) if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end 
if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)

--// METAMETHODS
local oldN; oldN = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    if not checkcaller() and getgenv().Config.Method1_Silent and LockedTarget and (m == "Raycast" or m:find("PartOnRay")) then
        local args = {...}
        if m == "Raycast" then args[2] = (LockedTarget.Position - args[1]).Unit * 1000
        else args[1] = Ray.new(Camera.CFrame.Position, (LockedTarget.Position - Camera.CFrame.Position).Unit * 1000) end
        return oldN(self, unpack(args))
    end
    return oldN(self, ...)
end)
local oldI; oldI = hookmetamethod(game, "__index", function(self, idx)
    if not checkcaller() and getgenv().Config.Method2_Silent and LockedTarget and self == Mouse and (idx == "Hit" or idx == "Target") then
        return (idx == "Hit" and LockedTarget.CFrame or LockedTarget)
    end
    return oldI(self, idx)
end)
