# ox_lib Zones System - Điểm Uy Tín

## Tổng quan
Resource Điểm Uy Tín đã được nâng cấp sử dụng **ox_lib zones** để quản lý các khu vực cấm combat (forbiddenCombatZones). Hệ thống này thay thế phương pháp tính khoảng cách thủ công cũ.

## Yêu cầu
- **ox_lib** (đã có sẵn)
- QBCore/QBX framework
- ox_target

## Cài đặt

### Không cần cài đặt thêm!
ox_lib zones đã được tích hợp sẵn trong ox_lib, không cần download thêm dependency.

### Chỉ cần khởi động lại resource
```
restart Diemuytin
```

## Cách hoạt động

### 1. Khởi tạo Zones
Khi resource start, tất cả 8 khu vực cấm trong `config.lua` sẽ được tự động chuyển đổi thành ox_lib sphere zones:

```lua
forbiddenCombatZones = {
    {name = "Pillbox Hospital", coords = vector3(298.88, -584.65, 43.26), radius = 100.0},
    {name = "Cardealer", coords = vector3(-56.96, -1098.93, 26.42), radius = 50.0},
    -- ... còn 6 zones nữa
}
```

Mỗi zone được tạo bằng:
```lua
local zone = lib.zones.sphere({
    coords = zoneConfig.coords,
    radius = zoneConfig.radius,
    debug = false,
    onEnter = function(self) -- Khi vào zone
        isInForbiddenZone = true
        currentZoneName = zoneConfig.name
    end,
    onExit = function(self) -- Khi rời zone
        isInForbiddenZone = false
        currentZoneName = ""
    end
})
```

### 2. Detection System
- Mỗi zone có callbacks `onEnter`/`onExit` tự động trigger khi player vào/ra
- Biến `isInForbiddenZone` update real-time
- Không cần kiểm tra khoảng cách thủ công nữa
- **Faster than PolyZone** - sử dụng glm.polygon optimization

### 3. Console Logging
Khi debug, bạn sẽ thấy:
```
[DIEMUYTIN] 🎯 Created forbidden zone: Pillbox Hospital (radius: 100m)
[DIEMUYTIN] 🎯 Created forbidden zone: LSPD (radius: 50m)
[DIEMUYTIN] ✅ All 8 forbidden zones initialized with ox_lib
[DIEMUYTIN] ✅ Entered forbidden zone: LSPD
[DIEMUYTIN] 🚪 Left forbidden zone: LSPD
```

## Kiểm tra cài đặt

### Xem console log
Khi start Diemuytin, bạn phải thấy:
- `🎯 Created forbidden zone: [tên zone]` cho mỗi zone (8 messages)
- `✅ All 8 forbidden zones initialized with ox_lib`

## Lợi ích của ox_lib zones

✅ **Không cần dependency**: ox_lib đã có sẵn, không cần tải thêm
✅ **Performance tốt nhất**: Faster than PolyZone với glm optimization
✅ **Code sạch hơn**: API đơn giản với onEnter/onExit
✅ **Tích hợp sâu**: Built-in với ox_lib ecosystem
✅ **Mở rộng dễ dàng**: Có thể dùng `lib.zones.box()`, `lib.zones.poly()` cho polygon zones
✅ **Debug dễ hơn**: Set `debug = true` để visualize zones in-game

## Troubleshooting

### Zones không detect player
1. Bật debug mode: Sửa `debug = true` trong client/main.lua (dòng 29)
2. Restart resource: `/restart Diemuytin`
3. Vào game và di chuyển vào zone → sẽ thấy sphere màu trong suốt

### ox_lib outdated
- Đảm bảo ox_lib version mới nhất: zones module được thêm vào ox_lib từ version 3.x
- Update ox_lib: `git pull` trong thư mục ox_lib

### Zones không được tạo
- Check console có error không
- Đảm bảo `config.lua` có đúng format (coords phải là vector3, radius là number)

## Cập nhật config

Để thêm zone mới, chỉ cần edit `config.lua`:
```lua
forbiddenCombatZones = {
    -- ... zones cũ ...
    {
        name = "Khu vực mới", 
        coords = vector3(x, y, z), 
        radius = 75.0
    }
}
```

Restart resource → Zone mới tự động được tạo!

## So sánh với PolyZone

| Feature | ox_lib zones | PolyZone |
|---------|--------------|----------|
| Dependency | ✅ Có sẵn | ❌ Phải tải thêm |
| Performance | ⚡ Fastest (glm) | 🔵 Fast |
| API | 🎯 Simple | 🔵 Moderate |
| Zone types | Sphere, Box, Poly | Circle, Box, Poly, Combo |
| Debug | ✅ Built-in | ✅ Built-in |
| Setup | 0 bước | 3 bước |

## Advanced: Sử dụng Polygon Zones

Nếu bạn cần zone phức tạp hơn hình tròn, có thể dùng `lib.zones.poly()`:

```lua
local complexZone = lib.zones.poly({
    points = {
        vec3(100, 200, 30),
        vec3(150, 200, 30),
        vec3(150, 250, 30),
        vec3(100, 250, 30)
    },
    thickness = 10, -- Chiều cao zone
    debug = true,
    onEnter = function(self)
        print('Entered complex zone')
    end,
    onExit = function(self)
        print('Left complex zone')
    end
})
```

Dùng `/zone poly` in-game để tạo polygon zones dễ dàng!

## Tài liệu tham khảo
- **ox_lib zones docs**: https://coxdocs.dev/ox_lib/Modules/Zones/Shared
- **Zone creator command**: `/zone sphere` hoặc `/zone poly`
- **GitHub**: [overextended/ox_lib](https://github.com/overextended/ox_lib)

## Credits
- **ox_lib**: [Overextended](https://github.com/overextended)
- **Integration**: Điểm Uy Tín v2.0

---

**Ngày cập nhật**: December 2, 2025
**Version**: 2.0 - ox_lib Zones Integration
