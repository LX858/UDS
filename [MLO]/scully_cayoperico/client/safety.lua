-- Safety layer for dual-map mode.
-- The dual-map method must NOT use IslandHopper because IslandHopper can cull San Andreas.
CreateThread(function()
    Wait(0)
    SetIslandHopperEnabled('HeistIsland', false)
    SetToggleMinimapHeistIsland(false)
    print('[scully_cayoperico] Dual-map safety active: IslandHopper OFF')
end)

RegisterCommand('dualmapreset', function()
    SetIslandHopperEnabled('HeistIsland', false)
    SetToggleMinimapHeistIsland(false)
    print('[scully_cayoperico] dualmapreset: IslandHopper OFF / San Andreas restored')
end, false)
