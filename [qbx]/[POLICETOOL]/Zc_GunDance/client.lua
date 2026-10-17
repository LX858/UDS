local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports['ox_lib']
local weather = nil
local time = nil
local inzone = false
local ped = nil
local coords = nil
local song = nil
local volume = 0.0
local songtime = 0
local playsound = false
local dancestart = false

Citizen.CreateThread(function()
    resrt()
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        aiming, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId(-1))
        for k, v in pairs(Config.Gun) do
            WaponHash = GetHashKey(v.Gunname)
            if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey(v.Gunname) then
                if not IsEntityAPed(targetPed) then
                    N_0x4757f00bc6323cfe(GetHashKey(v.Gunname), 0.00)
                else
                    N_0x4757f00bc6323cfe(GetHashKey(v.Gunname), 0.01)
                end
                TyreBust = v.TyreBust
                if TyreBust then
                    N_0x4757f00bc6323cfe(GetHashKey(v.Gunname), 0.01)
                end
            end
            if HasEntityBeenDamagedByWeapon(PlayerPedId(), WaponHash, 0) then
                if v.Dance then
                    ClearPedTasks(PlayerPedId())
                    Dance()
                    Stunt = v.Stunt
                end
                if v.Stunt then

                    effect = v.effect
                    Stunt = v.Stunt
                    Stunttime = v.Stunttime

                    if IsPedInAnyVehicle(PlayerPedId(), true) then
                        ClearPedTasksImmediately(PlayerPedId())
                        SetPedToRagdoll(PlayerPedId(), (Stunttime * 1000),
                                        (Stunttime * 1000), 0, 0, 0, 0)
                    end
                end
                ClearEntityLastDamageEntity(PlayerPedId())
            end
        end
    end
end)

TaskLeaveVehicle(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 0)
Citizen.CreateThread(function()
    while true do
        Wait(100)

        if Stunt then

            SetPedToRagdoll(PlayerPedId(), (Stunttime * 1000),
                            (Stunttime * 1000), 0, 0, 0, 0)

            Citizen.CreateThread(function()
                while Stunt do
                    Wait(5)
                    if IsPedBeingStunned(PlayerPedId()) then
                        SetPedToRagdoll(PlayerPedId(),
                                        (Stunttime * 1000) - 5000,
                                        (Stunttime * 1000) - 5000, 0, 0, 0, 0)
                    end
                end
            end)

            if effect then
                SetTimecycleModifier("REDMIST_blend")
                ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 1.0)
            end

            Wait(Stunttime * 1000)
            Stunt = false
            if effect then
                SetTimecycleModifier("")
                SetTransitionTimecycleModifier("")
                StopGameplayCamShaking()
            end
        end
    end
end)

function resrt()
    ClearEntityLastDamageEntity(PlayerPedId())
    SetTimecycleModifier("")
    SetTransitionTimecycleModifier("")
    StopGameplayCamShaking()
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
end
