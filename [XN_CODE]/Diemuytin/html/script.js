// DiemUyTin Warning UI Script
let isUIOpen = false;
let countdownInterval = null;

// Listen for NUI messages from client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'showWarning') {
        showWarning(data);
    } else if (data.action === 'hideWarning') {
        hideWarning();
    }
});

// Show warning UI with data
function showWarning(data) {
    try {
        isUIOpen = true;
        const container = document.getElementById('warningContainer');
        
        if (!container) {
            console.error('[DIEMUYTIN NUI] ERROR: Container not found!');
            return;
        }
        
        // Update player name
        const playerNameEl = document.getElementById('playerName');
        if (data.playerName && playerNameEl) {
            playerNameEl.textContent = data.playerName;
        }
    
    // Update reputation score
    const reputation = data.reputation || 0;
    const maxReputation = data.maxReputation || 100;
    const reputationPercent = Math.round((reputation / maxReputation) * 100);
    
    document.getElementById('reputationScore').textContent = reputation + '/' + maxReputation;
    document.getElementById('reputationPercent').textContent = '(' + reputationPercent + '%)';
    document.getElementById('progressPercent').textContent = reputationPercent + '%';
    
    // Update progress bar
    const progressFill = document.getElementById('progressFill');
    progressFill.style.width = reputationPercent + '%';
    
    // Update progress bar color based on reputation level
    if (reputationPercent <= 30) {
        progressFill.style.background = 'linear-gradient(90deg, #d32f2f 0%, #f44336 50%, #d32f2f 100%)';
    } else if (reputationPercent <= 60) {
        progressFill.style.background = 'linear-gradient(90deg, #ff9800 0%, #ffa726 50%, #ff9800 100%)';
    } else {
        progressFill.style.background = 'linear-gradient(90deg, #ff3b30 0%, #ff6b6b 50%, #ff3b30 100%)';
    }
    
    // Update reason if provided
    if (data.reason) {
        const reasonText = document.querySelector('.danger-text');
        if (reasonText) {
            reasonText.innerHTML = `<strong>Lý do:</strong> ${data.reason}<br><br>Nếu tiếp tục có hành vi vi phạm, bạn sẽ <strong>bị tù liên bang</strong> khi uy tín xuống dưới <strong>50 điểm!</strong>`;
        }
    }
    
    // Show the container with animation
    container.classList.remove('hidden');
    container.style.display = 'flex';
    
    // Start countdown with configured duration
    const displayTime = data.displayTime || 10;
    startCountdown(displayTime);
    
    // Play sound effect (if available)
    if (data.playSound !== false) {
        playWarningSound();
    }
    
    } catch (error) {
    }
}

// Start countdown timer
function startCountdown(duration) {
    // Clear existing countdown
    if (countdownInterval) {
        clearInterval(countdownInterval);
    }
    
    let timeLeft = duration || 10;
    const countdownEl = document.getElementById('countdown');
    
    if (countdownEl) {
        countdownEl.textContent = timeLeft;
    }
    
    countdownInterval = setInterval(() => {
        timeLeft--;
        
        if (countdownEl) {
            countdownEl.textContent = timeLeft;
        }
        
        if (timeLeft <= 0) {
            clearInterval(countdownInterval);
            hideWarning();
        }
    }, 1000);
}

// Hide warning UI
function hideWarning() {
    // Clear countdown
    if (countdownInterval) {
        clearInterval(countdownInterval);
        countdownInterval = null;
    }
    
    const container = document.getElementById('warningContainer');
    if (container) {
        container.classList.add('hidden');
        container.style.display = 'none';
    }
    isUIOpen = false;
    
    // Send callback to client
    fetch('https://Diemuytin/closeWarning', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).catch(() => {});
}

// Close button function
function closeWarning() {
    hideWarning();
}

// Play warning sound
function playWarningSound() {
    // You can add custom sound here if needed
    try {
        const audio = new Audio('warning.mp3');
        audio.volume = 0.3;
        audio.play().catch(() => {});
    } catch (e) {
        // Sound file not found, skip
    }
}

// Close on ESC key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && isUIOpen) {
        hideWarning();
    }
});

// Prevent right-click context menu
document.addEventListener('contextmenu', function(event) {
    event.preventDefault();
});

// Initialize on load
document.addEventListener('DOMContentLoaded', function() {
    // Hide UI initially
    const container = document.getElementById('warningContainer');
    
    if (container) {
        container.classList.add('hidden');
    }
    
    // Test function - window global
    window.testShowUI = function() {
        showWarning({
            playerName: 'Test Player',
            reputation: 50,
            maxReputation: 100,
            reason: 'Test UI from console',
            playSound: false
        });
    };
});
