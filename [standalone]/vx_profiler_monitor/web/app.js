'use strict';

const $ = id => document.getElementById(id);
let token = '', windowName = '5m', refreshing = false;
const number = value => new Intl.NumberFormat('vi-VN').format(value || 0);
const decimal = value => value == null ? '—' : new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 2 }).format(value);
const ms = value => value == null ? '—' : `${decimal(value)} ms`;
const date = value => value ? new Date(value).toLocaleString('vi-VN', { hour12: false }) : '—';

async function api(route) {
  const response = await fetch(route, { headers: { Authorization: `Bearer ${token}` }, cache: 'no-store' });
  if (response.status === 401) throw new Error('Token không hợp lệ hoặc đã thay đổi.');
  if (!response.ok) throw new Error(`Yêu cầu thất bại (${response.status}).`);
  return response.json();
}

function cell(row, text, className = '') {
  const item = document.createElement('td');
  item.textContent = text == null ? '—' : String(text);
  item.className = className;
  row.appendChild(item);
  return item;
}

function clearTable(id, columns, rows, render) {
  const body = $(id);
  body.replaceChildren();
  for (const item of rows) { const row = document.createElement('tr'); render(row, item); body.appendChild(row); }
  if (!rows.length) { const row = document.createElement('tr'); cell(row, 'Chưa có dữ liệu trong khoảng đã chọn.', 'empty').colSpan = columns; body.appendChild(row); }
}

function renderTrend(series) {
  const root = $('trend'); root.replaceChildren();
  if (!series.length) { const item = document.createElement('div'); item.className = 'empty'; item.textContent = 'Chưa có mẫu profiler.'; root.appendChild(item); return; }
  const peak = Math.max(50, ...series.map(item => item.maxMs || 0));
  for (const item of series) {
    const slot = document.createElement('div'), maximum = document.createElement('div'), p95 = document.createElement('div');
    slot.className = 'trend-slot'; maximum.className = 'trend-max'; p95.className = 'trend-p95';
    maximum.style.height = `${Math.max(2, (item.maxMs || 0) / peak * 100)}%`;
    p95.style.height = `${Math.max(2, (item.p95Ms || 0) / peak * 100)}%`;
    slot.title = `${date(item.at)} · ${item.samples} mẫu · P95 ${ms(item.p95Ms)} · cao nhất ${ms(item.maxMs)}`;
    slot.append(maximum, p95); root.appendChild(slot);
  }
}

function renderStatus(status) {
  const label = { idle: 'Đang chờ', recording: 'Đang ghi', saving: 'Đang lưu', analyzing: 'Đang phân tích', error: 'Lỗi', initializing: 'Khởi động' };
  $('state').textContent = label[status.phase] || status.phase;
  $('state').className = `badge ${status.phase === 'error' ? 'bad' : status.phase === 'idle' ? '' : 'warm'}`;
  $('metric-skipped').textContent = number(status.skippedBusy + status.skippedExternal + status.failures);
  $('metric-last').textContent = `Mẫu cuối ${date(status.lastSampleAt)}`;
  const notice = $('notice');
  if (status.lastError) { notice.textContent = `Lỗi profiler: ${status.lastError}. Lượt sau sẽ thử lại.`; notice.classList.remove('hidden'); }
  else if (status.skippedExternal) { notice.textContent = `Đã bỏ ${number(status.skippedExternal)} lượt vì profiler đang được dùng ở nơi khác.`; notice.classList.remove('hidden'); }
  else notice.classList.add('hidden');
}

function renderSummary(summary) {
  $('metric-samples').textContent = number(summary.samples);
  $('metric-frames').textContent = `${number(summary.analyzedFrames)} frame hoàn chỉnh`;
  $('metric-p95').textContent = ms(summary.p95Ms);
  $('metric-max').textContent = ms(summary.maxMs);
  $('metric-slow').textContent = `Trên 50 ms: ${number(summary.over50Ms)} frame`;
  $('range').textContent = `${date(summary.availableFrom)} → ${date(summary.to)}`;
  renderTrend(summary.trend);
  clearTable('resources', 4, summary.resources, (row, item) => {
    cell(row, item.resource, 'strong'); cell(row, ms(item.selfMs), 'numeric');
    cell(row, ms(item.perFrameMs), 'numeric'); cell(row, number(item.calls));
  });
  clearTable('scopes', 3, summary.scopes, (row, item) => {
    cell(row, `${item.resource} / ${item.name}`, 'strong');
    cell(row, ms(item.totalMs), 'numeric'); cell(row, ms(item.maxMs));
  });
  clearTable('slow-frames', 3, summary.slowFrames, (row, item) => {
    cell(row, date(item.at), 'muted'); cell(row, `#${item.frame}`, 'strong'); cell(row, ms(item.ms), 'numeric');
  });
  if (summary.partialScopes && !$('notice').textContent) {
    $('notice').textContent = 'Danh sách scope của một số mẫu vượt 100 mục; bảng scope có thể thiếu các mục nhỏ.';
    $('notice').classList.remove('hidden');
  }
}

async function downloadTrace(id, button) {
  button.disabled = true;
  try {
    const response = await fetch(`/profiler/trace/${encodeURIComponent(id)}`, {
      headers: { Authorization: `Bearer ${token}` }, cache: 'no-store' });
    if (!response.ok) throw new Error(`Không tải được trace (${response.status}).`);
    const blob = await response.blob();
    const url = URL.createObjectURL(blob), anchor = document.createElement('a');
    anchor.href = url; anchor.download = `profiler-${id}.json`; document.body.appendChild(anchor); anchor.click(); anchor.remove();
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  } catch (error) { $('notice').textContent = error.message; $('notice').classList.remove('hidden'); }
  finally { button.disabled = false; }
}

function renderSamples(result) {
  clearTable('samples', 4, result.items, (row, item) => {
    cell(row, date(item.at), 'muted'); cell(row, `${item.analyzedFrames}/${item.recordedFrames}`, 'strong');
    cell(row, ms(item.frames.p95Ms), 'numeric');
    const td = document.createElement('td');
    if (item.hasTrace) {
      const button = document.createElement('button'); button.className = 'download'; button.textContent = 'Tải JSON';
      button.addEventListener('click', () => downloadTrace(item.id, button)); td.appendChild(button);
    } else td.textContent = 'Đã xoá';
    row.appendChild(td);
  });
}

async function refresh() {
  if (!token || refreshing) return;
  refreshing = true;
  const requestedWindow = windowName;
  try {
    const [status, summary, samples] = await Promise.all([
      api('/profiler/status'), api(`/profiler/summary?window=${requestedWindow}`),
      api(`/profiler/samples?window=${requestedWindow}&limit=20`),
    ]);
    if (requestedWindow !== windowName) return;
    renderStatus(status); renderSummary(summary); renderSamples(samples);
    $('updated').textContent = `Cập nhật ${new Date().toLocaleTimeString('vi-VN', { hour12: false })}`;
  } catch (error) {
    $('state').textContent = 'Mất kết nối'; $('state').className = 'badge bad';
    $('notice').textContent = error.message; $('notice').classList.remove('hidden');
  } finally {
    refreshing = false;
    if (requestedWindow !== windowName) queueMicrotask(refresh);
  }
}

$('login-form').addEventListener('submit', async event => {
  event.preventDefault(); token = $('token').value.trim();
  try {
    await api('/profiler/status');
    $('token').value = ''; $('login-error').textContent = '';
    $('login').classList.add('hidden'); $('dashboard').classList.remove('hidden');
    refresh();
  } catch (error) { token = ''; $('login-error').textContent = error.message; }
});
$('logout').addEventListener('click', () => {
  token = ''; $('dashboard').classList.add('hidden'); $('login').classList.remove('hidden');
});
$('refresh').addEventListener('click', refresh);
for (const button of document.querySelectorAll('.window')) button.addEventListener('click', () => {
  windowName = button.dataset.window;
  for (const other of document.querySelectorAll('.window')) other.classList.toggle('active', other === button);
  refresh();
});
setInterval(refresh, 5000);
