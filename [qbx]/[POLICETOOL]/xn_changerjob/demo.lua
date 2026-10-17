-- Demo script để test job changer với QBCore
-- Chạy các commands này trong F8 console để test

-- 1. Set job thành police grade 13
-- /setjob [player_id] police 13

-- 2. Teleport đến vị trí target
-- /tp 629.2 -6.24 82.78

-- 3. Kiểm tra job hiện tại
-- /checkjob

-- 4. Test thay đổi job tại target location

-- Commands quản lý citizenid (Admin only):
-- /jobchanger_add [citizenid]     - Thêm citizenid vào danh sách cho phép
-- /jobchanger_remove [citizenid]  - Xóa citizenid khỏi danh sách cho phép  
-- /jobchanger_list                - Xem danh sách citizenid được phép

-- Để thêm citizenid trong config, chỉnh sửa config.lua:
-- Config.AllowedCitizenIds = {
--     "G601AI68",
--     "ABC12345", -- Thêm citizenid mới ở đây
--     "XYZ67890",
-- }

-- Commands hữu ích cho testing QBCore:
-- /setjob [id] police 13    - Set job police grade 13
-- /setjob [id] hocvien 4    - Set job hocvien grade 4
-- /tp 629.2 -6.24 82.78     - Teleport to target location
-- /checkjob                 - Check current job (requires admin)
-- /showme                   - Show player data including citizenid

print("QBCore Demo script loaded. Multiple citizenid support enabled!")
