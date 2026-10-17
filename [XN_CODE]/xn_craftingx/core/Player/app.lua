local setup = true
QBCore = exports['qb-core']:GetCoreObject()

-- local function hideText()
--     exports['xn-textui']:delete3DTextUI("banchetao")
-- end

Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end

    --print('[^2vierp.craftingx^7] The crafting table is preparing ...')
    Citizen.Wait(500)

    for k, v in ipairs(Config) do
        setupBlip(v.Blip, v.Position)
        setupObject(v)
        setupOxTarget(k, v)
    end

    --print('[^2vierp.craftingx^7] ^2Intialized successful!')
end)

-- Citizen.CreateThread(function()
--         local data = Config[IsNearId]
--         exports['xn-textui']:create3DTextUI("banchetao", {
--             coords = vector3(1723.4075, 3318.5225, 41.1840),
--             displayDist = 6.0,
--             interactDist = 2.0,
--             enableKeyClick = true, -- If true when you near it and click key it will trigger the event that you write inside triggerData
--             keyNum = 38,
--             key = "E",
--             text = "Crafting",
--             theme = "green", -- or red
--             job = "all", -- or the job you want to show this for
--             canInteract = function()
--                 return true
--             end,
--             triggerData = {
--                 triggerName = "open:chetao",
--                 args = {
--                     table = data,
--                     tableId = IsNearId
--                 }
--             }
--         })
--         exports['xn-textui']:create3DTextUI("banchetao2", {
--             coords = vector3(1737.4415, 3317.1846, 41.1882),
--             displayDist = 6.0,
--             interactDist = 2.0,
--             enableKeyClick = true, -- If true when you near it and click key it will trigger the event that you write inside triggerData
--             keyNum = 38,
--             key = "E",
--             text = "Crafting",
--             theme = "green", -- or red
--             job = "all", -- or the job you want to show this for
--             canInteract = function()
--                 return true
--             end,
--             triggerData = {
--                 triggerName = "open:chetao",
--                 args = {
--                     table = data,
--                     tableId = IsNearId
--                 }
--             }
--         })
--         exports['xn-textui']:create3DTextUI("banchetao3", {
--             coords = vector3(1730.5212, 3320.5552, 41.3845),
--             displayDist = 6.0,
--             interactDist = 2.0,
--             enableKeyClick = true, -- If true when you near it and click key it will trigger the event that you write inside triggerData
--             keyNum = 38,
--             key = "E",
--             text = "Crafting",
--             theme = "green", -- or red
--             job = "all", -- or the job you want to show this for
--             canInteract = function()
--                 return true
--             end,
--             triggerData = {
--                 triggerName = "open:chetao",
--                 args = {
--                     table = data,
--                     tableId = IsNearId
--                 }
--             }
--         })
-- end)


-- Không cần thread này nữa vì đã dùng ox_target

AddEventHandler('onResourceStop', function(resource)
    if resource == 'vierp.craftingx' then
        for k, v in ipairs(Tables) do
            DeleteObject(v)
        end
        -- Remove ox_target zones
        for i = 1, #Config do
            exports.ox_target:removeZone('crafting_table_' .. i)
        end
    end
end)


RegisterNetEvent('vierp.craftingx:openTable', function(tableId)
    if not IsOpen then
        local data = Config[tableId]
        if setup then
            SendNUIMessage({
                type = 'set-meta',
                path = Env.ImagePath,
                multiply = Env.TimeCalculator
            })
            setup = false
        end
        IsOpen = true
        SendNUIMessage({
            type = 'open',
            table = data,
            -- lucky = Config.Lucky,  -- BÙA MAY MẮN ĐÃ BỎ
            tableId = tableId
        })
        SetNuiFocus(true, true)
        TriggerScreenblurFadeOut()  -- Xóa blur nếu có từ resource khác
    end
end)
