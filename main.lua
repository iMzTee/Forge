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
    local args = {...}
    pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(table.unpack(args))
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(table.unpack(args))
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
        local bg = flyBody.Parent and flyBody.Parent:FindFirstChildOfClass("BodyGyro")
        if bg then bg:Destroy() end
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
    panel   = Color3.fromRGB(22,22,32),
    item    = Color3.fromRGB(30,30,45),
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
mainFrame.Size = UDim2.new(0.92, 0, 0, 420)
mainFrame.Position = UDim2.new(0.04, 0, 0.06, 0)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0.5, 0)
tbFix.Position = UDim2.new(0, 0, 0.5, 0)
tbFix.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
tbFix.BorderSizePixel = 0
tbFix.Parent = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -80, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "THE FORGE SCRIPT v2.0"
titleLbl.TextColor3 = C.accent
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local minimized = false
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 24)
minBtn.Position = UDim2.new(1, -68, 0, 7)
minBtn.BackgroundColor3 = C.off
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 24)
closeBtn.Position = UDim2.new(1, -34, 0, 7)
closeBtn.BackgroundColor3 = C.danger
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- Tab bar (horizontal, under title)
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -8, 0, 36)
tabBar.Position = UDim2.new(0, 4, 0, 42)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabBarLayout = Instance.new("UIListLayout")
tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
tabBarLayout.Padding = UDim.new(0, 4)
tabBarLayout.Parent = tabBar

-- Page container
local pageContainer = Instance.new("Frame")
pageContainer.Name = "Pages"
pageContainer.Size = UDim2.new(1, -8, 1, -88)
pageContainer.Position = UDim2.new(0, 4, 0, 82)
pageContainer.BackgroundTransparency = 1
pageContainer.Parent = mainFrame

-- Minimize logic
local function setMinimized(state)
    minimized = state
    tabBar.Visible = not state
    pageContainer.Visible = not state
    mainFrame.Size = state and UDim2.new(0.92, 0, 0, 42) or UDim2.new(0.92, 0, 0, 420)
    minBtn.Text = state and "+" or "-"
end
minBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

-- Pages and tabs
local pages = {}
local activeTab = nil

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.accent
    page.BorderSizePixel = 0
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Parent = pageContainer
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page
    Instance.new("UIPadding", page).PaddingTop = UDim.new(0, 4)
    pages[name] = page
    return page
end

local function makeTab(name, label)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.BackgroundColor3 = C.item
    btn.Text = label
    btn.TextColor3 = C.sub
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.btn.BackgroundColor3 = C.item
            activeTab.btn.TextColor3 = C.sub
            if pages[activeTab.name] then pages[activeTab.name].Visible = false end
        end
        btn.BackgroundColor3 = C.accent
        btn.TextColor3 = Color3.fromRGB(10, 10, 10)
        if pages[name] then pages[name].Visible = true end
        activeTab = {btn = btn, name = name}
    end)
    return btn
end

-- Toggle helper
local function makeToggle(parent, label, desc, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, desc and 58 or 42)
    row.BackgroundColor3 = C.item
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, desc and 8 or 10)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    if desc then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -70, 0, 18)
        sub.Position = UDim2.new(0, 10, 0, 30)
        sub.BackgroundTransparency = 1
        sub.Text = desc
        sub.TextColor3 = C.sub
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row
    end

    local state = false
    local tog = Instance.new("TextButton")
    tog.Size = UDim2.new(0, 52, 0, 28)
    tog.Position = UDim2.new(1, -60, 0.5, -14)
    tog.BackgroundColor3 = C.off
    tog.Text = "OFF"
    tog.TextColor3 = Color3.new(1,1,1)
    tog.Font = Enum.Font.GothamBold
    tog.TextSize = 12
    tog.BorderSizePixel = 0
    tog.Parent = row
    Instance.new("UICorner", tog).CornerRadius = UDim.new(0, 6)

    tog.MouseButton1Click:Connect(function()
        state = not state
        tog.BackgroundColor3 = state and C.on or C.off
        tog.Text = state and "ON" or "OFF"
        if onToggle then onToggle(state) end
    end)
    return tog
end

-- Button helper
local function makeButton(parent, label, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 40)
    btn.BackgroundColor3 = color or C.accent
    btn.Text = label
    btn.TextColor3 = color == C.item and C.text or Color3.fromRGB(10, 10, 10)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- Label helper
local function makeLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -4, 0, 32)
    lbl.BackgroundColor3 = C.panel
    lbl.Text = text
    lbl.TextColor3 = C.sub
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.BorderSizePixel = 0
    lbl.Parent = parent
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
    return lbl
end

-- =============================================
-- BUILD TABS AND PAGES
-- =============================================
local farmTab    = makeTab("Farm",    "Mine")
local forgeTab   = makeTab("Forge",   "Forge")
local sellTab    = makeTab("Sell",    "Sell")
local playerTab  = makeTab("Player",  "Player")
local tpTab      = makeTab("TP",      "TP")

local farmPage   = makePage("Farm")
local forgePage  = makePage("Forge")
local sellPage   = makePage("Sell")
local playerPage = makePage("Player")
local tpPage     = makePage("TP")

-- FARM
makeToggle(farmPage, "Auto Mine", "Tweens to nearest rock and mines", function(state)
    Settings.Mining.Enabled = state
    if state then startMining() else stopMining() end
end)
local mineStatusLabel = makeLabel(farmPage, "Status: Idle")

RunService.Heartbeat:Connect(function()
    if not mineStatusLabel or not mineStatusLabel.Parent then return end
    if miningActive and currentRock then
        mineStatusLabel.Text = "Mining: " .. currentRock.Name
    elseif miningActive then
        mineStatusLabel.Text = "Searching for rocks..."
    else
        mineStatusLabel.Text = "Status: Idle"
    end
end)

-- FORGE
makeToggle(forgePage, "Auto Forge", "Skips all forging minigames", function(state)
    Settings.Forge.Enabled = state
    if state then startForge() else stopForge() end
end)

-- SELL
makeToggle(sellPage, "Auto Sell", "Sells every 30 seconds", function(state)
    Settings.Sell.Enabled = state
    if state then startAutoSell() else stopAutoSell() end
end)
makeButton(sellPage, "Sell Now", C.on, function() doSell() end)

-- PLAYER
makeToggle(playerPage, "Noclip", "Walk through walls", function(state)
    Settings.Player.Noclip = state
    if state then startNoclip() else stopNoclip() end
end)
makeToggle(playerPage, "Fly", "WASD + Jump/Shift to fly", function(state)
    Settings.Player.Fly = state
    if state then startFly() else stopFly() end
end)
makeToggle(playerPage, "Infinite Jump", nil, function(state)
    Settings.Player.InfiniteJump = state
    if state then startInfiniteJump() else stopInfiniteJump() end
end)
makeToggle(playerPage, "Auto Run", nil, function(state)
    toggleAutoRun(state)
end)

-- TELEPORT
local islands = {
    {"Island 1", Vector3.new(0, 5, 0)},
    {"Island 2", Vector3.new(300, 5, 0)},
    {"Island 3", Vector3.new(600, 5, 0)},
    {"Island 4", Vector3.new(900, 5, 0)},
}
for _, data in ipairs(islands) do
    makeButton(tpPage, "-> " .. data[1], C.item, function()
        local root = getRoot()
        if root then root.CFrame = CFrame.new(data[2]) end
    end)
end

-- Activate Farm tab by default
farmTab.BackgroundColor3 = C.accent
farmTab.TextColor3 = Color3.fromRGB(10, 10, 10)
pages["Farm"].Visible = true
activeTab = {btn = farmTab, name = "Farm"}

-- Drag
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

print("[Forge Script v2.0] Loaded OK")
