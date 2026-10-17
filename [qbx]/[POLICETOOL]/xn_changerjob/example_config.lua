-- VÍ DỤ CẤU HÌNH NHIỀU CITIZENID
-- Copy nội dung này vào config.lua để sử dụng nhiều citizenid

Config.AllowedCitizenIds = {
    "G601AI68",     -- Citizenid đầu tiên (mặc định)
    "ABC12345",     -- Ví dụ citizenid thứ 2  
    "XYZ67890",     -- Ví dụ citizenid thứ 3
    "DEF11111",     -- Ví dụ citizenid thứ 4
    "GHI22222",     -- Ví dụ citizenid thứ 5
    -- Có thể thêm bao nhiêu citizenid cũng được
    -- Chỉ cần thêm dòng mới với format: "CITIZENID",
}

-- CÁCH THÊM CITIZENID MỚI:
-- 1. Cách thủ công: 
--    - Thêm dòng mới vào Config.AllowedCitizenIds
--    - Restart resource: /restart xn_changerjob
--
-- 2. Cách runtime (không cần restart):
--    - Dùng command: /jobchanger_add ABC12345
--    - Citizenid sẽ được thêm ngay lập tức
--
-- 3. Xem danh sách hiện tại:
--    - Dùng command: /jobchanger_list
--
-- 4. Xóa citizenid:
--    - Dùng command: /jobchanger_remove ABC12345

-- LƯU Ý:
-- - Tất cả commands trên chỉ admin mới sử dụng được
-- - Citizenid được thêm bằng command sẽ mất khi restart server
-- - Để lưu vĩnh viễn, cần thêm vào config.lua

print("Example config loaded. Check config.lua to modify allowed citizenids.")
