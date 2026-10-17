# Mechanic Tools - Vehicle Repair System

## 📋 Mô tả
Resource sửa xe cho FiveM sử dụng QBCore Framework với mini game và ox_target. Người chơi có thể sửa xe bằng cách target vào engine bone của xe, thực hiện mini game bấm phím 1-2-3, sau đó chờ progress bar hoàn thành.

## ✨ Tính năng
- 🎯 Target vào engine bone của xe bằng ox_target
- 🎮 Mini game bấm phím 1, 2, 3 theo thứ tự
- ⏱️ Progress bar 5-7 giây với animation sửa xe
- 🔧 Khôi phục engine health và body health về 100%
- 📦 Tiêu tốn item "repairkit" mỗi lần sử dụng
- 🚗 Chỉ hiển thị option sửa xe khi xe bị hỏng

## 📦 Dependencies
- qb-core
- ox_lib
- ox_target
- progressbar (hoặc tương tự)

## 🚀 Cài đặt

1. **Tải resource:**
   - Copy thư mục `mechanic_tools` vào thư mục `resources` của server

2. **Thêm vào server.cfg:**
   ```
   ensure mechanic_tools
   ```

3. **Thêm item vào qb-core/shared/items.lua:**
   ```lua
   ['repairkit'] = {
       ['name'] = 'repairkit',
       ['label'] = 'Repair Kit',
       ['weight'] = 1000,
       ['type'] = 'item',
       ['image'] = 'repairkit.png',
       ['unique'] = false,
       ['useable'] = true,
       ['shouldClose'] = true,
       ['combinable'] = nil,
       ['description'] = 'Dụng cụ sửa xe'
   },
   ```

4. **Khởi động server và test**

## ⚙️ Cấu hình

Mở file `config.lua` để tùy chỉnh:

```lua
Config.RepairItem = 'repairkit' -- Tên item cần thiết
Config.ProgressDuration = math.random(5000, 7000) -- Thời gian sửa xe
Config.MiniGameKeys = {'1', '2', '3'} -- Phím mini game
Config.RepairDistance = 3.0 -- Khoảng cách tối đa
```

## 🎮 Cách sử dụng

1. **Có sẵn repair kit trong túi**
2. **Đến gần xe bị hỏng**
3. **Nhìn vào engine/capô xe và bấm E (hoặc phím target)**
4. **Chọn "Sửa xe"**
5. **Thực hiện mini game: bấm phím 1, 2, 3 theo thứ tự**
6. **Chờ progress bar hoàn thành**
7. **Xe được sửa xong, repair kit bị trừ 1**

## 🔧 Tùy chỉnh

### Thay đổi engine bones:
```lua
Config.EngineBones = {
    'engine',
    'engine_1', 
    'engine_2',
    'motor',
    'bonnet' -- thêm bone khác nếu cần
}
```

### Thay đổi mini game:
```lua
Config.MiniGameKeys = {'Q', 'E', 'R'} -- Thay đổi phím
```

### Thay đổi animation:
Trong `client/main.lua`, tìm phần:
```lua
anim = {
    dict = 'mini@repair',
    clip = 'fixing_a_ped'
},
```

## 🐛 Troubleshooting

### Lỗi thường gặp:

1. **Không hiển thị option sửa xe:**
   - Kiểm tra ox_target đã được cài đặt và khởi động
   - Xe phải bị hỏng (engine health < 1000)

2. **Mini game không hoạt động:**
   - Kiểm tra key mapping trong `GetControlKey` function

3. **Progress bar không hiển thị:**
   - Kiểm tra dependency progressbar
   - Hoặc resource sẽ fallback về custom progress bar

4. **Item không bị trừ:**
   - Kiểm tra tên item trong config khớp với items.lua
   - Kiểm tra player có item trong túi

## 📝 Changelog

### v1.0.0
- Phiên bản đầu tiên
- Target engine bones
- Mini game 1-2-3
- Progress bar với animation
- Khôi phục engine + body health 100%

## 🤝 Hỗ trợ

Nếu gặp vấn đề, hãy kiểm tra:
1. Console F8 có lỗi gì không
2. Server console có lỗi gì không  
3. Các dependency đã được cài đặt đầy đủ
4. Config đã được thiết lập đúng

## 📄 License
Free to use and modify
