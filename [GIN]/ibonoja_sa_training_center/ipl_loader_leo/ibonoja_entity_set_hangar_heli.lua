local Config = {
    {
        ipl = "ibonoja_leo_hangar_kill_int_milo_",
        coords = { x = 2515.977, y = -460.42, z = 96.603 },
        entitySets = {
            { name = "ibonoja_leo_kill_01", enable = false, color = 1 },
            { name = "ibonoja_leo_kill_02", enable = true, color = 1 }
        }
    },
    {
        ipl = "ibonoja_leo_hangar_heli_int_milo_",
        coords = { x = 2485.404, y = -447.428, z = 96.236 },
        entitySets = {
            { name = "helipad_floor_1", enable = true, color = 1 },
            { name = "helipad_floor_2", enable = false, color = 3 },
            { name = "helipad_floor_3", enable = false, color = 4 },
            { name = "helipad_floor_4", enable = false, color = 2 }
        }
    },
    {
        ipl = "ibonoja_leo_interior_milo_",
        coords = { x = 2521.879, y = -293.299, z = 99.151 },
        entitySets = {
            { name = "briefing_1", enable = true, color = 1 },
            { name = "briefing_2", enable = false, color = 1 },
            { name = "briefing_3", enable = false, color = 1 },
            { name = "paleto_1", enable = false, color = 1 },
            { name = "paleto_2", enable = true, color = 1 },
            { name = "great_ocean_1", enable = false, color = 1 },
            { name = "great_ocean_2", enable = true, color = 1 },
            { name = "sandy_1", enable = false, color = 1 },
            { name = "sandy_2", enable = true, color = 2 },
            { name = "mrpd_1", enable = false, color = 2 },
            { name = "mrpd_2", enable = true, color = 2 },
            { name = "senora_1", enable = true, color = 2 },
            { name = "senora_2", enable = false, color = 2 }
        }
    },
    {
        ipl = "ibonoja_leo_training_02_milo_",
        coords = { x = 2521.879, y = -293.299, z = 98.151 },
        entitySets = {
            { name = "vespucci_1", enable = true, color = 1 },
            { name = "vespucci_2", enable = false, color = 1 },
            { name = "vinewood_1", enable = false, color = 3 },
            { name = "vinewood_2", enable = true, color = 3 }
        }
    },
    {
        ipl = "ibonoja_leo_galeria_tiro_int_milo_",
        coords = { x = 2463.174, y = -386.264, z = 90.992 },
        entitySets = {
            { name = "range_izda_1", enable = true, color = 1 },
            { name = "range_dcha_1", enable = false, color = 1 },
            { name = "range_izda_2", enable = false, color = 1 },
            { name = "range_dcha_2", enable = true, color = 1 },
            { name = "range_izda_target", enable = true, color = 1 },
            { name = "range_dcha_target", enable = false, color = 1 }
        }
    }
}

local PREFIX = "^5[IBONOJA]^7 "
local loadedInteriors = {}
local setsMap = {}
local lastChanges = {}

local function logMessage(fmt, ...)
    print(PREFIX .. string.format(fmt, ...))
end

local function loadIpl(iplName)
    if not iplName or iplName == "" then
        return
    end

    if IsIplActive(iplName) then
        return
    end

    RequestIpl(iplName)
    local timeout = 0
    while not IsIplActive(iplName) and timeout < 200 do
        Wait(10)
        timeout = timeout + 1
    end

    if IsIplActive(iplName) then
        logMessage("IPL cargado: %s", iplName)
    else
        logMessage("^1ADVERTENCIA:^7 IPL no se activó a tiempo: %s", iplName)
    end
end

local function getInteriorAtCoords(coords)
    local interiorId = GetInteriorAtCoords(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    local attempts = 0
    while (interiorId == 0 or not IsValidInterior(interiorId)) and attempts < 120 do
        Wait(10)
        interiorId = GetInteriorAtCoords(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
        attempts = attempts + 1
    end
    return interiorId
end

local function refreshInterior(interiorId)
    if interiorId and interiorId ~= 0 then
        RefreshInterior(interiorId)
    end
end

local function applyEntitySet(interiorId, setName, enable, color)
    if not interiorId or interiorId == 0 then
        return false, "interiorId=0 (coords fuera de volumen del interior)"
    end

    if enable then
        EnableInteriorProp(interiorId, setName)
        if color ~= nil then
            SetInteriorEntitySetColor(interiorId, setName, color)
        end
    else
        DisableInteriorProp(interiorId, setName)
    end

    RefreshInterior(interiorId)
    return true
end

local function setEntitySets(changes)
    if type(changes) ~= "table" then
        return
    end

    for _, change in ipairs(changes) do
        local targets = setsMap[change.name]
        if not targets then
            logMessage("^1Set no mapeado:^7 %s (¿nombre correcto?)", change.name)
        else
            for _, target in ipairs(targets) do
                local success, err = applyEntitySet(target.id, change.name, change.enable, change.color)
                if not success then
                    local colorStr = change.color and (" (color " .. change.color .. ")") or ""
                    logMessage("^1Fallo al aplicar:^7 %s -> %s%s | interiorId=%s | %s",
                        change.name,
                        tostring(change.enable),
                        colorStr,
                        tostring(target.id),
                        err or ""
                    )
                end

                local entry = loadedInteriors[target.idx]
                if entry and entry.setsByName and entry.setsByName[change.name] then
                    entry.setsByName[change.name].enable = change.enable
                    if change.color ~= nil then
                        entry.setsByName[change.name].color = change.color
                    end
                end
            end
        end
    end

    lastChanges = changes
end

local function initializeInteriors()
    loadedInteriors = {}
    setsMap = {}

    for idx, item in ipairs(Config) do
        loadIpl(item.ipl)
        local interiorId = getInteriorAtCoords(item.coords)

        if interiorId == 0 then
            logMessage("^1NO se encontró interiorId^7 para %s @ (%.3f, %.3f, %.3f)",
                item.ipl, item.coords.x, item.coords.y, item.coords.z)
        else
            logMessage("Interior %s = %s @ (%.3f, %.3f, %.3f)",
                item.ipl, tostring(interiorId), item.coords.x, item.coords.y, item.coords.z)
            LoadInterior(interiorId)
            PinInteriorInMemory(interiorId)
            RefreshInterior(interiorId)
        end

        local interiorData = {
            ipl = item.ipl,
            coords = item.coords,
            id = interiorId,
            setsByName = {}
        }
        loadedInteriors[idx] = interiorData

        local entitySets = item.entitySets or {}
        for _, set in ipairs(entitySets) do
            interiorData.setsByName[set.name] = {
                enable = set.enable,
                color = set.color
            }

            if not setsMap[set.name] then
                setsMap[set.name] = {}
            end
            table.insert(setsMap[set.name], {
                idx = idx,
                id = interiorId
            })

            local success, err = applyEntitySet(interiorId, set.name, set.enable, set.color)
            if not success then
                local colorStr = set.color and (" (color " .. set.color .. ")") or ""
                logMessage("^1Inicial:^7 %s -> %s%s | %s",
                    set.name,
                    tostring(set.enable),
                    colorStr,
                    err or "error"
                )
            end
        end
    end
end

RegisterNetEvent("ibonoja:setEntitySets", function(changes)
    setEntitySets(changes)
end)

CreateThread(function()
    initializeInteriors()
    TriggerServerEvent("ibonoja:requestSync")
end)

RegisterCommand("ibj_dump", function()
    print(PREFIX .. "Dump de interiores / sets:")
    for idx, entry in ipairs(loadedInteriors) do
        print(string.format("  #%d ipl=%s id=%s @ (%.3f, %.3f, %.3f)",
            idx,
            tostring(entry.ipl),
            tostring(entry.id),
            entry.coords.x,
            entry.coords.y,
            entry.coords.z
        ))
        for setName, setConfig in pairs(entry.setsByName) do
            local colorStr = setConfig.color and (" (color " .. tostring(setConfig.color) .. ")") or ""
            print(string.format("     - %s => %s%s", setName, tostring(setConfig.enable), colorStr))
        end
    end

    if lastChanges and #lastChanges > 0 then
        print("  Últimos cambios:")
        for _, change in ipairs(lastChanges) do
            local colorStr = change.color and (" (color " .. tostring(change.color) .. ")") or ""
            print(string.format("     * %s -> %s%s", change.name, tostring(change.enable), colorStr))
        end
    end
end, false)

RegisterCommand("ibj_reapply", function()
    initializeInteriors()
end, false)

RegisterCommand("ibj_ipl_on", function(source, args)
    local ipl = args and args[1]
    if not ipl then
        print("^1Uso:^7 /ibj_ipl_on <ipl>")
        return
    end
    RequestIpl(ipl)
    Wait(200)
    print(string.format("[IBJ] IPL '%s' activo? %s", ipl, tostring(IsIplActive(ipl))))
end)

RegisterCommand("ibj_ipl_off", function(source, args)
    local ipl = args and args[1]
    if not ipl then
        print("^1Uso:^7 /ibj_ipl_off <ipl>")
        return
    end
    RemoveIpl(ipl)
    Wait(200)
    print(string.format("[IBJ] IPL '%s' activo? %s", ipl, tostring(IsIplActive(ipl))))
end)

RegisterCommand("ibj_ipl_status", function()
    local ipls = {
        "ibonoja_leo_interior_milo_",
        "ibonoja_leo_02_interior_milo_",
        "ibonoja_leo_training_interior_milo_",
        "ibonoja_leo_training_02_interior_milo_"
    }
    for _, ipl in ipairs(ipls) do
        print(string.format("[IBJ] %s -> active=%s", ipl, tostring(IsIplActive(ipl))))
    end
end)
