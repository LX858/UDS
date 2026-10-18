const app = document.getElementById('app');
const hud = document.getElementById('rental-hud');
let locale = {}, theme = {}, mode = null, menu = {}, selectedPlan = '', account = '', pending = false;
let rental = null, deadline = 0, draft = null, entries = {}, pinned = false, raised = true, groundValid = false, confirmation = null, presets = [], blipCfg = {}, browsePage = null, blipSig = '';
const t = key => locale[key] || '';
let placementStage = 'capsule', capsuleReady = false;
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const icons = {
    bolt: '<path d="m13 2-3 8H4l7 12 3-8h6Z"/>',
    pin: '<path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    wallet: '<path d="M20 8V5H5a2 2 0 0 0 0 4h16v11H5a2 2 0 0 1-2-2V7"/><path d="M21 12h-5v4h5"/>',
    card: '<rect x="2" y="4" width="20" height="16" rx="2"/><path d="M2 10h20m-15 5h3"/>',
    arrow: '<path d="M5 12h14m-6-6 6 6-6 6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    trash: '<path d="M4 7h16M9 7V5h6v2m-8 0 1 13h8l1-13"/>',
};
const icon = name => `<svg viewBox="0 0 24 24" aria-hidden="true">${icons[name] || icons.bolt}</svg>`;
const money = value => `${theme.currency || '$'}${Number(value || 0).toLocaleString(theme.numberLocale || 'en-US')}`;
const clock = () => { const value = Math.max(0, Math.ceil((deadline - Date.now()) / 1000)); return `${Math.floor(value / 60).toString().padStart(2,'0')}:${(value % 60).toString().padStart(2,'0')}`; };
function configure(data) {
    if (data.locale) locale = data.locale;
    if (data.theme) {
        theme = data.theme;
        for (const [key, variable] of Object.entries({accent:'accent',accentSecondary:'secondary',panel:'panel',text:'text',muted:'muted'})) {
            if (/^#[0-9a-f]{6}$/i.test(theme[key] || '')) document.documentElement.style.setProperty(`--${variable}`, theme[key]);
        }
        document.documentElement.style.setProperty('--scale', Math.min(1.3, Math.max(.65, Number(theme.scale) || 1)));
        place();
    }
}
const clampPercent = value => Math.min(90, Math.max(0, Number(value) || 0));
function place() {
    const root = document.documentElement.style;
    root.setProperty('--menu-x', `${clampPercent(theme.menuOffsetX ?? 2.35)}vw`);
    root.setProperty('--menu-y', `${clampPercent(theme.menuOffsetY ?? 6.5)}vh`);
    root.setProperty('--hud-x', `${clampPercent(theme.rentalOffsetX ?? 2.35)}vw`);
    root.setProperty('--hud-y', `${clampPercent(theme.rentalOffsetY ?? 4)}vh`);
    const menu = String(theme.menuAnchor || 'left').toLowerCase();
    document.body.classList.toggle('menu-right', menu === 'right');
    document.body.classList.toggle('menu-center', menu === 'center');
    const rentalAnchor = String(theme.rentalAnchor || 'bottom-left').toLowerCase();
    document.body.classList.toggle('hud-right', rentalAnchor.includes('right'));
    document.body.classList.toggle('hud-top', rentalAnchor.includes('top'));
    document.body.classList.toggle('hud-center', rentalAnchor.includes('center'));
}
async function post(name, data = {}) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 18000);
    try {
        const response = await fetch(`https://${GetParentResourceName()}/${name}`, {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data),signal:controller.signal});
        return await response.json();
    } catch { return {ok:false,error:t('connection_error')}; }
    finally { clearTimeout(timer); }
}
function error(message) {
    const box = document.getElementById('error');
    if (box) { box.textContent = message || ''; box.hidden = !message; }
}
function shell(creator = false) {
    if (creator) {
        app.className = 'creator ag-skin';
        return `<header class="ag-hero">
  <div class="ag-hero-glow" aria-hidden="true"></div>
  <div class="ag-hero-orbit" aria-hidden="true"></div>
  <div class="ag-hero-top">
    <div class="ag-brand">
      <img class="ag-brand-logo" src="images/allgamers.png" alt="ALLGAMERS">
      <div class="ag-brand-text">
        <strong>${esc(t('brand'))}</strong>
        <em>VAULT SYSTEMS</em>
        <span class="ag-live"><i></i> LIVE EDITOR</span>
      </div>
    </div>
    <button class="ag-close close" data-action="close" type="button">${esc(t('close'))}<kbd>ESC</kbd></button>
  </div>
  <div class="ag-banner">
    <img src="images/allgamers.png" alt="ALLGAMERS">
  </div>
  <div class="ag-hero-title">
    <p class="ag-kicker">STATION TOOLING / V2</p>
    <h1>${esc(t('creator'))}</h1>
    <p class="ag-sub">${esc(t('creator_subtitle'))}</p>
  </div>
  <div class="ag-steps" aria-hidden="true"><span class="on">01 Đặt vị trí</span><span>02 Căn chỉnh</span><span>03 Lưu lại</span></div>
  <div class="ag-hero-bar" aria-hidden="true"></div>
</header>`;
    }
    app.className = '';
    return `<div class="topline"><div class="wordmark">${esc(t('brand'))}<span>.</span></div><button class="close" data-action="close">${esc(t('close'))}<kbd>ESC</kbd></button></div><div class="heading"><h1>${esc(t('title'))}</h1><p>${esc(t('subtitle'))}</p></div>`;
}
function setRental(value) {
    rental = value || null;
    deadline = rental ? Date.now() + rental.remaining * 1000 : 0;
    renderHud();
}
function renderHud() {
    const show = !!(rental && !mode);
    hud.hidden = !show;
    if (!show) {
        hud.classList.remove('is-on', 'is-urgent', 'is-warn');
        return;
    }
    const left = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
    const urgent = left <= 60;
    const warn = left <= 180 && left > 60;
    hud.classList.toggle('is-urgent', urgent);
    hud.classList.toggle('is-warn', warn);
    hud.classList.add('is-on');
    hud.innerHTML = `
<span class="rh-glow" aria-hidden="true"></span>
<span class="rh-scan" aria-hidden="true"></span>
<div class="rh-icon" aria-hidden="true">
  <i class="rh-ring"></i>
  ${icon('clock')}
</div>
<div class="rh-copy">
  <small class="rh-kicker">ALLGAMERS · LIVE</small>
  <strong>${esc(t('active'))}</strong>
  <em>${esc(rental.plate)}</em>
</div>
<div class="rh-timer">
  <span class="rh-label">${esc(t('remaining') || 'THỜI GIAN CÒN LẠI')}</span>
  <b data-clock>${clock()}</b>
  <i class="rh-bar" aria-hidden="true"></i>
</div>`;
}
function renderMenu() {
    if (mode !== 'rental') return;
    const plan = (menu.plans || []).find(p => p.id === selectedPlan);
    let content = `<div class="station">${icon('pin')}<span>${esc(menu.station?.name || t('station'))}</span><small>${esc(t(menu.busy ? 'busy' : 'available'))}</small></div>`;
    if (menu.rental) {
        content += `<h2 class="section-title">${esc(t('remaining'))}</h2><div class="countdown" data-clock>${clock()}</div><div class="rental-detail">${esc(t('plate'))}<b>${esc(menu.rental.plate)}</b></div>`;
        if (menu.rental.recoverable) content += `<p class="notice">${esc(t('recover_hint'))}</p><button class="primary" data-action="recover" ${pending || menu.busy ? 'disabled' : ''}>${esc(t('recover'))}${icon('arrow')}</button>`;
        content += `<button class="secondary" data-action="askReturn" ${pending ? 'disabled' : ''}>${esc(t('return_rental'))}</button>`;
    } else {
        content += `<h2 class="section-title">${esc(t('duration'))}</h2><div class="plans">${(menu.plans || []).map(p => `<button class="plan ${p.id === selectedPlan ? 'selected' : ''}" data-plan="${esc(p.id)}" aria-pressed="${p.id === selectedPlan}" ${pending ? 'disabled' : ''}><i class="check"></i><strong>${p.minutes}</strong><small>${esc(t('minutes'))}</small><span class="price">${esc(money(p.price))}</span></button>`).join('')}</div><h2 class="section-title">${esc(t('payment'))}</h2><div class="payments">${(menu.accounts || []).map(a => `<button class="payment ${a === account ? 'selected' : ''}" data-account="${esc(a)}" aria-pressed="${a === account}" ${pending ? 'disabled' : ''}>${icon(a === 'bank' ? 'card' : 'wallet')}<span>${esc(t(a))}<small>${esc(money(menu.balance?.[a]))}</small></span></button>`).join('')}</div><p class="terms">${esc(t('terms'))}</p>`;
    }
    app.innerHTML = shell() + `<div class="body">${content}<div id="error" class="error" role="alert" hidden></div><div id="confirm"></div></div>` + (!menu.rental ? `<div class="checkout"><div class="total"><span>${esc(t('total'))}</span><strong>${esc(money(plan?.price))}</strong></div><button class="primary" data-action="rent" ${!plan || !account || pending || menu.busy ? 'disabled' : ''}>${esc(t(pending ? 'working' : 'rent'))}${icon('arrow')}</button></div>` : '');
    showConfirmation();
}
function showConfirmation() {
    const el = document.getElementById('confirm');
    if (!el) return;
    el.innerHTML = confirmation ? `<div class="confirm-box"><p>${esc(t(confirmation === 'delete' ? 'delete_confirm' : 'return_confirm'))}</p><div class="row"><button class="secondary" data-action="confirm" ${pending ? 'disabled' : ''}>${esc(t('confirm'))}</button><button class="secondary" data-action="cancelConfirm" ${pending ? 'disabled' : ''}>${esc(t('cancel'))}</button></div></div>` : '';
}
function renderCreator() {
    if (mode !== 'creator') return;
    blipSig = '';
    app.innerHTML = shell(true) + `<div class="ag-body body">
<section class="ag-block ag-versions">
  <div class="ag-block-head"><b>Chế độ đặt trạm</b><small>CHỌN BỐ TRÍ</small></div>
  <h2 class="ag-label">${esc(t('station_version'))}</h2>
  <div class="version-options ag-version-grid">${['booth','tablet'].map(v=>`<button class="version-card ag-card" data-version="${v}" aria-pressed="false" type="button"><span class="version-number">0${v==='booth'?1:2}</span><strong>${esc(t('version_'+v))}</strong><small>${esc(t('version_'+v+'_hint'))}</small></button>`).join('')}</div>
  <div class="placement-stages ag-stages"><button data-stage="capsule" type="button">1 · ${esc(t('place_capsule'))}</button><button data-stage="terminal" type="button">2 · <span id="terminal-stage-label"></span></button></div>
  <p class="hint ag-hint" id="component-hint"></p>
  <button class="primary ag-cta" id="save" data-creator="save" type="button">${esc(t('save'))}${icon('arrow')}</button>
  <div id="error" class="error ag-error" role="alert" hidden></div>
</section>
<section class="ag-block">
  <div class="ag-block-head"><b>Cài đặt trạm</b><small>XEM TRỰC TIẾP</small></div>
  <div class="row ag-actions"><button class="secondary compact" data-creator="new" type="button">${icon('plus')}${esc(t('new_station'))}</button><button id="pin" class="secondary compact" data-creator="pin" type="button"></button></div>
  <h2 class="ag-label">${esc(t('name'))}</h2><input id="name" aria-label="${esc(t('name'))}" maxlength="60">
  <h2 class="ag-label">${esc(t('capsule_side'))}</h2><select id="side"><option value="right">${esc(t('side_right'))}</option><option value="left">${esc(t('side_left'))}</option></select>
  <h2 class="ag-label">${esc(t('position'))}</h2><div class="coords ag-coords">${['x','y','z'].map(a => `<label>${a.toUpperCase()}<input type="number" step="0.01" id="coord-${a}" data-axis="${a}" aria-label="${a.toUpperCase()}"></label>`).join('')}</div>
  <h2 class="ag-label">${esc(t('strip_color'))}</h2><div class="swatches ag-swatches">${presets.map(c => `<button class="swatch" data-color="${esc(c)}" style="background:${esc(c)}" title="${esc(c)}" type="button"></button>`).join('')}<input id="color" maxlength="9" aria-label="${esc(t('strip_color'))}"></div>
  <p class="hint ag-hint">${esc(t('strip_hint'))}</p>
  <h2 class="ag-label">${esc(t('blip'))}</h2><div id="blipbox" class="ag-blip"></div>
  <h2 class="ag-label">${esc(t('heading'))}</h2><input id="heading" type="number" min="0" max="359.99" step="1" aria-label="${esc(t('heading'))}">
  <div class="row ag-actions" style="margin-top:10px"><button class="secondary compact" data-creator="ground" type="button">${esc(t('ground'))}</button><button class="secondary compact" id="preview" data-creator="preview" type="button"></button></div>
  <p class="status ag-status" id="placement-status"></p>
  <button class="danger ag-danger" id="delete" data-action="askDelete" type="button" hidden>${esc(t('delete'))}</button>
  <div id="confirm"></div>
</section>
<section class="ag-block">
  <div class="ag-block-head"><b>Danh sách trạm</b><small>TRÊN BẢN ĐỒ</small></div>
  <div class="station-list ag-stations">${Object.values(entries).length ? Object.values(entries).map(e => `<div class="station-row"><button class="station-item" data-edit="${esc(e.id)}" title="${esc(t('travel'))}" type="button">${icon('pin')}<span>${esc(e.name || t('station'))}</span><small>${esc(t(e.fixed ? 'static_station' : 'travel'))}</small></button>${e.fixed ? '' : `<button class="station-del" data-remove="${esc(e.id)}" title="${esc(t('delete'))}" type="button">${icon('trash')}</button>`}</div>`).join('') : `<p class="empty">${esc(t('empty_stations'))}</p>`}</div>
  <div id="step" class="step ag-step"></div>
  ${hints()}
</section>
</div>`;
    updateCreator();
}
function hints() {
    const rows = [
        ['key_rmb','hint_look'], ['key_arrows','hint_nudge'], ['key_qe','hint_rotate'],
        ['key_pages','hint_height'], ['key_shift','hint_precise'], ['key_esc','hint_cancel'],
    ];
    return `<div class="creator-hints ag-hints">${rows.map(([k, label]) =>
        `<div><kbd>${esc(t(k))}</kbd><span>${esc(t(label))}</span></div>`).join('')}` +
        `<div class="wide"><kbd>${esc(t('key_enter'))}</kbd><span>${esc(t('hint_lock'))} → ${esc(t('hint_save'))}</span></div></div>`;
}
const BLIP_HINT = {0:'#ffffff',1:'#e04b4b',2:'#4cd964',3:'#3a7fe0',5:'#f0d040',7:'#8a5cff',8:'#ff64c8',
    11:'#7ae05a',15:'#4fd6e0',17:'#f09a3c',18:'#7fc4ff',38:'#2f6fd0',46:'#c94f4f'};

function blipValue(key, fallback) {
    const own = (draft && draft.blip) || {};
    if (own[key] !== undefined && own[key] !== null) return own[key];
    return blipCfg[key] !== undefined ? blipCfg[key] : fallback;
}
function renderBlip() {
    const box = document.getElementById('blipbox');
    if (!box || !draft) return;
    const on = blipValue('enabled', true) !== false;
    const sprite = blipValue('sprite', 226), colour = blipValue('color', 3), scale = blipValue('scale', 0.75);
    const label = blipValue('label', ''), short = blipValue('shortRange', true), flash = blipValue('flash', false);

    // The placement loop pushes state every 120 ms. Rewriting this box on each push swallowed
    // clicks that landed mid-render, so it is only rebuilt when something here actually changed.
    const sig = [on, sprite, colour, scale, label, short, flash, browsePage].join('|');
    // Never rebuild while a field in here has focus: the old guard only covered the number
    // inputs, so typing a blip name lost focus mid-word and the change event never fired.
    if (box.contains(document.activeElement) && document.activeElement.matches('input,textarea,select')) return;
    if (sig === blipSig && box.childElementCount) return;
    blipSig = sig;

    const chips = (list, field, current, hint) => (list || []).map(v =>
        `<button class="chip ${String(v) === String(current) ? 'selected' : ''}" data-blip="${field}" data-value="${v}"${
            hint ? ` style="border-color:${BLIP_HINT[v] || '#ffffff30'};color:${BLIP_HINT[v] || 'inherit'}"` : ''}>${v}</button>`).join('');

    box.innerHTML = `<button class="secondary compact ${on ? 'selected' : ''}" data-blip="enabled" data-value="${on ? 'false' : 'true'}">${
        esc(t(on ? 'blip_on' : 'blip_off'))}</button>` + (!on ? '' : `
        <label>${esc(t('blip_label'))}</label><input id="blip-label" maxlength="40" value="${esc(label)}" placeholder="${esc(t('blip_label_hint'))}">
        <label>${esc(t('blip_sprite'))}</label><div class="chips">${chips(blipCfg.sprites, 'sprite', sprite)}
            <input type="number" min="1" max="5000" value="${sprite}" data-blipnum="sprite"></div>
        <div class="row"><button class="secondary compact" data-blip="browse" data-value="${(browsePage || 1) - 1 || 1}">‹</button>
            <button class="secondary compact ${browsePage ? 'selected' : ''}" data-blip="browse" data-value="${browsePage ? 'false' : 1}">${
                esc(t(browsePage ? 'blip_browse_off' : 'blip_browse'))}${browsePage ? ` ${(browsePage - 1) * 12 + 1}-${browsePage * 12}` : ''}</button>
            <button class="secondary compact" data-blip="browse" data-value="${(browsePage || 0) + 1}">›</button></div>
        <label>${esc(t('blip_color'))}</label><div class="chips">${chips(blipCfg.colors, 'color', colour, true)}
            <input type="number" min="0" max="85" value="${colour}" data-blipnum="color"></div>
        <label>${esc(t('blip_scale'))}</label><div class="chips">
            <input type="number" min="0.1" max="2" step="0.05" value="${Number(scale).toFixed(2)}" data-blipnum="scale"></div>
        <div class="row"><button class="secondary compact ${short ? 'selected' : ''}" data-blip="shortRange" data-value="${short ? 'false' : 'true'}">${
            esc(t('blip_short'))}</button>
        <button class="secondary compact ${flash ? 'selected' : ''}" data-blip="flash" data-value="${flash ? 'false' : 'true'}">${
            esc(t('blip_flash'))}</button></div>
        <p class="hint">${esc(t('blip_hint'))}</p>`);
}
function updateCreator() {
    if (mode !== 'creator' || !draft) return;
    const value = (id, text) => { const el = document.getElementById(id); if (el && document.activeElement !== el) el.value = text; };
    const pose = placementStage==='terminal' ? (draft.terminal || draft) : draft;
    value('name', draft.name); value('heading', Number(pose.heading).toFixed(1)); value('side', draft.side || 'right');
    document.querySelectorAll('[data-version]').forEach(el=>{const selected=el.dataset.version===(draft.version||'booth');el.classList.toggle('selected',selected);el.setAttribute('aria-pressed',String(selected));});
    document.querySelectorAll('[data-stage]').forEach(el=>{el.classList.toggle('selected',el.dataset.stage===placementStage);el.disabled=el.dataset.stage==='terminal'&&!capsuleReady;});
    document.getElementById('terminal-stage-label').textContent=t('version_'+(draft.version||'booth'));
    document.getElementById('component-hint').textContent=t(placementStage==='capsule'?'capsule_step_hint':'terminal_step_hint');
    document.getElementById('side').disabled=placementStage==='terminal';
    value('color', draft.color || '');
    document.querySelectorAll('.swatch').forEach(el =>
        el.classList.toggle('selected', (el.dataset.color || '').toLowerCase() === String(draft.color || '').toLowerCase()));
    for (const axis of ['x','y','z']) value(`coord-${axis}`, Number(pose.coords[axis]).toFixed(3));
    document.getElementById('pin').textContent = t(pinned ? 'follow' : 'pin');
    document.getElementById('pin').classList.toggle('selected', pinned);
    document.getElementById('preview').textContent = `${t('preview')}: ${t(raised ? 'raised' : 'closed')}`;
    document.getElementById('placement-status').textContent = t(pinned ? 'pinned' : groundValid ? 'follow' : 'ground_failed');
    const step = document.getElementById('step');
    if (step) {
        step.innerHTML = pinned ? esc(t('step_ready')) : groundValid
            ? `<b>${esc(t('key_enter'))}</b> — ${esc(t('step_lock'))}`
            : esc(t('step_aim'));
        step.classList.toggle('done', pinned);
    }
    document.getElementById('save').disabled = (!pinned && !groundValid) || pending;
    document.getElementById('save').innerHTML=esc(t(placementStage==='capsule'?'confirm_capsule':'save_station'))+icon('arrow');
    document.getElementById('delete').hidden = !draft.id;
    const steps = document.querySelectorAll('.ag-steps span');
    if (steps.length === 3) {
        steps[0].classList.toggle('on', true);
        steps[1].classList.toggle('on', capsuleReady || placementStage === 'terminal');
        steps[2].classList.toggle('on', pinned && placementStage === 'terminal');
    }
    renderBlip();
}
async function creatorAction(action, extra = {}) {
    if (pending) return;
    const mutation = ['save','delete'].includes(action);
    if (mutation) { pending = true; updateCreator(); }
    const result = await post('creatorAction', {action,...extra});
    pending = false;
    if (!result?.ok) error(result?.error || t('connection_error'));
    updateCreator();
}
function forceCloseUi() {
    mode = null;
    confirmation = null;
    app.hidden = true;
    app.setAttribute('hidden', '');
    app.style.setProperty('display', 'none', 'important');
    renderHud();
    try {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: '{}',
        }).catch(() => {});
    } catch (_) {}
}
app.addEventListener('click', async event => {
    const closeBtn = event.target.closest('[data-action="close"], .ag-close');
    if (closeBtn) {
        event.preventDefault();
        event.stopPropagation();
        forceCloseUi();
        return;
    }
    const button = event.target.closest('button');
    if (!button || button.disabled) return;
    if (button.dataset.plan) { selectedPlan = button.dataset.plan; confirmation = null; renderMenu(); return; }
    if (button.dataset.account) { account = button.dataset.account; renderMenu(); return; }
    if (button.dataset.blip) {
        const raw = button.dataset.value;
        const value = raw === 'true' ? true : raw === 'false' ? false : Number(raw);
        const field = button.dataset.blip;
        if (draft && field !== 'browse') { draft.blip = draft.blip || {}; draft.blip[field] = value; renderBlip(); }
        if (field === 'browse') browsePage = value === false ? null : value;
        creatorAction('blip', {field, value});
        return;
    }
    if (button.dataset.version) { await creatorAction('version',{value:button.dataset.version}); return; }
    if (button.dataset.stage) { await creatorAction('stage',{value:button.dataset.stage}); return; }
    if (button.dataset.color) { await creatorAction('color', {value:button.dataset.color}); return; }
    if (button.dataset.creator) { await creatorAction(button.dataset.creator); return; }
    if (button.dataset.remove) { await creatorAction('remove', {id:button.dataset.remove}); return; }
    if (button.dataset.edit) { await creatorAction('edit', {id:button.dataset.edit}); return; }
    const action = button.dataset.action;
    if (action === 'askReturn' || action === 'askDelete') { confirmation = action === 'askReturn' ? 'returnRental' : 'delete'; showConfirmation(); return; }
    if (action === 'cancelConfirm') { confirmation = null; showConfirmation(); return; }
    if (action === 'confirm' && confirmation === 'delete') { await creatorAction('delete'); return; }
    const endpoint = action === 'confirm' ? confirmation : action;
    if (!['rent','recover','returnRental'].includes(endpoint) || pending) return;
    pending = true; renderMenu();
    const result = await post(endpoint, {plan:selectedPlan,account});
    pending = false;
    if (result?.ok) {
        if (endpoint === 'returnRental') setRental(null); else if (result.rental) setRental(result.rental);
        forceCloseUi();
    } else { renderMenu(); error(result?.error || t('connection_error')); }
});
app.addEventListener('change', event => {
    if (mode !== 'creator') return;
    const input = event.target;
    if (input.id === 'side') creatorAction('side', {value:input.value});
    if (input.id === 'name') creatorAction('name', {value:input.value});
    if (input.id === 'color') creatorAction('color', {value:input.value});
    if (input.dataset.blipnum) creatorAction('blip', {field:input.dataset.blipnum, value:Number(input.value)});
    if (input.id === 'blip-label') { blipSig = ''; creatorAction('blip', {field:'label', value:input.value}); }
    if (input.id === 'heading') creatorAction('heading', {value:Number(input.value)});
    if (input.dataset.axis) creatorAction('coordinate', {axis:input.dataset.axis,value:Number(input.value)});
});
app.addEventListener('input', event => {
    if (mode !== 'creator' || event.target.id !== 'blip-label' || !draft) return;
    draft.blip = draft.blip || {};
    draft.blip.label = event.target.value;
    clearTimeout(event.target._t);
    event.target._t = setTimeout(() => creatorAction('blip', {field:'label', value:event.target.value}), 250);
});
app.addEventListener('focusin', event => { if (mode === 'creator' && event.target.tagName === 'INPUT') post('creatorTyping',{active:true}); });
app.addEventListener('focusout', event => { if (mode === 'creator' && event.target.tagName === 'INPUT') post('creatorTyping',{active:false}); });
function denyTab() {
    app.querySelectorAll('button,input,a,[tabindex]').forEach(el => el.tabIndex = -1);
}
const observer = new MutationObserver(denyTab);
observer.observe(app, { childList: true, subtree: true });
window.addEventListener('keydown', event => {
    if (event.key === 'Tab') { event.preventDefault(); return; }
    if (!mode) return;

    if (event.key === 'Enter' && mode === 'creator') {
        const el = document.activeElement;
        const tag = (el && el.tagName) || '';
        if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') {
            el.blur();
            post('creatorTyping', { active: false });
        }
        event.preventDefault();
        if (!pinned) creatorAction('pin');
        else creatorAction('save');
        return;
    }

    if (event.key !== 'Escape') return;
    event.preventDefault();
    if (confirmation) { confirmation = null; showConfirmation(); return; }
    forceCloseUi();
});
window.addEventListener('message', event => {
    const d = event.data;
    if (!d || !['openMenu','closeMenu','rentalUpdate','openCreator','closeCreator','creatorState','creatorError'].includes(d.action)) return;
    configure(d);
    if (d.action === 'openMenu') {
        mode = 'rental'; pending = false; confirmation = null; menu = d.data;
        selectedPlan = menu.plans?.[0]?.id || ''; account = menu.accounts?.[0] || '';
        setRental(menu.rental); app.hidden = false; app.style.removeProperty('display'); renderMenu();
    } else if ((d.action === 'closeMenu' && mode === 'rental') || (d.action === 'closeCreator' && (mode === 'creator' || !app.hidden))) {
        mode = null; confirmation = null; app.hidden = true; app.setAttribute('hidden', '');
        app.style.setProperty('display', 'none', 'important'); renderHud();
    } else if (d.action === 'rentalUpdate') {
        setRental(d.rental);
        if (mode === 'rental' && !app.hidden) { menu.rental = rental; renderMenu(); }
    } else if (d.action === 'openCreator') {
        mode = 'creator'; pending = false; confirmation = null; draft = null; entries = d.locations || {};
        presets = Array.isArray(d.presets) ? d.presets.filter(c => /^#[0-9a-f]{6}$/i.test(c)) : [];
        blipCfg = d.blips || {}; app.hidden = false; app.style.removeProperty('display'); renderHud(); renderCreator();
    } else if (d.action === 'creatorState') {
        if (mode !== 'creator') return;
        placementStage=d.stage||'capsule';capsuleReady=d.capsuleReady===true;
        draft = d.draft; pinned = d.pinned; raised = d.raised; groundValid = d.groundValid;
        browsePage = d.browsePage ?? null; updateCreator();
    } else if (d.action === 'creatorError') { error(d.error); }
});
setInterval(() => {
    if (!rental) return;
    document.querySelectorAll('[data-clock]').forEach(el => el.textContent = clock());
    if (!mode && !hud.hidden) {
        const left = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
        hud.classList.toggle('is-urgent', left <= 60);
        hud.classList.toggle('is-warn', left <= 180 && left > 60);
    }
}, 1000);
