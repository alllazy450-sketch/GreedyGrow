-- ============================================================
--  GREEDY GROWERS AUTO FARM v5.0
-- ============================================================
print("=== LOADING GREEDY GROWERS AUTO FARM v5.0 ===")

local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Debris     = game:GetService("Debris")

-- ============================================================
--  KAIRO UI
-- ============================================================
local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()
if not Kairo then warn("Kairo failed!") return end

local Window = Kairo:CreateWindow({
    Title = "Greedy Growers AutoFarm",
    Theme = "Ocean",
    Size = UDim2.fromOffset(480, 520),
    Center = true,
    Draggable = true,
    Badges = {"v5.0"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    Config = { Enabled = true, Folder = "GreedyGrowers_v5", AutoLoad = true }
})
if not Window then warn("Window failed!") return end

local TabFarm = Window:CreateTab("Farm")
local TabMisc = Window:CreateTab("Misc")

-- ============================================================
--  REMOTE LOADING
-- ============================================================
task.wait(1)

local KnitServices
local ok = pcall(function()
    KnitServices = RS.Packages._Index["sleitnick_knit@1.6.0"].knit.Services
end)
if not ok or not KnitServices then
    task.wait(2)
    pcall(function()
        KnitServices = RS.Packages._Index["sleitnick_knit@1.6.0"].knit.Services
    end)
end

local Remote = {}
if KnitServices then
    local function sg(fn) local ok,r = pcall(fn) if ok then return r end end
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
end

-- ============================================================
--  SEED LIST
-- ============================================================
local SEEDS = {
    "Oak","Pine","Apple","Peach","Fig","Orange","Lemon","Avocado","Cherry",
    "Mango","Coconut","Banana","Starfruit","Dragon Fruit","Glowing","Blooming",
    "Magic","Pizza","Diamond","Void"
}

local SEED_GENERATION_TIME = {
    Oak=10,Pine=12,Apple=30,Peach=40,Fig=50,Orange=60,Lemon=70,
    Avocado=90,Cherry=100,Mango=120,Coconut=150,Banana=180,Starfruit=240,
    ["Dragon Fruit"]=300,Glowing=360,Blooming=420,Magic=480,Pizza=540,Diamond=600,Void=720
}

-- ============================================================
--  STATE
-- ============================================================
local Toggles   = { AutoFarm=false, AutoSell=false, AutoBuy=false, AutoHarvest=false }
local Settings  = {
    SelectedSeed="Oak", BuySeed={"Oak"}, BuyMode="Direct",
    BuyAmount=100, SellTargets={"All"}, HarvestMode="DeadTree",
    GrownWaitTime=8, SeedSlot=1,
    SellMode="Instant",   -- "Instant" atau "Count&Delay"
    SellCount=10,         -- jual setiap N item di inventory
    SellDelay=60,         -- jual setiap N detik (max 180)
}
local FarmRunning     = false
local PlantDied       = false
local HarvestDone     = false  -- cegah double harvest
local ConveyorEnabled = false
local LastSellTime    = 0

-- Conveyor listener
if Remote.SeedSpawned and Remote.RequestPurchase then
    Remote.SeedSpawned.OnClientEvent:Connect(function(data)
        if not ConveyorEnabled or not Toggles.AutoBuy then return end
        if data and data.seedKey then
            for _, seed in ipairs(Settings.BuySeed) do
                if seed == data.seedKey then
                    pcall(function() Remote.RequestPurchase:InvokeServer(data.spawnId) end)
                    break
                end
            end
        end
    end)
end

-- ============================================================
--  HELPERS
-- ============================================================
local function doBuy()
    if not Toggles.AutoBuy then return end
    if Settings.BuyMode == "Conveyor" then ConveyorEnabled = true return end
    if not Remote.BuySeed then return end
    for _, seed in ipairs(Settings.BuySeed) do
        pcall(function() Remote.BuySeed:InvokeServer(seed, Settings.BuyAmount) end)
        task.wait(0.1)
    end
end

local function doEquipSeed()
    if not Remote.ToggleEquip then return end
    local seedLower = Settings.SelectedSeed:lower()

    -- Scan Inventory (6 slot), cari seed yang cocok by nama
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        local items = inv:GetChildren()
        for i, item in ipairs(items) do
            if item.Name:lower():find(seedLower) then
                pcall(function() Remote.ToggleEquip:FireServer(true, i) end)
                return
            end
        end
    end

    -- Fallback: scan Backpack by index
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        local items = bp:GetChildren()
        for i, item in ipairs(items) do
            if item:IsA("Tool") and item.Name:lower():find(seedLower) then
                pcall(function() Remote.ToggleEquip:FireServer(true, i) end)
                return
            end
        end
    end

    -- Last fallback: pakai slot manual dari Settings.SeedSlot
    if Settings.SeedSlot >= 1 then
        pcall(function() Remote.ToggleEquip:FireServer(true, Settings.SeedSlot) end)
    end
end

local function doHarvest()
    if not Toggles.AutoHarvest then return end
    if HarvestDone then return end
    HarvestDone = true
    if Settings.HarvestMode == "DeadTree" then
        if Remote.CollectDeadTree then
            pcall(function() Remote.CollectDeadTree:InvokeServer() end)
        end
    elseif Settings.HarvestMode == "Grown" then
        if Remote.StopPlant then
            pcall(function() Remote.StopPlant:InvokeServer() end)
        end
    end
end

local function countInventoryItems()
    local count = 0
    -- cek Inventory folder
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        for _, item in ipairs(inv:GetChildren()) do
            count = count + 1
        end
    end
    -- cek Backpack
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then count = count + 1 end
        end
    end
    return count
end

local function doSell()
    if not Toggles.AutoSell then return end

    if Settings.SellMode == "Count&Delay" then
        -- Jual berdasarkan count atau delay
        local itemCount = countInventoryItems()
        local timeSince = workspace.DistributedGameTime - LastSellTime
        local delayReached = timeSince >= math.min(Settings.SellDelay, 180)
        local countReached = itemCount >= Settings.SellCount
        if not delayReached and not countReached then return end
    end

    -- Lakukan sell
    if Remote.SellAll then
        pcall(function() Remote.SellAll:InvokeServer() end)
        task.wait(0.3)
    end
    if Settings.SellTargets and Remote.SellTree then
        for _, t in ipairs(Settings.SellTargets) do
            if t ~= "All" then
                pcall(function() Remote.SellTree:InvokeServer(t) end)
                task.wait(0.2)
            end
        end
    end
    LastSellTime = workspace.DistributedGameTime
end

local function onRoundStopped()
    PlantDied = true
    if Toggles.AutoHarvest and not HarvestDone then
        doHarvest()
    end
    doSell()
end

if Remote.PlantStoppedAll then
    Remote.PlantStoppedAll.OnClientEvent:Connect(function()
        PlantDied = true
        if Toggles.AutoHarvest or Toggles.AutoSell then
            task.spawn(onRoundStopped)
        end
    end)
end

-- ============================================================
--  KAIRO WRAPPERS
-- ============================================================
local _curTab = TabFarm

local C_ON  = Color3.fromRGB(0, 180, 80)
local C_OFF = Color3.fromRGB(80, 80, 100)

local function notify(text, color)
    Window:Notify({Title="GG AutoFarm", Description=text, Color=color or Color3.fromRGB(60,140,220), Duration=2})
end

local function addSection(title, tab)
    _curTab = tab or _curTab
    Window:AddDivider(_curTab, title)
end

local function addToggle(title, default, callback)
    Window:AddToggle(_curTab, title, "", default, callback)
end

local function addButton(title, callback)
    Window:AddButton(_curTab, title, "", nil, callback)
end

local function addDropdown(title, options, default, callback)
    Window:AddDropdown(_curTab, title, "", options, false, default, callback)
end

local function addMultiDropdown(title, options, default, callback)
    Window:AddDropdown(_curTab, title, "", options, true, default, callback)
end

local function addSlider(title, min, max, default, callback)
    Window:AddSlider(_curTab, title, "", min, max, default, callback)
end

-- ============================================================
--  BUILD UI
-- ============================================================

-- FARM
addSection("AUTO FARM")
addDropdown("Plant Seed", SEEDS, "Oak", function(v) Settings.SelectedSeed = v end)
addSlider("Seed Slot (1-6)", 1, 6, 1, function(v) Settings.SeedSlot = v end)
addToggle("Auto Farm", false, function(v)
    Toggles.AutoFarm = v
    if not v and Remote.StopPlant then
        pcall(function() Remote.StopPlant:InvokeServer() end)
        FarmRunning = false
    end
    notify("Auto Farm: "..(v and "ON" or "OFF"), v and C_ON or C_OFF)
end)

-- HARVEST
addSection("HARVEST")
addToggle("Auto Harvest", false, function(v)
    Toggles.AutoHarvest = v
    notify("Auto Harvest: "..(v and "ON" or "OFF"), v and C_ON or C_OFF)
end)
addDropdown("Harvest Mode", {"DeadTree","Grown"}, "DeadTree", function(v) Settings.HarvestMode = v end)
addSlider("Grown Wait (sec)", 1, 30, 8, function(v) Settings.GrownWaitTime = v end)

-- BUY
addSection("BUY")
addToggle("Auto Buy", false, function(v)
    Toggles.AutoBuy = v
    if not v then ConveyorEnabled = false end
    notify("Auto Buy: "..(v and "ON" or "OFF"), v and C_ON or C_OFF)
end)
addMultiDropdown("Buy Seeds", SEEDS, {"Oak"}, function(v) Settings.BuySeed = v end)
addDropdown("Buy Mode", {"Direct", "Conveyor"}, "Direct", function(v)
    Settings.BuyMode = v
    if v == "Direct" then ConveyorEnabled = false end
end)
addSlider("Buy Amount", 10, 500, 100, function(v) Settings.BuyAmount = v end)

-- SELL
addSection("SELL")
addToggle("Auto Sell", false, function(v)
    Toggles.AutoSell = v
    notify("Auto Sell: "..(v and "ON" or "OFF"), v and C_ON or C_OFF)
end)
local sellOpts = {"All"}
for _, s in ipairs(SEEDS) do table.insert(sellOpts, s) end
addMultiDropdown("Sell Targets", sellOpts, {"All"}, function(v) Settings.SellTargets = v end)
addDropdown("Sell Mode", {"Instant","Count&Delay"}, "Instant", function(v) Settings.SellMode = v end)
addSlider("Sell Count (items)", 1, 100, 10, function(v) Settings.SellCount = v end)
addSlider("Sell Delay (sec)", 5, 180, 60, function(v) Settings.SellDelay = v end)

-- MANUAL
addSection("MANUAL")
addButton("Plant Now", function()
    if Remote.StartRound then
        pcall(function() Remote.StartRound:InvokeServer(Settings.SelectedSeed, "Basic") end)
        notify("Planted: "..Settings.SelectedSeed, C_ACCENT)
    end
end)
addButton("Harvest Now", function()
    if Remote.CollectDeadTree then
        pcall(function() Remote.CollectDeadTree:InvokeServer() end)
        notify("Harvested!", C_ON)
    end
end)
addButton("Sell All Now", function()
    if Remote.SellAll then
        pcall(function() Remote.SellAll:InvokeServer() end)
        notify("Sold All!", C_ON)
    end
end)
addButton("Stop Plant", function()
    if Remote.StopPlant then
        pcall(function() Remote.StopPlant:InvokeServer() end)
        FarmRunning = false
        notify("Stopped!", C_OFF)
    end
end)
addButton("Buy Seed Now", function() doBuy() end)

-- MISC
addSection("MISC", TabMisc)
local antiAfkEnabled = false
addToggle("Anti AFK", false, function(v)
    antiAfkEnabled = v
    notify("Anti AFK: "..(v and "ON" or "OFF"), v and C_ON or C_OFF)
end)


local statsRef = Window:AddParagraph(TabMisc, "Stats", "FPS: -- | Ping: --")

task.spawn(function()
    while true do
        task.wait(1)
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        if statsRef then
            pcall(function() statsRef.Text = "FPS: "..fps.." | Ping: "..ping.."ms" end)
        end
    end
end)

-- ============================================================
--  BUY LOOP
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoBuy and Settings.BuyMode == "Direct" then doBuy() end
        if Toggles.AutoBuy and Settings.BuyMode == "Conveyor" then
            ConveyorEnabled = true
        else
            ConveyorEnabled = false
        end
    end
end)

-- ============================================================
--  MAIN LOOP
-- ============================================================
local SEED_TIME = {
    Oak=10,Pine=12,Apple=30,Peach=40,Fig=50,Orange=60,Lemon=70,
    Avocado=90,Cherry=100,Mango=120,Coconut=150,Banana=180,Starfruit=240,
    ["Dragon Fruit"]=300,Glowing=360,Blooming=420,Magic=480,Pizza=540,Diamond=600,Void=720
}

task.spawn(function()
    while true do
        task.wait(0.1)
        if Toggles.AutoFarm and not FarmRunning then
            FarmRunning = true
            HarvestDone = false
            PlantDied   = false

            -- Cek remote dulu
            if not Remote.StartRound then
                warn("Remote.StartRound nil — KnitServices belum load")
                FarmRunning = false
                task.wait(3)
            else
                -- Equip seed dulu sebelum plant
                doEquipSeed()
                task.wait(0.1)

                -- Plant
                local plantOk, plantErr = pcall(function()
                    Remote.StartRound:InvokeServer(Settings.SelectedSeed, "Basic")
                end)

                if plantOk then
                    -- Tunggu sesuai mode
                    if Settings.HarvestMode == "Grown" then
                        local elapsed = 0
                        while elapsed < Settings.GrownWaitTime do
                            task.wait(0.1); elapsed = elapsed + 0.1
                            if PlantDied then break end
                        end
                    else
                        -- DeadTree: tunggu sampai pohon mati
                        local waitTime = (SEED_TIME[Settings.SelectedSeed] or 15) + 2
                        local elapsed = 0
                        while elapsed < waitTime do
                            task.wait(0.1); elapsed = elapsed + 0.1
                            if PlantDied then break end
                        end
                    end

                    -- Harvest
                    if not HarvestDone then
                        doHarvest()
                        task.wait(0.1)
                    end

                    -- Sell
                    doSell()
                    task.wait(0.1)
                else
                    warn("StartRound failed: "..tostring(plantErr))
                    task.wait(2)
                end

                FarmRunning = false
            end
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
