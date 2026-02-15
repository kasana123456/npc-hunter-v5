--[[ 
    ASYLUM ELITE V8.0 (INTEGRATED BUILD)
    - COMBINED: Aimbot, Silent Aim, Hitbox Expander, ESP, and Glow.
    - DYNAMIC: Visuals respect your "Target Mode" (NPCs/Players/All).
    - TOGGLE: F5
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
    HitboxEnabled = false, -- NEW
    ESPEnabled = false,    -- NEW
    GlowEnabled = false,   -- NEW
    FOVRadius = 150,
    Smoothness = 0.15,
    HitboxSize = 10,       -- NEW
    AimPart = "Head",
    TargetMode = "NPCs", 
}

local LockedTarget = nil
local IsRightClicking = false
local ESP_Cache = {}

--// CONFIG SYSTEM
local filename = "AsylumElite_V8.json"
local function SaveConfig() writefile(filename, HttpService:JSONEncode(getgenv().Config)) end
-- (LoadConfig omitted for brevity, same as your v7.5)

--// Visuals (FOV Circle)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(0, 255, 255); FOVCircle.Visible = true

local function IsVisible(targetPart)
    if not getgenv().Config.WallCheck then return true end
    return #Camera:GetPartsObscuringTarget({targetPart.Position}, {LP.Character, Camera}) == 0
end

--// GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumElite_V8"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 650) -- Adjusted for more buttons
Main.Position = UDim2.new(0.05, 0, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 60); Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 0, 35); Title.Text = "ASYLUM ELITE V8.0"; Title.TextColor3 = Color3.new(1, 1, 1); Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1

local TargetLabel = Instance.new("TextLabel", Header)
TargetLabel.Size = UDim2.new(1, 0, 0, 20); TargetLabel.Position = UDim2.new(0, 0, 0.55, 0); TargetLabel.Text = "Target: None"; TargetLabel.TextColor3 = Color3.fromRGB(0, 255, 150); TargetLabel.Font = Enum.Font.Gotham; TargetLabel.BackgroundTransparency = 1; TargetLabel.TextSize = 12

--// UI HELPERS
local function createBtn(txt, pos, configKey, isAction)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 30); b.Position = pos; b.Text = txt
    b.BackgroundColor3 = (not isAction and getgenv().Config[configKey]) and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
    b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamSemibold; Instance.new("UICorner", b)
    
    b.MouseButton1Click:Connect(function()
        if isAction then
            SaveConfig(); b.Text = "SAVED!"; task.wait(1); b.Text = txt
        else
            getgenv().Config[configKey] = not getgenv().Config[configKey]
            b.BackgroundColor3 = getgenv().Config[configKey] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 35)
        end
    end)
    return b
end

--// INIT BUTTONS (Standard & New)
createBtn("Camera Snap", UDim2.new(0.05, 0, 0.10, 0), "CameraAim")
createBtn("Silent Aim", UDim2.new(0.05, 0, 0.15, 0), "Method1_Silent")
createBtn("Wall Check", UDim2.new(0.05, 0, 0.20, 0), "WallCheck")
createBtn("Hitbox Expander", UDim2.new(0.05, 0, 0.25, 0), "HitboxEnabled")
createBtn("Box ESP", UDim2.new(0.05, 0, 0.30, 0), "ESPEnabled")
createBtn("Chams / Glow", UDim2.new(0.05, 0, 0.35, 0), "GlowEnabled")

-- Target Mode Cycle
local modeBtn = Instance.new("TextButton", Main)
modeBtn.Size = UDim2.new(0.9, 0, 0, 32); modeBtn.Position = UDim2.new(0.05, 0, 0.42, 0)
modeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45); modeBtn.Font = Enum.Font.GothamBold; Instance.new("UICorner", modeBtn)

local function updateModeUI()
    local mode = getgenv().Config.TargetMode
    modeBtn.Text = "Targeting: " .. mode
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

--// SLIDERS (FOV & Hitbox)
local function createSlider(txt, pos, min, max, key)
    local frame = Instance.new("Frame", Main); frame.Size = UDim2.new(0.9, 0, 0, 40); frame.Position = pos; frame.BackgroundTransparency = 1
    local lab = Instance.new("TextLabel", frame); lab.Size = UDim2.new(1, 0, 0, 15); lab.Text = txt..": "..getgenv().Config[key]; lab.TextColor3 = Color3.new(1,1,1); lab.BackgroundTransparency = 1; lab.Font = Enum.Font.Gotham; lab.TextXAlignment = "Left"
    local bar = Instance.new("Frame", frame); bar.Size = UDim2.new(1, 0, 0, 4); bar.Position = UDim2.new(0, 0, 0.6, 0); bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().Config[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    local function update(input)
        local per = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        getgenv().Config[key] = math.floor(min + (max - min) * per); lab.Text = txt..": "..getgenv().Config[key]; fill.Size = UDim2.new(per, 0, 1, 0)
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; update(i) end end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
end

createSlider("FOV Radius", UDim2.new(0.05, 0, 0.50, 0), 10, 800, "FOVRadius")
createSlider("Hitbox Size", UDim2.new(0.05, 0, 0.60, 0), 2, 60, "HitboxSize")
createBtn("SAVE SETTINGS", UDim2.new(0.05, 0, 0.88, 0), nil, true)

--// CORE ENGINE: Visuals & Logic
local function SetupExtras(model)
    local d = {
        Box = Drawing.new("Square"), Text = Drawing.new("Text"),
        HL = Instance.new("Highlight")
    }
    d.Box.Thickness = 1; d.Box.Color = Color3.new(1,1,1)
    d.Text.Size = 13; d.Text.Outline = true; d.Text.Center = true; d.Text.Color = Color3.new(1,1,1)
    d.HL.FillTransparency = 0.5; d.HL.OutlineColor = Color3.new(1,1,1); d.HL.Parent = model
    return d
end

local function IsValid(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or model == LP.Character then return false end
    local isPlr = Players:GetPlayerFromCharacter(model)
    local mode = getgenv().Config.TargetMode
    if mode == "NPCs" and isPlr then return false end
    if mode == "Players" and not isPlr then return false end
    if getgenv().Config.TeamCheck and isPlr and isPlr.Team == LP.Team then return false end
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
                -- Visual Extras Cache
                if not ESP_Cache[v] then ESP_Cache[v] = SetupExtras(v) end
                local cache = ESP_Cache[v]
                
                -- Hitbox
                if getgenv().Config.HitboxEnabled then
                    root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
                    root.CanCollide = false
                else root.Size = Vector3.new(2,2,1) end
                
                -- Glow
                cache.HL.Enabled = getgenv().Config.GlowEnabled
                
                -- Aimbot & ESP Math
                local sPos, onScr = Camera:WorldToViewportPoint(root.Position)
                if onScr then
                    if getgenv().Config.ESPEnabled then
                        local scale = 1000 / sPos.Z
                        cache.Box.Size = Vector2.new(scale, scale); cache.Box.Position = Vector2.new(sPos.X - scale/2, sPos.Y - scale/2); cache.Box.Visible = true
                        cache.Text.Position = Vector2.new(sPos.X, sPos.Y + (scale/2)); cache.Text.Text = v.Name; cache.Text.Visible = true
                    else cache.Box.Visible = false; cache.Text.Visible = false end
                    
                    if IsVisible(root) then
                        local mDist = (Vector2.new(sPos.X, sPos.Y) - UIS:GetMouseLocation()).Magnitude
                        if mDist < dist then target = root; dist = mDist end
                    end
                else cache.Box.Visible = false; cache.Text.Visible = false end
            end
        end
    end
    LockedTarget = target
    TargetLabel.Text = LockedTarget and "Target: "..LockedTarget.Parent.Name or "Target: None"
    
    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

--// INPUTS & HOOKS (Standard v7.5 logic)
UIS.InputBegan:Connect(function(i, c)
    if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)

--// METAMETHODS (Silent Aim logic from v7.5)
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
