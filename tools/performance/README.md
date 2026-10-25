# Understar: triển khai tối ưu profiler 25/10/2026

Các thay đổi đã được triển khai vào source trong `X:\UDSFxServer\resources`. Chưa chạy FXServer, chưa ghi vào database thật, chưa cài scheduler hook lên artifact thật và chưa có capture sau tối ưu. Kết quả kiểm thử dưới đây là kiểm thử offline; không phải bằng chứng đã đạt P99 hoặc hết hitch trên server.

## Baseline được bảo toàn

- Bản sao 20 trace và SHA256: `X:\UDSFxServer\optimization-baselines\20261025-profiler\manifest.json`.
- Thống kê: `X:\UDSFxServer\optimization-baselines\20261025-profiler\summary.json`.
- Git tại lúc bắt đầu: `3b4dec68795d82e54de8a266b5c716562dd99958`. Trong lúc triển khai xuất hiện commit ngoài tác vụ `455bc63`; giữ nguyên commit này và các thay đổi của nó, gồm transport WS của airdrop. Boombox/HUD đã được commit đó ghi nhận, vì vậy không xuất hiện hết trong `git diff HEAD`.
- 7.000 frame bắt đầu, 6.980 hoàn chỉnh; P50 2,040 ms, P95 7,790 ms, P99 47,501 ms, max 207,818 ms; 64 frame >50 ms, 4 frame >100 ms.
- Không có player/entity count hay trạng thái monitor đáng tin cậy cho từng capture cũ. Không suy luận cải thiện từ các capture có tải khác nhau.
- `unfinishedStartedFrames` là frame bắt đầu chưa ghép được kết thúc; `parserBoundaryMarkers` còn tính cả marker kết thúc thiếu marker bắt đầu ở biên capture. Hai bộ đếm không đồng nghĩa.

## Phạm vi thay đổi

| Nhóm | Thay đổi |
|---|---|
| `1307_Boombox` | Bỏ lấy toàn bộ core trong nhánh kiểm tra quyền QBX; giữ ACE/quyền PlayerData, coalesce đồng bộ admin khi load, chỉ ghi state khi đổi. Server vẫn kiểm tra quyền tại thao tác. |
| `Tipi_hud` | Native lấy ID, ping/online gửi riêng mỗi 10 giây, client nhận payload mới; tránh ghi metadata stress hai lần qua cùng QBX. |
| `qbx_core` | Export scalar `GetPlayerCitizenId` để kiểm tra lại danh tính mà không copy player object. Airdrop/daily rewards cần export này. |
| `vx_airdrop` | Gom remove/check đội, roster delta có version; snapshot khi vào hoặc thiếu version. Giữ luật điểm, kill/death, routing bucket và phần thưởng hiện tại. |
| `Police_Grappler` | Index theo owner; scope chỉ gửi grappler liên quan; cleanup khi owner rời hoặc entity mất, client merge entry. |
| `vx_runtime_monitor` | Mặc định tổng hợp nhẹ; detail có thời hạn; off chặn thu thập trong hook. Giới hạn intake 128 record/lượt, ghi 250 record/lượt, bộ đếm sự kiện và mất record tính theo trọng số aggregate. |
| `vx_profiler_monitor` | Capture mới lưu player/entity count, mode monitor, artifact version và revision cấu hình vào sample metadata. |
| `ox_inventory` | Snapshot theo chunk mặc định 20 inventory, budget chuẩn bị 2 ms; FIFO transaction cho các đường ghi và fence khi đọc lại. Pending save, dirty tracking và lỗi SQL được giữ đến khi hoàn tất. |
| `Tipi_Daily_Rewards` | SQL await, lock theo citizenid, cộng phút theo thời gian từng session, cache chỉ cho push hiển thị; retry phút chưa lưu và giữ qua disconnect/đổi ngày. |
| `XNClothes`/appearance | Coalesce theo người chơi, chỉ ghi metadata khi đổi; appearance latest-wins theo citizenid, transaction cho UPDATE/DELETE/INSERT, giữ bản mới nhất để retry khi SQL lỗi. |
| `qbx_core`/`Renewed-Banking` | Chặn payroll chồng nhau, kiểm tra lại player trước trả tiền; đo từng bước payroll và encode ledger. Chưa đổi schema hoặc cắt lịch sử giao dịch khi chưa có bằng chứng live. |
| `xn_motels` | Validate bucket/phòng/cooldown phía server; delta phòng sạch thay toàn bộ GlobalState, gom ghi cùng motel, chỉ JSON_SET hai trường dọn phòng. Retry lỗi SQL, flush khi shutdown. |

`illenium-appearance/server/server.lua` bị thiếu và từng bị `.gitignore` loại ra. Đã khôi phục từ `X:\UDSFxServer\resourcesa\[standalone]\illenium-appearance`: 71 file Lua chung của hai cây khớp byte tại lúc đối chiếu. Chỉ khôi phục file thiếu, bỏ hai dòng ignore tương ứng, rồi sửa đường save. Cần đưa file mới này vào gói triển khai/commit; đây là bằng chứng tương thích source, không xác nhận bản trên host capture.

## Kiểm thử đã chạy

Từ `X:\UDSFxServer\resources`, harness dùng Python + Lupa Lua 5.4, mô phỏng coroutine/promise/SQL và chuẩn hóa cú pháp riêng FiveM trong bộ nhớ:

```powershell
$env:PYTHONPATH='X:\UDSFxServer\optimization-baselines\20261025-profiler\test-tools'
python -X utf8 tools/performance/verify.py
```

15 nhóm kiểm tra PASS, cộng bộ test gameplay airdrop: quyền admin và thu hồi quyền; targeted ping/stress; scope grappler; monitor aggregate/drop/detail expiry/off; lock citizenid; FIFO SQL; inventory sửa tiếp trong lúc đang save, disconnect và save lỗi; daily đổi ngày/retry; appearance coalesce/transaction/retry; motel delta/bucket/retry; payroll chống chạy lặp và thiếu quỹ. Các log `database unavailable`, `SQL unavailable`, `offline` trong harness là lỗi được cố ý tạo để kiểm tra giữ dữ liệu.

Chạy Node từ từng resource để tránh Node diễn giải dấu `[]` trong đường dẫn như glob:

```powershell
Push-Location -LiteralPath 'X:\UDSFxServer\resources\[standalone]\vx_runtime_monitor'
node --test tests/api.test.js tests/stats.test.js tests/store.test.js
Pop-Location
Push-Location -LiteralPath 'X:\UDSFxServer\resources\[standalone]\vx_profiler_monitor'
node --test tests/profiler.test.js
Pop-Location
git diff --check
```

Kết quả: runtime monitor 14/14, profiler 9/9. Chrome smoke test `node tests/ui-browser.js` tại resource monitor cũng đạt: login, stats, target detail, loading 24 giờ và detailed log. Dashboard hiển thị mode, intake queue và count/tổng bytes/max wall time của dòng aggregate; không cần build vì là JS trực tiếp. Installer hook đã được thử trên bản sao: cài mới, chạy lại, upgrade từ hook cũ và uninstall đều trả đúng SHA256 ban đầu. Không thay scheduler đang có tại `X:\UDSFxServer\server`.

## Triển khai theo nhóm

1. Backup source/cấu hình/database trên host thực tế. Ghi lại artifact path và phiên bản source. Giữ baseline bên ngoài thư mục retention của profiler.
2. Đưa Boombox và HUD lên trước; reload cả server/client của hai resource, thử admin/thường, thu hồi quyền, load nhân vật, ping/online/stress; capture cùng hoạt động và số người.
3. Kết thúc trận airdrop, thu hồi grappler. Đưa core export cùng airdrop/Grappler lên trong maintenance restart toàn FXServer; không hot restart `qbx_core` khi người chơi đang online. Thử burst disconnect, source reuse, hết đội, kết thúc trận và entity cleanup.
4. Trên host artifact thật, dừng FXServer, chép cả bộ `vx_runtime_monitor/patch`, giữ `install-state.json` và backup của lần cài trước. Chạy `install.ps1 -TargetPath <đường dẫn scheduler.lua thật>`. Installer từ chối nếu hash/state/anchor không khớp. Không dùng đường dẫn mặc định nếu artifact thực tế khác. Đặt `vx_monitor_scheduler_path` trỏ cùng file. Restart toàn FXServer để hook mới có hiệu lực trong mọi Lua runtime.
5. Đưa các đường lưu inventory/daily/appearance/motel và payroll lên ở maintenance window sau khi kiểm tra staging. Flush dữ liệu và kết thúc hoạt động trước khi dừng. Không chỉ restart collector rồi coi hook đã cập nhật. Không cần migration schema cho patch hiện tại.

Daily rewards bắt đầu tính đủ 60 giây của từng session, không cấp phút tròn chỉ vì người chơi vừa vào trước nhịp cập nhật chung. Giữ citizenid/session check khi source được tái sử dụng. Cache cho UI không thay quyền nhận thưởng hoặc các lần đọc phục vụ claim.

## Điều khiển monitor và đo A/B

Trong console server (command ACE restricted):

```text
vx_monitor_mode light
vx_monitor_detail 60
vx_monitor_mode off
```

Detail tối đa 300 giây, tự về light khi hết hạn. Hook đọc thay đổi mode trong khoảng một giây. Light gom tối đa 512 nhóm/resource/lượt một giây, giữ count và tổng payload bytes, `wallMs` là max trong nhóm; không giữ ID cá nhân cho aggregate. Detail có player ID theo khả năng xác định. Quá giới hạn báo dropped, không đoán dữ liệu bị mất. `wallMs` có cả thời gian await, không phải CPU time.

Off tắt tạo record/đóng gói trong hook và intake/lifecycle logging của collector. Dashboard và map entity/player của collector vẫn có thể hoạt động; vì vậy off không đồng nghĩa toàn resource có overhead bằng 0. Để đo baseline không có cả collector, đặt off trước, đợi hook nhận mode rồi dừng resource. So sánh thêm bản artifact chưa cài hook nếu cần đo chi phí wrapper còn lại.

Kiểm tra `/health`: `collectionMode`, `schedulerHookPresent`, `freshAgents`, `inputQueue`, `queue`, `dropped`. Chế độ off báo `status=off`; light/detail cần hook thật và agent mới. Chỉ có marker trên disk chưa chứng minh runtime đã nạp patch mới.

Đặt revision đại diện đúng gói code, gồm trạng thái chưa commit nếu có:

```text
set vx_profiler_revision "understar-20261025-optimization-staging"
set qbx:profilePaychecks 1
```

Payroll export `exports.qbx_core:GetPaycheckProfile()` trả count/total/max/errors của `balance`, `debitAndLedger`, `payment`; banking export `exports['Renewed-Banking']:GetLedgerProfile()` trả thống kê encode ledger. Dùng kết quả này kèm slow-query/lock/pool/CPU/disk để quyết định thay lưu trữ; các con số là wall time, không thể tự suy ra SQL execution time. Tắt log đo payroll bằng `set qbx:profilePaychecks 0` sau điều tra.

Copy capture sau triển khai cùng sample metadata vào cây riêng `after/traces` và `after/samples` trước khi retention xóa. Từ thư mục resources:

```powershell
node tools/performance/compare-traces.cjs 'X:\UDSFxServer\optimization-baselines\20261025-profiler' '<thư mục after/traces>'
```

Công cụ chỉ đọc; xuất JSON P50/P95/P99/max, >50/>100 ms, self-time/max theo resource, context và cảnh báo trùng file. Resource self-time có thể gồm scope ở frame biên; đây không phải CPU toàn máy. So sánh capture không trùng, cùng player/entity/activity và monitor mode; không chỉ so tổng self-time của hai khoảng ghi dài khác nhau.

## Những kiểm tra live còn bắt buộc

- A/B light/detail/off với tải tương đương; đo lượng event/payload, queue, dropped và P95/P99. Chưa có số phần trăm cải thiện được xác nhận.
- Inventory: disconnect/reconnect trong lúc save, SQL lỗi/phục hồi, stash/trunk/glovebox/player, shutdown và xác nhận số lượng/metadata vật phẩm trên database. Một inventory JSON lớn vẫn có thể vượt budget 2 ms vì không yield giữa một lần encode.
- Daily: reconnect, source reuse, đổi ngày, claim đồng thời và SQL mất kết nối; xác nhận phút và không nhận thưởng lặp.
- Appearance: spam thay đồ, đổi nhân vật, disconnect trong lúc SQL đang chạy, lỗi transaction. UI/NUI không có thay đổi cần build.
- Motel: thử schema JSON phòng dạng array và object trên đúng MariaDB của server; verify chỉ `trashCount`/`lastCleaned` thay đổi, quyền/phòng/bucket và rental/revenue vẫn đúng. SQL dùng `COALESCE(JSON_SET(...), rooms)` vì JSON_SET có thể trả NULL nếu đường dẫn không phù hợp. Tham khảo [JSON_SET](https://mariadb.com/docs/server/reference/sql-functions/special-functions/json-functions/json_set) và [JSON_TYPE](https://mariadb.com/docs/server/reference/sql-functions/special-functions/json-functions/json_type).
- Các queue retry giữ trong RAM: bảo vệ khi lỗi ghi trong tiến trình đang chạy, không cung cấp bảo đảm chống mất dữ liệu khi process bị kill hoặc host mất điện. Hook flush/shutdown cũng cần xác minh trên runtime thật.
- Đo payroll các bước trước khi quyết định đổi ledger schema. Chưa tối ưu storage/history của Renewed-Banking trong patch này.

Nếu rollback, phục hồi riêng các nhóm resource đã triển khai từ backup cùng phiên bản core export/client/server. Không reset cả repo vì có commit/thay đổi ngoài tác vụ. Gỡ hook bằng `uninstall.ps1` với state/backup tương ứng và restart toàn FXServer. Không rollback database chỉ để rollback source này.
