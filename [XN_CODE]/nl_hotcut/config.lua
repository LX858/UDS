Config = {}

Config.Locale       				= 'en' -- Traduções disponives en / br

Config.EnableDiscordLogs			= true -- Bật/tắt gửi log Discord (true = bật, false = tắt)

Config.ServiceExtensionOnEscape		= 20

Config.ZoneRadius					= 180 --tù (meters)

Config.BuyoutPrice					= 2000 -- Giá chuộc 1 bãi ($)

Config.VisitFee						= 5000 -- Phí thăm tù ($)

Config.IsolationBucketStart		= 2000 -- Bucket bắt đầu cho cách ly (mỗi người 1 bucket riêng từ 2000-9999)

Config.ReputationPrisonActions		= 100 -- Số bãi khi bị tù do uy tín thấp

Config.ReputationRestoreAmount		= 70 -- Số điểm uy tín cộng lại sau khi ra tù

Config.NPCLocation					= vec4(1774.8732, 2553.4888, 45.5650, 90.8222) -- Tọa độ NPC chuộc tù (trong tù)

Config.NPCVisitLocation				= vec4(1852.9213, 2595.6458, 45.6720, 268.3121) -- Tọa độ NPC thăm/chuộc tù (ngoài tù)

Config.ServiceLocation 				= vec3(1771.8, 2552.22, 45.56)

Config.ReleaseLocation				= vec3(1852.61, 2605.02, 45.67) --vec3(414.77, -992.57, 29.4)

Config.ZoneMarkerLocation			= vec3(1663.1160, 2591.1965, 45.5648) -- Tọa độ tâm vùng tù

Config.RespawnLocation				= vec3(1771.8, 2552.22, 45.56) -- Tọa độ hồi sinh khi chết trong tù

Config.ServiceLocations = {
	{ stt = 's1', type = "cleaning", coords = vec3(1755.87, 2554.25, 45.56) },
	{ stt = 's2', type = "cleaning", coords = vec3(1756.46, 2541.85, 45.56) },
	{ stt = 's3', type = "cleaning", coords = vec3(1750.39, 2535.65, 45.56) },
	{ stt = 's4', type = "cleaning", coords = vec3(1743.42, 2541.73, 45.56) },
	{ stt = 's5', type = "cleaning", coords = vec3(1737.64, 2548.37, 45.56) },
	{ stt = 's6', type = "cleaning", coords = vec3(1731.13, 2556.68, 45.56) },
	{ stt = 's7', type = "cleaning", coords = vec3(1739.79, 2558.5, 45.56) }
}

Config.Uniforms ={
    ['male'] = {
        outfitData ={
            ['t-shirt'] = {item = 15, texture = 0}, -- done
            ['torso2'] = {item = 146, texture = 7},
			['arms'] = {item = 0, texture = 0}, -- done
			['pants'] = {item = 7, texture = 15}, -- done
			['shoes'] = {item = 5, texture = 0},
        }
    },
    ['female'] = {
        outfitData ={
            ['t-shirt'] = {item = 3, texture = 0},
			['torso2'] = {item = 141, texture = 3},
			['arms'] = {item = 2, texture = 0},
			['pants'] = {item = 0, texture = 0},
			['shoes'] = {item = 5, texture = 0},
        }
    },
}

-- ===== MUGSHOT CONFIG =====
Config.EnableMugshot = true -- Bật/tắt chụp ảnh khi vào tù (sử dụng kael-mugshot)

-- ===== OFFLINE PRISON LOCATIONS (PD Cells) =====
Config.OfflinePrisonLocations = {
    vec4(13.2966, -413.4630, 33.5623, 51.2431),
    vec4(14.4854, -408.0513, 33.5622, 346.2467),
    vec4(17.0280, -402.2281, 33.5622, 244.9452),
    vec4(25.3347, -399.3193, 33.5622, 174.1168),
    vec4(31.0561, -400.8424, 33.5621, 141.9453)
}

