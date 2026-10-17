let currentProgress = 0;
let isDuelActive = false;
let userRole = 'tyer';
let timerInterval = null;
let remainingTimeMs = 10000;

const duelContainer = document.getElementById('duel-container');
const roleBadge = document.getElementById('role-badge');
const roleTitle = document.getElementById('role-title');
const roleDesc = document.getElementById('role-desc');
const yellowNoticeText = document.getElementById('yellow-notice-text');
const redFill = document.getElementById('red-fill');
const blueFill = document.getElementById('blue-fill');
const sliderHandle = document.getElementById('slider-handle');
const handlePercentage = document.getElementById('handle-percentage');
const timerText = document.getElementById('timer-text');
const keyCap = document.getElementById('key-cap');
const resultOverlay = document.getElementById('result-overlay');
const resultTitle = document.getElementById('result-title');
const resultDesc = document.getElementById('result-desc');

// Lắng nghe sự kiện từ FiveM Client Lua
window.addEventListener('message', function(event) {
    const item = event.data;
    if (!item) return;

    switch (item.action) {
        case 'startDuel':
            startDuelUI(item.role, item.progress !== undefined ? item.progress : 0, item.duration || 10000);
            break;
        case 'updateProgress':
            updateProgressBar(item.progress);
            break;
        case 'finishDuel':
            showResultUI(item.result, item.message);
            break;
        case 'playSlapSound':
            playSlapSound();
            break;
        case 'close':
            closeDuelUI();
            break;
    }
});

// Phát âm thanh tát (Slap Sound Effect) bằng Web Audio API
function playSlapSound() {
    try {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        
        // 1. Tiếng va chạm da thịt (Palm Noise Impact)
        const bufferSize = audioCtx.sampleRate * 0.12;
        const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
            data[i] = Math.random() * 2 - 1;
        }

        const noise = audioCtx.createBufferSource();
        noise.buffer = buffer;

        const filter = audioCtx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(1500, audioCtx.currentTime);
        filter.Q.setValueAtTime(1.0, audioCtx.currentTime);

        const gain = audioCtx.createGain();
        gain.gain.setValueAtTime(1.0, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.12);

        // 2. Tiếng bốp trầm (Impact Thump)
        const osc = audioCtx.createOscillator();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(200, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(40, audioCtx.currentTime + 0.08);

        const oscGain = audioCtx.createGain();
        oscGain.gain.setValueAtTime(0.7, audioCtx.currentTime);
        oscGain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.08);

        noise.connect(filter);
        filter.connect(gain);
        gain.connect(audioCtx.destination);

        osc.connect(oscGain);
        oscGain.connect(audioCtx.destination);

        noise.start();
        osc.start();
        noise.stop(audioCtx.currentTime + 0.12);
        osc.stop(audioCtx.currentTime + 0.08);
    } catch (e) {
        console.log('Slap sound error:', e);
    }
}

// Khởi chạy giao diện Duel Minigame
function startDuelUI(role, initialProgress, durationMs) {
    userRole = role;
    currentProgress = initialProgress;
    remainingTimeMs = durationMs;
    isDuelActive = true;

    // Reset giao diện
    resultOverlay.classList.add('hidden');
    duelContainer.classList.remove('hidden');

    // Thiết lập Vai Trò và Thông Báo Mốc 60%
    if (role === 'tyer') {
        roleBadge.className = 'role-badge tyer-theme';
        roleTitle.innerText = 'BẠN LÀ NGƯỜI TRÓI (ĐỘI ĐỎ)';
        roleDesc.innerText = 'Dập phím [E] thật nhanh để đẩy vạch từ 0% lên qua 60% khi hết 10s!';
        if (yellowNoticeText) {
            yellowNoticeText.innerHTML = 'Nạn nhân giữ vạch <strong class="highlight-yellow">DƯỚI 60%</strong> khi hết 10s sẽ <strong class="highlight-yellow">KHÔNG BỊ TRÓI</strong>!';
        }
    } else {
        roleBadge.className = 'role-badge target-theme';
        roleTitle.innerText = 'BẠN LÀ NẠN NHÂN (ĐỘI XANH)';
        roleDesc.innerText = 'Dập phím [E] thật nhanh để kéo vạch giữ dưới 60% khi hết 10s!';
        if (yellowNoticeText) {
            yellowNoticeText.innerHTML = 'Bạn chỉ cần giữ vạch <strong class="highlight-yellow">DƯỚI 60%</strong> khi hết 10s sẽ <strong class="highlight-yellow">KHÔNG BỊ TRÓI</strong>!';
        }
    }

    updateProgressBar(currentProgress);

    // Chạy đếm ngược thời gian
    if (timerInterval) clearInterval(timerInterval);
    const startTime = Date.now();
    const endTime = startTime + durationMs;

    timerInterval = setInterval(() => {
        const now = Date.now();
        const left = Math.max(0, endTime - now);
        remainingTimeMs = left;
        timerText.innerText = (left / 1000).toFixed(1) + 's';

        if (left <= 0) {
            clearInterval(timerInterval);
        }
    }, 100);
}

// Cập nhật mốc % động của 2 thanh tiến trình và ranh giới
function updateProgressBar(progress) {
    currentProgress = Math.max(0, Math.min(100, progress));
    
    // Thanh đỏ chiếm % từ trái sang
    redFill.style.width = currentProgress + '%';
    // Thanh xanh chiếm phần còn lại
    blueFill.style.width = (100 - currentProgress) + '%';
    
    // Con trỏ di chuyển theo %
    sliderHandle.style.left = currentProgress + '%';
    handlePercentage.innerText = Math.round(currentProgress) + '%';
}

// Lắng nghe thao tác spam phím E
window.addEventListener('keydown', function(event) {
    if (!isDuelActive) return;

    // Chỉ bắt phím E hoặc e
    if (event.key.toLowerCase() === 'e') {
        if (event.repeat) return; // Tránh giữ đè phím (bắt buộc phải spam nhấp thả)

        // Hiệu ứng phím E nẩy nẩy
        keyCap.classList.add('pressed');
        setTimeout(() => {
            keyCap.classList.remove('pressed');
        }, 80);

        // Gửi NUI callback về Client FiveM
        fetch(`https://${GetParentResourceName()}/pressE`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                role: userRole
            })
        }).catch(err => console.log('Fetch error:', err));
    }
});

// Hiển thị màn hình kết quả Thắng / Thua
function showResultUI(result, message) {
    isDuelActive = false;
    if (timerInterval) clearInterval(timerInterval);

    resultOverlay.classList.remove('hidden');
    if (result === 'win') {
        resultTitle.className = 'win-title';
        resultTitle.innerText = 'CHIẾN THẮNG!';
    } else {
        resultTitle.className = 'lose-title';
        resultTitle.innerText = 'THẤT BẠI!';
    }
    resultDesc.innerText = message || '';

    setTimeout(() => {
        closeDuelUI();
    }, 2000);
}

// Đóng toàn bộ NUI
function closeDuelUI() {
    isDuelActive = false;
    if (timerInterval) clearInterval(timerInterval);
    duelContainer.classList.add('hidden');
    resultOverlay.classList.add('hidden');

    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).catch(err => console.log('Fetch error:', err));
}
