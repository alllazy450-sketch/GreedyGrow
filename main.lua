-- ============================================================
--  W424HUB  | GREEDY GROWERS AUTO FARM v5.1
-- ============================================================
print("=== LOADING W424HUB - GREEDY GROWERS v5.1 ===")

-- ============================================================
--  LOAD UI LIBRARY (Oxidelib) + GAYA GROWAGARDEN2
-- ============================================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/Oxidelib/main/Oxidelib.lua"))()
if not Library then return warn("Oxidelib gagal dimuat") end

Library:SetTheme("Ocean")

local MY_LOGO = "rbxassetid://70773874533764"

local Window = Library:CreateWindow({
    Name = "W424HUB",
    BrandSubtitle = "Greedy Growers AutoFarm",
    Logo = MY_LOGO,
    LogoZoom = 1.5,
    ToggleKey = Enum.KeyCode.F3,
    ProfileKey = Enum.KeyCode.K,
    Size = UDim2.fromOffset(720, 500),
    LoadingText = "W424HUB",
    LoadingSubtitle = "Loading Greedy Growers Engine...",
})

-- Watermark
task.spawn(function()
    task.wait(0.5)
    if Window.Watermark then
        Window.Watermark.ImageTransparency = 0.4
    end
end)

-- ============================================================
--  MOBILE BUBBLE (FIX DUPLIKAT)
-- ============================================================
task.spawn(function()
    pcall(function()
        local sg = Window.ScreenGui
        if not sg then return end

        local oldBubble = sg:FindFirstChild("W424MobileBubble")
        if oldBubble then oldBubble:Destroy() end

        local btn = Instance.new("TextButton")
        btn.Name = "W424MobileBubble"
        btn.Size = UDim2.new(0, 56, 0, 56)
        btn.Position = UDim2.new(0.1, 0, 0.4, 0)
        btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        btn.BackgroundTransparency = 0.1
        btn.Text = ""
        btn.ZIndex = 999
        btn.Parent = sg

        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 16)

        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = Color3.fromRGB(167, 200, 244)
        stroke.Thickness = 1.5

        local icon = Instance.new("ImageLabel", btn)
        icon.Size = UDim2.new(0.8, 0, 0.8, 0)
        icon.Position = UDim2.new(0.1, 0, 0.1, 0)
        icon.BackgroundTransparency = 1
        icon.Image = MY_LOGO
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ZIndex = 1000

        btn.MouseButton1Click:Connect(function() Window:ToggleUI() end)

        local UserInputService = game:GetService("UserInputService")
        local dragging, dragStart, startPos = false, nil, nil

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, btn.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end)
end)

-- ============================================================
--  REMOTE LOADING
-- ============================================================
task.wait(1)

local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Debris     = game:GetService("Debris")

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
    Remote.PlantTree       = sg(function() return KnitServices.PlayerPlotService.RF.PlantTree end)
    Remote.FruitCollected  = sg(function() return KnitServices.PlayerPlotService.RE.FruitCollected end)
    Remote.CollectFruit    = sg(function() return KnitServices.PlayerPlotService.RF.CollectFruit end)
    Remote.FruitReady      = sg(function() return KnitServices.PlayerPlotService.RE.FruitReady end)
    Remote.TreeRemoved     = sg(function() return KnitServices.PlayerPlotService.RE.TreeRemoved end)
    Remote.GetMyPlot       = sg(function() return KnitServices.PlayerPlotService.RF.GetMyPlot end)
    Remote.CrashedAll      = sg(function() return KnitServices.PlantRoundService.RE.CrashedAll end)
    Remote.CollectAllFruits= sg(function() return KnitServices.PlayerPlotService.RF.CollectAllFruits end)
    Remote.GetPlotTrees    = sg(function() return KnitServices.PlayerPlotService.RF.GetPlotTrees end)
    Remote.GetPlotDecor    = sg(function() return KnitServices.PlayerPlotService.RF.GetPlotDecor end)
    Remote.SeedPurchased   = sg(function() return KnitServices.SeedConveyorService.RE.SeedPurchased end)
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
local Toggles   = { AutoFarm=false, AutoSell=false, AutoBuy=false, AutoHarvest=false, AutoHarvestFruit=false, AutoCollectAll=false }
local Settings  = {
    SelectedSeed="Oak", BuySeed={"Oak"}, BuyMode="Direct",
    BuyAmount=100, SellTargets={"All"}, HarvestMode="DeadTree",
    GrownWaitTime=8, SeedSlot=1,
    SellMode="Instant",
    SellCount=10,
    SellDelay=60,
    AutoCollectAll=false,
}
local FarmRunning     = false
local PlantDied       = false
local HarvestDone     = false
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
    if Settings.BuyMode == "Conveyor" then
        ConveyorEnabled = true
        return
    end
    if not Settings.BuySeed or #Settings.BuySeed == 0 then return end

    local buyRemote = Remote.BuySeed
    if not buyRemote then
        if KnitServices and KnitServices.SeedStandService and KnitServices.SeedStandService.RF then
            buyRemote = KnitServices.SeedStandService.RF.BuySeed
        end
    end

    if not buyRemote then
        warn("doBuy: Remote.BuySeed nil")
        return
    end

    for _, seed in ipairs(Settings.BuySeed) do
        local ok, err = pcall(function()
            buyRemote:InvokeServer(seed, Settings.BuyAmount)
        end)
        if not ok then
            warn("doBuy "..seed.." failed: "..tostring(err))
        end
        task.wait(0.05)
    end
end

local function doEquipSeed()
    if not Remote.ToggleEquip then return end
    local seedLower = Settings.SelectedSeed:lower()

    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        local items = inv:GetChildren()
        for i, item in ipairs(items) do
            local nameLow = item.Name:lower()
            if nameLow:find(seedLower) or (seedLower:find(nameLow) and #nameLow > 2) then
                pcall(function() Remote.ToggleEquip:FireServer(true, i) end)
                return
            end
        end
    end

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

    if Settings.SeedSlot >= 1 then
        pcall(function() Remote.ToggleEquip:FireServer(true, Settings.SeedSlot) end)
    end
end

local function getSeedUUID()
    local seedLower = Settings.SelectedSeed:lower()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        for _, item in ipairs(inv:GetChildren()) do
            if item.Name:lower():find(seedLower) then
                local uuid = item:GetAttribute("UUID") or item:GetAttribute("Id") or item:GetAttribute("ItemId")
                if uuid then return uuid end
                if #item.Name > 10 then return item.Name end
            end
        end
    end
    return nil
end

local function doHarvest()
    if not Toggles.AutoHarvest then return end
    if HarvestDone then return end
    HarvestDone = true

    if Remote.CollectDeadTree then
        pcall(function() Remote.CollectDeadTree:InvokeServer() end)
    end

    if Settings.HarvestMode == "Grown" and Remote.StopPlant then
        pcall(function() Remote.StopPlant:InvokeServer() end)
    end
end

local function doCollectAll()
    if not Toggles.AutoCollectAll then return end
    local collectRemote = Remote.CollectAllFruits
    if not collectRemote and KnitServices and KnitServices.PlayerPlotService and KnitServices.PlayerPlotService.RF then
        collectRemote = KnitServices.PlayerPlotService.RF.CollectAllFruits
    end
    if collectRemote then
        pcall(function() collectRemote:InvokeServer() end)
    end
end

local function countInventoryItems()
    local count = 0
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        for _, item in ipairs(inv:GetChildren()) do
            count = count + 1
        end
    end
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
        local itemCount = countInventoryItems()
        local timeSince = workspace.DistributedGameTime - LastSellTime
        local delayReached = timeSince >= math.min(Settings.SellDelay, 180)
        local countReached = itemCount >= Settings.SellCount
        if not delayReached and not countReached then return end
    end

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
        if Toggles.AutoHarvest and not HarvestDone then
            task.spawn(function()
                doHarvest()
                doSell()
            end)
        end
    end)
end

if Remote.TreeRemoved then
    Remote.TreeRemoved.OnClientEvent:Connect(function()
        PlantDied = true
        if Toggles.AutoHarvest and not HarvestDone then
            task.spawn(doHarvest)
        end
    end)
end

if Remote.CrashedAll then
    Remote.CrashedAll.OnClientEvent:Connect(function()
        PlantDied = true
        if Toggles.AutoHarvest and not HarvestDone then
            task.spawn(function()
                doHarvest()
                doSell()
            end)
        end
    end)
end

if Remote.FruitReady then
    Remote.FruitReady.OnClientEvent:Connect(function(plotIndex, fruitUUID, count, stage, mutations)
        if not Toggles.AutoHarvestFruit then return end
        if Remote.CollectFruit and fruitUUID then
            pcall(function() Remote.CollectFruit:InvokeServer(fruitUUID) end)
        elseif Remote.CollectDeadTree then
            pcall(function() Remote.CollectDeadTree:InvokeServer() end)
        end
    end)
end

if Remote.FruitCollected then
    Remote.FruitCollected.OnClientEvent:Connect(function(plotIndex, fruitUUID, count)
        if not Toggles.AutoHarvestFruit then return end
        if Remote.CollectFruit and fruitUUID then
            pcall(function() Remote.CollectFruit:InvokeServer(fruitUUID) end)
        end
    end)
end

-- ============================================================
--  UI STRUKTUR (OXIDELIB - GROWAGARDEN2)
-- ============================================================
local TabFarm = Window:AddTab({ Name = "Farm", Icon = "home" })
local TabShop = Window:AddTab({ Name = "Shop", Icon = "shopping" })
local TabMisc = Window:AddTab({ Name = "Misc", Icon = "gear" })
local TabInfo = Window:AddTab({ Name = "Info", Icon = "chart" })

-- ===== FARM TAB =====
local SubFarm = TabFarm:AddSubTab("Auto Farm")
local SubHarvest = TabFarm:AddSubTab("Harvest")
local SubManual = TabFarm:AddSubTab("Manual")

-- SubFarm
SubFarm:AddSection("AUTO FARM")
SubFarm:AddDropdown({
    Name = "Plant Seed",
    Options = SEEDS,
    Default = "Oak",
    Searchable = true,
    Callback = function(v) Settings.SelectedSeed = v end
})
SubFarm:AddSlider({
    Name = "Seed Slot (1-6)",
    Min = 1,
    Max = 6,
    Default = 1,
    Callback = function(v) Settings.SeedSlot = v end
})
SubFarm:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(v)
        Toggles.AutoFarm = v
        if not v and Remote.StopPlant then
            pcall(function() Remote.StopPlant:InvokeServer() end)
            FarmRunning = false
        end
        Window:Notify({ Title = "Auto Farm", Content = v and "ON" or "OFF", Type = v and "success" or "warning", Duration = 2 })
    end
})

-- SubHarvest (berisi semua fitur harvest + stop plant)
SubHarvest:AddSection("HARVEST SETTINGS")
SubHarvest:AddToggle({
    Name = "Auto Harvest",
    Default = false,
    Callback = function(v)
        Toggles.AutoHarvest = v
        Window:Notify({ Title = "Auto Harvest", Content = v and "ON" or "OFF", Type = v and "success" or "warning", Duration = 2 })
    end
})
SubHarvest:AddToggle({
    Name = "Auto Harvest Fruit",
    Default = false,
    Callback = function(v)
        Toggles.AutoHarvestFruit = v
        Window:Notify({ Title = "Auto Harvest Fruit", Content = v and "ON" or "OFF", Type = v and "success" or "warning", Duration = 2 })
    end
})
SubHarvest:AddToggle({
    Name = "Auto Collect All Fruits",
    Default = false,
    Callback = function(v)
        Toggles.AutoCollectAll = v
        Window:Notify({ Title = "Auto Collect All", Content = v and "ON" or "OFF", Type = v and "success" or "warning", Duration = 2 })
    end
})
SubHarvest:AddDropdown({
    Name = "Harvest Mode",
    Options = {"DeadTree","Grown"},
    Default = "DeadTree",
    Callback = function(v) Settings.HarvestMode = v end
})
SubHarvest:AddSlider({
    Name = "Grown Wait (sec)",
    Min = 1,
    Max = 30,
    Default = 8,
    Callback = function(v) Settings.GrownWaitTime = v end
})
SubHarvest:AddDivider()
SubHarvest:AddSection("QUICK ACTIONS")
SubHarvest:AddButton({
    Name = "Stop Plant (Now)",
    Callback = function()
        if Remote.StopPlant then
            pcall(function() Remote.StopPlant:InvokeServer() end)
            FarmRunning = false
            Window:Notify({ Title = "Stopped!", Type = "warning", Duration = 2 })
        end
    end
})
SubHarvest:AddButton({
    Name = "Harvest Now",
    Callback = function()
        if Remote.CollectDeadTree then
            pcall(function() Remote.CollectDeadTree:InvokeServer() end)
            Window:Notify({ Title = "Harvested!", Type = "success", Duration = 2 })
        end
    end
})

-- SubManual (tetap ada untuk kontrol lengkap)
SubManual:AddSection("MANUAL CONTROLS")
SubManual:AddButton({
    Name = "Plant Now",
    Callback = function()
        if Remote.StartRound then
            pcall(function() Remote.StartRound:InvokeServer(Settings.SelectedSeed, "Basic") end)
            Window:Notify({ Title = "Planted", Content = Settings.SelectedSeed, Type = "success", Duration = 2 })
        end
    end
})
SubManual:AddButton({
    Name = "Harvest Now",
    Callback = function()
        if Remote.CollectDeadTree then
            pcall(function() Remote.CollectDeadTree:InvokeServer() end)
            Window:Notify({ Title = "Harvested!", Type = "success", Duration = 2 })
        end
    end
})
SubManual:AddButton({
    Name = "Collect All Fruits",
    Callback = function()
        local collectRemote = Remote.CollectAllFruits
        if not collectRemote and KnitServices and KnitServices.PlayerPlotService and KnitServices.PlayerPlotService.RF then
            collectRemote = KnitServices.PlayerPlotService.RF.CollectAllFruits
        end
        if collectRemote then
            pcall(function() collectRemote:InvokeServer() end)
            Window:Notify({ Title = "Collected All Fruits", Type = "success", Duration = 2 })
        else
            Window:Notify({ Title = "Error", Content = "Remote tidak tersedia", Type = "warning", Duration = 2 })
        end
    end
})
SubManual:AddButton({
    Name = "Sell All Now",
    Callback = function()
        if Remote.SellAll then
            pcall(function() Remote.SellAll:InvokeServer() end)
            Window:Notify({ Title = "Sold All!", Type = "success", Duration = 2 })
        end
    end
})
SubManual:AddButton({
    Name = "Stop Plant",
    Callback = function()
        if Remote.StopPlant then
            pcall(function() Remote.StopPlant:InvokeServer() end)
            FarmRunning = false
            Window:Notify({ Title = "Stopped!", Type = "warning", Duration = 2 })
        end
    end
})

-- ===== SHOP TAB =====
local SubBuy = TabShop:AddSubTab("Buy")
local SubSell = TabShop:AddSubTab("Sell")
local SubStands = TabShop:AddSubTab("Stands")

-- SubBuy
SubBuy:AddSection("BUY SEEDS")
SubBuy:AddToggle({
    Name = "Auto Buy",
    Default = false,
    Callback = function(v)
        Toggles.AutoBuy = v
        if not v then ConveyorEnabled = false end
        Window:Notify({ Title = "Auto Buy", Content = v and "ON" or "OFF", Type = v and "success" or "warning", Duration = 2 })
    end
})
SubBuy:AddDropdown({
    Name = "Buy Seeds",
    Options = SEEDS,
    Default = {"Oak"},
    Multi = true,
    Searchable = true,
    Callback = function(v) Settings.BuySeed = v end
})
SubBuy:AddDropdown({
    Name = "Buy Mode",
    Options = {"Direct","Conveyor"},
    Default = "Direct",
    Callback = function(v)
        Settings.BuyMode = v
        if v == "Direct" then ConveyorEnabled = false end
    end
})
SubBuy:AddSlider({
    Name = "Buy Amount",
    Min = 10,
    Max = 500,
    Default = 100,
    Callback = function(v) Settings.BuyAmount = v end
})
SubBuy:AddButton({
    Name = "Buy Now",
    Callback = function() doBuy() end
})

-- SubSell
SubSell:AddSection("SELL SETTINGS")
SubSell:AddToggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(v)
        Toggles.AutoSell = v
        Window:Notify({ Title = "Auto Sell", Content = v and "ON" or "OFF", Type = v and "success" or "warning", Duration = 2 })
    end
})
local sellOpts2 = {"All"}
for _, s in ipairs(SEEDS) do table.insert(sellOpts2, s) end
SubSell:AddDropdown({
    Name = "Sell Targets",
    Options = sellOpts2,
    Default = {"All"},
    Multi = true,
    Searchable = true,
    Callback = function(v) Settings.SellTargets = v end
})
SubSell:AddDropdown({
    Name = "Sell Mode",
    Options = {"Instant","Count&Delay"},
    Default = "Instant",
    Callback = function(v) Settings.SellMode = v end
})
SubSell:AddSlider({
    Name = "Sell Count",
    Min = 1,
    Max = 100,
    Default = 10,
    Callback = function(v) Settings.SellCount = v end
})
SubSell:AddSlider({
    Name = "Sell Delay (sec)",
    Min = 5,
    Max = 180,
    Default = 60,
    Callback = function(v) Settings.SellDelay = v end
})
SubSell:AddButton({
    Name = "Sell All Now",
    Callback = function()
        if Remote.SellAll then
            pcall(function() Remote.SellAll:InvokeServer() end)
            Window:Notify({ Title = "Sold All!", Type = "success", Duration = 2 })
        end
    end
})

-- SubStands
SubStands:AddSection("TELEPORT TO STANDS")
SubStands:AddButton({
    Name = "TP to Sell Stand",
    Callback = function()
        local stand = workspace:FindFirstChild("BigField") and workspace.BigField:FindFirstChild("SellStand")
        if stand then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.CFrame = CFrame.new(stand:GetPivot().Position + Vector3.new(0,3,0)) end) end
            Window:Notify({ Title = "TP to Sell Stand", Type = "success", Duration = 2 })
        else
            Window:Notify({ Title = "Not found", Content = "Sell Stand tidak ditemukan", Type = "warning", Duration = 2 })
        end
    end
})
SubStands:AddButton({
    Name = "TP to Seed Stand",
    Callback = function()
        local stand = workspace:FindFirstChild("BigField") and workspace.BigField:FindFirstChild("SeedStand")
        if stand then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.CFrame = CFrame.new(stand:GetPivot().Position + Vector3.new(0,3,0)) end) end
            Window:Notify({ Title = "TP to Seed Stand", Type = "success", Duration = 2 })
        else
            Window:Notify({ Title = "Not found", Content = "Seed Stand tidak ditemukan", Type = "warning", Duration = 2 })
        end
    end
})

-- ===== MISC TAB =====
local SubMisc = TabMisc:AddSubTab("Settings")
SubMisc:AddSection("MISC")
local antiAfkEnabled = false
SubMisc:AddToggle({
    Name = "Anti AFK",
    Default = false,
    Callback = function(v)
        antiAfkEnabled = v
        Window:Notify({ Title = "Anti AFK", Content = v and "ON" or "OFF", Type = v and "success" or "warning", Duration = 2 })
    end
})
SubMisc:AddSlider({
    Name = "WalkSpeed",
    Min = 8,
    Max = 100,
    Default = 16,
    Callback = function(v)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.WalkSpeed = v end) end
    end
})
SubMisc:AddButton({
    Name = "Reduce Map (Potato)",
    Callback = function()
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    obj:Destroy()
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                elseif obj:IsA("PostEffect") then
                    obj.Enabled = false
                end
            end
            Window:Notify({ Title = "Potato Mode ON", Type = "success", Duration = 2 })
        end)
    end
})

-- ===== INFO TAB =====
local SubInfo = TabInfo:AddSubTab("Stats")
SubInfo:AddSection("PLOT INFO")
local plotInfoLabel = SubInfo:AddLabel({ Text = "Loading plot info..." })

local function updatePlotInfo()
    local plotRemote = Remote.GetMyPlot
    if not plotRemote and KnitServices and KnitServices.PlayerPlotService and KnitServices.PlayerPlotService.RF then
        plotRemote = KnitServices.PlayerPlotService.RF.GetMyPlot
    end
    if plotRemote then
        local ok, plotData = pcall(function() return plotRemote:InvokeServer() end)
        if ok and plotData then
            -- Cek apakah plotData adalah tabel, bukan number
            if type(plotData) == "table" then
                local treeCount = 0
                if plotData.Trees and type(plotData.Trees) == "table" then
                    treeCount = #plotData.Trees
                end
                plotInfoLabel.Text = "Plot: "..tostring(plotData.Name or "N/A").." | Trees: "..treeCount
                return
            else
                -- Jika plotData adalah number (misal ID), kita tampilkan saja ID-nya
                plotInfoLabel.Text = "Plot ID: "..tostring(plotData).." (tidak ada detail tambahan)"
                return
            end
        end
    end
    plotInfoLabel.Text = "Plot info: not available"
end

task.spawn(function()
    while true do
        task.wait(10)
        updatePlotInfo()
    end
end)

SubInfo:AddSection("FPS & PING")
local statsRef = SubInfo:AddLabel({ Text = "FPS: -- | Ping: --" })
task.spawn(function()
    while true do
        task.wait(1)
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        statsRef.Text = "FPS: "..fps.." | Ping: "..ping.."ms"
    end
end)

-- ============================================================
--  LOOP AUTO COLLECT ALL
-- ============================================================
task.spawn(function()
    while true do
        task.wait(5)
        if Toggles.AutoCollectAll then
            doCollectAll()
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
task.spawn(function()
    while true do
        task.wait(0.1)
        if Toggles.AutoFarm and not FarmRunning then
            FarmRunning = true
            HarvestDone = false
            PlantDied   = false

            if not Remote.StartRound then
                warn("Remote.StartRound nil")
                FarmRunning = false
                task.wait(3)
            else
                doEquipSeed()
                task.wait(0.1)

                local plantOk, plantErr = pcall(function()
                    Remote.StartRound:InvokeServer(Settings.SelectedSeed, "Basic")
                end)

                if plantOk then
                    if Settings.HarvestMode == "Grown" then
                        local elapsed = 0
                        while elapsed < Settings.GrownWaitTime do
                            task.wait(0.1); elapsed = elapsed + 0.1
                            if PlantDied then break end
                        end
                    else
                        local waitTime = (SEED_GENERATION_TIME[Settings.SelectedSeed] or 15) + 2
                        local elapsed = 0
                        while elapsed < waitTime do
                            task.wait(0.1); elapsed = elapsed + 0.1
                            if PlantDied then break end
                        end
                    end

                    if not HarvestDone then
                        doHarvest()
                        task.wait(0.1)
                    end

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

-- ============================================================
--  NOTIFIKASI AWAL
-- ============================================================
Window:Notify({
    Title = "W424HUB",
    Content = "Greedy Growers AutoFarm v5.1 loaded!",
    Type = "success",
    Duration = 5
})

print("✅ W424HUB - Greedy Growers AutoFarm v5.1 loaded!")
