# Sleep System for FiveM

Hệ thống ngủ cho FiveM sử dụng QBCore Framework.

## Tính năng

- **Ox_target integration**: Tạo điểm tương tác tại các vị trí ngủ
- **Kiểm tra sleepiness thông minh**: Không cho phép ngủ nếu năng lượng đã đầy (100%)
- **Tính toán thời gian ngủ động**: Thời gian ngủ tự động điều chỉnh theo % sleepiness hiện tại
- **Player state tracking**: Sử dụng LocalPlayer.state để theo dõi trạng thái ngủ
- **Thông báo chi tiết**: Hiển thị năng lượng hiện tại, sau khi ngủ và thời gian ngủ cần thiết
- Khi bắt đầu ngủ, người chơi sẽ được chuyển thành dạng `xm_prop_body_bag`
- Có progressbar hiển thị thời gian ngủ còn lại (sử dụng ox_lib)
- Có thể hủy bỏ việc ngủ bằng cách nhấn ESC khi đang có progressbar
- Chỉ số `sleepiness` sẽ tăng lên 100% sau khi ngủ xong
- Không thể di chuyển khi đang ngủ (được xử lý bởi ox_lib progressbar)
- Admin có thể đánh thức player bằng command
- **4 vị trí ngủ được cấu hình**: Giường ngủ 1, 2, 3 và Ghế chùa 1

## 🕐 Hệ thống Tính toán Thời gian Ngủ

### Công thức tính toán:
- **100% sleepiness = 3 phút (180 giây)**
- **1% sleepiness = 1.8 giây**
- **Thời gian ngủ = (100% - sleepiness hiện tại) × 1.8 giây**

### Ví dụ:
- Sleepiness 0% → 100%: 100 × 1.8s = 180s (3 phút)
- Sleepiness 50% → 100%: 50 × 1.8s = 90s (1.5 phút)
- Sleepiness 80% → 100%: 20 × 1.8s = 36s (36 giây)
- Sleepiness 95% → 100%: 5 × 1.8s = 9s (9 giây)

### Giới hạn:
- **Thời gian tối thiểu**: 5 giây
- **Thời gian tối đa**: 180 giây (3 phút)
- **Sleepiness >= 100%**: Không cần ngủ

## Cài đặt

1. Sao chép thư mục `sleep_system` vào thư mục `resources` của server
2. Thêm `ensure sleep_system` vào file `server.cfg`
3. Restart server

## Sử dụng

### Sử dụng

#### Ox_target (Mặc định)
- Đi tới một trong 4 vị trí ngủ được cấu hình
- Nhấm vào điểm tương tác ox_target
- Chọn "Ngủ (Tên vị trí)"

#### Commands (Dự phòng)
- `/sleep` - Tự động tìm vị trí ngủ gần nhất
- `/wakeup` - Thức dậy sớm
- `/wakeup [id]` - Admin đánh thức player (chỉ admin)

#### Debug Commands
- `/reloadsleeptargets` - Reload tất cả sleep targets
- `/checksleepstatus` - Kiểm tra trạng thái ghế ngủ
- `/clearsleepstatus` - Xóa tất cả trạng thái ghế (admin debug)
- `/testsleeptime <sleepiness>` - Test thời gian ngủ cho sleepiness cụ thể

#### Ví dụ Debug Commands
```
/testsleeptime 0    → Hiển thị thời gian ngủ từ 0% đến 100%
/testsleeptime 50   → Hiển thị thời gian ngủ từ 50% đến 100%
/testsleeptime 95   → Hiển thị thời gian ngủ từ 95% đến 100%
```

#### Phím tắt
- `F9` - Tự động tìm vị trí ngủ gần nhất
- `F10` - Thức dậy

## Tính năng Thông minh

### 🧠 Kiểm tra Sleepiness
- **Tự động kiểm tra năng lượng**: Hệ thống sẽ kiểm tra sleepiness hiện tại trước khi cho phép ngủ
- **Ngăn ngủ không cần thiết**: Nếu năng lượng đã đầy (100%), sẽ hiển thị thông báo và không cho phép ngủ
- **Hiển thị thông tin chi tiết**: Thông báo sẽ cho biết năng lượng hiện tại và sau khi ngủ
- **Tính toán thời gian ngủ**: Hệ thống tính toán lượng sleepiness cần tăng

### 🔄 Player State Management
- **LocalPlayer.state tracking**: Sử dụng `LocalPlayer.state:set('isSleeping', true, true)` để theo dõi trạng thái
- **QBCore loop integration**: Tương thích với các hệ thống khác sử dụng player state
- **Trạng thái an toàn**: Đảm bảo reset trạng thái khi hủy bỏ hoặc hoàn thành ngủ

### 📍 Location Management
- **Lưu vị trí ngủ**: `currentSleepLocation` để theo dõi vị trí ngủ hiện tại
- **Thông báo vị trí**: Hiển thị tên vị trí và thông tin năng lượng trong thông báo

## Cấu hình

Tất cả cấu hình có thể thay đổi trong file `config.lua`:

### Cấu hình Thời gian Ngủ Động
- `Config.SleepTimeCalculation.enabled` - Bật/tắt tính toán thời gian ngủ động
- `Config.SleepTimeCalculation.timePerPercent` - Thời gian (giây) cho mỗi 1% sleepiness
- `Config.SleepTimeCalculation.maxSleepTime` - Thời gian tối đa để ngủ (giây)
- `Config.SleepTimeCalculation.minSleepTime` - Thời gian tối thiểu để ngủ (giây)

### Cấu hình Chung
- `Config.SleepDuration` - Thời gian ngủ cố định (khi tính toán động tắt)
- `Config.SleepModel` - Model khi ngủ
- `Config.SleepinessIncrease` - Lượng sleepiness tăng
- `Config.SleepLocations` - Vị trí có thể ngủ
- `Config.Messages` - Thông báo

## Tùy chỉnh Thời gian Ngủ

```lua
-- Cấu hình tính toán thời gian ngủ động
Config.SleepTimeCalculation = {
    enabled = true,           -- Bật tính toán động
    timePerPercent = 1.8,     -- 1.8 giây cho mỗi 1%
    maxSleepTime = 180,       -- Tối đa 3 phút
    minSleepTime = 5,         -- Tối thiểu 5 giây
}

-- Để sử dụng thời gian cố định, tắt tính toán động:
Config.SleepTimeCalculation.enabled = false
Config.SleepDuration = 60 -- 60 giây cố định
```

## Export Functions

### Server-side
```lua
-- Tăng sleepiness cho player
exports['sleep_system']:IncreaseSleepiness(Player, amount)
```

### Client-side
```lua
-- Lấy sleepiness hiện tại
QBCore.Functions.TriggerCallback('sleep:getSleepiness', function(sleepiness)
    print('Current sleepiness:', sleepiness)
end)
```

## Yêu cầu

- QBCore Framework
- ox_lib (cho progressbar)
- ox_target (cho điểm tương tác)
- FiveM Server

## Ghi chú

- Hệ thống sẽ tự động reset khi player disconnect/reconnect
- Player không thể di chuyển khi đang ngủ
- Sleepiness metadata sẽ được lưu trong database của QBCore

## Tối ưu hóa Camera và Bảo vệ

### 🎥 Trải nghiệm Camera Tốt
- **Ẩn ped hoàn toàn**: Tránh hiển thị mờ gây trải nghiệm xấu
- **Không đặt ped dưới lòng đất**: Tránh góc nhìn lạ, chỉ sử dụng entity proofs
- **Camera tự do**: Không force camera focus, người chơi có thể xoay camera tự do
- **Vị trí chính xác**: Ped được đặt tại vị trí body bag chính xác, chỉ hiển thị body bag

### 🛡️ Bảo vệ Toàn diện
- **Entity Proofs**: Bảo vệ khỏi đạn, lửa, nổ, va chạm, đánh đấm, nước, khói
- **Bất tử hoàn toàn**: SetEntityInvincible + SetEntityCanBeDamaged(false)
- **Không thể target**: Tắt targeting từ mọi player
- **Tắt collision**: Không va chạm với vật thể khác
- **Freeze position**: Không thể di chuyển
- **Disable controls**: Tắt combat và movement controls
- **Tắt ragdoll**: Tránh bị ném bay khi bị tấn công
- **Thread kiểm tra**: Tái áp dụng bảo vệ nếu bị vô hiệu hóa

### 🌙 Hiệu ứng Visual Khi Ngủ
- **Blur Effect**: Hiệu ứng mờ màn hình khi ngủ (có thể tắt trong config)
- **Timecycle Modifier**: Hiệu ứng màu sắc mơ màng
- **Screen Effect**: Sử dụng `DeathFailMPIn` tạo hiệu ứng giống như đang ngủ
- **Fade Out**: Hiệu ứng tắt dần khi thức dậy
- **Configurable**: Có thể thay đổi loại hiệu ứng và độ mạnh

### 🔧 Cấu hình Camera và Bảo vệ
```lua
Config.SleepProtection = {
    invisible = true,         -- BẬT ẩn ped (tránh hiển thị mờ)
    setCameraFocus = false,   -- TẮT camera focus (tự do xoay)
    useEntityProofs = true,   -- BẬT entity proofs bảo vệ
    freezePlayer = true,      -- BẬT freeze để tránh di chuyển
    disableControls = true,   -- BẬT disable controls
    
    -- Hiệu ứng blur khi ngủ
    enableBlurEffect = true,  -- BẬT/TẮT hiệu ứng blur
    blurEffectName = 'DeathFailMPIn',  -- Tên hiệu ứng
    blurTimecycle = 'sleeping',        -- Timecycle modifier
    blurStrength = 0.8,               -- Độ mạnh (0.0 - 1.0)
    -- ... các cài đặt khác
}
```

### 🎨 Các Hiệu ứng Blur Có thể Sử dụng
- **`DeathFailMPIn`**: Hiệu ứng chết trong MP (mờ và tối) - Khuyến nghị
- **`DrugsTrevorClownsFight`**: Hiệu ứng ma túy (màu sắc lạ)
- **`SwitchHudMichaelOut`**: Hiệu ứng switch character
- **`DrugsMichaelAliensFight`**: Hiệu ứng alien fight
- **`HeistCelebPass`**: Hiệu ứng celebrate

### 🧪 Kiểm thử
- Thử tấn công player đang ngủ bằng súng → Không thể gây sát thương
- Thử đấm player đang ngủ → Không thể gây sát thương
- Thử nổ gần player đang ngủ → Không bị ảnh hưởng
- Kiểm tra góc nhìn camera → Mượt mà, không bị dịch chuyển
- Kiểm tra vị trí restore → Về đúng vị trí ban đầu
- Kiểm tra hiệu ứng blur → Màn hình mờ, có hiệu ứng mơ màng khi ngủ
- Kiểm tra fade out → Hiệu ứng tắt dần khi thức dậy
- Thử ngủ nhiều người tại cùng vị trí → Chỉ 1 người được ngủ
