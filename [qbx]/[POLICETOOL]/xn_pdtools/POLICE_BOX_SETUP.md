# Hướng dẫn cài đặt tính năng Police Box

## Bước 1: Thêm items vào ox_inventory

Mở file `data/items.lua` trong resource `ox_inventory` và thêm các items sau:

```lua
-- Police Box
['box_police'] = {
    label = 'Hộp Cảnh Sát',
    weight = 2000,
    stack = true,
    close = true,
    description = 'Một hộp chứa trang bị cơ bản cho cảnh sát',
    client = {
        export = 'xn_pdtools.usePoliceBox'
    }
},

-- Các items nhận được từ hộp (nếu chưa có)
['weapon_stungun'] = {
    label = 'Súng Điện',
    weight = 1000,
    stack = false,
    close = true,
    description = 'Súng điện để khống chế tội phạm'
},

['weapon_nightstick'] = {
    label = 'Dùi Cui',
    weight = 500,
    stack = false,
    close = true,
    description = 'Dùi cui tiêu chuẩn của cảnh sát'
},

['handcuffs'] = {
    label = 'Còng Tay',
    weight = 200,
    stack = true,
    close = true,
    description = 'Còng tay để bắt giữ tội phạm'
}
```

## Bước 2: Restart resource

Sau khi thêm items vào ox_inventory, restart các resource:

```
/restart ox_inventory
/restart xn_pdtools
```

## Bước 3: Test

Để test, bạn có thể dùng lệnh:

```
/give [id] box_police 1
```

Sau đó sử dụng item `box_police` trong inventory để nhận:
- 1x weapon_stungun
- 1x weapon_nightstick  
- 1x handcuffs

## Tùy chỉnh

Bạn có thể tùy chỉnh các items nhận được trong file `config.lua`:

```lua
Config.PoliceBox = {
    itemName = 'box_police',
    items = {
        { name = 'weapon_stungun', amount = 1 },
        { name = 'weapon_nightstick', amount = 1 },
        { name = 'handcuffs', amount = 1 }
    }
}
```

Thay đổi `name` và `amount` để tùy chỉnh items và số lượng.
