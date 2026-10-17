const TAU = Math.PI * 2;

let nextBlink = 0;
let blinkStart = -1e9;

function rgba(color, alpha) {
  return `rgba(${color[0]}, ${color[1]}, ${color[2]}, ${alpha})`;
}

/** Called when the UI opens so the eye doesn't blink on the first frame. */
export function resetMarker(now) {
  nextBlink = now + 1200;
  blinkStart = -1e9;
}

/**
 * @param {CanvasRenderingContext2D} ctx
 * @param {number} cx
 * @param {number} cy
 * @param {number} ts frame timestamp
 * @param {{kind: string, accent: number[], acq: number}} o acq = 0 scanning → 1 locked on
 */
export function drawMarker(ctx, cx, cy, ts, o) {
  if (o.kind === "crosshair") drawCrosshair(ctx, cx, cy, o);
  else drawEye(ctx, cx, cy, ts, o);
}

/** The original reticle: inner ring, four ticks and a centre dot. */
function drawCrosshair(ctx, cx, cy, { accent, acq }) {
  ctx.lineWidth = 1;
  ctx.strokeStyle = rgba(accent, 0.14 + 0.22 * acq);
  ctx.beginPath();
  ctx.arc(cx, cy, 12.5, 0, TAU);
  ctx.stroke();

  ctx.strokeStyle = rgba(accent, 0.55 + 0.35 * acq);
  ctx.lineWidth = 1.2;

  for (let i = 0; i < 4; i++) {
    const a = (i * Math.PI) / 2;
    const c = Math.cos(a);
    const s = Math.sin(a);
    ctx.beginPath();
    ctx.moveTo(cx + c * 5, cy + s * 5);
    ctx.lineTo(cx + c * 9.5, cy + s * 9.5);
    ctx.stroke();
  }

  ctx.beginPath();
  ctx.arc(cx, cy, 1.5 + acq * 0.9, 0, TAU);
  ctx.fillStyle = rgba(accent, 0.95);
  ctx.fill();
}

/**
 * The third eye. It squints, blinks and glances around while scanning, then
 * opens wide and dilates onto whatever the player is pointing at.
 */
function drawEye(ctx, cx, cy, ts, { accent, acq }) {
  if (ts > nextBlink) {
    blinkStart = ts;
    nextBlink = ts + 2600 + Math.random() * 3200;
  }

  const blinkT = (ts - blinkStart) / 190;
  const lid = blinkT >= 0 && blinkT < 1 ? 1 - Math.sin(blinkT * Math.PI) * 0.94 : 1;

  const halfW = 15.5 + 4 * acq;
  const halfH = (7.4 + 3.6 * acq) * lid;
  const wander = 1 - acq;
  const gazeX = (Math.sin(ts * 0.00072) * 1.6 + Math.sin(ts * 0.00131) * 0.9) * wander;
  const gazeY = Math.cos(ts * 0.00094) * 0.9 * wander;

  // lens: two mirrored quadratics, filled dark so it reads against bright walls
  ctx.beginPath();
  ctx.moveTo(cx - halfW, cy);
  ctx.quadraticCurveTo(cx, cy - halfH * 2, cx + halfW, cy);
  ctx.quadraticCurveTo(cx, cy + halfH * 2, cx - halfW, cy);
  ctx.closePath();
  ctx.fillStyle = `rgba(4, 6, 10, ${(0.34 + 0.16 * acq).toFixed(3)})`;
  ctx.fill();
  ctx.strokeStyle = rgba(accent, 0.55 + 0.4 * acq);
  ctx.lineWidth = 1.5 + 0.3 * acq;
  ctx.stroke();

  if (lid < 0.35) return; // mid-blink, skip the iris

  // iris clipped to the lens so it never spills over the lid
  ctx.save();
  ctx.clip();

  const irisR = 4.6 + 2.2 * acq;
  const ix = cx + gazeX;
  const iy = cy + gazeY;

  ctx.beginPath();
  ctx.arc(ix, iy, irisR, 0, TAU);
  ctx.fillStyle = rgba(accent, 0.42 + 0.28 * acq);
  ctx.fill();
  ctx.strokeStyle = rgba(accent, 0.9);
  ctx.lineWidth = 1.2;
  ctx.stroke();

  ctx.beginPath();
  ctx.arc(ix, iy, 2.1 + 0.6 * acq, 0, TAU);
  ctx.fillStyle = `rgba(3, 5, 9, ${(0.72 + 0.2 * acq).toFixed(3)})`;
  ctx.fill();

  ctx.beginPath();
  ctx.arc(ix - irisR * 0.42, iy - irisR * 0.42, 1.1, 0, TAU);
  ctx.fillStyle = "rgba(255, 255, 255, 0.5)";
  ctx.fill();

  ctx.restore();
}

/**
 * Frame that surrounds the marker: corner brackets, scan arcs and the locked
 * ring. Shared with the settings preview so both look identical.
 * @param {{accent: number[], acq: number, lock: number}} o
 */
export function drawMarkerFrame(ctx, cx, cy, ts, { accent, acq, lock }) {
  const spin = ts * 0.0011;

  if (acq < 0.98) {
    const a = (1 - acq) * 0.55;
    ctx.lineWidth = 1.4;
    ctx.strokeStyle = rgba(accent, a);
    for (let i = 0; i < 2; i++) {
      ctx.beginPath();
      ctx.arc(cx, cy, 25, spin + i * Math.PI, spin + i * Math.PI + 1.05);
      ctx.stroke();
    }
  }

  // corner brackets snap inwards on acquire (all but invisible while scanning)
  const bracketR = 36 - 11 * acq;
  const offset = 0.3 * (1 - acq) + lock * ts * 0.00022;
  ctx.lineWidth = 1.7 + 0.7 * acq;
  ctx.strokeStyle = rgba(accent, 0.05 + 0.79 * acq);

  for (let i = 0; i < 4; i++) {
    const a = offset + Math.PI / 4 + (i * Math.PI) / 2;
    ctx.beginPath();
    ctx.arc(cx, cy, bracketR, a - 0.3, a + 0.3);
    ctx.stroke();
  }

  if (lock > 0.02) {
    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(ts * 0.0004);
    ctx.setLineDash([3, 7]);
    ctx.strokeStyle = rgba(accent, 0.5 * lock);
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.arc(0, 0, 33, 0, TAU);
    ctx.stroke();
    ctx.restore();
    ctx.setLineDash([]);
  }
}
