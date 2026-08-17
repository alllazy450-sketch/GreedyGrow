-- ============================================
-- W424HUB – MM2
-- ============================================
print("=== LOADING W424HUB ===")

local Players             = game:GetService("Players")
local LocalPlayer         = Players.LocalPlayer
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")
local CoreGui             = game:GetService("CoreGui")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local Camera              = workspace.CurrentCamera

-- ============================================
-- LOAD ORVION UI
-- ============================================
local Orvion
local _src
local _ok1 = pcall(function() _src = game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/Orvion-UI-Library/main/source.luau") end)
if not _ok1 or not _src or _src == "" then warn("Orvion fetch failed!") return end
local _fn, _err = loadstring(_src)
if not _fn then warn("Orvion loadstring failed: "..tostring(_err)) return end
local _ok2 = pcall(function() Orvion = _fn() end)
if not _ok2 or not Orvion then warn("Orvion init failed!") return end

local Window = Orvion:CreateWindow({
    Title          = "W424HUB",
    Theme          = "Default",
    Size           = UDim2.fromOffset(470, 270),
    Center         = true,
    Draggable      = true,
    Badges         = {"v3.0"},
    ToggleButton   = true,
})
if not Window then return end

Window:Notify({Title="W424HUB", Description="Loaded!", Color=Color3.fromRGB(0,200,50), Duration=3})

-- ============================================
-- FUNGSI GET ROLE (AKURAT)
-- ============================================
local function getRole(player)
    if not player or not player.Character then return "Innocent" end

    local hasKnife = false
    local hasGun = false

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("knife") or name:find("murderer") or name:find("blade") then
                    hasKnife = true
                end
                if name:find("gun") or name:find("revolver") or name:find("sheriff") or name:find("pistol") then
                    hasGun = true
                end
            end
        end
    end

    local charTool = player.Character:FindFirstChildOfClass("Tool")
    if charTool then
        local name = charTool.Name:lower()
        if name:find("knife") or name:find("murderer") or name:find("blade") then
            hasKnife = true
        end
        if name:find("gun") or name:find("revolver") or name:find("sheriff") or name:find("pistol") then
            hasGun = true
        end
    end

    if hasKnife then return "Murderer" end
    if hasGun then return "Sheriff" end
    return "Innocent"
end

local function isMurderer(player)
    return getRole(player) == "Murderer"
end

local function isSheriff(player)
    return getRole(player) == "Sheriff"
end

local function CharacterRayOrigin(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return (hrp.CFrame * CFrame.new(0, 0, hrp.Size.Z / 2)).Position
end

local function hasClearLOS(fromPos, toPos, myChar, targetChar)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {myChar, targetChar}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(fromPos, (toPos - fromPos), params)
    if result then
        if not result.Instance:IsDescendantOf(targetChar) then
            return false
        end
    end
    return true
end

-- ============================================
-- TAB SHERIFF
-- ============================================
local TabSheriff   = Window:CreateTab("Sheriff")
local TabMurderer  = Window:CreateTab("Murderer")
local TabVisual    = Window:CreateTab("Visual")
local TabInnocent  = Window:CreateTab("Innocent")
local TabSkins     = Window:CreateTab("Skins")

local secSheriff = Window:AddCollapsible(TabSheriff, "Sheriff Aimbot", true)

local sheriffAimbot    = false
local sheriffTrigger   = "On Shoot"
local sheriffTargetMode = "Murderer Only"
local sheriffFOV       = 150
local sheriffDistance  = 300
local sheriffSmooth    = 0.5
local sheriffWall      = true
local sheriffPrediction = false
local sheriffPredFactor = 0.2
local sheriffAutoShoot = false
local sheriffAutoDelay = 0.1
local sheriffTargetPart = "HumanoidRootPart"
local lastAutoShootTime = 0
local lastThrowTime     = 0
local function getT() return workspace.DistributedGameTime end

Window:AddToggle(secSheriff, "Enable Aimbot", "Aim at target", false, function(v) sheriffAimbot = v end)
Window:AddDropdown(secSheriff, "Trigger", "When to aim", {"On Shoot","Always"}, false, "On Shoot", function(v) sheriffTrigger = v end)
Window:AddDropdown(secSheriff, "Target", "Who to aim at", {"Murderer Only","All Players","Innocent Only"}, false, "Murderer Only", function(v) sheriffTargetMode = v end)
Window:AddSlider(secSheriff, "FOV Radius", "30-400", 30, 400, 150, function(v) sheriffFOV = v end)
Window:AddSlider(secSheriff, "Max Distance", "50-500", 50, 500, 300, function(v) sheriffDistance = v end)
Window:AddSlider(secSheriff, "Smoothness", "1-10", 1, 10, 5, function(v) sheriffSmooth = v / 10 end)
Window:AddToggle(secSheriff, "Wall Check", "No wall penetration", true, function(v) sheriffWall = v end)
Window:AddToggle(secSheriff, "Prediction", "Lead target position", false, function(v) sheriffPrediction = v end)
Window:AddSlider(secSheriff, "Pred Factor", "0-100", 0, 100, 20, function(v) sheriffPredFactor = v / 100 end)
Window:AddToggle(secSheriff, "Auto Shoot", "Auto fire", false, function(v) sheriffAutoShoot = v end)
Window:AddSlider(secSheriff, "Auto Shoot Delay", "5-50ms", 5, 50, 10, function(v) sheriffAutoDelay = v / 100 end)
Window:AddDropdown(secSheriff, "Target Part", "Body part to aim", {"Head","HumanoidRootPart","Torso"}, false, "HumanoidRootPart", function(v) sheriffTargetPart = v end)

-- ============================================
-- TAB MURDERER
-- ============================================
local secMurderer = Window:AddCollapsible(TabMurderer, "Murderer Tools", true)

local murdererThrow       = false
local murdererThrowTarget = "All Players"
local murdererThrowDist   = 300
local murdererThrowCD     = 2
local murdererThrowPred   = false
local murdererThrowPredFactor = 0.2
local murdererThrowWall   = true
local murdererAutoEquip   = false
local murdererMelee       = false
local murdererMeleeRadius = 10

Window:AddToggle(secMurderer, "Auto Throw Knife", "Auto throw knife", false, function(v) murdererThrow = v end)
Window:AddDropdown(secMurderer, "Throw Target", "Throw target", {"All Players","Sheriff Only","Innocent Only"}, false, "All Players", function(v) murdererThrowTarget = v end)
Window:AddSlider(secMurderer, "Max Throw Distance", "50-500", 50, 500, 300, function(v) murdererThrowDist = v end)
Window:AddSlider(secMurderer, "Throw Cooldown", "0.5-10s", 1, 20, 4, function(v) murdererThrowCD = v / 2 end)
Window:AddToggle(secMurderer, "Throw Prediction", "Lead throw position", false, function(v) murdererThrowPred = v end)
Window:AddSlider(secMurderer, "Throw Pred Factor", "0-100", 0, 100, 20, function(v) murdererThrowPredFactor = v / 100 end)
Window:AddToggle(secMurderer, "Throw Wall Check", "No wall throw", true, function(v) murdererThrowWall = v end)
Window:AddToggle(secMurderer, "Auto Equip Knife", "Auto equip knife", false, function(v) murdererAutoEquip = v end)

local secMelee = Window:AddCollapsible(TabMurderer, "Auto Melee", true)
Window:AddToggle(secMelee, "Auto Melee", "Attack nearby enemies", false, function(v) murdererMelee = v end)
Window:AddSlider(secMelee, "Melee Radius", "3-30 studs", 3, 30, 10, function(v) murdererMeleeRadius = v end)

-- ============================================
-- TAB VISUAL
-- ============================================
local secESP = Window:AddCollapsible(TabVisual, "ESP", true)

if CoreGui:FindFirstChild("ESP_Holder") then CoreGui.ESP_Holder:Destroy() end
local espEnabled = false
local espData    = {}

local function updateESPVisual(player)
    local data = espData[player]
    if not data or not espEnabled then
        if data and data.Highlight then data.Highlight.Enabled = false end
        if data and data.Billboard then data.Billboard.Enabled = false end
        return
    end

    local role = getRole(player)
    local color = role == "Murderer" and Color3.new(1, 0, 0) or
                  role == "Sheriff" and Color3.new(0, 0, 1) or
                  Color3.new(0, 1, 0)
    data.Highlight.FillColor = color
    data.Highlight.OutlineColor = color
    data.Highlight.Enabled = true
    data.Billboard.Enabled = true
end

local function refreshESP()
    for player, _ in pairs(espData) do
        if player and player.Parent then
            updateESPVisual(player)
        end
    end
end

Window:AddToggle(secESP, "Enable ESP", "Show name + distance + highlight", false, function(v)
    espEnabled = v
    refreshESP()
end)

local secFOV = Window:AddCollapsible(TabVisual, "FOV Circle", true)

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "W424_FOV"
fovGui.Parent = CoreGui
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true

local fovCircle = Instance.new("Frame")
fovCircle.BackgroundTransparency = 1
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, 300, 0, 300)
fovCircle.Visible = false
fovCircle.Parent = fovGui
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.5
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)

Window:AddToggle(secFOV, "Show FOV Circle", "Show FOV circle", false, function(v)
    fovCircle.Visible = v
end)

Window:AddSlider(secFOV, "FOV Radius", "30-400", 30, 400, 150, function(v)
    fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

-- ============================================
-- ESP IMPLEMENTATION
-- ============================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP_Holder"
ESPFolder.Parent = CoreGui

local function createESP(player)
    if player == LocalPlayer then return end
    if espData[player] then
        if espData[player].Highlight then espData[player].Highlight:Destroy() end
        if espData[player].Billboard then espData[player].Billboard:Destroy() end
        espData[player] = nil
    end

    local char = player.Character
    if not char then return end

    local highlight = Instance.new("Highlight")
    highlight.Parent = char
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0.2
    highlight.Enabled = false

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.ExtentsOffset = Vector3.new(0, 2.5, 0)
    billboard.Enabled = false
    local head = char:FindFirstChild("Head")
    billboard.Parent = head or char
    if head then billboard.Adornee = head end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 12
    distanceLabel.Parent = billboard

    espData[player] = {
        Highlight = highlight,
        Billboard = billboard
    }

    updateESPVisual(player)
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then
        createESP(player)
    end
    player.CharacterAdded:Connect(function()
        createESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    local data = espData[player]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
        espData[player] = nil
    end
end)

task.spawn(function()
    local lastRoles = {}
    while true do
        for player, data in pairs(espData) do
            if player and player.Parent then
                local newRole = getRole(player)
                if lastRoles[player] ~= newRole then
                    lastRoles[player] = newRole
                    updateESPVisual(player)
                end
            end
        end
        task.wait(0.5)
    end
end)

RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position

    for player, data in pairs(espData) do
        if player and player.Parent and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head and myPos and data.Billboard then
                local dist = (head.Position - myPos).Magnitude
                local distLabel = data.Billboard:FindFirstChildWhichIsA("TextLabel")
                if distLabel and distLabel.Text and distLabel.Text:match("m$") then
                    distLabel.Text = string.format("%.0fm", dist)
                end
            end
        end
    end
end)

-- ============================================
-- FUNGSI TARGET FILTER UNTUK SHERIFF
-- ============================================
local function isSheriffTargetAllowed(player)
    local role = getRole(player)
    if sheriffTargetMode == "Murderer Only" and role == "Murderer" then return true end
    if sheriffTargetMode == "Innocent Only" and role == "Innocent" then return true end
    if sheriffTargetMode == "All Players" then return true end
    return false
end

local function getSheriffTargets()
    local targets = {}
    local myChar = LocalPlayer.Character
    if not myChar then return targets end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return targets end
    local myPos = myRoot.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and isSheriffTargetAllowed(player) then
                    local part = char:FindFirstChild(sheriffTargetPart) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                    if part then
                        local targetPos = part.Position
                        if sheriffPrediction then
                            local vel = part.AssemblyLinearVelocity or Vector3.new()
                            targetPos = targetPos + (vel * sheriffPredFactor)
                        end
                        local dist = (targetPos - myPos).Magnitude
                        if dist <= sheriffDistance then
                            if not sheriffWall or hasClearLOS(myPos, targetPos, myChar, char) then
                                table.insert(targets, {
                                    Player = player,
                                    Part = part,
                                    Position = targetPos,
                                    Distance = dist
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

-- ============================================
-- FUNGSI TARGET FILTER UNTUK MURDERER
-- ============================================
local function isMurdererTargetAllowed(player)
    local role = getRole(player)
    if murdererThrowTarget == "Sheriff Only" and role == "Sheriff" then return true end
    if murdererThrowTarget == "Innocent Only" and role == "Innocent" then return true end
    if murdererThrowTarget == "All Players" then return true end
    return false
end

local function getMurdererTargets()
    local targets = {}
    local char = LocalPlayer.Character
    if not char then return targets end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return targets end
    local myPos = myRoot.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            if pChar and isMurdererTargetAllowed(player) then
                local hum = pChar:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local part = pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Head")
                    if part then
                        local targetPos = part.Position
                        if murdererThrowPred then
                            local vel = part.AssemblyLinearVelocity or Vector3.new()
                            targetPos = targetPos + (vel * murdererThrowPredFactor)
                        end
                        local dist = (targetPos - myPos).Magnitude
                        if dist <= murdererThrowDist then
                            if not murdererThrowWall or hasClearLOS(myPos, targetPos, char, pChar) then
                                table.insert(targets, { Character = pChar, Position = targetPos, Distance = dist })
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

-- ============================================
-- AIMBOT SHERIFF LOOP + AUTO SHOOT
-- ============================================
local function isShooting()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or
           UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)
end

RunService.RenderStepped:Connect(function(dt)
    if not sheriffAimbot then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end

    local hasGun = false
    local gunTool = nil
    for _, tool in ipairs(myChar:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("gun") or name:find("revolver") or name:find("pistol") or name:find("sheriff") then
                hasGun = true
                gunTool = tool
                break
            end
        end
    end
    if not hasGun then return end

    local canAim = (sheriffTrigger == "Always") or (sheriffTrigger == "On Shoot" and isShooting())
    if not canAim then return end

    local targets = getSheriffTargets()
    if #targets == 0 then return end

    local target = targets[1]
    local targetPos = target.Position
    local currentCF = Camera.CFrame
    local targetCF = CFrame.new(currentCF.Position, targetPos)

    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if onScreen then
        local center = Camera.ViewportSize / 2
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist > sheriffFOV then return end
    else
        return
    end

    if sheriffSmooth < 1 then
        local lerpFactor = 1 - math.exp(-sheriffSmooth * dt * 5)
        Camera.CFrame = currentCF:Lerp(targetCF, lerpFactor)
    else
        Camera.CFrame = targetCF
    end

    if sheriffAutoShoot and target then
        local center = Camera.ViewportSize / 2
        local pos, on = Camera:WorldToViewportPoint(target.Position)
        if on then
            local crosshairDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if crosshairDist < 30 and (getT() - lastAutoShootTime) > sheriffAutoDelay then
                lastAutoShootTime = getT()
                pcall(function()
                    local origin = CharacterRayOrigin(myChar)
                    if origin and target.Part then
                        local hitPart = target.Part
                        local targetPos2 = hitPart.Position

                        local shootRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ShootGun")
                        if shootRemote then
                            shootRemote:FireServer(origin, targetPos2, hitPart, targetPos2)
                        else
                            local remote = ReplicatedStorage:FindFirstChild("ShootGun")
                            if remote then
                                remote:FireServer(origin, targetPos2, hitPart, targetPos2)
                            end
                        end

                        if gunTool and gunTool:FindFirstChild("Fire") then
                            gunTool.Fire:Play()
                        end
                    end
                end)
            end
        end
    end
end)

-- ============================================
-- MURDERER AUTO THROW + AUTO MELEE LOOP
-- ============================================
local function equipKnife()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return false end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("knife") or tool.Name:lower():find("blade")) then
            hum:EquipTool(tool)
            return true
        end
    end
    return false
end

local function throwKnifeAt(targetChar, targetPos)
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or not (tool.Name:lower():find("knife") or tool.Name:lower():find("blade")) then return end
    local rightHandle = tool:FindFirstChild("RightHandle")
    if not rightHandle then return end

    local origin = CharacterRayOrigin(char)
    if not origin then return end

    local direction = (targetPos - origin).Unit
    local throwRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ThrowStart")
    if throwRemote then
        throwRemote:FireServer(origin, direction)
    else
        local remote = ReplicatedStorage:FindFirstChild("ThrowStart")
        if remote then remote:FireServer(origin, direction) end
    end

    local knifeModule = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("KnifeProjectileController")
    if knifeModule then
        pcall(function()
            require(knifeModule)({
                Speed = tool:GetAttribute("ThrowSpeed") or 50,
                KnifeProjectile = rightHandle:Clone(),
                Direction = direction,
                Origin = origin
            }, function(raycastResult)
                local hitRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ThrowHit")
                if hitRemote then
                    hitRemote:FireServer(raycastResult and raycastResult.Instance, raycastResult and raycastResult.Position)
                else
                    local remote = ReplicatedStorage:FindFirstChild("ThrowHit")
                    if remote then remote:FireServer(raycastResult and raycastResult.Instance, raycastResult and raycastResult.Position) end
                end
            end)
        end)
    else
        local hitRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ThrowHit")
        if hitRemote then
            hitRemote:FireServer(nil, targetPos)
        else
            local remote = ReplicatedStorage:FindFirstChild("ThrowHit")
            if remote then remote:FireServer(nil, targetPos) end
        end
    end
    lastThrowTime = getT()
end

local function doMeleeAttack()
    local char = LocalPlayer.Character
    if not char then return end
    local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Melee")
    if remote then
        remote:FireServer()
    else
        local general = ReplicatedStorage:FindFirstChild("Melee") or ReplicatedStorage:FindFirstChild("Attack")
        if general then general:FireServer() end
    end
end

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char and isMurderer(LocalPlayer) then
            if murdererAutoEquip then
                local hasKnife = false
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") and (tool.Name:lower():find("knife") or tool.Name:lower():find("blade")) then
                        hasKnife = true
                        break
                    end
                end
                if not hasKnife then
                    equipKnife()
                    task.wait(0.2)
                end
            end

            if murdererMelee then
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local myPos = myRoot.Position
                    local closest = nil
                    local closestDist = murdererMeleeRadius
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and isMurdererTargetAllowed(player) then
                            local pChar = player.Character
                            if pChar then
                                local hum = pChar:FindFirstChildOfClass("Humanoid")
                                if hum and hum.Health > 0 then
                                    local targetRoot = pChar:FindFirstChild("HumanoidRootPart")
                                    if targetRoot then
                                        local dist = (targetRoot.Position - myPos).Magnitude
                                        if dist < closestDist and hasClearLOS(myPos, targetRoot.Position, char, pChar) then
                                            closestDist = dist
                                            closest = pChar
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if closest then
                        doMeleeAttack()
                        task.wait(0.3)
                    end
                end
            end

            if murdererThrow and (getT() - lastThrowTime) >= murdererThrowCD then
                local targets = getMurdererTargets()
                if #targets > 0 then
                    local target = targets[1]
                    throwKnifeAt(target.Character, target.Position)
                end
            end
        end

        task.wait(0.1)
    end
end)

-- ============================================
-- TAB INNOCENT
-- ============================================
local secInnocent = Window:AddCollapsible(TabInnocent, "Innocent Tools", true)

-- State
local noclipEnabled   = false
local invisEnabled    = false
local gunDropEnabled  = false
local noclipConn      = nil
local invisConn       = nil

-- Noclip
local function enableNoclip(v)
    noclipEnabled = v
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        -- restore collision
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Invisible (hide character locally)
local function enableInvis(v)
    invisEnabled = v
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            pcall(function()
                part.LocalTransparencyModifier = v and 1 or 0
            end)
        end
    end
    -- Hook CharacterAdded untuk apply setiap respawn
    if v and not invisConn then
        invisConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            task.wait(0.5)
            if invisEnabled then
                for _, part in ipairs(newChar:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        pcall(function() part.LocalTransparencyModifier = 1 end)
                    end
                end
            end
        end)
    elseif not v and invisConn then
        invisConn:Disconnect(); invisConn = nil
    end
end

local function startGunDropDetect()
    task.spawn(function()
        local notified = {}
        while gunDropEnabled do
            task.wait(0.5)
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and not notified[obj] then
                    local name = obj.Name:lower()
                    if name:find("gun") or name:find("pistol") or name:find("revolver") or name:find("sheriff") then
                        notified[obj] = true
                        Window:Notify({Title="Gun Dropped!", Description=obj.Name, Color=Color3.fromRGB(255,200,0), Duration=3})
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            pcall(function() obj:SetPrimaryPartCFrame(CFrame.new(hrp.Position + Vector3.new(0,2,0))) end)
                        end
                    end
                end
            end
        end
    end)
end

Window:AddToggle(secInnocent, "Noclip", "Walk through walls", false, function(v)
    enableNoclip(v)
    Window:Notify({Title="Noclip", Description=v and "ON" or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

Window:AddToggle(secInnocent, "Invisible", "Hide character (local only)", false, function(v)
    enableInvis(v)
    Window:Notify({Title="Invisible", Description=v and "ON" or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

local secGunDrop = Window:AddCollapsible(TabInnocent, "Gun Drop Detector", true)

Window:AddToggle(secGunDrop, "Gun Drop Detect", "Auto detect & pickup sheriff gun", false, function(v)
    gunDropEnabled = v
    if v then startGunDropDetect() end
    Window:Notify({Title="Gun Drop Detect", Description=v and "ON" or "OFF", Color=v and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), Duration=2})
end)

Window:AddButton(secGunDrop, "Grab Nearest Gun", "Grab dropped gun near you", nil, function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local closest, closestDist = nil, 50
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Tool") then
            local name = obj.Name:lower()
            if name:find("gun") or name:find("pistol") or name:find("revolver") or name:find("sheriff") then
                local pp = obj:GetPivot().Position
                local dist = (pp - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end
    if closest then
        pcall(function() closest:SetPrimaryPartCFrame(CFrame.new(hrp.Position + Vector3.new(0,2,0))) end)
        Window:Notify({Title="Grabbed!", Description=closest.Name, Color=Color3.fromRGB(0,200,255), Duration=2})
    else
        Window:Notify({Title="No gun found", Description="None within 50 studs", Color=Color3.fromRGB(255,0,0), Duration=2})
    end
end)

-- ============================================
-- TAB SKINS
-- ============================================
local secSkins = Window:AddCollapsible(TabSkins, "Unlock & Apply Skins", true)

-- Variabel skin
local SkinData      = nil
local selectedKnife = "Default"
local selectedGun   = "Default"
local autoApplySkin = false

-- Fungsi load data
local function loadSkinData()
    if SkinData then return SkinData end

    if isfile and isfile("mm2data.lua") then
        local success, result = pcall(loadfile, "mm2data.lua")
        if success and result then
            SkinData = result()
            if SkinData then return SkinData end
        end
    end

    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/mm2meshes.lua")
    end)

    if success and result then
        local func = loadstring(result)
        if func then
            SkinData = func()
            if writefile then
                pcall(function() writefile("mm2data.lua", result) end)
            end
            return SkinData
        end
    end

    return nil
end

local function findMeshAndTexture(node)
    if not node or type(node) ~= "table" then return nil end
    local props = node.Props
    if props then
        local meshId = props.MeshId or props.MeshID
        if meshId and meshId ~= "" then
            return {
                meshid = meshId,
                textureid = props.TextureId or props.TextureID or "",
                scale = props.Scale or Vector3.new(0.045,0.045,0.045),
                size = props.Size or Vector3.new(0.045,0.045,0.045)
            }
        end
    end
    if node.Display and type(node.Display) == "table" then
        for _, child in ipairs(node.Display) do
            local res = findMeshAndTexture(child)
            if res then return res end
        end
    end
    return nil
end

local function getWeaponData(name)
    if not SkinData then return nil end
    local weapon = SkinData[name]
    if not weapon then return nil end
    return findMeshAndTexture(weapon)
end

local function applyWeaponMesh(refPart, weaponData, weaponName, weapontype)
    if not weaponData or not weaponData.meshid then return end

    local tool = refPart:FindFirstAncestorOfClass("Tool")
    if tool then
        if weapontype == "Gun" then
            if weaponData.meshid:find("79401392") then
                tool.Grip = CFrame.fromMatrix(
                    Vector3.new(0, -0.699999988, -0.300000012),
                    Vector3.new(1, 0, 0), 
                    Vector3.new(0, 0, 1), 
                    Vector3.new(0, -1, 0)
                )
            elseif weaponData.meshid:find("6600918074") then
                tool.Grip = CFrame.new(1, -0.359999988, 0.00000012, 0, 0, 1, 0, 1, 0, -1, 0, 0)
            else
                tool.Grip = CFrame.fromMatrix(
                    Vector3.new(0, -0.5, 0.7),
                    Vector3.new(1, 0, 0),
                    Vector3.new(0, 1, 0),
                    Vector3.new(0, 0, 1)
                )
            end
        end
    end

    if refPart:IsA("MeshPart") then
        local specialMesh = refPart:FindFirstChildOfClass("SpecialMesh")
        if specialMesh then specialMesh:Destroy() end
        refPart.Size = weaponData.size
        refPart.MeshId = weaponData.meshid
        refPart.TextureID = weaponData.textureid
    else
        local mesh = refPart:FindFirstChildOfClass("SpecialMesh")
        if not mesh then
            mesh = Instance.new("SpecialMesh")
            mesh.Name = "Mesh"
            mesh.Parent = refPart
        end
        refPart.Size = weaponData.size
        mesh.MeshId = weaponData.meshid
        mesh.TextureId = weaponData.textureid
        mesh.Scale = weaponData.scale
    end
end

local function unlockAllSkins()
    if not SkinData then
        Window:Notify({Title="Error", Description="Data skin belum dimuat!", Color=Color3.new(1,0,0), Delay=3})
        return
    end

    local success = pcall(function()
        local InventoryModule = require(game.ReplicatedStorage.Modules.InventoryModule)
        local ProfileData = require(game.ReplicatedStorage.Modules.ProfileData)
        local Sync = require(game.ReplicatedStorage.Database.Sync)

        for name, itemData in pairs(Sync.Weapons) do
            itemData.SortWithinGroup = itemData.SortWithinGroup or 0
            itemData.SortGroup = itemData.SortGroup or nil
            itemData.Name = itemData.Name or itemData.ItemName or name
            itemData.Rarity = itemData.Rarity or "Common"

            if Sync.Rarities[itemData.Rarity] then
                local weaponMeshInfo = getWeaponData(name)
                if weaponMeshInfo and weaponMeshInfo.meshid then
                    ProfileData.Weapons.Owned[name] = 1
                end
            end
        end

        local UpdateInventory = nil
        for _, func in pairs(getgc()) do
            if typeof(func) == "function" and islclosure(func) and debug.info(func, "l") == 122 and #debug.getupvalues(func) == 2 then
                UpdateInventory = func
                break
            end
        end
        if UpdateInventory then
            UpdateInventory(debug.getupvalue(UpdateInventory, 2), InventoryModule.MyInventory)
        end
    end)

    if success then
        Window:Notify({Title="Skins", Description="All skins unlocked!", Color=Color3.new(0,1,0), Delay=3})
    else
        Window:Notify({Title="Error", Description="Unlock failed!", Color=Color3.new(1,0,0), Delay=3})
    end
end

-- Buat tombol unlock pakai AddToggle (sebagai trigger)
Window:AddToggle(TabSkins, "Unlock All Skins", "Klik sekali untuk unlock semua skin (toggle)", false, function(v)
    if v then
        unlockAllSkins()
        -- Matikan toggle agar bisa diklik lagi
        -- Tapi karena tidak ada referensi, kita biarkan saja
        Window:Notify({Title="Info", Description="Unlock diproses", Color=Color3.new(1,1,0), Delay=2})
    end
end)

-- Variabel untuk dropdown (akan dibuat setelah data dimuat)
local knifeDropdown = nil
local gunDropdown = nil
local dropdownCreated = false

-- Fungsi membuat dropdown setelah data siap
local function createSkinDropdowns()
    if dropdownCreated then return end
    if not SkinData then return end

    local skinList = {}
    for name, _ in pairs(SkinData) do
        table.insert(skinList, name)
    end
    table.sort(skinList)
    table.insert(skinList, 1, "Default") -- tambahkan opsi default di awal

    -- Buat dropdown untuk knife
    knifeDropdown = Window:AddDropdown(TabSkins, "Knife Skin", "Pilih skin untuk pisau", skinList, false, "Default", function(v)
        selectedKnife = v
        Window:Notify({Title="Knife", Description="Selected: "..v, Color=Color3.new(0,1,1), Delay=2})
    end)

    -- Buat dropdown untuk gun
    gunDropdown = Window:AddDropdown(TabSkins, "Gun Skin", "Pilih skin untuk senjata", skinList, false, "Default", function(v)
        selectedGun = v
        Window:Notify({Title="Gun", Description="Selected: "..v, Color=Color3.new(0,1,1), Delay=2})
    end)

    dropdownCreated = true
end

-- Auto Apply toggle
Window:AddToggle(TabSkins, "Auto Apply Skin", "Terapkan skin ke senjata yang dipegang", false, function(v)
    autoApplySkin = v
end)

-- Load data skin di background
task.spawn(function()
    local data = loadSkinData()
    if data then
        SkinData = data
        createSkinDropdowns()
        Window:Notify({
            Title = "Skins",
            Description = "Data skin loaded!",
            Content = "Available: " .. #SkinData .. " skins",
            Color = Color3.fromRGB(0, 200, 200),
            Delay = 3
        })
    else
        Window:Notify({
            Title = "Error",
            Description = "Gagal memuat data skin!",
            Content = "Periksa koneksi internet",
            Color = Color3.fromRGB(255, 0, 0),
            Delay = 3
        })
    end
end)

-- ============================================
-- LOOP AUTO APPLY SKIN
-- ============================================
task.spawn(function()
    while true do
        if autoApplySkin and SkinData then
            local char = LocalPlayer.Character
            if char then
                -- Ambil nama skin yang dipilih
                local knifeName = (selectedKnife ~= "Default") and selectedKnife or nil
                local gunName = (selectedGun ~= "Default") and selectedGun or nil

                -- Terapkan ke tool
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        local itemType = tool:GetAttribute("ItemType")
                        local Handle = tool:FindFirstChild("Handle")
                        if Handle then
                            if itemType == "Knife" and knifeName then
                                local data = getWeaponData(knifeName)
                                if data then applyWeaponMesh(Handle, data, knifeName, "Knife") end
                            elseif itemType == "Gun" and gunName then
                                local data = getWeaponData(gunName)
                                if data then applyWeaponMesh(Handle, data, gunName, "Gun") end
                            end
                        end
                    end
                end

                -- DisplayRef
                local refGun = char:FindFirstChild("DisplayRefGun")
                if refGun and refGun.Value and gunName then
                    local data = getWeaponData(gunName)
                    if data then applyWeaponMesh(refGun.Value, data, gunName) end
                end

                local refKnife = char:FindFirstChild("DisplayRefKnife")
                if refKnife and refKnife.Value and knifeName then
                    local data = getWeaponData(knifeName)
                    if data then applyWeaponMesh(refKnife.Value, data, knifeName) end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ============================================
-- HANDLER STUCK KNIFE
-- ============================================
Workspace.ChildAdded:Connect(function(ch)
    if ch and ch:IsA("BasePart") and ch.Name == "StuckKnife" then
        task.wait(0.1)
        local mesh = ch:FindFirstChild("Mesh")
        if mesh and SkinData then
            local knifeName = (selectedKnife ~= "Default") and selectedKnife or nil
            if knifeName then
                local data = getWeaponData(knifeName)
                if data and data.meshid then
                    mesh.MeshId = data.meshid
                    mesh.TextureId = data.textureid
                    mesh.Scale = data.scale
                end
            end
        end
    end
end)

-- ============================================
-- SELESAI
-- ============================================
print("✅ W424HUB loaded")
Window:Notify({
    Title = "Ready!",
    Description = "All features loaded",
    Content = "Enjoy!",
    Color = Color3.fromRGB(0, 255, 0),
    Delay = 3
})