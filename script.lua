--[[ 
    ASYLUM ELITE V7.5 (FINAL BUILD)
    - NEW: Wall Check (LOS)
    - NEW: Team Check logic
    - NEW: Priority Targeting (Crosshair Proximity)
    - FIXED: Jittering when targets are behind cover
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
    WallCheck = true, -- Prevents locking through walls
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

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1; SnapLine.Color = Color3.fromRGB(255, 255, 255)

local function CreateESP()
    return {
        Box = Drawing.new("Square"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square")
    }
end

--// WALL CHECK FUNCTION (The "Dev" Way)
local function IsVisible(targetPart)
    if not getgenv().Config.WallCheck then return true end
    local castPoints = {targetPart.Position}
    local ignoreList = {LP.Character, Camera}
    local obstacles = Camera:GetPartsObscuringTarget(castPoints, ignoreList)
    
    return #obstacles == 0
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
Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0); Title.Text = "ASYLUM ELITE V7.5"; Title.TextColor3 = Color3.new(1, 1, 1); Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1

--// DRAG LOGIC
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
UIS.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

--// UI COMPONENTS
local function createBtn(txt, pos, configKey)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 35); b.Position = pos; b.Text = txt
    b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamSemibold; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        getgenv().Config[configKey] = not getgenv().Config[configKey]
        b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    end)
end

createBtn("Camera Snap", UDim2.new(0.05, 0, 0.10, 0), "CameraAim")
createBtn("Silent Aim (Namecall)", UDim2.new(0.05, 0, 0.17, 0), "Method1_Silent")
createBtn("Silent Aim (Mouse)", UDim2.new(0.05, 0, 0.24, 0), "Method2_Silent")
createBtn("Wall Check (LOS)", UDim2.new(0.05, 0, 0.31, 0), "WallCheck")
createBtn("Team Check", UDim2.new(0.05, 0, 0.38, 0), "TeamCheck")
createBtn("Toggle ESP", UDim2.new(0.05, 0, 0.45, 0), "ESP")

-- Aim Part Cycle
local ap = Instance.new("TextButton", Main)
ap.Size = UDim2.new(0.9, 0, 0, 35); ap.Position = UDim2.new(0.05, 0, 0.52, 0); ap.Text = "Target: Head"; ap.BackgroundColor3 = Color3.fromRGB(40, 40, 60); ap.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", ap)
ap.MouseButton1Click:Connect(function()
    getgenv().Config.AimPart = getgenv().Config.AimPart == "Head" and "HumanoidRootPart" or "Head"
    ap.Text = "Target: " .. (getgenv().Config.AimPart == "Head" and "Head" or "Torso")
end)

--// CORE ENGINE
RunService.RenderStepped:Connect(function()
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local target, dist = nil, getgenv().Config.FOVRadius
    local ActiveNPCs = {}

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Parent:IsA("Model") and v.Parent ~= LP.Character then
            local char = v.Parent
            if Players:GetPlayerFromCharacter(char) then continue end -- Focus only on NPCs
            
            local root = char:FindFirstChild(getgenv().Config.AimPart) or char:FindFirstChild("HumanoidRootPart")
            if root and v.Health > 0 then
                ActiveNPCs[char] = true
                
                -- Team Check logic
                if getgenv().Config.TeamCheck then
                    local tc = char:FindFirstChild("TeamColor") or char:FindFirstChild("Team")
                    if tc and (tc.Value == LP.TeamColor or tc.Value == LP.Team) then continue end
                end

                local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
                if rVis and IsVisible(root) then
                    local mDist = (Vector2.new(rPos.X, rPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then target = root; dist = mDist end
                end
                
                -- ESP Logic
                if getgenv().Config.ESP then
                    local esp = ESP_Objects[char] or CreateESP(); ESP_Objects[char] = esp
                    if rVis then
                        local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y)
                        esp.Box.Size = Vector2.new(size * 0.6, size); esp.Box.Position = Vector2.new(rPos.X - (size * 0.6) / 2, rPos.Y - size / 2); esp.Box.Visible = true; esp.Box.Color = Color3.new(1,0,0)
                        esp.HealthBarBG.Visible = true; esp.HealthBar.Visible = true
                        esp.HealthBar.Size = Vector2.new(2, size * (v.Health/v.MaxHealth)); esp.HealthBar.Position = esp.Box.Position - Vector2.new(5, 0)
                    else esp.Box.Visible = false; esp.HealthBarBG.Visible = false; esp.HealthBar.Visible = false end
                end
            end
        end
    end

    LockedTarget = target
    if LockedTarget and IsRightClicking then
        if getgenv().Config.CameraAim then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
        end
    end
end)

--// METAMETHOD HOOKS
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

UIS.InputBegan:Connect(function(i, c) if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)
