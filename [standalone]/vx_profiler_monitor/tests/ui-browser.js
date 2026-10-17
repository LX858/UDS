'use strict';

// Optional real-browser smoke test: node tests/ui-browser.js
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const net = require('net');
const { spawn } = require('child_process');
const { createHandler } = require('../server');

const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function freePort() {
  const server = net.createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  await new Promise(resolve => server.close(resolve));
  return port;
}
async function waitFor(callback, message) {
  for (let i = 0; i < 120; i++) {
    if (await callback()) return;
    await delay(100);
  }
  throw new Error(message);
}

async function main() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  if (!fs.existsSync(chromePath)) throw new Error('Chrome not installed');
  const root = path.resolve(__dirname, '..');
  const token = 'test-profiler-token-'.padEnd(40, 'x');
  const port = await freePort(), debugPort = await freePort();
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'vx-profiler-ui-'));
  const monitor = {
    status: () => ({ phase: 'idle', skippedBusy: 0, skippedExternal: 0, failures: 0, lastSampleAt: new Date().toISOString() }),
    summary: async windowName => ({ window: windowName, samples: 1, analyzedFrames: 349,
      availableFrom: new Date().toISOString(), to: new Date().toISOString(),
      p95Ms: 12, maxMs: 65, over50Ms: 1, partialScopes: false,
      trend: [{ at: new Date().toISOString(), samples: 1, p95Ms: 12, maxMs: 65 }],
      resources: [{ resource: 'alpha', selfMs: 100, perFrameMs: .287, calls: 349 }],
      scopes: [{ resource: 'alpha', name: 'event:test', totalMs: 50, maxMs: 4 }],
      slowFrames: [{ at: new Date().toISOString(), frame: 13, ms: 65 }] }),
    listSamples: () => ({ items: [{ id: 'sample-one', at: new Date().toISOString(),
      recordedFrames: 350, analyzedFrames: 349, frames: { p95Ms: 12 }, hasTrace: false }] }),
    tracePath: () => null,
  };
  const handler = createHandler({ root, token, monitor, port });
  const server = http.createServer((req, res) => handler(req, res).catch(error => { res.statusCode = 500; res.end(error.message); }));
  await new Promise(resolve => server.listen(port, '127.0.0.1', resolve));
  let chrome, socket;
  try {
    chrome = spawn(chromePath, ['--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
      `--user-data-dir=${profile}`, `--remote-debugging-port=${debugPort}`, '--window-size=1920,1080',
      `http://127.0.0.1:${port}/`], { windowsHide: true, stdio: 'ignore' });
    let page;
    await waitFor(async () => {
      try {
        const pages = await (await fetch(`http://127.0.0.1:${debugPort}/json/list`)).json();
        page = pages.find(item => item.type === 'page' && item.url.includes(String(port)));
        return !!page;
      } catch { return false; }
    }, 'Browser did not open dashboard');
    socket = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
    let nextId = 1;
    const pending = new Map();
    socket.onmessage = event => {
      const data = JSON.parse(event.data);
      if (!data.id || !pending.has(data.id)) return;
      const { resolve, reject } = pending.get(data.id);
      pending.delete(data.id);
      if (data.error) reject(new Error(data.error.message)); else resolve(data.result);
    };
    const send = (method, params) => new Promise((resolve, reject) => {
      const id = nextId++; pending.set(id, { resolve, reject }); socket.send(JSON.stringify({ id, method, params }));
    });
    const evaluate = async expression => {
      const result = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      if (result.exceptionDetails) throw new Error(result.exceptionDetails.text);
      return result.result.value;
    };
    await waitFor(() => evaluate("Boolean(document.getElementById('login-form'))"), 'Login missing');
    await evaluate(`document.getElementById('token').value=${JSON.stringify(token)}; document.getElementById('login-form').dispatchEvent(new Event('submit',{bubbles:true,cancelable:true}));`);
    await waitFor(() => evaluate("document.getElementById('resources').textContent.includes('alpha')"), 'Resource stats missing');
    assert.equal(await evaluate("document.getElementById('metric-p95').textContent.includes('12')"), true);
    await evaluate("document.querySelector('.window[data-window=\"24h\"]').click()");
    await waitFor(() => evaluate("document.querySelector('.window[data-window=\"24h\"]').classList.contains('active')"), '24h tab missing');
    assert.equal(await evaluate("document.getElementById('slow-frames').textContent.includes('65')"), true);
    console.log('Browser smoke passed: login, metrics, resource ranking, slow frame and 24h tab.');
  } finally {
    socket?.close();
    if (chrome && chrome.exitCode === null) {
      chrome.kill();
      await Promise.race([new Promise(resolve => chrome.once('exit', resolve)), delay(1000)]);
    }
    await new Promise(resolve => server.close(resolve));
    if (path.resolve(profile).startsWith(path.resolve(os.tmpdir()) + path.sep)) {
      try { fs.rmSync(profile, { recursive: true, force: true }); } catch { /* Chrome can still hold a file briefly. */ }
    }
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
