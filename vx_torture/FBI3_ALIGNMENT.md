# Căn chỉnh prop theo cảnh FBI3 gốc

Nguồn chính là [`fbi3.c` đã decompile](https://github.com/YimMenu/GTA-V-Decompiled-Scripts/blob/master/decompiled_scripts/fbi3.c) của nhiệm vụ GTA V. Đây là dữ liệu kịch bản và animation, chưa phải kết quả kiểm tra trực tiếp trên build FiveM của máy chủ.

Tên clip trưng bày, hai kẹp điện và khăn dùng trong code đã được đối chiếu thêm với [`animDictsCompact.json`](https://github.com/DurtyFree/gta-v-data-dumps/blob/master/animDictsCompact.json). File dump xác nhận tên clip tồn tại; vị trí thực tế vẫn do game tính ở runtime.

## Scene lifecycle v12 — kiểm chứng multiplayer còn chờ

Bản này sửa vòng đời scene và xác nhận hai phía. Không đổi flag actor, blend, clip, scene root hay thêm task/teleport để chữa triệu chứng rơi xuống đất. Chưa có kết quả chạy hai/ba FiveM client thật; harness chỉ kiểm tra logic và native giả lập.

### Luồng và giao thức

- `BeginSceneRun`/`SceneCurrent`/`ExpectScene` dùng setup + token + loại cảnh + bước/epoch + generation local. Network scene ID có thể tái sử dụng, không phải định danh phiên. Callback tải asset và trả prop kiểm tra phiên trước khi tác động; prepare được đặt trạng thái trước khi tạo coroutine. Join đến trước lệnh chuyển bước được giữ lại nếu cùng định danh.
- Actor giữ network scene; nạn nhân vẫn điều khiển ped của chính mình. Tải asset trước khi thay cảnh; dừng handle cũ một lần trước successor; giữ camera đến khi camera kế tiếp sẵn sàng. Hai frame nhường xử lý stop chỉ là xử lý local, không phải xác nhận engine phía remote.
- Kiểm tra track mỗi 100 ms, `remoteTrackGraceMs = 500`. Mất track ngắn được dung sai nhưng không được coi là hoàn tất. Mất kéo dài báo lỗi một lần. Entity mất hoặc người chơi chết không có grace; server tiếp tục kiểm tra bucket/khoảng cách/sống.
- `toolSelected(setupId, token, success, netScene, reason)` và `stageDone(setupId, token, index, success, netScene, reason)` báo phía actor; nạn nhân gửi `sceneComplete(setupId, token, kind, step, netScene, success, reason)`. Server chỉ chấp nhận hai người của phiên và đúng peer identity, không chấp nhận client tự chọn damage. Gửi xác nhận xong không tự chuyển cảnh local.
- `scenePeersReady(token, kind, step, netScene)` báo cho nạn nhân mốc server đã chấp nhận readiness. Clip hữu hạn kết thúc theo phase actor >= 0.97 và phase track nạn nhân >= 0.95, trừ victim loop độc lập. Loop dùng thời gian `loopMs` kể từ readiness, không chờ phase 1.
- Server chờ cả hai xác nhận cuối, tối đa `stageConfirmTimeoutMs = 4000` sau xác nhận đầu. Các hạn chuẩn bị/phát cảnh cũ vẫn có hiệu lực. Damage chỉ áp dụng một lần sau toàn bộ chuỗi. Event trùng, sai handle, token, stage hoặc idle epoch không được làm kết thúc successor.
- `toolSceneFailed` mang kind/step/reason; `stageFailed` mang stage/reason. Server truyền lý do qua stopAction/stopTool. Đòn lỗi thử về idle một lần; idle lỗi thì đóng phiên và trả prop, không phát thông báo lỗi lần hai. Nếu không khôi phục được tư thế ngồi cơ bản, nạn nhân báo `seatRecoveryFailed` với token vừa đóng để server giải phóng ghế.

### Thu bằng chứng lỗi rơi/đứng im

1. Bật `Config.Torture.sceneDiagnostics = true` trong `config.lua`; chạy `restart vx_torture` và đặt ghế mới.
2. Kiểm tra cả F8 và server có marker **scene lifecycle v12**. Client in game build; server in artifact/enforced build nếu convar cung cấp.
3. Dùng hai người tham gia và một observer. Thử cờ lê trái/giữa/phải, mỗi đòn 10 lần, ghi hình cùng lượt từ actor và victim. Các dụng cụ còn lại mỗi option 5 lần; idle 60 giây; thử FPS/ping khác nhau.
4. Khi actor rơi hoặc đứng im trên máy victim, chạy `vx_torture_diag` ngay trên **cả hai máy**. Lỗi được resource phát hiện cũng tự dump. Gửi các dòng `scene_v12`, `scene_trace`, `scene_sample` của cùng token và log server.
5. Mẫu chỉ giữ tối đa 50 bản ghi / 5 giây, mỗi 100 ms, không gửi telemetry liên tục lên server. Ghi scene/local handle, root, clip, phase, tọa độ actor quan sát được, visibility/alpha/owner và tọa độ người chơi local. Xuất từng dòng để giảm nguy cơ console cắt một JSON quá dài. Tắt diagnostics sau khi thu xong.

Đối chiếu timestamp **trong từng máy** và định danh chung; không trừ trực tiếp GetGameTimer của hai máy. Actor đúng local nhưng sai remote: ưu tiên packet/chuyển scene; cả hai sai: kiểm tra task/transform; server hủy trước: xem reason và điều kiện. Chỉ thử thay flag/transform sau khi đã có đối chứng. Nếu vẫn lỗi ở ca tái hiện tối giản, cần kiểm chứng artifact/engine trên máy chạy server, không kết luận đã sửa bằng harness.

### Kiểm thử đã chạy

`uv run --with lupa python tests/run_scene_flow.py`: 5 dụng cụ / 21 stage và hiệu ứng cũ; thêm xác nhận cuối hai phía, mất remote track ngắn/kéo dài, loop wrap, duplicate prepare, hủy trước khi coroutine chuẩn bị chạy, generation cũ, trace giới hạn, sai nguồn/handle/token, timeout xác nhận cuối, stale idle failure và chống thông báo/sát thương lặp. `git diff --check` kiểm tra whitespace. Những kiểm tra này không mô phỏng packet engine, hình học GTA hoặc rendering thật.

Nghiệm thu trực tiếp còn phải kiểm tra chết/ngắt kết nối/đổi bucket/restart giữa select, idle, action và exit; không còn camera, khóa điều khiển hoặc prop bị treo. Thử freemode nam/nữ và các góc đặt ghế. Không đổi artifact/config OneSync của server trong bản sửa này.

## Vị trí trưng bày

Trong `func_501` (khoảng dòng 55308–55363), game lấy vị trí và góc xoay ban đầu của từng object bằng [`GET_ANIM_INITIAL_OFFSET_POSITION`](https://github.com/citizenfx/natives/blob/master/PED/GetAnimInitialOffsetPosition.md) và [`GET_ANIM_INITIAL_OFFSET_ROTATION`](https://github.com/citizenfx/natives/blob/master/PED/GetAnimInitialOffsetRotation.md) từ dictionary `missfbi3_weapon_select`. Trong script gốc, gốc scene `Local_127` trùng với tọa độ ghế tĩnh `Local_121`, và góc scene là góc ghế cộng 180 độ. Tuy nhiên track `waterboard_idle_chair` có thể dịch chuyển gốc model khi animation bắt đầu. Khi đặt ghế mới, resource giải ngược vị trí ban đầu của track ghế bằng `GET_ANIM_INITIAL_OFFSET_POSITION`, rồi dùng gốc đã căn này cho ped, trolley và dụng cụ. Trolley và bộ điện vẫn lấy transform từ track của chúng, thay vì đặt theo kích thước hộp bao model.

| Prop trong resource | Model | Clip đặt ban đầu |
| --- | --- | --- |
| `trolley` | `p_cs_trolley_01_s` | `weapon_select_bench_bench` |
| `wrench` | `prop_cs_wrench` | `weapon_select_bench_wrench` |
| `pliers` | `p_pliers_01_s` | `weapon_select_bench_pliers` |
| `electric` | `p_ld_crocclips01_s` | `weapon_select_bench_clip1` |
| `clipRight` | `p_ld_crocclips02_s` | `weapon_select_bench_clip2` |
| `waterboard` | `w_am_jerrycan` | `weapon_select_bench_can` |
| `syringe` | `prop_syringe_01` | `weapon_select_bench_syringe` |
| `battery` | `prop_torture_01` | `weapon_select_bench_battery` |
| `rag` | `p_loose_rag_01_s` | `weapon_select_bench_rag` |

Model `w_am_jerrycan` tương ứng `WEAPON_PETROLCAN` theo [bảng model vũ khí của Cfx](https://docs.fivem.net/docs/game-references/weapon-models/). Game gốc lấy model can qua `GET_WEAPONTYPE_MODEL(WEAPON_PETROLCAN)`.

`stool` và `ecg` không dùng các clip trên. Script gốc đặt stool tại `(143.1199, -2201.345, 4.35)`, ECG tại `(143.1, -2201.345, 4.502)` so với ghế `(142.99, -2201.98, 4.07)` (khoảng dòng 2693–2704). Resource xoay các tọa độ tương đối này theo hướng ghế do người chơi chọn. Chân trolley và stool được hạ/chỉnh theo mặt đất bằng hộp bao của model sau khi xoay; toàn bộ prop trên trolley và ECG dịch cùng object đỡ để giữ bố cục gốc.

## Cầm và chạy scene

Tư thế chưa chọn món dùng `case 0` trong `func_429`: dictionary `missfbi3_weapon_select`, clip `waterboard_idle_victim` và `waterboard_idle_chair`. Nó khác bước chờ của dụng cụ can nước trong `missfbi3_waterboard`. Gốc và yaw của bộ đặt được tính ngược từ transform ban đầu của track ghế; `sceneHeadingCorrection` là hiệu chỉnh thêm, mặc định 0. Khi ngồi ngoài phiên dụng cụ, client nạn nhân chỉ chạy track ped; ghế đứng yên ở vị trí đặt để tránh hai client giành quyền điều khiển.

Trong phiên dụng cụ, actor tạo network scene cho mình và prop. Server chỉ chuyển scene ID khi owner, token, epoch/stage và trạng thái khớp. Client nạn nhân truyền **gốc scene FBI3** và yaw vào `TaskPlayAnimAdvanced` với `AF_OVERRIDE_PHYSICS`, `AF_EXTRACT_INITIAL_OFFSET`, `AF_USE_MOVER_EXTRACTION`, `AF_FORCE_START`, rotation order `2`. Engine áp offset được tác giả lưu trong clip và điều khiển chuyển động capsule. Không truyền kết quả `GetAnimInitialOffsetPosition` làm gốc task: đó đã là vị trí track sau offset, chỉ dùng để đối chiếu trong diagnostic. Xem [cờ animation của Cfx](https://github.com/citizenfx/natives/blob/master/TASK/TaskPlayAnim.md) và [mô tả extraction/physics của RAGE Multiplayer](https://wiki.rage.mp/wiki/Player::taskPlayAnim). `func_428` của FBI3 cũng dùng `TASK_PLAY_ANIM_ADVANCED` với cờ `5129` (loop + not interruptable + override physics + extract initial offset) cho nhánh đứng chọn món. Clip nạn nhân hữu hạn giữ frame cuối, clip chờ lặp; `animTime` lấy từ phase actor nếu scene đã stream. Client nạn nhân không điều khiển ghế/prop hoặc dừng network scene actor. Khi trả món hoặc kết thúc phiên, nạn nhân trở lại clip ngồi của bước chọn món. Cần kiểm tra thời điểm và góc nhìn trên máy chủ thật.

Đã so với `um-ronin-multicharacter/modules/client/modescenario.lua` trong cùng cây resources: resource đó thêm player và ped phụ vào một network scene do một client điều khiển. Mẫu này phù hợp player + NPC, nhưng không xử lý quyền sở hữu của hai player thật. Mẫu hai player trong FiveM-CopAnimations giao mỗi bên chạy task trên ped của mình. `TaskPlayAnimAdvanced` tự thay task hiện tại; không gọi `ClearPedTasks` giữa hai clip liên tiếp vì sẽ tạo khung đứng dậy khỏi ghế. Chỉ xóa task khi thất bại hoặc giải phóng ghế.

Khi cảnh lấy món hoặc một đòn hoàn tất, actor giữ frame cuối và camera qua lượt trao đổi với server. Scene tiếp theo chuẩn bị entity/quyền điều khiển trước khi dừng scene cũ, thay camera sau khi camera mới chạy được, không xóa task hoặc trả ghế về pose tĩnh ở giữa. Các prop phụ trên bàn được trả trong coroutine có kiểm tra phiên, sau khi cảnh chờ đã sẵn sàng; thao tác lấy quyền điều khiển các prop này không chặn menu. Thả người/Thoát/lỗi/restart vẫn dọn toàn bộ scene, camera và ghế.

Khi scene yêu cầu gắn prop vào tay, `func_428` (khoảng dòng 49127–49160) dùng bone `28422` với offset và rotation bằng `0`. Đây là bone `PH_R_Hand` theo [danh sách bone của Cfx](https://github.com/citizenfx/fivem/blob/master/code/client/clrcore/External/BoneID.cs). Khi dùng điện, kẹp thứ hai gắn vào bone `60309` (`PH_L_Hand`). Resource áp dụng hai attachment này khi người chơi cầm kẹp điện, rồi trả cả hai prop về đúng transform ban đầu. Nếu ped thiếu bone `PH_*`, code thử bone bàn tay `SKEL_*` tương ứng.

Script gốc tắt collision cho object dụng cụ khi tạo (khoảng dòng 55542–55545). Resource cũng tắt collision cục bộ cho prop phụ và dụng cụ đã stream vào; ghế và trolley giữ collision để `ox_target` có thể raycast vào chúng. Lựa chọn từng dụng cụ và menu được gắn vào vùng `ox_target:addBoxZone` ôm theo kích thước model trolley. Vùng này nhận cả tia ngắm trúng mặt bàn, dụng cụ hoặc ped đứng sát bàn; `canInteract` dùng điểm raycast trên mặt phẳng bàn để chọn món gần nhất. Menu luôn hiện cho chủ ghế khi phiên rỗng và báo nếu nạn nhân chưa ngồi sẵn sàng. `removeZone` dọn vùng khi thu hồi hoặc dừng resource.

Track prop phải phân biệt không gian scene và không gian bone. Cờ lê và clip lấy món giữ cách chạy scene hiện có. Kìm trong `missfbi3_toothpull` và hai kẹp trong các loop `missfbi3_electrocute` gắn vào tay rồi chạy animation nội bộ của object; không đưa các track này vào world scene. Can nước trong `missfbi3_waterboard` gắn tay, không có track jerrycan trong ánh xạ của `func_429`; khăn vẫn chạy scene riêng cùng actor. Các track gắn tay được khai báo bằng `handProps`, dùng `PlayEntityAnim` và phase của actor; dừng animation nội bộ khi đổi scene hoặc thu hồi. Attachment bone lấy từ game gốc; độ khớp trên freemode vẫn cần kiểm tra trong game.

### Nhánh kìm, điện và nước — v7

Đối chiếu [fbi3.c](https://github.com/YimMenu/GTA-V-Decompiled-Scripts/blob/master/decompiled_scripts/fbi3.c): `func_428` (quanh dòng 49127–49198) dùng `f_23` để phân biệt attach/scene; `func_429` khai báo mặc định attach cho các cảnh kìm và nước. Nhánh scripted animation quanh dòng 123588–123686 gắn kìm vào bone 28422 và blend hai loop nhẹ/mạnh. Nhánh quanh dòng 124120–124280 dùng `Clamp_Wait/Left/Right_Loop`, `Electrocute_Both_Loop`, gắn hai kẹp vào bone 28422/60309 và giữ camera `Clamp_Wait_Loop_Cam`. Không khai báo ghế `Clamp_Wait_Loop_Chair` trong nhánh này.

- Kìm: `Pull_Tooth_Idle → Pull_Tooth_Intro → Pull_Tooth_Loop_Weak/Loop → Pull_Tooth_Outro_B/Outro → Idle`. `Ready_Intro` là bước từ tư thế đang nhổ về tư thế chờ khác, không dùng để bắt đầu từ `Idle`.
- Điện: menu trái/phải dùng `Clamp_Left/Right_Loop`, hai bên dùng `Electrocute_Both_Loop` rồi `Electrocute_Both_Outro`. Ghế tĩnh ở các loop, chỉ chạy track ghế khi outro có khai báo. Không tự suy ra tên camera từ tên actor ở các loop này.
- Nước: `Idle → Kick → Ready_To_Loop → Loop → Finish_Pour → Outro → Idle`. Can vẫn gắn tay. Bản v8 chỉ có option **Dội nước** và **Thoát**; `Kick` là bước nghiêng ghế tự động trong chuỗi dội, không còn action `water_kick`. Không tạo nhân vật Steve của nhiệm vụ gốc.

Resource chuyển nhánh minigame blend theo input của GTA thành các option menu đã thống nhất: loop được chạy trọn `loopMs` trong config, cả actor và victim dùng loop; server tính thời gian từ xác nhận nạn nhân và từ chối báo hoàn tất sớm. Đây không phải bản sao phần điều khiển analog/scaleform của nhiệm vụ. Cờ lê, ống tiêm và mức sát thương của từng option không đổi.

### Dội nước — v8

Người dùng báo dừng sau khi nghiêng ghế và mở can. Kiểm tra tìm thấy ngưỡng server `durationMs / 2` có thể từ chối clip chuyển đã hoàn tất dưới 1 giây; chưa có log runtime xác nhận đây là nguyên nhân duy nhất. Hai bước chuyển nước đặt `minimumMs = 0` để chỉ dựa vào actor hoàn tất và peer readiness; loop gây sát thương vẫn bắt buộc 4000 ms từ xác nhận nạn nhân và cả chuỗi vẫn phải hoàn tất trước khi tính 20 HP. Các đòn khác giữ nguyên ngưỡng cũ. Harness với clip chuyển 800 ms tái hiện việc server v7 hủy và server v8 chuyển bước thành công; 800 ms là dữ liệu thử, không phải độ dài asset đã đo trong game.

Nhánh kết thúc dùng scene **31 → 32** của `func_429`, đúng lệnh `func_428(31, ...)` ở case 4 của luồng nước; scene 30 là quay lại chờ để dội tiếp. Scene 31 dùng actor `Waterboard_Loop_To_Ready_Player`, victim/chair/rag `Waterboard_Loop_*` và camera `Waterboard_Loop_Cam`. Trong bản network, `victimProps.rag` đưa khăn loop cùng clock ghế/nạn nhân để loop nền không kéo dài clip actor ngắn. Hai frame dừng/chuyển scene và cơ chế ped của các dụng cụ khác không đổi.

### Hiển thị scene trên client nạn nhân — v11

Người dùng xác nhận cả hai máy chạy Legacy, actor nhìn đúng nhưng victim đôi lúc thấy actor biến mất/nhảy vị trí/không chạy anim. Chưa có capture runtime hai máy chứng minh nguyên nhân duy nhất. Rà code và đối chiếu mã engine xác định được các lỗi/rủi ro sau:

- `JoinVictimScene` cũ lấy phase 0 khi không có local handle hoặc scene chưa chạy, vẫn phát task nạn nhân và báo ready. Bản v11 đợi cả scene actor, clock ghế riêng nếu có, và clip actor thật trên client nạn nhân; lấy phase sau khi dict đã tải. Hết `sceneReplicationTimeoutMs` (2000 ms) báo `remote_scene_timeout` hoặc `remote_actor_timeout`, không khởi động task nạn nhân bằng phase giả. Không thêm chờ cố định khi scene đã sẵn sàng.
- Một scene trolley cũ chứa 6–7 object. `CStartNetworkSyncedSceneEvent::Parse` trong [ServerGameState.cpp](https://github.com/citizenfx/fivem/blob/master/code/components/citizen-server-impl/src/state/ServerGameState.cpp) chỉ đọc 3/4/5 non-ped tracks theo build; `server.cfg` trên X: cấu hình build 3258, thuộc nhánh 5. Tách bench thành nhóm tối đa 3, mỗi object đúng một nhóm, chỉ một scene chứa actor. Stop/cleanup thu hồi toàn bộ nhóm; không đổi actor clip, origin hay camera.
- `CStartNetworkSyncedSceneEvent::Sanitize` từ chối scene chứa entity thuộc network owner khác nếu chưa cho phép remote scenes. Request control lúc dựng scene không bảo đảm owner trên server còn như cũ lúc gói scene tới. Server bật [SetEntityRemoteSyncedScenesAllowed](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetEntityRemoteSyncedScenesAllowed.md) chỉ trên prop do resource tạo, trong phiên dụng cụ; tắt khi StopTool. Không bật trên ped người chơi. Handler `startNetworkSyncedSceneEvent` bảo vệ các prop đó bằng chủ phiên, trạng thái, bucket, khoảng cách, dictionary của dụng cụ, cùng bộ prop và chỉ ped của chủ ghế. Scene không liên quan resource được bỏ qua. Đây là xử lý rủi ro theo mã engine, chưa có console live xác nhận lần lỗi của người dùng từng bị engine từ chối.
- Join được nhận diện theo token/kind/step/scene và kiểm tra lại sau khi yield; sự kiện trùng không restart task. Sự kiện/luồng cũ không được ghi đè scene mới. Hai ped tham gia được tắt collision với nhau theo từng frame trong phiên để capsule không đẩy nhau khi clip áp sát; hết phiên native tự hết hiệu lực.

Actor vẫn dùng network scene do chính client actor tạo; victim vẫn chỉ task ped của mình. Không force-visible, teleport hoặc chạy task chữa cháy lên ped actor từ máy nạn nhân; không chỉnh server.cfg hay artifact. Không sửa phase mỗi frame trên remote ped. `vx_torture_diag` đọc thêm game build và actor từ góc nhìn client đang gọi: streamed/visible/alpha, vị trí, network owner, dict/clip/playing và network/local scene handle.

Harness: toàn bộ 21 action stage/5 dụng cụ/FX v10 vẫn qua; thêm kiểm tra giới hạn prop từng scene, không gắn actor vào scene phụ, dọn tất cả bench group, scene đến chậm, scene/actor không đến, native trả số 0, duplicate bind, hủy khi đang chờ, quyền prop riêng và từ chối người khác/chèn ped nạn nhân/object ngoài bộ. Các kiểm tra là native mô phỏng, không thay thế OneSync trên hai máy thật.

Sau `restart vx_torture`, đặt bộ mới và kiểm tra cả hai F8 có `scene replication v11 loaded (client)`. Thử chọn → idle → đòn → idle → Thoát cho cả năm món từ góc nhìn nạn nhân. Nếu còn mất hình, chạy `vx_torture_diag` trong F8 của nạn nhân ngay lúc xảy ra, gửi dòng diagnostics cùng `remote_scene_failed`/`peer_join_failed` và console server (`prop_scene_rejected` hoặc cảnh báo sync). Không kết luận đã hết lỗi multiplayer trước khi bước này được xác nhận.

### Âm thanh và particle của toàn bộ dụng cụ — v10

Đã đối chiếu `func_250/251`, `func_429` và nhánh dụng cụ trong [FBI3 gốc](https://github.com/YimMenu/GTA-V-Decompiled-Scripts/blob/master/decompiled_scripts/fbi3.c). `tests/fbi3_effect_reference.json` lưu 17 tên sound, 6 tên particle, URL và SHA-256 nguồn; cả 6 particle cũng được kiểm tra trong dictionary `scr_fbi3` của [danh mục asset](https://github.com/DurtyFree/gta-v-data-dumps/blob/master/particleEffectsCompact.json). Đây là xác minh tên và cách gọi trong nguồn, chưa chứng minh âm thanh phát được trên build server.

| Luồng | Hiệu ứng bổ sung | Mốc/điểm phát |
| --- | --- | --- |
| Chọn dụng cụ | `Choose_Wrench/Pliers/Electric/Water`, `Water_Pick_Up`, `Electric_Hum` | Sound chọn ở đầu scene; lấy can ở phase 0.14; hum ở 0.222, tại battery |
| Cờ lê | `Wrench_Hit_Shin` | Trái 0.393; giữa 0.185; phải 0.245, tại nạn nhân |
| Kìm | `Teeth_Initial_Pain`, `Teeth_Pulling`, `Teeth_Tooth_Out`; `blood_mouth`, `blood_extraction`, `blood_throwaway` | Loop mạnh có máu miệng; outro có extraction ở phase 0.071, bone 31086 + offset (0,0.1,0). Răng `prop_ld_tooth` gắn tay trái actor bone 60309, dọn cuối stage. Tooth_Out: outro 0.01, outro_b 0.06 |
| Điện | Hum, Zap, Spark, `Electrical_Clamp_On/Off`; `elec_smoulder`, `elec_sparks`; rung camera | Smoulder bone 39317; smoke evolution 0 trong shock và giảm 1→0 theo phase outro hai bên; spark tại kẹp; rung ROAD_VIBRATION_SHAKE 0.25 chỉ camera actor |
| Can nước | `Water_Pour_Water`, `dirty_water_pour` | Chỉ loop dội; particle trên can tại (0.15,0.025,0.2), tiếng nước tại nạn nhân |
| ECG/ống tiêm | `Heart_Monitor_Single`, `Heart_Monitor_Flatline`; audio mix ADRENALINE | ECG trên object ecg khi có người ngồi, BPM cấu hình mặc định 80; ngừng beep khi flatline của option quá liều bắt đầu |

Tên sound đầy đủ `FBI_03_*` truyền audioRef NULL (`0`) như nguồn. `Electrical_Clamp_On/Off` và `Teeth_Initial_Pain` dùng `FBI_03_Torture_Sounds`. Audio bank tải với thời hạn 2 giây, quản lý số phiên đang dùng và chỉ `ReleaseNamedScriptAudioBank` sau khi sound đã dừng và không còn phiên cần bank đó. Mỗi client gần ghế phát một bản local, tránh phát network sound/particle trùng do broadcast. Audio mix riêng dụng cụ chỉ áp dụng cho hai người tham gia.

Các điều chỉnh để phù hợp menu hiện tại: tiếng chọn được đặt ở đầu scene thay cho hover trong menu gốc; Intensity nhổ nhẹ/mạnh cố định 0.25/1.0; `Teeth_Initial_Pain` ở intro; spark phase 0.11 và tiếng spark 0.146 được gắn vào shock loop thay cho nhánh input `Electrocute_Spark` riêng; clamp-off phát khi trở về idle (hai bên có thêm outro). Không đổi clip, camera track, origin hay cơ chế sync ped. Không thêm thoại cố định của Trevor/MisterK, nhạc hoặc các audio scene ngoài khu vực dụng cụ. Nguồn không khai báo particle hay sound riêng cho mũi tiêm; dùng audio mix và ECG có thật.

Server chỉ gửi FX sau peer readiness đã xác nhận, kèm network scene ID; client đổi sang local handle rồi đọc phase. Mỗi cue chạy một lần trong stage dù loop quay vòng. Không lấy `durationMs` ước lượng làm mốc va chạm. Stage hữu hạn có watchdog `stageTimeoutMs`; loop dùng `loopMs`. Dọn sound ID, loop particle, răng tạm, camera shake và audio mix khi chuyển/hủy/thoát, mất stream, quá xa, nạn nhân chết hoặc resource dừng. Burst particle tự kết thúc theo asset; không dùng `RemoveParticleFxInRange` để xóa hiệu ứng của resource khác.

`Config.Torture.fx` có công tắc `enabled`, `sounds`, `particles`, `cameraShake`, `audioScenes`, `monitor`, BPM và asset timeout. `effects` trong từng stage/select/idle chứa cue và `atPhase`; chỉnh tại đây nếu build thực tế cần căn lại. Log `audio_bank_timeout`, `particle_asset_timeout`, `particle_start_failed` chỉ lỗi tải/khởi tạo; một sound event im lặng dù bank đã tải vẫn phải kiểm tra bằng nghe trực tiếp.

Kiểm tra: `uv run --with lupa python tests/run_scene_flow.py` kiểm tra 21 stage, phase va chạm, 17 sound name/audioRef, 6 particle/điểm gắn, stream/range, duplicate, hủy trong lúc load, cleanup, nhiều phiên dùng chung bank, ECG và observer không bị rung camera/đổi audio mix. Chưa chạy native âm thanh/particle trên FiveM thật. Sau `restart vx_torture`, F8 và server phải hiện `FBI3 effects v10 loaded`; thử cả 5 món với actor/victim/observer, hai bộ ghế cùng lúc, Thoát và restart giữa mỗi loop.

### Hiệu ứng nước — v9

Code cũ dùng `StartParticleFxNonLoopedOnEntity` tại gốc ped nạn nhân. FBI3 dùng emitter loop `scr_fbi3_dirty_water_pour` trên can `Local_389[0]`, offset `Local_2720 = (0.15, 0.025, 0.2)`, rotation `(0,0,0)`, scale 1 (quanh dòng 2848 và 124689). [Danh mục particle trích từ game](https://github.com/DurtyFree/gta-v-data-dumps/blob/master/particleEffectsCompact.json) xác nhận effect nằm trong dictionary `scr_fbi3`.

Bản v9 tải trước asset khi chọn can, rồi mỗi client gần ghế phát một emitter local trên cùng net entity của can sau lệnh `stageEffect` từ server. Không dùng network emitter khi mọi client đều nhận broadcast để tránh nhân bản hiệu ứng. Server gửi `stopEffects` khi chuyển bước; client còn có hạn tự dừng, dọn khi hủy/restart và kiểm tra phiên sau khi tải asset để coroutine cũ không phát lại nước. Harness kiểm tra can/offset/asset, actor-victim-observer, sự kiện trùng, hủy trước/trong lúc tải và tự dừng; hình ảnh thực tế cần xác nhận trong FiveM.

`tests/fbi3_clip_reference.json` lưu danh sách clip trích từ các nhánh nguồn, URL và SHA-256 của snapshot. Harness không còn coi mọi tên clip đều tồn tại ở ba dictionary này: kiểm tra tên camera, ghế, ped, prop; kiểm tra prop gắn tay không bị thêm vào world scene, loop có đủ thời gian, chuyển clock nước và sát thương một lần. `ValidateSceneAssets` còn kiểm tra `GetAnimDuration` trên client thật, in `missing_scene_clip`/`missing_prop_clip` khi thiếu asset. Snapshot nguồn và harness không chứng minh geometry hay replication trên game build của máy chủ.

## Kiểm tra trực tiếp

Bản client `peer fix v3` thống nhất kiểm tra native actor ở bước start và watchdog: boolean `true` hoặc số khác 0 là thành công; `false`, `nil`, số 0 là thất bại. Trước đây start dùng truthiness nhưng watchdog dùng `== true`, nên kết quả native dạng số có thể làm hủy scene ngay trước xác nhận nạn nhân. Harness tái hiện lỗi lấy cờ lê với mã cũ khi giả lập kết quả `1`; mã sửa qua cùng trường hợp. Đây chưa xác nhận kiểu trả về thực tế trên máy chơi. Khi track mất, diagnostic mới ghi cả giá trị/kiểu native hoặc các scene ID không khớp. Phiên cũng giữ revision từ lệnh prepare/select/idle để broadcast cũ đến muộn không dọn phiên mới; snapshot kết thúc mới hơn vẫn được xử lý.

Actor được đăng ký bằng `NetworkAddPedToSynchronisedScene` **trước** `NetworkStartSynchronisedScene`, theo [trình tự network scene của Cfx](https://github.com/citizenfx/natives/blob/master/NETWORK/NetworkCreateSynchronisedScene.md). Không ghép `TaskSynchronizedScene` vào local handle của network scene đã start: nhánh thử nghiệm này đã bị loại sau báo lỗi lấy dụng cụ. Local handle dùng cho camera và phase. Actor dùng cờ `DONT_INTERRUPT`, `HIDE_WEAPON`, `ABORT_ON_DEATH` và `LOOP_WITHIN_SCENE` khi chờ; không dùng `ON_ABORT_STOP_SCENE` để thay task không dừng clock của prop/camera. `DONT_INTERRUPT` chặn sự kiện ngoài theo [bảng cờ Cfx](https://github.com/citizenfx/natives/blob/master/NETWORK/NetworkAddPedToSynchronisedScene.md). Trước khi báo hoàn tất, kiểm tra actor còn chạy đúng clip và phase của synchronized scene đạt mốc; không bắt buộc `GetEntityAnimCurrentTime` của ped cũng đạt mốc. Cơ chế nạn nhân giữ nguyên. Đây là sửa theo API và kiểm thử giả lập, chưa phải xác nhận runtime trên máy chơi.

Bản `scene clocks v5` thay thế cơ chế phục hồi actor riêng của v4. Log thực tế cho thấy clip cờ lê mất ở 7,448 giây / phase 0,559; điện ở 8,335 / 0,625; nước ở 12,510 / 0,938: cùng suy ra đồng hồ khoảng 13,33 giây. Trong `func_428` FBI3, `Var0.f_22` tách ghế/nạn nhân chờ sang scene 37. Resource áp dụng cùng cách tách với `victimLoop`: actor và dụng cụ dùng scene chính; ghế chờ dùng network scene riêng, nạn nhân lấy phase từ scene ghế qua ID được server chuyển tiếp. Không kéo dài cảnh chọn bằng clip ghế idle.

Khi chuyển chọn → chờ hoặc chờ → đòn → chờ, client dừng toàn bộ scene cũ trước khi thêm ped/prop vào scene mới. Bản `scene handoff v6` sửa lỗi `previous_scene_stop_timeout` của v5: không coi `IsSynchronizedSceneRunning`/`IsEntityPlayingAnim` của scene cũ là xác nhận dừng. [NetworkStopSynchronisedScene](https://github.com/citizenfx/natives/blob/master/NETWORK/NetworkStopSynchronisedScene.md) trả về void; local handle/clip cũ có thể còn trạng thái giữ pose. Client nhả hold-last-frame và loop, gửi stop rồi nhường hai frame xử lý trước khi gán task kế tiếp. Mỗi lượt nhường kiểm tra generation để phiên đã hủy không khởi động lại. Không xóa task ped ở giữa; scene mới thay task cũ và phải qua `WaitForActorTrack` cùng xác nhận nạn nhân trước khi mở menu. Camera cũ giữ đến khi camera mới sẵn sàng. Harness mới giữ trạng thái scene cũ sau stop, tái hiện đúng timeout trên v5 và qua trên v6; đồng thời kiểm tra lệnh stop muộn không xóa task actor/prop mới. Đây là kiểm thử giả lập, chưa xác nhận độ trễ native trên FiveM thật. Không dùng `TaskPlayAnimAdvanced` để phục hồi actor riêng khỏi clock prop/camera nữa.

Đòn hoàn tất theo phase thật. `durationMs` của stage không còn là timeout client cộng 2,5 giây; giới hạn lỗi chung `stageTimeoutMs` là 30 giây ở cả client/server. Một clip chạy 6 giây với ước lượng config 2 giây không còn bị cắt ở 4,5 giây. Các giá trị giới hạn không tạo thời gian chờ khi clip hoàn tất sớm. Harness kiểm tra ba độ dài chọn khác nhau với loop ghế 13,33 giây, victim dùng đúng clock, chuyển scene không làm đứng prop và toàn bộ 21 stage cấu hình. Chưa thay thế kiểm chứng trên FiveM thật.

Lỗi lấy/chờ dụng cụ ghi `[vx_torture] tool_scene_failed reason=...` trong F8: `actor_start`, `actor_track_lost`, `camera_start`, `peer_ready`, `chair_control`, `prop_control:<món>` hoặc `selection_timeout_or_cancelled`. Console server ghi `tool_failed` kèm state/phase/peer trước khi dọn phiên. Thu log cả hai client và server tại cùng lần tái hiện để xác định nhánh thất bại.

Sau `restart vx_torture`, đặt một bộ ghế mới trên nền phẳng. Kiểm tra ghế, chân trolley và stool chạm nền; đầu hai kẹp và từng món nằm đúng theo cảnh gốc trên trolley; target từng món trúng vùng trên bàn; lấy, đổi, trả từng món; hai kẹp vào hai tay và trở lại hai chỗ cũ; sau scene, dụng cụ và ghế không bị lệch. Lặp lại trên freemode nam/nữ và trang phục khác nhau. Các native và animation có thể thay đổi theo build GTA V/FiveM, nên kiểm tra này là bước nghiệm thu cuối.
