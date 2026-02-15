--[[ 
    ASYLUM ELITE V7.5 (FINAL BUILD)
    - FIXED: Added FOV & Smoothness Sliders
    - NEW: Wall Check (LOS) & Team Check logic
    - NEW: Priority Targeting & Name Randomization
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

--// Global Settings
getgenv().Config = {
    CameraAim = false,
    Method1_Silent = false, 
    Method2_Silent = false, 
    ESP = true,
    WallCheck = true,
    TeamCheck = false,
    FOVRadius = 150,
    Smoothness = 0.15,
    AimPart = "Head",
}

local LockedTarget = nil
local IsRightClicking = false
local ESP_Objects = {}

--// Visuals
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(100, 150, 255); FOVCircle.Visible = true

local function CreateESP()
    return {
        Box = Drawing.new("Square"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square")
    }
end

--// WALL CHECK
local function IsVisible(targetPart)
    if not getgenv().Config.WallCheck then return true end
    return #Camera:GetPartsObscuringTarget({targetPart.Position}, {LP.Character, Camera}) == 0
end

--// GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "Asylum_"..math.random(100,999)
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 560)
Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0); Title.Text = "ASYLUM ELITE V7.5"; Title.TextColor3 = Color3.new(1, 1, 1); Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1

--// DRAG LOGIC
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
UIS.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

--// UI COMPONENTS
local function createBtn(txt, pos, configKey)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 32); b.Position = pos; b.Text = txt
    b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamSemibold; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        getgenv().Config[configKey] = not getgenv().Config[configKey]
        b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    end)
end

local function createSlider(txt, pos, min, max, configKey)
    local sliderFrame = Instance.new("Frame", Main)
    sliderFrame.Size = UDim2.new(0.9, 0, 0, 45); sliderFrame.Position = pos; sliderFrame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", sliderFrame)
    label.Size = UDim2.new(1, 0, 0, 20); label.Text = txt .. ": " .. getgenv().Config[configKey]; label.TextColor3 = Color3.new(1,1,1); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.TextXAlignment = Enum.TextXAlignment.Left
    
    local bar = Instance.new("Frame", sliderFrame)
    bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0.6, 0); bar.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", bar)
    
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((getgenv().Config[configKey] - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255); Instance.new("UICorner", fill)

    local function update(input)
        local per = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * per)
        if configKey == "Smoothness" then val = math.round((min + (max - min) * per) * 100) / 100 end
        getgenv().Config[configKey] = val
        label.Text = txt .. ": " .. val
        fill.Size = UDim2.new(per, 0, 1, 0)
    end

    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then update(input) end end)
end

createBtn("Camera Snap", UDim2.new(0.05, 0, 0.10, 0), "CameraAim")
createBtn("Silent (Namecall)", UDim2.new(0.05, 0, 0.17, 0), "Method1_Silent")
createBtn("Silent (Mouse)", UDim2.new(0.05, 0, 0.24, 0), "Method2_Silent")
createBtn("Wall Check", UDim2.new(0.05, 0, 0.31, 0), "WallCheck")
createBtn("Team Check", UDim2.new(0.05, 0, 0.38, 0), "TeamCheck")
createBtn("NPC ESP", UDim2.new(0.05, 0, 0.45, 0), "ESP")

createSlider("FOV Radius", UDim2.new(0.05, 0, 0.55, 0), 10, 800, "FOVRadius")
createSlider("Smoothness", UDim2.new(0.05, 0, 0.65, 0), 0.01, 1, "Smoothness")

local ap = Instance.new("TextButton", Main)
ap.Size = UDim2.new(0.9, 0, 0, 32); ap.Position = UDim2.new(0.05, 0, 0.78, 0); ap.Text = "Target: Head"; ap.BackgroundColor3 = Color3.fromRGB(40, 40, 60); ap.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", ap)
ap.MouseButton1Click:Connect(function()
    getgenv().Config.AimPart = getgenv().Config.AimPart == "Head" and "HumanoidRootPart" or "Head"
    ap.Text = "Target: " .. (getgenv().Config.AimPart == "Head" and "Head" or "Torso")
end)

--// CORE ENGINE
RunService.RenderStepped:Connect(function()
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local target, dist = nil, getgenv().Config.FOVRadius
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Parent:IsA("Model") and v.Parent ~= LP.Character then
            if Players:GetPlayerFromCharacter(v.Parent) then continue end
            local root = v.Parent:FindFirstChild(getgenv().Config.AimPart) or v.Parent:FindFirstChild("HumanoidRootPart")
            if root and v.Health > 0 then
                if getgenv().Config.TeamCheck then
                    local tc = v.Parent:FindFirstChild("TeamColor") or v.Parent:FindFirstChild("Team")
                    if tc and tc.Value == LP.TeamColor then continue end
                end
                local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
                if rVis and IsVisible(root) then
                    local mDist = (Vector2.new(rPos.X, rPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then target = root; dist = mDist end
                end
            end
        end
    end

    LockedTarget = target
    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

--// HOOKS
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

UIS.InputBegan:Connect(function(i, c) if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)
