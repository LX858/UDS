# OXLYN HeliCam — Airborne Camera Unit

A realistic **helicopter surveillance camera** (FLIR / gimbal) for FiveM. Sit in a
supported helicopter, press the keybind and operate an under-nose camera: pan /
tilt / zoom, four vision sensors, a nightsun searchlight, suspect marking for your
whole unit, and a **target lock that makes the helicopter auto-follow / orbit** the
locked person or vehicle while you run the camera.

- **Multi-framework** — ESX / QBCore / Qbox, auto-detected
- **Optional job gate** — restrict to any job(s), or open to everyone
- **Supported-vehicle list** — any heli, or a whitelist
- **4 languages** — EN / PT / ES / FR · zero external assets
- **km/h or mph** — set the default, or let operators flip it in-flight

> Shares its roots with **OXLYN Drones**, but this is a fully distinct product:
> the camera lives on a real helicopter you're flying, with its own airborne-LE
> FLIR interface and a helicopter auto-follow autopilot.

---

## 📦 Installation

1. Drop `oxlyn-helicam` into your `resources`.
2. Add to `server.cfg`:
   ```cfg
   ensure oxlyn-helicam
   ```
3. Open [`config.lua`](config.lua) and set who can use it (`Config.Access`) and
   which helicopters carry the camera (`Config.Vehicles`).
4. Restart the server.

> No framework / no jobs? Set `Config.Access.everyone = true`.

---

## 🎮 Controls

Open / close the camera with the **F5** keybind (rebindable in GTA Settings ›
Key Bindings › FiveM) while in a supported helicopter, or the `/helicam` command.

| Key | Action |
|---|---|
| **Mouse** | Pan / tilt the gimbal |
| **Scroll** | Zoom — or, while the light is ON, resize the beam |
| **F** | Cycle vision sensor (EO → NVG → IR → B&W thermal) |
| **E** | Toggle the nightsun searchlight |
| **G** | Mark the reticle target (blip to your whole unit) |
| **RMB** | Acquire / release **target lock** (heli auto-follows) |
| **Space** | Re-center the gimbal |
| **U** | Switch the speed read-outs between **km/h** and **mph** |
| **Backspace / F5** | Close the camera |

Every in-feed key in the table is set in `Config.Controls` — change one there and
the camera reads the new key (the hint bar follows). **If you rebind the open /
close keybind onto one of them** (E is the usual one), the in-feed action wins the
press while the feed is up and **Backspace** closes the camera; the server console
points the overlap out on start.

The unit key is `Config.Units.toggleKey`, and `/helicamunits [kmh|mph]` does the same
thing from chat (no argument = flip). Each player's choice is remembered on their
own client; set `Config.Units.allowToggle = false` to pin everyone to one unit.

Stuck interface, ever? `/helicamfix` on the client wipes the OSD, the scripted
camera and the vision sensors whatever state anything is in.

---

## 🛠️ How it works

- **The camera** hangs under the helicopter (configurable mount). The mouse aims a
  smooth gimbal; the wheel zooms like a long lens (sensitivity scales with zoom).
- **Vision sensors** — EO (optical), NVG (night vision), IR (white-hot thermal,
  see-through), and B&W thermal (heat only on people / vehicles).
- **Searchlight** — a shadow-casting nightsun that lands wherever the gimbal aims.
- **Suspect marking** — press G on a target and a temporary minimap blip is pushed
  to everyone doing your job (or `Config.Marking.shareWith`).
- **Target lock** — put the ring over a person or vehicle and press RMB; at 100%
  the gimbal auto-tracks it. **If you are the pilot, the helicopter then
  auto-follows / orbits the target** at the radius & height in `Config.Lock.follow`.
  A lock is only lost if the target dies, despawns, or leaves the camera line of
  sight (thermal sees through walls). While you run the camera, an optional
  auto-hover keeps the heli from falling; closing the camera returns full control.
- **Who flies?** With `follow.onlyPilot = true` the autopilot only engages when the
  operator is the pilot. A passenger operator lets the human pilot keep flying while
  the gimbal still auto-tracks.

---

## ⚙️ Configuration highlights

| Block | Controls |
|---|---|
| `Config.Access` | Who can use it — `everyone`, `jobs`, `gangs`, `aces`. |
| `Config.Vehicles` | `allowAllHelis` or a model whitelist; whether the pilot can operate. |
| `Config.Controls` | The open/close keybind **and every in-feed key** (they are real bindings, not just hints). |
| `Config.Units` | Speed read-outs in `kmh` or `mph`, the live toggle key, and whether each player's choice is remembered. |
| `Config.Camera` | Mount offset, FOV / zoom, pitch limits, gimbal feel, the 4 sensors, `seethroughThickness`, the searchlight. |
| `Config.Lock` | Acquisition time / ring / range, line-of-sight rules, and the **heli auto-follow** (`radius`, `height`, `speed`, `onlyPilot`, `hoverWhenIdle`). |
| `Config.Marking` | Mark range, blip duration, `shareWith`, NPC marking, blip styling. |

---

## 🔌 Compatibility

- **Frameworks:** ESX, QBCore, Qbox (auto-detected; force with `Config.Framework`).
- **Notify:** ox_lib, okok, mythic, ESX, QB, or the built-in NUI toast.
- **Dependencies:** none.

---

*OXLYN Software® — Airborne Camera Unit · v1.2.2*
