'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const crypto = require('crypto');
const { ProfilerMonitor } = require('./profiler');

function allowedAddress(address) {
  const ip = String(address || '').replace(/^::ffff:/, '');
  return ip === '127.0.0.1' || ip === '::1';
}

function authorized(req, token) {
  if (token.length < 32) return false;
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return false;
  const supplied = Buffer.from(header.slice(7), 'utf8');
  const expected = Buffer.from(token, 'utf8');
  return supplied.length === expected.length && crypto.timingSafeEqual(supplied, expected);
}

function json(res, code, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body), 'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff', 'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'" });
  res.end(body);
}

function createHandler({ root, token, monitor, host = '127.0.0.1', port = 32191 }) {
  const calls = new Map();
  return async function handle(req, res) {
    const ip = req.socket.remoteAddress;
    if (!allowedAddress(ip)) return json(res, 403, { error: 'network_denied' });
    const current = Date.now(), rate = calls.get(ip);
    if (!rate || current - rate.since > 60000) calls.set(ip, { since: current, count: 1 });
    else if (++rate.count > 600) return json(res, 429, { error: 'rate_limited' });
    if (req.method !== 'GET') return json(res, 405, { error: 'method_not_allowed' });
    const url = new URL(req.url, `http://${host}:${port}`);
    const staticFiles = { '/': ['index.html', 'text/html; charset=utf-8'],
      '/app.js': ['app.js', 'application/javascript; charset=utf-8'],
      '/app.css': ['app.css', 'text/css; charset=utf-8'] };
    if (staticFiles[url.pathname]) {
      const [name, mime] = staticFiles[url.pathname];
      try {
        const body = await fs.promises.readFile(path.join(root, 'web', name));
        res.writeHead(200, { 'Content-Type': mime, 'Content-Length': body.length,
          'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff',
          'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'" });
        return res.end(body);
      } catch { return json(res, 404, { error: 'not_found' }); }
    }
    if (!authorized(req, token)) return json(res, 401, { error: 'unauthorized' });
    if (url.pathname === '/profiler/status') return json(res, 200, monitor.status());
    if (url.pathname === '/profiler/summary') {
      try { return json(res, 200, await monitor.summary(url.searchParams.get('window') || '5m')); }
      catch (error) { return json(res, 400, { error: error.message }); }
    }
    if (url.pathname === '/profiler/samples') {
      try { return json(res, 200, monitor.listSamples(Object.fromEntries(url.searchParams))); }
      catch (error) { return json(res, 400, { error: error.message }); }
    }
    const match = /^\/profiler\/trace\/([A-Za-z0-9_-]+)$/.exec(url.pathname);
    if (match) {
      const file = monitor.tracePath(match[1]);
      if (!file) return json(res, 404, { error: 'trace_not_found' });
      const stat = await fs.promises.stat(file).catch(() => null);
      if (!stat?.isFile()) return json(res, 404, { error: 'trace_not_found' });
      res.writeHead(200, { 'Content-Type': 'application/json', 'Content-Length': stat.size,
        'Content-Disposition': `attachment; filename="profiler-${match[1]}.json"`,
        'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff',
        'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'" });
      const stream = fs.createReadStream(file);
      stream.on('error', () => res.destroy());
      return stream.pipe(res);
    }
    return json(res, 404, { error: 'not_found' });
  };
}

function startRuntime() {
  const resource = GetCurrentResourceName();
  const root = GetResourcePath(resource);
  const host = GetConvar('vx_profiler_host', '127.0.0.1');
  const port = Number.parseInt(GetConvar('vx_profiler_port', '32191'), 10);
  const token = GetConvar('vx_profiler_token', '') || GetConvar('vx_monitor_token', '');
  const monitor = new ProfilerMonitor(root);
  monitor.start().catch(error => {
    monitor.phase = 'error';
    monitor.lastError = `startup: ${error.message}`;
    console.error(`[vx_profiler_monitor] Startup failed: ${error.message}`);
  });
  if (token.length < 32) {
    console.error('[vx_profiler_monitor] Set vx_profiler_token (or vx_monitor_token) to at least 32 characters; dashboard disabled.');
    return;
  }
  if ((host !== '127.0.0.1' && host !== '::1') || !Number.isInteger(port) || port < 1 || port > 65535) {
    console.error('[vx_profiler_monitor] Bind must be loopback with a valid port; dashboard disabled.');
    return;
  }
  const handler = createHandler({ root, token, monitor, host, port });
  const server = http.createServer((req, res) => {
    handler(req, res).catch(error => {
      console.error(`[vx_profiler_monitor] HTTP error: ${error.message}`);
      if (!res.headersSent) json(res, 500, { error: 'internal_error' });
      else res.destroy();
    });
  });
  server.on('error', error => console.error(`[vx_profiler_monitor] Dashboard failed: ${error.message}`));
  server.listen(port, host, () => console.log(`[vx_profiler_monitor] Dashboard listening on ${host}:${port}`));
  on('onResourceStop', name => { if (name === resource) { monitor.stop(); server.close(); } });
}

if (typeof GetCurrentResourceName === 'function') startRuntime();

module.exports = { createHandler, allowedAddress, authorized, startRuntime };
