# us_long_container v2

Resource FiveM tạo container hàng dài bằng **thân rỗng không có cửa liền khối** và bốn prop cửa rời:

- Hai cửa phía trước mở/đóng bằng `ox_target`.
- Hai cửa phía sau gắn cố định để container chỉ có một đầu thao tác.
- Trạng thái được server đồng bộ cho toàn bộ người chơi.

## Sửa lỗi của bản cũ

Bản cũ dùng `prop_container_01mb`. Model đó vẫn có phần cửa nằm liền trong thân nên dù hai cửa rời đã xoay ra ngoài, mặt container vẫn còn một bộ cửa đóng.

Bản v2 đổi thân mặc định thành:

```lua
prop_container_03mb
```

Bộ prop hoàn chỉnh:

```lua
body      = 'prop_container_03mb'
leftDoor  = 'prop_container_door_mb_l'
rightDoor = 'prop_container_door_mb_r'
```

Không đổi lại thân thành `prop_container_01mb` hoặc dòng `prop_container_01a` đến `prop_container_01h`.

## Offset cửa

Hai cửa phía trước:

```lua
right = vec3( 1.2979125976562, -3.390869140625, 1.4021835327148)
left  = vec3(-1.2979125976562, -3.390869140625, 1.4021835327148)
```

Hai cửa phía sau:

```lua
left  = vec3( 1.2979125976562, 3.390869140625, 1.4021835327148)
right = vec3(-1.2979125976562, 3.390869140625, 1.4021835327148)
```

Các tọa độ trên là vị trí pivot/bản lề của cửa rời. Không cộng thêm nửa chiều rộng cánh cửa.

## Cài đặt

1. Xóa bản `us_long_container` cũ hoặc thay toàn bộ file bằng bản v2.
2. Chép thư mục resource vào `resources/[understar]/`.
3. Sửa `Config.Containers` trong `config.lua`.
4. Thêm:

```cfg
ensure ox_lib
ensure ox_target
ensure us_long_container
```

Tên thư mục có thể đổi thành `us_long_container`; khi đó sửa dòng ensure tương ứng.

## Cấu hình vị trí

```lua
Config.Containers = {
    {
        id = 'understar_container_01',
        coords = vec4(-1095.10, -2735.20, 13.75, 149.0),
        placeOnGround = true,
        initiallyOpen = false,
        textureVariation = 0
    }
}
```

## Đổi màu/thân tương thích

Có thể thử các model dùng cùng hệ cửa và kích thước:

```lua
Config.Models.body = 'prop_container_03mb'
-- hoặc:
Config.Models.body = 'prop_container_03_ld'
Config.Models.body = 'prop_container_04mb'
```

Nên giữ `prop_container_03mb` để test đầu tiên.

## Góc mở

```lua
left.openRotation  = vec3(0.0, 0.0, -112.0)
right.openRotation = vec3(0.0, 0.0, 112.0)
```

Nếu muốn mở rộng hơn, tăng trị tuyệt đối lên khoảng `125.0`. Nếu cửa mở vào trong, đảo dấu hai góc.

## Yêu cầu

- `ox_lib`
- `ox_target`
- Khuyến nghị bật OneSync để server kiểm tra khoảng cách ổn định.

Resource không phụ thuộc Qbox, QBCore hoặc ESX.

## Phân quyền

- `client/editable.lua`: điều kiện hiển thị target.
- `server/editable.lua`: xác thực job, gang, item hoặc quyền phía server.

## Export

```lua
exports.us_long_container:SetState('understar_container_01', true)  -- mở
exports.us_long_container:SetState('understar_container_01', false) -- đóng
local isOpen = exports.us_long_container:GetState('understar_container_01')
```

Nếu đổi tên thư mục resource, tên export cũng đổi theo tên thư mục đó.
