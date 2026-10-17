local resource = GetCurrentResourceName()

Config = {}

Config.CustomApps = {
    ["ubee_taxi"] = { -- A unique identifier for the app, not shown to the user
        name = "Ubee", -- The name of the app, shown to the user
        description = "Đặt xe và chạy taxi trong thành phố.", -- The description of the app, shown to the user
        developer = "LuaNest", -- OPTIONAL the developer of the app
        defaultApp = true, -- OPTIONAL if set to true, app should be added without having to download it,
        game = false, -- OPTIONAL if set to true, app will be added to the game section
        size = 59812, -- OPTIONAL in kB
        images = {}, -- OPTIONAL array of images for the app on the app store
        ui = resource .. "/ui/index.html", -- OPTIONAL
        icon = "https://cfx-nui-" .. resource .. "/ui/icon.svg", -- OPTIONAL app icon
        price = 0, -- OPTIONAL, Make players pay with in-game money to download the app
        landscape = false, -- OPTIONAL, if set to true, the app will be displayed in landscape mode
        keepOpen = false, -- OPTIONAL, if set to true, the app will not close when the player opens the app (only works if ui is not defined)
        -- onUse = function() -- OPTIONAL function to be called when the app is opened
        --     -- do something
        -- end,
        -- onServerUse = function(source) -- OPTIONAL server side function to be called when the app is opened
        --     -- do something
        -- end
    }
}

-- Giữ tương thích ngược với các hàm/sự kiện gọi Config.App
Config.App = Config.CustomApps["ubee_taxi"]
Config.App.id = "ubee_taxi"

Config.Rates = { bike = 2400, car = 3000 } -- Giá tiền trên mỗi km (xe máy / ô tô)
Config.MinFare = 500                       -- Giá cước tối thiểu cho mỗi chuyến đi
Config.DriverShare = 0.9                   -- Tỷ lệ chia cho tài xế (90%), còn lại là hoa hồng hệ thống
Config.RegisterFee = 1000                  -- Phí đăng ký làm tài xế
Config.InviteTimeout = 20                  -- Thời gian chờ tài xế phản hồi lời mời (giây)
Config.SearchTimeout = 180                 -- Thời gian tối đa tìm tài xế cho khách (giây)
Config.ArriveRange = 60.0                  -- Khoảng cách tối đa (mét) để tính là tài xế đã đến điểm đón
Config.HistoryLimit = 20                   -- Số lượng chuyến đi lưu trong lịch sử của người dùng

-- Billing (unpaid fares) lives in config_sv.lua (server only).  
