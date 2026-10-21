return {
    requireMission = false, -- false: Đào tự do tại các mộ không cần nhận nhiệm vụ từ NPC | true: Cần nhận nhiệm vụ từ NPC
    graveCooldown = 60,    -- Thời gian hồi (giây) của mỗi ngôi mộ sau khi đào xong (đặt 0 để không hồi chiêu)
    drawMarker = false,    -- false: Tắt marker 3D chỉ dùng TextUI [E] | true: Hiển thị cả Marker 3D
    requireShovel = false, -- false: Không cần có xẻng (shovel) vẫn có thể đào | true: Bắt buộc phải có xẻng
    shovelItem = 'shovel', -- Tên item xẻng yêu cầu trong ox_inventory (nếu requireShovel = true)
    textUI = {
        message = '[E] - Đào mộ',
        icon = 'shovel',
        position = 'right-center'
    },
    model = "cs_dreyfuss",
    coords = vec4(-1803.62, -122.96, 78.31, 145.99),
    coordsGraves = {
        vec4(-1766.9904, -220.7254, 53.8284, 328.0725),
        vec4(-1769.0909, -218.7238, 53.7416, 307.4222),
        vec4(-1780.7548, -204.2195, 54.3246, 306.3606),
        vec4(-1769.2599, -240.3451, 52.0222, 318.0479),
        vec4(-1758.2395, -247.9771, 51.9260, 322.7679),
        vec4(-1750.2808, -253.4654, 51.5391, 320.3990),
        vec4(-1756.1593, -284.2592, 47.5432, 277.0306),
        vec4(-1746.6923, -299.0365, 47.8490, 284.9381),
        vec4(-1739.5959, -298.1839, 48.4679, 283.4255),
        vec4(-1730.0541, -286.6544, 49.7994, 285.2122),
        vec4(-1742.1654, -224.3198, 55.5093, 354.3604),
        vec4(-1748.9094, -222.4026, 55.0931, 350.5686),
        vec4(-1758.6755, -209.0414, 56.2343, 318.2654),
        vec4(-1756.0776, -203.4677, 56.8418, 327.3083),
        vec4(-1758.4476, -201.3798, 56.6934, 307.4838),
        vec4(-1714.8318, -233.4123, 55.4547, 353.8817),
        vec4(-1664.2668, -170.3118, 57.5948, 280.2256),
        vec4(-1665.6084, -167.8086, 57.5548, 306.6451),
        vec4(-1683.8394, -143.8730, 59.1914, 284.2873),
        vec4(-1685.6492, -137.7758, 59.5776, 14.6177),
        vec4(-1663.1508, -138.2872, 59.3466, 284.5846),
        vec4(-1661.2644, -141.7264, 58.8857, 294.1185),
        vec4(-1646.5963, -125.7017, 59.3091, 358.5349),
        vec4(-1657.4768, -125.4353, 60.1591, 358.5527),
        vec4(-1677.5009, -125.2823, 60.4113, 357.8910),
        vec4(-1642.8472, -152.5066, 57.7598, 129.5743),
        vec4(-1623.4630, -179.2958, 55.8270, 42.0271),
        vec4(-1640.3756, -181.9614, 55.9123, 37.4083),
        vec4(-1639.6543, -170.4198, 56.7989, 31.7886),
        vec4(-1625.0994, -196.3056, 55.2611, 14.1739),
        vec4(-1635.9813, -132.9809, 58.3769, 294.6851),
        vec4(-1626.8030, -148.1761, 57.2760, 300.2372),
        vec4(-1794.6562, -231.7427, 49.2561, 276.9645),
        vec4(-1793.4790, -236.1415, 49.1377, 284.7602),
        vec4(-1783.7505, -256.3832, 47.4520, 321.5656),
        vec4(-1781.6324, -257.8318, 47.5638, 325.7621),
        vec4(-1803.0973, -264.1018, 44.0825, 143.7556),
        vec4(-1756.2719, -284.0635, 47.5166, 288.2132),
        vec4(-1746.7605, -298.9431, 47.8527, 283.4256),
        vec4(-1739.6647, -298.2470, 48.4679, 272.0558),
        vec4(-1740.4556, -288.2519, 49.1161, 276.3102),
        vec4(-1748.3982, -277.4973, 48.9394, 279.8165),
        vec4(-1730.5211, -286.8187, 49.8105, 281.8185),
        vec4(-1732.3807, -275.1852, 50.8531, 281.3364)
    },
    robZone = vec3(-1724.84, -192.47, 58.09),
    policeCallChance = 0.40,
    policeCallNightChance = 0.20,
    fingerprintChance = 100,
    zombie = {
        chance = 40, -- Tỷ lệ % xuất hiện zombie khi đào mộ (Ví dụ: 40 = 40% ra zombie, 60% không ra)
        count = { min = 1, max = 2 }, -- Số lượng zombie xuất hiện mỗi lần đào (số cố định hoặc khoảng min, max)
        models = {
            "u_m_y_zombie_01", -- Model zombie mặc định trong GTA V
        },
        health = 100, -- Lượng máu của zombie (100 máu thực tế)
        deleteOnDeath = true, -- Tự động xóa xác zombie khi chết
        deleteDelay = 3000,   -- Thời gian chờ trước khi xóa xác (mili giây, 3000 = 3 giây sau khi chết để hoàn tất ngã xuống rồi biến mất, 0 = xóa ngay lập tức)
        poison = {
            chance = 70, -- Tỷ lệ % bị nhiễm độc khi bị zombie đánh trúng (0-100%)
            duration = 3000, -- Thời gian bị nhiễm độc mỗi lần (mili giây, 3000 = 3 giây)
            percentDamage = 30, -- Tổng % máu bị mất trong suốt 3 giây (30 = mất 30% HP trên thanh máu max 200)
            interval = 1000, -- Chu kỳ rút máu (mili giây, 1000 = 1 giây rút 1 lần, 3 giây = 3 lần rút)
            screenEffect = true, -- Bật hiệu ứng hình ảnh trúng độc
        }
    },
    minCops = 0,
    tokenReward = {
        item = 'event_token', -- Tên item nhận được
        chance = 50,          -- Tỷ lệ % đào trúng item (50 = 50% ra event_token, 50% không nhận được gì)
        amount = 1,           -- Số lượng nhận được mỗi lần đào trúng (có thể đặt số cố định 1 hoặc table { min = 1, max = 2 })
        emptyNotify = true,   -- Hiển thị thông báo khi không tìm thấy gì
    },
    enableShop = false, -- Đặt false để tắt hoàn toàn shop bán đồ (ilegalItems)
    modelShop = "a_m_y_acult_02",
    coordsShop = vec4(-1146.54, 4940.94, 221.27, 156.55),
    ilegalItems = {

        ['flowers'] = { 
            price = 75 
        },

        ['humanbone'] = {
            price = 400
        },

        ['humanbones'] = {
            price = 875
        },

        ['humanskull'] = {
            price = 950
        },

        ['humantooth'] = {
            price = 350
        },

        ['voodoodoll'] = {
            price = 200
        },

        ['pearlnecklace'] = {
            price = 1000
        },
    }
}
