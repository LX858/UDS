# Triển khai trucker trên UDSFxServer

## Mã và cấu hình

`lr_trucker_job` nằm trong `resources/[new]`, được `ensure [new]` khởi động sau `xn-sellitem`, `cdn-fuel`, `xn_banhnuoc`, `ox_inventory` và `Renewed-Banking`. Các resource đó giữ vị trí, giá và cấu hình đang chạy. `Config.EnableTruckerjob` trong `xn-sellitem`, `xn_banhnuoc`, `cdn-fuel` mặc định `true`; đặt `false` để chặn đơn mới của tích hợp tương ứng, vẫn cho phép quyết toán/hoàn các đơn cũ.

Không sao chép toàn bộ cấu hình backup và không chạy `20260923_trucker_reference_prices.sql` hoặc `2026-09-23-fixed-retail-fuel-price.sql`. Mã fuel hiện tại không ép `fuelprice` về 20. Hàng mới chưa có bản ghi DB dùng giá khởi tạo trong `xn-sellitem/config.lua`; giá/tồn kho các bản ghi hiện hữu được giữ.

## Database trước lần start đầu

1. Cho các chuyến vận chuyển và đơn hàng đang hoạt động hoàn thành hoặc hủy, dừng FXServer và sao lưu database. Kiểm tra bảng `lr_trucker_%`, `xn_sellitem_config`, `xn_sellitem_delivery_reservations`, `fuel_station_procurement_ledger` và cột `current_amount`, `debited_at` trước khi chạy SQL.
2. Với database chưa từng chạy trucker, áp dụng `lr_trucker_job/install.sql`. Nếu đã có bảng trucker, đối chiếu schema và chỉ áp dụng migration nâng cấp cần thiết theo thứ tự `20260913_processed_ingredients.sql`, `20260923_payment_ledger.sql`, `20260926_persistent_rental_leases.sql`; không chạy `install.sql` đè dữ liệu cũ. Kiểm tra `lr_trucker_payments.kind` có `rental_fee`.
3. Với `xn-sellitem` đang chạy, áp dụng `migrations/20260903_trucker_integration.sql` để thêm `current_amount` và bảng giữ hàng. Không chạy lại `install.sql` trên database hiện hữu.
4. Áp dụng `cdn-fuel/assets/sql/2026-10-20-trucker-procurement-ledger.sql`. Nếu ledger từ bản cũ đã tồn tại mà thiếu `debited_at`, startup `cdn-fuel` sẽ thêm cột và đánh dấu các dòng lịch sử là đã ghi nợ; đối soát ledger và số dư trạm trước khi mở đơn mới.

## Xác nhận staging

- Kiểm tra `bar` ở (214.6596, -961.8030, 32.9034) và `restaurant_shop` ở (321.5259, -1645.8512, 32.5832). Điểm đỗ ban đầu lần lượt ở (206.8376, -1144.8131, 31.3624, 250.5054) và (311.7239, -1695.5260, 32.4171, 0.2916). Các điểm đỗ, dỡ hàng và xe nâng này được tịnh tiến từ bản backup: phải kiểm tra địa hình, va chạm, hướng và đường đi trong game, chỉnh `config.lua` nếu cần trước khi mở đơn doanh nghiệp trên live.
- Thử bán nguyên liệu sạch, tạo đơn quán nước/nhà hàng/trạm xăng, giữ hàng, hai tài xế tranh đơn, giao và giao lặp, hủy, kho đầy, ngắt kết nối và restart từng resource. So sánh giá, tồn kho, quỹ doanh nghiệp, số dư/nhiên liệu trạm và sổ thanh toán trước/sau.
- Thử chế biến `nuocdua_utso` từ `dua_soche`, `trada_utso` từ `tra_kho`, `com_suon_tam_9h` từ `gao`/`conheo`; thử thiếu nguyên liệu, rời bàn, sai job, lỗi thêm item và rollback. Kiểm tra ảnh item trong `ox_inventory`.
- Thử thuê/trả xe, phụ phí, tiền công, reconnect và restart. Các khoản `processing` có kết quả thanh toán chưa rõ cần đối soát lịch sử QBX trước khi xử lý thủ công.

Sau khi staging đạt, triển khai cả cụm mã và SQL trong một lần bảo trì rồi khởi động lại toàn bộ FXServer. Không restart riêng từng resource để cập nhật hợp đồng export và schema.
