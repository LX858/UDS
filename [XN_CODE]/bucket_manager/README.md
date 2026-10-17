# Bucket Manager - FiveM Resource

Resource quản lý bucket cho server FiveM sử dụng QBCore framework và ox_lib.

## Tính năng

- **Kiểm tra bucket hiện tại**: Sử dụng lệnh `/bucket` để xem bucket hiện tại của bạn
- **Reset bucket về 0**: Sử dụng lệnh `/resetbucket` để trở về bucket mặc định (bucket 0)
- **Set bucket cho player khác**: Admin có thể sử dụng `/setbucket [player_id] [bucket_id]` để chuyển player khác đến bucket cụ thể

## Cài đặt

1. Sao chép thư mục `bucket_manager` vào thư mục `resources` của server
2. Thêm `ensure bucket_manager` vào file `server.cfg`
3. Khởi động lại server

## Lệnh

### `/bucket`
- **Mô tả**: Kiểm tra bucket hiện tại của bạn
- **Quyền**: Tất cả người chơi
- **Cách sử dụng**: `/bucket`

### `/resetbucket`
- **Mô tả**: Reset bucket của bạn về bucket 0 (bucket mặc định)
- **Quyền**: Tất cả người chơi  
- **Cách sử dụng**: `/resetbucket`

### `/setbucket` (Admin)
- **Mô tả**: Set bucket cho player khác
- **Quyền**: Admin
- **Cách sử dụng**: `/setbucket [player_id] [bucket_id]`
- **Ví dụ**: `/setbucket 1 5` (chuyển player ID 1 đến bucket 5)

## Exports

Resource này cung cấp các exports để các resource khác có thể sử dụng:

```lua
-- Lấy bucket hiện tại
exports['bucket_manager']:GetCurrentBucket()

-- Reset bucket về 0
exports['bucket_manager']:ResetBucket()
```

## Dependencies

- qb-core
- ox_lib

## Thông tin kỹ thuật

- **Framework**: QBCore
- **Notification System**: ox_lib
- **Lua Version**: 5.4

## Ghi chú

- Bucket 0 là bucket mặc định nơi tất cả người chơi sẽ ở cùng một dimension
- Các bucket khác nhau sẽ tách biệt người chơi (không thể nhìn thấy hoặc tương tác với nhau)
- Resource này hữu ích cho việc tạo phòng riêng, event riêng, hoặc các khu vực đặc biệt

## Hỗ trợ

Nếu gặp vấn đề, vui lòng kiểm tra:
1. Đã cài đặt đúng dependencies (qb-core, ox_lib)
2. File fxmanifest.lua có đúng cú pháp
3. Server console có báo lỗi không
