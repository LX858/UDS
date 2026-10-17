// ===== STATE =====
let currentMotelData = null;
let currentServerTime = 0;
let myRoomData = null;
let timerInterval = null;
let isClosing = false;
let resourceName = 'xn_motels';
let ownerData = null; // { isOwner, isEmployee, revenue, hourRate, employees, rooms }
let currentOwnerRoomIndex = null;

// ===== SOUND =====
function playsound(table) {
    var file = table['file'];
    var volume = table['volume'];
    if (volume == undefined) volume = 0.5;
    var audioPlayer = new Audio("./audio/" + file + ".ogg");
    audioPlayer.volume = volume;
    audioPlayer.play();
}

// ===== TIME FORMAT =====
function formatTimeRemaining(seconds) {
    if (seconds <= 0) return 'Hết hạn';
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    if (days > 0) return `${days} ngày ${hours} giờ`;
    if (hours > 0) return `${hours} giờ ${minutes} phút`;
    if (minutes > 0) return `${minutes} phút ${secs} giây`;
    return `${secs} giây`;
}

// ===== TIMER =====
function updateTimer() {
    if (!myRoomData) return;
    currentServerTime += 1;
    const remaining = myRoomData.expiresAt - currentServerTime;
    document.getElementById('time-left').textContent = formatTimeRemaining(remaining);
    if (remaining <= 0) {
        clearInterval(timerInterval);
        timerInterval = null;
        document.getElementById('my-room-section').classList.add('hidden');
        myRoomData = null;
        renderRooms();
    }
}

// ===== TAB SWITCHING =====
function switchTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
    document.getElementById('tab-' + tab).classList.remove('hidden');
    document.getElementById('tab-' + tab + '-btn').classList.add('active');
}

// ===== RENDER ROOMS (Tenant Tab) =====
function renderRooms() {
    if (!currentMotelData || !currentMotelData.rooms) return;
    const grid = document.getElementById('rooms-grid');
    grid.innerHTML = '';
    const rooms = currentMotelData.rooms;
    const hasRoom = myRoomData !== null && myRoomData !== undefined;
    rooms.forEach(room => {
        const isRented = room.status === 'rented';
        const isMyRoom = myRoomData && myRoomData.roomNumber == room.number;
        const showRentButton = !isRented && !hasRoom;
        const roomCard = document.createElement('div');
        roomCard.className = `room-item ${isRented ? 'rented' : ''} ${isMyRoom ? 'my-room-item' : ''}`;
        roomCard.innerHTML = `
            <h3>Phòng #${room.number}</h3>
            <span class="status ${isRented ? 'rented' : 'available'}">
                ${isMyRoom ? '⭐ Phòng Tôi' : (isRented ? 'Đã Thuê' : 'Trống')}
            </span>
            ${showRentButton ? `
                <button class="btn-rent available" onclick="openRentDialog(${room.number})">
                    Thuê Ngay
                </button>
            ` : `
                <button class="btn-rent rented" disabled>
                    ${isMyRoom ? 'Đang Thuê' : (isRented ? 'Không Khả Dụng' : 'Bạn Đã Có Phòng')}
                </button>
            `}
        `;
        grid.appendChild(roomCard);
    });
}

// ===== RENDER OWNER DASHBOARD =====
function renderOwnerDashboard() {
    if (!ownerData) return;
    const { isOwner, isEmployee, revenue, hourRate, employees, rooms } = ownerData;

    // Update tab visibility
    const ownerTabBtn = document.getElementById('tab-owner-btn');
    if (isOwner || isEmployee) {
        ownerTabBtn.style.display = '';
    } else {
        ownerTabBtn.style.display = 'none';
    }

    if (!currentMotelData || !currentMotelData.rooms) return;
    const totalRooms = currentMotelData.rooms.length;
    const rentedRooms = currentMotelData.rooms.filter(r => r.status === 'rented').length;

    if (isOwner) {
        document.getElementById('owner-buy-section').classList.add('hidden');
        document.getElementById('employee-dashboard-section').classList.add('hidden');
        document.getElementById('owner-dashboard-section').classList.remove('hidden');

        document.getElementById('owner-revenue').textContent = '$' + (revenue || 0).toLocaleString();
        document.getElementById('stat-total-rooms').textContent = totalRooms;
        document.getElementById('stat-rented-rooms').textContent = rentedRooms;
        document.getElementById('stat-empty-rooms').textContent = totalRooms - rentedRooms;
        document.getElementById('withdraw-available').textContent = '$' + (revenue || 0).toLocaleString();
        document.getElementById('current-rate').textContent = '$' + (hourRate || 0).toLocaleString() + '/ngày';

    } else if (isEmployee) {
        document.getElementById('owner-buy-section').classList.add('hidden');
        document.getElementById('owner-dashboard-section').classList.add('hidden');
        document.getElementById('employee-dashboard-section').classList.remove('hidden');

    } else if (ownerData.motelNotOwned) {
        // Motel not owned - show buy option
        document.getElementById('owner-dashboard-section').classList.add('hidden');
        document.getElementById('employee-dashboard-section').classList.add('hidden');
        document.getElementById('owner-buy-section').classList.remove('hidden');

        document.getElementById('buy-room-count').textContent = totalRooms + ' phòng';
        document.getElementById('buy-price').textContent = '$' + (ownerData.businessPrice || 0).toLocaleString();
        document.getElementById('sell-price').textContent = '$' + Math.floor((ownerData.businessPrice || 0) / 2).toLocaleString();

        // Show owner tab for buy option
        ownerTabBtn.style.display = '';
    }
}

// ===== OPEN UI =====
function openUI(data) {
    console.log('[MOTEL] Opening UI with data:', data);
    isClosing = false;

    if (data.resourceName) resourceName = data.resourceName;

    currentMotelData = {
        motel: data.motelId,
        rooms: data.rooms,
        rate: data.dayRate
    };
    currentServerTime = data.serverTime;
    myRoomData = data.myRoom;
    ownerData = data.ownerData || null;

    // Title
    document.getElementById('motel-title').textContent = data.motelName || 'MOTEL';

    // My room section
    if (myRoomData) {
        document.getElementById('my-room-section').classList.remove('hidden');
        document.getElementById('my-room-number').textContent = myRoomData.roomNumber;
        if (timerInterval) clearInterval(timerInterval);
        updateTimer();
        timerInterval = setInterval(updateTimer, 1000);
    } else {
        document.getElementById('my-room-section').classList.add('hidden');
    }

    renderRooms();
    renderOwnerDashboard();

    // Default tab to tenant
    switchTab('tenant');

    // Show UI
    document.getElementById('motel-container').classList.remove('hidden');
}

// ===== CLOSE UI =====
function closeUI() {
    if (isClosing) return;
    isClosing = true;
    if (timerInterval) { clearInterval(timerInterval); timerInterval = null; }
    document.getElementById('motel-container').classList.add('hidden');
    fetch(`https://${resourceName}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(() => {});
    setTimeout(() => { isClosing = false; }, 300);
}

// ===== ESC KEY =====
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        const dialogs = [
            'renew-dialog', 'rent-dialog', 'checkout-dialog', 'withdraw-dialog',
            'edit-rate-dialog', 'invoice-dialog', 'transfer-dialog', 'sell-dialog',
            'owner-rooms-dialog', 'occupants-dialog', 'employee-dialog'
        ];
        for (const id of dialogs) {
            const el = document.getElementById(id);
            if (el && !el.classList.contains('hidden')) {
                el.classList.add('hidden');
                return;
            }
        }
        const container = document.getElementById('motel-container');
        if (!container.classList.contains('hidden')) closeUI();
    }
});

// ===== TENANT: RENEW =====
function openRenewDialog() {
    if (!myRoomData) return;
    document.getElementById('renew-dialog').classList.remove('hidden');
    const inp = document.getElementById('renew-days');
    inp.value = 1;
    updateRenewPrice();
    inp.oninput = updateRenewPrice;
}
function closeRenewDialog() { document.getElementById('renew-dialog').classList.add('hidden'); }
function updateRenewPrice() {
    const days = parseInt(document.getElementById('renew-days').value) || 0;
    const rate = currentMotelData?.rate || 1000;
    document.getElementById('renew-price').textContent = `$${(days * rate).toLocaleString()}`;
}
function confirmRenew() {
    const days = parseInt(document.getElementById('renew-days').value);
    if (days < 1) return;
    fetch(`https://${resourceName}/renewRoom`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ days })
    }).then(r => r.json()).then(() => { closeRenewDialog(); setTimeout(closeUI, 300); }).catch(() => { closeRenewDialog(); closeUI(); });
}

// ===== TENANT: RENT =====
let selectedRoomToRent = null;
function openRentDialog(roomIndex) {
    selectedRoomToRent = roomIndex;
    document.getElementById('rent-room-number').textContent = roomIndex;
    document.getElementById('rent-dialog').classList.remove('hidden');
    const inp = document.getElementById('rent-days');
    inp.value = 1;
    updateRentPrice();
    inp.oninput = updateRentPrice;
}
function closeRentDialog() { document.getElementById('rent-dialog').classList.add('hidden'); selectedRoomToRent = null; }
function updateRentPrice() {
    const days = parseInt(document.getElementById('rent-days').value) || 0;
    const rate = currentMotelData?.rate || 1000;
    document.getElementById('rent-price').textContent = `$${(days * rate).toLocaleString()}`;
}
function confirmRent() {
    const days = parseInt(document.getElementById('rent-days').value);
    const payment = document.getElementById('payment-method').value;
    if (days < 1) return;
    fetch(`https://${resourceName}/rentRoom`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, roomIndex: selectedRoomToRent, days, paymentMethod: payment })
    }).then(r => r.json()).then(() => { closeRentDialog(); setTimeout(closeUI, 300); }).catch(() => { closeRentDialog(); closeUI(); });
}

// ===== TENANT: CHECKOUT =====
function openCheckoutDialog() { document.getElementById('checkout-dialog').classList.remove('hidden'); }
function closeCheckoutDialog() { document.getElementById('checkout-dialog').classList.add('hidden'); }
function confirmCheckout() {
    fetch(`https://${resourceName}/checkoutRoom`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel })
    }).then(r => r.json()).then(() => { closeCheckoutDialog(); setTimeout(closeUI, 300); }).catch(() => { closeCheckoutDialog(); closeUI(); });
}

// ===== OWNER: BUY MOTEL =====
function confirmBuyMotel() {
    fetch(`https://${resourceName}/buyMotel`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel })
    }).then(r => r.json()).then(() => { setTimeout(closeUI, 300); }).catch(() => closeUI());
}

// ===== OWNER: WITHDRAW =====
function openWithdrawDialog() {
    document.getElementById('withdraw-available').textContent = '$' + ((ownerData && ownerData.revenue) || 0).toLocaleString();
    document.getElementById('withdraw-amount').value = 0;
    document.getElementById('withdraw-dialog').classList.remove('hidden');
}
function closeWithdrawDialog() { document.getElementById('withdraw-dialog').classList.add('hidden'); }
function confirmWithdraw() {
    const amount = parseInt(document.getElementById('withdraw-amount').value);
    if (!amount || amount < 1) return;
    fetch(`https://${resourceName}/withdrawFund`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, amount })
    }).then(r => r.json()).then(() => { closeWithdrawDialog(); setTimeout(closeUI, 300); }).catch(() => { closeWithdrawDialog(); closeUI(); });
}

// ===== OWNER: EDIT RATE =====
function openEditRateDialog() {
    document.getElementById('current-rate').textContent = '$' + ((ownerData && ownerData.hourRate) || 0).toLocaleString() + '/ngày';
    document.getElementById('new-rate').value = (ownerData && ownerData.hourRate) || 0;
    document.getElementById('edit-rate-dialog').classList.remove('hidden');
}
function closeEditRateDialog() { document.getElementById('edit-rate-dialog').classList.add('hidden'); }
function confirmEditRate() {
    const rate = parseInt(document.getElementById('new-rate').value);
    if (!rate || rate < 1) return;
    fetch(`https://${resourceName}/editRate`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, rate })
    }).then(r => r.json()).then(() => { closeEditRateDialog(); setTimeout(closeUI, 300); }).catch(() => { closeEditRateDialog(); closeUI(); });
}

// ===== OWNER: SEND INVOICE =====
function openSendInvoiceDialog() {
    document.getElementById('invoice-pid').value = '';
    document.getElementById('invoice-amount').value = 0;
    document.getElementById('invoice-desc').value = '';
    document.getElementById('invoice-dialog').classList.remove('hidden');
}
function closeInvoiceDialog() { document.getElementById('invoice-dialog').classList.add('hidden'); }
function confirmSendInvoice() {
    const pid = parseInt(document.getElementById('invoice-pid').value);
    const amount = parseInt(document.getElementById('invoice-amount').value);
    const desc = document.getElementById('invoice-desc').value;
    const payment = document.getElementById('invoice-payment').value;
    if (!pid || !amount || amount < 1) return;
    fetch(`https://${resourceName}/sendInvoice`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, pid, amount, desc, payment })
    }).then(r => r.json()).then(() => { closeInvoiceDialog(); setTimeout(closeUI, 300); }).catch(() => { closeInvoiceDialog(); closeUI(); });
}

// ===== OWNER: TRANSFER =====
function openTransferDialog() {
    document.getElementById('transfer-pid').value = '';
    document.getElementById('transfer-dialog').classList.remove('hidden');
}
function closeTransferDialog() { document.getElementById('transfer-dialog').classList.add('hidden'); }
function confirmTransfer() {
    const pid = parseInt(document.getElementById('transfer-pid').value);
    if (!pid) return;
    fetch(`https://${resourceName}/transferMotel`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, pid })
    }).then(r => r.json()).then(() => { closeTransferDialog(); setTimeout(closeUI, 300); }).catch(() => { closeTransferDialog(); closeUI(); });
}

// ===== OWNER: SELL =====
function openSellDialog() {
    const sellVal = ownerData && ownerData.businessPrice ? Math.floor(ownerData.businessPrice / 2) : 0;
    document.getElementById('sell-price').textContent = '$' + sellVal.toLocaleString();
    document.getElementById('sell-dialog').classList.remove('hidden');
}
function closeSellDialog() { document.getElementById('sell-dialog').classList.add('hidden'); }
function confirmSell() {
    fetch(`https://${resourceName}/sellMotel`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel })
    }).then(r => r.json()).then(() => { closeSellDialog(); setTimeout(closeUI, 300); }).catch(() => { closeSellDialog(); closeUI(); });
}

// ===== OWNER: ROOMS PANEL =====
function openOwnerRoomsPanel() {
    const grid = document.getElementById('owner-rooms-grid');
    grid.innerHTML = '';
    if (!currentMotelData || !currentMotelData.rooms) return;
    currentMotelData.rooms.forEach(room => {
        const isRented = room.status === 'rented';
        const div = document.createElement('div');
        div.className = `owner-room-card ${isRented ? 'rented' : 'empty'}`;
        div.innerHTML = `
            <span class="or-number">Phòng #${room.number}</span>
            <span class="or-status ${isRented ? 'rented' : 'empty'}">${isRented ? '✅ Đang Thuê' : '⭕ Trống'}</span>
            <button class="or-manage-btn" onclick="openOccupantsDialog(${room.number})">Quản Lý</button>
        `;
        grid.appendChild(div);
    });
    document.getElementById('owner-rooms-dialog').classList.remove('hidden');
}
function closeOwnerRoomsDialog() { document.getElementById('owner-rooms-dialog').classList.add('hidden'); }

// ===== OWNER: OCCUPANTS DIALOG =====
function openOccupantsDialog(roomIndex) {
    currentOwnerRoomIndex = roomIndex;
    document.getElementById('occ-room-number').textContent = roomIndex;
    document.getElementById('add-occ-pid').value = '';
    document.getElementById('add-occ-days').value = 1;
    // Fetch fresh occupant list
    fetch(`https://${resourceName}/getOccupants`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, roomIndex })
    }).then(r => r.json()).then(data => {
        renderOccupants(data.occupants || []);
    }).catch(() => renderOccupants([]));
    document.getElementById('occupants-dialog').classList.remove('hidden');
}
function renderOccupants(occupants) {
    const list = document.getElementById('occupants-list');
    list.innerHTML = '';
    if (!occupants.length) {
        list.innerHTML = '<p style="color:rgba(255,255,255,0.5);text-align:center;">Phòng trống</p>';
        return;
    }
    occupants.forEach(occ => {
        const div = document.createElement('div');
        div.className = 'occ-item';
        div.innerHTML = `
            <span>${occ.name || 'Người thuê'}</span>
            <button class="occ-kick-btn" onclick="kickOccupant('${occ.identifier}')">Đá</button>
        `;
        list.appendChild(div);
    });
}
function closeOccupantsDialog() { document.getElementById('occupants-dialog').classList.add('hidden'); currentOwnerRoomIndex = null; }
function kickOccupant(identifier) {
    fetch(`https://${resourceName}/kickOccupant`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, roomIndex: currentOwnerRoomIndex, identifier })
    }).then(r => r.json()).then(() => { closeOccupantsDialog(); closeOwnerRoomsDialog(); setTimeout(closeUI, 300); }).catch(() => closeUI());
}
function confirmAddOccupant() {
    const pid = parseInt(document.getElementById('add-occ-pid').value);
    const days = parseInt(document.getElementById('add-occ-days').value);
    if (!pid || !days || days < 1) return;
    fetch(`https://${resourceName}/addOccupant`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, roomIndex: currentOwnerRoomIndex, pid, days })
    }).then(r => r.json()).then(() => { closeOccupantsDialog(); closeOwnerRoomsDialog(); setTimeout(closeUI, 300); }).catch(() => closeUI());
}

// ===== OWNER: EMPLOYEES =====
function openEmployeePanel() {
    const list = document.getElementById('employee-list');
    list.innerHTML = '';
    const employees = (ownerData && ownerData.employees) || {};
    const keys = Object.keys(employees);
    if (!keys.length) {
        list.innerHTML = '<p style="color:rgba(255,255,255,0.5);text-align:center;margin-bottom:10px;">Chưa có nhân viên</p>';
    } else {
        keys.forEach(id => {
            const div = document.createElement('div');
            div.className = 'occ-item';
            div.innerHTML = `
                <span>${employees[id]}</span>
                <button class="occ-kick-btn" onclick="removeEmployee('${id}')">Xóa</button>
            `;
            list.appendChild(div);
        });
    }
    document.getElementById('emp-pid').value = '';
    document.getElementById('employee-dialog').classList.remove('hidden');
}
function closeEmployeeDialog() { document.getElementById('employee-dialog').classList.add('hidden'); }
function removeEmployee(identifier) {
    fetch(`https://${resourceName}/removeEmployee`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, identifier })
    }).then(r => r.json()).then(() => { closeEmployeeDialog(); setTimeout(closeUI, 300); }).catch(() => closeUI());
}
function confirmAddEmployee() {
    const pid = parseInt(document.getElementById('emp-pid').value);
    if (!pid) return;
    fetch(`https://${resourceName}/addEmployee`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ motel: currentMotelData.motel, pid })
    }).then(r => r.json()).then(() => { closeEmployeeDialog(); setTimeout(closeUI, 300); }).catch(() => closeUI());
}

// ===== MESSAGE LISTENER =====
window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.type) {
        case 'openUI':
            openUI(data);
            break;
        case 'closeUI':
            closeUI();
            break;
        case 'playsound':
            playsound(data.content);
            break;
        case 'door':
            document.getElementById('door').innerHTML = `
                <video autoplay id="myVideo">
                    <source src="audio/door.mp4" type="video/mp4">
                </video>
            `;
            setTimeout(() => { document.getElementById('door').innerHTML = ''; }, 7000);
            break;
    }
});
