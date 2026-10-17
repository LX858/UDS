# OXLYN NotifyKit

**72 notification styles, one resource.** Every design a FiveM server could want — clean cards,
phone and desktop looks, roleplay feeds and dispatch alerts, game achievements, neon and
terminals, bold banners, luxury and editorial cards, tiny toasts, comic panels, retro dialogs and
sticker cards — with coloured icons, 25 types,
9 positions, progress / confirm / announcement formats, a history panel, an in-game editor with
live previews, and drop-in support for every framework and the popular
notification resources.

- **Version:** 1.0.0
- **Frameworks:** Standalone · ESX · QBCore · QBox · ox_core · ND_Core (auto-detected — only used for admin access, `NotifyJob` and `NotifyGang`)
- **Dependencies:** none
- **Resmon:** 0.00 ms idle — nothing runs per frame (see *Performance*)

---

## Installation

1. Put the `oxlyn-notifykit` folder in your `resources` (keep the folder name).
2. In `server.cfg`, **early** — before your framework and the scripts that send notifications:
   ```cfg
   ensure oxlyn-notifykit
   ```
3. Give yourself the admin tools (paste in the server console to apply now, and keep them in `server.cfg`):
   ```cfg
   add_ace group.admin oxlyn.notifykit.admin allow
   add_principal identifier.license:YOUR_LICENSE group.admin
   ```
   Framework admins (`admin` / `superadmin` / `god` groups) are allowed too — see `Config.Admin`.
4. In game: `/notifyeditor` ▸ pick a style ▸ **Save** (applies to every player).
5. Make your framework use it (optional, recommended) — in the **server console**:
   ```
   notifykit install all
   ```
   then restart `es_extended` / `qb-core` / `ox_lib` (or the server). `notifykit status` shows
   what is installed; `notifykit uninstall all` undoes it.
6. Remove the notification resource you used before (okokNotify, mythic_notify, pNotify,
   t-notify, esx_notify, brutal_notify, wasabi_notify, vms_notify, k5_notify, codem-notification,
   FL-Notify, bulletin, origen_notify, renzu_notify …): scripts that call it keep working —
   NotifyKit answers their exports.

Developers: **`EXPORTS.md`** documents every export, field, event and integration.

---

## Features

### 72 styles in 9 families
| Family | |
|---|---|
| **Essentials** | classic · glass · soft · outline · line · split · pill · minimal |
| **Devices** | mobile · material · desktop · aqua · island · snackbar · watch · lock |
| **Roleplay** | feed · nopixel · phone · dispatch · radio · sms · breaking · receipt |
| **Gaming** | achievement · trophy · levelup · quest · loot · arcade · killfeed · mission |
| **Cyber** | neon · cyber · hologram · terminal · glitch · synthwave · circuit · hud |
| **Bold** | solid · gradient · brutal · banner · ribbon · tile · stamp · duo |
| **Elegant** | luxe · paper · frost · mono · elegant · velvet · aurora · editorial |
| **Compact** | toast · chip · dot · ticker · sidebar · ring · bubble · underline |
| **Playful** | comic · kawaii · sketch · retro · western · score · sticker · candy |

One default style for the server, and any notification may pick its own.

### Coloured icons and 25 types
success · error · warning · info · primary · neutral · money · bank · police · ems · fire ·
mechanic · phone · message · mail · system · admin · announce · achievement · xp · item · vehicle
· location · weather · loading — each with its colour, Font Awesome icon, sound and label, all
editable in-game, plus your own types in `config.lua`. Icons can also be images, avatars or
emoji, with 12 icon animations and an entrance motion per type.

### Everything a notification can do
- 9 positions, offsets, width, scale, radius, gap, list or **deck** stacking, 9 entrance animations (slide · glide · swoop · fade · drop · curtain · reveal · bounce · none) plus the signature entrances of many styles
- title, message, subtitle, label, value, image, avatar, custom colour
- **markdown** (`**bold**`, `*italic*`, `` `code` ``…) and **GTA colour codes** (`~r~`, `~g~`, `~b~`…), always escaped
- **update in place** by id, **×N** instead of duplicates, **progress** notifications (0–100 %)
- **Confirm** — yes / no answered with keys (Y / N by default), from the client or the server
- **Announcements** — a big centred format for server-wide messages (`/notifyall`)
- timers pause and notifications hide behind the pause menu
- synthesized sounds in 4 packs (soft · crisp · retro · bubble) or GTA frontend sounds, custom sound files
- flood guard (paced, never lost), text limits, HTML only when you allow it

### In-game editor — `/notifyeditor`
Style gallery with live previews and family filters, colour presets and pickers, layout,
behaviour, a **type editor** (colour, icon picker, label, sound), sound packs with previews, a
**composer** (send to yourself, to everyone, as an announcement, or copy the Lua code), and a
**setup** tab (framework, compatibility layers, one-click framework bridges). One **Save** applies
to every player.

### History panel — `/notifications`
Every notification of the session, filters by type, **Do Not Disturb**, mute, and — when you allow
it — personal style, position and volume for each player.

### Works with everything
- **ESX, QBCore, QBox, ox_lib** — one console command bridges their notify functions
  (`ESX.ShowNotification`, `QBCore.Functions.Notify`, `lib.notify`), with a backup and an uninstall
- **okokNotify, mythic_notify, pNotify, t-notify, esx_notify, brutal_notify, wasabi_notify,
  oxlyn-notify, vms_notify, vms_notifyv2, k5_notify, codem-notification (mNotification), FL-Notify,
  bulletin, origen_notify, renzu_notify** — their exports and events are answered: old scripts
  work unchanged
- **ox_core, ND_Core** — read on the server for admin groups, `NotifyJob` and `NotifyGang`, next to
  ESX, QBCore and QBox
- import files: `Notify.success('Saved')` from any resource, client or server
- server helpers: `NotifyAll`, `NotifyJob`, `NotifyGang`, `NotifyRadius`, `NotifyAce`, `Confirm`

### 9 languages
English, Português, Español, Français, Deutsch, Polski, Lietuvių, Italiano, Türkçe (`Config.Locale`).

---

## Commands

| Command | Who | |
|---|---|---|
| `/notifyeditor` | admins | in-game editor |
| `/notifytest [style] [type]` | admins | samples |
| `/notifystyle <style> [global]` | everyone / admins | personal / server style |
| `/notifyall <message>` | admins, console | announcement |
| `/notifications` | everyone | history panel |
| `notifyaccess <id>` | admins, console | admin access report |
| `notifykit status \| install \| uninstall \| restore <target> [force]` | console | framework bridges |

---

## Configuration

Everything lives in `config.lua`, with comments:

- `Config.Locale`, `Config.Framework`, `Config.Debug`
- `Config.Look` — the default look (the editor saves over it into `data/settings.json`)
- `Config.AllowPlayerSettings` — players may choose their own style / position / sound
- `Config.Types` — change or add types
- `Config.Limits` — flood guard, text lengths, HTML
- `Config.Announce`, `Config.Confirm`, `Config.History`
- `Config.GameSounds` — the GTA frontend sounds of the "game" pack
- `Config.Compat` — which other notification resources are answered
- `Config.Commands`, `Config.Permissions`, `Config.Admin`

Delete `data/settings.json` to go back to `config.lua` for everyone.

---

## Performance

- **Nothing runs per frame.** A notification is one message to the NUI; everything sent in the
  same tick travels in a single message.
- The pause-menu watcher exists only while a notification is on screen (4 checks a second).
- The key loop of a Confirm exists only while a Confirm is on screen.
- Timers, animations and stacks live in the NUI; infinite animations are compositor-only
  (transform / opacity) so they cost no repaints.

---

## Support

OXLYN Software — https://oxlynsoftware.com
All rights reserved © OXLYN Software.
