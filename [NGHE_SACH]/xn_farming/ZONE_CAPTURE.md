# Chiếm khu nông trại (Zone Capture)

Khu **Ruộng 11** (đu đủ, hoa mỹ nhân) là khu tranh giành: xã đoàn nào chiếm được khu thì độc quyền trồng và khai thác trong một khoảng thời gian. Khu **Ruộng 12** cùng loại cây nhưng là khu thường, ai cũng trồng được.

## Cách chơi

1. Vào bán kính khu 11, banner phía dưới màn hình cho biết trạng thái: **trống**, **đang bị chiếm** hoặc **đã bị chiếm** (kèm tên xã đoàn và đồng hồ).
2. Ra vòng tròn đỏ ở tâm khu, bấm **E** để chiếm quyền sở hữu.
3. Giữ vị trí **5 phút** để chiếm thành công.
4. Chiếm xong, chỉ xã đoàn đó được trồng, thu hoạch, tưới, bón phân và chăm cây trong **30 phút**.
5. Hết 30 phút khu về trạng thái trống. Xã đoàn nào muốn trồng thì phải chiếm lại.

## Luật

| Nội dung | Quy định |
|---|---|
| Điều kiện bắt đầu | Có xã đoàn, còn sống, đứng trong vòng tròn đỏ (ngồi xe vẫn được), trong khu có tối thiểu **5** thành viên cùng xã đoàn còn sống |
| Thời gian chiếm | 5 phút |
| Hủy chiếm | Khi không còn thành viên xã đoàn nào còn sống trong khu (chết, gục hoặc ra ngoài bán kính). Xã đoàn bị khóa chiếm khu **30 phút** |
| Khu đang trống | Không ai được trồng hay khai thác, phải chiếm trước |
| Khu đang bị xã đoàn khác giữ | Không trồng, không thu hoạch, không tưới/bón phân, không phá cây, không thả sâu, không ăn cắp, không chiếm |
| Khu 11 và thời gian lớn | Cây lớn nhanh hơn **10 phút** (dudu, poppy: 25 phút xuống 15 phút) |

## Thông báo

Khi bắt đầu, hủy, thành công hoặc hết hạn, cả xã đoàn và những người đang đứng trong khu đều nhận thông báo.

## Cấu hình

Trong [config.lua](./config.lua), khối `capture` của khu 11:

| Tham số | Ý nghĩa |
|---|---|
| `markerRadius` | Bán kính vòng tròn đỏ và khoảng cách bấm E |
| `minMembers` | Số thành viên tối thiểu để bắt đầu chiếm |
| `keepMembers` | Số thành viên còn sống tối thiểu để không bị hủy |
| `captureTime` | Thời gian chiếm (giây) |
| `holdTime` | Thời gian giữ khu (giây) |
| `cooldown` | Thời gian khóa khi chiếm bị hủy (giây) |
| `winnerCooldown` | Khóa xã đoàn vừa thắng sau khi hết hạn, 0 là tắt |
| `requireOwner` | `true`: khu trống thì không ai được trồng |
| `blip` | Hiện vùng trên bản đồ |

Ngoài khối `capture`, `growthTimeReduction = 10` là số phút rút ngắn thời gian lớn của khu.

> Lưu ý: file config hiện đang để giá trị thử nghiệm (`minMembers = 2`, `captureTime = 60`, `markerRadius = 2.0`). Trước khi chạy chính thức hãy đặt lại `minMembers = 5`, `captureTime = 300`, `markerRadius = 5.0`.

## Giao diện

Banner và lời nhắc nằm trong source React ở thư mục `web/`. Sau khi sửa giao diện: `cd web`, `npm run build`, rồi restart `xn_farming`.

## Hiệu năng

- Khu rảnh không tốn tài nguyên server. Chỉ khi có xã đoàn đang chiếm mới có một vòng kiểm tra mỗi giây.
- Hết hạn giữ khu dùng một timer duy nhất.
- Trạng thái chỉ đồng bộ cho client khi đổi pha. Đồng hồ đếm ngược do giao diện tự chạy.
- Client chỉ chạy vòng lặp nặng khi người chơi đứng gần tâm khu.
