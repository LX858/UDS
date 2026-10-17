# Hướng dẫn tùy chỉnh hiệu ứng Blur khi ngủ

## Cấu hình hiệu ứng Blur trong config.lua

```lua
Config.SleepProtection = {
    -- Hiệu ứng visual khi ngủ
    enableBlurEffect = true,    -- 🌙 BẬT/TẮT hiệu ứng blur khi ngủ
    blurEffectName = 'DeathFailMPIn',  -- Tên hiệu ứng blur
    blurTimecycle = 'sleeping',        -- Timecycle modifier cho hiệu ứng mơ màng
    blurStrength = 0.5,               -- Độ mạnh của timecycle (0.0 - 1.0) - GIẢM để ít rung
    
    -- Cài đặt chống rung màn hình
    reduceScreenShake = true,         -- 🔧 Giảm rung màn hình
    blurUpdateInterval = 500,         -- Thời gian cập nhật hiệu ứng (ms) - Tăng để ít rung
    
    -- Các cài đặt khác...
}
```

## Các hiệu ứng có thể sử dụng (theo mức độ rung từ ít -> nhiều)

### 1. SwitchHudMichaelOut (Ít rung nhất)
- **Mô tả**: Hiệu ứng chuyển đổi character, nhẹ nhàng
- **Phù hợp**: Tốt nhất cho người dễ bị rung màn hình
- **Cài đặt**: `blurEffectName = 'SwitchHudMichaelOut'`

### 2. DeathFailMPIn (Khuyến nghị)
- **Mô tả**: Hiệu ứng mờ và tối như khi chết trong multiplayer
- **Phù hợp**: Tốt cho trạng thái ngủ, rung vừa phải
- **Cài đặt**: `blurEffectName = 'DeathFailMPIn'`

### 3. HeistCelebPass (Rung trung bình)
- **Mô tả**: Hiệu ứng celebrate
- **Phù hợp**: Hiệu ứng vui vẻ nhưng có thể rung nhẹ
- **Cài đặt**: `blurEffectName = 'HeistCelebPass'`

### 4. DrugsTrevorClownsFight (Rung nhiều)
- **Mô tả**: Hiệu ứng màu sắc lạ như khi sử dụng ma túy
- **Phù hợp**: Tạo hiệu ứng mơ màng nhưng có thể gây rung
- **Cài đặt**: `blurEffectName = 'DrugsTrevorClownsFight'`

### 5. DrugsMichaelAliensFight (Rung nhiều nhất)
- **Mô tả**: Hiệu ứng alien fight
- **Phù hợp**: Hiệu ứng mạnh nhưng gây rung nhiều
- **Cài đặt**: `blurEffectName = 'DrugsMichaelAliensFight'`

## Timecycle Modifiers

### sleeping (Khuyến nghị)
- **Mô tả**: Hiệu ứng mờ nhẹ, thích hợp cho ngủ
- **Cài đặt**: `blurTimecycle = 'sleeping'`

### underwater
- **Mô tả**: Hiệu ứng như dưới nước
- **Cài đặt**: `blurTimecycle = 'underwater'`

### drunk
- **Mô tả**: Hiệu ứng say rượu
- **Cài đặt**: `blurTimecycle = 'drunk'`

## Tùy chỉnh độ mạnh

```lua
-- Nhẹ nhàng (ít rung)
blurStrength = 0.3

-- Trung bình (khuyến nghị để giảm rung)
blurStrength = 0.5

-- Mạnh (có thể gây rung)
blurStrength = 0.8
```

## Giảm rung màn hình

```lua
-- Bật giảm rung màn hình
reduceScreenShake = true

-- Tăng thời gian cập nhật để giảm rung
blurUpdateInterval = 500  -- 500ms (khuyến nghị)
blurUpdateInterval = 1000 -- 1s (ít rung hơn)
```

## Tắt hiệu ứng blur

```lua
enableBlurEffect = false
```

## Kiểm thử

1. Thay đổi cài đặt trong `config.lua`
2. Restart resource: `/restart sleep_system`
3. Thử ngủ và kiểm tra hiệu ứng

## Lưu ý

- **Rung màn hình**: Nếu hiệu ứng gây rung, hãy:
  - Giảm `blurStrength` xuống 0.3-0.5
  - Bật `reduceScreenShake = true`
  - Tăng `blurUpdateInterval` lên 500-1000ms
- Nếu hiệu ứng không hoạt động, hãy kiểm tra console F8 xem có lỗi gì không
- Một số hiệu ứng có thể gây chói mắt, nên test kỹ trước khi sử dụng
- Nếu người chơi phàn nàn về hiệu ứng quá mạnh, hãy giảm `blurStrength`

## Khuyến nghị cho server

```lua
-- Cấu hình tối ưu để giảm rung và tăng trải nghiệm
Config.SleepProtection = {
    enableBlurEffect = true,
    blurEffectName = 'DeathFailMPIn',
    blurTimecycle = 'sleeping',
    blurStrength = 0.5,          -- Giảm từ 0.8 xuống 0.5
    reduceScreenShake = true,     -- Bật giảm rung
    blurUpdateInterval = 500,     -- Cập nhật mỗi 500ms
}
```
