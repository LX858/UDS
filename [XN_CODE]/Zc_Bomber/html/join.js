let roomInfo = {};

$(document).ready(function() {
    console.log('[BOMBER] Join.js loaded');
    
    // Lắng nghe sự kiện từ client
    window.addEventListener('message', function(event) {
        const data = event.data;
        console.log('[BOMBER] Join received message:', data);
        
        if (data.type === 'openJoinPanel') {
            roomInfo = data.roomInfo || {};
            updateJoinUI();
            $('#joinPanel').addClass('show');
        } else if (data.type === 'closeJoinPanel') {
            $('#joinPanel').removeClass('show');
        } else if (data.type === 'refreshJoinPanel') {
            roomInfo = data.roomInfo || roomInfo || {};
            updateJoinUI();
        } else if (data.type === 'updateRoomData') {
            roomInfo = data.data || roomInfo || {};
            updateJoinUI();
        }
    });

    // Nút tham gia
    $('#btnJoin').click(function() {
        console.log('[BOMBER] Join button clicked');
        $.post('https://' + GetParentResourceName() + '/joinEvent', JSON.stringify({}));
        $('#joinPanel').removeClass('show');
    });

    // Nút hủy
    $('#btnCancel').click(function() {
        console.log('[BOMBER] Cancel button clicked');
        $.post('https://' + GetParentResourceName() + '/cancelJoin', JSON.stringify({}));
        $('#joinPanel').removeClass('show');
    });

    $('#btnRefreshPlayers').click(function() {
        $.post('https://' + GetParentResourceName() + '/requestRoomPlayers', JSON.stringify({}));
    });

    window.setInterval(function() {
        if ($('#joinPanel').hasClass('show')) {
            $.post('https://' + GetParentResourceName() + '/requestRoomPlayers', JSON.stringify({}));
        }
    }, 1500);

    // ESC để đóng
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            $.post('https://' + GetParentResourceName() + '/cancelJoin', JSON.stringify({}));
            $('#joinPanel').removeClass('show');
        }
    });
});

function updateJoinUI() {
    $('#joinEntryFee').text(roomInfo.entryFee || 0);

    const list = $('#joinPlayerList');
    const players = Array.isArray(roomInfo.players) ? roomInfo.players : Object.values(roomInfo.players || {});
    const isAlreadyJoined = !!roomInfo.alreadyJoined;

    if (isAlreadyJoined) {
        $('#joinActionArea').hide();
        $('#joinModeLabel').text('Bạn đã tham gia phòng này');
    } else {
        $('#joinActionArea').show();
        $('#joinModeLabel').text('Xem danh sách phòng hiện tại');
    }

    console.log('[BOMBER] join players:', players.length, players);

    if (players.length === 0) {
        list.html('<div class="join-player-empty">Chưa có người chơi tham gia</div>');
        return;
    }

    let html = '';
    players.forEach((player, index) => {
        html += `<div class="join-player-item">
            <div class="join-player-num">${index + 1}</div>
            <div class="join-player-name">${player.name}</div>
        </div>`;
    });
    list.html(html);
}

function GetParentResourceName() {
    return 'Zc_Bomber';
}
