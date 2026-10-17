let updatesData = [];
let filteredCategory = 'all';
let searchQuery = '';
let selectedUpdateId = null;
let isAdminUser = false;

// DOM Elements
const appContainer = document.getElementById('app');
const serverTitleEl = document.getElementById('serverTitle');
const updatesListEl = document.getElementById('updatesList');
const adminPostBtn = document.getElementById('adminPostBtn');
const categoryTabs = document.getElementById('categoryTabs');
const searchInput = document.getElementById('searchInput');

// Detail Panel Elements
const detailPlaceholder = document.getElementById('detailPlaceholder');
const detailContent = document.getElementById('detailContent');
const detailCategory = document.getElementById('detailCategory');
const detailVersion = document.getElementById('detailVersion');
const detailTitle = document.getElementById('detailTitle');
const detailAuthor = document.getElementById('detailAuthor');
const detailDate = document.getElementById('detailDate');
const detailBody = document.getElementById('detailBody');

// Admin Modal Elements
const adminModal = document.getElementById('adminModal');
const closeAdminModalBtn = document.getElementById('closeAdminModal');
const cancelPostBtn = document.getElementById('cancelPostBtn');
const postForm = document.getElementById('postForm');

// Close Button
const readCloseBtn = document.getElementById('readCloseBtn');

// Helper to Format Category Badge
function getBadgeInfo(category) {
    switch (category) {
        case 'feature': return { label: 'Tính năng mới', class: 'badge-feature' };
        case 'update': return { label: 'Cập nhật', class: 'badge-update' };
        case 'fix': return { label: 'Sửa lỗi', class: 'badge-fix' };
        case 'event': return { label: 'Sự kiện', class: 'badge-event' };
        default: return { label: 'Thông báo', class: 'badge-update' };
    }
}

// Reset view state back to default ("Tất cả", empty search, reset selection)
function resetViewState() {
    filteredCategory = 'all';
    searchQuery = '';
    selectedUpdateId = null;
    searchInput.value = '';

    categoryTabs.querySelectorAll('.tab-btn').forEach(btn => {
        if (btn.dataset.category === 'all') {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });
}

let editingUpdateId = null;

// Strip raw markdown & formatting tags for clean card preview snippets
function stripFormatting(text) {
    if (!text) return '';
    let clean = text;
    // Strip bold **text**
    clean = clean.replace(/\*\*(.*?)\*\*/g, '$1');
    // Strip uppercase ^^text^^
    clean = clean.replace(/\^\^(.*?)\^\^/g, '$1');
    // Strip italic *text*
    clean = clean.replace(/\*(.*?)\*/g, '$1');
    // Strip cyan [cyan]text[/cyan]
    clean = clean.replace(/\[cyan\](.*?)\[\/cyan\]/g, '$1');
    // Strip links [Anchor](url)
    clean = clean.replace(/\[(.*?)\]\((https?:\/\/[^\s]+)\)/g, '$1');
    // Strip bullet points • or -
    clean = clean.replace(/^[\s•\-]+/gm, '');
    return escapeHtml(clean.trim());
}

// Render Updates List
function renderUpdatesList() {
    updatesListEl.innerHTML = '';

    const listToRender = updatesData.filter(item => {
        const matchesCategory = (filteredCategory === 'all') || (item.category === filteredCategory);
        const matchesSearch = item.title.toLowerCase().includes(searchQuery) || item.content.toLowerCase().includes(searchQuery);
        return matchesCategory && matchesSearch;
    });

    if (listToRender.length === 0) {
        updatesListEl.innerHTML = `
            <div style="text-align: center; color: var(--text-muted); padding: 30px 10px; font-size: 13px;">
                <i class="fa-solid fa-folder-open" style="font-size: 24px; margin-bottom: 8px; display: block;"></i>
                Không tìm thấy bài cập nhật nào!
            </div>
        `;
        showPlaceholder(true);
        return;
    }

    listToRender.forEach(item => {
        const badge = getBadgeInfo(item.category);
        const isSelected = item.id === selectedUpdateId;

        const card = document.createElement('div');
        card.className = `update-card ${isSelected ? 'active' : ''}`;
        card.dataset.id = item.id;

        card.innerHTML = `
            <div class="card-meta-top">
                <span class="badge ${badge.class}">${badge.label}</span>
                <span class="card-date">${item.date || ''}</span>
            </div>
            <h3 class="card-title">${escapeHtml(item.title)}</h3>
            <p class="card-snippet">${stripFormatting(item.content)}</p>
            ${isAdminUser ? `
                <div class="card-actions-group">
                    <button class="card-action-btn btn-edit-card" data-id="${item.id}" title="Sửa bài"><i class="fa-solid fa-pen-to-square"></i></button>
                    <button class="card-action-btn btn-delete-card" data-id="${item.id}" title="Xóa bài"><i class="fa-solid fa-trash"></i></button>
                </div>
            ` : ''}
        `;

        card.addEventListener('click', (e) => {
            if (e.target.closest('.btn-edit-card')) {
                e.stopPropagation();
                const editId = parseInt(e.target.closest('.btn-edit-card').dataset.id);
                openAdminEditModal(editId);
                return;
            }

            if (e.target.closest('.btn-delete-card')) {
                e.stopPropagation();
                const deleteId = parseInt(e.target.closest('.btn-delete-card').dataset.id);
                deleteUpdateItem(deleteId);
                return;
            }

            selectUpdateItem(item.id);
        });

        updatesListEl.appendChild(card);
    });

    // Auto select first item if none selected or current selected lost
    if (!selectedUpdateId || !listToRender.find(x => x.id === selectedUpdateId)) {
        if (listToRender.length > 0) {
            selectUpdateItem(listToRender[0].id);
        } else {
            showPlaceholder(true);
        }
    }
}

// Select Update Item & Display Details
function selectUpdateItem(id) {
    selectedUpdateId = id;
    const item = updatesData.find(x => x.id === id);
    if (!item) {
        showPlaceholder(true);
        return;
    }

    showPlaceholder(false);

    const badge = getBadgeInfo(item.category);
    detailCategory.textContent = badge.label;
    detailCategory.className = `badge ${badge.class}`;
    detailVersion.textContent = item.version || 'v1.0.0';
    detailTitle.textContent = item.title;
    detailAuthor.textContent = item.author || 'BQL';
    detailDate.textContent = item.date || '';
    
    // Format body content (convert double newlines and bullet points)
    detailBody.innerHTML = formatBodyText(item.content);

    // Update active state class on cards
    document.querySelectorAll('.update-card').forEach(card => {
        if (parseInt(card.dataset.id) === id) {
            card.classList.add('active');
        } else {
            card.classList.remove('active');
        }
    });
}

function showPlaceholder(show) {
    if (show) {
        detailPlaceholder.classList.remove('hidden');
        detailContent.classList.add('hidden');
    } else {
        detailPlaceholder.classList.add('hidden');
        detailContent.classList.remove('hidden');
    }
}

// Escape HTML safety helper
function escapeHtml(text) {
    if (!text) return '';
    return text.replace(/&/g, "&amp;")
               .replace(/</g, "&lt;")
               .replace(/>/g, "&gt;")
               .replace(/"/g, "&quot;")
               .replace(/'/g, "&#039;");
}

// Helper to open external URL in user's default browser
function openExternalUrl(url) {
    if (!url) return;

    // Send NUI callback to client lua
    fetch(`https://${GetParentResourceName()}/openUrl`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: url })
    });

    try {
        if (window.invokeNative) {
            window.invokeNative('openUrl', url);
        } else {
            window.open(url, '_blank');
        }
    } catch (e) {
        window.open(url, '_blank');
    }
}

// Text formatter supporting bold, uppercase, italic, cyan color, links, and list bullet items
function formatBodyText(text) {
    if (!text) return '';
    let formatted = escapeHtml(text);
    
    // **In đậm**
    formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong class="text-bold">$1</strong>');
    
    // ^^IN HOA^^
    formatted = formatted.replace(/\^\^(.*?)\^\^/g, (match, p1) => `<span class="text-uppercase">${p1.toUpperCase()}</span>`);
    
    // *In nghiêng*
    formatted = formatted.replace(/\*(.*?)\*/g, '<em>$1</em>');
    
    // [cyan]Chữ màu Cyan[/cyan]
    formatted = formatted.replace(/\[cyan\](.*?)\[\/cyan\]/g, '<span class="text-cyan">$1</span>');

    // [Tên Link](https://...)
    formatted = formatted.replace(/\[(.*?)\]\((https?:\/\/[^\s]+)\)/g, '<a href="$2" data-url="$2" class="content-link"><i class="fa-solid fa-up-right-from-square link-icon"></i> <span>$1</span></a>');

    // Auto URL regex: https://...
    formatted = formatted.replace(/(^|[^"'])((https?:\/\/)[^\s<]+)/g, '$1<a href="$2" data-url="$2" class="content-link"><i class="fa-solid fa-up-right-from-square link-icon"></i> <span>$2</span></a>');

    // Split into lines for list item bullet processing (lines starting with • or -)
    const lines = formatted.split('\n');
    const processedLines = lines.map(line => {
        const trimmed = line.trim();
        if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
            const content = trimmed.substring(1).trim();
            return `<div class="content-list-item"><i class="fa-solid fa-star list-icon"></i> <span>${content}</span></div>`;
        }
        return line;
    });

    let result = processedLines.join('\n');
    // Remove extra newline between consecutive content-list-item divs to avoid double line breaks with pre-wrap
    result = result.replace(/<\/div>\n<div class="content-list-item">/g, '</div><div class="content-list-item">');
    return result;
}

// Bind delegated click listener for external links in detail body
if (detailBody) {
    detailBody.addEventListener('click', (e) => {
        const linkEl = e.target.closest('.content-link');
        if (linkEl) {
            e.preventDefault();
            e.stopPropagation();
            const url = linkEl.getAttribute('data-url') || linkEl.getAttribute('href');
            if (url) {
                openExternalUrl(url);
            }
        }
    });
}

// Formatting Toolbar Helper for Textarea
function insertFormattingTag(tagType) {
    const textarea = document.getElementById('postContent');
    if (!textarea) return;

    // Save current scroll position to prevent jumping
    const savedScrollTop = textarea.scrollTop;

    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const text = textarea.value;
    const selectedText = text.substring(start, end);

    let before = '';
    let after = '';
    let defaultSample = 'nội dung';

    switch (tagType) {
        case 'bold':
            before = '**';
            after = '**';
            defaultSample = 'Chữ in đậm';
            break;
        case 'uppercase':
            before = '^^';
            after = '^^';
            defaultSample = 'CHỮ IN HOA';
            break;
        case 'italic':
            before = '*';
            after = '*';
            defaultSample = 'Chữ in nghiêng';
            break;
        case 'cyan':
            before = '[cyan]';
            after = '[/cyan]';
            defaultSample = 'Chữ màu Cyan';
            break;
        case 'link':
            before = '[';
            after = '](https://...)';
            defaultSample = 'Tên liên kết';
            break;
        case 'bullet':
            before = '• ';
            after = '';
            defaultSample = '';
            break;
    }

    let insertText = selectedText || defaultSample;
    if (tagType === 'uppercase' && selectedText) {
        insertText = selectedText.toUpperCase();
    }

    textarea.value = text.substring(0, start) + before + insertText + after + text.substring(end);
    
    // Calculate new selection range
    const selectStartPos = start + before.length;
    const selectEndPos = selectStartPos + insertText.length;
    
    // Focus without jumping scroll
    textarea.focus({ preventScroll: true });
    
    // Select the inserted text or set cursor position
    if (selectedText) {
        textarea.setSelectionRange(start, selectEndPos + after.length);
    } else {
        textarea.setSelectionRange(selectStartPos, selectEndPos);
    }

    // Restore exact scroll position
    textarea.scrollTop = savedScrollTop;
}

// Bind Toolbar Button Clicks
document.querySelectorAll('#editorToolbar .tool-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        const tag = btn.dataset.tag;
        insertFormattingTag(tag);
    });
});

// Event Listeners for Filter Tabs
categoryTabs.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        categoryTabs.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        filteredCategory = btn.dataset.category;
        renderUpdatesList();
    });
});

// Event Listener for Search Input
searchInput.addEventListener('input', (e) => {
    searchQuery = e.target.value.toLowerCase().trim();
    renderUpdatesList();
});

// Admin Actions: Create & Edit Modal
function openAdminCreateModal() {
    editingUpdateId = null;
    postForm.reset();
    document.querySelector('.admin-modal-header h3').innerHTML = `<i class="fa-solid fa-pen-to-square"></i> ĐĂNG BÀI CẬP NHẬT MỚI`;
    document.querySelector('.btn-cyan-submit').innerHTML = `<i class="fa-solid fa-paper-plane"></i> Đăng Thông Báo`;
    adminModal.classList.remove('hidden');
    setTimeout(() => {
        document.getElementById('postTitle').focus();
    }, 100);
}

function openAdminEditModal(id) {
    const item = updatesData.find(x => x.id === id);
    if (!item) return;

    editingUpdateId = id;
    document.getElementById('postTitle').value = item.title || '';
    document.getElementById('postCategory').value = item.category || 'update';
    document.getElementById('postVersion').value = item.version || 'v1.0.0';
    document.getElementById('postContent').value = item.content || '';

    document.querySelector('.admin-modal-header h3').innerHTML = `<i class="fa-solid fa-pen-to-square"></i> CHỈNH SỬA BÀI CẬP NHẬT (#${id})`;
    document.querySelector('.btn-cyan-submit').innerHTML = `<i class="fa-solid fa-floppy-disk"></i> Lưu Thay Đổi`;
    adminModal.classList.remove('hidden');
    setTimeout(() => {
        document.getElementById('postTitle').focus();
    }, 100);
}

adminPostBtn.addEventListener('click', openAdminCreateModal);

closeAdminModalBtn.addEventListener('click', () => {
    adminModal.classList.add('hidden');
    editingUpdateId = null;
});

cancelPostBtn.addEventListener('click', () => {
    adminModal.classList.add('hidden');
    editingUpdateId = null;
});

postForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const title = document.getElementById('postTitle').value.trim();
    const category = document.getElementById('postCategory').value;
    const version = document.getElementById('postVersion').value.trim();
    const content = document.getElementById('postContent').value.trim();

    if (!title || !content) return;

    if (editingUpdateId) {
        // Edit Mode
        fetch(`https://${GetParentResourceName()}/editUpdate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: editingUpdateId, title, category, version, content })
        });
    } else {
        // Create Mode
        fetch(`https://${GetParentResourceName()}/postUpdate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title, category, version, content })
        });
    }

    postForm.reset();
    editingUpdateId = null;
    adminModal.classList.add('hidden');
});

function deleteUpdateItem(id) {
    fetch(`https://${GetParentResourceName()}/deleteUpdate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: id })
    });
}

// Close NUI
function closeUI() {
    appContainer.classList.add('hidden');
    adminModal.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

readCloseBtn.addEventListener('click', closeUI);

// Keydown listener for ESC key
window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.code === 'Escape') {
        if (!adminModal.classList.contains('hidden')) {
            adminModal.classList.add('hidden');
        } else if (!appContainer.classList.contains('hidden')) {
            closeUI();
        }
    }
});

// Listen to NUI Messages from Lua Client Script
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'open') {
        updatesData = data.updates || [];
        isAdminUser = data.isAdmin || false;
        
        if (data.serverName) {
            serverTitleEl.textContent = data.serverName;
        }

        // Only show Admin buttons if player has Admin role
        if (isAdminUser) {
            adminPostBtn.classList.remove('hidden');
        } else {
            adminPostBtn.classList.add('hidden');
        }

        // Always reset filter tab to "Tất cả" & clear search on UI open
        resetViewState();

        appContainer.classList.remove('hidden');
        adminModal.classList.add('hidden');
        renderUpdatesList();
    } else if (data.action === 'close') {
        appContainer.classList.add('hidden');
        adminModal.classList.add('hidden');
    } else if (data.action === 'updateList') {
        updatesData = data.updates || [];
        renderUpdatesList();
    }
});
