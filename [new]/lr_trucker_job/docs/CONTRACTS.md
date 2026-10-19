# Contracts v2

Canonical source được tách theo trách nhiệm. Neutral TypeBox schemas và boundary
definitions nằm trong `packages/contracts/src/authoring/<module_id>/`; decorated MobX
store nằm trong `web/src/app/modules/<module_id>/`, còn explicit `storeModules` registry
nằm tại `web/src/app/modules/registry.ts`. Explicit `moduleBoundaries` registry nằm trong
`packages/contracts/src/authoring/index.ts`. `tooling/codegen` compose `@State` metadata
từ `storeModules` với sibling boundaries từ `moduleBoundaries`, đồng thời validate
one-to-one parity trước khi sinh contract.

`packages/contracts/src/modules/*.contract.ts` và `packages/contracts/src/modules/index.ts`
là generated artifacts. Không thêm hoặc sửa module contract trực tiếp trong đó.

## Supported schema subset

- object, array, record;
- string, integer, number, boolean;
- literal, enum, optional, nullable và discriminated union;
- min/max, length và pattern cơ bản;
- `additionalProperties: false` mặc định.

Generator reject recursive schema, custom runtime type, `Unsafe`, Transform, function,
class instance, `Date`, `BigInt`, userdata/vector và cyclic table. Dữ liệu qua boundary
phải là DTO JSON.

## Module boundaries

Một module thường có các file sau:

```text
packages/contracts/src/authoring/inventory/inventory.schemas.ts
packages/contracts/src/authoring/inventory/inventory.boundaries.ts
packages/contracts/src/authoring/inventory/index.ts
packages/contracts/src/authoring/index.ts
web/src/app/modules/inventory/inventory.store.ts
web/src/app/modules/registry.ts
```

Schemas và boundary definitions là neutral TypeScript authoring source:

```ts
// packages/contracts/src/authoring/inventory/inventory.schemas.ts
import Type from 'typebox';

export const InventorySnapshotSchema = Type.Object({
  items: Type.Array(
    Type.Object({
      id: Type.String({minLength: 1, maxLength: 64}),
      count: Type.Integer({minimum: 0}),
    }),
    {maxItems: 200}
  ),
});

// packages/contracts/src/authoring/inventory/inventory.boundaries.ts
import Type from 'typebox';
import {rpc, type ModuleBoundaries} from '../../index';
import {InventorySnapshotSchema} from './inventory.schemas';

const EmptySchema = Type.Object({});

export const inventoryNuiBoundary = {
  events: {toNui: {}, toClient: {}},
  rpc: {toNui: {}, toClient: {}},
} as const satisfies ModuleBoundaries['nui'];

export const inventoryNetworkBoundary = {
  events: {clientToServer: {}, serverToClient: {}},
  rpc: {
    clientToServer: {
      refresh: rpc(EmptySchema, InventorySnapshotSchema),
    },
    serverToClient: {},
  },
} as const satisfies ModuleBoundaries['net'];

export const inventoryExportBoundary = {
  client: {
    getSnapshot: rpc(EmptySchema, InventorySnapshotSchema),
  },
  server: {},
} as const satisfies ModuleBoundaries['exports'];

export const inventoryBoundaries = {
  nui: inventoryNuiBoundary,
  net: inventoryNetworkBoundary,
  exports: inventoryExportBoundary,
} as const satisfies ModuleBoundaries;
```

NUI, network và exports là sibling module boundaries, không phải các phần thuộc browser
store. Mỗi boundary file export explicit `<id>NuiBoundary`, `<id>NetworkBoundary` và
`<id>ExportBoundary`, sau đó ghép chúng thành `<id>Boundaries`. Đăng ký combined constant
trong explicit boundary registry. Public per-module index chỉ export schemas:

```ts
// packages/contracts/src/authoring/inventory/index.ts
export * from './inventory.schemas.ts';

// packages/contracts/src/authoring/index.ts
import {inventoryBoundaries} from './inventory/inventory.boundaries';

export const moduleBoundaries = Object.freeze({
  inventory: inventoryBoundaries,
});
```

Decorated store chỉ khai báo module ID và synchronized state. Store import state schemas
qua public per-module subpath, không import direct schema path:

```ts
// web/src/app/modules/inventory/inventory.store.ts
import {State, Store} from '@lr/nui-store';
import type {ContractStatic} from '@lr/contracts';
import {InventorySnapshotSchema} from '@lr/contracts/authoring/inventory';

@Store({id: 'inventory'})
export class InventoryStore {
  @State(InventorySnapshotSchema, {items: []})
  accessor snapshot!: ContractStatic<typeof InventorySnapshotSchema>;
}
```

Package chỉ expose per-module `@lr/contracts/authoring/<module_id>` entrypoint cho browser.
Boundary files và root authoring index không được package-export; web stores không được
import chúng. Mỗi per-module `index.ts` chỉ re-export schemas để net/exports không đi vào
browser bundle.

Mỗi `@State(schema, default)` cần default hợp lệ. Object state tự có generated patch
schema. State không có owner; Lua và NUI đều có thể write. Store có thể thêm computed
getter/method bình thường, nhưng chỉ accessor có `@State` đi qua boundary.

Đăng ký store tường minh để codegen và AppRuntime cùng thấy module:

```ts
// web/src/app/modules/registry.ts
import {InventoryStore} from './inventory/inventory.store';

export const storeModules = {
  inventory: InventoryStore,
} as const;
```

Registry key phải trùng `@Store` ID và ID không được trùng nhau. Mỗi ID trong
`storeModules` phải có đúng một entry cùng ID trong `moduleBoundaries`, và boundary
registry không được có ID thiếu store. RPC có request, response, timeout và có thể có
`mutating`/`rateLimit` metadata. Mọi section `nui`, `net`, `exports` phải tồn tại dù map
bên trong rỗng.

Browser generated contracts chỉ chứa synchronized state và NUI endpoints. Net và exports
vẫn có trong full `packages/contracts/src/modules/`, Lua runtime schemas và side-isolated
LuaLS declarations, nhưng không được import hoặc bundle bởi web stores.

## Canonical NUI envelope

Một endpoint duy nhất: `lr_bridge`.

```ts
interface BridgeEnvelope {
  version: 2;
  module: string;
  kind:
    | 'state.snapshot'
    | 'state.set'
    | 'state.patch'
    | 'event'
    | 'rpc.request'
    | 'rpc.response'
    | 'rpc.error';
  name: string;
  requestId?: string;
  sessionId?: string;
  revision?: number;
  payload?: unknown; // internal transport only, validated before feature code
  error?: {code: string; message?: string};
}
```

Protocol-v2 state rules:

- Browser gửi command `state.set` hoặc `state.patch` với `requestId` và `sessionId`, không
  gửi `revision`.
- Lua validate command, áp write vào canonical state, cấp revision tăng đơn điệu và trả
  ACK `rpc.response` chứa full canonical payload cùng revision.
- Lua luôn publish full `state.snapshot`; `Patch` chỉ là write command, không phải dạng
  snapshot mà feature code phải tự merge.
- Lua bridge là canonical revision sequencer. Lua write và browser write dùng cùng commit
  path; write hợp lệ được chấp nhận sau cùng thắng.
- Request ID replay giống hệt nhận lại ACK cũ; reuse ID cho command khác bị reject.
- Browser bỏ snapshot sai session hoặc revision không mới hơn canonical revision đã thấy.

Handshake bắt đầu bằng `core/event/ready` có `sessionId`. Sau ACK, Lua gửi full initial
snapshots rồi `core/event/synced` cùng session. Browser `ready()` chỉ resolve sau barrier
`core.synced`. Không tồn tại protocol song song `action`, `event/data` hoặc callback name
tùy ý. NUI payload tối đa 256 KiB, RPC mặc định 5 giây và tối đa 60 giây.

## Network and exports

Raw network chỉ dùng các event cố định namespaced theo resource: `net:c2s`, `net:s2c`
và `net:response`. Payload request/response tối đa 128 KiB, RPC mặc định 10 giây/tối
đa 30 giây. Server áp coarse per-source ingress limit trước encode/route, rồi endpoint
token bucket; mutating endpoint bắt buộc authorization. Duplicate/replay request bị
chặn theo `source + requestId` bằng expiry queue partition theo player.

Public export có deterministic name `<module>_<method>`. Provider và consumer chỉ thấy
method allowlisted trong generated API; request và response đều validate và bound 128
KiB. Export `mutating: true` bắt buộc provider đăng ký `Authorize(invokingResource,
request)` và `Execute(invokingResource, request)`; caller không xác định hoặc không được
authorize sẽ fail closed.

## Generation workflow

```powershell
pnpm generate:contracts
pnpm check:contracts
```

Artifacts gồm Lua runtime schema, LuaLS declaration theo side, generated TypeScript và
contract docs, bao gồm `packages/contracts/src/modules/`. Thêm module bằng neutral
schemas/boundaries, entry trong `moduleBoundaries`, decorated store và entry trong
`storeModules`; không sửa generated package registry hoặc NUI dispatcher. Generation hai
lần phải byte-identical; CI fail khi generated output drift. Commit canonical schema,
boundary, store, hai registry và generated outputs cùng nhau.
