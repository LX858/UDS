local shouldOpenCompose = false

-- Debug logging helper
local function DebugPrint(...)
    if Config.Debug then
        print(...)
    end
end

-- NUI Callbacks for communication with the phone UI
RegisterNUICallback('getAnnouncements', function(data, cb)
    DebugPrint("^3[xn_pdemstool] Client: getAnnouncements NUI Callback triggered^7")
    local announcements = lib.callback.await('xn_pdemstool:server:getAnnouncements', false)
    DebugPrint("^3[xn_pdemstool] Client: announcements received from server: " .. tostring(announcements and #announcements or 0) .. " items^7")
    cb(announcements or {})
end)

RegisterNUICallback('checkPermissions', function(data, cb)
    DebugPrint("^3[xn_pdemstool] Client: checking permissions...^7")
    local perm = lib.callback.await('xn_pdemstool:server:checkPermissions', false)
    
    if perm and perm.canPost then
        perm.openCompose = shouldOpenCompose
        shouldOpenCompose = false -- Reset state
    end
    
    DebugPrint("^3[xn_pdemstool] Client: permissions received: " .. json.encode(perm) .. "^7")
    cb(perm)
end)

RegisterNUICallback('postAnnouncement', function(data, cb)
    TriggerServerEvent('xn_pdemstool:server:postAnnouncement', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('deleteAnnouncement', function(data, cb)
    DebugPrint("^3[xn_pdemstool] Client: deleteAnnouncement NUI Callback triggered for ID: " .. tostring(data.id) .. "^7")
    local success = lib.callback.await('xn_pdemstool:server:deleteAnnouncement', false, data.id)
    cb(success)
end)


-- Listen for server event indicating a new announcement was posted
RegisterNetEvent('xn_pdemstool:client:refreshAnnouncements', function()
    -- Send message to the custom app's NUI
    exports["lb-phone"]:SendCustomAppMessage(Config.App.identifier, {
        action = "refresh"
    })
end)

-- Helper to retrieve current job and grade
local function GetPlayerJob()
    local playerData = exports.qbx_core:GetPlayerData()
    if playerData and playerData.job then
        local gradeLevel = 0
        if type(playerData.job.grade) == "table" then
            gradeLevel = tonumber(playerData.job.grade.level) or 0
        else
            gradeLevel = tonumber(playerData.job.grade) or 0
        end
        return playerData.job.name, playerData.job.onduty, gradeLevel
    end
    return nil, false, 0
end

-- Command /tbbn for police and EMS to post announcements quickly
RegisterCommand('tbbn', function()
    DebugPrint("^3[xn_pdemstool] /tbbn command triggered!^7")
    local jobName, onDuty, gradeLevel = GetPlayerJob()
    DebugPrint("^3[xn_pdemstool] Player Job: " .. tostring(jobName) .. " | Duty: " .. tostring(onDuty) .. " | Grade: " .. tostring(gradeLevel) .. "^7")

    local perm = Config.Permissions[jobName]
    if perm then
        DebugPrint("^3[xn_pdemstool] Perm config found. Min Grade required: " .. tostring(perm.minGrade) .. "^7")
        if gradeLevel >= perm.minGrade then
            DebugPrint("^2[xn_pdemstool] Permission passed! Opening app: " .. tostring(Config.App.identifier) .. "^7")
            shouldOpenCompose = true
            exports["lb-phone"]:OpenApp(Config.App.identifier)
            
            -- Immediate dispatch in case the app is already open
            exports["lb-phone"]:SendCustomAppMessage(Config.App.identifier, {
                action = "openCompose"
            })
        else
            DebugPrint("^1[xn_pdemstool] Permission failed: Grade too low!^7")
            lib.notify({
                title = 'Thông báo ban ngành',
                description = 'Bạn không có quyền sử dụng lệnh này! (Cấp bậc thấp)',
                type = 'error'
            })
        end
    else
        DebugPrint("^1[xn_pdemstool] Permission failed: Job config not found!^7")
        lib.notify({
            title = 'Thông báo ban ngành',
            description = 'Bạn không có quyền sử dụng lệnh này! (Sai job: ' .. tostring(jobName) .. ')',
            type = 'error'
        })
    end
end, false)
