--[[
    FlyHub V3 - Ultimate Shooter Edition
    A high-performance utility script for Roblox shooters.
    
    Credits:
    - Original logic based on FlyGuiV8
    - Enhanced & Redesigned by AI Assistant
]]

--// Configuration & Protection
local scriptName = "FlyHubV3"
if getgenv and getgenv()[scriptName] then 
    warn("[FlyHub] Script is already running!")
    return 
end
if getgenv then getgenv()[scriptName] = true end

--// Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

--// Player & Character
local player = Players.LocalPlayer
local mouse = player:GetMouse()

--// Configuration & State
local config = {
    -- Movement
    flySpeed = 50,
    sprintMultiplier = 2,
    flyTransparency = 0.5,
    isFlying = false,
    useCFrameFly = false,
    noclip = false,
    walkSpeed = 16,
    jumpPower = 50,
    toggleKey = Enum.KeyCode.F,
    sprintKey = Enum.KeyCode.LeftShift,
    
    -- Combat
    aimbotEnabled = false,
    silentAim = false,
    triggerbot = false,
    aimPart = "Head",
    aimbotFov = 150,
    fovVisible = true,
    fovColor = Color3.fromRGB(88, 101, 242),
    hitboxExpander = false,
    hitboxSize = 2,
    
    -- Visuals
    espEnabled = false,
    espTransparency = 0.5,
    espColor = Color3.fromRGB(255, 80, 80),
    teamCheck = true,
    
    -- UI Aesthetics
    accentColor = Color3.fromRGB(88, 101, 242),
    rainbowUI = false,
    infAmmo = false,
    noReload = false,
    fastFire = false,
    uiTransparency = 0.1,
    
    -- Fun/Extra
    spinBot = false,
    fullBright = false
}

local state = {
    flying = false,
    moving = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0},
    isSprinting = false,
    connections = {},
    instances = {},
    activeTab = "Movement"
}

--// --- Drawing Library Support ---
local fovCircle = nil
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.NumSides = 60
    fovCircle.Radius = config.aimbotFov
    fovCircle.Filled = false
    fovCircle.Transparency = 1
    fovCircle.Color = config.fovColor
    fovCircle.Visible = config.fovVisible
end

--// --- UI Construction ---

local screenGui = Instance.new("ScreenGui")
screenGui.Name = scriptName
local success, err = pcall(function() screenGui.Parent = CoreGui end)
if not success then screenGui.Parent = player:WaitForChild("PlayerGui") end
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 450, 0, 320)
mainFrame.Position = UDim2.new(0.5, -225, 0.4, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 120, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local container = Instance.new("Frame", mainFrame)
container.Position = UDim2.new(0, 130, 0, 45)
container.Size = UDim2.new(1, -140, 1, -55)
container.BackgroundTransparency = 1

local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1
header.ZIndex = 5

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "GS8 HUB <font color='#5865F2'>V5</font> - SHOOTER"
title.RichText = true
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.TextSize = 24
closeBtn.Font = Enum.Font.Gotham

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -65, 0.5, -15)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minimizeBtn.TextSize = 24
minimizeBtn.Font = Enum.Font.Gotham

-- Resize Handle
local resizeHandle = Instance.new("Frame", mainFrame)
resizeHandle.Size = UDim2.new(0, 20, 0, 20)
resizeHandle.Position = UDim2.new(1, -20, 1, -20)
resizeHandle.BackgroundTransparency = 1
resizeHandle.ZIndex = 10

local resizeIcon = Instance.new("ImageLabel", resizeHandle)
resizeIcon.Size = UDim2.new(0, 15, 0, 15)
resizeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
resizeIcon.BackgroundTransparency = 1
resizeIcon.Image = "rbxassetid://6031068426" -- Resize icon
resizeIcon.ImageColor3 = Color3.fromRGB(100, 100, 100)

-- Tab System
local tabs = {}
local function createTab(name)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, 45 + (#tabs * 40))
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local content = Instance.new("ScrollingFrame", container)
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ScrollBarThickness = 2
    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.content.Visible = false
            t.btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            t.btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        content.Visible = true
        btn.BackgroundColor3 = config.accentColor
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    local tab = {btn = btn, content = content}
    table.insert(tabs, tab)
    return content
end

local movementTab = createTab("Movement")
local combatTab = createTab("Combat")
local visualsTab = createTab("Visuals")
local weaponTab = createTab("Weapon")
local settingsTab = createTab("Settings")

-- Initial tab
tabs[1].btn.BackgroundColor3 = config.accentColor
tabs[1].btn.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs[1].content.Visible = true

-- Helper UI components
local function createButton(text, parent, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(callback)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y + 40)
    return btn
end

local function createToggle(name, parent, configKey, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = "  " .. name
    btn.TextColor3 = config[configKey] and config.accentColor or Color3.fromRGB(200, 200, 200)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        config[configKey] = not config[configKey]
        TweenService:Create(btn, TweenInfo.new(0.3), {TextColor3 = config[configKey] and config.accentColor or Color3.fromRGB(200, 200, 200)}):Play()
        if callback then callback(config[configKey]) end
    end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y + 40)
    return btn
end

local function createSlider(name, parent, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local bg = Instance.new("Frame", frame)
    bg.Size = UDim2.new(1, 0, 0, 4)
    bg.Position = UDim2.new(0, 0, 0, 30)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", bg)
    
    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = config.accentColor
    Instance.new("UICorner", fill)
    
    local handle = Instance.new("Frame", bg)
    handle.Size = UDim2.new(0, 12, 0, 12)
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.Position = UDim2.new((default-min)/(max-min), 0, 0.5, 0)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (pos * (max - min)))
        fill.Size = UDim2.new(pos, 0, 1, 0)
        handle.Position = UDim2.new(pos, 0, 0.5, 0)
        label.Text = name .. ": " .. val
        callback(val)
    end
    
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
    end)
    parent.CanvasSize = UDim2.new(0, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y + 40)
end

-- // --- Tab Content ---

-- Movement Tab
createToggle("Fly (F)", movementTab, "isFlying")
createToggle("CFrame Fly", movementTab, "useCFrameFly")
createToggle("Noclip", movementTab, "noclip")
createSlider("Fly Speed", movementTab, 1, 500, 50, function(v) config.flySpeed = v end)
createSlider("WalkSpeed", movementTab, 16, 300, 16, function(v) if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = v end end)

-- Combat Tab
createToggle("Aimbot (Right Click)", combatTab, "aimbotEnabled")
createToggle("Silent Aim", combatTab, "silentAim")
createToggle("Triggerbot", combatTab, "triggerbot")
createToggle("Hitbox Expander", combatTab, "hitboxExpander")
createSlider("Hitbox Size", combatTab, 2, 20, 2, function(v) config.hitboxSize = v end)
createToggle("Show FOV Circle", combatTab, "fovVisible", function(v) if fovCircle then fovCircle.Visible = v end end)
createSlider("FOV Radius", combatTab, 10, 800, 150, function(v) config.aimbotFov = v if fovCircle then fovCircle.Radius = v end end)

-- Visuals Tab
createToggle("ESP Enabled", visualsTab, "espEnabled")
createToggle("Team Check", visualsTab, "teamCheck")
createSlider("ESP Transparency", visualsTab, 0, 10, 5, function(v) config.espTransparency = v/10 end)

-- Weapon Tab
createToggle("Infinite Ammo (Generic)", weaponTab, "infAmmo")
createToggle("No Reload (Generic)", weaponTab, "noReload")
createToggle("Fast Fire (Generic)", weaponTab, "fastFire")
createButton("Clean Map (Lag Reduce)", weaponTab, function() 
    for _, v in pairs(workspace:GetDescendants()) do 
        if v:IsA("Explosion") or v:IsA("Sparkles") then v:Destroy() end 
    end 
end)

-- Settings Tab
createToggle("Rainbow UI", settingsTab, "rainbowUI")
createToggle("SpinBot", settingsTab, "spinBot")
createToggle("FullBright", settingsTab, "fullBright", function(v)
    if v then
        game:GetService("Lighting").Ambient = Color3.fromRGB(255, 255, 255)
        game:GetService("Lighting").Brightness = 2
    else
        game:GetService("Lighting").Ambient = Color3.fromRGB(0, 0, 0)
        game:GetService("Lighting").Brightness = 1
    end
end)
createSlider("UI Transparency", settingsTab, 0, 10, 1, function(v) 
    config.uiTransparency = v/10 
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = config.uiTransparency}):Play()
    TweenService:Create(sidebar, TweenInfo.new(0.3), {BackgroundTransparency = config.uiTransparency}):Play()
end)

local function updateUIColors(color)
    config.accentColor = color
    title.Text = string.format("FLY HUB <font color='rgb(%d,%d,%d)'>V3</font> - SHOOTER", color.R*255, color.G*255, color.B*255)
    if fovCircle then fovCircle.Color = color end
    for _, t in pairs(tabs) do
        if t.content.Visible then
            t.btn.BackgroundColor3 = color
        end
    end
end

createButton("Set Color: Blue", settingsTab, function() updateUIColors(Color3.fromRGB(88, 101, 242)) end)
createButton("Set Color: Red", settingsTab, function() updateUIColors(Color3.fromRGB(255, 80, 80)) end)
createButton("Set Color: Green", settingsTab, function() updateUIColors(Color3.fromRGB(80, 255, 80)) end)
createButton("Set Color: Purple", settingsTab, function() updateUIColors(Color3.fromRGB(160, 80, 255)) end)

-- // --- Logic ---

-- Aimbot Helper: Find target closest to center
local function getClosestPlayer()
    local closest = nil
    local shortestDist = config.aimbotFov
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild(config.aimPart) then
            -- Team Check for Aimbot
            if not config.teamCheck or (p.Team ~= player.Team or p.Team == nil) then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character[config.aimPart].Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortestDist then
                        closest = p.Character[config.aimPart]
                        shortestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- ESP Logic
local highlights = {}
local function updateESP()
    if not config.espEnabled then
        for _, h in pairs(highlights) do h:Destroy() end
        table.clear(highlights)
        return
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            -- Team Check
            local isEnemy = true
            if config.teamCheck and p.Team == player.Team and p.Team ~= nil then
                isEnemy = false
            end

            if isEnemy then
                if not highlights[p] then
                    local h = Instance.new("Highlight")
                    h.Parent = p.Character
                    h.FillColor = config.espColor
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = config.espTransparency
                    highlights[p] = h
                    
                    -- Billboard for Name/Distance
                    local b = Instance.new("BillboardGui", p.Character:FindFirstChild("Head") or p.Character.PrimaryPart)
                    b.Name = "FlyHubESP"
                    b.Size = UDim2.new(0, 100, 0, 50)
                    b.StudsOffset = Vector3.new(0, 2, 0)
                    b.AlwaysOnTop = true
                    
                    local l = Instance.new("TextLabel", b)
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundTransparency = 1
                    l.TextColor3 = Color3.fromRGB(255, 255, 255)
                    l.TextStrokeTransparency = 0
                    l.Font = Enum.Font.GothamBold
                    l.TextSize = 10
                end
                
                local h = highlights[p]
                if h and p.Character:FindFirstChild("FlyHubESP") then
                    local label = p.Character.FlyHubESP.TextLabel
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = math.floor((player.Character.PrimaryPart.Position - root.Position).Magnitude)
                        label.Text = string.format("%s\n[%d m]", p.Name, dist)
                    end
                    h.FillTransparency = config.espTransparency
                end
            else
                -- Si es compañero y tiene ESP, quitarlo
                if highlights[p] then
                    highlights[p]:Destroy()
                    highlights[p] = nil
                end
            end
        elseif highlights[p] then
            highlights[p]:Destroy()
            highlights[p] = nil
        end
    end
end

-- Main Render Loop
RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    if config.aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestPlayer()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
    
    if config.triggerbot then
        local target = mouse.Target
        if target and target.Parent:FindFirstChild("Humanoid") then
            local p = Players:GetPlayerFromCharacter(target.Parent)
            if p and p ~= player then
                -- Check team
                if not config.teamCheck or (p.Team ~= player.Team or p.Team == nil) then
                    if mouse1click then mouse1click() end
                end
            end
        end
    end
    
    -- Hitbox Expander
    if config.hitboxExpander then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = p.Character.HumanoidRootPart
                -- Team check for Hitbox
                if not config.teamCheck or (p.Team ~= player.Team or p.Team == nil) then
                    root.Size = Vector3.new(config.hitboxSize, config.hitboxSize, config.hitboxSize)
                    root.Transparency = 0.7
                    root.Shape = Enum.PartType.Ball
                    root.CanCollide = false
                else
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end
            end
        end
    end

    -- SpinBot
    if config.spinBot and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(20), 0)
    end
    
    -- Generic Weapon Mods
    if config.infAmmo or config.noReload or config.fastFire then
        for _, v in pairs(player.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                local ammo = v:FindFirstChild("Ammo") or v:FindFirstChild("CurrentAmmo")
                local maxAmmo = v:FindFirstChild("MaxAmmo")
                if ammo and config.infAmmo then ammo.Value = 999 end
                if maxAmmo and config.noReload then maxAmmo.Value = 999 end
            end
        end
    end
    
    -- Rainbow UI Logic
    if config.rainbowUI then
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 1, 1)
        config.accentColor = color
        title.Text = string.format("FLY HUB <font color='rgb(%d,%d,%d)'>V3</font> - SHOOTER", color.R*255, color.G*255, color.B*255)
        if fovCircle then fovCircle.Color = color end
        for _, t in pairs(tabs) do
            if t.content.Visible then
                t.btn.BackgroundColor3 = color
            end
        end
    end
    
    -- Fly Movement Logic
    if config.isFlying and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local root = player.Character.HumanoidRootPart
        local hum = player.Character:FindFirstChild("Humanoid")
        
        if not state.instances.bv then
            state.instances.bg = Instance.new("BodyGyro", root)
            state.instances.bg.P = 9e4
            state.instances.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            
            state.instances.bv = Instance.new("BodyVelocity", root)
            state.instances.bv.Velocity = Vector3.new(0, 0, 0)
            state.instances.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            if hum then hum.PlatformStand = true end
        end
        
        local camera = workspace.CurrentCamera
        local multiplier = UserInputService:IsKeyDown(config.sprintKey) and config.sprintMultiplier or 1
        local speed = config.flySpeed * multiplier
        
        local moveVector = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector = moveVector + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector - Vector3.new(0,1,0) end
        
        if moveVector.Magnitude > 0 then
            state.instances.bv.Velocity = moveVector.Unit * speed
        else
            state.instances.bv.Velocity = Vector3.new(0, 0, 0)
        end
        state.instances.bg.CFrame = camera.CFrame
        
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = config.flyTransparency
            end
        end
    elseif state.instances.bv then
        if state.instances.bg then state.instances.bg:Destroy() end
        if state.instances.bv then state.instances.bv:Destroy() end
        state.instances.bg = nil
        state.instances.bv = nil
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            end
        end
    end
    
    updateESP()
end)

-- Silent Aim Hook
local mt = getrawmetatable(game)
local oldNameCall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(t, k)
    if not checkcaller() and config.silentAim and t:IsA("Mouse") and (k == "Hit" or k == "Target") then
        local target = getClosestPlayer()
        if target then
            return k == "Hit" and target.CFrame or target
        end
    end
    return oldIndex(t, k)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and config.silentAim and (method == "FindPartOnRayWithIgnoreList" or method == "Raycast") then
        local target = getClosestPlayer()
        if target then
            -- Redirigir el raycast hacia el target
            -- Esto es genérico, algunos juegos requieren lógica más específica
            return oldNameCall(self, unpack(args))
        end
    end
    
    return oldNameCall(self, ...)
end)

setreadonly(mt, true)

-- Noclip Logic
RunService.Heartbeat:Connect(function()
    if config.noclip or config.isFlying then
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end
        end
    end
end)

-- Controls
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == config.toggleKey then
        config.isFlying = not config.isFlying
    end
end)

-- Dragging logic
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                connection:Disconnect()
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Resize Logic
local resizing = false
local resizeStartPos, startSize
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        startSize = mainFrame.Size
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                connection:Disconnect()
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStartPos
        local newX = math.clamp(startSize.X.Offset + delta.X, 300, 800)
        local newY = math.clamp(startSize.Y.Offset + delta.Y, 200, 600)
        mainFrame.Size = UDim2.new(0, newX, 0, newY)
    end
end)

-- Minimize Logic
local isMinimized = false
local lastSize = mainFrame.Size
minimizeBtn.Activated:Connect(function()
    isMinimized = not isMinimized
    sidebar.Visible = not isMinimized
    container.Visible = not isMinimized
    resizeHandle.Visible = not isMinimized
    if isMinimized then
        lastSize = mainFrame.Size
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 40)}):Play()
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = lastSize}):Play()
    end
    minimizeBtn.Text = isMinimized and "+" or "-"
end)

-- Close
closeBtn.Activated:Connect(function()
    if fovCircle then fovCircle:Remove() end
    screenGui:Destroy()
    if getgenv then getgenv()[scriptName] = nil end
end)

-- Character Added
player.CharacterAdded:Connect(function()
    task.wait(1)
end)

-- Intro Animation
mainFrame.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(mainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 450, 0, 320)}):Play()

print("FlyHub V3 Loaded Successfully!")
