'use strict';

// Optional real-browser smoke test. Run with: node tests/ui-browser.js
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const net = require('net');
const { spawn } = require('child_process');

async function freePort() {
  const server = net.createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  await new Promise(resolve => server.close(resolve));
  return port;
}
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function waitFor(callback, message, timeout = 8000) {
  const until = Date.now() + timeout;
  while (Date.now() < until) {
    const result = await callback();
    if (result) return result;
    await delay(50);
  }
  throw new Error(message);
}

async function main() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  if (!fs.existsSync(chromePath)) throw new Error('Chrome is required for this optional smoke test.');
  const sourceRoot = path.resolve(__dirname, '..');
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vx-monitor-ui-'));
  fs.cpSync(path.join(sourceRoot, 'web'), path.join(root, 'web'), { recursive: true });
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'vx-monitor-chrome-'));
  const port = await freePort(), debugPort = await freePort();
  const token = 'browser-test-token-'.padEnd(64, 'x');
  const handlers = new Map();
  global.GetCurrentResourceName = () => 'vx_runtime_monitor';
  global.GetResourcePath = () => root;
  global.GetConvar = (name, fallback) => ({ vx_monitor_host: '127.0.0.1', vx_monitor_port: String(port), vx_monitor_token: token })[name] || fallback;
  global.GetConvarInt = (_name, fallback) => fallback;
  global.RegisterCommand = () => {};
  global.GetPlayers = () => [];
  global.GetAllObjects = () => [];
  global.GetAllPeds = () => [];
  global.GetAllVehicles = () => [];
  global.on = (name, callback) => handlers.set(name, callback);
  const monitor = require('../server');
  let chrome, socket;
  try {
    if (!monitor.server.listening) await new Promise(resolve => monitor.server.once('listening', resolve));
    handlers.get('__vx_runtime_monitor:batch')({ resource: 'weather', records: [
      { kind: 'event', phase: 'send-client', name: 'weather:sync', playerSessionId: 12, status: 'ok' },
      { kind: 'event', phase: 'send-client', name: 'weather:sync', status: 'broadcast' },
    ] });
    await monitor.store.flushAll();
    const originalGet = monitor.store.stats.get.bind(monitor.store.stats);
    monitor.store.stats.get = async query => {
      if (query.window === '24h') await delay(700);
      return originalGet(query);
    };
    chrome = spawn(chromePath, [
      '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
      `--user-data-dir=${profile}`, `--remote-debugging-port=${debugPort}`, '--window-size=1920,1080',
      `http://127.0.0.1:${port}/`,
    ], { windowsHide: true, stdio: 'ignore' });
    const page = await waitFor(async () => {
      try {
        const pages = await (await fetch(`http://127.0.0.1:${debugPort}/json/list`)).json();
        return pages.find(item => item.type === 'page' && item.url.includes(String(port)));
      } catch { return null; }
    }, 'Chrome DevTools did not start.');
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
      const id = nextId++;
      pending.set(id, { resolve, reject });
      socket.send(JSON.stringify({ id, method, params }));
    });
    const evaluate = async expression => {
      const result = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      if (result.exceptionDetails) throw new Error(result.exceptionDetails.text);
      return result.result.value;
    };
    await waitFor(() => evaluate("Boolean(document.getElementById('login-form'))"), 'Login did not render.');
    await evaluate(`document.getElementById('token').value=${JSON.stringify(token)}; document.getElementById('login-form').dispatchEvent(new Event('submit',{bubbles:true,cancelable:true}));`);
    await waitFor(() => evaluate("document.querySelector('#stats-body .clickable-row')?.textContent.includes('weather:sync')"), 'Stats did not render after login.');
    await evaluate("document.querySelector('#stats-body .clickable-row').click()");
    await waitFor(() => evaluate("document.getElementById('stats-detail').textContent.includes('Player #12')"), 'Target ID detail did not open.');
    await evaluate("document.querySelector('.window[data-window=\"24h\"]').click()");
    assert.equal(await evaluate("document.getElementById('stats-range').textContent.includes('Đang quét log 24 giờ')"), true);
    await waitFor(() => evaluate("document.querySelector('#stats-body .clickable-row')?.textContent.includes('weather:sync')"), '24h result did not render.');
    await evaluate("document.querySelector('.nav[data-view=\"records\"]').click()");
    await waitFor(() => evaluate("document.getElementById('records-view').classList.contains('hidden') === false"), 'Detailed log did not open.');
    assert.equal(await evaluate("document.getElementById('all-records').textContent"), 'Hiện tất cả');
    console.log('Browser smoke test passed: login, stats, target detail, 24h loading and detailed log.');
  } finally {
    socket?.close();
    if (chrome && chrome.exitCode === null) {
      chrome.kill();
      await Promise.race([new Promise(resolve => chrome.once('exit', resolve)), delay(1000)]);
    }
    await new Promise(resolve => monitor.server.close(resolve));
    await monitor.store.stop();
    if (path.resolve(root).startsWith(path.resolve(os.tmpdir()) + path.sep)) fs.rmSync(root, { recursive: true, force: true });
    if (path.resolve(profile).startsWith(path.resolve(os.tmpdir()) + path.sep)) {
      try { fs.rmSync(profile, { recursive: true, force: true }); } catch { /* Chrome child may still be closing. */ }
    }
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
