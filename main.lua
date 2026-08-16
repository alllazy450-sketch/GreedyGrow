-- ============================================================
--  GREEDY GROWERS AUTO FARM v5.0 (REBUILD)
-- ============================================================
print("=== LOADING GREEDY GROWERS AUTO FARM v5.0 ===")

local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")

-- ============================================================
--  REMOTE LOADING (direct path, no findRemote)
-- ============================================================
task.wait(1)

local KnitServices
local ok = pcall(function()
    KnitServices = RS.Packages._Index["sleitnick_knit@1.6.0"].knit.Services
end)

if not ok or not KnitServices then
    task.wait(2)
    ok = pcall(function()
        KnitServices = RS.Packages._Index["sleitnick_knit@1.6.0"].knit.Services
    end)
end

if not ok or not KnitServices then
    warn("FATAL: Knit services not found!")
    return
end

local Remote = {}
local function sg(fn) local ok,r = pcall(fn) if ok then return r else warn("Remote nil: "..tostring(r)) end end

Remote.StartRound      = sg(function() return KnitServices.PlantRoundService.RF.StartRound end)
Remote.StopPlant       = sg(function() return KnitServices.PlantRoundService.RF.StopPlant end)
Remote.CollectDeadTree = sg(function() return KnitServices.PlantRoundService.RF.CollectDeadTree end)
Remote.PlantStoppedAll = sg(function() return KnitServices.PlantRoundService.RE.PlantStoppedAll end)
Remote.SellAll         = sg(function() return KnitServices.SellStandService.RF.SellAll end)
Remote.SellTree        = sg(function() return KnitServices.SellStandService.RF.SellTree end)
Remote.BuySeed         = sg(function() return KnitServices.SeedStandService.RF.BuySeed end)
Remote.RequestPurchase = sg(function() return KnitServices.SeedConveyorService.RF.RequestPurchase end)
Remote.SeedSpawned     = sg(function() return KnitServices.SeedConveyorService.RE.SeedSpawned end)
Remote.ToggleEquip     = sg(function() return KnitServices.ToolService.RE.ToggleEquip end)

for k, v in pairs(Remote) do
    print((v and "OK" or "NIL").." Remote."..k)
end

-- ============================================================
--  SEED LIST
-- ============================================================
local SEEDS = {
    "Oak", "Pine", "Apple", "Peach", "Fig",
    "Orange", "Lemon", "Avocado", "Cherry",
    "Mango", "Coconut", "Banana", "Starfruit",
    "Dragon Fruit", "Glowing", "Blooming",
    "Magic", "Pizza", "Diamond", "Void"
}

-- ============================================================
--  STATE
-- ============================================================
local Toggles = {
    AutoFarm    = false,
    AutoSell    = false,
    AutoBuy     = false,
    AutoHarvest = false,
}
local Settings = {
    SelectedSeed  = "Oak",
    BuySeed       = {"Oak"},
    BuyMode       = "Direct",
    BuyAmount     = 100,
    SellTargets   = {"All"},
    HarvestMode   = "DeadTree",
    GrownWaitTime = 8,
    SeedSlot      = 1, -- slot seed di inventory (1-6)
}
local FarmRunning = false
local PlantDied = false -- flag: plant mati sebelum Grown timer habis

-- Conveyor: auto-beli seed yang cocok saat muncul di belt
local ConveyorEnabled = false
if Remote.SeedSpawned and Remote.RequestPurchase then
    Remote.SeedSpawned.OnClientEvent:Connect(function(data)
        if not ConveyorEnabled then return end
        if not Toggles.AutoBuy then return end
        if data and data.seedKey then
            for _, seed in ipairs(Settings.BuySeed) do
                if seed == data.seedKey then
                    pcall(function() Remote.RequestPurchase:InvokeServer(data.spawnId) end)
                    break
                end
            end
        end
    end)
    print("OK Conveyor listener hooked")
end

-- generationTime dari SeedConfig (detik)
local SEED_GENERATION_TIME = {
    Oak = 10, Pine = 12, Apple = 30, Peach = 40, Fig = 50,
    Orange = 60, Lemon = 70, Avocado = 90, Cherry = 100,
    Mango = 120, Coconut = 150, Banana = 180, Starfruit = 240,
    ["Dragon Fruit"] = 300, Glowing = 360, Blooming = 420,
    Magic = 480, Pizza = 540, Diamond = 600, Void = 720
}

-- ============================================================
--  HELPERS
-- ============================================================
local Window -- forward declare

local function doBuy()
    if not Toggles.AutoBuy then return end
    if Settings.BuyMode == "Conveyor" then
        ConveyorEnabled = true
        return
    end
    if not Remote.BuySeed then warn("doBuy: Remote.BuySeed nil!") return end
    for _, seed in ipairs(Settings.BuySeed) do
        pcall(function() Remote.BuySeed:InvokeServer(seed, Settings.BuyAmount) end)
        task.wait(0.1)
    end
end

local function doEquipSeed()
    if not Remote.ToggleEquip then return end
    if Settings.SeedSlot < 1 then return end
    pcall(function() Remote.ToggleEquip:FireServer(true, Settings.SeedSlot) end)
end

local function doHarvest()
    if not Toggles.AutoHarvest then return end
    -- selalu coba CollectDeadTree dulu
    if Remote.CollectDeadTree then
        pcall(function() Remote.CollectDeadTree:InvokeServer() end)
        task.wait(0.2)
    end
    -- kalau Grown mode, juga panggil StopPlant
    if Settings.HarvestMode == "Grown" and Remote.StopPlant then
        pcall(function() Remote.StopPlant:InvokeServer() end)
        task.wait(0.2)
    end
end

local function doSell()
    if not Toggles.AutoSell then return end
    -- selalu coba SellAll dulu (paling reliable)
    if Remote.SellAll then
        for i = 1, 2 do
            pcall(function() Remote.SellAll:InvokeServer() end)
            task.wait(0.3)
        end
    end
    -- jika ada target spesifik selain All, jual per seed juga
    if Settings.SellTargets and #Settings.SellTargets > 0 then
        local hasSpecific = false
        for _, t in ipairs(Settings.SellTargets) do
            if t ~= "All" then hasSpecific = true; break end
        end
        if hasSpecific and Remote.SellTree then
            for _, seedType in ipairs(Settings.SellTargets) do
                if seedType ~= "All" then
                    pcall(function() Remote.SellTree:InvokeServer(seedType) end)
                    task.wait(0.2)
                end
            end
        end
    end
end

local function onRoundStopped()
    doHarvest()
    doSell()
end

-- Hook PlantStoppedAll untuk trigger harvest/sell otomatis
if Remote.PlantStoppedAll then
    Remote.PlantStoppedAll.OnClientEvent:Connect(function()
        PlantDied = true -- plant mati, signal ke Grown timer
        if Toggles.AutoHarvest or Toggles.AutoSell then
            task.spawn(onRoundStopped)
        end
    end)
    print("OK PlantStoppedAll hooked")
end

-- ============================================================
--  KAIRO UI
-- ============================================================
local kairoUrl = "https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"
local kairoSrc
local fetchOk = pcall(function() kairoSrc = game:HttpGet(kairoUrl) end)
if not fetchOk or not kairoSrc or kairoSrc == "" then
    warn("Kairo fetch failed!")
    return
end
local kairoFn, kairoErr = loadstring(kairoSrc)
if not kairoFn then
    warn("Kairo loadstring failed: "..tostring(kairoErr))
    return
end
local Kairo = kairoFn()
if not Kairo then warn("Kairo failed to load!") return end

Window = Kairo:CreateWindow({
    Title = "Greedy Growers AutoFarm",
    Theme = "Ocean",
    Size = UDim2.fromOffset(480, 480),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"v5.0"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    Config = { Enabled = true, Folder = "GreedyGrowers_v5", AutoLoad = true }
})
if not Window then warn("Window failed!") return end
print("OK Window created")

Window:Notify({
    Title = "Greedy Growers v5.0",
    Description = "Auto Plant, Harvest, Sell, Buy, Equip",
    Color = Color3.fromRGB(0,200,50),
    Duration = 3
})

-- ============================================================
--  TAB FARM
-- ============================================================
local TabFarm = Window:CreateTab("Farm")
local TabShop = Window:CreateTab("Shop")
local TabMisc = Window:CreateTab("Misc")

-- FARM TAB
Window:AddParagraph(TabFarm, "Auto Farm", "Plant, harvest, equip")

Window:AddDropdown(TabFarm, "Plant Seed", "Seed to plant", SEEDS, false, "Oak", function(v)
    Settings.SelectedSeed = v
end)

Window:AddSlider(TabFarm, "Seed Slot", "Slot seed di inventory (1-6)", 1, 6, 1, function(v)
    Settings.SeedSlot = v
end)

Window:AddToggle(TabFarm, "Auto Farm", "Loop: auto plant every round", false, function(v)
    Toggles.AutoFarm = v
    if not v and Remote.StopPlant then
        pcall(function() Remote.StopPlant:InvokeServer() end)
        FarmRunning = false
    end
    Window:Notify({Title="Auto Farm", Description=v and "ON - "..Settings.SelectedSeed or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

Window:AddDivider(TabFarm, "Harvest")

Window:AddToggle(TabFarm, "Auto Harvest", "Harvest after round", false, function(v)
    Toggles.AutoHarvest = v
    Window:Notify({Title="Auto Harvest", Description=v and "ON" or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

Window:AddDropdown(TabFarm, "Harvest Mode", "DeadTree = after die, Grown = before die", {"DeadTree", "Grown"}, false, "DeadTree", function(v)
    Settings.HarvestMode = v
end)

Window:AddSlider(TabFarm, "Grown Wait", "Seconds before Grown harvest", 1, 30, 8, function(v)
    Settings.GrownWaitTime = v
end)

Window:AddDivider(TabFarm, "Manual")

Window:AddButton(TabFarm, "Plant Now", "Start a new round", nil, function()
    if Remote.StartRound then
        pcall(function() Remote.StartRound:InvokeServer(Settings.SelectedSeed, "Basic") end)
        Window:Notify({Title="Plant", Description=Settings.SelectedSeed, Color=Color3.fromRGB(0,255,0), Duration=2})
    end
end)

Window:AddButton(TabFarm, "Harvest Now", "Collect dead trees", nil, function()
    if Remote.CollectDeadTree then
        pcall(function() Remote.CollectDeadTree:InvokeServer() end)
        Window:Notify({Title="Harvest", Description="Done!", Color=Color3.fromRGB(255,200,0), Duration=2})
    end
end)

Window:AddButton(TabFarm, "Stop Plant", "Stop current round", nil, function()
    if Remote.StopPlant then
        pcall(function() Remote.StopPlant:InvokeServer() end)
        FarmRunning = false
        Window:Notify({Title="Stop", Description="Stopped!", Color=Color3.fromRGB(255,255,0), Duration=2})
    end
end)

-- ============================================================
--  SHOP TAB
-- ============================================================
Window:AddParagraph(TabShop, "Buy & Sell", "Seed purchase and selling")

Window:AddToggle(TabShop, "Auto Buy", "Buy seeds automatically", false, function(v)
    Toggles.AutoBuy = v
    if not v then ConveyorEnabled = false end
    Window:Notify({Title="Auto Buy", Description=v and "ON" or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

Window:AddDropdown(TabShop, "Buy Seed", "Seeds to buy", SEEDS, true, {"Oak"}, function(v)
    Settings.BuySeed = v
end)

Window:AddDropdown(TabShop, "Buy Mode", "Direct = seed stand, Conveyor = belt", {"Direct", "Conveyor"}, false, "Direct", function(v)
    Settings.BuyMode = v
    if v == "Direct" then ConveyorEnabled = false end
end)

Window:AddSlider(TabShop, "Buy Amount", "Amount per buy (Direct)", 10, 500, 100, function(v)
    Settings.BuyAmount = v
end)

Window:AddButton(TabShop, "Buy Seed Now", "Buy selected seed", nil, function()
    doBuy()
end)

Window:AddDivider(TabShop, "Sell")

Window:AddToggle(TabShop, "Auto Sell", "Sell after harvest", false, function(v)
    Toggles.AutoSell = v
    Window:Notify({Title="Auto Sell", Description=v and "ON" or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

local sellOptions = {"All"}
for _, s in ipairs(SEEDS) do table.insert(sellOptions, s) end
Window:AddDropdown(TabShop, "Sell Targets", "What to sell (multi-select)", sellOptions, true, {"All"}, function(v)
    Settings.SellTargets = v
end)

Window:AddButton(TabShop, "Sell All Now", "Sell everything", nil, function()
    if Remote.SellAll then
        pcall(function() Remote.SellAll:InvokeServer() end)
        Window:Notify({Title="Sell", Description="Done!", Color=Color3.fromRGB(0,255,0), Duration=2})
    end
end)

-- ============================================================
--  MISC TAB
-- ============================================================
Window:AddParagraph(TabMisc, "Misc", "Anti AFK, FPS & Ping")

local antiAfkEnabled = false
Window:AddToggle(TabMisc, "Anti AFK", "Prevent AFK kick", false, function(v)
    antiAfkEnabled = v
    Window:Notify({Title="Anti AFK", Description=v and "ON" or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

-- FPS & Ping display
local statsLabel = Window:AddParagraph(TabMisc, "Stats", "FPS: -- | Ping: --")

task.spawn(function()
    while true do
        task.wait(1)
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        local ping = LocalPlayer and LocalPlayer:GetNetworkPing and math.floor(LocalPlayer:GetNetworkPing() * 1000) or 0
        if statsLabel then
            pcall(function()
                statsLabel.Text = "FPS: "..fps.." | Ping: "..ping.."ms"
            end)
        end
    end
end)

-- ============================================================
--  BUY LOOP (independent dari farm)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5) -- buy lebih sering
        if Toggles.AutoBuy and Settings.BuyMode == "Direct" then
            doBuy()
        end
        if Toggles.AutoBuy and Settings.BuyMode == "Conveyor" then
            ConveyorEnabled = true
        else
            ConveyorEnabled = false
        end
    end
end)

-- ============================================================
--  MAIN LOOP (sequential, mirror manual)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if Toggles.AutoFarm and not FarmRunning then
            FarmRunning = true

            -- 1. Plant
            local plantOk = pcall(function()
                Remote.StartRound:InvokeServer(Settings.SelectedSeed, "Basic")
            end)

            if plantOk then
                -- 2. Tunggu lalu harvest
                if Settings.HarvestMode == "Grown" then
                    PlantDied = false
                    local elapsed = 0
                    while elapsed < Settings.GrownWaitTime do
                        task.wait(0.2)
                        elapsed = elapsed + 0.2
                        if PlantDied then break end
                    end
                else
                    task.wait(2)
                end

                -- 3. Harvest
                doHarvest()
                task.wait(0.3)

                -- 4. Equip seed
                doEquipSeed()
                task.wait(0.3)

                -- 5. Sell
                doSell()
                task.wait(0.3)
            else
                warn("StartRound failed")
                task.wait(1)
            end

            FarmRunning = false
        end
    end
end)

-- Anti AFK
task.spawn(function()
    while true do
        task.wait(300)
        if antiAfkEnabled then
            local char = LocalPlayer and LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(5), 0) end
        end
    end
end)

print("OK Greedy Growers AutoFarm v5.0 loaded!")
