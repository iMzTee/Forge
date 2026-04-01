-- =============================================
-- THE FORGE SCRIPT v1.0
-- =============================================

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local function getHRP()
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    return character and character:FindFirstChildWhichIsA("Humanoid")
end

-- [[ REMOTES ]]
local RF_FOLDER = ReplicatedStorage:WaitForChild("RF", 10)
local RE_FOLDER = ReplicatedStorage:WaitForChild("RE", 10)

local function getRemote(folder, name)
    if not folder then return nil end
    return folder:FindFirstChild(name)
end

local Remotes = {}
if RF_FOLDER then
    Remotes.StartForge       = getRemote(RF_FOLDER, "StartForge")
    Remotes.EndForge         = getRemote(RF_FOLDER, "EndForge")
    Remotes.Forge            = getRemote(RF_FOLDER, "Forge")
    Remotes.ChangeSequence   = getRemote(RF_FOLDER, "ChangeSequence")
    Remotes.Claim            = getRemote(RF_FOLDER, "Claim")
    Remotes.ClaimOre         = getRemote(RF_FOLDER, "ClaimOre")
    Remotes.ClaimEnemy       = getRemote(RF_FOLDER, "ClaimEnemy")
    Remotes.ToolActivated    = getRemote(RF_FOLDER, "ToolActivated")
    Remotes.StartBlock       = getRemote(RF_FOLDER, "StartBlock")
    Remotes.StopBlock        = getRemote(RF_FOLDER, "StopBlock")
    Remotes.Activate         = getRemote(RF_FOLDER, "Activate")
    Remotes.Dash             = getRemote(RF_FOLDER, "Dash")
    Remotes.Run              = getRemote(RF_FOLDER, "Run")
    Remotes.StopRun          = getRemote(RF_FOLDER, "StopRun")
    Remotes.Sell             = getRemote(RF_FOLDER, "Sell")
    Remotes.SellAnywhere     = getRemote(RF_FOLDER, "SellAnywhere")
    Remotes.SellMisc         = getRemote(RF_FOLDER, "SellMisc")
    Remotes.Purchase         = getRemote(RF_FOLDER, "Purchase")
    Remotes.RedeemCode       = getRemote(RF_FOLDER, "RedeemCode")
    Remotes.EquipItem        = getRemote(RF_FOLDER, "EquipItem")
    Remotes.SwitchSlot       = getRemote(RF_FOLDER, "SwitchSlot")
    Remotes.ClientTrackQuest = getRemote(RF_FOLDER, "ClientTrackQuest")
    Remotes.ProgressUIQuest  = getRemote(RF_FOLDER, "ProgressUIQuest")
    Remotes.TeleportToIsland = getRemote(RF_FOLDER, "TeleportToIsland")
    Remotes.GetRemainingTime = getRemote(RF_FOLDER, "GetRemainingTime")
    Remotes.Reroll           = getRemote(RF_FOLDER, "Reroll")
    Remotes.Reset            = getRemote(RF_FOLDER, "Reset")
    Remotes.GetPlayerEquipmentInfo = getRemote(RF_FOLDER, "GetPlayerEquipmentInfo")
    Remotes.DialogueRemote   = ReplicatedStorage:FindFirstChild("DialogueEvents") and
                               ReplicatedStorage.DialogueEvents:FindFirstChild("DialogueRemote")
    Remotes.HammerMinigame   = ReplicatedStorage:FindFirstChild("HammerMinigame") and
                               ReplicatedStorage.HammerMinigame:FindFirstChild("RemoteFunction")
end

-- [[ ORE POOLS PER ROCK ]]
local rockOrePool = {
    ["Pebble"]           = {"Stone","Sand Stone","Copper","Iron","Poopite"},
    ["Rock"]             = {"Sand Stone","Copper","Iron","Tin","Silver","Cardboardite","Mushroomite","Bananite","Poopite"},
    ["Boulder"]          = {"Copper","Iron","Tin","Silver","Gold","Cardboardite","Mushroomite","Bananite","Aite","Platinum","Poopite"},
    ["Basalt Rock"]      = {"Cobalt","Titanium","Lapis Lazuli","Eye Ore"},
    ["Basalt Core"]      = {"Cobalt","Titanium","Lapis Lazuli","Quartz","Amethyst","Topaz","Diamond","Sapphire","Cuprite","Emerald","Eye Ore"},
    ["Basalt Vein"]      = {"Quartz","Amethyst","Topaz","Diamond","Sapphire","Cuprite","Emerald","Ruby","Rivalite","Uranium","Mythril","Lightite","Eye Ore"},
    ["Volcanic Rock"]    = {"Volcanic Rock Ore","Topaz","Cuprite","Obsidian","Rivalite","Eye Ore","Fireite","Magmaite","Demonite","Darkryte"},
    ["Icy Pebble"]       = {"Tungsten","Sulfur","Pumice","Aetherit","Emerald","Ruby","Rivalite","Uranium","Mythril"},
    ["Icy Rock"]         = {"Tungsten","Sulfur","Pumice","Graphite","Aetherit","Scheelite","Larimar","Neurotite"},
    ["Icy Boulder"]      = {"Tungsten","Sulfur","Pumice","Graphite","Aetherit","Scheelite","Larimar","Neurotite","Frost Fossil","Tide Carve","Velchire","Sanctis","Snowite"},
    ["Small Ice Crystal"]  = {"Aetherit","Scheelite","Mistvein","Lgarite","Voidfractal","Suryafal"},
    ["Medium Ice Crystal"] = {"Mistvein","Lgarite","Voidfractal","Moltenfrost","Crimsonite","Malachite","Aquajade","Cryptex","Galestor","Iceite","Etherealite","Voidstar"},
    ["Large Ice Crystal"]  = {"Mistvein","Lgarite","Voidfractal","Moltenfrost","Crimsonite","Malachite","Aquajade","Cryptex","Galestor","Iceite","Etherealite","Voidstar"},
    ["Floating Crystal"]   = {"Mistvein","Lgarite","Voidfractal","Moltenfrost","Crimsonite","Malachite","Aquajade","Cryptex","Galestor","Suryafal","Voidstar"},
    ["Crimson Crystal"]  = {"Magenta Crystal Ore","Crimson Crystal Ore","Green Crystal Ore","Orange Crystal Ore","Blue Crystal Ore","Rainbow Crystal Ore","Arcane Crystal Ore","Galaxite"},
    ["Cyan Crystal"]     = {"Magenta Crystal Ore","Crimson Crystal Ore","Green Crystal Ore","Orange Crystal Ore","Blue Crystal Ore","Rainbow Crystal Ore","Arcane Crystal Ore","Galaxite"},
    ["Earth Crystal"]    = {"Magenta Crystal Ore","Crimson Crystal Ore","Green Crystal Ore","Orange Crystal Ore","Blue Crystal Ore","Rainbow Crystal Ore","Arcane Crystal Ore","Galaxite"},
    ["Light Crystal"]    = {"Magenta Crystal Ore","Crimson Crystal Ore","Green Crystal Ore","Orange Crystal Ore","Blue Crystal Ore","Rainbow Crystal Ore","Arcane Crystal Ore","Galaxite"},
    ["Small Red Crystal"]  = {"Frogite","Moon Stone"},
    ["Medium Red Crystal"] = {"Frogite","Moon Stone","Gulabite","Coinite"},
    ["Large Red Crystal"]  = {"Moon Stone","Gulabite","Coinite","Duranite","Evil Eye"},
    ["Heart of the Island"]= {"Moon Stone","Gulabite","Coinite","Duranite","Evil Eye","Heart of the Island Ore","Stolen Heart"},
}

-- [[ ORE RARITY ]]
local oreRarity = {
    ["Stone"]="Common",["Sand Stone"]="Common",["Copper"]="Common",["Iron"]="Common",["Cardboardite"]="Common",["Tungsten"]="Common",
    ["Tin"]="Uncommon",["Silver"]="Uncommon",["Gold"]="Uncommon",["Bananite"]="Uncommon",["Cobalt"]="Uncommon",["Titanium"]="Uncommon",["Lapis Lazuli"]="Uncommon",["Sulfur"]="Uncommon",
    ["Mushroomite"]="Rare",["Platinum"]="Rare",["Volcanic Rock Ore"]="Rare",["Quartz"]="Rare",["Amethyst"]="Rare",["Topaz"]="Rare",["Diamond"]="Rare",["Sapphire"]="Rare",["Pumice"]="Rare",["Graphite"]="Rare",["Aetherit"]="Rare",["Scheelite"]="Rare",["Mistvein"]="Rare",["Lgarite"]="Rare",["Voidfractal"]="Rare",
    ["Aite"]="Epic",["Poopite"]="Epic",["Cuprite"]="Epic",["Obsidian"]="Epic",["Emerald"]="Epic",["Ruby"]="Epic",["Rivalite"]="Epic",["Magenta Crystal Ore"]="Epic",["Crimson Crystal Ore"]="Epic",["Green Crystal Ore"]="Epic",["Orange Crystal Ore"]="Epic",["Blue Crystal Ore"]="Epic",["Larimar"]="Epic",["Neurotite"]="Epic",["Frost Fossil"]="Epic",["Tide Carve"]="Epic",["Moltenfrost"]="Epic",["Crimsonite"]="Epic",["Malachite"]="Epic",["Aquajade"]="Epic",["Cryptex"]="Epic",["Galestor"]="Epic",["Frogite"]="Epic",
    ["Uranium"]="Legendary",["Mythril"]="Legendary",["Eye Ore"]="Legendary",["Fireite"]="Legendary",["Magmaite"]="Legendary",["Lightite"]="Legendary",["Rainbow Crystal Ore"]="Legendary",["Velchire"]="Legendary",["Sanctis"]="Legendary",["Snowite"]="Legendary",["Voidstar"]="Legendary",["Prismatic Heart"]="Legendary",["Moon Stone"]="Legendary",["Gulabite"]="Legendary",["Coinite"]="Legendary",
    ["Demonite"]="Mythical",["Darkryte"]="Mythical",["Iceite"]="Mythical",["Arcane Crystal Ore"]="Mythical",["Etherealite"]="Mythical",["Yeti Heart"]="Mythical",["Duranite"]="Mythical",["Evil Eye"]="Mythical",
    ["Suryafal"]="Relic",["Heart of the Island Ore"]="Relic",
    ["Mosasaursit"]="Exotic",
    ["Galaxite"]="Divine",["Stolen Heart"]="Divine",
}

local rarityOrder = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythical=6,Relic=7,Exotic=8,Divine=9}

-- [[ SETTINGS ]]
local Settings = {
    Mining = {
        Enabled=false, Position="Above", RockDistance=5, TweenSpeed=50,
        MineDelay=0.1, AutoSwing=true, AutoSwapper=true, SkipMined=true,
        SkipUndesiredRocks=false, AvoidEnemies=false, KillNearby=false,
        SetCamera=false, SelectedRocks={}, SelectedOres={}, OrePriority={},
        RockPriority={}, ZoneFilter="All", LavaMode="Skip",
    },
    Combat = {
        Enabled=false, Position="Above", Distance=12, VerticalOffset=20,
        TweenSpeed=60, RepositionThreshold=3, AutoDodge=true, SetCamera=false,
        SelectedMobs={}, MobPriority={}, LevelMin=1, LevelMax=9999, HPThreshold=20,
        GiantMode=false,
    },
    Forging  = {AutoForge=false},
    Items    = {AutoSell=false, SellWhenFull=false, SellByRarity="Epic", AutoUsePotions=false,
                AutoBuyPotions=false, AutoRaceReroll=false, TargetRace="", InventoryThreshold=80},
    Quests   = {AutoQuest=false, AutoClaim=false, AutoIndex=false, RedeemCodes=false},
    Player   = {AutoRun=false, Noclip=false, Fly=false, InfiniteJump=false,
                WalkSpeed=16, JumpPower=50, Gravity=196.2,
                StaffDetection=true, AutoRejoin=false},
    Visuals  = {RockESP=false, OreESP=false, MobESP=false, PlayerESP=false,
                Fullbright=false, BrightnessValue=2, ESPDistance=200},
    Webhook  = {URL="", NotifyOres=false, NotifyQuests=false, NotifyMaterials=false,
                OreWhitelist={}, RarityPriority="Epic", AutoSendStats=false,
                AutoSendInventory=false, StatInterval=300},
    Config   = {MenuKey=Enum.KeyCode.RightShift, Theme="Dark", AntiAFK=true, FPSBoost=false},
}

-- [[ STATE ]]
local State = {
    combatConnection=nil, facingConnection=nil,
    noclipConnection=nil, flyConnection=nil,
    flyBodyVelocity=nil, flyBodyGyro=nil, isFlying=false,
    espHighlights={},
    sessionStats={oresCollected=0,enemiesKilled=0,goldEarned=0,questsCompleted=0,startTime=os.time()},
}

-- =============================================
-- [[ UTILITY ]]
-- =============================================

local function safeInvoke(remote, ...)
    if not remote then return nil end
    local ok, res = pcall(remote.InvokeServer, remote, ...)
    return ok and res or nil
end

local function safeFire(remote, ...)
    if not remote then return end
    pcall(remote.FireServer, remote, ...)
end

local function tweenTo(targetPos, speed)
    local hrp = getHRP()
    if not hrp then return end
    speed = speed or Settings.Mining.TweenSpeed
    local dist = (hrp.Position - targetPos).Magnitude
    if dist < 0.5 then return end
    local t = TweenService:Create(hrp, TweenInfo.new(math.max(0.1, dist/speed), Enum.EasingStyle.Linear), {CFrame=CFrame.new(targetPos)})
    t:Play(); t.Completed:Wait()
end

local function faceTarget(pos)
    local hrp = getHRP()
    if not hrp then return end
    local look = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
    if (hrp.Position - look).Magnitude > 0.1 then
        hrp.CFrame = CFrame.lookAt(hrp.Position, look)
    end
end

-- [[ ROCK / MOB DETECTION ]]
local function isRock(m)
    return m:IsA("Model") and m:FindFirstChild("Hitbox") and m:FindFirstChild("infoFrame") and not m:FindFirstChildWhichIsA("Humanoid")
end

local function isMob(m)
    return m:IsA("Model") and m~=character and m:FindFirstChildWhichIsA("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("infoFrame")
end

local function getBillboardLabel(model, labelName)
    local bb = model:FindFirstChild("infoFrame")
    return bb and bb:FindFirstChild(labelName, true)
end

local function getRockName(m)  local l = getBillboardLabel(m,"rockName"); return l and l.Text or m.Name end
local function getRockHP(m)    local l = getBillboardLabel(m,"rockHP");   return l and tonumber(l.Text) end
local function getMobName(m)   local l = getBillboardLabel(m,"rockName"); return l and l.Text or m.Name end
local function getMobHP(m)     local l = getBillboardLabel(m,"rockHP");   return l and tonumber(l.Text) end
local function getMobLevel(m)  local l = getBillboardLabel(m,"Lvl");      return l and tonumber(l.Text) or 1 end

local function isMobAttacking(mob)
    local s = mob:FindFirstChild("Status")
    if s then local a = s:FindFirstChild("Attacking"); return a and a.Value end
    return false
end

local function getOrePosition(rock)
    local h = rock:FindFirstChild("Hitbox")
    if h then local a = h:FindFirstChild("OrePosition"); if a then return a.WorldPosition end; return h.Position end
    return rock:GetPivot().Position
end

local function getBehindAndAbove(enemyRoot)
    local back = -enemyRoot.CFrame.LookVector
    return Vector3.new(
        enemyRoot.Position.X + back.X * Settings.Combat.Distance,
        enemyRoot.Position.Y + Settings.Combat.VerticalOffset,
        enemyRoot.Position.Z + back.Z * Settings.Combat.Distance
    )
end

local function rockCanDropDesiredOre(rockName)
    if not next(Settings.Mining.SelectedOres) then return true end
    local pool = rockOrePool[rockName]
    if not pool then return true end
    for _, ore in pairs(pool) do if Settings.Mining.SelectedOres[ore] then return true end end
    return false
end

local function getSortedRocks()
    local hrp = getHRP()
    if not hrp then return {} end
    local list = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if isRock(v) then
            local name = getRockName(v)
            if Settings.Mining.SkipUndesiredRocks and not rockCanDropDesiredOre(name) then continue end
            if next(Settings.Mining.SelectedRocks) and not Settings.Mining.SelectedRocks[name] then continue end
            local h = v:FindFirstChild("Hitbox")
            if h then
                table.insert(list, {
                    model=v, name=name,
                    distance=(hrp.Position-h.Position).Magnitude,
                    priority=Settings.Mining.RockPriority[name] or 0,
                })
            end
        end
    end
    table.sort(list, function(a,b)
        if a.priority~=b.priority then return a.priority>b.priority end
        return a.distance<b.distance
    end)
    return list
end

local function getSortedMobs()
    local hrp = getHRP()
    if not hrp then return {} end
    local list = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if isMob(v) then
            local name = getMobName(v)
            local lvl  = getMobLevel(v)
            if next(Settings.Combat.SelectedMobs) and not Settings.Combat.SelectedMobs[name] then continue end
            if lvl < Settings.Combat.LevelMin or lvl > Settings.Combat.LevelMax then continue end
            local root = v:FindFirstChild("HumanoidRootPart")
            if root then
                table.insert(list, {
                    model=v, name=name,
                    distance=(hrp.Position-root.Position).Magnitude,
                    priority=Settings.Combat.MobPriority[name] or 0,
                })
            end
        end
    end
    table.sort(list, function(a,b)
        if a.priority~=b.priority then return a.priority>b.priority end
        return a.distance<b.distance
    end)
    return list
end

-- =============================================
-- [[ SYSTEMS ]]
-- =============================================

-- Auto Swapper
local function equipPickaxe() safeInvoke(Remotes.SwitchSlot, 1) end
local function equipWeapon()  safeInvoke(Remotes.SwitchSlot, 2) end

-- Mining
local miningActive = false
local miningThread = nil

local function stopMining()
    miningActive = false
    safeInvoke(Remotes.StopBlock)
end

local function startMining()
    if miningActive then return end
    miningActive = true
    miningThread = task.spawn(function()
        while miningActive and Settings.Mining.Enabled do
            local hrp = getHRP(); local hum = getHumanoid()
            if not hrp or not hum then task.wait(0.5) continue end
            if hum.Health/hum.MaxHealth*100 <= Settings.Combat.HPThreshold then task.wait(1) continue end
            if Settings.Mining.AutoSwapper then equipPickaxe(); task.wait(0.1) end

            local rocks = getSortedRocks()
            if #rocks == 0 then task.wait(1) continue end

            local rock = rocks[1]
            local orePos = getOrePosition(rock.model)
            local above = Settings.Mining.Position == "Above"
            local dir = (hrp.Position - orePos)
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude > 0 then dir = dir.Unit end
            local targetPos = Vector3.new(
                orePos.X + dir.X * Settings.Mining.RockDistance,
                orePos.Y + (above and 10 or -5),
                orePos.Z + dir.Z * Settings.Mining.RockDistance
            )

            tweenTo(targetPos, Settings.Mining.TweenSpeed)
            faceTarget(orePos)

            local hitbox = rock.model:FindFirstChild("Hitbox")
            if not hitbox then task.wait(0.2) continue end

            safeInvoke(Remotes.StartBlock, hitbox)

            while miningActive and Settings.Mining.Enabled do
                local hp = getRockHP(rock.model)
                if not hp or hp <= 0 or not rock.model.Parent then break end

                if Settings.Mining.AvoidEnemies then
                    for _, v in pairs(workspace:GetDescendants()) do
                        if isMob(v) then
                            local r = v:FindFirstChild("HumanoidRootPart")
                            if r and (hrp.Position-r.Position).Magnitude < 20 then
                                safeInvoke(Remotes.StopBlock)
                                task.wait(0.5)
                                break
                            end
                        end
                    end
                end

                if Settings.Mining.KillNearby then
                    for _, v in pairs(workspace:GetDescendants()) do
                        if isMob(v) then
                            local r = v:FindFirstChild("HumanoidRootPart")
                            if r and (hrp.Position-r.Position).Magnitude < 15 then
                                safeInvoke(Remotes.Activate, v); task.wait(0.1)
                            end
                        end
                    end
                end

                if Settings.Mining.AutoSwing then
                    safeInvoke(Remotes.ToolActivated)
                end

                faceTarget(orePos)
                task.wait(Settings.Mining.MineDelay)
            end

            safeInvoke(Remotes.StopBlock)
            task.wait(0.2)
            safeInvoke(Remotes.ClaimOre)
            State.sessionStats.oresCollected += 1

            -- Webhook ore notify
            if Settings.Webhook.NotifyOres and Settings.Webhook.URL ~= "" then
                task.spawn(function()
                    pcall(function()
                        local data = HttpService:JSONEncode({
                            embeds={{title="Ore Mined",description="Rock: "..rock.name,color=16776960,timestamp=DateTime.now():ToIsoDate()}}
                        })
                        HttpService:PostAsync(Settings.Webhook.URL, data, Enum.HttpContentType.ApplicationJson)
                    end)
                end)
            end

            task.wait(0.1)
        end
        miningActive = false
    end)
end

-- Combat
local combatActive = false

local function stopCombatLoop()
    if State.combatConnection then State.combatConnection:Disconnect(); State.combatConnection=nil end
    if State.facingConnection  then State.facingConnection:Disconnect();  State.facingConnection=nil  end
end

local function startCombatLoop(mob)
    stopCombatLoop()
    local enemyRoot = mob:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then return end

    State.combatConnection = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp or not enemyRoot or not mob.Parent then stopCombatLoop(); return end
        local targetPos = getBehindAndAbove(enemyRoot)
        local drift = (hrp.Position - targetPos).Magnitude
        if drift > Settings.Combat.RepositionThreshold then
            local t = TweenService:Create(hrp, TweenInfo.new(drift/Settings.Combat.TweenSpeed,Enum.EasingStyle.Linear), {CFrame=CFrame.new(targetPos)})
            t:Play()
        end
    end)

    State.facingConnection = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp or not enemyRoot then return end
        faceTarget(enemyRoot.Position)
    end)
end

local function stopCombat()
    combatActive = false
    stopCombatLoop()
end

local function startCombat()
    if combatActive then return end
    combatActive = true
    task.spawn(function()
        while combatActive and Settings.Combat.Enabled do
            local hrp = getHRP(); local hum = getHumanoid()
            if not hrp or not hum then task.wait(0.5) continue end
            if hum.Health/hum.MaxHealth*100 <= Settings.Combat.HPThreshold then task.wait(1) continue end
            if Settings.Mining.AutoSwapper then equipWeapon(); task.wait(0.1) end

            local mobs = getSortedMobs()
            if #mobs == 0 then stopCombatLoop(); task.wait(1) continue end

            local mob = mobs[1].model
            startCombatLoop(mob)
            task.wait(0.5)

            local enemyHum = mob:FindFirstChildWhichIsA("Humanoid")
            while combatActive and Settings.Combat.Enabled and mob.Parent and enemyHum and enemyHum.Health > 0 do
                local hum2 = getHumanoid()
                if not hum2 or hum2.Health/hum2.MaxHealth*100 <= Settings.Combat.HPThreshold then break end
                if Settings.Combat.AutoDodge and isMobAttacking(mob) then
                    safeInvoke(Remotes.Dash); task.wait(0.3)
                end
                safeInvoke(Remotes.Activate, mob)
                task.wait(0.1)
            end

            if mob.Parent then
                task.wait(0.2)
                safeInvoke(Remotes.ClaimEnemy, mob)
                State.sessionStats.enemiesKilled += 1
            end

            stopCombatLoop()
            task.wait(0.2)
        end
        stopCombatLoop()
        combatActive = false
    end)
end

-- Auto Forge
local function startAutoForge()
    task.spawn(function()
        while Settings.Forging.AutoForge do
            local r = safeInvoke(Remotes.StartForge)
            if r then
                task.wait(0.1); safeInvoke(Remotes.ChangeSequence)
                task.wait(0.1); safeInvoke(Remotes.EndForge)
            end
            task.wait(0.5)
        end
    end)
end

-- Auto Sell
local function startAutoSell()
    task.spawn(function()
        while Settings.Items.AutoSell do
            safeInvoke(Remotes.SellAnywhere)
            task.wait(5)
        end
    end)
end

-- Auto Potions
local function startAutoPotions()
    task.spawn(function()
        while Settings.Items.AutoUsePotions or Settings.Items.AutoBuyPotions do
            if Settings.Items.AutoBuyPotions then
                safeInvoke(Remotes.Purchase, "LuckPotion1")
                safeInvoke(Remotes.Purchase, "MinerPotion1")
            end
            task.wait(30)
        end
    end)
end

-- Auto Run
local function toggleAutoRun(v)
    if v then safeInvoke(Remotes.Run) else safeInvoke(Remotes.StopRun) end
end

-- Noclip
local function startNoclip()
    State.noclipConnection = RunService.Stepped:Connect(function()
        if character then
            for _, p in pairs(character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end
local function stopNoclip()
    if State.noclipConnection then State.noclipConnection:Disconnect(); State.noclipConnection=nil end
end

-- Fly
local function startFly()
    local hrp = getHRP(); if not hrp then return end
    local bv = Instance.new("BodyVelocity"); bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=hrp
    local bg = Instance.new("BodyGyro"); bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.CFrame=hrp.CFrame; bg.Parent=hrp
    State.flyBodyVelocity=bv; State.flyBodyGyro=bg; State.isFlying=true
    State.flyConnection = RunService.Heartbeat:Connect(function()
        local hrp2=getHRP(); if not hrp2 or not State.isFlying then return end
        local speed=Settings.Player.WalkSpeed*2; local cam=workspace.CurrentCamera
        local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
        bv.Velocity = (dir.Magnitude>0 and dir.Unit or Vector3.zero)*speed
        bg.CFrame = cam.CFrame
    end)
end
local function stopFly()
    State.isFlying=false
    if State.flyConnection then State.flyConnection:Disconnect(); State.flyConnection=nil end
    if State.flyBodyVelocity then State.flyBodyVelocity:Destroy(); State.flyBodyVelocity=nil end
    if State.flyBodyGyro    then State.flyBodyGyro:Destroy();    State.flyBodyGyro=nil    end
end

-- Infinite Jump
local ijConn
local function startInfiniteJump()
    ijConn = UserInputService.JumpRequest:Connect(function()
        local h=getHumanoid(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
local function stopInfiniteJump()
    if ijConn then ijConn:Disconnect(); ijConn=nil end
end

-- Anti AFK
local function startAntiAFK()
    task.spawn(function()
        while Settings.Config.AntiAFK do
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
            task.wait(20)
        end
    end)
end

-- Codes
local knownCodes = {"RELEASE","UPDATE1","FORGE100K","SORRY","SORRY2","NEWUPDATE","HOLIDAY","NEW","FROZEN","RAVEN","ISLAND3","WORLD3","ICEBERG"}
local function redeemAllCodes()
    task.spawn(function()
        for _, code in pairs(knownCodes) do
            safeInvoke(Remotes.RedeemCode, code); task.wait(0.5)
        end
    end)
end

-- Fullbright
local origAmbient, origBrightness, origFog
local function enableFullbright()
    origAmbient=Lighting.Ambient; origBrightness=Lighting.Brightness; origFog=Lighting.FogEnd
    Lighting.Ambient=Color3.new(1,1,1); Lighting.Brightness=Settings.Visuals.BrightnessValue; Lighting.FogEnd=1e6
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then v.Enabled=false end
    end
end
local function disableFullbright()
    if origAmbient then Lighting.Ambient=origAmbient; Lighting.Brightness=origBrightness; Lighting.FogEnd=origFog end
end

-- ESP
local function clearESP()
    for _, h in pairs(State.espHighlights) do if h and h.Parent then h:Destroy() end end
    State.espHighlights={}
end
local function addHighlight(model, fill, outline)
    if model:FindFirstChild("ESP_H") then return end
    local h=Instance.new("Highlight"); h.Name="ESP_H"
    h.FillColor=fill; h.OutlineColor=outline; h.FillTransparency=0.5; h.Parent=model
    table.insert(State.espHighlights, h)
end
local function updateESP()
    clearESP()
    local hrp=getHRP(); if not hrp then return end
    for _, v in pairs(workspace:GetDescendants()) do
        local d
        if Settings.Visuals.RockESP and isRock(v) then
            local hb=v:FindFirstChild("Hitbox"); if hb then d=(hrp.Position-hb.Position).Magnitude end
            if d and d<=Settings.Visuals.ESPDistance then addHighlight(v,Color3.fromRGB(180,120,0),Color3.fromRGB(255,200,50)) end
        elseif Settings.Visuals.MobESP and isMob(v) then
            local r=v:FindFirstChild("HumanoidRootPart"); if r then d=(hrp.Position-r.Position).Magnitude end
            if d and d<=Settings.Visuals.ESPDistance then addHighlight(v,Color3.fromRGB(200,0,0),Color3.new(1,1,1)) end
        end
    end
    if Settings.Visuals.PlayerESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local r=p.Character:FindFirstChild("HumanoidRootPart")
                if r and (hrp.Position-r.Position).Magnitude<=Settings.Visuals.ESPDistance then
                    addHighlight(p.Character,Color3.fromRGB(0,100,255),Color3.new(1,1,1))
                end
            end
        end
    end
end

-- FPS Boost
local function enableFPSBoost()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled=false end
    end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end

-- Server Hop
local function serverHop()
    local ok, result = pcall(function()
        return HttpService:JSONDecode(HttpService:GetAsync("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and result and result.data then
        local servers={}
        for _, s in pairs(result.data) do
            if s.id~=game.JobId and s.playing<s.maxPlayers then table.insert(servers,s.id) end
        end
        if #servers>0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)]) end
    end
end

-- Webhook stats
local function sendWebhookStats()
    if Settings.Webhook.URL=="" then return end
    task.spawn(function()
        local e=os.time()-State.sessionStats.startTime
        local msg=string.format("Ores: %d | Kills: %d | Quests: %d | Time: %dm %ds",
            State.sessionStats.oresCollected, State.sessionStats.enemiesKilled,
            State.sessionStats.questsCompleted, math.floor(e/60), e%60)
        pcall(function()
            HttpService:PostAsync(Settings.Webhook.URL,
                HttpService:JSONEncode({embeds={{title="Session Stats",description=msg,color=16776960,timestamp=DateTime.now():ToIsoDate()}}}),
                Enum.HttpContentType.ApplicationJson)
        end)
    end)
end

-- Character respawn
player.CharacterAdded:Connect(function(char)
    character=char; task.wait(1)
    if Settings.Mining.Enabled  then startMining()      end
    if Settings.Combat.Enabled  then startCombat()      end
    if Settings.Player.Noclip   then startNoclip()      end
    if Settings.Player.Fly      then startFly()         end
    if Settings.Player.InfiniteJump then startInfiniteJump() end
    if Settings.Player.AutoRun  then toggleAutoRun(true) end
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

local COLORS = {
    bg        = Color3.fromRGB(13,13,18),
    sidebar   = Color3.fromRGB(18,18,26),
    panel     = Color3.fromRGB(22,22,32),
    item      = Color3.fromRGB(28,28,42),
    accent    = Color3.fromRGB(255,200,50),
    text      = Color3.fromRGB(210,210,220),
    subtext   = Color3.fromRGB(130,130,150),
    inactive  = Color3.fromRGB(55,55,70),
    danger    = Color3.fromRGB(200,50,50),
    success   = Color3.fromRGB(50,200,100),
}

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0.92,0,0.72,0)
mainFrame.Position = UDim2.new(0.04,0,0.14,0)
mainFrame.BackgroundColor3 = COLORS.bg
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner",mainFrame).CornerRadius = UDim.new(0,10)

-- Drop shadow
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1,12,1,12)
shadow.Position = UDim2.new(0,-6,0,-6)
shadow.BackgroundColor3 = Color3.new(0,0,0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.ZIndex = mainFrame.ZIndex - 1
shadow.Parent = mainFrame
Instance.new("UICorner",shadow).CornerRadius = UDim.new(0,14)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,38)
titleBar.BackgroundColor3 = COLORS.sidebar
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner",titleBar).CornerRadius = UDim.new(0,10)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1,0,0.5,0)
titleFix.Position = UDim2.new(0,0,0.5,0)
titleFix.BackgroundColor3 = COLORS.sidebar
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Text = "⚒  THE FORGE SCRIPT"
titleText.Size = UDim2.new(1,-80,1,0)
titleText.Position = UDim2.new(0,14,0,0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = COLORS.accent
titleText.TextSize = 13
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local versionLabel = Instance.new("TextLabel")
versionLabel.Text = "v1.0"
versionLabel.Size = UDim2.new(0,40,1,0)
versionLabel.Position = UDim2.new(1,-90,0,0)
versionLabel.BackgroundTransparency = 1
versionLabel.TextColor3 = COLORS.subtext
versionLabel.TextSize = 10
versionLabel.Font = Enum.Font.Gotham
versionLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✕"
closeBtn.Size = UDim2.new(0,28,0,28)
closeBtn.Position = UDim2.new(1,-34,0.5,-14)
closeBtn.BackgroundColor3 = COLORS.danger
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner",closeBtn).CornerRadius = UDim.new(0,6)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Text = "—"
minimizeBtn.Size = UDim2.new(0,28,0,28)
minimizeBtn.Position = UDim2.new(1,-66,0.5,-14)
minimizeBtn.BackgroundColor3 = COLORS.inactive
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.TextSize = 12
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar
Instance.new("UICorner",minimizeBtn).CornerRadius = UDim.new(0,6)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0,130,1,-38)
sidebar.Position = UDim2.new(0,0,0,38)
sidebar.BackgroundColor3 = COLORS.sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sidebarFix = Instance.new("Frame")
sidebarFix.Size = UDim2.new(0.5,0,1,0)
sidebarFix.BackgroundColor3 = COLORS.sidebar
sidebarFix.BorderSizePixel = 0
sidebarFix.Parent = sidebar

local tabListLayout = Instance.new("UIListLayout")
tabListLayout.Parent = sidebar
tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabListLayout.Padding = UDim.new(0,3)

local tabPad = Instance.new("UIPadding")
tabPad.PaddingTop = UDim.new(0,6)
tabPad.PaddingLeft = UDim.new(0,5)
tabPad.PaddingRight = UDim.new(0,5)
tabPad.Parent = sidebar

-- Content
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1,-134,1,-42)
contentArea.Position = UDim2.new(0,132,0,40)
contentArea.BackgroundColor3 = COLORS.panel
contentArea.BorderSizePixel = 0
contentArea.Parent = mainFrame
Instance.new("UICorner",contentArea).CornerRadius = UDim.new(0,8)

-- Dragging
local dragging, dragStart, dragStartPos
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; dragStartPos=mainFrame.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        mainFrame.Position=UDim2.new(dragStartPos.X.Scale,dragStartPos.X.Offset+d.X,dragStartPos.Y.Scale,dragStartPos.Y.Offset+d.Y)
    end
end)

-- Minimize
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    sidebar.Visible = not minimized
    contentArea.Visible = not minimized
    mainFrame.Size = minimized and UDim2.new(0.92,0,0,38) or UDim2.new(0.92,0,0.72,0)
end)

closeBtn.MouseButton1Click:Connect(function()
    stopMining(); stopCombat(); stopNoclip(); stopFly(); stopInfiniteJump()
    clearESP(); disableFullbright()
    screenGui:Destroy()
end)

-- Tab system
local tabPages = {}
local activeTab = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_"..name
    btn.Text = icon.."  "..name
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = COLORS.item
    btn.TextColor3 = COLORS.subtext
    btn.TextSize = 11
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = #tabPages+1
    btn.Parent = sidebar
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)

    local pad = Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,10); pad.Parent=btn

    local page = Instance.new("ScrollingFrame")
    page.Name = name.."_Page"
    page.Size = UDim2.new(1,-8,1,-8)
    page.Position = UDim2.new(0,4,0,4)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.accent
    page.Visible = false
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Parent = contentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)
    layout.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0,4)
    pagePad.PaddingLeft = UDim.new(0,4)
    pagePad.PaddingRight = UDim.new(0,4)
    pagePad.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+12)
    end)

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.page.Visible = false
            activeTab.btn.BackgroundColor3 = COLORS.item
            activeTab.btn.TextColor3 = COLORS.subtext
        end
        page.Visible = true
        btn.BackgroundColor3 = COLORS.accent
        btn.TextColor3 = Color3.fromRGB(15,15,20)
        activeTab = {page=page, btn=btn}
    end)

    tabPages[name] = {btn=btn, page=page}
    return page
end

-- [[ COMPONENT BUILDERS ]]
local function sectionLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Text = "  "..text
    lbl.Size = UDim2.new(1,0,0,24)
    lbl.BackgroundColor3 = Color3.fromRGB(30,30,45)
    lbl.TextColor3 = COLORS.accent
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BorderSizePixel = 0
    lbl.Parent = parent
    Instance.new("UICorner",lbl).CornerRadius = UDim.new(0,4)
    return lbl
end

local function toggle(parent, label, default, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,34)
    frame.BackgroundColor3 = COLORS.item
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Size = UDim2.new(1,-56,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local tbg = Instance.new("TextButton")
    tbg.Size = UDim2.new(0,40,0,22)
    tbg.Position = UDim2.new(1,-48,0.5,-11)
    tbg.BackgroundColor3 = default and COLORS.accent or COLORS.inactive
    tbg.Text = ""
    tbg.BorderSizePixel = 0
    tbg.Parent = frame
    Instance.new("UICorner",tbg).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,18,0,18)
    knob.Position = default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = tbg
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local val = default or false
    tbg.MouseButton1Click:Connect(function()
        val = not val
        tbg.BackgroundColor3 = val and COLORS.accent or COLORS.inactive
        knob.Position = val and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
        if cb then cb(val) end
    end)
    return frame
end

local function slider(parent, label, min, max, default, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,52)
    frame.BackgroundColor3 = COLORS.item
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label..": "..tostring(default)
    lbl.Size = UDim2.new(1,-10,0,20)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local track = Instance.new("TextButton")
    track.Text = ""
    track.Size = UDim2.new(1,-20,0,6)
    track.Position = UDim2.new(0,10,0,34)
    track.BackgroundColor3 = COLORS.inactive
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local frac = (default-min)/(max-min)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(frac,0,1,0)
    fill.BackgroundColor3 = COLORS.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(frac,-7,0.5,-7)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.Text = ""; knob.BorderSizePixel=0
    knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local val = default
    local sliding = false

    local function update(x)
        local t = track.AbsolutePosition.X; local w = track.AbsoluteSize.X
        local f = math.clamp((x-t)/w,0,1)
        val = math.floor(min+(max-min)*f+0.5)
        fill.Size = UDim2.new(f,0,1,0)
        knob.Position = UDim2.new(f,-7,0.5,-7)
        lbl.Text = label..": "..tostring(val)
        if cb then cb(val) end
    end

    knob.MouseButton1Down:Connect(function() sliding=true end)
    track.MouseButton1Down:Connect(function() sliding=true end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            sliding=false
        end
    end)
    return frame
end

local function button(parent, label, color, cb)
    local btn = Instance.new("TextButton")
    btn.Text = label
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = color or COLORS.accent
    btn.TextColor3 = (color and Color3.new(1,1,1)) or Color3.fromRGB(15,15,20)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return btn
end

local function dropdown(parent, label, opts, default, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,34)
    frame.BackgroundColor3 = COLORS.item
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Size = UDim2.new(0.55,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local dd = Instance.new("TextButton")
    dd.Text = default or opts[1] or "—"
    dd.Size = UDim2.new(0.4,0,0,24)
    dd.Position = UDim2.new(0.58,0,0.5,-12)
    dd.BackgroundColor3 = COLORS.inactive
    dd.TextColor3 = Color3.new(1,1,1)
    dd.TextSize = 10
    dd.Font = Enum.Font.Gotham
    dd.BorderSizePixel = 0
    dd.Parent = frame
    Instance.new("UICorner",dd).CornerRadius = UDim.new(0,4)

    local idx = 1
    for i,v in pairs(opts) do if v==(default or opts[1]) then idx=i end end

    dd.MouseButton1Click:Connect(function()
        idx = idx%#opts+1
        dd.Text = opts[idx]
        if cb then cb(opts[idx]) end
    end)
    return frame
end

local function textInput(parent, label, placeholder, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,52)
    frame.BackgroundColor3 = COLORS.item
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Size = UDim2.new(1,-10,0,20)
    lbl.Position = UDim2.new(0,10,0,2)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,-20,0,22)
    box.Position = UDim2.new(0,10,0,26)
    box.BackgroundColor3 = COLORS.inactive
    box.TextColor3 = Color3.new(1,1,1)
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = COLORS.subtext
    box.BorderSizePixel = 0
    box.Text = ""
    box.Parent = frame
    Instance.new("UICorner",box).CornerRadius = UDim.new(0,4)

    local pad = Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,6); pad.Parent=box

    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return frame
end

-- =============================================
-- [[ BUILD TABS ]]
-- =============================================

-- FARM TAB
local farmPage = createTab("Farm","⛏")
sectionLabel(farmPage,"MINING")
toggle(farmPage,"Auto Mine",false,function(v) Settings.Mining.Enabled=v; if v then startMining() else stopMining() end end)
toggle(farmPage,"Auto Swing",true,function(v) Settings.Mining.AutoSwing=v end)
toggle(farmPage,"Auto Swapper",true,function(v) Settings.Mining.AutoSwapper=v end)
toggle(farmPage,"Skip Mined Rocks",true,function(v) Settings.Mining.SkipMined=v end)
toggle(farmPage,"Skip Undesired Rocks",false,function(v) Settings.Mining.SkipUndesiredRocks=v end)
toggle(farmPage,"Avoid Enemies",false,function(v) Settings.Mining.AvoidEnemies=v end)
toggle(farmPage,"Kill Nearby Enemies",false,function(v) Settings.Mining.KillNearby=v end)
toggle(farmPage,"Set Camera To Rock",false,function(v) Settings.Mining.SetCamera=v end)
dropdown(farmPage,"Mine Position",{"Above","Below","Off"},"Above",function(v) Settings.Mining.Position=v end)
dropdown(farmPage,"Lava Mode (W2)",{"Skip","Above","Off"},"Skip",function(v) Settings.Mining.LavaMode=v end)
slider(farmPage,"Rock Distance",3,30,5,function(v) Settings.Mining.RockDistance=v end)
slider(farmPage,"Tween Speed",10,200,50,function(v) Settings.Mining.TweenSpeed=v end)
slider(farmPage,"Mine Delay (ms)",50,2000,100,function(v) Settings.Mining.MineDelay=v/1000 end)

sectionLabel(farmPage,"COMBAT")
toggle(farmPage,"Auto Kill Mobs",false,function(v) Settings.Combat.Enabled=v; if v then startCombat() else stopCombat() end end)
toggle(farmPage,"Auto Dodge (Dash)",true,function(v) Settings.Combat.AutoDodge=v end)
toggle(farmPage,"Set Camera To Mob",false,function(v) Settings.Combat.SetCamera=v end)
toggle(farmPage,"Giant Boss Mode",false,function(v) Settings.Combat.GiantMode=v end)
dropdown(farmPage,"Mob Position",{"Above","Below","Off"},"Above",function(v) Settings.Combat.Position=v end)
slider(farmPage,"Combat Distance",5,40,12,function(v) Settings.Combat.Distance=v end)
slider(farmPage,"Vertical Offset",5,60,20,function(v) Settings.Combat.VerticalOffset=v end)
slider(farmPage,"Combat Tween Speed",20,200,60,function(v) Settings.Combat.TweenSpeed=v end)
slider(farmPage,"Reposition Threshold",1,15,3,function(v) Settings.Combat.RepositionThreshold=v end)
slider(farmPage,"HP Safety %",5,80,20,function(v) Settings.Combat.HPThreshold=v end)
slider(farmPage,"Min Mob Level",1,500,1,function(v) Settings.Combat.LevelMin=v end)
slider(farmPage,"Max Mob Level",1,9999,9999,function(v) Settings.Combat.LevelMax=v end)

-- FORGE TAB
local forgePage = createTab("Forge","🔨")
sectionLabel(forgePage,"AUTO FORGE")
toggle(forgePage,"Auto Forge",false,function(v) Settings.Forging.AutoForge=v; if v then startAutoForge() end end)
sectionLabel(forgePage,"FORGE CALCULATOR")
local calcLabel = Instance.new("TextLabel")
calcLabel.Text = "Enter target multiplier to see\noptimal ore combinations."
calcLabel.Size = UDim2.new(1,0,0,36)
calcLabel.BackgroundTransparency = 1
calcLabel.TextColor3 = COLORS.subtext
calcLabel.TextSize = 10
calcLabel.Font = Enum.Font.Gotham
calcLabel.TextWrapped = true
calcLabel.Parent = forgePage
slider(forgePage,"Target Multiplier (x10)",10,200,50,function(v) end)
button(forgePage,"Calculate",nil,function()
    -- Forge calculator logic placeholder
end)

-- QUESTS TAB
local questPage = createTab("Quests","📋")
sectionLabel(questPage,"AUTO QUEST")
toggle(questPage,"Auto Complete All Quests",false,function(v) Settings.Quests.AutoQuest=v end)
toggle(questPage,"Auto Claim Rewards",true,function(v) Settings.Quests.AutoClaim=v end)
toggle(questPage,"Auto Index",false,function(v) Settings.Quests.AutoIndex=v end)
sectionLabel(questPage,"CODES")
button(questPage,"Redeem All Codes",nil,function() redeemAllCodes() end)

-- ITEMS TAB
local itemsPage = createTab("Items","🎒")
sectionLabel(itemsPage,"AUTO SELL")
toggle(itemsPage,"Auto Sell",false,function(v) Settings.Items.AutoSell=v; if v then startAutoSell() end end)
toggle(itemsPage,"Only Sell When Full",false,function(v) Settings.Items.SellWhenFull=v end)
dropdown(itemsPage,"Min Sell Rarity",{"Common","Uncommon","Rare","Epic","Legendary","Mythical","Relic"},"Epic",function(v) Settings.Items.SellByRarity=v end)
slider(itemsPage,"Inventory Threshold %",10,100,80,function(v) Settings.Items.InventoryThreshold=v end)
sectionLabel(itemsPage,"POTIONS")
toggle(itemsPage,"Auto Use Potions",false,function(v) Settings.Items.AutoUsePotions=v; if v then startAutoPotions() end end)
toggle(itemsPage,"Auto Buy Potions",false,function(v) Settings.Items.AutoBuyPotions=v end)
sectionLabel(itemsPage,"RACE REROLL")
toggle(itemsPage,"Auto Race Reroll",false,function(v)
    Settings.Items.AutoRaceReroll=v
    if v then
        task.spawn(function()
            while Settings.Items.AutoRaceReroll do
                safeInvoke(Remotes.Reroll); task.wait(0.5)
            end
        end)
    end
end)
textInput(itemsPage,"Target Race","e.g. Dragon",function(v) Settings.Items.TargetRace=v end)

-- PLAYER TAB
local playerPage = createTab("Player","👤")
sectionLabel(playerPage,"MOVEMENT")
toggle(playerPage,"Auto Run",false,function(v) Settings.Player.AutoRun=v; toggleAutoRun(v) end)
toggle(playerPage,"Noclip",false,function(v) Settings.Player.Noclip=v; if v then startNoclip() else stopNoclip() end end)
toggle(playerPage,"Fly",false,function(v) Settings.Player.Fly=v; if v then startFly() else stopFly() end end)
toggle(playerPage,"Infinite Jump",false,function(v) Settings.Player.InfiniteJump=v; if v then startInfiniteJump() else stopInfiniteJump() end end)
slider(playerPage,"Walk Speed",16,300,16,function(v) Settings.Player.WalkSpeed=v; local h=getHumanoid(); if h then h.WalkSpeed=v end end)
slider(playerPage,"Jump Power",50,1000,50,function(v) Settings.Player.JumpPower=v; local h=getHumanoid(); if h then h.JumpPower=v end end)
slider(playerPage,"Gravity",10,500,196,function(v) Settings.Player.Gravity=v; workspace.Gravity=v end)
sectionLabel(playerPage,"TELEPORTS")
button(playerPage,"Teleport: World 1",nil,function() safeInvoke(Remotes.TeleportToIsland,1) end)
button(playerPage,"Teleport: World 2",nil,function() safeInvoke(Remotes.TeleportToIsland,2) end)
button(playerPage,"Teleport: World 3",nil,function() safeInvoke(Remotes.TeleportToIsland,3) end)
button(playerPage,"Open Forge",nil,function() safeInvoke(Remotes.StartForge) end)
sectionLabel(playerPage,"SAFETY")
toggle(playerPage,"Staff Detection",true,function(v) Settings.Player.StaffDetection=v end)
toggle(playerPage,"Auto Rejoin",false,function(v) Settings.Player.AutoRejoin=v end)

-- VISUALS TAB
local visualsPage = createTab("Visuals","👁")
sectionLabel(visualsPage,"ESP")
toggle(visualsPage,"Rock ESP",false,function(v) Settings.Visuals.RockESP=v; if not v then clearESP() end end)
toggle(visualsPage,"Ore ESP",false,function(v) Settings.Visuals.OreESP=v end)
toggle(visualsPage,"Monster ESP",false,function(v) Settings.Visuals.MobESP=v; if not v then clearESP() end end)
toggle(visualsPage,"Player ESP",false,function(v) Settings.Visuals.PlayerESP=v; if not v then clearESP() end end)
slider(visualsPage,"ESP Range",50,1000,200,function(v) Settings.Visuals.ESPDistance=v end)
sectionLabel(visualsPage,"LIGHTING")
toggle(visualsPage,"Fullbright",false,function(v) Settings.Visuals.Fullbright=v; if v then enableFullbright() else disableFullbright() end end)
slider(visualsPage,"Brightness",1,10,2,function(v) Settings.Visuals.BrightnessValue=v; if Settings.Visuals.Fullbright then Lighting.Brightness=v end end)

-- WEBHOOK TAB
local webhookPage = createTab("Webhook","🔔")
sectionLabel(webhookPage,"DISCORD WEBHOOK")
textInput(webhookPage,"Webhook URL","https://discord.com/api/webhooks/...",function(v) Settings.Webhook.URL=v end)
dropdown(webhookPage,"Min Notify Rarity",{"Rare","Epic","Legendary","Mythical","Relic","Divine"},"Epic",function(v) Settings.Webhook.RarityPriority=v end)
toggle(webhookPage,"Notify Ores",false,function(v) Settings.Webhook.NotifyOres=v end)
toggle(webhookPage,"Notify Quest Completion",false,function(v) Settings.Webhook.NotifyQuests=v end)
toggle(webhookPage,"Notify Materials",false,function(v) Settings.Webhook.NotifyMaterials=v end)
toggle(webhookPage,"Auto Send Stats",false,function(v)
    Settings.Webhook.AutoSendStats=v
    if v then
        task.spawn(function()
            while Settings.Webhook.AutoSendStats do
                sendWebhookStats(); task.wait(Settings.Webhook.StatInterval)
            end
        end)
    end
end)
toggle(webhookPage,"Auto Send Inventory",false,function(v) Settings.Webhook.AutoSendInventory=v end)
slider(webhookPage,"Stat Interval (sec)",60,3600,300,function(v) Settings.Webhook.StatInterval=v end)

-- MISC TAB
local miscPage = createTab("Misc","⚙")
sectionLabel(miscPage,"PERFORMANCE")
toggle(miscPage,"FPS Boost",false,function(v) Settings.Config.FPSBoost=v; if v then enableFPSBoost() end end)
toggle(miscPage,"Anti-AFK",true,function(v) Settings.Config.AntiAFK=v; if v then startAntiAFK() end end)
sectionLabel(miscPage,"SERVER")
button(miscPage,"Server Hop",nil,function() serverHop() end)
button(miscPage,"Rejoin",nil,function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
sectionLabel(miscPage,"SESSION STATS")
local statsLbl = Instance.new("TextLabel")
statsLbl.Size = UDim2.new(1,0,0,72)
statsLbl.BackgroundColor3 = COLORS.item
statsLbl.TextColor3 = COLORS.text
statsLbl.TextSize = 11
statsLbl.Font = Enum.Font.Gotham
statsLbl.TextWrapped = true
statsLbl.BorderSizePixel = 0
statsLbl.Text = "Ores: 0  |  Kills: 0  |  Quests: 0\nTime: 0m 0s"
statsLbl.Parent = miscPage
Instance.new("UICorner",statsLbl).CornerRadius = UDim.new(0,6)
button(miscPage,"Destroy UI & Stop All",COLORS.danger,function()
    stopMining(); stopCombat(); stopNoclip(); stopFly(); stopInfiniteJump()
    clearESP(); disableFullbright(); screenGui:Destroy()
end)

-- Activate first tab
do
    local first = tabPages["Farm"]
    first.page.Visible = true
    first.btn.BackgroundColor3 = COLORS.accent
    first.btn.TextColor3 = Color3.fromRGB(15,15,20)
    activeTab = {page=first.page, btn=first.btn}
end

-- =============================================
-- [[ BACKGROUND LOOPS ]]
-- =============================================

-- Stats update
task.spawn(function()
    while screenGui and screenGui.Parent do
        local e = os.time()-State.sessionStats.startTime
        statsLbl.Text = string.format(
            "Ores: %d  |  Kills: %d  |  Quests: %d\nTime: %dm %ds  |  Gold: %d",
            State.sessionStats.oresCollected, State.sessionStats.enemiesKilled,
            State.sessionStats.questsCompleted, math.floor(e/60), e%60,
            State.sessionStats.goldEarned
        )
        task.wait(1)
    end
end)

-- ESP loop
task.spawn(function()
    while screenGui and screenGui.Parent do
        if Settings.Visuals.RockESP or Settings.Visuals.MobESP or Settings.Visuals.PlayerESP or Settings.Visuals.OreESP then
            updateESP()
        end
        task.wait(2)
    end
end)

-- Menu toggle key
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Settings.Config.MenuKey then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Start anti-AFK
if Settings.Config.AntiAFK then startAntiAFK() end

print("✅ The Forge Script v1.0 loaded!")
print("🔑 Press RightShift to toggle the menu")
