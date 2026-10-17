return {
    discordWebhook = nil, -- Replace nil with your webhook if you chose to use discord logging over ox_lib logging
    minOnDutyLogTimeMinutes = 30,
    formatDateTime = '%m-%d-%Y %H:%M',

    -- Discord webhooks cho từng job (báo cáo tổng kết)
    jobWebhooks = {
        police = "https://discord.com/api/webhooks/1548350756745117857/H-tHbpYK_-6AituA_NeWl7QC8tGxezZQIfSlhge4yxgMc6_rOjRaBDq29xmm9XB1Uc_O", -- Thay nil bằng webhook Discord của Police
        ambulance = "https://discord.com/api/webhooks/1548347432767594526/kioJj3lfQGWWWzaz7PYn_Y_vlKAdOvv6qvhuFk2AZwvYv_N4Cf0laH4goB8UgeClUiJJ", -- Thay nil bằng webhook Discord của Ambulance
    },

    -- Webhook cho Nghỉ việc và Đình chỉ (dùng chung cho cả 2 trường hợp)
    cooldownWebhook = "https://discord.com/api/webhooks/1548336090069467146/8YLm7_907ON3XQ8Bi1IYTW601O5-d2NkkTnA55StxkoQeEC7sshWzRSG3obNCTpYWRg4",

    -- Webhook log khi Admin gỡ / hủy Countdown
    removeCooldownWebhook = "https://discord.com/api/webhooks/1548352142753136680/aBiAe1c55lEcvrkAYevBgp-i_KktfFK3hcLrYjOM4PUBfSw0I8K7szPbunDV3EjAc5U3",

    -- Webhook log Định danh (Nâng/Hạ cấp định danh và Thu hồi ID Card)
    identityWebhook = "https://discord.com/api/webhooks/1556684696744632332/iNE4hX2Tt7PQkqxGqlTb6bmbkWwUp7K1nvc0iKFCj935WoiIfSmbZQTZLItvb19VJ2bh",
    identityWebhook2 = "https://discord.com/api/webhooks/1556680766744694905/GXnFGuawS8A-YQSHN9ObK0K4Qhy-bRIKdbVP2AzFcGODnrAR4QgUfG7fVcJV3O5v1DDf", -- Webhook thứ 2 cho log Định danh (thay URL vào đây nếu muốn gửi về 2 kênh Discord)

    -- Webhook log Cấp giấy phép vũ khí (giay_phep_sung)
    weaponLicenseWebhook = "https://discord.com/api/webhooks/1556691014633267200/ZcDkGDki7IyRDeUCFRchEAWO-QlXF3uGsBjm-pY6SANumc5WDR9XtQOtptzX8AhHy4sC", -- Thay Webhook Discord cho Cấp giấy phép vũ khí ở đây


    -- Các job áp dụng cooldown khi bị sa thải/đình chỉ
    cooldownJobs = {
        police = true,
        ambulance = true,
    },

    -- Thời gian cooldown tính bằng ngày
    cooldownDurations = {
        resignation = 3, -- Nghỉ việc (thông thường): 3 ngày
        blacklist = 15,  -- Đình chỉ (Blacklist): 15 ngày
    },


    -- While the config boss menu creation still works, it is recommended to use the runtime export instead.
    ---@alias GroupName string
    ---@type table<GroupName, ZoneInfo | ZoneInfo[]> | ZoneInfo[]
    menus = {
        -- Có thể config 1 điểm hoặc nhiều điểm cho cùng 1 job:
        -- Cách 1: Danh sách nhiều vị trí bên trong 1 job
        police = {
            {
                coords = vec3(93.36, -397.09, 47.31), -- Vị trí 1
                size = vec3(1.5, 1.5, 1.5),
                rotation = 39.68,
                type = 'job',
            },
            {
                coords = vec3(2515.9690, -319.2136, 93.1120), -- Vị trí 2
                size = vec3(1.5, 1.5, 1.5),
                rotation = 39.68,
                type = 'job',
            },
        },
        ambulance = {
            coords = vec3(337.31048583984,-1416.7091064453,32.305950164795), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },
        mechanic = {
            coords = vec3(-339.43756103516,-156.96691894531,44.486366271973), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },

        quanan = {
            coords = vec3(334.8875, -1660.3898, 32.7588), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },

        quannuoc = {
            coords = vec3(217.0235, -961.0499, 32.1635), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },

        doxe = {
            coords = vec3(157.88, -1108.84, 34.21), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },

        toathichinh = {
            coords = vec3(-527.2834, -590.2373, 34.6819), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },

        cardealer = {
            coords = vec3(-802.2745, -202.4032, 44.1874), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },

        luxurycar = {
            coords = vec3(746.2684, -942.2781, 33.9455), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },


        bar = {
            coords = vec3(363.8821, -299.7240, 49.6942), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },

        hocvien = {
            coords = vec3(2511.75, -423.04, 106.91), --vec4(339.0, -582.43, 47.28, 251.09)
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },
        taxi = {
            coords = vec3(358.14, -1591.57, 29.29),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'job',
        },
        lostmc = {
            coords = vec3(983.69, -90.92, 74.85),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
        },
        vagos = {
            coords = vec3(351.18, -2054.92, 22.09),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
        },
    },
}