
const ctx = new (window.AudioContext || window.webkitAudioContext)();
const buffers = {};
const bust = Date.now();
const active = new Map();
const loading = new Set();

if (ctx.listener.forwardZ) {
    ctx.listener.forwardX.value = 0; ctx.listener.forwardY.value = 0; ctx.listener.forwardZ.value = -1;
    ctx.listener.upX.value = 0; ctx.listener.upY.value = 1; ctx.listener.upZ.value = 0;
    ctx.listener.positionX.value = 0; ctx.listener.positionY.value = 0; ctx.listener.positionZ.value = 0;
} else if (ctx.listener.setOrientation) {
    ctx.listener.setOrientation(0, 0, -1, 0, 1, 0);
    ctx.listener.setPosition(0, 0, 0);
}

async function grab(file) {
    if (buffers[file]) return buffers[file];
    const res = await fetch('sounds/' + file + '?v=' + bust, { cache: 'no-store' });
    buffers[file] = await ctx.decodeAudioData(await res.arrayBuffer());
    return buffers[file];
}

function move(panner, d) {
    if (panner.positionX) {
        panner.positionX.setTargetAtTime(d.x, ctx.currentTime, 0.02);
        panner.positionY.setTargetAtTime(d.y, ctx.currentTime, 0.02);
        panner.positionZ.setTargetAtTime(d.z, ctx.currentTime, 0.02);
    } else {
        panner.setPosition(d.x, d.y, d.z);
    }
}

window.addEventListener('message', async (e) => {
    const d = e.data;
    if (!d || !d.action) return;

    if (d.action === 'preload') {
        d.files.forEach(f => grab(f).catch(() => {}));
        return;
    }

    if (d.action === 'play') {
        loading.add(d.id);
        let buf;
        try { buf = await grab(d.file); } catch (err) { loading.delete(d.id); return; }
        if (ctx.state === 'suspended') { try { await ctx.resume(); } catch (err) {} }
        if (!loading.delete(d.id)) return;

        const src = ctx.createBufferSource();
        src.buffer = buf;
        src.loop = d.loop === true;

        const panner = ctx.createPanner();
        panner.panningModel = 'HRTF';
        panner.distanceModel = 'inverse';
        panner.refDistance = d.ref;
        panner.maxDistance = d.max;
        panner.rolloffFactor = d.rolloff;
        move(panner, d);

        const gain = ctx.createGain();
        gain.gain.value = d.volume;

        src.connect(gain).connect(panner).connect(ctx.destination);
        src.onended = () => active.delete(d.id);
        active.set(d.id, { src: src, gain: gain, panner: panner });
        src.start();
        return;
    }

    if (d.action === 'update') {
        const s = active.get(d.id);
        if (s) {
            s.gain.gain.setTargetAtTime(d.volume, ctx.currentTime, 0.05);
            move(s.panner, d);
        }
        return;
    }

    if (d.action === 'stop') {
        loading.delete(d.id);
        const s = active.get(d.id);
        if (s) {
            s.gain.gain.setTargetAtTime(0, ctx.currentTime, 0.035);
            try { s.src.stop(ctx.currentTime + 0.15); } catch (err) {}
            active.delete(d.id);
        }
    }
});
