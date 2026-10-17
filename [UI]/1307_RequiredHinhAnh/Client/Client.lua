local Core
if rlConfig.Inventory == "qb-inventory" then
    Core = exports["qb-core"]:GetCoreObject()
elseif rlConfig.Inventory == "ESX" then
    Core = exports["es_extended"]:getSharedObject()
end


RegisterCommand("ShowRequired", function()
    exports["rl_requirements"]:ShowRequirements({ 
        { 
            ["Amount"] = 1,
            ["Label"] = exports.ox_inventory:Items()["gold_ring"].label,
        }, 
        { 
            ["Amount"] = 21,
            ["Label"] = exports.ox_inventory:Items()["gold_ring"].label,
        }, 
    })
end)

exports("ShowRequirements", function(Requirements) 
    local Reqs = {}
    for Key, Value in pairs(Requirements) do
        for Item, ItemData in pairs(exports.ox_inventory:Items()) do
            if Value["Label"] == ItemData["label"] then
                local ItemCount = exports.ox_inventory:Search("count", Item)
                print(ItemCount)
                if ItemCount <= Value["Amount"] then
                    print(Item)
                    Reqs[#Reqs + 1] = {
                        ["Amount"] = Value["Amount"], 
                        ["Image"] = 'https://raw.githubusercontent.com/QuocHuyCrow/elephanttown/master/Items_KhoDo/'..Item..'.png', 
                        ["Label"] = ItemData.label,
                        ["Local"] = false,
                    }
                end
            end
        end
    end
    print(json.encode(Reqs))
    SendNUIMessage({
        Action = "SetRequirements", 
        Display = true,
        Requirements = Reqs
    })
end)        

exports(
    "HideRequirements",
    function()
        SendNUIMessage({
            Action = "SetRequirements", 
            Display = false,
        })
    end
)
