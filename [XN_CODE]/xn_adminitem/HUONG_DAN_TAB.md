# XN Admin Item - Hệ thống quản lý đa tab

## Tổng quan
Đã mở rộng hệ thống admin item với 5 tab chính:

### 1. 👥 Tab Players
- **Chức năng**: Quản lý toàn bộ người chơi trong server
- **Dữ liệu**: Lấy từ bảng `players` (resource qbx_core)
- **Thông tin hiển thị**:
  - PID (Player ID)
  - Citizen ID
  - Họ và Tên (từ charinfo JSON)
  - Inventory
- **Tính năng**: 
  - Phân trang: 20 players/trang
  - Button "Xem kho đồ" để xem inventory của player
  - Hiển thị items với hình ảnh, số lượng, metadata

### 2. 📦 Tab Items
- **Chức năng**: Tìm kiếm theo tên item (tab gốc)
- **Dữ liệu**: Từ ox_inventory items
- **Tính năng**:
  - Search item theo tên
  - Xem chi tiết item
  - Xóa item khỏi players/vehicles/storage

### 3. 🚗 Tab Vehicles  
- **Chức năng**: Quản lý tất cả xe trong thành phố
- **Dữ liệu**: Lấy từ bảng `player_vehicles`
- **Thông tin hiển thị**:
  - Biển số xe (plate)
  - Citizen ID chủ xe
  - Tên chủ sở hữu (join với bảng players)
- **Tính năng**:
  - Phân trang: 20 vehicles/trang
  - Button "Xem cốp xe" để xem trunk inventory
  - Hiển thị items trong cốp xe

### 4. 🏨 Tab Nhà Trọ
- **Chức năng**: Quản lý các khu nhà trọ
- **Dữ liệu**: Lấy từ bảng `renzu_motels`
- **Cấu trúc dữ liệu**:
  - `motel`: Tên khu nhà trọ
  - `rooms`: JSON array chứa thông tin từng phòng
- **Thông tin phòng**:
  - Số phòng
  - Trạng thái khóa (locked/unlocked)
  - Người thuê (citizenid + tên)
  - Thời hạn thuê (duration)
- **Tính năng**:
  - Click vào motel để expand/collapse danh sách phòng
  - Button "Xem kho đồ" để xem stash phòng
  - Format stash name: `stash_{motelname}_motels_room_{roomNumber}`

### 5. 📂 Tab Kho Khác
- **Chức năng**: Quản lý các kho lưu trữ khác
- **Dữ liệu**: Lấy từ bảng `ox_inventory`
- **Filter**: Loại trừ trunk, glovebox
- **Thông tin hiển thị**:
  - Tên kho (name)
  - Owner (citizenid)
  - Tên chủ sở hữu (join với players)
  - Số lượng items
- **Tính năng**:
  - Phân trang: 20 stashes/trang
  - Button "Xem kho đồ" để xem inventory

## Cấu trúc Code

### Server-side (server/main.lua)
**Callbacks mới:**
- `xn_adminitem:getPlayers` - Lấy danh sách players với pagination
- `xn_adminitem:getPlayerInventory` - Lấy inventory của 1 player
- `xn_adminitem:getVehicles` - Lấy danh sách vehicles
- `xn_adminitem:getVehicleTrunk` - Lấy trunk inventory
- `xn_adminitem:getMotels` - Lấy danh sách motels và rooms
- `xn_adminitem:getMotelRoomInventory` - Lấy stash phòng trọ
- `xn_adminitem:getOtherStashes` - Lấy danh sách stashes
- `xn_adminitem:getStashInventory` - Lấy inventory của stash

### Client-side (client/main.lua)
**NUI Callbacks:**
- `getPlayers`, `getPlayerInventory`
- `getVehicles`, `getVehicleTrunk`
- `getMotels`, `getMotelRoomInventory`
- `getOtherStashes`, `getStashInventory`

**Client Events:**
- `xn_adminitem:playersData`
- `xn_adminitem:playerInventoryData`
- `xn_adminitem:vehiclesData`
- `xn_adminitem:vehicleTrunkData`
- `xn_adminitem:motelsData`
- `xn_adminitem:motelRoomInventoryData`
- `xn_adminitem:otherStashesData`
- `xn_adminitem:stashInventoryData`

### Frontend Components
**Components mới:**
- `PlayerTab.jsx` - Quản lý tab players
- `VehicleTab.jsx` - Quản lý tab vehicles
- `MotelTab.jsx` - Quản lý tab motels
- `OtherStashTab.jsx` - Quản lý tab stashes
- `InventoryView.jsx` - Component dùng chung để hiển thị inventory

**Cập nhật:**
- `App.jsx` - Thêm tab navigation và routing
- `index.css` - Thêm styles cho tabs, tables, inventory view

## Cách sử dụng

1. **Mở UI**: Gõ lệnh `/adminitem` trong game

2. **Chuyển tab**: Click vào các button ở thanh navigation:
   - 👥 Players
   - 📦 Items  
   - 🚗 Vehicles
   - 🏨 Nhà trọ
   - 📂 Kho khác

3. **Xem inventory**: Click button "Xem kho đồ" / "Xem cốp xe"

4. **Phân trang**: Dùng button "« Trước" và "Sau »"

5. **Quay lại**: Click "← Quay lại" khi đang xem inventory

## Database Tables

### players (qbx_core)
```sql
- pid: INT
- citizenid: VARCHAR
- charinfo: JSON (firstname, lastname)
- inventory: JSON
```

### player_vehicles
```sql
- citizenid: VARCHAR
- plate: VARCHAR
- trunk: JSON
```

### renzu_motels
```sql
- motel: VARCHAR
- rooms: JSON Array
  [
    {
      "players": {"citizenid": {"name": "...", "duration": ...}},
      "lock": boolean
    }
  ]
```

### ox_inventory
```sql
- owner: VARCHAR (citizenid)
- name: VARCHAR (stash name)
- data: JSON (inventory items)
```

## Build

Để build lại UI sau khi chỉnh sửa:

```bash
cd web
npm run build
```

## Lưu ý kỹ thuật

1. **Motel stash naming**: 
   - Format: `stash_{motelname}_motels_room_{roomNumber}`
   - Tên motel được lowercase và space thay bằng underscore

2. **Pagination**: 
   - Mặc định 20 items/trang
   - Tự động tính totalPages từ COUNT(*)

3. **Inventory display**:
   - Sử dụng component InventoryView dùng chung
   - Hỗ trợ metadata và item count
   - Tự động load image từ GitHub CDN

4. **Performance**:
   - JOIN tables để lấy tên owner
   - LIMIT/OFFSET cho pagination
   - Filter trong SQL để giảm data transfer

## Troubleshooting

**Q: Không thấy dữ liệu?**
- Kiểm tra bảng database tồn tại
- Kiểm tra server console có lỗi SQL không
- F8 console browser xem có lỗi JS không

**Q: Inventory không hiển thị?**
- Kiểm tra stash name format đúng chưa
- Kiểm tra ox_inventory table có data không

**Q: Build failed?**
- Kiểm tra Node.js đã cài đặt
- Run `npm install` trong folder web
- Kiểm tra syntax errors trong JSX files
