Config = {}

-------------------------- COMMANDS & FUNCTIONALITY

Config.InvoicesCommand = 'hoadon' -- Command used to open the invoices menu

Config.VATPercentage = 10 -- Chỉ trực quan, nó sẽ không ảnh hưởng đến giá trị hóa đơn cuối cùng, thay đổi nó thành giá trị VAT quốc gia của bạn

Config.LimitDate = true -- Used to enable/disable whether we want to have the payment limit date or not

Config.LimitDateDays = 1 -- If Config.LimitDate is enabled, it is used to define the days of the deadline for payment after issuing the invoice

Config.PayAutomaticallyAfterLimit = true -- It serves to enable/disable if we want the invoice to be automatically paid after the due date

-- (For this to work you need to set  = true and add a number to LimitDateDays)
Config.FeeAfterEachDay = true -- Serves to enable/disable if we want unpaid invoices to increase in value after each day they are not paid 

Config.FeeAfterEachDayPercentage = 5 -- If Config.FeeAfterEachDay is enabled, it is used to set the fee percentage after each day

Config.OnlyBossCanAccessSocietyInvoices = false -- Defines if only the boss can access the society invoices, if false all the employees will have access to it

Config.AllowedSocieties = { -- Allowed societies to open the 'Society Invoices' and 'Create Invoice' menus
	-- 'police',
	-- 'ambulance',
	-- 'mechanic',
	-- 'cardealer',
	-- 'nhahang',
	-- 'doxe',
	-- 'bar',
	-- 'quannuoc',
	-- 'toathichinh'
}

-- Doanh nghiệp được phép thanh toán tự động ngay khi tạo hóa đơn
Config.AutoPaySocieties = {
	'police',      -- Cảnh sát
	'ambulance',   -- Bệnh viện
	'cardealer'    -- Đại lý xe
}

Config.CID_CancelBill = {
    "CYW04708",
	"FE21QI0E",
	"G601AI68",
	"GXBP4543",
	"SCLV2HJP",
	"Z9I65HI6",
	"Y3H75683",
}
-------------------------- DISCORD LOGS

Config.BotName = 'MINI CITY' -- Write the desired bot name

Config.ServerName = 'MINI CITY' -- Write your server's name

Config.IconURL = 'https://cdn.discordapp.com/attachments/1214393064135589969/1221632834586939402/512x512.png?ex=6613493c&is=6600d43c&hm=44a79c30012ddaff817add5a6934d9717e38b0b34a0d352ced3284d1feeb1d57&' -- Insert your desired image link

Config.DateFormat = '%d/%m/%Y [%X]' -- To change the date format check this website - https://www.lua.org/pil/22.1.html

-- To change a webhook color you need to set the decimal value of a color, you can use this website to do that - https://www.mathsisfun.com/hexadecimal-decimal-colors.html

Config.CreateNewInvoiceWebhookColor = '16127'

Config.PayInvoiceWebhookColor = '65352'

Config.AutopayInvoiceWebhookColor = '4542858'

Config.CancelInvoiceWebhookColor = '9868950'

-------------------------- WEBHOOK CHO TỪNG BAN NGÀNH

-- Cấu hình webhook riêng cho từng society (ban ngành)
-- Nếu society không có trong danh sách hoặc webhook = '', sẽ không gửi log
Config.SocietyWebhooks = {
	['police'] = 'https://discordapp.com/api/webhooks/1464260689341452442/dME1bGL-dxbpAZb4gvankwX_gEReWleG8MkrbPwBY_xy-hND06CAFdTYxuFx3b6KnVAv', -- Webhook cho Sở Cảnh Sát
	['ambulance'] = 'https://discordapp.com/api/webhooks/1464261582157643851/MyfKq7b0zIHMDgDu8mijJxJ71_BZDx3XKFFVWmYA38IgVZ8ap3ftplkoi6UI-1fy0KiU', -- Webhook cho Bệnh Viện
	['mechanic'] = '', -- Webhook cho Garage/Mechanic
	['cardealer'] = '', -- Webhook cho Đại Lý Xe
	['nhahang'] = '', -- Webhook cho Nhà Hàng
	['doxe'] = '', -- Webhook cho Đỗ Xe
	['bar'] = '', -- Webhook cho Bar
	['quannuoc'] = '', -- Webhook cho Quán Nước
	['toathichinh'] = '', -- Webhook cho Tòa Thị Chính
}