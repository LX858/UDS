// Global state and configurations
let config = {
    apiKey: 'DYds5MyJBLJRpLO73SRROn09QKfCSr7X',
    uploadUrl: 'https://api.fivemanage.com/api/v3/file',
    recordDuration: 10,
    fps: 30
};

let mediaRecorder = null;
let recordedChunks = [];
let recordInterval = null;
let currentSecondsLeft = 10;
let isRecording = false;
let animFrameId = null;
let gameview = null;

// DOM Elements
const app = document.getElementById('report-app');
const reportCard = document.getElementById('report-card');
const formView = document.getElementById('form-view');
const statusView = document.getElementById('status-view');
const historyView = document.getElementById('history-view');
const recordingState = document.getElementById('recording-state');
const uploadingState = document.getElementById('uploading-state');
const successState = document.getElementById('success-state');

const tabCreate = document.getElementById('tab-create');
const tabHistory = document.getElementById('tab-history');
const historyCountBadge = document.getElementById('history-count-badge');
const historySearchInput = document.getElementById('history-search-input');
const btnClearSearch = document.getElementById('btn-clear-search');
const btnRefreshHistory = document.getElementById('btn-refresh-history');
const historyList = document.getElementById('history-list');
const historyFooterText = document.getElementById('history-footer-text');

const reasonInput = document.getElementById('report-reason');
const charCount = document.getElementById('char-count');
const btnSubmit = document.getElementById('btn-submit');
const btnCancel = document.getElementById('btn-cancel');
const btnClose = document.getElementById('btn-close');

const recordTimer = document.getElementById('record-timer');
const recordProgress = document.getElementById('record-progress');
const renderCanvas = document.getElementById('render-canvas');

let activeTab = 'create';
let cachedReports = [];
let isLoadingReports = false;

// ============================================================================
// FIVE-M NATIVE GAMEVIEW WEBGL ENGINE (DIRECTX BUFFER VSYNC HOOK)
// ============================================================================

const vertexShaderSrc = `
  attribute vec2 a_position;
  attribute vec2 a_texcoord;
  varying vec2 textureCoordinate;
  void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
    textureCoordinate = a_texcoord;
  }
`;

const fragmentShaderSrc = `
  varying highp vec2 textureCoordinate;
  uniform sampler2D external_texture;
  void main() {
    gl_FragColor = texture2D(external_texture, textureCoordinate);
  }
`;

function createGameview(canvas) {
    const gl = canvas.getContext('webgl', {
        preserveDrawingBuffer: true,
        alpha: false,
        antialias: false,
        depth: false,
        premultipliedAlpha: false,
        powerPreference: 'high-performance'
    });

    if (!gl) {
        console.error('[XN_REPORT] WebGL is not supported on this client');
        return null;
    }

    const vs = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vs, vertexShaderSrc);
    gl.compileShader(vs);

    const fs = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fs, fragmentShaderSrc);
    gl.compileShader(fs);

    const program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    gl.useProgram(program);

    // Quad Vertex Buffer (-1.0 to 1.0)
    const positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
        -1, -1,
         1, -1,
        -1,  1,
        -1,  1,
         1, -1,
         1,  1
    ]), gl.STATIC_DRAW);

    const a_position = gl.getAttribLocation(program, 'a_position');
    gl.enableVertexAttribArray(a_position);
    gl.vertexAttribPointer(a_position, 2, gl.FLOAT, false, 0, 0);

    // Texture UV Buffer (Lật đúng chiều DirectX sang WebGL)
    const texcoordBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
        0, 0,
        1, 0,
        0, 1,
        0, 1,
        1, 0,
        1, 1
    ]), gl.STATIC_DRAW);

    const a_texcoord = gl.getAttribLocation(program, 'a_texcoord');
    gl.enableVertexAttribArray(a_texcoord);
    gl.vertexAttribPointer(a_texcoord, 2, gl.FLOAT, false, 0, 0);

    // FiveM Native Magic Hook Texture
    const tex = gl.createTexture();
    const texPixels = new Uint8Array([0, 0, 255, 255]);
    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, texPixels);

    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);

    // FiveM Magic Hook Sequence (Khóa buffer DirectX vào WebGL texture)
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    const u_texture = gl.getUniformLocation(program, 'external_texture');
    gl.uniform1i(u_texture, 0);

    console.log('[XN_REPORT] FiveM DirectX WebGL VSync Engine initialized!');

    return {
        render: () => {
            gl.viewport(0, 0, canvas.width, canvas.height);
            gl.useProgram(program);
            gl.bindTexture(gl.TEXTURE_2D, tex);
            gl.drawArrays(gl.TRIANGLES, 0, 6);
        },
        destroy: () => {
            try {
                gl.deleteTexture(tex);
                gl.deleteBuffer(positionBuffer);
                gl.deleteBuffer(texcoordBuffer);
                gl.deleteProgram(program);
            } catch (e) {}
        }
    };
}

// Khởi tạo Gameview Engine HD 720p
function initGameviewEngine() {
    if (gameview) return;

    renderCanvas.width = 1280;
    renderCanvas.height = 720;

    gameview = createGameview(renderCanvas);
}

// Bắt đầu Render Loop đồng bộ GPU VSync (Khắc phục 100% nhấp nháy & mượt mà 1:1 thời gian thực)
function startRenderingGameLoop() {
    if (!gameview) initGameviewEngine();
    if (!gameview) return;

    const targetFps = config.fps || 30;
    const frameInterval = 1000 / targetFps;
    let lastDrawTime = performance.now();

    const render = (currentTime) => {
        if (!isRecording) return;
        animFrameId = requestAnimationFrame(render);

        const elapsed = currentTime - lastDrawTime;
        // Dung sai 4ms giúp khớp nhịp hoàn hảo với VSync màn hình mà không bị nhảy cóc
        if (elapsed >= frameInterval - 4) {
            lastDrawTime = currentTime - (elapsed % frameInterval);
            gameview.render();
        }
    };

    animFrameId = requestAnimationFrame(render);
}

function stopRenderingGameLoop() {
    if (animFrameId) {
        cancelAnimationFrame(animFrameId);
        animFrameId = null;
    }
}

// ============================================================================
// TAB NAVIGATION & REPORT HISTORY MANAGEMENT
// ============================================================================

function switchTab(tabName) {
    if (isRecording) return;
    activeTab = tabName;

    if (tabName === 'create') {
        tabCreate.classList.add('active');
        tabHistory.classList.remove('active');
        formView.classList.remove('hidden');
        historyView.classList.add('hidden');
        reportCard.classList.remove('history-mode');
        setTimeout(() => {
            reasonInput.focus();
        }, 50);
    } else if (tabName === 'history') {
        tabHistory.classList.add('active');
        tabCreate.classList.remove('active');
        historyView.classList.remove('hidden');
        formView.classList.add('hidden');
        reportCard.classList.add('history-mode');
        fetchReportHistory();
    }
}

tabCreate.addEventListener('click', () => switchTab('create'));
tabHistory.addEventListener('click', () => switchTab('history'));

// Fetch lịch sử report từ FiveM Server Callback
async function fetchReportHistory(isRefresh = false) {
    if (isLoadingReports && !isRefresh) return;
    isLoadingReports = true;

    if (isRefresh) {
        btnRefreshHistory.classList.add('spinning');
    }

    renderSkeletonLoading();
    historyFooterText.textContent = 'Đang tải dữ liệu từ máy chủ...';

    try {
        const response = await fetch(`https://${GetParentResourceName()}/getReportHistory`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });

        if (response.ok) {
            const data = await response.json();
            cachedReports = Array.isArray(data) ? data : [];
            historyCountBadge.textContent = cachedReports.length;
        } else {
            console.warn('[XN_REPORT] Failed to load history with status:', response.status);
        }
    } catch (err) {
        console.error('[XN_REPORT] Fetch history error:', err);
    } finally {
        isLoadingReports = false;
        if (isRefresh) {
            setTimeout(() => {
                btnRefreshHistory.classList.remove('spinning');
            }, 400);
        }
        applyFilterAndRender();
    }
}

function renderSkeletonLoading() {
    let html = '';
    for (let i = 0; i < 3; i++) {
        html += `
            <div class="skeleton-card">
                <div class="skeleton-line w-30"></div>
                <div class="skeleton-line h-30"></div>
                <div class="skeleton-line w-80"></div>
            </div>
        `;
    }
    historyList.innerHTML = html;
}

function getFilteredReports() {
    const query = historySearchInput.value.trim().toLowerCase();
    if (!query) return cachedReports;

    return cachedReports.filter(rp => {
        const idMatch = rp.id && rp.id.toString().toLowerCase().includes(query);
        const reasonMatch = rp.reason && rp.reason.toLowerCase().includes(query);
        return idMatch || reasonMatch;
    });
}

function applyFilterAndRender() {
    const filtered = getFilteredReports();
    renderReportList(filtered);

    const query = historySearchInput.value.trim();
    if (query) {
        btnClearSearch.classList.remove('hidden');
        historyFooterText.textContent = `Tìm thấy ${filtered.length} / ${cachedReports.length} báo cáo`;
    } else {
        btnClearSearch.classList.add('hidden');
        historyFooterText.textContent = `Tổng cộng ${cachedReports.length} báo cáo cá nhân của bạn`;
    }
}

function renderReportList(reports) {
    if (!reports || reports.length === 0) {
        const isSearch = historySearchInput.value.trim().length > 0;
        historyList.innerHTML = `
            <div class="history-empty-state">
                <div class="empty-icon-box">
                    <i class="fa-solid ${isSearch ? 'fa-magnifying-glass' : 'fa-box-archive'}"></i>
                </div>
                <div class="empty-title">${isSearch ? 'Không tìm thấy kết quả' : 'Chưa có báo cáo nào'}</div>
                <div class="empty-desc">
                    ${isSearch 
                        ? 'Không tìm thấy báo cáo nào khớp với từ khóa tìm kiếm của bạn.' 
                        : 'Các báo cáo vi phạm kèm video bằng chứng bạn gửi sẽ được lưu và hiển thị tại đây.'}
                </div>
            </div>
        `;
        return;
    }

    let html = '';
    reports.forEach(rp => {
        const id = rp.id || 'N/A';
        const createdAt = rp.createdAt || 'Gần đây';
        const reason = escapeHtml(rp.reason || 'Không có mô tả');
        const videoUrl = rp.videoUrl || '';

        let videoHtml = '';
        if (videoUrl && videoUrl.trim() !== '' && videoUrl.startsWith('http')) {
            videoHtml = `
                <div class="video-box-active">
                    <div class="video-info-left">
                        <i class="fa-solid fa-circle-play video-play-icon"></i>
                        <div class="video-link-wrapper" title="${escapeHtml(videoUrl)}">
                            <span class="video-link-text">${escapeHtml(videoUrl)}</span>
                        </div>
                    </div>
                    <div class="video-actions-right">
                        <button class="btn-video-action btn-video-copy" data-url="${escapeHtml(videoUrl)}" title="Sao chép liên kết">
                            <i class="fa-regular fa-copy"></i>
                            <span>Copy Link</span>
                        </button>
                        <button class="btn-video-action btn-video-open" data-url="${escapeHtml(videoUrl)}" title="Mở video bằng chứng">
                            <i class="fa-solid fa-arrow-up-right-from-square"></i>
                            <span>Xem Video</span>
                        </button>
                    </div>
                </div>
            `;
        } else {
            videoHtml = `
                <div class="no-video-box">
                    <i class="fa-solid fa-video-slash"></i>
                    <span>Không có video đính kèm hoặc chưa hoàn tất tải lên</span>
                </div>
            `;
        }

        html += `
            <div class="report-item-card">
                <div class="report-item-header">
                    <div class="report-id-badge">
                        <i class="fa-solid fa-hashtag"></i>
                        <span>ID: ${id}</span>
                    </div>
                    <div class="report-time-badge">
                        <i class="fa-regular fa-clock"></i>
                        <span>${createdAt}</span>
                    </div>
                </div>

                <div class="report-reason-container">
                    <div class="report-reason-title">
                        <i class="fa-solid fa-quote-left"></i>
                        <span>Nội dung báo cáo:</span>
                    </div>
                    <div class="report-reason-box">${reason}</div>
                </div>

                <div class="report-video-section">
                    ${videoHtml}
                </div>
            </div>
        `;
    });

    historyList.innerHTML = html;

    // Gắn sự kiện cho các nút Copy & Open Video
    historyList.querySelectorAll('.btn-video-copy').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const url = btn.getAttribute('data-url');
            copyToClipboard(url, btn);
        });
    });

    historyList.querySelectorAll('.btn-video-open').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const url = btn.getAttribute('data-url');
            openVideoUrl(url);
        });
    });
}

function escapeHtml(str) {
    if (!str) return '';
    return str
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// Copy URL to clipboard
function copyToClipboard(text, btnElement) {
    if (!text) return;

    const originalHtml = btnElement ? btnElement.innerHTML : null;

    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).catch(() => {
            fallbackCopyTextToClipboard(text);
        });
    } else {
        fallbackCopyTextToClipboard(text);
    }

    if (btnElement) {
        btnElement.innerHTML = `<i class="fa-solid fa-check"></i> <span>Đã sao chép!</span>`;
        btnElement.style.background = 'rgba(16, 185, 129, 0.25)';
        btnElement.style.borderColor = 'rgba(16, 185, 129, 0.5)';
        btnElement.style.color = '#34d399';
        setTimeout(() => {
            if (originalHtml) {
                btnElement.innerHTML = originalHtml;
                btnElement.style.background = '';
                btnElement.style.borderColor = '';
                btnElement.style.color = '';
            }
        }, 1800);
    }

    fetch(`https://${GetParentResourceName()}/copyNotify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(() => {});
}

function fallbackCopyTextToClipboard(text) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.top = '0';
    textArea.style.left = '0';
    textArea.style.position = 'fixed';
    textArea.style.opacity = '0';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
        document.execCommand('copy');
    } catch (err) {}
    document.body.removeChild(textArea);
}

// Mở link video
function openVideoUrl(url) {
    if (!url) return;
    if (window.invokeNative) {
        window.invokeNative('openUrl', url);
    } else {
        window.open(url, '_blank');
    }
}

// Search & Refresh listeners
historySearchInput.addEventListener('input', applyFilterAndRender);

btnClearSearch.addEventListener('click', () => {
    historySearchInput.value = '';
    applyFilterAndRender();
    historySearchInput.focus();
});

btnRefreshHistory.addEventListener('click', () => {
    fetchReportHistory(true);
});

// ============================================================================
// NUI EVENT HANDLERS & WORKFLOW
// ============================================================================

reasonInput.addEventListener('input', () => {
    const len = reasonInput.value.length;
    charCount.textContent = `${len} / 500`;
});

function closeUI() {
    if (isRecording) return;
    app.classList.add('hidden');
    resetState();
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(() => {});
}

btnClose.addEventListener('click', closeUI);
btnCancel.addEventListener('click', closeUI);

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.keyCode === 27) {
        closeUI();
    }
});

let cooldownSecondsLeft = 0;
let cooldownTimerInterval = null;

function formatCooldownDisplay(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    if (mins > 0) {
        return `${mins}p ${secs > 0 ? String(secs).padStart(2, '0') + 's' : '00s'}`;
    }
    return `${secs}s`;
}

function updateCooldownUI() {
    if (cooldownSecondsLeft > 0) {
        btnSubmit.disabled = true;
        btnSubmit.style.opacity = '0.65';
        btnSubmit.style.cursor = 'not-allowed';
        btnSubmit.innerHTML = `<i class="fa-solid fa-hourglass-half"></i> <span>Chờ gửi lại (${formatCooldownDisplay(cooldownSecondsLeft)})</span>`;
    } else {
        btnSubmit.disabled = false;
        btnSubmit.style.opacity = '';
        btnSubmit.style.cursor = '';
        btnSubmit.innerHTML = `<i class="fa-solid fa-circle-play"></i> <span>Bắt đầu Ghi & Gửi Report</span>`;
        if (cooldownTimerInterval) {
            clearInterval(cooldownTimerInterval);
            cooldownTimerInterval = null;
        }
    }
}

function startCooldownCountdown(seconds) {
    cooldownSecondsLeft = seconds;
    if (cooldownTimerInterval) clearInterval(cooldownTimerInterval);
    updateCooldownUI();

    if (seconds > 0) {
        cooldownTimerInterval = setInterval(() => {
            cooldownSecondsLeft--;
            if (cooldownSecondsLeft <= 0) {
                cooldownSecondsLeft = 0;
                clearInterval(cooldownTimerInterval);
                cooldownTimerInterval = null;
            }
            updateCooldownUI();
        }, 1000);
    }
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'open') {
        if (data.config) {
            config.apiKey = data.config.apiKey || config.apiKey;
            config.uploadUrl = data.config.uploadUrl || config.uploadUrl;
            config.recordDuration = data.config.recordDuration || 10;
            config.fps = data.config.fps || 30;
            config.cooldownTotal = data.config.cooldownTotal || (15 * 60);
        }
        openUI(data.config ? data.config.cooldownRemaining : 0);
    } else if (data.action === 'close') {
        app.classList.add('hidden');
        resetState();
    }
});

function openUI(remainingCooldown = 0) {
    resetState();
    initGameviewEngine();
    app.classList.remove('hidden');
    switchTab('create');
    startCooldownCountdown(remainingCooldown || 0);
    // Fetch danh sách report trước trong background để update badge count
    fetchReportHistory();
    setTimeout(() => {
        if (cooldownSecondsLeft <= 0) {
            reasonInput.focus();
        }
    }, 150);
}

function resetState() {
    isRecording = false;
    stopRenderingGameLoop();
    app.classList.remove('recording-mode');
    reportCard.classList.remove('compact-hud');
    reportCard.classList.remove('history-mode');
    formView.classList.remove('hidden');
    historyView.classList.add('hidden');
    statusView.classList.add('hidden');
    recordingState.classList.remove('hidden');
    uploadingState.classList.add('hidden');
    successState.classList.add('hidden');
    reasonInput.value = '';
    charCount.textContent = '0 / 500';
    recordProgress.style.width = '0%';
    historySearchInput.value = '';
    btnClearSearch.classList.add('hidden');
    clearInterval(recordInterval);
}

// Bắt đầu gửi Report và quay video màn hình game
btnSubmit.addEventListener('click', async () => {
    if (cooldownSecondsLeft > 0) {
        return;
    }

    const reason = reasonInput.value.trim();
    if (!reason) {
        reasonInput.focus();
        reasonInput.parentElement.style.borderColor = '#ef4444';
        setTimeout(() => {
            reasonInput.parentElement.style.borderColor = '';
        }, 1500);
        return;
    }

    startReportWorkflow(reason);
});

async function startReportWorkflow(reason) {
    isRecording = true;

    // Chuyển sang giao diện nhỏ ở Center Bottom để không che màn hình
    app.classList.add('recording-mode');
    reportCard.classList.add('compact-hud');
    formView.classList.add('hidden');
    statusView.classList.remove('hidden');
    recordingState.classList.remove('hidden');
    uploadingState.classList.add('hidden');
    successState.classList.add('hidden');

    // Bỏ khóa chuột NUI để người chơi nhìn và tương tác game bình thường trong khi quay
    fetch(`https://${GetParentResourceName()}/recordingStarted`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(() => {});

    currentSecondsLeft = config.recordDuration;
    updateTimerDisplay();
    recordProgress.style.width = '0%';

    // 1. Kích hoạt render game loop đồng bộ GPU VSync
    startRenderingGameLoop();

    // 2. Thu luồng Video Canvas (HD 720p @ 30 FPS)
    const targetFps = config.fps || 30;
    const canvasStream = renderCanvas.captureStream(targetFps);

    console.log(`[XN_REPORT] Bắt đầu quay video HD thời gian thực mượt mà (${targetFps} FPS)...`);

    // 3. Khởi tạo MediaRecorder mượt mà, ổn định
    recordedChunks = [];
    let mimeType = 'video/webm;codecs=vp8';
    if (!MediaRecorder.isTypeSupported(mimeType)) {
        mimeType = 'video/webm';
    }

    mediaRecorder = new MediaRecorder(canvasStream, {
        mimeType: mimeType,
        videoBitsPerSecond: 2000000 // 2.0 Mbps (HD 720p sắc nét và mượt)
    });

    mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
            recordedChunks.push(event.data);
        }
    };

    mediaRecorder.onstop = async () => {
        stopRenderingGameLoop();
        const videoBlob = new Blob(recordedChunks, { type: mimeType });
        await uploadToFiveManage(videoBlob, reason);
    };

    mediaRecorder.start(100);

    // 4. Chạy bộ đếm giờ
    const totalDuration = config.recordDuration;
    let elapsed = 0;
    const intervalTime = 100;

    recordInterval = setInterval(() => {
        elapsed += intervalTime;
        const remainingMs = Math.max(0, (totalDuration * 1000) - elapsed);
        currentSecondsLeft = Math.ceil(remainingMs / 1000);
        updateTimerDisplay();

        const progressPercent = Math.min(100, (elapsed / (totalDuration * 1000)) * 100);
        recordProgress.style.width = `${progressPercent}%`;

        if (elapsed >= totalDuration * 1000) {
            clearInterval(recordInterval);
            if (mediaRecorder && mediaRecorder.state !== 'inactive') {
                mediaRecorder.stop();
            }
        }
    }, intervalTime);
}

function updateTimerDisplay() {
    const mins = Math.floor(currentSecondsLeft / 60);
    const secs = currentSecondsLeft % 60;
    recordTimer.textContent = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

// Upload Blob trực tiếp lên FiveManage API
async function uploadToFiveManage(blob, reason) {
    recordingState.classList.add('hidden');
    uploadingState.classList.remove('hidden');

    let videoUrl = null;

    try {
        const formData = new FormData();
        formData.append('file', blob, `report_${Date.now()}.webm`);
        formData.append('metadata', JSON.stringify({
            name: `Report_Evidence_${Date.now()}`,
            description: reason
        }));

        const response = await fetch(config.uploadUrl, {
            method: 'POST',
            headers: {
                'Authorization': config.apiKey
            },
            body: formData
        });

        if (!response.ok) {
            throw new Error(`Upload failed with status: ${response.status}`);
        }

        const data = await response.json();
        console.log('[XN_REPORT] FiveManage upload response:', data);

        if (data.data && data.data.url) {
            videoUrl = data.data.url;
        } else if (data.url) {
            videoUrl = data.url;
        } else if (typeof data === 'string' && data.startsWith('http')) {
            videoUrl = data;
        } else if (data.data && typeof data.data === 'string' && data.data.startsWith('http')) {
            videoUrl = data.data;
        }
    } catch (err) {
        console.error('[XN_REPORT] Upload to FiveManage error:', err);
    }

    // Transition sang Success State
    uploadingState.classList.add('hidden');
    successState.classList.remove('hidden');

    // Gửi kết quả về FiveM Lua Client Callback
    setTimeout(() => {
        fetch(`https://${GetParentResourceName()}/submitReport`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                reason: reason,
                videoUrl: videoUrl,
                duration: config.recordDuration
            })
        }).catch(() => {});

        // Cập nhật lại lịch sử sau khi gửi report mới
        fetchReportHistory(true);

        setTimeout(() => {
            app.classList.add('hidden');
            resetState();
        }, 1800);
    }, 1200);
}
