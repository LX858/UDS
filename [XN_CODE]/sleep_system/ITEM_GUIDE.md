# Hướng dẫn thêm item Chiếu ngủ di động

## Bước 1: Thêm item vào ox_inventory

Mở file `ox_inventory/data/items.lua` và thêm đoạn code sau:

```lua
['chieungu'] = {
    label = 'Chiếu ngủ di động',
    weight = 2000,
    stack = false,
    close = true,
    description = 'Một tấm chiếu để bạn có thể ngủ bất cứ nơi đâu',
    client = {
        export = 'sleep_system.SleepWithItem'
    }
},
```

## Bước 2: Restart resource

Restart lại các resource:
```
restart ox_inventory
restart sleep_system
```

## Bước 3: Thêm item cho player (test)

Sử dụng command để test:
```
/giveitem [id] chieungu 1
```

## Cách sử dụng

1. Mở inventory và chọn item "Chiếu ngủ di động"
2. Nhấn "Use" để sử dụng
3. Người chơi sẽ ngủ ngay tại vị trí đang đứng
4. Thời gian ngủ sẽ được tính tự động dựa trên năng lượng hiện tại

## Cấu hình

Trong file `config.lua` có thể điều chỉnh:

```lua
Config.SleepItem = {
    enabled = true,                 -- Bật/tắt tính năng
    itemName = 'chieungu',          -- Tên item
    consumeOnUse = false,           -- true = xóa item sau khi dùng, false = giữ lại
    label = "Chiếu ngủ di động",
}
```

## Lưu ý

- Item có thể được sử dụng ở bất cứ đâu
- Vị trí ngủ sẽ là vị trí người chơi đang đứng
- Người chơi vẫn được bảo vệ khi ngủ (invincible, no collision, etc.)
- Có thể cấu hình để item bị tiêu hao sau khi dùng bằng cách đặt `consumeOnUse = true`
