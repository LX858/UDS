'use strict';

const $ = id => document.getElementById(id);
let token = '', view = 'stats', history = false, showAll = false;
let windowSize = '5m', statsView = 'client', statsSearch = '';
let statsSerial = 0, statsLoadedAt = 0, statsLoadedKey = '', statsPendingKey = '';
const pages = { records: 1, players: 1, entities: 1 };
const number = n => new Intl.NumberFormat('vi-VN').format(n || 0);
const value = x => x === null || x === undefined || x === '' ? '—' : String(x);
const time = raw => { const date = new Date(raw); return Number.isNaN(date.getTime()) ? value(raw) : date.toLocaleString('vi-VN', { hour12: false }); };

async function api(route) {
  const response = await fetch(route, { headers: { Authorization: `Bearer ${token}` }, cache: 'no-store' });
  if (response.status === 401) throw new Error('Token không hợp lệ hoặc đã thay đổi.');
  if (!response.ok) throw new Error(`Yêu cầu thất bại (${response.status}).`);
  return response.json();
}
function cell(row, content, className = '') {
  const td = document.createElement('td'); td.textContent = value(content); td.className = className; row.appendChild(td); return td;
}
function empty(body, columns, message) {
  const row = document.createElement('tr'); cell(row, message, 'empty').colSpan = columns; body.appendChild(row);
}
function statsRoute(name) {
  const query = new URLSearchParams({ window: windowSize, view: statsView });
  if (name) query.set('name', name); else if (statsSearch) query.set('search', statsSearch);
  return `/stats?${query}`;
}
function statsColumns() {
  if (statsView === 'client') return ['Tên event', 'Tổng lượt gửi', 'Gửi -1', 'Gửi ID', 'Resource gửi nhiều nhất', 'Lần gần nhất'];
  if (statsView === 'local') return ['Tên event', 'Tổng lượt gửi', 'Resource gửi nhiều nhất', 'Lần gần nhất'];
  if (statsView === 'handled') return ['Tên event', 'Lượt chạy handler', 'Resource xử lý nhiều nhất', 'Lỗi', 'Lần gần nhất'];
  return ['Tên export', 'Bước', 'Số lần', 'Resource', 'Lỗi', 'Lần gần nhất'];
}
function renderStats(result) {
  const columns = statsColumns(), heading = document.createElement('tr'), body = $('stats-body');
  for (const label of columns) { const th = document.createElement('th'); th.textContent = label; heading.appendChild(th); }
  $('stats-head').replaceChildren(heading); body.replaceChildren();
  for (const item of result.top) {
    const row = document.createElement('tr'); cell(row, item.name, 'cell-strong');
    if (statsView === 'client') {
      cell(row, number(item.count), 'count-cell'); cell(row, number(item.broadcast)); cell(row, number(item.targeted)); cell(row, item.topResource);
    } else if (statsView === 'local') { cell(row, number(item.count), 'count-cell'); cell(row, item.topResource); }
    else if (statsView === 'handled') { cell(row, number(item.count), 'count-cell'); cell(row, item.topResource); cell(row, number(item.errors), item.errors ? 'cell-status error' : ''); }
    else { cell(row, item.phase === 'call' ? 'Gọi' : 'Thực thi'); cell(row, number(item.count), 'count-cell'); cell(row, item.topResource); cell(row, number(item.errors), item.errors ? 'cell-status error' : ''); }
    cell(row, item.lastAt ? time(item.lastAt) : null, 'cell-muted');
    if (item.name !== 'Khác') {
      row.className = 'clickable-row'; row.tabIndex = 0;
      row.addEventListener('click', () => openDetail(item.name));
      row.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); openDetail(item.name); } });
    }
    body.appendChild(row);
  }
  if (!result.top.length) empty(body, columns.length, 'Chưa có lượt gọi phù hợp trong khoảng thời gian này.');
  $('stats-range').textContent = `${time(result.availableFrom)} → ${time(result.to)}`;
  $('stats-total').textContent = statsView === 'client'
    ? `${number(result.total)} lượt · ${number(result.broadcast)} broadcast · ${number(result.targeted)} gửi ID`
    : `${number(result.total)} lượt · Top ${result.top.length} tên`;
  const notice = $('stats-notice');
  if (result.partial) {
    const messages = { retention: 'Dữ liệu ghi nhận từ thời điểm hiển thị; không thể xác nhận đủ cả khoảng đã chọn.',
      group_limit: 'Vượt 5.000 nhóm tên/resource; phần vượt được gộp vào Khác.',
      scan_incomplete: 'Có file log bị xóa trong lúc quét; hãy làm mới.' };
    notice.textContent = result.partialReasons.map(reason => messages[reason] || reason).join(' ');
    notice.classList.remove('hidden');
  } else notice.classList.add('hidden');
}
function detailList(parent, title, items, labelOf) {
  const section = document.createElement('section'), heading = document.createElement('h4');
  heading.textContent = title; section.appendChild(heading);
  if (!items.length) { const p = document.createElement('p'); p.textContent = 'Không xác định'; section.appendChild(p); }
  else {
    const list = document.createElement('div'); list.className = 'detail-list';
    for (const item of items) {
      const row = document.createElement('div'), label = document.createElement('span'), count = document.createElement('strong');
      label.textContent = labelOf(item); count.textContent = number(item.count); row.append(label, count); list.appendChild(row);
    }
    section.appendChild(list);
  }
  parent.appendChild(section);
}
async function openDetail(name) {
  const panel = $('stats-detail'); panel.classList.remove('hidden'); panel.replaceChildren();
  const header = document.createElement('div'), title = document.createElement('h3'), close = document.createElement('button');
  header.className = 'detail-head'; title.textContent = name; close.className = 'outline'; close.textContent = 'Đóng';
  close.addEventListener('click', () => panel.classList.add('hidden')); header.append(title, close); panel.appendChild(header);
  const loading = document.createElement('p'); loading.textContent = 'Đang tính phân bố…'; panel.appendChild(loading);
  const requestedWindow = windowSize, requestedView = statsView;
  try {
    const result = await api(statsRoute(name));
    if (panel.classList.contains('hidden') || requestedWindow !== windowSize || requestedView !== statsView) return;
    loading.remove();
    if (!result.selected) { const p = document.createElement('p'); p.textContent = 'Không còn dữ liệu cho event này.'; panel.appendChild(p); return; }
    const grid = document.createElement('div'); grid.className = 'detail-grid';
    detailList(grid, 'Theo resource', result.selected.resources, item => item.phase ? `${item.resource} · ${item.phase}` : item.resource);
    if (statsView === 'client') detailList(grid, 'Theo ID đích', result.selected.targets, item => item.id === '-1' ? '-1 · broadcast' : `Player #${item.id}`);
    if (statsView === 'handled') detailList(grid, 'Theo ID người gửi', result.selected.senders, item => `Player #${item.id}`);
    if (statsView === 'exports') detailList(grid, 'Theo bước', result.selected.phases, item => item.phase === 'call' ? 'Gọi' : 'Thực thi');
    panel.appendChild(grid);
  } catch (error) { loading.textContent = error.message; }
}
async function refreshStats(force = false) {
  const key = `${windowSize}:${statsView}:${statsSearch}`;
  const interval = windowSize === '24h' ? 60_000 : windowSize === '1h' ? 15_000 : 5_000;
  if (!force && (statsPendingKey === key || (statsLoadedKey === key && Date.now() - statsLoadedAt < interval))) return;
  const serial = ++statsSerial; statsPendingKey = key;
  if (statsLoadedKey !== key) {
    $('stats-range').textContent = windowSize === '24h' ? 'Đang quét log 24 giờ…' : 'Đang tính thống kê…';
    $('stats-total').textContent = ''; $('stats-body').replaceChildren();
    empty($('stats-body'), statsColumns().length, windowSize === '24h' ? 'Đang quét log 24 giờ; dữ liệu sẽ hiện khi tính xong…' : 'Đang tính thống kê…');
  }
  $('stats-detail').classList.add('hidden');
  try {
    const result = await api(statsRoute());
    if (serial !== statsSerial) return;
    statsLoadedKey = key; statsLoadedAt = Date.now(); renderStats(result);
  } catch (error) {
    if (serial === statsSerial) { $('stats-range').textContent = error.message; $('stats-body').replaceChildren(); empty($('stats-body'), statsColumns().length, 'Không tải được thống kê.'); }
  } finally { if (serial === statsSerial) statsPendingKey = ''; }
}
function recordRoute() {
  const query = new URLSearchParams({ page: String(pages.records), limit: '100' });
  for (const [key, raw] of new FormData($('filters')).entries()) {
    if (raw) query.set(key, key === 'from' || key === 'to' ? new Date(raw).toISOString() : raw);
  }
  if (history) query.set('history', '1'); if (!showAll) query.set('clean', '1');
  return `/records?${query}`;
}
async function refreshRecords() {
  const result = await api(recordRoute()), body = $('records-body'); body.replaceChildren();
  for (const item of result.records) {
    const row = document.createElement('tr');
    cell(row, time(item.timestamp), 'cell-muted'); cell(row, `${item.kind} / ${item.phase}`, 'cell-strong');
    cell(row, item.targetResource ? `${value(item.resource)} → ${item.targetResource}` : item.resource);
    cell(row, item.name, 'cell-strong');
    cell(row, item.status === 'broadcast' ? '-1 · broadcast' : item.playerSessionId ? `#${item.playerSessionId} ${item.playerName || ''}` : item.entityNetId !== null ? `Net ${item.entityNetId}` : null);
    cell(row, [item.payloadBytes !== null ? `${number(item.payloadBytes)} B` : '', item.wallMs !== null ? `${number(item.wallMs)} ms` : ''].filter(Boolean).join(' · '));
    cell(row, item.status, item.status === 'error' ? 'cell-status error' : 'cell-status'); body.appendChild(row);
  }
  if (!result.records.length) empty(body, 7, 'Không có bản ghi phù hợp.');
  $('records-count').textContent = `${result.records.length} bản ghi · ${history ? 'log trên đĩa' : 'bộ nhớ trực tiếp'}`;
  $('records-page').textContent = String(pages.records); $('records-prev').disabled = pages.records === 1; $('records-next').disabled = !result.hasMore;
  $('mode-label').textContent = history ? 'HISTORY' : 'LIVE';
}
async function refreshPlayers() {
  const result = await api(`/players?page=${pages.players}&limit=100`), body = $('players-body'); body.replaceChildren();
  for (const item of result.items) { const row = document.createElement('tr'); cell(row, item.id, 'cell-strong'); cell(row, item.name); cell(row, time(item.joinedAt), 'cell-muted'); body.appendChild(row); }
  if (!result.items.length) empty(body, 3, 'Không có player online.');
  $('players-count').textContent = `${number(result.total)} ONLINE`; $('players-page').textContent = String(pages.players);
  $('players-prev').disabled = pages.players === 1; $('players-next').disabled = pages.players * 100 >= result.total;
}
async function refreshEntities() {
  const query = new URLSearchParams({ page: String(pages.entities), limit: '100' });
  if ($('entity-type').value) query.set('type', $('entity-type').value);
  if ($('entity-resource').value) query.set('resource', $('entity-resource').value);
  const result = await api(`/entities?${query}`), body = $('entities-body'); body.replaceChildren();
  for (const item of result.items) { const row = document.createElement('tr'); cell(row, item.handle, 'cell-strong'); cell(row, item.type); cell(row, item.model); cell(row, item.netId); cell(row, item.owner); cell(row, item.resource); body.appendChild(row); }
  if (!result.items.length) empty(body, 6, 'Không có entity phù hợp.');
  $('entities-count').textContent = `${number(result.total)} ENTITIES`; $('entities-page').textContent = String(pages.entities);
  $('entities-prev').disabled = pages.entities === 1; $('entities-next').disabled = pages.entities * 100 >= result.total;
}
async function refresh(force = false) {
  if (!token) return;
  try {
    const [health, summary] = await Promise.all([api('/health'), api('/summary')]);
    $('health-badge').textContent = health.status;
    $('health-badge').className = `badge ${health.status === 'degraded' ? 'bad' : health.status === 'warming' ? 'warm' : ''}`;
    $('agent-info').textContent = `${health.freshAgents} agent đang gửi · queue ${number(health.queue)}`;
    $('metric-total').textContent = number(summary.total); $('metric-players').textContent = number(summary.players);
    $('metric-entities').textContent = number(summary.entities);
    $('metric-dropped').textContent = number((summary.dropped.agentsAfterStart || 0) + summary.dropped.collector + summary.dropped.disk);
    $('drop-detail').textContent = `${number(summary.dropped.agentsInitial || 0)} agent báo ở lần nhận đầu · ${number(summary.dropped.agentsAfterStart || 0)} agent sau đó · ${number(summary.dropped.collector)} queue · ${number(summary.dropped.disk)} disk`;
    if (view === 'stats') await refreshStats(force);
    if (view === 'records' && (!history || force)) await refreshRecords();
    if (view === 'players') await refreshPlayers(); if (view === 'entities') await refreshEntities();
    $('last-update').textContent = `Cập nhật ${new Date().toLocaleTimeString('vi-VN', { hour12: false })}`;
  } catch (error) { $('health-badge').textContent = 'Mất kết nối'; $('health-badge').className = 'badge bad'; $('last-update').textContent = error.message; }
}
function showView(next) {
  view = next;
  for (const item of ['stats', 'records', 'players', 'entities']) $(`${item}-view`).classList.toggle('hidden', item !== next);
  for (const item of document.querySelectorAll('.nav')) item.classList.toggle('active', item.dataset.view === next);
  $('view-title').textContent = { stats: 'Thống kê event', records: 'Log chi tiết', players: 'Players', entities: 'Entities' }[next]; refresh(true);
}
$('login-form').addEventListener('submit', async event => {
  event.preventDefault(); token = $('token').value.trim();
  try { await api('/health'); $('token').value = ''; $('login-error').textContent = ''; $('login').classList.add('hidden'); $('dashboard').classList.remove('hidden'); refresh(true); }
  catch (error) { token = ''; $('login-error').textContent = error.message; }
});
$('logout').addEventListener('click', () => { token = ''; $('dashboard').classList.add('hidden'); $('login').classList.remove('hidden'); });
$('refresh').addEventListener('click', () => refresh(true));
for (const item of document.querySelectorAll('.nav')) item.addEventListener('click', () => showView(item.dataset.view));
for (const item of document.querySelectorAll('.window')) item.addEventListener('click', () => {
  windowSize = item.dataset.window;
  for (const button of document.querySelectorAll('.window')) button.classList.toggle('active', button === item);
  refreshStats(true);
});
for (const item of document.querySelectorAll('.stats-tab')) item.addEventListener('click', () => {
  statsView = item.dataset.statsView;
  for (const button of document.querySelectorAll('.stats-tab')) button.classList.toggle('active', button === item);
  refreshStats(true);
});
let searchTimer;
$('stats-search').addEventListener('input', event => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => { statsSearch = event.target.value.trim(); refreshStats(true); }, 300);
});
$('filters').addEventListener('submit', event => { event.preventDefault(); pages.records = 1; refresh(true); });
$('all-records').addEventListener('click', () => { showAll = !showAll; $('all-records').textContent = showAll ? 'Ẩn bản ghi trùng' : 'Hiện tất cả'; pages.records = 1; refresh(true); });
$('history').addEventListener('click', () => { history = !history; pages.records = 1; $('history').textContent = history ? 'Về trực tiếp' : 'Xem log lưu'; refresh(true); });
$('entity-type').addEventListener('change', () => { pages.entities = 1; refresh(true); });
$('entity-resource').addEventListener('change', () => { pages.entities = 1; refresh(true); });
for (const item of ['records', 'players', 'entities']) {
  $(`${item}-prev`).addEventListener('click', () => { if (pages[item] > 1) pages[item]--; refresh(true); });
  $(`${item}-next`).addEventListener('click', () => { pages[item]++; refresh(true); });
}
setInterval(() => refresh(false), 3000);
