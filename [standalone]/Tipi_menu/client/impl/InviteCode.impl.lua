local Impl = NewImpl('InviteCode')

function Impl:OnReady()
    for _, action in ipairs({ 'getState', 'redeem' }) do
        RegisterNUICallback('inviteCode:' .. action, function(body, cb)
            local ok, result = pcall(lib.callback.await, 'Tipi_menu:sv:invite:' .. action, false, body)
            cb(ok and type(result) == 'table' and result or { ok = false, message = 'Không thể kết nối hệ thống mã mời. Vui lòng thử lại.' })
        end)
    end
end
