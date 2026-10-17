if Config.Framework ~= 'QBcore' then return end
QBCore = exports['qb-core']:GetCoreObject()


function OpenMenuAlcomat(elements)
    local menuElements = {}

    for _, v in ipairs(elements) do
        table.insert(menuElements, {
            header = v.label,
            txt = "",
            params = {
                event = "nrg_alcoeffect:client:SendAlcoCheck",
                args = {
                    id = v.value
                }
            }
        })
    end

    exports['qb-menu']:openMenu(menuElements)
end