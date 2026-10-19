# Refactor v2 TDD evidence

Tài liệu này ghi lại regression đã dẫn tới implementation v2; kết quả hiện tại phải
được xác nhận lại bằng `pnpm verify` trên checkout đang release.

## RED regressions đã tái hiện

- `Ms.parse("500ms")` từng match `m` trước `ms` và trả `30000000` thay vì `500`.
- Legacy runtime có đường truyền source Lua và `load(source)` qua network.
- Manifest từng khai báo ox/framework/rdr3 và thiếu nested release files.
- NUI từng có nhiều protocol (`action`, `event`, callback name) và generic event string.
- Invalid state với revision rất lớn từng có thể chặn update hợp lệ phía NUI.
- Response spoof/duplicate/late, bucket allocation DoS, nil/false RPC response và disposer
  capture đã được đưa thành Lua transport regressions.
- NUI runtime từng generate contract module mới nhưng chỉ dispatch/expose facade cho
  một module; regression hai-module khóa typed facade, inbound routing và browser mock RPC
  theo registry.
- Invalid bridge identity/error metadata từng bị phản chiếu vào Lua error response.
- Packager từng cho output đi xuyên symlink/junction trước thao tác recursive cleanup.
- LuaLS factory declarations từng đúng trong type-only fixture nhưng bị runtime source
  hạ thành `unknown`; source-aware probes hiện bắt buộc factory trả về class cụ thể.
- Root LuaLS workspace từng index `tests/`, làm test fixtures xuất hiện trong
  Find References/Definitions của production symbols; tooling regression hiện bắt buộc
  editor workspace ignore test sources.
- Root/multi-root LuaLS từng nạp shared workspace binding vào client, làm `LR` bị hạ về
  `LRShared.Namespace` và phát sinh `inject-field`; base declarations giờ không bind global,
  root không nạp namespace `LR`, và từng folder VS Code mirror đúng side config.
- Prototype declarations từng gán `self` của instance method thành `*Class`, khiến VS Code
  báo hàng loạt `inject-field`/`undefined-field` trong `shared/core/application.lua`;
  regression hiện cấm class-table receiver ngoài constructor và kiểm tra application trong
  isolated open-file context.
- Client/server boot từng công khai application và disposer nội bộ trên `LR`; lifecycle
  state giờ là local, boot trả application cho test harness và không làm bẩn public namespace.
- Boilerplate từng phải copy/rename thủ công và chưa có npm initializer. RED regressions
  khóa CLI argument contract, portable resource names, non-empty destination, symlink,
  credential filtering, recursive template exclusion và tarball execution thật.

## GREEN gates

| Guarantee | Command |
|---|---|
| Không `load/loadstring`, `ImplCall` hoặc raw bridge ngoài core | `pnpm test:security` |
| Manifest standalone, GTA5-only | `pnpm test:security` và `pnpm verify:manifest` |
| `500ms` và pure helper đúng | `pnpm test:lua` |
| Module dependency/lifecycle/rollback/cleanup đúng | `pnpm test:lua` |
| Lua schema và generated contract validate đúng | `pnpm test:lua` |
| NUI/net/public transport reject spoof, malformed, oversized và unauthorized | `pnpm test:lua` + web tests |
| Generated artifacts deterministic, side-specific | `pnpm check:contracts` |
| Mọi NUI module trong canonical registry có typed facade/validator/dispatcher | web tests |
| Invalid envelope không bị reflect; package output không traverse link | Lua + tooling tests |
| Client/server/shared diagnostic isolation và `inject-field` regression | `pnpm check:luals` + `pnpm test:tooling` |
| Public Lua factory không trả `unknown` khi source thật được index | LuaLS source-aware type probes |
| Test fixtures không xuất hiện trong production Find References | `pnpm test:tooling` |
| Prototype methods nhận đúng instance type, constructor mới nhận class table | `pnpm check:luals` + `tests/tooling/luals-config.test.mjs` |
| `create-lr-resource` scaffold an toàn từ tarball npm thật | creator coverage + `pnpm test:tooling` |
| Browser app boot, ready, client state render và typed close RPC | `pnpm test:e2e` |
| Authored contracts/codegen/NUI core đạt coverage gate | `pnpm test:coverage` |

Mocks và Fengari kiểm tra protocol/lifecycle nhưng không thay thế manual FXServer/client
QA cho native behavior, focus, resource restart và real network source semantics.

## `create-lr-resource` TDD evidence

User journey: developer chạy `npx create-lr-resource@latest --name <resource>` và nhận
một resource độc lập, đã đổi toàn bộ metadata/workspace nhưng không ghi đè dữ liệu hoặc
đóng gói local credentials/artifacts.

| Guarantee | RED evidence | GREEN evidence |
|---|---|---|
| CLI parse `--name`, positional name và package-manager separator | missing parser/`Unknown argument: --` | 24 creator unit tests pass |
| Tên resource portable và destination không bị overwrite | Windows device names từng được accept | validation, empty/non-empty và binary-copy tests pass |
| Snapshot không follow link, copy secret hay tự lồng template | linked/`.env.local`/`.npmrc` fixtures từng fail | snapshot security tests pass |
| Package thật dùng được qua npm executor | packed CLI từng fail vì thiếu `template/` | `tests/tooling/create-resource-package.test.mjs` pass |
| Authored initializer vượt coverage gate | branch coverage ban đầu `77.35%` | statements `92.36%`, branches `87.20%` |
