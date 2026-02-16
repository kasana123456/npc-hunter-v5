local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
    AimPart = "Head",
    TargetMode = "All", -- All, Players, NPCs
}

local Window = Rayfield:CreateWindow({
    Name = "FinalElite v1.0",
    LoadingTitle = "FinalElite Execution",
    LoadingSubtitle = "by Gemini",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FinalElite_Configs",
        FileName = "MainConfig"
    },
    KeySystem = false
})

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

--// FOV DRAWING
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Visible = true; FOVCircle.Color = Color3.fromRGB(0, 150, 255)

--// TARGETING LOGIC (With Dead Check)
local function IsValidTarget(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or model == LP.Character then return false end
    
    local isPlayer = Players:GetPlayerFromCharacter(model)
    
    if getgenv().Config.TargetMode == "Players" then return isPlayer ~= nil end
    if getgenv().Config.TargetMode == "NPCs" then return isPlayer == nil end
    return true -- "All" mode
end

--// TABS
local AimTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)
local MiscTab = Window:CreateTab("Misc", 4483362458)

--// COMBAT TAB
AimTab:CreateSection("Aimbot Settings")

AimTab:CreateToggle({
    Name = "Camera Snap (Right Click)",
    CurrentValue = false,
    Callback = function(Value) getgenv().Config.CameraAim = Value end,
})

AimTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "Smoothness",
    CurrentValue = 0.15,
    Callback = function(Value) getgenv().Config.Smoothness = Value end,
})

AimTab:CreateSection("Silent Aim")

AimTab:CreateToggle({
    Name = "Silent Aim (Method 1: Raycast)",
    CurrentValue = false,
    Callback = function(Value) getgenv().Config.Method1_Silent = Value end,
})

AimTab:CreateToggle({
    Name = "Silent Aim (Method 2: Mouse Hit)",
    CurrentValue = false,
    Callback = function(Value) getgenv().Config.Method2_Silent = Value end,
})

AimTab:CreateSection("Targeting")

AimTab:CreateDropdown({
    Name = "Target Group",
    Options = {"All", "Players", "NPCs"},
    CurrentOption = "All",
    Callback = function(Option) getgenv().Config.TargetMode = Option end,
})

AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(Option) getgenv().Config.AimPart = Option end,
})

--// VISUALS TAB
VisualsTab:CreateSection("FOV Settings")

VisualsTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Callback = function(Value) getgenv().Config.ShowFOV = Value end,
})

VisualsTab:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 800},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 150,
    Callback = function(Value) getgenv().Config.FOVRadius = Value end,
})

--// MISC TAB
MiscTab:CreateSection("Experimental")

MiscTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Callback = function(Value) getgenv().Config.HitboxEnabled = Value end,
})

MiscTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 10,
    Callback = function(Value) getgenv().Config.HitboxSize = Value end,
})

--// MAIN ENGINE
local LockedTarget = nil
local IsRightClicking = false

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local potential, dist = nil, getgenv().Config.FOVRadius
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and IsValidTarget(v) then
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

    -- Camera Smooth Snap
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

-- Inputs
UIS.InputBegan:Connect(function(i, c)
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end 
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end 
end)

Rayfield:Notify({
    Title = "FinalElite Loaded",
    Content = "Press Shift or use UI to toggle.",
    Duration = 5,
    Image = 4483362458,
})
