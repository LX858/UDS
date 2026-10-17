local ClientCallbacks = {}
local CurrentRequestId = 0
if Config.FrameWork == "ESX" then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.FrameWork == "QBOX" or Config.FrameWork == "QBCORE" then 
    QBCore = exports['qb-core']:GetCoreObject()
end 

Citizen.CreateThread(function()
    if Config.FrameWork == "ESX" then
        while ESX == nil do
            Citizen.Wait(0) 
        end

        while ESX.GetPlayerData().job == nil do
            Citizen.Wait(10)
        end

        PlayerData = ESX.GetPlayerData()

        RegisterNetEvent('esx:setJob')
        AddEventHandler('esx:setJob', function(job)
            PlayerData.job = job
            PlayerJobName = job.name
            PlayerJobGrade = job.grade
        end)
        PlayerJobName = PlayerData.job.name
        PlayerJobGrade = PlayerData.job.grade

    elseif Config.FrameWork == "QBOX" or Config.FrameWork == "QBCORE" then
        while QBCore == nil do
            Citizen.Wait(0)
        end

        while QBCore.Functions.GetPlayerData().job == nil do
            Citizen.Wait(10)
        end

        PlayerData = QBCore.Functions.GetPlayerData()

        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            PlayerData.job = job
            PlayerJobName = job.name
            PlayerJobGrade = job.grade.level
        end)
        PlayerJobName = PlayerData.job.name
        PlayerJobGrade = PlayerData.job.grade.level
    end
end)

function TriggerServerCallback(name, cb, ...)
    CurrentRequestId = CurrentRequestId + 1
    ClientCallbacks[CurrentRequestId] = cb
    TriggerServerEvent('MClothes:triggerServerCallback', name, CurrentRequestId, ...)
end

RegisterNetEvent('MClothes:serverCallbackResponse', function(requestId, ...)
    if ClientCallbacks[requestId] then
        ClientCallbacks[requestId](...)
        ClientCallbacks[requestId] = nil
    end
end)


function ShowNotification(mes)
    if Config.FrameWork == "ESX" then
        ESX.ShowNotification(mes)
    elseif Config.FrameWork == "QBOX" then 
        QBCore.Functions.Notify(mes)
    end 
end

function ShowHelpNotification(msg)
    AddTextEntry("esxHelpNotification", msg)
    if thisFrame then
        DisplayHelpTextThisFrame("esxHelpNotification", false)
    else
        BeginTextCommandDisplayHelp("esxHelpNotification")
        EndTextCommandDisplayHelp(0, false, beep == nil or beep, duration or -1)
    end
end 

