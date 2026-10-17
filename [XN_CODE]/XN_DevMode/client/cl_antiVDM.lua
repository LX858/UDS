-- -- Tối ưu hóa anti-VDM sử dụng ox_lib cache system
-- lib.onCache('ped', function(ped)
--     if ped then
--         SetPedConfigFlag(ped, 43, true) -- Disable Lock-on
--     end
-- end)

-- -- Backup method sử dụng event (nếu lib.onCache không hoạt động)
-- -- AddEventHandler('skinchanger:modelLoaded', function()
-- --     local ped = PlayerPedId()
-- --     SetPedConfigFlag(ped, 43, true)
-- -- end)

-- -- Alternative method với interval thay vì Wait(0)
-- -- lib.interval(function()
-- --     local ped = PlayerPedId()
-- --     SetPedConfigFlag(ped, 43, true)
-- -- end, 1000) -- Check every 1 second thay vì mỗi frame