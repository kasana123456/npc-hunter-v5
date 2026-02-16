local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Global Settings
getgenv().Config = {
    CameraAim = false,
    Method1_Silent = false,
    Method2_Silent = false,
    WallCheck = true,
    ShowFOV = true,
    FOVRadius = 150,
    Smoothness = 0.2, -- Increased slightly for better tracking
    HitboxEnabled = false,
    HitboxSize = 10,
    AimPart = "Head",
    TargetMode = "NPCs", -- Default to NPCs for this game
    TeamCheck = true,    -- Don't target teammates
}

local Window = Rayfield:CreateWindow({
    Name = "FinalElite v1.1 | TFS2 Fix",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Optimized for The Final Stand 2",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FinalElite_TFS2",
        FileName = "Config"
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

--// TARGETING LOGIC
local function IsValidTarget(model)
    -- 1. Basic Checks
    if not model or model == LP.Character then return false end
    
    -- 2. Health Check
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    -- 3. Player vs NPC Logic
    local player = Players:GetPlayerFromCharacter(model)
    
    if getgenv().Config.TargetMode == "Players" then
        if not player then return false end -- Must be a player
        if getgenv().Config.TeamCheck and player.Team == LP.Team then return false end -- Teammate check
        return true
        
    elseif getgenv().Config.TargetMode == "NPCs" then
        if player then return false end -- Ignore all players
        -- Optional: Add specific name checks for TFS2 zombies if needed
        return true
        
    else -- "All" Mode
        if player and getgenv().Config.TeamCheck and player.Team == LP.Team then return false end
        return true
    end
end

local function GetPotentialTargets()
    local targets = {}
    
    -- Optimized: Only check direct children of Workspace and specific folders
    -- This prevents lag from scanning thousands of parts
    local searchLocations = {workspace}
    
    -- Add known NPC folders if they exist (Common in TFS2)
    if workspace:FindFirstChild("Zombies") then table.insert(searchLocations, workspace.Zombies) end
    if workspace:FindFirstChild("Enemies") then table.insert(searchLocations, workspace.Enemies) end
    if workspace:FindFirstChild("Distractions") then table.insert(searchLocations, workspace.Distractions) end

    for _, location in pairs(searchLocations) do
        for _, v in pairs(location:GetChildren()) do
            if v:IsA("Model") and IsValidTarget(v) then
                table.insert(targets, v)
            end
        end
    end
    return targets
end

--// TABS
local AimTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)

--// COMBAT TAB
AimTab:CreateSection("Target Selection")

AimTab:CreateDropdown({
    Name = "Target Group",
    Options = {"NPCs", "Players", "All"},
    CurrentOption = "NPCs",
    Callback = function(Option) getgenv().Config.TargetMode = Option end,
})

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(Value) getgenv().Config.TeamCheck = Value end,
})

AimTab:CreateSection("Aimbot")

AimTab:CreateToggle({
    Name = "Camera Snap (Right Click)",
    CurrentValue = false,
    Callback = function(Value) getgenv().Config.CameraAim = Value end,
})

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

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "Value",
    CurrentValue = 0.2,
    Callback = function(Value) getgenv().Config.Smoothness = Value end,
})

AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = "Head",
    Callback = function(Option) getgenv().Config.AimPart = Option end,
})

--// VISUALS TAB
VisualsTab:CreateSection("FOV")

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

--// ENGINE
local LockedTarget = nil
local IsRightClicking = false

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local potential, dist = nil, getgenv().Config.FOVRadius
    local allTargets = GetPotentialTargets() -- Uses the optimized list
    
    for _, v in pairs(allTargets) do
        local root = v:FindFirstChild(getgenv().Config.AimPart) or v:FindFirstChild("HumanoidRootPart")
        if root then
            local sPos, onScr = Camera:WorldToViewportPoint(root.Position)
            if onScr then
                local mDist = (Vector2.new(sPos.X, sPos.Y) - UIS:GetMouseLocation()).Magnitude
                if mDist < dist then potential = root; dist = mDist end
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

-- Inputs
UIS.InputBegan:Connect(function(i, c)
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end 
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end 
end)
