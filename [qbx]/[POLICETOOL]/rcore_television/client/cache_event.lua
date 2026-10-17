RegisterNetEvent("rcore_television:AddTelevisionToCache", function(tvData)
    MegaDebug("AddTelevisionToCache start")
    table.insert(TelevisionCache, tvData)
    MegaDebug("AddTelevisionToCache stop")
end)

RegisterNetEvent("rcore_television:UpdateTelevisionCache", function(cacheIndex, updateData)
    MegaDebug("UpdateTelevisionCache start")

    local tvEntry = TelevisionCache[cacheIndex]
    if tvEntry then
        tvEntry.URL  = updateData.URL
        tvEntry.time = 0

        local resolvedUrl = getSupportedLink(RedirectType.SUPPORTED, updateData.URL, PlayerTelevisionVolume, 0)
        resolvedUrl = resolvedUrl:gsub(" ", "")

        if tvEntry.duiObj then
            while not tvEntry.duiLoaded do
                Wait(100)
            end
            Debug("cache_event.lua | SetDUILink | 22", resolvedUrl, cacheIndex)
            SetDUILink(tvEntry.duiObj, resolvedUrl)
        end
    end

    MegaDebug("UpdateTelevisionCache stop")
end)
