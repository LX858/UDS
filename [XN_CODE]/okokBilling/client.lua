QBCore = nil
PlayerData = {}
local targetedPlayer = nil
local targetOptionsAdded = false

Citizen.CreateThread(function()
	while QBCore == nil do
		QBCore = exports['qb-core']:GetCoreObject()
		Citizen.Wait(0)
    end
	while QBCore.Functions.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	PlayerData = QBCore.Functions.GetPlayerData()
	-- Thêm delay và gọi UpdateTargetOptions
	Wait(2000)
	UpdateTargetOptions()
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
	PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate")
AddEventHandler("QBCore:Client:OnJobUpdate", function(job)
	PlayerData.job = job
	-- Cập nhật ox_target khi đổi job
	UpdateTargetOptions()
end)

-- Hàm để cập nhật ox_target options dựa trên job
function UpdateTargetOptions()
	----print("[okokBilling] UpdateTargetOptions called")
	----print("[okokBilling] Current job:", PlayerData.job and PlayerData.job.name or "nil")
	
	-- Xóa target options cũ trước khi thêm mới để tránh duplicate
	if targetOptionsAdded then
		exports.ox_target:removeGlobalPlayer({'send_invoice_direct'})
		targetOptionsAdded = false
		----print("[okokBilling] Removed old target options")
	end
	
	local isAllowed = false
	if PlayerData.job and PlayerData.job.name then
		for k, v in pairs(Config.AllowedSocieties) do
			----print("[okokBilling] Checking job:", v, "vs", PlayerData.job.name)
			if v == PlayerData.job.name then
				isAllowed = true
				break
			end
		end
	end
	
	----print("[okokBilling] Is allowed:", isAllowed)
	
	-- Tắt target cho cảnh sát (police) nhưng vẫn giữ menu hóa đơn
	if isAllowed and PlayerData.job.name ~= 'police' then
		-- Thêm target option cho players sử dụng addGlobalPlayer
		local success, err = pcall(function()
			exports.ox_target:addGlobalPlayer({
			{
				name = 'send_invoice_direct',
				icon = 'fa-solid fa-file-invoice-dollar',
				label = 'Tạo hóa đơn ngay',
				onSelect = function(data)
					local entity = data.entity
					-- Kiểm tra entity hợp lệ trước khi thực hiện bất kỳ thao tác nào
					local success, err = pcall(function()
						if not entity or type(entity) ~= "number" or entity == 0 then
							QBCore.Functions.Notify("Target không hợp lệ!", 5000, 'error')
							return
						end
						
						-- Kiểm tra entity tồn tại và là player
						if not DoesEntityExist(entity) then
							QBCore.Functions.Notify("Entity không tồn tại!", 5000, 'error')
							return
						end
						
						if not IsPedAPlayer(entity) then
							QBCore.Functions.Notify("Target không phải là player!", 5000, 'error')
							return
						end
						
						local playerIndex = NetworkGetPlayerIndexFromPed(entity)
						if playerIndex == -1 then
							QBCore.Functions.Notify("Không thể lấy player index!", 5000, 'error')
							return
						end
						
						local targetId = GetPlayerServerId(playerIndex)
						if not targetId or targetId <= 0 then
							QBCore.Functions.Notify("Không thể lấy server ID!", 5000, 'error')
							return
						end
						
						targetedPlayer = targetId
						CreateInvoice(PlayerData.job.label)
					end)
					
					if not success then
						----print("[okokBilling] Error in target callback: " .. tostring(err))
						QBCore.Functions.Notify("Lỗi khi target player!", 5000, 'error')
					end
				end,
				canInteract = function(entity, distance)
					-- Sử dụng distance từ ox_target thay vì tính toán lại
					if distance > 3.0 then
						return false
					end
					
					-- Kiểm tra entity có phải là player ped không với error handling
					local success, result = pcall(function()
						if not entity or type(entity) ~= "number" or entity == 0 then
							return false
						end
						
						if not DoesEntityExist(entity) then
							return false
						end
						
						if not IsPedAPlayer(entity) then
							return false
						end
						
						-- Kiểm tra không target chính mình
						local playerPed = PlayerPedId()
						if entity == playerPed then
							return false
						end
						
						return true
					end)
					
					return success and result
				end
			}
		})
		end)
		
		if success then
			targetOptionsAdded = true
			----print("[okokBilling] Target options added successfully")
		else
			----print("[okokBilling] ERROR adding target options:", tostring(err))
			targetOptionsAdded = false
		end
	else
		-- Xóa target option nếu không được phép
		if targetOptionsAdded then
			exports.ox_target:removeGlobalPlayer({'send_invoice_direct'})
			targetOptionsAdded = false
		end
		----print("[okokBilling] Target options not added - job not allowed")
	end
end

-- Khởi tạo target options khi player load
RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
	PlayerData = QBCore.Functions.GetPlayerData()
	----print("[okokBilling] Player loaded, waiting for target system...")
	-- Retry system để đảm bảo ox_target đã load
	Citizen.CreateThread(function()
		local attempts = 0
		while attempts < 10 do
			Wait(2000)
			attempts = attempts + 1
			----print("[okokBilling] Attempt", attempts, "to update target options")
			UpdateTargetOptions()
			
			if targetOptionsAdded then
				----print("[okokBilling] Target options successfully added")
				break
			end
		end
		
		if not targetOptionsAdded then
			----print("[okokBilling] WARNING: Could not add target options after 10 attempts")
		end
	end)
end)

function MyInvoices(page)
	page = page or 1
	QBCore.Functions.TriggerCallback("okokBilling:GetInvoices", function(invoices, totalInvoices, currentPage, totalPages)
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'myinvoices',
			invoices = invoices,
			totalInvoices = totalInvoices,
			currentPage = currentPage,
			totalPages = totalPages,
			VAT = Config.VATPercentage
		})			
	end, page, 5)
end

function SocietyInvoices(society, page)
	page = page or 1
	QBCore.Functions.TriggerCallback("okokBilling:GetSocietyInvoices", function(cb, totalInvoices, totalIncome, totalUnpaid, awaitedIncome, currentPage, totalPages)
		if json.encode(cb) ~= '[]' then
			SetNuiFocus(true, true)
			SendNUIMessage({
				action = 'societyinvoices',
				invoices = cb,
				totalInvoices = totalInvoices,
				totalIncome = totalIncome,
				totalUnpaid = totalUnpaid,
				awaitedIncome = awaitedIncome,
				currentPage = currentPage,
				totalPages = totalPages,
				VAT = Config.VATPercentage
			})		
		else
			QBCore.Functions.Notify("Doanh nghiệp của bạn không có hóa đơn.", 10000, 'info')
			SetNuiFocus(false, false)
		end
	end, society, page, 5) -- Load 5 records per page (giữ nguyên layout)
end

function CreateInvoice(society)
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = 'createinvoice',
		society = society
	})
end

RegisterCommand(Config.InvoicesCommand, function()
	local isAllowed = false
	local jobName = ""
	for k, v in pairs(Config.AllowedSocieties) do
		if v == PlayerData.job.name then
			jobName = v
			isAllowed = true
		end
	end

	if Config.OnlyBossCanAccessSocietyInvoices and PlayerData.job.isboss == true and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = true,
			create = true
		})
	elseif Config.OnlyBossCanAccessSocietyInvoices and PlayerData.job.isboss ~= true and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = false,
			create = true
		})
	elseif not Config.OnlyBossCanAccessSocietyInvoices and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = true,
			create = true
		})
	elseif not isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = false,
			create = false
		})
	end
end, false)

-- Add F5 key mapping for invoice command
RegisterKeyMapping(Config.InvoicesCommand, 'Open Invoice Menu', 'keyboard', 'O')

-- Command để reset target nếu cần
-- RegisterCommand('resettarget', function()
-- 	targetedPlayer = nil
-- 	QBCore.Functions.Notify("Đã reset target player.", 5000, 'info')
-- end, false)

-- Command để kiểm tra target hiện tại
-- RegisterCommand('checktarget', function()
-- 	if targetedPlayer then
-- 		QBCore.Functions.Notify("Target hiện tại: Player ID " .. targetedPlayer, 5000, 'info')
-- 	else
-- 		QBCore.Functions.Notify("Chưa có target nào được chọn.", 5000, 'info')
-- 	end
-- end, false)

-- Command để debug job và target options
-- RegisterCommand('debugjob', function()
-- 	----print("=== DEBUG JOB INFO ===")
-- 	----print("PlayerData:", json.encode(PlayerData))
-- 	if PlayerData.job then
-- 		----print("Job name:", PlayerData.job.name)
-- 		----print("Job label:", PlayerData.job.label)
-- 		----print("Is boss:", PlayerData.job.isboss)
-- 	else
-- 		----print("No job data")
-- 	end
-- 	----print("Target options added:", targetOptionsAdded)
-- 	----print("Config.AllowedSocieties:", json.encode(Config.AllowedSocieties))
	
-- 	-- Force update target options
-- 	UpdateTargetOptions()
-- end, false)

RegisterNUICallback("action", function(data, cb)
	if data.action == "close" then
		SetNuiFocus(false, false)
	elseif data.action == "payInvoice" then
		TriggerServerEvent("okokBilling:PayInvoice", data.invoice_id)
		SetNuiFocus(false, false)
	elseif data.action == "cancelInvoice" then
		--QBCore.Functions.Notify("Vui lòng liên hệ Tòa Thị Chính để hủy hóa đơn!", 10000, 'error')
		TriggerServerEvent("okokBilling:CancelInvoice", data.invoice_id)
		SetNuiFocus(false, false)
	elseif data.action == "createInvoice" then
		if targetedPlayer then
			-- Sử dụng player đã được target
			data.target = targetedPlayer
			data.society = PlayerData.job.name
			data.society_name = PlayerData.job.label

			TriggerServerEvent("okokBilling:CreateInvoice", data)
			QBCore.Functions.Notify("Ghi hóa đơn thành công cho Player ID: ("..targetedPlayer..")", 10000, 'success')
			
			-- Reset targetedPlayer sau khi sử dụng
			targetedPlayer = nil
		else
			QBCore.Functions.Notify("Lỗi: Vui lòng sử dụng ox_target để chọn người cần gửi hóa đơn!", 10000, 'error')
		end
		
		SetNuiFocus(false, false)
	elseif data.action == "missingInfo" then
		QBCore.Functions.Notify("Vui lòng điền đầy đủ thông tin trong 3 hàng!", 10000, 'error')
	elseif data.action == "negativeAmount" then
		QBCore.Functions.Notify("số tiền phải là số dương. Không được để số âm!", 10000, 'error')
	elseif data.action == "exceedLimit" then
		QBCore.Functions.Notify("số tiền không được vượt quá 500,000💵!", 10000, 'error')
	elseif data.action == "mainMenuOpenMyInvoices" then
		MyInvoices(data.page)
	elseif data.action == "mainMenuOpenSocietyInvoices" then
		for k, v in pairs(Config.AllowedSocieties) do
			if v == PlayerData.job.name then
				if Config.OnlyBossCanAccessSocietyInvoices and PlayerData.job.isboss == true then
					SocietyInvoices(PlayerData.job.name, data.page) -- Sử dụng job.name để khớp database
				elseif not Config.OnlyBossCanAccessSocietyInvoices then
					SocietyInvoices(PlayerData.job.name, data.page) -- Sử dụng job.name để khớp database
				elseif Config.OnlyBossCanAccessSocietyInvoices then
					QBCore.Functions.Notify("Chỉ có Giám Đốc mới có thể truy cập vào các hóa đơn.", 10000, 'error')
				end
			end
		end
	elseif data.action == "mainMenuOpenCreateInvoice" then
		for k, v in pairs(Config.AllowedSocieties) do
			if v == PlayerData.job.name then
				CreateInvoice(PlayerData.job.label)
			end
		end
	end
end)

RegisterNetEvent("okokBilling:client:menu_quanly")
AddEventHandler("okokBilling:client:menu_quanly", function()
	exports['qb-menu']:openMenu({
		{
			header = "QUẢN LÝ HÓA ĐƠN",
			txt = "(Biết thì sử dụng không thì đừng đụng vào)",
			icon = "fa-solid fa-gears",
			-- disabled = true,
			isMenuHeader = true,
		},
		{
			id = 1,
			header = "Xóa hóa đơn đã thanh toán",
			txt = "Xóa toàn bộ hóa đơn đã thanh toán của thành phố",
			icon = "fa-solid fa-shop",
			params = {
				event = "okokBilling:client:clear_hoadon",
			}
		},
		{
			id = 2,
			header = "Xóa hóa đơn doanh nghiệp",
			txt = "Sử dụng khi bị viết nhầm hóa đơn",
			icon = "fa-solid fa-shop",
			params = {
				event = "okokBilling:client:clear_doanhnghiep",
			}
		},
		-- {
		-- 	id = 3,
		-- 	header = "<b style='color:orange;'>•[CHECK]•</b>Tự động thanh toán",
		-- 	txt = "- Kiểm tra tổng tiền hóa đơn tự thanh toán",
		-- 	icon = "fa-solid fa-shop",
		-- 	params = {
		-- 		event = "okokBilling:client:check_auto",
		-- 	}
		-- },
		{
			id = 4,
			header = "Hẹn gặp lại dịp khác",
			txt = "",
			icon = "fa-solid fa-circle-xmark",
			params = {
				event = "qb-menu:client:closeMenu",
			}
		},
	})
end)

RegisterNetEvent("okokBilling:client:clear_hoadon")
AddEventHandler("okokBilling:client:clear_hoadon", function()
	exports['qb-menu']:openMenu({
		{
			header = "BẠN CÓ CHẮC CHẮN MUỐN XÓA",
			txt = "- Suy nghĩ kỹ trước khi quyết định",
			icon = "fa-solid fa-gears",
			disabled = true,
			isMenuHeader = true,
		},
		{
			id = 1,
			header = "[ĐỒNG Ý]",
			icon = "fas fa-check",
			params = {
				event = "okokBilling:client:ok_clear_hoadon",
			}
		},
		{
			id = 2,
			header = "[KHÔNG ĐỒNG Ý]",
			icon = "fa-solid fa-circle-xmark",
			params = {
				event = "qb-menu:client:closeMenu",
			}
		},
	})
end)

RegisterNetEvent("okokBilling:client:ok_clear_hoadon")
AddEventHandler("okokBilling:client:ok_clear_hoadon", function()
    TriggerServerEvent("okokBilling:server:clear_hoadon")
end)

RegisterNetEvent("okokBilling:client:clear_doanhnghiep")
AddEventHandler("okokBilling:client:clear_doanhnghiep", function()
    local dialog = exports['qb-input']:ShowInput({
        header = "XÓA HƠN ĐƠN CÁ NHÂN",
        submitText = "XÁC NHẬN",
        inputs = {
            {
                text = "Số hóa đơn",
                name = "billnumber",
                type = "number",
                isRequired = true
            }
        }
    })
    if dialog then
        TriggerServerEvent('okokBilling:server:clear_hd_canhan', dialog.billnumber)
    end
end)

-- Dọn dẹp khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    -- Xóa tất cả target options khi resource stop
    if targetOptionsAdded then
        exports.ox_target:removeGlobalPlayer({'send_invoice_direct'})
        targetOptionsAdded = false
    end
end)