local QBCore = exports['qb-core']:GetCoreObject()
local poppyPed = nil

-- Tạo NPC bán hạt giống Hoa Mỹ Nhân
local function CreatePoppyPed()
    if PoppyShop and PoppyShop.Enabled == false then
        return
    end

    local config = PoppyShop or {
        Enabled = true,
        PedLocation = vector4(1430.0602, -2316.8923, 66.8418, 322.8018),
        PedModel = 'a_m_m_farmer_01'
    }

    local pedModel = config.PedModel or 'a_m_m_farmer_01'
    local pedCoords = config.PedLocation or vector4(1430.0602, -2316.8923, 66.8418, 322.8018)

    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(5)
    end

    poppyPed = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)
    FreezeEntityPosition(poppyPed, true)
    SetEntityInvincible(poppyPed, true)
    SetBlockingOfNonTemporaryEvents(poppyPed, true)

    if config.Blip and config.Blip.enabled then
        local blip = AddBlipForCoord(pedCoords.x, pedCoords.y, pedCoords.z)
        SetBlipSprite(blip, config.Blip.sprite or 285)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, config.Blip.scale or 0.7)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, config.Blip.color or 2)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(config.Blip.label or "Cửa Hàng Hoa Mỹ Nhân")
        EndTextCommandSetBlipName(blip)
    end

    exports.ox_target:addLocalEntity(poppyPed, {
        {
            name = 'poppy_shop_menu',
            icon = 'fas fa-cannabis',
            label = 'Mua Hạt Giống Hoa Mỹ Nhân',
            distance = 2.5,
            onSelect = function()
                TriggerEvent('xn_farming:openPoppyShop')
            end
        }
    })
end

CreateThread(function()
    CreatePoppyPed()
end)

-- Event mở menu Context
RegisterNetEvent('xn_farming:openPoppyShop', function()
    if PoppyShop and PoppyShop.Enabled == false then
        QBCore.Functions.Notify('Cửa hàng này hiện đang tạm đóng!', 'error')
        return
    end

    local shopItems = (PoppyShop and PoppyShop.Items) or {
        {
            item = 'hatgiong_hoamynhan',
            label = 'Hạt Giống Hoa Mỹ Nhân',
            price = 100,
            description = 'Hạt giống trồng hoa mỹ nhân'
        }
    }

    local options = {}

    for _, itemData in ipairs(shopItems) do
        table.insert(options, {
            title = itemData.label,
            description = string.format("%s - Giá: $%d / hạt", itemData.description, itemData.price),
            icon = 'seedling',
            onSelect = function()
                local input = lib.inputDialog(string.format('Mua %s', itemData.label), {
                    {
                        type = 'number',
                        label = 'Số lượng cần mua',
                        description = string.format('Giá: $%d/hạt (Tối thiểu: 1, Tối đa: 99)', itemData.price),
                        icon = 'seedling',
                        required = true,
                        min = 1,
                        max = 99,
                        default = 1
                    }
                })

                if input and input[1] then
                    local quantity = tonumber(input[1])
                    if quantity and quantity >= 1 and quantity <= 99 then
                        BuyPoppyItem(itemData.item, quantity, itemData.price, itemData.label)
                    else
                        QBCore.Functions.Notify('Số lượng không hợp lệ (từ 1 đến 99)!', 'error')
                    end
                end
            end
        })
    end

    lib.registerContext({
        id = 'poppy_shop_context',
        title = 'Cửa Hàng Hoa Mỹ Nhân',
        options = options
    })
    lib.showContext('poppy_shop_context')
end)

function BuyPoppyItem(item, quantity, unitPrice, itemLabel)
    local totalPrice = unitPrice * quantity

    if lib.progressBar({
        duration = 2000,
        label = string.format('Đang mua %dx %s...', quantity, itemLabel),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a',
            flag = 1,
        }
    }) then
        QBCore.Functions.TriggerCallback('xn_farming:buyItem', function(success, message)
            if success then
                QBCore.Functions.Notify(message, 'success')
            else
                QBCore.Functions.Notify(message, 'error')
            end
        end, item, quantity, totalPrice)
    else
        QBCore.Functions.Notify('Đã hủy giao dịch!', 'error')
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and poppyPed and DoesEntityExist(poppyPed) then
        DeleteEntity(poppyPed)
    end
end)
