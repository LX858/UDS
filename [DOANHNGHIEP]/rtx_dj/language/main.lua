Config = Config or {}
local openKey = Config.DjOpenKey or "E"

Language = {
    ["English"] = {
        ["pressfordj"] = "Nhấn [" .. openKey .. "] để mở menu DJ",
        ["pressfordjinteract"] = "Nhấn <span id='infobindcolor'>" .. openKey .. "</span> để mở menu DJ",
        ["pressfordjinteractclassic"] = "Nhấn ~INPUT_CONTEXT~ để mở menu DJ",
        ["djmenu"] = "MENU DJ",
        ["djperms"] = "Bạn không có quyền sử dụng menu DJ này.",
        ["djsusing"] = "Đã có người đang sử dụng menu DJ.",
        ["locationcreated"] = "Đã tạo vị trí DJ mới (%s)",
        ["locationedited"] = "Đã chỉnh sửa vị trí DJ (%s)",
        ["locationremoved"] = "Đã xóa vị trí DJ (%s)",
        ["streamerdeactivated"] = "Đã tắt chế độ Streamer",
        ["streamerdactivated"] = "Đã bật chế độ Streamer",
    },
}

setmetatable(Language, {
    __index = function(t, k)
        return rawget(t, "English") or {}
    end
})