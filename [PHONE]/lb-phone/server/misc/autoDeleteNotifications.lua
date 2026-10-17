

if not Config.AutoDeleteNotifications then
    return
end

if type(Config.AutoDeleteNotifications) ~= "number" then
    Config.AutoDeleteNotifications = 168
end

CreateThread(function()
    while true do
        if DatabaseCheckerFinished then
            break
        end
        Wait(500)
    end
end)

CreateThread(function()
    while true do
        debugprint("Deleting all old notifications..")
        local startTime = os.nanotime()
        
        MySQL.update("DELETE FROM phone_notifications WHERE `timestamp` < DATE_SUB(NOW(), INTERVAL ? HOUR)", {
            Config.AutoDeleteNotifications
        }, function(affectedRows)
            local endTime = os.nanotime()
            local duration = (endTime - startTime) / 1000000.0
            
            local pluralSuffix = ""
            if affectedRows ~= 1 then
                pluralSuffix = "s"
            end
            
            debugprint("Deleted " .. affectedRows .. " notification" .. pluralSuffix .. " in " .. duration .. " ms")
        end)
        
        Wait(3600000)
    end
end)
