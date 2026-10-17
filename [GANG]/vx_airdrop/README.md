# VX Airdrop

Sự kiện PvP hai đội. Admin mở thủ công hoặc đặt giờ Bangkok trong `Config.Airdrop.Schedule`. Mặc định người chơi có 15 giây bấm Y để đăng ký, sau đó trận kéo dài 1 phút. Hạ gục người đội địch được 1 điểm khi cả người hạ lẫn nạn nhân đều ở trong vòng 10 m quanh prop. Mỗi 20 giây, nếu trong vòng chỉ có người của một đội thì đội đó được thêm 1 điểm, bất kể số người; vòng trống hoặc có cả hai đội không cộng điểm chiếm vùng.

## Cài đặt

Đảm bảo `oxmysql`, `ox_lib`, `ox_inventory`, `qbx_core`, `qbx_medical`, `neons_ddame` chạy trước `vx_airdrop`. `neons_ddame` phát event server nội bộ `neons_ddame:server:kill(playerId, attackerId)`, trong đó `playerId` là nạn nhân và `attackerId` là người hạ. Airdrop đối chiếu event này với trạng thái chết trước khi cộng điểm. Resource tự tạo bảng `vx_airdrop_pending_rewards` khi khởi động; tài khoản MySQL cần quyền `CREATE TABLE`. Build NUI bằng `cd web && pnpm install && pnpm build`, rồi restart `neons_ddame` trước `vx_airdrop`.

Để cấp quyền mở/hủy cho nhóm admin, thêm vào `server.cfg`:

```cfg
add_ace group.admin vx_airdrop.admin allow
```

Các lệnh:

- `/airdropstart`: mở lượt ngay (console hoặc người có ACE).
- `/airdropcancel`: hủy lượt, không phát thưởng (console hoặc người có ACE).
- `/airdropclaim`: nhận lại vật phẩm thưởng đã lưu khi túi đầy.

## Cấu hình

- `Config.Airdrop.Schedule = { '20:00', '22:30' }` chạy hằng ngày theo Asia/Bangkok. Mặc định `{}` nên chỉ có lệnh admin.
- `Config.Airdrop.Uniforms.A/B.male/female` là bốn bộ đồ mẫu cho freemode ped. Mỗi component hoặc prop là `{ drawable, texture }`. Hãy thay bằng set admin chọn trước khi dùng chính thức. Mặt và tóc không bị đổi.
- Trong trận, server đồng bộ `vxAirdropRound`, `vxAirdropTeam` và `vxAirdropActive`; mỗi client tự kiểm tra đồng phục của các thành viên đang được stream. Khi rời trận, outfit đã lưu được khôi phục trước khi server mở lại các luồng thay đồ thông thường.
- `Config.Airdrop.Weapons` khớp ba nút trong `Weapons.tsx`; `Config.Airdrop.Rewards` mặc định là `bandage x2` và `nuocsuoi x2` cho mỗi thành viên đội thắng còn trong trận.
- `JoinPosition` được lưu theo yêu cầu nhưng chưa dùng; bấm Y được ở mọi nơi khi còn sống và không ngồi xe. Đội A/B và drop dùng các tọa độ trong `Config.Airdrop.Teams` và `DropPosition`.

## Kiểm thử trong FiveM

Mở lượt bằng console với ít nhất hai client. Thử đăng ký khi ngồi xe, rời xe và bấm lại Y trước khi hết thời gian cấu hình; xác nhận chia đội, outfit và prop giống nhau khi nhìn từ cả hai client, chọn vũ khí, điểm chiếm vùng mỗi 20 giây khi chỉ một đội hiện diện, điểm hạ gục, hồi sinh sau 2 giây, kết quả và trả vị trí/bucket. Trong trận, thử on-duty, mở/đóng menu quần áo, dùng item quần áo, chết/hồi sinh và đi ra/vào streaming range; đồng phục không được nhấp nháy hoặc đổi sai. Sau trận, xác nhận đúng outfit, túi và props trước trận được khôi phục. Kiểm tra vòng trống, hai đội cùng ở trong vòng, nhiều người cùng một đội và người đang chết/hồi sinh. Thử hạ gục khi cả hai trong vòng đỏ, một người ngoài vòng, cùng đội, và nhiều hit trên cùng một mạng; thử thêm túi đầy rồi dùng `/airdropclaim`. Các kiểm tra build/cú pháp trên máy phát triển không thay thế lượt thử nhiều người trong FXServer.

Có thể chạy bộ kiểm tra logic server từ thư mục `vx_airdrop` bằng `npm exec --yes --package=fengari-node-cli -- fengari tests/server-kill-score.lua`.
