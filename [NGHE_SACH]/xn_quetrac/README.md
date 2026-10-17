# XN Quét Rác - Trash Collector Job

## Mô tả
Resource nghề dọn rác cho QBCore/QBX Framework sử dụng ox_lib và ox_target.

## Tính năng
- ✅ Mua chổi tại cửa hàng ($500)
- ✅ Quét rác tại 8 điểm trong công viên
- ✅ Xử lý rác để nhận nhựa tái chế
- ✅ 1% cơ hội nhận Lá chà bồn (rare item)
- ✅ Hệ thống ox_target cho tất cả tương tác
- ✅ Progress bar với animation
- ✅ Blips hiển thị trên map

## Cài đặt

### 1. Thêm items vào qbx_core/shared/items.lua

```lua
-- Công cụ
['broom'] = {
    name = 'broom',
    label = 'Chổi',
    weight = 1000,
    type = 'item',
    image = 'broom.png',
    unique = false,
    useable = false,
    shouldClose = true,
    combinable = nil,
    description = 'Chổi dùng để quét rác'
},

-- Rác
['trash'] = {
    name = 'trash',
    label = 'Rác',
    weight = 100,
    type = 'item',
    image = 'trash.png',
    unique = false,
    useable = false,
    shouldClose = true,
    combinable = nil,
    description = 'Rác từ công viên'
},

-- Phần thưởng
['plastic'] = {
    name = 'plastic',
    label = 'Nhựa Tái Chế',
    weight = 50,
    type = 'item',
    image = 'plastic.png',
    unique = false,
    useable = false,
    shouldClose = true,
    combinable = nil,
    description = 'Nhựa được tái chế từ rác'
},

['toilet_paper'] = {
    name = 'toilet_paper',
    label = 'Lá Chà Bồn',
    weight = 10,
    type = 'item',
    image = 'toilet_paper.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Lá chà bồn hiếm (1% từ rác)'
},
```

### 2. Thêm resource vào server.cfg

```cfg
ensure xn_quetrac
```

### 3. Thêm hình ảnh items
Thêm các file hình ảnh sau vào `qbx_core/html/images/`:
- `broom.png`
- `trash.png`
- `plastic.png`
- `toilet_paper.png`

## Hướng dẫn chơi

### Bước 1: Mua chổi
- Đến vị trí: `vec4(236.03, -879.57, 29.57, 333.22)` (Công viên)
- Tương tác với ox_target
- Mua chổi với giá $500

### Bước 2: Quét rác
- Sử dụng chổi đến các điểm rác trong công viên
- Nhấn E (ox_target) tại mỗi điểm
- Chờ 5 giây để quét rác
- Nhận được item "Rác"

### Các vị trí rác:
1. `vec3(229.73, -896.53, 29.51)`
2. `vec3(239.68, -886.78, 29.51)`
3. `vec3(243.2, -879.47, 29.51)`
4. `vec3(230.38, -876.42, 29.51)`
5. `vec3(224.35, -884.62, 29.51)`
6. `vec3(215.85, -892.96, 29.51)`
7. `vec3(208.28, -901.58, 29.51)`
8. `vec3(213.86, -903.66, 29.51)`

### Bước 3: Xử lý rác
- Đến khu xử lý rác: `vec3(125.1, -1180.61, 28.85)`
- Tương tác với ox_target
- Chờ 5 giây để xử lý
- Nhận phần thưởng:
  - Nhựa tái chế (1-3 cái mỗi rác)
  - 1% cơ hội nhận Lá chà bồn

## Commands (Admin only)

```lua
/givebroom - Nhận chổi
/givetrash [amount] - Nhận rác (số lượng tùy chọn)
```

## Cấu hình

Chỉnh sửa `config.lua` để thay đổi:
- Giá chổi
- Vị trí các điểm
- Thời gian thực hiện
- Phần thưởng
- Tỉ lệ rare item
- Blip settings

## Dependencies

- qbx_core
- ox_lib
- ox_target

## Credits

- Author: Nghe Sach
- Framework: QBX Core
- Version: 1.0.0
