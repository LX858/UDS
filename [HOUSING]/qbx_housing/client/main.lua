local QBX = exports.qbx_core


local function GetGangHouseInterior(level)
    local lvl = tonumber(level) or 1
    if Config.GangHouseLevels and Config.GangHouseLevels[lvl] and Config.GangHouseLevels[lvl].interior then
        return Config.GangHouseLevels[lvl].interior
    end
    if lvl == 2 then
        return vector4(-31.4107, -595.1233, 80.0309, 244.8473)
    elseif lvl >= 3 then
        return vector4(342.2681, 437.8397, 149.3809, 105.3746)
    else
        return vector4(346.60, -1012.87, -99.20, 0.0)
    end
end

local function GetGangHouseStashCoords(level)
    local lvl = tonumber(level) or 1
    if Config.GangHouseLevels and Config.GangHouseLevels[lvl] and Config.GangHouseLevels[lvl].stashCoords then
        return Config.GangHouseLevels[lvl].stashCoords
    end
    if lvl == 2 then
        return vector3(-12.889921188354, -596.69024658203, 79.556922912598)
    elseif lvl >= 3 then
        return vector3(338.62582397461, 437.19735717773, 142.03758239746)
    else
        return vector3(352.56, -998.95, -99.64)
    end
end

local currentHouse = nil
local inHouse = false
local isCurrentHouseOwner = false
local houseBlips = {}
local houseRadiusBlips = {}
local houseZones = {} -- LƯU ZONE NAMES
local allHouses = {} -- Cache houses từ server (thay thế Config.Houses)
local allHousesMap = {} -- Map O(1) lookup: {[strHouseId] = house}

local function UpdateHousesMap()
    allHousesMap = {}
    for _, h in ipairs(allHouses) do
        local strId = tostring(h.id)
        allHousesMap[strId] = h
        allHousesMap[h.id] = h
    end
end
local createdZones = {} -- Track tất cả zones đã tạo trong nhà

-- Helper lấy gang label từ qbx_core
local function GetGangLabel(gangName)
    if not gangName or gangName == '' or gangName == 'none' then return 'Xã Đoàn' end
    local success, gangData = pcall(function()
        return exports.qbx_core:GetGang(gangName)
    end)
    if success and gangData and gangData.label and gangData.label ~= '' then
        return gangData.label
    end
    return gangName
end

-- Helper lấy custom blip sprite cho gang từ config (mặc định 438)
local function GetGangBlipSprite(gangName)
    if not gangName or gangName == '' or gangName == 'none' then return 438 end
    if Config.GangBlipSprites and Config.GangBlipSprites[gangName] then
        return tonumber(Config.GangBlipSprites[gangName]) or 438
    end
    return 438
end

-- Helper tạo single house blip (Nhà dân: 40 | Nhà Gang: custom sprite / 438 + Zone đỏ hình vuông 50.0m)
local function CreateSingleHouseBlip(house)
    if not house or not house.door then return nil end
    local isGangHouse = (house.gang and house.gang ~= '' and house.gang ~= 'none') or house.type == 'gang'
    local blip = AddBlipForCoord(house.door.x, house.door.y, house.door.z)
    
    if isGangHouse then
        -- 1. Main Blip Icon (Mặc định luôn màu 0)
        local gangName = (house.gang and house.gang ~= '' and house.gang ~= 'none') and house.gang or 'Xã Đoàn'
        local gangSprite = GetGangBlipSprite(house.gang)
        SetBlipSprite(blip, gangSprite) -- Blip nhà gang (theo Config.GangBlipSprites hoặc mặc định 438)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 0) -- Blip nhà gang luôn màu 0
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        local gangName = (house.gang and house.gang ~= '' and house.gang ~= 'none') and house.gang or 'Xã Đoàn'
        local gangLabel = GetGangLabel(gangName)
        local blipTitle = house.label or ('Trụ sở ' .. gangLabel)
        AddTextComponentSubstringPlayerName(blipTitle)
        EndTextCommandSetBlipName(blip)
        
        -- 2. Area Zone đỏ hình vuông khoảng cách 50.0m (100.0x100.0m) xung quanh nhà gang
        if houseRadiusBlips[house.id] then
            RemoveBlip(houseRadiusBlips[house.id])
            houseRadiusBlips[house.id] = nil
        end
        local radiusBlip = AddBlipForArea(house.door.x, house.door.y, house.door.z, 70.0, 70.0)
        SetBlipRotation(radiusBlip, 0)
        SetBlipColour(radiusBlip, 1) -- Vùng zone luôn là màu đỏ cố định (1)
        SetBlipAlpha(radiusBlip, 180) -- Độ trong suốt của zone đỏ (đậm hơn, giá trị tối đa 255)
        SetBlipAsShortRange(radiusBlip, true)
        houseRadiusBlips[house.id] = radiusBlip
    else
        SetBlipSprite(blip, 40)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 7) -- Màu tím mặc định (empty)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        local houseLabel = (Config.HouseTypes[house.type] and Config.HouseTypes[house.type].label) or (house.label or 'Nhà')
        AddTextComponentSubstringPlayerName(houseLabel)
        EndTextCommandSetBlipName(blip)
    end
    
    return blip
end

-- Function tạo house blips (không dùng CreateThread - tối ưu resources)
local function CreateHouseBlips()
    local player = QBX:GetPlayerData()
    if not player or not player.citizenid then return end
    
    local citizenid = player.citizenid
    
    -- BƯỚC 1: TẠO TẤT CẢ BLIPS NGAY LẬP TỨC
    for _, house in ipairs(allHouses) do
        local blip = CreateSingleHouseBlip(house)
        if blip then
            houseBlips[house.id] = blip
        end
    end
    
    -- BƯỚC 2: ASYNC UPDATE MÀU CHO NHÀ DÂN (callback không block)
    lib.callback('qbx_housing:server:getAllHousesData', false, function(allHousesData)
        if not allHousesData then return end
        
        for houseId, houseData in pairs(allHousesData) do
            local blip = houseBlips[houseId]
            if blip then
                local houseObj = GetHouseConfigClient(houseId)
                
                local isGangHouse = houseObj and ((houseObj.gang and houseObj.gang ~= '' and houseObj.gang ~= 'none') or houseObj.type == 'gang')
                if not isGangHouse then
                    if houseData.citizenid == citizenid then
                        SetBlipColour(blip, 2) -- Nhà của mình - xanh lá
                    else
                        SetBlipColour(blip, 1) -- Nhà của người khác - đỏ
                    end
                else
                    -- Nhà gang giữ sprite theo config và màu blip luôn là 0
                    local gangSprite = GetGangBlipSprite(houseObj.gang)
                    SetBlipSprite(blip, gangSprite)
                    SetBlipColour(blip, 0)
                end
            end
        end
    end)
end

-- Function tạo interaction points cho doors (TỐI ƯU: không dùng callback trong canInteract)
local function CreateHouseInteractions()
    for _, house in ipairs(allHouses) do
        if Config.UseTarget then
            local zoneName = 'house_door_' .. house.id -- Unique zone name
            
            exports.ox_target:addSphereZone({
                coords = house.door,
                radius = 1.5,
                debug = Config.DebugPoly,
                name = zoneName,
                options = {
                    {
                        name = 'house_interact_' .. house.id,
                        icon = 'fa-solid fa-home',
                        label = 'Tương tác nhà',
                        onSelect = function()
                            OpenHousingNUI(house.id)
                        end
                    }
                }
            })
            houseZones[house.id] = zoneName
        else
            exports.ox_lib:addPoint({
                coords = house.door,
                distance = Config.InteractionDistance,
                house_id = house.id,
                onEnter = function(self)
                    lib.showTextUI('[E] - Tương tác nhà')
                end,
                onExit = function(self)
                    lib.hideTextUI()
                end,
                nearby = function(self)
                    if IsControlJustReleased(0, 38) then -- E key
                        OpenHousingNUI(self.house_id)
                    end
                end
            })
        end
    end
end

-- Chạy khi player loaded (event-driven thay vì CreateThread)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Load houses từ server TRƯỚC
    lib.callback('qbx_housing:server:getAllHouses', false, function(houses)
        if houses then
            allHouses = houses; UpdateHousesMap()
            CreateHouseBlips()
            CreateHouseInteractions()
        end
    end)
end)

-- Chạy khi resource start (nếu player đã logged in)
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Đợi player data sẵn sàng
    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end
    
    -- Load houses từ server TRƯỚC
    lib.callback('qbx_housing:server:getAllHouses', false, function(houses)
        if houses then
            allHouses = houses; UpdateHousesMap()
            CreateHouseBlips()
            CreateHouseInteractions()
        end
    end)
end)

-- Event reload houses từ server
RegisterNetEvent('qbx_housing:client:reloadHouses', function(houses)
    if not houses then return end
    
    --print('[Client] Reloading houses: ' .. #houses .. ' houses received')
    
    -- KIỂM TRA: Nếu player đang trong garage interior, SKIP reload để tránh mất xe
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    
    -- Check nếu đang trong mh_garage interior (coords thường ở dưới map)
    if pedCoords.z < -50.0 then
        --print('^3[Client] Player in garage interior, skipping reload to prevent vehicle loss^7')
        lib.notify({
            title = 'Housing System',
            description = 'Houses reloaded! Exit garage to see changes.',
            type = 'info'
        })
        
        -- Chỉ update cache, KHÔNG clear zones/blips/garages
        allHouses = houses; UpdateHousesMap()
        return
    end
    
    -- Clear old blips
    for _, blip in pairs(houseBlips) do
        RemoveBlip(blip)
    end
    houseBlips = {}
    for _, rBlip in pairs(houseRadiusBlips) do
        RemoveBlip(rBlip)
    end
    houseRadiusBlips = {}
    
    -- Clear old ox_target zones ĐÚNG CÁCH (dùng zone name)
    if Config.UseTarget then
        for houseId, zoneName in pairs(houseZones) do
            exports.ox_target:removeZone(zoneName)
        end
        houseZones = {}
    end
    
    -- QUAN TRỌNG: Clear all house garages từ mh_garage trước khi inject lại
    if GetResourceState('mh_garage') == 'started' then
        -- Trigger event để remove tất cả house garages
        for _, house in ipairs(allHouses) do
            local garageName = 'house_' .. house.id
            pcall(function()
                exports['mh_garage']:RemoveGarage(garageName)
            end)
        end
        --print('[Client] Cleared all house garages from mh_garage')
    end
    
    -- Update cache
    allHouses = houses; UpdateHousesMap()
    
    -- Recreate blips và interactions
    CreateHouseBlips()
    CreateHouseInteractions()
    
    --print('[Client] Houses reloaded successfully!')
end)

-- Event: Add house mới (tối ưu - chỉ add 1 nhà)
RegisterNetEvent('qbx_housing:client:addHouse', function(house)
    if not house then return end
    
    --print('[Client] Adding new house: ' .. house.id)
    
    -- Add vào cache
    table.insert(allHouses, house); UpdateHousesMap()
    
    -- Tạo blip cho nhà mới
    local blip = CreateSingleHouseBlip(house)
    if blip then
        houseBlips[house.id] = blip
    end
    
    -- Tạo ox_target zone cho nhà mới
    if Config.UseTarget then
        local zoneName = 'house_door_' .. house.id
        exports.ox_target:addSphereZone({
            coords = house.door,
            radius = Config.InteractionDistance,
            name = zoneName,
            options = {
                {
                    name = 'house_interact_' .. house.id,
                    icon = 'fa-solid fa-home',
                    label = 'Tương tác nhà',
                    onSelect = function()
                        OpenHousingNUI(house.id)
                    end
                }
            }
        })
        houseZones[house.id] = zoneName
    end
    
    --print('[Client] Successfully added house: ' .. house.id)
end)

-- Event: Update house (tối ưu - chỉ update 1 nhà)
RegisterNetEvent('qbx_housing:client:updateHouse', function(house)
    if not house then return end
    
    --print('[Client] Updating house: ' .. house.id)
    
    -- SAFETY CHECK: Nếu player đang TRONG nhà này, SKIP update để tránh glitch
    if currentHouse == house.id and inHouse then
        --print('^3[Client] Player is inside house ' .. house.id .. ', deferring update until exit^7')
        -- Cache update để apply sau khi exit
        for i, h in ipairs(allHouses) do
            if h.id == house.id then
                allHouses[i] = house
                break
            end
        end
        
        lib.notify({
            title = 'Housing System',
            description = 'House updated! Changes will apply when you exit.',
            type = 'info'
        })
        return
    end
    
    -- Tìm và update trong cache
    for i, h in ipairs(allHouses) do
        if h.id == house.id then
            allHouses[i] = house
            break
        end
    end
    
    -- Remove old blip
    if houseBlips[house.id] then
        RemoveBlip(houseBlips[house.id])
        houseBlips[house.id] = nil
    end
    if houseRadiusBlips[house.id] then
        RemoveBlip(houseRadiusBlips[house.id])
        houseRadiusBlips[house.id] = nil
    end
    
    -- Remove old zone
    if Config.UseTarget and houseZones[house.id] then
        exports.ox_target:removeZone(houseZones[house.id])
        houseZones[house.id] = nil
    end
    
    -- Recreate blip với coords mới
    local blip = CreateSingleHouseBlip(house)
    if blip then
        houseBlips[house.id] = blip
    end
    
    -- Recreate zone với coords mới
    if Config.UseTarget then
        local zoneName = 'house_door_' .. house.id
        exports.ox_target:addSphereZone({
            coords = house.door,
            radius = Config.InteractionDistance,
            name = zoneName,
            options = {
                {
                    name = 'house_interact_' .. house.id,
                    icon = 'fa-solid fa-home',
                    label = 'Tương tác nhà',
                    onSelect = function()
                        OpenHousingNUI(house.id)
                    end
                }
            }
        })
        houseZones[house.id] = zoneName
    end
    
    --print('[Client] Successfully updated house: ' .. house.id)
end)

-- Event: Delete house (tối ưu - chỉ xóa 1 nhà)
RegisterNetEvent('qbx_housing:client:deleteHouse', function(houseId)
    if not houseId then return end
    
    --print('[Client] Deleting house: ' .. houseId)
    
    -- Remove khỏi cache
    for i, house in ipairs(allHouses) do
        if house.id == houseId then
            table.remove(allHouses, i)
            break
        end
    end
    
    -- Remove blip
    if houseBlips[houseId] then
        RemoveBlip(houseBlips[houseId])
        houseBlips[houseId] = nil
    end
    if houseRadiusBlips[houseId] then
        RemoveBlip(houseRadiusBlips[houseId])
        houseRadiusBlips[houseId] = nil
    end
    
    -- Remove zone
    if Config.UseTarget and houseZones[houseId] then
        exports.ox_target:removeZone(houseZones[houseId])
        houseZones[houseId] = nil
    end
    
    -- Remove garage (nếu có)
    if GetResourceState('mh_garage') == 'started' then
        local garageName = 'house_' .. houseId
        pcall(function()
            exports['mh_garage']:RemoveGarage(garageName)
        end)
    end
    
    --print('[Client] Successfully deleted house: ' .. houseId)
end)

-- Vào nhà
function EnterHouse(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Xóa zones của nhà cũ TRƯỚC (nếu đang ở trong nhà khác)
    if currentHouse and currentHouse ~= houseId then
        RemoveExitPoint(currentHouse)
        RemovePreviewExitPoint(currentHouse)
    end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Trigger server event để set bucket TRƯỚC KHI teleport
    TriggerServerEvent('qbx_housing:server:enterHouse', houseId)
    
    Wait(100) -- Đợi bucket được set
    
    SetEntityCoords(PlayerPedId(), houseConfig.interior.x, houseConfig.interior.y, houseConfig.interior.z)
    local heading = houseConfig.interior.w or houseConfig.interior.h or 0.0
    if heading and heading ~= 0.0 then SetEntityHeading(PlayerPedId(), heading) end
    
    Wait(500)
    DoScreenFadeIn(500)
    
    currentHouse = houseId
    inHouse = true
    
    -- Cache ownership 1 lần duy nhất khi vào nhà để các zone dùng ngay (0ms)
    isCurrentHouseOwner = lib.callback.await('qbx_housing:server:isOwner', false, houseId) or false
    
    -- Tạo exit point và các interior zones
    CreateExitPoint(houseId)
end

-- Xóa điểm thoát (gọi khi exit house hoặc trước khi create exit point mới)
function RemoveExitPoint(houseId)
    if not Config.UseTarget then return end
    
    -- Xóa TẤT CẢ zones đã tạo (không chỉ của 1 nhà)
    for zoneName, _ in pairs(createdZones) do
        pcall(function()
            exports.ox_target:removeZone(zoneName)
        end)
    end
    
    -- Clear tracking table
    createdZones = {}
end

-- Tạo điểm thoát
function CreateExitPoint(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Xóa TẤT CẢ zones cũ trước
    RemoveExitPoint(houseId)
    
    if Config.UseTarget then
        local exitZoneName = 'house_exit_' .. houseId
        local manageZoneName = 'house_manage_interior_' .. houseId
        local stashZoneName = 'house_stash_interior_' .. houseId
        
        local isGang = (houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang'
        local stashCoords = houseConfig.storagePoint
        if isGang then
            stashCoords = GetGangHouseStashCoords(houseConfig.level or 1)
        end
        
        exports.ox_target:addSphereZone({
            coords = vector3(houseConfig.interior.x, houseConfig.interior.y, houseConfig.interior.z),
            radius = 1.5,
            debug = Config.DebugPoly,
            name = exitZoneName,
            options = {
                {
                    name = 'house_exit_' .. houseId,
                    icon = 'fa-solid fa-door-open',
                    label = 'Ra khỏi nhà',
                    onSelect = function()
                        ExitHouse(houseId)
                    end
                },
                {
                    name = 'house_manage_interior_' .. houseId,
                    icon = 'fa-solid fa-cog',
                    label = 'Quản lý nhà',
                    canInteract = function()
                        return isCurrentHouseOwner
                    end,
                    onSelect = function()
                        OpenHouseManagement(houseId)
                    end
                }
            }
        })
        
        -- Track zone
        createdZones[exitZoneName] = true
        
        -- Kho trong nhà (sử dụng stashCoords)
        if stashCoords then
            local stashOptions = {
                {
                    name = 'house_stash_interior_' .. houseId,
                    icon = 'fa-solid fa-box',
                    label = 'Mở kho đồ',
                    onSelect = function()
                        OpenStash(houseId)
                    end
                },
                {
                    name = 'house_change_ped_' .. houseId,
                    icon = 'fa-solid fa-user-circle',
                    label = 'Thay đổi Ped',
                    onSelect = function()
                        ChangePedFunction()
                    end
                }
            }

            -- Nếu là nhà Gang, thêm tính năng thay đồ Xã Đoàn
            if isGang and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none' then
                table.insert(stashOptions, {
                    name = 'house_gang_clothing_' .. houseId,
                    icon = 'fa-solid fa-shirt',
                    label = 'Thay đồ Xã Đoàn',
                    canInteract = function()
                        local PlayerData = QBX:GetPlayerData()
                        return PlayerData and PlayerData.gang and PlayerData.gang.name == houseConfig.gang
                    end,
                    onSelect = function()
                        OpenGangClothingMenu(houseConfig.gang, houseId)
                    end
                })
            end

            exports.ox_target:addSphereZone({
                coords = vector3(stashCoords.x, stashCoords.y, stashCoords.z),
                radius = 1.5,
                debug = Config.DebugPoly,
                name = stashZoneName,
                options = stashOptions
            })
            
            -- Track zone
            createdZones[stashZoneName] = true
        end
        
        -- Máy xay sinh tố (chỉ chủ nhà mới thấy)
        if houseConfig.juicerPoint then
            local juicerZoneName = 'house_juicer_interior_' .. houseId
            exports.ox_target:addSphereZone({
                coords = houseConfig.juicerPoint,
                radius = 1.5,
                debug = Config.DebugPoly,
                name = juicerZoneName,
                options = {
                    {
                        name = 'juicer_option',
                        icon = 'fa-solid fa-blender',
                        label = 'Đặt máy xay sinh tố',
                        canInteract = function()
                            return isCurrentHouseOwner
                        end,
                        onSelect = function()
                            exports['F7_ladudu']:StartJuicer(houseConfig.juicerPoint)
                        end
                    }
                }
            })
            createdZones[juicerZoneName] = true
        end
        
        -- Điểm đóng thùng hàng (chỉ chủ nhà mới thấy)
        if houseConfig.packagingPoint then
            local packagingZoneName = 'house_packaging_interior_' .. houseId
            exports.ox_target:addSphereZone({
                coords = houseConfig.packagingPoint,
                radius = 1.5,
                debug = Config.DebugPoly,
                name = packagingZoneName,
                options = {
                    {
                        name = 'packaging_option',
                        icon = 'fa-solid fa-box-open',
                        label = 'Đóng thùng hàng',
                        canInteract = function()
                            return isCurrentHouseOwner
                        end,
                        onSelect = function()
                            exports['F7_ladudu']:StartPackaging(houseConfig.packagingPoint)
                        end
                    }
                }
            })
            createdZones[packagingZoneName] = true
        end
        
        -- Tạo bed target zone khi vào nhà
        CreateBedTarget(houseId)
    end
end

-- Ra khỏi nhà
function ExitHouse(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Xóa tất cả zones trong nhà trước khi exit
    RemoveExitPoint(houseId)
    
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Trigger server event để reset bucket TRƯỚC KHI teleport
    TriggerServerEvent('qbx_housing:server:exitHouse', houseId)
    
    Wait(100) -- Đợi bucket được reset
    
    SetEntityCoords(PlayerPedId(), houseConfig.exitPoint.x, houseConfig.exitPoint.y, houseConfig.exitPoint.z)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    currentHouse = nil
    inHouse = false
    isCurrentHouseOwner = false
end

-- Mở kho
function OpenStash(houseId)
    local hasAccess = lib.callback.await('qbx_housing:server:openStash', false, houseId)
    
    if hasAccess then
        exports.ox_inventory:openInventory('stash', 'house_' .. houseId)
    else
        lib.notify({
            title = 'Kho đồ',
            description = 'Bạn không có quyền truy cập kho này',
            type = 'error'
        })
    end
end

-- Quản lý nhà & Trụ sở Xã Đoàn (Mở React NUI Modal chuyên nghiệp)
function OpenHouseManagement(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    local isGangHouse = (houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang'
    
    if isGangHouse then
        -- Kiểm tra quyền boss gang >= 3
        local player = QBX:GetPlayerData()
        local gangGrade = player and player.gang and player.gang.grade
        local gradeLevel = (type(gangGrade) == 'table' and gangGrade.level) or (type(gangGrade) == 'number' and gangGrade) or 0
        local isBoss = (player and player.gang and player.gang.name == houseConfig.gang) and (gradeLevel >= 3 or player.gang.isboss == true)
        
        if not isBoss then
            lib.notify({
                title = 'Xã Đoàn',
                description = 'Chỉ Boss Xã Đoàn (Cấp 3 trở lên) mới có quyền quản lý trụ sở!',
                type = 'error'
            })
            return
        end
    end
    
    -- Lấy dữ liệu quản lý đầy đủ từ server
    lib.callback('qbx_housing:server:getManagementData', false, function(mData)
        if not mData then
            lib.notify({
                title = 'Quản lý',
                description = 'Không thể tải dữ liệu quản lý ngôi nhà!',
                type = 'error'
            })
            return
        end
        
        -- Lấy danh sách người chơi xung quanh cửa
        local doorCoords = houseConfig.door or GetEntityCoords(PlayerPedId())
        lib.callback('qbx_housing:server:getNearbyPlayers', false, function(nearbyPlayers)
            -- Đóng HousingCard nếu đang mở và mở Modal Quản Lý React
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'showManagementUI',
                managementData = mData,
                nearbyPlayers = nearbyPlayers or {},
                data = {
                    managementData = mData,
                    nearbyPlayers = nearbyPlayers or {}
                }
            })
        end, doorCoords, 10.0)
    end, houseId)
end

-- Quản lý chìa khóa
function OpenKeyManagement(houseId)
    -- Get list of players with keys
    lib.callback('qbx_housing:server:getSharedKeys', false, function(sharedKeys)
        local options = {
            {
                title = 'Chia sẻ chìa khóa',
                description = 'Cho người chơi khác chìa khóa',
                icon = 'user-plus',
                onSelect = function()
                    GiveKeys(houseId)
                end
            }
        }
        
        -- Add players with keys to list
        if sharedKeys and #sharedKeys > 0 then
            table.insert(options, {
                title = '────────────────',
                description = 'Danh sách người có chìa khóa',
                disabled = true,
                icon = 'list'
            })
            
            for _, keyData in ipairs(sharedKeys) do
                table.insert(options, {
                    title = keyData.player_name or 'Unknown',
                    description = 'Nhấn để thu hồi chìa khóa',
                    icon = 'user',
                    iconColor = '#3b82f6',
                    onSelect = function()
                        -- Confirm revoke
                        local alert = lib.alertDialog({
                            header = 'Thu hồi chìa khóa',
                            content = 'Bạn có chắc muốn thu hồi chìa khóa của ' .. (keyData.player_name or 'người này') .. '?',
                            centered = true,
                            cancel = true,
                            labels = {
                                confirm = 'Thu hồi',
                                cancel = 'Hủy'
                            }
                        })
                        
                        if alert == 'confirm' then
                            local success, message = lib.callback.await('qbx_housing:server:removeKeys', false, houseId, keyData.citizenid)
                            
                            lib.notify({
                                title = 'Chìa khóa',
                                description = message,
                                type = success and 'success' or 'error'
                            })
                            
                            if success then
                                -- Reopen menu to refresh list
                                Wait(500)
                                OpenKeyManagement(houseId)
                            end
                        end
                    end
                })
            end
        else
            table.insert(options, {
                title = 'Chưa có ai được chia sẻ chìa khóa',
                disabled = true,
                icon = 'info-circle'
            })
        end
        
        lib.registerContext({
            id = 'key_management',
            title = 'Quản lý chìa khóa',
            options = options,
            menu = 'house_management'
        })
        
        lib.showContext('key_management')
    end, houseId)
end

-- Bán nhà
function SellHouse(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Kiểm tra và xóa hợp đồng bán nhà
    local hasContract, message = lib.callback.await('qbx_housing:server:checkSellContract', false, houseId)
    
    if not hasContract then
        lib.notify({
            title = 'Bán nhà',
            description = message,
            type = 'error'
        })
        return
    end
    
    -- Nhập giá bán
    local input = lib.inputDialog('Bán nhà', {
        {
            type = 'number',
            label = 'Giá bán',
            description = 'Giá tối thiểu: $500,000 - Tối đa: $10,000,000',
            required = true,
            min = 500000,
            max = 10000000,
            icon = 'dollar-sign'
        }
    })
    
    if not input then return end
    
    local sellPrice = tonumber(input[1])
    
    -- Validate price range
    if sellPrice < 500000 or sellPrice > 10000000 then
        lib.notify({
            title = 'Bán nhà',
            description = 'Giá bán phải từ $500,000 đến $10,000,000',
            type = 'error'
        })
        return
    end
    
    -- Get nearby players
    lib.callback('qbx_housing:server:getNearbyPlayers', false, function(nearbyPlayers)
        if not nearbyPlayers or #nearbyPlayers == 0 then
            lib.notify({
                title = 'Bán nhà',
                description = 'Không có người chơi nào gần đây để bán nhà',
                type = 'error'
            })
            return
        end
        
        -- Create options list
        local options = {}
        for _, player in ipairs(nearbyPlayers) do
            table.insert(options, {
                value = player.id,
                label = player.name .. ' (PID: ' .. (player.pid or 'N/A') .. ') - ' .. player.distance .. 'm'
            })
        end
        
        -- Show player selection dialog
        local buyerInput = lib.inputDialog('Chọn người mua', {
            {
                type = 'select',
                label = 'Chọn người mua nhà',
                description = 'Giá bán: $' .. sellPrice,
                options = options,
                required = true
            }
        })
        
        if not buyerInput then return end
        
        local buyerId = tonumber(buyerInput[1])
        
        -- Confirm sale
        local alert = lib.alertDialog({
            header = 'Xác nhận bán nhà',
            content = 'Bán nhà với giá $' .. sellPrice .. ' cho người chơi đã chọn?\n\nNgười mua sẽ thanh toán bằng tiền mặt.',
            centered = true,
            cancel = true,
            labels = {
                confirm = 'Bán',
                cancel = 'Hủy'
            }
        })
        
        if alert == 'confirm' then
            local success, message = lib.callback.await('qbx_housing:server:sellHouseToPlayer', false, houseId, buyerId, sellPrice)
            if success then
                lib.notify({
                    title = 'Bán nhà',
                    description = message,
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Bán nhà',
                    description = message,
                    type = 'error'
                })
            end
        end
    end, houseConfig.door, 5.0)
end

-- Mua máy xay sinh tố
function PurchaseJuicerMachine(houseId)
    -- Kiểm tra đã mua chưa
    lib.callback('qbx_housing:server:checkJuicerPurchased', false, function(alreadyPurchased)
        if alreadyPurchased then
            lib.notify({
                title = 'Máy xay sinh tố',
                description = 'Bạn đã mua máy xay sinh tố cho ngôi nhà này rồi',
                type = 'info'
            })
            return
        end
        
        -- Confirm purchase
        local alert = lib.alertDialog({
            header = 'Mua máy xay sinh tố',
            content = 'Mở khóa tính năng máy xay sinh tố trong nhà?\n\nGiá: 500 coin',
            centered = true,
            cancel = true,
            labels = {
                confirm = 'Mua (500 coin)',
                cancel = 'Hủy'
            }
        })
        
        if alert == 'confirm' then
            -- Call server to purchase
            lib.callback('qbx_housing:server:purchaseJuicer', false, function(success, message)
                lib.notify({
                    title = 'Máy xay sinh tố',
                    description = message,
                    type = success and 'success' or 'error'
                })
            end, houseId)
        end
    end, houseId)
end

-- Cho chìa khóa
function GiveKeys(houseId)
    -- Get current player position (use door coords from houseConfig)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Get nearby players
    lib.callback('qbx_housing:server:getNearbyPlayers', false, function(nearbyPlayers)
        if not nearbyPlayers or #nearbyPlayers == 0 then
            lib.notify({
                title = 'Chìa khóa',
                description = 'Không có người chơi nào gần đây',
                type = 'error'
            })
            return
        end
        
        -- Create options list
        local options = {}
        for _, player in ipairs(nearbyPlayers) do
            table.insert(options, {
                value = player.id,
                label = player.name .. ' (PID: ' .. (player.pid or 'N/A') .. ') - ' .. player.distance .. 'm'
            })
        end
        
        -- Show player selection dialog
        local input = lib.inputDialog('Cho chìa khóa', {
            {
                type = 'select',
                label = 'Chọn người nhận chìa khóa',
                description = 'Người chơi gần nhất',
                options = options,
                required = true
            }
        })
        
        if not input then return end
        
        local targetId = tonumber(input[1])
        local success, message = lib.callback.await('qbx_housing:server:giveKeys', false, houseId, targetId)
        
        lib.notify({
            title = 'Chìa khóa',
            description = message,
            type = success and 'success' or 'error'
        })
        
        if success then
            -- Reopen key management menu to refresh list
            Wait(500)
            OpenKeyManagement(houseId)
        end
    end, houseConfig.door, 5.0)
end

-- Mời vào nhà (owner)
function InvitePlayerToHouse(houseId, doorCoords)
    -- Get nearby players
    lib.callback('qbx_housing:server:getNearbyPlayers', false, function(nearbyPlayers)
        if not nearbyPlayers or #nearbyPlayers == 0 then
            lib.notify({
                title = 'Mời Vào Nhà',
                description = 'Không có người chơi nào gần đây',
                type = 'error'
            })
            return
        end
        
        -- Create options list
        local options = {}
        for _, player in ipairs(nearbyPlayers) do
            table.insert(options, {
                value = player.id,
                label = player.name .. ' (PID: ' .. (player.pid or 'N/A') .. ') - ' .. player.distance .. 'm'
            })
        end
        
        -- Show player selection dialog
        local input = lib.inputDialog('Mời Vào Nhà', {
            {
                type = 'select',
                label = 'Chọn người mời',
                description = 'Người chơi gần nhất',
                options = options,
                required = true
            }
        })
        
        if not input then return end
        
        local targetId = tonumber(input[1])
        
        -- Invite player (as owner - no job check)
        lib.callback('qbx_housing:server:inviteToHouseOwner', false, function(success, message)
            lib.notify({
                title = 'Mời Vào Nhà',
                description = message,
                type = success and 'success' or 'error'
            })
        end, houseId, targetId)
    end, doorCoords, 5.0)
end

-- Mở garage
function OpenGarage(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Kiểm tra quyền truy cập - CHỈ CHỦ NHÀ mới được mở garage
    local isOwner = lib.callback.await('qbx_housing:server:isOwner', false, houseId)
    if not isOwner then
        lib.notify({
            title = 'Garage',
            description = 'Chỉ chủ nhà mới có quyền truy cập garage',
            type = 'error'
        })
        return
    end
    
    -- Tạo garage name cho house
    local garageName = 'house_' .. houseId
    
    -- Kiểm tra khoảng cách (gần garage hoặc gần cửa nhà)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local garageCoords = houseConfig.garagePoint and vector3(houseConfig.garagePoint.x, houseConfig.garagePoint.y, houseConfig.garagePoint.z)
    local doorCoords = houseConfig.door and vector3(houseConfig.door.x, houseConfig.door.y, houseConfig.door.z)
    
    local distGarage = garageCoords and #(playerCoords - garageCoords) or 999.0
    local distDoor = doorCoords and #(playerCoords - doorCoords) or 999.0
    
    if distGarage > 100.0 and distDoor > 100.0 then
        lib.notify({
            title = 'Garage',
            description = 'Bạn phải đến gần nhà hoặc garage',
            type = 'error'
        })
        return
    end
    
    -- Gọi event để mở garage menu của housing (sẽ xử lý bởi client/garage.lua)
    TriggerEvent('qbx_housing:client:openGarageMenu', houseId, garageName)
end

-- Helper function
function GetHouseConfigClient(houseId)
    if not houseId then return nil end
    local strHouseId = tostring(houseId)
    return allHousesMap[strHouseId] or allHousesMap[houseId] or allHousesMap[tonumber(houseId)]
end

-- Receive invite to house tour (with confirmation dialog)
RegisterNetEvent('qbx_housing:client:receiveInvite', function(houseId, realestateSource, realestateName, houseLabel)
    local alert = lib.alertDialog({
        header = 'Lời Mời Thăm Quan',
        content = realestateName .. ' mời bạn thăm quan ' .. houseLabel .. '\n\nBạn có chấp nhận không?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Chấp nhận',
            cancel = 'Từ chối'
        }
    })
    
    if alert == 'confirm' then
        -- Player accepted - call server to teleport
        lib.callback('qbx_housing:server:acceptInvite', false, function(success, message)
            if success then
                -- enterAsGuest event will be triggered from server
            else
                lib.notify({
                    title = 'Thăm Quan',
                    description = message or 'Không thể vào nhà',
                    type = 'error'
                })
            end
        end, houseId, realestateSource)
    else
        -- Player declined - notify realestate
        TriggerServerEvent('qbx_housing:server:declineInvite', houseId, realestateSource)
        
        lib.notify({
            title = 'Thăm Quan',
            description = 'Bạn đã từ chối lời mời',
            type = 'info'
        })
    end
end)

-- Receive house transfer offer (with confirmation dialog)
RegisterNetEvent('qbx_housing:client:receiveTransferOffer', function(houseId, realestateSource, realestateName, houseLabel, price)
    local alert = lib.alertDialog({
        header = 'Đề Nghị Mua Nhà',
        content = realestateName .. ' đề nghị bán cho bạn ' .. houseLabel .. '\n\nGiá: $' .. price .. ' (tiền mặt)\n\nBạn có chấp nhận không?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Mua',
            cancel = 'Từ chối'
        }
    })
    
    if alert == 'confirm' then
        -- Player accepted - call server to process purchase
        lib.callback('qbx_housing:server:acceptTransfer', false, function(success, message)
            if success then
                lib.notify({
                    title = 'Mua Nhà',
                    description = message or 'Mua nhà thành công',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Mua Nhà',
                    description = message or 'Không thể mua nhà',
                    type = 'error'
                })
            end
        end, houseId, realestateSource, price)
    else
        -- Player declined - notify realestate
        TriggerServerEvent('qbx_housing:server:declineTransfer', houseId, realestateSource)
        
        lib.notify({
            title = 'Mua Nhà',
            description = 'Bạn đã từ chối đề nghị',
            type = 'info'
        })
    end
end)

-- Receive house purchase offer from player (new for player-to-player sale)
RegisterNetEvent('qbx_housing:client:receiveHousePurchaseOffer', function(offerData)
    local alert = lib.alertDialog({
        header = 'Đề Nghị Mua Nhà',
        content = offerData.sellerName .. ' muốn bán cho bạn ' .. offerData.houseLabel .. '\n\nGiá: $' .. offerData.price .. ' (tiền mặt)\n\nBạn có chấp nhận không?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Mua',
            cancel = 'Từ chối'
        }
    })
    
    if alert == 'confirm' then
        -- Player accepted - call server to process purchase
        lib.callback('qbx_housing:server:confirmHousePurchase', false, function(success, message)
            if success then
                lib.notify({
                    title = 'Mua Nhà',
                    description = message or 'Mua nhà thành công',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Mua Nhà',
                    description = message or 'Không thể mua nhà',
                    type = 'error'
                })
            end
        end, offerData.houseId, offerData.sellerId, offerData.price)
    else
        -- Player declined - notify seller
        TriggerServerEvent('qbx_housing:server:declineHousePurchase', offerData.houseId, offerData.sellerId)
        
        lib.notify({
            title = 'Mua Nhà',
            description = 'Bạn đã từ chối đề nghị',
            type = 'info'
        })
    end
end)

-- Update blip color khi nhà được mua hoặc bán
RegisterNetEvent('qbx_housing:client:updateBlipColor', function(houseId, ownerId)
    local blip = houseBlips[houseId]
    if not blip then return end
    
    local houseObj = nil
    for _, h in ipairs(allHouses) do
        if h.id == houseId then
            houseObj = h
            break
        end
    end
    
    local isGangHouse = houseObj and ((houseObj.gang and houseObj.gang ~= '' and houseObj.gang ~= 'none') or houseObj.type == 'gang')
    if isGangHouse then
        local gangSprite = GetGangBlipSprite(houseObj.gang)
        SetBlipSprite(blip, gangSprite)
        SetBlipColour(blip, 0)
        return
    end
    
    local player = QBX:GetPlayerData()
    local citizenid = player and player.citizenid
    
    if ownerId then
        -- Nhà có chủ
        if ownerId == citizenid then
            -- Nhà của mình - màu xanh lá
            SetBlipColour(blip, 2)
        else
            -- Nhà của người khác - màu đỏ
            SetBlipColour(blip, 1)
        end
    else
        -- Nhà trống - màu tím
        SetBlipColour(blip, 7)
    end
end)
-- ========== REALESTATE EVENTS ==========

-- Xóa preview exit point (cho realestate tour)
function RemovePreviewExitPoint(houseId)
    if not Config.UseTarget then return end
    
    -- Xóa TẤT CẢ zones đã tạo
    for zoneName, _ in pairs(createdZones) do
        pcall(function()
            exports.ox_target:removeZone(zoneName)
        end)
    end
    
    -- Clear tracking table
    createdZones = {}
end

-- Tạo preview exit point (cho realestate tour - chỉ có nút ra khỏi nhà)
function CreatePreviewExitPoint(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Xóa TẤT CẢ zones cũ trước
    RemovePreviewExitPoint(houseId)
    
    if Config.UseTarget then
        local previewZoneName = 'house_preview_exit_' .. houseId
        
        exports.ox_target:addSphereZone({
            coords = vector3(houseConfig.interior.x, houseConfig.interior.y, houseConfig.interior.z),
            radius = 1.5,
            debug = Config.DebugPoly,
            name = previewZoneName,
            options = {
                {
                    name = 'preview_exit_' .. houseId,
                    icon = 'fa-solid fa-door-open',
                    label = 'Ra khỏi nhà',
                    onSelect = function()
                        -- Exit preview mode
                        RemovePreviewExitPoint(houseId)
                        
                        DoScreenFadeOut(500)
                        Wait(500)
                        
                        -- Trigger server to reset bucket
                        TriggerServerEvent('qbx_housing:server:exitHouse', houseId)
                        
                        Wait(100)
                        
                        -- Teleport to exit point
                        SetEntityCoords(PlayerPedId(), houseConfig.exitPoint.x, houseConfig.exitPoint.y, houseConfig.exitPoint.z)
                        
                        Wait(500)
                        DoScreenFadeIn(500)
                        
                        currentHouse = nil
                        inHouse = false
                        
                        lib.notify({
                            title = 'Thăm Quan',
                            description = 'Đã thoát chế độ thăm quan',
                            type = 'info'
                        })
                    end
                }
            }
        })
        
        -- Track zone
        createdZones[previewZoneName] = true
    end
end

-- Enter house as guest (for realestate tour or owner invite)
RegisterNetEvent('qbx_housing:client:enterAsGuest', function(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Xóa zones của nhà CŨ (currentHouse) trước khi vào nhà mới
    if currentHouse and currentHouse ~= houseId then
        RemovePreviewExitPoint(currentHouse)
        RemoveExitPoint(currentHouse)
    end
    -- Xóa zones của nhà mới (nếu có)
    RemovePreviewExitPoint(houseId)
    
    -- Xóa NUI preview zone nếu có (từ nui.lua previewHouse)
    pcall(function()
        exports.ox_target:removeZone('preview_exit_' .. houseId)
    end)
    
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Teleport to interior
    SetEntityCoords(PlayerPedId(), houseConfig.interior.x, houseConfig.interior.y, houseConfig.interior.z)
    
    -- Server already set bucket, no need to call enterHouse event again
    
    inHouse = true
    currentHouse = houseId
    isCurrentHouseOwner = false
    
    -- Create exit point (using main.lua's CreatePreviewExitPoint which handles bucket reset)
    CreatePreviewExitPoint(houseId)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    lib.notify({
        title = 'Thăm Quan',
        description = 'Bạn đang ở chế độ thăm quan - không thể sử dụng kho đồ',
        type = 'info'
    })
end)

-- ========== BED SYSTEM ==========
local lastBurnedNotify = {} -- Throttle thông báo nhà bị đốt (10s)

-- Helper tạo bed target zone
local function SetupBedTargetZone(houseId, bedCoords)
    if not bedCoords or not inHouse or currentHouse ~= houseId then return end
    
    -- Remove old bed target if exists
    RemoveBedTarget(houseId)
    
    local bedZoneName = 'house_bed_' .. houseId
    local targetCoords = vector3(bedCoords.x, bedCoords.y, bedCoords.z)
    
    -- Create new bed target
    exports.ox_target:addSphereZone({
        coords = targetCoords,
        radius = 1.5,
        debug = Config.DebugPoly,
        name = bedZoneName,
        options = {
            {
                name = 'use_bed_' .. houseId,
                icon = 'fa-solid fa-bed',
                label = 'Ngủ',
                onSelect = function()
                    -- Kiểm tra sleep cooldown từ arson
                    if GetResourceState('tromnha_dotnha') == 'started' then
                        local canSleep, remaining = exports['tromnha_dotnha']:CanSleepInHouse(houseId)
                        if not canSleep then
                            local now = GetGameTimer()
                            if not lastBurnedNotify[houseId] or (now - lastBurnedNotify[houseId]) >= 10000 then
                                lastBurnedNotify[houseId] = now
                                local hours = math.floor(remaining / 3600)
                                local minutes = math.floor((remaining % 3600) / 60)
                                lib.notify({
                                    title = 'Giường ngủ',
                                    description = 'Giường và nhà đã bị đốt! Còn ' .. hours .. 'h ' .. minutes .. 'p nữa mới có thể sử dụng',
                                    type = 'error',
                                    duration = 10000
                                })
                            end
                            return
                        end
                    end
                    UseBed(bedCoords)
                end
            }
        }
    })
    
    -- Track zone
    createdZones[bedZoneName] = true
end

-- Tạo bed target zone
function CreateBedTarget(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if houseConfig and houseConfig.bedPoint then
        SetupBedTargetZone(houseId, houseConfig.bedPoint)
    else
        -- Fallback lấy từ server nếu chưa có trong house config
        lib.callback('qbx_housing:server:getBedCoords', false, function(bedCoords)
            if bedCoords then
                SetupBedTargetZone(houseId, bedCoords)
            end
        end, houseId)
    end
end

-- Remove bed target zone
function RemoveBedTarget(houseId)
    local zoneName = 'house_bed_' .. houseId
    exports.ox_target:removeZone(zoneName)
end

-- Use bed (sleep)
function UseBed(coordsleep)
    if not coordsleep then
        lib.notify({
            title = 'Giường ngủ',
            description = 'Không tìm thấy tọa độ giường',
            type = 'error'
        })
        return
    end
    --print(bedCoordsleep)
    -- Ensure bedCoords is vector4
    local bedVector4 = coordsleep
    if type(coordsleep) == 'table' and coordsleep.x and coordsleep.y and coordsleep.z then
        -- Convert table to vector4 (with heading if available, otherwise default to 0)
        local heading = coordsleep.w or coordsleep.h
        bedVector4 = vector4(coordsleep.x, coordsleep.y, coordsleep.z, heading)
    end
    
    -- Call sleep system export with bed coordinates
    local success, err = pcall(function()
        exports['sleep_system']:SleepWithMaxSleepiness(bedVector4, 100)
    end)
    
    if not success then
        lib.notify({
            title = 'Giường ngủ',
            description = 'Hệ thống ngủ không khả dụng',
            type = 'error'
        })
    end
end

-- ========== PED CHANGE SYSTEM ==========

-- Hàm thay đổi ped của player (gọi từ target/zone trong nhà)
function ChangePedFunction()
    local pedData = lib.callback.await('qbx_housing:server:getPed', false)

    if not pedData or not pedData.ped_model then
        return lib.notify({ description = 'Bạn không có ped đặc biệt', type = 'inform' })
    end

    local currentModel  = GetEntityModel(PlayerPedId())
    local isUsingPedMod = currentModel == GetHashKey(pedData.ped_model)
    local options = {}

    if isUsingPedMod then
        -- Đang dùng ped mod → cho đổi về mặc định
        table.insert(options, {
            title       = 'Đổi về nhân vật mặc định',
            description = 'Trở về ped mặc định của nhân vật',
            icon        = 'fas fa-undo',
            onSelect    = function()
                local defaultRow = lib.callback.await('qbx_housing:server:getDefaultAppearance', false)
                if not defaultRow or not defaultRow.model then
                    return lib.notify({ description = 'Không tìm thấy dữ liệu mặc định. Vui lòng reconnect.', type = 'inform' })
                end

                local model = GetHashKey(defaultRow.model)
                RequestModel(model)
                while not HasModelLoaded(model) do Wait(100) end
                SetPlayerModel(PlayerId(), model)
                SetModelAsNoLongerNeeded(model)

                local skin = defaultRow.skin and json.decode(defaultRow.skin) or nil
                if skin then
                    local ped = PlayerPedId()

                    -- Components
                    if skin.components then
                        for _, comp in ipairs(skin.components) do
                            SetPedComponentVariation(ped, comp.component_id, comp.drawable or 0, comp.texture or 0, 0)
                        end
                    end

                    -- Props
                    if skin.props then
                        for _, prop in ipairs(skin.props) do
                            if prop.drawable == -1 then
                                ClearPedProp(ped, prop.prop_id)
                            else
                                SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture or 0, true)
                            end
                        end
                    end

                    -- HeadBlend (freemode only)
                    if skin.headBlend then
                        local hb = skin.headBlend
                        SetPedHeadBlendData(ped,
                            hb.shapeFirst or 0, hb.shapeSecond or 0, hb.shapeThird or 0,
                            hb.skinFirst  or 0, hb.skinSecond  or 0, hb.skinThird  or 0,
                            hb.shapeMix   or 0, hb.skinMix     or 0, hb.thirdMix   or 0,
                            false
                        )
                    end

                    -- Hair color
                    if skin.hair then
                        SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
                    end

                    -- Eye color
                    if skin.eyeColor and skin.eyeColor >= 0 then
                        SetPedEyeColor(ped, skin.eyeColor)
                    end

                    -- Head overlays
                    if skin.headOverlays then
                        local overlayMap = {
                            blemishes       = 0, facialHair = 1, eyebrows = 2,
                            ageing          = 3, makeUp     = 4, blush    = 5,
                            complexion      = 6, sunDamage  = 7, lipstick = 8,
                            moleAndFreckles = 9, chestHair  = 10, bodyBlemishes = 11,
                        }
                        for name, idx in pairs(overlayMap) do
                            local o = skin.headOverlays[name]
                            if o then
                                SetPedHeadOverlay(ped, idx, o.style or 0, o.opacity or 0)
                                SetPedHeadOverlayColor(ped, idx, 1, o.color or 0, o.secondColor or 0)
                            end
                        end
                    end

                    -- Lưu lại vào illenium-appearance
                    TriggerServerEvent('illenium-appearance:server:saveAppearance', skin)
                end

                -- KHÔNG xóa motel_ped — player có thể đổi lại
                lib.notify({ description = 'Đã đổi về nhân vật mặc định (' .. defaultRow.model .. ')', type = 'success' })

                -- Sau 1s reload quần áo
                SetTimeout(1000, function()
                    TriggerServerEvent('clothes:reloadPlayerClothes')
                end)
            end
        })
    else
        -- Có ped mod nhưng đang dùng mặc định → cho đổi sang ped mod
        table.insert(options, {
            title       = 'Đổi sang: ' .. pedData.ped_model,
            description = 'Áp dụng nhân vật đặc biệt được gán cho bạn',
            icon        = 'fas fa-user-check',
            onSelect    = function()
                local model = GetHashKey(pedData.ped_model)
                RequestModel(model)
                while not HasModelLoaded(model) do Wait(100) end
                SetPlayerModel(PlayerId(), model)
                SetModelAsNoLongerNeeded(model)

                local ped = PlayerPedId()
                for i = 0, 11 do
                    SetPedComponentVariation(ped, i, pedData['comp'..i] or 0, pedData['tex'..i] or 0, 0)
                end
                for i = 0, 2 do ClearPedProp(ped, i) end
                ClearPedProp(ped, 6) ; ClearPedProp(ped, 7)

                -- Lưu vào illenium-appearance
                lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
                    if not appearance then appearance = {} end
                    appearance.model        = pedData.ped_model
                    appearance.headBlend    = nil
                    appearance.faceFeatures = nil
                    appearance.headOverlays = nil
                    appearance.hair         = nil
                    appearance.tattoos      = nil
                    local components = {}
                    for i = 0, 11 do
                        components[i + 1] = {
                            componentId = i,
                            drawableId  = pedData['comp'..i] or 0,
                            textureId   = pedData['tex'..i]  or 0,
                            paletteId   = 0,
                        }
                    end
                    appearance.components = components
                    appearance.props = {
                        { propId = 0, drawableId = -1, textureId = -1 },
                        { propId = 1, drawableId = -1, textureId = -1 },
                        { propId = 2, drawableId = -1, textureId = -1 },
                        { propId = 6, drawableId = -1, textureId = -1 },
                        { propId = 7, drawableId = -1, textureId = -1 },
                    }
                    TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
                end)

                lib.notify({ description = 'Đã đổi sang nhân vật: ' .. pedData.ped_model, type = 'success' })

                -- Sau 1s reload quần áo
                SetTimeout(1000, function()
                    TriggerServerEvent('clothes:reloadPlayerClothes')
                end)
            end
        })
    end

    lib.registerContext({
        id      = 'changePed_menu',
        title   = 'Thay đổi ngoại hình nhân vật',
        options = options,
    })
    lib.showContext('changePed_menu')
end

-- Event: Admin gán ped và áp dụng ngay cho client
RegisterNetEvent('qbx_housing:client:applyPed', function(pedModel, comps, texs)
    local model = GetHashKey(pedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    for i = 0, 11 do
        SetPedComponentVariation(ped, i, comps[i] or 0, texs[i] or 0, 0)
    end
    for i = 0, 2 do ClearPedProp(ped, i) end
    ClearPedProp(ped, 6) ; ClearPedProp(ped, 7)

    lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
        if not appearance then appearance = {} end
        appearance.model = pedModel
        appearance.headBlend = nil ; appearance.faceFeatures = nil
        appearance.headOverlays = nil ; appearance.hair = nil ; appearance.tattoos = nil
        local components = {}
        for i = 0, 11 do
            components[i + 1] = { componentId = i, drawableId = comps[i] or 0, textureId = texs[i] or 0, paletteId = 0 }
        end
        appearance.components = components
        appearance.props = {
            { propId = 0, drawableId = -1, textureId = -1 },
            { propId = 1, drawableId = -1, textureId = -1 },
            { propId = 2, drawableId = -1, textureId = -1 },
            { propId = 6, drawableId = -1, textureId = -1 },
            { propId = 7, drawableId = -1, textureId = -1 },
        }
        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    end)

    lib.notify({ description = 'Admin đã gán ped "' .. pedModel .. '" cho bạn', type = 'inform' })
end)

-- Event: Thông báo chung từ server
RegisterNetEvent('qbx_housing:client:notify', function(msg, notifyType)
    lib.notify({ description = msg, type = notifyType or 'inform' })
end)

-- Event: Admin capture ped data từ target player
RegisterNetEvent('qbx_housing:client:capturePedData', function(adminSource, pedModel)
    local ped = PlayerPedId()
    local comps = {}
    local texs = {}
    
    -- Capture current components
    for i = 0, 11 do
        comps[i] = GetPedDrawableVariation(ped, i)
        texs[i] = GetPedTextureVariation(ped, i)
    end
    
    -- Thay đổi model trước rồi mới gửi data
    local model = GetHashKey(pedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    -- Reset components cho model mới (mặc định)
    ped = PlayerPedId()
    local newComps = {}
    local newTexs = {}
    for i = 0, 11 do
        newComps[i] = GetPedDrawableVariation(ped, i)
        newTexs[i] = GetPedTextureVariation(ped, i)
    end
    
    -- Clear props
    for i = 0, 2 do ClearPedProp(ped, i) end
    ClearPedProp(ped, 6) ; ClearPedProp(ped, 7)
    
    -- Get citizenid
    local QBX = exports.qbx_core
    local player = QBX:GetPlayerData()
    local citizenid = player.citizenid
    
    -- Send to server
    TriggerServerEvent('qbx_housing:server:receivePedData', adminSource, citizenid, pedModel, newComps, newTexs)
end)

-- Đồng bộ Level Trụ Sở Xã Đoàn từ Server
RegisterNetEvent('qbx_housing:client:syncGangHouseLevel', function(houseId, newLevel, newInterior, newStorage)
    for _, h in ipairs(allHouses) do
        if h.id == houseId then
            h.level = newLevel
            if newInterior then
                h.interior = newInterior
            end
            if newStorage then
                h.storagePoint = newStorage
            end
            break
        end
    end
    
    -- Nếu người chơi đang ở trong ngôi nhà này, teleport sang interior mới và recreate zones ngay lập tức
    if currentHouse and currentHouse == houseId and inHouse then
        local houseConfig = GetHouseConfigClient(houseId)
        if houseConfig then
            DoScreenFadeOut(500)
            Wait(500)
            SetEntityCoords(PlayerPedId(), houseConfig.interior.x, houseConfig.interior.y, houseConfig.interior.z)
            local heading = houseConfig.interior.w or houseConfig.interior.h or 0.0
            if heading and heading ~= 0.0 then
                SetEntityHeading(PlayerPedId(), heading)
            end
            CreateExitPoint(houseId)
            Wait(500)
            DoScreenFadeIn(500)
        end
    end
end)