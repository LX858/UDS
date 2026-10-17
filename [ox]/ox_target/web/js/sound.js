// NEXUS synth SFX — everything generated with WebAudio oscillators, no audio assets.
let ctx = null;
let master = null;
let enabled = true;
let volume = 0.4;

function ensureCtx() {
  if (!enabled) return null;
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) {
      enabled = false;
      return null;
    }
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = volume * 0.55;
    master.connect(ctx.destination);
  }
  if (ctx.state === "suspended") ctx.resume();
  return ctx;
}

export function configureSound(on, vol) {
  enabled = on !== false;
  volume = Math.max(0, Math.min(1, (vol ?? 40) / 100));
  if (master) master.gain.value = volume * 0.55;
}

function tone({ freq = 440, end = 0, dur = 0.08, type = "sine", gain = 0.2, delay = 0, filter = 0 }) {
  const c = ensureCtx();
  if (!c) return;
  const t0 = c.currentTime + delay;
  const osc = c.createOscillator();
  const g = c.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, t0);
  if (end > 0) osc.frequency.exponentialRampToValueAtTime(end, t0 + dur);
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(gain, t0 + Math.min(0.014, dur * 0.35));
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);

  let head = osc;
  if (filter > 0) {
    const f = c.createBiquadFilter();
    f.type = "lowpass";
    f.frequency.value = filter;
    osc.connect(f);
    head = f;
  }
  head.connect(g);
  g.connect(master);
  osc.start(t0);
  osc.stop(t0 + dur + 0.05);
}

let noiseBuf = null;
function noise({ dur = 0.18, gain = 0.1, delay = 0, from = 500, to = 2600 }) {
  const c = ensureCtx();
  if (!c) return;
  if (!noiseBuf) {
    const len = Math.floor(c.sampleRate * 0.5);
    noiseBuf = c.createBuffer(1, len, c.sampleRate);
    const d = noiseBuf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
  }
  const t0 = c.currentTime + delay;
  const src = c.createBufferSource();
  src.buffer = noiseBuf;
  const f = c.createBiquadFilter();
  f.type = "bandpass";
  f.Q.value = 1.1;
  f.frequency.setValueAtTime(from, t0);
  f.frequency.exponentialRampToValueAtTime(to, t0 + dur);
  const g = c.createGain();
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(gain, t0 + dur * 0.3);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  src.connect(f);
  f.connect(g);
  g.connect(master);
  src.start(t0);
  src.stop(t0 + dur + 0.05);
}

export const sfx = {
  open() {
    noise({ dur: 0.2, gain: 0.07, from: 400, to: 3200 });
    tone({ freq: 340, end: 540, dur: 0.14, type: "sine", gain: 0.08 });
  },
  close() {
    tone({ freq: 480, end: 260, dur: 0.12, type: "sine", gain: 0.08 });
  },
  acquire() {
    tone({ freq: 640, dur: 0.04, type: "triangle", gain: 0.12 });
    tone({ freq: 920, dur: 0.05, type: "triangle", gain: 0.1, delay: 0.05 });
  },
  drop() {
    tone({ freq: 520, end: 380, dur: 0.05, type: "triangle", gain: 0.05 });
  },
  hover(i) {
    tone({ freq: 1300 + (i % 9) * 55, dur: 0.024, type: "triangle", gain: 0.055 });
  },
  select() {
    tone({ freq: 1500, dur: 0.03, type: "square", gain: 0.07, filter: 2400 });
    tone({ freq: 250, end: 170, dur: 0.1, type: "triangle", gain: 0.16, delay: 0.012 });
  },
  lock() {
    tone({ freq: 210, dur: 0.045, type: "square", gain: 0.12, filter: 900 });
    tone({ freq: 118, dur: 0.08, type: "sine", gain: 0.16, delay: 0.03 });
  },
  unlock() {
    tone({ freq: 150, end: 240, dur: 0.07, type: "square", gain: 0.07, filter: 900 });
  },
};

let chargeOsc = null;
let chargeGain = null;

function chargeStop() {
  if (!chargeOsc) return;
  try {
    const t = ctx.currentTime;
    chargeGain.gain.cancelScheduledValues(t);
    chargeGain.gain.setTargetAtTime(0.0001, t, 0.02);
    chargeOsc.stop(t + 0.12);
  } catch (e) { /* context may be gone */ }
  chargeOsc = null;
  chargeGain = null;
}

export function chargeStart() {
  const c = ensureCtx();
  if (!c) return;
  chargeStop();
  chargeOsc = c.createOscillator();
  chargeGain = c.createGain();
  const f = c.createBiquadFilter();
  f.type = "lowpass";
  f.frequency.value = 1400;
  chargeOsc.type = "sawtooth";
  chargeOsc.frequency.value = 160;
  chargeGain.gain.setValueAtTime(0.0001, c.currentTime);
  chargeGain.gain.exponentialRampToValueAtTime(0.05, c.currentTime + 0.05);
  chargeOsc.connect(f);
  f.connect(chargeGain);
  chargeGain.connect(master);
  chargeOsc.start();
}

export function chargeProgress(p) {
  if (!chargeOsc || !ctx) return;
  chargeOsc.frequency.setTargetAtTime(160 + p * 620, ctx.currentTime, 0.03);
}

export function chargeEnd(success) {
  chargeStop();
  if (success) {
    tone({ freq: 900, dur: 0.04, type: "triangle", gain: 0.12 });
    tone({ freq: 200, end: 130, dur: 0.12, type: "triangle", gain: 0.18, delay: 0.02 });
  } else {
    tone({ freq: 420, end: 300, dur: 0.06, type: "triangle", gain: 0.05 });
  }
}
