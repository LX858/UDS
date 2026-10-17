
if GetResourceState('qbx_core') ~= 'started' then return end

Framework = {}
Framework.Name = 'QBox'

--- Return the QBX player object for a given server ID.
--- @param  src  integer      Player server ID
--- @return table|nil         QBX player object, or nil if not found
function Framework.GetPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end
