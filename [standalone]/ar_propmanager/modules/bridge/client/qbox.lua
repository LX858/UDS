if GetResourceState('qbx_core') ~= 'started' then return end

Framework = {}
Framework.Name = 'QBox'

--- Return whether the local player is currently logged in.
--- @return boolean
function Framework.IsLoaded()
    return LocalPlayer.state.isLoggedIn
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() 
    Framework.OnLoaded()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function() 
    Framework.OnUnloaded()
end)