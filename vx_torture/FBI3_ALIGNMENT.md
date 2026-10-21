# Căn chỉnh prop theo cảnh FBI3 gốc

Nguồn chính là [`fbi3.c` đã decompile](https://github.com/YimMenu/GTA-V-Decompiled-Scripts/blob/master/decompiled_scripts/fbi3.c) của nhiệm vụ GTA V. Đây là dữ liệu kịch bản và animation, chưa phải kết quả kiểm tra trực tiếp trên build FiveM của máy chủ.

Tên clip trưng bày, hai kẹp điện và khăn dùng trong code đã được đối chiếu thêm với [`animDictsCompact.json`](https://github.com/DurtyFree/gta-v-data-dumps/blob/master/animDictsCompact.json). File dump xác nhận tên clip tồn tại; vị trí thực tế vẫn do game tính ở runtime.

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

Khi scene yêu cầu gắn prop vào tay, `func_428` (khoảng dòng 49127–49160) dùng bone `28422` với offset và rotation bằng `0`. Đây là bone `PH_R_Hand` theo [danh sách bone của Cfx](https://github.com/citizenfx/fivem/blob/master/code/client/clrcore/External/BoneID.cs). Khi dùng điện, kẹp thứ hai gắn vào bone `60309` (`PH_L_Hand`). Resource áp dụng hai attachment này khi người chơi cầm kẹp điện, rồi trả cả hai prop về đúng transform ban đầu. Nếu ped thiếu bone `PH_*`, code thử bone bàn tay `SKEL_*` tương ứng.

Script gốc tắt collision cho object dụng cụ khi tạo (khoảng dòng 55542–55545). Resource cũng tắt collision cục bộ cho prop phụ và dụng cụ đã stream vào; ghế và trolley giữ collision để `ox_target` có thể raycast vào chúng. Lựa chọn từng dụng cụ và menu được gắn vào vùng `ox_target:addBoxZone` ôm theo kích thước model trolley. Vùng này nhận cả tia ngắm trúng mặt bàn, dụng cụ hoặc ped đứng sát bàn; `canInteract` dùng điểm raycast trên mặt phẳng bàn để chọn món gần nhất. Menu luôn hiện cho chủ ghế khi phiên rỗng và báo nếu nạn nhân chưa ngồi sẵn sàng. `removeZone` dọn vùng khi thu hồi hoặc dừng resource.

Khi đánh bằng cờ lê, kìm, can nước hoặc kẹp điện, prop được tháo khỏi tay và thêm vào synchronized scene với clip object tương ứng. Dictionary `missfbi3_electrocute` có hai clip `*_r_clip` và `*_l_clip` cho mỗi giai đoạn; resource cho cả hai kẹp chạy cùng scene. Các giai đoạn `missfbi3_waterboard` cũng thêm khăn vào scene bằng clip `*_rag`, rồi trả khăn về trolley khi kết thúc. Game gốc không có tư thế đi bộ tự do với mọi dụng cụ; attachment bone bằng `0` là điểm tựa lấy từ script gốc, còn độ khớp khi chạy/đứng với ped freemode cần kiểm tra trong game.

## Kiểm tra trực tiếp

Sau `restart vx_torture`, đặt một bộ ghế mới trên nền phẳng. Kiểm tra ghế, chân trolley và stool chạm nền; đầu hai kẹp và từng món nằm đúng theo cảnh gốc trên trolley; target từng món trúng vùng trên bàn; lấy, đổi, trả từng món; hai kẹp vào hai tay và trở lại hai chỗ cũ; sau scene, dụng cụ và ghế không bị lệch. Lặp lại trên freemode nam/nữ và trang phục khác nhau. Các native và animation có thể thay đổi theo build GTA V/FiveM, nên kiểm tra này là bước nghiệm thu cuối.
