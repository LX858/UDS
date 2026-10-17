QBCore = exports['qb-core']:GetCoreObject()

-- Biến lưu thông tin vũ khí cần xóa khi nâng cấp
CurrentWeaponsToRemove = nil

string.join = function(...)
    local result = ''
    for i, v in ipairs(arg) do
        result = result .. tostring(v)
    end

    return result
end

setupBlip = function(data, position)
    if data.Enable then
        local blip = AddBlipForCoord(position.x, position.y, position.z)
        SetBlipSprite(blip, data.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, data.Scale)
        SetBlipColour(blip, data.Color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(data.Label)
        EndTextCommandSetBlipName(blip)

        Citizen.Wait(math.random(100, 400))
    end
end

setupObject = function(data)
    if data.Hash ~= false then
        RequestModel(data.Hash)
        while not HasModelLoaded(data.Hash) do
            Citizen.Wait(1)
        end

        local objPlace = 0
        while objPlace < 1 do
            local tableObj = CreateObject(GetHashKey(data.Hash), data.Position.x, data.Position.y, data.Position.z, false, true, true)
            table.insert(Tables, tableObj)
            objPlace = objPlace + 1

            SetEntityHeading(tableObj, data.Heading)
        end

        Citizen.Wait(math.random(100, 400))
    end
end

setupOxTarget = function(id, data)
    exports.ox_target:addSphereZone({
        coords = vector3(data.Position.x, data.Position.y, data.Position.z + 2.0),
        radius = 1.5,
        debug = false,
        options = {
            {
                name = 'crafting_table_' .. id,
                icon = 'fas fa-hammer',
                label = data.Blip.Label,
                onSelect = function()
                    TriggerEvent('vierp.craftingx:openTable', id)
                end
            }
        }
    })
end

Draw3DText = function(x, y, z, textInput, fontId, scaleX, scaleY)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)    
    local scale = (1 / dist) * 15
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov 
    SetTextScale(scaleX * scale, scaleY * scale)
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(250, 250, 250, 255)		
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(x, y , z + 2, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

preparePlayerItem = function(item, multiply, lucky)
    local playerData = QBCore.Functions.GetPlayerData()
    local cashNeed = item.Cash * multiply
    local itemsNeed = {}
    local weaponNeed = false
    local state = {
        Dirty = true,
        Cash = true,
        Item = true,
        Weapon = true
    }

    -- BÙA MAY MẮN ĐÃ BỎ
    -- if lucky > 0 then
    --     table.insert(itemsNeed, {
    --         Name = Config.Lucky[lucky].item,
    --         Need = multiply
    --     })
    -- end

    for k, v in pairs(item.CraftItems) do
        table.insert(itemsNeed, {
            Name = k,
            Need = v[2]
        })
    end


    for k, v in pairs(item.PermItems) do
        table.insert(itemsNeed, {
            Name = k,
            Need = v[2]
        })
    end

    if Env.Debug then
        print('DEBUG : Craft Items ' .. json.encode(item.CraftItems))
        print('DEBUG : Perm Items ' .. json.encode(item.PermItems))  
    end

    local missingItems = {}
    for k, v in ipairs(itemsNeed) do
        local item = exports.ox_inventory:Search('count', v.Name)
        total_itemneed = v.Need*multiply
        if item < total_itemneed then
            state.Item = false
            table.insert(missingItems, v.Name)
        end
    end

    if Env.Debug then
        print('DEBUG : Cash ' .. playerData.money.cash)
        print('DEBUG : CashNeed ' .. cashNeed)
        
    end

    if playerData.money.cash < cashNeed and cashNeed > 0 then
        state.Cash = false
    end

    if item.ParentWeapon ~= nil then
        weaponNeed = item.ParentWeapon
        QBCore.Functions.TriggerCallback('vierp.craftingx:callback:hasWeapon', function(has, c, d) 
            state.Weapon = has
            state.Cash = c
            state.Dirty = d

            local status = true
            for k, v in pairs(state) do
                if v == false then
                    status = false
                    break
                end
            end

            if Env.Debug then
                print('DEBUG : State ' .. json.encode(state))
            end

            if status then
                SendNUIMessage({ type = 'item-ready' })
                playAnim()
                local craftLength = tonumber(item.Length) or 3000
                Citizen.SetTimeout(craftLength, function()
                    if IsCrafting then
                        SendNUIMessage({ type = 'craft-trigger' })
                    end
                end)
            else
                IsCrafting = false  -- Reset để player có thể thử lại
                QBCore.Functions.Notify('Không đủ vật phẩm chế tạo', 'error')
                SendNUIMessage({
                    type = 'item-not-ready',
                    missingItems = missingItems,
                    missingCash = not state.Cash
                }) 
            end
        end, weaponNeed, cashNeed)
    elseif item.RequireWeaponDurability ~= nil then
        -- Kiểm tra độ bền vũ khí
        QBCore.Functions.TriggerCallback('vierp.craftingx:callback:checkWeaponDurability', function(hasWeapons, hasCash, validCount, weaponsToRemove, noValidSerial)
            state.Weapon = hasWeapons
            state.Cash = hasCash
            
            -- Lưu danh sách vũ khí cần xóa
            CurrentWeaponsToRemove = weaponsToRemove
            CurrentRequireData = item.RequireWeaponDurability

            local status = true
            for k, v in pairs(state) do
                if v == false then
                    status = false
                    break
                end
            end

            if Env.Debug then
                print('DEBUG : WeaponDurability Check')
                print('DEBUG : Valid Weapons Count: ' .. validCount)
                print('DEBUG : Required: ' .. (item.RequireWeaponDurability.MinCount or 2))
                print('DEBUG : Min Durability: ' .. (item.RequireWeaponDurability.MinDurability or 30) .. '%')
                print('DEBUG : State ' .. json.encode(state))
            end

            if status then
                SendNUIMessage({ type = 'item-ready' })
                playAnim()
                local craftLength = tonumber(item.Length) or 3000
                Citizen.SetTimeout(craftLength, function()
                    if IsCrafting then
                        SendNUIMessage({ type = 'craft-trigger' })
                    end
                end)
            else
                if not hasWeapons then
                    if noValidSerial then
                        QBCore.Functions.Notify('Số seri không hợp lệ!', 'error')
                    else
                        local requiredWeapon = item.RequireWeaponDurability.RequiredWeapon or 'vũ khí'
                        local requiredLevel = item.RequireWeaponDurability.RequiredLevel or 1
                        local additionalCount = item.RequireWeaponDurability.AdditionalCount or 1
                        local minDurability = item.RequireWeaponDurability.MinDurability or 30
                        
                        -- Tìm label vũ khí từ tất cả crafting tables
                        local weaponName = requiredWeapon
                        for tableIndex, craftTable in pairs(Config) do
                            if type(craftTable) == 'table' and craftTable.Categories then
                                for _, category in pairs(craftTable.Categories) do
                                    if category.Items then
                                        for _, craftItem in pairs(category.Items) do
                                            if string.upper(craftItem.Item) == string.upper(requiredWeapon) and 
                                               craftItem.WeaponLevel == requiredLevel then
                                                weaponName = craftItem.Label
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        QBCore.Functions.Notify('Cần: 1x ' .. weaponName .. ' + ' .. additionalCount .. 'x vũ khí phụ (độ bền ≥' .. minDurability .. '%)', 'error')
                    end
                else
                    QBCore.Functions.Notify('Không đủ vật phẩm chế tạo', 'error')
                end
                IsCrafting = false  -- Reset để player có thể thử lại
                SendNUIMessage({
                    type = 'item-not-ready',
                    missingItems = missingItems,
                    missingCash = not state.Cash
                }) 
            end
        end, item.RequireWeaponDurability, cashNeed)
    else
        local wait = true
        QBCore.Functions.TriggerCallback('vierp.craftingx:callback:hasMoney', function(c, d)
            state.Cash = c
            state.Dirty = d

            wait = false
        end, cashNeed)

        while wait do
            Citizen.Wait(100)
        end

        local status = true
        for k, v in pairs(state) do
            if v == false then
                status = false
                break
            end
        end

        if Env.Debug then
            print('DEBUG : State ' .. json.encode(state))
        end

        if status then
            SendNUIMessage({ type = 'item-ready' })
            playAnim()
            local craftLength = tonumber(item.Length) or 3000
            Citizen.SetTimeout(craftLength, function()
                if IsCrafting then
                    SendNUIMessage({ type = 'craft-trigger' })
                end
            end)
        else
            IsCrafting = false  -- Reset để player có thể thử lại
            QBCore.Functions.Notify('Không đủ vật phẩm chế tạo', 'error')
            SendNUIMessage({
                type = 'item-not-ready',
                missingItems = missingItems,
                missingCash = not state.Cash
            }) 
        end 
    end
end

getInventoryItem = function(playerData, item)
    local myInventory = playerData.inventory
    for k, v in ipairs(myInventory) do
        if v.name == item then
            return v
        end
    end
end

getAccount = function(playerData, account)
    for k, v in ipairs(playerData.accounts) do
        if v.name == account then
            return v.money
        end
    end
end

loadAnimDict = function(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(5)
	end
end

playAnim = function()
    loadAnimDict('anim@amb@business@coc@coc_unpack_cut_left@')
    TaskPlayAnim(PlayerId(), 'anim@amb@business@coc@coc_unpack_cut_left@', 'cut_cough_coccutter', 3.0, 1.0, -1, 0, 0, 0, 0, 0)
end

checkPlayerItemOnClick = function(item, multiply)
    local playerData = QBCore.Functions.GetPlayerData()
    local cashNeed = item.Cash * multiply
    local itemsNeed = {}
    local state = {
        Cash = true,
        Item = true
    }
    if Env.Debug then
        print("^2[CHECK ITEM] Starting check for item^0")
        print("^2[CHECK ITEM] Cash needed: " .. cashNeed .. ", Player cash: " .. playerData.money.cash .. "^0")
    end
    
    for k, v in pairs(item.CraftItems or {}) do
        table.insert(itemsNeed, {
            Name = k,
            Need = v[2]
        })
    end

    for k, v in pairs(item.PermItems or {}) do
        table.insert(itemsNeed, {
            Name = k,
            Need = v[2]
        })
    end

    local missingItems = {}
    for k, v in ipairs(itemsNeed) do
        local itemCount = exports.ox_inventory:Search('count', v.Name)
        local total_itemneed = v.Need * multiply
        if Env.Debug then
            print("^2[CHECK ITEM] Item: " .. v.Name .. ", Need: " .. total_itemneed .. ", Have: " .. itemCount .. "^0")
        end
        if itemCount < total_itemneed then
            state.Item = false
            table.insert(missingItems, v.Name)
            if Env.Debug then
                print("^1[CHECK ITEM] Missing item: " .. v.Name .. "^0")
            end
        end
    end

    if playerData.money.cash < cashNeed and cashNeed > 0 then
        state.Cash = false
        if Env.Debug then
            print("^1[CHECK ITEM] Missing cash^0")
        end
    end

    if Env.Debug then
        print("^2[CHECK ITEM] Sending result to NUI^0")
        print("^2[CHECK ITEM] Missing items: " .. json.encode(missingItems) .. "^0")
    end
    SendNUIMessage({
        type = 'check-result',
        missingItems = missingItems,
        missingCash = not state.Cash,
        hasAll = state.Cash and state.Item
    })
end