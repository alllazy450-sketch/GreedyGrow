-- ============================================================
--  W424HUB | GREEDY GROWERS AUTO FARM v5.3 (ADVANCED)
--  New: Auto Rebirth, Admin Detector, Server Hopper
-- ============================================================

-- [TRACKING DATA]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StartTime = tick()
local InitialMoney = 0
local AdminGroupID = 34320950 -- Ganti dengan Group ID game jika tahu

pcall(function() InitialMoney = LocalPlayer.leaderstats.Money.Value end)

-- [LOAD UI LIBRARY]
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/Oxidelib/main/Oxidelib.lua"))()
if not Library then return end

Library:SetTheme("Ocean")
local MY_LOGO = "rbxassetid://70773874533764"

local Window = Library:CreateWindow({
    Name = "W424HUB v5.3",
    BrandSubtitle = "Advanced Greedy Growers Engine",
    Logo = MY_LOGO,
    Size = UDim2.fromOffset(750, 550),
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
        Remote.CollectAllFruits = KnitServices.PlayerPlotService.RF.CollectAllFruits
        Remote.GetMyPlot        = KnitServices.PlayerPlotService.RF.GetMyPlot
        -- Remote Rebirth (Biasanya ada di RebirthService)
        Remote.Rebirth          = pcall(function() return KnitServices.RebirthService.RF.Rebirth end)
    end
end
InitKnit()

-- [STATE & SETTINGS]
local Toggles = { AutoFarm = false, AutoSell = false, AutoBuy = false, AntiAFK = true, Webhook = false, AutoRebirth = false, AdminDetect = false }
local Settings = { SelectedSeed = "Oak", BuyAmount = 100, WebhookURL = "", WebhookInt = 600 }
local FarmRunning = false
local LastWebhookTime = 0

-- [FUNCTIONS]
local function ServerHop()
    local PlaceID = game.PlaceId
    local JobID = game.JobId
    local TeleportService = game:GetService("TeleportService")
    pcall(function()
        TeleportService:Teleport(PlaceID, LocalPlayer)
    end)
end

local function CheckAdmin(player)
    if Toggles.AdminDetect then
        if player:GetRankInGroup(AdminGroupID) >= 100 or player.Name:lower():find("admin") then
            Window:Notify({ Title = "ADMIN DETECTED", Content = "Leaving server for safety...", Type = "warning" })
            task.wait(1)
            ServerHop()
        end
    end
end

local function SendWebhook()
    if Settings.WebhookURL == "" then return end
    local CurrentMoney = LocalPlayer.leaderstats.Money.Value
    local data = {
        ["embeds"] = {{
            ["title"] = "W424HUB v5.3 Report",
            ["color"] = 65432,
            ["fields"] = {
                {["name"] = "Player", ["value"] = LocalPlayer.Name, ["inline"] = true},
                {["name"] = "Earned", ["value"] = "$" .. tostring(CurrentMoney - InitialMoney), ["inline"] = true},
                {["name"] = "Total Money", ["value"] = "$" .. tostring(CurrentMoney), ["inline"] = false}
            }
        }}
    }
    pcall(function()
        (syn and syn.request or http_request or request)({
            Url = Settings.WebhookURL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    end)
end

-- [TABS & UI]
local TabFarm = Window:AddTab({ Name = "Farm", Icon = "home" })
local TabStats = Window:AddTab({ Name = "Stats", Icon = "chart" })
local TabMisc = Window:AddTab({ Name = "Safety & Misc", Icon = "gear" })

-- Tab Farm
local SubFarm = TabFarm:AddSubTab("Engine")
SubFarm:AddDropdown({ Name = "Select Seed", Options = {"Oak","Pine","Apple","Peach","Void"}, Default = "Oak", Callback = function(v) Settings.SelectedSeed = v end })
SubFarm:AddToggle({ Name = "Start Auto Farm", Default = false, Callback = function(v) Toggles.AutoFarm = v end })
SubFarm:AddToggle({ Name = "Auto Rebirth", Default = false, Callback = function(v) Toggles.AutoRebirth = v end })

-- Tab Stats
local SubStats = TabStats:AddSubTab("Dashboard")
local LabelRate = SubStats:AddLabel({ Text = "Rate: $0/hr" })
SubStats:AddInput({ Name = "Webhook URL", Placeholder = "URL...", Callback = function(v) Settings.WebhookURL = v end })
SubStats:AddToggle({ Name = "Enable Webhook", Default = false, Callback = function(v) Toggles.Webhook = v end })

-- Tab Misc
local SubMisc = TabMisc:AddSubTab("Settings")
SubMisc:AddToggle({ Name = "Admin Detector", Default = false, Callback = function(v) Toggles.AdminDetect = v end })
SubMisc:AddButton({ Name = "Server Hop", Callback = ServerHop })
SubMisc:AddButton({ Name = "Ultra Potato", Callback = function()
    settings().Rendering.QualityLevel = 1
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic end
    end
end })

-- [LOOPS]

-- Admin Detector Event
Players.PlayerAdded:Connect(CheckAdmin)

-- Main Automation Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoFarm and not FarmRunning then
            FarmRunning = true
            
            -- Auto Buy & Equip logic here
            pcall(function() Remote.BuySeed:InvokeServer(Settings.SelectedSeed, 100) end)
            
            -- Plant & Smart Wait
            local success = pcall(function() Remote.StartRound:InvokeServer(Settings.SelectedSeed, "Basic") end)
            if success then
                local MyPlot = Remote.GetMyPlot:InvokeServer()
                local start = tick()
                repeat task.wait(1) until MyPlot:GetAttribute("Dead") or (tick() - start > 25) or not Toggles.AutoFarm
                Remote.CollectDeadTree:InvokeServer()
                Remote.SellAll:InvokeServer()
            end
            FarmRunning = false
        end

        if Toggles.AutoRebirth then
            pcall(function() KnitServices.RebirthService.RF.Rebirth:InvokeServer() end)
        end
    end
end)

-- Stats Loop
task.spawn(function()
    while true do
        task.wait(10)
        local Earned = LocalPlayer.leaderstats.Money.Value - InitialMoney
        local Rate = math.floor(Earned / ((tick() - StartTime) / 3600))
        LabelRate.Text = "Rate: $" .. tostring(Rate) .. "/hr"
        if Toggles.Webhook and (tick() - LastWebhookTime) > Settings.WebhookInt then
            SendWebhook()
            LastWebhookTime = tick()
        end
    end
end)

-- Anti-AFK
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    if Toggles.AntiAFK then
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

Window:Notify({ Title = "W424HUB v5.3", Content = "Ready to Farm!", Type = "success" })
