// Global variables
let currentData = null;
let selectedRod = null;

// DOM elements
const fishingPanel = document.getElementById('fishing-panel');
const closeBtn = document.getElementById('close-btn');
const playerNameEl = document.getElementById('player-name');
const playerLevelEl = document.getElementById('player-level');
const progressFill = document.getElementById('progress-fill');
const currentXPEl = document.getElementById('current-xp');
const nextLevelXPEl = document.getElementById('next-level-xp');
const currentRodsGrid = document.getElementById('current-rods-grid');
const zonesListEl = document.getElementById('zones-list');

// Event listeners
document.addEventListener('DOMContentLoaded', function () {
    closeBtn.addEventListener('click', closePanel);

    window.addEventListener('message', function (event) {
        const data = event.data;
        switch (data.action) {
            case 'openPanel': openPanel(data.data); break;
            case 'closePanel': closePanel(); break;
            case 'updateData': updatePanelData(data.data); break;
        }
    });

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') closePanel();
    });
});

// Open panel
function openPanel(data) {
    currentData = data;
    updatePanelData(data);
    fishingPanel.classList.add('active');
    fetch('https://xn_cauca/panelOpened', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Close panel
function closePanel() {
    fishingPanel.classList.remove('active');
    selectedRod = null;
    document.querySelectorAll('.rod-slot').forEach(s => s.classList.remove('selected'));
    fetch('https://xn_cauca/panelClosed', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Update all panel data
function updatePanelData(data) {
    if (!data) return;
    currentData = data;

    // Player info
    playerNameEl.textContent = data.playerName || 'Unknown';
    playerLevelEl.textContent = data.level || 1;

    const progressPercent = ((data.currentXP || 0) / (data.nextLevelXP || 100)) * 100;
    progressFill.style.width = Math.min(progressPercent, 100) + '%';
    currentXPEl.textContent = data.currentXP || 0;
    nextLevelXPEl.textContent = data.nextLevelXP || 100;

    // Rods
    updateCurrentRods(data.currentRods || []);

    // Zones
    renderAllZones(data.allZones || [], data.currentZoneName || null, data.currentXP || 0);
}

// ─── Render ALL fishing zones ────────────────────────────────────────────────
function renderAllZones(zones, currentZoneName, playerXP) {
    zonesListEl.innerHTML = '';

    if (!zones || zones.length === 0) {
        zonesListEl.innerHTML = '<p style="color:rgba(255,255,255,0.3);font-size:11px;text-align:center">Không có dữ liệu khu vực</p>';
        return;
    }

    zones.forEach(zone => {
        const isActive = zone.name === currentZoneName;
        const isLocked = playerXP < (zone.requiredXP || 0);

        const card = document.createElement('div');
        let cardClass = 'zone-card';
        if (isActive) cardClass += ' active';
        else if (isLocked) cardClass += ' locked';
        card.className = cardClass;

        // ── Top row: label + XP badge ──
        const topRow = document.createElement('div');
        topRow.className = 'zone-card-top';

        const labelEl = document.createElement('span');
        labelEl.className = 'zone-card-label';
        labelEl.textContent = zone.label || zone.name;

        const rightEl = document.createElement('div');
        rightEl.style.display = 'flex';
        rightEl.style.alignItems = 'center';
        rightEl.style.gap = '6px';

        // "YOU ARE HERE" blink badge
        if (isActive) {
            const hereBadge = document.createElement('span');
            hereBadge.className = 'zone-here-badge';
            hereBadge.textContent = '📍 ĐANG Ở ĐÂY';
            rightEl.appendChild(hereBadge);
        }

        // XP requirement badge
        const xpBadge = document.createElement('span');
        if (isActive) {
            xpBadge.className = 'zone-xp-badge current';
            xpBadge.textContent = zone.requiredXP === 0 ? '✓ Mở khoá' : `✓ ${zone.requiredXP} XP`;
        } else if (isLocked) {
            xpBadge.className = 'zone-xp-badge locked';
            xpBadge.textContent = `🔒 ${zone.requiredXP} XP`;
        } else {
            xpBadge.className = 'zone-xp-badge unlocked';
            xpBadge.textContent = zone.requiredXP === 0 ? '✓ Mở khoá' : `✓ ${zone.requiredXP} XP`;
        }
        rightEl.appendChild(xpBadge);

        topRow.appendChild(labelEl);
        topRow.appendChild(rightEl);
        card.appendChild(topRow);

        // ── Fish row ──
        const fishRow = document.createElement('div');
        fishRow.className = 'zone-card-row';

        const fishLabel = document.createElement('div');
        fishLabel.className = 'zone-row-label';
        fishLabel.textContent = '🐟 Cá có thể câu';
        fishRow.appendChild(fishLabel);

        const fishTags = document.createElement('div');
        fishTags.className = 'zone-tags';
        const fishList = Array.isArray(zone.fish) ? zone.fish : [];
        if (fishList.length === 0) {
            fishTags.innerHTML = '<span style="opacity:0.3;font-size:10px">—</span>';
        } else {
            fishList.forEach(f => {
                const tag = document.createElement('div');
                tag.className = 'zone-tag fish tooltip';
                tag.setAttribute('data-tooltip', prettifyName(f));
                tag.innerHTML = `
                    <img src="https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main//${f}.webp" 
                         alt="${prettifyName(f)}" 
                         onerror="this.src='https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main//default.webp'">
                `;
                fishTags.appendChild(tag);
            });
        }
        fishRow.appendChild(fishTags);
        card.appendChild(fishRow);

        // ── Rods row ──
        const rodsRow = document.createElement('div');
        rodsRow.className = 'zone-card-row';

        const rodsLabel = document.createElement('div');
        rodsLabel.className = 'zone-row-label';
        rodsLabel.textContent = '🎣 Cần câu phù hợp';
        rodsRow.appendChild(rodsLabel);

        const rodsTags = document.createElement('div');
        rodsTags.className = 'zone-tags';
        const rodsList = Array.isArray(zone.allowedRods) ? zone.allowedRods : [];
        if (rodsList.length === 0) {
            rodsTags.innerHTML = '<span style="opacity:0.3;font-size:10px">—</span>';
        } else {
            rodsList.forEach(r => {
                const tag = document.createElement('div');
                tag.className = 'zone-tag rod tooltip';
                tag.setAttribute('data-tooltip', prettifyName(r));
                tag.innerHTML = `
                    <img src="https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main//${r}.webp" 
                         alt="${prettifyName(r)}" 
                         onerror="this.src='https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main//default.webp'">
                `;
                rodsTags.appendChild(tag);
            });
        }
        rodsRow.appendChild(rodsTags);
        card.appendChild(rodsRow);

        zonesListEl.appendChild(card);
    });
}

// ─── Prettify item names ─────────────────────────────────────────────────────
function prettifyName(name) {
    return name
        .replace(/_/g, ' ')
        .replace(/\b\w/g, c => c.toUpperCase());
}

// ─── Update current rods display ─────────────────────────────────────────────
function updateCurrentRods(rods) {
    currentRodsGrid.innerHTML = '';

    for (let i = 0; i < 10; i++) {
        const slot = document.createElement('div');
        slot.className = 'rod-slot';

        if (rods[i]) {
            const rod = rods[i];
            const doHiem = rod.doHiem || rod.metadata?.DoHiem || 'Common';
            const tier = rod.tier || rod.metadata?.tier || 1;
            const rarityClass = doHiem.toLowerCase();
            const durability = rod.durability !== undefined ? rod.durability : 100;
            const tooltipText = `${rod.label}\nSố lượng: ${rod.count}x\nĐộ hiếm: ${doHiem}\nTier: ${tier}\nĐộ bền: ${durability.toFixed(1)}%\nSlot: ${rod.slot || 'N/A'}`;

            slot.innerHTML = `
                <div class="rod-item ${rarityClass}">
                    <img src="https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main//${rod.item}.webp"
                         alt="${rod.label}"
                         onerror="this.src='https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main//default.webp'">
                </div>
            `;
            slot.setAttribute('data-tooltip', tooltipText);
            slot.classList.add('tooltip');
            slot.addEventListener('click', () => selectRod(rod, slot));
        } else {
            slot.classList.add('empty');
        }

        currentRodsGrid.appendChild(slot);
    }
}

// ─── Select rod ──────────────────────────────────────────────────────────────
function selectRod(rod, slotEl) {
    selectedRod = rod;
    document.querySelectorAll('.rod-slot').forEach(s => s.classList.remove('selected'));
    slotEl.classList.add('selected');
}

// ─── Utilities ───────────────────────────────────────────────────────────────
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
