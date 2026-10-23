local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()

Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        Citizen.Wait(amount)
    end
end)

DATA = {}
LOC = {}
ACTIVE = false
LOCCLOSETO = 0
NPC = {}
BLIPS = {}
POPUP = false

local function createLocationBlip(v)
    if not v.Blip or not v.Blip.Enable then return end

    local coords = v.Coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, v.Blip.Sprite or 356)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, v.Blip.Scale or 0.7)
    SetBlipColour(blip, v.Blip.Color or 11)
    SetBlipAsShortRange(blip, v.Blip.ShortRange == true)
    SetBlipHighDetail(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(v.Blip.Label or v.NPCText or 'Thu mua')
    EndTextCommandSetBlipName(blip)

    BLIPS[#BLIPS + 1] = blip
end

Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end

    Citizen.Wait(500)
    Citizen.Wait(3000)
    
    TriggerServerEvent('xn-sellitem:requestAllItems')
    Citizen.Wait(1000)
    TriggerServerEvent('xn-sellitem:cfx:getPrices')
    
    Citizen.Wait(1000)
    if not DATA or next(DATA) == nil then
        TriggerServerEvent('xn-sellitem:cfx:getPrices')
        Citizen.Wait(1000)
    end

    InitEnvironment()
    InitLoop()
end)

function InitEnvironment()
    for k, v in pairs(Config.Locations) do
        createLocationBlip(v)
    end
end

function InitLoop()
    LOC = {}
    for k, v in pairs(Config.Locations) do
        table.insert(LOC, {
            Coords = v.Coords,
            Items = v.Items,
            ExtraItems = v.ExtraItems,
            NPCText = v.NPCText
        })
    end

    Citizen.CreateThread(function()
        while true do
            local sleep = 500
            if not ACTIVE then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                for k, v in pairs(LOC) do
                    local dist = GetDistanceBetweenCoords(coords, v.Coords, true)
                    if dist <= 5.0 then
                        sleep = 0
                        DrawText3D(v.Coords.x, v.Coords.y, v.Coords.z + 0.8, "~b~" .. (v.NPCText or 'Thu mua'), 1.2, 1)
                        DrawText3D(v.Coords.x, v.Coords.y, v.Coords.z + 0.6, "~w~Có gì muốn bán không?", 1.0, 1)
                    end
                end
            end
            Citizen.Wait(sleep)
        end
    end)
end

Citizen.CreateThread(function()
    for k, v in pairs(Config.Locations) do
        exports.ox_target:addBoxZone({
            coords = vec3(v.Coords.x, v.Coords.y, v.Coords.z),
            size = vec3(2.0, 2.0, 2.0),
            rotation = v.Coords.w or 0,
            debug = false,
            options = {
                {
                    name = v.TargetName .. '_talk',
                    event = 'xn-sellitem:client:tuong_tac',
                    icon = 'fas fa-store',
                    label = 'Nói chuyện',
                    distance = 2.0,
                    locationIndex = k
                },
                {
                    name = v.TargetName .. '_hide',
                    icon = 'fa-solid fa-comment',
                    label = 'Tâm sự mỏng',
                    items = 'note_1',
                    onSelect = function()
                        Action_TuongTac_Hide()
                    end,
                    distance = 2.0
                }
            }
        })
    end
end)

function Action_TuongTac_Hide()
    QBCore.Functions.TriggerCallback('xn-sellitem:server:nCheckItem', function(hasGoiY)
        if hasGoiY then
            SetNewWaypoint(386.13, 423.68, 144.2)
            TriggerServerEvent("dt-useitem:server:RemoveItem", "note_1", 1)
            TriggerServerEvent("dt-useitem:server:RemoveItem", "note_3", 1)
            QBCore.Functions.Notify('Sau khi tâm sự mỏng Người Thu Mua đã định vị cho bạn một vị trí ẩn trên bản đồ', "success", 3500)
        else
            QBCore.Functions.Notify('Cần phải có [Mảnh giấy (Số 1) và Mảnh giấy (Số 3)]', "error", 3500)
        end
    end)
end

RegisterNetEvent("xn-sellitem:client:tuong_tac")
AddEventHandler("xn-sellitem:client:tuong_tac", function(data)
    ACTIVE = true
    local locIdx = type(data) == 'table' and data.locationIndex or nil
    OpenOrRefreshUI(locIdx)
end)

function DrawText3D(x,y,z, text, scl, font) 
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*scl
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
   
    if onScreen then
        SetTextScale(0.0*scale, 1.1*scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

function OpenOrRefreshUI(locIdx)
    if not DATA or next(DATA) == nil then
        TriggerServerEvent('xn-sellitem:cfx:getPrices')
        Citizen.Wait(500)
    end
    
    if locIdx and LOC[locIdx] then
        LOCCLOSETO = locIdx
    end

    if not LOCCLOSETO or LOCCLOSETO == 0 or not LOC[LOCCLOSETO] then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local minDistance = 999.0
        local closestIndex = 0
        for k, v in pairs(LOC) do
            if v and v.Coords then
                local dist = GetDistanceBetweenCoords(coords, v.Coords.x, v.Coords.y, v.Coords.z, true)
                if dist < minDistance then
                    minDistance = dist
                    closestIndex = k
                end
            end
        end
        if closestIndex ~= 0 and minDistance < 20.0 then
            LOCCLOSETO = closestIndex
        else
            LOCCLOSETO = 1
        end
    end
    
    QBCore.Functions.TriggerCallback('xn-sellitem:server:getInv', function(serverInv)
        local inventory = {}
        local PlyInv = serverInv or {}
        
        if not LOC[LOCCLOSETO] or not LOC[LOCCLOSETO].Items then
            for k, v in pairs(LOC) do
                if v and v.Items then
                    LOCCLOSETO = k
                    break
                end
            end
        end

        local currentLoc = LOC[LOCCLOSETO] or LOC[1]
        local locItems = Config.GetLocationItems(currentLoc)
        local locText = (currentLoc and currentLoc.NPCText) or 'Thu mua'

        for itemName, amount in pairs(PlyInv) do
            if locItems[itemName] then
                local amt = tonumber(amount) or 0
                if amt > 0 then
                    inventory[itemName] = amt
                end
            end
        end
        
        SendNUIMessage({
            type = 'open',
            items = locItems,
            inventory = inventory,
            npcText = locText
        })
        
        SendNUIMessage({
            type = 'set-price',
            data = DATA or {}
        })

        SetNuiFocus(true, true)
        TriggerScreenblurFadeIn()
        LocalPlayer.state:set("inv_busy", true, true)
    end)
end

function tableLength(T)
    if not T then return 0 end
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Function để tổ chức lại dữ liệu theo danh mục
local function OrganizeDataByCategory()
    local organizedData = {}
    
    -- Tự động khởi tạo categories từ Config.Items
    if Config and Config.Items then
        for category, items in pairs(Config.Items) do
            if type(items) == 'table' then
                organizedData[category] = {}
                
                -- Map items với categories
                for itemName, _ in pairs(items) do
                    if DATA and DATA[itemName] then
                        organizedData[category][itemName] = DATA[itemName]
                    end
                end
            end
        end
    end
    
    return organizedData
end

local rouletteSellTable, rouletteSellPed, rouletteSellBall, rouletteSellCam = nil, nil, nil, nil
local rouletteSellSpawned, activeRouletteSale = false, nil
local roulettePositions = { 30, 11, 26, 7, 22, 3, 18, 37, 14, 33, 17, 36, 29, 10, 25, 6, 21, 2, 38, 19, 4, 23, 8, 27, 34, 15, 32, 13, 35, 16, 1, 20, 5, 24, 9, 28, 12, 31 }

local function FormatMoney(amount)
    local formatted = tostring(math.floor(tonumber(amount) or 0))
    while true do
        local k
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function CloseSellerUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    TriggerScreenblurFadeOut()
    ACTIVE = false
    LocalPlayer.state:set("inv_busy", false, true)
end

local function GetRouletteSellCoords()
    return Config.RouletteSell and Config.RouletteSell.TableCoords
end

local function DeleteRouletteSellTable()
    if rouletteSellBall and DoesEntityExist(rouletteSellBall) then DeleteEntity(rouletteSellBall) end
    if rouletteSellTable and DoesEntityExist(rouletteSellTable) then DeleteObject(rouletteSellTable) end
    if rouletteSellPed and DoesEntityExist(rouletteSellPed) then DeleteEntity(rouletteSellPed) end
    rouletteSellBall, rouletteSellTable, rouletteSellPed = nil, nil, nil
    rouletteSellSpawned = false
end

local function IdleRouletteSellDealer()
    if not rouletteSellPed or not DoesEntityExist(rouletteSellPed) then return end
    lib.requestAnimDict('anim_casino_b@amb@casino@games@roulette@dealer_female')
    TaskPlayAnim(rouletteSellPed, 'anim_casino_b@amb@casino@games@roulette@dealer_female', 'idle_var01', 1.0, 1.0, -1, 1, 0.0, false, false, false)
end

local function SetupRouletteSellTable()
    if rouletteSellSpawned then return true end
    if not Config.RouletteSell or not Config.RouletteSell.Enable then return false end

    local coords = GetRouletteSellCoords()
    if not coords then return false end

    lib.requestModel(`vw_prop_casino_roulette_01b`)
    lib.requestModel(`s_f_y_casino_01`)

    rouletteSellTable = CreateObject(`vw_prop_casino_roulette_01b`, coords.x, coords.y, coords.z, false, true, false)
    SetEntityHeading(rouletteSellTable, coords.w)
    FreezeEntityPosition(rouletteSellTable, true)

    local pedCoordsX = -0.1 * Cos(coords.w) - 0.6 * Sin(coords.w)
    local pedCoordsY = -0.1 * Sin(coords.w) + 0.6 * Cos(coords.w)
    rouletteSellPed = CreatePed(26, `s_f_y_casino_01`, coords.x + pedCoordsX, coords.y + pedCoordsY, coords.z, coords.w - 180.0, false, true)
    SetEntityCanBeDamaged(rouletteSellPed, false)
    SetPedAsEnemy(rouletteSellPed, false)
    SetBlockingOfNonTemporaryEvents(rouletteSellPed, true)
    SetPedCanRagdollFromPlayerImpact(rouletteSellPed, false)
    SetPedDefaultComponentVariation(rouletteSellPed)
    IdleRouletteSellDealer()

    SetModelAsNoLongerNeeded(`vw_prop_casino_roulette_01b`)
    SetModelAsNoLongerNeeded(`s_f_y_casino_01`)

    rouletteSellSpawned = true
    return true
end

local function DestroyRouletteSellCam()
    if rouletteSellCam then
        RenderScriptCams(false, false, 0, true, false)
        SetCamActive(rouletteSellCam, false)
        DestroyCam(rouletteSellCam, false)
        rouletteSellCam = nil
    end
end

local function CreateRouletteSellCam()
    DestroyRouletteSellCam()

    local coords = GetRouletteSellCoords()
    if not coords then return end

    rouletteSellCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z + 2.35, -70.0, 0.0, coords.w, 48.0, false, 2)
    if rouletteSellTable and DoesEntityExist(rouletteSellTable) then
        local wheelCoords = GetEntityBonePosition_2(rouletteSellTable, GetEntityBoneIndexByName(rouletteSellTable, 'Roulette_Wheel'))
        PointCamAtCoord(rouletteSellCam, wheelCoords.x, wheelCoords.y, wheelCoords.z)
    else
        PointCamAtCoord(rouletteSellCam, coords.x, coords.y, coords.z + 1.0)
    end
    SetCamActive(rouletteSellCam, true)
    RenderScriptCams(true, false, 0, true, false)
end

local function CleanupRouletteSellSession()
    lib.hideTextUI()
    DestroyRouletteSellCam()
    FreezeEntityPosition(PlayerPedId(), false)
    activeRouletteSale = nil
end

local function WaitForEntityAnim(entity, dict, anim, targetTime, timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 10000)
    while DoesEntityExist(entity) and GetEntityAnimCurrentTime(entity, dict, anim) < targetTime and GetGameTimer() < deadline do
        Wait(0)
    end
end

CreateThread(function()
    while true do
        local sleep = 1000
        if Config.RouletteSell and Config.RouletteSell.Enable and GetRouletteSellCoords() then
            local coords = GetRouletteSellCoords()
            local playerCoords = GetEntityCoords(PlayerPedId())
            local tableCoords = vector3(coords.x, coords.y, coords.z)
            local distance = #(playerCoords - tableCoords)

            if distance <= 40.0 and not rouletteSellSpawned then
                SetupRouletteSellTable()
            elseif distance >= 100.0 and rouletteSellSpawned and not activeRouletteSale then
                DeleteRouletteSellTable()
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('xn-sellitem:client:rouletteStart', function(data)
    CloseSellerUI()

    if not SetupRouletteSellTable() then
        exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:roulette-cancel")
        QBCore.Functions.Notify("Không thể khởi tạo bàn roulette", "error")
        return
    end

    activeRouletteSale = data
    local coords = GetRouletteSellCoords()
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, true)
    TaskTurnPedToFaceCoord(ped, coords.x, coords.y, coords.z, 1000)
    CreateRouletteSellCam()

    local timeout = tonumber(data.timeout) or 30
    local expiresAt = GetGameTimer() + (timeout * 1000)
    lib.showTextUI(string.format('[E] Đỏ  \n[G] Đen  \n[Backspace] Hủy  \n%s x%d | cược: $%s | thắng x%s', data.label or data.item, data.amount or 0, FormatMoney(data.basePrice), data.multiplier or 2))

    CreateThread(function()
        while activeRouletteSale == data and GetGameTimer() < expiresAt do
            if IsControlJustReleased(0, 38) then
                lib.hideTextUI()
                QBCore.Functions.Notify("Bạn đã chọn Đỏ. Đang quay roulette...", "primary")
                exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:roulette-choice", 'red')
                return
            elseif IsControlJustReleased(0, 47) then
                lib.hideTextUI()
                QBCore.Functions.Notify("Bạn đã chọn Đen. Đang quay roulette...", "primary")
                exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:roulette-choice", 'black')
                return
            elseif IsControlJustReleased(0, 202) then
                exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:roulette-cancel")
                CleanupRouletteSellSession()
                QBCore.Functions.Notify("Đã hủy lượt roulette bán hàng", "primary")
                return
            end
            Wait(0)
        end

        if activeRouletteSale == data then
            exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:roulette-cancel")
            CleanupRouletteSellSession()
            QBCore.Functions.Notify("Lượt roulette đã hết thời gian chọn", "error")
        end
    end)
end)

RegisterNetEvent('xn-sellitem:client:rouletteAbort', function(message)
    CleanupRouletteSellSession()
    if message then
        QBCore.Functions.Notify(message, "error")
    end
end)

RegisterNetEvent('xn-sellitem:client:rouletteResult', function(data)
    SetupRouletteSellTable()
    CreateRouletteSellCam()

    if rouletteSellPed and rouletteSellTable and DoesEntityExist(rouletteSellPed) and DoesEntityExist(rouletteSellTable) then
        lib.requestAnimDict('anim_casino_b@amb@casino@games@roulette@dealer_female')
        TaskPlayAnim(rouletteSellPed, 'anim_casino_b@amb@casino@games@roulette@dealer_female', 'no_more_bets', 1.0, 1.0, -1, 0, 0.0, false, false, false)
        PlayPedAmbientSpeechNative(rouletteSellPed, 'MINIGAME_DEALER_CLOSED_BETS', 'SPEECH_PARAMS_STANDARD')
        Wait(GetAnimDuration('anim_casino_b@amb@casino@games@roulette@dealer_female', 'no_more_bets') * 1000)

        TaskPlayAnim(rouletteSellPed, 'anim_casino_b@amb@casino@games@roulette@dealer_female', 'spin_wheel', 1.0, 1.0, -1, 0, 0.0, false, false, false)
        lib.requestModel(`vw_prop_roulette_ball`)

        local wheelCoords = GetEntityBonePosition_2(rouletteSellTable, GetEntityBoneIndexByName(rouletteSellTable, 'Roulette_Wheel'))
        rouletteSellBall = CreateObjectNoOffset(`vw_prop_roulette_ball`, wheelCoords.x, wheelCoords.y, wheelCoords.z, false, false, false)
        SetModelAsNoLongerNeeded(`vw_prop_roulette_ball`)
        SetEntityHeading(rouletteSellBall, GetEntityHeading(rouletteSellTable))

        lib.requestAnimDict('anim_casino_b@amb@casino@games@roulette@table')
        PlayEntityAnim(rouletteSellBall, 'intro_ball', 'anim_casino_b@amb@casino@games@roulette@table', 1000.0, false, true, false, 0, 136704)
        PlayEntityAnim(rouletteSellTable, 'intro_wheel', 'anim_casino_b@amb@casino@games@roulette@table', 1000.0, false, true, false, 0, 136704)

        WaitForEntityAnim(rouletteSellPed, 'anim_casino_b@amb@casino@games@roulette@dealer_female', 'spin_wheel', 0.99, 10000)
        IdleRouletteSellDealer()
        WaitForEntityAnim(rouletteSellTable, 'anim_casino_b@amb@casino@games@roulette@table', 'intro_wheel', 0.99, 12000)

        local result = tonumber(data.result) or 1
        SetEntityCoords(rouletteSellBall, wheelCoords.x, wheelCoords.y, wheelCoords.z, false, false, false, false)
        local wheelRot = GetEntityBoneRotationLocal(rouletteSellTable, GetEntityBoneIndexByName(rouletteSellTable, 'Roulette_Wheel'))
        SetEntityRotation(rouletteSellBall, 0.0, 0.0, wheelRot.z + GetEntityHeading(rouletteSellTable), 2, false)
        PlayEntityAnim(rouletteSellBall, string.format('exit_%s_ball', roulettePositions[result]), 'anim_casino_b@amb@casino@games@roulette@table', 1000.0, false, true, false, 0, 136704)
        PlayEntityAnim(rouletteSellTable, string.format('exit_%s_wheel', roulettePositions[result]), 'anim_casino_b@amb@casino@games@roulette@table', 1000.0, false, true, false, 0, 136704)

        Wait(7500)
        PlayPedAmbientSpeechNative(rouletteSellPed, string.format('minigame_roulette_ball_%s', result), 'SPEECH_PARAMS_STANDARD')
        Wait(1500)
    end

    if rouletteSellBall and DoesEntityExist(rouletteSellBall) then DeleteEntity(rouletteSellBall) end
    rouletteSellBall = nil

    CleanupRouletteSellSession()
    exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:roulette-finished")
end)

RegisterNetEvent('xn-sellitem:client:roulettePayout', function(data)
    local chosenLabel = data.chosen == 'red' and 'Đỏ' or 'Đen'
    local colorLabel = data.resultColor == 'red' and 'Đỏ' or data.resultColor == 'black' and 'Đen' or '0/00'
    if data.win then
        QBCore.Functions.Notify(string.format("Roulette ra %s (%s). Bạn thắng x%s và nhận $%s", data.resultLabel, colorLabel, data.multiplier or 2, FormatMoney(data.reward)), "success", 7000)
    else
        QBCore.Functions.Notify(string.format("Roulette ra %s (%s). Bạn chọn %s và mất tiền bán lượt này", data.resultLabel, colorLabel, chosenLabel), "error", 7000)
    end
end)

RegisterNetEvent('xn-sellitem:setPrices')
AddEventHandler('xn-sellitem:setPrices', function(data)
    -- print("^2[SELLITEM]^7 Received prices from server, items:", data and tableLength(data) or 0)
    DATA = data

    -- Gửi đến NUI ngay khi nhận được
    SendNUIMessage({
        type = 'set-price',
        data = DATA
    })
    
    -- print("^2[SELLITEM]^7 Prices sent to NUI")
end)

RegisterNetEvent('xn-sellitem:update')
AddEventHandler('xn-sellitem:update', function(item, data)
    DATA[item] = data
    
    -- print("^3[SELLITEM]^7 Price updated for "..item..": $"..data.Price.." ("..data.Status..")")

    SendNUIMessage({
        type = 'update',
        item = item,
        data = data
    })
    
    -- Gửi update cho phone app (organized by category)
    SendNUIMessage({
        type = 'updatePrices',
        prices = OrganizeDataByCategory()
    })
end)


-- NUI Callback để lấy giá thị trường cho phone app
RegisterNUICallback('getMarketPrices', function(data, cb)
    ---- print('[xn-sellitem] getMarketPrices called')
    
    -- Nếu chưa có DATA, request từ server
    if not DATA or next(DATA) == nil then
        ---- print('[xn-sellitem] DATA is empty, requesting from server')
        TriggerServerEvent('xn-sellitem:cfx:getPrices')
        
        -- Đợi một chút để server gửi dữ liệu
        Citizen.SetTimeout(500, function()
            local organizedData = OrganizeDataByCategory()
            ---- print('[xn-sellitem] Returning organized data:', json.encode(organizedData))
            -- Không dùng SendNUIMessage vì nó gửi sai target
            -- Data sẽ được trả qua callback response
        end)
        cb({ success = false, message = 'Loading...' })
    else
        -- Tổ chức dữ liệu theo danh mục
        local organizedData = OrganizeDataByCategory()
        ---- print('[xn-sellitem] Returning organized data:', json.encode(organizedData))
        
        -- Trả dữ liệu và tên categories từ config
        cb({ 
            success = true, 
            prices = organizedData,
            categoryNames = Config.CategoryNames or {}
        })
    end
end)

--
-- @nui
--

-- @router /action
-- @desc On Player Click Button Sell Item
RegisterNUICallback('action', function(data, cb)
    local PlayerCoords = GetEntityCoords(PlayerPedId())
    local item = data.item
    local amount = tonumber(data.amount)
    
    ---- print("^3[CLIENT SELLITEM]^7 Player trying to sell:", item, "amount:", amount)
    
    -- Kiểm tra nếu đang ở gần một trong các NPC
    local nearNPC = false
    for k, v in pairs(Config.Locations) do
        local distance = GetDistanceBetweenCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, v.Coords.x, v.Coords.y, v.Coords.z, true)
        ---- print("^3[CLIENT SELLITEM]^7 Distance to", v.TargetName, ":", distance)
        
        if distance < 5.0 then -- Tăng khoảng cách từ 3 lên 5 để dễ dàng hơn
            nearNPC = true
            ---- print("^2[CLIENT SELLITEM]^7 Player is near NPC, sending to server")
            exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:action", item, amount)
            -- Refresh UI sau khi bán
            Citizen.SetTimeout(1000, function()
                OpenOrRefreshUI()
            end)
            break
        end
    end
    
    if not nearNPC then
        ---- print("^1[CLIENT SELLITEM]^7 Player not near any NPC")
        QBCore.Functions.Notify("Bạn phải đứng gần Người Thu Mua để bán hàng", "error")
    end
    
    cb('ok')
end)

RegisterNUICallback('action-all', function(data, cb)
    local PlayerCoords = GetEntityCoords(PlayerPedId())
    local item = data.item
    
    ---- print("^3[CLIENT SELLITEM]^7 Player trying to sell all:", item)
    
    -- Kiểm tra nếu đang ở gần một trong các NPC
    local nearNPC = false
    for k, v in pairs(Config.Locations) do
        local distance = GetDistanceBetweenCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, v.Coords.x, v.Coords.y, v.Coords.z, true)
        ---- print("^3[CLIENT SELLITEM]^7 Distance to", v.TargetName, ":", distance)
        
        if distance < 5.0 then -- Tăng khoảng cách từ 3 lên 5 để dễ dàng hơn
            nearNPC = true
            ---- print("^2[CLIENT SELLITEM]^7 Player is near NPC, sending to server")
            exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:action-all", item)
            -- Refresh UI sau khi bán
            Citizen.SetTimeout(1000, function()
                OpenOrRefreshUI()
            end)
            break
        end
    end
    
    if not nearNPC then
        ---- print("^1[CLIENT SELLITEM]^7 Player not near any NPC")
        QBCore.Functions.Notify("Bạn phải đứng gần Người Thu Mua để bán hàng", "error")
    end
    
    cb('ok')
end)

RegisterNUICallback('roulette-action-all', function(data, cb)
    local PlayerCoords = GetEntityCoords(PlayerPedId())
    local item = data.item

    local nearNPC = false
    for k, v in pairs(Config.Locations) do
        local distance = GetDistanceBetweenCoords(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, v.Coords.x, v.Coords.y, v.Coords.z, true)
        if distance < 5.0 then
            nearNPC = true
            exports['monitors']:TriggerProtectedServerEvent("xn-sellitem:cfx:roulette-action-all", item)
            break
        end
    end

    if not nearNPC then
        QBCore.Functions.Notify("Bạn phải đứng gần Người Thu Mua để bán hàng", "error")
    end

    cb('ok')
end)

-- @router /close
-- @desc On player will close the window
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
    TriggerScreenblurFadeOut()
    ACTIVE = false
    LocalPlayer.state:set("inv_busy", false, true) -- Busy
    cb('ok')
end)

-- @on script disable
AddEventHandler('onResourceStop', function(resource)
    if resource == 'xn-sellitem' then
        CleanupRouletteSellSession()
        DeleteRouletteSellTable()
        for _, v in pairs(NPC) do
            DeletePed(v)
            DeleteEntity(v)
        end
        for _, blip in ipairs(BLIPS) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)

-- ========================================
-- ADMIN SHOP MANAGEMENT CLIENT SIDE
-- ========================================

-- Mở admin menu
RegisterNetEvent('xn-sellitem:client:openAdminMenu', function()
    -- print('^3[ADMIN CLIENT]^7 Opening admin menu...')
    QBCore.Functions.TriggerCallback('xn-sellitem:server:getAdminItems', function(items)
        -- print('^3[ADMIN CLIENT]^7 Received items:', json.encode(items))
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openAdminMenu',
            items = items
        })
        -- print('^3[ADMIN CLIENT]^7 NUI message sent')
    end)
end)

-- Đóng admin menu
RegisterNUICallback('closeAdminMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Cập nhật item config
RegisterNUICallback('updateItemConfig', function(data, cb)
    TriggerServerEvent('xn-sellitem:server:updateItemConfig', data)
    cb('ok')
end)

-- Tạo item mới
RegisterNUICallback('createItem', function(data, cb)
    -- print('^3[ADMIN CLIENT]^7 Creating new item:', data.itemName)
    TriggerServerEvent('xn-sellitem:server:createNewItem', data)
    cb('ok')
end)

-- Xóa item
RegisterNUICallback('deleteItem', function(data, cb)
    -- print('^3[ADMIN CLIENT]^7 Deleting item:', data.itemName, 'from category:', data.category)
    TriggerServerEvent('xn-sellitem:server:deleteItem', data)
    cb('ok')
end)

-- Refresh admin data sau khi update
RegisterNetEvent('xn-sellitem:client:refreshAdminData', function(items)
    -- print('^3[ADMIN CLIENT]^7 Refreshing admin data with', #items, 'items')
    SendNUIMessage({
        action = 'refreshAdminData',
        items = items
    })
end)

-- Sync item mới từ server (khi admin tạo item mới)
RegisterNetEvent('xn-sellitem:syncNewItem', function(category, itemName, itemData)
    -- print('^2[SELLITEM]^7 Syncing new item: ' .. itemName .. ' in category: ' .. category)
    
    -- Cập nhật Config.Items
    if not Config.Items[category] then
        Config.Items[category] = {}
    end
    
    Config.Items[category][itemName] = {
        Label = itemData.Label,
        Min = itemData.Min,
        Max = itemData.Max,
        RandomWhenStart = itemData.RandomWhenStart,
        RangeChange = itemData.RangeChange,
        AmountToChange = itemData.AmountToChange
    }
    
    -- Cập nhật LOC (locations) để item mới xuất hiện trong shop
    for k, location in pairs(Config.Locations) do
        -- Nếu location này bán items của category này
        if LOC[k] and (location.Items == Config.Items[category] or location.ExtraItems == Config.Items[category]) then
            -- Giữ cả hai bảng gốc; danh sách hiển thị được gộp khi mở menu.
            LOC[k].Items = location.Items
            LOC[k].ExtraItems = location.ExtraItems
            -- print('^2[SELLITEM]^7 Updated location: ' .. location.NPCText)
        end
    end
    
    -- print('^2[SELLITEM]^7 Item sync completed')
end)

-- Sync toàn bộ items từ server (khi player join hoặc restart resource)
RegisterNetEvent('xn-sellitem:syncAllItems', function(allItems)
    -- print('^2[SELLITEM]^7 Syncing all items from server...')
    
    local totalItems = 0
    
    -- Cập nhật toàn bộ Config.Items
    for category, items in pairs(allItems) do
        if not Config.Items[category] then
            Config.Items[category] = {}
        end
        
        for itemName, itemData in pairs(items) do
            Config.Items[category][itemName] = itemData
            totalItems = totalItems + 1
        end
        
        -- Cập nhật LOC cho category này (LOC đã được link với Config.Items từ đầu)
        -- Không cần update vì LOC[k].Items là reference trực tiếp đến Config.Items[category]
    end
    
    -- print('^2[SELLITEM]^7 All items synced! Total: ' .. totalItems .. ' items')
end)

-- Xóa item khỏi Config (khi admin xóa item)
RegisterNetEvent('xn-sellitem:removeItem', function(category, itemName)
    -- print('^1[SELLITEM]^7 Removing item: ' .. itemName .. ' from category: ' .. category)
    
    -- Xóa khỏi Config.Items
    if Config and Config.Items and Config.Items[category] and Config.Items[category][itemName] then
        Config.Items[category][itemName] = nil
        -- print('^1[SELLITEM]^7 Removed ' .. itemName .. ' from Config.Items[' .. category .. ']')
    end
    
    -- LOC đã tự động update vì Items là reference đến Config.Items[category]
    -- print('^1[SELLITEM]^7 LOC automatically updated (reference to Config.Items)')
    
    -- print('^1[SELLITEM]^7 Item removal completed')
end)
