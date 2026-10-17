# 🔧 FIX: Sửa lỗi không lưu PID khi giam xe

## ❌ Vấn đề
- Khi giam xe, cột `officer_pid` và `owner_pid` trong database không được lưu
- Dữ liệu hiển thị "PID: -" hoặc "PID: 0" trên giao diện web
- Không thể tìm kiếm xe giam theo PID

## ✅ Giải pháp đã thực hiện

### 1. **Sửa Server Code** ([server/vehicle_impound.lua](server/vehicle_impound.lua))
   - ✅ Thêm query để lấy `officer_pid` từ database (nếu client không gửi hoặc gửi 0)
   - ✅ Đã có query lấy `owner_pid` từ database
   - ✅ Sửa INSERT query để thêm các trường:
     - `officer_citizenid`
     - `officer_name`
     - `officer_pid` ← **MỚI**
     - `owner_citizenid`
     - `owner_name`
     - `owner_pid` ← **MỚI**
     - `vehicle_plate`
     - `vehicle_model`
     - `offence`
     - `fine_amount`
     - `duration_until`
     - `status`
   - ✅ Sửa tên cột từ `impounded_at` → `impound_date` trong query
   - ✅ Thêm log debug để hiển thị PID khi giam xe

### 2. **Kiểm tra Client Code** ([client/vehicle_actions.lua](client/vehicle_actions.lua))
   - ✅ Client đã gửi `officer_pid` từ `PlayerData.pid`
   - ✅ Nếu `PlayerData.pid` là nil, server sẽ tự động query từ database

### 3. **Kiểm tra Web UI** ([web/script.js](web/script.js))
   - ✅ Web đã hiển thị đúng `owner_pid` và `officer_pid`
   - ✅ Code render tại dòng 2889-2890 đã đúng

### 4. **Database Schema** ([vehicle_impound.sql](vehicle_impound.sql))
   - ✅ Schema đã có sẵn cột `officer_pid` và `owner_pid`
   - ✅ Có index cho tìm kiếm nhanh

## 📋 Hướng dẫn cập nhật

### Bước 1: Backup Database
```sql
-- Backup bảng trước khi sửa (an toàn hơn)
CREATE TABLE mini_mdt_vehicle_impound_backup AS 
SELECT * FROM mini_mdt_vehicle_impound;
```

### Bước 2: Chạy SQL Update
```bash
# Import file DATABASE_UPDATE_FIX_PID.sql vào database của bạn
```

Hoặc chạy trực tiếp:
```sql
-- Thêm cột nếu chưa có
ALTER TABLE `mini_mdt_vehicle_impound`
ADD COLUMN IF NOT EXISTS `officer_pid` INT(11) DEFAULT 0 AFTER `officer_name`,
ADD COLUMN IF NOT EXISTS `owner_pid` INT(11) DEFAULT 0 AFTER `owner_name`;

-- Cập nhật PID cho dữ liệu cũ
UPDATE `mini_mdt_vehicle_impound` vi
JOIN `players` p ON vi.officer_citizenid = p.citizenid
SET vi.officer_pid = p.pid
WHERE vi.officer_pid = 0 OR vi.officer_pid IS NULL;

UPDATE `mini_mdt_vehicle_impound` vi
JOIN `players` p ON vi.owner_citizenid = p.citizenid
SET vi.owner_pid = p.pid
WHERE vi.owner_pid = 0 OR vi.owner_pid IS NULL;
```

### Bước 3: Restart Resource
```bash
restart mini-mdt
```

## 🧪 Kiểm tra

1. Giam một xe mới
2. Kiểm tra console server xem log có hiển thị PID không:
   ```
   [MINI-MDT] Xe ABC123 đã bị giam bởi John Doe (PID: 12345) | Chủ xe: Jane Smith (PID: 67890)
   ```
3. Mở MDT → Tab "Quản Lý Xe Tạm Giam"
4. Kiểm tra xem cột "Chủ xe" và "Cảnh sát" có hiển thị PID không

## 📝 Các file đã sửa
- ✅ [server/vehicle_impound.lua](server/vehicle_impound.lua)
- ✅ [DATABASE_UPDATE_FIX_PID.sql](DATABASE_UPDATE_FIX_PID.sql) (mới)

## 🔍 Debug

Nếu vẫn không lưu PID, kiểm tra:

1. **Bảng `players` có cột `pid` không?**
   ```sql
   SHOW COLUMNS FROM players LIKE 'pid';
   ```

2. **Giá trị PID trong bảng players có đúng không?**
   ```sql
   SELECT citizenid, pid FROM players LIMIT 10;
   ```

3. **Check console log khi giam xe** - xem có query lỗi không?

---

**Ngày sửa:** 2026-03-12  
**Người sửa:** GitHub Copilot
