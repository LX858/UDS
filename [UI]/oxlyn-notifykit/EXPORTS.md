# OXLYN NotifyKit — Exports & Integration

Everything a developer needs to send notifications with **oxlyn-notifykit**: every export (client and
server), every field a notification accepts, the events, the import files, the special formats
(progress, confirm, announcement), and how to make ESX, QBCore, QBox, ox_lib and the other
notification resources use it without touching their scripts.

> The resource name is `oxlyn-notifykit`. If you rename the folder, change the name in your calls
> (`exports['your-name']`) — or use the import files, which follow the rename for you.

---

## Contents

1. [Quick start](#1-quick-start)
2. [The notification table (every field)](#2-the-notification-table)
3. [Client exports](#3-client-exports)
4. [Server exports](#4-server-exports)
5. [Events (no exports needed)](#5-events)
6. [Import files (`Notify.success(...)`)](#6-import-files)
7. [Types](#7-types)
8. [Styles](#8-styles)
9. [Positions](#9-positions)
10. [Text formatting](#10-text-formatting)
11. [Progress notifications](#11-progress-notifications)
12. [Confirm (yes / no with keys)](#12-confirm)
13. [Announcements](#13-announcements)
14. [Frameworks: ESX, QBCore, QBox, ox_lib, ox_core, ND_Core](#14-frameworks)
15. [Replacing another notification resource](#15-replacing-another-notification-resource)
16. [Look, editor and personal settings](#16-look-editor-and-personal-settings)
17. [Commands](#17-commands)
18. [Recipes](#18-recipes)

---

## 1. Quick start

```lua
-- client
exports['oxlyn-notifykit']:Notify('Vehicle stored in the garage.')
exports['oxlyn-notifykit']:Notify('You do not have the keys.', 'error')
exports['oxlyn-notifykit']:Success('Payment received', 'Bank', 4000)

exports['oxlyn-notifykit']:Notify({
    type        = 'money',
    title       = 'Payment received',
    message     = '**$2,500** was added to your account.',
    duration    = 6000,
})

-- server
exports['oxlyn-notifykit']:Notify(source, 'Welcome to the city!', 'info')
exports['oxlyn-notifykit']:NotifyAll({ type = 'announce', title = 'Storm', message = 'Stay inside.' })
exports['oxlyn-notifykit']:NotifyJob('police', { type = 'police', title = '10-80', message = 'Pursuit on Vinewood Blvd' })
```

Every call is safe: a notification with nothing to show is ignored, unknown fields are dropped,
text is escaped, lengths are capped, and a flood of calls is paced (never lost).

---

## 2. The notification table

`Notify(data)` takes a table. Every field is optional except that there must be a `title`, a
`message` or a `progress`.

| Field | Type | What it does |
|---|---|---|
| `message` | string | The text. Aliases: `description`, `text`, `msg`, `content`. Markdown + GTA colour codes, see §10. |
| `title` | string | Bold first line. Aliases: `header`, `caption`. |
| `type` | string | Colour, icon, sound and label (§7). Default `info`. Aliases from other resources resolve on their own (`inform`, `ambulance`, `warn`, `danger` …). |
| `duration` | number (ms) | How long it stays. `0` or `-1` = until hidden. Aliases: `length`, `timeout`. Default `Config.Look.duration` (5000). Minimum 800. |
| `persistent` | boolean | Stays until `Hide(id)` (same as `duration = 0`). |
| `id` | string / number | Gives the notification a name: calling `Notify` again with the same `id` **updates it in place** instead of adding a new one. Needed for `Update`, `Progress`, `Hide`. |
| `style` | string | One of the 72 styles (§8) for this notification only. |
| `position` | string | One of the 9 positions (§9) for this notification only. |
| `icon` | string / table / false | Font Awesome 7 Free class (`'fa-solid fa-car'`, `'fas car'`, `'car'`, `{ 'fas', 'car' }`), an image URL / `nui://` path, or an emoji (`'📦'`). `false` hides the icon. Default: the type's icon. |
| `iconColor` | string | Colour of the icon only (`'#ff0'`, `'red'`, `'rgb(…)'`). |
| `iconAnimation` | string | `spin` · `spinPulse` · `spinReverse` · `pulse` · `beat` · `fade` · `beatFade` · `bounce` · `shake` · `wiggle` · `ring` · `flip` |
| `color` | string | Overrides the type colour for this notification (hex, `rgb()`, or a name: `red` `green` `blue` `yellow` `orange` `purple` `pink` `cyan` `teal` `gold` …). |
| `subtitle` | string | A smaller third line (a street, an account, a subject). Alias: `subject`. |
| `label` | string | A small label / kicker above the title. Styles use it as a code badge (`dispatch`), an app name (`material`), a tag (`breaking`) … |
| `value` | string | A big value on the side: an amount (`receipt`), a level (`levelup`), a quantity (`loot`) … Alias: `amount`. |
| `app` | string | App name shown by the device styles (`mobile`, `material`, `desktop` …). Default: the type label. |
| `time` | string | Time label of the device styles. Default `now`. |
| `avatar` | string | Picture (URL / `nui://` / `https://nui-img/<dict>/<txd>`) used instead of the icon (feed, sms, phone …). |
| `image` | string | A large image inside the notification (a photo, a screenshot). |
| `progress` | number 0-100 | Draws a determinate progress bar (§11). |
| `showProgress` | boolean | Show / hide the time bar for this one. Alias: `showDuration` (ox_lib). |
| `sound` | string / table / false | A sound name (`success` `error` `warning` `info` `message` `money` `alert` `announce` `achievement` `soft`), `false` / `'none'` for silence, a file (`'nui://my-res/sounds/ding.ogg'`, `https://…`), or a GTA frontend sound `{ name = 'PICK_UP', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET', bank = nil }`. |
| `dedupe` | boolean | `false` = never merge with an identical visible notification (default merges into a `×2` badge). |
| `markdown` | boolean | `false` = show `*` `_` `~` literally. |
| `html` | boolean | Render raw HTML — **only** when `Config.Limits.allowHTML = true` (trusted scripts only). |
| `force` | boolean | Shows even when the player has Do Not Disturb on. Alias: `priority = 'high'`. |

Limits (config): title 120 characters, message 600, at most 8 notifications per second per client
(the rest are queued and shown at that pace, up to 30 waiting).

---

## 3. Client exports

All client exports are also available as `Notify.<name>` through the import file (§6).

### `Notify(data | message, type?, duration?, title?)` → id | nil
Shows a notification. Returns the `id` you gave it (or `nil`).
```lua
exports['oxlyn-notifykit']:Notify('Saved.')
exports['oxlyn-notifykit']:Notify('Engine damaged', 'warning', 7000, 'Vehicle')
exports['oxlyn-notifykit']:Notify({ id = 'fuel', type = 'warning', message = 'Low fuel', persistent = true })
```

### `Success` · `Error` · `Warning` · `Info` `(message, title?, duration?)`
Shorthands for the four main types. A table works too: `exports['oxlyn-notifykit']:Error({ message = '…', icon = 'fa-solid fa-lock' })`.

### `Update(id, patch)` → boolean
Changes a notification that is on screen. Only the fields in `patch` change; the timer restarts
unless `keepTimer = true`.
```lua
exports['oxlyn-notifykit']:Update('fuel', { type = 'error', message = 'Out of fuel!' })
exports['oxlyn-notifykit']:Update('upload', { message = 'Almost there…', keepTimer = true })
```

### `Progress(id, value, text?)` → boolean
Sets the progress (0-100) of a notification created with `progress = …` (§11). At 100 it closes by
itself after a moment (unless `autoClose = false` was set with `Update`).

### `Hide(id)` → boolean
Closes a notification.

### `Clear(position?)`
Closes every notification, or only those of one position (`'top-right'` …).

### `Announce(data | message, title?, duration?)` → id | nil
A big announcement with the `Config.Announce` defaults (style `mission`, top-center, 8 s) that
shows even in Do Not Disturb. §13.

### `Confirm(data)` → `true` | `false` | `nil`
Asks a yes / no question answered with two keys (default **Y** / **N**). **Blocks** the calling
thread until the player answers or the time runs out (`nil`). §12.

### `ConfirmAsync(data, cb?)` → requestId
Same without blocking: `cb(answer)` is called later. `data.onAccept`, `data.onDecline`,
`data.onTimeout` work too.

### `Test(style?, type?)`
Shows the four sample notifications (optionally in one style / one type) — what `/notifytest` does.

### `SetDnd(state)` · `SetMute(state)` · `GetPersonal()` → `{ dnd, mute }`
The player's Do Not Disturb and mute switches (also in the history panel). Saved per player.

### `GetStyles()` · `GetStyleGroups()` · `GetTypes()` · `GetPositions()` · `GetLook()`
Read the lists (72 styles, styles by family, every type with its colour / icon / sound / label,
the 9 positions) and the look in use.

### `SetStyle(style)` · `SetPersonalLook(patch | nil)`
Personal look of this player — only when `Config.AllowPlayerSettings = true` (returns `false`
otherwise). `nil` goes back to the server look.

### `OxLib(data)` · `ESX(message, type, length, title, position)` · `ESXAdvanced(sender, subject, message, textureDict)` · `QBCore(text, type, length, icon)`
The same signatures as `lib.notify`, `ESX.ShowNotification`, `ESX.ShowAdvancedNotification` and
`QBCore.Functions.Notify`. They are what the framework bridges call (§14) — use them when you port
code from those frameworks.

### Panels and tools
| Export | |
|---|---|
| `OpenEditor()` · `CloseEditor()` | the in-game editor (admins — the server re-checks every save) |
| `OpenHistory()` · `CloseHistory()` · `IsHistoryOpen()` | the history panel |

---

## 4. Server exports

`source` is a player id, or `-1` for everyone. Anything else (`nil`, `''`, a table — typically a
`source` read after a `Wait`) is refused and the call returns `false`: a private notification can
never reach every player by accident.

### `Notify(source, data | message, type?, duration?, title?)` → boolean
```lua
exports['oxlyn-notifykit']:Notify(source, 'Your order is ready.', 'success')
exports['oxlyn-notifykit']:Notify(-1, { type = 'weather', title = 'Weather', message = 'Thunderstorm incoming' })
```

### `Success` · `Error` · `Warning` · `Info` `(source, message, title?, duration?)`

### `NotifyAll(data | message, type?, duration?, title?)`
Everyone on the server.

### `NotifyJob(jobs, data, onDutyOnly?)` → number of players reached
`jobs` = `'police'`, `{ 'police', 'sheriff' }` or `{ police = 2 }` (minimum grade). ESX, QBCore,
QBox, ox_core and ND_Core (see §14 for what "job" and "on duty" mean in each).
```lua
exports['oxlyn-notifykit']:NotifyJob({ 'police', 'sheriff' }, {
    type = 'police', style = 'dispatch', label = '10-71', title = 'Shots fired',
    subtitle = 'Grove Street · Postal 104', message = 'Multiple callers report gunfire.',
}, true)
```

### `NotifyGang(gangs, data)` → number
Same idea for gangs (QBCore / QBox, and ox_core groups of type `gang`).

### `NotifyRadius(coords, radius, data)` → number
Everyone within `radius` metres of `coords` (vector3 or `{ x, y, z }`). Needs OneSync.

### `NotifyAce(ace, data)` → number
Everyone with an ACE permission (`'group.admin'`, `'my.staff'` …).

### `Announce(data | message, source?)`
An announcement (§13) to everyone, or to one player.

### `Update(source, id, patch)` · `Progress(source, id, value, text?)` · `Hide(source, id)` · `Clear(source, position?)`
The client functions, sent to a player.

### `Confirm(source, data)` → `true` | `false` | `nil`
Asks a player and **waits** for the answer (use it inside a thread / an event handler):
```lua
RegisterNetEvent('garage:sell', function(price)
    local src = source
    local ok = exports['oxlyn-notifykit']:Confirm(src, {
        title = 'Sell vehicle?', message = ('Sell it for **$%s**?'):format(price),
        acceptText = 'Sell', declineText = 'Keep', duration = 20000,
    })
    if ok then --[[ sell ]] end
end)
```

### `ConfirmAsync(source, data, cb)` → requestId
Without waiting: `cb(answer)`. Only the asked player can answer; a player who leaves answers `nil`.

### Look
| Export | |
|---|---|
| `SetLook(patch)` | change the server look (saved in `data/settings.json`, sent to everyone) |
| `SetStyle(style)` | shorthand for `SetLook({ style = style })` |
| `GetLook()` | the server look (config + saved changes) |
| `GetStyles()` · `GetTypes()` | lists |
| `IsAdmin(source)` · `AccessReport(source)` | the admin check used by the editor, with its full report |

---

## 5. Events

If you prefer events (or write from another language):

```lua
-- server → one player (or -1)
TriggerClientEvent('oxlyn-notifykit:notify',   source, { type = 'success', message = 'Done' })
TriggerClientEvent('oxlyn-notifykit:notify',   source, 'Done', 'success', 4000, 'Title')
TriggerClientEvent('oxlyn-notifykit:announce', -1, { title = 'Restart', message = 'in 5 minutes' })
TriggerClientEvent('oxlyn-notifykit:update',   source, 'job-1', { message = 'Step 2 / 3' })
TriggerClientEvent('oxlyn-notifykit:progress', source, 'job-1', 66, 'Step 2 / 3')
TriggerClientEvent('oxlyn-notifykit:hide',     source, 'job-1')
TriggerClientEvent('oxlyn-notifykit:clear',    source)

-- client → the same client
TriggerEvent('oxlyn-notifykit:notify', { message = 'Hello' })
```

---

## 6. Import files

Add one line to another resource's `fxmanifest.lua` and a global `Notify` appears:

```lua
client_script '@oxlyn-notifykit/imports/client.lua'
server_script '@oxlyn-notifykit/imports/server.lua'
```

```lua
-- client
Notify('Hello')
Notify({ type = 'money', message = '+$500' })
Notify.success('Saved')                  Notify.error('Nope')
Notify.warning('Careful')                Notify.info('FYI')
Notify.update('job', { progress = 40 })  Notify.progress('job', 80)
Notify.hide('job')                       Notify.clear()
Notify.announce('Restart in 5 minutes')
local ok = Notify.confirm({ title = 'Join the race?' })
Notify.openHistory()                     Notify.setDnd(true)

-- server
Notify(source, 'Hello')                  Notify.all('Hello everyone')
Notify.job('police', { … })             Notify.gang('ballas', { … })
Notify.radius(coords, 50.0, { … })      Notify.ace('group.admin', { … })
Notify.announce('Restart in 5 minutes')  local ok = Notify.confirm(source, { … })
Notify.setStyle('glass')                 Notify.isAdmin(source)
```
Any other export is reachable by its name in camelCase (`Notify.getTypes()` …).

---

## 7. Types

A type gives the colour, the icon, the sound and the label. 25 are built in:

| Type | Colour | Icon | Sound |
|---|---|---|---|
| `success` | `#34d399` | `fa-circle-check` | success |
| `error` | `#f43f5e` | `fa-circle-xmark` | error |
| `warning` | `#f59e0b` | `fa-triangle-exclamation` | warning |
| `info` | `#3b82f6` | `fa-circle-info` | info |
| `primary` | `#8b5cf6` | `fa-bell` | info |
| `neutral` | `#9ca3af` | `fa-circle-dot` | soft |
| `money` | `#22c55e` | `fa-sack-dollar` | money |
| `bank` | `#10b981` | `fa-building-columns` | money |
| `police` | `#3b82f6` | `fa-shield-halved` | alert |
| `ems` | `#ef4444` | `fa-truck-medical` | alert |
| `fire` | `#f97316` | `fa-fire` | alert |
| `mechanic` | `#eab308` | `fa-wrench` | info |
| `phone` | `#22c55e` | `fa-phone` | message |
| `message` | `#06b6d4` | `fa-comment-dots` | message |
| `mail` | `#6366f1` | `fa-envelope` | message |
| `system` | `#94a3b8` | `fa-gear` | soft |
| `admin` | `#e11d48` | `fa-user-shield` | alert |
| `announce` | `#ec4899` | `fa-bullhorn` | announce |
| `achievement` | `#eab308` | `fa-trophy` | achievement |
| `xp` | `#a855f7` | `fa-star` | achievement |
| `item` | `#14b8a6` | `fa-box-open` | soft |
| `vehicle` | `#0ea5e9` | `fa-car` | info |
| `location` | `#84cc16` | `fa-location-dot` | info |
| `weather` | `#38bdf8` | `fa-cloud-sun` | soft |
| `loading` | `#a3a3a3` | `fa-spinner` (spinning) | none |

**Aliases** (what other resources send): `inform` `information` `default` `normal` → info ·
`notice` → primary · `ok` `done` `check` → success · `err` `danger` `fail` `failed` `bad` → error ·
`warn` `alert` `caution` → warning · `ambulance` `medic` `medical` `doctor` → ems · `cop` `lspd`
`sheriff` `dispatch` → police · `cash` `dollar` → money · `phonemessage` → phone · `sms` `chat` →
message · `email` → mail · `staff` → admin · `server` → system · `broadcast` `announcement` →
announce · `trophy` → achievement · `level` `exp` → xp · `inventory` → item · `car` → vehicle ·
`gps` `waypoint` → location · `progress` `working` → loading. Unknown types fall back to `info`.

**Your own types** — in `config.lua`:
```lua
Config.Types = {
    gang = { label = 'Gang', color = '#a855f7', icon = 'fa-solid fa-skull', sound = 'alert' },
    taxi = { label = 'Taxi', color = '#facc15', icon = 'fa-solid fa-taxi',  sound = 'message' },
}
-- then
exports['oxlyn-notifykit']:Notify({ type = 'gang', message = 'Turf under attack' })
```
Admins can also recolour / re-icon / rename every type in `/notifyeditor ▸ Types` (saved for everyone).

---

## 8. Styles

72 styles in 9 families. `style = '<name>'` on one notification, or pick the default in the editor.

| Family | Styles |
|---|---|
| **Essentials** | `classic` `glass` `soft` `outline` `line` `split` `pill` `minimal` |
| **Devices** | `mobile` `material` `desktop` `aqua` `island` `snackbar` `watch` `lock` |
| **Roleplay** | `feed` `nopixel` `phone` `dispatch` `radio` `sms` `breaking` `receipt` |
| **Gaming** | `achievement` `trophy` `levelup` `quest` `loot` `arcade` `killfeed` `mission` |
| **Cyber** | `neon` `cyber` `hologram` `terminal` `glitch` `synthwave` `circuit` `hud` |
| **Bold** | `solid` `gradient` `brutal` `banner` `ribbon` `tile` `stamp` `duo` |
| **Elegant** | `luxe` `paper` `frost` `mono` `elegant` `velvet` `aurora` `editorial` |
| **Compact** | `toast` `chip` `dot` `ticker` `sidebar` `ring` `bubble` `underline` |
| **Playful** | `comic` `kawaii` `sketch` `retro` `western` `score` `sticker` `candy` |

A few styles always sit at the same place (their design needs it): `island` and `banner` at the
top-centre, `snackbar` at the bottom-centre. The others follow the position you choose.
Styles that make good use of the extra fields: `dispatch` (`label` = code, `subtitle` = street),
`receipt` (`value` = amount), `levelup` (`value` = level), `loot` (`value` = quantity), `breaking`
(`label` = tag), `radio` (`label` = channel), `feed` / `sms` (`avatar`), device styles (`app`).

`/notifytest <style>` previews one style.

---

## 9. Positions

`top-left` · `top-center` · `top-right` · `center-left` · `center` · `center-right` · `bottom-left` ·
`bottom-center` · `bottom-right`

Also accepted: `top` `bottom` `left` `right` `middle`, camelCase (`topRight`), `right-center`,
`middle-left` … (ox_lib, pNotify and okok names all work).
The offset, width, gap, scale and stacking (list / deck) of the stacks are set in the editor.

---

## 10. Text formatting

With `Config.Look.markdown = true` (default):

| Write | Get |
|---|---|
| `**bold**` | **bold** |
| `*italic*` | *italic* |
| `__underline__` | underline |
| `~~strike~~` | ~~strike~~ |
| `` `code` `` | `code` |
| `\n` or `~n~` / `~br~` | a new line |
| `~r~ ~g~ ~b~ ~y~ ~o~ ~p~ ~c~ ~m~ ~q~ ~u~` | GTA colours (red, green, blue, yellow, orange, purple, grey, dark grey, pink, black) |
| `~s~` / `~w~` | back to the normal colour |
| `~h~` | bold on / off |

Everything else is escaped: a player name can never inject HTML. Raw HTML needs
`Config.Limits.allowHTML = true` **and** `html = true` on the notification.

---

## 11. Progress notifications

```lua
local id = 'hack:' .. GetGameTimer()
exports['oxlyn-notifykit']:Notify({ id = id, type = 'loading', title = 'Hacking', message = 'Bypassing the firewall…', progress = 0 })

for p = 10, 100, 10 do
    Wait(400)
    exports['oxlyn-notifykit']:Progress(id, p, p < 100 and ('Layer %d / 10'):format(p // 10) or 'Access granted')
end
-- at 100 it closes by itself; or turn it into a result:
exports['oxlyn-notifykit']:Update(id, { type = 'success', title = 'Done', message = 'You are in.', progress = 100 })
```
A notification with `progress` stays until it reaches 100 (or you `Hide` it).

---

## 12. Confirm

```lua
CreateThread(function()
    local ok = exports['oxlyn-notifykit']:Confirm({
        title = 'Trade request', message = 'Franklin wants to trade with you.',
        acceptText = 'Accept', declineText = 'Decline',   -- labels next to the keys
        acceptKey = 'Y', declineKey = 'N',                -- any key name (client/keys.lua)
        duration = 15000,                                 -- then nil
        type = 'primary', style = 'glass',                -- any other notification field
    })
    if ok == true then print('accepted') elseif ok == false then print('declined') else print('no answer') end
end)
```
- Nothing takes the mouse; keys are read raw and only while the confirm is up. The game actions on
  those keys (team chat on Y, push-to-talk on N) are paused meanwhile (`Config.Confirm.disableGameControls`).
- Typing in the chat never answers (keys are ignored while any NUI has focus).
- Several confirms queue up and are asked one after another.
- From the server: `exports['oxlyn-notifykit']:Confirm(source, data)` (§4).

---

## 13. Announcements

```lua
-- client (this player) / server (everyone)
exports['oxlyn-notifykit']:Announce('The city hall opens at 20:00')
exports['oxlyn-notifykit']:Announce({ title = 'Tsunami warning', message = 'Move to high ground.', type = 'error', style = 'breaking' })
```
Defaults in `Config.Announce` (style, position, duration, type, sound). Announcements show even in
Do Not Disturb. Admins can also use `/notifyall <message>` (works from the server console) or the
editor's **Compose ▸ Announce**.

---

## 14. Frameworks

Notifications need no framework. To make the framework's **own** notification functions (used by
every script of that framework) show NotifyKit notifications, type in the **server console**:

```
notifykit install all          (or: notifykit install esx | qbcore | oxlib)
notifykit status
notifykit uninstall all        (removes the bridge lines)
notifykit restore all          (puts the backup file back — refused when the framework file was
                                updated since; add "force" to do it anyway: notifykit restore esx force)
```
then restart the framework resource (or the whole server).

What it does: it adds **one line** at the top of the framework's notify function, e.g. in
`es_extended/client/functions.lua`:
```lua
function ESX.ShowNotification(message, notifyType, length, title, position)
    if GetResourceState('oxlyn-notifykit') == 'started' then return exports['oxlyn-notifykit']:ESX(message, notifyType, length, title, position) end -- [OXLYN-NOTIFYKIT BRIDGE]
    ...
```
- A backup of the original file is kept next to it (`.oxlyn-backup`) and refreshed on every
  install, so it always matches the framework version you run.
- If NotifyKit is stopped, the framework falls back to its own notifications automatically.
- Framework updates overwrite the line — run `notifykit install …` again after updating.

| Framework | File | Function |
|---|---|---|
| ESX Legacy | `es_extended/client/functions.lua` | `ESX.ShowNotification`, `ESX.ShowAdvancedNotification` |
| QBCore | `qb-core/client/functions.lua` | `QBCore.Functions.Notify` |
| QBox / ox_lib | `ox_lib/resource/interface/client/notify.lua` | `lib.notify` (QBox's notify uses it) |

Prefer to do it by hand? Paste the line yourself (the console prints it for each target with
`notifykit status`).

**Server helpers.** Admin access, `NotifyJob`, `NotifyGang` and the console logs read the
framework on the server (`Config.Framework = 'auto'` detects it: QBox → ESX → QBCore → ox_core →
ND_Core, a started core first). Every call is guarded — a core that is missing, stopped or
throwing counts as "no job / no gang / group `user`", never as an error.

| Framework | `Config.Framework` | Job · grade · on duty | Gang | Framework group (admin) |
|---|---|---|---|---|
| ESX Legacy | `esx` | `xPlayer.job` · `grade` · `onDuty` (true when absent) | — | `xPlayer.getGroup()` |
| QBCore | `qbcore` | `PlayerData.job` · `grade.level` · `onduty` | `PlayerData.gang` | `HasPermission` |
| QBox | `qbox` | `PlayerData.job` · `grade.level` · `onduty` | `PlayerData.gang` | ACE `group.<name>` |
| ox_core | `oxcore` | the owned group of type `job` · its grade · on duty = it is the `activeGroup` (servers that type no groups: the active group is the job) | the owned group of type `gang` | ACE `group.<name>` (ox_core's principals) |
| ND_Core | `ndcore` | `player.job` / the group with `isJob` · `rank` · always on duty (ND has no duty state) | — | a group of `Config.Admin.groups` in `player.groups` (and its `group.<name>` principals) |
| Standalone | `standalone` | — | — | ACE / identifiers only |

ox_core and ND_Core are read through their exports only (`exports.ox_core:GetPlayer` /
`CallPlayer` / `GetGroupsByType`, `exports.ND_Core:getPlayer`) — no `@ox_core` / `@ND_Core` import
in the manifest, so the kit still starts on servers without them.

---

## 15. Replacing another notification resource

Scripts written for these resources work **unchanged**: their exports and events are answered by
NotifyKit (`Config.Compat`), and the manifest `provide`s their names. Remove the old resource from
your `server.cfg`; if it is still running, the matching layer stands by on its own.

| Resource | Answered |
|---|---|
| **esx_notify** | `exports['esx_notify']:Notify(type, length, message, title, position)` · event `ESX:Notify` |
| **okokNotify** | `exports['okokNotify']:Alert(title, message, time, type, playSound)` · event `okokNotify:Alert` |
| **mythic_notify** | `SendAlert` · `DoHudText` · `DoShortHudText` · `DoLongHudText` · `DoCustomHudText` · `PersistentHudText` · `PersistentAlert` · events `mythic_notify:client:*` |
| **pNotify** | `SendNotification({ text, type, timeout, layout })` · `SetQueueMax` · event `pNotify:SendNotification` (its HTML is converted to markdown) |
| **t-notify** | `Alert` · `Custom` · `Image` · `Icon` · `Persist` · events `t-notify:client:*` |
| **brutal_notify** | `SendAlert(title, message, time, type, sound)` |
| **wasabi_notify** | `notify(title, message, time, type, sound, icon, color)` |
| **oxlyn-notify** (older OXLYN) | `ShowNotification(type, title, message, duration)` · `ClearNotifications()` |
| **vms_notify** | `Notification(title, message, time, hexColor, icon)` · event `vms_notify:Notification` |
| **vms_notifyv2** | `Notification({ title, description, time, color, icon, image, progressBar, preset, soundNative })` · `TopNotification({ … })` (top centre) · events `vms_notifyv2:Notification` / `:TopNotification` — `preset` becomes the type |
| **k5_notify** | `notify(title, text, type, duration?)` · event `k5_notify:notify` (`warn` → warning, its custom styles → info) |
| **codem-notification** (CodeM mNotification) | events `codem-notification:Create(text, type, header, duration)` and the older `codem-notification(message, time, type)` — `lspd` → police, `lsfd` → fire, `twitter` → message … |
| **FL-Notify** | `Notify(title, subTitle, content, timeout, type 1–7, position 0–3)` · event `fl:notify` |
| **bulletin** | `Send` · `SendAdvanced` (a `CHAR_*` icon becomes the avatar) · `SendSuccess` / `SendInfo` / `SendWarning` / `SendError` · `SendPinned` → id · `Unpin(id \| ids \| nil)` · `UpdatePinned` · events `bulletin:*` |
| **origen_notify** | `ShowNotification(message)` |
| **renzu_notify** | event `renzu_notify:Notify(type, title, message, { life, sticky, progressbar })` |
| **ox_lib** events | `ox_lib:notify` · `ox_lib:defaultNotify` — only when ox_lib is not running |
| **QBCore** event | `QBCore:Notify` — only when qb-core / qbx_core are not running |
| **ESX** event | `esx:showNotification` — only when es_extended is not running |

The editor's **Setup** tab shows each layer as *active*, *standby* (the real resource is running)
or *off* — `exports['oxlyn-notifykit']:GetCompat()` (client) returns the same list. Any other resource: one line in its client file is enough —
```lua
RegisterNetEvent('myscript:notify', function(msg, kind) exports['oxlyn-notifykit']:Notify(msg, kind) end)
```

---

## 16. Look, editor and personal settings

- **`/notifyeditor`** (admins): style gallery, colours, layout (position, offsets, width, scale,
  radius, gap, max visible, list / deck, entrance animation: slide · glide · swoop · fade · drop ·
  curtain · reveal · bounce · none), behaviour, types, sounds, a composer (send to
  yourself, to everyone, as an announcement, or copy the Lua code) and the setup status. **Save**
  applies to every player and is stored in `data/settings.json` (delete it to go back to
  `config.lua`).
- **Order of precedence**: `config.lua` ← the editor's save ← a player's own settings (only with
  `Config.AllowPlayerSettings = true`) ← the fields of one notification.
- **Players**: `/notifications` opens the history of the session with filters, Do Not Disturb and
  mute; with `AllowPlayerSettings` they can also pick their own style, position and volume there.
- Admin access = ACE `oxlyn.notifykit.admin` OR a framework group in `Config.Admin.groups` (ESX
  group, QBCore permission, ND_Core group, or the `group.<name>` ACE that QBox / ox_core / txAdmin
  use) OR an identifier in `Config.Admin.identifiers` OR your `Config.Admin.check(src)`. `notifyaccess <id>`
  explains the verdict for any player.

---

## 17. Commands

| Command | Who | |
|---|---|---|
| `/notifyeditor` | admin | the editor |
| `/notifytest [style] [type]` | admin | sample notifications |
| `/notifystyle <style> [global]` | everyone / admin | personal (needs `AllowPlayerSettings`) or server-wide style |
| `/notifyall <message>` | admin + console | announcement to everyone |
| `/notifications` | everyone | history panel |
| `notifyaccess <id>` | admin + console | why a player is (not) an admin here |
| `notifykit status \| install \| uninstall \| restore <esx \| qbcore \| oxlib \| all> [force]` | console / admin | framework bridges |

Names and permissions: `Config.Commands` / `Config.Permissions`.

---

## 18. Recipes

**Money received with the amount on the side**
```lua
exports['oxlyn-notifykit']:Notify({ type = 'bank', style = 'receipt', label = 'Maze Bank', value = '+$2,500', message = 'Salary · Los Santos Customs' })
```

**Police dispatch**
```lua
exports['oxlyn-notifykit']:NotifyJob('police', {
    type = 'police', style = 'dispatch', label = '10-90', title = 'Bank robbery',
    subtitle = 'Pacific Standard · Postal 7035', message = 'Silent alarm triggered.', duration = 12000,
}, true)
```

**Phone message with a picture**
```lua
exports['oxlyn-notifykit']:Notify({ type = 'message', style = 'sms', title = 'Lamar', message = 'Yo, where you at?', avatar = 'https://example.com/lamar.png' })
```

**Level up**
```lua
exports['oxlyn-notifykit']:Notify({ type = 'xp', style = 'levelup', value = '12', title = 'Mechanic level 12', message = '+ Engine tuning unlocked' })
```

**A persistent status you update**
```lua
exports['oxlyn-notifykit']:Notify({ id = 'zone', type = 'location', title = 'Safe zone', message = 'Weapons disabled', persistent = true })
-- later
exports['oxlyn-notifykit']:Hide('zone')
```

**One notification that never merges**
```lua
exports['oxlyn-notifykit']:Notify({ message = 'Tick', dedupe = false })
```
