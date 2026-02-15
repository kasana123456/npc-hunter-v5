--[[ 
    ASYLUM ELITE V7.1
    - Custom Header-Only Dragging (Sliders won't move the GUI)
    - Fixed ESP "Ghosting"
    - Fixed Sliders & Health Bars
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
    FOVRadius = 150,
    Smoothness = 0.15,
}

local LockedTarget = nil
local IsRightClicking = false
local ESP_Objects = {}

--// Visuals
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(100, 150, 255); FOVCircle.Visible = true

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1; SnapLine.Color = Color3.fromRGB(255, 255, 255)

local function CreateESP()
    return {
        Box = Drawing.new("Square"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square")
    }
end

--// GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumElite_V7_1"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 540)
Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Header (This is the only part you can drag now)
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "ASYLUM ELITE V7.1"; Title.TextColor3 = Color3.new(1, 1, 1); Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1

--// CUSTOM DRAG LOGIC (Header Only)
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
Header.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// UI BUTTONS & SLIDERS
local function createBtn(txt, pos, configKey)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 38); b.Position = pos; b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 35); b.TextColor3 = Color3.new(0.7, 0.7, 0.7); b.Font = Enum.Font.GothamSemibold; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        getgenv().Config[configKey] = not getgenv().Config[configKey]
        b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
        b.TextColor3 = getgenv().Config[configKey] and Color3.new(1, 1, 1) or Color3.new(0.7, 0.7, 0.7)
    end)
end

local function createSlider(label, pos, min, max, configKey)
    local lbl = Instance.new("TextLabel", Main)
    lbl.Text = label .. ": " .. string.format("%.2f", getgenv().Config[configKey])
    lbl.Position = pos; lbl.Size = UDim2.new(0.9, 0, 0, 20); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12

    local bg = Instance.new("Frame", Main)
    bg.Size = UDim2.new(0.9, 0, 0, 8); bg.Position = pos + UDim2.new(0, 0, 0, 24); bg.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", bg)
    
    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((getgenv().Config[configKey]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255); Instance.new("UICorner", fill)
    
    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            local conn; conn = RunService.RenderStepped:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then conn:Disconnect() return end
                local percent = math.clamp((Mouse.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
                local val = min + (max - min) * percent
                getgenv().Config[configKey] = val
                fill.Size = UDim2.new(percent, 0, 1, 0)
                lbl.Text = label .. ": " .. string.format("%.2f", val)
            end)
        end
    end)
end

createBtn("Camera Snap (MB2)", UDim2.new(0.05, 0, 0.12, 0), "CameraAim")
createBtn("Silent Aim (Namecall)", UDim2.new(0.05, 0, 0.20, 0), "Method1_Silent")
createBtn("Silent Aim (Mouse)", UDim2.new(0.05, 0, 0.28, 0), "Method2_Silent")
createBtn("NPC ESP + Health", UDim2.new(0.05, 0, 0.36, 0), "ESP")
createSlider("FOV Radius", UDim2.new(0.05, 0, 0.48, 0), 0, 1000, "FOVRadius")
createSlider("Smoothness", UDim2.new(0.05, 0, 0.64, 0), 0.05, 1, "Smoothness")

--// CORE ENGINE
RunService.RenderStepped:Connect(function()
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local target, dist = nil, getgenv().Config.FOVRadius
    local ActiveNPCs = {}

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Parent:IsA("Model") and not Players:GetPlayerFromCharacter(v.Parent) and v.Parent ~= LP.Character then
            local char = v.Parent
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
            
            if root and v.Health > 0 then
                ActiveNPCs[char] = true
                local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
                
                if rVis then
                    local mDist = (Vector2.new(rPos.X, rPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then target = root; dist = mDist end
                end
                
                if getgenv().Config.ESP then
                    if not ESP_Objects[char] then ESP_Objects[char] = CreateESP() end
                    local esp = ESP_Objects[char]
                    if rVis then
                        local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y)
                        local bS = Vector2.new(size * 0.6, size); local bP = Vector2.new(rPos.X - bS.X / 2, rPos.Y - bS.Y / 2)
                        esp.Box.Size = bS; esp.Box.Position = bP; esp.Box.Visible = true; esp.Box.Color = Color3.new(1,0,0)
                        esp.HealthBarBG.Size = Vector2.new(2, size); esp.HealthBarBG.Position = bP - Vector2.new(5, 0); esp.HealthBarBG.Visible = true; esp.HealthBarBG.Color = Color3.new(0,0,0)
                        esp.HealthBar.Size = Vector2.new(2, size * (v.Health/v.MaxHealth)); esp.HealthBar.Position = bP - Vector2.new(5, 0); esp.HealthBar.Visible = true; esp.HealthBar.Color = Color3.new(0,1,0)
                    else esp.Box.Visible = false; esp.HealthBarBG.Visible = false; esp.HealthBar.Visible = false end
                end
            end
        end
    end

    for char, esp in pairs(ESP_Objects) do
        if not ActiveNPCs[char] or not getgenv().Config.ESP then
            esp.Box.Visible = false; esp.HealthBarBG.Visible = false; esp.HealthBar.Visible = false
        end
    end
    
    LockedTarget = target
    if LockedTarget then
        local p, o = Camera:WorldToViewportPoint(LockedTarget.Position)
        SnapLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2); SnapLine.To = Vector2.new(p.X, p.Y); SnapLine.Visible = o
        if getgenv().Config.CameraAim and IsRightClicking then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
        end
    else SnapLine.Visible = false end
end)

--// Hooks & Input
local oldN; oldN = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    if getgenv().Config.Method1_Silent and LockedTarget and (m == "Raycast" or m:find("PartOnRay")) then
        local args = {...}
        if m == "Raycast" then args[2] = (LockedTarget.Position - args[1]).Unit * 1000
        else args[1] = Ray.new(Camera.CFrame.Position, (LockedTarget.Position - Camera.CFrame.Position).Unit * 1000) end
        return oldN(self, unpack(args))
    end
    return oldN(self, ...)
end)

local oldI; oldI = hookmetamethod(game, "__index", function(self, idx)
    if getgenv().Config.Method2_Silent and LockedTarget and self == Mouse and (idx == "Hit" or idx == "Target") then
        return (idx == "Hit" and LockedTarget.CFrame or LockedTarget)
    end
    return oldI(self, idx)
end)

UIS.InputBegan:Connect(function(i, c)
    if c then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true
    elseif i.KeyCode == Enum.KeyCode.Insert then Main.Visible = not Main.Visible end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)
