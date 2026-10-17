-- Vui lòng đọc tài liệu của chúng tôi tại https://docs.londonstudios.net

main = {
    frameRotation = 115,
    burstTyre = true,
    burstTyreLevel = 700,
    rope = {
        defaultLength = 10.0,
        maxLength = 12.0,
        type = 2,
    },
    forceHandbrake = {
        enabled = true,
        timeToForceHandbrake = 2,
        maxSpeedAfterHandbrake = 40 -- TÍNH THEO DẶM/GIỜ
    },
    radiusToAttachToVehicle = 2 -- Tăng giá trị này nếu gặp vấn đề khi kết nối với bánh sau
}

-- Đây là phần cấu hình cho các phương tiện mà grappler có thể được cài đặt và triển khai
-- Tên là mô tả của phương tiện và chủ yếu được sử dụng cho mục đích ghi log
vehicles = {
    [`police4`] = { -- Đây là những ví dụ, vui lòng chỉnh sửa và thêm phương tiện của riêng bạn
        name = "Response Car",
        boneName = "engine",
        offSet = {0.0, 0.76, -0.4},
        rotation = {0.0, 0.0, 0.0},
    },

    [`nkbuffalo4`] = { -- Đây là những ví dụ, vui lòng chỉnh sửa và thêm phương tiện của riêng bạn
        name = "Buffalo4",
        boneName = "engine",
        offSet = {0.0, 0.90, -0.4},
        rotation = {0.0, 0.0, 0.0},
    },

    [`nkdoradoac`] = { -- Đây là những ví dụ, vui lòng chỉnh sửa và thêm phương tiện của riêng bạn
        name = "SUV Scout",
        boneName = "engine",
        offSet = {0.0, 0.86, -0.4},
        rotation = {0.0, 0.0, 0.0},
    },

    [`nkgtx`] = { -- Đây là những ví dụ, vui lòng chỉnh sửa và thêm phương tiện của riêng bạn
        name = "Dominator",
        boneName = "engine",
        offSet = {0.0, 0.96, -0.4},
        rotation = {0.0, 0.0, 0.0},
    },

    [`nkvigero2`] = { -- Đây là những ví dụ, vui lòng chỉnh sửa và thêm phương tiện của riêng bạn
        name = "Vigero2",
        boneName = "engine",
        offSet = {0.0, 0.86, -0.4},
        rotation = {0.0, 0.0, 0.0},
    },

    [`nkfugitive`] = { -- Đây là những ví dụ, vui lòng chỉnh sửa và thêm phương tiện của riêng bạn
        name = "Vstr",
        boneName = "engine",
        offSet = {0.0, 0.76, -0.4},
        rotation = {0.0, 0.0, 0.0},
    },

    [`polcaracara`] = { -- Đây là những ví dụ, vui lòng chỉnh sửa và thêm phương tiện của riêng bạn
        name = "Caracara",
        boneName = "engine",
        offSet = {0.0, 0.78, -0.55},
        rotation = {0.0, 0.0, 0.0},
    },

    [`valor12bb`] = {
        name = "Police Van",
        boneName = "engine",
        offSet = {0.0, 0.78, -0.55},
        rotation = {0.0, 0.0, 0.0},
    },
}

-- Đây là phần cấu hình cho lệnh /grappler
-- Sử dụng: /grappler install, /grappler deploy, /grappler remove và /grappler remove
grapplerCommand = {
    enabled = true,
    commandName = "moc",
    install = "gan",
    deploy = "thao",
    remove = "xoa",
    reset = "reset",

    acePermissions = {
        enabled = false,
        -- Điều này cho phép ace permissions trên lệnh grappler
    },
    -- Chúng tôi đã thêm tích hợp ESX. Tất cả những gì bạn cần làm là kích hoạt nó bên dưới và cấu hình nghề nghiệp nào có thể sử dụng lệnh
    ESX = {
        enabled = false,
        checkJob = {
            enabled = false, -- Kích hoạt để sử dụng kiểm tra nghề nghiệp ESX
            jobs = {"fire", "firefighter"} -- Người dùng có thể có bất kỳ nghề nghiệp nào sau đây, cho phép bạn thêm nhiều nghề
        }
    },
    -- Chúng tôi đã thêm tích hợp vRP. Tất cả những gì bạn cần làm là kích hoạt nó bên dưới. Sau đó, cấu hình nếu bạn muốn kiểm tra nhóm hoặc quyền, hoặc thậm chí cả hai
    vRP = {
        enabled = false,
        checkGroup = {
            enabled = false, -- Kích hoạt để sử dụng kiểm tra nhóm vRP
            groups = {"fire", "admin"}, -- Người dùng có thể có bất kỳ nhóm nào sau đây, nghĩa là bạn có thể thêm các nghề nghiệp khác nhau
        },
        checkPermission = {
            enabled = false, -- Kích hoạt để sử dụng kiểm tra quyền vRP
            permissions = {"player.kick"} -- Người dùng có thể có bất kỳ quyền nào sau đây, cho phép bạn thêm nhiều quyền
        },
    },
    -- Chúng tôi đã thêm tích hợp QBCore. Tất cả những gì bạn cần làm là kích hoạt nó bên dưới. Sau đó, cấu hình nếu bạn muốn kiểm tra nghề nghiệp hoặc quyền, hoặc thậm chí cả hai
    QBCore = {
        enabled = true,
        checkJob = {
            enabled = true, -- Kích hoạt để sử dụng kiểm tra nghề nghiệp QBCore
            jobs = {"police"}, -- Người dùng có thể có bất kỳ nghề nghiệp nào sau đây, nghĩa là bạn có thể thêm các nghề nghiệp khác nhau
        },
        checkPermission = {
            enabled = false, -- Kích hoạt để sử dụng kiểm tra quyền QBCore
            permissions = {"god", "admin"}, -- Người dùng có thể có bất kỳ quyền nào sau đây, cho phép bạn thêm nhiều quyền
        },
    },
}

-- https://docs.fivem.net/docs/game-references/controls/
deployGrapplerKey = {0, 246} -- Mặc định được đặt là phím Y
-- Số đầu tiên là nhóm điều khiển và số thứ hai là điều khiển

grapplerSound = { -- https://pastebin.com/DCeRiaLJ
    enabled = true,
    soundName = "Activate_Trap",
    soundDict = "DLC_AW_Trap_Controller_Sounds",
}

-- Điều này cho phép bạn kích hoạt ghi log Discord cho grappler
-- Bạn phải thêm webhook của mình trong sv_utils.lua
logging = {
    enabled = false,
    displayName = "Grappler",
    colour = 31487,
    title = "**New Log**",
    icon = "https://i.imgur.com/n3n7JNW.png",
    footerIcon = "https://i.imgur.com/n3n7JNW.png",
    dateFormat = "%d-%m-%Y %H:%M:%S", -- Ngày-Tháng-Năm Giờ-Phút-Giây
}

-- Phần này cho phép bạn dịch tài nguyên sang ngôn ngữ khác
translations = {
    noPermission = "~r~Lỗi~w~: Bạn không có quyền truy cập lệnh này.",
    invalidGrapplerArguments = "~r~Lỗi~w~: Tham số lệnh không hợp lệ.",
    inVehicle = "~r~Lỗi~w~: Bạn không được ở trong xe.",
    noVehicleFound = "~r~Lỗi~w~: Không tìm thấy phương tiện.",
    vehicleNotAllowed = "~r~Lỗi~w~: Phương tiện này không hỗ trợ móc cản.",
    cannotPerformAction = "~r~Lỗi~w~: Bạn không thể thực hiện hành động đó.",
    drivingVehicle = "~r~Lỗi~w~: Bạn phải đang lái xe để triển khai.",
    installedGrappler = "Đã Cài Đặt Móc Cản",
    deployedGrappler = "Đã Triển Khai Móc Cản",
    removedGrappler = "Đã Gỡ Bỏ Móc Cản",
    usedGrappler = "Đã Sử Dụng Móc Cản Trên Xe",
    vehicle = "Phương tiện: ",
    grapplerCommandHelp = "Cài đặt và triển khai móc cản cảnh sát",
    grapplerCommandParameterOne = "Hành động",
    grapplerCommandParameterOneHelp = "gan/thao/reset/xoa",
    installed = "~g~Thành công~w~: Đã cài đặt móc cản.",
    removed = "~g~Thành công~w~: Đã gỡ bỏ móc cản.",
    deployed = "~g~Thành công~w~: Đã triển khai móc cản.",
    reset = "~g~Thành công~w~: Đã khởi tạo lại móc cản.",
}

animation = {
    enabled = true,
    dict = "mini@repair",
    name = "fixing_a_ped"
}

-- Phần này cho phép bạn cấu hình các bone bánh xe của phương tiện mà grappler sẽ triển khai lên
wheelBones = {
    ["wheel_lr"] = {
        offSet = {0.0, 0.0, 0.0},
        rotation = {0.0, 0.0, 0.0},
    },
    ["wheel_rr"] = {
        offSet = {0.0, 0.0, 0.0},
        rotation = {0.0, 0.0, 0.0},
    },
}

-- Đây là các prop được sử dụng bởi resource.
-- Chúng tôi không khuyến nghị chỉnh sửa phần này
props = {
    bumperClosed = `bv_bumper_closed`,
    bumperReady = `bv_bumper_a`,
    bumperDeployed = `bv_bumper_b`,
    frameReady = `bv_frame_a`,
    frameDeployed = `bv_frame_b`,
    wheelBlock = `bv_wheelblock`,
}