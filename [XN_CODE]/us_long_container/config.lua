Config = {}

Config.Debug = false

-- Khoảng cách hiện target và khoảng cách server cho phép tương tác.
Config.TargetDistance = 3.0
Config.FrontInteractionDistance = 3.25
Config.ServerValidationDistance = 4.0

-- Thời gian mở/đóng cửa, tính bằng mili giây.
Config.AnimationDuration = 1800
Config.InteractionCooldown = 750

-- Thanh khóa chắn giữa hai cửa trước khi mở.
Config.Lock = {
    model = 'tr_prop_tr_lock_01a',
    position = vec3(0.0, -3.38, 1.20),
    rotation = vec3(0.0, 0.0, 0.0),
    collision = true,
    invincible = true
}

-- Animation mở container.
Config.OpenAnimation = {
    enabled = true,
    duration = 3150,
    doorDelay = 2400,
    doorAnimDuration = 3000,
    animation = {
        dict = 'anim@scripted@freemode@ig1_open_container@heeled@',
        pedClip = 'action'
    }
}

-- Yêu cầu item để mở container.
Config.RequireItem = {
    enabled = true,
    itemName = 'keysiver',
    removeOnUse = true
}

-- QUAN TRỌNG:
-- Không dùng prop_container_01mb/prop_container_01a vì phần cửa trước nằm liền trong thân.
-- prop_container_03mb là thân container rỗng dùng cùng bộ cửa rời door_mb_l/door_mb_r.
-- prop_container_03_ld và prop_container_04mb cũng dùng chung hệ offset bên dưới.
Config.Models = {
    body = 'prop_container_04a',
    leftDoor = 'prop_cntrdoor_ld_l',
    rightDoor = 'prop_cntrdoor_ld_r'
}

-- Danh sách dùng để cảnh báo khi cấu hình nhầm thân có cửa liền khối.
Config.InvalidBodyModels = {
    prop_container_01a = true,
    prop_container_01b = true,
    prop_container_01c = true,
    prop_container_01d = true,
    prop_container_01e = true,
    prop_container_01f = true,
    prop_container_01g = true,
    prop_container_01h = true,
    prop_container_01mb = true
}

Config.Door = {
    -- Offset là vị trí PIVOT/bản lề của model cửa rời, không phải tâm cánh cửa.
    -- Mặt target/mở cửa nằm ở đầu local Y âm của thân container.
    left = {
        modelSide = 'left',
        position = vec3(-1.2979125976562, -3.3908691406250, 1.4021835327148),
        closedRotation = vec3(0.0, 0.0, 0.0),
        openRotation = vec3(0.0, 0.0, -112.0)
    },
    right = {
        modelSide = 'right',
        position = vec3(1.2979125976562, -3.3908691406250, 1.4021835327148),
        closedRotation = vec3(0.0, 0.0, 0.0),
        openRotation = vec3(0.0, 0.0, 112.0)
    },

    -- prop_container_03mb hở hai đầu. Cặp cửa sau được gắn cố định,
    -- vì vậy người chơi chỉ thao tác được một đầu phía trước.
    rear = {
        enabled = true,
        left = {
            modelSide = 'left',
            position = vec3(1.2979125976562, 3.3908691406250, 1.4021835327148),
            rotation = vec3(0.0, 0.0, 180.0)
        },
        right = {
            modelSide = 'right',
            position = vec3(-1.2979125976562, 3.3908691406250, 1.4021835327148),
            rotation = vec3(0.0, 0.0, 180.0)
        }
    },

    collision = true,
    invincible = true,
    lodDistance = 500
}

Config.Target = {
    openLabel = 'Mở cửa container',
    closeLabel = 'Đóng cửa container',
    openIcon = 'fa-solid fa-box-open',
    closeIcon = 'fa-solid fa-box'
}

-- Có thể khai báo nhiều container.
-- id phải duy nhất và chỉ nên dùng chữ, số, dấu gạch dưới.
Config.Containers = {
    {
        id = 'understar_container_01',
        coords = vec4(932.9295, -3183.3862, 5.9008, 359.3321),

        -- true: tự căn đáy thân container xuống mặt đất.
        placeOnGround = true,

        -- Trạng thái mặc định sau khi resource/server khởi động lại.
        initiallyOpen = false,

        -- Texture variation của thân và cửa. Để nil nếu không muốn ép variation.
        textureVariation = 0
    },
    {
        id = 'understar_container_02',
        coords = vec4(936.9295, -3183.3862, 5.9008, 359.3321),
        placeOnGround = true,
        initiallyOpen = false,
        textureVariation = 0
    }, 
    {
        id = 'understar_container_03',
        coords = vec4(941.0295, -3183.3862, 5.9008, 359.3321),
        placeOnGround = true,
        initiallyOpen = false,
        textureVariation = 0
    },
    {
        id = 'understar_container_04',
        coords = vec4(929.0295, -3183.3862, 5.9008, 359.3321),
        placeOnGround = true,
        initiallyOpen = false,
        textureVariation = 0
    },
    {
        id = 'understar_container_05',
        coords = vec4(925.0295, -3183.3862, 5.9008, 359.3321),
        placeOnGround = true,
        initiallyOpen = false,
        textureVariation = 0
    },
    -- {
    --     id = 'understar_container_06',
    --     coords = vec4(920.9295, -3183.3862, 5.9008, 359.3321),
    --     placeOnGround = true,
    --     initiallyOpen = false,
    --     textureVariation = 0
    -- },

    -- {
    --     id = 'understar_container_07',
    --     coords = vec4(916.9295, -3183.3862, 5.9008, 359.3321),
    --     placeOnGround = true,
    --     initiallyOpen = false,
    --     textureVariation = 0
    -- },

    -- {
    --     id = 'understar_container_08',
    --     coords = vec4(944.9295, -3183.3862, 5.9008, 359.3321),
    --     placeOnGround = true,
    --     initiallyOpen = false,
    --     textureVariation = 0
    -- },

    -- {
    --     id = 'understar_container_09',
    --     coords = vec4(949.2295, -3183.3862, 5.9008, 359.3321),
    --     placeOnGround = true,
    --     initiallyOpen = false,
    --     textureVariation = 0
    -- },

    -- {
    --     id = 'understar_container_10',
    --     coords = vec4(953.2295, -3183.3862, 5.9008, 359.3321),
    --     placeOnGround = true,
    --     initiallyOpen = false,
    --     textureVariation = 0
    -- },
}
