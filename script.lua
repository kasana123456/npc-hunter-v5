--[[ 
    ASYLUM HITBOX + ESP + GLOW V2
    - FIXED: ESP boxes now properly hide when off-screen.
    - NEW: Glow (Highlight) effect for targets.
    - TOGGLE: F5
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LP = game:GetService("Players").LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().HitboxSettings = {
    Enabled = false,
    ESPEnabled = true,
    GlowEnabled = true,
    HitboxSize = 10,
    Transparency = 0.7,
    GlowColor = Color3.fromRGB(0, 255, 255)
}

local ESP_Cache = {}

--// GUI Setup
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 480)
Main.Position = UDim2.new(0.4, 0, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40); Title.Text = "ASYLUM NPC SUITE"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1

--// Dragging logic
local dragStart, startPos, dragging
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

--// UI HELPERS
local function createToggle(txt, pos, key)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 35); b.Position = pos; b.Text = txt .. ": " .. (getgenv().HitboxSettings[key] and "ON" or "OFF")
    b.BackgroundColor3 = getgenv().HitboxSettings[key] and Color3.fromRGB(30, 80, 30) or Color3.fromRGB(40, 30, 30)
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamSemibold; Instance.new("UICorner", b)
    
    b.MouseButton1Click:Connect(function()
        getgenv().HitboxSettings[key] = not getgenv().HitboxSettings[key]
        b.Text = txt .. ": " .. (getgenv().HitboxSettings[key] and "ON" or "OFF")
        b.BackgroundColor3 = getgenv().HitboxSettings[key] and Color3.fromRGB(30, 80, 30) or Color3.fromRGB(40, 30, 30)
    end)
end

local function createSlider(txt, pos, min, max, key)
    local lab = Instance.new("TextLabel", Main); lab.Size = UDim2.new(0.9, 0, 0, 20); lab.Position = pos; lab.Text = txt .. ": " .. getgenv().HitboxSettings[key]; lab.BackgroundTransparency = 1; lab.TextColor3 = Color3.new(1,1,1)
    local bar = Instance.new("Frame", Main); bar.Size = UDim2.new(0.9, 0, 0, 5); bar.Position = pos + UDim2.new(0, 0, 0, 25); bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().HitboxSettings[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    
    local function update(input)
        local per = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * per)
        if key == "Transparency" then val = per end
        getgenv().HitboxSettings[key] = val
        fill.Size = UDim2.new(per, 0, 1, 0)
        lab.Text = txt .. ": " .. (key == "Transparency" and math.floor(val*10)/10 or val)
    end
    
    local sliding = false
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; update(i) end end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
end

--// INIT UI
createToggle("Hitbox Expander", UDim2.new(0.05, 0, 0.12, 0), "Enabled")
createToggle("Box ESP", UDim2.new(0.05, 0, 0.20, 0), "ESPEnabled")
createToggle("NPC Glow", UDim2.new(0.05, 0, 0.28, 0), "GlowEnabled")
createSlider("Hitbox Size", UDim2.new(0.05, 0, 0.42, 0), 2, 50, "HitboxSize")
createSlider("Box Visibility", UDim2.new(0.05, 0, 0.60, 0), 0, 1, "Transparency")

--// ESP & HIGHLIGHT BUILDER
local function SetupExtras(model)
    local data = {}
    
    -- ESP Drawings
    data.Box = Drawing.new("Square"); data.Box.Thickness = 1; data.Box.Filled = false; data.Box.Color = Color3.new(1,1,1); data.Box.Visible = false
    data.Text = Drawing.new("Text"); data.Text.Size = 13; data.Text.Center = true; data.Text.Outline = true; data.Text.Color = Color3.new(1,1,1); data.Text.Visible = false
    
    -- Highlight (Glow)
    local hl = Instance.new("Highlight")
    hl.Name = "AsylumGlow"
    hl.FillColor = getgenv().HitboxSettings.GlowColor
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Parent = model
    data.Highlight = hl
    
    return data
end

--// MAIN ENGINE
RunService.RenderStepped:Connect(function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Parent:IsA("Model") and not game.Players:GetPlayerFromCharacter(v.Parent) then
            local char = v.Parent
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if root and v.Health > 0 then
                if not ESP_Cache[char] then ESP_Cache[char] = SetupExtras(char) end
                local cache = ESP_Cache[char]
                
                -- Hitbox Logic
                if getgenv().HitboxSettings.Enabled then
                    root.Size = Vector3.new(getgenv().HitboxSettings.HitboxSize, getgenv().HitboxSettings.HitboxSize, getgenv().HitboxSettings.HitboxSize)
                    root.Transparency = getgenv().HitboxSettings.Transparency
                    root.CanCollide = false
                end
                
                -- Glow Logic
                cache.Highlight.Enabled = getgenv().HitboxSettings.GlowEnabled
                
                -- ESP Logic (Fixed Off-Screen logic)
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                
                if onScreen and getgenv().HitboxSettings.ESPEnabled then
                    local scale = 1000 / screenPos.Z
                    cache.Box.Size = Vector2.new(scale, scale)
                    cache.Box.Position = Vector2.new(screenPos.X - scale/2, screenPos.Y - scale/2)
                    cache.Box.Visible = true
                    
                    cache.Text.Position = Vector2.new(screenPos.X, screenPos.Y + (scale/2) + 5)
                    cache.Text.Text = string.format("%s [%d m]", char.Name, math.floor(screenPos.Z))
                    cache.Text.Visible = true
                else
                    cache.Box.Visible = false
                    cache.Text.Visible = false
                end
            elseif ESP_Cache[char] then
                -- Cleanup for dead NPCs
                ESP_Cache[char].Box.Visible = false
                ESP_Cache[char].Text.Visible = false
                ESP_Cache[char].Highlight.Enabled = false
            end
        end
    end
end)

-- F5 Toggle
UIS.InputBegan:Connect(function(i, c) if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end end)
