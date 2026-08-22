-- ============================================================
--  W424HUB | GREEDY GROWERS AUTO FARM v5.6 (PRO EDITION)
--  Sistem: Auto-Equip, Multi-Seed, & Custom Grown Config
-- ============================================================

-- [TRACKING DATA]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StartTime = tick()
local InitialMoney = 0

pcall(function() InitialMoney = LocalPlayer.leaderstats.Money.Value end)

-- [LOAD UI LIBRARY]
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/Oxidelib/main/Oxidelib.lua"))()
if not Library then return end

Library:SetTheme("Ocean")
local MY_LOGO = "rbxassetid://70773874533764"

local Window = Library:CreateWindow({
    Name = "W424HUB v5.6",
    BrandSubtitle = "Multi-Seed & Auto-Equip Engine",
    Logo = MY_LOGO,
    Size = UDim2.fromOffset(750, 650),
})

-- [KNIT SERVICES INITIALIZATION]
local RS = game:GetService("ReplicatedStorage")
local KnitServices = nil
local Remote = {}

local function InitKnit()
    local attempts = 0
    while not KnitServices and attempts < 10 do
        pcall(function()
            KnitServices = RS.Packages._Index["sleitnick_knit@1.6.0"].knit.Services
        end)
        if not KnitServices then task.wait(1) attempts = attempts + 1 end
    end

    if KnitServices then
        Remote.StartRound       = KnitServices.PlantRoundService.RF.StartRound
        Remote.StopPlant        = KnitServices.PlantRoundService.RF.StopPlant
        Remote.CollectDeadTree  = KnitServices.PlantRoundService.RF.CollectDeadTree
        Remote.SellAll          = KnitServices.SellStandService.RF.SellAll
        Remote.BuySeed          = KnitServices.SeedStandService.RF.BuySeed
        Remote.ToggleEquip      = KnitServices.ToolService.RE.ToggleEquip
        Remote.GetMyPlot        = KnitServices.PlayerPlotService.RF.GetMyPlot
    end
end
InitKnit()

-- [STATE & SETTINGS]
local Toggles = { AutoFarm = false, AutoSell = false, AntiAFK = true }
local Settings = { 
    MultiSeeds = {"Oak"}, -- Menyimpan daftar seed yang dipilih
    RoundType = "Basic",   -- Basic / Research / Gold
    HarvestMode = "DeadTree",
    GrownWaitTime = 5,     -- User bisa setting ini (detik)
    SafetyTimeout = 30,
    SmartDelay = 1,
    CurrentSeedIndex = 1
}
local FarmRunning = false

-- [FUNCTIONS: SMART EQUIP]
local function SmartEquip(seedName)
    -- Mencari seed di Inventory Folder atau Backpack
    local inventory = LocalPlayer:FindFirstChild("Inventory") or LocalPlayer:FindFirstChildOfClass("Backpack")
    if not inventory then return false end

    for _, item in ipairs(inventory:GetChildren()) do
        if item.Name:lower():find(seedName:lower()) then
            -- Ambil Index item (biasanya ada di Attribute atau nama)
            local itemIndex = item:GetAttribute("Index") or 1 
            pcall(function() Remote.ToggleEquip:FireServer(true, itemIndex) end)
            return true
        end
    end
    return false
end

-- [TABS & UI]
local TabFarm = Window:AddTab({ Name = "Farm", Icon = "home" })
local TabConfig = Window:AddTab({ Name = "Smart Config", Icon = "gear" })

-- Tab Farm: Engine
local SubFarm = TabFarm:AddSubTab("Engine")
SubFarm:AddSection("PLANTING SYSTEM")

SubFarm:AddDropdown({ 
    Name = "Select Multiple Seeds", 
    Options = {"Oak","Pine","Apple","Peach","Lemon","Dragon Fruit","Void"}, 
    Default = {"Oak"}, 
    Multi = true, -- BISA PILIH BANYAK
    Callback = function(v) Settings.MultiSeeds = v end 
})

SubFarm:AddDropdown({ 
    Name = "Round Type (Research)", 
    Options = {"Basic", "Research", "Gold"}, 
    Default = "Basic", 
    Callback = function(v) Settings.RoundType = v end 
})

SubFarm:AddToggle({ Name = "Start Multi-Auto Farm", Default = false, Callback = function(v) Toggles.AutoFarm = v end })
SubFarm:AddToggle({ Name = "Auto Sell", Default = false, Callback = function(v) Toggles.AutoSell = v end })

-- Tab Config: Smart Settings
local SubConfig = TabConfig:AddSubTab("Advanced")
SubConfig:AddSection("GROWN MODE SETTINGS")

SubConfig:AddDropdown({ 
    Name = "Harvest Mode", 
    Options = {"DeadTree", "Grown"}, 
    Default = "DeadTree",
    Callback = function(v) Settings.HarvestMode = v end 
})

SubConfig:AddSlider({ 
    Name = "Grown Pick Delay (sec)", 
    Min = 0, Max = 30, Default = 5, 
    Tooltip = "Berapa detik nunggu setelah pohon berbuah baru dipetik/stop.",
    Callback = function(v) Settings.GrownWaitTime = v end 
})

SubConfig:AddSection("TIMING & SAFETY")
SubConfig:AddSlider({ Name = "Safety Timeout (sec)", Min = 10, Max = 120, Default = 30, Callback = function(v) Settings.SafetyTimeout = v end })
SubConfig:AddSlider({ Name = "Post-Harvest Delay (sec)", Min = 0, Max = 5, Default = 1, Callback = function(v) Settings.SmartDelay = v end })

-- [MAIN LOOP: MULTI-SEED ENGINE]

task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoFarm and not FarmRunning then
            -- Cek apakah ada seed yang dipilih
            if #Settings.MultiSeeds == 0 then 
                task.wait(1) 
                continue 
            end

            FarmRunning = true
            
            -- Ambil seed berikutnya dari antrian
            local targetSeed = Settings.MultiSeeds[Settings.CurrentSeedIndex]
            
            -- AUTO EQUIP DETEKSYEN
            local hasSeed = SmartEquip(targetSeed)
            
            if not hasSeed then
                -- Jika tidak punya seed ini, coba beli otomatis (Optional)
                pcall(function() Remote.BuySeed:InvokeServer(targetSeed, 1) end)
                task.wait(0.5)
                SmartEquip(targetSeed)
            end

            -- START PLANTING
            local success = pcall(function() 
                Remote.StartRound:InvokeServer(targetSeed, Settings.RoundType) 
            end)

            if success then
                local MyPlot = Remote.GetMyPlot:InvokeServer()
                local start = tick()
                
                -- MONITORING GROWTH
                repeat 
                    task.wait(0.5)
                    local isReady = false
                    if Settings.HarvestMode == "DeadTree" then
                        isReady = MyPlot:GetAttribute("Dead") 
                    else
                        isReady = MyPlot:GetAttribute("Grown") or (MyPlot:GetAttribute("Stage") == 5)
                    end
                until isReady or (tick() - start > Settings.SafetyTimeout) or not Toggles.AutoFarm
                
                -- CUSTOM GROWN WAIT (SETTINGAN USER)
                if Settings.HarvestMode == "Grown" and isReady then
                    Window:Notify({ Title = "Pohon Tumbuh!", Content = "Menunggu "..Settings.GrownWaitTime.." detik sebelum petik.", Duration = 2 })
                    task.wait(Settings.GrownWaitTime)
                    pcall(function() Remote.StopPlant:InvokeServer() end)
                    task.wait(0.2)
                end

                -- FINAL DELAY
                if Settings.SmartDelay > 0 then task.wait(Settings.SmartDelay) end
                
                -- PANEN & JUAL
                Remote.CollectDeadTree:InvokeServer()
                if Toggles.AutoSell then Remote.SellAll:InvokeServer() end

                -- PINDAH KE SEED BERIKUTNYA DALAM LIST (Antrian)
                Settings.CurrentSeedIndex = Settings.CurrentSeedIndex + 1
                if Settings.CurrentSeedIndex > #Settings.MultiSeeds then
                    Settings.CurrentSeedIndex = 1
                end
            end
            FarmRunning = false
        end
    end
end)

-- Anti-AFK & Fixes
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if Toggles.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

Window:Notify({ Title = "W424HUB v5.6", Content = "Multi-Seed Engine Ready!", Type = "success" })
