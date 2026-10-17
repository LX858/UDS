// Tablet Menu Functions
function showTabletMenu() {
    const existingMenu = document.getElementById('tablet-menu-overlay');
    if (existingMenu) existingMenu.remove();
    
    const menuHTML = `
        <div id="tablet-menu-overlay" class="tablet-overlay">
            <div class="tablet-menu">
                <h2>📱 Máy Tính Bảng</h2>
                <div class="tablet-options">
                    <button class="tablet-btn" onclick="selectTabletOption('mdt')">
                        <i class="fas fa-file-shield"></i>
                        <span>Mở MDT</span>
                    </button>
                    <button class="tablet-btn" onclick="selectTabletOption('quick')">
                        <i class="fas fa-gavel"></i>
                        <span>Menu Kết Án Nhanh</span>
                    </button>
                </div>
                <button class="tablet-close-btn" onclick="closeTabletMenu()">
                    <i class="fas fa-times"></i> Đóng
                </button>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', menuHTML);
}

function selectTabletOption(option) {
    fetch(`https://${GetParentResourceName()}/tabletOption`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ option: option })
    });
    closeTabletMenu();
}

function closeTabletMenu() {
    const menu = document.getElementById('tablet-menu-overlay');
    if (menu) menu.remove();
    
    // Tắt NUI focus
    fetch(`https://${GetParentResourceName()}/closeTabletMenu`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// Export để có thể gọi từ script.js
window.closeTabletMenu = closeTabletMenu;
window.selectTabletOption = selectTabletOption;
window.showTabletMenu = showTabletMenu;
