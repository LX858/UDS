local sharedConfig = require 'config.shared'

---@alias source number

-- ============================================================
-- Discord Webhook Log
-- ============================================================
local DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/1512201972445483018/vDBZOIBJolbFZZkzxOtoM0IVs7LL0dliK6AXzuGA8x6fX549KadFu2HoMfC4WdcD1oTx'

---Gửi log y tế về Discord
---@param action string  'Cứu sống' hoặc 'Chữa trị'
---@param doctorId number
---@param doctorName string
---@param patientId number
---@param patientName string
local function sendDiscordLog(action, doctorId, doctorName, patientId, patientName)
    local time = os.date('%d/%m/%Y %H:%M:%S')
    local color = (action == 'Cứu sống') and 15158332 or 3447003 -- đỏ: cứu sống | xanh: chữa trị
    local payload = json.encode({
        embeds = {
            {
                title = '🏥 Nhật Ký Y Tế',
                color = color,
                fields = {
                    { name = 'Hành động',  value = action,                                     inline = false },
                    { name = 'Bác sĩ',    value = 'ID: **' .. doctorId  .. '** | ' .. doctorName,  inline = true  },
                    { name = 'Bệnh nhân', value = 'ID: **' .. patientId .. '** | ' .. patientName, inline = true  },
                    { name = 'Thời gian', value = time,                                        inline = false },
                },
                footer = { text = 'Hệ thống Y tế' },
            }
        }
    })
    PerformHttpRequest(DISCORD_WEBHOOK, function() end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

lib.callback.register('qbx_ambulancejob:server:getPlayerStatus', function(_, targetSrc)
	return exports.qbx_medical:GetPlayerStatus(targetSrc)
end)

lib.callback.register('qbx_ambulancejob:server:isPlayerDownedOrDead', function(_, targetSrc)
	targetSrc = tonumber(targetSrc)
	if not targetSrc or targetSrc <= 0 or not exports.qbx_core:GetPlayer(targetSrc) then
		return false
	end
	local success, isDownedOrDead = pcall(function()
		return lib.callback.await('qbx_ambulancejob:client:isPlayerDownedOrDead', targetSrc)
	end)
	return success and isDownedOrDead or false
end)

local function alertAmbulance(src, text)
	local ped = GetPlayerPed(src)
	local coords = GetEntityCoords(ped)
	local _, doctors = exports.qbx_core:GetDutyCountType('ems')
	if doctors and #doctors > 0 then
		for i = 1, #doctors do
			TriggerClientEvent('hospital:client:ambulanceAlert', doctors[i], coords, text)
		end
	end
end

local function registerArmory()
	for _, armory in pairs(sharedConfig.locations.armory) do
		exports.ox_inventory:RegisterShop(armory.shopType, armory)
	end
end

local function registerStashes()
    for _, stash in pairs(sharedConfig.locations.stash) do
        exports.ox_inventory:RegisterStash(stash.name, stash.label, stash.slots, stash.weight, stash.owner, stash.groups, stash.location)
    end
end

RegisterNetEvent('hospital:server:ambulanceAlert', function(text)
	if GetInvokingResource() then return end
	local src = source
	alertAmbulance(src, text or locale('info.civ_down'))
end)

RegisterNetEvent('hospital:server:emergencyAlert', function()
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	alertAmbulance(src, locale('info.ems_down', player.PlayerData.charinfo.lastname))
end)

RegisterNetEvent('qbx_medical:server:onPlayerLaststand', function()
	if GetInvokingResource() then return end
	local src = source
	--alertAmbulance(src, locale('info.civ_down'))
end)

---@param playerId number
RegisterNetEvent('hospital:server:TreatWounds', function(playerId)
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local patient = exports.qbx_core:GetPlayer(playerId)
	if player.PlayerData.job.type ~= 'ems' or not patient then return end

	-- Revive player để reset toàn bộ trạng thái
	TriggerClientEvent('qbx_medical:client:playerRevived', patient.PlayerData.source)

	-- Discord log
	local doctorName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
	local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname
	sendDiscordLog('Chữa trị vết thương', src, doctorName, playerId, patientName)
end)

---Freeze/Unfreeze người chơi đang được điều trị
---@param playerId number
---@param freeze boolean
RegisterNetEvent('hospital:server:SetPatientTreatment', function(playerId, freeze)
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player or player.PlayerData.job.type ~= 'ems' then return end

	local patient = exports.qbx_core:GetPlayer(playerId)
	if not patient then return end

	TriggerClientEvent('hospital:client:SetBeingTreated', patient.PlayerData.source, freeze)
end)

---Set máu cho người chơi
---@param playerId number
---@param health number
RegisterNetEvent('hospital:server:SetPlayerHealth', function(playerId, health)
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player or player.PlayerData.job.type ~= 'ems' then return end

	local patient = exports.qbx_core:GetPlayer(playerId)
	if not patient then return end

	-- Set máu trên client của patient
	TriggerClientEvent('hospital:client:SetHealth', patient.PlayerData.source, health)
end)

---Gửi yêu cầu chữa trị đến bệnh nhân
---@param playerId number ID của bệnh nhân
---@param doctorName string Tên của bác sĩ
---@param cost number Chi phí điều trị
RegisterNetEvent('hospital:server:RequestTreatment', function(playerId, doctorName, cost)
	if GetInvokingResource() then return end
	local src = source
	local doctor = exports.qbx_core:GetPlayer(src)
	if not doctor or doctor.PlayerData.job.type ~= 'ems' then return end

	local patient = exports.qbx_core:GetPlayer(playerId)
	if not patient then return end

	-- Gửi yêu cầu chữa trị đến client của bệnh nhân
	TriggerClientEvent('hospital:client:ReceiveTreatmentRequest', patient.PlayerData.source, src, doctorName, cost)
end)

---Bệnh nhân đồng ý chữa trị
---@param doctorId number ID của bác sĩ
RegisterNetEvent('hospital:server:AcceptTreatment', function(doctorId)
	if GetInvokingResource() then return end
	local src = source
	local patient = exports.qbx_core:GetPlayer(src)
	local doctor = exports.qbx_core:GetPlayer(doctorId)

	if not patient or not doctor then return end

	-- Tạo hóa đơn ngay khi đồng ý
	local invoiceData = {
		target = src,
		society = "ambulance",
		society_name = "Bác sĩ",
		invoice_item = "Chữa trị vết thương",
		invoice_value = sharedConfig.chuatri or 2000,
		invoice_notes = "Điều trị bởi " .. doctor.PlayerData.charinfo.firstname .. " " .. doctor.PlayerData.charinfo.lastname
	}

	local phantram = (sharedConfig.chuatri or 2000) * 0.1
	doctor.Functions.AddMoney("cash", phantram, "% Hóa đơn bác sĩ")
	TriggerClientEvent('hospital:client:CreateInvoiceWrapper', doctorId, invoiceData)

	-- Thông báo cho bác sĩ và bắt đầu điều trị
	TriggerClientEvent('hospital:client:StartTreatment', doctor.PlayerData.source, src)
	exports.qbx_core:Notify(doctor.PlayerData.source, 'Bệnh nhân đã đồng ý điều trị', 'success')

	-- Discord log
	local doctorName = doctor.PlayerData.charinfo.firstname .. ' ' .. doctor.PlayerData.charinfo.lastname
	local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname
	sendDiscordLog('Chữa trị (bệnh nhân đã đồng ý)', doctorId, doctorName, src, patientName)
end)

---Bệnh nhân từ chối chữa trị
---@param doctorId number ID của bác sĩ
RegisterNetEvent('hospital:server:DeclineTreatment', function(doctorId)
	if GetInvokingResource() then return end
	local src = source
	local doctor = exports.qbx_core:GetPlayer(doctorId)

	if not doctor then return end

	-- Thông báo cho bác sĩ rằng bệnh nhân đã từ chối
	exports.qbx_core:Notify(doctor.PlayerData.source, 'Bệnh nhân đã từ chối điều trị', 'error')
end)

---Bắt đầu quy trình điều trị trên giường
---@param playerId number ID của bệnh nhân
RegisterNetEvent('hospital:server:StartBedTreatment', function(playerId)
	if GetInvokingResource() then return end
	local src = source
	local doctor = exports.qbx_core:GetPlayer(src)
	local patient = exports.qbx_core:GetPlayer(playerId)

	if not doctor or not patient then return end
	if doctor.PlayerData.job.type ~= 'ems' then return end

	-- Trigger event cho bệnh nhân để đưa lên giường
	TriggerClientEvent('hospital:client:BedTreatment', patient.PlayerData.source)
end)

---Hoàn thành điều trị - set máu và reset injuries
RegisterNetEvent('hospital:server:CompleteTreatment', function()
	if GetInvokingResource() then return end
	local src = source
	local patient = exports.qbx_core:GetPlayer(src)

	if not patient then return end

	-- Set máu về max
	TriggerClientEvent('hospital:client:SetHealth', src, 200)

	-- Reset tất cả injuries
	TriggerClientEvent('hospital:client:ResetAllInjuries', src)

	-- Revive để reset trạng thái
	TriggerClientEvent('qbx_medical:client:playerRevived', src)
end)

---@param playerId number
RegisterNetEvent('hospital:server:RevivePlayer', function(playerId)
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local patient = exports.qbx_core:GetPlayer(playerId)

	if not patient then return end

	exports.ox_inventory:RemoveItem(player.PlayerData.source, 'firstaid', 1)
	TriggerClientEvent('qbx_medical:client:playerRevived', patient.PlayerData.source)

	-- Discord log
	local doctorName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
	local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname
	sendDiscordLog('Cứu sống', src, doctorName, playerId, patientName)

	-- Thống kê số lượt cứu trong tuần của Bác sĩ
	if TrackDoctorRevive then
		TrackDoctorRevive(src)
	end
end)

---Cho bệnh nhân nằm xuống trước khi CPR
---@param playerId number
RegisterNetEvent('hospital:server:preparePatientForCPR', function(playerId)
	if GetInvokingResource() then return end
	local patient = exports.qbx_core:GetPlayer(playerId)
	if not patient then return end

	TriggerClientEvent('hospital:client:prepareForCPR', patient.PlayerData.source)
end)

---Sync CPR animation cho bệnh nhân
---@param playerId number
RegisterNetEvent('hospital:server:syncCPRAnimation', function(playerId, cprTime)
	if GetInvokingResource() then return end
	local patient = exports.qbx_core:GetPlayer(playerId)
	if not patient then return end

	TriggerClientEvent('hospital:client:receiveCPR', patient.PlayerData.source, cprTime)
end)

---Tạo hóa đơn cho bệnh nhân
---@param playerId number ID của người chơi nhận hóa đơn
---@param amount number Số tiền hóa đơn
---@param reason string Lý do tạo hóa đơn
RegisterNetEvent('hospital:server:CreateMedicalInvoice', function(playerId, amount, reason)
	--print("^2[INVOICE] Event received!^0")
	--print("^3playerId:^0", playerId)
	--print("^3amount:^0", amount)
	--print("^3reason:^0", reason)

	if GetInvokingResource() then
		--print("^1[INVOICE] Blocked by GetInvokingResource^0")
		return
	end

	local src = source
	--print("^3src:^0", src)

	local doctor = exports.qbx_core:GetPlayer(src)
	local patient = exports.qbx_core:GetPlayer(playerId)
    local phantram = amount * 0.1

	--print("^3doctor:^0", doctor and "Found" or "nil")
	--print("^3patient:^0", patient and "Found" or "nil")

	if not doctor or not patient then
		--print("^1[INVOICE] Doctor or patient not found^0")
		return
	end

	--print("^3doctor.job.type:^0", doctor.PlayerData.job.type)

	if doctor.PlayerData.job.type ~= 'ems' then
		--print("^1[INVOICE] Not EMS^0")
		return
	end

	--print("^2[INVOICE] Preparing invoice data^0")

	-- Chuẩn bị data theo đúng format của okokBilling
	local invoiceData = {
		target = playerId,
		society = "ambulance",
		society_name = "Bác sĩ",
		invoice_item = reason or "Điều trị y tế",
		invoice_value = amount or 0,
		invoice_notes = "Điều trị bởi " .. doctor.PlayerData.charinfo.firstname .. " " .. doctor.PlayerData.charinfo.lastname
	}

	--print("^2[INVOICE] Sending to doctor's client (src=" .. src .. "):^0", json.encode(invoiceData))

	-- Gửi về client của doctor để trigger event okokBilling từ đó
    doctor.Functions.AddMoney("cash", phantram, "% Hóa đơn bác sĩ")
    exports.ox_inventory:AddItem(src, 'phieu_luong_y', 1)
	TriggerClientEvent('hospital:client:CreateInvoiceWrapper', src, invoiceData)

	--print("^2[INVOICE] Event sent!^0")
end)---@param targetId number
RegisterNetEvent('hospital:server:UseFirstAid', function(targetId)
	if GetInvokingResource() then return end
	local src = source
	targetId = tonumber(targetId)
	if not targetId or targetId <= 0 then return end
	local target = exports.qbx_core:GetPlayer(targetId)
	if not target then return end

	local success, canHelp = pcall(function()
		return lib.callback.await('hospital:client:canHelp', targetId)
	end)
	if not success or not canHelp then
		exports.qbx_core:Notify(src, locale('error.cant_help'), 'error')
		return
	end

	TriggerClientEvent('hospital:client:HelpPerson', src, targetId)
end)

lib.callback.register('qbx_ambulancejob:server:getNumDoctors', function()
	return exports.qbx_core:GetDutyCountType('ems')
end)


---@param src number
---@param event string
local function triggerEventOnEmsPlayer(src, event)
	local player = exports.qbx_core:GetPlayer(src)
	if player.PlayerData.job.type ~= 'ems' then
		exports.qbx_core:Notify(src, locale('error.not_ems'), 'error')
		return
	end

	TriggerClientEvent(event, src)
end

-- lib.addCommand('status', {
--     help = locale('info.check_health'),
-- }, function(source)
-- 	triggerEventOnEmsPlayer(source, 'hospital:client:CheckStatus')
-- end)

-- lib.addCommand('heal', {
--     help = locale('info.heal_player'),
-- }, function(source)
-- 	triggerEventOnEmsPlayer(source, 'hospital:client:TreatWounds')
-- end)

-- lib.addCommand('revivep', {
--     help = locale('info.revive_player'),
-- }, function(source)
-- 	triggerEventOnEmsPlayer(source, 'hospital:client:RevivePlayer')
-- end)

-- Items
---@param src number
---@param item table
---@param event string
local function triggerItemEventOnPlayer(src, item, event)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end

	if exports.ox_inventory:Search(src, 'count', item.name) == 0 then return end

	local removeItem = lib.callback.await(event, src)
	if not removeItem then return end

	exports.ox_inventory:RemoveItem(src, item.name, 1)
end

exports.qbx_core:CreateUseableItem('ifaks', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseIfaks')
end)

exports.qbx_core:CreateUseableItem('bandage', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseBandage')
end)

exports.qbx_core:CreateUseableItem('bandage_lv2', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseBandageLv2')
end)

exports.qbx_core:CreateUseableItem('painkillers', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UsePainkillers')
end)

exports.qbx_core:CreateUseableItem('firstaid', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseFirstAid')
end)

exports.qbx_core:CreateUseableItem('ao_giap_gang_lv1', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseAoGiapGang')
end)

exports.qbx_core:CreateUseableItem('ao_giap_gang', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseAoGiapGang')
end)

exports.qbx_core:CreateUseableItem('medlangbam', function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseMedLangBam')
end)

local function isCoordsInRedZone(coords)
	local redZones = (sharedConfig.medLangBam and sharedConfig.medLangBam.redZones) or {}
	for _, zone in ipairs(redZones) do
		local center = zone.center or zone.coords or (type(zone) == 'vector3' and zone)
		local radius = zone.radius or 100.0
		if center then
			local dist = #(coords - center)
			if dist <= radius then
				return true, zone
			end
		end
	end
	return false
end

RegisterNetEvent('hospital:server:ReviveMedLangBam', function(targetId)
	if GetInvokingResource() then return end
	local src = source
	targetId = tonumber(targetId)
	if not targetId or targetId <= 0 then return end
	local patient = exports.qbx_core:GetPlayer(targetId)
	if not patient then return end

	local srcPed = GetPlayerPed(src)
	local targetPed = GetPlayerPed(targetId)
	local srcCoords = GetEntityCoords(srcPed)
	local targetCoords = GetEntityCoords(targetPed)

	if #(srcCoords - targetCoords) > 10.0 then
		exports.qbx_core:Notify(src, 'Bạn ở quá xa người bệnh!', 'error')
		return
	end

	if not isCoordsInRedZone(srcCoords) then
		exports.qbx_core:Notify(src, 'Chỉ có thể dùng Med lang băm trong vùng đỏ!', 'error')
		return
	end

	local deathState = Player(targetId).state['qbx_medical:deathState']
	local isDead = (deathState == 3) or (patient.PlayerData.metadata.isdead == true)
	local inLaststand = (deathState == 2) or (patient.PlayerData.metadata.inlaststand == true)

	if isDead or not inLaststand then
		exports.qbx_core:Notify(src, 'Med lang băm chỉ cứu được người bị ngất (hấp hối), không cứu được người đã chết hẳn!', 'error')
		return
	end

	TriggerClientEvent('qbx_medical:client:playerRevived', patient.PlayerData.source)

	-- Discord log
	local player = exports.qbx_core:GetPlayer(src)
	local doctorName = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname) or 'Unknown'
	local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname
	sendDiscordLog('Cứu sống (Med Lang Băm)', src, doctorName, targetId, patientName)
end)

RegisterNetEvent('qbx_medical:server:playerDied', function()
	if GetInvokingResource() then return end
	local src = source
	--alertAmbulance(src, locale('info.civ_died'))
end)

---Event để lấy tất cả người chơi đang ngất/chết trong danh sách người gần và kéo họ về phía người sử dụng
---@param nearbyPlayerIds table Danh sách ID người chơi gần (đã được lọc trong bán kính 10m từ client)
RegisterNetEvent('hospital:server:dragAllDownedPlayers', function(nearbyPlayerIds)
	if GetInvokingResource() then return end
	local src = source

	-- Validate danh sách
	if not nearbyPlayerIds or type(nearbyPlayerIds) ~= 'table' then
		return
	end

	local downedPlayers = {}

	-- Chỉ duyệt qua danh sách người chơi gần (đã được tối ưu từ client)
	for _, targetSrc in pairs(nearbyPlayerIds) do
		targetSrc = tonumber(targetSrc)
		if targetSrc and targetSrc > 0 and targetSrc ~= src and exports.qbx_core:GetPlayer(targetSrc) then
			-- Kiểm tra trạng thái của người chơi thông qua callback an toàn
			local success, isDownedOrDead = pcall(function()
				return lib.callback.await('qbx_ambulancejob:client:isPlayerDownedOrDead', targetSrc)
			end)

			if success and isDownedOrDead then
				-- Lấy tọa độ của người chơi ngất/chết từ client của họ an toàn
				local coordsSuccess, targetCoords = pcall(function()
					return lib.callback.await('qbx_ambulancejob:client:getPlayerCoords', targetSrc)
				end)

				if coordsSuccess and targetCoords then
					table.insert(downedPlayers, {
						source = targetSrc,
						coords = targetCoords
					})
				end
			end
		end
	end

	-- Gửi danh sách người chơi đang ngất/chết về cho tất cả người chơi gần đó
	-- (để tạo hiệu ứng đồng bộ)
	local allPlayers = GetPlayers()
	for _, playerId in pairs(allPlayers) do
		TriggerClientEvent('hospital:client:dragDownedPlayers', tonumber(playerId), downedPlayers)
	end
end)

-- Command để kéo tất cả người chơi đang ngất/chết trong bán kính 10m
-- lib.addCommand('dragdowned', {
-- 	help = 'Kéo tất cả người chơi đang ngất hoặc chết trong bán kính 10m về phía bạn',
-- 	restricted = false, -- Đặt thành 'group.admin' nếu muốn chỉ admin dùng được
-- }, function(source)
-- 	TriggerClientEvent('hospital:client:initDragDownedPlayers', source)
-- end)

-- Xóa đơn ping khi player được revive
RegisterNetEvent('qbx_medical:server:onPlayerRevived', function(playerId)
	local src = playerId or source
	-- Trigger event để xn_Pingjob xóa đơn của player này
	TriggerEvent('xn_pingjob:autoDeleteServiceOnRevive', src)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    registerArmory()
    registerStashes()
end)