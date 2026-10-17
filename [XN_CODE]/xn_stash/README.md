# XN_STASH - Hệ Thống Kho Đồ (Simplified)

## Mô tả
Resource tạo hệ thống kho đồ đơn giản cho các công việc sử dụng ox_target và ox_inventory trong QBX Core.

## Tính năng
- ✅ Kho đồ riêng biệt cho từng công việc
- ✅ Kho đồ cá nhân theo citizenid
- ✅ Kiểm tra quyền truy cập theo job và grade (client + server validation)
- ✅ **Yêu cầu item cụ thể để mở kho (chìa khóa, thẻ từ, v.v.)**
- ✅ Sử dụng ox_target để tương tác
- ✅ Tích hợp với ox_inventory
- ✅ Thông báo bằng ox_lib
- ✅ Cấu hình dễ dàng
- ✅ Bảo mật cao với double validation
- ✅ Đơn giản và ổn định

## Dependencies
- qbx_core
- ox_lib
- ox_inventory
- ox_target

## Cài đặt

1. Sao chép folder `xn_stash` vào thư mục `resources`
2. Thêm vào `server.cfg`:
```
ensure xn_stash
```

## Cấu hình

### Thêm kho đồ công việc
Mở file `config.lua` và thêm vào `Config.Stashes`:

```lua
ten_cong_viec = {
    coords = vec3(x, y, z), -- Tọa độ đặt target
    label = "Tên Hiển Thị Kho Đồ",
    job = "ten_job", -- Tên job trong database
    stashId = "job_stash", -- ID duy nhất cho stash
    slots = 50, -- Số slot
    weight = 100000, -- Trọng lượng tối đa (gram)
    icon = "fas fa-icon", -- Icon FontAwesome
    groups = {
        ten_job = 0 -- Grade tối thiểu (nil = không yêu cầu job)
    },
    requiredItem = "item_name" -- (Optional) Item cần có để mở kho
}
```

### Thêm kho đồ cá nhân
Mở file `config.lua` và thêm vào `Config.PersonalStashes`:

```lua
personal_stash = {
    coords = vec3(x, y, z),
    label = "Tên Hiển Thị",
    stashType = "personal", -- Cố định
    stashId = "personal_id", -- ID duy nhất
    slots = 20,
    weight = 50000,
    icon = "fas fa-home",
    groups = {
        police = 1 -- (Optional) Yêu cầu job và grade
    },
    requiredItem = "safe_key" -- (Optional) Item cần có
}
```

### Ví dụ: Két sắt yêu cầu chìa khóa

```lua
-- Trong Config.Stashes
secure_vault = {
    coords = vec3(1274.0, -1710.0, 54.77),
    label = "Két Sắt An Toàn",
    job = nil, -- Không yêu cầu job cụ thể
    stashId = "secure_vault",
    slots = 20,
    weight = 150000,
    icon = "fas fa-lock",
    groups = nil, -- Ai cũng có thể mở nếu có chìa
    requiredItem = "vault_key" -- Phải có item này
}
```

### Ví dụ: Kho police với thẻ từ + grade

```lua
police_armory = {
    coords = vec3(451.51, -992.42, 30.69),
    label = "Kho Vũ Khí Cảnh Sát",
    job = "police",
    stashId = "police_armory",
    slots = 30,
    weight = 200000,
    icon = "fas fa-gun",
    groups = {
        police = 3 -- Phải là police grade 3+
    },
    requiredItem = "police_keycard" -- VÀ phải có thẻ từ
}
```

**Lưu ý:**
- `requiredItem`: Người chơi PHẢI có item này trong inventory mới thấy được option
- `groups`: Kiểm tra job và grade (nil = không yêu cầu)
- Có thể kết hợp cả 2: Yêu cầu cả job/grade VÀ item

### Các vị trí mặc định
- **Mechanic**: `vec3(-316.91, -129.96, 39.02)`
- **Police**: `vec3(451.51, -992.42, 30.69)`
- **Ambulance**: `vec3(307.69, -1433.24, 29.95)`

## Bảo mật

### Double Validation System
Resource sử dụng hệ thống xác thực 2 lớp:

1. **Client-side check (canInteract)**
   - Kiểm tra nhanh để hiện/ẩn option
   - Kiểm tra job, grade và item (ox_target tự động)
   - Giảm tải cho server

2. **Server-side validation (hasStashPermission)**
   - Kiểm tra lại job và grade trên server
   - Không thể bypass bằng console hoặc script injection
   - Đảm bảo an toàn tuyệt đối

### Tính năng bảo mật
- ✅ Không thể mở stash bằng command injection
- ✅ Không thể bypass quyền truy cập
- ✅ Input validation chặt chẽ
- ✅ Personal stash theo citizenid (không thể access stash người khác)
- ✅ Item requirement được ox_target xử lý (native check)

## Commands

### Client
- `/reloadstash` - Reload targets (chỉ trong môi trường dev)

### Server (Admin only)
- `/reloadstashes` - Reload tất cả stashes

## Commands

### Client
- `/reloadstash` - Reload targets (chỉ trong môi trường dev)
- `/closestash` - Đóng stash thủ công
- `/resetstash` - Reset state khi bị stuck

### Server (Admin only)
- `/reloadstashes` - Reload tất cả stashes

## Troubleshooting

### Stash không hiển thị
1. Kiểm tra job của player
2. Kiểm tra grade của player
3. Kiểm tra tọa độ trong config
4. Restart resource: `/restart xn_stash`

### Target không hoạt động
1. Kiểm tra ox_target đã start
2. Kiểm tra dependencies trong fxmanifest
3. Sử dụng `/reloadstash` để reload

### Inventory không mở hoặc bị stuck
1. Sử dụng `/resetstash` để reset state
2. Sử dụng `/closestash` để đóng thủ công
3. Restart resource: `/restart xn_stash`

## Changelog

### v1.2.0 (Current)
- ✅ Thêm tính năng yêu cầu item (requiredItem)
- ✅ Hỗ trợ ox_target items parameter
- ✅ Cải thiện bảo mật với double validation
- ✅ Server-side permission check
- ✅ Hỗ trợ kho đồ cá nhân (personal stashes)
- ✅ Input validation chống exploit

### v1.0.0
- ✅ Khởi tạo resource
- ✅ Hỗ trợ mechanic, police, ambulance
- ✅ Tích hợp ox_target và ox_inventory
- ✅ Kiểm tra quyền truy cập

## Support
- Discord: XuanNuyen#1234
- GitHub: https://github.com/xuannuyen

## License
MIT License
