# HỆ THỐNG NÂNG CẤP - NGHỀ NUÔI THÚ

## 📋 Tính Năng Mới

### 1. Hệ Thống Level
- **Tối đa 5 Level** với biểu tượng thay đổi theo cấp độ:
  - Level 0-1: 🐷 Heo
  - Level 2-3: 🐄 Bò  
  - Level 4-5: 🦙 Alpaca
- Vòng tròn tiến trình hiển thị mốc level hiện tại
- Level tổng chỉ tăng khi CẢ 3 chỉ số đạt cùng level

### 2. Điểm Kỹ Năng
Nhận điểm kỹ năng khi thu hoạch động vật:
- 🐷 Heo: **5 điểm**
- 🐄 Bò: **10 điểm**
- 🦙 Alpaca: **15 điểm**

### 3. Ba Chỉ Số Nâng Cấp

#### 📊 May Mắn
- **Hiệu ứng**: Mỗi cấp tăng **1%** tỷ lệ spawn Bò và Alpaca
- **Tối đa**: Level 5 (+5% tổng)

#### ⏱️ Thời Gian  
- **Hiệu ứng**: Mỗi cấp giảm **1 phút** thời gian trưởng thành của Bò và Alpaca
- **Tối đa**: Level 5 (-5 phút tổng)
- **Lưu ý**: Không áp dụng cho Heo

#### 📦 Sức Chứa
- **Hiệu ứng**: Mỗi cấp tăng **1 slot** chăm sóc
- **Mặc định**: 5 slots
- **Tối đa**: 10 slots (Level 5)

### 4. Yêu Cầu Nâng Cấp

| Mốc | Vật Phẩm | Số Lượng | Điểm KN | Tỷ Lệ Thành Công |
|-----|----------|----------|---------|------------------|
| 0→1 | phoinangcap1 | 2 | 5 | 80% |
| 1→2 | phoinangcap2 | 2 | 10 | 50% |
| 2→3 | phoinangcap3 | 2 | 15 | 30% |
| 3→4 | phoinangcap4 | 2 | 20 | 10% |
| 4→5 | phoinangcap5 | 2 | 25 | 5% |

**⚠️ LƯU Ý**: 
- Nâng cấp **THẤT BẠI** sẽ **MẤT** vật phẩm và điểm kỹ năng
- Chọn chỉ số cần nâng bằng cách nhấn nút **LEVEL** màu đỏ

## 🔧 Cài Đặt

### Bước 1: Chạy Database
```sql
-- Import file database.sql vào MySQL
-- Hoặc chạy lệnh sau:

CREATE TABLE IF NOT EXISTS `xn_nuoithu_upgrades` (
  `citizenid` varchar(50) NOT NULL,
  `luck_level` int(11) NOT NULL DEFAULT 0,
  `time_level` int(11) NOT NULL DEFAULT 0,
  `capacity_level` int(11) NOT NULL DEFAULT 0,
  `skill_points` int(11) NOT NULL DEFAULT 0,
  `overall_level` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Bước 2: Thêm Items vào ox_inventory
Copy các items trong file `items_ox_inventory.lua` vào:
```
ox_inventory/data/items.lua
```

Hoặc thêm trực tiếp:
```lua
-- Phi nâng cấp
['phoinangcap1'] = {...},
['phoinangcap2'] = {...},
['phoinangcap3'] = {...},
['phoinangcap4'] = {...},
['phoinangcap5'] = {...},
```

### Bước 3: Build lại Web UI
```bash
cd web
pnpm install  # hoặc npm install
pnpm build    # hoặc npm run build
```

### Bước 4: Restart Resource
```
restart xn_nuoithu
```

## 🎮 Hướng Dẫn Sử Dụng

### Mở Giao Diện Nâng Cấp
1. Vào khu vực chăm sóc thú cưng
2. Nhấn nút **"⭐ NÂNG CẤP"** trên giao diện

### Nâng Cấp Chỉ Số
1. Nhấn vào nút **LEVEL** màu đỏ bên cạnh chỉ số muốn nâng
2. Kiểm tra yêu cầu trong phần **THÔNG TIN NÂNG CẤP**
3. Nhấn nút **NÂN CẤP** để tiến hành
4. Chờ kết quả (thành công/thất bại)

### Tăng Level Tổng
- Phải nâng **CẢ 3** chỉ số lên cùng level
- Ví dụ: May mắn Lv3, Thời gian Lv3, Sức chứa Lv3 → **Level tổng = 3**

## 📝 Ghi Chú Kỹ Thuật

### Files Đã Thay Đổi
- ✅ `Config.lua` - Thêm cấu hình nâng cấp
- ✅ `server/main.lua` - Logic xử lý nâng cấp server-side
- ✅ `client/main.lua` - Áp dụng buff và giao tiếp UI
- ✅ `web/src/App.jsx` - Quản lý state upgrade data
- ✅ `web/src/components/AnimalUI.jsx` - Toggle giữa view động vật và nâng cấp
- ✅ `web/src/components/UpgradePanel.jsx` - **MỚI** - UI nâng cấp
- ✅ `web/src/App.css` - Styling cho upgrade panel
- ✅ `database.sql` - **MỚI** - Schema database
- ✅ `items_ox_inventory.lua` - Thêm 5 loại phi nâng cấp

### Callbacks NUI
```javascript
// Nâng cấp chỉ số
fetch('https://xn_nuoithu/upgradeStat', {
  method: 'POST',
  body: JSON.stringify({ statType: 'luck' | 'time' | 'capacity' })
});
```

### Server Events
```lua
-- Client → Server
TriggerServerEvent('vie-chamsocthucung:server:GetUpgradeData')
TriggerServerEvent('vie-chamsocthucung:server:UpgradeStat', statType)

-- Server → Client  
TriggerClientEvent('vie-chamsocthucung:client:ReceiveUpgradeData', src, upgradeData, maxCapacity)
```

## 🐛 Xử Lý Lỗi

### Lỗi: "Không tìm thấy bảng xn_nuoithu_upgrades"
➡️ Chưa import database, chạy file `database.sql`

### Lỗi: "Không đủ vật phẩm"
➡️ Cần có đủ phi nâng cấp và điểm kỹ năng trong inventory

### UI không hiển thị upgrade data
➡️ Kiểm tra console F8, có thể cần build lại web UI

### Buff không áp dụng
➡️ Thử disconnect/reconnect để reload dữ liệu từ database

## 📊 Công Thức Tính Toán

### Buff May Mắn
```lua
-- Tỷ lệ spawn có buff
Bò: 14% + luck_level%
Alpaca: 1% + luck_level%
```

### Buff Thời Gian
```lua
-- Thời gian trưởng thành sau buff
newGrowTime = originalGrowTime - (time_level * 60000) -- 60000ms = 1 phút
minimum = 60000 -- Tối thiểu 1 phút
```

### Sức Chứa
```lua
maxCapacity = 5 + capacity_level
-- Tối đa: 5 + 5 = 10 slots
```

## 💡 Tips

- 🎯 Ưu tiên nâng **Sức Chứa** trước để nuôi nhiều động vật hơn
- ⏰ **Thời Gian** giúp farm nhanh hơn cho Bò/Alpaca
- 🍀 **May Mắn** tăng cơ hội nhận động vật hiếm
- 💰 Giữ điểm kỹ năng cho các lần nâng cấp quan trọng
- 🎲 Lưu phi nâng cấp cao cấp (IV, V) vì tỷ lệ thấp

## 📞 Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
1. Server console có lỗi MySQL không?
2. F8 client console có lỗi NUI không?
3. Database đã import chưa?
4. Items đã thêm vào ox_inventory chưa?
5. Web UI đã build lại chưa?

---
**Phiên bản**: 2.0.0  
**Tác giả**: VIE-TEAM  
**Chỉnh sửa**: VIRP-DEV
