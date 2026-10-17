// State global NUI
let inventoryItems = [];
let appraisalSlots = [null, null, null, null, null]; // 5 ô chứa cố định
let currentMode = 'washing'; // 'appraisal' | 'washing' | 'closed'
let timeRestrictions = {
    enabled: true,
    appraisalLabel: '14:00 - 15:00',
    washingLabel: '20:00 - 23:00'
};
let config = {
    minItems: 2,
    maxItems: 5,
    totalSlots: 5,
    processTime: 5000,
    showRealPayoutPreview: true,
    showPriceTrend: true,
    minPayoutPercent: 0.60,
    maxPayoutPercent: 1.00,
    itemImagePath: 'nui://ox_inventory/web/images/'
};

// Cập nhật giao diện theo Chế độ hiện tại (Giờ Định Giá hoặc Giờ Rửa)
function updateModeUI() {
    const modeBadge = document.getElementById('timeModeBadge');
    const modeIcon = document.getElementById('timeModeIcon');
    const modeLabel = document.getElementById('timeModeLabel');
    const modeValue = document.getElementById('timeModeValue');
    const banner = document.getElementById('instructionBanner');

    if (!modeBadge || !banner) return;

    if (currentMode === 'appraisal') {
        modeBadge.className = 'time-mode-badge mode-appraisal';
        modeIcon.innerHTML = '<i class="fa-solid fa-magnifying-glass-dollar"></i>';
        modeLabel.innerText = 'CHẾ ĐỘ HIỆN TẠI';
        modeValue.innerText = `GIỜ ĐỊNH GIÁ (${timeRestrictions.appraisalLabel || '14:00 - 15:00'})`;

        banner.className = 'instruction-banner banner-appraisal';
        banner.innerHTML = `<i class="fa-solid fa-shield-halved"></i> <b>KHUNG GIỜ ĐỊNH GIÁ (${timeRestrictions.appraisalLabel || '14:00 - 15:00'}):</b> Bạn chỉ có thể đặt vật phẩm để kiểm tra giá trị. Khung giờ Rửa tiền là <b>${timeRestrictions.washingLabel || '20:00 - 23:00'}</b>.`;
    } else {
        modeBadge.className = 'time-mode-badge mode-washing';
        modeIcon.innerHTML = '<i class="fa-solid fa-money-bill-transfer"></i>';
        modeLabel.innerText = 'CHẾ ĐỘ HIỆN TẠI';
        modeValue.innerText = `GIỜ RỬA TIỀN (${timeRestrictions.washingLabel || '20:00 - 23:00'})`;

        banner.className = 'instruction-banner';
        banner.innerHTML = `<i class="fa-solid fa-circle-info"></i> Click chọn vật phẩm từ <b>Tab 1</b> sang <b>Tab 2</b> (Tối thiểu 2 món, tối đa 5 món để thực hiện quy đổi).`;
    }
}


let draggedData = null; // { type: 'inventory' | 'slot', index: number, item: object }
let progressInterval = null;
let isProcessingActive = false;

// Format số tiền (ví dụ: 25000 -> 25,000)
function formatMoney(amount) {
    return (amount || 0).toLocaleString('en-US');
}

// ============================================================
// WEB AUDIO API - TECH UI SOUND EFFECTS (0ms Latency, Native)
// ============================================================
let audioCtx = null;

function getAudioContext() {
    if (!audioCtx) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === 'suspended') {
        audioCtx.resume();
    }
    return audioCtx;
}

// 1. Nút bấm Click sound
function playClickSound() {
    try {
        const ctx = getAudioContext();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(850, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(420, ctx.currentTime + 0.04);

        gain.gain.setValueAtTime(0.12, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.04);

        osc.connect(gain);
        gain.connect(ctx.destination);

        osc.start();
        osc.stop(ctx.currentTime + 0.04);
    } catch(e) {}
}

// 2. Rê chuột Hover sound
function playHoverSound() {
    try {
        const ctx = getAudioContext();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(320, ctx.currentTime);

        gain.gain.setValueAtTime(0.02, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.025);

        osc.connect(gain);
        gain.connect(ctx.destination);

        osc.start();
        osc.stop(ctx.currentTime + 0.025);
    } catch(e) {}
}

// 3. Thả/Đặt món hàng vào Slot (Socket Snap sound)
function playSlotSnapSound() {
    try {
        const ctx = getAudioContext();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();

        osc.type = 'triangle';
        osc.frequency.setValueAtTime(280, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(1100, ctx.currentTime + 0.07);

        gain.gain.setValueAtTime(0.18, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.07);

        osc.connect(gain);
        gain.connect(ctx.destination);

        osc.start();
        osc.stop(ctx.currentTime + 0.07);
    } catch(e) {}
}

// 4. Trả/Gỡ món hàng khỏi Slot (Pop sound)
function playRemoveSound() {
    try {
        const ctx = getAudioContext();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(650, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(220, ctx.currentTime + 0.06);

        gain.gain.setValueAtTime(0.14, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.06);

        osc.connect(gain);
        gain.connect(ctx.destination);

        osc.start();
        osc.stop(ctx.currentTime + 0.06);
    } catch(e) {}
}

// 5. Âm thanh Nhận Tiền Thưởng (Ka-Ching Cash Chime sound)
function playClaimRewardSound() {
    try {
        const ctx = getAudioContext();
        const now = ctx.currentTime;

        // Note 1 (E5)
        const osc1 = ctx.createOscillator();
        const gain1 = ctx.createGain();
        osc1.type = 'triangle';
        osc1.frequency.setValueAtTime(659.25, now);
        gain1.gain.setValueAtTime(0.22, now);
        gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.22);
        osc1.connect(gain1);
        gain1.connect(ctx.destination);
        osc1.start(now);
        osc1.stop(now + 0.22);

        // Note 2 (B5)
        const osc2 = ctx.createOscillator();
        const gain2 = ctx.createGain();
        osc2.type = 'triangle';
        osc2.frequency.setValueAtTime(987.77, now + 0.08);
        gain2.gain.setValueAtTime(0.28, now + 0.08);
        gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
        osc2.connect(gain2);
        gain2.connect(ctx.destination);
        osc2.start(now + 0.08);
        osc2.stop(now + 0.45);
    } catch(e) {}
}

// 6. Hiệu ứng hạt lấp lánh (Sparkle Particles - Disabled)
function createCoinSparkles() {
    return;
}

// Tính toán tỷ giá lên/xuống và phần trăm biến động giữa giá hiện tại và giá trước đó
function getPriceTrendData(price, oldPrice) {
    if (!oldPrice || oldPrice === price) {
        return {
            trend: 'stable',
            diff: 0,
            percent: '0.0',
            text: '0.0%',
            class: 'trend-stable',
            icon: 'fa-solid fa-minus'
        };
    }
    const diff = price - oldPrice;
    const percent = ((diff / oldPrice) * 100).toFixed(1);
    if (diff > 0) {
        return {
            trend: 'up',
            diff: diff,
            percent: percent,
            text: `+${percent}%`,
            class: 'trend-up',
            icon: 'fa-solid fa-arrow-trend-up'
        };
    } else {
        return {
            trend: 'down',
            diff: diff,
            percent: percent,
            text: `${percent}%`,
            class: 'trend-down',
            icon: 'fa-solid fa-arrow-trend-down'
        };
    }
}

// Lấy URL hình ảnh vật phẩm
function getItemImageUrl(itemName) {
    if (!itemName) return '';
    return `${config.itemImagePath}${itemName}.png`;
}

// Khởi tạo các sự kiện DOM
document.addEventListener('DOMContentLoaded', () => {
    setupEventListeners();
});

let marketCountdownInterval = null;
let marketRemainingSeconds = 0;

// Quản lý đếm ngược thời gian đổi giá tiếp theo
function startMarketCountdown(seconds, dynamicEnabled) {
    stopMarketCountdown();

    const timerBadge = document.getElementById('marketTimerBadge');
    if (!timerBadge) return;

    if (!dynamicEnabled || seconds === undefined || seconds === null) {
        timerBadge.classList.add('hidden');
        return;
    }

    timerBadge.classList.remove('hidden');
    marketRemainingSeconds = Math.max(0, parseInt(seconds) || 0);
    updateMarketTimerDisplay(marketRemainingSeconds);

    marketCountdownInterval = setInterval(() => {
        marketRemainingSeconds--;
        if (marketRemainingSeconds <= 0) {
            marketRemainingSeconds = 0;
            updateMarketTimerDisplay(0);
            stopMarketCountdown();
            document.getElementById('marketTimerValue').innerText = 'ĐANG ĐỔI GIÁ...';
        } else {
            updateMarketTimerDisplay(marketRemainingSeconds);
        }
    }, 1000);
}

function stopMarketCountdown() {
    if (marketCountdownInterval) {
        clearInterval(marketCountdownInterval);
        marketCountdownInterval = null;
    }
}

function updateMarketTimerDisplay(totalSeconds) {
    const timerValue = document.getElementById('marketTimerValue');
    if (!timerValue) return;
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    const formattedMins = mins < 10 ? `0${mins}` : `${mins}`;
    const formattedSecs = secs < 10 ? `0${secs}` : `${secs}`;
    timerValue.innerText = `${formattedMins}:${formattedSecs}`;
}

// Lắng nghe Message từ Client Lua
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'openUI') {
        config = { ...config, ...(data.config || {}) };
        currentMode = data.currentMode || 'washing';
        if (data.timeRestrictions) {
            timeRestrictions = { ...timeRestrictions, ...data.timeRestrictions };
        }
        
        // Khởi tạo dữ liệu túi đồ (mỗi món gom nhóm có thêm thuộc tính available)
        inventoryItems = (data.items || []).map(item => ({
            ...item,
            available: item.count
        }));

        // Reset 5 ô chứa
        appraisalSlots = [null, null, null, null, null];
        isProcessingActive = false;

        document.getElementById('processingOverlay').classList.add('hidden');
        document.getElementById('resultOverlay').classList.add('hidden');
        document.getElementById('valuationModal').classList.remove('hidden');
        document.getElementById('app').classList.remove('processing-active');
        document.getElementById('app').classList.remove('hidden');

        // Render UI
        updateModeUI();
        renderInventoryGrid();
        renderAppraisalSlots();
        updateLiveCalculation();
        startMarketCountdown(data.nextUpdateIn, data.dynamicEnabled);
    } else if (data.action === 'updatePrices') {
        // Cập nhật giá mới khi tỷ giá thị trường thay đổi trong lúc UI đang mở
        const newItemsMap = {};
        (data.items || []).forEach(item => { newItemsMap[item.name] = item; });

        inventoryItems = (data.items || []).map(item => {
            const usedInSlots = appraisalSlots.filter(s => s && s.name === item.name).length;
            return {
                ...item,
                available: Math.max(0, item.count - usedInSlots)
            };
        });

        // Cập nhật lại giá cho các món đang nằm trên ô Tab 2
        appraisalSlots.forEach(s => {
            if (s && newItemsMap[s.name]) {
                s.price = newItemsMap[s.name].price;
                s.oldPrice = newItemsMap[s.name].oldPrice;
            }
        });

        renderInventoryGrid();
        renderAppraisalSlots();
        updateLiveCalculation();
        startMarketCountdown(data.nextUpdateIn, data.dynamicEnabled);
    } else if (data.action === 'closeUI') {
        hideUIOnly();
    } else if (data.action === 'resetProcessing') {
        stopProgressTimer();
        document.getElementById('app').classList.remove('processing-active');
        document.getElementById('valuationModal').classList.remove('hidden');
        document.getElementById('processingOverlay').classList.add('hidden');
        isProcessingActive = false;
    }
});




// Render danh sách vật phẩm ở Tab 1 (Túi đồ quy đổi)
function renderInventoryGrid() {
    const container = document.getElementById('inventoryContainer');
    const emptyState = document.getElementById('emptyInventory');
    container.innerHTML = '';

    let totalAvailableTypes = 0;

    inventoryItems.forEach((item, index) => {
        if (item.available > 0) {
            totalAvailableTypes++;
            const card = document.createElement('div');
            card.className = `item-card ${item.available <= 0 ? 'disabled' : ''}`;
            card.setAttribute('draggable', item.available > 0 ? 'true' : 'false');
            card.setAttribute('data-index', index);

            const trend = getPriceTrendData(item.price, item.oldPrice);
            const trendHtml = (config.showPriceTrend !== false) ? `
                <span class="price-trend-badge ${trend.class}">
                    <i class="${trend.icon}"></i> ${trend.text}
                </span>
            ` : '';

            const oldPriceHtml = (item.oldPrice && item.oldPrice !== item.price && config.showPriceTrend !== false) ? `
                <span class="item-old-price">$${formatMoney(item.oldPrice)}</span>
            ` : '';

            card.innerHTML = `
                <span class="item-qty-badge">x${item.available}</span>
                ${trendHtml}
                <img class="item-img" src="${getItemImageUrl(item.name)}" alt="${item.label}" onerror="this.src='https://cdn-icons-png.flaticon.com/512/2916/2916115.png';">
                <div class="item-info">
                    <span class="item-label">${item.label}</span>
                    <div class="item-price-wrapper">
                        <span class="item-price">$${formatMoney(item.price)}</span>
                        ${oldPriceHtml}
                    </div>
                </div>
            `;

            // Click trực tiếp để tự động chuyển 1 món sang ô trống đầu tiên ở Tab 2
            card.addEventListener('click', (e) => {
                autoMoveItemToSlot(index);
            });

            container.appendChild(card);
        }
    });

    document.getElementById('inventoryCountBadge').innerText = `${totalAvailableTypes} Loại item`;

    if (totalAvailableTypes === 0) {
        emptyState.classList.remove('hidden');
    } else {
        emptyState.classList.add('hidden');
    }
}

// Render 5 Ô chứa ở Tab 2 (Định giá)
function renderAppraisalSlots() {
    const slots = document.querySelectorAll('.appraisal-slot');
    let occupiedCount = 0;

    slots.forEach((slotEl) => {
        const slotIdx = parseInt(slotEl.getAttribute('data-slot')) - 1; // 0-indexed
        const slotContent = slotEl.querySelector('.slot-content');
        const slotData = appraisalSlots[slotIdx];

        slotContent.innerHTML = '';
        slotEl.classList.remove('occupied');

        if (slotData) {
            occupiedCount++;
            slotEl.classList.add('occupied');

            const itemCard = document.createElement('div');
            itemCard.className = 'item-cardInSlot';
            itemCard.style.cssText = 'width:100%; height:100%; display:flex; flex-direction:column; align-items:center; justify-content:space-between; cursor:pointer; text-align:center; position:relative; padding:2px 0;';

            const trend = getPriceTrendData(slotData.price, slotData.oldPrice);
            const trendHtml = (config.showPriceTrend !== false) ? `
                <span class="price-trend-badge ${trend.class}" style="position:absolute; top:4px; left:4px; z-index:2;">
                    <i class="${trend.icon}"></i> ${trend.text}
                </span>
            ` : '';

            const oldPriceHtml = (slotData.oldPrice && slotData.oldPrice !== slotData.price && config.showPriceTrend !== false) ? `
                <span style="color:#94a3b8; font-size:10px; font-weight:500; text-decoration:line-through; margin-left:4px;">$${formatMoney(slotData.oldPrice)}</span>
            ` : '';

            itemCard.innerHTML = `
                <span class="item-qty-badge" style="position:absolute; top:4px; right:4px; background:#06b6d4; color:#ffffff; font-size:10px; font-weight:700; padding:1px 5px; border-radius:4px; z-index:2;">x1</span>
                ${trendHtml}
                <img src="${getItemImageUrl(slotData.name)}" style="width:44px; height:44px; object-fit:contain; margin-bottom:2px;" onerror="this.src='https://cdn-icons-png.flaticon.com/512/2916/2916115.png';">
                <div style="width:100%;">
                    <span style="color:#f1f5f9; font-size:11px; font-weight:500; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:100%; display:block;">${slotData.label}</span>
                    <div style="display:flex; align-items:center; justify-content:center; gap:4px; margin-top:1px;">
                        <span style="color:#22d3ee; font-size:12px; font-weight:700;">$${formatMoney(slotData.price)}</span>
                        ${oldPriceHtml}
                    </div>
                </div>
            `;

            // Click trực tiếp vào ô Tab 2 để trả item về Tab 1
            itemCard.addEventListener('click', (e) => {
                e.stopPropagation();
                removeItemFromSlot(slotIdx);
            });

            slotContent.appendChild(itemCard);
        } else {
            slotContent.innerHTML = `<i class="fa-solid fa-plus" style="color: rgba(6, 182, 212, 0.35); font-size: 18px;"></i>`;
        }
    });

    document.getElementById('appraisalCountBadge').innerText = `${occupiedCount} / 5 Ô`;
}




// Thêm 1 item từ Tab 1 vào ô slotIdx ở Tab 2
function addItemToSlot(inventoryIndex, slotIdx) {
    const item = inventoryItems[inventoryIndex];
    if (!item || item.available <= 0) return;

    const existingSlotItem = appraisalSlots[slotIdx];

    if (existingSlotItem) {
        // Ô đã có vật phẩm -> Trả vật phẩm cũ về Tab 1 rồi đặt vật phẩm mới vào
        const oldInvItem = inventoryItems.find(i => i.name === existingSlotItem.name);
        if (oldInvItem) oldInvItem.available += 1;
    }

    // Trừ số lượng available của item ở Tab 1
    item.available -= 1;

    // Đặt 1 món duy nhất vào ô
    appraisalSlots[slotIdx] = {
        name: item.name,
        label: item.label,
        price: item.price,
        oldPrice: item.oldPrice || item.price,
        inventoryIndex: inventoryIndex
    };

    playSlotSnapSound();
    renderInventoryGrid();
    renderAppraisalSlots();
    updateLiveCalculation();
}

// Di chuyển item giữa 2 ô thuộc Tab 2
function swapOrMoveSlot(fromSlotIdx, toSlotIdx) {
    if (fromSlotIdx === toSlotIdx) return;

    const temp = appraisalSlots[toSlotIdx];
    appraisalSlots[toSlotIdx] = appraisalSlots[fromSlotIdx];
    appraisalSlots[fromSlotIdx] = temp;

    playSlotSnapSound();
    renderAppraisalSlots();
    updateLiveCalculation();
}

// Trả item từ ô slotIdx ở Tab 2 về Tab 1
function removeItemFromSlot(slotIdx) {
    const slotItem = appraisalSlots[slotIdx];
    if (!slotItem) return;

    const invItem = inventoryItems.find(i => i.name === slotItem.name);
    if (invItem) {
        invItem.available += 1;
    }

    appraisalSlots[slotIdx] = null;

    playRemoveSound();
    renderInventoryGrid();
    renderAppraisalSlots();
    updateLiveCalculation();
}

// Auto move khi double-click item ở Tab 1
function autoMoveItemToSlot(inventoryIndex) {
    const emptySlotIdx = appraisalSlots.findIndex(s => s === null);
    if (emptySlotIdx !== -1) {
        addItemToSlot(inventoryIndex, emptySlotIdx);
    }
}

// Cập nhật tính toán trực tiếp giá trị (Live Calculation)
function updateLiveCalculation() {
    let totalBase = 0;
    let totalOldBase = 0;
    let occupiedCount = 0;

    appraisalSlots.forEach(s => {
        if (s) {
            occupiedCount++;
            totalBase += s.price;
            totalOldBase += (s.oldPrice || s.price);
        }
    });

    const minPayout = Math.floor(totalBase * config.minPayoutPercent);
    const maxPayout = Math.floor(totalBase * config.maxPayoutPercent);
    const avgRealPayout = Math.floor((minPayout + maxPayout) / 2);

    // Hiển thị Tổng giá trị hiện tại
    document.getElementById('calcPriceRange').innerText = `~ $${formatMoney(totalBase)}`;

    // Hiển thị biến động tỷ giá tổng thể
    const priceTrendRow = document.getElementById('priceTrendRow');
    const calcPriceTrend = document.getElementById('calcPriceTrend');

    if (config.showPriceTrend !== false) {
        priceTrendRow.style.display = 'flex';
        if (totalOldBase > 0 && occupiedCount > 0) {
            const diff = totalBase - totalOldBase;
            const pct = ((diff / totalOldBase) * 100).toFixed(1);
            if (diff > 0) {
                calcPriceTrend.className = 'calc-val green-text';
                calcPriceTrend.innerHTML = `<i class="fa-solid fa-arrow-trend-up"></i> Tăng +${pct}% (+$${formatMoney(diff)})`;
            } else if (diff < 0) {
                calcPriceTrend.className = 'calc-val red-text';
                calcPriceTrend.innerHTML = `<i class="fa-solid fa-arrow-trend-down"></i> Giảm ${pct}% (-$${formatMoney(Math.abs(diff))})`;
            } else {
                calcPriceTrend.className = 'calc-val trend-stable-text';
                calcPriceTrend.innerHTML = `<i class="fa-solid fa-minus"></i> Không đổi 0.0% ($0)`;
            }
        } else {
            calcPriceTrend.className = 'calc-val trend-stable-text';
            calcPriceTrend.innerHTML = `0.0% ($0)`;
        }
    } else {
        priceTrendRow.style.display = 'none';
    }

    // Hiển thị / Ẩn dòng Thực Nhận
    const realPayoutRow = document.getElementById('realPayoutRow');
    if (config.showRealPayoutPreview) {
        realPayoutRow.style.display = 'flex';
        document.getElementById('calcRealPayout').innerText = `~ $${formatMoney(avgRealPayout)}`;
    } else {
        realPayoutRow.style.display = 'none';
    }

    // Điều kiện bật Nút XÁC NHẬN: Tối thiểu 2 món, tối đa 5 món
    const btnConfirm = document.getElementById('btnConfirm');
    if (currentMode === 'appraisal') {
        btnConfirm.disabled = true;
        btnConfirm.classList.add('btn-locked-mode');
        btnConfirm.innerHTML = `<i class="fa-solid fa-lock"></i> CHỈ ĐƯỢC RỬA TỪ ${timeRestrictions.washingLabel || '20:00 - 23:00'}`;
    } else {
        btnConfirm.classList.remove('btn-locked-mode');
        btnConfirm.innerHTML = `<i class="fa-solid fa-check-double"></i> XÁC NHẬN QUY ĐỔI`;
        if (occupiedCount >= config.minItems && occupiedCount <= config.maxItems) {
            btnConfirm.disabled = false;
        } else {
            btnConfirm.disabled = true;
        }
    }
}

// Thiết lập listener nút bấm
function setupEventListeners() {
    // Bấm nút Đóng (X)
    document.getElementById('btnCloseModal').addEventListener('click', () => {
        playClickSound();
        if (isProcessingActive) {
            cancelProcess();
        } else {
            closeAppUI();
        }
    });

    // Bấm nút HỦY BỎ
    document.getElementById('btnCancel').addEventListener('click', () => {
        playClickSound();
        if (isProcessingActive) {
            cancelProcess();
        } else {
            closeAppUI();
        }
    });

    // Bấm nút XÁC NHẬN quy đổi
    document.getElementById('btnConfirm').addEventListener('click', () => {
        playClickSound();
        startExchangeProcess();
    });

    // Bấm nút HỦY QUÁ TRÌNH trên màn hình chờ
    document.getElementById('btnCancelProcess').addEventListener('click', () => {
        playClickSound();
        cancelProcess();
    });

    // Bấm nút XÁC NHẬN NHẬN TIỀN trên UI Kết quả
    const btnClaim = document.getElementById('btnClaimReward');
    if (btnClaim) {
        btnClaim.addEventListener('click', () => {
            playClaimRewardSound();
            createCoinSparkles();
            claimReward();
        });
        btnClaim.addEventListener('mouseenter', playHoverSound);
    }

    // Thêm hover sound cho tất cả nút bấm
    document.querySelectorAll('.btn, .btn-close-modal, .btn-cancel-process').forEach(b => {
        b.addEventListener('mouseenter', playHoverSound);
    });

    // Phím tắt bàn phím (Escape hoặc X để Hủy / Đóng / Nhận tiền)
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' || e.key === 'x' || e.key === 'X') {
            if (!document.getElementById('app').classList.contains('hidden')) {
                if (!document.getElementById('resultOverlay').classList.contains('hidden')) {
                    playClaimRewardSound();
                    claimReward();
                } else if (isProcessingActive) {
                    playClickSound();
                    cancelProcess();
                } else {
                    playClickSound();
                    closeAppUI();
                }
            }
        }
    });
}

// Bắt đầu quá trình load chờ định giá (Freeze ped, khóa ox_inventory, xoay chuột)
function startExchangeProcess() {
    if (currentMode !== 'washing') {
        playRemoveSound();
        return;
    }

    const occupiedItems = appraisalSlots.filter(s => s !== null);
    if (occupiedItems.length < config.minItems || occupiedItems.length > config.maxItems) return;

    isProcessingActive = true;
    playClickSound();

    // Gửi tín hiệu về client lua để khóa di chuyển ped, chạy animation và chặn ox_inventory
    fetch(`https://${GetParentResourceName()}/startProcess`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });

    // Ẩn bảng định giá chính để nhân vật hiển thị rõ nét
    document.getElementById('valuationModal').classList.add('hidden');

    // Màn hình trong suốt hoàn toàn khi chạy progressbar (không mờ tối)
    document.getElementById('app').classList.add('processing-active');

    // Hiển thị Progressbar nổi ở dưới giữa màn hình
    const overlay = document.getElementById('processingOverlay');
    const fill = document.getElementById('progressBarFill');
    const percentText = document.getElementById('progressPercent');

    fill.style.width = '0%';
    percentText.innerText = '0%';
    overlay.classList.remove('hidden');
    document.getElementById('resultOverlay').classList.add('hidden');

    const startTime = Date.now();
    const duration = config.processTime;

    stopProgressTimer();

    progressInterval = setInterval(() => {
        const elapsed = Date.now() - startTime;
        let pct = Math.min(100, Math.floor((elapsed / duration) * 100));

        fill.style.width = `${pct}%`;
        percentText.innerText = `${pct}%`;

        if (pct >= 100) {
            stopProgressTimer();
            completeExchange();
        }
    }, 50);
}

// Dừng timer progress
function stopProgressTimer() {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }
}

// Hoàn tất quá trình load chờ -> Gọi server chuẩn bị đơn nhận thưởng và mở UI Kết Quả
function completeExchange() {
    if (!isProcessingActive) return;
    const slotItems = appraisalSlots.filter(s => s !== null);

    fetch(`https://${GetParentResourceName()}/completeExchange`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ slotItems: slotItems })
    }).then(res => res.json()).then(data => {
        if (data && data.success) {
            showResultModal(data.amount, data.slotItems);
        } else {
            cancelProcess();
        }
    }).catch(() => {
        cancelProcess();
    });
}

// Hiển thị Popup UI thông báo kết quả định giá & số tiền thực nhận
function showResultModal(amount, items) {
    document.getElementById('processingOverlay').classList.add('hidden');
    document.getElementById('app').classList.remove('processing-active');
    document.getElementById('resultOverlay').classList.remove('hidden');

    playSlotSnapSound();
    createCoinSparkles();

    document.getElementById('resultPayoutAmount').innerText = `+$${formatMoney(amount)}`;

    const resultList = document.getElementById('resultItemsList');
    resultList.innerHTML = '';
    (items || []).forEach(item => {
        const chip = document.createElement('div');
        chip.className = 'result-item-chip';
        chip.innerHTML = `
            <img src="${getItemImageUrl(item.name)}" alt="${item.label}" onerror="this.src='https://cdn-icons-png.flaticon.com/512/2916/2916115.png';">
            <span class="chip-name">${item.label || item.name}</span>
            <span class="chip-price">$${formatMoney(item.price)}</span>
        `;
        resultList.appendChild(chip);
    });
}

// Nhấn nút XÁC NHẬN NHẬN TIỀN trên UI Kết Quả -> Trừ item và cộng tiền vào túi đồ
function claimReward() {
    fetch(`https://${GetParentResourceName()}/claimReward`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    hideUIOnly();
}

// Hủy quá trình đang xử lý
function cancelProcess() {
    stopProgressTimer();
    document.getElementById('app').classList.remove('processing-active');
    document.getElementById('processingOverlay').classList.add('hidden');
    document.getElementById('resultOverlay').classList.add('hidden');
    document.getElementById('valuationModal').classList.remove('hidden');
    isProcessingActive = false;

    fetch(`https://${GetParentResourceName()}/cancelProcess`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function hideUIOnly() {
    stopProgressTimer();
    stopMarketCountdown();
    document.getElementById('app').classList.remove('processing-active');
    document.getElementById('valuationModal').classList.add('hidden');
    document.getElementById('processingOverlay').classList.add('hidden');
    document.getElementById('resultOverlay').classList.add('hidden');
    document.getElementById('app').classList.add('hidden');
    isProcessingActive = false;
}

// Đóng NUI UI
function closeAppUI() {
    hideUIOnly();

    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

