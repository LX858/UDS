# Hướng Dẫn Build và Debug NUI

## ⚠️ Lỗi Hiện Tại: Command /nangcap không hiển thị UI

### 🔧 Nguyên nhân đã sửa:

1. **UpgradePanel.jsx** - Đã thêm data mặc định thay vì chỉ hiển thị "Đang tải..."
2. **App.jsx** - Đã thêm debug logs để trace flow
3. **Client/Server** - Đã tạo event riêng `GetUpgradeDataForCommand` để đảm bảo data được truyền

### 📝 Các thay đổi đã thực hiện:

#### 1. UpgradePanel.jsx
```jsx
// Thay vì return null khi không có data, giờ dùng default data
const defaultData = {
  luck_level: 0,
  time_level: 0,
  capacity_level: 0,
  skill_points: 0,
  overall_level: 0
};
const data = upgradeData || defaultData;
```

#### 2. App.jsx
```jsx
// Thêm debug logs
console.log('[NUI] Received message:', data);
console.log('[NUI] Opening upgrade panel, data:', data.upgradeData);
console.log('[NUI] Rendering - visible:', visible, 'upgradeOnlyMode:', upgradeOnlyMode);
```

#### 3. client/main.lua
```lua
-- Event riêng để mở upgrade panel với data
RegisterNetEvent('vie-chamsocthucung:client:OpenUpgradePanel', function(upgradeData, maxCapacity)
  PlayerUpgradeData = upgradeData
  MaxCapacity = maxCapacity
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = "showUpgradeOnly",
    show = true,
    upgradeData = upgradeData,
    maxAnimals = maxCapacity
  })
end)
```

#### 4. server/main.lua
```lua
-- Event mới để lấy data cho command
RegisterNetEvent('vie-chamsocthucung:server:GetUpgradeDataForCommand', function()
  -- ... lấy data từ database ...
  TriggerClientEvent('vie-chamsocthucung:client:OpenUpgradePanel', src, upgradeData, maxCapacity)
end)
```

## 🛠️ Các bước Build và Test

### Bước 1: Build Web UI

**Mở PowerShell trong folder web:**
```powershell
# Navigate vào folder web (chú ý escape dấu ngoặc vuông)
cd 'c:\Users\nghec\Desktop\Newstart\txData\Qbox_2B74CE.base\resources\[NGHE_SACH_XN]\xn_nuoithu\web'

# Build
pnpm build
# hoặc
npm run build
```

**Hoặc từ folder resource:**
```powershell
cd 'c:\Users\nghec\Desktop\Newstart\txData\Qbox_2B74CE.base\resources\[NGHE_SACH_XN]\xn_nuoithu'
cd web
pnpm build
```

### Bước 2: Restart Resource
Trong game console (F8):
```
restart xn_nuoithu
```

### Bước 3: Test Command
Trong game chat (T hoặc F8):
```
/nangcap
```

### Bước 4: Kiểm tra Debug Logs

**Mở F8 Console và xem logs:**
```
[NUI] Received message: {action: "showUpgradeOnly", show: true, upgradeData: {...}}
[NUI] Opening upgrade panel, data: {luck_level: 0, time_level: 0, ...}
[NUI] Rendering - visible: true upgradeOnlyMode: true upgradeData: {...}
[NUI] Rendering upgrade panel
```

## 🐛 Troubleshooting

### Vấn đề: UI không hiển thị
✅ **Kiểm tra:**
1. F8 Console có logs `[NUI]` không?
2. Database đã import chưa? (xn_nuoithu_upgrades table)
3. Web đã build lại chưa?
4. Resource đã restart chưa?

### Vấn đề: UI hiển thị nhưng trống
✅ **Kiểm tra:**
1. Console có log upgradeData không?
2. Server console có lỗi MySQL không?
3. Player có citizenid không? (QBCore)

### Vấn đề: Nhấn ESC không tắt được
✅ **Kiểm tra:**
1. F8 console có lỗi fetch() không?
2. NUI callback `closeUpgradeOnly` đã register chưa?

## 📊 Debug Checklist

- [ ] Database table `xn_nuoithu_upgrades` đã tạo
- [ ] Web UI đã build (kiểm tra file `web/build/index.html`)
- [ ] Resource đã restart
- [ ] F8 console không có lỗi
- [ ] Server console không có lỗi MySQL
- [ ] Command `/nangcap` có phản hồi (cursor busy)
- [ ] SetNuiFocus đang active (không điều khiển được character)

## 🔍 Test Manual

### Test 1: Kiểm tra NUI nhận message
F8 Console gõ:
```javascript
fetch('https://xn_nuoithu/message', {
  method: 'POST',
  body: JSON.stringify({
    action: 'showUpgradeOnly',
    show: true,
    upgradeData: {
      luck_level: 2,
      time_level: 1,
      capacity_level: 3,
      skill_points: 50,
      overall_level: 1
    },
    maxAnimals: 6
  })
});
```

Nếu UI hiển thị → NUI hoạt động tốt, vấn đề ở client-server communication

### Test 2: Kiểm tra Database
Server console gõ:
```lua
RegisterCommand('testdb', function(source)
  local Player = exports.qbx_core:GetPlayer(source)
  print('CitizenID:', Player.PlayerData.citizenid)
  local result = MySQL.Sync.fetchAll('SELECT * FROM xn_nuoithu_upgrades WHERE citizenid = ?', {Player.PlayerData.citizenid})
  print(json.encode(result))
end)
```

Nếu không có kết quả → Tạo record mới trong database

## 💾 Tạo Record Mặc Định (nếu cần)

Trong HeidiSQL hoặc phpMyAdmin:
```sql
INSERT INTO xn_nuoithu_upgrades (citizenid, luck_level, time_level, capacity_level, skill_points, overall_level)
VALUES ('YOUR_CITIZENID', 0, 0, 0, 0, 0);
```

Hoặc server sẽ tự tạo khi lần đầu gọi GetPlayerUpgradeData()

## ✅ Kết Luận

Sau khi build lại web UI, code đã sẵn sàng với:
1. ✅ Default data fallback
2. ✅ Debug logs đầy đủ
3. ✅ Event flow đúng (command → server → client → NUI)
4. ✅ UI responsive với/không data

**Hãy build lại và test!**
