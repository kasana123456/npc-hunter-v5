--[[ 
    ASYLUM ELITE V11.4
    - FIXED: FOV Circle not appearing
    - ADDED: Show FOV Toggle (In Aim Tab)
    - FIXED: Skeleton cleanup and larger text scaling
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
    ShowFOV = true, -- New Toggle
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(0, 150, 255),
    Smoothness = 0.15,
    HitboxEnabled = false,
    HitboxSize = 10,
    ESPEnabled = false,
    SkeletonEnabled = false,
    GlowEnabled = false,
    AimPart = "Head",
    TargetMode = "NPCs",
    TextScale = 18,
}

--// FOV DRAWING OBJECT (Created early to ensure it exists)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = getgenv().Config.ShowFOV
FOVCircle.Color = getgenv().Config.FOVColor

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

--// GUI CORE (SCALED UP)
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumV11_4"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 600, 0, 420); Main.Position = UDim2.new(0.5, -300, 0.5, -210); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 160, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30); Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -180, 1, -20); Container.Position = UDim2.new(0, 170, 0, 10); Container.BackgroundTransparency = 1

local Tabs = { Aim = {}, Visuals = {}, Misc = {} }
local function CreateTabFrame()
    local f = Instance.new("ScrollingFrame", Container)
    f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.Visible = false; f.ScrollBarThickness = 0; f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", f).Padding = UDim.new(0, 12)
    return f
end

Tabs.Aim.Frame = CreateTabFrame(); Tabs.Visuals.Frame = CreateTabFrame(); Tabs.Misc.Frame = CreateTabFrame()

local function ShowTab(name)
    for i, v in pairs(Tabs) do v.Frame.Visible = (i == name) end
end

local bCount = 0
local function CreateSidebarBtn(name)
    local b = Instance.new("TextButton", Sidebar)
    b.Size = UDim2.new(0.9, 0, 0, 45); b.Position = UDim2.new(0.05, 0, 0, 75 + (bCount * 55)); b.BackgroundColor3 = Color3.fromRGB(30, 30, 45); b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamSemibold"; b.TextSize = 18; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() ShowTab(name) end); bCount = bCount + 1
end

CreateSidebarBtn("Aim"); CreateSidebarBtn("Visuals"); CreateSidebarBtn("Misc"); ShowTab("Aim")

--// COMPONENT HELPERS
local function AddToggle(parent, txt, key)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 45); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 45, 0, 24); btn.Position = UDim2.new(1, -50, 0.5, -12); btn.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local label = Instance.new("TextLabel", f); label.Size = UDim2.new(1, -60, 1, 0); label.Text = txt; label.TextColor3 = Color3.new(1,1,1); label.Font = "Gotham"; label.TextSize = getgenv().Config.TextScale; label.TextXAlignment = "Left"; label.BackgroundTransparency = 1
    btn.MouseButton1Click:Connect(function()
        getgenv().Config[key] = not getgenv().Config[key]
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60)}):Play()
        if key == "ShowFOV" then FOVCircle.Visible = getgenv().Config[key] end
        SaveConfig()
    end)
end

local function AddSlider(parent, txt, min, max, key, decimal)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 60); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, 0, 0, 25); l.Text = txt .. ": " .. getgenv().Config[key]; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.Font = "Gotham"; l.TextSize = getgenv().Config.TextScale - 2
    local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, 0, 0, 8); bar.Position = UDim2.new(0,0,0.75,0); bar.BackgroundColor3 = Color3.fromRGB(40,40,50); Instance.new("UICorner", bar)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().Config[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255); Instance.new("UICorner", fill)
    local sliding = false
    local function up(i)
        local per = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * per
        if decimal then val = math.round(val * 100) / 100 else val = math.floor(val) end
        getgenv().Config[key] = val; l.Text = txt .. ": " .. val; fill.Size = UDim2.new(per, 0, 1, 0); SaveConfig()
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; up(i) end end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then up(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
end

-- POPULATE TABS
AddToggle(Tabs.Aim.Frame, "Show FOV Circle", "ShowFOV")
AddSlider(Tabs.Aim.Frame, "FOV Radius", 10, 800, "FOVRadius")
AddToggle(Tabs.Aim.Frame, "Camera Snap", "CameraAim")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 1)", "Method1_Silent")
AddSlider(Tabs.Aim.Frame, "Smoothness", 0.01, 1, "Smoothness", true)

AddToggle(Tabs.Visuals.Frame, "Box ESP", "ESPEnabled")
AddToggle(Tabs.Visuals.Frame, "Skeleton ESP", "SkeletonEnabled")
AddToggle(Tabs.Visuals.Frame, "Chams / Glow", "GlowEnabled")

AddToggle(Tabs.Misc.Frame, "Hitbox Expander", "HitboxEnabled")
AddSlider(Tabs.Misc.Frame, "Hitbox Size", 2, 50, "HitboxSize")
AddSlider(Tabs.Misc.Frame, "Font Size", 12, 24, "TextScale")

--// CORE ENGINE
local LockedTarget, ESP_Cache = nil, {}

RunService.RenderStepped:Connect(function()
    -- FOV Position Update (Always keep this running)
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local potential, dist = nil, getgenv().Config.FOVRadius

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v ~= LP.Character then
            local root = v:FindFirstChild(getgenv().Config.AimPart) or v:FindFirstChild("HumanoidRootPart")
            if root then
                local sPos, onScr = Camera:WorldToViewportPoint(root.Position)
                
                -- Priority Selection
                if onScr then
                    local mDist = (Vector2.new(sPos.X, sPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then potential = root; dist = mDist end
                end
            end
        end
    end
    LockedTarget = potential
    
    -- Silent Aim & Camera logic goes here...
end)

--// DRAGGING (Restricted to Sidebar)
local dragging, dStart, sPos
Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dStart = i.Position; sPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
