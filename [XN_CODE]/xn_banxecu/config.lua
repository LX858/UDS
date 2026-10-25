Config = {}

Config.Debug = false -- Bật/tắt debug logs

-- Các vị trí được phép bán xe
Config.SaleZonePoints = {
    vec3(908.1, -19.7, 78.76),
    vec3(929.2, -36.1, 78.76),
    vec3(899.2, -86.0, 78.76),
    vec3(875.0, -69.8, 78.76),
}

-- Độ dày của zone poly
Config.ZoneThickness = 5.0

-- Phần trăm thuế giao dịch (5%)
Config.TransactionTax = 0.05

-- Phần trăm giá min/max so với giá cardealer (50%)
Config.PricePercentage = 0.5

-- Bán kính tìm người chơi gần nhất
Config.NearbyRadius = 5.0

-- Cấu hình item vé bán xe VIP (để bán các xe trong danh sách BlacklistedVehicles)
Config.VIPItem = {
    enabled = true,
    item = 'vebanxevip',
    label = 'Vé Bán Xe VIP',
    count = 1,
    minPrice = 1000000 -- Giá bán tối thiểu mặc định khi bán xe VIP/Blacklist (1.000.000 cash)
}

-- Danh sách xe không được phép bán trừ khi có vé VIP (blacklist)
Config.BlacklistedVehicles = {
    'policeold1',
    'policeold2',
    'police',
    'police2',
    'police3',
    'police4',
    'policeb',
    'titanh2',
    'policet',
    'sheriff',
    'sheriff2',
    'ambulance',
    'firetruk',
    'lguard',
    'riot',
    'fbi',
    'fbi2',
    'pranger',
    'polmav',
    'r2f2fgtr34',
    '2f2fs2000',
    'chargerf8',
    'r2f2fgts',
    'r2f2fmk4',
    'r2f2fmle7',
    'ff4wrx',
    'fnf4r34',
    'fnflan',
    'fnfmits',
    'fnfmk4',
    'fnfrx7',
    'thecivir23',
    'draugur',
    'titanh2',
    'yaz',
    'sh350',
    'GODz95GSX',
    'Dicygt3mq',
    'raulzl1',
    'carmaz',
    'Ks_Kitty_Speaker',
    'sidecarh',
    'bmwm8',
    'kamacho',
    'r35ultra',
    'rmod918spyder',
    'tundrat',
    'shabudragon',
    'rmodmustang',
    'x3bearcat2',
    'm5g60',
    'vf3',
    'vf8',
    'vf9'
    -- Thêm tên xe muốn blacklist ở đây
}

-- Vị trí đỗ xe khi đăng bán (parking spots)
Config.ParkingSpots = {
    vec4(896.9, -73.3, 78.06, 56.93),
    vec4(900.6, -67.4, 78.06, 58.19),
    vec4(903.9, -61.5, 78.06, 57.41),
    vec4(907.3, -55.6, 78.06, 57.21),
    vec4(911.1, -49.8, 78.06, 57.99),
    vec4(914.7, -43.8, 78.06, 58.43),
    vec4(918.4, -38.0, 78.06, 58.81),

    vec4(887.5, -67.5, 78.06, 237.64),
    vec4(890.9, -61.5, 78.06, 238.35),
    vec4(894.9, -55.8, 78.06, 238.11),
    vec4(898.4, -50.0, 78.06, 238.62),
    vec4(902.4, -44.3, 78.06, 237.89),
    vec4(905.6, -38.2, 78.06, 238.49),
    vec4(909.3, -32.4, 78.06, 238.89),
}

-- Bán kính kiểm tra vị trí đỗ xe có trống không
Config.ParkingCheckRadius = 3.0

-- Discord Webhook cho log bán xe
Config.DiscordWebhook = ""

-- Cấu hình drawtext3d
Config.DrawText = {
    font = 0,
    scale = 0.35,
    outline = true
}

-- Hàm tiện ích kiểm tra xe có trong danh sách blacklist không
function Config.IsVehicleBlacklisted(modelName)
    if not modelName then return false end
    local model = string.lower(tostring(modelName))
    for _, blacklisted in ipairs(Config.BlacklistedVehicles) do
        if string.lower(tostring(blacklisted)) == model then
            return true
        end
    end
    return false
end
