PermissionMap = {
    ['group.admin'] = {
        Permissions.OPEN_CONTROL,
        Permissions.EDIT_PAGE,
        Permissions.CREATE_PAGE,
        Permissions.DELETE_PAGE,
        Permissions.CREATE_CATEGORY,
        Permissions.EDIT_CATEGORY,
        Permissions.DELETE_CATEGORY,
        Permissions.CREATE_POINT,
        Permissions.EDIT_POINT,
        Permissions.DELETE_POINT,
        Permissions.SEND_HELP,
        Permissions.TELEPORT,
    },
    ['builtin.everyone'] = { --Everyone
        Permissions.OPEN_PAGE,
        Permissions.NAVIGATE,
    }
}

-- Cấu hình cấp quyền chỉnh sửa Guidebook cho người chơi cụ thể (Steam, License, Discord...)
AdminPlayers = {
    -- 'license:1234567890abcdef...',
    -- 'steam:1100001...',
}

-- Cấu hình cấp quyền chỉnh sửa Guidebook cho các Job có cấp bậc (grade) từ mức này trở lên
-- Ví dụ: ['police'] = 3 tức là Job 'police' có grade >= 3 thì có quyền sửa
AdminJobs = {
    ['toathichinh'] = 4,
}
