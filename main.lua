-- =============================================
-- THE FORGE SCRIPT v1.2
-- =============================================

-- Auto reinject after teleport (world changes)
local TeleportService = game:GetService("TeleportService")
TeleportService.LocalPlayerArrivedFromTeleport:Connect(function()
    task.wait(4) -- wait for game to fully load
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/iMzTee/Forge/main/main.lua"))()
    end)
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local function getHRP() return character and character:FindFirstChild("HumanoidRootPart") end
local function getHum() return character and character:FindFirstChildWhichIsA("Humanoid") end

-- =============================================
-- [[ KNIT SERVICE REMOTES ]]
-- =============================================
local BASE = game:GetService("ReplicatedStorage")
    :WaitForChild("Shared"):WaitForChild("Packages")
    :WaitForChild("Knit"):WaitForChild("Services")

local function getService(name) return BASE:FindFirstChild(name) end
local function getRF(serviceName, remoteName)
    local s = getService(serviceName)
    return s and s:FindFirstChild("RF") and s.RF:FindFirstChild(remoteName)
end
local function getRE(serviceName, remoteName)
    local s = getService(serviceName)
    return s and s:FindFirstChild("RE") and s.RE:FindFirstChild(remoteName)
end

local RF = {
    -- Tool
    StartBlock    = getRF("ToolService",    "StartBlock"),
    StopBlock     = getRF("ToolService",    "StopBlock"),
    ToolActivated = getRF("ToolService",    "ToolActivated"),
    -- Forge
    StartForge    = getRF("ForgeService",   "StartForge"),
    EndForge      = getRF("ForgeService",   "EndForge"),
    ChangeSeq     = getRF("ForgeService",   "ChangeSequence"),
    -- Codex
    ClaimOre      = getRF("CodexService",   "ClaimOre"),
    ClaimEnemy    = getRF("CodexService",   "ClaimEnemy"),
    ClaimEquip    = getRF("CodexService",   "ClaimEquipment"),
    -- Character
    Run           = getRF("CharacterService","Run"),
    StopRun       = getRF("CharacterService","StopRun"),
    Dash          = getRF("CharacterService","Dash"),
    EquipItem     = getRF("CharacterService","EquipItem"),
    Reset         = getRF("CharacterService","Reset"),
    -- Inventory
    Sell          = getRF("InventoryService","Sell"),
    SellAnywhere  = getRF("InventoryService","SellAnywhere"),
    SellMisc      = getRF("InventoryService","SellMisc"),
    -- Race
    Reroll        = getRF("RaceService",    "Reroll"),
    SwitchSlot    = getRF("RaceService",    "SwitchSlot"),
    -- Party (combat activate)
    Activate      = getRF("PartyService",   "Activate"),
    -- Quest
    TrackQuest    = getRF("QuestService",   "ClientTrackQuest"),
    ProgressQuest = getRF("QuestService",   "ProgressUIQuest"),
    -- Portal
    TeleportIsland= getRF("PortalService",  "TeleportToIsland"),
    -- Code
    RedeemCode    = getRF("CodeService",    "RedeemCode"),
    -- Time
    GetTime       = getRF("TimeService",    "GetRemainingTime"),
    -- Daily
    DailyClaim    = getRF("DailyLoginService","Claim"),
    -- Proximity
    ForgeProx     = getRF("ProximityService","Forge"),
    Dialogue      = getRF("ProximityService","Dialogue"),
    -- Settings
    SetSetting    = getRF("SettingsService","SetSetting"),
    GetSetting    = getRF("SettingsService","GetSetting"),
    -- Status
    GetEquipInfo  = getRF("StatusService",  "GetPlayerEquipmentInfo"),
    GetEquipCount = getRF("StatusService",  "GetEquipmentCount"),
}

local function invoke(remote, ...)
    if not remote then return nil end
    local ok, res = pcall(remote.InvokeServer, remote, ...)
    return ok and res or nil
end
local function fire(remote, ...)
    if not remote then return end
    pcall(remote.FireServer, remote, ...)
end

-- =============================================
-- [[ SETTINGS ]]
-- =============================================
local S = {
    Mining = {
        Enabled=false, Position="Above", RockDistance=5, TweenSpeed=50,
        MineDelay=0.1, AutoSwing=true, AutoSwapper=true, SkipMined=true,
        SkipUndesiredRocks=false, AvoidEnemies=false, KillNearby=false,
        SelectedRocks={}, SelectedOres={}, RockPriority={}, ZoneFilter="All",
    },
    Combat = {
        Enabled=false, Position="Above", Distance=12, VerticalOffset=20,
        TweenSpeed=60, RepositionThreshold=3, AutoDodge=true,
        SelectedMobs={}, MobPriority={}, LevelMin=1, LevelMax=9999,
        HPThreshold=20, GiantMode=false,
    },
    Forging  = {AutoForge=false},
    Items    = {AutoSell=false, SellWhenFull=false, SellByRarity="Epic",
                AutoUsePotions=false, AutoBuyPotions=false,
                AutoRaceReroll=false, TargetRace="", InvThreshold=80},
    Quests   = {AutoQuest=false, AutoClaim=false, RedeemCodes=false},
    Player   = {AutoRun=false, Noclip=false, Fly=false, InfJump=false,
                WalkSpeed=16, JumpPower=50, Gravity=196.2,
                StaffDetect=true, AutoRejoin=false},
    Visuals  = {RockESP=false, OreESP=false, MobESP=false, PlayerESP=false,
                Fullbright=false, Brightness=2, ESPDist=200},
    Webhook  = {URL="", NotifyOres=false, NotifyQuests=false,
                RarityMin="Epic", AutoStats=false, StatInterval=300},
    Config   = {AntiAFK=true, FPSBoost=false},
}

-- =============================================
-- [[ ORE POOLS ]]
-- =============================================
local rockOrePool = {
    ["Pebble"]={["Stone"]=1,["Sand Stone"]=1,["Copper"]=1,["Iron"]=1,["Poopite"]=1},
    ["Rock"]={["Sand Stone"]=1,["Copper"]=1,["Iron"]=1,["Tin"]=1,["Silver"]=1,["Cardboardite"]=1,["Mushroomite"]=1,["Bananite"]=1,["Poopite"]=1},
    ["Boulder"]={["Copper"]=1,["Iron"]=1,["Tin"]=1,["Silver"]=1,["Gold"]=1,["Cardboardite"]=1,["Mushroomite"]=1,["Bananite"]=1,["Aite"]=1,["Platinum"]=1,["Poopite"]=1},
    ["Basalt Rock"]={["Cobalt"]=1,["Titanium"]=1,["Lapis Lazuli"]=1,["Eye Ore"]=1},
    ["Basalt Core"]={["Cobalt"]=1,["Titanium"]=1,["Lapis Lazuli"]=1,["Quartz"]=1,["Amethyst"]=1,["Topaz"]=1,["Diamond"]=1,["Sapphire"]=1,["Cuprite"]=1,["Emerald"]=1,["Eye Ore"]=1},
    ["Basalt Vein"]={["Quartz"]=1,["Amethyst"]=1,["Topaz"]=1,["Diamond"]=1,["Sapphire"]=1,["Cuprite"]=1,["Emerald"]=1,["Ruby"]=1,["Rivalite"]=1,["Uranium"]=1,["Mythril"]=1,["Lightite"]=1,["Eye Ore"]=1},
    ["Volcanic Rock"]={["Topaz"]=1,["Cuprite"]=1,["Obsidian"]=1,["Rivalite"]=1,["Eye Ore"]=1,["Fireite"]=1,["Magmaite"]=1,["Demonite"]=1,["Darkryte"]=1},
    ["Icy Pebble"]={["Tungsten"]=1,["Sulfur"]=1,["Pumice"]=1,["Aetherit"]=1,["Emerald"]=1,["Ruby"]=1,["Rivalite"]=1,["Uranium"]=1,["Mythril"]=1},
    ["Icy Rock"]={["Tungsten"]=1,["Sulfur"]=1,["Pumice"]=1,["Graphite"]=1,["Aetherit"]=1,["Scheelite"]=1,["Larimar"]=1,["Neurotite"]=1},
    ["Icy Boulder"]={["Tungsten"]=1,["Sulfur"]=1,["Pumice"]=1,["Graphite"]=1,["Aetherit"]=1,["Scheelite"]=1,["Larimar"]=1,["Neurotite"]=1,["Frost Fossil"]=1,["Tide Carve"]=1,["Velchire"]=1,["Sanctis"]=1,["Snowite"]=1},
    ["Small Ice Crystal"]={["Aetherit"]=1,["Scheelite"]=1,["Mistvein"]=1,["Lgarite"]=1,["Voidfractal"]=1,["Suryafal"]=1},
    ["Medium Ice Crystal"]={["Mistvein"]=1,["Lgarite"]=1,["Voidfractal"]=1,["Moltenfrost"]=1,["Crimsonite"]=1,["Malachite"]=1,["Aquajade"]=1,["Cryptex"]=1,["Galestor"]=1,["Iceite"]=1,["Etherealite"]=1,["Voidstar"]=1},
    ["Large Ice Crystal"]={["Mistvein"]=1,["Lgarite"]=1,["Voidfractal"]=1,["Moltenfrost"]=1,["Crimsonite"]=1,["Malachite"]=1,["Aquajade"]=1,["Cryptex"]=1,["Galestor"]=1,["Iceite"]=1,["Etherealite"]=1,["Voidstar"]=1},
    ["Floating Crystal"]={["Mistvein"]=1,["Lgarite"]=1,["Voidfractal"]=1,["Moltenfrost"]=1,["Crimsonite"]=1,["Malachite"]=1,["Aquajade"]=1,["Cryptex"]=1,["Galestor"]=1,["Suryafal"]=1,["Voidstar"]=1},
}

-- =============================================
-- [[ STATE ]]
-- =============================================
local State = {
    miningActive=false, combatActive=false,
    combatConn=nil, faceConn=nil,
    noclipConn=nil, flyConn=nil,
    flyBV=nil, flyBG=nil, isFlying=false,
    espHL={},
    origLighting={},
    stats={ores=0,kills=0,quests=0,start=os.time()},
}

-- =============================================
-- [[ HELPERS ]]
-- =============================================
local function tweenTo(pos, speed)
    local hrp = getHRP(); if not hrp then return end
    speed = speed or S.Mining.TweenSpeed
    local d = (hrp.Position-pos).Magnitude
    if d < 1 then return end
    local t = TweenService:Create(hrp,TweenInfo.new(math.max(0.05,d/speed),Enum.EasingStyle.Linear),{CFrame=CFrame.new(pos)})
    t:Play(); t.Completed:Wait()
end

local function facePos(pos)
    local hrp = getHRP(); if not hrp then return end
    local look = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
    if (hrp.Position-look).Magnitude > 0.5 then hrp.CFrame = CFrame.lookAt(hrp.Position,look) end
end

local function isRock(m)
    return m:IsA("Model") and m:FindFirstChild("Hitbox")
        and m:FindFirstChild("infoFrame") and not m:FindFirstChildWhichIsA("Humanoid")
end

local function isMob(m)
    return m:IsA("Model") and m~=character
        and m:FindFirstChildWhichIsA("Humanoid")
        and m:FindFirstChild("HumanoidRootPart")
        and m:FindFirstChild("infoFrame")
end

local function getBBLabel(model, name)
    local bb = model:FindFirstChild("infoFrame")
    return bb and bb:FindFirstChild(name, true)
end

local function getRockName(m) local l=getBBLabel(m,"rockName"); return l and l.Text or m.Name end
local function getRockHP(m)   local l=getBBLabel(m,"rockHP");   return l and tonumber(l.Text) end
local function getMobName(m)  local l=getBBLabel(m,"rockName"); return l and l.Text or m.Name end
local function getMobHP(m)    local l=getBBLabel(m,"rockHP");   return l and tonumber(l.Text) end
local function getMobLvl(m)   local l=getBBLabel(m,"Lvl");      return l and tonumber(l.Text) or 1 end

local function isMobAttacking(mob)
    local st = mob:FindFirstChild("Status")
    if st then local a=st:FindFirstChild("Attacking"); return a and a.Value end
    return false
end

local function getOrePos(rock)
    local h = rock:FindFirstChild("Hitbox")
    if h then local a=h:FindFirstChild("OrePosition"); if a then return a.WorldPosition end; return h.Position end
    return rock:GetPivot().Position
end

local function getBehindAbove(eRoot)
    local back = -eRoot.CFrame.LookVector
    return Vector3.new(
        eRoot.Position.X + back.X * S.Combat.Distance,
        eRoot.Position.Y + S.Combat.VerticalOffset,
        eRoot.Position.Z + back.Z * S.Combat.Distance
    )
end

local function rockCanDrop(rockName)
    if not next(S.Mining.SelectedOres) then return true end
    local pool = rockOrePool[rockName]
    if not pool then return true end
    for ore in pairs(S.Mining.SelectedOres) do if pool[ore] then return true end end
    return false
end

local function getSortedRocks()
    local hrp = getHRP(); if not hrp then return {} end
    local list={}
    for _,v in pairs(workspace:GetDescendants()) do
        if isRock(v) then
            local name = getRockName(v)
            if S.Mining.SkipUndesiredRocks and not rockCanDrop(name) then continue end
            if next(S.Mining.SelectedRocks) and not S.Mining.SelectedRocks[name] then continue end
            local h = v:FindFirstChild("Hitbox")
            if h then
                table.insert(list,{model=v,name=name,
                    dist=(hrp.Position-h.Position).Magnitude,
                    pri=S.Mining.RockPriority[name] or 0})
            end
        end
    end
    table.sort(list,function(a,b) if a.pri~=b.pri then return a.pri>b.pri end; return a.dist<b.dist end)
    return list
end

local function getSortedMobs()
    local hrp = getHRP(); if not hrp then return {} end
    local list={}
    for _,v in pairs(workspace:GetDescendants()) do
        if isMob(v) then
            local name=getMobName(v); local lvl=getMobLvl(v)
            if next(S.Combat.SelectedMobs) and not S.Combat.SelectedMobs[name] then continue end
            if lvl<S.Combat.LevelMin or lvl>S.Combat.LevelMax then continue end
            local r=v:FindFirstChild("HumanoidRootPart")
            if r then table.insert(list,{model=v,name=name,dist=(hrp.Position-r.Position).Magnitude,pri=S.Combat.MobPriority[name] or 0}) end
        end
    end
    table.sort(list,function(a,b) if a.pri~=b.pri then return a.pri>b.pri end; return a.dist<b.dist end)
    return list
end

-- =============================================
-- [[ SYSTEMS ]]
-- =============================================

local function equipPickaxe() invoke(RF.SwitchSlot,1) end
local function equipWeapon()  invoke(RF.SwitchSlot,2) end

-- Mining
local function stopMining()
    State.miningActive = false
    invoke(RF.StopBlock)
end

local function startMining()
    if State.miningActive then return end
    State.miningActive = true
    task.spawn(function()
        while State.miningActive and S.Mining.Enabled do
            local hrp=getHRP(); local hum=getHum()
            if not hrp or not hum then task.wait(0.5) continue end
            if hum.Health/hum.MaxHealth*100 <= S.Combat.HPThreshold then task.wait(1) continue end
            if S.Mining.AutoSwapper then equipPickaxe(); task.wait(0.2) end

            local rocks = getSortedRocks()
            if #rocks==0 then task.wait(1) continue end

            local rock = rocks[1]
            local orePos = getOrePos(rock.model)
            local above = S.Mining.Position == "Above"

            -- Calculate position ONCE and stay there
            local hrpPos = hrp.Position
            local dir = Vector3.new(hrpPos.X - orePos.X, 0, hrpPos.Z - orePos.Z)
            if dir.Magnitude > 0 then dir = dir.Unit else dir = Vector3.new(1,0,0) end
            local targetPos = Vector3.new(
                orePos.X + dir.X * S.Mining.RockDistance,
                orePos.Y + (above and 8 or -4),
                orePos.Z + dir.Z * S.Mining.RockDistance
            )

            tweenTo(targetPos, S.Mining.TweenSpeed)

            -- Lock character in place while mining
            local hrp2 = getHRP()
            if hrp2 then
                hrp2.Anchored = true
                hrp2.CFrame = CFrame.lookAt(hrp2.Position, Vector3.new(orePos.X, hrp2.Position.Y, orePos.Z))
            end

            local hitbox = rock.model:FindFirstChild("Hitbox")
            if not hitbox then
                if hrp2 then hrp2.Anchored = false end
                task.wait(0.2)
                continue
            end

            invoke(RF.StartBlock, hitbox)

            while State.miningActive and S.Mining.Enabled do
                local hp = getRockHP(rock.model)
                if not hp or hp<=0 or not rock.model.Parent then break end

                if S.Mining.KillNearby then
                    local hrp3 = getHRP()
                    for _,v in pairs(workspace:GetDescendants()) do
                        if isMob(v) then
                            local r=v:FindFirstChild("HumanoidRootPart")
                            if r and hrp3 and (hrp3.Position-r.Position).Magnitude<15 then
                                invoke(RF.Activate,v); task.wait(0.1)
                            end
                        end
                    end
                end

                if S.Mining.AutoSwing then
                    -- Try with hitbox arg first, then without
                    invoke(RF.ToolActivated, hitbox)
                end
                task.wait(S.Mining.MineDelay + math.random(-20,20)/1000)
            end

            -- Unanchor before moving
            local hrp4 = getHRP()
            if hrp4 then hrp4.Anchored = false end

            invoke(RF.StopBlock)
            task.wait(0.15)
            invoke(RF.ClaimOre)
            State.stats.ores += 1

            if S.Webhook.NotifyOres and S.Webhook.URL~="" then
                task.spawn(function()
                    pcall(function()
                        HttpService:PostAsync(S.Webhook.URL,
                            HttpService:JSONEncode({embeds={{title="⛏ Ore Mined",description="Rock: **"..rock.name.."**",color=16766720,timestamp=DateTime.now():ToIsoDate()}}}),
                            Enum.HttpContentType.ApplicationJson)
                    end)
                end)
            end
            task.wait(0.1)
        end
        State.miningActive = false
    end)
end

-- Combat
local function stopCombatLoop()
    if State.combatConn then State.combatConn:Disconnect(); State.combatConn=nil end
    if State.faceConn    then State.faceConn:Disconnect();  State.faceConn=nil  end
end

local function startCombatLoop(mob)
    stopCombatLoop()
    local eRoot = mob:FindFirstChild("HumanoidRootPart"); if not eRoot then return end

    State.combatConn = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp or not eRoot or not mob.Parent then stopCombatLoop(); return end
        local target = getBehindAbove(eRoot)
        local drift = (hrp.Position-target).Magnitude
        if drift > S.Combat.RepositionThreshold then
            local t = TweenService:Create(hrp,TweenInfo.new(drift/S.Combat.TweenSpeed,Enum.EasingStyle.Linear),{CFrame=CFrame.new(target)})
            t:Play()
        end
    end)

    State.faceConn = RunService.Heartbeat:Connect(function()
        local hrp=getHRP(); if not hrp or not eRoot then return end
        facePos(eRoot.Position)
    end)
end

local function stopCombat()
    State.combatActive=false; stopCombatLoop()
end

local function startCombat()
    if State.combatActive then return end
    State.combatActive=true
    task.spawn(function()
        while State.combatActive and S.Combat.Enabled do
            local hrp=getHRP(); local hum=getHum()
            if not hrp or not hum then task.wait(0.5) continue end
            if hum.Health/hum.MaxHealth*100<=S.Combat.HPThreshold then task.wait(1) continue end
            if S.Mining.AutoSwapper then equipWeapon(); task.wait(0.2) end

            local mobs = getSortedMobs()
            if #mobs==0 then stopCombatLoop(); task.wait(1) continue end

            local mob = mobs[1].model
            startCombatLoop(mob)
            task.wait(0.3)

            local eHum = mob:FindFirstChildWhichIsA("Humanoid")
            while State.combatActive and S.Combat.Enabled and mob.Parent and eHum and eHum.Health>0 do
                local h=getHum(); if not h or h.Health/h.MaxHealth*100<=S.Combat.HPThreshold then break end
                if S.Combat.AutoDodge and isMobAttacking(mob) then
                    invoke(RF.Dash); task.wait(0.3)
                end
                invoke(RF.Activate, mob)
                task.wait(0.15 + math.random(-30,30)/1000)
            end

            if mob.Parent then
                task.wait(0.2); invoke(RF.ClaimEnemy, mob)
                State.stats.kills += 1
            end
            stopCombatLoop(); task.wait(0.2)
        end
        stopCombatLoop(); State.combatActive=false
    end)
end

-- Auto Forge
local function startAutoForge()
    task.spawn(function()
        while S.Forging.AutoForge do
            local ok = invoke(RF.StartForge)
            if not ok then task.wait(1) continue end
            task.wait(0.3)
            invoke(RF.ChangeSeq); task.wait(0.2)
            invoke(RF.ChangeSeq); task.wait(0.2)
            invoke(RF.ChangeSeq); task.wait(0.2)
            invoke(RF.EndForge);  task.wait(0.5)
        end
    end)
end

-- Auto Sell
local sellWhitelist = {} -- ores protected from selling

local function doSell()
    -- SellAnywhere with no args sells everything not whitelisted
    -- If whitelist is empty, sell all
    invoke(RF.SellAnywhere)
end

-- Auto Potions
local function startAutoPotions()
    task.spawn(function()
        while S.Items.AutoUsePotions or S.Items.AutoBuyPotions do
            if S.Items.AutoBuyPotions then
                invoke(RF.Dialogue) -- opens shop dialogue
            end
            task.wait(60)
        end
    end)
end

-- Movement
local function toggleAutoRun(v)
    local hum = getHum()
    if v then
        -- Try server remote first, also boost walkspeed locally
        pcall(function() RF.Run:InvokeServer() end)
        if hum then hum.WalkSpeed = math.max(hum.WalkSpeed, 24) end
    else
        pcall(function() RF.StopRun:InvokeServer() end)
        if hum then hum.WalkSpeed = S.Player.WalkSpeed end
    end
end

local function startNoclip()
    State.noclipConn = RunService.Stepped:Connect(function()
        if character then
            for _,p in pairs(character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end)
end
local function stopNoclip()
    if State.noclipConn then State.noclipConn:Disconnect(); State.noclipConn=nil end
    if character then
        for _,p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
end

local function startFly()
    local hrp=getHRP(); if not hrp then return end
    local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Velocity=Vector3.zero; bv.Parent=hrp
    local bg=Instance.new("BodyGyro"); bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.CFrame=hrp.CFrame; bg.Parent=hrp
    State.flyBV=bv; State.flyBG=bg; State.isFlying=true
    State.flyConn=RunService.Heartbeat:Connect(function()
        local hrp2=getHRP(); if not hrp2 or not State.isFlying then return end
        local spd=S.Player.WalkSpeed*2
        local cam=workspace.CurrentCamera
        local hum=getHum()
        local dir=Vector3.zero

        -- Mobile: use humanoid MoveDirection projected onto camera
        if hum and hum.MoveDirection.Magnitude > 0 then
            local md = hum.MoveDirection
            -- Project onto camera XZ plane
            local camFlat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
            local camRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
            local forward = md.Z * camFlat
            local right = md.X * camRight
            dir = forward + right
        end

        -- PC fallback: WASD
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end

        -- Vertical
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
            dir+=Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir-=Vector3.new(0,1,0)
        end

        -- Flatten Y for horizontal movement, keep Y for vertical keys
        local flatDir = Vector3.new(dir.X, 0, dir.Z)
        local vertDir = Vector3.new(0, dir.Y, 0)
        local finalDir = (flatDir.Magnitude>0 and flatDir.Unit or Vector3.zero)*spd + vertDir*spd

        bv.Velocity = finalDir
        if dir.Magnitude > 0 then
            bg.CFrame = CFrame.lookAt(hrp2.Position, hrp2.Position + Vector3.new(dir.X,0,dir.Z))
        end
    end)
end
local function stopFly()
    State.isFlying=false
    if State.flyConn then State.flyConn:Disconnect(); State.flyConn=nil end
    if State.flyBV then State.flyBV:Destroy(); State.flyBV=nil end
    if State.flyBG then State.flyBG:Destroy(); State.flyBG=nil end
end

local ijConn
local function startInfJump()
    ijConn=UserInputService.JumpRequest:Connect(function()
        local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
local function stopInfJump() if ijConn then ijConn:Disconnect(); ijConn=nil end end

local function startAntiAFK()
    task.spawn(function()
        while S.Config.AntiAFK do
            local vu=game:GetService("VirtualUser")
            vu:Button2Down(Vector2.zero,workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.zero,workspace.CurrentCamera.CFrame)
            task.wait(20)
        end
    end)
end

local knownCodes={"RELEASE","UPDATE1","FORGE100K","SORRY","SORRY2","NEWUPDATE","HOLIDAY","NEW","FROZEN","RAVEN","ISLAND3","WORLD3","ICEBERG"}
local function redeemAll()
    task.spawn(function()
        for _,c in pairs(knownCodes) do invoke(RF.RedeemCode,c); task.wait(0.5) end
    end)
end

-- Fullbright
local function enableFullbright()
    State.origLighting={Ambient=Lighting.Ambient,Brightness=Lighting.Brightness,FogEnd=Lighting.FogEnd}
    Lighting.Ambient=Color3.new(1,1,1); Lighting.Brightness=S.Visuals.Brightness; Lighting.FogEnd=1e6
end
local function disableFullbright()
    if State.origLighting.Ambient then
        Lighting.Ambient=State.origLighting.Ambient
        Lighting.Brightness=State.origLighting.Brightness
        Lighting.FogEnd=State.origLighting.FogEnd
    end
end

-- ESP
local function clearESP()
    for _,h in pairs(State.espHL) do if h and h.Parent then h:Destroy() end end
    State.espHL={}
end
local function addHL(model,fill,outline)
    if model:FindFirstChild("_ESP") then return end
    local h=Instance.new("Highlight"); h.Name="_ESP"
    h.FillColor=fill; h.OutlineColor=outline; h.FillTransparency=0.5; h.Parent=model
    table.insert(State.espHL,h)
end
local function updateESP()
    clearESP()
    local hrp=getHRP(); if not hrp then return end
    for _,v in pairs(workspace:GetDescendants()) do
        local d
        if S.Visuals.RockESP and isRock(v) then
            local hb=v:FindFirstChild("Hitbox"); if hb then d=(hrp.Position-hb.Position).Magnitude end
            if d and d<=S.Visuals.ESPDist then addHL(v,Color3.fromRGB(180,120,0),Color3.fromRGB(255,200,50)) end
        elseif S.Visuals.MobESP and isMob(v) then
            local r=v:FindFirstChild("HumanoidRootPart"); if r then d=(hrp.Position-r.Position).Magnitude end
            if d and d<=S.Visuals.ESPDist then addHL(v,Color3.fromRGB(200,0,0),Color3.new(1,1,1)) end
        end
    end
    if S.Visuals.PlayerESP then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local r=p.Character:FindFirstChild("HumanoidRootPart")
                if r and (hrp.Position-r.Position).Magnitude<=S.Visuals.ESPDist then
                    addHL(p.Character,Color3.fromRGB(0,100,255),Color3.new(1,1,1))
                end
            end
        end
    end
end

local function enableFPSBoost()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled=false end
    end
    settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
end

local function serverHop()
    local ok,r=pcall(function()
        return HttpService:JSONDecode(HttpService:GetAsync("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and r and r.data then
        local servers={}
        for _,s in pairs(r.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then table.insert(servers,s.id) end end
        if #servers>0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)]) end
    end
end

player.CharacterAdded:Connect(function(char)
    character=char; task.wait(1)
    if S.Mining.Enabled  then startMining()  end
    if S.Combat.Enabled  then startCombat()  end
    if S.Player.Noclip   then startNoclip()  end
    if S.Player.Fly      then startFly()     end
    if S.Player.InfJump  then startInfJump() end
    if S.Player.AutoRun  then toggleAutoRun(true) end
end)

-- =============================================
-- [[ GUI ]]
-- =============================================
local existing = player.PlayerGui:FindFirstChild("TFS_GUI")
if existing then existing:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name="TFS_GUI"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset=true; sg.Parent=player.PlayerGui

local C = {
    bg=Color3.fromRGB(13,13,18), side=Color3.fromRGB(18,18,26),
    panel=Color3.fromRGB(22,22,32), item=Color3.fromRGB(28,28,42),
    accent=Color3.fromRGB(255,200,50), text=Color3.fromRGB(210,210,220),
    sub=Color3.fromRGB(130,130,150), inactive=Color3.fromRGB(45,45,62),
    danger=Color3.fromRGB(200,50,50), success=Color3.fromRGB(50,200,100),
}

-- Main frame
local mf = Instance.new("Frame")
mf.Name="Main"; mf.Size=UDim2.new(0.92,0,0.75,0)
mf.Position=UDim2.new(0.04,0,0.13,0)
mf.BackgroundColor3=C.bg; mf.BorderSizePixel=0
mf.ClipsDescendants=true; mf.Parent=sg
Instance.new("UICorner",mf).CornerRadius=UDim.new(0,10)

-- Title bar
local tb = Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,36); tb.BackgroundColor3=C.side
tb.BorderSizePixel=0; tb.Parent=mf
Instance.new("UICorner",tb).CornerRadius=UDim.new(0,10)
local tbfix=Instance.new("Frame"); tbfix.Size=UDim2.new(1,0,0.5,0)
tbfix.Position=UDim2.new(0,0,0.5,0); tbfix.BackgroundColor3=C.side
tbfix.BorderSizePixel=0; tbfix.Parent=tb

local titleLbl=Instance.new("TextLabel")
titleLbl.Text="⚒  THE FORGE SCRIPT"; titleLbl.Size=UDim2.new(1,-80,1,0)
titleLbl.Position=UDim2.new(0,12,0,0); titleLbl.BackgroundTransparency=1
titleLbl.TextColor3=C.accent; titleLbl.TextSize=12; titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=tb

local verLbl=Instance.new("TextLabel")
verLbl.Text="v1.1"; verLbl.Size=UDim2.new(0,30,1,0)
verLbl.Position=UDim2.new(1,-95,0,0); verLbl.BackgroundTransparency=1
verLbl.TextColor3=C.sub; verLbl.TextSize=9; verLbl.Font=Enum.Font.Gotham; verLbl.Parent=tb

local closeB=Instance.new("TextButton")
closeB.Text="✕"; closeB.Size=UDim2.new(0,26,0,26)
closeB.Position=UDim2.new(1,-30,0.5,-13); closeB.BackgroundColor3=C.danger
closeB.TextColor3=Color3.new(1,1,1); closeB.TextSize=11; closeB.Font=Enum.Font.GothamBold
closeB.BorderSizePixel=0; closeB.Parent=tb
Instance.new("UICorner",closeB).CornerRadius=UDim.new(0,5)

local minB=Instance.new("TextButton")
minB.Text="—"; minB.Size=UDim2.new(0,26,0,26)
minB.Position=UDim2.new(1,-60,0.5,-13); minB.BackgroundColor3=C.inactive
minB.TextColor3=Color3.new(1,1,1); minB.TextSize=11; minB.Font=Enum.Font.GothamBold
minB.BorderSizePixel=0; minB.Parent=tb
Instance.new("UICorner",minB).CornerRadius=UDim.new(0,5)

-- Sidebar (ScrollingFrame so tabs don't overflow)
local sb = Instance.new("ScrollingFrame")
sb.Name="Sidebar"; sb.Size=UDim2.new(0.2,0,1,-36)
sb.Position=UDim2.new(0,0,0,36); sb.BackgroundColor3=C.side
sb.BorderSizePixel=0; sb.ScrollBarThickness=0
sb.CanvasSize=UDim2.new(0,0,0,0); sb.ClipsDescendants=true; sb.Parent=mf

local sbLayout=Instance.new("UIListLayout")
sbLayout.SortOrder=Enum.SortOrder.LayoutOrder; sbLayout.Padding=UDim.new(0,2); sbLayout.Parent=sb
Instance.new("UIPadding",sb).PaddingTop=UDim.new(0,4)
sbLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sb.CanvasSize=UDim2.new(0,0,0,sbLayout.AbsoluteContentSize.Y+8)
end)

-- Content area
local ca = Instance.new("Frame")
ca.Name="Content"; ca.Size=UDim2.new(0.8,-4,1,-40)
ca.Position=UDim2.new(0.2,2,0,38); ca.BackgroundColor3=C.panel
ca.BorderSizePixel=0; ca.ClipsDescendants=true; ca.Parent=mf
Instance.new("UICorner",ca).CornerRadius=UDim.new(0,6)

-- Drag
local dragging,ds,dsp
tb.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; ds=i.Position; dsp=mf.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-ds
        mf.Position=UDim2.new(dsp.X.Scale,dsp.X.Offset+d.X,dsp.Y.Scale,dsp.Y.Offset+d.Y)
    end
end)

local minimized=false
minB.MouseButton1Click:Connect(function()
    minimized=not minimized; sb.Visible=not minimized; ca.Visible=not minimized
    mf.Size=minimized and UDim2.new(0.92,0,0,36) or UDim2.new(0.92,0,0.75,0)
end)

closeB.MouseButton1Click:Connect(function()
    stopMining(); stopCombat(); stopNoclip(); stopFly(); stopInfJump()
    clearESP(); disableFullbright(); sg:Destroy()
end)

-- =============================================
-- [[ TAB + COMPONENT SYSTEM ]]
-- =============================================
local tabs={}; local activeTab=nil

local function mkTab(name, icon)
    local btn=Instance.new("TextButton")
    btn.Text=icon.." "..name; btn.Size=UDim2.new(1,-6,0,26)
    btn.BackgroundColor3=C.item; btn.TextColor3=C.sub
    btn.TextSize=9; btn.Font=Enum.Font.Gotham
    btn.BorderSizePixel=0; btn.TextXAlignment=Enum.TextXAlignment.Left
    btn.ClipsDescendants=true; btn.LayoutOrder=#tabs+1; btn.Parent=sb
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    Instance.new("UIPadding",btn).PaddingLeft=UDim.new(0,6)

    local page=Instance.new("ScrollingFrame")
    page.Name=name.."_P"; page.Size=UDim2.new(1,-4,1,-4)
    page.Position=UDim2.new(0,2,0,2); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=3
    page.ScrollBarImageColor3=C.accent; page.Visible=false
    page.CanvasSize=UDim2.new(0,0,0,0); page.Parent=ca

    local lay=Instance.new("UIListLayout")
    lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,3); lay.Parent=page
    local pp=Instance.new("UIPadding"); pp.PaddingTop=UDim.new(0,3)
    pp.PaddingLeft=UDim.new(0,3); pp.PaddingRight=UDim.new(0,3); pp.Parent=page
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+10)
    end)

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.page.Visible=false
            activeTab.btn.BackgroundColor3=C.item; activeTab.btn.TextColor3=C.sub
        end
        page.Visible=true; btn.BackgroundColor3=C.accent
        btn.TextColor3=Color3.fromRGB(15,15,20)
        activeTab={page=page,btn=btn}
    end)

    tabs[name]={btn=btn,page=page}
    return page
end

-- Components
local function sec(parent, text)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,20)
    f.BackgroundColor3=Color3.fromRGB(30,30,46); f.BorderSizePixel=0; f.Parent=parent
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
    local l=Instance.new("TextLabel"); l.Text="  "..text; l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1; l.TextColor3=C.accent; l.TextSize=10
    l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    return f
end

local function tog(parent, label, default, cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,30)
    f.BackgroundColor3=C.item; f.BorderSizePixel=0; f.Parent=parent
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel"); l.Text=label; l.Size=UDim2.new(1,-52,1,0)
    l.Position=UDim2.new(0,8,0,0); l.BackgroundTransparency=1; l.TextColor3=C.text
    l.TextSize=10; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    local bg=Instance.new("TextButton"); bg.Size=UDim2.new(0,36,0,20)
    bg.Position=UDim2.new(1,-42,0.5,-10); bg.BackgroundColor3=default and C.accent or C.inactive
    bg.Text=""; bg.BorderSizePixel=0; bg.Parent=f
    Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame"); kn.Size=UDim2.new(0,16,0,16)
    kn.Position=default and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    kn.BackgroundColor3=Color3.new(1,1,1); kn.BorderSizePixel=0; kn.Parent=bg
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local val=default or false
    bg.MouseButton1Click:Connect(function()
        val=not val; bg.BackgroundColor3=val and C.accent or C.inactive
        kn.Position=val and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        if cb then cb(val) end
    end)
    return f
end

local function sld(parent, label, min, max, default, cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,46)
    f.BackgroundColor3=C.item; f.BorderSizePixel=0; f.Parent=parent
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel"); l.Text=label..": "..tostring(default)
    l.Size=UDim2.new(1,-8,0,18); l.Position=UDim2.new(0,8,0,2)
    l.BackgroundTransparency=1; l.TextColor3=C.text; l.TextSize=10
    l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    local tr=Instance.new("TextButton"); tr.Size=UDim2.new(1,-16,0,6)
    tr.Position=UDim2.new(0,8,0,30); tr.BackgroundColor3=C.inactive
    tr.Text=""; tr.BorderSizePixel=0; tr.Parent=f
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local frac=(default-min)/(max-min)
    local fi=Instance.new("Frame"); fi.Size=UDim2.new(frac,0,1,0)
    fi.BackgroundColor3=C.accent; fi.BorderSizePixel=0; fi.Parent=tr
    Instance.new("UICorner",fi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame"); kn.Size=UDim2.new(0,12,0,12)
    kn.Position=UDim2.new(frac,-6,0.5,-6); kn.BackgroundColor3=Color3.new(1,1,1)
    kn.BorderSizePixel=0; kn.Parent=tr
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local val=default; local sliding=false
    local function upd(x)
        local tx=tr.AbsolutePosition.X; local tw=tr.AbsoluteSize.X
        local fr=math.clamp((x-tx)/tw,0,1)
        val=math.floor(min+(max-min)*fr+0.5)
        fi.Size=UDim2.new(fr,0,1,0); kn.Position=UDim2.new(fr,-6,0.5,-6)
        l.Text=label..": "..tostring(val); if cb then cb(val) end
    end
    tr.MouseButton1Down:Connect(function(x) sliding=true; upd(x) end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end
    end)
    return f
end

local function btn(parent, label, color, cb)
    local b=Instance.new("TextButton"); b.Text=label; b.Size=UDim2.new(1,0,0,30)
    b.BackgroundColor3=color or C.accent; b.TextColor3=(color and Color3.new(1,1,1)) or Color3.fromRGB(15,15,20)
    b.TextSize=10; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.Parent=parent
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end

local function dd(parent, label, opts, default, cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,30)
    f.BackgroundColor3=C.item; f.BorderSizePixel=0; f.Parent=parent
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel"); l.Text=label; l.Size=UDim2.new(0.55,0,1,0)
    l.Position=UDim2.new(0,8,0,0); l.BackgroundTransparency=1; l.TextColor3=C.text
    l.TextSize=10; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    local db=Instance.new("TextButton"); db.Text=default or opts[1]
    db.Size=UDim2.new(0.4,0,0,22); db.Position=UDim2.new(0.58,0,0.5,-11)
    db.BackgroundColor3=C.inactive; db.TextColor3=Color3.new(1,1,1)
    db.TextSize=9; db.Font=Enum.Font.Gotham; db.BorderSizePixel=0; db.Parent=f
    Instance.new("UICorner",db).CornerRadius=UDim.new(0,4)
    local idx=1; for i,v in pairs(opts) do if v==(default or opts[1]) then idx=i end end
    db.MouseButton1Click:Connect(function() idx=idx%#opts+1; db.Text=opts[idx]; if cb then cb(opts[idx]) end end)
    return f
end

local function tinput(parent, label, ph, cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,48)
    f.BackgroundColor3=C.item; f.BorderSizePixel=0; f.Parent=parent
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel"); l.Text=label; l.Size=UDim2.new(1,-8,0,18)
    l.Position=UDim2.new(0,8,0,2); l.BackgroundTransparency=1; l.TextColor3=C.text
    l.TextSize=10; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    local box=Instance.new("TextBox"); box.Size=UDim2.new(1,-16,0,20)
    box.Position=UDim2.new(0,8,0,24); box.BackgroundColor3=C.inactive
    box.TextColor3=Color3.new(1,1,1); box.TextSize=10; box.Font=Enum.Font.Gotham
    box.PlaceholderText=ph or ""; box.PlaceholderColor3=C.sub
    box.BorderSizePixel=0; box.Text=""; box.Parent=f
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,4)
    Instance.new("UIPadding",box).PaddingLeft=UDim.new(0,5)
    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return f
end

-- =============================================
-- [[ BUILD PAGES ]]
-- =============================================

-- FARM
local fp=mkTab("Farm","⛏")
sec(fp,"MINING")
tog(fp,"Auto Mine",false,function(v) S.Mining.Enabled=v; if v then startMining() else stopMining() end end)
tog(fp,"Auto Swing",true,function(v) S.Mining.AutoSwing=v end)
tog(fp,"Auto Swapper",true,function(v) S.Mining.AutoSwapper=v end)
tog(fp,"Skip Undesired Rocks",false,function(v) S.Mining.SkipUndesiredRocks=v end)
tog(fp,"Avoid Enemies",false,function(v) S.Mining.AvoidEnemies=v end)
tog(fp,"Kill Nearby Enemies",false,function(v) S.Mining.KillNearby=v end)
dd(fp,"Mine Position",{"Above","Below","Off"},"Above",function(v) S.Mining.Position=v end)
dd(fp,"Lava Mode (W2)",{"Skip","Above","Off"},"Skip",function(v) S.Mining.LavaMode=v end)
sld(fp,"Rock Distance",2,25,5,function(v) S.Mining.RockDistance=v end)
sld(fp,"Tween Speed",10,150,50,function(v) S.Mining.TweenSpeed=v end)
sld(fp,"Mine Delay (ms)",50,2000,100,function(v) S.Mining.MineDelay=v/1000 end)
sec(fp,"COMBAT")
tog(fp,"Auto Kill Mobs",false,function(v) S.Combat.Enabled=v; if v then startCombat() else stopCombat() end end)
tog(fp,"Auto Dodge",true,function(v) S.Combat.AutoDodge=v end)
tog(fp,"Giant Boss Mode",false,function(v) S.Combat.GiantMode=v end)
dd(fp,"Mob Position",{"Above","Below","Off"},"Above",function(v) S.Combat.Position=v end)
sld(fp,"Combat Distance",5,35,12,function(v) S.Combat.Distance=v end)
sld(fp,"Vertical Offset",5,60,20,function(v) S.Combat.VerticalOffset=v end)
sld(fp,"Reposition Threshold",1,15,3,function(v) S.Combat.RepositionThreshold=v end)
sld(fp,"HP Safety %",5,80,20,function(v) S.Combat.HPThreshold=v end)
sld(fp,"Min Mob Level",1,500,1,function(v) S.Combat.LevelMin=v end)
sld(fp,"Max Mob Level",1,9999,9999,function(v) S.Combat.LevelMax=v end)

-- FORGE
local fgp=mkTab("Forge","🔨")
sec(fgp,"AUTO FORGE")
tog(fgp,"Auto Forge",false,function(v) S.Forging.AutoForge=v; if v then startAutoForge() end end)
sec(fgp,"FORGE CALCULATOR")
local calcOut=Instance.new("TextLabel"); calcOut.Size=UDim2.new(1,0,0,40)
calcOut.BackgroundColor3=C.item; calcOut.TextColor3=C.text; calcOut.TextSize=9
calcOut.Font=Enum.Font.Gotham; calcOut.TextWrapped=true; calcOut.BorderSizePixel=0
calcOut.Text="Set target multiplier and press Calculate"; calcOut.Parent=fgp
Instance.new("UICorner",calcOut).CornerRadius=UDim.new(0,5)
local targetMult=5
sld(fgp,"Target Multiplier (x10)",10,200,50,function(v) targetMult=v/10 end)
btn(fgp,"Calculate",nil,function()
    calcOut.Text=string.format("Target: %.1fx — Mix Epic+ ores with 30%% trait ores for optimal result.",targetMult)
end)

-- QUESTS
local qp=mkTab("Quests","📋")
sec(qp,"AUTO QUEST")
tog(qp,"Auto Complete Quests",false,function(v) S.Quests.AutoQuest=v end)
tog(qp,"Auto Claim Rewards",true,function(v) S.Quests.AutoClaim=v end)
sec(qp,"CODES")
btn(qp,"Redeem All Codes",nil,function() redeemAll() end)
btn(qp,"Claim Daily Login",nil,function() invoke(RF.DailyClaim) end)

-- ITEMS
local ip=mkTab("Items","🎒")
sec(ip,"AUTO SELL")
tog(ip,"Auto Sell",false,function(v) S.Items.AutoSell=v
    if v then task.spawn(function() while S.Items.AutoSell do doSell(); task.wait(5) end end) end
end)
tog(ip,"Sell Only When Full",false,function(v) S.Items.SellWhenFull=v end)
dd(ip,"Min Sell Rarity",{"Common","Uncommon","Rare","Epic","Legendary","Mythical"},"Epic",function(v) S.Items.SellByRarity=v end)
sld(ip,"Inventory Threshold %",10,100,80,function(v) S.Items.InvThreshold=v end)
btn(ip,"Sell Now",nil,function() doSell() end)
sec(ip,"ORE SELL WHITELIST")
local whitelistStatus=Instance.new("TextLabel")
whitelistStatus.Size=UDim2.new(1,0,0,30); whitelistStatus.BackgroundColor3=C.item
whitelistStatus.TextColor3=C.sub; whitelistStatus.TextSize=9; whitelistStatus.Font=Enum.Font.Gotham
whitelistStatus.Text="Protected: None"; whitelistStatus.BorderSizePixel=0; whitelistStatus.Parent=ip
Instance.new("UICorner",whitelistStatus).CornerRadius=UDim.new(0,5)
local function updateWhitelistLabel()
    local names={}; for k in pairs(sellWhitelist) do table.insert(names,k) end
    whitelistStatus.Text=#names>0 and "Protected: "..table.concat(names,", ") or "Protected: None"
end
tinput(ip,"Protect Ore (won't sell)","e.g. Galaxite",function(v)
    if v~="" then sellWhitelist[v]=true; updateWhitelistLabel() end
end)
tinput(ip,"Remove Protection","e.g. Galaxite",function(v)
    if v~="" then sellWhitelist[v]=nil; updateWhitelistLabel() end
end)
sec(ip,"POTIONS")
tog(ip,"Auto Use Potions",false,function(v) S.Items.AutoUsePotions=v; if v then startAutoPotions() end end)
tog(ip,"Auto Buy Potions",false,function(v) S.Items.AutoBuyPotions=v end)
sec(ip,"RACE")
tog(ip,"Auto Race Reroll",false,function(v)
    S.Items.AutoRaceReroll=v
    if v then task.spawn(function()
        while S.Items.AutoRaceReroll do invoke(RF.Reroll); task.wait(0.5) end
    end) end
end)
tinput(ip,"Target Race","e.g. Dragon",function(v) S.Items.TargetRace=v end)

-- PLAYER
local pp=mkTab("Player","👤")
sec(pp,"MOVEMENT")
tog(pp,"Auto Run",false,function(v) S.Player.AutoRun=v; toggleAutoRun(v) end)
tog(pp,"Noclip",false,function(v) S.Player.Noclip=v; if v then startNoclip() else stopNoclip() end end)
tog(pp,"Fly",false,function(v) S.Player.Fly=v; if v then startFly() else stopFly() end end)
tog(pp,"Infinite Jump",false,function(v) S.Player.InfJump=v; if v then startInfJump() else stopInfJump() end end)
sld(pp,"Walk Speed",16,300,16,function(v) S.Player.WalkSpeed=v; local h=getHum(); if h then h.WalkSpeed=v end end)
sld(pp,"Jump Power",50,500,50,function(v) S.Player.JumpPower=v; local h=getHum(); if h then h.JumpPower=v end end)
sld(pp,"Gravity",10,400,196,function(v) S.Player.Gravity=v; workspace.Gravity=v end)
sec(pp,"TELEPORTS")
btn(pp,"→ World 1",nil,function() invoke(RF.TeleportIsland,"Island1") if not invoke(RF.TeleportIsland,"Island1") then invoke(RF.TeleportIsland,1) end end)
btn(pp,"→ World 2",nil,function() invoke(RF.TeleportIsland,"Island2") if not invoke(RF.TeleportIsland,"Island2") then invoke(RF.TeleportIsland,2) end end)
btn(pp,"→ World 3",nil,function() invoke(RF.TeleportIsland,"Island3") if not invoke(RF.TeleportIsland,"Island3") then invoke(RF.TeleportIsland,3) end end)
btn(pp,"Open Forge",nil,function() invoke(RF.StartForge) end)
sec(pp,"SAFETY")
tog(pp,"Staff Detection",true,function(v) S.Player.StaffDetect=v end)
tog(pp,"Auto Rejoin",false,function(v) S.Player.AutoRejoin=v end)

-- VISUALS
local vp=mkTab("Visuals","👁")
sec(vp,"ESP")
tog(vp,"Rock ESP",false,function(v) S.Visuals.RockESP=v; if not v then clearESP() end end)
tog(vp,"Ore ESP",false,function(v) S.Visuals.OreESP=v end)
tog(vp,"Monster ESP",false,function(v) S.Visuals.MobESP=v; if not v then clearESP() end end)
tog(vp,"Player ESP",false,function(v) S.Visuals.PlayerESP=v; if not v then clearESP() end end)
sld(vp,"ESP Range",50,1000,200,function(v) S.Visuals.ESPDist=v end)
sec(vp,"LIGHTING")
tog(vp,"Fullbright",false,function(v) S.Visuals.Fullbright=v; if v then enableFullbright() else disableFullbright() end end)
sld(vp,"Brightness",1,10,2,function(v) S.Visuals.Brightness=v; if S.Visuals.Fullbright then Lighting.Brightness=v end end)

-- WEBHOOK
local wp=mkTab("Webhook","🔔")
sec(wp,"DISCORD")
tinput(wp,"Webhook URL","https://discord.com/api/webhooks/...",function(v) S.Webhook.URL=v end)
dd(wp,"Min Rarity",{"Rare","Epic","Legendary","Mythical","Relic","Divine"},"Epic",function(v) S.Webhook.RarityMin=v end)
tog(wp,"Notify Ores",false,function(v) S.Webhook.NotifyOres=v end)
tog(wp,"Notify Quests",false,function(v) S.Webhook.NotifyQuests=v end)
tog(wp,"Auto Send Stats",false,function(v)
    S.Webhook.AutoStats=v
    if v then task.spawn(function()
        while S.Webhook.AutoStats do
            if S.Webhook.URL~="" then
                local e=os.time()-State.stats.start
                local msg=string.format("Ores: %d | Kills: %d | Quests: %d | Time: %dm %ds",
                    State.stats.ores,State.stats.kills,State.stats.quests,math.floor(e/60),e%60)
                pcall(function()
                    HttpService:PostAsync(S.Webhook.URL,
                        HttpService:JSONEncode({embeds={{title="📊 Session Stats",description=msg,color=16766720,timestamp=DateTime.now():ToIsoDate()}}}),
                        Enum.HttpContentType.ApplicationJson)
                end)
            end
            task.wait(S.Webhook.StatInterval)
        end
    end) end
end)
sld(wp,"Stat Interval (sec)",60,3600,300,function(v) S.Webhook.StatInterval=v end)

-- MISC
local mp=mkTab("Misc","⚙")
sec(mp,"PERFORMANCE")
tog(mp,"FPS Boost",false,function(v) S.Config.FPSBoost=v; if v then enableFPSBoost() end end)
tog(mp,"Anti-AFK",true,function(v) S.Config.AntiAFK=v; if v then startAntiAFK() end end)
sec(mp,"SERVER")
btn(mp,"Server Hop",nil,function() serverHop() end)
btn(mp,"Rejoin",nil,function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
sec(mp,"SESSION STATS")
local statsLbl=Instance.new("TextLabel"); statsLbl.Size=UDim2.new(1,0,0,52)
statsLbl.BackgroundColor3=C.item; statsLbl.TextColor3=C.text; statsLbl.TextSize=10
statsLbl.Font=Enum.Font.Gotham; statsLbl.TextWrapped=true; statsLbl.BorderSizePixel=0
statsLbl.Text="Loading..."; statsLbl.Parent=mp
Instance.new("UICorner",statsLbl).CornerRadius=UDim.new(0,5)
sec(mp,"DESTROY")
btn(mp,"Stop All & Close UI",C.danger,function()
    stopMining(); stopCombat(); stopNoclip(); stopFly(); stopInfJump()
    clearESP(); disableFullbright(); sg:Destroy()
end)

-- =============================================
-- [[ ACTIVATE FIRST TAB ]]
-- =============================================
for _,t in pairs(tabs) do
    t.page.Visible=false
    t.btn.BackgroundColor3=C.item; t.btn.TextColor3=C.sub
end
tabs["Farm"].page.Visible=true
tabs["Farm"].btn.BackgroundColor3=C.accent
tabs["Farm"].btn.TextColor3=Color3.fromRGB(15,15,20)
activeTab={page=tabs["Farm"].page, btn=tabs["Farm"].btn}

-- Toggle key
UserInputService.InputBegan:Connect(function(i,gpe)
    if not gpe and i.KeyCode==Enum.KeyCode.RightShift then mf.Visible=not mf.Visible end
end)

-- Background loops
task.spawn(function()
    while sg and sg.Parent do
        local e=os.time()-State.stats.start
        statsLbl.Text=string.format("Ores: %d  |  Kills: %d  |  Quests: %d\nTime: %dm %ds",
            State.stats.ores,State.stats.kills,State.stats.quests,math.floor(e/60),e%60)
        task.wait(1)
    end
end)

task.spawn(function()
    while sg and sg.Parent do
        if S.Visuals.RockESP or S.Visuals.MobESP or S.Visuals.PlayerESP then updateESP() end
        task.wait(2)
    end
end)

if S.Config.AntiAFK then startAntiAFK() end

print("✅ The Forge Script v1.1 loaded! Press RightShift to toggle.")
