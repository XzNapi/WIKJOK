return function(Core)
    -- ==========================================
    -- WIKJOK: AUTO PABRIK (INTEGRATED NLIGHT MODULE)
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
    
    -- Menggunakan fungsi bawaan NLight + Filter Cerdas (Hanya tampilkan sapling)
    Core.UI.createInventoryDropdown("Pilih Sapling", "pabrikSaplingType", secSapling, nil, function(itemName, itemId)
        local n = string.lower(itemName); local id = string.lower(itemId)
        return string.find(n, "sapling") or string.find(id, "sapling")
    end)

    -- UI SETUP: Pengaturan & Eksekusi
    local secControl = Core.UI.createSection(page, "4. Pengaturan & Eksekusi")
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

    local function MoveToGrid(gx, gy)
        if Core.Managers.MovementState then
            Core.Managers.MovementState.Position = Vector3.new(gx, gy, 0) * Core.Utils.TILE_SIZE
            Core.Managers.MovementState.VelocityX, Core.Managers.MovementState.VelocityY = 0, 0
        end
    end

    local function HasBlock(gx, gy)
        if Core.Managers.WorldManager and Core.Managers.WorldManager.GetTile then
            for l = 1, 5 do if Core.Managers.WorldManager.GetTile(gx, gy, l) then return true end end
        end
        return false
    end

    local function IsSaplingGrown(gx, gy, plantTime)
        return (os.time() - plantTime) >= 60 -- Asumsi tumbuh 60 detik (bisa diubah)
    end

    local function FastAutoLoot(radiusPos)
        local dropsFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("DroppedItems") or workspace:FindFirstChild("Items")
        if dropsFolder and Core.Managers.MovementState then
            for _, item in ipairs(dropsFolder:GetChildren()) do
                local part = item:IsA("BasePart") and item or (item:IsA("Model") and item.PrimaryPart)
                if part then
                    local dist = (Vector2.new(part.Position.X, part.Position.Y) - Vector2.new(radiusPos.X, radiusPos.Y)).Magnitude
                    if dist < (20 * Core.Utils.TILE_SIZE) then
                        Core.Managers.MovementState.Position = part.Position
                        task.wait(0.05)
                    end
                end
            end
        end
    end

    -- ==========================================
    -- MESIN WIKJOK: RUNTIME LOOP
    -- ==========================================
    local engineActive = false

    Core.UI.createToggle("▶ ENABLE AUTO PABRIK", "autoPabrikToggle", secControl, false, function(state)
        engineActive = state
        
        if not engineActive then 
            print("[NLight Pabrik] Sistem Dimatikan.")
            local hrp = Core.LocalPlayer.Character and (Core.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or Core.LocalPlayer.Character.PrimaryPart)
            if hrp then hrp.Anchored = false end
            return 
        end

        print("[NLight Pabrik] Sistem Dijalankan! Memulai Loop Tertutup.")

        task.spawn(function()
            -- FPS Booster (Global Anchor)
            local hrp = Core.LocalPlayer.Character and (Core.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or Core.LocalPlayer.Character.PrimaryPart)
            if hrp then hrp.Anchored = true end

            while engineActive do
                -- Mengambil Data Langsung dari UI NLight
                local standX, standY = ParsePos(Core.Inputs["pabrikStandPos"] and Core.Inputs["pabrikStandPos"].Text or "0,0")
                local farmX, farmY = ParsePos(Core.Inputs["pabrikBlockPos"] and Core.Inputs["pabrikBlockPos"].Text or "0,0")
                local blockType = string.lower(Core.Inputs["pabrikBlockType"] and Core.Inputs["pabrikBlockType"].Text or "")
                
                local sStartX, sStartY = ParsePos(Core.Inputs["pabrikSapStart"] and Core.Inputs["pabrikSapStart"].Text or "0,0")
                local sEndX, sEndY = ParsePos(Core.Inputs["pabrikSapEnd"] and Core.Inputs["pabrikSapEnd"].Text or "0,0")
                local sLimitY = tonumber(Core.Inputs["pabrikSapLimitY"] and Core.Inputs["pabrikSapLimitY"].Text) or sStartY
                
                local saplingType = Core.Toggles.pabrikSaplingType or "auto"
                if saplingType == "auto" then saplingType = "dirt_sapling" end
                saplingType = string.lower(saplingType)

                local breakDelay = (tonumber(Core.Inputs["pabrikBreakSpeed"] and Core.Inputs["pabrikBreakSpeed"].Text) or 250) / 1000

                -- ==========================================
                -- FASE 1: SMART AUTO FARM BLOCK
                -- ==========================================
                MoveToGrid(standX, standY)
                task.wait(0.5)

                while engineActive do
                    local count, slot = GetItemSlotAndCount(blockType, "block")
                    if count <= 0 then break end

                    if not HasBlock(farmX, farmY) and Core.Remotes.PlayerPlaceRemote then
                        Core.Remotes.PlayerPlaceRemote:FireServer(Vector2.new(farmX, farmY), slot)
                        task.wait(0.1)
                    end

                    while HasBlock(farmX, farmY) and engineActive do
                        if Core.Remotes.PlayerFistRemote then Core.Remotes.PlayerFistRemote:FireServer(Vector2.new(farmX, farmY)) end
                        task.wait(breakDelay)
                    end

                    FastAutoLoot(Vector3.new(farmX * Core.Utils.TILE_SIZE, farmY * Core.Utils.TILE_SIZE, 0))
                    MoveToGrid(standX, standY)
                end

                if not engineActive then break end

                -- ==========================================
                -- FASE 2: SMART AUTO FARM SAPLING
                -- ==========================================
                local plantedSaplings = {}
                local isOutOfSapling = false
                
                local loopStepX = (sStartX <= sEndX) and 1 or -1
                local loopStepY = (sStartY >= sLimitY) and -2 or 2 

                -- [A] Tanam
                for y = sStartY, sLimitY, loopStepY do
                    if isOutOfSapling or not engineActive then break end
                    for x = sStartX, sEndX, loopStepX do
                        if not engineActive then break end
                        
                        local sCount, sSlot = GetItemSlotAndCount(saplingType, "sapling")
                        if sCount <= 0 then isOutOfSapling = true break end
                        
                        if not HasBlock(x, y) then
                            MoveToGrid(x, y)
                            task.wait(0.1)
                            if Core.Remotes.PlayerPlaceRemote then
                                Core.Remotes.PlayerPlaceRemote:FireServer(Vector2.new(x, y), sSlot)
                                table.insert(plantedSaplings, {X = x, Y = y, Time = os.time()})
                                task.wait(0.1)
                            end
                        end
                    end
                end

                if not engineActive then break end

                -- [B] Tunggu
                if #plantedSaplings > 0 then
                    local allGrown = false
                    while not allGrown and engineActive do
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

                if not engineActive then break end

                -- [C] Panen
                for _, sapling in ipairs(plantedSaplings) do
                    if not engineActive then break end
                    MoveToGrid(sapling.X, sapling.Y)
                    task.wait(0.1)

                    while HasBlock(sapling.X, sapling.Y) and engineActive do
                        if Core.Remotes.PlayerFistRemote then Core.Remotes.PlayerFistRemote:FireServer(Vector2.new(sapling.X, sapling.Y)) end
                        task.wait(breakDelay)
                    end
                    FastAutoLoot(Vector3.new(sapling.X * Core.Utils.TILE_SIZE, sapling.Y * Core.Utils.TILE_SIZE, 0))
                end
            end
        end)
    end)
end
