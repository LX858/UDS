--  _                             _                                  ___                        _     
-- | |_   _ _ __  _ __  _   _  __| | _____   _____ ___  _ __ ___    ( _ )    _ ____      ____ _(_)___ 
-- | | | | | '_ \| '_ \| | | |/ _` |/ _ \ \ / / __/ _ \| '_ ` _ \   / _ \/\ | '_ \ \ /\ / / _` | / __|
-- | | |_| | | | | | | | |_| | (_| |  __/\ V / (_| (_) | | | | | | | (_>  < | |_) \ V  V / (_| | \__ \
-- |_|\__,_|_| |_|_| |_|\__, |\__,_|\___| \_(_)___\___/|_| |_| |_|  \___/\/ | .__/ \_/\_/ \__,_|_|___/
--                      |___/                                               |_|                       

local QBCore = exports['qb-core']:GetCoreObject()
local dispatchs = {}

local units = {}
local playershaveunit = {}

RegisterServerEvent('ld-dispatch:addDispatch')
AddEventHandler('ld-dispatch:addDispatch', function(data)
    data.dispatchnumber = #dispatchs+1
    data.date = os.date("%Y-%m-%d %H:%M:%S")
    dispatchs[#dispatchs+1] = data
    TriggerClientEvent('ld-dispatch:client:dispatch', -1, data)
end)

QBCore.Functions.CreateCallback('ld-dispatch:getDispatchs', function(source, cb)
    cb(dispatchs)
end)

function getActiveJobPlayers(jobname)
    local players = QBCore.Functions.GetPlayers()
    local selectedplayers = {}
    for k,v in pairs(players) do 
        local pdata = QBCore.Functions.GetPlayer(v)
        if pdata.PlayerData.job.name == jobname then 
            local selectedData = {
                source = pdata.PlayerData.source,
                name = pdata.PlayerData.charinfo.firstname .. " " .. pdata.PlayerData.charinfo.lastname,
                callsign = "",
                job = pdata.PlayerData.job
            }
            selectedplayers[#selectedplayers+1] = selectedData
        end 
    end 
    return selectedplayers
end 

QBCore.Functions.CreateCallback('ld-dispatch:getJobPlayers', function(source, cb)
    local totaljobplayers = {}
    for k,v in pairs(Config.EmergencyJobs) do 
        local activepl = getActiveJobPlayers(v.name)
        totaljobplayers[#totaljobplayers+1] = {
            name = v.name,
            displayname = v.displayname,
            officers = activepl
        }
    end 
    cb(totaljobplayers)
end)

function createUnit(source, players, teamname, callsign) 
    local officers = {}
    local groupid = #units+1
    local self = QBCore.Functions.GetPlayer(source)
    for k,v in pairs(players) do 
        local player = QBCore.Functions.GetPlayer(tonumber(v))
        if player then 
            if player.PlayerData.job.name == self.PlayerData.job.name then 
                officers[#officers+1] = {
                    callsign = "",
                    name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                    source = player.PlayerData.source,
                    unithead = false,
                }
                playershaveunit[player.PlayerData.source] = groupid
            end 
        end 
    end 
    officers[#officers+1] = {
        callsign = "",
        name = self.PlayerData.charinfo.firstname .. " " .. self.PlayerData.charinfo.lastname,
        source = self.PlayerData.source,
        unithead = true, 
    }
    playershaveunit[source] = groupid

    local unit = {
        active = true,
        unithead = source,
        officer = officers,
        name = teamname,
        callname = callsign,
        job = self.PlayerData.job.name
    }

    units[groupid] = unit
    -- print(json.encode(units))
    return true 
end 

function leaveUnit(source) 
    local unitid = playershaveunit[source]
    if unitid then 
        for k,v in pairs(units[unitid].officer) do 
            if v.source == source then 
                table.remove(units[unitid].officer, k)
                playershaveunit[source] = nil 
            end 
        end 
    end
    return true  
end 

function deleteUnit(source)
    local unitid = playershaveunit[source]
    if unitid then 
        if units[unitid].unithead == source then 
            for k,v in pairs(units[unitid].officer) do 
                playershaveunit[v.source] = nil 
            end 
        else     
            return false 
        end 
        table.remove(units, unitid)
    end 
    return true 
end 

QBCore.Functions.CreateCallback('ld-dispatch:getUnits', function(source, cb)
    local totaljobplayers = {}
    for k,v in pairs(Config.EmergencyJobs) do
        local jobunitsx = {}
        for c,x in pairs(units) do 
            if x.job == v.name then 
                jobunitsx[#jobunitsx+1] = units[c]
            end 
        end 

        totaljobplayers[#totaljobplayers+1] = {
            name = v.name,
            displayname = v.displayname,
            jobunits = jobunitsx
        }
    end     
    cb(totaljobplayers)
end)

QBCore.Functions.CreateCallback('ld-dispatch:getMyUnit', function(source,cb)
    local myunit = playershaveunit[source]
    if myunit then
        local iamowner = false 
        if units[myunit].unithead == source then 
            iamowner = true 
        end 

        cb({
            unitid = myunit,
            unithead = iamowner,
            hasaunit = true,
        })
    else 
        cb(false)
    end 
end)

QBCore.Functions.CreateCallback('ld-dispatch:canAddtoUnit', function(source,cb, id)
    local player = QBCore.Functions.GetPlayer(id)
    local me = QBCore.Functions.GetPlayer(source)
    if player then 
        local unit = playershaveunit[id]
        if unit then
            cb(false)
        else 
            if player.PlayerData.job.name == me.PlayerData.job.name then 
                cb(true)
            else 
                cb(false)
            end
        end 
    else 
        cb(false)
    end 
end)

QBCore.Functions.CreateCallback('ld-dispatch:createUnit', function(source,cb, data)
    cb(createUnit(source, data.personlist, data.name, data.callcode))
end)


QBCore.Functions.CreateCallback('ld-dispatch:leaveUnit', function(source,cb)
    cb(leaveUnit(source))
end)

QBCore.Functions.CreateCallback('ld-dispatch:deleteUnit', function(source,cb)
    cb(deleteUnit(source))
end)

AddEventHandler('playerDropped', function(reason)
    local myunit = playershaveunit[source]
    if myunit then
        if units[myunit].unithead == source then 
            deleteUnit(source)
        else 
            leaveUnit(source)
        end 
    end 
end)

RegisterServerEvent('ld-dispatch:setActive', function(id)
    local src = source 
    local myunit = playershaveunit[source]
    if myunit then 
        local unitcallcode = units[myunit].callname
        dispatchs[id].active = true 
        dispatchs[id].valuestwo = {
            {
                text = unitcallcode,
                icon = "fa-solid fa-walkie-talkie",
            },
        }
    else 
        TriggerClientEvent('QBCore:Notify', src, 'You dont have a unit. You cant active the dispatch.', 'error')
    end 
end)

QBCore.Functions.CreateCallback('ld-dispatch:getLocation', function(source,cb,id)
    cb(dispatchs[id].coords)
end)

--  _                             _                                  ___                        _     
-- | |_   _ _ __  _ __  _   _  __| | _____   _____ ___  _ __ ___    ( _ )    _ ____      ____ _(_)___ 
-- | | | | | '_ \| '_ \| | | |/ _` |/ _ \ \ / / __/ _ \| '_ ` _ \   / _ \/\ | '_ \ \ /\ / / _` | / __|
-- | | |_| | | | | | | | |_| | (_| |  __/\ V / (_| (_) | | | | | | | (_>  < | |_) \ V  V / (_| | \__ \
-- |_|\__,_|_| |_|_| |_|\__, |\__,_|\___| \_(_)___\___/|_| |_| |_|  \___/\/ | .__/ \_/\_/ \__,_|_|___/
--                      |___/                                               |_|                       