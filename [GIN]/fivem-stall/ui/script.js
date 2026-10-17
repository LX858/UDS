function getRarityClass(rarityVal) {
  if (!rarityVal) return 'common';
  const val = String(rarityVal).toLowerCase().trim();
  if (val === 'common' || val === 'thuong' || val === 'thường' || val === '1') return 'common';
  if (val === 'uncommon' || val === 'khong pho bien' || val === 'không phổ biến' || val === '2') return 'uncommon';
  if (val === 'rare' || val === 'hiem' || val === 'hiếm' || val === '3') return 'rare';
  if (val === 'epic' || val === 'su thi' || val === 'sử thi' || val === '4') return 'epic';
  if (val === 'legendary' || val === 'huyen thoai' || val === 'huyền thoại' || val === '5') return 'legendary';
  return val;
}

function getRarityLabel(rarityClass) {
  const labels = {
    common: 'Thường',
    uncommon: 'Không phổ biến',
    rare: 'Hiếm',
    epic: 'Sử thi',
    legendary: 'Huyền thoại'
  };
  return labels[rarityClass] || rarityClass.toUpperCase();
}

let currentStallData = null;
let currentStallConfig = null;
let isOwner = false;
let countdownInterval = null;
let selectedItem = null;
let selectedInventoryItem = null;
let playerInventory = [];
let currentStallItems = [];
let isProcessing = false;
let isRentPopup = false;

// State management
let stallState = {
  isRented: false,
  isOwner: false,
  stallId: null
};

// Event listeners
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      const tabName = this.getAttribute('data-tab');
      switchTab(tabName);
    });
  });

  document.querySelectorAll('.sub-tab-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      const subTabName = this.getAttribute('data-subtab');
      switchSubTab(subTabName);
    });
  });

  document.getElementById('buy-backdrop').addEventListener('click', closeBuyPopup);
  document.getElementById('rent-backdrop').addEventListener('click', closeRentPopup);
  document.getElementById('sell-backdrop').addEventListener('click', closeSellPopup);
  document.getElementById('renew-backdrop').addEventListener('click', closeRenewPopup);

  document.getElementById('buy-quantity').addEventListener('focus', function () {
    this.select();
  });

  document.getElementById('rent-hours').addEventListener('focus', function () {
    this.select();
  });

  document.getElementById('rent-hours-input').addEventListener('focus', function () {
    this.select();
  });

  document.getElementById('sell-quantity').addEventListener('focus', function () {
    this.select();
  });

  document.getElementById('renew-hours-input').addEventListener('focus', function () {
    this.select();
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeAll();
    }
  });
});

// NUI Messages
window.addEventListener('message', (event) => {
  const data = event.data;

  if (data.action === 'openStall') {
    openStallUI(data.stallData, data.isOwner, data.stallConfig);
  } else if (data.action === 'openRent') {
    openRentUI(data.stallId, data.stallConfig);
  } else if (data.action === 'closeUI') {
    closeAll();
  } else if (data.action === 'notification') {
    showNotification(data.message, data.type);
  } else if (data.action === 'refresh') {
    refreshUI();
  }
});

function openStallUI(stallData, isOwnerValue, stallConfig) {
  currentStallData = stallData;
  currentStallConfig = stallConfig;
  isOwner = isOwnerValue;

  stallState.isRented = stallData !== null && stallData !== undefined;
  stallState.isOwner = isOwnerValue;
  stallState.stallId = stallConfig ? stallConfig.id : null;

  // Cập nhật header
  document.getElementById('stall-name').textContent = stallConfig ? stallConfig.name : 'Gian hàng';

  if (stallState.isRented) {
    document.getElementById('stall-owner').textContent = stallData.owner_name || 'N/A';
    document.getElementById('stall-status').innerHTML = `👤 Chủ: <span id="stall-owner">${stallData.owner_name || 'N/A'}</span>`;

    // Hiển thị countdown
    document.getElementById('countdown-container').style.display = 'flex';
    document.getElementById('renew-btn').style.display = isOwnerValue ? 'block' : 'none';
    if (stallData.rent_end) {
      startCountdown(stallData.rent_end);
    }
  } else {
    document.getElementById('stall-owner').textContent = 'Chưa có';
    document.getElementById('stall-status').innerHTML = `👤 Chủ: <span id="stall-owner">Chưa có</span>`;
    document.getElementById('countdown-container').style.display = 'none';
    document.getElementById('renew-btn').style.display = 'none';
    if (countdownInterval) {
      clearInterval(countdownInterval);
      countdownInterval = null;
    }
  }

  // Cập nhật UI tabs
  updateTabVisibility();

  // Hiển thị container
  document.getElementById('main-container').style.display = 'flex';

  if (!stallState.isRented) {
    switchTab('rent');
    updateRentUI(stallConfig);
  } else if (stallState.isOwner) {
    switchTab('manage');
    setTimeout(() => {
      switchSubTab('sell');
      loadPlayerInventory();
      loadStallItems();
    }, 100);
    renderItems(stallData.items || []);
    updateRevenueInfo(stallData);
  } else {
    switchTab('sell');
    renderItems(stallData.items || []);
  }
}

function updateTabVisibility() {
  const rentTab = document.getElementById('rent-tab');
  const sellTab = document.getElementById('sell-tab');
  const manageTab = document.getElementById('manage-tab');
  const revenueTab = document.getElementById('revenue-tab');

  rentTab.style.display = 'none';
  sellTab.style.display = 'none';
  manageTab.style.display = 'none';
  revenueTab.style.display = 'none';

  if (!stallState.isRented) {
    rentTab.style.display = 'block';
    rentTab.classList.add('active');
  } else if (stallState.isOwner) {
    sellTab.style.display = 'block';
    manageTab.style.display = 'block';
    revenueTab.style.display = 'block';
    rentTab.style.display = 'none';
  } else {
    sellTab.style.display = 'block';
    rentTab.style.display = 'none';
  }
}

function updateRentUI(stallConfig) {
  if (!stallConfig) return;

  document.getElementById('rent-stall-name-display').textContent = stallConfig.name || 'Gian hàng';
  document.getElementById('rent-price-display').textContent = formatMoney(stallConfig.rentPrice || 1000) + '$';
  document.getElementById('rent-hours-input').max = stallConfig.maxHours || 24;
  document.getElementById('rent-hours-input').value = 1;
  updateRentTotalDisplay();
}

function updateRentTotalDisplay() {
  const hours = parseInt(document.getElementById('rent-hours-input').value) || 1;
  const price = currentStallConfig ? currentStallConfig.rentPrice : 1000;
  const total = price * hours;
  document.getElementById('rent-total-display').textContent = formatMoney(total) + '$';
}

function changeRentHours(delta) {
  const input = document.getElementById('rent-hours-input');
  let value = parseInt(input.value) + delta;
  if (isNaN(value)) value = 1;
  const max = parseInt(input.max) || 24;
  if (value < 1) value = 1;
  if (value > max) value = max;
  input.value = value;
  updateRentTotalDisplay();
}

function validateRentHours() {
  const input = document.getElementById('rent-hours-input');
  let value = parseInt(input.value);
  if (isNaN(value) || value < 1) value = 1;
  const max = parseInt(input.max) || 24;
  if (value > max) value = max;
  input.value = value;
  updateRentTotalDisplay();
}

function confirmRent() {
  if (!currentStallConfig) {
    showNotification('Không tìm thấy thông tin gian hàng!', 'error');
    return;
  }

  const hours = parseInt(document.getElementById('rent-hours-input').value);
  if (hours <= 0 || hours > (currentStallConfig.maxHours || 24)) {
    showNotification('Số giờ không hợp lệ!', 'error');
    return;
  }

  $.post('https://' + GetParentResourceName() + '/rentStall', JSON.stringify({
    stallId: currentStallConfig.id,
    hours: hours
  }), function (response) {
    setTimeout(() => {
      closeAll();
    }, 500);
  }).fail(function () {
    showNotification('Có lỗi xảy ra khi thuê gian hàng!', 'error');
  });
}

// RENEW STALL
function openRenewPopup() {
  if (!currentStallConfig || !currentStallData) {
    showNotification('Không tìm thấy thông tin gian hàng!', 'error');
    return;
  }

  document.getElementById('renew-stall-name').textContent = currentStallConfig.name || 'Gian hàng';
  document.getElementById('renew-price').textContent = formatMoney(currentStallConfig.rentPrice || 1000) + '$';
  document.getElementById('renew-current-time').textContent = document.getElementById('countdown-timer').textContent;
  document.getElementById('renew-hours-input').value = 1;
  document.getElementById('renew-hours-input').max = currentStallConfig.maxHours || 24;
  updateRenewTotal();

  document.getElementById('renew-backdrop').style.display = 'block';
  document.getElementById('renew-popup').style.display = 'block';
}

function closeRenewPopup() {
  document.getElementById('renew-backdrop').style.display = 'none';
  document.getElementById('renew-popup').style.display = 'none';
}

function changeRenewHours(delta) {
  const input = document.getElementById('renew-hours-input');
  let value = parseInt(input.value) + delta;
  if (isNaN(value)) value = 1;
  const max = parseInt(input.max) || 24;
  if (value < 1) value = 1;
  if (value > max) value = max;
  input.value = value;
  updateRenewTotal();
}

function validateRenewHours() {
  const input = document.getElementById('renew-hours-input');
  let value = parseInt(input.value);
  if (isNaN(value) || value < 1) value = 1;
  const max = parseInt(input.max) || 24;
  if (value > max) value = max;
  input.value = value;
  updateRenewTotal();
}

function updateRenewTotal() {
  const hours = parseInt(document.getElementById('renew-hours-input').value) || 1;
  const price = currentStallConfig ? currentStallConfig.rentPrice : 1000;
  const total = price * hours;
  document.getElementById('renew-total').textContent = formatMoney(total) + '$';
}

function confirmRenewPopup() {
  if (!currentStallConfig || !currentStallData) {
    showNotification('Không tìm thấy thông tin gian hàng!', 'error');
    return;
  }

  const hours = parseInt(document.getElementById('renew-hours-input').value);
  if (hours <= 0 || hours > (currentStallConfig.maxHours || 24)) {
    showNotification('Số giờ không hợp lệ!', 'error');
    return;
  }

  $.post('https://' + GetParentResourceName() + '/renewStall', JSON.stringify({
    stallId: currentStallConfig.id,
    hours: hours
  }), function (response) {
    setTimeout(() => {
      refreshUI();
      showNotification('Gia hạn gian hàng thành công!', 'success');
      closeRenewPopup();
    }, 500);
  }).fail(function () {
    showNotification('Có lỗi xảy ra khi gia hạn gian hàng!', 'error');
  });
}

function openRentUI(stallId, stallConfig) {
  currentStallConfig = stallConfig;
  currentStallData = { stall_id: stallId };
  isRentPopup = true;

  document.getElementById('rent-stall-name').textContent = stallConfig.name;
  document.getElementById('rent-price').textContent = formatMoney(stallConfig.rentPrice) + '$';
  document.getElementById('rent-hours').value = 1;
  document.getElementById('rent-hours').max = stallConfig.maxHours || 24;

  updateRentTotal();

  document.getElementById('rent-backdrop').style.display = 'block';
  document.getElementById('rent-popup').style.display = 'block';
}

function closeRentPopup() {
  document.getElementById('rent-backdrop').style.display = 'none';
  document.getElementById('rent-popup').style.display = 'none';
  currentStallData = null;
  isRentPopup = false;
  $.post('https://' + GetParentResourceName() + '/closeUI', JSON.stringify({
  }));

}

function changeRentHoursPopup(delta) {
  const input = document.getElementById('rent-hours');
  let value = parseInt(input.value) + delta;
  if (isNaN(value)) value = 1;
  const max = parseInt(input.max) || 24;
  if (value < 1) value = 1;
  if (value > max) value = max;
  input.value = value;
  updateRentTotal();
}

function validateRentHoursPopup() {
  const input = document.getElementById('rent-hours');
  let value = parseInt(input.value);
  if (isNaN(value) || value < 1) value = 1;
  const max = parseInt(input.max) || 24;
  if (value > max) value = max;
  input.value = value;
  updateRentTotal();
}

function updateRentTotal() {
  if (!currentStallConfig) return;
  const hours = parseInt(document.getElementById('rent-hours').value) || 1;
  const total = currentStallConfig.rentPrice * hours;
  document.getElementById('rent-total').textContent = formatMoney(total) + '$';
}

function confirmRentPopup() {
  if (!currentStallConfig || !currentStallData) return;

  const hours = parseInt(document.getElementById('rent-hours').value);
  if (hours <= 0 || hours > (currentStallConfig.maxHours || 24)) {
    showNotification('Số giờ không hợp lệ!', 'error');
    return;
  }

  $.post('https://' + GetParentResourceName() + '/rentStall', JSON.stringify({
    stallId: currentStallConfig.id,
    hours: hours
  }));

  closeRentPopup();
  setTimeout(() => {
    closeAll();
  }, 500);
}

function refreshUI() {
  if (currentStallData && currentStallConfig) {
    $.post('https://' + GetParentResourceName() + '/getStallItems', JSON.stringify({
      stallId: currentStallConfig.id
    }), function (items) {
      currentStallItems = items || [];
      renderSellingItems(items);
      renderItems(items);
      renderInventoryItems(playerInventory);
    }).fail(function () {
      console.error('❌ Failed to get stall items');
    });

    $.post('https://' + GetParentResourceName() + '/getStallData', JSON.stringify({
      stallId: currentStallConfig.id
    }), function (data) {
      if (data) {
        currentStallData = data;
        updateRevenueInfo(data);

        if (data.rent_end) {
          startCountdown(data.rent_end);
        }
      }
    }).fail(function () {
      console.error('❌ Failed to get stall data');
    });
  }
}

function renderItems(items) {
  const grid = document.getElementById('items-grid');
  const emptyState = document.getElementById('empty-state');

  grid.innerHTML = '';

  if (!items || items.length === 0) {
    grid.style.display = 'none';
    emptyState.style.display = 'block';
    return;
  }

  grid.style.display = 'grid';
  emptyState.style.display = 'none';

  for (let i = 0; i < items.length; i++) {
    const itemData = items[i];
    if (itemData.count <= 0) continue;
    const card = createItemCard(i + 1, itemData);
    grid.appendChild(card);
  }
}

function createItemCard(itemIndex, itemData) {
  const card = document.createElement('div');
  card.className = 'item-card';

  if (itemData.count <= 0) {
    card.classList.add('out-of-stock');
  }

  const metadata = itemData.metadata || {};
  const rarityVal = metadata.DoHiem || itemData.rarity || 'Common';
  const rarity = rarityVal; // Định nghĩa để tránh lỗi ReferenceError ở template literal bên dưới
  const rarityClass = getRarityClass(rarityVal);
  const rarityLabel = getRarityLabel(rarityClass);
  card.classList.add('rarity-' + rarityClass);

  let imagePath = metadata.imageurl || `https://raw.githubusercontent.com/xuannguyen995/prime_item/main/${itemData.name}.webp`;
  // SỬ DỤNG LABEL TỪ itemData (đã được server xử lý)
  const displayName = itemData.label || metadata.label || itemData.name;
  const durability = metadata.durability || null;

  let metadataInfo = '';
  if (metadata) {
    const metaKeys = Object.keys(metadata);
    if (metaKeys.length > 0) {
      metadataInfo = '<div class="item-metadata-list" style="font-size:11px;opacity:0.8;margin:4px 0;line-height:1.4;">';
      const importantFields = ['description', 'drawable', 'texture', 'type', 'sex', 'id'];
      importantFields.forEach(key => {
        if (metadata[key]) {
          metadataInfo += `<div class="item-metadata-item" style="font-size:10px;"><span class="meta-key">${key}:</span> <span class="meta-value">${metadata[key]}</span></div>`;
        }
      });
      metaKeys.forEach(key => {
        if (!importantFields.includes(key) && key !== 'label' && key !== 'DoHiem' && key !== 'imageurl' && key !== 'durability') {
          const value = metadata[key];
          if (value !== null && value !== undefined && value !== '') {
            metadataInfo += `<div class="item-metadata-item" style="font-size:10px;"><span class="meta-key">${key}:</span> <span class="meta-value">${value}</span></div>`;
          }
        }
      });
      metadataInfo += '</div>';
    }
  }

  const metadataStr = metadata ? JSON.stringify(metadata).replace(/"/g, '&quot;') : '{}';

  card.innerHTML = `
        <img src="${imagePath}" alt="${itemData.name}" onerror="this.src='https://via.placeholder.com/120'">
        <div class="item-name" title="${displayName}">${displayName}</div>
        <div style="margin-bottom: 8px; display: flex; gap: 5px; justify-content: center;">
            <span class="rarity-badge ${rarityClass}">${rarityLabel}</span>
        </div>
        ${durability ? `<div class="item-durability">🔧 Độ bền: ${durability}%</div>` : ''}
        ${metadataInfo}
        <div class="item-stock">📦 Còn: ${itemData.count}</div>
        <div class="item-price">💰 ${formatMoney(itemData.price)}$/cái</div>
        <button class="buy-btn" ${itemData.count <= 0 ? 'disabled' : ''} data-itemindex="${itemIndex}" data-itemname="${itemData.name}" data-stock="${itemData.count}" data-price="${itemData.price}" data-image="${imagePath}" data-label="${displayName}" data-rarity="${rarity}" data-durability="${durability || 0}" data-metadata='${metadataStr}'>
            ${itemData.count <= 0 ? 'Hết hàng' : 'Mua'}
        </button>
        ${itemData.count <= 0 ? '<div class="out-of-stock-overlay">Hết hàng</div>' : ''}
    `;

  const buyBtn = card.querySelector('.buy-btn');
  if (buyBtn && itemData.count > 0) {
    buyBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      const itemIndex = parseInt(this.dataset.itemindex);
      const itemName = this.dataset.itemname;
      const stock = parseInt(this.dataset.stock);
      const price = parseInt(this.dataset.price);
      const image = this.dataset.image;
      const label = this.dataset.label;
      const rarity = this.dataset.rarity;
      const durability = parseInt(this.dataset.durability);
      const metadata = JSON.parse(this.dataset.metadata);

      openBuyPopup(itemIndex, itemName, stock, price, image, label, rarity, durability, metadata);
    });
  }

  return card;
}

function renderInventoryItems(inventory) {
  const container = document.getElementById('inventory-items');
  container.innerHTML = '';

  // Lọc bỏ các vật phẩm nằm ở slot từ 6 đến 21
  const visibleInventory = (inventory || []).filter(item => !(item.slot >= 6 && item.slot <= 21));

  if (visibleInventory.length === 0) {
    container.innerHTML = '<p style="text-align:center;opacity:0.6;padding:20px;">Túi đồ trống</p>';
    return;
  }

  visibleInventory.forEach(item => {
    const card = document.createElement('div');
    card.className = 'inventory-item-card';

    const rarityVal = item.DoHiem || (item.fullMetadata && item.fullMetadata.DoHiem) || 'Common';
    const rarityClass = getRarityClass(rarityVal);
    const rarityLabel = getRarityLabel(rarityClass);
    card.classList.add('rarity-' + rarityClass);

    const imageUrl = item.imageurl || (item.fullMetadata && item.fullMetadata.imageurl) || `https://raw.githubusercontent.com/xuannguyen995/prime_item/main/${item.name}.webp`;
    // SỬ DỤNG LABEL TỪ item (đã có sẵn từ client)
    const label = item.fullMetadata?.label || item.label || item.name;
    const durability = item.durability || item.fullMetadata?.durability || null;

    let availableCount = item.count;

    let metadataInfo = '';
    if (item.fullMetadata) {
      const metaKeys = Object.keys(item.fullMetadata);
      if (metaKeys.length > 0) {
        metadataInfo = '<div class="inventory-item-metadata" style="font-size:10px;opacity:0.6;margin-top:2px;">';
        const importantFields = ['description', 'drawable', 'texture', 'type', 'sex', 'id'];
        importantFields.forEach(key => {
          if (item.fullMetadata[key] !== undefined && item.fullMetadata[key] !== null && item.fullMetadata[key] !== '') {
            metadataInfo += `<span style="margin-right:5px;">${key}: ${item.fullMetadata[key]}</span>`;
          }
        });
        metaKeys.forEach(key => {
          if (!importantFields.includes(key) &&
            key !== 'label' && key !== 'DoHiem' && key !== 'imageurl' && key !== 'durability' &&
            item.fullMetadata[key] !== undefined && item.fullMetadata[key] !== null && item.fullMetadata[key] !== '') {
            metadataInfo += `<span style="margin-right:5px;">${key}: ${item.fullMetadata[key]}</span>`;
          }
        });
        if (metaKeys.length > 0) {
          metadataInfo += '</div>';
        }
      }
    }

    const metadataStr = item.fullMetadata ? JSON.stringify(item.fullMetadata).replace(/"/g, '&quot;') : '{}';

    card.innerHTML = `
            <img src="${imageUrl}" alt="${item.name}" onerror="this.src='https://via.placeholder.com/80'">
            <div class="inventory-item-info">
                <div class="inventory-item-name">${label}</div>
                <div class="inventory-item-details">
                    <span>📦 Có: ${item.count}</span>
                    ${durability ? `<span>🔧 Độ bền: ${durability}%</span>` : ''}
                    <span class="rarity-badge ${rarityClass}">${rarityLabel}</span>
                    <span style="font-size:10px;opacity:0.6;color:#FFD700;">📌 Slot: ${item.slot}</span>
                </div>
                ${metadataInfo}
            </div>
            <button class="sell-btn" data-itemname="${item.name}" data-maxquantity="${availableCount}" data-image="${imageUrl}" data-label="${label}" data-durability="${durability || 0}" data-rarity="${rarityVal}" data-metadata='${metadataStr}' data-slot="${item.slot}">
                🏪 Đăng bán
            </button>
        `;

    const sellBtn = card.querySelector('.sell-btn');
    if (sellBtn) {
      sellBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        const itemName = this.dataset.itemname;
        const maxQuantity = parseInt(this.dataset.maxquantity);
        const imageUrl = this.dataset.image;
        const label = this.dataset.label;
        const durability = parseInt(this.dataset.durability);
        const rarity = this.dataset.rarity;
        const metadata = JSON.parse(this.dataset.metadata);
        const slot = parseInt(this.dataset.slot);

        openSellPopup(itemName, maxQuantity, imageUrl, label, durability, rarity, metadata, slot);
      });
    }

    container.appendChild(card);
  });
}

function renderSellingItems(items) {
  const container = document.getElementById('selling-items');
  container.innerHTML = '';

  if (!items || items.length === 0) {
    container.innerHTML = '<p style="text-align:center;opacity:0.6;padding:20px;">Chưa có vật phẩm nào đang bán</p>';
    return;
  }

  for (const [index, itemData] of Object.entries(items)) {
    if (itemData.count <= 0) continue;

    const card = document.createElement('div');
    card.className = 'selling-item-card';

    const metadata = itemData.metadata || {};
    const rarityVal = metadata.DoHiem || itemData.rarity || 'Common';
    const rarityClass = getRarityClass(rarityVal);
    const rarityLabel = getRarityLabel(rarityClass);
    card.classList.add('rarity-' + rarityClass);

    let imageUrl = metadata.imageurl || `https://raw.githubusercontent.com/xuannguyen995/prime_item/main/${itemData.name}.webp`;
    // SỬ DỤNG LABEL TỪ itemData (đã được server xử lý)
    const displayName = itemData.label || metadata.label || itemData.name;
    const durability = metadata.durability || null;

    let metadataInfo = '';
    if (metadata) {
      const metaKeys = Object.keys(metadata);
      if (metaKeys.length > 0) {
        metadataInfo = '<div class="selling-item-metadata" style="font-size:11px;opacity:0.8;margin-top:4px;line-height:1.4;">';
        const importantFields = ['description', 'drawable', 'texture', 'type', 'sex', 'id'];
        importantFields.forEach(key => {
          if (metadata[key]) {
            metadataInfo += `<span style="margin-right:8px;display:inline-block;">${key}: ${metadata[key]}</span>`;
          }
        });
        metaKeys.forEach(key => {
          if (!importantFields.includes(key) && key !== 'label' && key !== 'DoHiem' && key !== 'imageurl' && key !== 'durability') {
            const value = metadata[key];
            if (value !== null && value !== undefined && value !== '') {
              metadataInfo += `<span style="margin-right:8px;display:inline-block;">${key}: ${value}</span>`;
            }
          }
        });
        metadataInfo += '</div>';
      }
    }

    const itemIndex = parseInt(index) + 1;

    card.innerHTML = `
            <img src="${imageUrl}" alt="${itemData.name}" onerror="this.src='https://via.placeholder.com/80'">
            <div class="selling-item-info">
                <div class="selling-item-name" title="${displayName}">${displayName}</div>
                <div class="selling-item-details">
                    <span>📦 SL: ${itemData.count}</span>
                    <span>💰 ${formatMoney(itemData.price)}$/cái</span>
                    ${durability ? `<span>🔧 Độ bền: ${durability}%</span>` : ''}
                    <span class="rarity-badge ${rarityClass}">${rarityLabel}</span>
                </div>
                ${metadataInfo}
            </div>
            <button class="remove-btn" data-itemindex="${itemIndex}">
                ❌ Hủy bán
            </button>
        `;

    const removeBtn = card.querySelector('.remove-btn');
    if (removeBtn) {
      removeBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        const itemIndex = parseInt(this.dataset.itemindex);
        confirmRemoveItem(itemIndex);
      });
    }

    container.appendChild(card);
  }
}

function confirmRemoveItem(itemIndex) {
  if (!currentStallData || !currentStallConfig) return;
  if (isProcessing) {
    showNotification('Hệ thống đang bận xử lý giao dịch, vui lòng thử lại sau!', 'warning');
    return;
  }

  showConfirm('Bạn có chắc muốn hủy bán vật phẩm này?', function () {
    isProcessing = true;
    $.post('https://' + GetParentResourceName() + '/removeItem', JSON.stringify({
      stallId: currentStallConfig.id,
      itemIndex: itemIndex
    }), function () {
      setTimeout(() => {
        refreshUI();
        loadPlayerInventory();
        loadStallItems();
        showNotification('Đã hủy bán thành công!', 'success');

        // Delay 1 giây cooldown an toàn trước khi cho phép giao dịch tiếp
        setTimeout(() => {
          isProcessing = false;
        }, 1000);
      }, 200);
    }).fail(function () {
      isProcessing = false;
      showNotification('Hủy bán thất bại!', 'error');
    });
  });
}

function loadPlayerInventory() {
  $.post('https://' + GetParentResourceName() + '/getPlayerInventory', JSON.stringify({}), function (inventory) {
    playerInventory = inventory || [];
    renderInventoryItems(inventory);
  }).fail(function (jqXHR, textStatus, errorThrown) {
    console.error('❌ Error loading inventory:', textStatus, errorThrown);
  });
}

function loadStallItems() {
  if (!currentStallConfig) return;
  $.post('https://' + GetParentResourceName() + '/getStallItems', JSON.stringify({
    stallId: currentStallConfig.id
  }), function (items) {
    currentStallItems = items || [];
    renderSellingItems(items);
  }).fail(function () {
    console.error('❌ Failed to load stall items');
  });
}

function openSellPopup(itemName, maxQuantity, imageUrl, label, durability, rarity, fullMetadata, slot) {
  if (isProcessing) {
    showNotification('Hệ thống đang bận xử lý giao dịch, vui lòng thử lại sau!', 'warning');
    return;
  }

  if (maxQuantity <= 0) {
    showNotification('Không còn vật phẩm để bán!', 'error');
    return;
  }

  const metadata = fullMetadata || {};

  selectedInventoryItem = {
    name: itemName,
    maxQuantity: maxQuantity,
    imageUrl: imageUrl,
    label: label,
    durability: durability,
    rarity: rarity,
    fullMetadata: metadata,
    slot: slot
  };

  document.getElementById('sell-item-image').src = imageUrl;
  document.getElementById('sell-item-name').textContent = label || itemName;
  document.getElementById('sell-item-stock').textContent = maxQuantity;
  document.getElementById('sell-item-durability').textContent = durability ? durability + '%' : 'N/A';
  const rClass = getRarityClass(rarity);
  const rLabel = getRarityLabel(rClass);
  document.getElementById('sell-item-rarity').textContent = rLabel;
  document.getElementById('sell-item-rarity').className = 'rarity-badge ' + rClass;

  let metadataText = '';
  if (metadata) {
    const metaKeys = Object.keys(metadata);
    const importantFields = ['description', 'drawable', 'texture', 'type', 'sex', 'id'];
    importantFields.forEach(key => {
      if (metadata[key] !== undefined && metadata[key] !== null && metadata[key] !== '') {
        metadataText += `${key}: ${metadata[key]} | `;
      }
    });
    metaKeys.forEach(key => {
      if (!importantFields.includes(key) &&
        key !== 'label' && key !== 'DoHiem' && key !== 'imageurl' && key !== 'durability' &&
        metadata[key] !== undefined && metadata[key] !== null && metadata[key] !== '') {
        metadataText += `${key}: ${metadata[key]} | `;
      }
    });
  }
  document.getElementById('sell-item-metadata').textContent = metadataText || 'Không có metadata';

  const slotElement = document.getElementById('sell-item-slot');
  if (slot) {
    slotElement.style.display = 'block';
    slotElement.innerHTML = `📌 Slot: <span style="font-weight:bold;color:#FFD700;">${slot}</span>`;
  } else {
    slotElement.style.display = 'none';
  }

  document.getElementById('sell-quantity').value = 1;
  document.getElementById('sell-quantity').max = maxQuantity;
  document.getElementById('sell-price').value = 100;

  document.getElementById('sell-backdrop').style.display = 'block';
  document.getElementById('sell-popup').style.display = 'block';
}

function closeSellPopup() {
  document.getElementById('sell-backdrop').style.display = 'none';
  document.getElementById('sell-popup').style.display = 'none';
  selectedInventoryItem = null;
}

function changeSellQuantity(delta) {
  const input = document.getElementById('sell-quantity');
  let value = parseInt(input.value) + delta;

  if (isNaN(value)) value = 1;

  const max = parseInt(input.max);
  if (value < 1) value = 1;
  if (value > max) value = max;

  input.value = value;
}

function validateSellQuantity() {
  const input = document.getElementById('sell-quantity');
  let value = parseInt(input.value);

  if (isNaN(value) || value < 1) value = 1;

  const max = parseInt(input.max);
  if (value > max) value = max;

  input.value = value;
}
function confirmSell() {
  if (isProcessing) {
    showNotification('Đang xử lý, vui lòng chờ!', 'warning');
    return;
  }

  if (!selectedInventoryItem || !currentStallData) return;

  const quantity = parseInt(document.getElementById('sell-quantity').value);
  const price = parseInt(document.getElementById('sell-price').value);

  if (quantity <= 0 || quantity > selectedInventoryItem.maxQuantity) {
    showNotification('Số lượng không hợp lệ!', 'error');
    return;
  }

  if (price <= 0 || price > 9999999) {
    showNotification('Giá bán không hợp lệ (tối đa 9.999.999$!)', 'error');
    return;
  }

  // Lấy metadata gốc từ item
  const metadata = selectedInventoryItem.fullMetadata || {};

  // Tạo metadata để gửi lên server - CHỈ GỬI NẾU CÓ DỮ LIỆU
  const metadataToSend = {};

  // Copy toàn bộ metadata gốc (chỉ những field có giá trị)
  for (const [key, value] of Object.entries(metadata)) {
    if (value !== null && value !== undefined && value !== '') {
      metadataToSend[key] = value;
    }
  }

  // KHÔNG TỰ ĐỘNG THÊM LABEL, DoHiem, durability, imageurl
  // Chỉ gửi những gì item thực sự có

  // Kiểm tra xem có metadata không
  const hasMetadata = Object.keys(metadataToSend).length > 0;

  console.log('📦 Metadata to send:', metadataToSend);
  console.log('📦 Has metadata:', hasMetadata);

  isProcessing = true;

  const sellBtn = document.querySelector('.btn-buy');
  if (sellBtn) {
    sellBtn.disabled = true;
    sellBtn.textContent = 'Đang xử lý...';
  }

  // Gửi metadata nếu có, không thì gửi object rỗng
  $.post('https://' + GetParentResourceName() + '/addItem', JSON.stringify({
    stallId: currentStallConfig.id,
    itemName: selectedInventoryItem.name,
    itemLabel: selectedInventoryItem.label,
    quantity: quantity,
    price: price,
    metadata: metadataToSend,
    slot: selectedInventoryItem.slot
  }), function (response) {
    setTimeout(() => {
      loadPlayerInventory();
      loadStallItems();

      $.post('https://' + GetParentResourceName() + '/getStallItems', JSON.stringify({
        stallId: currentStallConfig.id
      }), function (items) {
        currentStallItems = items || [];
        renderSellingItems(items);
        renderItems(items);
        renderInventoryItems(playerInventory);
      });

      showNotification('Mua thành công!', 'success');

      // Cooldown 1 giây trước khi cho phép giao dịch tiếp theo
      setTimeout(() => {
        isProcessing = false;
        if (sellBtn) {
          sellBtn.disabled = false;
          sellBtn.textContent = '✅ Mua ngay';
        }
      }, 1000);
    }, 500);
  }).fail(function (jqXHR, textStatus, errorThrown) {
    console.error('❌ Error selling item:', textStatus, errorThrown);
    showNotification('Có lỗi xảy ra khi mua!', 'error');

    isProcessing = false;

    if (sellBtn) {
      sellBtn.disabled = false;
      sellBtn.textContent = '✅ Mua ngay';
    }
  });

  closeSellPopup();
}

function openBuyPopup(itemIndex, itemName, stock, price, imageUrl, label, rarity, durability, fullMetadata) {
  if (isProcessing) {
    showNotification('Hệ thống đang bận xử lý giao dịch, vui lòng thử lại sau!', 'warning');
    return;
  }

  selectedItem = {
    itemIndex: parseInt(itemIndex),
    name: itemName,
    stock: stock,
    price: price,
    imageUrl: imageUrl || `https://raw.githubusercontent.com/xuannguyen995/prime_item/main/${itemName}.webp`,
    label: label || itemName,
    rarity: rarity || 'Common',
    durability: durability || null,
    fullMetadata: fullMetadata || {}
  };

  document.getElementById('buy-item-image').src = selectedItem.imageUrl;
  document.getElementById('buy-item-name').textContent = selectedItem.label;
  document.getElementById('buy-item-stock').textContent = stock;
  document.getElementById('buy-item-price').textContent = formatMoney(price);
  const rClass = getRarityClass(selectedItem.rarity);
  const rLabel = getRarityLabel(rClass);
  document.getElementById('buy-item-rarity').textContent = rLabel;
  document.getElementById('buy-item-rarity').className = 'rarity-badge ' + rClass;
  document.getElementById('buy-item-durability').textContent = selectedItem.durability ? selectedItem.durability + '%' : 'N/A';

  let metadataText = '';
  if (fullMetadata) {
    const metaKeys = Object.keys(fullMetadata);
    const importantFields = ['description', 'drawable', 'texture', 'type', 'sex', 'id'];
    importantFields.forEach(key => {
      if (fullMetadata[key] !== undefined && fullMetadata[key] !== null && fullMetadata[key] !== '') {
        metadataText += `${key}: ${fullMetadata[key]} | `;
      }
    });
    metaKeys.forEach(key => {
      if (!importantFields.includes(key) &&
        key !== 'label' && key !== 'DoHiem' && key !== 'imageurl' && key !== 'durability' &&
        fullMetadata[key] !== undefined && fullMetadata[key] !== null && fullMetadata[key] !== '') {
        metadataText += `${key}: ${fullMetadata[key]} | `;
      }
    });
  }
  document.getElementById('buy-item-metadata').textContent = metadataText || 'Không có metadata';

  document.getElementById('buy-quantity').value = 1;
  document.getElementById('buy-quantity').max = stock;

  updateBuyTotal();

  document.getElementById('buy-backdrop').style.display = 'block';
  document.getElementById('buy-popup').style.display = 'block';
}

function closeBuyPopup() {
  document.getElementById('buy-backdrop').style.display = 'none';
  document.getElementById('buy-popup').style.display = 'none';
  selectedItem = null;
}

function changeQuantity(delta) {
  const input = document.getElementById('buy-quantity');
  let value = parseInt(input.value) + delta;

  if (isNaN(value)) value = 1;

  const max = parseInt(input.max);
  if (value < 1) value = 1;
  if (value > max) value = max;

  input.value = value;
  updateBuyTotal();
}

function validateQuantity() {
  const input = document.getElementById('buy-quantity');
  let value = parseInt(input.value);

  if (isNaN(value) || value < 1) value = 1;

  const max = parseInt(input.max);
  if (value > max) value = max;

  input.value = value;
  updateBuyTotal();
}

function updateBuyTotal() {
  if (!selectedItem) return;

  const quantity = parseInt(document.getElementById('buy-quantity').value) || 1;
  const subtotal = selectedItem.price * quantity;
  const tax = Math.floor(subtotal * 0.02);
  const total = subtotal + tax;

  document.getElementById('subtotal').textContent = formatMoney(subtotal) + '$';
  document.getElementById('tax').textContent = formatMoney(tax) + '$';
  document.getElementById('total-price').textContent = formatMoney(total) + '$';
}

function confirmBuy() {
  if (!selectedItem || !currentStallData) return;
  if (isProcessing) {
    showNotification('Hệ thống đang bận xử lý giao dịch, vui lòng thử lại sau!', 'warning');
    return;
  }

  const quantity = parseInt(document.getElementById('buy-quantity').value);

  if (quantity <= 0 || quantity > selectedItem.stock) {
    showNotification('Số lượng không hợp lệ!', 'error');
    return;
  }

  isProcessing = true;

  $.post('https://' + GetParentResourceName() + '/buyItem', JSON.stringify({
    stallId: currentStallConfig.id,
    itemIndex: selectedItem.itemIndex,
    itemName: selectedItem.name,
    quantity: quantity
  }), function (response) {
    setTimeout(() => {
      refreshUI();
      showNotification('Mua hàng thành công!', 'success');

      // Delay 1 giây cooldown an toàn trước khi cho phép giao dịch tiếp theo
      setTimeout(() => {
        isProcessing = false;
      }, 1000);
    }, 300);
  }).fail(function (jqXHR, textStatus, errorThrown) {
    console.error('❌ Error buying item:', textStatus, errorThrown);
    showNotification('Có lỗi xảy ra khi mua hàng!', 'error');
    isProcessing = false;
  });

  closeBuyPopup();
}

function withdrawAllMoney() {
  if (!isOwner || !currentStallData) return;

  $.post('https://' + GetParentResourceName() + '/withdrawMoney', JSON.stringify({
    stallId: currentStallConfig.id
  }), function () {
    refreshUI();
  });
}

function loadTransactionHistory() {
  if (!currentStallData) return;

  $.post('https://' + GetParentResourceName() + '/getTransactionHistory', JSON.stringify({
    stallId: currentStallConfig.id
  }), function (transactions) {
    displayTransactionHistory(transactions);
  });
}

function displayTransactionHistory(transactions) {
  const historyList = document.getElementById('history-list');

  if (!transactions || transactions.length === 0) {
    historyList.innerHTML = '<p style="opacity: 0.6; text-align: center;">Chưa có giao dịch nào</p>';
    return;
  }

  historyList.innerHTML = transactions.map(trans => {
    const time = new Date(trans.transaction_time);
    const timeStr = time.getHours().toString().padStart(2, '0') + ':' +
      time.getMinutes().toString().padStart(2, '0');

    const displayName = trans.item_label || trans.item_name;

    return `
            <div class="transaction-item">
                <span>${trans.quantity}x ${displayName} → ${trans.buyer_name}</span>
                <span style="color: #4CAF50;">+${formatMoney(trans.total_price)}$</span>
                <span style="opacity: 0.6; font-size: 12px;">${timeStr}</span>
            </div>
        `;
  }).join('');
}

function updateRevenueInfo(stallData) {
  document.getElementById('total-revenue').textContent = formatMoney(stallData.revenue || 0) + '$';
  document.getElementById('unclaimed-money').textContent = formatMoney(stallData.unclaimed_money || 0) + '$';
  loadTransactionHistory();
}

function switchTab(tabName) {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    if (btn.getAttribute('data-tab') === tabName) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  document.querySelectorAll('.tab-content').forEach(content => {
    if (content.id === 'tab-' + tabName) {
      content.classList.add('active');
    } else {
      content.classList.remove('active');
    }
  });

  if (tabName === 'manage' && isOwner) {
    loadPlayerInventory();
    loadStallItems();
  }

  if (tabName === 'revenue' && currentStallData) {
    updateRevenueInfo(currentStallData);
  }
}

function switchSubTab(subTabName) {
  document.querySelectorAll('.sub-tab-btn').forEach(btn => {
    if (btn.getAttribute('data-subtab') === subTabName) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  document.querySelectorAll('.sub-tab-content').forEach(content => {
    if (content.id === 'subtab-' + subTabName) {
      content.classList.add('active');
    } else {
      content.classList.remove('active');
    }
  });

  if (subTabName === 'sell') {
    loadPlayerInventory();
  } else if (subTabName === 'selling') {
    loadStallItems();
  }
}

function startCountdown(endTime) {
  if (countdownInterval) {
    clearInterval(countdownInterval);
  }

  function update() {
    const now = new Date().getTime();
    let end;
    if (typeof endTime === 'number') {
      end = endTime > 9999999999 ? endTime : endTime * 1000;
    } else {
      end = new Date(endTime).getTime();
    }
    const diff = end - now;

    if (diff <= 0) {
      document.getElementById('countdown-timer').textContent = '00:00:00';
      clearInterval(countdownInterval);
      showNotification('Gian hàng đã hết hạn! Bạn cần thuê lại để tiếp tục bán.', 'error');
      return;
    }

    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((diff % (1000 * 60)) / 1000);

    document.getElementById('countdown-timer').textContent =
      `${hours.toString().padStart(2, '0')}h ${minutes.toString().padStart(2, '0')}m ${seconds.toString().padStart(2, '0')}s`;
  }

  update();
  countdownInterval = setInterval(update, 1000);
}

function formatMoney(amount) {
  return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

function showNotification(message, type = 'success') {
  const container = document.getElementById('notifications-container');
  const notification = document.createElement('div');
  notification.className = `notification ${type}`;
  notification.textContent = message;

  container.appendChild(notification);

  setTimeout(() => {
    notification.style.animation = 'slideOut 0.3s ease-out';
    setTimeout(() => {
      container.removeChild(notification);
    }, 300);
  }, 3000);
}

function closeAll() {
  document.getElementById('main-container').style.display = 'none';
  closeBuyPopup();
  closeRentPopup();
  closeSellPopup();
  closeRenewPopup();
  closeConfirmPopup();

  if (countdownInterval) {
    clearInterval(countdownInterval);
    countdownInterval = null;
  }

  $.post('https://' + GetParentResourceName() + '/closeUI', JSON.stringify({}));

  currentStallData = null;
  currentStallConfig = null;
  selectedItem = null;
  selectedInventoryItem = null;
  isProcessing = false;
  stallState.isRented = false;
  stallState.isOwner = false;
  stallState.stallId = null;
}

function showConfirm(message, onAccept, onCancel) {
  document.getElementById('confirm-message').textContent = message;

  const acceptBtn = document.getElementById('confirm-accept-btn');
  const cancelBtn = document.getElementById('confirm-cancel-btn');

  // Clone và replace để xóa event listener cũ tránh trùng lặp click
  const newAcceptBtn = acceptBtn.cloneNode(true);
  const newCancelBtn = cancelBtn.cloneNode(true);

  acceptBtn.parentNode.replaceChild(newAcceptBtn, acceptBtn);
  cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

  newAcceptBtn.addEventListener('click', () => {
    closeConfirmPopup();
    if (onAccept) onAccept();
  });

  newCancelBtn.addEventListener('click', () => {
    closeConfirmPopup();
    if (onCancel) onCancel();
  });

  document.getElementById('confirm-backdrop').style.display = 'block';
  document.getElementById('confirm-popup').style.display = 'block';
}

function closeConfirmPopup() {
  document.getElementById('confirm-backdrop').style.display = 'none';
  document.getElementById('confirm-popup').style.display = 'none';
}

function GetParentResourceName() {
  return 'fivem-stall';
}