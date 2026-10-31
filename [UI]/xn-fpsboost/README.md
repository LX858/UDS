# Oxlyn · FPS Boost V2

An FPS monitor and optimiser with a liquid glass panel: real measurements, six
presets, eighty-seven individual settings, a before/after benchmark that runs on
the player's own machine, entity cleanup and an adaptive layer that tightens the
game while the player is away and gives it back when they return.

It measures every single frame — not a sample every second — so the average, the
1% low and the 0.1% low in the panel are the same numbers a benchmarking tool
would give you. And it never invents a number: what the game cannot tell us is
either badged `EST` or simply not shown.

* **Frameworks** — ESX · QBCore · Qbox · standalone
* **Notifications** — built-in · ox_lib · framework · native · chat · your own
* **Languages** — 12 included (EN, PT, ES, FR, DE, PL, NL, IT, TR, RU, CS, SV)
* **Dependencies** — none. No database, no `oxmysql`, no UI build step.
* **Cost** — one thread at `Wait(0)` for the whole resource, and it is the one
  that measures the frame time

---

## Table of contents

1. [Installation](#installation)
2. [What it measures](#what-it-measures)
3. [The panel](#the-panel)
4. [Presets](#presets)
5. [The benchmark](#the-benchmark)
6. [The floating HUD](#the-floating-hud)
7. [Entity cleanup](#entity-cleanup)
8. [Automation](#automation)
9. [Configuration](#configuration)
10. [Commands and keys](#commands-and-keys)
11. [Admins and restrictions](#admins-and-restrictions)
12. [Exports](#exports)
13. [Translating](#translating)
14. [Performance](#performance)
15. [Troubleshooting](#troubleshooting)

---

## Installation

**1.** Drop the folder into your `resources` directory. It must be named
`oxlyn-fpsboost` — the exports are documented under that name.

**2.** Add it to your `server.cfg`:

```cfg
ensure oxlyn-fpsboost
```

**3.** Give yourself admin access, if you want the admin panel (optional):

```cfg
add_ace group.admin oxlyn.fps allow
```

**4.** Restart the server and press **F7**.

That is the whole installation. There is no database to import, no items to add
and no UI to build.

### Requirements

* FiveM server build **7290** or newer
* A framework is **not** required — the resource runs standalone and only uses
  the framework it finds for admin groups and notifications

---

## What it measures

A resource cannot read your hardware. There is no native that returns CPU usage,
GPU usage, temperatures or VRAM. Any script showing you "CPU 45 °C" is making
the number up.

This one is explicit about the difference:

| Real — read from the game | Estimated — badged `EST` in the UI |
| --- | --- |
| Instant FPS and frame time | CPU load |
| Average, 1% low, 0.1% low, min, max | GPU load |
| Median and frame time stability | RAM pressure |
| Ping to the server | VRAM pressure |
| Peds, vehicles, objects, total entities | |
| Screen resolution, Lua memory, resource count | |
| Players online, session time | |

The estimates are derived from real signals — CPU load from frame time variance,
GPU load from the average frame time against the best one seen this session — so
they are useful as a **trend**, not as an absolute value. Set
`Config.Metrics.showEstimates = false` and the rings disappear; the layout
adjusts on its own.

Temperatures are never shown, in any edition. They cannot be read.

---

## The panel

**F7**, or `/fps`. Seven views:

| View | What it holds |
| --- | --- |
| **Overview** | The big FPS number, the live chart, the averages and the lows, the estimate rings, and performance tips written for what is actually happening |
| **Performance** | The six presets, the benchmark, and the saved custom profiles |
| **Graph** | FPS, frame time, ping or entities over 1 min, 5 min, 15 min or 1 hour, with the real min/max band |
| **System** | Everything the game will tell us about the machine and the session |
| **Settings** | All 87 settings, by group, with an impact and a visual-cost badge on each one |
| **Admin** | Every player's FPS, sortable, with "force preset" — admins only |
| **About** | Version, credits, language picker |

Everything a player changes is saved on **their own machine** (FiveM KVP), so it
survives reconnects and server restarts without a single database row.

---

## Presets

| Preset | What it does |
| --- | --- |
| **Off** | Untouched game. Nothing applied. |
| **Light** | Small gain, no visual loss. Safe for roleplay. |
| **Balanced** | The recommended one. Noticeable gain, the city still looks like the city. |
| **Performance** | Large gain. Shadows, effects and population clearly reduced. |
| **Extreme** | For weak machines. The game stays playable and stops being pretty. |
| **Potato** | The floor. Everything off, LOD at 10%. |

A player can also build their own from the 87 settings and save it as a named
profile (up to six, `Config.MaxCustomPresets`).

Presets live in `Config.Presets`. Add, remove or rewrite them freely: a preset is
a list of setting IDs and values, and any ID it does not mention keeps the
schema default.

---

## The benchmark

"This preset gives +40 FPS" is a meaningless sentence — the gain depends on the
hardware, the area of the map, the time of day and the resources your server
runs. So instead of promising a number, the resource measures it:

1. Closes the panel (the interface itself costs GPU and would falsify the test)
2. Measures 8 seconds with the current settings → **before**
3. Applies the preset being tested
4. Waits 1.5 s for streaming to settle → discarded
5. Measures 8 seconds → **after**
6. Reverts, and shows the comparison

The statistics window is cleared before each phase, so the "after" never drags
frames from the "before". Timings are in `Config.Preview`.

A player can also benchmark the settings they just changed and have not saved
yet — the draft — and the result card offers to save it as a profile.

---

## The floating HUD

A small panel that stays on screen with the panel closed: FPS, frame time,
1% low, ping, entity count and a sparkline. Every row is optional, and so is the
whole HUD.

Position, scale, opacity and which rows to show are player settings (group
`hud`). Toggle it with `/fpshud`, with a key you bind in `Config.Keys.hud`, or
from the interface.

If another resource on your server already draws an FPS counter, put its name in
`Config.Integration.conflictingHudResources` and this HUD will not start enabled
by default.

---

## Entity cleanup

Removes abandoned props, empty vehicles and dead peds that no longer belong to
anyone. It is off by default and it is **conservative on purpose**:

* Nothing closer than `CleanupSafety.minDistance` (45 m) is touched — cars do not
  vanish in front of the player
* Never touches mission entities, entities with a player in them, or the
  player's own vehicle
* Never touches anything listed in `CleanupSafety.protectedModels`
* At most `maxPerPass` (40) entities per category per pass, so the cleanup itself
  cannot cause a stutter

Put your server's persistent vehicles and props in `protectedModels`, by name or
hash, and they are safe even if everything else about them looks abandoned.

---

## Automation

**The adaptive layer** puts a temporary overlay on top of the player's preset:
in the pause menu, while they are away from the keyboard, or indoors. It only
ever tightens, never loosens, and it is lifted the moment the situation ends —
the player's own settings are never overwritten. Configure it in
`Config.Adaptive`.

**Auto-boost** moves the player up a preset when the average FPS stays below a
floor, and back down when it recovers above a ceiling. Off by default; it is a
player setting (`autoBoost`), with a floor, a ceiling and a cooldown.

**The low FPS alert** notifies the player when the average stays under a
threshold for 15 continuous seconds. Also a player setting.

---

## Configuration

Everything lives in `config.lua`, in twelve numbered sections, and every option
has a comment explaining what it does and what it costs:

| Section | What it controls |
| --- | --- |
| 1 · General | Locale, framework, debug, startup banner |
| 2 · Commands and keys | Every command name and the default keys |
| 3 · Admin permissions | Groups, ACE, console |
| 4 · Monitoring | Sample rate, history, statistics window, tick rates |
| 5 · System metrics | Estimates on/off, FPS and ping thresholds |
| 6 · Presets | The six presets and the custom profile limit |
| 7 · Settings schema | The 87 settings: type, default, range, impact, group |
| 8 · Preview | Benchmark timings |
| 9 · Notifications | Type, duration, sounds |
| 10 · Restrictions | Locked settings, locked presets, maximum preset |
| 11 · Telemetry | Server-side FPS summaries for the admin view |
| 12 · Integration | Blocking conditions and conflicting resources |

The settings schema is where the resource is actually defined: each entry
declares what a setting is, what it may be, and how much it costs visually. The
interface is built from it, presets are validated against it, and the
optimisation engine reads it. Adding a setting means adding an entry — the UI
picks it up on its own.

### Notifications

`Config.Notify.type` takes `'ui'` (the resource's own toast, recommended),
`'auto'` (your framework's), `'native'`, `'chat'` or `'none'`. If you use
something else, there is one function to point at it — the whole notification
path goes through `shared/bridge.lua`.

---

## Commands and keys

| Command | What it does |
| --- | --- |
| `/fps` | Opens and closes the panel (also `/fpsboost-menu`, `/oxlyn`) |
| `/fpshud` | Toggles the floating HUD |
| `/fpsboost <preset>` | Applies a preset directly, e.g. `/fpsboost performance` |
| `/fpsreset` | Resets the player's settings back to the config defaults |
| `/fpsstats` | Prints a summary in chat: average, 1% low, ping, session |
| `/fpsadmin` | Opens the admin view — admins only |

Every name is configurable in `Config.Commands`.

**Keys.** `F7` opens the panel by default. Two more can be bound in
`Config.Keys`: one for the HUD and one to cycle presets. All of them go through
FiveM's key mapping, so each player can rebind them in *Settings → Key Bindings*.
Leave a key as `''` and it is not registered at all.

---

## Admins and restrictions

An admin passes if **any** of these is true: their framework group is in
`Config.Admin.groups`, they hold the ACE in `Config.Admin.ace`, or (optionally)
they hold the `command` ACE. The check is done **server side** — the client is
told the answer, never asked for it.

Admins get a live list of every player's FPS, sorted, and can force a preset on
one player or on everybody.

`Config.Restrictions` is the other direction:

```lua
lockedSettings     = { 'artificialLights' },  -- players cannot change these
lockedPresets      = { 'extreme' },           -- admins can still use them
maxPreset          = 'performance',           -- the ceiling for normal players
forceDefaultOnJoin = false,                   -- re-apply the default on connect
```

---

## Exports

### Client

```lua
exports['oxlyn-fpsboost']:GetFps()              -- the smoothed number on screen
exports['oxlyn-fpsboost']:GetStats()            -- avg, lows, min, max, median, stability
exports['oxlyn-fpsboost']:GetMetrics()          -- entities, ping, memory, estimates
exports['oxlyn-fpsboost']:GetPreset()           -- id of the active preset
exports['oxlyn-fpsboost']:ApplyPreset(id)       -- apply one
exports['oxlyn-fpsboost']:GetSetting(id)        -- read a setting
exports['oxlyn-fpsboost']:SetSetting(id, value) -- write a setting
exports['oxlyn-fpsboost']:OpenPanel()
exports['oxlyn-fpsboost']:ClosePanel()
exports['oxlyn-fpsboost']:IsPanelOpen()
exports['oxlyn-fpsboost']:ToggleHud()
exports['oxlyn-fpsboost']:RunCleanup()          -- one cleanup pass, now
```

### Server

```lua
exports['oxlyn-fpsboost']:GetPlayerPerformance(source)  -- last summary of one player
exports['oxlyn-fpsboost']:GetAllPerformance()           -- everyone, for your own dashboards
exports['oxlyn-fpsboost']:ForcePreset(target, preset)   -- target = source or -1 for all
```

---

## Translating

Twelve languages ship in `locales/`. To add one:

**1.** Copy `locales/en.lua` to `locales/xx.lua` and translate the values.
**2.** Add it to `shared_scripts` in `fxmanifest.lua`, after `en.lua`.
**3.** Set `Config.Locale = 'xx'`.

Players can also pick their own language in the panel, which overrides the server
default for them alone. Any key you leave out falls back to English instead of
showing an empty string.

---

## Performance

The resource that measures the cost has to be honest about its own:

* **One** thread at `Wait(0)` in the entire resource — the one that reads the
  frame time. The optimisation engine runs inside it instead of having its own.
* The statistics window uses a histogram, not a sort: inserting a frame is O(1)
  and a percentile costs the number of buckets, whatever the frame rate.
* Percentiles are recalculated every 500 ms with the panel open, 750 ms with only
  the HUD, and 1.5 s with neither. The measurement never stops; only the maths
  slows down.
* The panel's fast channel sends three fields at 20 Hz, and only when at least
  one of them changed.
* With the panel closed, the HUD off and no preset applied, the per-frame work is
  one native call and one addition.

---

## Troubleshooting

**The panel does not open.** Check the console at startup: the banner prints the
detected framework and the registered commands. If `Config.Integration.blockWhenDead`
is on, the panel will not open while the player is dead.

**The key does nothing.** `F7` may already be taken by another resource. FiveM
key mapping is per player: *Settings → Key Bindings → FiveM* and rebind it there.

**The FPS number does not match my other counter.** This one is smoothed with a
0.12 s time constant so it can be read without flickering; the FiveM overlay
(F8 → Overlays → Draw FPS) shows a 45-frame average updated once a second. Both
are right, they just answer slightly different questions.

**A preset changes nothing.** Some options only apply at night (city lights), in
the rain (puddles) or with traffic around (density). Use the benchmark: it tells
you what that preset is worth on that machine, in that spot.

**Cars are disappearing.** Cleanup is off by default — if it is on, raise
`CleanupSafety.minDistance` and put your persistent models in `protectedModels`.

**The admin view is empty.** It is fed by telemetry. Check
`Config.Telemetry.enabled` and that players have been connected for at least one
interval (30 s by default).

---

## Support

Oxlyn Software · [discord.gg/oxlyn](https://discord.gg/oxlyn)

When reporting a problem, `/fpsstats` plus the resource version (in the panel's
About view) usually answers half the questions.

---

© Oxlyn Software · FPS Boost V2 · `2.0.1`
