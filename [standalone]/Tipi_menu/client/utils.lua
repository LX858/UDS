
---@param action string The action you wish to target
---@param data any The data you wish to send along with this action
function SendReactMessage(action, data)
    SendNUIMessage({ action = action, data = data })
end

local currentResourceName = GetCurrentResourceName()

local debugIsEnabled = GetConvarInt(
    ('%s-debugMode'):format(currentResourceName), 0) == 1


function debugPrint(...)
    if not debugIsEnabled then return end
    local args <const> = { ... }

    local appendStr = ''
    for _, v in ipairs(args) do appendStr = appendStr .. ' ' .. tostring(v) end
    local msgTemplate = '^3[%s]^0%s'
    local finalMsg = msgTemplate:format(currentResourceName, appendStr)
    print(finalMsg)
end

function GetCoinAmounts(accounts)
    for _, v in pairs(accounts) do
        if v.name == 'coin' then
            return tonumber(v.money) or 0
        end
    end
    return 0
end

function GetCoinAmounts2(accounts)
    for _, v in pairs(accounts) do
        if v.name == 'point' then
            return tonumber(v.money) or 0
        end
    end
    return 0
end
