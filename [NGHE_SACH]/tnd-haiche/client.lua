Keys = {
    ['ESC'] = 322, ['F1'] = 288, ['F2'] = 289, ['F3'] = 170, ['F5'] = 166, ['F6'] = 167, ['F7'] = 168, ['F8'] = 169, ['F9'] = 56, ['F10'] = 57,
    ['~'] = 243, ['1'] = 157, ['2'] = 158, ['3'] = 160, ['4'] = 164, ['5'] = 165, ['6'] = 159, ['7'] = 161, ['8'] = 162, ['9'] = 163, ['-'] = 84, ['='] = 83, ['BACKSPACE'] = 177,
    ['TAB'] = 37, ['Q'] = 44, ['W'] = 32, ['E'] = 38, ['R'] = 45, ['T'] = 245, ['Y'] = 246, ['U'] = 303, ['P'] = 199, ['['] = 39, [']'] = 40, ['ENTER'] = 18,
    ['CAPS'] = 137, ['A'] = 34, ['S'] = 8, ['D'] = 9, ['F'] = 23, ['G'] = 47, ['H'] = 74, ['K'] = 311, ['L'] = 182,
    ['LEFTSHIFT'] = 21, ['Z'] = 20, ['X'] = 73, ['C'] = 26, ['V'] = 0, ['B'] = 29, ['N'] = 249, ['M'] = 244, [','] = 82, ['.'] = 81,
    ['LEFTCTRL'] = 36, ['LEFTALT'] = 19, ['SPACE'] = 22, ['RIGHTCTRL'] = 70,
    ['HOME'] = 213, ['PAGEUP'] = 10, ['PAGEDOWN'] = 11, ['DELETE'] = 178,
    ['LEFT'] = 174, ['RIGHT'] = 175, ['TOP'] = 27, ['DOWN'] = 173,
}

local QBCore = exports['qb-core']:GetCoreObject()
local isHaiChe = false
local cooldowns = {}          -- cooldowns[k] = GetGameTimer() lúc hái xong
local currentHarvestIndex = nil

RegisterNetEvent('Nos-haiche:roHai') --rohai
AddEventHandler('Nos-haiche:roHai',function()  
    if isHaiCheArea() and isHaiChe == false then
		
		UseRoHai()
        
       -- return
    elseif isHaiChe == true then
		QBCore.Functions.Notify('Bạn đang hái chè rồi mà!', 'error')
	else
		QBCore.Functions.Notify('Bạn không thể sử dụng cái này ở đây!', 'error')
	end
    
end)

-------------------------------------------------OX_TARGET hái chè---------
for k, v in pairs(Config.ViTriHai["HaiChe"]) do
    exports.ox_target:addBoxZone({
        coords = vector3(v.x, v.y, v.z),
        size = vector3(1.5, 1.5, 2.0),
        rotation = 0,
        options = {
            {
                label = 'Hái Chè',
                icon = 'fas fa-leaf',
                onSelect = function()
                    if isHaiChe then
                        QBCore.Functions.Notify('Bạn đang hái chè rồi mà!', 'error')
                        return
                    end
                    local now = GetGameTimer()
                    if cooldowns[k] and (now - cooldowns[k]) < (Config.Cooldown * 1000) then
                        local remaining = math.ceil(((Config.Cooldown * 1000) - (now - cooldowns[k])) / 1000)
                        QBCore.Functions.Notify('Vị trí này cần chờ thêm ' .. remaining .. ' giây!', 'error')
                        return
                    end
                    currentHarvestIndex = k
                    TriggerServerEvent('Nos-haiche:server:startHarvest')
                end
            }
        }
    })
end

function isHaiCheArea()
    local PlayerPed = PlayerPedId()
    local PlayerPos = GetEntityCoords(PlayerPed)
        for k, v in pairs(Config.ViTriHai["HaiChe"]) do
            local dist = #(PlayerPos - vector3(v.x, v.y, v.z))
            if dist < 1.5 then
                return true
            else
                Citizen.Wait(100)
            end
        end
end

-- tắt tính năng rổ hái chè
-- RegisterNetEvent('Nos-haiche:client:dobenRoHai',function(slot)
--     TriggerServerEvent('qb-doben:server:RemoveItemQuality',math.random(1,1),"rodungche", slot)
-- end)



Citizen.CreateThread(function()
    blip = AddBlipForCoord(Config.BlipLocation)
    SetBlipSprite(blip, 683)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.BlipName)
    EndTextCommandSetBlipName(blip)
end)
function RequestAnimationDict(AnimDict)
    RequestAnimDict(AnimDict)
    while not HasAnimDictLoaded(AnimDict) do
        Citizen.Wait(1)
    end
end


function ResetAnimSet()
    ResetPedMovementClipset(PlayerPedId())
    ResetPedWeaponMovementClipset(PlayerPedId())
    ResetPedStrafeClipset(PlayerPedId())
end
function loadAnimDict(dict)
    while(not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(1)
    end
end
function UseRoHai()
    local ped = PlayerPedId()
    isHaiChe = true
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 8.5, "correct", 0.925)

    if Config.EnableMinigame then
        local success = lib.skillCheck({'easy', 'easy'}, {'w', 'a', 's', 'd'})
        if not success then
            QBCore.Functions.Notify('Thất bại', 'error')
            isHaiChe = false
            return
        end
    end

    local completed = lib.progressBar({
        duration = 10000,
        label = 'Đang hái...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
            move = true,
            car = true,
            mouse = true,
        },
        anim = {
            dict = 'amb@prop_human_bum_bin@base',
            clip = 'base',
            flag = 49,
        },
        prop = {
            model = 'prop_fruit_basket',
            bone = 28422,
            pos = vector3(-0.22, 0.05, -0.10),
            rot = vector3(160.0, 90.0, 125.0),
        },
    })

    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
    ResetAnimSet()
    ClearPedTasks(ped)
    isHaiChe = false

    if completed then
        if currentHarvestIndex then
            cooldowns[currentHarvestIndex] = GetGameTimer()
        end
        TriggerServerEvent('Nos-haiche:giveItems')
    else
        QBCore.Functions.Notify('Đã hủy.')
    end
end


function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
  end

