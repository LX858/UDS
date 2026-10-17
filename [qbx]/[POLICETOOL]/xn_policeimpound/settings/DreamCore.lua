--[[
    Thank you for using our script. We are happy to have you here. If you need help, you can join our Discord server.
    https://discord.gg/zppUXj4JRm
]]

DreamLocales = {} -- Do not touch this!!!
DreamFramework = {} -- Do not touch this!!!
DreamCore = {} -- Do not touch this!!!

-- Dream Police Impound Settings
DreamCore.Language = 'en'
DreamCore.GiveCredits = true -- Set to false if you don't want to give credits

DreamCore.AllowedPoliceJobs = { 'police', 'sheriff' } -- Allowed Police Jobs
DreamCore.ImpoundStatusIconColor = {
    [2] = '#d4af37',
    [3] = '#374f6b',
}
DreamCore.ImpoundDurationFormat = '%H:%M %d.%m.%Y'
DreamCore.ImpoundStations = {
    {
        label = 'Chuộc xe giam',
        coords = vec3(50.18, -392.87, 39.13),
        ped = {
            model = 's_m_y_cop_01',
            coords = vec3(50.18, -392.87, 38.13), --vec3(469.52, -1028.61, 28.23)
            heading = 36.98,
        },
        blip = {
            sprite = 67,
            color = 68,
            label = 'Chuộc xe giam',
        },
        parkout = {
            coords = vec3(47.73, -385.66, 39.13), --vec3(475.94, -1026.09, 27.53)
            heading = 70.68,
        }
    },
    {
        label = 'Chuộc xe giam',
        coords = vec3(1856.43, 3687.7, 34.33),
        ped = {
            model = 's_m_y_cop_01',
            coords = vec3(1856.43, 3687.7, 33.33), --vec3(469.52, -1028.61, 28.23)
            heading = 305.66,
        },
        blip = {
            sprite = 67,
            color = 68,
            label = 'Chuộc xe giam',
        },
        parkout = {
            coords = vec3(1860.54, 3692.8, 33.81), --vec3(475.94, -1026.09, 27.53)
            heading = 207.15,
        }
    }

    -- Add more Impound Stations here
}

DreamCore.ImpoundForm = {
    Duration = {
        selection = 'number', -- date, time, or number (for minutes)
        formatDate = "DD.MM.YYYY",
        formatTime = '24', -- 24 or 12
    },
    CustomFineAmount = false,
    DisableInput = {
        officer = true,
        model = false,
        plate = false,
    }
}

--[[ QBCORE ONLY ]]

--[[ If set to true, the vehicle will be deleted from player_vehicles until the fine is paid.]]
--[[ If set to false, the vehicle's state will be updated to 2 (impounded). ]]
DreamCore.DeleteVehicle = false

--[[ QBCORE ONLY ]]

DreamCore.Target = function()
    if GetResourceState('ox_target') == 'started' then
        return 'ox'
    elseif GetResourceState('qb-target') == 'started' then
        return 'qb'
    else
        return error('No target system found! Please adjust DreamCore.Target!!!')
    end
end
