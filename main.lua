-- ==========================================
-- WIKJOK: AUTO PABRIK (STANDALONE FIXED)
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 1. UI SETUP (DIPRIORITASKAN AGAR INSTANT MUNCUL)
-- ==========================================
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("WIKJOK_UI")
if oldGui then oldGui:Destroy() end

local WIKJOK_UI = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
WIKJOK_UI.Name = "WIKJOK_UI"
WIKJOK_UI.ResetOnSpawn = false
WIKJOK_UI.IgnoreGuiInset = true 
WIKJOK_UI.DisplayOrder = 2147483647 
WIKJOK_UI.ZIndexBehavior = Enum.ZIndexBehavior.Global

local Theme = {
    BG = Color3.fromRGB(13, 13, 17), Surface = Color3.fromRGB(22, 22, 28),
    Accent = Color3.fromRGB(245, 158, 11), Text = Color3.fromRGB(250, 250, 255),
    Border = Color3.fromRGB(45, 45, 55)
}

local MainFrame = Instance.new("Frame", WIKJOK_UI)
MainFrame.Size = UDim2.new(0, 360, 0, 520); MainFrame.Position = UDim2.new(0.5, -180, 0.5, -260)
MainFrame.BackgroundColor3 = Theme.BG; MainFrame.BorderSizePixel = 0
MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Theme.Border

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1
Title.Text = "⚙️ WIKJOK: AUTO PABRIK"; Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16; Title.TextColor3 = Theme.Accent
Instance.new("UIStroke", Title).Transparency = 0.8

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 40); CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Theme.Text
CloseBtn.MouseButton1Click:Connect(function() WIKJOK_UI:Destroy() end)

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -20, 1, -50); ScrollFrame.Position = UDim2.new(0, 10, 0, 40)
ScrollFrame.BackgroundTransparency = 1; ScrollFrame.ScrollBarThickness = 4
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)

local Layout = Instance.new("UIListLayout", ScrollFrame)
Layout.SortOrder = Enum.SortOrder.LayoutOrder; Layout.Padding = UDim.new(0, 8)

local function CreateSectionLabel(text)
    local lbl = Instance.new("TextLabel", ScrollFrame)
    lbl.Size = UDim2.new(1, 0, 0, 25); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
    lbl.TextColor3 = Theme.Accent; lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local function CreateInput(labelText, placeholderName)
    local container = Instance.new("Frame", ScrollFrame)
    container.Size = UDim2.new(1, 0, 0, 35); container.BackgroundColor3 = Theme.Surface
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5, 0, 1, 0); label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1; label.Text = labelText
    label.Font = Enum.Font.GothamMedium; label.TextSize = 12
    label.TextColor3 = Theme.Text; label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(0.45, 0, 0.7, 0); box.Position = UDim2.new(0.5, 0, 0.15, 0)
    box.BackgroundColor3 = Theme.BG; box.Text = ""; box.PlaceholderText = placeholderName
    box.Font = Enum.Font.GothamBold; box.TextSize = 12; box.TextColor3 = Theme.Accent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", box).Color = Theme.Border
    return box
end

local function CreateSaplingDropdown(labelText)
    local container = Instance.new("Frame", ScrollFrame)
    container.Size = UDim2.new(1, 0, 0, 35); container.BackgroundColor3 = Theme.Surface
    container.ClipsDescendants = true; Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5, 0, 0, 35); label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1; label.Text = labelText
    label.Font = Enum.Font.GothamMedium; label.TextSize = 12
    label.TextColor3 = Theme.Text; label.TextXAlignment = Enum.TextXAlignment.Left

    local mainBtn = Instance.new("TextButton", container)
    mainBtn.Size = UDim2.new(0.45, 0, 0, 25); mainBtn.Position = UDim2.new(0.5, 0, 0, 5)
    mainBtn.BackgroundColor3 = Theme.BG; mainBtn.Text = "▶ dirt_sapling"
    mainBtn.Font = Enum.Font.GothamBold; mainBtn.TextSize = 11; mainBtn.TextColor3 = Theme.Accent
    mainBtn.TextTruncate = Enum.TextTruncate.AtEnd
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", mainBtn).Color = Theme.Border

    local listFrame = Instance.new("ScrollingFrame", container)
    listFrame.Size = UDim2.new(1, 0, 0, 100); listFrame.Position = UDim2.new(0, 0, 0, 35)
    listFrame.BackgroundTransparency = 1; listFrame.ScrollBarThickness = 2
    local listLayout = Instance.new("UIListLayout", listFrame)

    local isOpen = false
    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            container.Size = UDim2.new(1, 0, 0, 135)
            for _, child in ipairs(listFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            
            local saplingOptions = {"dirt_sapling", "wood_sapling", "stone_sapling"}
            
            -- Scan Inventory (Menggunakan referensi yang sudah diambil di Background)
            pcall(function()
                local tempInv = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory"))
                local tempItems = require(ReplicatedStorage:WaitForChild("Managers"):WaitForChild("ItemsManager"))
                if tempInv and tempInv.Stacks then
                    local foundInInv = {}
                    for i = 1, (tempInv.MaxSlots or 100) do
                        local stack = tempInv.Stacks[i]
                        if stack and stack.Id and stack.Amount and stack.Amount > 0 then
                            local idStr = string.lower(tostring(stack.Id))
                            local itemName = idStr
                            if tempItems and tempItems.ItemsData[stack.Id] then
                                itemName = string.lower(tostring(tempItems.ItemsData[stack.Id].Name or idStr))
                            end
                            if string.find(idStr, "sapling") or string.find(itemName, "sapling") then
                                if not foundInInv[itemName] then
                                    foundInInv[itemName] = true
                                    table.insert(saplingOptions, 1, itemName)
                                end
                            end
                        end
                    end
                end
            end)

            local uniqueOptions = {}; local addedCount = 0
            for _, optName in ipairs(saplingOptions) do
                if not uniqueOptions[optName] then
                    uniqueOptions[optName] = true; addedCount = addedCount + 1
                    local optBtn = Instance.new("TextButton", listFrame)
                    optBtn.Size = UDim2.new(1, 0, 0, 25); optBtn.BackgroundColor3 = Theme.Surface
                    optBtn.Text = "  " .. optName; optBtn.Font = Enum.Font.GothamMedium
                    optBtn.TextSize = 11; optBtn.TextColor3 = Theme.Text
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left; optBtn.BorderSizePixel = 0
                    optBtn.MouseButton1Click:Connect(function()
                        mainBtn.Text = "▶ " .. optName; isOpen = false
                        container.Size = UDim2.new(1, 0, 0, 35)
                    end)
                end
            end
            listFrame.CanvasSize = UDim2.new(0, 0, 0, addedCount * 25)
        else
            container.Size = UDim2.new(1, 0, 0, 35)
        end
    end)
    return mainBtn
end

-- MERAKIT ELEMEN INPUT
CreateSectionLabel("1️⃣ Titik Awal & Area Block")
local inputStandPos = CreateInput("Player Stand Pos", "Cth: 10,5")
local inputBlockPos = CreateInput("Block Farm Pos", "Cth: 11,5")

CreateSectionLabel("2️⃣ Pemilihan Item Block")
local inputBlockType = CreateInput("Item to Farm", "Cth: dirt")

CreateSectionLabel("3️⃣ Area Sapling (Plant & Break)")
local inputSaplingStart = CreateInput("Awal Tanam [X,Y]", "Cth: 45,37")
local inputSaplingEnd = CreateInput("Akhir Tanam [X,Y]", "Cth: 55,37")
local inputSaplingLimit = CreateInput("Baris Akhir [Y]", "Cth: 29")
local dropdownSaplingType = CreateSaplingDropdown("Pilih Sapling")

CreateSectionLabel("4️⃣ Pengaturan Kecepatan")
local inputWalkSpeed = CreateInput("Walk Speed", "Default: 45")
local inputBreakSpeed = CreateInput("Break Speed (ms)", "Default: 250")

local ToggleBtn = Instance.new("TextButton", ScrollFrame)
ToggleBtn.Size = UDim2.new(1, 0, 0, 45); ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtn.Text = "▶ START AUTO PABRIK"; ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 14; ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", ToggleBtn).Color = Theme.Border

-- ==========================================
-- 2. FETCH ENVIRONMENT (BACKGROUND LOADING)
-- ==========================================
local MovementState, WorldManager, InventoryModule, ItemsManager
local Remotes, PlayerPlaceRemote, PlayerFistRemote

task.spawn(function() pcall(function() MovementState = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerMovement")) end) end)
task.spawn(function() pcall(function() WorldManager = require(ReplicatedStorage:WaitForChild("Managers"):WaitForChild("WorldManager")) end) end)
task.spawn(function() pcall(function() InventoryModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory")) end) end)
task.spawn(function() pcall(function() ItemsManager = require(ReplicatedStorage:WaitForChild("Managers"):WaitForChild("ItemsManager")) end) end)

task.spawn(function()
    pcall(function()
        Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        if Remotes then
            PlayerFistRemote = Remotes:WaitForChild("PlayerFist", 5)
            PlayerPlaceRemote = Remotes:WaitForChild("PlayerPlaceItem", 5)
        end
    end)
end)

local TILE_SIZE = 4.5

-- ==========================================
-- 3. ENGINE HELPER FUNCTIONS
-- ==========================================
local isRunning = false

local function ParsePos(text)
    local x, y = string.match(text, "([%d%-]+)%s*,%s*([%d%-]+)")
    return (tonumber(x) or 0), (tonumber(y) or 0)
end

local function GetItemSlotAndCount(targetName, expectedType)
    local count = 0; local targetSlot = nil
    targetName = string.lower(targetName)
    
    if InventoryModule and InventoryModule.Stacks then
        for i = 1, (InventoryModule.MaxSlots or 100) do
            local stack = InventoryModule.Stacks[i]
            if stack and stack.Id and stack.Amount and stack.Amount > 0 then
                local idStr = string.lower(tostring(stack.Id))
                local nameStr = idStr
                if ItemsManager and ItemsManager.ItemsData[stack.Id] then
                    nameStr = string.lower(tostring(ItemsManager.ItemsData[stack.Id].Name or idStr))
                end
                
                local isMatch = false
                if expectedType == "block" then
                    if (string.find(idStr, targetName) or string.find(nameStr, targetName)) 
                       and not string.find(idStr, "_sapling") 
                       and not string.find(idStr, "_background") then
                        isMatch = true
                    end
                elseif expectedType == "sapling" then
                    if (string.find(idStr, targetName) or string.find(nameStr, targetName)) 
                       and string.find(idStr, "_sapling") then
                        isMatch = true
                    end
                end
                
                if isMatch then
                    count = count + stack.Amount
                    if not targetSlot then targetSlot = i end
                end
            end
        end
    end
    return count, targetSlot
end

local function MoveToGrid(gx, gy)
    if MovementState then
        local targetVec = Vector3.new(gx, gy, 0) * TILE_SIZE
        MovementState.Position = targetVec
        MovementState.VelocityX, MovementState.VelocityY = 0, 0
    end
end

local function HasBlock(gx, gy)
    if WorldManager and WorldManager.GetTile then
        for l = 1, 5 do if WorldManager.GetTile(gx, gy, l) then return true end end
    end
    return false
end

local function IsSaplingGrown(gx, gy, plantTime)
    return (os.time() - plantTime) >= 60 
end

local function StandaloneAutoLoot(radiusPos)
    local dropsFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("DroppedItems") or workspace:FindFirstChild("Items")
    if dropsFolder and MovementState then
        for _, item in ipairs(dropsFolder:GetChildren()) do
            local part = item:IsA("BasePart") and item or (item:IsA("Model") and item.PrimaryPart)
            if part then
                local dist = (Vector2.new(part.Position.X, part.Position.Y) - Vector2.new(radiusPos.X, radiusPos.Y)).Magnitude
                if dist < (20 * TILE_SIZE) then
                    MovementState.Position = part.Position
                    task.wait(0.05)
                end
            end
        end
    end
end

-- ==========================================
-- 4. WIKJOK CORE RUNTIME LOOP
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "🛑 STOP AUTO PABRIK"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
        
        local blockType = string.lower(inputBlockType.Text)
        local saplingType = string.lower(string.gsub(dropdownSaplingType.Text, "▶ ", ""))
        local standX, standY = ParsePos(inputStandPos.Text)
        local farmX, farmY = ParsePos(inputBlockPos.Text)
        
        local sStartX, sStartY = ParsePos(inputSaplingStart.Text)
        local sEndX, sEndY = ParsePos(inputSaplingEnd.Text)
        local sLimitY = tonumber(inputSaplingLimit.Text) or sStartY
        
        local breakDelay = (tonumber(inputBreakSpeed.Text) or 250) / 1000
        
        print("[WIKJOK] Engine Started! Mode: Pabrik Siklus Penuh")
        
        task.spawn(function()
            local hrp = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart)
            if hrp then hrp.Anchored = true end

            while isRunning do
                -- ==========================================
                -- FASE 1: SMART AUTO FARM BLOCK
                -- ==========================================
                print("[WIKJOK] Memulai Fase 1: Smart Auto Farm Block")
                MoveToGrid(standX, standY)
                task.wait(0.5)
                
                while isRunning do
                    local count, slot = GetItemSlotAndCount(blockType, "block")
                    if count <= 0 then break end
                    
                    if not HasBlock(farmX, farmY) and PlayerPlaceRemote then
                        PlayerPlaceRemote:FireServer(Vector2.new(farmX, farmY), slot)
                        task.wait(0.1)
                    end
                    
                    while HasBlock(farmX, farmY) and isRunning do
                        if PlayerFistRemote then PlayerFistRemote:FireServer(Vector2.new(farmX, farmY)) end
                        task.wait(breakDelay)
                    end
                    
                    StandaloneAutoLoot(Vector3.new(farmX * TILE_SIZE, farmY * TILE_SIZE, 0))
                    MoveToGrid(standX, standY)
                end
                
                if not isRunning then break end
                
                -- ==========================================
                -- FASE 2: SMART AUTO FARM SAPLING
                -- ==========================================
                print("[WIKJOK] Block Habis! Memulai Fase 2: Smart Auto Farm Sapling")
                local plantedSaplings = {}
                local isOutOfSapling = false
                
                local loopStepX = (sStartX <= sEndX) and 1 or -1
                local loopStepY = (sStartY >= sLimitY) and -2 or 2 
                
                -- [A] Tanam
                for y = sStartY, sLimitY, loopStepY do
                    if isOutOfSapling or not isRunning then break end
                    for x = sStartX, sEndX, loopStepX do
                        if not isRunning then break end
                        
                        local sCount, sSlot = GetItemSlotAndCount(saplingType, "sapling")
                        if sCount <= 0 then isOutOfSapling = true break end
                        
                        if not HasBlock(x, y) then
                            MoveToGrid(x, y)
                            task.wait(0.1)
                            if PlayerPlaceRemote then 
                                PlayerPlaceRemote:FireServer(Vector2.new(x, y), sSlot) 
                                table.insert(plantedSaplings, {X = x, Y = y, Time = os.time()})
                                task.wait(0.1)
                            end
                        end
                    end
                end
                
                if not isRunning then break end
                
                -- [B] Tunggu Matang
                if #plantedSaplings > 0 then
                    print("[WIKJOK] Menunggu Sapling Matang...")
                    local allGrown = false
                    while not allGrown and isRunning do
                        allGrown = true
                        for _, sapling in ipairs(plantedSaplings) do
                            if not IsSaplingGrown(sapling.X, sapling.Y, sapling.Time) then
                                allGrown = false
                                break
                            end
                        end
                        if not allGrown then task.wait(2) end
                    end
                end
                
                if not isRunning then break end
                
                -- [C] Panen Sapling
                print("[WIKJOK] Pohon Matang! Memulai Panen...")
                for _, sapling in ipairs(plantedSaplings) do
                    if not isRunning then break end
                    
                    MoveToGrid(sapling.X, sapling.Y)
                    task.wait(0.1)
                    
                    while HasBlock(sapling.X, sapling.Y) and isRunning do
                        if PlayerFistRemote then PlayerFistRemote:FireServer(Vector2.new(sapling.X, sapling.Y)) end
                        task.wait(breakDelay)
                    end
                    
                    StandaloneAutoLoot(Vector3.new(sapling.X * TILE_SIZE, sapling.Y * TILE_SIZE, 0))
                end
                
                print("[WIKJOK] Siklus Sapling Selesai! Mengulang kembali dari Fase 1.")
            end

            local finalHrp = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart)
            if finalHrp then finalHrp.Anchored = false end
        end)
    else
        ToggleBtn.Text = "▶ START AUTO PABRIK"
        ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        print("[WIKJOK] Engine Stopped!")
    end
end)
