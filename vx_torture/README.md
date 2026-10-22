# vx_torture (QBX)

Bộ ghế tra tấn dùng vật phẩm **`toture`** (giữ nguyên cách viết này). Mỗi người chơi được đặt một bộ ghế, item không bị tiêu hao. Ghế, trolley và từng dụng cụ là object networked. Chỉ người đặt ghế được lấy dụng cụ, thực hiện hành động, thả người hoặc thu hồi.

## Cài đặt

1. Cài và khởi động `qbx_core`, `qbx_medical`, `ox_inventory`, `ox_target`, `ox_lib` trước `vx_torture`. OneSync phải bật.
2. Thêm item này vào `ox_inventory/data/items.lua` của máy chủ (hoặc hệ thống item QBX hiện dùng), **một lần**:

```lua
['toture'] = {
    label = 'Bộ ghế tra tấn',
    weight = 5000,
    stack = false,
    close = true,
    consume = 0,
},
```

`vx_torture` đăng ký usable callback bằng `exports.qbx_core:CreateUseableItem('toture', ...)`. Không cần khai báo thêm item cho từng dụng cụ. Nếu máy chủ dùng danh mục `qbx_core/shared/items.lua` để đồng bộ sang ox_inventory, thêm item tại đó thay vì khai báo trùng cả hai nơi.

3. Thêm `ensure vx_torture` sau các dependency trong `server.cfg`; khởi động lại các resource liên quan và cấp item cho người thử. Không cần SQL hoặc build web.

## Cách chơi

- Dùng `toture` để hiện preview của cả bộ ghế. Di chuyển hoặc xoay người để chọn vị trí phía trước; nhấn **E** để đặt, **Backspace** để hủy. Item còn trong inventory và chỉ có một bộ đang hoạt động cho mỗi người.
- Target ghế để bắt người còn sống trong 3 m tính từ ghế. Một người hợp lệ được chọn ngay; nhiều người sẽ hiện danh sách.
- Sau khi nạn nhân đã ngồi ổn định, nhắm vào vị trí từng dụng cụ trên mặt trolley để lấy món gần điểm ngắm nhất; menu **Lấy dụng cụ** trên trolley là cách chọn dự phòng. Cảnh lấy món, hoạt ảnh của nạn nhân và camera FBI3 sẽ phát trước khi vào tư thế chờ riêng của món đó.
- Khi đang chờ, menu trên góc quay phim gồm các đòn của món đang cầm và **Thoát và trả dụng cụ**. Kết thúc đòn gây sát thương, menu mở lại để chọn đòn tiếp hoặc Thoát. Thoát đưa người vận hành về trolley và trả món lên bàn; sau đó mới chọn món khác. Đòn gây chết thả nạn nhân và kết thúc phiên dụng cụ.
- Target ghế để thả người hoặc thu hồi cả bộ sau khi thoát khỏi phiên dụng cụ.
- `damage` trừ máu nhưng giữ nạn nhân còn sống; `kill` gọi `qbx_medical:KillPlayer()` trên client nạn nhân để vào thẳng trạng thái DEAD. Bộ ghế được giữ lại sau khi thả hoặc chết, đến khi chủ sở hữu thu hồi.

## Cấu hình

`Config.Torture` trong [config.lua](./config.lua) chứa khoảng cách, thời gian chờ, model, vị trí, bone cầm tay, cảnh chọn/chờ của từng dụng cụ, hành động và kết quả. Trolley và các prop FBI3 lấy tọa độ cùng góc xoay trưng bày từ `GetAnimInitialOffsetPosition/Rotation` của từng `restClip` trong `missfbi3_weapon_select`, với gốc tại ghế. Ghế phụ và ECG dùng tọa độ gốc tương đối của nhiệm vụ. Preview và object networked dùng cùng transform; khi trả dụng cụ, transform đó được áp dụng lại. `offset` dùng để đặt các prop không có clip; prop FBI3 được server giới hạn trong phạm vi scene quanh ghế. `toolTargetRadius = 0.45` giới hạn khoảng cách từ điểm ngắm đến tâm dụng cụ theo mặt phẳng bàn; `targetOffset` của từng món dịch tâm đó theo góc xoay prop. `toolScenes` khai báo clip actor/victim/camera/prop cho cảnh chọn và cảnh chờ; `toolReturnOffset` cùng `toolExitCameraOffset` căn vị trí trả món. Mỗi action có `result = { mode = 'damage', amount = 20 }` hoặc `result = { mode = 'kill' }`. Các stage định nghĩa anim dict/clip, thời lượng tối đa và effect tùy chọn. Xem [FBI3_ALIGNMENT.md](./FBI3_ALIGNMENT.md) để biết nguồn và giới hạn căn chỉnh; kiểm tra trong FiveM trên map dự kiến dùng.

Các clip, prop và effect FBI3 lấy từ [FiveM_Torture_Research.md](./FiveM_Torture_Research.md). Đây là dữ liệu tĩnh; FiveM artifact, game build và ped/clothing của máy chủ có thể khác. Scene sẽ hủy mà không gây sát thương khi không tải được anim, entity hoặc không hoàn thành đúng hạn. Camera, sound và particle là phần trình diễn; gameplay và quyền thao tác do server quyết định.

## Kiểm thử trong FiveM

Thử với ít nhất ba client: một/nhiều người trong 3 m, khác bucket, người khác cố target ghế/tủ, cảnh chọn và chờ của cả năm món, menu sau mỗi đòn, Thoát/trả món, spam option, giảm máu đến 101, tiêm quá liều, ngắt kết nối và restart resource giữa từng giai đoạn. Kiểm tra cả freemode nam/nữ, trang phục cồng kềnh và map dự kiến dùng. Actor và object dùng network scene. Server chuyển ID scene đúng token/epoch sang nạn nhân; client sở hữu ped nạn nhân lấy local scene handle rồi dùng `TaskSynchronizedScene` tham gia cùng scene. Actor tiếp tục phát scene trong lúc chờ nạn nhân xác nhận; nếu thiếu xác nhận thì hủy thao tác. Nạn nhân không có quyền dừng network scene của actor. Trạng thái ngồi ngoài phiên dụng cụ dùng clip `waterboard_idle_victim` trong scene 0 của FBI3 (`missfbi3_weapon_select`); ghế chỉ được actor điều khiển khi chạy cảnh dụng cụ.

Khi thay đổi `config.lua` hoặc mã Lua, chạy `restart vx_torture`. Bộ ghế không lưu qua restart; tất cả session và object của resource sẽ được dọn.

Để căn điểm target của từng món, đặt `Config.Debug = true` rồi restart resource. Khi chủ ghế đứng gần trolley, dấu cầu màu cam chỉ tâm chọn của các món đang để trên bàn. Chỉnh `targetOffset` tương ứng trong `Config.Torture.props` nếu tâm nằm lệch khỏi phần muốn nhắm, rồi restart và thử lại. Dấu cầu chỉ hiện trong chế độ debug.

`Config.DebugZones` điều khiển riêng việc vẽ BoxZone; mặc định `false`. Dòng “Creating new BoxZone with debug enabled” của ox_target là thông báo khi bật lựa chọn này, không phải lỗi target.

Nếu nạn nhân vẫn lệch hoặc không vào scene, mở F8 trên cả actor và victim rồi chạy `vx_torture_diag` tại thời điểm lỗi. Log cho biết role, token/epoch, trạng thái menu, network/local scene ID, phase/rate, gốc scene và tọa độ ghế/nạn nhân. Hai client có thể có local handle khác nhau nhưng phải có cùng network scene ID trong phiên dụng cụ. Lỗi “Victim cannot resolve actor scene” chỉ việc scene chưa stream; “Victim scene missing/off chair” chỉ việc ped chưa thực hiện clip hoặc vị trí cách ghế quá xa. Thiếu xác nhận nạn nhân sẽ hủy scene và không gây sát thương.

Harness hồi quy: cài Python package `lupa`, chạy `python tests/run_scene_flow.py`. Harness thực thi các hàm Lua thật với native giả lập để kiểm tra năm menu/scene chờ, cleanup camera, scene dùng chung, token/epoch, xác nhận hai phía và sát thương một lần. Nó không chứng minh vị trí skeleton, camera hiển thị hoặc OneSync replication trong FiveM.

Nếu vẫn hiện “Không thể đặt bộ ghế tại đây”, đặt `Config.Debug = true` rồi restart resource. Lỗi trước khi preview xuất hiện sẽ ghi lý do vào F8 của client; lỗi sau khi nhấn E sẽ ghi lý do vào console server (ví dụ `wrench:scene_bounds` hoặc `chair:spawn`).
