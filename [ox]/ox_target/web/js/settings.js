import { fetchNui } from "./fetchNui.js";
import { drawMarker, drawMarkerFrame } from "./marker.js";

const SWATCHES = [
  "#ffffff", "#22d3ee", "#38bdf8", "#818cf8", "#a855f7",
  "#ec4899", "#ef4444", "#f97316", "#eab308", "#22c55e",
];

const DEFAULTS = {
  marker: "eye",
  accentMode: "auto",
  accentColor: "#00ffff",
  vignette: true,
  handCursor: false,
  hotkeys: true,
};

let hooks = { setAccent: () => {} };
let config = { ...DEFAULTS };
let hudName = null;
let open = false;
let previewFrame = null;
let pushTimer = null;
let el = {};

function hexToRgb(hex) {
  const clean = String(hex || "").replace("#", "");
  if (!/^[0-9a-fA-F]{6}$/.test(clean)) return null;
  return [
    parseInt(clean.slice(0, 2), 16),
    parseInt(clean.slice(2, 4), 16),
    parseInt(clean.slice(4, 6), 16),
  ];
}

/** Accent the preview should use: the picked colour, or whatever is live now. */
function previewAccent() {
  if (config.accentMode === "custom") return hexToRgb(config.accentColor) || [0, 255, 255];

  const live = getComputedStyle(document.documentElement).getPropertyValue("--accent-rgb");
  const parts = live.split(",").map((v) => parseInt(v.trim(), 10));

  return parts.length === 3 && parts.every((v) => Number.isFinite(v)) ? parts : [0, 255, 255];
}

function push() {
  clearTimeout(pushTimer);
  pushTimer = setTimeout(() => fetchNui("settings:update", config), 120);
}

function paint() {
  el.cards.forEach((card) => card.classList.toggle("on", card.dataset.marker === config.marker));
  el.modes.forEach((pill) => pill.classList.toggle("on", pill.dataset.mode === config.accentMode));
  el.rows.forEach((row) => row.classList.toggle("on", !!config[row.dataset.key]));

  el.swatches.forEach((sw) => {
    const active = config.accentMode === "custom" && sw.dataset.hex === config.accentColor.toLowerCase();
    sw.classList.toggle("on", active);
  });

  el.hex.value = config.accentColor;
  el.color.value = config.accentColor;
  el.custom.classList.toggle("disabled", config.accentMode !== "custom");
  el.note.textContent =
    config.accentMode === "auto"
      ? `Follows ${hudName || "the server colour"}`
      : "Using your own colour";

  // Instant feedback: repaint the whole UI in the chosen accent right away.
  const rgb = previewAccent();
  hooks.setAccent(rgb[0], rgb[1], rgb[2]);
}

function setMarker(marker) {
  config.marker = marker;
  paint();
  push();
}

function setColor(hex, { fromPicker } = {}) {
  const rgb = hexToRgb(hex);
  if (!rgb) return;

  config.accentColor = "#" + hex.replace("#", "").toLowerCase();
  if (fromPicker) config.accentMode = "custom";
  paint();
  push();
}

function previewLoop(ts) {
  previewFrame = null;
  if (!open) return;

  const ctx = el.preview.getContext("2d");
  const w = el.preview.width;
  const h = el.preview.height;
  ctx.clearRect(0, 0, w, h);

  // Cycle scanning → locked so both states are visible in the preview.
  const cycle = (ts % 3800) / 3800;
  const acq = cycle < 0.32 ? 0 : cycle < 0.45 ? (cycle - 0.32) / 0.13 : 1;
  const accent = previewAccent();

  ctx.shadowColor = "rgba(0, 0, 0, 0.65)";
  ctx.shadowBlur = 4;
  drawMarkerFrame(ctx, w / 2, h / 2, ts, { accent, acq, lock: 0 });
  drawMarker(ctx, w / 2, h / 2, ts, { kind: config.marker, accent, acq });
  ctx.shadowBlur = 0;

  previewFrame = requestAnimationFrame(previewLoop);
}

export function initSettings(userHooks) {
  hooks = Object.assign(hooks, userHooks);

  el = {
    root: document.getElementById("settings"),
    preview: document.getElementById("sp-preview"),
    cards: [...document.querySelectorAll("[data-marker]")],
    modes: [...document.querySelectorAll("[data-mode]")],
    rows: [...document.querySelectorAll(".sp-row[data-key]")],
    swatchWrap: document.getElementById("sp-swatches"),
    hex: document.getElementById("sp-hex"),
    color: document.getElementById("sp-color"),
    note: document.getElementById("sp-note"),
    custom: document.getElementById("sp-custom"),
  };

  el.swatches = SWATCHES.map((hex) => {
    const sw = document.createElement("button");
    sw.className = "sp-swatch";
    sw.dataset.hex = hex;
    sw.style.background = hex;
    sw.addEventListener("click", () => setColor(hex, { fromPicker: true }));
    el.swatchWrap.appendChild(sw);
    return sw;
  });

  el.cards.forEach((card) => card.addEventListener("click", () => setMarker(card.dataset.marker)));

  el.modes.forEach((pill) =>
    pill.addEventListener("click", () => {
      config.accentMode = pill.dataset.mode;
      paint();
      push();
    })
  );

  el.rows.forEach((row) =>
    row.addEventListener("click", () => {
      config[row.dataset.key] = !config[row.dataset.key];
      paint();
      push();
    })
  );

  el.color.addEventListener("input", () => setColor(el.color.value, { fromPicker: true }));
  el.hex.addEventListener("change", () => setColor(el.hex.value, { fromPicker: true }));
  el.hex.addEventListener("keydown", (e) => {
    if (e.key === "Enter") setColor(el.hex.value, { fromPicker: true });
  });

  document.getElementById("sp-reset").addEventListener("click", () => fetchNui("settings:reset"));
  document.getElementById("sp-close").addEventListener("click", requestClose);
  el.root.addEventListener("mousedown", (e) => {
    if (e.target === el.root) requestClose();
  });

  document.addEventListener("keydown", (e) => {
    if (open && (e.key === "Escape" || e.key === "Backspace" && e.target !== el.hex)) requestClose();
  });
}

function requestClose() {
  closeSettings();
  fetchNui("settings:close");
}

export function isSettingsOpen() {
  return open;
}

/** Config pushed from Lua (startup, saves and resets). */
export function applySettings(next) {
  if (!next) return;

  config = Object.assign({ ...DEFAULTS }, next);
  if (el.root) paint();

  return config;
}

export function openSettings(data) {
  if (data?.hud) hudName = data.hud;
  applySettings(data?.settings);

  open = true;
  document.body.style.visibility = "visible";
  document.body.classList.add("settings-open");
  el.root.classList.add("show");

  if (!previewFrame) previewFrame = requestAnimationFrame(previewLoop);
}

export function closeSettings() {
  if (!open) return;

  open = false;
  el.root.classList.remove("show");
  document.body.classList.remove("settings-open");
  document.body.style.visibility = "hidden";

  if (previewFrame) {
    cancelAnimationFrame(previewFrame);
    previewFrame = null;
  }
}
