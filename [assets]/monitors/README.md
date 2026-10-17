# Anti-Trigger System - Token-Based Authentication

## 📋 Mô tả
Hệ thống bảo vệ các event trong FiveM khỏi việc trigger trái phép bằng cách sử dụng Token-Based Authentication. Mỗi client sẽ được cấp một token duy nhất và phải gửi kèm token khi trigger event được bảo vệ.

## ✨ Tính năng

- ✅ **Token Authentication**: Xác thực người dùng bằng token duy nhất
- ✅ **Auto Token Refresh**: Tự động làm mới token trước khi hết hạn
- ✅ **Client Loader**: Tự động quản lý token ở phía client
- ✅ **Violation Tracking**: Theo dõi và xử lý các vi phạm
- ✅ **Auto Ban System**: Tự động ban người chơi vi phạm
- ✅ **Discord Webhook**: Thông báo vi phạm qua Discord
- ✅ **Easy Integration**: Dễ dàng tích hợp vào các event hiện có

## 🔧 Cài đặt

1. Copy thư mục `anti-trigger` vào thư mục resources của server
2. Thêm vào `server.cfg`:
```
ensure anti-trigger
```
3. Cấu hình trong file `config.lua`
4. Khởi động lại server

## ⚙️ Cấu hình

Mở file `config.lua` để cấu hình:

```lua
-- Thời gian token hết hạn (milliseconds)
Config.TokenExpireTime = 300000 -- 5 phút

-- Thời gian tự động refresh token
Config.TokenRefreshInterval = 240000 -- 4 phút

-- Độ dài token
Config.TokenLength = 64

-- Bật logging
Config.EnableLogging = true

-- Tự động ban khi vi phạm
Config.BanOnViolation = true

-- Số lần vi phạm tối đa trước khi ban
Config.MaxViolations = 3

-- Discord Webhook (tùy chọn)
Config.Webhook = {
    enabled = false,
    url = 'YOUR_WEBHOOK_URL_HERE',
    color = 16711680
}
```

## 🚀 Sử dụng

### Cách 1: Bảo vệ event trong resource khác (Khuyến nghị)

Trong file server của resource bạn muốn bảo vệ:

```lua
-- Đăng ký event được bảo vệ
exports['anti-trigger']:RegisterProtectedEvent('myResource:giveItem', function(source, itemName, quantity)
    -- Token đã được xác thực tự động
    -- Code xử lý event của bạn ở đây
    print(string.format("Player %s nhận %d %s", GetPlayerName(source), quantity, itemName))
    
    -- Ví dụ: Trao item cho người chơi
    -- ESX.GetPlayerFromId(source).addInventoryItem(itemName, quantity)
end)
```

Trong file client của resource:

```lua
-- Trigger event được bảo vệ
RegisterCommand('getitem', function(source, args)
    local itemName = args[1] or 'bread'
    local quantity = tonumber(args[2]) or 1
    
    -- Sử dụng helper function để tự động gửi kèm token
    exports['anti-trigger']:TriggerProtectedServerEvent('myResource:giveItem', itemName, quantity)
    
    -- HOẶC sử dụng global function
    _TriggerProtectedServerEvent('myResource:giveItem', itemName, quantity)
end, false)
```

### Cách 2: Bảo vệ nhiều event cùng lúc

```lua
local protectedEvents = {
    ['myResource:giveItem'] = function(source, itemName, quantity)
        -- Xử lý trao item
    end,
    
    ['myResource:giveMoney'] = function(source, amount)
        -- Xử lý trao tiền
    end,
    
    ['myResource:setJob'] = function(source, job, grade)
        -- Xử lý đổi nghề
    end
}

exports['anti-trigger']:RegisterProtectedEvents(protectedEvents)
```

### Cách 3: Sử dụng trong code hiện có

**Server side:**
```lua
-- Thay vì dùng RegisterNetEvent thông thường
RegisterNetEvent('myEvent', function(data)
    -- Code xử lý
end)

-- Dùng RegisterProtectedEvent
exports['anti-trigger']:RegisterProtectedEvent('myEvent', function(source, data)
    -- Token đã được xác thực
    -- Code xử lý
end)
```

**Client side:**
```lua
-- Thay vì dùng TriggerServerEvent thông thường
TriggerServerEvent('myEvent', data)

-- Dùng TriggerProtectedServerEvent
exports['anti-trigger']:TriggerProtectedServerEvent('myEvent', data)
-- HOẶC
_TriggerProtectedServerEvent('myEvent', data)
```

## 📝 API Functions

### Server Exports

```lua
-- Đăng ký một event được bảo vệ
exports['anti-trigger']:RegisterProtectedEvent(eventName, handler)

-- Đăng ký nhiều event được bảo vệ
exports['anti-trigger']:RegisterProtectedEvents(eventsTable)

-- Kiểm tra token có hợp lệ không
local isValid = exports['anti-trigger']:ValidateToken(source, token)

-- Lấy token của người chơi
local token = exports['anti-trigger']:GetPlayerToken(source)

-- Kiểm tra event có được bảo vệ không
local isProtected = exports['anti-trigger']:IsEventProtected(eventName)
```

### Client Exports

```lua
-- Lấy token hiện tại
local token = exports['anti-trigger']:GetCurrentToken()

-- Kiểm tra token đã sẵn sàng chưa
local isReady = exports['anti-trigger']:IsTokenReady()

-- Trigger event được bảo vệ (tự động gửi kèm token)
exports['anti-trigger']:TriggerProtectedServerEvent(eventName, ...)
```

### Global Functions

```lua
-- Client side - Helper function toàn cục
_TriggerProtectedServerEvent(eventName, ...)
```

## 🔒 Bảo mật

Hệ thống bảo vệ chống lại:
- ✅ Trigger event trái phép từ menu inject
- ✅ Sử dụng token đã hết hạn
- ✅ Sử dụng token của người khác
- ✅ Trigger event mà không có token
- ✅ Gửi token không hợp lệ

Khi phát hiện vi phạm:
1. Ghi log chi tiết
2. Đếm số lần vi phạm
3. Gửi thông báo Discord (nếu bật)
4. Tự động ban sau X lần vi phạm

## 📊 Commands

**Console only:**
```
tokeninfo [player_id]        # Xem thông tin token của người chơi
protectedevents              # Liệt kê các event được bảo vệ
```

**Player commands (debug):**
```
/checktoken                  # Kiểm tra trạng thái token
/refreshtoken                # Làm mới token thủ công
```

## 📦 Ví dụ đầy đủ

Xem file `example_usage.lua` để biết ví dụ chi tiết về cách tích hợp vào các resource phổ biến như ESX, QBCore, v.v.

## 🐛 Debug

Nếu gặp vấn đề:
1. Kiểm tra console server xem có lỗi không
2. Bật `Config.EnableLogging = true` để xem log chi tiết
3. Dùng command `/checktoken` để kiểm tra trạng thái token
4. Dùng command `tokeninfo [id]` trong console để xem token info

## ⚠️ Lưu ý

- Token sẽ tự động làm mới trước khi hết hạn
- Khi người chơi disconnect, token sẽ bị xóa
- Không cần lo lắng về việc quản lý token thủ công
- Hệ thống tự động xử lý mọi thứ

## 📄 License

MIT License - Tự do sử dụng cho mọi mục đích

## 👨‍💻 Hỗ trợ

Nếu cần hỗ trợ, vui lòng mở issue hoặc liên hệ qua Discord.

---

**Made with ❤️ for FiveM Community**
