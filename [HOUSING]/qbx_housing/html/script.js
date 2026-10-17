let currentHouse = null;

// Format number with commas
function formatMoney(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Get street name from coordinates (simplified)
function getStreetName(coords) {
    const streets = [
        'Americano Way', 'Vinewood Hills', 'Rockford Hills', 
        'Del Perro', 'Vespucci', 'Downtown', 'Little Seoul',
        'Mirror Park', 'Sandy Shores', 'Paleto Bay'
    ];
    return streets[Math.floor(Math.random() * streets.length)];
}

// Show housing UI
function showHousingUI(data) {
    currentHouse = data;
    
    // Update house info
    $('#houseType').text(data.typeLabel.toUpperCase());
    $('#houseId').text('#' + data.houseId.toUpperCase().replace('_', ''));
    $('#houseCategory').text(data.categoryLabel);
    $('#garageInfo').text(`Garage ${data.garageLabel} (${data.maxVehicles} chỗ)`);
    $('#location').text(`${data.maxSharedKeys + 1} người`);
    $('#storageInfo').text(`${data.storageSlots} slot / ${data.storageWeight/1000}kg`);
    $('#price').text(formatMoney(data.price));
    
    // Update owner display (hiển thị ngay dưới giá bán)
    if (data.isOwned) {
        $('#ownerDisplay').text(data.ownerName);
    } else {
        $('#ownerDisplay').text('Trống');
    }
    
    // Update image
    if (data.image) {
        $('#houseImage').attr('src', data.image);
    } else {
        // Thử tìm file jpg trước, nếu không có thì dùng svg
        $('#houseImage').attr('src', `images/${data.houseType}.png`)
            .on('error', function() {
                $(this).attr('src', `images/${data.houseType}.svg`);
            });
    }
    
    // Update buttons based on ownership and role
    if (data.isOwned) {
        if (data.isOwner) {
            // Change buttons for owner: Garage, Hòm thư, Quản lý, Vào nhà (4 buttons)
            $('#btnCash').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M19 20H5V8h14m0-5h-1V1h-2v2H8V1H6v2H5c-1.11 0-2 .89-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.11-.9-2-2-2m-2.47 8.06L15.47 10l-4.88 4.88-2.12-2.12-1.06 1.06L10.59 17l5.94-5.94z"/></svg>Garage');
            $('#btnCash').attr('data-action', 'garage');
            
            $('#btnMailbox').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg>Hòm thư');
            $('#btnMailbox').attr('data-action', 'mailbox');
            
            $('#btnBank').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z"/></svg>Quản lý');
            $('#btnBank').attr('data-action', 'manage');
            
            $('#btnPreview').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>Vào nhà');
            $('#btnPreview').attr('data-action', 'enter');
            
            // Show all 4 buttons for owner
            $('#btnCash, #btnMailbox, #btnBank, #btnPreview').show().prop('disabled', false).css('opacity', '1');
            $('.housing-actions').removeClass('single-button').addClass('four-buttons');
        } else if (data.hasKeys) {
            // Player có chìa khóa: CHỈ hiển thị button Vào nhà
            $('#btnCash, #btnMailbox, #btnBank').hide();
            
            $('#btnPreview').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>Vào nhà');
            $('#btnPreview').attr('data-action', 'enter');
            $('#btnPreview').show().prop('disabled', false).css('opacity', '1');
            
            // Add single-button class to center the button
            $('.housing-actions').addClass('single-button');
        } else {
            // Hide all buttons for non-owners of owned houses
            $('#btnCash, #btnMailbox, #btnBank, #btnPreview').hide();
            $('.housing-actions').removeClass('single-button').removeClass('four-buttons');
        }
    } else {
        // House is empty
        if (data.isRealestate) {
            // Realestate on duty: Chuyển nhượng, Mời thăm quan, Vào nhà
            $('#btnCash').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>Chuyển nhượng');
            $('#btnCash').attr('data-action', 'transfer');
            
            $('#btnBank').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M15 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm-9-2V7H4v3H1v2h3v3h2v-3h3v-2H6zm9 4c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>Mời thăm quan');
            $('#btnBank').attr('data-action', 'invite');
            
            $('#btnPreview').html('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>Vào nhà');
            $('#btnPreview').attr('data-action', 'enter');
            
            // Show all buttons for realestate
            $('#btnCash, #btnBank, #btnPreview').show().prop('disabled', false).css('opacity', '1');
            $('#btnMailbox').hide();
            $('.housing-actions').removeClass('single-button').removeClass('four-buttons');
        } else {
            // Regular player: hide all buttons, just show info
            $('#btnCash, #btnMailbox, #btnBank, #btnPreview').hide();
            $('.housing-actions').removeClass('single-button').removeClass('four-buttons');
        }
    }
    
    // Show UI
    $('#housingContainer').removeClass('hidden');
}

// Hide housing UI
function hideHousingUI() {
    $('#housingContainer').addClass('hidden');
    currentHouse = null;
}

// Button events
$('#btnCash').click(function() {
    if (!currentHouse) return;
    
    const action = $(this).attr('data-action') || 'cash';
    
    if (action === 'garage') {
        // Mở garage
        $.post('https://qbx_housing/openGarage', JSON.stringify({
            houseId: currentHouse.houseId
        }));
        hideHousingUI();
    } else if (action === 'transfer') {
        // Realestate: Chuyển nhượng nhà
        $.post('https://qbx_housing/transferHouse', JSON.stringify({
            houseId: currentHouse.houseId
        }));
        hideHousingUI();
    } else if (action === 'cash') {
        // Mua bằng tiền mặt
        $.post('https://qbx_housing/buyHouse', JSON.stringify({
            houseId: currentHouse.houseId,
            paymentType: 'cash'
        }));
        hideHousingUI();
    }
});

$('#btnBank').click(function() {
    if (!currentHouse) return;
    
    const action = $(this).attr('data-action') || 'bank';
    
    if (action === 'manage') {
        // Mở menu quản lý
        $.post('https://qbx_housing/manageHouse', JSON.stringify({
            houseId: currentHouse.houseId
        }));
        hideHousingUI();
    } else if (action === 'invite') {
        // Realestate: Mời thăm quan
        $.post('https://qbx_housing/inviteToHouse', JSON.stringify({
            houseId: currentHouse.houseId
        }));
        hideHousingUI();
    } else if (action === 'bank') {
        // Mua bằng chuyển khoản
        $.post('https://qbx_housing/buyHouse', JSON.stringify({
            houseId: currentHouse.houseId,
            paymentType: 'bank'
        }));
        hideHousingUI();
    }
});

$('#btnMailbox').click(function() {
    if (!currentHouse) return;
    
    const action = $(this).attr('data-action') || 'mailbox';
    
    if (action === 'mailbox') {
        // Mở hòm thư
        $.post('https://qbx_housing/openMailbox', JSON.stringify({
            houseId: currentHouse.houseId
        }));
        hideHousingUI();
    }
});

$('#btnPreview').click(function() {
    if (!currentHouse) return;
    
    const action = $(this).attr('data-action') || 'preview';
    
    if (action === 'enter') {
        // Vào nhà
        $.post('https://qbx_housing/enterHouse', JSON.stringify({
            houseId: currentHouse.houseId
        }));
        hideHousingUI();
    } else if (action === 'preview') {
        // Xem thử
        $.post('https://qbx_housing/previewHouse', JSON.stringify({
            houseId: currentHouse.houseId
        }));
    }
});

// Close UI on ESC
$(document).keyup(function(e) {
    if (e.key === "Escape") {
        // Don't close housing UI if admin frame is visible
        const adminFrame = document.getElementById('adminFrame');
        if (adminFrame && adminFrame.style.display === 'block') {
            return; // Let admin.js handle ESC
        }
        
        $.post('https://qbx_housing/closeUI', JSON.stringify({}));
        hideHousingUI();
    }
});

// Click outside to close
$('#housingContainer').click(function(e) {
    if (e.target === this) {
        $.post('https://qbx_housing/closeUI', JSON.stringify({}));
        hideHousingUI();
    }
});

// Message handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'showUI':
            showHousingUI(data.houseData);
            break;
        case 'hideUI':
            hideHousingUI();
            break;
        case 'updateHouse':
            if (currentHouse && currentHouse.houseId === data.houseData.houseId) {
                showHousingUI(data.houseData);
            }
            break;
    }
});

// Debug mode (comment out in production)
// For testing in browser
if (window.location.protocol === 'file:') {
    setTimeout(() => {
        showHousingUI({
            houseId: 'slum_1',
            houseType: 'slum',
            typeLabel: 'Nhà Ổ Chuột',
            categoryLabel: 'Căn hộ Luxury Seductive',
            garageLabel: 'cao cấp',
            maxVehicles: 12,
            storageSlots: 40,
            storageWeight: 130000,
            location: 'Americano Way',
            price: 59550000,
            isOwned: false,
            isOwner: false,
            ownerName: '',
            image: 'images/house-default.png'
        });
    }, 500);
}
