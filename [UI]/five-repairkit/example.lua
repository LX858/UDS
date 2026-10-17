local function runRepairkitDemo(difficulty)
    local minigame = exports["five-repairkit"]:Minigame(difficulty)

    if minigame then
        print('[five-repairkit] User won the minigame with difficulty: ' .. tostring(difficulty or 'medium'))
    else
        print('[five-repairkit] User lost the minigame with difficulty: ' .. tostring(difficulty or 'medium'))
    end

    return minigame
end

exports('DemoRepairkit', runRepairkitDemo)

-- RegisterCommand('testrepairkit', function(source, args)
--     local difficulty = args[1] or 'medium'
--     runRepairkitDemo(difficulty)
-- end)

-- RegisterKeyMapping('testrepairkit', 'Test five-repairkit minigame', 'KEYBOARD', 'G')
