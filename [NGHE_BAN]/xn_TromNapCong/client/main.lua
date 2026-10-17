local Inzone = false
local hasTarget = false
local targetName = "Trom_Nap_Cong"


CreateThread(function()
    lib.zones.poly({
        name = 'Trom_Nap_Cong',
        points = {
            vec3(-621.0, -461.0, 15.0), vec3(-654.0, -1487.0, 15.0),
            vec3(494.0, -1434.0, 15.0), vec3(484.0, -299.0, 15.0),
            vec3(482.0, -301.0, 15.0)
        },
        thickness = 200.0,
        onEnter = function(self) Inzone = true end,
        onExit = function(self) Inzone = false end
    })
end)

function Check_Ground()
    local pPed = PlayerPedId()
    local coords = GetEntityCoords(pPed)
    local handle = StartShapeTestRay(coords.x, coords.y, coords.z, coords.x,
                                     coords.y, coords.z - 2.0, 339, pPed, 0)
    local _, _, _, _, materialHash = GetShapeTestResultIncludingMaterial(handle)
    local materialName = nil
    return materialHash
end

RegisterNetEvent('1307_TromNapCong:client:Xa_Beng', function()
    local numCops = GlobalState['police_count'] or 0
    if numCops < Config.Cops then
        return exports.qbx_core:Notify("Không đủ cảnh sát (Cần " ..Config.Cops .. " trở lên)", "error")
    end
    if Check_Ground() ~= -754997699 then
        return exports.qbx_core:Notify("Bạn không ở dưới nắp cống", "error")
    end
    if IsInVehicle() then
        return exports.qbx_core:Notify("Vui lòng xuống xe!", "error")
    end
    if not Inzone then
        return exports.qbx_core:Notify("Bạn không thể trộm nắp cống ở đây, hãy về Thành Phố", "error")
    end
    Trom_Nap_Cong()
end)

function Trom_Nap_Cong()
    -- Server sẽ check atomic (chống race condition)
    local canRob = lib.callback.await('1307_TromNapCong:sv:CheckCanRob', 2000)
    if not canRob then return end
    local canRob_2 = lib.callback.await(
                         '1307_TromNapCong:sv:CheckCanRob_Failed', 2000)
    if not canRob_2 then return end
    LockpickAnim()
    TriggerServerEvent('hud:server:GainStress', 0.5)
    --TriggerServerEvent('1307_TromNapCong:server:active_only_player')
    lockpickDone()
end

function IsInVehicle()
    local ply = PlayerPedId()
    if IsPedSittingInAnyVehicle(ply) then
        return true
    else
        return false
    end
end

function lockpickDone(success)
    local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'hard'}, {'w', 'a', 's', 'd'})
    if success then
       PoliceCall()
        TriggerEvent('mini-mdt:client:setCooldown', 30, "Bị cấm vào Red Zone do vừa trong tình huống phó bản khác")
        local result = lib.progressCircle({
            duration = Config.ThoiGianThanh,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {move = true, car = true, combat = true, mouse = false},
            label = 'Đang trộm nắp cống...',
            anim = {
                dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                clip = 'machinic_loop_mechandplayer',
                flag = 76,
            },
        })

        TriggerServerEvent('1307_TromNapCong:server:Reset_Only')
        if result then
            TriggerServerEvent('1307_TromNapCong:server:1I1i01I1')
            TriggerServerEvent('1307_TromNapCong:server:Reset_Only')
            timer = 300
            -- exports.loadscript:TriggerServerEvent(
            --     '1307_DevMode:cb:ActiveRemoveDurability', 'advancedlockpick')
            OpeningSomething = false
        else
            OpeningSomething = false
        end
    else
        OpeningSomething = false
        TriggerServerEvent('1307_TromNapCong:server:delay_failed')
        TriggerServerEvent('1307_TromNapCong:server:Reset_Only')
    end
end

function LockpickAnim(time)
    time = (time or 999999999) / 1000
    local playerPed = PlayerPedId()
    OpeningSomething = true
    -- Đã tắt vòng lặp tăng stress
    -- CreateThread(function()
    --     while OpeningSomething do
    --         TriggerServerEvent('hud:server:GainStress', 1)
    --         time = time - 2
    --         if time <= 0 then
    --             OpeningSomething = false
    --         end
    --         Wait(2000)
    --     end
    -- end)
end

function PoliceCall()
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    exports['ld-dispatch']:sendDispatch(
        {
            title = "TRỘM NẮP CỐNG",
            code = "11-10B",
            values = {
                {
                    text = "Nắp cống",
                    icon = "fa-solid fa-earth-americas",
                },
                {
                    text = "2 sao",
                    icon = "fa-solid fa-hashtag",
                },
            },
            valuestwo = {}, -- DON'T TOUCH
            jobs = {"police"},
            active = false,-- DON'T TOUCH
            dispatchnumber = nil,-- DON'T TOUCH
            coords = plyCoords,
            blip = {
                blipid = 171,
                blipcolor = 1,
            }
        }
    ) 
end

-- Điểm bán nắp cống
-- Tạo Blip
-- local blip = AddBlipForCoord(Config.ViTriBan.coords.x, Config.ViTriBan.coords.y, Config.ViTriBan.coords.z)
-- SetBlipSprite(blip, 256)
-- SetBlipDisplay(blip, 4)
-- SetBlipScale(blip, 0.8)
-- SetBlipColour(blip, 2)
-- SetBlipAsShortRange(blip, true)
-- BeginTextCommandSetBlipName("STRING")
-- AddTextComponentString("Bán nắp cống")
-- EndTextCommandSetBlipName(blip)

-- Tạo Ped
local pedModel = lib.requestModel(`a_m_y_hippy_01`)
local ped = CreatePed(4, pedModel, Config.ViTriBan.coords.x, Config.ViTriBan.coords.y, Config.ViTriBan.coords.z - 1, Config.ViTriBan.coords.w, false, true)
FreezeEntityPosition(ped, true)
SetEntityInvincible(ped, true)
SetBlockingOfNonTemporaryEvents(ped, true)
SetModelAsNoLongerNeeded(pedModel)

-- Target zone
exports.ox_target:addSphereZone({
    coords = vec3(Config.ViTriBan.coords.x, Config.ViTriBan.coords.y, Config.ViTriBan.coords.z),
    radius = 1.5,
    options = {
        {
            name = "ban_nap_cong",
            event = "1307_TromNapCong:client:BanNapCong",
            icon = "fas fa-hand-holding-usd",
            label = "Bán Nắp Cống",
            distance = 2.5
        },
    }
})

RegisterNetEvent('1307_TromNapCong:client:BanNapCong', function()
    if IsInVehicle() then
        return exports.qbx_core:Notify("Vui lòng xuống xe!", "error")
    end
    
    lib.callback.await('1307_TromNapCong:sv:BanNapCong', false)
end)

