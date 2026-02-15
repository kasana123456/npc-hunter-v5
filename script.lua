--[[ 
    ASYLUM ELITE V7.5 (HYBRID BUILD)
    - TOGGLE KEY: F5
    - LOCK KEY: Right Click (Hold)
    - TARGET MODES: [NPCs] (Green), [Players] (Blue), [All] (Red)
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()
local HttpService = game:GetService("HttpService")

--// Global Settings
getgenv().Config = {
    CameraAim = false,
    Method1_Silent = false, 
    Method2_Silent = false, 
    WallCheck = true,
    TeamCheck = false,
    FOVRadius = 150,
    Smoothness = 0.15,
    AimPart = "Head",
    TargetMode = "NPCs", -- Default: NPCs, Players, All
}

--// CONFIG SYSTEM
local filename = "AsylumElite_Hybrid.json"
local function SaveConfig() writefile(filename, HttpService:JSONEncode(getgenv().Config)) end
local function LoadConfig()
    if isfile(filename) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(filename))
            for i, v in pairs(data) do getgenv().Config[i] = v end
        end)
    end
end
LoadConfig()

local LockedTarget = nil
local IsRightClicking = false
local GuiVisible = true

--// Visuals
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(100, 150, 255); FOVCircle.Visible = true

local function IsVisible(targetPart)
    if not getgenv().Config.WallCheck then return true end
    return #Camera:GetPartsObscuringTarget({targetPart.Position}, {LP.Character, Camera}) == 0
end

--// GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumElite_V7_5"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 600)
Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 60); Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 0, 35); Title.Text = "ASYLUM ELITE V7.5"; Title.TextColor3 = Color3.new(1, 1, 1); Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1

local TargetLabel = Instance.new("TextLabel", Header)
TargetLabel.Size = UDim2.new(1, 0, 0, 20); TargetLabel.Position = UDim2.new(0, 0, 0.55, 0); TargetLabel.Text = "Target: None"; TargetLabel.TextColor3 = Color3.fromRGB(150, 150, 150); TargetLabel.Font = Enum.Font.Gotham; TargetLabel.BackgroundTransparency = 1; TargetLabel.TextSize = 12

--// DRAG LOGIC
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
UIS.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

--// UI BUTTONS
local function createBtn(txt, pos, configKey, isAction)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 32); b.Position = pos; b.Text = txt
    b.BackgroundColor3 = (not isAction and getgenv().Config[configKey]) and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamSemibold; Instance.new("UICorner", b)
    
    b.MouseButton1Click:Connect(function()
        if isAction then
            SaveConfig()
            b.Text = "CONFIG SAVED!"
            task.wait(1)
            b.Text = txt
        else
            getgenv().Config[configKey] = not getgenv().Config[configKey]
            b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
        end
    end)
    return b
end

--// INIT UI COMPONENTS
createBtn("Camera Snap", UDim2.new(0.05, 0, 0.12, 0), "CameraAim")
createBtn("Silent (Method 1)", UDim2.new(0.05, 0, 0.18, 0), "Method1_Silent")
createBtn("Silent (Method 2)", UDim2.new(0.05, 0, 0.24, 0), "Method2_Silent")
createBtn("Wall Check", UDim2.new(0.05, 0, 0.30, 0), "WallCheck")
createBtn("Team Check", UDim2.new(0.05, 0, 0.36, 0), "TeamCheck")

-- Target List Cycling Button
local modeBtn = Instance.new("TextButton", Main)
modeBtn.Size = UDim2.new(0.9, 0, 0, 35); modeBtn.Position = UDim2.new(0.05, 0, 0.43, 0)
modeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45); modeBtn.Font = Enum.Font.GothamBold; modeBtn.TextSize = 13
Instance.new("UICorner", modeBtn)

local function updateModeUI()
    local mode = getgenv().Config.TargetMode
    modeBtn.Text = "Targeting: [" .. mode .. "]"
    if mode == "NPCs" then modeBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
    elseif mode == "Players" then modeBtn.TextColor3 = Color3.fromRGB(0, 160, 255)
    else modeBtn.TextColor3 = Color3.fromRGB(255, 100, 100) end
end
updateModeUI()

modeBtn.MouseButton1Click:Connect(function()
    if getgenv().Config.TargetMode == "NPCs" then getgenv().Config.TargetMode = "Players"
    elseif getgenv().Config.TargetMode == "Players" then getgenv().Config.TargetMode = "All"
    else getgenv().Config.TargetMode = "NPCs" end
    updateModeUI()
end)

--// SLIDERS
local function createSlider(txt, pos, min, max, configKey)
    local sliderFrame = Instance.new("Frame", Main)
    sliderFrame.Size = UDim2.new(0.9, 0, 0, 45); sliderFrame.Position = pos; sliderFrame.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", sliderFrame); label.Size = UDim2.new(1, 0, 0, 20); label.Text = txt .. ": " .. getgenv().Config[configKey]; label.TextColor3 = Color3.new(1,1,1); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.TextXAlignment = Enum.TextXAlignment.Left
    local bar = Instance.new("Frame", sliderFrame); bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0.6, 0); bar.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", bar)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().Config[configKey] - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255); Instance.new("UICorner", fill)
    local function update(input)
        local per = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * per
        if configKey == "Smoothness" then val = math.round(val * 100) / 100 else val = math.floor(val) end
        getgenv().Config[configKey] = val; label.Text = txt .. ": " .. val; fill.Size = UDim2.new(per, 0, 1, 0)
    end
    local sliding = false
    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; update(input) end end)
    UIS.InputChanged:Connect(function(input) if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
end

createSlider("FOV Radius", UDim2.new(0.05, 0, 0.51, 0), 10, 800, "FOVRadius")
createSlider("Smoothness", UDim2.new(0.05, 0, 0.61, 0), 0.01, 1, "Smoothness")

createBtn("SAVE SETTINGS", UDim2.new(0.05, 0, 0.76, 0), nil, true)
local ap = createBtn("Target Part: " .. getgenv().Config.AimPart, UDim2.new(0.05, 0, 0.84, 0), nil, true)
ap.MouseButton1Click:Connect(function()
    getgenv().Config.AimPart = (getgenv().Config.AimPart == "Head" and "HumanoidRootPart" or "Head")
    ap.Text = "Target Part: " .. getgenv().Config.AimPart
end)

--// CORE ENGINE
local function IsValid(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local isPlayer = Players:GetPlayerFromCharacter(model)
    local mode = getgenv().Config.TargetMode
    
    if mode == "NPCs" and isPlayer then return false end
    if mode == "Players" and not isPlayer then return false end
    if isPlayer and isPlayer == LP then return false end
    if getgenv().Config.TeamCheck and isPlayer and isPlayer.Team == LP.Team then return false end
    return true
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local target, dist = nil, getgenv().Config.FOVRadius
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and IsValid(v) then
            local root = v:FindFirstChild(getgenv().Config.AimPart) or v:FindFirstChild("HumanoidRootPart")
            if root then
                local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
                if rVis and IsVisible(root) then
                    local mDist = (Vector2.new(rPos.X, rPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then target = root; dist = mDist end
                end
            end
        end
    end

    LockedTarget = target
    TargetLabel.Text = LockedTarget and "Target: " .. LockedTarget.Parent.Name or "Target: None"
    TargetLabel.TextColor3 = LockedTarget and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(150, 150, 150)

    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

--// INPUT & METAMETHODS
UIS.InputBegan:Connect(function(i, c)
    if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)

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
