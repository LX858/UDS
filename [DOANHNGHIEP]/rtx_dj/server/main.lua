Config = Config or {}
Config.DjLocations = Config.DjLocations or {}

if Config.Framework == "esx" then
    if Config.ESXFramework.newversion == true then
        ESX = exports[Config.ESXFramework.resourcename]:getSharedObject()
    else
        TriggerEvent(Config.ESXFramework.getsharedobject, function(obj)
            ESX = obj
        end)
    end
end

if Config.Framework == "qbcore" then
    QBCore = exports[Config.QBCoreFrameworkResourceName]:GetCoreObject()
end

function LanguageFile2(key, ...)
    local lang = (Config and Config.Language) or "English"
    local langTable = (Language and Language[lang]) or (Language and Language["English"]) or {}
    local formatStr = langTable[key] or key or ""
    local success, result = pcall(string.format, formatStr, ...)
    if success then return result end
    return formatStr
end

function LanguageFile(key, ...)
    local text = tostring(LanguageFile2(key, ...))
    return text:gsub("^%l", string.upper)
end

-- ─── Queue and Storage System ───────────────────────────────────────────────────────

local DjQueues = {}

local DjLocationsFromDatabase = {}

-- Counts entries in a queue that may have nil holes (from RemoveQueueMusic)
local function queueCount(queue)
    local count = 0
    for _ in pairs(queue) do count = count + 1 end
    return count
end

-- Returns the next safe insert index for a sparse queue table
local function queueNextIndex(queue)
    local max = 0
    for k in pairs(queue) do
        if k > max then max = k end
    end
    return max + 1
end

function GetFirstInQueue(locationId)
    local queue = DjQueues[locationId] and DjQueues[locationId].queue

    if not queue then
        return nil
    end

    local lowestIndex = nil
    local firstSong = nil

    for index, song in pairs(queue) do
        if not lowestIndex or index < lowestIndex then
            lowestIndex = index
            firstSong = song
        end
    end

    return firstSong, lowestIndex
end

-- ─── Load DJ Locations from Config ───────────────────────────────────────────────────────

function LoadDj()
    if type(Config) ~= "table" then
        Config = {}
    end
    if type(Config.DjLocations) ~= "table" then
        Config.DjLocations = {}
    end
    for locationId, locationData in pairs(Config.DjLocations) do
        DjQueues[locationId] = {
            queue = {}
        }

        GlobalState["rtxdjlocation-" .. locationId .. "-playing"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-stopped"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-loop"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-titledata"] = ""
        GlobalState["rtxdjlocation-" .. locationId .. "-typedata"] = ""
        GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
        GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"] = 0
        GlobalState["rtxdjlocation-" .. locationId .. "-linkdata"] = ""
        GlobalState["rtxdjlocation-" .. locationId .. "-using"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] = nil
        GlobalState["rtxdjlocation-" .. locationId .. "-currentdistance"] = locationData.maxdistance
        GlobalState["rtxdjlocation-" .. locationId .. "-currentvolume"] = 100
        GlobalState["rtxdjlocation-" .. locationId .. "-lights"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-lightsmove"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-lightscolor"] = {r = 255, g = 255, b = 255}
        GlobalState["rtxdjlocation-" .. locationId .. "-smoke"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-smokecolor"] = {r = 255, g = 255, b = 255}
        GlobalState["rtxdjlocation-" .. locationId .. "-lasers"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-lasersmove"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-laserscolor"] = {r = 255, g = 255, b = 255}
        GlobalState["rtxdjlocation-" .. locationId .. "-particles"] = false
        GlobalState["rtxdjlocation-" .. locationId .. "-editable"] = true
    end
end

-- ─── Load DJ Locations from Database ───────────────────────────────────────────────────────

function LoadDjDatabase()
    MySQL.Async.fetchAll("SELECT * FROM djlocations", {}, function(results)
        for _, row in ipairs(results) do
            local coordsDecoded = json.decode(row.coords)
            local coords = vector3(coordsDecoded.coords.x, coordsDecoded.coords.y, coordsDecoded.coords.z)
            local locationId = row.locationid

            local permissionsDecoded = json.decode(row.permissions)
            local lightsDecoded = json.decode(row.lights)
            local smokeDecoded = json.decode(row.smoke)
            local lasersDecoded = json.decode(row.lasers)
            local particlesDecoded = json.decode(row.particles)

            local locationData = {
                label = row.label,
                coords = coords,
                maxdistance = row.maxdistance,
                soundtype = row.soundtype,
                lights = {
                    enabled = lightsDecoded.enabled,
                    locations = lightsDecoded.locations
                },
                smoke = {
                    enabled = smokeDecoded.enabled,
                    locations = smokeDecoded.locations
                },
                lasers = {
                    enabled = lasersDecoded.enabled,
                    locations = lasersDecoded.locations
                },
                particles = {
                    enabled = particlesDecoded.enabled,
                    locations = particlesDecoded.locations
                },
                permissions = {
                    everyone = permissionsDecoded.everyone,
                    permissions = permissionsDecoded.permissions
                }
            }

            DjLocationsFromDatabase[locationId] = {
                label = row.label,
                coords = coords,
                maxdistance = row.maxdistance,
                lights = {
                    enabled = lightsDecoded.enabled,
                    locations = lightsDecoded.locations
                },
                smoke = {
                    enabled = smokeDecoded.enabled,
                    locations = smokeDecoded.locations
                },
                lasers = {
                    enabled = lasersDecoded.enabled,
                    locations = lasersDecoded.locations
                },
                particles = {
                    enabled = particlesDecoded.enabled,
                    locations = particlesDecoded.locations
                },
                permissions = {
                    everyone = permissionsDecoded.everyone,
                    permissions = permissionsDecoded.permissions
                }
            }

            DjQueues[locationId] = {
                queue = {}
            }

            Config.DjLocations[locationId] = locationData

            GlobalState["rtxdjlocation-" .. locationId .. "-playing"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-stopped"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-loop"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-titledata"] = ""
            GlobalState["rtxdjlocation-" .. locationId .. "-typedata"] = ""
            GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
            GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"] = 0
            GlobalState["rtxdjlocation-" .. locationId .. "-linkdata"] = ""
            GlobalState["rtxdjlocation-" .. locationId .. "-using"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] = nil
            GlobalState["rtxdjlocation-" .. locationId .. "-currentdistance"] = locationData.maxdistance
            GlobalState["rtxdjlocation-" .. locationId .. "-currentvolume"] = 100
            GlobalState["rtxdjlocation-" .. locationId .. "-lights"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-lightsmove"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-lightscolor"] = {r = 255, g = 255, b = 255}
            GlobalState["rtxdjlocation-" .. locationId .. "-smoke"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-smokecolor"] = {r = 255, g = 255, b = 255}
            GlobalState["rtxdjlocation-" .. locationId .. "-lasers"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-lasersmove"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-laserscolor"] = {r = 255, g = 255, b = 255}
            GlobalState["rtxdjlocation-" .. locationId .. "-particles"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-editable"] = true

            TriggerClientEvent("rtx_dj:Global:CreateNewDjLocation", -1, locationId, locationData)
        end
    end)
end

-- ─── Unique ID Generation ───────────────────────────────────────────────────────

function generateRandomId()
    return math.random(100000000, 999999999)
end

function checkDjExistence(locationId, callback)
    local query = "SELECT COUNT(*) as count FROM djlocations WHERE locationid = @locationid"
    local parameters = {
        ["@locationid"] = locationId
    }

    MySQL.Async.execute(query, parameters, function(result)
        if result and result[1] and result[1].count then
            if result[1].count > 0 then
                callback(true)
            else
                callback(false)
            end
        else
            callback(false)
        end
    end)
end

function generateUniqueDjId(callback)
    local randomId = generateRandomId()

    checkDjExistence(randomId, function(exists)
        if exists then
            generateUniqueDjId(callback)
        else
            callback(randomId)
        end
    end)
end

-- ─── Server Events - Synchronization and Menu ───────────────────────────────────────────────────────

RegisterServerEvent("rtx_dj:Global:SynchLocations")
AddEventHandler("rtx_dj:Global:SynchLocations", function()
    local source = source

    for locationId, locationData in pairs(DjLocationsFromDatabase) do
        TriggerClientEvent("rtx_dj:Global:CreateNewDjLocation", source, locationId, DjLocationsFromDatabase[locationId])
    end
end)

RegisterServerEvent("rtx_dj:Global:OpenMenu")
AddEventHandler("rtx_dj:Global:OpenMenu", function(locationId)
    local source = source

    if PlayerHasLocationAccess(source, locationId) then
        if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == false then
            GlobalState["rtxdjlocation-" .. locationId .. "-using"] = true
            GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] = source

            TriggerClientEvent("rtx_dj:Global:OpenMenuClient", source, locationId, DjQueues[locationId].queue)
        else
            TriggerClientEvent("rtx_dj:Notify", source, Language[Config.Language].djsusing)
        end
    else
        TriggerClientEvent("rtx_dj:Notify", source, Language[Config.Language].djperms)
    end
end)

RegisterServerEvent("rtx_dj:Global:CloseMenu")
AddEventHandler("rtx_dj:Global:CloseMenu", function(locationId)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-using"] = false
            GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] = nil
        end
    end
end)

-- ─── Music Playback Controls ───────────────────────────────────────────────────────

RegisterServerEvent("rtx_dj:Global:PlayMusic")
AddEventHandler("rtx_dj:Global:PlayMusic", function(locationId, duration, title, type, link)
    local source = source
    if not DjQueues[locationId] then return end
    if GlobalState["rtxdjlocation-" .. locationId .. "-playing"] == false then
        if queueCount(DjQueues[locationId].queue) == 0 then
            GlobalState["rtxdjlocation-" .. locationId .. "-playing"] = true
            GlobalState["rtxdjlocation-" .. locationId .. "-titledata"] = title
            GlobalState["rtxdjlocation-" .. locationId .. "-typedata"] = type
            GlobalState["rtxdjlocation-" .. locationId .. "-linkdata"] = link
            GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
            GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"] = duration
        end
    else
        local queueIndex = queueNextIndex(DjQueues[locationId].queue)
        DjQueues[locationId].queue[queueIndex] = {
            durationqueuedata = duration,
            titlequeuedata = title,
            typequeuedata = type,
            linkqueuedata = link
        }

        Citizen.Wait(100)

        TriggerClientEvent("rtx_dj:Global:UpdateQueue", source, locationId, DjQueues[locationId].queue)
    end
end)

RegisterServerEvent("rtx_dj:Global:ChangeLoop")
AddEventHandler("rtx_dj:Global:ChangeLoop", function(locationId, loopEnabled)
    local source = source
    GlobalState["rtxdjlocation-" .. locationId .. "-loop"] = loopEnabled
end)

RegisterServerEvent("rtx_dj:Global:ChangeDuration")
AddEventHandler("rtx_dj:Global:ChangeDuration", function(locationId, percentage)
    local source = source

    local clampedPercentage = percentage
    if clampedPercentage < 0 then
        clampedPercentage = 0
    elseif clampedPercentage > 100 then
        clampedPercentage = 100
    end

    local maxDuration = GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"]
    local newTime = (clampedPercentage / 100) * maxDuration

    GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = newTime

    TriggerClientEvent("rtx_dj:Global:ChangeTime", -1, locationId, newTime)
end)

RegisterServerEvent("rtx_dj:Global:ChangeForwardBackWard")
AddEventHandler("rtx_dj:Global:ChangeForwardBackWard", function(locationId, isForward)
    local source = source

    local maxDuration = GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"]
    local currentDuration = GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"]
    local skipTime = Config.ForwardBackwardTime or 0

    if isForward == true then
        currentDuration = currentDuration + skipTime
        if currentDuration > maxDuration then
            currentDuration = maxDuration
        end
    else
        currentDuration = currentDuration - skipTime
        if currentDuration < 0 then
            currentDuration = 0
        end
    end

    GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = currentDuration

    TriggerClientEvent("rtx_dj:Global:ChangeTime", -1, locationId, currentDuration)
end)

RegisterServerEvent("rtx_dj:Global:ResumeMusic")
AddEventHandler("rtx_dj:Global:ResumeMusic", function(locationId, shouldResume)
    local source = source
    if shouldResume == true then
        GlobalState["rtxdjlocation-" .. locationId .. "-stopped"] = false
        TriggerClientEvent("rtx_dj:Global:ResumeHandler", -1, locationId,
            GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"], false,
            GlobalState["rtxdjlocation-" .. locationId .. "-typedata"])
    else
        GlobalState["rtxdjlocation-" .. locationId .. "-stopped"] = true
        TriggerClientEvent("rtx_dj:Global:ResumeHandler", -1, locationId,
            GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"], true,
            GlobalState["rtxdjlocation-" .. locationId .. "-typedata"])
    end
end)

RegisterServerEvent("rtx_dj:Global:ChangeVolume")
AddEventHandler("rtx_dj:Global:ChangeVolume", function(locationId, volume)
    local source = source

    local clampedVolume = volume
    if clampedVolume < 0 then
        clampedVolume = 0
    elseif clampedVolume > 100 then
        clampedVolume = 100
    end

    GlobalState["rtxdjlocation-" .. locationId .. "-currentvolume"] = clampedVolume

    TriggerClientEvent("rtx_dj:Global:SettingsUpdate", source, locationId, 
        GlobalState["rtxdjlocation-" .. locationId .. "-currentvolume"],
        GlobalState["rtxdjlocation-" .. locationId .. "-currentdistance"])
end)

RegisterServerEvent("rtx_dj:Global:ChangeDistance")
AddEventHandler("rtx_dj:Global:ChangeDistance", function(locationId, distance)
    local source = source

    local locationData = Config.DjLocations[locationId]
    if not locationData then return end

    local clampedDistance = distance
    if clampedDistance < 1 then
        clampedDistance = 1
    elseif clampedDistance > locationData.maxdistance then
        clampedDistance = locationData.maxdistance
    end

    clampedDistance = tonumber(string.format("%.1f", clampedDistance))

    GlobalState["rtxdjlocation-" .. locationId .. "-currentdistance"] = clampedDistance

    TriggerClientEvent("rtx_dj:Global:SettingsUpdate", source, locationId,
        GlobalState["rtxdjlocation-" .. locationId .. "-currentvolume"],
        GlobalState["rtxdjlocation-" .. locationId .. "-currentdistance"])
end)

RegisterServerEvent("rtx_dj:Global:ClearQueue")
AddEventHandler("rtx_dj:Global:ClearQueue", function(locationId)
    local source = source
    if not DjQueues[locationId] then return end

    DjQueues[locationId].queue = {}

    Citizen.Wait(100)

    TriggerClientEvent("rtx_dj:Global:UpdateQueue", source, locationId, DjQueues[locationId].queue)
end)

RegisterServerEvent("rtx_dj:Global:StopSong")
AddEventHandler("rtx_dj:Global:StopSong", function(locationId)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-playing"] == true then
        -- Desactivar el bucle y establecer la duración actual al máximo
        GlobalState["rtxdjlocation-" .. locationId .. "-loop"] = false
        local maxDuration = GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"]
        GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = maxDuration
    end
end)

RegisterServerEvent("rtx_dj:Global:RemoveQueueMusic")
AddEventHandler("rtx_dj:Global:RemoveQueueMusic", function(locationId, queueIndex)
    local source = source
    if not DjQueues[locationId] then return end

    if queueIndex ~= nil then
        if DjQueues[locationId].queue[queueIndex] ~= nil then
            DjQueues[locationId].queue[queueIndex] = nil

            TriggerClientEvent("rtx_dj:Global:UpdateQueue", source, locationId, DjQueues[locationId].queue)
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:SoundBoard")
AddEventHandler("rtx_dj:Global:SoundBoard", function(locationId, soundData)
    local source = source

    if soundData ~= nil then
        TriggerClientEvent("rtx_dj:Global:SoundBoardClient", -1, locationId, soundData)
    end
end)

-- ─── Effect Controls ───────────────────────────────────────────────────────

RegisterServerEvent("rtx_dj:Global:LightHandler")
AddEventHandler("rtx_dj:Global:LightHandler", function(locationId, enabled)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-lights"] = enabled
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:LightMoveHandler")
AddEventHandler("rtx_dj:Global:LightMoveHandler", function(locationId, enabled)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-lightsmove"] = enabled
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:LightColorHandler")
AddEventHandler("rtx_dj:Global:LightColorHandler", function(locationId, color)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-lightscolor"] = {
                r = color.r,
                g = color.g,
                b = color.b
            }
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:FogHandler")
AddEventHandler("rtx_dj:Global:FogHandler", function(locationId, enabled)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-smoke"] = enabled
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:FogColorHandler")
AddEventHandler("rtx_dj:Global:FogColorHandler", function(locationId, color)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-smokecolor"] = {
                r = color.r,
                g = color.g,
                b = color.b
            }
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:LaserHandler")
AddEventHandler("rtx_dj:Global:LaserHandler", function(locationId, enabled)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-lasers"] = enabled
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:LaserMoveHandler")
AddEventHandler("rtx_dj:Global:LaserMoveHandler", function(locationId, enabled)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-lasersmove"] = enabled
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:LaserColorHandler")
AddEventHandler("rtx_dj:Global:LaserColorHandler", function(locationId, color)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-laserscolor"] = {
                r = color.r,
                g = color.g,
                b = color.b
            }
        end
    end
end)

RegisterServerEvent("rtx_dj:Global:ParticlesHandler")
AddEventHandler("rtx_dj:Global:ParticlesHandler", function(locationId, enabled)
    local source = source

    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
        if GlobalState["rtxdjlocation-" .. locationId .. "-usingid"] == source then
            GlobalState["rtxdjlocation-" .. locationId .. "-particles"] = enabled
        end
    end
end)

-- ─── In-game DJ Creator ───────────────────────────────────────────────────────

if Config.InGameDjCreator == true then
    RegisterServerEvent("rtx_dj:Global:DjCreator")
    AddEventHandler("rtx_dj:Global:DjCreator", function()
        local source = source

        if CheckDjCreatorPermission(source) == true then
            TriggerClientEvent("rtx_dj:Global:DjCreatorClient", source)
        else
            TriggerClientEvent("rtx_dj:Notify", source, Language[Config.Language].djperms)
        end
    end)

    RegisterServerEvent("rtx_dj:Global:EditDjLocation")
    AddEventHandler("rtx_dj:Global:EditDjLocation", function(locId, payload)
        local source = source

        if CheckDjCreatorPermission(source) ~= true then return end
        if not locId or not payload then return end

        local function validateVector3(data)
            if type(data) ~= "table" then return vector3(0.0, 0.0, 0.0) end
            return vector3(tonumber(data.x) or 0.0, tonumber(data.y) or 0.0, tonumber(data.z) or 0.0)
        end

        local function processEffectLocations(locations)
            local result = {}
            if type(locations) == "table" then
                for _, location in ipairs(locations) do
                    table.insert(result, {
                        handler = nil, handler2 = nil, handlermain = nil,
                        coords = validateVector3(location.coords or location.pos),
                        rotation = validateVector3(location.rotation or location.rot)
                    })
                end
            end
            return result
        end

        local function processParticleLocations(locations)
            local result = {}
            if type(locations) == "table" then
                for _, location in ipairs(locations) do
                    table.insert(result, {
                        handler = nil, handler2 = nil,
                        animdict = tostring(location.animdict or location.dict or ""),
                        animname = tostring(location.animname or location.name or ""),
                        coords = validateVector3(location.coords or location.pos),
                        rotation = validateVector3(location.rotation or location.rot)
                    })
                end
            end
            return result
        end

        local locationCoords = validateVector3(payload.location or payload.coords or {})
        local locationName   = tostring(payload.name or payload.label or "Unnamed Location")
        local locationMaxDist = tonumber(payload.maxDistance or payload.maxdistance) or 100.0

        local effects   = payload.effects or {}
        local smokeData    = effects.smoke    or payload.smoke    or {}
        local lightsData   = effects.lights   or payload.lights   or {}
        local lasersData   = effects.lasers   or payload.lasers   or {}
        local particlesData = effects.particles or payload.particles or {}

        local access    = payload.access or payload.permissions or {}
        local everyoneAccess  = not not access.everyone
        local permsList = access.permissions or {}

        local updatedLocation = {
            label       = locationName,
            coords      = locationCoords,
            maxdistance = locationMaxDist,
            soundtype   = tostring(payload.soundtype or "linear"),
            lights    = { enabled = not not lightsData.enabled,   locations = processEffectLocations(lightsData.locations) },
            smoke     = { enabled = not not smokeData.enabled,    locations = processEffectLocations(smokeData.locations)  },
            lasers    = { enabled = not not lasersData.enabled,   locations = processEffectLocations(lasersData.locations) },
            particles = { enabled = not not particlesData.enabled, locations = processParticleLocations(particlesData.locations or particlesData.entries) },
            permissions = { everyone = everyoneAccess, permissions = permsList },
        }

        -- Persist to database
        MySQL.Async.execute(
            "UPDATE djlocations SET coords=@coords, label=@label, maxdistance=@maxdistance, permissions=@permissions, lights=@lights, smoke=@smoke, lasers=@lasers, particles=@particles WHERE locationid=@locationid",
            {
                ["@locationid"]    = locId,
                ["@coords"]        = json.encode({ coords = updatedLocation.coords }),
                ["@label"]         = updatedLocation.label,
                ["@maxdistance"]   = updatedLocation.maxdistance,
                ["@permissions"]   = json.encode(updatedLocation.permissions),
                ["@lights"]        = json.encode(updatedLocation.lights),
                ["@smoke"]         = json.encode(updatedLocation.smoke),
                ["@lasers"]        = json.encode(updatedLocation.lasers),
                ["@particles"]     = json.encode(updatedLocation.particles),
            },
            function()
                Config.DjLocations[locId]        = updatedLocation
                DjLocationsFromDatabase[locId]   = updatedLocation

                GlobalState["rtxdjlocation-" .. locId .. "-currentdistance"] = updatedLocation.maxdistance

                TriggerClientEvent("rtx_dj:Global:UpdateDjLocation", -1, locId, updatedLocation)
            end
        )
    end)

    RegisterServerEvent("rtx_dj:Global:RemoveDjLocation")
    AddEventHandler("rtx_dj:Global:RemoveDjLocation", function(locId)
        local source = source

        if CheckDjCreatorPermission(source) ~= true then return end
        if not locId or not Config.DjLocations[locId] then return end

        MySQL.Async.execute(
            "DELETE FROM djlocations WHERE locationid = @locationid",
            { ["@locationid"] = locId },
            function()
                Config.DjLocations[locId]      = nil
                DjLocationsFromDatabase[locId] = nil
                DjQueues[locId]                = nil

                TriggerClientEvent("rtx_dj:Global:RemoveDjLocationClient", -1, locId)
            end
        )
    end)


    RegisterServerEvent("rtx_dj:Global:CreateDjLocation")
    AddEventHandler("rtx_dj:Global:CreateDjLocation", function(locationData)
        local source = source

        if CheckDjCreatorPermission(source) == true then

            if type(Config) ~= "table" then
                Config = {}
            end

            if type(Config.DjLocations) ~= "table" then
                Config.DjLocations = {}
            end

            local function validateVector3(data)
                if type(data) ~= "table" then
                    return vector3(0.0, 0.0, 0.0)
                end

                local x = tonumber(data.x) or 0.0
                local y = tonumber(data.y) or 0.0
                local z = tonumber(data.z) or 0.0

                return vector3(x, y, z)
            end

            local function roundDistance(distance)
                local num = tonumber(distance)
                if not num then
                    num = 0.0
                end
                return math.floor(num * 10 + 0.5) / 10.0
            end

            local function processEffectLocations(locations)
                local result = {}

                if type(locations) == "table" then
                    for _, location in ipairs(locations) do
                        table.insert(result, {
                            handler = nil,
                            handler2 = nil,
                            coords = validateVector3(location.pos),
                            rotation = validateVector3(location.rot)
                        })
                    end
                end

                return result
            end

            local function processParticleLocations(locations)
                local result = {}

                if type(locations) == "table" then
                    for _, location in ipairs(locations) do
                        table.insert(result, {
                            handler = nil,
                            handler2 = nil,
                            animdict = tostring(location.dict or ""),
                            animname = tostring(location.name or ""),
                            coords = validateVector3(location.pos),
                            rotation = validateVector3(location.rot)
                        })
                    end
                end

                return result
            end

            local function processPermissions(permissions)
                local result = {}

                if type(permissions) == "table" then
                    for _, perm in ipairs(permissions) do
                        local permType = tostring(perm.type or "")
                        local permValue = tostring(perm.value or "")

                        table.insert(result, {
                            permissiontype = permType,
                            permission = permValue,
                            [1] = permValue
                        })
                    end
                end

                return result
            end

            local locationName = tostring((locationData and locationData.name) or "Unnamed Location")
            local locationCoords = validateVector3((locationData and locationData.location) or {})
            local locationMaxDistance = roundDistance((locationData and locationData.maxDistance) or 0)

            local effects = (locationData and locationData.effects) or {}
            local smokeData = effects.smoke or {}
            local lightsData = effects.lights or {}
            local lasersData = effects.lasers or {}
            local particlesData = effects.particles or {}

            local access = (locationData and locationData.access) or {}
            local everyoneAccess = not not access.everyone -- Convertir a booleano
            local permissionsList = processPermissions(access.permissions)

            local newLocation = {
                label = locationName,
                coords = locationCoords,
                maxdistance = locationMaxDistance,
                lights = {
                    enabled = not not lightsData.enabled,
                    locations = processEffectLocations(lightsData.locations)
                },
                smoke = {
                    enabled = not not smokeData.enabled,
                    locations = processEffectLocations(smokeData.locations)
                },
                lasers = {
                    enabled = not not lasersData.enabled,
                    locations = processEffectLocations(lasersData.locations)
                },
                particles = {
                    enabled = not not particlesData.enabled,
                    locations = processParticleLocations(particlesData.entries)
                },
                permissions = {
                    everyone = everyoneAccess,
                    permissions = permissionsList
                }
            }

            generateUniqueDjId(function(uniqueId)
                MySQL.Async.execute(
                    "INSERT INTO djlocations (locationid, creatoridentifier, coords, label, maxdistance, permissions, lights, smoke, lasers, particles) VALUES (@locationid,@creatoridentifier,@coords,@label,@maxdistance,@permissions,@lights,@smoke,@lasers,@particles)",
                    {
                        ["@locationid"] = uniqueId,
                        ["@creatoridentifier"] = GetPlayerIdentifierRTX(source),
                        ["@coords"] = json.encode({coords = newLocation.coords}),
                        ["@label"] = newLocation.label,
                        ["@maxdistance"] = newLocation.maxdistance,
                        ["@permissions"] = json.encode(newLocation.permissions),
                        ["@lights"] = json.encode(newLocation.lights),
                        ["@smoke"] = json.encode(newLocation.smoke),
                        ["@lasers"] = json.encode(newLocation.lasers),
                        ["@particles"] = json.encode(newLocation.particles)
                    },
                    function(result)
                        DjQueues[uniqueId] = {
                            queue = {}
                        }

                        Config.DjLocations[uniqueId] = newLocation

                        DjLocationsFromDatabase[uniqueId] = {
                            label = locationName,
                            coords = locationCoords,
                            maxdistance = locationMaxDistance,
                            soundtype = "linear",
                            lights = {
                                enabled = not not lightsData.enabled,
                                locations = processEffectLocations(lightsData.locations)
                            },
                            smoke = {
                                enabled = not not smokeData.enabled,
                                locations = processEffectLocations(smokeData.locations)
                            },
                            lasers = {
                                enabled = not not lasersData.enabled,
                                locations = processEffectLocations(lasersData.locations)
                            },
                            particles = {
                                enabled = not not particlesData.enabled,
                                locations = processParticleLocations(particlesData.entries)
                            },
                            permissions = {
                                everyone = everyoneAccess,
                                permissions = permissionsList
                            }
                        }

                        GlobalState["rtxdjlocation-" .. uniqueId .. "-playing"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-stopped"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-loop"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-titledata"] = ""
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-typedata"] = ""
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-currentdurationdata"] = 0
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-maxdurationdata"] = 0
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-linkdata"] = ""
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-using"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-usingid"] = nil
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-currentdistance"] = locationMaxDistance
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-currentvolume"] = 100
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-lights"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-lightsmove"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-lightscolor"] = {r = 255, g = 255, b = 255}
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-smoke"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-smokecolor"] = {r = 255, g = 255, b = 255}
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-lasers"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-lasersmove"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-laserscolor"] = {r = 255, g = 255, b = 255}
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-particles"] = false
                        GlobalState["rtxdjlocation-" .. uniqueId .. "-editable"] = true

                        TriggerClientEvent("rtx_dj:Global:CreateNewDjLocation", -1, uniqueId, newLocation)
                    end
                )
            end)
        end
    end)
end

-- ─── Main Thread and Initialization System ───────────────────────────────────────────────────────

function authorized()
    print("[RTX DJ SYSTEM] - Thank you for choosing us - Discord: https://discord.gg/P6KdaDpgAk Store: https://rtx.tebex.io")
end

CreateThread(function()
    while true do
        Wait(1000)

        for locationId, locationData in pairs(Config.DjLocations) do

            local isPlaying = GlobalState["rtxdjlocation-" .. locationId .. "-playing"]

            if isPlaying then
                local isStopped = GlobalState["rtxdjlocation-" .. locationId .. "-stopped"]

                if isStopped == false then

                    local currentDuration = tonumber(GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"]) or 0
                    local maxDuration = tonumber(GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"]) or 0

                    if maxDuration > 0 and currentDuration < maxDuration then

                        currentDuration = currentDuration + 1

                        if currentDuration > maxDuration then
                            currentDuration = maxDuration
                        end

                        GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = currentDuration

                        if currentDuration >= maxDuration then

                            local isLooping = GlobalState["rtxdjlocation-" .. locationId .. "-loop"]

                            if isLooping == false then
                                local nextSong, nextIndex = GetFirstInQueue(locationId)

                                if nextSong then
                                    GlobalState["rtxdjlocation-" .. locationId .. "-titledata"] = nextSong.titlequeuedata
                                    GlobalState["rtxdjlocation-" .. locationId .. "-typedata"] = nextSong.typequeuedata
                                    GlobalState["rtxdjlocation-" .. locationId .. "-linkdata"] = nextSong.linkqueuedata
                                    GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
                                    GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"] = nextSong.durationqueuedata

                                    DjQueues[locationId].queue[nextIndex] = nil

                                    if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
                                        local usingPlayerId = GlobalState["rtxdjlocation-" .. locationId .. "-usingid"]
                                        TriggerClientEvent("rtx_dj:Global:UpdateQueue", usingPlayerId, locationId, DjQueues[locationId].queue)
                                    end
                                else
                                    TriggerClientEvent("rtx_dj:Global:StopCompletly", -1, locationId, 
                                        GlobalState["rtxdjlocation-" .. locationId .. "-typedata"])

                                    GlobalState["rtxdjlocation-" .. locationId .. "-playing"] = false
                                    GlobalState["rtxdjlocation-" .. locationId .. "-stopped"] = false
                                    GlobalState["rtxdjlocation-" .. locationId .. "-loop"] = false
                                    GlobalState["rtxdjlocation-" .. locationId .. "-titledata"] = ""
                                    GlobalState["rtxdjlocation-" .. locationId .. "-typedata"] = ""
                                    GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
                                    GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"] = 0
                                    GlobalState["rtxdjlocation-" .. locationId .. "-linkdata"] = ""
                                end
                            else
                                GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
                                TriggerClientEvent("rtx_dj:Global:ChangeTime", -1, locationId, 0)
                            end
                        end

                    elseif currentDuration == maxDuration then
                        local isLooping = GlobalState["rtxdjlocation-" .. locationId .. "-loop"]

                        if isLooping == false then
                            local nextSong, nextIndex = GetFirstInQueue(locationId)

                            if nextSong then
                                GlobalState["rtxdjlocation-" .. locationId .. "-titledata"] = nextSong.titlequeuedata
                                GlobalState["rtxdjlocation-" .. locationId .. "-typedata"] = nextSong.typequeuedata
                                GlobalState["rtxdjlocation-" .. locationId .. "-linkdata"] = nextSong.linkqueuedata
                                GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
                                GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"] = nextSong.durationqueuedata

                                DjQueues[locationId].queue[nextIndex] = nil

                                if GlobalState["rtxdjlocation-" .. locationId .. "-using"] == true then
                                    local usingPlayerId = GlobalState["rtxdjlocation-" .. locationId .. "-usingid"]
                                    TriggerClientEvent("rtx_dj:Global:UpdateQueue", usingPlayerId, locationId, DjQueues[locationId].queue)
                                end
                            else
                                TriggerClientEvent("rtx_dj:Global:StopCompletly", -1, locationId,
                                    GlobalState["rtxdjlocation-" .. locationId .. "-typedata"])

                                GlobalState["rtxdjlocation-" .. locationId .. "-playing"] = false
                                GlobalState["rtxdjlocation-" .. locationId .. "-stopped"] = false
                                GlobalState["rtxdjlocation-" .. locationId .. "-loop"] = false
                                GlobalState["rtxdjlocation-" .. locationId .. "-titledata"] = ""
                                GlobalState["rtxdjlocation-" .. locationId .. "-typedata"] = ""
                                GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
                                GlobalState["rtxdjlocation-" .. locationId .. "-maxdurationdata"] = 0
                                GlobalState["rtxdjlocation-" .. locationId .. "-linkdata"] = ""
                            end
                        else
                            GlobalState["rtxdjlocation-" .. locationId .. "-currentdurationdata"] = 0
                            TriggerClientEvent("rtx_dj:Global:ChangeTime", -1, locationId, 0)
                        end
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    authorized()

    LoadDj()

    LoadDjDatabase()
end)