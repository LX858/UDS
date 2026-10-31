# Changelog

## 2.0.2

- Fixed: the interface showed Portuguese even with `Config.Locale = 'en'`. The `uiLocale` setting had a hardcoded `'pt'` default that overrode `Config.Locale`; it now follows `Config.Locale` until the player picks a language.
- Fixed: hardcoded Portuguese text in `html/index.html` (menu labels, search placeholder, buttons) is now English, so nothing flashes in Portuguese before the locale loads.
- Fixed: `<html lang>`, date format and number format fallbacks now default to English.
- Verified: all client/server events, NUI callbacks, locale keys and the fxmanifest file list are consistent.
- Note: players who already picked a language in-game keep their saved choice (stored locally). Use Settings > Interface > Language or `/fpsreset` to change it.

## 2.0.1

- Reuse exact history block summaries when building long charts; preserve averages and real min/max bands.
- Calculate each frame's histogram bucket once, including eviction and benchmark reset.
- Reuse the adaptive overlay while its inputs and resolved settings are unchanged.
- Cache chart band smoothing, avoid unchanged live text writes and ignore stale chart responses.
- Preserve presets, per-frame natives, UI effects, animation timing and sampling cadence.

## 2.0.0

First release of FPS Boost **V2**. The V1 resource was a single `client.lua`
with a small interface; this is a different product that happens to share the
name — the engine, the interface and the configuration were all rewritten.

- **The measuring engine is honest.** Every frame is measured, not one sample a
  second. The statistics window uses a histogram, so inserting a frame costs
  O(1) and a percentile costs the number of buckets — the average, the 1% low
  and the 0.1% low are the same numbers a benchmarking tool would give you, at
  any frame rate.
- **Nothing is invented.** CPU, GPU, RAM and VRAM are derived from real signals
  and badged `EST`; temperatures are not shown at all, because no resource can
  read them. `Config.Metrics.showEstimates = false` removes the rings and the
  layout closes the gap on its own.
- **A real benchmark.** The panel measures the current settings, applies the
  preset, waits for streaming to settle and measures again — on that machine,
  in that spot, with your server's resources running. The statistics window is
  cleared between phases so the "after" cannot drag frames from the "before".
  Drafts can be benchmarked too, and saved from the result card.
- **87 settings, six presets, six custom profiles per player.** The settings
  schema is the definition of the resource: the interface is built from it,
  presets are validated against it and the optimiser reads it.
- **An adaptive layer** tightens the game in the pause menu, while the player is
  away, or indoors — and lifts the moment the situation ends. It only ever
  tightens, and it never overwrites what the player chose.
- **Entity cleanup that refuses to be dramatic.** Minimum distance, a per-pass
  cap per category, mission entities and occupied vehicles skipped, and a
  protected model list for your server's own props.
- **One thread at `Wait(0)` in the whole resource** — the one that reads the
  frame time. The optimiser runs inside it rather than paying for a second
  scheduler slot, and percentile maths slows down when nobody is looking at it.
- **12 languages**, a per-player language override, and English as the fallback
  for any key a translation leaves out.
- **Admin view** with every player's FPS and "force preset", gated server side
  by framework group or ACE.

Interface, engine and config are all new. Install it as a fresh resource; there
is nothing to migrate and no database to import.
