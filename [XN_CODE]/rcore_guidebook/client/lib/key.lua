Key = {}
Key.Register = function(name, desc, key, cbPlus, cbMinus)
    if cbPlus == nil and cbMinus == nil then
        dbg.critical("At least one callback must be filled!")
        return
    end

    cbPlus = cbPlus or function()  end
    cbMinus = cbMinus or function()  end

    local plusCmd = string.format('+%s', name)
    local minusCmd = string.format('-%s', name)

    RegisterKeyMapping(plusCmd, desc, 'keyboard', key)
    RegisterCommand(plusCmd, cbPlus)
    RegisterCommand(minusCmd, cbMinus)

    dbg.debug('Register key mapping %s - %s %s - %s', name, plusCmd, minusCmd, key)
end

