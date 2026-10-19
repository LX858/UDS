# Migration to v2

v2 is a breaking cleanup of the boilerplate contract.

## Breaking Changes

- Standalone core: framework and ox integrations are not part of the core public API.
- No hot reload contract: resource restart is the supported development and production
  lifecycle.
- Typed public boundaries: module, NUI, net, and export APIs must define payloads and
  failure modes.
- Neutral TypeBox schemas and sibling NUI/network/export boundary definitions are the
  contract authoring source under `packages/contracts/src/authoring/<module_id>/`.
  Decorated MobX stores remain under `web/src/app/modules/<module_id>/` and are listed in
  the explicit `storeModules` registry. Combined boundaries are listed independently in
  `moduleBoundaries` at `packages/contracts/src/authoring/index.ts`.
- `packages/contracts/src/modules/` is generated output. Existing hand-authored module
  contracts must move to neutral authoring files, decorated stores, and the two explicit
  registries.
- Synchronized state is ownerless. Remove the legacy directional state helpers; Lua and
  NUI can both write, while the Lua bridge sequences canonical revisions and the last
  accepted write wins.
- NUI bridge envelopes use protocol version 2. Browser state commands carry
  `requestId`/`sessionId` without revision; Lua emits full snapshots and completes startup
  with the `core.synced` barrier.
- Release artifacts are produced by deterministic staging instead of shallow zip globs.
- CI targets GitHub Actions, Node.js 24, and pnpm 10.

## Migration Steps

1. Move framework-specific logic into optional bridge modules.
2. Replace arbitrary method dispatch with typed public methods or exports.
3. Move each module's neutral TypeBox schemas to
   `packages/contracts/src/authoring/<id>/<id>.schemas.ts` and its boundary definitions to
   `<id>.boundaries.ts`. Add `authoring/<id>/index.ts` that exports schemas only.
4. Export explicit `<id>NuiBoundary`, `<id>NetworkBoundary`, and `<id>ExportBoundary`
   constants plus combined `<id>Boundaries`. NUI, network, and exports are sibling module
   boundaries.
5. Add `<id>Boundaries` to the explicit `moduleBoundaries` registry in
   `packages/contracts/src/authoring/index.ts`.
6. Keep the MobX class at `web/src/app/modules/<id>/<id>.store.ts`, use
   `@Store({id: 'inventory'})`, add `@State(schema, default)` accessors, then register the
   class in `web/src/app/modules/registry.ts`. Import only state schemas through a module
   subpath such as `@lr/contracts/authoring/inventory`. Boundary files, direct schema-file
   paths, and the root authoring index are not package-exported to browser code.
7. Keep one-to-one parity between `storeModules` and `moduleBoundaries`. Codegen composes
   both registries and rejects missing or extra module IDs.
8. Treat browser generated contracts as state/NUI-only. Net and exports remain in full
   package, Lua, and LuaLS outputs and must not be imported or bundled by web stores.
9. Replace normal UI low-level state wiring with decorated store reads/assignments; keep
   temporary tabs, drafts, hover and modal state undecorated/local.
10. Replace ownership assumptions with conflict-safe ownerless synchronization. Await
   `AppRuntime.flush()` only where code needs all queued browser assignments settled.
11. Configure runtime `onError` for asynchronous transport failures; invalid decorated
   assignment now fails synchronously.
12. Run `pnpm generate:contracts` and commit generated contract/Lua/LuaLS/docs output with
    the canonical schema, boundary, store, and both registry changes. Never edit generated
    artifacts directly.
13. Audit net events for receiver-side validation and authorization. Browser-writable
   synchronized state cannot authorize authoritative server mutations.
14. Build `web/build/**`, verify/package the artifact, and smoke test it in FXServer with
     the protocol-v2 checklist in `docs/RELEASE.md`.

## Compatibility Notes

Existing v1 modules that depend on global framework objects should be treated as bridge
modules during migration. They should not block the core resource from booting when the
framework resource is absent.

Existing hot reload commands should be considered legacy. If development reload support
is reintroduced later, it should be implemented as a separate development tool, not as a
production module lifecycle requirement.

Do not add a dual owner/protocol compatibility path. A v2 browser and Lua bridge must be
deployed together, then the resource restarted so old sessions cannot submit state writes.
