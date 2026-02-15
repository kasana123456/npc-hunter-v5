--[[ 
    ASYLUM ELITE V7.2
    - Added Aim Target Selection (Head/Torso)
    - Added Target Name Display
    - Custom Header-Only Dragging
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
    AimPart = "Head", -- Default target
}

local LockedTarget = nil
local IsRightClicking = false
local ESP_Objects = {}

--// Visuals
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(100, 150, 255); FOVCircle.Visible = true; FOVCircle.Filled = false

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1; SnapLine.Color = Color3.fromRGB(255, 255, 255); SnapLine.Transparency = 0.5

local TargetLabel = Drawing.new("Text")
TargetLabel.Size = 18; TargetLabel.Center = true; TargetLabel.Outline = true; TargetLabel.Color = Color3.new(1, 1, 0); TargetLabel.Visible = false

local function CreateESP()
    return {
        Box = Drawing.new("Square"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square")
    }
end

--// GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumElite_V7_2"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 580) -- Increased size for new buttons
Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Header
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "ASYLUM ELITE V7.2"; Title.TextColor3 = Color3.new(1, 1, 1); Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1

--// DRAG LOGIC
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

--// UI HELPERS
local function createBtn(txt, pos, configKey)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 38); b.Position = pos; b.Text = txt
    b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamSemibold; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        getgenv().Config[configKey] = not getgenv().Config[configKey]
        b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    end)
end

-- New Target Cycle Button
local targetBtn = Instance.new("TextButton", Main)
targetBtn.Size = UDim2.new(0.9, 0, 0, 38); targetBtn.Position = UDim2.new(0.05, 0, 0.44, 0)
targetBtn.Text = "Target: " .. getgenv().Config.AimPart
targetBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 60); targetBtn.TextColor3 = Color3.new(1,1,1); targetBtn.Font = Enum.Font.GothamBold; Instance.new("UICorner", targetBtn)

targetBtn.MouseButton1Click:Connect(function()
    if getgenv().Config.AimPart == "Head" then
        getgenv().Config.AimPart = "HumanoidRootPart"
    else
        getgenv().Config.AimPart = "Head"
    end
    targetBtn.Text = "Target: " .. (getgenv().Config.AimPart == "HumanoidRootPart" and "Torso" or "Head")
end)

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
createSlider("FOV Radius", UDim2.new(0.05, 0, 0.54, 0), 0, 1000, "FOVRadius")
createSlider("Smoothness", UDim2.new(0.05, 0, 0.68, 0), 0.05, 1, "Smoothness")

--// CORE ENGINE
RunService.RenderStepped:Connect(function()
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local target, dist = nil, getgenv().Config.FOVRadius
    local ActiveNPCs = {}

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Parent:IsA("Model") and not Players:GetPlayerFromCharacter(v.Parent) and v.Parent ~= LP.Character then
            local char = v.Parent
            -- Use the AimPart from config
            local root = char:FindFirstChild(getgenv().Config.AimPart) or char:FindFirstChild("HumanoidRootPart")
            
            if root and v.Health > 0 then
                ActiveNPCs[char] = true
                local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
                
                if rVis then
                    local mDist = (Vector2.new(rPos.X, rPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then target = root; dist = mDist end
                end
                
                -- ESP Logic
                if getgenv().Config.ESP then
                    if not ESP_Objects[char] then ESP_Objects[char] = CreateESP() end
                    local esp = ESP_Objects[char]
                    if rVis then
                        local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y)
                        local bS = Vector2.new(size * 0.6, size); local bP = Vector2.new(rPos.X - bS.X / 2, rPos.Y - bS.Y / 2)
                        esp.Box.Size = bS; esp.Box.Position = bP; esp.Box.Visible = true; esp.Box.Color = Color3.new(1,0,0)
                        esp.HealthBarBG.Size = Vector2.new(2, size); esp.HealthBarBG.Position = bP - Vector2.new(5, 0); esp.HealthBarBG.Visible = true
                        esp.HealthBar.Size = Vector2.new(2, size * (v.Health/v.MaxHealth)); esp.HealthBar.Position = bP - Vector2.new(5, 0); esp.HealthBar.Visible = true; esp.HealthBar.Color = Color3.new(0,1,0)
                    else esp.Box.Visible = false; esp.HealthBarBG.Visible = false; esp.HealthBar.Visible = false end
                end
            end
        end
    end

    -- Cleanup ESP
    for char, esp in pairs(ESP_Objects) do
        if not ActiveNPCs[char] or not getgenv().Config.ESP then
            esp.Box.Visible = false; esp.HealthBarBG.Visible = false; esp.HealthBar.Visible = false
        end
    end
    
    LockedTarget = target
    if LockedTarget then
        local p, o = Camera:WorldToViewportPoint(LockedTarget.Position)
        SnapLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2); SnapLine.To = Vector2.new(p.X, p.Y); SnapLine.Visible = o
        
        -- Target Indicator Text
        TargetLabel.Position = Vector2.new(p.X, p.Y - 25)
        TargetLabel.Text = "[ LOCKED: " .. LockedTarget.Parent.Name .. " ]"
        TargetLabel.Visible = true

        if getgenv().Config.CameraAim and IsRightClicking then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
        end
    else 
        SnapLine.Visible = false 
        TargetLabel.Visible = false
    end
end)

--// Silent Aim Hooks (Keep existing logic)
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

--// Input Handling
UIS.InputBegan:Connect(function(i, c)
    if c then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true
    elseif i.KeyCode == Enum.KeyCode.Insert then Main.Visible = not Main.Visible end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)
