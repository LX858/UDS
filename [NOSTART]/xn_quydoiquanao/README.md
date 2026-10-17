# Clothes Exchange - FiveM Resource

Resource FiveM cho phép người chơi trao đổi item quần áo cùng loại và cùng độ hiếm.

## Tính năng

- ✅ Trao đổi item quần áo cùng loại và cùng độ hiếm
- ✅ Vị trí cố định với DrawText3D + phím E
- ✅ Hỗ trợ command `/doiquanao` mở bất kỳ đâu
- ✅ UI React Vite hiện đại, NoPixel gaming style
- ✅ Glass morphism, smooth animations
- ✅ Tích hợp XNClothes export
- ✅ Server-side validation chặt chẽ
- ✅ Anti-spam cooldown
- ✅ Hỗ trợ ox_inventory và qbx_core

## Yêu cầu

- qbx_core / qbox
- ox_lib
- ox_inventory
- XNClothes

## Cài đặt

### 1. Clone hoặc copy resource vào thư mục resources

```
resources/
└── [XN_CODE2]/
    └── xn_quydoiquanao/
```

### 2. Build NUI (React Vite)

```bash
cd web
npm install
npm run build
```

Sau khi build xong, thư mục `web/dist` sẽ chứa file đã build.

### 3. Thêm vào server.cfg

```cfg
ensure xn_quydoiquanao
```

### 4. Cấu hình

Mở file `shared/config.lua` và điều chỉnh:

- **Config.Location**: Vị trí mở shop (set `nil` nếu chỉ dùng command)
  - `coords`: Tọa độ vec3
  - `distance`: Khoảng cách hiển thị text
  - `text`: Text hiển thị
  - `marker.enabled`: Bật/tắt marker
- **Config.Dohiem**: Thêm đầy đủ drawable ID cho từng loại quần áo, giới tính, và độ hiếm
- **Config.Command**: Đổi command mở UI (mặc định: `/doiquanao`)
- **Config.ExchangeCooldown**: Thời gian cooldown giữa các lần đổi (milliseconds)
- **Config.Url**: URL ảnh quần áo
- **Config.Extension**: Extension ảnh (webp, png, jpg...)

## Sử dụng

### Mở UI

**Cách 1: Tại vị trí cố định**

Đến tọa độ: `154.17, -961.87, 29.61`

Khi ở gần sẽ hiển thị text 3D `[E] Trao Đổi Quần Áo`

Bấm phím **E** để mở UI

**Cách 2: Dùng command**

Người chơi sử dụng command bất kỳ nơi đâu:

```
/doiquanao
```

### Quy trình đổi quần áo

1. Mở UI bằng command
2. Chọn danh mục quần áo từ sidebar
3. Chọn item quần áo đang có trong inventory
4. Xem danh sách drawable có thể đổi
5. Chọn drawable mới và xác nhận
6. Item cũ sẽ bị xóa và nhận item mới

### Điều kiện đổi

- ✅ Item phải có metadata.DoHiem (độ hiếm)
- ✅ Item phải có metadata.drawable
- ✅ Chỉ đổi được item cùng loại (cloth_torso -> cloth_torso)
- ✅ Chỉ đổi được item cùng độ hiếm
- ✅ Drawable mới phải nằm trong Config.Dohiem
- ✅ Nhân vật phải là freemode male/female
- ✅ Không spam (cooldown 1.5s)

## Cấu trúc file

```
xn_quydoiquanao/
├── fxmanifest.lua          # Manifest file
├── shared/
│   └── config.lua          # Config chính
├── client/
│   └── main.lua            # Client-side logic
├── server/
│   └── main.lua            # Server-side validation
└── web/
    ├── package.json        # NPM dependencies
    ├── vite.config.js      # Vite config
    ├── index.html          # HTML template
    ├── src/
    │   ├── main.jsx        # React entry point
    │   ├── App.jsx         # Main React component
    │   ├── api.js          # NUI callbacks
    │   └── styles.css      # Gaming theme CSS
    └── dist/               # Build output (sau npm run build)
```

## Development

### Dev mode cho NUI

```bash
cd web
npm run dev
```

Sau đó truy cập `http://localhost:5173` để xem UI trong browser.

### Build production

```bash
cd web
npm run build
```

## Lưu ý quan trọng

### Server-side validation

Server luôn kiểm tra:
- Sex hợp lệ (male/female)
- Item tồn tại trong inventory
- Metadata đầy đủ
- Drawable hợp lệ theo config
- Cooldown

**Không bao giờ tin dữ liệu từ client/NUI!**

### XNClothes Export

Format:
```lua
exports['XNClothes']:GiveClothingItem(source, uiCategory, drawable, texture, palette)
```

- `source`: Player source
- `uiCategory`: 'shirt', 'torso', 'pants', etc.
- `drawable`: Drawable ID
- `texture`: Texture ID (mặc định 0)
- `palette`: Palette ID (mặc định 0)

### Ox_Inventory

Sử dụng:
- `exports.ox_inventory:GetInventoryItems(source)` - Lấy tất cả items
- `exports.ox_inventory:GetSlot(source, slot)` - Lấy item theo slot
- `exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)` - Xóa item

## Troubleshooting

### UI không hiển thị

- Kiểm tra đã build NUI chưa: `cd web && npm run build`
- Kiểm tra thư mục `web/dist` có file không
- Kiểm tra console browser (F12) có lỗi không

### Không đổi được quần áo

- Kiểm tra console server có lỗi validation không
- Kiểm tra Config.Dohiem đã có drawable cần đổi chưa
- Kiểm tra item có metadata.DoHiem không
- Kiểm tra nhân vật có phải freemode model không

### Ảnh không hiển thị

- Kiểm tra Config.Url đúng chưa
- Kiểm tra Config.ComponentMapping đúng chưa
- Kiểm tra metadata.imageurl của item (nếu có)

## Hỗ trợ

Nếu gặp vấn đề, kiểm tra:
1. Console server (F8)
2. Console browser (F12)
3. Logs của ox_inventory
4. Logs của XNClothes

## License

MIT License - Sử dụng tự do cho dự án FiveM
