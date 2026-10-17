let currentTab = 'police';
let announcements = [];
let permissions = { canPost: false, category: null };

// Debug toggle
const debug = false;
function debugLog(...args) {
    if (debug) {
        console.log(...args);
    }
}

// DOM Elements
const feedContainer = document.getElementById('announcement-feed');
const tabPd = document.getElementById('tab-pd');
const tabEms = document.getElementById('tab-ems');
const fabBtn = document.getElementById('fab-btn');
const composeModal = document.getElementById('compose-modal');
const composeForm = document.getElementById('compose-form');
const closeModalBtn = document.getElementById('close-modal');

// Input Elements
const postTitle = document.getElementById('post-title');
const postContent = document.getElementById('post-content');
const postApplyTime = document.getElementById('post-apply-time');

// Helper to interact with client script
async function sendRequestToClient(event, data = {}) {
    try {
        const resourceName = 'xn_pdemstool';
        const response = await fetch(`https://${resourceName}/${event}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (err) {
        console.error(`Error fetching NUI event ${event}:`, err);
        return null;
    }
}

// Date formatter (HH:MM - DD/MM/YYYY)
function formatDate(dateStr) {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return dateStr;
    
    const pad = (n) => n.toString().padStart(2, '0');
    const hours = pad(date.getHours());
    const minutes = pad(date.getMinutes());
    const day = pad(date.getDate());
    const month = pad(date.getMonth() + 1);
    const year = date.getFullYear();
    
    return `${hours}:${minutes} - ${day}/${month}/${year}`;
}

// Update fab button visibility based on tab and permissions
function updateFabVisibility() {
    const shouldShow = permissions.canPost && (permissions.category === currentTab);
    fabBtn.style.display = shouldShow ? 'flex' : 'none';
}

// Render the feed list
function renderFeed() {
    feedContainer.innerHTML = '';
    
    // Filter announcements by current tab category
    const filtered = announcements.filter(item => item.category === currentTab);
    debugLog("[xn_pdemstool] renderFeed: filtering by", currentTab, "total announcements:", announcements.length, "filtered announcements:", filtered.length);
    
    if (filtered.length === 0) {
        feedContainer.innerHTML = `
            <div class="empty-state">
                <svg viewBox="0 0 24 24" class="empty-icon"><path fill="currentColor" d="M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-7 9h-2V5h2v6zm0 4h-2v-2h2v2z"/></svg>
                <p>Không có thông báo nào</p>
            </div>
        `;
        return;
    }
    
    filtered.forEach(item => {
        const card = document.createElement('div');
        card.className = 'announcement-card';
        
        const isEms = item.category === 'ems';
        const badgeClass = isEms ? 'ems-type' : 'pd-type';
        const typeLabel = isEms ? 'Y tế (EMS)' : 'Công an (PD)';
        
        const canDelete = permissions.canPost && (permissions.category === item.category);
        const deleteBtnHtml = canDelete ? `
            <button class="delete-btn" data-id="${item.id}" title="Xóa thông báo">
                <svg viewBox="0 0 24 24" class="delete-icon-svg"><path fill="currentColor" d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
            </button>
        ` : '';

        card.innerHTML = `
            <div class="card-header">
                <div class="card-header-top">
                    <h3 class="card-title">${escapeHTML(item.title)}</h3>
                    ${deleteBtnHtml}
                </div>
                <div class="card-meta">
                    <div class="meta-item">
                        <svg viewBox="0 0 24 24" class="meta-icon"><path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
                        <span>${typeLabel}</span>
                    </div>
                    <div class="meta-item">
                        <svg viewBox="0 0 24 24" class="meta-icon"><path fill="currentColor" d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>
                        <span>Người đăng: ${escapeHTML(item.sender_name)}</span>
                    </div>
                    <div class="meta-item">
                        <svg viewBox="0 0 24 24" class="meta-icon"><path fill="currentColor" d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/></svg>
                        <span>${formatDate(item.created_at)}</span>
                    </div>
                </div>
            </div>
            <div class="card-divider"></div>
            <div class="card-body">${escapeHTML(item.content)}</div>
            <div class="card-apply-time ${badgeClass}">
                <svg viewBox="0 0 24 24" class="meta-icon"><path fill="currentColor" d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z"/></svg>
                <span>Thời gian áp dụng: ${escapeHTML(item.apply_time)}</span>
            </div>
        `;

        
        feedContainer.appendChild(card);
    });
}

function escapeHTML(str) {
    if (!str) return '';
    return str.replace(/[&<>'"]/g, 
        tag => ({
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            "'": '&#39;',
            '"': '&quot;'
        }[tag] || tag)
    );
}

// Fetch announcements from client script
async function loadAnnouncements() {
    const res = await sendRequestToClient('getAnnouncements');
    debugLog("[xn_pdemstool] loadAnnouncements: Data received from client:", JSON.stringify(res));
    if (res) {
        announcements = res;
        renderFeed();
    }
}

// Check player job permissions
async function initPermissions() {
    debugLog("[xn_pdemstool] Requesting permissions...");
    const res = await sendRequestToClient('checkPermissions');
    debugLog("[xn_pdemstool] Permissions response:", JSON.stringify(res));
    if (res) {
        permissions = res;
        updateFabVisibility();
        
        // Dynamically adjust input focus border color based on category
        if (permissions.canPost) {
            document.documentElement.style.setProperty(
                '--input-focus', 
                permissions.category === 'ems' ? 'var(--ems-color)' : 'var(--primary-color)'
            );
        }

        // Open compose modal if requested by /tbbn command handshake
        if (permissions.openCompose) {
            composeModal.classList.add('active');
            postTitle.value = '';
            postContent.value = '';
            postApplyTime.value = '';
        }
    }
}

// Tab click handler
function handleTabChange(tab) {
    if (currentTab === tab) return;
    
    currentTab = tab;
    
    // Update active UI classes
    if (currentTab === 'police') {
        tabPd.classList.add('active');
        tabEms.classList.remove('active');
        document.documentElement.style.setProperty('--accent-color', 'var(--primary-color)');
    } else {
        tabPd.classList.remove('active');
        tabEms.classList.add('active');
        document.documentElement.style.setProperty('--accent-color', 'var(--ems-color)');
    }
    
    updateFabVisibility();
    renderFeed();
}

// Bind event listeners
tabPd.addEventListener('click', () => handleTabChange('police'));
tabEms.addEventListener('click', () => handleTabChange('ems'));

// FAB Compose
fabBtn.addEventListener('click', () => {
    composeModal.classList.add('active');
    // Clear old values
    postTitle.value = '';
    postContent.value = '';
    postApplyTime.value = '';
});

// Close Compose modal
closeModalBtn.addEventListener('click', () => {
    composeModal.classList.remove('active');
});

// Close modal when clicking overlay
composeModal.addEventListener('click', (e) => {
    if (e.target === composeModal) {
        composeModal.classList.remove('active');
    }
});

// Submit Compose form
composeForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const title = postTitle.value.trim();
    const content = postContent.value.trim();
    const applyTime = postApplyTime.value.trim();
    
    if (!title || !content || !applyTime) return;
    
    const submitBtn = composeForm.querySelector('.submit-btn');
    submitBtn.disabled = true;
    submitBtn.innerText = 'Đang đăng...';
    
    const payload = {
        title: title,
        content: content,
        apply_time: applyTime,
        category: permissions.category
    };
    
    await sendRequestToClient('postAnnouncement', payload);
    
    // Reset and close
    submitBtn.disabled = false;
    submitBtn.innerText = 'Đăng bài';
    composeModal.classList.remove('active');

    // Immediately reload feed locally for the poster
    loadAnnouncements();
});

// Event delegation for deleting announcements
feedContainer.addEventListener('click', async (e) => {
    const deleteBtn = e.target.closest('.delete-btn');
    if (deleteBtn) {
        const id = deleteBtn.getAttribute('data-id');
        if (id) {
            if (!deleteBtn.classList.contains('armed')) {
                // First click: arm the button
                deleteBtn.classList.add('armed');
                deleteBtn.setAttribute('title', 'Click lại để xác nhận xóa');
                
                // Reset after 3 seconds
                setTimeout(() => {
                    deleteBtn.classList.remove('armed');
                    deleteBtn.setAttribute('title', 'Xóa thông báo');
                }, 3000);
            } else {
                // Second click: execute deletion
                deleteBtn.classList.remove('armed');
                deleteBtn.disabled = true;
                const success = await sendRequestToClient('deleteAnnouncement', { id: parseInt(id) });
                if (success) {
                    // Update feed locally
                    announcements = announcements.filter(item => item.id !== parseInt(id));
                    renderFeed();
                } else {
                    deleteBtn.disabled = false;
                }
            }
        }
    }
});


// Listen for updates from Client script
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    debugLog("[xn_pdemstool] Received window message: ", JSON.stringify(data));

    // Handle different lb-phone custom app message structures
    let isRefresh = false;
    let isOpenCompose = false;

    if (data.action === 'dep_announcements' && data.data) {
        if (data.data.action === 'refresh') isRefresh = true;
        if (data.data.action === 'openCompose') isOpenCompose = true;
    } else if (data.action === 'refresh') {
        isRefresh = true;
    } else if (data.action === 'openCompose') {
        isOpenCompose = true;
    } else if (data.message) {
        if (data.message.action === 'refresh') isRefresh = true;
        if (data.message.action === 'openCompose') isOpenCompose = true;
    }

    if (isRefresh) {
        loadAnnouncements();
    } else if (isOpenCompose) {
        composeModal.classList.add('active');
        postTitle.value = '';
        postContent.value = '';
        postApplyTime.value = '';
    }
});

// Initialise app
async function init() {
    await initPermissions();
    await loadAnnouncements();
}

init();

