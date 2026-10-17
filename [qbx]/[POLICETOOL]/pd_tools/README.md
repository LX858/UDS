# Vehicle Freeze System

Resource FiveM cho phép freeze và tạo khiên bảo vệ cho phương tiện nkscout sử dụng ox_target và ox_lib.

## Tính năng

### 🧊 Đóng băng xe (Freeze Vehicle)
- Target vào xe nkscout và chọn "Đóng băng xe"
- Xe sẽ không thể di chuyển, không bị hư hại
- Có hiệu ứng băng xung quanh xe
- Có thể bỏ đóng băng bằng cách chọn "Bỏ đóng băng xe"

### 🛡️ Khiên bảo vệ (Vehicle Shield)
- Target vào xe nkscout và chọn "Tạo khiên bảo vệ"
- 3 loại khiên:
  - **Khiên cơ bản** (màu cyan)
  - **Khiên nâng cao** (màu cam)
  - **Khiên tối thượng** (màu vàng)
- Có thể đặt thời gian tồn tại (0 = vĩnh viễn)
- Xe hoàn toàn miễn nhiễm mọi sát thương
- Có hiệu ứng ánh sáng màu sắc theo loại khiên

## Cài đặt

1. **Yêu cầu dependencies:**
   - ox_target
   - ox_lib

2. **Cài đặt resource:**
   ```
   1. Copy thư mục pd_tools vào thư mục resources
   2. Thêm vào server.cfg:
      ensure ox_target
      ensure ox_lib
      ensure pd_tools
   ```

3. **Khởi động server**

## Cách sử dụng

### Cho người chơi:
1. Tìm xe mẫu "nkscout"
2. Đi gần xe và nhấn `Alt` (hoặc phím target của bạn)
3. Chọn các tùy chọn:
   - 🧊 **Đóng băng xe** - Cố định xe tại vị trí hiện tại
   - 🔥 **Bỏ đóng băng xe** - Cho phép xe di chuyển lại
   - 🛡️ **Tạo khiên bảo vệ** - Tạo khiên bảo vệ cho xe
   - 🛡️ **Xóa khiên bảo vệ** - Xóa khiên bảo vệ

### Cho admin:

#### Commands có sẵn:
- `/listfrozen` - Xem danh sách xe đang đóng băng
- `/listshields` - Xem danh sách xe có khiên bảo vệ
- `/unfreezeall` - Bỏ đóng băng tất cả xe (Admin only)
- `/removeshieldsall` - Xóa tất cả khiên xe (Admin only)

## Cấu hình

### Thay đổi model xe:
Trong file `client/main.lua`, tìm dòng:
```lua
exports.ox_target:addModel('nkscout', {
```
Thay `'nkscout'` bằng model xe khác.

### Thay đổi khoảng cách target:
Thay đổi giá trị `distance` trong từng option:
```lua
distance = 3.0, -- Khoảng cách target (meter)
```

### Thay đổi màu khiên:
Trong hàm `GetShieldColor()`, sửa giá trị RGB:
```lua
local colors = {
    basic = {r = 0, g = 255, b = 255},      -- Cyan
    advanced = {r = 255, g = 165, b = 0},   -- Orange
    ultimate = {r = 255, g = 215, b = 0}    -- Gold
}
```

## Hiệu ứng

### Freeze Effect:
- Particle effect khói xung quanh xe
- Xe không thể di chuyển
- Engine tự động tắt

### Shield Effect:
- Marker ánh sáng màu sắc theo loại khiên
- Xe miễn nhiễm hoàn toàn sát thương
- Tự động hết hạn theo thời gian đặt

## Logging

System tự động log các hoạt động:
- Đóng băng/bỏ đóng băng xe
- Tạo/xóa khiên bảo vệ
- Cleanup tự động khi player disconnect
- Cleanup xe không tồn tại

## Troubleshooting

### Lỗi thường gặp:

1. **Không thấy target options:**
   - Kiểm tra ox_target đã cài đặt đúng
   - Đảm bảo xe là model 'nkscout'
   - Kiểm tra khoảng cách target

2. **Hiệu ứng không hiển thị:**
   - Kiểm tra graphic settings
   - Restart resource

3. **Xe không freeze:**
   - Kiểm tra console có lỗi
   - Đảm bảo network ownership

### Performance:
- System tự động cleanup mỗi 5 phút
- Các hiệu ứng được tối ưu hóa
- Không ảnh hưởng FPS đáng kể

## Support

Nếu gặp vấn đề, kiểm tra:
1. Console F8 có lỗi gì
2. Server console có log lỗi
3. Dependencies đã cài đúng chưa

---

**Phiên bản:** 1.0.0  
**Tác giả:** [Your Name]  
**License:** MIT
