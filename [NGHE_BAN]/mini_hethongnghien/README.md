# F7 Lá Đu Đủ - Hệ Thống Nghiện 🚬

## Tính Năng

- ✅ **Nghiện tự động**: Khi dùng item `dieududu` sẽ bị nghiện ngay
- ⏱️ **Cai nghiện tự nhiên**: Quá 2 giờ không dùng → Triệu chứng cai nghiện
- 🏥 **NPC Cai nghiện**: Tại Pillbox Hospital - Phí $10,000
- 💊 **Triệu chứng**: Ngã lăn, màn hình chập chờn, mất máu, ngứa người
- 💾 **Persistent**: Lưu vào database, logout/login vẫn nhớ

---

## Cài Đặt

### 1. Thêm vào `server.cfg`:
```cfg
ensure F7_ladudu_addiction
```

### 2. Kiểm tra item name trong `config.lua`:
```lua
Config.AddictiveItem = 'dieududu' -- Hoặc 'dieu_ladudu'
```
**Phải khớp với item trong ox_inventory!**

### 3. Restart server

---

## Cách Hoạt Động

### Khi Dùng Item
1. Player dùng `dieududu`
2. Hiệu ứng ảo giác 15 giây
3. Hồi 50 HP
4. **Bị nghiện ngay lập tức**
5. Bắt đầu đếm ngược 2 giờ

### Khi Quá 2 Giờ Không Dùng
Player sẽ bị các triệu chứng:
- 🤕 Ngã lăn ngẫu nhiên (30% mỗi phút)
- 👁️ Màn hình chập chờn
- ❤️ Mất 2 HP mỗi phút (tối thiểu 20 HP)
- 😰 Animation ngứa người

### Cách Cai Nghiện
1. Đến **Pillbox Hospital** (có blip màu xanh lá)
2. Target NPC bác sĩ
3. Chọn "Cai Nghiện ($10,000)"
4. Làm minigame skillcheck
5. Chờ 5 phút điều trị
6. ✅ Hoàn thành → Hết nghiện!

---

## Config Chính

```lua
-- Thời gian cai (giây)
withdrawalTimeSeconds = 7200  -- 2 giờ

-- Phí cai nghiện
cost = 10000  -- $10,000

-- Vị trí NPC (Pillbox Hospital)
npcCoords = vector4(307.85, -595.35, 43.28, 248.5)

-- Triệu chứng
ragdollChance = 30           -- 30% ngã mỗi phút
healthDrain = 2              -- Mất 2 HP/phút
screenFlickerInterval = 10000 -- Chập chờn mỗi 10s
```

---

## Debug Commands (Config.Debug = true)

```
/checkaddiction   - Xem trạng thái nghiện
/resetaddiction   - Reset nghiện (admin)
```

---

## Yêu Cầu

- ✅ QBX Core
- ✅ ox_lib
- ✅ ox_inventory
- ✅ ox_target

---

## Lưu Ý

⚠️ **Người chưa dùng = KHÔNG bị ảnh hưởng**
⚠️ Dữ liệu lưu vào `players.metadata.ladudu_addiction`
⚠️ Có thể chỉnh config mọi thứ trong [config.lua](config.lua)

---

## Hỗ Trợ

Discord: F7 Scripts Community
Version: 1.0.0
