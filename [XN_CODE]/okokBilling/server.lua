QBCore = nil

QBCore = exports['qb-core']:GetCoreObject()

-- WEBHOOK CHO BÁO CÁO BẮT NỢ
local JAIL_WEBHOOK = 'https://discord.com/api/webhooks/1469052399900430548/53L3t3IvZG3-nnUaQQD0ivWwwzE8WJ_yIIr6sUeKCO8nAFC2h7PCdEG2DL-glTsyOTVs'

local limiteTimeHours = Config.LimitDateDays*24
local hoursToPay = limiteTimeHours
local whenToAddFees = {}
local expired7DaysDeletedCount = 0

local function getAffectedRows(result)
	if type(result) == 'number' then
		return result
	end

	if type(result) == 'table' then
		return result.affectedRows or result.changedRows or 0
	end

	return 0
end

local function clearExpiredInvoicesOnStart(cb)
	exports.oxmysql:execute('DELETE FROM okokBilling WHERE sent_date <= DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)', {}, function(result)
		expired7DaysDeletedCount = getAffectedRows(result)
		print("[okokBilling] 🧹 Đã xóa " .. expired7DaysDeletedCount .. " hóa đơn quá hạn 7 ngày khi khởi động resource")

		if cb then
			cb()
		end
	end)
end

function IsAuthorized(CitizenId)
    local retval = false
    for _, cid in pairs(Config.CID_CancelBill) do
        if cid == CitizenId then
            retval = true
            break
        end
    end
    return retval
end

for i = 1, Config.LimitDateDays, 1 do
	hoursToPay = hoursToPay - 24
	table.insert(whenToAddFees, hoursToPay)
end

QBCore.Functions.CreateCallback("okokBilling:GetInvoices", function(source, cb, page, limit)
	local xPlayer = QBCore.Functions.GetPlayer(source)
	local _source = source

	-- Thiết lập pagination
	page = page or 1
	limit = limit or 5
	local maxPages = 5  -- Giới hạn tối đa 5 trang cho hóa đơn cá nhân
	
	-- Đảm bảo page luôn >= 1
	if page < 1 then
		page = 1
	end
	
	-- Giới hạn page không vượt quá 5
	if page > maxPages then
		page = maxPages
	end
	
	local offset = (page - 1) * limit

	-- Lấy tổng số hóa đơn (giới hạn tối đa 25 hóa đơn = 5 trang x 5)
	exports.oxmysql:execute('SELECT COUNT(*) as total FROM (SELECT * FROM okokBilling WHERE receiver_identifier = @identifier ORDER BY FIELD(status, "unpaid", "autopaid", "paid", "cancelled"), id DESC LIMIT @maxLimit) as limited', {
		['@identifier'] = xPlayer.PlayerData.citizenid,
		['@maxLimit'] = maxPages * limit
	}, function(countResult)
		local totalInvoices = countResult[1].total or 0
		
		-- Tính totalPages nhưng giới hạn tối đa 5
		local totalPages = math.min(math.ceil(totalInvoices / limit), maxPages)
		
		-- Chỉ load 5 hóa đơn của trang hiện tại
		exports.oxmysql:execute('SELECT * FROM okokBilling WHERE receiver_identifier = @identifier ORDER BY FIELD(status, "unpaid", "autopaid", "paid", "cancelled"), id DESC LIMIT @limit OFFSET @offset', {
			['@identifier'] = xPlayer.PlayerData.citizenid,
			['@limit'] = limit,
			['@offset'] = offset
		}, function(result)
			local invoices = {}

			if result ~= nil then
				for i=1, #result, 1 do
					table.insert(invoices, result[i])
				end
			end

			cb(invoices, totalInvoices, page, totalPages)
		end)
	end)
end)

RegisterServerEvent("okokBilling:PayInvoice")
AddEventHandler("okokBilling:PayInvoice", function(invoice_id)
	local xPlayer = QBCore.Functions.GetPlayer(source)
	local _source = source

	exports.oxmysql:execute('SELECT * FROM okokBilling WHERE id = @id', {
		['@id'] = invoice_id
	}, function(result)
		local invoices = result[1]
		local playerBankMoney = xPlayer.PlayerData.money.bank or 0
		local playerCashMoney = xPlayer.PlayerData.money.cash or 0
		local job = xPlayer.PlayerData.job.name

		invoices.invoice_value = math.ceil(invoices.invoice_value)

		-- Kiểm tra tiền: ưu tiên bank, nếu bank không đủ thì kiểm tra cash
		local paymentType = 'bank'
		local availableMoney = playerBankMoney
		
		if playerBankMoney < invoices.invoice_value then
			-- Ngân hàng không đủ, kiểm tra tiền mặt
			if playerCashMoney >= invoices.invoice_value then
				paymentType = 'cash'
				availableMoney = playerCashMoney
			else
				-- Cả 2 đều không đủ, lấy số tiền lớn hơn để hiển thị
				if playerCashMoney > playerBankMoney then
					paymentType = 'cash'
					availableMoney = playerCashMoney
				else
					availableMoney = playerBankMoney
				end
			end
		end

		if availableMoney < invoices.invoice_value then
			TriggerClientEvent('QBCore:Notify', _source, "Bạn không có đủ 💵! (Cần: $"..invoices.invoice_value.." - Có: $"..availableMoney..")", 'error', 10000)
		else
			xPlayer.Functions.RemoveMoney(paymentType, invoices.invoice_value, 'thanh toán hóa đơn')
			TriggerEvent('okokBanking:TruTien_HoaDon', invoices.invoice_value, invoices.society_name, _source)
			-- Trừ 2% thuế khi cộng vào doanh nghiệp
			local moneyAfterTax = math.floor(invoices.invoice_value * 0.98)
			exports['Renewed-Banking']:addAccountMoney(invoices.society, moneyAfterTax)
			--TriggerEvent("qb-bossmenu:server:addAccountMoney", invoices.society, invoices.invoice_value)

			exports.oxmysql:execute('UPDATE okokBilling SET status = @status, paid_date = CURRENT_TIMESTAMP WHERE id = @id', {
				['@status'] = 'paid',
				['@id'] = invoice_id
			})
--================================================== THÔNG BÁO THANH TOÁN HÓA ĐƠN - TỪ HOẢNG UPDATE 09:30 - 03/04/2022 ==================================================
			local sender = QBCore.Functions.GetPlayerByCitizenId(invoices.author_identifier)
			local firstname = xPlayer.PlayerData.charinfo.firstname
			local lastname = xPlayer.PlayerData.charinfo.lastname
			local name = ''..firstname..' '.. lastname..''

			if sender then
			TriggerClientEvent('QBCore:Notify', sender.PlayerData.source, ""..name.." vừa thanh toán hóa đơn của bạn với số tiền $"..invoices.invoice_value.."", 'success', 10000)
			end
--=======================================================================================================================================================================			
			local paymentMethodText = paymentType == 'bank' and 'ngân hàng' or 'tiền mặt'
			TriggerClientEvent('QBCore:Notify', _source, "Hóa đơn đã thanh toán thành công bằng "..paymentMethodText.."!", 'success', 10000)
			
			-- Tạo webhookData với đầy đủ thông tin
			local webhookData = {
				id = invoices.id,
				player_name = invoices.receiver_name,
				value = invoices.invoice_value,
				item = invoices.item,
				society = invoices.society_name,
				society_code = invoices.society,
				payment_method = paymentMethodText
			}
			
			payInvoiceWebhook(webhookData)
		end
	end)
end)

RegisterServerEvent("okokBilling:CancelInvoice")
AddEventHandler("okokBilling:CancelInvoice", function(invoice_id)
	local xPlayer = QBCore.Functions.GetPlayer(source)
	local _source = source
	if IsAuthorized(xPlayer.PlayerData.citizenid) then
		exports.oxmysql:execute('SELECT * FROM okokBilling WHERE id = @id', {
			['@id'] = invoice_id
		}, function(result)
			local invoices = result[1]
			local webhookData = {
				id = invoices.id,
				player_name = invoices.receiver_name,
				value = invoices.invoice_value,
				item = invoices.item,
				society = invoices.society_name,
				society_code = invoices.society,
				name = xPlayer.PlayerData.name
			}
			exports.oxmysql:execute('UPDATE okokBilling SET status = "cancelled", paid_date = CURRENT_TIMESTAMP WHERE id = @id', {
				['@id'] = invoice_id
			})
			TriggerClientEvent('QBCore:Notify', _source, "Bạn đã hủy hóa đơn!", 'info', 10000)
			cancelInvoiceWebhook(webhookData)
		end)
	else
        TriggerClientEvent('QBCore:Notify', _source, "Vui lòng liên hệ Tòa Thị Chính để hủy hóa đơn!", "error")
    end
end)

RegisterServerEvent("okokBilling:CreateInvoice")
AddEventHandler("okokBilling:CreateInvoice", function(data)
	local _source = QBCore.Functions.GetPlayer(source)
	local target = QBCore.Functions.GetPlayer(data.target)

	local webhookData = {}
	
	-- Tạo tên đầy đủ từ citizenID, firstname và lastname
	local targetFullName = '[' .. target.PlayerData.pid .. '] ' .. target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
	local sourceFullName = '[' .. _source.PlayerData.pid .. '] ' .. _source.PlayerData.charinfo.firstname .. ' ' .. _source.PlayerData.charinfo.lastname
	
	local invoiceValue = math.ceil(data.invoice_value)
	local playerBankMoney = target.PlayerData.money.bank or 0
	local playerCashMoney = target.PlayerData.money.cash or 0
	
	-- Kiểm tra loại tiền sẽ dùng: ưu tiên bank, nếu bank không đủ thì dùng cash
	local paymentType = 'bank'
	local availableMoney = playerBankMoney
	
	if playerBankMoney < invoiceValue then
		-- Ngân hàng không đủ, kiểm tra tiền mặt
		if playerCashMoney >= invoiceValue then
			paymentType = 'cash'
			availableMoney = playerCashMoney
		end
	end
	
	-- Kiểm tra xem society có được phép thanh toán tự động không
	local allowAutoPay = false
	for _, allowedSociety in pairs(Config.AutoPaySocieties) do
		if data.society == allowedSociety then
			allowAutoPay = true
			break
		end
	end
	
	-- Kiểm tra nếu player đang online VÀ có đủ tiền VÀ society được phép auto pay → thanh toán ngay lập tức
	if availableMoney >= invoiceValue and allowAutoPay then
		----print("→ ĐỦ TIỀN - Bắt đầu thanh toán tự động...")
		-- Thanh toán tự động ngay lập tức
		local success = target.Functions.RemoveMoney(paymentType, invoiceValue, 'thanh toán hóa đơn tự động')
		
		if not success then
			----print("→ LỖI: Không thể trừ tiền!")
			TriggerClientEvent('QBCore:Notify', source, "Lỗi: Không thể trừ tiền!", 'error', 5000)
			return
		end
		
		TriggerEvent('okokBanking:TruTien_HoaDon', invoiceValue, data.society_name, target.PlayerData.source)
		-- Trừ 2% thuế khi cộng vào doanh nghiệp
		local moneyAfterTax = math.floor(invoiceValue * 0.98)
		exports['Renewed-Banking']:addAccountMoney(data.society, moneyAfterTax)
				
		-- Lưu hóa đơn với trạng thái autopaid
		if Config.LimitDate then
			exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date, paid_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL @limit_pay_date DAY), CURRENT_TIMESTAMP())', {
				['@receiver_identifier'] = target.PlayerData.citizenid,
				['@receiver_name'] = targetFullName,
				['@author_identifier'] = _source.PlayerData.citizenid,
				['@author_name'] = sourceFullName,
				['@society'] = data.society,
				['@society_name'] = data.society_name,
				['@item'] = data.invoice_item,
				['@invoice_value'] = invoiceValue,
				['@status'] = "autopaid",
				['@notes'] = data.invoice_notes,
				['@limit_pay_date'] = Config.LimitDateDays
			}, function(result)
				local paymentMethodText = paymentType == 'bank' and 'ngân hàng' or 'tiền mặt'
				TriggerClientEvent('QBCore:Notify', target.PlayerData.source, "Hóa đơn đã được thanh toán tự động bằng "..paymentMethodText.."!", 'success', 10000)
				
				exports.oxmysql:execute('SELECT id FROM okokBilling WHERE id = (SELECT MAX(id) FROM okokBilling)', {}, function(idResult)
					if idResult and idResult[1] then
						webhookData = {
							id = idResult[1].id,
							player_name = targetFullName,
							value = invoiceValue,
							item = data.invoice_item,
							society = data.society_name,
							society_code = data.society,
							name = sourceFullName,
							payment_method = paymentMethodText
						}
						autopayInvoiceWebhook(webhookData)
					end
				end)
			end)
		else
			exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date, paid_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), @limit_pay_date, CURRENT_TIMESTAMP())', {
				['@receiver_identifier'] = target.PlayerData.citizenid,
				['@receiver_name'] = targetFullName,
				['@author_identifier'] = _source.PlayerData.citizenid,
				['@author_name'] = sourceFullName,
				['@society'] = data.society,
				['@society_name'] = data.society_name,
				['@item'] = data.invoice_item,
				['@invoice_value'] = invoiceValue,
				['@status'] = "autopaid",
				['@notes'] = data.invoice_notes,
				['@limit_pay_date'] = 'N/A'
			}, function(result)
				local paymentMethodText = paymentType == 'bank' and 'ngân hàng' or 'tiền mặt'
				TriggerClientEvent('QBCore:Notify', target.PlayerData.source, "Hóa đơn đã được thanh toán tự động bằng "..paymentMethodText.."!", 'success', 10000)
				
				exports.oxmysql:execute('SELECT id FROM okokBilling WHERE id = (SELECT MAX(id) FROM okokBilling)', {}, function(idResult)
					if idResult and idResult[1] then
						webhookData = {
							id = idResult[1].id,
							player_name = targetFullName,
							value = invoiceValue,
							item = data.invoice_item,
							society = data.society_name,
							society_code = data.society,
							name = sourceFullName,
							payment_method = paymentMethodText
						}
						autopayInvoiceWebhook(webhookData)
					end
				end)
			end)
		end
		-- Thông báo cho người tạo hóa đơn
		TriggerClientEvent('QBCore:Notify', _source.PlayerData.source, targetFullName.." đã thanh toán hóa đơn tự động!", 'success', 10000)
		--print("=== KẾT THÚC - Thanh toán tự động thành công ===")
	else
		-- Không đủ tiền HOẶC doanh nghiệp không được phép auto pay → tạo hóa đơn unpaid
		local notifyMessage = "Bạn vừa nhận được một hóa đơn mới!"
		
		-- Nếu doanh nghiệp được phép autopay nhưng không đủ tiền
		if allowAutoPay and availableMoney < invoiceValue then
			notifyMessage = "Bạn vừa nhận được một hóa đơn mới! (Không đủ tiền để thanh toán tự động)"
		end
		
		if Config.LimitDate then
			exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL @limit_pay_date DAY))', {
				['@receiver_identifier'] = target.PlayerData.citizenid,
				['@receiver_name'] = targetFullName,
				['@author_identifier'] = _source.PlayerData.citizenid,
				['@author_name'] = sourceFullName,
				['@society'] = data.society,
				['@society_name'] = data.society_name,
				['@item'] = data.invoice_item,
				['@invoice_value'] = invoiceValue,
				['@status'] = "unpaid",
				['@notes'] = data.invoice_notes,
				['@limit_pay_date'] = Config.LimitDateDays
			}, function(result)
				TriggerClientEvent('QBCore:Notify', target.PlayerData.source, notifyMessage, 'info', 10000)
				
				exports.oxmysql:execute('SELECT id FROM okokBilling WHERE id = (SELECT MAX(id) FROM okokBilling)', {}, function(idResult)
					if idResult and idResult[1] then
						webhookData = {
							id = idResult[1].id,
							player_name = targetFullName,
							value = invoiceValue,
							item = data.invoice_item,
							society = data.society_name,
							society_code = data.society,
							name = sourceFullName
						}
						createNewInvoiceWebhook(webhookData)
					end
				end)
			end)
		else
			exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), @limit_pay_date)', {
				['@receiver_identifier'] = target.PlayerData.citizenid,
				['@receiver_name'] = targetFullName,
				['@author_identifier'] = _source.PlayerData.citizenid,
				['@author_name'] = sourceFullName,
				['@society'] = data.society,
				['@society_name'] = data.society_name,
				['@item'] = data.invoice_item,
				['@invoice_value'] = invoiceValue,
				['@status'] = "unpaid",
				['@notes'] = data.invoice_notes,
				['@limit_pay_date'] = 'N/A'
			}, function(result)
				TriggerClientEvent('QBCore:Notify', target.PlayerData.source, notifyMessage, 'info', 10000)
				
				exports.oxmysql:execute('SELECT id FROM okokBilling WHERE id = (SELECT MAX(id) FROM okokBilling)', {}, function(idResult)
					if idResult and idResult[1] then
						webhookData = {
							id = idResult[1].id,
							player_name = targetFullName,
							value = invoiceValue,
							item = data.invoice_item,
							society = data.society_name,
							society_code = data.society,
							name = sourceFullName
						}
						createNewInvoiceWebhook(webhookData)
					end
				end)
			end)
		end
	end
end)

QBCore.Functions.CreateCallback("okokBilling:GetSocietyInvoices", function(source, cb, society, page, limit)
	local xPlayer = QBCore.Functions.GetPlayer(source)
	
	-- Thiết lập pagination
	page = page or 1
	limit = limit or 5  -- Chỉ load 5 hóa đơn mỗi lần
	local maxPages = 50  -- Giới hạn UI tối đa 50 trang
	
	-- Đảm bảo page luôn >= 1
	if page < 1 then
		page = 1
	end
	
	-- Giới hạn page không vượt quá 50
	if page > maxPages then
		page = maxPages
	end
	
	local offset = (page - 1) * limit

	-- Lấy thống kê trên 250 hóa đơn gần nhất (50 trang x 5)
	-- Fix: Query theo society (job code) thay vì society_name (job label)
	exports.oxmysql:execute('SELECT COUNT(*) as total, SUM(CASE WHEN status = "paid" OR status = "autopaid" THEN invoice_value ELSE 0 END) as totalIncome, COUNT(CASE WHEN status = "unpaid" THEN 1 END) as totalUnpaid, SUM(CASE WHEN status = "unpaid" THEN invoice_value ELSE 0 END) as awaitedIncome FROM (SELECT * FROM okokBilling WHERE society = @society ORDER BY id DESC LIMIT @maxLimit) as limited', {
		['@society'] = society,
		['@maxLimit'] = maxPages * limit
	}, function(statsResult)
		local stats = statsResult[1] or {}
		local totalInvoices = stats.total or 0
		local totalIncome = stats.totalIncome or 0
		local totalUnpaid = stats.totalUnpaid or 0
		local awaitedIncome = stats.awaitedIncome or 0
		
		-- Tính totalPages nhưng giới hạn tối đa 50
		local totalPages = math.min(math.ceil(totalInvoices / limit), maxPages)

		-- Chỉ load 5 hóa đơn của trang hiện tại
		-- Fix: Query theo society (job code) thay vì society_name (job label)
		exports.oxmysql:execute('SELECT * FROM okokBilling WHERE society = @society ORDER BY id DESC LIMIT @limit OFFSET @offset', {
			['@society'] = society,
			['@limit'] = limit,
			['@offset'] = offset
		}, function(result)
			local invoices = {}

			if result ~= nil then
				for i=1, #result, 1 do
					table.insert(invoices, result[i])
				end
			end
			
			cb(invoices, totalInvoices, totalIncome, totalUnpaid, awaitedIncome, page, totalPages)
		end)
	end)
end)

-- Function riêng: Quét tất cả players có bank âm >= 20k
function scanNegativePlayers()
	print("[okokBilling] 🔍 Đang quét tất cả players để kiểm tra nợ >= $20,000...")
	
	local jailedCount = 0
	local jailedPlayers = {}
	local jailedData = {} -- Array lưu thông tin để gửi webhook gộp
	local checkedCount = 0
	local onlineChecked = 0
	
	-- BƯỚC 1: Kiểm tra tất cả ONLINE players từ PlayerData (data thực tế sau khi RemoveMoney)
	local allOnlinePlayers = QBCore.Functions.GetQBPlayers()
	for _, xPlayer in pairs(allOnlinePlayers) do
		if xPlayer and xPlayer.PlayerData then
			onlineChecked = onlineChecked + 1
			local bankBalance = xPlayer.PlayerData.money.bank or 0
			
			-- Kiểm tra nợ >= 20k
			if bankBalance < 0 and math.abs(bankBalance) >= 20000 then
				local debtAmount = math.abs(bankBalance)
				local jailTime = math.floor(debtAmount / 1000) * 10
				
				jailedCount = jailedCount + 1
				table.insert(jailedPlayers, xPlayer.PlayerData.citizenid .. " ($"..debtAmount..") [ONLINE]")
				
				-- Lấy thông tin player
				local playerName = xPlayer.PlayerData.charinfo.lastname .. " " .. xPlayer.PlayerData.charinfo.firstname
				local playerPID = xPlayer.PlayerData.pid or "N/A"
				local citizenid = xPlayer.PlayerData.citizenid
				
				-- Set bank về 0
				xPlayer.Functions.SetMoney('bank', 0, 'Xóa nợ khi vào tù')
				
				-- Kiểm tra xem player đã có trong tù chưa
				exports.oxmysql:execute('SELECT actions_remaining FROM communityservice WHERE identifier = @identifier', {
					['@identifier'] = xPlayer.PlayerData.citizenid
				}, function(result)
					if result and result[1] then
						-- ĐANG Ở TÙ - Cộng thêm thời gian
						local oldActions = tonumber(result[1].actions_remaining) or 0
						local newActions = oldActions + jailTime
						
						exports.oxmysql:execute('UPDATE communityservice SET actions_remaining = @actions WHERE identifier = @identifier', {
							['@identifier'] = xPlayer.PlayerData.citizenid,
							['@actions'] = newActions
						}, function()
							-- Update số bãi cho client (không trigger lại inCommunityService)
							TriggerClientEvent('esx_communityservice:updateActions', xPlayer.PlayerData.source, newActions)
							TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "⚖️ Bạn bị phạt thêm "..jailTime.." bãi do nợ $"..debtAmount.." (Tổng: "..newActions.." bãi)", 'error', 15000)
							
							-- Lưu thông tin để gửi batch webhook sau
							table.insert(jailedData, {
								playerName = playerName,
								pid = playerPID,
								citizenid = citizenid,
								debtAmount = debtAmount,
								jailTime = jailTime,
								oldActions = oldActions,
								newActions = newActions,
								isOnline = true,
								isAddingTime = true
							})
							print("[okokBilling] 📝 Đã thêm vào jailedData (ONLINE-ACCUMULATION): " .. playerName .. " - Total: " .. #jailedData)
						end)
					else
						-- CHƯA Ở TÙ - Tạo mới và đưa vào tù
						exports.oxmysql:insert('INSERT INTO communityservice (identifier, actions_remaining) VALUES (@identifier, @actions)', {
							['@identifier'] = xPlayer.PlayerData.citizenid,
							['@actions'] = jailTime
						}, function()
							-- Đưa thẳng vào tù
							TriggerClientEvent('esx_communityservice:inCommunityService', xPlayer.PlayerData.source, jailTime)
							
							-- Lưu thông tin để gửi batch webhook sau
							table.insert(jailedData, {
								playerName = playerName,
								pid = playerPID,
								citizenid = citizenid,
								debtAmount = debtAmount,
								jailTime = jailTime,
								isOnline = true,
								isAddingTime = false
							})
						end)
					end
				end)
			end
		end
	end
	
	-- BƯỚC 2: Kiểm tra tất cả OFFLINE players từ database
	exports.oxmysql:execute('SELECT citizenid, money, charinfo, pid FROM players', {}, function(allPlayers)
		if not allPlayers then
			print("[okokBilling] ⚠️ Không thể truy vấn database players")
			return
		end
		
		for _, player in ipairs(allPlayers) do
			-- Bỏ qua nếu player đang online (đã check ở BƯỚC 1)
			local xPlayer = QBCore.Functions.GetPlayerByCitizenId(player.citizenid)
			if not xPlayer then
				checkedCount = checkedCount + 1
				local success, playerAccount = pcall(json.decode, player.money)
				
				if success and playerAccount and playerAccount.bank then
					local bankBalance = playerAccount.bank or 0
					
					-- Kiểm tra nợ >= 20k
					if bankBalance < 0 and math.abs(bankBalance) >= 20000 then
						local debtAmount = math.abs(bankBalance)
						local jailTime = math.floor(debtAmount / 1000) * 10
						
						jailedCount = jailedCount + 1
						table.insert(jailedPlayers, player.citizenid .. " ($"..debtAmount..") [OFFLINE]")
						
						-- Lấy thông tin player từ database
						local charSuccess, charInfo = pcall(json.decode, player.charinfo)
						local playerName = "Unknown"
						if charSuccess and charInfo then
							playerName = (charInfo.lastname or "?") .. " " .. (charInfo.firstname or "?")
						end
						local playerPID = player.pid or "N/A"
						local citizenid = player.citizenid
						
						-- Set bank = 0 trong database
						local clearedMoney = json.encode({bank = 0, cash = playerAccount.cash or 0})
						
						-- Kiểm tra xem player đã có trong tù chưa
						exports.oxmysql:execute('SELECT actions_remaining FROM communityservice WHERE identifier = @identifier', {
							['@identifier'] = player.citizenid
						}, function(jailResult)
							if jailResult and jailResult[1] then
								-- ĐANG Ở TÙ - Cộng thêm thời gian
								local oldActions = tonumber(jailResult[1].actions_remaining) or 0
								local newActions = oldActions + jailTime
								
								exports.oxmysql:execute('UPDATE communityservice SET actions_remaining = @actions WHERE identifier = @identifier', {
									['@identifier'] = player.citizenid,
									['@actions'] = newActions
								}, function()
									-- Update metadata và money
									exports.oxmysql:execute('UPDATE players SET metadata = JSON_SET(metadata, "$.injail", @jailTime), money = @money WHERE citizenid = @citizenid', {
										['@jailTime'] = newActions,
										['@money'] = clearedMoney,
										['@citizenid'] = player.citizenid
									})
									
									-- Lưu thông tin để gửi batch webhook sau (ACCUMULATION - OFFLINE)
									table.insert(jailedData, {
										playerName = playerName,
										pid = playerPID,
										citizenid = citizenid,
										debtAmount = debtAmount,
										jailTime = jailTime,
										oldActions = oldActions,
										newActions = newActions,
										isOnline = false,
										isAddingTime = true
									})
								end)
							else
								-- CHƯA Ở TÙ - Tạo mới
								exports.oxmysql:insert('INSERT INTO communityservice (identifier, actions_remaining) VALUES (@identifier, @actions)', {
									['@identifier'] = player.citizenid,
									['@actions'] = jailTime
								}, function()
									-- Cập nhật metadata injail trong database
									exports.oxmysql:execute('UPDATE players SET metadata = JSON_SET(metadata, "$.injail", @jailTime, "$.jailtimestamp", UNIX_TIMESTAMP()), money = @money WHERE citizenid = @citizenid', {
										['@jailTime'] = jailTime,
										['@money'] = clearedMoney,
										['@citizenid'] = player.citizenid
									})
									
									-- Lưu thông tin để gửi batch webhook sau (NEW - OFFLINE)
									table.insert(jailedData, {
										playerName = playerName,
										pid = playerPID,
										citizenid = citizenid,
										debtAmount = debtAmount,
										jailTime = jailTime,
										isOnline = false,
										isAddingTime = false
									})
								end)
							end
						end)
					end
				end
			end
		end
		
		-- Báo cáo quét tiền âm
		print("[okokBilling] ==================== BÁO CÁO QUÉT TIỀN ÂM ====================")
		print("[okokBilling] ✓ Đã kiểm tra ONLINE: " .. onlineChecked .. " players")
		print("[okokBilling] ✓ Đã kiểm tra OFFLINE: " .. checkedCount .. " players")
		if jailedCount > 0 then
			print("[okokBilling] 🚔 Đã bắt: " .. jailedCount .. " người vì nợ >= $20,000")
			for _, info in ipairs(jailedPlayers) do
				print("[okokBilling]    - " .. info)
			end
		else
			print("[okokBilling] ✓ Không có player nào nợ >= $20,000")
		end
		print("[okokBilling] ================================================================")
		
		-- Chờ 3 giây để tất cả nested database callbacks hoàn thành, rồi gửi batch webhook
		SetTimeout(3000, function()
			print("[okokBilling] 🔍 Kiểm tra jailedData: " .. #jailedData .. " người")
			-- Luôn gửi báo cáo, kể cả khi không có người bị bắt
			sendBatchJailWebhook(jailedData, onlineChecked, checkedCount)
		end)
	end)
end

function checkTimeLeft()
	-- Quét và xử lý TẤT CẢ hóa đơn chưa thanh toán (unpaid) - KHÔNG GIỚI HẠN
	exports.oxmysql:execute('SELECT *, TIMESTAMPDIFF(HOUR, limit_pay_date, CURRENT_TIMESTAMP()) AS "timeLeft" FROM okokBilling WHERE status = @status ORDER BY id DESC', {
		['@status'] = 'unpaid'
	}, function(result)
		if not result or #result == 0 then
			print("[okokBilling] ==================== BÁO CÁO TỰ ĐỘNG TRỪ HÓA ĐƠN ====================")
			print("[okokBilling] ✓ Không có hóa đơn unpaid cần xử lý")
			print("[okokBilling] 🧹 Đã xóa hóa đơn hết hạn 7 ngày: " .. expired7DaysDeletedCount)
			print("[okokBilling] ========================================================================")
			
			-- Dù không có hóa đơn, vẫn phải quét tiền âm
			SetTimeout(2000, function()
				scanNegativePlayers()
			end)
	else
	
	local invoiceList = result
	local processedCount = #invoiceList
	local successCount = 0
	local negativeCount = 0
	local deletedCount = 0
	local deletedCitizens = {}
	
	-- Lưu chi tiết từng hóa đơn
	local successDetails = {}
	local negativeDetails = {}
	
	-- Xử lý từng hóa đơn
	for k, v in ipairs(invoiceList) do
		local invoiceValue = v.invoice_value or 0
		local xPlayer = QBCore.Functions.GetPlayerByCitizenId(v.receiver_identifier)
			
				if xPlayer == nil then
					-- Player OFFLINE - Xử lý từ database
					exports.oxmysql:execute('SELECT money FROM players WHERE citizenid = @id', {
						['@id'] = v.receiver_identifier
					}, function(account)
						if account and account[1] and account[1].money then
							local success, playerAccount = pcall(json.decode, account[1].money)
							if success and playerAccount then
								local playerBank = playerAccount.bank or 0
								local playerCash = playerAccount.cash or 0
								local totalMoney = playerBank + playerCash
								
								-- Đếm trước khi xử lý và lưu chi tiết
								if totalMoney < invoiceValue then
									negativeCount = negativeCount + 1
									table.insert(negativeDetails, {
										name = v.receiver_name,
										pid = string.match(v.receiver_name, "%[(%d+)%]") or "N/A",
										id = v.id,
										amount = invoiceValue
									})
								else
									successCount = successCount + 1
									table.insert(successDetails, {
										name = v.receiver_name,
										pid = string.match(v.receiver_name, "%[(%d+)%]") or "N/A",
										id = v.id,
										amount = invoiceValue
									})
								end
							
							local remainingAmount = invoiceValue
							local paymentMethod = 'ngân hàng'
							
							-- BƯỚC 1: Trừ hết tiền mặt trước
							if playerCash > 0 then
								if playerCash >= remainingAmount then
									playerAccount.cash = playerCash - remainingAmount
									paymentMethod = 'tiền mặt'
									remainingAmount = 0
								else
									playerAccount.cash = 0
									remainingAmount = remainingAmount - playerCash
									paymentMethod = 'tiền mặt + ngân hàng'
								end
							end
							
							-- BƯỚC 2: Trừ phần còn lại từ Bank (CHO PHÉP ÂM)
							if remainingAmount > 0 then
								playerAccount.bank = playerAccount.bank - remainingAmount
							end
							
							-- Cập nhật database
							local encodedMoney = json.encode({bank = playerAccount.bank, cash = playerAccount.cash})
							exports.oxmysql:execute('UPDATE players SET money = @playerAccount WHERE citizenid = @target', {
								['@playerAccount'] = encodedMoney,
								['@target'] = v.receiver_identifier
							})
							
							-- Cập nhật trạng thái hóa đơn
							exports.oxmysql:execute('UPDATE okokBilling SET status = @paid, paid_date = CURRENT_TIMESTAMP() WHERE id = @id', {
								['@paid'] = 'autopaid',
								['@id'] = v.id
							})
						else
							-- Không tìm thấy hoặc lỗi decode - Xóa hóa đơn
							deletedCount = deletedCount + 1
							table.insert(deletedCitizens, v.receiver_identifier)
							exports.oxmysql:execute('DELETE FROM okokBilling WHERE id = @id', {
								['@id'] = v.id
							})
						end
					else
						-- Không tìm thấy account - Xóa hóa đơn
						deletedCount = deletedCount + 1
						table.insert(deletedCitizens, v.receiver_identifier)
						exports.oxmysql:execute('DELETE FROM okokBilling WHERE id = @id', {
							['@id'] = v.id
						})
					end
				end)
		else
			-- Player ONLINE - Xử lý trực tiếp
				local playerBank = xPlayer.PlayerData.money.bank or 0
				local playerCash = xPlayer.PlayerData.money.cash or 0
				local totalMoney = playerBank + playerCash
				
				-- Đếm trước khi xử lý và lưu chi tiết
				if totalMoney < invoiceValue then
					negativeCount = negativeCount + 1
					table.insert(negativeDetails, {
						name = v.receiver_name,
						pid = string.match(v.receiver_name, "%[(%d+)%]") or "N/A",
						id = v.id,
						amount = invoiceValue
					})
				else
					successCount = successCount + 1
					table.insert(successDetails, {
						name = v.receiver_name,
						pid = string.match(v.receiver_name, "%[(%d+)%]") or "N/A",
						id = v.id,
						amount = invoiceValue
					})
				end
				
				local remainingAmount = invoiceValue
				local paymentMethod = 'ngân hàng'
				
				-- BƯỚC 1: Trừ hết tiền mặt trước
				if playerCash > 0 then
					if playerCash >= remainingAmount then
						xPlayer.Functions.RemoveMoney("cash", remainingAmount, 'Hóa đơn tự động')
						paymentMethod = 'tiền mặt'
						remainingAmount = 0
					else
						xPlayer.Functions.RemoveMoney("cash", playerCash, 'Hóa đơn tự động')
						remainingAmount = remainingAmount - playerCash
						paymentMethod = 'tiền mặt + ngân hàng'
					end
				end
				
				-- BƯỚC 2: Trừ phần còn lại từ Bank (CHO PHÉP ÂM)
				if remainingAmount > 0 then
					xPlayer.Functions.RemoveMoney("bank", remainingAmount, 'Hóa đơn tự động')
					
					if playerBank < remainingAmount then
						TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "⚠️ Hóa đơn #"..v.id.." đã trừ âm tài khoản ngân hàng!", 'error', 10000)
				end
			end
			
			-- Cập nhật trạng thái hóa đơn
			exports.oxmysql:execute('UPDATE okokBilling SET status = @paid, paid_date = CURRENT_TIMESTAMP() WHERE id = @id', {
				['@paid'] = 'autopaid',
				['@id'] = v.id
			})
			
			if totalMoney >= invoiceValue then
				TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "Hóa đơn #"..v.id.." đã được thanh toán tự động!", 'info', 10000)
			end
			
			-- Webhook riêng lẻ đã bị tắt để tránh trùng lặp
			-- Chỉ gửi báo cáo tổng hợp ở cuối
			end
		end
		
		-- Báo cáo tổng kết hóa đơn
		Wait(2000) -- Đợi 2 giây cho callbacks hoàn thành
		print("[okokBilling] ==================== BÁO CÁO TỰ ĐỘNG TRỪ HÓA ĐƠN ====================")
		print("[okokBilling] ✓ Tổng số hóa đơn đã xử lý: "..processedCount)
		print("[okokBilling] ✓ Thanh toán thành công: "..successCount.." hóa đơn")
		print("[okokBilling] ⚠️ Trừ âm ngân hàng: "..negativeCount.." hóa đơn")
		if deletedCount > 0 then
			print("[okokBilling] ❌ Đã xóa (không tìm thấy citizen): "..deletedCount.." hóa đơn")
			print("[okokBilling]    Citizens: " .. table.concat(deletedCitizens, ", "))
		end
		print("[okokBilling] ========================================================================")
		
		-- Gửi báo cáo invoice qua Discord
		if JAIL_WEBHOOK and JAIL_WEBHOOK ~= '' then
			print("[okokBilling] 📤 Đang gửi webhook báo cáo hóa đơn...")
			SetTimeout(1000, function()
				-- Tạo báo cáo
				local messages = {}
				local currentMessage = ""
				local maxLength = 1800 -- Giới hạn độ dài Discord
				
				-- HEADER
			local header = "📋 **BÁO CÁO TỰ ĐỘNG TRỪ HÓA ĐƠN**\n"
			header = header .. "```\n"
			header = header .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
			header = header .. "📊 TỔNG QUAN:\n"
			header = header .. "   • Tổng xử lý:  " .. processedCount .. " hóa đơn\n"
			header = header .. "   • Thành công:  " .. successCount .. " hóa đơn\n"
			header = header .. "   • Trừ âm:      " .. negativeCount .. " hóa đơn"
			header = header .. "\n   • Xóa quá hạn 7 ngày: " .. expired7DaysDeletedCount .. " hóa đơn"
			if deletedCount > 0 then
				header = header .. "\n   • Đã xóa:      " .. deletedCount .. " hóa đơn"
			end
			header = header .. "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
			
			currentMessage = header
			
			-- CHI TIẾT HÓA ĐƠN THÀNH CÔNG
			if #successDetails > 0 then
				currentMessage = currentMessage .. "\n\n✅ THANH TOÁN THÀNH CÔNG:\n"
				currentMessage = currentMessage .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
				currentMessage = currentMessage .. string.format("%-28s %-8s %-15s %-10s\n", "Tên", "ID", "Số hóa đơn", "Số tiền")
				currentMessage = currentMessage .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
				
				for i, detail in ipairs(successDetails) do
				-- Loại bỏ [ID] ở đầu tên
				local cleanName = string.gsub(detail.name, "^%[%d+%]%s*", "")
				local line = string.format("%-28s %-8s #%-14s $%-9s\n", 
					string.sub(cleanName, 1, 27),
					detail.pid,
					detail.id,
					detail.amount
					)
					
					-- Kiểm tra nếu vượt giới hạn độ dài
					if #(currentMessage .. line .. "```") > maxLength then
						currentMessage = currentMessage .. "```"
						table.insert(messages, currentMessage)
						currentMessage = "✅ **THANH TOÁN THÀNH CÔNG (tiếp):**\n```\n"
						currentMessage = currentMessage .. string.format("%-28s %-8s %-15s %-10s\n", "Tên", "ID", "Số hóa đơn", "Số tiền")
						currentMessage = currentMessage .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
						currentMessage = currentMessage .. line
					else
						currentMessage = currentMessage .. line
					end
				end
			end
			
			-- CHI TIẾT HÓA ĐƠN TRỪ ÂM
			if #negativeDetails > 0 then
				local negativeLine = "\n⚠️ TRỪ ÂM NGÂN HÀNG:\n"
				negativeLine = negativeLine .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
				negativeLine = negativeLine .. string.format("%-28s %-8s %-15s %-10s\n", "Tên", "ID", "Số hóa đơn", "Số tiền")
				negativeLine = negativeLine .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
				
				-- Kiểm tra nếu thêm header trừ âm sẽ vượt limit
				if #(currentMessage .. negativeLine .. "```") > maxLength then
					currentMessage = currentMessage .. "```"
					table.insert(messages, currentMessage)
					currentMessage = "⚠️ **TRỪ ÂM NGÂN HÀNG:**\n```\n"
					currentMessage = currentMessage .. string.format("%-28s %-8s %-15s %-10s\n", "Tên", "ID", "Số hóa đơn", "Số tiền")
					currentMessage = currentMessage .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
				else
					currentMessage = currentMessage .. negativeLine
				end
				
				for i, detail in ipairs(negativeDetails) do
				-- Loại bỏ [ID] ở đầu tên
				local cleanName = string.gsub(detail.name, "^%[%d+%]%s*", "")
				local line = string.format("%-28s %-8s #%-14s $%-9s\n", 
					string.sub(cleanName, 1, 27),
					detail.pid,
					detail.id,
					detail.amount
					)
					
					-- Kiểm tra nếu vượt giới hạn độ dài
					if #(currentMessage .. line .. "```") > maxLength then
						currentMessage = currentMessage .. "```"
						table.insert(messages, currentMessage)
						currentMessage = "⚠️ **TRỪ ÂM NGÂN HÀNG (tiếp):**\n```\n"
						currentMessage = currentMessage .. string.format("%-28s %-8s %-15s %-10s\n", "Tên", "ID", "Số hóa đơn", "Số tiền")
						currentMessage = currentMessage .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
						currentMessage = currentMessage .. line
					else
						currentMessage = currentMessage .. line
					end
				end
			end
			
			-- Đóng code block và thêm message cuối cùng
			if currentMessage ~= "" then
				if not string.match(currentMessage, "```$") then
					currentMessage = currentMessage .. "```"
				end
				table.insert(messages, currentMessage)
			end
				
				-- Gửi từng message với delay 1 giây
				print("[okokBilling] 📤 Đang gửi " .. #messages .. " webhook message(s)...")
				for i, msg in ipairs(messages) do
					SetTimeout((i - 1) * 1000, function()
						PerformHttpRequest(JAIL_WEBHOOK, function(err, text, headers) 
							print("[okokBilling] Webhook #"..i.." - Status:", err, "Response:", text)
						end, 'POST', json.encode({content = msg}), {['Content-Type'] = 'application/json'})
					end)
				end
			end)
		else
			print("[okokBilling] ⚠️ Không gửi webhook: JAIL_WEBHOOK chưa được config")
		end
	
	-- Đợi 8 giây để đảm bảo tất cả UPDATE đã commit vào database, rồi quét tiền âm
	SetTimeout(8000, function()
		scanNegativePlayers()
	end)
end
end)

-- SetTimeout(30 * 60000, checkTimeLeft) -- COMMENTED: Chỉ quét 1 lần khi khởi động
end

-- Khởi động auto-payment sau khi tất cả resources đã load
if Config.PayAutomaticallyAfterLimit then
	CreateThread(function()
		Wait(15000) -- Đợi 15 giây để đảm bảo tất cả resources đã sẵn sàng
		print("^2[okokBilling]^0 Bắt đầu quét auto-payment sau khi hệ thống khởi động hoàn tất...")
		clearExpiredInvoicesOnStart(function()
			checkTimeLeft()
		end)
	end)
end

-------------------------- JAIL WEBHOOK (GỬI LOG KHI BẮT NỢ)

function sendJailWebhook(data)
	-- Kiểm tra webhook có được config không
	if not JAIL_WEBHOOK or JAIL_WEBHOOK == '' then
		return
	end
	
	-- Format đơn giản: tên: mr bin id: 1954 -50000 500 bãi
	local message = "tên: " .. data.playerName .. " id: " .. data.pid .. " -" .. data.debtAmount .. " " .. data.jailTime .. " bãi"
	
	-- Nếu cộng thêm thì hiển thị tổng
	if data.isAddingTime then
		message = message .. " (Tổng: " .. data.newActions .. " bãi)"
	end
	
	PerformHttpRequest(JAIL_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({content = message}), {['Content-Type'] = 'application/json'})
end

function sendBatchJailWebhook(jailedData, onlineChecked, offlineChecked)
	if not JAIL_WEBHOOK or JAIL_WEBHOOK == '' then
		print("[okokBilling] ⚠️ Không gửi batch jail webhook: JailWebhook chưa config")
		return
	end
	
	-- Tạo header báo cáo
	local onlineJailed = 0
	local offlineJailed = 0
	local jailedCount = 0
	
	if jailedData and #jailedData > 0 then
		jailedCount = #jailedData
		for _, data in ipairs(jailedData) do
			if data.isOnline then
				onlineJailed = onlineJailed + 1
			else
				offlineJailed = offlineJailed + 1
			end
		end
		print("[okokBilling] 📊 Chuẩn bị gửi batch jail webhook cho " .. jailedCount .. " con nợ...")
	else
		print("[okokBilling] 📊 Chuẩn bị gửi batch jail webhook (Không có con nợ bị bắt)")
	end
	
	local reportHeader = "🚔 BÁO CÁO BẮT NỢ ĐẤT BẮC\n━━━━━━━━━━━━━━━━━━━━━━━\n"
	reportHeader = reportHeader .. "🔍 Quét: " .. (onlineChecked or 0) .. " Online | " .. (offlineChecked or 0) .. " Offline\n"
	
	if jailedCount > 0 then
		reportHeader = reportHeader .. "🚨 Bắt: " .. jailedCount .. " con nợ (" .. onlineJailed .. " Online | " .. offlineJailed .. " Offline)\n"
		reportHeader = reportHeader .. "━━━━━━━━━━━━━━━━━━━━━━━"
	else
		reportHeader = reportHeader .. "✅ Không có con nợ nào >= $20,000"
	end
	
	local messages = {}
	local currentMessage = reportHeader
	local maxLength = 1800 -- Safety margin under Discord's 2000 char limit
	
	-- Chỉ xử lý danh sách khi có người bị bắt
	if jailedCount > 0 then
		for i, data in ipairs(jailedData) do
			-- Format: tên: mr bin id: 1954 -50000 500 bãi
			local line = "tên: " .. data.playerName .. " id: " .. data.pid .. " -" .. data.debtAmount .. " " .. data.jailTime .. " bãi"
			
			-- Nếu cộng thêm thì hiển thị tổng
			if data.isAddingTime then
				line = line .. " (Tổng: " .. data.newActions .. " bãi)"
			end
			
			-- Kiểm tra nếu thêm line này sẽ vượt limit
			local testMessage = currentMessage .. "\n" .. line
			
			if #testMessage > maxLength and currentMessage ~= "" then
				-- Lưu message hiện tại và bắt đầu message mới (không có header)
				table.insert(messages, currentMessage)
				currentMessage = line
			else
				-- Thêm vào message hiện tại
				currentMessage = testMessage
			end
		end
	end
	
	-- Thêm message cuối cùng
	if currentMessage ~= "" then
		table.insert(messages, currentMessage)
	end
	
	-- Gửi từng message với delay 2 giây
	print("[okokBilling] 📤 Đang gửi " .. #messages .. " webhook message(s) cho bắt nợ...")
	for i, msg in ipairs(messages) do
		SetTimeout((i - 1) * 2000, function()
			PerformHttpRequest(JAIL_WEBHOOK, function(err, text, headers) 
				print("[okokBilling] Batch Jail Webhook #"..i.." - Status:", err, "Response:", text)
			end, 'POST', json.encode({content = msg}), {['Content-Type'] = 'application/json'})
		end)
	end
	
	if jailedCount > 0 then
		print("[okokBilling] 📤 Đã gửi " .. #messages .. " webhook message(s) với " .. jailedCount .. " con nợ vào tù")
	else
		print("[okokBilling] 📤 Đã gửi báo cáo: Không có con nợ nào bị bắt")
	end
end

-------------------------- PAY INVOICE WEBHOOK

function payInvoiceWebhook(data)
	-- Lấy webhook theo society
	local societyWebhook = Config.SocietyWebhooks[data.society_code] or ''
	
	-- Nếu không có webhook, không gửi
	if societyWebhook == '' then
		return
	end
	
	local information = {
		{
			["color"] = Config.PayInvoiceWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["title"] = '💰 Hóa Đơn #'..data.id..' Đã Được Thanh Toán',
			["description"] = '**👤 Người Thanh Toán:** '..data.player_name..'\n**💵 Số Tiền:** $'..data.value..'\n**📝 Nội Dung:** '..data.item..'\n**🏢 Ban Ngành:** '..data.society..'\n**💳 Phương Thức:** '..data.payment_method,

			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(societyWebhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

-------------------------- CANCEL INVOICE WEBHOOK

function cancelInvoiceWebhook(data)
	-- Lấy webhook theo society
	local societyWebhook = Config.SocietyWebhooks[data.society_code] or ''
	
	-- Nếu không có webhook, không gửi
	if societyWebhook == '' then
		return
	end
	
	local information = {
		{
			["color"] = Config.CancelInvoiceWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["title"] = '❌ Hóa Đơn #'..data.id..' Đã Bị Hủy',
			["description"] = '**👮 Người Hủy:** '..data.name..'\n\n**👤 Người Nhận:** '..data.player_name..'\n**💵 Số Tiền:** $'..data.value..'\n**📝 Nội Dung:** '..data.item..'\n**🏢 Ban Ngành:** '..data.society,

			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(societyWebhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

-------------------------- CREATE NEW INVOICE WEBHOOK

function createNewInvoiceWebhook(data)
	-- Lấy webhook theo society
	local societyWebhook = Config.SocietyWebhooks[data.society_code] or ''
	
	-- Nếu không có webhook, không gửi
	if societyWebhook == '' then
		return
	end
	
	local information = {
		{
			["color"] = Config.CreateNewInvoiceWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["title"] = '📄 Hóa Đơn #'..data.id..' Đã Được Tạo',
			["description"] = '**✍️ Người Tạo:** '..data.name..'\n**🏢 Ban Ngành:** '..data.society..'\n\n**👤 Người Nhận:** '..data.player_name..'\n**💵 Số Tiền:** $'..data.value..'\n**📝 Nội Dung:** '..data.item,

			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(societyWebhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

-------------------------- AUTOPAY INVOICE WEBHOOK

function autopayInvoiceWebhook(data)
	-- Lấy webhook theo society
	local societyWebhook = Config.SocietyWebhooks[data.society_code] or ''
	
	-- Nếu không có webhook, không gửi
	if societyWebhook == '' then
		return
	end
	
	local information = {
		{
			["color"] = Config.AutopayInvoiceWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["title"] = '⚡ Hóa Đơn #'..data.id..' Đã Tự Động Thanh Toán',
			["description"] = '**👤 Người Thanh Toán:** '..data.player_name..'\n**💵 Số Tiền:** $'..data.value..'\n**📝 Nội Dung:** '..data.item..'\n**🏢 Ban Ngành:** '..data.society..'\n**💳 Phương Thức:** '..data.payment_method,

			["footer"] = {
				["text"] = os.date(Config.DateFormat),
			}
		}
	}
	PerformHttpRequest(societyWebhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end

--=================================================== CLEAR HÓA ĐƠN ĐÃ THANH TOÁN ===================================================
RegisterServerEvent('okokBilling:server:clear_hoadon')
AddEventHandler('okokBilling:server:clear_hoadon', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	exports.oxmysql:execute("SELECT * FROM okokBilling WHERE status = @status", {
        ["@status"] = 'paid',
    }, function(status)
		if status then
			exports.oxmysql:execute('DELETE FROM okokBilling WHERE status = @status', {
				["@status"] = 'paid'
			})
			TriggerClientEvent('QBCore:Notify', src, "Xóa thành công toàn bộ hóa đơn đã thanh toán", 'info', 10000)
		end
	end)
end)
--=================================================== CLEAR HÓA ĐƠN CÁ NHÂN ===================================================
RegisterServerEvent('okokBilling:server:clear_hd_canhan')
AddEventHandler('okokBilling:server:clear_hd_canhan', function(billnumber)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	exports.oxmysql:execute("SELECT * FROM okokBilling WHERE id = @id", {
        ["@id"] = billnumber,
    }, function(id)
		if id[1] ~= nil then
			exports.oxmysql:execute('DELETE FROM okokBilling WHERE id = @id', {
				["@id"] = billnumber
			})
			TriggerClientEvent('QBCore:Notify', src, "Xóa thành công hóa đơn số: "..billnumber.."", 'info', 10000)
		else
			TriggerClientEvent('QBCore:Notify', src, "Hóa đơn số: "..billnumber.." không tồn tại", 'error', 10000)
		end
	end)
end)