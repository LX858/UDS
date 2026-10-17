-- slide = true
-- local isSliding = false 

-- function IsSlideAvailable()
--     return slide and not isSliding 
-- end
-- exports('IsSlideAvailable', IsSlideAvailable)

-- RegisterCommand("slide", function()
--     if not IsPedInAnyVehicle(PlayerPedId(), false) then
--         local ped = PlayerPedId()
--         local ad = "missheistfbi3b_ig6_v2"
--         local anim = "rubble_slide_franklin"
--         if slide and not isSliding then
--             isSliding = true  
            
--             CreateThread(function()
--                 while isSliding do
--                     Wait(0)
--                     DisableControlAction(0, 142, true) 
--                     DisableControlAction(0, 24, true)  
--                     DisableControlAction(0, 257, true) 
--                     DisableControlAction(0, 263, true) 
--                     DisableControlAction(0, 25, true)  
--                 end
--             end)
--             slide = false
--             ClearPedSecondaryTask(ped)

--             loadAnimDict(ad)
--             SetPedMoveRateOverride(ped, 1.25)
--             ClearPedSecondaryTask(ped)
--             TaskPlayAnim(ped, ad, anim, 3.0, 1.0, -1, 01, 0, 0, 0, 0)
--             ApplyForceToEntityCenterOfMass(ped, 1, 0, 20.0, 0.8, true, true, true, true)
--             Wait(100)
--             TaskPlayAnim(ped, ad, "exit", 3.0, 1.0, -1, 01, 0, 0, 0, 0)
--             ClearPedSecondaryTask(ped)
--             Wait(100)
--             isSliding = false  

--             Wait(10 * 1000)  

--             slide = true
--             exports.qbx_core:Notify('Bạn đã có thể trượt tiếp', 'success')
--         else
--             exports.qbx_core:Notify('Vui lòng đợi', 'success') 
--         end
--     end
-- end, false)

-- RegisterKeyMapping("slide", "<FONT FACE='Oswald'>Hành động trượt</FONT>", "keyboard", "H")

-- function loadAnimDict(dict)
--     while (not HasAnimDictLoaded(dict)) do
--         RequestAnimDict(dict)
--         Wait(5)
--     end
-- end