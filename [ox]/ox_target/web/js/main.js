import { buildOption, selectOption } from "./createOptions.js";
import { fetchNui } from "./fetchNui.js";
import { drawMarker, drawMarkerFrame, resetMarker } from "./marker.js";
import { initSettings, isSettingsOpen, openSettings, closeSettings, applySettings } from "./settings.js";

/* ------------------------------------------------------------------- setup */

const wrapper = document.getElementById("options-wrapper");
const vignette = document.getElementById("vignette");
const body = document.body;

// Anchor canvas is parented to the wrapper, so it stays glued to the target
// point. The cursor canvas is independent and always tracks the real pointer —
// that split is what lets the reticle detach into a pointer while locked.
const ANCHOR_SIZE = 1000;
const ANCHOR_HALF = ANCHOR_SIZE / 2;
const CURSOR_SIZE = 260;
const CURSOR_HALF = CURSOR_SIZE / 2;

const anchorCanvas = document.createElement("canvas");
anchorCanvas.id = "connector-canvas";
anchorCanvas.width = ANCHOR_SIZE;
anchorCanvas.height = ANCHOR_SIZE;
wrapper.appendChild(anchorCanvas);
const actx = anchorCanvas.getContext("2d");

const cursorCanvas = document.createElement("canvas");
cursorCanvas.id = "cursor-canvas";
cursorCanvas.width = CURSOR_SIZE;
cursorCanvas.height = CURSOR_SIZE;
body.appendChild(cursorCanvas);
const cctx = cursorCanvas.getContext("2d");

const TAU = Math.PI * 2;

/* ------------------------------------------------------------------- state */

let accent = [0, 255, 255];
let accent2 = [0, 255, 255];

let mouseX = window.innerWidth / 2;
let mouseY = window.innerHeight / 2;
let prevMouseX = mouseX;
let prevMouseY = mouseY;

let isLocked = false;
let lockedX = null;
let lockedY = null;
let tiltEnabled = false;
let hideTimeout = null;

let optionEls = [];
let lineData = [];
let pulses = [];
let layoutKey = "";

let hasTarget = false;
let phase = "idle"; // "in" | "idle" | "out"
let phaseStart = 0;

let animFrameId = null;

let swayX = 0;
let swayY = 0;

// reticle
let acq = 0;
let lockAmt = 0;
let acqFlash = -1e9;
let nextPing = 0;
let pings = [];
let shockwaves = [];
let motes = [];
let motesActive = false;
let moteAccum = 0;
let markerKind = "eye";

/* --------------------------------------------------------------- constants */

const GAP_X = 64;
const COL_GAP = 12;
const ROW_GAP = 7;
const BOW = 18;
const EDGE_PAD = 12;
const LINE_START = 23; // connectors leave from outside the eye, not from its centre

const ENTRANCE_STAGGER = 45;
const LINE_DRAW_DURATION = 170;
const MATERIALIZE_DURATION = 230;
const EXIT_DURATION = 170;
const TRAVEL_FRACTION = 0.42;

const BLOB_POINTS = 44;
const BLOB_LERP = 0.09;

const FOCUS_HOVERED = 1.07;
const FOCUS_SHRUNK = 0.95;
const FOCUS_LERP = 0.13;

const PULSES_PER_LINE = 2;

const MOTE_RATE = 0.16;
const MOTE_LIFE = 100;
const MOTE_RANGE = 44;
const MOTE_SPEED = 0.26;

/* ----------------------------------------------------------------- helpers */

const clamp = (v, min, max) => (v < min ? min : v > max ? max : v);
const lerp = (a, b, t) => a + (b - a) * t;
const easeOut = (t) => 1 - Math.pow(1 - t, 3);
const easeOutBack = (t) => 1 + 2.4 * Math.pow(t - 1, 3) + 1.4 * Math.pow(t - 1, 2);

/** Later options bunch up so long lists still finish quickly. */
const staggerFor = (i) => ENTRANCE_STAGGER * (i < 6 ? i : 6 + (i - 6) * 0.45);

function rgba(color, alpha) {
  return `rgba(${color[0]}, ${color[1]}, ${color[2]}, ${alpha})`;
}

/** Rotates the accent hue a touch so gradients have somewhere to travel to. */
function deriveAccent2([r, g, b]) {
  const rn = r / 255;
  const gn = g / 255;
  const bn = b / 255;
  const max = Math.max(rn, gn, bn);
  const min = Math.min(rn, gn, bn);
  const l = (max + min) / 2;
  const d = max - min;

  if (d < 0.04) return [r, g, b];

  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;

  if (max === rn) h = ((gn - bn) / d + (gn < bn ? 6 : 0)) / 6;
  else if (max === gn) h = ((bn - rn) / d + 2) / 6;
  else h = ((rn - gn) / d + 4) / 6;

  h = (h + 0.075) % 1;
  const l2 = clamp(l + 0.08, 0, 1);
  const c = (1 - Math.abs(2 * l2 - 1)) * s;
  const x = c * (1 - Math.abs(((h * 6) % 2) - 1));
  const m = l2 - c / 2;
  const seg = Math.floor(h * 6) % 6;
  const table = [
    [c, x, 0],
    [x, c, 0],
    [0, c, x],
    [0, x, c],
    [x, 0, c],
    [c, 0, x],
  ][seg];

  return table.map((v) => Math.round((v + m) * 255));
}

function setAccent(r, g, b) {
  accent = [r, g, b];
  accent2 = deriveAccent2(accent);
  const root = document.documentElement.style;
  root.setProperty("--accent-rgb", `${accent[0]}, ${accent[1]}, ${accent[2]}`);
  root.setProperty("--accent-rgb-2", `${accent2[0]}, ${accent2[1]}, ${accent2[2]}`);
}

/* ------------------------------------------------------------------ layout */

let mouseMoved = false;

document.addEventListener("mousemove", (e) => {
  mouseX = e.clientX;
  mouseY = e.clientY;
  mouseMoved = true;
});

function positionCursorCanvas() {
  cursorCanvas.style.left = mouseX - CURSOR_HALF + "px";
  cursorCanvas.style.top = mouseY - CURSOR_HALF + "px";
}

function moveWrapperToCursor() {
  wrapper.style.left = mouseX + "px";
  wrapper.style.top = mouseY + "px";
  layoutOptions();
}

/**
 * Two balanced columns fanned around the cursor, bowed outwards at the ends.
 * Falls back to stacking on one side (and slides vertically) so the options
 * never run off the edge of the screen.
 */
function layoutOptions() {
  const n = optionEls.length;
  if (!n) return;

  const w = optionEls[0]._w;
  const cx = isLocked && lockedX !== null ? lockedX : mouseX;
  const cy = isLocked && lockedY !== null ? lockedY : mouseY;
  const vw = window.innerWidth;
  const vh = window.innerHeight;

  const need = GAP_X + w + BOW + EDGE_PAD;
  const need2 = GAP_X + w * 2 + COL_GAP + BOW + EDGE_PAD;
  const roomR = vw - cx;
  const roomL = cx;

  let cols;

  if (n <= 3) {
    cols = [{ side: roomR >= need || roomR >= roomL ? 1 : -1, depth: 0 }];
  } else if (roomR < need && roomL >= need2) {
    cols = [{ side: -1, depth: 0 }, { side: -1, depth: 1 }];
  } else if (roomL < need && roomR >= need2) {
    cols = [{ side: 1, depth: 0 }, { side: 1, depth: 1 }];
  } else {
    cols = [{ side: 1, depth: 0 }, { side: -1, depth: 0 }];
  }

  const perCol = Math.ceil(n / cols.length);
  const placed = [];
  let idx = 0;
  let minY = Infinity;
  let maxY = -Infinity;

  for (let c = 0; c < cols.length && idx < n; c++) {
    const take = c === cols.length - 1 ? n - idx : Math.min(perCol, n - idx);
    const items = [];
    for (let k = 0; k < take; k++) items.push(idx++);

    let totalH = ROW_GAP * (items.length - 1);
    for (const i of items) totalH += optionEls[i]._h;

    const { side, depth } = cols[c];
    const baseX = side > 0
      ? GAP_X + depth * (w + COL_GAP)
      : -(GAP_X + w + depth * (w + COL_GAP));

    let y = -totalH / 2;

    for (const i of items) {
      const h = optionEls[i]._h;
      const centerY = y + h / 2;
      const norm = totalH > h ? Math.abs(centerY) / (totalH / 2) : 0;
      const bow = BOW * Math.pow(clamp(norm, 0, 1), 1.7);

      placed.push({ i, x: baseX + side * bow, y, side });
      if (y < minY) minY = y;
      if (y + h > maxY) maxY = y + h;
      y += h + ROW_GAP;
    }
  }

  let shiftY = 0;
  if (cy + maxY > vh - EDGE_PAD) shiftY = vh - EDGE_PAD - (cy + maxY);
  if (cy + minY + shiftY < EDGE_PAD) shiftY = EDGE_PAD - cy - minY;

  let key = `${cols.length}:${cols[0].side}:${Math.round(shiftY)}`;

  for (const p of placed) {
    const el = optionEls[p.i];
    const y = p.y + shiftY;

    el._x = p.x;
    el._y = y;
    el._side = p.side;
    el._dirX = p.x + el._w / 2;
    el._dirY = y + el._h / 2;
    el.style.left = p.x + "px";
    el.style.top = y + "px";
    key += `|${Math.round(p.x)},${Math.round(y)}`;
  }

  if (key !== layoutKey) {
    layoutKey = key;
    buildLines();
  }
}

function buildLines() {
  const keepPulses = lineData.length === optionEls.length;
  const previous = lineData;
  lineData = [];

  for (let i = 0; i < optionEls.length; i++) {
    const el = optionEls[i];
    const nearX = clamp(0, el._x, el._x + el._w);
    const nearY = clamp(0, el._y, el._y + el._h);
    const reach = Math.hypot(nearX, nearY);

    if (reach < LINE_START + 6) {
      el._lineIdx = -1;
      continue;
    }

    const startX = (nearX / reach) * LINE_START;
    const startY = (nearY / reach) * LINE_START;
    const dx = nearX - startX;
    const dy = nearY - startY;
    const len = Math.hypot(dx, dy);

    const px = -dy / len;
    const py = dx / len;
    const amplitude = Math.min(len * 0.11, 12);
    const segments = 3;
    const curves = [];
    let sx = startX;
    let sy = startY;

    for (let s = 0; s < segments; s++) {
      const t2 = (s + 1) / segments;
      const tMid = (s + 0.5) / segments;
      const dir = s % 2 === 0 ? 1 : -1;

      curves.push({
        sx,
        sy,
        cpx: startX + dx * tMid + px * amplitude * dir,
        cpy: startY + dy * tMid + py * amplitude * dir,
        ex: startX + dx * t2,
        ey: startY + dy * t2,
      });

      sx = startX + dx * t2;
      sy = startY + dy * t2;
    }

    const old = keepPulses ? previous[lineData.length] : null;

    lineData.push({
      nearX,
      nearY,
      startX,
      startY,
      len,
      curves,
      elIdx: i,
      // A relayout after the entrance must not blank the connector again.
      progress: old ? old.progress : phase === "in" ? 0 : 1,
      alpha: old ? old.alpha : 0.5,
      width: old ? old.width : 1.8,
    });

    el._lineIdx = lineData.length - 1;
  }

  if (!keepPulses) {
    pulses = [];
    for (let i = 0; i < lineData.length; i++) {
      for (let p = 0; p < PULSES_PER_LINE; p++) {
        pulses.push({
          lineIdx: i,
          t: p / PULSES_PER_LINE,
          speed: 0.0035 + Math.random() * 0.0035,
          size: 1.4 + Math.random() * 1.4,
        });
      }
    }
  }
}

function evalCurves(line, t) {
  const total = t * line.curves.length;
  const seg = Math.min(Math.floor(total), line.curves.length - 1);
  const lt = total - seg;
  const c = line.curves[seg];
  const u = 1 - lt;

  return {
    x: u * u * c.sx + 2 * u * lt * c.cpx + lt * lt * c.ex,
    y: u * u * c.sy + 2 * u * lt * c.cpy + lt * lt * c.ey,
  };
}

/* ----------------------------------------------------------- blob geometry */

function sampleRoundedRect(w, h, r) {
  r = Math.min(r, w / 2, h / 2);
  const points = [];

  const sections = [
    { type: 0, x1: r, y1: 0, x2: w - r, y2: 0, nx: 0, ny: -1 },
    { type: 1, cx: w - r, cy: r, start: -Math.PI / 2, end: 0 },
    { type: 0, x1: w, y1: r, x2: w, y2: h - r, nx: 1, ny: 0 },
    { type: 1, cx: w - r, cy: h - r, start: 0, end: Math.PI / 2 },
    { type: 0, x1: w - r, y1: h, x2: r, y2: h, nx: 0, ny: 1 },
    { type: 1, cx: r, cy: h - r, start: Math.PI / 2, end: Math.PI },
    { type: 0, x1: 0, y1: h - r, x2: 0, y2: r, nx: -1, ny: 0 },
    { type: 1, cx: r, cy: r, start: Math.PI, end: (3 * Math.PI) / 2 },
  ];

  const lengths = [];
  let totalLen = 0;

  for (const s of sections) {
    const len = s.type === 0 ? Math.hypot(s.x2 - s.x1, s.y2 - s.y1) : Math.abs(s.end - s.start) * r;
    lengths.push(len);
    totalLen += len;
  }

  for (let i = 0; i < BLOB_POINTS; i++) {
    const d = (i / BLOB_POINTS) * totalLen;
    let accumulated = 0;

    for (let si = 0; si < sections.length; si++) {
      if (d <= accumulated + lengths[si] || si === sections.length - 1) {
        const localD = d - accumulated;
        const s = sections[si];

        if (s.type === 0) {
          const t = lengths[si] > 0 ? localD / lengths[si] : 0;
          points.push({
            x: s.x1 + (s.x2 - s.x1) * t,
            y: s.y1 + (s.y2 - s.y1) * t,
            nx: s.nx,
            ny: s.ny,
          });
        } else {
          const angle = s.start + localD / r;
          points.push({
            x: s.cx + r * Math.cos(angle),
            y: s.cy + r * Math.sin(angle),
            nx: Math.cos(angle),
            ny: Math.sin(angle),
          });
        }
        break;
      }
      accumulated += lengths[si];
    }
  }

  points._defaultPath = pointsToSvgPath(points);
  return points;
}

function generateBlobPath(base, amplitude, time, seed) {
  if (amplitude <= 0.01) return base._defaultPath || pointsToSvgPath(base);
  const n = base.length;
  const pts = new Array(n);

  for (let i = 0; i < n; i++) {
    const p = base[i];
    // Uniform parametric position keeps point density even; atan2 would cluster on long edges.
    const t = (i / n) * TAU;
    const offset =
      amplitude *
      (Math.sin(t * 2 + time * 0.7 + seed) * 0.5 +
        Math.sin(t * 3.5 - time * 0.5 + seed * 2.3) * 0.3 +
        Math.sin(t * 5 + time * 0.9 + seed * 0.7) * 0.2);

    pts[i] = { x: p.x + p.nx * offset, y: p.y + p.ny * offset };
  }

  return pointsToSvgPath(pts);
}

function pointsToSvgPath(pts) {
  const n = pts.length;
  if (n < 3) return "";

  let d = "M" + pts[0].x.toFixed(2) + "," + pts[0].y.toFixed(2);

  for (let i = 0; i < n; i++) {
    const p0 = pts[(i - 1 + n) % n];
    const p1 = pts[i];
    const p2 = pts[(i + 1) % n];
    const p3 = pts[(i + 2) % n];

    // Catmull-Rom → cubic bezier control points.
    d +=
      "C" + (p1.x + (p2.x - p0.x) / 6).toFixed(2) + "," + (p1.y + (p2.y - p0.y) / 6).toFixed(2) +
      "," + (p2.x - (p3.x - p1.x) / 6).toFixed(2) + "," + (p2.y - (p3.y - p1.y) / 6).toFixed(2) +
      "," + p2.x.toFixed(2) + "," + p2.y.toFixed(2);
  }

  return d + "Z";
}

/* ------------------------------------------------------------- option flow */

function clearOptions() {
  for (const el of optionEls) el.remove();
  optionEls = [];
  lineData = [];
  pulses = [];
  layoutKey = "";
  hasTarget = false;
  phase = "idle";
  actx.clearRect(0, 0, ANCHOR_SIZE, ANCHOR_SIZE);
}

function collapseOptions() {
  if (!optionEls.length) return clearOptions();
  if (phase === "out") return;

  phase = "out";
  phaseStart = performance.now();
  hasTarget = false;
  startAnimation();
}

function setTargetOptions(data) {
  clearOptions();

  const add = (type, list, zoneId) => {
    if (!list) return;
    list.forEach((option, i) => {
      const el = buildOption(type, option, i + 1, zoneId);
      if (!el) return;
      wrapper.appendChild(el);
      optionEls.push(el);
    });
  };

  if (data.options) {
    for (const type in data.options) add(type, data.options[type]);
  }

  if (data.zones) {
    data.zones.forEach((zoneOptions, i) => add("zones", zoneOptions, i + 1));
  }

  if (!optionEls.length) return;

  // Measure once — layout runs on every mouse move and must not thrash.
  for (let i = 0; i < optionEls.length; i++) {
    const el = optionEls[i];
    el._w = el.offsetWidth;
    el._h = el.offsetHeight;
    el._blobBase = null;
    el._blobAmp = 0;
    el._blobSeed = Math.random() * 100;
    el._travel = 0;
    el._focusScale = 1;

    if (i < 9) {
      el._hotkey = i + 1;
      el._key.textContent = String(i + 1);
      el._key.classList.remove("empty");
    }
  }

  hasTarget = true;
  phase = "in";
  phaseStart = performance.now();
  acqFlash = phaseStart;

  if (isLocked && lockedX !== null) {
    wrapper.style.left = lockedX + "px";
    wrapper.style.top = lockedY + "px";
    requestAnimationFrame(layoutOptions);
  } else {
    requestAnimationFrame(moveWrapperToCursor);
  }

  startAnimation();
}

/* --------------------------------------------------------------- animation */

function startAnimation() {
  if (!animFrameId) animFrameId = requestAnimationFrame(animationLoop);
}

function stopAnimation() {
  if (animFrameId) {
    cancelAnimationFrame(animFrameId);
    animFrameId = null;
  }
}

function animationLoop(ts) {
  animFrameId = null;

  if (mouseMoved) {
    mouseMoved = false;
    positionCursorCanvas();
    if (!isLocked) {
      wrapper.style.left = mouseX + "px";
      wrapper.style.top = mouseY + "px";
      if (optionEls.length) layoutOptions();
    }
  }

  const velX = mouseX - prevMouseX;
  const velY = mouseY - prevMouseY;
  prevMouseX = mouseX;
  prevMouseY = mouseY;

  swayX = clamp((swayX + velX * 0.08) * 0.92, -4, 4);
  swayY = clamp((swayY + velY * 0.08) * 0.92, -4, 4);

  updateMotes(ts);
  updateOptions(ts);

  drawAnchor(ts);
  drawCursor(ts);

  const busy =
    optionEls.length > 0 ||
    motes.length > 0 ||
    motesActive ||
    shockwaves.length > 0 ||
    body.style.visibility === "visible";

  if (busy) animFrameId = requestAnimationFrame(animationLoop);
}

function updateOptions(ts) {
  const n = optionEls.length;
  if (!n) return;

  const elapsed = ts - phaseStart;
  const exiting = phase === "out";
  const exitT = exiting ? clamp(elapsed / EXIT_DURATION, 0, 1) : 0;
  const anyHovered = !exiting && optionEls.some((el) => el._isHovered);
  const blobTime = ts * 0.00135;

  for (let i = 0; i < n; i++) {
    const el = optionEls[i];
    const line = el._lineIdx >= 0 ? lineData[el._lineIdx] : null;

    if (exiting) {
      const fade = 1 - exitT;
      el.style.opacity = fade.toFixed(3);
      el._travel = 1 - exitT * 0.55;
      el._focusScale = lerp(el._focusScale, 0.88, 0.25);
      if (line) line.progress = fade;
    } else if (phase === "in") {
      const delay = staggerFor(i);
      const lineT = clamp((elapsed - delay) / LINE_DRAW_DURATION, 0, 1);
      const matT = clamp((elapsed - delay - LINE_DRAW_DURATION) / MATERIALIZE_DURATION, 0, 1);

      if (line) line.progress = easeOut(lineT);

      el.style.opacity = "1";
      el._travel = matT <= 0 ? 0 : easeOutBack(matT);
      el._content.style.opacity = clamp(matT / 0.45, 0, 1).toFixed(3);

      const path = el._blobPath;
      if (matT <= 0) {
        path.style.strokeOpacity = "0";
        path.style.fillOpacity = "0";
      } else {
        if (!el._pathLength) el._pathLength = path.getTotalLength() || 500;
        const outline = easeOut(clamp((matT - 0.05) / 0.75, 0, 1));
        path.style.strokeOpacity = "1";
        path.style.strokeDasharray = el._pathLength;
        path.style.strokeDashoffset = el._pathLength * (1 - outline);
        path.style.fillOpacity = clamp((matT - 0.55) / 0.45, 0, 1).toFixed(3);
        el.classList.add("visible");
      }

      if (matT >= 1) {
        el.style.opacity = "";
        el._content.style.opacity = "";
        path.style.strokeDasharray = "";
        path.style.strokeDashoffset = "";
        path.style.strokeOpacity = "";
        path.style.fillOpacity = "";
        el._pathLength = 0;
        el._travel = 1;
      }
    }

    // organic wobble
    if (!el._blobBase && el._w && el._h) {
      el._blobBase = sampleRoundedRect(el._w, el._h, el._h / 2);
      el._blobSvg.setAttribute("viewBox", `0 0 ${el._w} ${el._h}`);
      el._blobPath.setAttribute("d", el._blobBase._defaultPath);
      el._blobRendered = true;
    }

    if (el._blobBase) {
      const prevAmp = el._blobAmp;
      el._blobAmp += (el._blobTarget - el._blobAmp) * BLOB_LERP;
      if (Math.abs(el._blobAmp) < 0.01) el._blobAmp = 0;

      if (el._blobAmp > 0) {
        el._blobPath.setAttribute("d", generateBlobPath(el._blobBase, el._blobAmp, blobTime, el._blobSeed));
        el._blobRendered = true;
      } else if (prevAmp > 0 || !el._blobRendered) {
        el._blobPath.setAttribute("d", el._blobBase._defaultPath);
        el._blobRendered = true;
      }
    }

    if (!exiting && phase !== "in") {
      const target = anyHovered ? (el._isHovered ? FOCUS_HOVERED : FOCUS_SHRUNK) : 1;
      el._focusScale += (target - el._focusScale) * FOCUS_LERP;
    }

    // connector emphasis follows the hover
    if (line) {
      const targetAlpha = exiting ? 0 : anyHovered ? (el._isHovered ? 0.95 : 0.17) : 0.52;
      const targetWidth = anyHovered && el._isHovered ? 2.6 : 1.7;
      line.alpha += (targetAlpha - line.alpha) * 0.18;
      line.width += (targetWidth - line.width) * 0.18;
      line.hovered = !!el._isHovered;
    }

    const travel = 1 - el._travel;
    const tx = -el._dirX * travel * TRAVEL_FRACTION;
    const ty = -el._dirY * travel * TRAVEL_FRACTION;
    const tilt = tiltEnabled
      ? ` rotateY(${(-el._side * 6 + swayX * 0.4).toFixed(2)}deg) rotateX(${(-swayY * 0.3).toFixed(2)}deg)`
      : "";

    el.style.transform =
      `perspective(760px) translate3d(${tx.toFixed(2)}px, ${ty.toFixed(2)}px, 0) scale(${el._focusScale.toFixed(4)})${tilt}`;
  }

  if (phase === "in" && elapsed > staggerFor(n - 1) + LINE_DRAW_DURATION + MATERIALIZE_DURATION) {
    finishEntrance();
  } else if (exiting && exitT >= 1) {
    clearOptions();
  }
}

/**
 * Snaps everything to its settled state. A frame hitch can skip the whole
 * entrance window, and nothing drives these values once the phase is over.
 */
function finishEntrance() {
  phase = "idle";

  for (const el of optionEls) {
    el.style.opacity = "";
    el._content.style.opacity = "";
    el._blobPath.style.strokeDasharray = "";
    el._blobPath.style.strokeDashoffset = "";
    el._blobPath.style.strokeOpacity = "";
    el._blobPath.style.fillOpacity = "";
    el._pathLength = 0;
    el._travel = 1;
    el.classList.add("visible");
  }

  for (const line of lineData) line.progress = 1;
}

/* ------------------------------------------------------- anchor / conectors */

function drawAnchor(ts) {
  actx.clearRect(0, 0, ANCHOR_SIZE, ANCHOR_SIZE);
  if (!lineData.length) return;

  actx.lineCap = "round";

  for (const line of lineData) {
    if (line.alpha <= 0.01) continue;

    const path = () => {
      actx.beginPath();
      actx.moveTo(line.startX + ANCHOR_HALF, line.startY + ANCHOR_HALF);
      for (let s = 0; s < line.curves.length; s++) {
        const c = line.curves[s];
        const sway = s % 2 === 0 ? 1 : -0.5;
        actx.quadraticCurveTo(
          c.cpx + swayX * sway + ANCHOR_HALF,
          c.cpy + swayY * sway + ANCHOR_HALF,
          c.ex + ANCHOR_HALF,
          c.ey + ANCHOR_HALF
        );
      }
    };

    if (line.progress < 0.999) {
      actx.setLineDash([line.len * line.progress, line.len]);
    } else {
      actx.setLineDash([]);
    }

    if (line.hovered) {
      actx.strokeStyle = rgba(accent, line.alpha * 0.16);
      actx.lineWidth = line.width + 5;
      path();
      actx.stroke();
    }

    // dark under-stroke keeps thin accent lines legible over bright scenery
    actx.strokeStyle = `rgba(0, 0, 0, ${(line.alpha * 0.5).toFixed(3)})`;
    actx.lineWidth = line.width + 2;
    path();
    actx.stroke();

    actx.strokeStyle = rgba(accent, line.alpha);
    actx.lineWidth = line.width;
    path();
    actx.stroke();
  }

  actx.setLineDash([]);

  // anchor dots where a line meets its option
  for (const line of lineData) {
    if (line.progress < 0.98 || line.alpha <= 0.05) continue;
    const r = line.hovered ? 3.4 : 2.2;
    actx.beginPath();
    actx.arc(line.nearX + ANCHOR_HALF, line.nearY + ANCHOR_HALF, r, 0, TAU);
    actx.fillStyle = rgba(accent, clamp(line.alpha + 0.2, 0, 1));
    actx.fill();
  }

  // data pulses travelling outwards
  for (const pulse of pulses) {
    const line = lineData[pulse.lineIdx];
    if (!line || line.progress < 0.999 || line.alpha <= 0.06) continue;

    pulse.t += pulse.speed * (line.hovered ? 2.4 : 1);
    if (pulse.t >= 1) pulse.t -= 1;

    const pos = evalCurves(line, pulse.t);
    const fade = clamp(Math.min(pulse.t, 1 - pulse.t) * 5, 0, 1);

    actx.beginPath();
    actx.arc(pos.x + ANCHOR_HALF, pos.y + ANCHOR_HALF, pulse.size, 0, TAU);
    actx.fillStyle = rgba([255, 255, 255], fade * line.alpha * 0.85);
    actx.fill();
  }

  // while locked the anchor keeps a marker on the target point
  if (lockAmt > 0.02) {
    const r = 7 + Math.sin(ts * 0.004) * 1.2;
    actx.save();
    actx.translate(ANCHOR_HALF, ANCHOR_HALF);
    actx.rotate(Math.PI / 4);
    actx.strokeStyle = rgba(accent, 0.75 * lockAmt);
    actx.lineWidth = 1.6;
    actx.strokeRect(-r, -r, r * 2, r * 2);
    actx.fillStyle = rgba(accent, 0.9 * lockAmt);
    actx.beginPath();
    actx.arc(0, 0, 1.6, 0, TAU);
    actx.fill();
    actx.restore();
  }
}

/* ------------------------------------------------------------ cursor / hud */

function updateMotes(ts) {
  if (motesActive) {
    moteAccum += MOTE_RATE;
    while (moteAccum >= 1) {
      moteAccum -= 1;
      const angle = Math.random() * TAU;
      const speed = MOTE_SPEED * (0.5 + Math.random() * 0.8);
      motes.push({
        x: 0,
        y: 0,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        alpha: 0.7,
        size: 1 + Math.random() * 1.4,
        life: MOTE_LIFE,
      });
    }
  }

  let j = 0;
  for (const p of motes) {
    p.x += p.vx;
    p.y += p.vy;
    p.life--;
    p.alpha = (p.life / MOTE_LIFE) * 0.65;

    if (p.life > 0 && Math.hypot(p.x, p.y) < MOTE_RANGE) motes[j++] = p;
  }
  motes.length = j;

  if (motesActive && ts > nextPing) {
    nextPing = ts + 1500;
    pings.push({ start: ts });
  }
}

function drawCursor(ts) {
  cctx.clearRect(0, 0, CURSOR_SIZE, CURSOR_SIZE);

  acq += ((hasTarget ? 1 : 0) - acq) * 0.14;
  lockAmt += ((isLocked ? 1 : 0) - lockAmt) * 0.14;

  const cx = CURSOR_HALF;
  const cy = CURSOR_HALF;

  // Soft dark halo so the marker survives white walls and bright skies.
  cctx.shadowColor = "rgba(0, 0, 0, 0.65)";
  cctx.shadowBlur = 4;

  // idle motes
  for (const p of motes) {
    cctx.beginPath();
    cctx.arc(cx + p.x, cy + p.y, p.size, 0, TAU);
    cctx.strokeStyle = rgba(accent, p.alpha * (1 - acq * 0.7));
    cctx.lineWidth = 0.7;
    cctx.stroke();
  }

  // radar pings while scanning
  for (let i = pings.length - 1; i >= 0; i--) {
    const p = (ts - pings[i].start) / 900;
    if (p >= 1) {
      pings.splice(i, 1);
      continue;
    }
    cctx.beginPath();
    cctx.arc(cx, cy, 8 + easeOut(p) * 42, 0, TAU);
    cctx.strokeStyle = rgba(accent, (1 - p) * 0.28 * (1 - acq));
    cctx.lineWidth = 1;
    cctx.stroke();
  }

  drawMarkerFrame(cctx, cx, cy, ts, { accent, acq, lock: lockAmt });
  drawMarker(cctx, cx, cy, ts, { kind: markerKind, accent, acq });

  // lock-on flash
  const flashT = (ts - acqFlash) / 260;
  if (flashT >= 0 && flashT < 1) {
    cctx.beginPath();
    cctx.arc(cx, cy, 48 - easeOut(flashT) * 24, 0, TAU);
    cctx.strokeStyle = rgba(accent, (1 - flashT) * 0.75);
    cctx.lineWidth = 1.6;
    cctx.stroke();
  }

  // select shockwaves
  for (let i = shockwaves.length - 1; i >= 0; i--) {
    const p = (ts - shockwaves[i]) / 420;
    if (p >= 1) {
      shockwaves.splice(i, 1);
      continue;
    }
    const e = easeOut(p);
    cctx.beginPath();
    cctx.arc(cx, cy, 10 + e * 78, 0, TAU);
    cctx.strokeStyle = rgba(accent, (1 - p) * 0.55);
    cctx.lineWidth = 2.4 * (1 - p) + 0.4;
    cctx.stroke();
  }
}

/* ---------------------------------------------------------------- messages */

function pick(el) {
  if (!el) return;
  shockwaves.push(performance.now());
  el._blobTarget = 6;
  setTimeout(() => {
    if (!el._isHovered) el._blobTarget = 0;
  }, 220);
  selectOption(el);
  startAnimation();
}

window.addEventListener("message", (event) => {
  const data = event.data;

  switch (data.event) {
    case "updateAccentColor":
      setAccent(data.r, data.g, data.b);
      return;

    case "visible": {
      if (data.state) {
        if (hideTimeout) {
          clearTimeout(hideTimeout);
          hideTimeout = null;
        }

        if (data.cursor) {
          mouseX = data.cursor.x * window.innerWidth;
          mouseY = data.cursor.y * window.innerHeight;
          prevMouseX = mouseX;
          prevMouseY = mouseY;
          positionCursorCanvas();
          wrapper.style.left = mouseX + "px";
          wrapper.style.top = mouseY + "px";
        }

        body.classList.toggle("hand-cursor", !!data.handCursor);

        body.style.visibility = "visible";
        tiltEnabled = !!data.tilt;
        if (data.vignette) vignette.classList.add("active");

        motesActive = true;
        motes = [];
        nextPing = 0;
        acq = 0;
        resetMarker(performance.now());
        startAnimation();
      } else {
        vignette.classList.remove("active");
        collapseOptions();
        isLocked = false;
        lockedX = null;
        lockedY = null;
        wrapper.classList.remove("locked");
        motesActive = false;

        hideTimeout = setTimeout(() => {
          // The settings panel owns the screen if it happens to be open.
          if (!isSettingsOpen()) body.style.visibility = "hidden";
          clearOptions();
          motes = [];
          pings = [];
          shockwaves = [];
          stopAnimation();
          cctx.clearRect(0, 0, CURSOR_SIZE, CURSOR_SIZE);
          hideTimeout = null;
        }, 400);
      }
      return;
    }

    case "leftTarget":
      if (!isLocked) {
        collapseOptions();
        motesActive = true;
        startAnimation();
      }
      return;

    case "lockOptions":
      isLocked = true;
      lockedX = parseFloat(wrapper.style.left) || mouseX;
      lockedY = parseFloat(wrapper.style.top) || mouseY;
      wrapper.classList.add("locked");
      startAnimation();
      return;

    case "unlockOptions":
      isLocked = false;
      lockedX = null;
      lockedY = null;
      wrapper.classList.remove("locked");
      return;

    case "hotkey":
      pick(optionEls[(data.index | 0) - 1]);
      return;

    case "setTarget":
      motesActive = false;
      setTargetOptions(data);
      return;

    case "updateSettings":
      if (data.settings) {
        markerKind = data.settings.marker === "crosshair" ? "crosshair" : "eye";
        applySettings(data.settings);
      }
      return;

    case "openSettings":
      openSettings(data);
      return;

    case "closeSettings":
      closeSettings();
      return;
  }
});

initSettings({ setAccent });
positionCursorCanvas();

// Ask Lua for the current settings/accent — a push sent while the page was
// still loading would have been dropped.
fetchNui("uiReady");
