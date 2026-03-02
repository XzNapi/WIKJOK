return function(Core)
    -- ==========================================
    -- WIKJOK: AUTO PABRIK (LOOT SYNC EDITION)
    -- ==========================================
    
    local page = Core.Pages.Pabrik
    if not page then return warn("[NLight] Halaman Pabrik tidak ditemukan di Core!") end

    -- UI SETUP: Titik Awal & Block
    local secArea = Core.UI.createSection(page, "1. Titik Awal & Area Block")
    Core.UI.createInputRow("Player Stand Pos [X,Y]", "10,5", secArea, 0.4, "pabrikStandPos")
    Core.UI.createInputRow("Block Farm Pos [X,Y]", "11,5", secArea, 0.4, "pabrikBlockPos")

    -- UI SETUP: Pemilihan Item
    local secBlock = Core.UI.createSection(page, "2. Pemilihan Item Block")
    Core.UI.createInputRow("Item to Farm (Block)", "dirt", secBlock, 0.4, "pabrikBlockType")

    -- UI SETUP: Area Sapling
    local secSapling = Core.UI.createSection(page, "3. Area Sapling (Plant & Break)")
    Core.UI.createInputRow("Awal Tanam [X,Y]", "45,37", secSapling, 0.4, "pabrikSapStart")
    Core.UI.createInputRow("Akhir Tanam [X,Y]", "55,37", secSapling, 0.4, "pabrikSapEnd")
    Core.UI.createInputRow("Baris Akhir [Y]", "29", secSapling, 0.4, "pabrikSapLimitY")
    
    Core.UI.createInventoryDropdown("Pilih Sapling", "pabrikSaplingType", secSapling, nil, function(itemName, itemId)
        local n = string.lower(itemName); local id = string.lower(itemId)
        return string.find(n, "sapling") or string.find(id, "sapling")
    end)

    -- UI SETUP: Pengaturan & Eksekusi
    local secControl = Core.UI.createSection(page, "4. Pengaturan & Eksekusi")
    Core.UI.createInputRow("Walk Speed", "45", secControl, 0.4, "pabrikWalkSpeed")
    Core.UI.createInputRow("Place Delay (ms)", "150", secControl, 0.4, "pabrikPlaceSpeed") -- [BARU]
    Core.UI.createInputRow("Break Speed (ms)", "250", secControl, 0.4, "pabrikBreakSpeed")
    
    -- ==========================================
    -- FUNGSI UTILITAS PABRIK
    -- ==========================================
    local function ParsePos(text)
        if not text then return 0, 0 end
        local x, y = string.match(text, "([%d%-]+)%s*,%s*([%d%-]+)")
        return (tonumber(x) or 0), (tonumber(y) or 0)
    end

    local function GetItemSlotAndCount(targetName, expectedType)
        local count, targetSlot = 0, nil
        targetName = string.lower(targetName)
        
        if Core.Managers.InventoryModule and Core.Managers.InventoryModule.Stacks then
            for i = 1, (Core.Managers.InventoryModule.MaxSlots or 100) do
                local stack = Core.Managers.InventoryModule.Stacks[i]
                if stack and stack.Id and stack.Amount and stack.Amount > 0 then
                    local idStr = string.lower(tostring(stack.Id))
                    local nameStr = idStr
                    if Core.Managers.ItemsManager and Core.Managers.ItemsManager.ItemsData[stack.Id] then
                        nameStr = string.lower(tostring(Core.Managers.ItemsManager.ItemsData[stack.Id].Name or idStr))
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

    local function HasBlock(gx, gy)
        if Core.Managers.WorldManager and Core.Managers.WorldManager.GetTile then
            for l = 1, 5 do if Core.Managers.WorldManager.GetTile(gx, gy, l) then return true end end
        end
        return false
    end

    local function IsSaplingGrown(gx, gy, plantTime, saplingId)
        local rarity = 1
        if Core.Managers.ItemsManager and Core.Managers.ItemsManager.ItemsData then
            local itemData = Core.Managers.ItemsManager.ItemsData[saplingId]
            if itemData and itemData.Rarity then
                rarity = itemData.Rarity
            end
        end

        local requiredGrowTime = (rarity * rarity * rarity) + (rarity * 30)
        local serverPlantedAt = plantTime

        if Core.Managers.WorldManager and Core.Managers.WorldManager.GetTile then
            local tileId, tileMeta = Core.Managers.WorldManager.GetTile(gx, gy, 1)
            if type(tileMeta) == "table" and tileMeta.at then
                serverPlantedAt = tileMeta.at
            end
        end

        local currentTime = workspace:GetServerTimeNow()
        return (currentTime - serverPlantedAt) >= requiredGrowTime
    end

    local function StopMovement()
        if Core.Managers.MovementState then
            Core.Managers.MovementState.VelocityX = 0
            Core.Managers.MovementState.VelocityY = 0
            Core.Managers.MovementState.MoveX = 0
            Core.Managers.MovementState.MoveY = 0
            Core.Managers.MovementState.OldPosition = Core.Managers.MovementState.Position
        end
    end

    local function SafeAutoLoot(radiusGridX, radiusGridY, moveSpeed, customRadius)
        local rad = customRadius or 15
        local dropsFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("DroppedItems") or workspace:FindFirstChild("Items")
        local itemsToLoot = {}
        
        if dropsFolder then
            for _, v in ipairs(dropsFolder:GetChildren()) do
                if (v:IsA("BasePart") or v:IsA("Model")) and not Core.Pathfinding.blacklistedItems[v] then 
                    table.insert(itemsToLoot, v) 
                end
            end
        else
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(Core.LocalPlayer.Character) and not Core.Players:GetPlayerFromCharacter(obj.Parent) and obj.Size.Y < 3 and not Core.Pathfinding.blacklistedItems[obj] then 
                    table.insert(itemsToLoot, obj) 
                end
            end
        end

        if #itemsToLoot > 0 then
            local validItems = {}
            for _, item in ipairs(itemsToLoot) do
                local part = item:IsA("BasePart") and item or (item:IsA("Model") and item.PrimaryPart)
                if part then
                    local ex = math.floor(part.Position.X / Core.Utils.TILE_SIZE + 0.5)
                    local ey = math.floor(part.Position.Y / Core.Utils.TILE_SIZE + 0.5)
                    local dist = math.sqrt((ex - radiusGridX)^2 + (ey - radiusGridY)^2)
                    
                    if dist <= rad then table.insert(validItems, {item = item, part = part, ex = ex, ey = ey, dist = dist}) end
                end
            end

            table.sort(validItems, function(a, b) return a.dist < b.dist end)

            for _, data in ipairs(validItems) do
                if not Core.Toggles.autoPabrik then break end
                
                if Core.Pathfinding.isOutOfBounds(data.ex, data.ey) or Core.Pathfinding.isItemTrapped(data.ex, data.ey) then
                    Core.Pathfinding.blacklistedItems[data.item] = true
                else
                    if Core.Pathfinding.aiMoveTo(data.ex, data.ey, moveSpeed, "autoPabrik") then 
                        StopMovement()
                        task.wait(0.05)
                    else
                        Core.Pathfinding.blacklistedItems[data.item] = true 
                    end
                end
            end
        end
    end

    -- ==========================================
    -- MESIN WIKJOK: RUNTIME LOOP
    -- ==========================================
    Core.UI.createToggle("▶ ENABLE AUTO PABRIK", "autoPabrik", secControl, false, function(state)
        if not state then 
            print("[NLight Pabrik] Sistem Dimatikan.")
            local hrp = Core.LocalPlayer.Character and (Core.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or Core.LocalPlayer.Character.PrimaryPart)
            if hrp then hrp.Anchored = false end
            return 
        end

        print("[NLight Pabrik] Sistem Dijalankan! Membaca Jalur Pathfinding...")

        task.spawn(function()
            local hrp = Core.LocalPlayer.Character and (Core.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or Core.LocalPlayer.Character.PrimaryPart)
            if hrp then hrp.Anchored = true end

            while Core.Toggles.autoPabrik do
                local standX, standY = ParsePos(Core.Inputs["pabrikStandPos"] and Core.Inputs["pabrikStandPos"].Text or "0,0")
                local farmX, farmY = ParsePos(Core.Inputs["pabrikBlockPos"] and Core.Inputs["pabrikBlockPos"].Text or "0,0")
                local blockType = string.lower(Core.Inputs["pabrikBlockType"] and Core.Inputs["pabrikBlockType"].Text or "")
                
                local sStartX, sStartY = ParsePos(Core.Inputs["pabrikSapStart"] and Core.Inputs["pabrikSapStart"].Text or "0,0")
                local sEndX, sEndY = ParsePos(Core.Inputs["pabrikSapEnd"] and Core.Inputs["pabrikSapEnd"].Text or "0,0")
                local sLimitY = tonumber(Core.Inputs["pabrikSapLimitY"] and Core.Inputs["pabrikSapLimitY"].Text) or sStartY
                
                local saplingType = Core.Toggles.pabrikSaplingType or "dirt_sapling"
                saplingType = string.lower(saplingType)

                local walkSpeed = tonumber(Core.Inputs["pabrikWalkSpeed"] and Core.Inputs["pabrikWalkSpeed"].Text) or 45
                local placeDelay = (tonumber(Core.Inputs["pabrikPlaceSpeed"] and Core.Inputs["pabrikPlaceSpeed"].Text) or 150) / 1000
                local breakDelay = (tonumber(Core.Inputs["pabrikBreakSpeed"] and Core.Inputs["pabrikBreakSpeed"].Text) or 250) / 1000

                -- ==========================================
                -- FASE 1: SMART AUTO FARM BLOCK
                -- ==========================================
                print("[WIKJOK] Memulai Fase 1: Smart Auto Farm Block")
                
                while Core.Toggles.autoPabrik do
                    local count, slot = GetItemSlotAndCount(blockType, "block")
                    if count <= 0 then break end

                    -- Pindah ke tempat berdiri dan Mengerem
                    Core.Pathfinding.aiMoveTo(standX, standY, walkSpeed, "autoPabrik")
                    StopMovement()
                    task.wait(0.1)

                    if not HasBlock(farmX, farmY) and Core.Remotes.PlayerPlaceRemote then
                        Core.Remotes.PlayerPlaceRemote:FireServer(Vector2.new(farmX, farmY), slot)
                        task.wait(placeDelay) -- [DIPERBARUI] Delay saat menaruh blok
                    end

                    local brokeBlock = false
                    while HasBlock(farmX, farmY) and Core.Toggles.autoPabrik do
                        if Core.Remotes.PlayerFistRemote then Core.Remotes.PlayerFistRemote:FireServer(Vector2.new(farmX, farmY)) end
                        task.wait(breakDelay)
                        brokeBlock = true
                    end

                    -- [DIPERBARUI] Jeda penting agar server sempat memunculkan item drop secara fisik
                    if brokeBlock then
                        task.wait(0.2) 
                    end

                    -- Loot Block (Radius kecil 5 Grid)
                    SafeAutoLoot(farmX, farmY, walkSpeed, 5)
                    task.wait(0.1) -- Jeda nafas sebelum menaruh blok berikutnya
                end

                if not Core.Toggles.autoPabrik then break end

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
                    if isOutOfSapling or not Core.Toggles.autoPabrik then break end
                    
                    for x = sStartX, sEndX, loopStepX do
                        if not Core.Toggles.autoPabrik then break end
                        
                        local sCount, sSlot = GetItemSlotAndCount(saplingType, "sapling")
                        if sCount <= 0 then 
                            print("[WIKJOK] Sapling habis di tengah jalan! Lanjut ke fase panen.")
                            isOutOfSapling = true 
                            break 
                        end
                        
                        if not HasBlock(x, y) then
                            if Core.Pathfinding.aiMoveTo(x, y, walkSpeed, "autoPabrik") then
                                StopMovement()
                                task.wait(0.1)
                                if Core.Remotes.PlayerPlaceRemote then
                                    Core.Remotes.PlayerPlaceRemote:FireServer(Vector2.new(x, y), sSlot)
                                    table.insert(plantedSaplings, {X = x, Y = y, Time = workspace:GetServerTimeNow()})
                                    task.wait(placeDelay) -- [DIPERBARUI] Memakai settingan Place Delay
                                end
                            else
                                Core.Pathfinding.blacklistedSpots[x..","..y] = true
                            end
                        end
                    end
                end

                if not Core.Toggles.autoPabrik then break end

                -- [B] Tunggu Matang 
                if #plantedSaplings > 0 then
                    print(string.format("[WIKJOK] Menunggu %d Sapling Matang...", #plantedSaplings))
                    local allGrown = false
                    while not allGrown and Core.Toggles.autoPabrik do
                        allGrown = true
                        for _, sapling in ipairs(plantedSaplings) do
                            if not IsSaplingGrown(sapling.X, sapling.Y, sapling.Time, saplingType) then
                                allGrown = false
                                break
                            end
                        end
                        if not allGrown then task.wait(2) end
                    end
                end

                if not Core.Toggles.autoPabrik then break end

                -- [C] Panen Eksekusi Cepat
                if #plantedSaplings > 0 then
                    print("[WIKJOK] Pohon Matang! Memulai Penghancuran Massal...")
                    for _, sapling in ipairs(plantedSaplings) do
                        if not Core.Toggles.autoPabrik then break end
                        
                        if Core.Pathfinding.aiMoveTo(sapling.X, sapling.Y, walkSpeed, "autoPabrik") then
                            StopMovement()
                            task.wait(0.05)
                            while HasBlock(sapling.X, sapling.Y) and Core.Toggles.autoPabrik do
                                if Core.Remotes.PlayerFistRemote then Core.Remotes.PlayerFistRemote:FireServer(Vector2.new(sapling.X, sapling.Y)) end
                                task.wait(breakDelay)
                            end
                        end
                    end
                    
                    if not Core.Toggles.autoPabrik then break end

                    -- [C.2] Mass Sweeping Loot
                    print("[WIKJOK] Penghancuran Selesai! Memungut semua item hasil panen...")
                    task.wait(0.5) -- Jeda ekstra sebelum nyapu massal agar server drop semua item
                    
                    local centerX = (sStartX + sEndX) / 2
                    local centerY = (sStartY + sLimitY) / 2
                    local fieldRadius = math.max(math.abs(sStartX - sEndX), math.abs(sStartY - sLimitY)) + 10
                    
                    SafeAutoLoot(centerX, centerY, walkSpeed, fieldRadius)
                end

                -- [D] ANTI-CRASH PROTECTION
                local cekBlockLagi = GetItemSlotAndCount(blockType, "block")
                if #plantedSaplings == 0 and cekBlockLagi <= 0 then
                    print("[WIKJOK] Inventory Kosong (Block & Sapling Habis). Menunggu item masuk...")
                    task.wait(2)
                end

            end
        end)
    end)
end
