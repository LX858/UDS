RegisterNetEvent('xn:client:UseBandage', function()
    local ped = PlayerPedId()
    
    -- Kiểm tra trạng thái ngất
    if LocalPlayer.state.isDead or LocalPlayer.state.isLastStand then
        exports.qbx_core:Notify("Không thể sử dụng khi bị ngất!", "error")
        return
    end
    
    if lib.progressBar({
        duration = math.random(3000, 5000),
        label = 'Đang hồi máu...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            mouse = false,
            combat = true,
        },
        anim = {
            dict = "anim@amb@business@weed@weed_inspecting_high_dry@",
            clip = "weed_inspecting_high_base_inspector",
            flag = 49,
        },
    }) then
        SetEntityHealth(ped, GetEntityHealth(ped) + 10)
        Wait(500)
        TriggerEvent('qbx_medical:client:painkillers')
    else
        exports.qbx_core:Notify("Đã hủy hồi máu...", "error")
    end
end)