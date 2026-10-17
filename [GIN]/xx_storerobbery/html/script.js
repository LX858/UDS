let currentRole = null;

function getResourceName() {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }
    if (window.GetParentResourceName && typeof window.GetParentResourceName === 'function') {
        return window.GetParentResourceName();
    }
    return 'xx_storerobbery';
}

document.addEventListener('DOMContentLoaded', () => {
    const pcPinInputs = document.querySelectorAll('#pin-inputs .pin-box');
    const safePinInputs = document.querySelectorAll('#safe-pin-inputs .safe-pin-box');
    const btnSubmit = document.getElementById('btn-submit');
    const btnUnlockSafe = document.getElementById('btn-unlock-safe');
    const btnClose = document.getElementById('btn-close');

    // Setup auto-advance for inputs
    setupPinAutoAdvance(pcPinInputs, submitGuess);
    setupPinAutoAdvance(safePinInputs, submitFinalUnlock);

    btnSubmit.addEventListener('click', submitGuess);
    btnUnlockSafe.addEventListener('click', submitFinalUnlock);
    btnClose.addEventListener('click', closeUI);

    // ESC Key listener
    document.addEventListener('keyup', (e) => {
        if (e.key === 'Escape') {
            closeUI();
        }
    });
});

function setupPinAutoAdvance(inputs, onEnterCallback) {
    inputs.forEach((input, index) => {
        input.addEventListener('input', (e) => {
            let val = e.target.value.replace(/\D/g, '');
            if (val.length > 0) {
                e.target.value = val.slice(-1);
                if (index < inputs.length - 1) {
                    inputs[index + 1].focus();
                }
            } else {
                e.target.value = '';
            }
        });

        input.addEventListener('keydown', (e) => {
            if (e.key === 'Backspace' && !e.target.value && index > 0) {
                inputs[index - 1].focus();
            } else if (e.key === 'Enter') {
                if (onEnterCallback) onEnterCallback();
            }
        });
    });
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'open') {
        openUI(data);
    } else if (data.action === 'close') {
        hideUI();
    } else if (data.action === 'updateAttempts') {
        renderAttempts(data.attempts);
    } else if (data.action === 'updateSafeAttempts') {
        updateSafeAttempts(data.safeAttempts);
    } else if (data.action === 'setStatus') {
        document.getElementById('session-status').innerText = data.text;
    }
});

let checkPassLoadTime = 5000;
let maxPassAttempts = 8;
let maxSafeAttempts = 3;

function updateSafeAttempts(safeAttempts) {
    const safeCount = document.getElementById('safe-attempt-count');
    if (safeCount) safeCount.innerText = safeAttempts || 0;
}

function openUI(data) {
    currentRole = data.role;
    if (data.loadTime) checkPassLoadTime = data.loadTime;
    if (data.maxAttempts) {
        maxPassAttempts = data.maxAttempts;
        const pcMax = document.getElementById('pc-max-attempts');
        if (pcMax) pcMax.innerText = maxPassAttempts;
    }
    if (data.maxSafeAttempts) {
        maxSafeAttempts = data.maxSafeAttempts;
        const safeMax = document.getElementById('safe-max-attempts');
        if (safeMax) safeMax.innerText = maxSafeAttempts;
    }
    updateSafeAttempts(data.safeAttempts);

    document.getElementById('app').classList.remove('hidden');
    document.getElementById('pc-view').classList.add('hidden');
    document.getElementById('safe-view').classList.add('hidden');

    if (data.role === 'pc') {
        document.getElementById('pc-view').classList.remove('hidden');
        document.getElementById('terminal-mode-title').innerText = 'MÁY TÍNH GIẢI MÃ - STORE ROBBERY';
        document.getElementById('session-status').innerText = 'ĐÃ KẾT NỐI VỚI ĐỒNG ĐỘI';
        resetPinInputs('#pin-inputs .pin-box');
    } else if (data.role === 'safe') {
        document.getElementById('safe-view').classList.remove('hidden');
        document.getElementById('terminal-mode-title').innerText = 'ĐẦU ĐỌC THẺ THÀNH VIÊN & MỞ KÉT';
        document.getElementById('card-hidenumber').innerText = data.hidenumber || '----------';
        document.getElementById('session-status').innerText = 'ĐÃ TRÍCH XUẤT MÃ ẨN';
        resetPinInputs('#safe-pin-inputs .safe-pin-box');
    }

    if (data.debugPass) {
        document.getElementById('safe-debug-pass').classList.remove('hidden');
        document.getElementById('safe-debug-pass-val').innerText = data.debugPass;
        document.getElementById('pc-debug-pass').classList.remove('hidden');
        document.getElementById('pc-debug-pass-val').innerText = data.debugPass;
    } else {
        document.getElementById('safe-debug-pass').classList.add('hidden');
        document.getElementById('pc-debug-pass').classList.add('hidden');
    }

    renderAttempts(data.attempts || []);
}

let isGuessing = false;
let progressInterval = null;

function hideUI() {
    document.getElementById('app').classList.add('hidden');
    document.getElementById('safe-debug-pass').classList.add('hidden');
    document.getElementById('pc-debug-pass').classList.add('hidden');
    resetPinInputs('#pin-inputs .pin-box');
    resetPinInputs('#safe-pin-inputs .safe-pin-box');

    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }
    isGuessing = false;
    const progressContainer = document.getElementById('pc-progress-container');
    if (progressContainer) progressContainer.classList.add('hidden');
    const btnSubmit = document.getElementById('btn-submit');
    if (btnSubmit) btnSubmit.disabled = false;
}

function resetPinInputs(selector) {
    const inputs = document.querySelectorAll(selector);
    inputs.forEach(input => input.value = '');
    if (inputs.length > 0) inputs[0].focus();
}

function submitGuess() {
    if (currentRole !== 'pc') return;
    if (isGuessing) return; // Chống spam khi đang load

    const inputs = document.querySelectorAll('#pin-inputs .pin-box');
    let guess = '';
    inputs.forEach(input => guess += input.value.trim());

    if (guess.length !== 6) {
        document.getElementById('session-status').innerText = 'VUI LÒNG NHẬP ĐỦ 6 CHỮ SỐ!';
        return;
    }

    isGuessing = true;
    const btnSubmit = document.getElementById('btn-submit');
    if (btnSubmit) btnSubmit.disabled = true;

    const progressContainer = document.getElementById('pc-progress-container');
    const progressFill = document.getElementById('pc-progress-fill');
    const progressPercent = document.getElementById('pc-progress-percent');

    if (progressContainer) progressContainer.classList.remove('hidden');
    if (progressFill) progressFill.style.width = '0%';
    if (progressPercent) progressPercent.innerText = '0%';

    let elapsed = 0;
    const duration = checkPassLoadTime || 5000;
    const intervalTime = 50;

    if (progressInterval) clearInterval(progressInterval);

    progressInterval = setInterval(() => {
        elapsed += intervalTime;
        const pct = Math.min(100, Math.floor((elapsed / duration) * 100));

        if (progressFill) progressFill.style.width = `${pct}%`;
        if (progressPercent) progressPercent.innerText = `${pct}%`;

        if (elapsed >= duration) {
            clearInterval(progressInterval);
            progressInterval = null;

            if (progressContainer) progressContainer.classList.add('hidden');
            if (btnSubmit) btnSubmit.disabled = false;
            isGuessing = false;

            const resName = getResourceName();
            fetch(`https://${resName}/submitAttempt`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ guess: guess })
            });
        }
    }, intervalTime);
}

function submitFinalUnlock() {
    if (currentRole !== 'safe') return;
    const inputs = document.querySelectorAll('#safe-pin-inputs .safe-pin-box');
    let pass = '';
    inputs.forEach(input => pass += input.value.trim());

    if (pass.length !== 6) {
        document.getElementById('session-status').innerText = 'VUI LÒNG NHẬP ĐỦ 6 CHỮ SỐ MẬT KHẨU!';
        return;
    }

    const resName = getResourceName();
    fetch(`https://${resName}/submitFinalUnlock`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ pass: pass })
    });
}

function closeUI() {
    const resName = getResourceName();
    fetch(`https://${resName}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
    hideUI();
}

function renderAttempts(attempts) {
    const pcList = document.getElementById('attempts-list');
    const pcCount = document.getElementById('pc-attempt-count');

    if (pcCount) pcCount.innerText = (attempts || []).length;

    const recentAttempts = (attempts || []).slice().reverse().slice(0, 3);

    const html = recentAttempts.length === 0
        ? '<div class="empty-attempts">Chưa có dữ liệu thử nghiệm nào...</div>'
        : recentAttempts.map(att => {
            const digitsHtml = att.guess.split('').map((char, i) => {
                const statusClass = att.results[i] === 'correct' ? 'correct' : 'wrong';
                return `<div class="digit-chip ${statusClass}">${char}</div>`;
            }).join('');

            const isSuccess = att.results.every(r => r === 'correct');
            const statusText = isSuccess ? 'CHÍNH XÁC!' : 'SAI MẬT KHẨU';
            const statusClass = isSuccess ? 'success' : 'fail';

            return `
                <div class="attempt-row">
                    <div class="attempt-digits">${digitsHtml}</div>
                    <div class="attempt-status ${statusClass}">${statusText}</div>
                </div>
            `;
        }).join('');

    if (pcList) pcList.innerHTML = html;
}
