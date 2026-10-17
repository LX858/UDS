let selectedMaxPlayers = 20;
let selectedMap = 'map1';
let roomData = {
    status: 'idle',
    players: [],
    maxPlayers: 20,
    map: 'map1',
    winner: null
};

$(document).ready(function() {
    // Lắng nghe sự kiện từ client
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === 'openAdminPanel') {
            roomData = data.data;
            $('#adminPanel').addClass('show');
            updateUI();
        } else if (data.type === 'closeAdminPanel') {
            $('#adminPanel').removeClass('show');
        } else if (data.type === 'updateRoomData') {
            roomData = data.data;
            updateUI();
        } else if (data.type === 'updatePlayerList') {
            roomData.players = data.players;
            updatePlayerList();
        } else if (data.type === 'updateStatus') {
            roomData.status = data.status;
            updateStatus();
        } else if (data.type === 'showWinner') {
            showWinner(data.winner);
        } else if (data.type === 'adminFollowStopped') {
            followingSource = null;
            updatePlayerList();
        } else if (data.type === 'adminFollowSwitch') {
            followingSource = data.source;
            updatePlayerList();
        } else if (data.type === 'openJoinPanel') {
            updateAdminJoinInfo(data.roomInfo);
            $('#joinPanel').addClass('show');
        } else if (data.type === 'closeJoinPanel') {
            $('#joinPanel').removeClass('show');
        }
    });

    // Chọn số người
    $('.player-count-btn').click(function() {
        $('.player-count-btn').removeClass('active');
        $(this).addClass('active');
        selectedMaxPlayers = parseInt($(this).data('count'));
        roomData.maxPlayers = selectedMaxPlayers;
        updateUI();
    });

    // Chọn map
    $('#mapSelect').change(function() {
        selectedMap = $(this).val();
        roomData.map = selectedMap;
        updateUI();
    });

    // Nút tạo phòng
    $('#btnCreate').click(function() {
        const waitTime = parseInt($('#waitTime').val());
        const entryFee = parseInt($('#entryFee').val());
        const autoNotify = $('#autoNotify').is(':checked');
        
        $.post('https://' + GetParentResourceName() + '/createRoom', JSON.stringify({
            maxPlayers: selectedMaxPlayers,
            map: selectedMap,
            waitTime: waitTime,
            entryFee: entryFee,
            autoNotify: autoNotify
        }));
        
        $('#btnCreate').prop('disabled', true);
        $('#btnStart').prop('disabled', false);
    });

    // Nút bắt đầu
    $('#btnStart').click(function() {
        $.post('https://' + GetParentResourceName() + '/startBomberEvent', JSON.stringify({}));
        
        $('#btnStart').prop('disabled', true);
        $('#btnStop').prop('disabled', false);
    });

    // Nút dừng
    $('#btnStop').click(function() {
        $.post('https://' + GetParentResourceName() + '/stopBomberEvent', JSON.stringify({}));
        
        $('#btnCreate').prop('disabled', false);
        $('#btnStart').prop('disabled', true);
        $('#btnStop').prop('disabled', true);
    });

    // Nút đóng
    $('#btnClose').click(function() {
        $.post('https://' + GetParentResourceName() + '/closeAdminPanel', JSON.stringify({}));
        $('#adminPanel').removeClass('show');
    });

    // Nút thông báo bắt đầu
    $('#btnNotifyStart').click(function() {
        $.post('https://' + GetParentResourceName() + '/sendNotificationStart', JSON.stringify({}));
    });

    // Nút thông báo kết thúc
    $('#btnNotifyEnd').click(function() {
        $.post('https://' + GetParentResourceName() + '/sendNotificationEnd', JSON.stringify({}));
    });

    // ESC để đóng
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            if ($('#adminPanel').hasClass('show')) {
                $.post('https://' + GetParentResourceName() + '/closeAdminPanel', JSON.stringify({}));
                $('#adminPanel').removeClass('show');
            }
            if ($('#joinPanel').hasClass('show')) {
                $.post('https://' + GetParentResourceName() + '/cancelJoin', JSON.stringify({}));
                $('#joinPanel').removeClass('show');
            }
        }
    });

    // Join panel buttons
    $('#btnJoin').click(function() {
        $.post('https://' + GetParentResourceName() + '/joinEvent', JSON.stringify({}));
        $('#joinPanel').removeClass('show');
    });

    $('#btnCancelJoin').click(function() {
        $.post('https://' + GetParentResourceName() + '/cancelJoin', JSON.stringify({}));
        $('#joinPanel').removeClass('show');
    });
});

function updateUI() {
    // Normalize players
    roomData.players = Array.isArray(roomData.players) ? roomData.players : Object.values(roomData.players || {});
    
    // Cập nhật thông tin phòng
    $('#playerCount').text(roomData.players.length + ' / ' + roomData.maxPlayers);
    
    const mapNames = {
        'map1': 'Map 1 - Đảo Sandy Shores',
        'map2': 'Map 2 - Sân Golf',
        'map3': 'Map 3 - Sân Bay Quân Sự',
        'map4': 'Map 4 - Bãi Biển Del Perro'
    };
    $('#currentMap').text(mapNames[roomData.map] || 'Chưa chọn');
    
    // Cập nhật trạng thái nút dựa vào roomData.status
    if (roomData.status === 'idle') {
        $('#btnCreate').prop('disabled', false);
        $('#btnStart').prop('disabled', true);
        $('#btnStop').prop('disabled', true);
    } else if (roomData.status === 'waiting') {
        $('#btnCreate').prop('disabled', true);
        $('#btnStart').prop('disabled', false);
        $('#btnStop').prop('disabled', true);
    } else if (roomData.status === 'running') {
        $('#btnCreate').prop('disabled', true);
        $('#btnStart').prop('disabled', true).css('opacity', '0.5');
        $('#btnStop').prop('disabled', false);
    }
    
    updateStatus();
    updatePlayerList();
}

function updateStatus() {
    const statusBadge = $('#roomStatus');
    statusBadge.removeClass('status-idle status-waiting status-running');
    
    if (roomData.status === 'waiting') {
        statusBadge.addClass('status-waiting').text('Đang chờ');
    } else if (roomData.status === 'running') {
        statusBadge.addClass('status-running').text('Đang chơi');
    } else {
        statusBadge.addClass('status-idle').text('Đang chờ');
    }
}

let followingSource = null;

function updatePlayerList() {
    const playerList = $('#playerList');
    const players = Array.isArray(roomData.players) ? roomData.players : Object.values(roomData.players || {});
    
    if (players.length === 0) {
        playerList.html('<div style="text-align: center; color: #999; padding: 20px;">Chưa có người chơi tham gia</div>');
    } else {
        let html = '';
        players.forEach((player, index) => {
            const isActive = followingSource === player.source;
            html += `<div class="player-item">
                <div class="player-num">${index + 1}</div>
                <span class="player-name">${player.name}</span>
                <button class="btn-follow ${isActive ? 'active' : ''}" onclick="toggleFollow(${player.source})">${isActive ? '&#128065; Đang xem' : '&#128065; Theo dõi'}</button>
            </div>`;
        });
        playerList.html(html);
    }
}

function toggleFollow(targetSource) {
    if (followingSource === targetSource) {
        followingSource = null;
        $.post('https://' + GetParentResourceName() + '/adminStopFollow', JSON.stringify({}));
    } else {
        followingSource = targetSource;
        $.post('https://' + GetParentResourceName() + '/adminFollowPlayer', JSON.stringify({ source: targetSource }));
    }
    updatePlayerList();
}

function showWinner(winner) {
    if (winner) {
        $('#winnerName').text(winner.name);
        $('#winnerSection').show();
    } else {
        $('#winnerSection').hide();
    }
}

function GetParentResourceName() {
    return 'Zc_Bomber';
}

function updateAdminJoinInfo(roomInfo) {
    if (!roomInfo) return;
    const mapNames = {
        'map1': 'Vị trí tùy chỉnh'
    };
    
    if ($('#joinMapName').length) $('#joinMapName').text(mapNames[roomInfo.map] || 'Chưa chọn');
    if ($('#joinPlayerCount').length) $('#joinPlayerCount').text((roomInfo.playerCount || 0) + ' / ' + (roomInfo.maxPlayers || 0));
    if ($('#joinEntryFee').length) $('#joinEntryFee').text(roomInfo.entryFee || 0);
}
