# Trade System - Hướng dẫn sử dụng

## Tổng quan
Hệ thống giao dịch (Trade System) cho phép 2 người chơi trao đổi vật phẩm và tiền mặt một cách an toàn.

## Cách sử dụng

### 1. Bắt đầu giao dịch
- **Sử dụng ox_target**: Nhìn vào người chơi khác và chọn tùy chọn "Giao dịch" (icon 🤝)
- Khoảng cách tối đa: 3m

### 2. Chấp nhận giao dịch
- Người nhận sẽ thấy popup yêu cầu giao dịch
- Nhấn "Đồng ý" để mở giao diện giao dịch
- Nhấn "Từ chối" để hủy yêu cầu

### 3. Giao diện giao dịch

#### Phần của bạn (phía trên)
- **Input tiền mặt**: Nhập số tiền muốn chuyển (VD: 10000)
- **5 slot vật phẩm**: Click vào vật phẩm trong kho đồ để thêm vào giao dịch
- **Nút Khóa**: Khóa giao dịch khi đã sẵn sàng
- **Nút Xác nhận**: Xác nhận giao dịch (chỉ hoạt động khi cả 2 đã khóa)

#### Phần của đối phương (phía dưới)
- Hiển thị tiền mặt và vật phẩm đối phương đưa vào
- Hiển thị trạng thái khóa và xác nhận của đối phương

### 4. Quy trình giao dịch

1. **Thêm vật phẩm/tiền**: Cả 2 bên thêm vật phẩm và tiền vào giao dịch
2. **Khóa**: Cả 2 bên nhấn "Khóa" khi đã sẵn sàng
3. **Xác nhận**: Cả 2 bên nhấn "Xác nhận" để hoàn tất giao dịch
4. **Hoàn tất**: Vật phẩm và tiền được chuyển tự động

### 5. Hủy giao dịch
- Nhấn nút "✕ Hủy giao dịch" hoặc nút "✕" ở góc trên
- Giao dịch tự động hủy nếu một bên đi quá xa (>5m)
- Giao dịch tự động hủy nếu một bên disconnect

## Lưu ý quan trọng

- **Không thể giao dịch** khi bạn đang trong giao dịch khác
- **Vật phẩm không gửi đi** cho đến khi cả 2 bên xác nhận
- **Mở khóa** sẽ reset trạng thái xác nhận
- **Thay đổi vật phẩm/tiền** sẽ reset trạng thái khóa và xác nhận

## Cấu trúc file

```
modules/trade/
├── server.lua    # Xử lý logic phía server
└── client.lua    # Xử lý logic phía client + ox_target

web/src/components/trade/
├── TradeInterface.tsx    # Component React UI
├── TradeInterface.scss   # Styles
└── index.ts              # Export
```

## API Exports

### Client
```lua
-- Kiểm tra đang trong giao dịch
local isInTrade = exports.ox_inventory:isTradeOpen()

-- Yêu cầu giao dịch với player
exports.ox_inventory:requestTrade(targetServerId)
```

## Events

### Client Events
- `ox_inventory:openTrade` - Mở UI giao dịch
- `ox_inventory:closeTrade` - Đóng UI giao dịch
- `ox_inventory:updateTradeSlots` - Cập nhật trạng thái giao dịch
- `ox_inventory:receiveTradeRequest` - Nhận yêu cầu giao dịch
- `ox_inventory:tradeRequestDeclined` - Yêu cầu bị từ chối

### Server Events
- `ox_inventory:sendTradeRequest` - Gửi yêu cầu giao dịch
- `ox_inventory:declineTradeRequest` - Từ chối yêu cầu
- `ox_inventory:cancelTrade` - Hủy giao dịch

### Callbacks
- `ox_inventory:requestTrade` - Yêu cầu giao dịch
- `ox_inventory:acceptTrade` - Chấp nhận giao dịch
- `ox_inventory:tradeAddItem` - Thêm vật phẩm
- `ox_inventory:tradeRemoveItem` - Xóa vật phẩm
- `ox_inventory:tradeUpdateMoney` - Cập nhật tiền
- `ox_inventory:tradeLock` - Khóa/Mở khóa
- `ox_inventory:tradeConfirm` - Xác nhận giao dịch
