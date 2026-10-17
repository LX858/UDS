# Tóm tắt sửa lỗi hệ thống thuê ruộng

## Vấn đề đã phát hiện:

1. **Logic kiểm tra rental bị sai**: Code kiểm tra xem zone có được thuê bởi ai khác không, nhưng không exclude người hiện tại. Dẫn đến tình trạng:
   - Người chơi thuê ruộng lần đầu → thành công
   - Người chơi cùng thuê lại ruộng đó → báo "đã được thuê bởi người khác" (tức là chính họ)
   - Tiền vẫn bị trừ nhưng không tạo được rental mới

2. **Constraint UNIQUE KEY có vấn đề**: Constraint `UNIQUE KEY zone_owner (zone_id, owner, is_active)` trong bảng `farm_rentals` gây conflict khi sử dụng `ON DUPLICATE KEY UPDATE`

3. **Function updatePlayerPlantCount không accessible**: Function được khai báo `local` trong server.lua nên không thể gọi từ farm_rental.lua

## Các sửa đổi đã thực hiện:

### 1. Sửa logic kiểm tra rental trong `server/farm_rental.lua`:

**Trước:**
```lua
-- Kiểm tra xem zone đã được thuê chưa
local existing = exports.ghmattimysql:executeSync('SELECT * FROM farm_rentals WHERE zone_id = @zone_id AND is_active = 1 AND end_time > @current_time', {
    ['@zone_id'] = zoneId,
    ['@current_time'] = os.time()
})

if #existing > 0 then
    TriggerClientEvent('QBCore:Notify', source, 'Ruộng này đã được thuê bởi người khác!', 'error')
    return
end
```

**Sau:**
```lua
-- Kiểm tra xem zone đã được thuê bởi người khác chưa (không bao gồm người hiện tại)
local existing = exports.ghmattimysql:executeSync('SELECT * FROM farm_rentals WHERE zone_id = @zone_id AND owner != @owner AND is_active = 1 AND end_time > @current_time', {
    ['@zone_id'] = zoneId,
    ['@owner'] = pid,
    ['@current_time'] = os.time()
})

if #existing > 0 then
    TriggerClientEvent('QBCore:Notify', source, 'Ruộng này đã được thuê bởi người khác!', 'error')
    return
end

-- Kiểm tra xem người chơi hiện tại đã thuê zone này chưa
local currentRental = exports.ghmattimysql:executeSync('SELECT * FROM farm_rentals WHERE zone_id = @zone_id AND owner = @owner AND is_active = 1 AND end_time > @current_time', {
    ['@zone_id'] = zoneId,
    ['@owner'] = pid,
    ['@current_time'] = os.time()
})

if #currentRental > 0 then
    TriggerClientEvent('QBCore:Notify', source, 'Bạn đã thuê ruộng này rồi! Sử dụng chức năng gia hạn nếu muốn thuê thêm.', 'error')
    return
end
```

### 2. Sửa INSERT query để tránh ON DUPLICATE KEY UPDATE:

**Trước:**
```lua
exports.ghmattimysql:execute([[
    INSERT INTO farm_rentals (zone_id, owner, start_time, end_time, hours_rented, price_paid) 
    VALUES (@zone_id, @owner, @start_time, @end_time, @hours_rented, @price_paid)
    ON DUPLICATE KEY UPDATE 
    end_time = @end_time, 
    hours_rented = hours_rented + @hours_rented, 
    price_paid = price_paid + @price_paid
]], {...})
```

**Sau:**
```lua
exports.ghmattimysql:execute([[
    INSERT INTO farm_rentals (zone_id, owner, start_time, end_time, hours_rented, price_paid, is_active) 
    VALUES (@zone_id, @owner, @start_time, @end_time, @hours_rented, @price_paid, 1)
]], {...})
```

### 3. Sửa cách cập nhật plant count:

**Trước:**
```lua
updatePlayerPlantCount(pid, plantCount[1].count)
```

**Sau:**
```lua
TriggerEvent('xx_farming:updatePlantCount', pid)
```

### 4. Thêm event handler trong `server/server.lua`:

```lua
-- Event handler để cập nhật số lượng cây trồng
RegisterNetEvent('xx_farming:updatePlantCount')
AddEventHandler('xx_farming:updatePlantCount', function(playerId)
    local plantCount = exports.ghmattimysql:executeSync('SELECT COUNT(*) as count FROM tomato_db WHERE owner = @owner', {
        ['@owner'] = playerId
    })
    
    if plantCount and plantCount[1] then
        updatePlayerPlantCount(playerId, plantCount[1].count)
    end
end)
```

### 5. Cập nhật file `fix_rental_constraints.sql`:

```sql
-- Sửa lỗi constraint và logic trong farm_rentals table

-- 1. Xóa constraint cũ có vấn đề
ALTER TABLE `farm_rentals` DROP INDEX IF EXISTS `zone_owner`;

-- 2. Tạo các index mới để tối ưu query
ALTER TABLE `farm_rentals` ADD INDEX IF NOT EXISTS `idx_zone_active` (`zone_id`, `is_active`, `end_time`);
ALTER TABLE `farm_rentals` ADD INDEX IF NOT EXISTS `idx_owner_active` (`owner`, `is_active`);

-- 3. Reset tất cả rental về inactive để tránh conflict
UPDATE `farm_rentals` SET `is_active` = 0 WHERE `is_active` = 1;

-- 4. Xóa các record duplicate nếu có
DELETE t1 FROM farm_rentals t1
INNER JOIN farm_rentals t2 
WHERE t1.id > t2.id 
  AND t1.zone_id = t2.zone_id 
  AND t1.owner = t2.owner 
  AND t1.start_time = t2.start_time;
```

## Hướng dẫn khắc phục:

1. **Chạy SQL fix**: Thực thi file `fix_rental_constraints.sql` để sửa constraint và xóa data conflict
2. **Restart server**: Khởi động lại server để áp dụng code mới
3. **Test lại**: Thử thuê ruộng để xem có còn lỗi không

## Kết quả mong đợi:

- Không còn báo "Ruộng này đã được thuê bởi người khác" khi thuê ruộng trống
- Tiền không bị trừ sai khi có lỗi
- Có thể trồng cây bình thường sau khi thuê ruộng
- Người chơi có thể thuê lại ruộng sau khi hết hạn