// State Variables
let currentData = null;
let selectedAddedAmount = 100000; // Default first step

const app = document.getElementById('app');
const betModal = document.getElementById('bet-modal');
const winnerModal = document.getElementById('winner-modal');

// Bet Modal Elements
const auctionTitle = document.getElementById('auction-title');
const timerBadge = document.getElementById('timer-badge');
const timerText = document.getElementById('timer-text');
const currentPriceDisplay = document.getElementById('current-price-display');
const startingPriceNote = document.getElementById('starting-price-note');
const bidderName = document.getElementById('bidder-name');
const bidderTag = document.getElementById('bidder-tag');
const bidderIcon = document.getElementById('bidder-icon');
const cooldownBanner = document.getElementById('cooldown-banner');
const cooldownMsg = document.getElementById('cooldown-msg');
const betStepsGrid = document.getElementById('bet-steps-grid');
const calcCurrent = document.getElementById('calc-current');
const calcAdded = document.getElementById('calc-added');
const calcTotalDisplay = document.getElementById('calc-total-display');
const btnPlaceBid = document.getElementById('btn-place-bid');
const btnCloseBet = document.getElementById('btn-close-bet');

// Winner Modal Elements
const winnerAuctionTitle = document.getElementById('winner-auction-title');
const winnerFullname = document.getElementById('winner-fullname');
const winnerSubid = document.getElementById('winner-subid');
const winnerPriceDisplay = document.getElementById('winner-price-display');
const leaderboardBody = document.getElementById('leaderboard-body');
const btnCloseWinner = document.getElementById('btn-close-winner');

// Helper: Format Money (1000000 -> 1.000.000 or 1,000,000)
function formatMoney(amount) {
    return (amount || 0).toLocaleString('vi-VN');
}

// Helper: Format Short Price (100.000$ -> 100K$, 1.000.000$ -> 1M$)
function formatShort(amount) {
    if (amount >= 1000000) {
        return (amount / 1000000) + 'M';
    }
    if (amount >= 1000) {
        return (amount / 1000) + 'K';
    }
    return amount.toString();
}

// Render Bet Steps Buttons
function renderBetSteps(steps) {
    betStepsGrid.innerHTML = '';
    const defaultSteps = steps && steps.length > 0 ? steps : [
        100000, 200000, 300000, 400000, 500000,
        600000, 700000, 800000, 900000, 1000000
    ];

    defaultSteps.forEach((step, index) => {
        const btn = document.createElement('button');
        btn.className = `btn-step ${step === selectedAddedAmount ? 'active' : ''}`;
        btn.innerHTML = `
            <span class="step-plus">+${formatShort(step)}</span>
            <span class="step-val">${formatMoney(step)}$</span>
        `;

        btn.addEventListener('click', () => {
            document.querySelectorAll('.btn-step').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            selectedAddedAmount = step;
            updateCalculations();
        });

        betStepsGrid.appendChild(btn);
    });
}

// Update Calculations Summary
function updateCalculations() {
    if (!currentData) return;

    const currentPrice = currentData.currentPrice || currentData.startingPrice || 0;
    const added = selectedAddedAmount || 0;
    const total = currentPrice + added;

    calcCurrent.textContent = '$' + formatMoney(currentPrice);
    calcAdded.textContent = '$' + formatMoney(added);
    calcTotalDisplay.textContent = formatMoney(total);
}

// Update Bet UI with Data
function populateBetUI(data) {
    currentData = data;

    auctionTitle.textContent = data.title || 'Gói Đấu Giá Đặc Biệt';
    const currentPrice = data.currentPrice || data.startingPrice || 0;
    currentPriceDisplay.textContent = formatMoney(currentPrice);
    startingPriceNote.textContent = `Giá khởi điểm: $${formatMoney(data.startingPrice || 0)}`;

    // Update Bidder
    if (data.highestBidder) {
        bidderName.textContent = data.highestBidder.name || 'Người Chơi';
        bidderTag.textContent = `ID: ${data.highestBidder.id || data.highestBidder.source} • Mức cược: $${formatMoney(data.highestBidder.bidAmount)}`;
        bidderIcon.className = 'fa-solid fa-crown';
    } else {
        bidderName.textContent = 'Khởi Điểm (Chưa có ai)';
        bidderTag.textContent = 'Hệ Thống Đấu Giá';
        bidderIcon.className = 'fa-solid fa-flag';
    }

    renderBetSteps(data.betSteps);
    updateCalculations();
    checkCooldownState(data.countdown, data.highestBidder);
}

// Check Cooldown Lock State (3s cooldown rule & Self-bid lock)
function checkCooldownState(countdown, highestBidder) {
    if (!highestBidder || countdown <= 0) {
        timerText.textContent = "Chờ đặt thầu";
        timerBadge.classList.add('timer-waiting');
        cooldownBanner.classList.add('hidden');
        btnPlaceBid.disabled = false;
        btnPlaceBid.style.cursor = 'pointer';
        btnPlaceBid.innerHTML = `<div class="btn-glow-effect"></div><i class="fa-solid fa-bolt-lightning"></i><span>ĐẶT THẦU NGAY</span>`;
        return;
    }

    timerBadge.classList.remove('timer-waiting');
    timerText.textContent = `${countdown}s`;

    // Kiểm tra nếu chính người chơi này đang là người giữ giá cao nhất
    const myServerId = currentData && currentData.myServerId;
    const isLeading = highestBidder && myServerId && (highestBidder.id == myServerId || highestBidder.source == myServerId);

    if (isLeading) {
        cooldownBanner.classList.remove('hidden');
        cooldownMsg.textContent = `👑 Bạn đang giữ mức giá cao nhất! Vui lòng chờ người khác nâng giá...`;
        btnPlaceBid.disabled = true;
        btnPlaceBid.style.cursor = 'not-allowed';
        btnPlaceBid.innerHTML = `<div class="btn-glow-effect"></div><i class="fa-solid fa-crown"></i><span>BẠN ĐANG DẪN ĐẦU</span>`;
        return;
    } else {
        btnPlaceBid.innerHTML = `<div class="btn-glow-effect"></div><i class="fa-solid fa-bolt-lightning"></i><span>ĐẶT THẦU NGAY</span>`;
    }

    // Rule: Khi có người gọi cược đang đếm ngược (Config.CountdownSeconds), người tiếp theo chỉ được cược từ giây (CountdownSeconds - 3s) trở đi
    const bidLockSeconds = (currentData && currentData.bidLockSeconds) || 3;
    const maxCountdown = (currentData && currentData.countdownSeconds) || 10;
    const lockThreshold = maxCountdown - bidLockSeconds;

    if (countdown > lockThreshold) {
        const remainingLock = countdown - lockThreshold;
        cooldownBanner.classList.remove('hidden');
        cooldownMsg.textContent = `Vui lòng chờ sau ${bidLockSeconds} giây để đặt lượt tiếp theo (còn lại: ${remainingLock}s)...`;
        btnPlaceBid.disabled = true;
        btnPlaceBid.style.cursor = 'not-allowed';
    } else {
        cooldownBanner.classList.add('hidden');
        btnPlaceBid.disabled = false;
        btnPlaceBid.style.cursor = 'pointer';
    }
}

// Populate Winner & Leaderboard UI
function populateWinnerUI(resultData) {
    betModal.classList.add('hidden');
    winnerModal.classList.remove('hidden');

    winnerAuctionTitle.textContent = resultData.title || 'Phiên Đấu Giá';

    if (resultData.winner) {
        winnerFullname.textContent = resultData.winner.name || 'Vô Danh';
        winnerSubid.textContent = `ID: ${resultData.winner.id || resultData.winner.source} • CitizenID: ${resultData.winner.citizenid || 'N/A'}`;
        winnerPriceDisplay.textContent = formatMoney(resultData.winner.bidAmount || resultData.finalPrice || 0);
    } else {
        winnerFullname.textContent = 'Không có người chiến thắng';
        winnerSubid.textContent = 'Phiên đấu giá kết thúc không có lượt cược';
        winnerPriceDisplay.textContent = '0';
    }

    // Render Leaderboard
    leaderboardBody.innerHTML = '';
    const board = resultData.leaderboard || [];

    if (board.length === 0) {
        const tr = document.createElement('tr');
        tr.innerHTML = `<td colspan="4" style="text-align: center; color: #64748b; padding: 16px;">Chưa có lịch sử đặt cược trong phiên này.</td>`;
        leaderboardBody.appendChild(tr);
    } else {
        board.forEach((item, index) => {
            const tr = document.createElement('tr');
            const rank = index + 1;
            const rankClass = rank === 1 ? 'rank-1' : rank === 2 ? 'rank-2' : rank === 3 ? 'rank-3' : '';

            tr.innerHTML = `
                <td><span class="rank-badge ${rankClass}">#${rank}</span></td>
                <td><strong>${item.name}</strong> <span style="color: #64748b; font-size: 11px;">(ID: ${item.id})</span></td>
                <td style="color: #fbbf24; font-weight: 700;">$${formatMoney(item.finalBid)}</td>
                <td><span style="color: ${rank === 1 ? '#22c55e' : '#94a3b8'}; font-size: 11px;">${rank === 1 ? '👑 Thắng Cuộc' : 'Đã Tham Gia'}</span></td>
            `;
            leaderboardBody.appendChild(tr);
        });
    }
}

// Close Handler
function closeUI() {
    app.classList.add('hidden');
    betModal.classList.add('hidden');
    winnerModal.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Place Bid Handler
function placeBid() {
    if (btnPlaceBid.disabled) return;

    const currentPrice = (currentData && currentData.currentPrice) || 0;
    
    // Quick visual click effect
    btnPlaceBid.classList.add('btn-clicked');
    setTimeout(() => btnPlaceBid.classList.remove('btn-clicked'), 300);

    fetch(`https://${GetParentResourceName()}/placeBid`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            addedAmount: selectedAddedAmount,
            expectedPrice: currentPrice
        })
    });
}

// Event Listeners
btnPlaceBid.addEventListener('click', placeBid);
btnCloseBet.addEventListener('click', closeUI);
btnCloseWinner.addEventListener('click', closeUI);

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeUI();
    }
});

// 3D Overhead Elements
const overheadHud = document.getElementById('overhead-hud');
const overheadTimerVal = document.getElementById('overhead-timer-val');
const overheadTimerBadge = document.getElementById('overhead-timer-badge');
const overheadPlayerName = document.getElementById('overhead-player-name');
const overheadPriceVal = document.getElementById('overhead-price-val');
const overheadProgressFill = document.getElementById('overhead-progress-fill');

function updateOverheadHUD(data) {
    if (!data || !data.visible) {
        overheadHud.classList.add('hidden');
        return;
    }

    overheadHud.classList.remove('hidden');
    overheadHud.style.left = `${data.x}%`;
    overheadHud.style.top = `${data.y}%`;
    overheadHud.style.setProperty('--overhead-scale', data.scale || 1);

    if (data.name) {
        overheadPlayerName.textContent = data.serverId ? `${data.name} (ID: ${data.serverId})` : data.name;
    }
    if (data.price) {
        overheadPriceVal.textContent = data.price;
    }
    if (data.countdown !== undefined) {
        overheadTimerVal.textContent = `${data.countdown}s`;
        if (data.countdown <= 3) {
            overheadTimerBadge.classList.add('urgent');
        } else {
            overheadTimerBadge.classList.remove('urgent');
        }
    }
    if (data.ratio !== undefined) {
        const percentage = Math.max(0, Math.min(100, data.ratio * 100));
        overheadProgressFill.style.width = `${percentage}%`;
        if (percentage < 30) {
            overheadProgressFill.style.background = 'linear-gradient(135deg, #ef4444, #dc2626)';
        } else if (percentage < 60) {
            overheadProgressFill.style.background = 'linear-gradient(135deg, #f59e0b, #d97706)';
        } else {
            overheadProgressFill.style.background = 'var(--gold-gradient)';
        }
    }
}

// NUI Message Listener
window.addEventListener('message', (event) => {
    const item = event.data;

    if (item.action === 'open') {
        app.classList.remove('hidden');

        if (item.data.state === 'ENDED') {
            populateWinnerUI({
                winner: item.data.highestBidder,
                leaderboard: item.data.leaderboard,
                finalPrice: item.data.currentPrice,
                title: item.data.title
            });
        } else {
            winnerModal.classList.add('hidden');
            betModal.classList.remove('hidden');
            populateBetUI(item.data);
        }
    } else if (item.action === 'updateState') {
        populateBetUI(item.data);
    } else if (item.action === 'updateCountdown') {
        if (currentData) {
            currentData.countdown = item.countdown;
            checkCooldownState(item.countdown, currentData.highestBidder);
        }
    } else if (item.action === 'updateOverhead') {
        updateOverheadHUD(item);
    } else if (item.action === 'auctionEnded') {
        overheadHud.classList.add('hidden');
        populateWinnerUI(item.data);
    } else if (item.action === 'close') {
        app.classList.add('hidden');
        betModal.classList.add('hidden');
        winnerModal.classList.add('hidden');
    }
});
