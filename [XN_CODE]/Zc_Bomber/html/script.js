// Audio player cho Zc_Bomber
let currentSound = null;
let currentEffect = null;
let soundURL = '';

// Tự động chuyển đổi link github html thông thường sang link raw
function resolveSoundURL(url) {
    if (!url) return '';
    let formatted = url;
    if (formatted.includes('github.com')) {
        formatted = formatted.replace('github.com', 'raw.githubusercontent.com')
                             .replace('/blob/', '/')
                             .replace('/tree/', '/');
    }
    return formatted;
}

function getSoundSource(soundName) {
    if (!soundName) return '';
    
    // Nếu bản thân soundName là một URL trực tiếp
    if (soundName.startsWith('http://') || soundName.startsWith('https://')) {
        return resolveSoundURL(soundName);
    }
    
    // Nếu dùng base URL (ví dụ Config.SoundURL)
    if (soundURL && soundURL !== '') {
        let base = resolveSoundURL(soundURL);
        // Đảm bảo có dấu gạch chéo ở cuối base
        if (!base.endsWith('/')) {
            base = base + '/';
        }
        return base + soundName;
    }
    
    // Fallback về folder local
    return './sounds/' + soundName;
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'setSoundURL') {
        soundURL = data.url || '';
        console.log('[BOMBER AUDIO] Sound URL set to:', soundURL);
    }
    else if (data.type === 'playsound') {
        // Dừng nhạc cũ nếu đang phát
        if (currentSound) {
            currentSound.pause();
            currentSound.currentTime = 0;
        }
        
        // Tạo và phát nhạc mới
        let src = getSoundSource(data.sound);
        currentSound = new Audio(src);
        currentSound.volume = data.volume || 0.1;
        currentSound.loop = data.loop || false;
        
        currentSound.onerror = function(e) {
            console.error('[BOMBER AUDIO] Load failed for source:', src, 'Error Event:', e);
        };
        
        currentSound.play().catch(function(error) {
            console.error('[BOMBER AUDIO] Play failed. Error Name:', error.name, 'Message:', error.message);
        });
        
        console.log('[BOMBER AUDIO] Playing:', src, 'Volume:', data.volume, 'Loop:', data.loop);
    } 
    else if (data.type === 'stopsound') {
        // Dừng nhạc chính
        if (currentSound) {
            currentSound.pause();
            currentSound.currentTime = 0;
            currentSound = null;
            console.log('[BOMBER AUDIO] Stopped main sound');
        }
    }
    else if (data.type === 'eff') {
        // Effect sounds (không dừng nhạc chính, chỉ phát ngắn)
        if (currentEffect) {
            currentEffect.pause();
            currentEffect.currentTime = 0;
        }
        
        let src = getSoundSource(data.sound);
        currentEffect = new Audio(src);
        currentEffect.volume = data.volume || 0.1;
        
        currentEffect.onerror = function(e) {
            console.error('[BOMBER AUDIO] Effect load failed for source:', src, 'Error Event:', e);
        };
        
        currentEffect.play().catch(function(error) {
            console.error('[BOMBER AUDIO] Effect play failed. Error Name:', error.name, 'Message:', error.message);
        });
        
        console.log('[BOMBER AUDIO] Playing effect:', src, 'Volume:', data.volume);
    }
});

console.log('[BOMBER AUDIO] Script loaded');
