/**
 * Bablo Chopshop - Modern Contract UI Logic
 */

// Application State
const state = {
  visible: false,
  difficultyKey: 'easy',
  difficultyLabel: 'DỄ',
  difficultyRank: 0,
  difficultyTotal: 3,
  vehiclesLeft: 0,
  activeTargetModel: null,
  contracts: []
};

// DOM Elements
const appEl = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const footerCloseBtn = document.getElementById('footerCloseBtn');
const difficultyBadge = document.getElementById('difficultyBadge');
const difficultyLabel = document.getElementById('difficultyLabel');
const progressPercent = document.getElementById('progressPercent');
const progressBarFill = document.getElementById('progressBarFill');
const vehiclesRemainingText = document.getElementById('vehiclesRemainingText');
const vehiclesGrid = document.getElementById('vehiclesGrid');
const emptyState = document.getElementById('emptyState');

/**
 * Helper to make NUI callback requests to FiveM Client
 */
async function fetchNui(eventName, data = {}) {
  const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'bablo-chopshop';
  try {
    const response = await fetch(`https://${resourceName}/${eventName}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify(data),
    });
    return await response.json();
  } catch (error) {
    console.warn(`[NUI] Failed to call ${eventName}:`, error);
    return null;
  }
}

/**
 * Close the UI
 */
function closeUI() {
  state.visible = false;
  appEl.style.display = 'none';
  fetchNui('contracts/close', {});
}

async function handleStartSearch(model) {
  if (!model) return;

  state.activeTargetModel = model.toLowerCase();
  renderContracts();

  const res = await fetchNui('contracts/startSearch', { model: model });
  if (res && (res.ok === false || res.status === false)) {
    console.warn('[NUI] startSearch returned error:', res.message);
    state.activeTargetModel = null;
    renderContracts();
  }
}

/**
 * Stop/Cancel current vehicle search
 */
async function handleStopSearch() {
  state.activeTargetModel = null;
  renderContracts();
  await fetchNui('contracts/stopSearch', {});
}


/**
 * Render the difficulty badge
 */
function renderDifficulty(key, label) {
  const diffKey = (key || 'easy').toLowerCase();
  difficultyBadge.className = 'difficulty-chip';
  
  if (diffKey === 'easy' || diffKey.includes('dễ') || diffKey.includes('de')) {
    difficultyBadge.classList.add('diff-easy');
    difficultyLabel.textContent = `DỄ`;
  } else if (diffKey === 'medium' || diffKey.includes('thường') || diffKey.includes('thuong')) {
    difficultyBadge.classList.add('diff-medium');
    difficultyLabel.textContent = `TRUNG BÌNH`;
  } else {
    difficultyBadge.classList.add('diff-hard');
    difficultyLabel.textContent = `KHÓ`;
  }

  if (label) {
    difficultyLabel.textContent = label.toUpperCase();
  }
}

/**
 * Render the progress bar and remaining counts
 */
function renderProgress() {
  const total = state.contracts.length;
  if (total === 0) {
    progressPercent.textContent = '0%';
    progressBarFill.style.width = '0%';
    vehiclesRemainingText.textContent = '0 XE';
    return;
  }

  const completed = state.contracts.filter(c => c.status === 'completed').length;
  const percent = Math.round((completed / total) * 100);
  const remaining = state.vehiclesLeft !== undefined ? state.vehiclesLeft : (total - completed);

  progressPercent.textContent = `${percent}%`;
  progressBarFill.style.width = `${percent}%`;
  vehiclesRemainingText.textContent = `${remaining} XE`;
}

/**
 * Render all vehicle contract cards
 */
function renderContracts() {
  renderProgress();
  vehiclesGrid.innerHTML = '';

  if (!state.contracts || state.contracts.length === 0) {
    emptyState.style.display = 'block';
    return;
  }

  emptyState.style.display = 'none';

  state.contracts.forEach(contract => {
    const card = document.createElement('div');
    const isCompleted = contract.status === 'completed';
    const isSearching = !isCompleted && state.activeTargetModel && (state.activeTargetModel.toLowerCase() === (contract.model || '').toLowerCase());
    
    card.className = 'vehicle-card';
    if (isCompleted) card.classList.add('is-completed');
    if (isSearching) card.classList.add('is-searching');

    const modelName = (contract.model || '').toLowerCase();
    const displayName = contract.label || modelName.toUpperCase();
    const vehicleClass = contract.class || 'Standard';
    const imgUrl = `https://docs.fivem.net/vehicles/${modelName}.webp`;

    card.setAttribute('data-model-code', modelName);

    // Status Badge Element
    let statusBadgeHtml = '';
    let actionBtnHtml = '';

    if (isCompleted) {
      statusBadgeHtml = `<span class="card-status-badge status-completed"><i class="fa-solid fa-check-double"></i> ĐÃ HOÀN THÀNH</span>`;
      actionBtnHtml = `<div class="btn-action-done"><i class="fa-solid fa-circle-check"></i> Đã tháo dỡ</div>`;
    } else if (isSearching) {
      statusBadgeHtml = `<span class="card-status-badge status-searching"><i class="fa-solid fa-radar fa-spin"></i> ĐANG THEO DÕI</span>`;
      actionBtnHtml = `
        <button class="btn-action-tracking" title="Nhấn để dừng định vị xe này" data-action="stop" data-model="${modelName}">
          <i class="fa-solid fa-satellite-dish"></i> Đang tìm (Dừng)
        </button>
      `;
    } else {
      statusBadgeHtml = `<span class="card-status-badge status-available"><i class="fa-solid fa-circle-dot"></i> CHƯA TÌM</span>`;
      actionBtnHtml = `
        <button class="btn-action-start" data-action="start" data-model="${modelName}">
          <i class="fa-solid fa-crosshairs"></i> Bắt đầu tìm
        </button>
      `;
    }

    card.innerHTML = `
      <div class="vehicle-thumb-box">
        <img class="vehicle-thumb-img" 
             src="${imgUrl}" 
             alt="${displayName}" 
             loading="lazy"
             onerror="this.style.display='none'; this.nextElementSibling.style.display='block';" />
        <i class="fa-solid fa-car-side vehicle-thumb-fallback" style="display: none;"></i>
      </div>

      <div class="vehicle-info">
        <div class="vehicle-top-row">
          <span class="vehicle-name" title="${displayName}">${displayName}</span>
          ${statusBadgeHtml}
        </div>

        <div class="vehicle-chips">
          <span class="chip-item">Phân khúc: <strong>${vehicleClass}</strong></span>
          <span class="chip-item chip-mono">ID: <strong>${modelName}</strong></span>
        </div>

        <div class="vehicle-action-area">
          ${actionBtnHtml}
        </div>
      </div>
    `;

    // Attach button events
    const startBtn = card.querySelector('[data-action="start"]');
    if (startBtn) {
      startBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        handleStartSearch(modelName);
      });
    }

    const stopBtn = card.querySelector('[data-action="stop"]');
    if (stopBtn) {
      stopBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        handleStopSearch();
      });
    }

    vehiclesGrid.appendChild(card);
  });
}

/**
 * Handle NUI Messages from Lua Client
 */
window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};

  switch (action) {
    case 'SET_VISIBLE':
      state.visible = Boolean(data);
      appEl.style.display = state.visible ? 'flex' : 'none';
      break;

    case 'CONTRACTS_OPEN':
      if (data) {
        state.difficultyKey = data.difficultyKey || 'easy';
        state.difficultyLabel = data.difficultyLabel || 'Dễ';
        state.difficultyRank = data.difficultyRank || 0;
        state.difficultyTotal = data.difficultyTotal || 3;
        state.vehiclesLeft = data.vehiclesLeft !== undefined ? data.vehiclesLeft : (data.contracts ? data.contracts.length : 0);
        state.activeTargetModel = data.activeTargetModel ? data.activeTargetModel.toLowerCase() : null;
        state.contracts = Array.isArray(data.contracts) ? data.contracts : [];

        renderDifficulty(state.difficultyKey, state.difficultyLabel);
        renderContracts();
      }
      break;

    default:
      break;
  }
});

// Event Listeners for Closing
closeBtn.addEventListener('click', closeUI);
footerCloseBtn.addEventListener('click', closeUI);

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && state.visible) {
    closeUI();
  }
});
