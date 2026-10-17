# 🏪 fivem-stall — Hệ Thống Gian Hàng Player-Owned

Hệ thống gian hàng đầy đủ tính năng cho FiveM (GTA V), tích hợp **ox_inventory**, **ox_target**, **oxmysql**, hỗ trợ cả **QBCore** và **ESX**.

---

## 📦 Phụ thuộc

| Resource      | Bắt buộc | Ghi chú |
|---------------|----------|---------|
| ox_lib        | ✅       | Notify, lib.* |
| ox_target     | ✅       | Tương tác NPC |
| ox_inventory  | ✅       | Quản lý item + ảnh |
| oxmysql       | ✅       | Database |
| qb-core / esx | ✅       | Chọn 1 trong 2 |

---

## ⚡ Cài đặt

### 1. Import database
```sql
-- Chạy trong phpMyAdmin hoặc HeidiSQL:
SOURCE /path/to/fivem-stall/stall_schema.sql;
```

### 2. Cấu hình resource
Chỉnh file `config/config.lua`:
```lua
Config.Framework = 'qb-core'   -- hoặc 'esx'
Config.TaxRate   = 2           -- % thuế khi mua
Config.MaxStalls = 3           -- Giới hạn gian hàng / người
Config.MaxRentHours = 24       -- Thuê tối đa 24 giờ
```

### 3. Thêm vị trí gian hàng
```lua
Config.Stalls = {
    [1] = {
        id          = 1,
        label       = 'Stall #1',
        rentPrice   = 1000,          -- $/giờ
        npcModel    = 'a_m_m_skater_01',
        npcCoords   = vector4(213.5, -810.2, 30.7, 180.0),
        targetRadius = 2.0,
    },
    -- Thêm stall tiếp theo...
}
```

### 4. Thêm vào server.cfg
```
ensure fivem-stall
```

---

## 🏗️ Cấu trúc thư mục

```
fivem-stall/
├── config/
│   └── config.lua          ← Cấu hình chính
├── client/
│   └── main.lua            ← Logic client (NPC, NUI, events)
├── server/
│   └── main.lua            ← Logic server (DB, transactions, security)
├── html/
│   ├── index.html          ← Giao diện NUI
│   ├── css/style.css       ← Dark gaming theme
│   └── js/app.js           ← UI logic
├── stall_schema.sql        ← SQL tables
└── fxmanifest.lua
```

---

## 🎮 Tính năng

### Người mua (Khách)
- Xem danh sách item với ảnh từ `ox_inventory`
- Tìm kiếm item realtime
- Popup mua hàng với tính thuế tự động
- Đếm ngược thời gian gian hàng còn lại

### Chủ gian hàng
- Thuê gian hàng qua NPC (ox_target)
- Đưa item từ túi đồ lên bán, đặt giá tùy ý
- Thu hồi item về túi bất cứ lúc nào
- Xem thu nhập realtime, nhận tiền vào tài khoản ngân hàng
- Xem lịch sử giao dịch
- Nhận thông báo khi có người mua (dù không mở UI)

### Hệ thống
- Độ hiếm item: common → uncommon → rare → epic → legendary (màu viền + glow)
- Đếm ngược thời gian thuê cập nhật mỗi giây
- Khi hết hạn: vật phẩm vẫn được giữ nguyên trong gian hàng (không bị xóa), thông báo cho chủ thuê biết để thuê lại/gia hạn và lấy lại vật phẩm
- Giới hạn số gian hàng tối đa / người chơi
- Validate server-side cho mọi giao dịch
- Đồng bộ state realtime tất cả players

---

## 🔒 Bảo mật
- Mọi logic quan trọng (trừ tiền, cấp item) xử lý **server-side**
- Client chỉ gửi request, server validate lại tất cả
- Kiểm tra quyền sở hữu trước mọi thao tác quản lý
- Kiểm tra số dư trước khi trừ tiền

---

## 🎨 UI Theme
Dark Gaming / Night Market — nền tối `#0d0f14`, accent xanh lá `#4ade80`, hỗ trợ rarity glow effects.

Ảnh item tải từ `ox_inventory/web/images/{item_name}.png` với fallback emoji khi không có ảnh.

---

## 📝 Config mẫu thêm item rarity
```lua
Config.ItemRarity = {
    bread       = 'common',
    water       = 'common',
    phone       = 'uncommon',
    lockpick    = 'rare',
    weapon_pistol = 'epic',
    weapon_rpg  = 'legendary',
}
```

---

## 🐛 Troubleshooting

**NPC không xuất hiện**
→ Kiểm tra `npcModel` có tồn tại, thêm vào `fxmanifest.lua` nếu cần stream model custom.

**Ảnh item không load**
→ Đảm bảo `ox_inventory` đang chạy và path `cfx-nui-ox_inventory` đúng.

**Database error**
→ Chạy `stall_schema.sql` trước, kiểm tra `oxmysql` connect database.

**ox_target không hiện option**
→ Kiểm tra player có trong `targetRadius` của NPC không.
