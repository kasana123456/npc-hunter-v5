--[[ 
    ASYLUM ELITE V10.4
    - FIXED: Highlight cleanup (Yellow chams go away when not locked)
    - ADDED: Target Part Toggle (Head / HumanoidRootPart)
    - FEATURE: Auto-Save & Dual Silent Aim
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
    HitboxEnabled = false,
    ESPEnabled = false,
    GlowEnabled = false,
    FOVRadius = 150,
    Smoothness = 0.15,
    HitboxSize = 10,
    VisualTransparency = 0.7,
    AimPart = "Head",
    TargetMode = "NPCs", 
}

--// AUTO-SAVE
local filename = "AsylumElite_V10.json"
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

--// FOV Visual
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(0, 255, 255); FOVCircle.Visible = true

local function IsVisible(targetPart)
    if not getgenv().Config.WallCheck then return true end
    return #Camera:GetPartsObscuringTarget({targetPart.Position}, {LP.Character, Camera}) == 0
end

--// GUI CORE
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumV10_4"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 280, 0, 480); Main.Position = UDim2.new(0.05, 0, 0.2, 0); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.ClipsDescendants = true
Instance.new("UICorner", Main)

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 50); Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0); Title.Text = "ASYLUM ELITE V10.4"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = "GothamBold"; Title.BackgroundTransparency = 1

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, 0, 1, -55); Scroll.Position = UDim2.new(0, 0, 0, 55); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 3; Scroll.AutomaticCanvasSize = "Y"
Instance.new("UIListLayout", Scroll).HorizontalAlignment = "Center"; Scroll.UIListLayout.Padding = UDim.new(0, 8)

--// UI HELPERS
local function createToggle(txt, key)
    local b = Instance.new("TextButton", Scroll)
    b.Size = UDim2.new(0.9, 0, 0, 32); b.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(30, 30, 40)
    b.Text = txt .. ": " .. (getgenv().Config[key] and "ON" or "OFF"); b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamSemibold"; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        getgenv().Config[key] = not getgenv().Config[key]
        b.Text = txt .. ": " .. (getgenv().Config[key] and "ON" or "OFF")
        b.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(30, 30, 40)
        TriggerSave()
    end)
end

local function createSlider(txt, min, max, key, decimal)
    local f = Instance.new("Frame", Scroll); f.Size = UDim2.new(0.9, 0, 0, 45); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, 0, 0, 15); l.Text = txt .. ": " .. getgenv().Config[key]; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.Font = "Gotham"; l.TextXAlignment = "Left"
    local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, 0, 0, 4); bar.Position = UDim2.new(0,0,0.6,0); bar.BackgroundColor3 = Color3.fromRGB(45,45,55)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().Config[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0,120,255)
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

--// INIT UI
local modeBtn = Instance.new("TextButton", Scroll)
modeBtn.Size = UDim2.new(0.9, 0, 0, 35); modeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60); modeBtn.Font = "GothamBold"; Instance.new("UICorner", modeBtn)
local function updateMode()
    modeBtn.Text = "MODE: " .. getgenv().Config.TargetMode
    modeBtn.TextColor3 = (getgenv().Config.TargetMode == "NPCs" and Color3.new(0,1,0.5)) or (getgenv().Config.TargetMode == "Players" and Color3.new(0,0.6,1)) or Color3.new(1,0.3,0.3)
    TriggerSave()
end
modeBtn.MouseButton1Click:Connect(function()
    local m = getgenv().Config.TargetMode
    getgenv().Config.TargetMode = (m == "NPCs" and "Players") or (m == "Players" and "All") or "NPCs"
    updateMode()
end)
updateMode()

createToggle("Camera Snap", "CameraAim")
createToggle("Silent Method 1 (Ray)", "Method1_Silent")
createToggle("Silent Method 2 (Index)", "Method2_Silent")
createToggle("Wall Check", "WallCheck")
createToggle("Hitbox Expander", "HitboxEnabled")
createToggle("Box ESP", "ESPEnabled")
createToggle("Glow (Chams)", "GlowEnabled")
createSlider("Smoothness", 0.01, 1, "Smoothness", true)
createSlider("FOV Radius", 10, 800, "FOVRadius")
createSlider("Hitbox Size", 2, 100, "HitboxSize")

-- Target Part Toggle
local partBtn = Instance.new("TextButton", Scroll)
partBtn.Size = UDim2.new(0.9, 0, 0, 32); partBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); partBtn.TextColor3 = Color3.new(1,1,1); partBtn.Font = "GothamSemibold"; Instance.new("UICorner", partBtn)
local function updatePart() partBtn.Text = "Target Part: " .. getgenv().Config.AimPart; TriggerSave() end
partBtn.MouseButton1Click:Connect(function()
    getgenv().Config.AimPart = (getgenv().Config.AimPart == "Head" and "HumanoidRootPart" or "Head")
    updatePart()
end)
updatePart()

--// ENGINE
local LockedTarget = nil
local ESP_Cache = {}

local function CreateExtras(model)
    local d = { Box = Drawing.new("Square"), HL = Instance.new("Highlight") }
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

RunService.RenderStepped:Connect(function()
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    local potentialTarget, dist = nil, getgenv().Config.FOVRadius

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and IsValid(v) then
            local root = v:FindFirstChild(getgenv().Config.AimPart) or v:FindFirstChild("HumanoidRootPart")
            if root then
                if not ESP_Cache[v] then ESP_Cache[v] = CreateExtras(v) end
                local cache = ESP_Cache[v]
                
                -- Hitbox
                if getgenv().Config.HitboxEnabled then
                    root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
                    root.Transparency = getgenv().Config.VisualTransparency; root.CanCollide = false
                else root.Size = Vector3.new(2,2,1); root.Transparency = 1 end

                -- Visuals Logic
                local sPos, onScr = Camera:WorldToViewportPoint(root.Position)
                local isCurrentlyLocked = (potentialTarget == root) -- Will be updated below

                -- Chams Handling
                cache.HL.Enabled = getgenv().Config.GlowEnabled
                cache.HL.FillColor = Color3.new(1, 1, 1) -- Reset to White

                if onScr and getgenv().Config.ESPEnabled then
                    local scale = 1000 / sPos.Z
                    cache.Box.Size = Vector2.new(scale, scale); cache.Box.Position = Vector2.new(sPos.X - scale/2, sPos.Y - scale/2); cache.Box.Visible = true
                else cache.Box.Visible = false end

                -- Selection Logic
                if onScr and IsVisible(root) then
                    local mDist = (Vector2.new(sPos.X, sPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mDist < dist then potentialTarget = root; dist = mDist end
                end
            end
        end
    end
    
    LockedTarget = potentialTarget
    
    -- Highlight Cleanup & Priority Set
    for model, cache in pairs(ESP_Cache) do
        if model.Parent == nil then ESP_Cache[model] = nil -- Memory cleanup
        elseif LockedTarget and LockedTarget.Parent == model then
            cache.HL.Enabled = true
            cache.HL.FillColor = Color3.new(1, 1, 0) -- Locked = Yellow
        elseif not getgenv().Config.GlowEnabled then
            cache.HL.Enabled = false -- Turn off if menu glow is off and not locked
        end
    end

    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

--// METAMETHODS & INPUTS
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

local dStart, sPos, dragging
Header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dStart = i.Position; sPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UIS.InputBegan:Connect(function(i, c) if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end 
if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)
