# LuaLS side isolation fixtures

These fixtures document the intended Sumneko/LuaLS scopes for this resource.

The project uses three editor scopes:

- `shared`: `types/cfx/shared` + `types/shared`
- `client`: shared libraries + `types/cfx/client` + `types/client`
- `server`: shared libraries + `types/cfx/server` + `types/server`

Do not add `types/client` to the server workspace, or `types/server` to the client workspace.
That would make side-only globals appear in the wrong editor context.

## Automated checks

The official LuaLS diagnosis report command is `lua-language-server --check <workspace> --checklevel=warning`.
It uses the `.luarc.json` in the target workspace unless `--configpath` is passed.

From the repository root, run the pinned LuaLS check:

```powershell
pnpm check:luals
```

Expected diagnostics:

- `client/positive.lua`: no undefined side globals.
- `client/negative_server_leak.lua`: `TriggerClientEvent`, `LRServer`, and server `source` must be undefined.
- `server/positive.lua`: no undefined side globals.
- `server/negative_client_leak.lua`: `SendNUIMessage` and `LRClient` must be undefined.
- `shared/positive.lua`: no undefined side globals.
- `shared/negative_side_leak.lua`: `SendNUIMessage`, `TriggerClientEvent`, `LRClient`, `LRServer`, and server `source` must be undefined.

The runner verifies the exact diagnostic set, so a missing expected diagnostic also fails CI. It uses the bundled/pinned LuaLS 3.19.1 binary or `LUA_LANGUAGE_SERVER` when explicitly configured.
