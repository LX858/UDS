
AlertServer = function(source, type, text) -- Thông báo server
    exports.qbx_core:Notify(source, text, type, 3000)
end

SelectItem = function(_, cb)
    local items = {}
    for name in pairs(exports.ox_inventory:Items()) do
        items[#items + 1] = { name = name }
    end
    cb(items)
end



