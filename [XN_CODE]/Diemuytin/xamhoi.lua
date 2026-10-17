-- -- ============================================
-- -- Sám hối SYSTEM - Hồi điểm uy tín qua Yoga
-- -- ============================================

-- local QBX = exports.qbx_core
-- local isDoingYoga = false
-- local yogaBlip = nil
-- local currentYogaTask = nil

-- -- Cấu hình hệ thống Sám hối
-- local XamHoiConfig = {
--     targetLocation = vec3(200.55, -924.93, 29.82), -- Vị trí ox_target
--     yogaLocation = vec4(204.14, -915.96, 29.93, 154.32), -- Vị trí thực hiện yoga với heading
--     reputationGain = 1, -- Số điểm uy tín được cộng mỗi lần yoga thành công
--     yogaDuration = 10000, -- Thời gian yoga (10 giây)
--     cooldownTime = 30000, -- Thời gian cooldown giữa các lần yoga (30 giây)
    
--     -- Cấu hình animation
--     prayerAnim = {
--         type = "scenario",
--         dict = "Scenario",
--         anim = "WORLD_HUMAN_YOGA"
--     },
    
--     -- Cấu hình blip
--     blip = {
--         sprite = 77, -- Icon yoga
--         color = 3, -- Màu xanh lá
--         scale = 0.8,
--         name = "Khu vực Sám hối"
--     },
    
--     -- Cấu hình ox_target
--     target = {
--         icon = "fa-solid fa-person-praying",
--         label = "Sám hối",
--         distance = 2.5
--     }
-- }

-- -- Biến theo dõi cooldown
-- local lastYogaTime = 0

-- -- ============================================
-- -- CLIENT SIDE FUNCTIONS
-- -- ============================================

-- -- Tạo blip cho khu vực Sám hối
-- local function createXamHoiBlip()
--     if yogaBlip then
--         RemoveBlip(yogaBlip)
--     end
    
--     yogaBlip = AddBlipForCoord(XamHoiConfig.targetLocation.x, XamHoiConfig.targetLocation.y, XamHoiConfig.targetLocation.z)
--     SetBlipSprite(yogaBlip, XamHoiConfig.blip.sprite)
--     SetBlipDisplay(yogaBlip, 4)
--     SetBlipScale(yogaBlip, XamHoiConfig.blip.scale)
--     SetBlipColour(yogaBlip, XamHoiConfig.blip.color)
--     SetBlipAsShortRange(yogaBlip, true)
--     BeginTextCommandSetBlipName("STRING")
--     AddTextComponentString(XamHoiConfig.blip.name)
--     EndTextCommandSetBlipName(yogaBlip)
-- end

-- -- Bắt đầu hoạt động yoga
-- local function startYogaActivity()
--     if isDoingYoga then return end
    
--     local currentTime = GetGameTimer()
--     if (currentTime - lastYogaTime) < XamHoiConfig.cooldownTime then
--         local remainingTime = math.ceil((XamHoiConfig.cooldownTime - (currentTime - lastYogaTime)) / 1000)
--         exports.ox_lib:notify({
--             title = 'Sám hối',
--             description = 'Bạn cần nghỉ ngơi thêm ' .. remainingTime .. ' giây nữa',
--             type = 'error'
--         })
--         return
--     end
    
--     isDoingYoga = true
--     local playerPed = PlayerPedId()
    
--     -- Xoay người chơi về hướng phù hợp từ config
--     SetEntityHeading(playerPed, XamHoiConfig.yogaLocation.w)
    
--     exports.ox_lib:notify({
--         title = 'Sám hối',
--         description = 'Bạn bắt đầu thiền định. Giữ yên để hoàn thành...',
--         type = 'inform'
--     })
    
--     -- Bắt đầu animation yoga sử dụng scenario
--     TaskStartScenarioInPlace(playerPed, XamHoiConfig.prayerAnim.anim, 0, true)
    
--     -- Đếm ngược thời gian yoga
--     local yogaProgress = 0
--     local maxProgress = XamHoiConfig.yogaDuration / 100 -- Chia thành 100 bước
    
--     CreateThread(function()
--         while isDoingYoga and yogaProgress < maxProgress do
--             Wait(100)
            
--             -- Kiểm tra xem người chơi có đang thực hiện scenario không
--             if not IsPedUsingScenario(playerPed, XamHoiConfig.prayerAnim.anim) then
--                 -- Animation bị gián đoạn
--                 exports.ox_lib:notify({
--                     title = 'Sám hối',
--                     description = 'Bạn đã ngừng thiền định. Hãy thử lại!',
--                     type = 'error'
--                 })
--                 isDoingYoga = false
--                 return
--             end
            
--             -- Kiểm tra xem người chơi có nhấn X để hủy không
--             if IsControlJustPressed(0, 73) then -- X key
--                 exports.ox_lib:notify({
--                     title = 'Sám hối',
--                     description = 'Bạn đã hủy thiền định!',
--                     type = 'error'
--                 })
--                 ClearPedTasks(playerPed)
--                 isDoingYoga = false
--                 return
--             end
            
--             yogaProgress = yogaProgress + 1
            
--             -- Hiển thị progress (tùy chọn)
--             local progressPercent = math.floor((yogaProgress / maxProgress) * 100)
--             if progressPercent % 20 == 0 then -- Hiển thị mỗi 20%
--                 exports.ox_lib:notify({
--                     title = 'Thiền định',
--                     description = 'Tiến độ: ' .. progressPercent .. '%',
--                     type = 'inform'
--                 })
--             end
--         end
        
--         -- Hoàn thành yoga thành công
--         if isDoingYoga then
--             ClearPedTasks(playerPed)
--             isDoingYoga = false
--             lastYogaTime = GetGameTimer()
            
--             -- Trigger server event để cộng điểm uy tín
--             TriggerServerEvent('xamhoi:completeYoga')
            
--             exports.ox_lib:notify({
--                 title = 'Sám hối thành công',
--                 description = 'Bạn đã hoàn thành thiền định và được cộng ' .. XamHoiConfig.reputationGain .. ' điểm uy tín!',
--                 type = 'success'
--             })
--         end
--     end)
-- end

-- -- Di chuyển người chơi đến vị trí yoga
-- local function moveToYogaLocation()
--     local playerPed = PlayerPedId()
--     local targetCoords = vector3(XamHoiConfig.yogaLocation.x, XamHoiConfig.yogaLocation.y, XamHoiConfig.yogaLocation.z)
    
--     -- Tạo task đi bộ đến vị trí yoga
--     TaskGoToCoordAnyMeans(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, 0, false, 786603, 0.0)
    
--     -- Chờ đến khi người chơi đến gần vị trí yoga
--     CreateThread(function()
--         while true do
--             Wait(500)
--             local playerPos = GetEntityCoords(playerPed)
--             local distance = #(playerPos - targetCoords)
            
--             if distance < 2.0 then
--                 ClearPedTasks(playerPed)
--                 startYogaActivity()
--                 break
--             end
--         end
--     end)
-- end

-- -- Setup ox_target
-- local function setupOxTarget()
--     if not exports.ox_target then
--         --print('[XAMHOI ERROR] ox_target not found!')
--         return
--     end
    
--     exports.ox_target:addSphereZone({
--         coords = XamHoiConfig.targetLocation,
--         radius = XamHoiConfig.target.distance,
--         options = {
--             {
--                 name = 'xamhoi_start',
--                 icon = XamHoiConfig.target.icon,
--                 label = XamHoiConfig.target.label,
--                 onSelect = function()
--                     if isDoingYoga then
--                         exports.ox_lib:notify({
--                             title = 'Sám hối',
--                             description = 'Bạn đang trong quá trình thiền định!',
--                             type = 'error'
--                         })
--                         return
--                     end
                    
--                     exports.ox_lib:notify({
--                         title = 'Sám hối',
--                         description = 'Bạn đang di chuyển đến khu vực thiền định...',
--                         type = 'inform'
--                     })
                    
--                     moveToYogaLocation()
--                 end
--             }
--         }
--     })
-- end

-- -- ============================================
-- -- SERVER SIDE EVENTS (Cần đặt trong server/main.lua)
-- -- ============================================

-- --[[
-- -- Thêm vào server/main.lua:

-- -- Event xử lý hoàn thành yoga và cộng điểm uy tín
-- RegisterNetEvent('xamhoi:completeYoga', function()
--     local src = source
--     local Player = QBX.Functions.GetPlayer(src)
    
--     if not Player then
--         --print('[XAMHOI ERROR] Không tìm thấy player data cho source: ' .. src)
--         return
--     end
    
--     local citizenId = Player.PlayerData.citizenid
    
--     --print('[XAMHOI DEBUG] Player ' .. citizenId .. ' hoàn thành yoga')
    
--     -- Lấy uy tín hiện tại
--     local result = MySQL.scalar.await('SELECT reputation FROM player_reputation WHERE citizenid = ?', {citizenId})
--     local currentReputation = result or Config.ReputationSystem.defaultReputation
    
--     -- Tính điểm uy tín mới (cộng thêm 1 điểm)
--     local reputationGain = 1
--     local newReputation = math.min(Config.ReputationSystem.maxReputation, currentReputation + reputationGain)
    
--     --print('[XAMHOI DEBUG] Reputation update: ' .. currentReputation .. ' -> ' .. newReputation .. ' (gain: +' .. reputationGain .. ')')
    
--     -- Cập nhật database
--     if result then
--         MySQL.update.await('UPDATE player_reputation SET reputation = ? WHERE citizenid = ?', {newReputation, citizenId})
--     else
--         MySQL.insert.await('INSERT INTO player_reputation (citizenid, reputation) VALUES (?, ?)', {citizenId, newReputation})
--     end
    
--     -- Thông báo cho người chơi
--     TriggerClientEvent('ox_lib:notify', src, {
--         title = 'Uy tín được cộng',
--         description = string.format('Bạn được cộng %s điểm uy tín qua Sám hối. Uy tín hiện tại: %s', 
--                                    reputationGain, newReputation),
--         type = 'success'
--     })
-- end)
-- --]]

-- -- ============================================
-- -- INITIALIZATION
-- -- ============================================

-- CreateThread(function()
--     -- Đợi game load xong
--     while not NetworkIsPlayerActive(PlayerId()) do
--         Wait(500)
--     end
    
--     -- Tạo blip và setup ox_target
--     createXamHoiBlip()
--     setupOxTarget()
    
--     --print('[XAMHOI] Hệ thống Sám hối đã được khởi tạo!')
-- end)

-- -- Cleanup khi resource stop
-- AddEventHandler('onResourceStop', function(resourceName)
--     if resourceName == GetCurrentResourceName() then
--         if yogaBlip then
--             RemoveBlip(yogaBlip)
--         end
--         if isDoingYoga then
--             ClearPedTasks(PlayerPedId())
--         end
--     end
-- end)
