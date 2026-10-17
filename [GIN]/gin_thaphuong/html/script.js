let progressInterval = null;
let audioContext = null;

const audioPlayer = document.getElementById('temple-audio');
const container = document.getElementById('progress-container');
const fill = document.getElementById('progress-fill');
const timerText = document.getElementById('progress-timer');

// Trình giả lập âm thanh tiếng chuông / nhạc thiền chùa (Web Audio API Fallback)
// Giúp âm thanh HOẠT ĐỘNG NGAY LẬP TỨC ngay cả khi chưa có file MP3 thực tế
function playSynthesizedTempleSound(durationSec, vol) {
    try {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (!AudioCtx) return;
        audioContext = new AudioCtx();

        const now = audioContext.currentTime;
        const freqs = [174, 285, 432, 528]; // Tần số chuông thiền hòa âm

        freqs.forEach((freq, idx) => {
            const osc = audioContext.createOscillator();
            const gain = audioContext.createGain();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, now);

            // Envelope tiếng chuông trầm bổng
            const volumeLevel = (vol || 0.5) * (0.15 / (idx + 1));
            gain.gain.setValueAtTime(0.001, now);
            gain.gain.exponentialRampToValueAtTime(volumeLevel, now + 0.3);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + durationSec);

            osc.connect(gain);
            gain.connect(audioContext.destination);

            osc.start(now + idx * 0.15);
            osc.stop(now + durationSec);
        });
    } catch (e) {
        console.error("Audio synth error:", e);
    }
}

function stopSynthesizedSound() {
    if (audioContext) {
        try {
            audioContext.close();
        } catch (e) { }
        audioContext = null;
    }
}

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'startPray') {
        const durationMs = data.duration || 10000;
        const volume = data.volume !== undefined ? data.volume : 0.5;

        // Thử phát file mp3 trong html/sounds/nhac_chua.mp3
        audioPlayer.volume = volume;
        audioPlayer.src = 'sounds/nhac_chua.mp3';

        let playPromise = audioPlayer.play();
        if (playPromise !== undefined) {
            playPromise.catch(err => {
                // Nếu chưa có file MP3 hoặc bị chặn autoplay, phát âm thanh giả lập Web Audio API tiếng chuông chùa
                playSynthesizedTempleSound(durationMs / 1000, volume);
            });
        }

        // Hiển thị thanh Progress bar
        container.classList.remove('hidden');
        fill.style.width = '0%';

        const startTime = Date.now();
        const totalSec = Math.ceil(durationMs / 1000);
        timerText.innerText = totalSec + 's';

        if (progressInterval) clearInterval(progressInterval);

        progressInterval = setInterval(() => {
            const elapsed = Date.now() - startTime;
            const percentage = Math.min((elapsed / durationMs) * 100, 100);
            fill.style.width = percentage + '%';

            const remainingSec = Math.max(0, Math.ceil((durationMs - elapsed) / 1000));
            timerText.innerText = remainingSec + 's';

            if (elapsed >= durationMs) {
                clearInterval(progressInterval);
                stopPrayUI();
            }
        }, 50);
    }

    if (data.action === 'stopPray') {
        stopPrayUI();
    }
});

function stopPrayUI() {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }

    if (audioPlayer) {
        audioPlayer.pause();
        audioPlayer.currentTime = 0;
    }
    stopSynthesizedSound();

    container.classList.add('hidden');
    fill.style.width = '0%';
}

