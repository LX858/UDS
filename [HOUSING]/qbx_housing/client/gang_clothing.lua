local QBX = exports.qbx_core
local savedCivilianClothing = {}
local isWearingGangUniform = false

-- GTA V Component Mapping
local Components = {
    ['mask']      = 1,  -- Mặt nạ
    ['hair']      = 2,  -- Tóc
    ['arms']      = 3,  -- Cánh tay / Body
    ['pants']     = 4,  -- Quần
    ['bag']       = 5,  -- Balo / Túi xách
    ['shoes']     = 6,  -- Giày
    ['accessory'] = 7,  -- Phụ kiện / Cà vạt / Dây chuyền
    ['tshirt']    = 8,  -- Áo trong (Undershirt)
    ['bproof']    = 9,  -- Giáp (Body Armor)
    ['decals']    = 10, -- Decals / Huy hiệu
    ['torso']     = 11  -- Áo ngoài (Tops)
}

-- GTA V Prop Mapping
local Props = {
    ['helmet']   = 0, -- Mũ / Nón
    ['glasses']  = 1, -- Kính
    ['ear']      = 2, -- Khuyên tai
    ['watch']    = 6, -- Đồng hồ
    ['bracelet'] = 7  -- Vòng tay
}

-- 4 Cấp bậc Xã Đoàn chuẩn
local GangGradeNames = {
    [0] = 'Đàn em',
    [1] = 'Đàn anh',
    [2] = 'Trưởng lão',
    [3] = 'Lão đại (Boss)'
}

local function GetGangGradeLabel(grade)
    local g = tonumber(grade) or 0
    if GangGradeNames[g] then
        return GangGradeNames[g]
    elseif g >= 3 then
        return 'Lão đại (Boss)'
    end
    return 'Cấp ' .. g
end

local function FormatGradesList(grades)
    if not grades or #grades == 0 then
        return 'Tất cả cấp bậc'
    end
    local names = {}
    for _, g in ipairs(grades) do
        table.insert(names, GetGangGradeLabel(g))
    end
    return table.concat(names, ', ')
end

-- Lưu lại trang phục cá nhân của player trước khi mặc đồng phục
local function SaveCurrentClothing()
    local ped = PlayerPedId()
    savedCivilianClothing = {
        components = {},
        props = {}
    }
    
    for name, id in pairs(Components) do
        savedCivilianClothing.components[name] = {
            drawable = GetPedDrawableVariation(ped, id),
            texture  = GetPedTextureVariation(ped, id)
        }
    end
    
    for name, id in pairs(Props) do
        savedCivilianClothing.props[name] = {
            drawable = GetPedPropIndex(ped, id),
            texture  = GetPedPropTextureIndex(ped, id)
        }
    end
end

-- Khôi phục lại trang phục cá nhân
local function RestoreOriginalClothing()
    local ped = PlayerPedId()
    
    -- Animation cởi đồ
    lib.progressBar({
        duration = 1500,
        label = 'Đang thay trang phục thường...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'clothingshirt',
            clip = 'try_shirt_positive_d'
        }
    })
    
    -- Gọi server event reload quần áo chính của hệ thống
    TriggerServerEvent('clothes:reloadPlayerClothes')
    
    -- Khôi phục decal và phụ kiện từ backup nếu có
    if savedCivilianClothing and savedCivilianClothing.components then
        CreateThread(function()
            Wait(600)
            local currentPed = PlayerPedId()
            if savedCivilianClothing.components['decals'] then
                local d = savedCivilianClothing.components['decals']
                SetPedComponentVariation(currentPed, 10, d.drawable or 0, d.texture or 0, 0)
            end
            
            if exports['illenium-appearance'] then
                local appearance = exports['illenium-appearance']:getPedAppearance(currentPed)
                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            end
        end)
    end
    
    isWearingGangUniform = false
    lib.notify({
        title = 'Tủ Đồ Xã Đoàn',
        description = 'Đã cởi đồng phục, khôi phục lại trang phục cá nhân!',
        type = 'info'
    })
end

-- Mặc bộ đồ Xã Đoàn
local function ApplyGangOutfit(outfit)
    if not outfit then return end
    local ped = PlayerPedId()
    
    if not isWearingGangUniform then
        SaveCurrentClothing()
    end
    
    -- Animation thay đồ
    local success = lib.progressBar({
        duration = 2000,
        label = 'Đang mặc: ' .. outfit.name .. '...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'clothingshirt',
            clip = 'try_shirt_positive_d'
        }
    })
    
    if not success then return end
    
    local currentPed = PlayerPedId()
    
    -- 1. Áp dụng Components (Quần áo)
    if outfit.components and type(outfit.components) == 'table' then
        for compName, data in pairs(outfit.components) do
            local compId = Components[compName]
            if compId and data and type(data) == 'table' then
                local drawable = tonumber(data.drawable)
                local texture = tonumber(data.texture) or 0
                
                if drawable and drawable >= 0 then
                    local numDrawables = GetNumberOfPedDrawableVariations(currentPed, compId)
                    if drawable < numDrawables then
                        local numTextures = GetNumberOfPedTextureVariations(currentPed, compId, drawable)
                        if texture >= numTextures then
                            texture = 0
                        end
                        SetPedComponentVariation(currentPed, compId, drawable, texture, 0)
                    end
                elseif drawable == -1 then
                    SetPedComponentVariation(currentPed, compId, 0, 0, 0)
                end
            end
        end
    end
    
    -- 2. Áp dụng Props (Mũ, Kính, Phụ kiện...)
    if outfit.props and type(outfit.props) == 'table' then
        for propName, data in pairs(outfit.props) do
            local propId = Props[propName]
            if propId and data and type(data) == 'table' then
                local drawable = tonumber(data.drawable)
                local texture = tonumber(data.texture) or 0
                
                if drawable and drawable >= 0 then
                    local numProps = GetNumberOfPedPropDrawables(currentPed, propId)
                    if drawable < numProps then
                        local numTextures = GetNumberOfPedPropTextureVariations(currentPed, propId, drawable)
                        if texture >= numTextures then
                            texture = 0
                        end
                        SetPedPropIndex(currentPed, propId, drawable, texture, true)
                    end
                elseif drawable == -1 then
                    ClearPedProp(currentPed, propId)
                end
            end
        end
    end
    
    -- 3. Đồng bộ với illenium-appearance nếu có
    if exports['illenium-appearance'] then
        local appearance = exports['illenium-appearance']:getPedAppearance(currentPed)
        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    end
    
    isWearingGangUniform = true
    lib.notify({
        title = 'Tủ Đồ Xã Đoàn',
        description = 'Đã mặc bộ trang phục: ' .. outfit.name,
        type = 'success'
    })
end

-- Mở Menu Tủ Đồ Xã Đoàn (lib.contextmenu)
function OpenGangClothingMenu(gangName, houseId)
    local PlayerData = QBX:GetPlayerData()
    if not PlayerData or not PlayerData.gang or not PlayerData.gang.name or PlayerData.gang.name == '' or PlayerData.gang.name == 'none' then
        lib.notify({
            title = 'Tủ Đồ Xã Đoàn',
            description = 'Bạn không thuộc bất kỳ Xã Đoàn nào!',
            type = 'error'
        })
        return
    end

    if not gangName or gangName == '' or gangName == 'public' then
        gangName = PlayerData.gang.name
    end

    if PlayerData.gang.name ~= gangName then
        lib.notify({
            title = 'Tủ Đồ Xã Đoàn',
            description = 'Bạn không thuộc Xã Đoàn ' .. gangName .. '!',
            type = 'error'
        })
        return
    end

    local playerGrade = 0
    if PlayerData.gang.grade then
        if type(PlayerData.gang.grade) == 'table' then
            playerGrade = tonumber(PlayerData.gang.grade.level) or 0
        else
            playerGrade = tonumber(PlayerData.gang.grade) or 0
        end
    end

    local ped = PlayerPedId()
    local isMale = GetEntityModel(ped) == GetHashKey('mp_m_freemode_01')
    local playerGender = isMale and 'male' or 'female'
    local gangLabel = PlayerData.gang.label or gangName

    -- Lấy danh sách outfits từ server
    lib.callback('qbx_housing:server:getGangOutfits', false, function(outfits)
        local options = {}

        -- Tùy chọn 1: Cởi đồng phục
        table.insert(options, {
            title = 'Cởi đồng phục (Mặc lại đồ thường)',
            description = 'Khôi phục lại trang phục ban đầu của bạn',
            icon = 'fa-solid fa-person-arrow-down-to-line',
            onSelect = function()
                RestoreOriginalClothing()
            end
        })

        if not outfits or #outfits == 0 then
            table.insert(options, {
                title = 'Chưa có trang phục nào',
                description = 'Admin chưa thiết lập bộ đồ nào cho Xã Đoàn này',
                icon = 'fa-solid fa-circle-exclamation',
                disabled = true
            })
        else
            for _, outfit in ipairs(outfits) do
                -- Kiểm tra giới tính
                local matchGender = (outfit.gender == 'all' or outfit.gender == playerGender or outfit.gender == nil or outfit.gender == '')
                
                if matchGender then
                    -- Kiểm tra quyền theo cấp bậc
                    local hasPermission = false
                    local gradesList = outfit.grades or {}
                    
                    if #gradesList == 0 then
                        hasPermission = true
                    else
                        for _, g in ipairs(gradesList) do
                            if tonumber(g) == playerGrade then
                                hasPermission = true
                                break
                            end
                        end
                    end

                    local gradeText = FormatGradesList(gradesList)
                    local genderBadge = outfit.gender == 'male' and ' [Nam]' or (outfit.gender == 'female' and ' [Nữ]' or '')

                    if hasPermission then
                        table.insert(options, {
                            title = outfit.name .. genderBadge,
                            description = 'Phù hợp cấp bậc: ' .. gradeText,
                            icon = 'fa-solid fa-shirt',
                            onSelect = function()
                                ApplyGangOutfit(outfit)
                            end
                        })
                    else
                        table.insert(options, {
                            title = outfit.name .. genderBadge,
                            description = '🔒 Yêu cầu cấp: ' .. gradeText .. ' (Cấp hiện tại: ' .. GetGangGradeLabel(playerGrade) .. ')',
                            icon = 'fa-solid fa-lock',
                            disabled = true
                        })
                    end
                end
            end
        end

        local menuId = 'gang_clothing_menu_' .. tostring(houseId or 'default')
        lib.registerContext({
            id = menuId,
            title = 'Tủ Đồ Xã Đoàn - ' .. gangLabel,
            options = options
        })
        lib.showContext(menuId)
    end, gangName)
end

-- Export hàm đọc ngoại hình hiện tại của Ped cho Admin NUI
function GetCurrentPedClothingData()
    local ped = PlayerPedId()
    local isMale = GetEntityModel(ped) == GetHashKey('mp_m_freemode_01')
    local gender = isMale and 'male' or 'female'

    local components = {}
    for name, id in pairs(Components) do
        components[name] = {
            drawable = GetPedDrawableVariation(ped, id),
            texture  = GetPedTextureVariation(ped, id)
        }
    end

    local props = {}
    for name, id in pairs(Props) do
        props[name] = {
            drawable = GetPedPropIndex(ped, id),
            texture  = GetPedPropTextureIndex(ped, id)
        }
    end

    return {
        gender = gender,
        components = components,
        props = props
    }
end

-- Quản lý Spawn Ped Thay Quần Áo Gang Công Cộng
local spawnedPublicPeds = {}
local publicBlips = {}

local function SpawnPublicGangPeds()
    if not Config or not Config.PublicGangClothing then return end

    for i, data in ipairs(Config.PublicGangClothing) do
        local model = data.model or 'g_m_y_salvagoon_01'
        local modelHash = type(model) == 'number' and model or joaat(model)

        lib.requestModel(modelHash, 5000)

        local coords = data.coords
        local ped = CreatePed(0, modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
        SetEntityHeading(ped, coords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        if data.scenario then
            TaskStartScenarioInPlace(ped, data.scenario, 0, true)
        end

        SetModelAsNoLongerNeeded(modelHash)

        -- Gắn ox_target tương tác
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'public_gang_clothing_' .. i,
                icon = 'fa-solid fa-shirt',
                label = 'Tủ Đồ Xã Đoàn',
                distance = 2.5,
                onSelect = function()
                    OpenGangClothingMenu(nil, 'public_' .. i)
                end
            }
        })

        table.insert(spawnedPublicPeds, ped)

        -- Tạo Blip trên bản đồ nếu được bật
        if data.blip and data.blip.enabled then
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, data.blip.sprite or 73)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, data.blip.scale or 0.7)
            SetBlipColour(blip, data.blip.color or 1)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(data.blip.name or 'Tủ Đồ Xã Đoàn (Công Cộng)')
            EndTextCommandSetBlipName(blip)
            table.insert(publicBlips, blip)
        end
    end
end

CreateThread(function()
    Wait(1000)
    SpawnPublicGangPeds()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, ped in ipairs(spawnedPublicPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawnedPublicPeds = {}

    for _, blip in ipairs(publicBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    publicBlips = {}
end)

-- Export hàm ra toàn cục
_G.OpenGangClothingMenu = OpenGangClothingMenu
_G.GetCurrentPedClothingData = GetCurrentPedClothingData

