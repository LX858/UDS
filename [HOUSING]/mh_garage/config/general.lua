return {
    PhoneTakeoutPrice = 0, -- Số tiền phải trả khi lấy xe từ xa bằng TakeVehicleOutPhone
    
    Markers = {
        Enter = { id = 36, scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0, red = 30, green = 150, blue = 30 },
        Exit = { id = 36, scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0, red = 30, green = 150, blue = 30 },
        DeleteVehicle = { id = 36, scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0, red = 150, green = 30, blue = 30 },
        CustomizationMenu = { id = 36, scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0, red = 30, green = 150, blue = 30 },
        Impound = { id = 36, scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0, red = 30, green = 150, blue = 30 }
    },

    VehicleScaleFormInfo = false, -- shows vehicle info (speed, traction, acceleration etc) in scaleform, will use more ms

    -- Các mô hình ngẫu nhiên sẽ được chọn từ đây khi xem trước gara
    PreviewModels = {
        ['car'] = {
            "adder",
            "autarch",
            "banshee2",
            "bullet",
            "cheetah",
            "cyclone",
            "deveste",
            "emerus",
            "xa21",
            "zentorno",
            "zr350"
        },
        ['air'] = {
            'alkonost',
            'alphaz1',
            'avenger',
            'avenger2',
            'avenger3',
            'avenger4',
            'besra',
            'dodo',
            'cuban800',
            'jet',
            'vestra',
            'velum2'
        }
    }
}