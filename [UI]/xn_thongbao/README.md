# All Stars Vietnam - Announcements System

## Mô tả
Resource thông báo cho FiveM sử dụng QBCore framework với giao diện NUI đẹp mắt.

## Tính năng
- Giao diện NUI hiện đại với background và logo tùy chỉnh
- Hỗ trợ nhiều loại thông báo (info, success, warning, error)
- Animation mượt mà với progress bar
- Responsive design cho mọi kích thước màn hình
- Tự động gửi thông báo chào mừng cho người chơi mới
- Command admin để gửi thông báo

## Cài đặt
1. Copy thư mục `xn_thongbao` vào thư mục `resources` của server
2. Thêm `ensure xn_thongbao` vào file `server.cfg`
3. Restart server hoặc dùng `refresh` và `start xn_thongbao`

## Sử dụng

### Commands
- `/testannounce [message]` - Test thông báo với logo mặc định (client)
- `/testlogo [logo_url] [message]` - Test thông báo với logo tùy chỉnh (client)
- `/announce [message]` - Gửi thông báo đến tất cả người chơi (Admin only)
- `/announcelogo [logo_url] [title] [message]` - Gửi thông báo với logo tùy chỉnh (Admin only)

#### Ví dụ Commands:
```bash
# Test thông báo đơn giản
/testannounce Xin chào mọi người!

# Test với logo tùy chỉnh
/testlogo https://example.com/logo.png Thông báo test với logo mới

# Admin gửi thông báo
/announce Server sẽ restart sau 10 phút

# Admin gửi thông báo với logo
/announcelogo https://example.com/event.png "HALLOWEEN EVENT" Sự kiện Halloween bắt đầu!
```

### Exports (Client)
```lua
-- Gửi thông báo từ client
exports['xn_thongbao']:SendAnnouncement(title, message, duration, type, logo)

-- Ví dụ:
exports['xn_thongbao']:SendAnnouncement(
    'THÔNG BÁO QUAN TRỌNG',
    'Server sẽ restart sau 10 phút!',
    10000,
    'warning',
    'https://example.com/custom-logo.png' -- Logo tùy chỉnh (tùy chọn)
)
```

### Exports (Server)
```lua
-- Gửi thông báo đến tất cả người chơi
exports['xn_thongbao']:SendAnnouncementToAll(title, message, duration, type, logo)

-- Gửi thông báo đến người chơi cụ thể
exports['xn_thongbao']:SendAnnouncementToPlayer(playerId, title, message, duration, type, logo)

-- Ví dụ:
exports['xn_thongbao']:SendAnnouncementToAll(
    'ALL STARS VIETNAM',
    'Chào mừng bạn đến với server!',
    8000,
    'success',
    'https://example.com/event-logo.png' -- Logo cho sự kiện đặc biệt
)

-- Ví dụ với logo mặc định (bỏ qua parameter logo):
exports['xn_thongbao']:SendAnnouncementToAll(
    'ALL STARS VIETNAM',
    'Chào mừng bạn đến với server!',
    8000,
    'success'
)
```

### Events
```lua
-- Client Events
TriggerEvent('xn_thongbao:client:showAnnouncement', {
    title = 'Tiêu đề',
    message = 'Nội dung thông báo',
    duration = 5000,
    type = 'info',
    logo = 'https://example.com/custom-logo.png' -- Logo tùy chỉnh (tùy chọn)
})

TriggerEvent('xn_thongbao:client:hideAnnouncement')

-- Server Events
TriggerEvent('xn_thongbao:server:sendToAll', data)
TriggerEvent('xn_thongbao:server:sendToPlayer', playerId, data)
```

## Logo Parameters

### 🎨 **Sử dụng Logo tùy chỉnh:**
- **Parameter:** `logo` (string) - URL của hình ảnh logo
- **Tùy chọn:** Nếu không truyền logo, sẽ sử dụng logo mặc định All Stars Vietnam
- **Format hỗ trợ:** PNG, JPG, SVG, WebP
- **Kích thước đề xuất:** 80x80px hoặc tỷ lệ 1:1

### 📝 **Ví dụ Logo:**
```lua
-- Logo sự kiện Halloween
exports['xn_thongbao']:SendAnnouncementToAll(
    'HALLOWEEN EVENT',
    'Sự kiện Halloween đã bắt đầu!',
    10000,
    'warning',
    'https://yourserver.com/images/halloween-logo.png'
)

-- Logo VIP
exports['xn_thongbao']:SendAnnouncementToPlayer(
    playerId,
    'VIP WELCOME',
    'Chào mừng VIP member!',
    8000,
    'success',
    'https://yourserver.com/images/vip-logo.png'
)
```

## Tùy chỉnh

### Thay đổi logo và background
Chỉnh sửa trong file `html/style.css`:
```css
/* Background */
background-image: url('đường_dẫn_background_mới');

/* Logo trong HTML */
<img src="đường_dẫn_logo_mới" alt="Logo" class="logo">
```

### Thay đổi màu sắc
Chỉnh sửa các biến CSS trong file `html/style.css`:
```css
/* Màu chủ đạo */
background: linear-gradient(135deg, #1a4f3a 0%, #2d7a5f 50%, #1a4f3a 100%);

/* Màu progress bar */
background: linear-gradient(90deg, #4ade80, #22c55e, #16a34a);
```

## Hỗ trợ
- Tác giả: Xuan Nguyen
- Version: 1.0.0
- Framework: QBCore + ox_lib

## Changelog
### v1.0.0
- Phiên bản đầu tiên
- Giao diện NUI hoàn chỉnh
- Hỗ trợ QBCore commands
- Auto welcome message cho người chơi mới
