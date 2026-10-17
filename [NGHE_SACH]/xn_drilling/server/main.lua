MAIN = {}

function MAIN:Init()
    local o = {}
    setmetatable(o, {__index = MAIN})
    o.Platforms = {}
    o:InitPlatform()
    o:EventHander()
    o:CallbackHander()
    return o
end

function MAIN:InitPlatform()
    for k, v in ipairs(Config.Platforms) do
        self.Platforms[k] = PLATFORM:Init(k, v, nil)
    end
end

function MAIN:EventHander()


    RegisterNetEvent('ds-drilling:server:Drill', function(index, product)
        local rewardProduct = (Config.Reward[product] and product) or 'kerosene'
        local platform = self.Platforms[index]
        if not platform then return end

        if not platform:HasOil() then
            Notify(source, Config.Language['no_oil'], "error")
            return
        end

        local item = Config.Reward[rewardProduct].item
        local qty = Config.Reward[rewardProduct].qty

        if not CanAddItem(source, item, qty) then
            Notify(source, Config.Language['inventory_full'], "error")
            return
        end

        if platform:Drill() then
            if not AddItem(source, item, qty) then
                Notify(source, Config.Language['inventory_full'], "error")
            end
        else
            Notify(source, Config.Language['no_oil'], "error")
        end
    end)

    RegisterNetEvent('ds-drilling:server:leavePlatform', function(index)
        self.Platforms[index]:Leave(source)
    end)
end

RegisterServerEvent("ds-drilling:server:sellstuff")
AddEventHandler("ds-drilling:server:sellstuff", function(item, qty)
    local src = source
    if RemoveItem(source,item, qty) then
        AddMoney(src, Config.SellingPrices[item].price*qty)
    else
        Notify(src, Config.Language['no_oil_1'], "error")
    end
end)


Citizen.CreateThread(function()
    MAIN:Init()
end)