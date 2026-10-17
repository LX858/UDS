Config = Config or {}

-------------------------- WEBHOOK CHO TỪNG BAN NGÀNH
-- Cấu hình webhook riêng cho từng society (ban ngành)
-- Nếu society không có trong danh sách hoặc webhook = '', sẽ không gửi log
Config.SocietyWebhooks = {
	['police'] = 'https://discord.com/api/webhooks/1467123974168379414/9FfVUzXFX1OASDaH3fNnUP-lWF6BoU7Kz4MVifjHXRzcDoPbXmai6ETS597lYxE-YZJP', -- Webhook cho Sở Cảnh Sát
	['ambulance'] = 'https://discord.com/api/webhooks/1467124058083688538/epAbBUrh_BuL5zynDT3SjTqX3zkYxAmK7CVcCVksTjL-LtY0lb0_TgsOpFOvsvEx8Xvm', -- Webhook cho Bệnh Viện
	['mechanic'] = 'https://discord.com/api/webhooks/1469045995261264013/y9aVtViooHck7v-1kNP23WJDZPhZKYSHCMK3saQ203KU_6K-A_Fboljv25MbBxeJ18q1', -- Webhook cho Garage/Mechanic
	['cardealer'] = '', -- Webhook cho Đại Lý Xe
	['nhahang'] = '', -- Webhook cho Nhà Hàng
	['doxe'] = '', -- Webhook cho Đỗ Xe
	['bar'] = '', -- Webhook cho Bar
	['quannuoc'] = '', -- Webhook cho Quán Nước
	['toathichinh'] = '', -- Webhook cho Tòa Thị Chính
}
