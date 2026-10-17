# XN Admin Item Manager v2.0

## 📝 Mô tả
Resource quản lý và kiểm tra số lượng vật phẩm trên toàn máy chủ với **React + Vite** professional setup.

## 🎯 Cập nhật v2.0
✨ **React + Vite** - Modern build tool  
✨ **Component-based architecture** - Tách components rõ ràng  
✨ **Custom Hooks** - useNuiEvent hook  
✨ **Better code organization** - Folders structure chuẩn  
✨ **Fast refresh** - HMR trong development  
✨ **Optimized build** - Production-ready bundle

## ✨ Tính năng
- 🔍 Tìm kiếm vật phẩm theo tên
- 📊 Hiển thị tổng số lượng vật phẩm trên toàn server
- 🖼️ Hiển thị hình ảnh vật phẩm (GitHub CDN)
- 📋 Xem chi tiết phân bổ vật phẩm theo:
  - Kho đồ cá nhân người chơi
  - Cốp xe
  - Các kho chứa khác
- 💼 Giao diện React hiện đại, responsive

## 📦 Yêu cầu
- **ox_inventory** - Hệ thống inventory
- **oxmysql** - Database connector
- **ox_lib** (khuyến nghị) - Thư viện hỗ trợ
- **Node.js** (v16+) - Để build UI

## 🔧 Cài đặt

### 1. Build UI (Lần đầu tiên)
```bash
# Windows: Double-click build.bat
# Hoặc chạy manual:
cd web
npm install
npm run build
```

### 2. Thêm vào server.cfg
```cfg
ensure xn_adminitem
```

### 3. Cấu trúc Database
Resource tự động làm việc với:

#### Bảng `players`
- `citizenid` - ID người chơi
- `inventory` - JSON kho đồ cá nhân
- `charinfo` - JSON thông tin nhân vật

#### Bảng `player_vehicles`
- `plate` - Biển số xe
- `vehicle` - Tên xe
- `citizenid` - Chủ sở hữu
- `trunk` - JSON đồ trong cốp

#### Bảng `ox_inventory`
- `name` - Tên kho
- `owner` - Chủ sở hữu
- `data` - JSON items

## 📂 Cấu trúc Project

```
xn_adminitem/
├── web/                    # React source code
│   ├── src/
│   │   ├── components/    # React components
│   │   │   ├── Header.jsx
│   │   │   ├── SearchSection.jsx
│   │   │   ├── ResultsGrid.jsx
│   │   │   ├── ItemCard.jsx
│   │   │   ├── DetailsView.jsx
│   │   │   ├── SummaryCards.jsx
│   │   │   ├── DetailTable.jsx
│   │   │   └── EmptyState.jsx
│   │   ├── hooks/         # Custom hooks
│   │   │   └── useNuiEvent.js
│   │   ├── utils/         # Utility functions
│   │   │   ├── fetchNui.js
│   │   │   └── getItemImage.js
│   │   ├── App.jsx        # Main app component
│   │   ├── main.jsx       # Entry point
│   │   └── index.css      # Global styles
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   └── build/             # Build output (auto-generated)
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── fxmanifest.lua
├── build.bat             # Windows build script
└── README.md
```

## 🎮 Sử dụng

### Mở giao diện
```
/adminitem
```

### Development Mode (cho developers)
```bash
cd web
npm run dev
```

### Build Production
```bash
cd web
npm run build
# Hoặc double-click build.bat
```

## 🛠️ Development

### Thêm Component Mới
```javascript
// web/src/components/MyComponent.jsx
const MyComponent = ({ prop1, prop2 }) => {
  return (
    <div>Your component here</div>
  );
};

export default MyComponent;
```

### Sử dụng Custom Hook
```javascript
import useNuiEvent from './hooks/useNuiEvent';

useNuiEvent('eventName', (data) => {
  console.log('Received:', data);
});
```

### Gọi NUI Callback
```javascript
import fetchNui from './utils/fetchNui';

fetchNui('callbackName', { data: 'value' });
```

## 🎨 Tùy chỉnh

### Thay đổi màu sắc
Chỉnh sửa `web/src/index.css`

### Thay đổi URL hình ảnh
Chỉnh sửa `web/src/utils/getItemImage.js`

## 🐛 Xử lý lỗi

### Build failed
```bash
cd web
rm -rf node_modules package-lock.json
npm install
npm run build
```

### UI không hiển thị sau build
- Kiểm tra folder `html/` có files build
- Restart resource: `restart xn_adminitem`
- Check F8 console

## 📊 Performance
- ⚡ Fast build với Vite
- 📦 Optimized bundle size
- 🚀 Fast refresh trong dev mode
- 💾 Production-ready optimization

## 🔄 Changelog

### v2.0.0 - React + Vite
- ✅ Setup React + Vite
- ✅ Component-based architecture
- ✅ Custom hooks
- ✅ Better code organization
- ✅ Development mode support
- ✅ Production build optimization

### v1.0.0 - Initial Release
- ✅ Basic functionality
- ✅ Search and display items
- ✅ Detail view with tables
3. Xem thống kê tổng quan và danh sách chi tiết theo:
   - **Kho Người Chơi**: Danh sách người chơi đang sở hữu
   - **Cốp Xe**: Danh sách xe đang chứa
   - **Kho Khác**: Danh sách kho chứa khác

### Đóng giao diện
- Nhấn nút X ở góc trên bên phải
- Hoặc nhấn phím ESC

## 🎨 Giao diện

### Màn hình tìm kiếm
- Ô tìm kiếm với placeholder gợi ý
- Grid hiển thị kết quả với hình ảnh và số lượng
- Hover effect đẹp mắt

### Màn hình chi tiết
- Thông tin item với hình ảnh lớn
- 4 thẻ thống kê: Tổng cộng, Kho người, Cốp xe, Kho khác
- 3 bảng chi tiết với đầy đủ thông tin
- Nút quay lại để tìm kiếm tiếp

## ⚙️ Cấu hình

### Thay đổi lệnh mở giao diện
Chỉnh sửa trong [client/main.lua](client/main.lua):
```lua
RegisterCommand('adminitem', function()
    -- Thay đổi 'adminitem' thành tên khác
end, false)
```

### Tùy chỉnh URL hình ảnh
Chỉnh sửa trong [html/script.js](html/script.js):
```javascript
const getItemImage = (itemName) => {
    return `nui://ox_inventory/web/images/${itemName}.png`;
};
```

## 🐛 Xử lý lỗi

### Build failed
```bash
cd web
rm -rf node_modules package-lock.json
npm install
npm run build
```

### UI không hiển thị sau build
- Kiểm tra folder `html/` có files build
- Restart resource: `restart xn_adminitem`
- Check F8 console

### Không hiển thị hình ảnh
- Kiểm tra URL GitHub có đúng
- Kiểm tra tên file ảnh trùng với tên item

## 📊 Performance
- ⚡ Fast build với Vite
- 📦 Optimized bundle size
- 🚀 Fast refresh trong dev mode
- 💾 Production-ready optimization

## 📄 License
Free to use

## 👨‍💻 Author
XN Development Team

## 🔄 Changelog

### v2.0.0 - React + Vite
- ✅ Setup React + Vite
- ✅ Component-based architecture
- ✅ Custom hooks
- ✅ Better code organization
- ✅ Development mode support
- ✅ Production build optimization

### v1.0.0 - Initial Release
- ✅ Basic functionality
- ✅ Search and display items
- ✅ Detail view with tables
