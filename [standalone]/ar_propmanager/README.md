
![Banner](https://raw.githubusercontent.com/gist/Colbss/c3924e7b6c38089bda9754b19b0c2448/raw/ed14642ceab7a11e6451c8471cad273791775a21/ar_prop_manager.svg)

<img src="https://i.imgur.com/PG7Tx1d.png" width="50%"><img src="https://i.imgur.com/64uxRpX.png" width="50%">

Elevated user preview available on [streamable](https://streamable.com/t8yx3k)

Restricted user preview available on [streamable](https://streamable.com/d30vsa)

---

## Features

### Prop placement & editing
- Live updated searchable list of props (credit [DurtyFree](https://github.com/DurtyFree/gta-v-data-dumps/blob/master/ObjectList.ini))
- 3D gizmo for precise translate and rotate manipulation (no gimbal lock!)
- Manual coordinate input - type exact X/Y/Z position and rotation values directly in the gizmo overlay
- Copy and paste position / rotation vectors (resource restricted)

### Prop management
- Edit existing props
- Outline props for easy identification
- Teleport directly to any prop's location
- Delete props with server-side access checks

### Groups
- Organize props into named groups
- Toggle entire groups on/off

### Prop expiry
- Optional expiry timestamp per prop
- Server-side cron job automatically removes expired props and broadcasts removals to all clients
- Expiry check interval is configurable in `config.lua`

### Player access system
- Grant specific players access to manage props in designated groups without requiring a full admin ACE
- Optional zone restrictions - restrict a player's access to within drawn area

### Map view
- Interactive map showing all props as clusters or heatmap
- Click a prop marker to jump to it in the prop list

### Permission levels
Levels are cumulative - each level includes all levels below it.

| Level | ACE (default) | Permissions |
|-------|--------------|-------------|
| 0 | *(player access entry)* | Manage props in explicitly granted groups, within optional zone restrictions |
| 1 | `mod` | Toggle prop groups on / off |
| 2 | `admin` | Add, move, and delete props; view the map |
| 3 | `superadmin` | View and edit the player access list |

### Exports
Other resources can open the gizmo for any **non-networked** entity:

```lua
exports.ar_propmanager:OpenGizmo(entity, options, onFinish, onCancel)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `entity` | `number` | Entity handle to manipulate |
| `options` | `{ restrictRotationAxes?: boolean } \| nil` | Gizmo options |
| `onFinish` | `fun(position, quaternion)` | Called with final position and quaternion when confirmed |
| `onCancel` | `fun(entity)` | Called with the entity handle when cancelled |

---

## Requirements

- [ox_lib](https://github.com/CommunityOx/ox_lib)
- [oxmysql](https://github.com/CommunityOx/oxmysql)

## Install

1. Download the latest [release](https://github.com/Colbss/ar_propmanager/releases/latest)
2. Add `ensure ar_propmanager` to your `server.cfg`
3. Configure ACE permissions and the expiry cron in `config.lua`
4. Check / set up the framework bridge for your framework

## Frameworks

This script is framework agnostic, however you must set up the necessary logic for your framework. An example is provided for `qbx_core` under `modules/bridge/`.

## License

Licensed under the GNU General Public License v3.0 (GPL-3.0).
See the LICENSE file for details.
