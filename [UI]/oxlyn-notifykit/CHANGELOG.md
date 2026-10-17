# Changelog — OXLYN NotifyKit

## 1.0.0

First release.

* **72 notification styles in 9 families** — Essentials, Devices, Roleplay, Gaming, Cyber, Bold,
  Elegant, Compact and Playful. One default for the server; any notification may pick its own.
* **25 coloured types** with Font Awesome icons, sounds and labels, all editable in-game, plus
  custom types in `config.lua`. Images, avatars and emoji as icons, 12 icon animations and an
  entrance motion per type.
* **9 positions**, offsets, width, scale, radius, gap, list or deck stacking, 9 entrance animations
  (slide, glide, swoop, fade, drop, curtain, reveal, bounce, none) and signature entrances per style.
* **Rich notifications** — title, message, subtitle, label, value, image, avatar, custom colour,
  markdown and GTA colour codes (escaped), update in place by id, ×N instead of duplicates,
  progress notifications, key-answered **Confirm** (client and server), **Announcements**.
* **In-game editor** (`/notifyeditor`) — style gallery, colours, layout, behaviour, type editor,
  sound packs, composer (to me / to everyone / announce / copy code), setup status and one-click
  framework bridges. One Save applies to every player (`data/settings.json`).
* **History panel** (`/notifications`) — session log with filters, Do Not Disturb, mute and
  optional personal settings.
* **Frameworks** — ESX, QBCore, QBox and standalone. `notifykit install esx | qbcore | oxlib | all`
  bridges `ESX.ShowNotification`, `QBCore.Functions.Notify` and `lib.notify` (backup, uninstall,
  restore).
* **Drop-in** answers for okokNotify, mythic_notify, pNotify, t-notify, esx_notify,
  brutal_notify, wasabi_notify and the older oxlyn-notify; import files for client and server.
* **Server API** — Notify, NotifyAll, NotifyJob, NotifyGang, NotifyRadius, NotifyAce, Announce,
  Update, Progress, Hide, Clear, Confirm, SetLook.
* **Performance** — no per-frame work; one NUI message per tick; flood guard.
* Nine languages: English, Portuguese, Spanish, French, German, Polish, Lithuanian, Italian, Turkish.
