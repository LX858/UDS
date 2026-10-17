RegisterNetEvent("rcore_television:fetchCache")
AddEventHandler("rcore_television:fetchCache", function(newCache)
    MegaDebug("fetchCache start")
    DestroyDuiAndScaleform()
    TelevisionCache = newCache
    MegaDebug("fetchCache stop")
end)

RegisterNetEvent("rcore_television:stopTelevisionAtCoords")
AddEventHandler("rcore_television:stopTelevisionAtCoords", function(targetPos)
    MegaDebug("stopTelevisionAtCoords start")
    for index, entry in pairs(TelevisionCache) do
        local dist = #(entry.tvPos - targetPos)
        if dist < 1.5 then
            if entry.duiLoaded then
                entry.scaleformLoaded = false
                Debug("DestroyDui | event.lua | 11")
                DestroyDui(entry.duiObj)
                SetScaleformMovieAsNoLongerNeeded(entry.scaleformId)
            end
            table.remove(TelevisionCache, index)
            break
        end
    end
    MegaDebug("stopTelevisionAtCoords stop")
end)

RegisterNetEvent("rcore_television:stopTelevisionFromEntity")
AddEventHandler("rcore_television:stopTelevisionFromEntity", function(entity)
    local tvPos = GetTelevisionMetaData(GetEntityModel(entity), entity)
    for _, entry in pairs(TelevisionCache) do
        local dist = #(entry.tvPos - tvPos)
        if dist < 1.5 then
            TriggerServerEvent("rcore_television:stopTelevisionAtCoords", tvPos)
            break
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DestroyDuiAndScaleform()
end)
