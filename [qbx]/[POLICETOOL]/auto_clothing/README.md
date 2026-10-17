# Auto Clothing System - Police Uniforms

## Mô tả
Resource tự động thay đổi đồng phục cho cảnh sát khi on/off duty.

## Tính năng
- ✅ Tự động mặc đồng phục khi cảnh sát on duty
- ✅ Tự động khôi phục quần áo thường khi off duty
- ✅ Lưu quần áo hiện tại trước khi thay đổi
- ✅ Hỗ trợ 14 cấp bậc khác nhau
- ✅ Phân biệt đồng phục nam/nữ
- ✅ Commands hỗ trợ thủ công

## Cài đặt
1. Copy folder `auto_clothing` vào `resources/[POLICETOOL]/`
2. Thêm vào `server.cfg`:
```
ensure auto_clothing
```

## Cấu trúc cấp bậc
### Nam:
- **Học viên** (Grade 0-3): Tân Binh, Hạ Sĩ, Trung Sĩ, Thượng sĩ
- **Sĩ quan** (Grade 4-9): Thiếu úy, Thượng úy, Đại úy, Thiếu tá, Trung tá, Đại tá
- **Sĩ quan cấp cao** (Grade 10-13): Đồn phó, Đồn trưởng, Thư kí - FTO, Phó giám đốc
- **Giám đốc** (Grade 14): Giám đốc

### Nữ:
- **Học viên** (Grade 0-3)
- **Sĩ quan** (Grade 4-9)
- **Sĩ quan cấp cao** (Grade 10-14)

## Commands
- `/uniform` - Mặc đồng phục (phải on duty)
- `/civilian` - Khôi phục quần áo thường (phải off duty)
- `/reloaduniforms` - Reload config (Admin only)

## Cấu hình
Chỉnh sửa file `config.lua` để thay đổi:
- Số ID của quần áo
- Cấp bậc áp dụng
- Job name

## Yêu cầu
- qb-core hoặc QBox framework
- Duty system

## Lưu ý
- Resource tự động phát hiện giới tính của character
- Quần áo cũ sẽ được lưu và khôi phục khi off duty
- Hỗ trợ cả khi player join server đang on duty

## Hỗ trợ
Nếu có lỗi, kiểm tra:
1. F8 console
2. Server console
3. Đảm bảo qb-core đã khởi động
4. Kiểm tra job name trong config có khớp với shared.lua không
