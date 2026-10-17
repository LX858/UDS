# XN_BANXECU - Hệ thống bán lại xe cũ

Hệ thống bán lại xe cũ cho QBX Core + OX Lib

## Tính năng

✅ **Khu vực bán xe được định sẵn** - Sử dụng ox_lib zones poly  
✅ **Đăng bán xe** - Target "Đăng bán xe" khi vào zone với xe  
✅ **Giá động** - Giá min/max tự động dựa trên cardealer_stock (50%)  
✅ **Hiển thị thông tin** - DrawText3D hiển thị thông tin xe đang bán  
✅ **Giao dịch an toàn** - Hệ thống xác nhận 2 chiều  
✅ **Thuế giao dịch** - Thu 5% phí giao dịch  
✅ **Tối ưu hiệu năng** - Code được tối ưu cho server đông người  

## Yêu cầu

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)

## Cài đặt

1. Đặt resource vào thư mục `resources/[XN_CODE2]/`
2. Thêm `ensure xn_banxecu` vào `server.cfg`
3. Khởi động lại server

## Cấu hình

Chỉnh sửa `config.lua` để thay đổi:

- **SaleZonePoints**: Các điểm tạo thành zone bán xe
- **ZoneThickness**: Độ dày của zone (mặc định: 5.0)
- **TransactionTax**: Phần trăm thuế (mặc định: 5%)
- **PricePercentage**: % giá so với cardealer (mặc định: 50%)
- **NearbyRadius**: Bán kính tìm người chơi (mặc định: 5.0)

## Cách sử dụng

### Đăng bán xe

1. Lái xe vào khu vực bán xe (các điểm đã cấu hình)
2. Target vào xe và chọn "Đăng bán xe"
3. Nhập giá bán (trong khoảng min-max được hiển thị)
4. Xác nhận để đăng bán

### Gỡ đăng bán

1. Target vào xe đang bán
2. Chọn "Gỡ đăng bán"
3. Xác nhận để gỡ

### Bán xe cho người chơi khác

1. Target vào xe đang được treo bán (chỉ chủ xe)
2. Chọn "Bán xe"
3. Chọn người mua từ danh sách (trong bán kính 5m)
4. Xác nhận
5. Người mua xác nhận hoặc hủy giao dịch

## Cơ chế hoạt động

### Giá bán

- Giá lấy từ bảng `cardealer_stock` cột `priceToCustomers`
- Min/Max = 50% giá cardealer
- Người bán nhận 95% giá bán
- Hệ thống thu 5% thuế

### Giao dịch

1. Người bán chọn bán xe và chọn người mua
2. Người mua nhận thông báo và xác nhận
3. Hệ thống kiểm tra tiền mặt của người mua
4. Trừ tiền người mua, cộng tiền người bán
5. Chuyển ownership trong database
6. Xe được gỡ khỏi danh sách bán

### Tối ưu hóa

- ✅ Sử dụng lib.callback thay vì event chaining
- ✅ DrawText3D chỉ render khi ở gần (<=10m)
- ✅ Zone poly hiệu năng cao hơn PolyZone
- ✅ Target chỉ tạo khi cần thiết
- ✅ Cleanup tự động khi player disconnect
- ✅ Không sử dụng tick functions không cần thiết

## Database

Resource tự động sử dụng các bảng có sẵn:

- `player_vehicles` - Quản lý xe của người chơi
- `cardealer_stock` - Lấy giá xe từ cardealer

Không cần tạo bảng mới.

## Hỗ trợ

Nếu gặp vấn đề, vui lòng kiểm tra:

1. Tất cả dependencies đã được cài đặt
2. Bảng `cardealer_stock` có dữ liệu
3. Console có lỗi không
4. Quyền truy cập database

## Credits

- Phát triển bởi: XN_CODE2
- Framework: QBX Core
- Libraries: OX Lib, OX Target

## License

Chỉ sử dụng cho mục đích cá nhân/server riêng.
