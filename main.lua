-- =============================================
-- [[ THE FORGE SCRIPT ]]
-- Version 2.0 | Tween-based Mining
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- =============================================
-- [[ SETTINGS ]]
-- =============================================
local Settings = {
    Mining = {
        Enabled = false,
        TweenSpeed = 12,          -- studs/sec (higher = faster, less human)
        MineRadius = 60,          -- how far to search for rocks
        SwingDelay = 0.35,        -- seconds between pickaxe swings
        RetryDelay = 1.2,         -- delay before moving to next rock
        OreWhitelist = {},        -- empty = mine all ores
    },
    Forge = {
        Enabled = false,
        Delay = 0.5,
    },
    Sell = {
        Enabled = false,
        Interval = 30,            -- auto sell every N seconds
    },
    Player = {
        Noclip = false,
        Fly = false,
        FlySpeed = 60,
        InfiniteJump = false,
        AutoRun = false,
    },
}

-- =============================================
-- [[ REMOTE CACHE ]]
-- =============================================
local RS = ReplicatedStorage
local RemoteFolder = RS:FindFirstChild("RemoteEvents") or RS:FindFirstChild("Remotes") or RS

local function getRemote(name, folder)
    folder = folder or RS
    -- Search recursively
    local function search(obj)
        for _, child in ipairs(obj:GetChildren()) do
            if child.Name == name and (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
                return child
            end
            local found = search(child)
            if found then return found end
        end
    end
    return search(folder)
end

-- Cache remotes on startup
local Remotes = {}
task.spawn(function()
    task.wait(2)
    Remotes.ToolActivated  = getRemote("ToolActivated")
    Remotes.StartBlock     = getRemote("StartBlock")
    Remotes.StopBlock      = getRemote("StopBlock")
    Remotes.ClaimOre       = getRemote("ClaimOre")
    Remotes.StartForge     = getRemote("StartForge")
    Remotes.EndForge       = getRemote("EndForge")
    Remotes.ChangeSequence = getRemote("ChangeSequence")
    Remotes.Forge          = getRemote("Forge")
    Remotes.Sell           = getRemote("Sell")
    Remotes.SellAnywhere   = getRemote("SellAnywhere")
    Remotes.SellMisc       = getRemote("SellMisc")
    Remotes.Run            = getRemote("Run")
    Remotes.StopRun        = getRemote("StopRun")
    Remotes.Dash           = getRemote("Dash")
    Remotes.TeleportToIsland = getRemote("TeleportToIsland")
end)

-- =============================================
-- [[ UTILITY FUNCTIONS ]]
-- =============================================
local function fireRemote(name, ...)
    local remote = Remotes[name]
    if not remote then return end
    pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(...)
        end
    end)
end

local function getRoot()
    character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    character = player.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function distance(a, b)
    return (a.Position - b.Position).Magnitude
end

-- =============================================
-- [[ TWEEN MOVEMENT ]]
-- =============================================
local activeTween = nil

local function tweenToPosition(targetPos, speed)
    local root = getRoot()
    if not root then return end

    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end

    local dist = (root.Position - targetPos).Magnitude
    local duration = dist / speed

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})

    activeTween = tween
    tween:Play()
    tween.Completed:Wait()
    activeTween = nil
end

local function tweenToInstance(instance, offset, speed)
    offset = offset or Vector3.new(0, 0, 0)
    speed = speed or Settings.Mining.TweenSpeed
    local targetPos = instance.Position + offset
    tweenToPosition(targetPos, speed)
end

-- =============================================
-- [[ MINING SYSTEM ]]
-- =============================================
local miningActive = false
local currentRock = nil

local function isRock(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    local name = obj.Name:lower()
    return name:find("rock") or name:find("ore") or name:find("stone") or name:find("boulder")
end

local function getRocks()
    local rocks = {}
    local root = getRoot()
    if not root then return rocks end

    -- Search workspace for rock/ore objects
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and isRock(obj) then
            local d = distance(root, obj)
            if d <= Settings.Mining.MineRadius then
                -- Filter by whitelist if set
                if #Settings.Mining.OreWhitelist == 0 then
                    table.insert(rocks, obj)
                else
                    for _, allowed in ipairs(Settings.Mining.OreWhitelist) do
                        if obj.Name:lower():find(allowed:lower()) then
                            table.insert(rocks, obj)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Sort by distance
    table.sort(rocks, function(a, b)
        local ra = getRoot()
        if not ra then return false end
        return distance(ra, a) < distance(ra, b)
    end)

    return rocks
end

local function mineRock(rock)
    if not rock or not rock.Parent then return end
    currentRock = rock

    local root = getRoot()
    if not root then return end

    -- Tween to safe distance behind the rock
    local dir = (root.Position - rock.Position).Unit
    local targetPos = rock.Position + dir * 5 + Vector3.new(0, 3, 0)
    tweenToPosition(targetPos, Settings.Mining.TweenSpeed)

    -- Face the rock
    pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, rock.Position)
    end)

    -- Fire start interaction
    fireRemote("StartBlock", rock)
    task.wait(0.1)

    -- Swing pickaxe repeatedly until rock is gone
    local swings = 0
    while rock and rock.Parent and miningActive do
        fireRemote("ToolActivated", rock)
        swings = swings + 1
        task.wait(Settings.Mining.SwingDelay)

        if swings > 30 then break end -- safety cap
    end

    -- Claim ore
    task.wait(0.2)
    fireRemote("ClaimOre", rock)
    fireRemote("StopBlock", rock)

    currentRock = nil
    task.wait(Settings.Mining.RetryDelay)
end

local function startMining()
    miningActive = true
    task.spawn(function()
        while miningActive do
            local rocks = getRocks()
            if #rocks == 0 then
                task.wait(2)
            else
                for _, rock in ipairs(rocks) do
                    if not miningActive then break end
                    if rock and rock.Parent then
                        mineRock(rock)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopMining()
    miningActive = false
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
    currentRock = nil
end

-- =============================================
-- [[ FORGE SYSTEM ]]
-- =============================================
local forgeActive = false

local function startForge()
    forgeActive = true
    task.spawn(function()
        while forgeActive do
            pcall(function()
                fireRemote("StartForge")
                task.wait(Settings.Forge.Delay)
                fireRemote("ChangeSequence", 1)
                task.wait(Settings.Forge.Delay)
                fireRemote("ChangeSequence", 2)
                task.wait(Settings.Forge.Delay)
                fireRemote("ChangeSequence", 3)
                task.wait(Settings.Forge.Delay)
                fireRemote("Forge")
                task.wait(Settings.Forge.Delay)
                fireRemote("EndForge")
            end)
            task.wait(Settings.Forge.Delay * 2)
        end
    end)
end

local function stopForge()
    forgeActive = false
end

-- =============================================
-- [[ SELL SYSTEM ]]
-- =============================================
local sellActive = false

local function doSell()
    pcall(function()
        fireRemote("SellAnywhere")
        task.wait(0.2)
        fireRemote("Sell")
        task.wait(0.2)
        fireRemote("SellMisc")
    end)
end

local function startAutoSell()
    sellActive = true
    task.spawn(function()
        while sellActive do
            doSell()
            task.wait(Settings.Sell.Interval)
        end
    end)
end

local function stopAutoSell()
    sellActive = false
end

-- =============================================
-- [[ PLAYER FEATURES ]]
-- =============================================

-- Noclip
local noclipConn = nil
local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- Fly
local flyConn = nil
local flyBody = nil
local function startFly()
    local root = getRoot()
    if not root then return end

    flyBody = Instance.new("BodyVelocity")
    flyBody.Velocity = Vector3.zero
    flyBody.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBody.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D = 100
    bg.Parent = root

    flyConn = RunService.Heartbeat:Connect(function()
        local root2 = getRoot()
        if not root2 or not flyBody then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        flyBody.Velocity = dir.Magnitude > 0 and dir.Unit * Settings.Player.FlySpeed or Vector3.zero
        bg.CFrame = cam.CFrame
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBody then
        flyBody.Parent:FindFirstChildOfClass("BodyGyro"):Destroy()
        flyBody:Destroy()
        flyBody = nil
    end
end

-- Infinite Jump
local jumpConn = nil
local function startInfiniteJump()
    jumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
local function stopInfiniteJump()
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
end

-- Auto Run
local function toggleAutoRun(state)
    Settings.Player.AutoRun = state
    if state then
        fireRemote("Run")
    else
        fireRemote("StopRun")
    end
end

-- =============================================
-- [[ CHARACTER RESPAWN HANDLER ]]
-- =============================================
player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(1)
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    if Settings.Mining.Enabled then startMining() end
    if Settings.Player.Noclip then startNoclip() end
    if Settings.Player.Fly then startFly() end
    if Settings.Player.InfiniteJump then startInfiniteJump() end
    if Settings.Player.AutoRun then toggleAutoRun(true) end
end)

-- =============================================
-- [[ GUI ]]
-- =============================================
local existing = player.PlayerGui:FindFirstChild("ForgeScript_GUI")
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ForgeScript_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local C = {
    bg      = Color3.fromRGB(13,13,18),
    sidebar = Color3.fromRGB(18,18,26),
    panel   = Color3.fromRGB(22,22,32),
    item    = Color3.fromRGB(28,28,42),
    accent  = Color3.fromRGB(255,200,50),
    text    = Color3.fromRGB(210,210,220),
    sub     = Color3.fromRGB(130,130,150),
    off     = Color3.fromRGB(55,55,70),
    on      = Color3.fromRGB(50,200,100),
    danger  = Color3.fromRGB(200,50,50),
}

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0,560,0,400)
mainFrame.Position = UDim2.new(0.5,-280,0.5,-200)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner",mainFrame).CornerRadius = UDim.new(0,10)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundColor3 = C.sidebar
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner",titleBar).CornerRadius = UDim.new(0,10)
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1,0,0.5,0)
titleFix.Position = UDim2.new(0,0,0.5,0)
titleFix.BackgroundColor3 = C.sidebar
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,-20,1,0)
titleLabel.Position = UDim2.new(0,14,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚒ THE FORGE SCRIPT v2.0"
titleLabel.TextColor3 = C.accent
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Minimize / Close
local minimized = false
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,28,0,22)
closeBtn.Position = UDim2.new(1,-32,0,7)
closeBtn.BackgroundColor3 = C.danger
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner",closeBtn).CornerRadius = UDim.new(0,4)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,28,0,22)
minBtn.Position = UDim2.new(1,-64,0,7)
minBtn.BackgroundColor3 = C.off
minBtn.Text = "—"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 12
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar
Instance.new("UICorner",minBtn).CornerRadius = UDim.new(0,4)

-- Content area
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1,0,1,-36)
content.Position = UDim2.new(0,0,0,36)
content.BackgroundTransparency = 1
content.Parent = mainFrame

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    mainFrame.Size = minimized and UDim2.new(0,560,0,36) or UDim2.new(0,560,0,400)
end)

-- Sidebar tabs
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0,110,1,0)
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = content
Instance.new("UICorner",sidebar).CornerRadius = UDim.new(0,8)
local sidebarFix = Instance.new("Frame")
sidebarFix.Size = UDim2.new(0.5,0,1,0)
sidebarFix.Position = UDim2.new(0.5,0,0,0)
sidebarFix.BackgroundColor3 = C.sidebar
sidebarFix.BorderSizePixel = 0
sidebarFix.Parent = sidebar

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Vertical
tabList.Padding = UDim.new(0,4)
tabList.Parent = sidebar
Instance.new("UIPadding",sidebar).PaddingTop = UDim.new(0,8)

-- Right panel
local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(1,-118,1,-8)
rightPanel.Position = UDim2.new(0,118,0,4)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = content

-- Pages container
local pages = {}
local activeTab = nil

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.accent
    page.BorderSizePixel = 0
    page.Visible = false
    page.Parent = rightPanel
    Instance.new("UIListLayout",page).Padding = UDim.new(0,6)
    Instance.new("UIPadding",page).PaddingTop = UDim.new(0,4)
    pages[name] = page
    return page
end

local function makeTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-12,0,36)
    btn.Position = UDim2.new(0,6,0,0)
    btn.BackgroundColor3 = C.item
    btn.Text = icon .. " " .. name
    btn.TextColor3 = C.sub
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = sidebar
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.btn.BackgroundColor3 = C.item
            activeTab.btn.TextColor3 = C.sub
            if pages[activeTab.name] then pages[activeTab.name].Visible = false end
        end
        btn.BackgroundColor3 = C.accent
        btn.TextColor3 = Color3.fromRGB(10,10,10)
        if pages[name] then pages[name].Visible = true end
        activeTab = {btn=btn, name=name}
    end)

    return btn
end

-- Helper: toggle button
local function makeToggle(parent, label, desc, initialState, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-8,0,52)
    row.BackgroundColor3 = C.item
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-70,0,24)
    lbl.Position = UDim2.new(0,12,0,6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    if desc then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1,-70,0,18)
        sub.Position = UDim2.new(0,12,0,28)
        sub.BackgroundTransparency = 1
        sub.Text = desc
        sub.TextColor3 = C.sub
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row
    end

    local state = initialState or false
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0,48,0,26)
    toggle.Position = UDim2.new(1,-58,0.5,-13)
    toggle.BackgroundColor3 = state and C.on or C.off
    toggle.Text = state and "ON" or "OFF"
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 11
    toggle.BorderSizePixel = 0
    toggle.Parent = row
    Instance.new("UICorner",toggle).CornerRadius = UDim.new(0,6)

    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and C.on or C.off
        toggle.Text = state and "ON" or "OFF"
        if onToggle then onToggle(state) end
    end)

    return toggle
end

-- Helper: action button
local function makeButton(parent, label, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-8,0,38)
    btn.BackgroundColor3 = color or C.accent
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(10,10,10)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- =============================================
-- BUILD TABS
-- =============================================
local farmTab = makeTab("Farm", "⛏")
local forgeTab = makeTab("Forge", "🔨")
local sellTab = makeTab("Sell", "💰")
local playerTab = makeTab("Player", "🧍")
local tpTab = makeTab("Teleport", "🗺")

local farmPage = makePage("Farm")
local forgePage = makePage("Forge")
local sellPage = makePage("Sell")
local playerPage = makePage("Player")
local tpPage = makePage("Teleport")

-- FARM PAGE
makeToggle(farmPage, "Auto Mine", "Tweens to nearest ore and mines", false, function(state)
    Settings.Mining.Enabled = state
    if state then startMining() else stopMining() end
end)

local mineStatusLabel = Instance.new("TextLabel")
mineStatusLabel.Size = UDim2.new(1,-8,0,30)
mineStatusLabel.BackgroundColor3 = C.panel
mineStatusLabel.Text = "Status: Idle"
mineStatusLabel.TextColor3 = C.sub
mineStatusLabel.Font = Enum.Font.Gotham
mineStatusLabel.TextSize = 12
mineStatusLabel.BorderSizePixel = 0
mineStatusLabel.Parent = farmPage
Instance.new("UICorner",mineStatusLabel).CornerRadius = UDim.new(0,8)

RunService.Heartbeat:Connect(function()
    if miningActive and currentRock then
        mineStatusLabel.Text = "⛏ Mining: " .. currentRock.Name
    elseif miningActive then
        mineStatusLabel.Text = "🔍 Searching for rocks..."
    else
        mineStatusLabel.Text = "Status: Idle"
    end
end)

-- FORGE PAGE
makeToggle(forgePage, "Auto Forge", "Skips all forging minigames", false, function(state)
    Settings.Forge.Enabled = state
    if state then startForge() else stopForge() end
end)

-- SELL PAGE
makeToggle(sellPage, "Auto Sell", "Sells inventory every 30s", false, function(state)
    Settings.Sell.Enabled = state
    if state then startAutoSell() else stopAutoSell() end
end)
makeButton(sellPage, "Sell Now", C.on, function() doSell() end)

-- PLAYER PAGE
makeToggle(playerPage, "Noclip", "Walk through walls", false, function(state)
    Settings.Player.Noclip = state
    if state then startNoclip() else stopNoclip() end
end)
makeToggle(playerPage, "Fly", "WASD + Space/Shift to fly", false, function(state)
    Settings.Player.Fly = state
    if state then startFly() else stopFly() end
end)
makeToggle(playerPage, "Infinite Jump", "Jump anytime", false, function(state)
    Settings.Player.InfiniteJump = state
    if state then startInfiniteJump() else stopInfiniteJump() end
end)
makeToggle(playerPage, "Auto Run", "Hold run toggle", false, function(state)
    toggleAutoRun(state)
end)

-- TELEPORT PAGE
local islands = {
    {"Island 1 (Starter)", Vector3.new(0, 5, 0)},
    {"Island 2", Vector3.new(300, 5, 0)},
    {"Island 3", Vector3.new(600, 5, 0)},
    {"Island 4", Vector3.new(900, 5, 0)},
}

for _, data in ipairs(islands) do
    makeButton(tpPage, "→ " .. data[1], C.item, function()
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(data[2])
        end
    end)
end

-- Activate first tab
farmTab:FireMouseButton1Click()

-- =============================================
-- DRAG SUPPORT
-- =============================================
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

print("[Forge Script v2.0] Loaded successfully!")
