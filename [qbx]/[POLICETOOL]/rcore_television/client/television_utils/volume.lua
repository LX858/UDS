PlayerTelevisionVolume = Config.defaultVolume

RegisterCommand(Config.volumeCommand, function(source, args)
    local volume = tonumber(args[1])
    if volume ~= nil then
        if volume >= 0 and volume <= 100 then
            PlayerTelevisionVolume = volume
            local msg = _U("volume_changed", volume)
            if not msg then msg = "You updated prefer TV volume to: " .. volume end
            showNotification(msg)
            DestroyDuiAndScaleform()
        else
            local msg = _U("volume_invalid")
            if not msg then msg = "The volume has to be between 0-100" end
            showNotification(msg)
        end
    else
        local msg = _U("argument_has_to_be_number")
        if not msg then msg = "The volume has to be a number!" end
        showNotification(msg)
    end
end, false)
