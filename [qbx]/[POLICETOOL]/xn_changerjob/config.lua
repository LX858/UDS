-- Cấu hình cho XN Job Changer
Config = {}

-- Vị trí target zone
Config.TargetLocation = vec3(629.2, -6.24, 82.78)
Config.TargetRadius = 2.0

-- Citizen ID được phép sử dụng (có thể thêm nhiều citizenid)
Config.AllowedCitizenIds = {
    "G601AI68",
    "LJX7AY25", -- Thêm citizenid khác ở đây
    -- "XYZ67890", -- Ví dụ thêm citizenid
    -- "DEF11111", -- Có thể thêm bao nhiêu cũng được
}

-- Function để kiểm tra citizenid có được phép không
function Config.IsAllowedCitizen(citizenId)
    for _, allowedId in pairs(Config.AllowedCitizenIds) do
        if citizenId == allowedId then
            return true
        end
    end
    return false
end

-- Function để thêm citizenid mới (runtime)
function Config.AddAllowedCitizen(citizenId)
    if not Config.IsAllowedCitizen(citizenId) then
        table.insert(Config.AllowedCitizenIds, citizenId)
        return true
    end
    return false
end

-- Function để xóa citizenid (runtime)
function Config.RemoveAllowedCitizen(citizenId)
    for i, allowedId in pairs(Config.AllowedCitizenIds) do
        if allowedId == citizenId then
            table.remove(Config.AllowedCitizenIds, i)
            return true
        end
    end
    return false
end

-- Job configurations for QBCore
Config.Jobs = {
    police = {
        name = "police",
        grade = 13,
        label = "Police",
        switchTo = {
            name = "hocvien",
            grade = 4,
            label = "Học viên"
        }
    },
    hocvien = {
        name = "hocvien", 
        grade = 4,
        label = "Học viên",
        switchTo = {
            name = "police",
            grade = 13,
            label = "Police"
        }
    }
}

-- Logging configuration
Config.EnableDatabaseLogging = false -- Set to true để bật database logging
Config.EnableConsoleLogging = true   -- Console logging

-- UI Configuration
Config.Notifications = {
    success = {
        title = "Thành công",
        type = "success"
    },
    error = {
        title = "Lỗi", 
        type = "error"
    },
    warning = {
        title = "Thông báo",
        type = "warning"
    }
}

Config.ContextMenu = {
    title = "Thay đổi công việc",
    icon = "fas fa-exchange-alt",
    label = "Thay đổi công việc"
}
