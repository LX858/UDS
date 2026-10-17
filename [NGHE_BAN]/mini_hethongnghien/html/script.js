// Message listener phải ở ngoài DOMContentLoaded
let rehabPrices = { normal: 10000, fast: 20000 }; // Default prices

window.addEventListener('message', function(event) {
    const data = event.data;
    if (!data) return;
    
    if (data.action === 'openRehabMenu') {
        // Update prices if provided
        if (data.prices) {
            rehabPrices = data.prices;
        }
        
        const menu = document.getElementById('rehab-menu');
        if (menu) {
            menu.style.display = 'flex';
            document.body.classList.add('menu-open');
        }
    } else if (data.action === 'closeRehabMenu') {
        const menu = document.getElementById('rehab-menu');
        if (menu) {
            menu.style.display = 'none';
            document.body.classList.remove('menu-open');
        }
    } else if (data.action === 'showAddictionIndicator') {
        const indicator = document.getElementById('addiction-indicator');
        if (indicator) {
            indicator.style.display = 'flex';
        }
    } else if (data.action === 'hideAddictionIndicator') {
        const indicator = document.getElementById('addiction-indicator');
        if (indicator) {
            indicator.style.display = 'none';
        }
    } else if (data.action === 'setWithdrawalState') {
        const indicator = document.getElementById('addiction-indicator');
        if (indicator) {
            if (data.isWithdrawal) {
                indicator.classList.add('withdrawal');
            } else {
                indicator.classList.remove('withdrawal');
            }
        }
    } else if (data.type === 'playMusic') {
        stopMusicFading = true;
        setTimeout(function() {
            playTripMusic(data.song, data.seek || 0);
        }, 100);
    } else if (data.type === 'stopMusic') {
        stopTripMusic();
    }
});

// Trip Music Player
let ytPlayer = null;
let stopMusicFading = false;

function playTripMusic(song, seek) {
    if (typeof YT === 'undefined' || !YT.Player) return;
    try {
        if (ytPlayer && ytPlayer.loadVideoById) {
            ytPlayer.loadVideoById(song, seek || 0);
            ytPlayer.setVolume(50);
            ytPlayer.playVideo();
        } else {
            ytPlayer = new YT.Player('player', {
                videoId: song,
                playerVars: {
                    autoplay: 1,
                    loop: 1
                },
                events: {
                    onReady: function (e) {
                        e.target.setVolume(50);
                        e.target.playVideo();
                        if (seek) e.target.seekTo(seek);
                    }
                }
            });
        }
    } catch(e) {}
}

function stopTripMusic() {
    stopMusicFading = false;
    if (!ytPlayer || !ytPlayer.setVolume) return;
    
    function fadeVol(v) {
        if (stopMusicFading) return;
        ytPlayer.setVolume(v);
        setTimeout(function() {
            if (!stopMusicFading) {
                if (v <= 0) {
                    if (ytPlayer.pauseVideo) ytPlayer.pauseVideo();
                } else {
                    fadeVol(v - 2);
                }
            }
        }, 100);
    }
    fadeVol(50);
}

function closeMenu() {
    const menu = document.getElementById('rehab-menu');
    const confirmMenu = document.getElementById('confirm-menu');
    
    if (menu) {
        menu.style.display = 'none';
        document.body.classList.remove('menu-open');
    }
    
    if (confirmMenu) {
        confirmMenu.style.display = 'none';
    }
    
    fetch('https://mini_hethongnghien/close', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).catch(err => {});
}

// Wait for DOM to load
document.addEventListener('DOMContentLoaded', function() {
    // Close on ESC
    document.addEventListener('keyup', function(e) {
        if (e.key === "Escape") {
            closeMenu();
        }
    });

    // Close button
    const closeButton = document.querySelector('.close-button');
    if (closeButton) {
        closeButton.addEventListener('click', function() {
            closeMenu();
        });
    }

    // Select package buttons
    let selectedPackage = null;
    
    document.querySelectorAll('.select-button').forEach(function(button) {
        button.addEventListener('click', function() {
            const packageCard = this.closest('.package-card');
            const type = packageCard.getAttribute('data-type');
            
            // Store selected package info
            selectedPackage = {
                type: type,
                name: type === 'normal' ? 'Cai Nghiện Thường' : 'Cai Nghiện Cấp Tốc',
                duration: type === 'normal' ? '3 tháng' : '1 tháng',
                price: type === 'normal' ? `$${rehabPrices.normal.toLocaleString()}` : `$${rehabPrices.fast.toLocaleString()}`
            };
            
            // Hide main menu and show confirmation
            document.getElementById('rehab-menu').style.display = 'none';
            showConfirmation();
        });
    });
    
    // Show confirmation menu
    function showConfirmation() {
        document.getElementById('confirmPackageName').textContent = selectedPackage.name;
        document.getElementById('confirmDuration').textContent = selectedPackage.duration;
        document.getElementById('confirmPrice').textContent = selectedPackage.price;
        
        const confirmMenu = document.getElementById('confirm-menu');
        confirmMenu.style.display = 'flex';
    }
    
    // Confirm button - proceed with treatment
    const confirmButton = document.getElementById('confirmButton');
    if (confirmButton) {
        confirmButton.addEventListener('click', function() {
            // Send selection to client
            fetch('https://mini_hethongnghien/selectPackage', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    type: selectedPackage.type
                })
            }).catch(err => {});
            
            // Close all menus
            document.getElementById('confirm-menu').style.display = 'none';
            document.getElementById('rehab-menu').style.display = 'none';
            document.body.classList.remove('menu-open');
            
            fetch('https://mini_hethongnghien/close', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            }).catch(err => {});
        });
    }
    
    // Cancel button - go back to package selection
    const cancelButton = document.getElementById('cancelButton');
    if (cancelButton) {
        cancelButton.addEventListener('click', function() {
            document.getElementById('confirm-menu').style.display = 'none';
            document.getElementById('rehab-menu').style.display = 'flex';
        });
    }
});
