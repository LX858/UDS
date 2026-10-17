Config = {}

-- Loai giao dien nhap so luong trong ox_lib ('number' hoac 'slider')
Config.InputType = 'number'

-- Mo ta hien thi duoi title
Config.Description = 'Vật phẩm này đã hết hạn sử dụng hãy quy đổi lại thành tiền mặt'

-- Danh sach vat pham quy doi thanh tien mat
Config.Items = {
    ['com_suon_tam'] = {
        label = 'bánh Mochi',
        price = 500, -- 500$ cho 1 vat pham
        icon = 'cookie',
    },
    ['chieungu'] = {
        label = 'Chiếu ngủ',
        price = 1500, -- 500$ cho 1 vat pham
        icon = 'cookie',
    },
    ['banhrandua_ht'] = {
        label = 'Bánh rán dừa',
        price = 800, -- 800$ cho 1 vat pham
        icon = 'cookie',
    }
}
