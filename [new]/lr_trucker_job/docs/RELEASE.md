# Release and FXServer QA

Resource release dùng GitHub tag `v*.*.*`; package initializer `create-lr-resource` được
publish riêng lên npm. Cả hai dùng Node 24 và pnpm 10.32.1. Ubuntu chạy full
verify/build/package; Windows chạy smoke để bắt lỗi path. GitHub CLI tạo release từ ZIP.

## Local release gates

```powershell
pnpm install --frozen-lockfile
pnpm --filter web exec playwright install chromium
pnpm generate
pnpm check:cfx
pnpm verify
pnpm package
```

Push vào `main` chạy full Ubuntu verify và Windows smoke. Sau khi cả hai pass, job
`publish-npm` đọc `packages/create-lr-resource/package.json`: version đã tồn tại thì skip,
version mới thì publish bằng npm Trusted Publishing/OIDC. Workflow không dùng
`NPM_TOKEN` dài hạn.

Thiết lập trust một lần cho package bằng npm CLI 11.15+ (lệnh yêu cầu browser/2FA):

```powershell
npm trust github create-lr-resource --file autorelease.yml --repo Lorraxs/lr_trucker_job --allow-publish --yes
npm trust list create-lr-resource
```

Mỗi release initializer phải bump `packages/create-lr-resource/package.json`; commit không
bump version sẽ không publish lại. Để kiểm tra hoặc publish thủ công khi pipeline bị sự cố:

```powershell
pnpm --filter create-lr-resource pack
npm publish ./packages/create-lr-resource --access public
npm view create-lr-resource version
```

Máy publish thủ công phải trả về account hợp lệ từ `npm whoami`; không bypass
authentication hoặc publish lại một version đã tồn tại. OIDC job cần `id-token: write`,
GitHub-hosted runner và trusted publisher trỏ chính xác tới workflow `autorelease.yml`.

Build/release thường không tự tải native metadata. Khi chủ động nâng snapshot Cfx,
chạy `pnpm update:cfx`, review thay đổi ở lock/snapshot/generated declarations, rồi chạy
`pnpm verify`. Cơ chế này tránh việc upstream thay đổi âm thầm làm autocomplete khác
giữa developer và CI.

Package script stage mọi local path trong `fxmanifest.lua`, giữ nested directories và
ghi `release-manifest.txt`. Artifact phải có Lua runtime, generated schemas, config,
locale và `web/build`; không chứa `node_modules`, caches, test output hoặc `web/src`.

Nếu máy Windows không có `zip`, kiểm tra staging bằng:

```powershell
node tooling/scripts/package-resource.mjs --root . --out dist/release --name lr_trucker_job --no-zip
```

## Manual FXServer/client checklist

1. Start resource standalone, không start framework/ox dependency.
2. Xác nhận shared/main/trucker modules start đúng và không missing file.
3. Mở NUI; xác nhận protocol v2 `core.ready` ACK, full initial snapshots và
   `core.synced` cùng `sessionId` hoàn tất trước khi app báo started.
4. Lua `Set/Patch` synchronized state; UI decorated store render full snapshot và Lua
   revision tăng.
5. Gán decorated store từ NUI; xác nhận optimistic render, serialized write, Lua watcher
   nhận giá trị và canonical ACK/snapshot reconcile đúng.
6. Test low-level browser `state.set` và object `state.patch`; command có
   `requestId`/`sessionId`, không có revision, Lua response có canonical revision.
7. Xen kẽ Lua và browser writes; xác nhận write hợp lệ được Lua bridge chấp nhận sau cùng
   thắng và stale session không thay đổi state.
8. Gán decorated `@State` sai schema; xác nhận throw đồng bộ. Làm transport fail; xác nhận
   runtime `onError` nhận lỗi và `AppRuntime.flush()` chờ hết pending writes.
9. Test NUI RPC cả hai hướng, gồm success, handler error và timeout.
10. Test authorized và unauthorized client-to-server mutating RPC; synchronized NUI state
    không được dùng để bypass server authorization.
11. Gửi malformed/oversized payload, browser state command có revision và request ID reuse
    sai nội dung; xác nhận bị reject trước handler và không leak stack.
12. Test Escape/close; focus và visibility được dọn.
13. Restart resource/browser session; old `sessionId` bị reject và không còn duplicate
    handler, timer, subscription hoặc pending RPC.
14. Kiểm tra client/server console không có missing file hoặc late-response noise bất thường.
15. Lần lượt chọn `esx`, `qbcore`, `qbx`; start framework trước resource, xác nhận bridge
    acquire đúng API, normalized player/job data và notification trên cả client/server.
16. Với mỗi framework, logout rồi load character khác; xác nhận unload/data subscriptions
    không duplicate và player module đã start vẫn tự clear/rebind state đúng.
17. Chọn explicit framework khi resource thiếu hoặc start sai order; xác nhận startup fail
    rõ ràng. Chạy `auto` với nhiều framework cùng started; xác nhận ambiguous selection fail.
18. Stop/restart resource; xác nhận framework event handlers được remove và không callback
    stale. Không dùng framework lifecycle event để bypass server RPC authorization.

## Rollback

Không có database migration. Nếu v2 artifact lỗi production, rollback về tag/artifact v1;
không bật dual protocol trong cùng release. Contract/type metadata được pin và committed,
do đó có thể quay lại snapshot trước bằng revert release commit.
