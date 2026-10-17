-- Items cho ox_inventory
-- Copy nội dung này vào file: ox_inventory/data/items.lua

return {
	-- Xích chó (dùng khi đi bộ)
	["xichcho"] = {
		label = "Xích Chó",
		weight = 500,
		stack = true,
		close = true,
		consume = 0,
		description = "Dây xích để bắt chó khi đi bộ. Đứng gần chó và sử dụng item này.",
		client = {
			export = 'xn_tromcho.UseXichCho'
		}
	},
	
	-- Thòng lọng (dùng khi trên xe)
	["thonglong"] = {
		label = "Thòng Lọng",
		weight = 800,
		stack = true,
		close = true,
		consume = 0,
		description = "Thòng lọng để bắt chó từ xa khi đang trên xe máy. Ngồi sau xe và sử dụng khi gần chó.",
		client = {
			export = 'xn_tromcho.UseThongLong'
		}
	}
}w
--[[
HƯỚNG DẪN CÀI ĐẶT:

1. Mở file: ox_inventory/data/items.lua

2. Thêm 2 items này vào trong bảng items:

["xichcho"] = {
	label = "Xích Chó",
	weight = 500,
	stack = true,
	close = true,
	description = "Dây xích để bắt chó khi đi bộ. Đứng gần chó và sử dụng item này.",
	client = {
		export = 'xn_tromcho.UseXichCho'
	}
},

["thonglong"] = {
	label = "Thòng Lọng", 
	weight = 800,
	stack = true,
	close = true,
	description = "Thòng lọng để bắt chó từ xa khi đang trên xe máy. Ngồi sau xe và sử dụng khi gần chó.",
	client = {
		export = 'xn_tromcho.UseThongLong'
	}
},

3. Restart ox_inventory và xn_tromcho

4. Test bằng cách:
   - Give item: /giveitem [id] xichcho 5
   - Give item: /giveitem [id] thonglong 5
   - Đến khu vực chó spawn
   - Đứng gần chó và click USE item trong inventory

CÁCH HOẠT ĐỘNG:
- Khi đi bộ: Đứng gần chó (< 1.5m) → Sử dụng "Xích Chó" từ inventory
- Khi trên xe: Ngồi sau xe Exciter → Đến gần chó (< 4m) → Sử dụng "Thòng Lọng" từ inventory
- Không cần nhấn phím E nữa!
- Item sẽ tự động bị xóa sau khi sử dụng (được xử lý bởi server)

LƯU Ý:
- Đảm bảo Config.VatPham = "xichcho" 
- Đảm bảo Config.PhuongTien.VatPham = "thonglong"
- Đảm bảo fxmanifest.lua có: client_export { 'UseXichCho', 'UseThongLong' }
]]
