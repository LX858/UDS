

RegisterLegacyCallback("appstore:buyApp", function(source, callback, appPrice)
    local phoneNumber = GetEquippedPhoneNumber(source)
    if not phoneNumber then
        return callback(false)
    end
    callback(RemoveMoney(source, appPrice))
end)
