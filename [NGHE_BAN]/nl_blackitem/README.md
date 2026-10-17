# NL Black Item Shop

Script bán vật phẩm đen cho QBCore Framework với ox_inventory và ox_lib.

## Tính năng

- **NPC Dealer**: NPC tại vị trí cố định để bán vật phẩm
- **Giờ hoạt động**: NPC chỉ xuất hiện từ 19:00 đến 04:00 (thời gian in-game)
- **Giá ngẫu nhiên**: Giá các vật phẩm thay đổi ngẫu nhiên theo thời gian
- **Giao diện hiện đại**: Sử dụng ox_lib context menu và input dialog
- **Thanh toán bằng tiền bẩn**: Chỉ chấp nhận black_money
- **Xác thực bảo mật**: Kiểm tra giá phía server để tránh hack
- **Lệnh quản trị**: Các lệnh cho admin quản lý giá cả

## Cài đặt

1. Đặt thư mục `nl_blackitem` vào thư mục `resources` của server
2. Thêm `ensure nl_blackitem` vào file `server.cfg`
3. Khởi động lại server hoặc chạy lệnh `restart nl_blackitem`

## Dependencies

- qb-core
- ox_inventory
- ox_lib
- ox_target (tự động detect)

## Cấu hình

Chỉnh sửa file `config.lua` để:
- Thay đổi vị trí NPC
- **Điều chỉnh giờ hoạt động**: Mặc định 19:00-04:00
- Thêm/bớt vật phẩm bán
- Điều chỉnh giá min/max
- Thay đổi thời gian làm mới giá
- Tùy chỉnh ngôn ngữ

### Cấu hình thời gian hoạt động:
```lua
Config.TimeRestrictions = {
    enabled = true,  -- Bật/tắt giới hạn thời gian
    startHour = 19,  -- Giờ bắt đầu (19:00)
    endHour = 4      -- Giờ kết thúc (04:00)
}
```

## Vật phẩm mặc định

- `xa_beng`: Vật phẩm chính (100-500 tiền bẩn)
- `lockpick`: Dụng cụ phá khóa (50-150 tiền bẩn)
- `thermite`: Thuốc nổ (200-600 tiền bẩn)
- `weapon_knife`: Dao bướm (300-800 tiền bẩn)

## Lệnh quản trị

- `/refreshblackprices`: Làm mới giá ngay lập tức (Admin only)
- `/checkblackprices`: Kiểm tra giá hiện tại
- `/cleannpc`: Dọn dẹp và spawn lại NPC dealer (Client command)

## Hỗ trợ

Nếu có lỗi hoặc cần hỗ trợ, vui lòng kiểm tra:
1. Đã cài đặt đủ dependencies
2. Item `black_money` có tồn tại trong database
3. Các vật phẩm trong config có tồn tại trong `qb-core/shared/items.lua`
