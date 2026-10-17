# GIN Trói Tay (`gin_troitay`)

Resource trói tay và cởi trói tùy biến cao cho FiveM server sử dụng hệ sinh thái `ox_lib`, `ox_inventory`, và `ox_target`.

---

## 🛠️ Tính Năng Nổi Bật

1. **Trói người chơi khác (`ox_target`)**:
   - Khi có `day_thung` hoặc `day_cuoc` trong túi đồ, nhắm `ox_target` vào người chơi khác để thực hiện trói.
   - Khi trói sẽ kích hoạt **minigame `ox_lib` (skillCheck)**. Thành công mới trói được.

2. **Quy Định 2 Loại Dây**:
   - 🧵 **`day_cuoc` (Dây cước)**: Người bị trói **cho phép chạy**, nhưng **KHÔNG cho phép nhảy** (bị khóa phím Jump).
   - 🪢 **`day_thung` (Dây thừng)**: Người bị trói **cho phép chạy** và **cho phép nhảy** bình thường.

3. **Tháo Trói / Cắt Trói**:
   - 🔪 **Bản thân tự cởi trói**:
     - Người bị trói mở `ox_inventory` và **sử dụng `dao_cat`**.
     - Bắt buộc phải **chạy minigame `ox_lib`**. Nếu vượt qua minigame mới cởi trói thành công.
   - ✂️ **Người chơi khác cắt trói giúp**:
     - Người chơi khác cầm `dao_cat` nhắm `ox_target` vào người đang bị trói và chọn "Cắt dây trói".
     - **KHÔNG cần minigame** (chạy thanh tiến trình cắt dây ngắn để giải cứu ngay).

---

## 📦 1. Cấu hình Items trong `ox_inventory`

Thêm 3 items sau vào file `ox_inventory/data/items.lua`:

```lua
['day_thung'] = {
    label = 'Dây Thừng',
    weight = 200,
    stack = true,
    close = true,
    description = 'Dây thừng chắc chắn dùng để trói tay (Cho phép chạy và nhảy).'
},

['day_cuoc'] = {
    label = 'Dây Cước',
    weight = 50,
    stack = true,
    close = true,
    description = 'Dây cước mảnh dùng để trói tay (Cho phép chạy, không cho nhảy).'
},

['dao_cat'] = {
    label = 'Dao Cắt Dây',
    weight = 150,
    stack = true,
    close = true,
    description = 'Con dao nhỏ dùng để cắt dây thừng/dây cước cởi trói.',
    client = {
        event = 'gin_troitay:client:useDaoCat'
    }
}
```

---

## ⚙️ 2. Cài Đặt và Kích Hoạt

1. Đặt thư mục `gin_troitay` vào thư mục `resources/[GIN]/` hoặc `resources/`.
2. Đảm bảo các dependency đã được start trước trong `server.cfg`:
```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure gin_troitay
```

---

## 🔧 3. Cấu hình Tùy Chỉnh (`config.lua`) & Lưu Trữ

- `Config.DebugDisableMinigame`: Đặt `true` để tắt minigame giúp test nhanh.
- `Config.RopeLoseChance`: Tỷ lệ % mất dây khi trói thành công (vd: 50 = 50% mất dây, 50% còn).
- `Config.KnifeLoseChance`: Tỷ lệ % mất dao cắt khi tháo trói (vd: 50 = 50% mất dao, 50% còn).
- `Config.TieDuration`: Thời gian thanh tiến trình trói (ms).
- `Config.CutRopeDuration`: Thời gian thanh tiến trình cắt dây khi giải cứu (ms).

### 💾 File Lưu Trữ Bảo Tồn Trạng Thái Bị Trói
- Dữ liệu những người chơi đang bị trói được tự động lưu bền vững tại:
  [`gin_troitay/data/tied_players.json`](file:///d:/SeverGta/Understar/server/resources/[GIN]/gin_troitay/data/tied_players.json)
- Khi ai đó bị trói, thông tin `isTied` và `ropeType` sẽ được ghi vào file này. Khi họ thoát game (out server) và kết nối lại, server sẽ tự động đọc từ file này để trói lại họ.
