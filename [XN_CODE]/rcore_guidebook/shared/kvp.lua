KVP_PREFIX = 'rcore_guidebook_'
KVP_DATA = {
    pageScale = {
        value = GetResourceKvpFloat(KVP_PREFIX .. 'pageScale') or 1.0,
        type = 'float',
    },
}

KVPCache = {
    pageScale = KVP_DATA.pageScale.value,
}
function StoreKVPValue(name, value)
    KVPCache[name] = value
end

function GetKVPValue(key)
    return KVPCache[key]
end

function StoreAllToKVP()
    for key, data in pairs(KVP_DATA) do
        local cachedValue = GetKVPValue(key)
        if KVP_DATA[key].value == cachedValue then goto continue end

        if data.type == 'float' then
            dbg.debug('saving float %s %s', KVP_PREFIX .. key, cachedValue)
            SetResourceKvpFloat(KVP_PREFIX .. key, cachedValue)
        elseif data.type == 'string' then
            dbg.debug('saving string %s %s', KVP_PREFIX .. key, cachedValue)
            SetResourceKvp(KVP_PREFIX .. key, cachedValue)
        elseif data.type == 'int' then
            dbg.debug('saving int %s %s', KVP_PREFIX .. key, data.value)
            SetResourceKvpInt(KVP_PREFIX .. key, cachedValue)
        end

        ::continue::
    end
end
