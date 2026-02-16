--[[ 
    ASYLUM ELITE V11.5 (Updated with Sliders)
    - ADDED: Slider Component for FOV, Smoothness, and Hitbox
    - RESTORED: Sidebar Title & Method 2 Silent Aim
    - FIXED: FOV Rendering & UI Scaling
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()
local TweenService = game:GetService("TweenService")

--// Global Settings
getgenv().Config = {
    CameraAim = false,
    Method1_Silent = false,
    Method2_Silent = false,
    WallCheck = true,
    ShowFOV = true,
    FOVRadius = 150,
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

--// FOV DRAWING
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Visible = true; FOVCircle.Color = Color3.fromRGB(0, 150, 255)

--// GUI CORE
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumV11_5"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 600, 0, 480); Main.Position = UDim2.new(0.5, -300, 0.5, -240); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 160, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30); Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local SidebarTitle = Instance.new("TextLabel", Sidebar)
SidebarTitle.Size = UDim2.new(1, 0, 0, 60); SidebarTitle.Text = "ASYLUM ELITE"; SidebarTitle.TextColor3 = Color3.fromRGB(0, 150, 255); SidebarTitle.Font = "GothamBold"; SidebarTitle.TextSize = 22; SidebarTitle.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -180, 1, -20); Container.Position = UDim2.new(0, 170, 0, 10); Container.BackgroundTransparency = 1

local Tabs = { Aim = {}, Visuals = {}, Misc = {} }
local function CreateTabFrame()
    local f = Instance.new("ScrollingFrame", Container)
    f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.Visible = false; f.ScrollBarThickness = 2; f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", f).Padding = UDim.new(0, 12)
    return f
end
Tabs.Aim.Frame = CreateTabFrame(); Tabs.Visuals.Frame = CreateTabFrame(); Tabs.Misc.Frame = CreateTabFrame()

local function ShowTab(name) for i, v in pairs(Tabs) do v.Frame.Visible = (i == name) end end
local bCount = 0
local function CreateSidebarBtn(name)
    local b = Instance.new("TextButton", Sidebar)
    b.Size = UDim2.new(0.9, 0, 0, 45); b.Position = UDim2.new(0.05, 0, 0, 75 + (bCount * 55)); b.BackgroundColor3 = Color3.fromRGB(30, 30, 45); b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamSemibold"; b.TextSize = 18; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() ShowTab(name) end); bCount = bCount + 1
end
CreateSidebarBtn("Aim"); CreateSidebarBtn("Visuals"); CreateSidebarBtn("Misc"); ShowTab("Aim")

--// COMPONENTS
local function AddToggle(parent, txt, key)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 45); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 45, 0, 24); btn.Position = UDim2.new(1, -50, 0.5, -12); btn.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local label = Instance.new("TextLabel", f); label.Size = UDim2.new(1, -60, 1, 0); label.Text = txt; label.TextColor3 = Color3.new(1,1,1); label.Font = "Gotham"; label.TextSize = 16; label.TextXAlignment = "Left"; label.BackgroundTransparency = 1
    btn.MouseButton1Click:Connect(function()
        getgenv().Config[key] = not getgenv().Config[key]
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60)}):Play()
    end)
end

local function AddSlider(parent, txt, key, min, max)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 65); f.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", f); label.Size = UDim2.new(1, 0, 0, 25); label.Text = txt .. ": " .. getgenv().Config[key]; label.TextColor3 = Color3.new(1,1,1); label.Font = "Gotham"; label.TextSize = 14; label.TextXAlignment = "Left"; label.BackgroundTransparency = 1
    
    local track = Instance.new("Frame", f); track.Size = UDim2.new(1, 0, 0, 6); track.Position = UDim2.new(0, 0, 0, 40); track.BackgroundColor3 = Color3.fromRGB(45, 45, 55); track.BorderSizePixel = 0; Instance.new("UICorner", track)
    local fill = Instance.new("Frame", track); fill.Size = UDim2.new((getgenv().Config[key] - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255); fill.BorderSizePixel = 0; Instance.new("UICorner", fill)
    
    local function UpdateSlider()
        local mousePos = UIS:GetMouseLocation().X
        local trackPos = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        local percent = math.clamp((mousePos - trackPos) / trackWidth, 0, 1)
        local val = math.floor(min + (max - min) * percent)
        if key == "Smoothness" then val = min + (max - min) * percent end -- Smoothness needs decimals
        
        getgenv().Config[key] = val
        fill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = txt .. ": " .. (key == "Smoothness" and string.format("%.2f", val) or tostring(val))
    end

    local sliding = false
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; UpdateSlider() end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider() end end)
end

-- AIM TAB
AddToggle(Tabs.Aim.Frame, "Show FOV Circle", "ShowFOV")
AddSlider(Tabs.Aim.Frame, "FOV Radius", "FOVRadius", 10, 800)
AddSlider(Tabs.Aim.Frame, "Aim Smoothness", "Smoothness", 0, 1)
AddToggle(Tabs.Aim.Frame, "Camera Snap", "CameraAim")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 1)", "Method1_Silent")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 2)", "Method2_Silent")
AddToggle(Tabs.Aim.Frame, "Wall Check", "WallCheck")

-- Target Part Toggle
local partBtn = Instance.new("TextButton", Tabs.Aim.Frame)
partBtn.Size = UDim2.new(0.95, 0, 0, 40); partBtn.BackgroundColor3 = Color3.fromRGB(35,35,50); partBtn.TextColor3 = Color3.new(1,1,1); partBtn.Font = "GothamBold"; partBtn.TextSize = 16; Instance.new("UICorner", partBtn)
partBtn.MouseButton1Click:Connect(function()
    getgenv().Config.AimPart = (getgenv().Config.AimPart == "Head" and "HumanoidRootPart" or "Head")
    partBtn.Text = "TARGET PART: " .. getgenv().Config.AimPart
end)
partBtn.Text = "TARGET PART: " .. getgenv().Config.AimPart

-- VISUALS & MISC
AddToggle(Tabs.Visuals.Frame, "Box ESP", "ESPEnabled")
AddToggle(Tabs.Visuals.Frame, "Skeleton ESP", "SkeletonEnabled")
AddToggle(Tabs.Visuals.Frame, "Chams / Glow", "GlowEnabled")
AddToggle(Tabs.Misc.Frame, "Hitbox Expander", "HitboxEnabled")
AddSlider(Tabs.Misc.Frame, "Hitbox Size", "HitboxSize", 2, 50)

--// ENGINE & METAMETHODS (Logic remains same as original)
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local potential, dist = nil, getgenv().Config.FOVRadius
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v ~= LP.Character then
            local root = v:FindFirstChild(getgenv().Config.AimPart) or v:FindFirstChild("HumanoidRootPart")
            if root then
                local sPos, onScr = Camera:WorldToViewportPoint(root.Position)
                if onScr then
                    local mDist = (Vector2.new(sPos.X, sPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then potential = root; dist = mDist end
                end
            end
        end
    end
    LockedTarget = potential
    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

-- Metamethod Hooks
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

-- Dragging & Logic
local dragging, dStart, sPos
Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dStart = i.Position; sPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UIS.InputBegan:Connect(function(i, c) 
    if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end 
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end 
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)
