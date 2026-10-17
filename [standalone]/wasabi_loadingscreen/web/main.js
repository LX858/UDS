let backgroundShown = false;
let draggingMouse = false;
let popupOpened = false;
let canClick = true;
let selectedStaff = 0;
let currentSong = 0;
let Config = {};
let swiperTeam;
let music;
let songs = [];
let pageOpened = '';
let isPaused = false;
let isMuted = false;
let previousVol = 50;

const keyboardLayouts = {
    'QWERTY': [
        { id: 'esc', value: 'ESC' },
        { id: 'f1', value: 'F1', class: 'ml1' },
        { id: 'f2', value: 'F2' },
        { id: 'f3', value: 'F3' },
        { id: 'f4', value: 'F4' },
        { id: 'f5', value: 'F5', class: 'ml1' },
        { id: 'f6', value: 'F6' },
        { id: 'f7', value: 'F7' },
        { id: 'f8', value: 'F8' },
        { id: 'f9', value: 'F9', class: 'ml1' },
        { id: 'f10', value: 'F10' },
        { id: 'f11', value: 'F11' },
        { id: 'f12', value: 'F12' },
        { id: 'print', value: 'PRINT', class: 'ml05 fz06' },
        { id: 'lock', value: 'LOCK', class: 'fz06' },
        { id: 'pause', value: 'PAUSE', class: 'fz06' },
        { id: 'tilde', value: '~' },
        { id: '1', value: '1' },
        { id: '2', value: '2' },
        { id: '3', value: '3' },
        { id: '4', value: '4' },
        { id: '5', value: '5' },
        { id: '6', value: '6' },
        { id: '7', value: '7' },
        { id: '8', value: '8' },
        { id: '9', value: '9' },
        { id: '0', value: '0' },
        { id: 'minus', value: '-' },
        { id: 'plus', value: '+' },
        { id: 'back', value: 'BACK' },
        { id: 'ins', value: 'INS', class: 'ml05 fz06' },
        { id: 'home', value: 'HOME', class: 'fz06' },
        { id: 'pgup', value: 'PGUP', class: 'fz06' },
        { id: 'tab', value: 'TAB' },
        { id: 'q', value: 'Q' },
        { id: 'w', value: 'W' },
        { id: 'e', value: 'E' },
        { id: 'r', value: 'R' },
        { id: 't', value: 'T' },
        { id: 'y', value: 'Y' },
        { id: 'u', value: 'U' },
        { id: 'i', value: 'I' },
        { id: 'o', value: 'O' },
        { id: 'p', value: 'P' },
        { id: 'open-bracket', value: '[' },
        { id: 'close-bracket', value: ']' },
        { id: 'backslash', value: '\\' },
        { id: 'del', value: 'DEL', class: 'ml05 fz06' },
        { id: 'end', value: 'END', class: 'fz06' },
        { id: 'pgdn', value: 'PGDN', class: 'fz06' },
        { id: 'caps', value: 'CAPS' },
        { id: 'a', value: 'A' },
        { id: 's', value: 'S' },
        { id: 'd', value: 'D' },
        { id: 'f', value: 'F' },
        { id: 'g', value: 'G' },
        { id: 'h', value: 'H' },
        { id: 'j', value: 'J' },
        { id: 'k', value: 'K' },
        { id: 'l', value: 'L' },
        { id: 'colon', value: ':' },
        { id: 'quote', value: "''" },
        { id: 'enter', value: 'ENTER' },
        { id: 'left-shift', value: 'SHIFT' },
        { id: 'z', value: 'Z' },
        { id: 'x', value: 'X' },
        { id: 'c', value: 'C' },
        { id: 'v', value: 'V' },
        { id: 'b', value: 'B' },
        { id: 'n', value: 'N' },
        { id: 'm', value: 'M' },
        { id: 'comma', value: ',' },
        { id: 'dot', value: '.' },
        { id: 'cross', value: '-' },
        { id: 'right-shift', value: 'SHIFT' },
        { id: 'arrow-up', value: '<i class="fa-solid fa-arrow-up"></i>', class: 'ml5' },
        { id: 'left-ctrl', value: 'CTRL' },
        { id: 'left-windows', value: '<i class="fa-brands fa-windows"></i>' },
        { id: 'left-alt', value: 'ALT' },
        { id: 'space', value: 'SPACE' },
        { id: 'right-alt', value: 'ALT' },
        { id: 'right-windows', value: '<i class="fa-brands fa-windows"></i>' },
        { id: 'right-ctrl', value: 'CTRL' },
        { id: 'arrow-left', value: '<i class="fa-solid fa-arrow-left"></i>', class: 'ml05' },
        { id: 'arrow-down', value: '<i class="fa-solid fa-arrow-down"></i>' },
        { id: 'arrow-right', value: '<i class="fa-solid fa-arrow-right"></i>' }
    ],
    'AZERTY': [
        { id: 'esc', value: 'ESC' },
        { id: 'f1', value: 'F1', class: 'ml1' },
        { id: 'f2', value: 'F2' },
        { id: 'f3', value: 'F3' },
        { id: 'f4', value: 'F4' },
        { id: 'f5', value: 'F5', class: 'ml1' },
        { id: 'f6', value: 'F6' },
        { id: 'f7', value: 'F7' },
        { id: 'f8', value: 'F8' },
        { id: 'f9', value: 'F9', class: 'ml1' },
        { id: 'f10', value: 'F10' },
        { id: 'f11', value: 'F11' },
        { id: 'f12', value: 'F12' },
        { id: 'print', value: 'PRINT', class: 'ml05 fz06' },
        { id: 'lock', value: 'LOCK', class: 'fz06' },
        { id: 'pause', value: 'PAUSE', class: 'fz06' },
        { id: 'tilde', value: '²' },
        { id: '1', value: '&' },
        { id: '2', value: 'é' },
        { id: '3', value: '"' },
        { id: '4', value: "'" },
        { id: '5', value: '(' },
        { id: '6', value: '-' },
        { id: '7', value: 'è' },
        { id: '8', value: '_' },
        { id: '9', value: 'ç' },
        { id: '0', value: 'à' },
        { id: 'minus', value: ')' },
        { id: 'plus', value: '=' },
        { id: 'back', value: 'BACK' },
        { id: 'ins', value: 'INS', class: 'ml05 fz06' },
        { id: 'home', value: 'HOME', class: 'fz06' },
        { id: 'pgup', value: 'PGUP', class: 'fz06' },
        { id: 'tab', value: 'TAB' },
        { id: 'q', value: 'A' },
        { id: 'w', value: 'Z' },
        { id: 'e', value: 'E' },
        { id: 'r', value: 'R' },
        { id: 't', value: 'T' },
        { id: 'y', value: 'Y' },
        { id: 'u', value: 'U' },
        { id: 'i', value: 'I' },
        { id: 'o', value: 'O' },
        { id: 'p', value: 'P' },
        { id: 'open-bracket', value: '^' },
        { id: 'close-bracket', value: '$' },
        { id: 'backslash', value: '*' },
        { id: 'del', value: 'DEL', class: 'ml05 fz06' },
        { id: 'end', value: 'END', class: 'fz06' },
        { id: 'pgdn', value: 'PGDN', class: 'fz06' },
        { id: 'caps', value: 'CAPS' },
        { id: 'a', value: 'Q' },
        { id: 's', value: 'S' },
        { id: 'd', value: 'D' },
        { id: 'f', value: 'F' },
        { id: 'g', value: 'G' },
        { id: 'h', value: 'H' },
        { id: 'j', value: 'J' },
        { id: 'k', value: 'K' },
        { id: 'l', value: 'L' },
        { id: 'colon', value: 'M' },
        { id: 'quote', value: 'ù' },
        { id: 'enter', value: 'ENTER' },
        { id: 'left-shift', value: 'SHIFT' },
        { id: 'z', value: 'W' },
        { id: 'x', value: 'X' },
        { id: 'c', value: 'C' },
        { id: 'v', value: 'V' },
        { id: 'b', value: 'B' },
        { id: 'n', value: 'N' },
        { id: 'comma', value: ',' },
        { id: 'dot', value: '.' },
        { id: 'cross', value: ':' },
        { id: 'plus', value: '+' },
        { id: 'right-shift', value: 'SHIFT' },
        { id: 'arrow-up', value: '<i class="fa-solid fa-arrow-up"></i>', class: 'ml5' },
        { id: 'left-ctrl', value: 'CTRL' },
        { id: 'left-windows', value: '<i class="fa-brands fa-windows"></i>' },
        { id: 'left-alt', value: 'ALT' },
        { id: 'space', value: 'SPACE' },
        { id: 'right-alt', value: 'ALT' },
        { id: 'right-windows', value: '<i class="fa-brands fa-windows"></i>' },
        { id: 'right-ctrl', value: 'CTRL' },
        { id: 'arrow-left', value: '<i class="fa-solid fa-arrow-left"></i>', class: 'ml05' },
        { id: 'arrow-down', value: '<i class="fa-solid fa-arrow-down"></i>' },
        { id: 'arrow-right', value: '<i class="fa-solid fa-arrow-right"></i>' }
    ]
};

function setVideoVolume(vol0to1) {
    const clamped = Math.max(0, Math.min(1, vol0to1));
    const vid = document.querySelector('#background video') || document.getElementById('bg-video');
    if (vid && vid.tagName === 'VIDEO') {
        vid.volume = clamped;
        vid.muted = (clamped === 0);
    }
}

function toggleVideoPlayback(pause) {
    const vid = document.querySelector('#background video') || document.getElementById('bg-video');
    if (vid && vid.tagName === 'VIDEO') {
        if (pause) {
            vid.pause();
        } else {
            vid.play().catch(() => {});
        }
    }
}

window.addEventListener('DOMContentLoaded', () => {
    Config = (window.nuiHandoverData && window.nuiHandoverData.config) || window.Config || {};
    
    // Set theme color
    if (Config.MainColor) {
        $(':root').css('--wsbcolor', Config.MainColor);
    }

    const useVideoAudio = Config.UseVideoAudio === true;
    const defaultVol = (Config.DefaultVolume !== undefined ? Config.DefaultVolume : 0.5);

    // Background setup
    if (Config.BackgroundType === 'video') {
        if (Config.UseLocalVideo) {
            const mutedAttr = (useVideoAudio && defaultVol > 0) ? '' : 'muted';
            $('#background').html(`<video id="bg-video" autoplay ${mutedAttr} loop playsinline src="assets/background.mp4" type="video/mp4"></video>`);
            const vid = document.getElementById('bg-video');
            if (vid) {
                vid.volume = defaultVol;
            }
        } else {
            if (Config.Platform === 'streamable') {
                // Fetch direct MP4 URL from Streamable CDN for native HTML5 video & 100% working volume control
                fetch(`https://api.streamable.com/videos/${Config.VideoID}`)
                    .then(res => res.json())
                    .then(data => {
                        const mp4Url = (data.files && data.files.mp4 && data.files.mp4.url) || 
                                       (data.files && data.files['mp4-mobile'] && data.files['mp4-mobile'].url);
                        if (mp4Url) {
                            const directUrl = mp4Url.startsWith('//') ? 'https:' + mp4Url : mp4Url;
                            $('#background').html(`
                                <video id="bg-video" autoplay loop playsinline style="width:100%; height:100%; object-fit:cover;">
                                    <source src="${directUrl}" type="video/mp4">
                                </video>
                            `);
                            const vid = document.getElementById('bg-video');
                            if (vid) {
                                vid.volume = defaultVol;
                                vid.muted = (defaultVol === 0);
                                if (Config.AddBlurToBackground) {
                                    $(vid).css('filter', 'blur(8px)');
                                }
                            }
                        } else {
                            throw new Error('No direct stream MP4');
                        }
                    })
                    .catch(() => {
                        // Fallback to iframe embed if Streamable API is unavailable
                        const mutedParam = (useVideoAudio && defaultVol > 0) ? '0' : '1';
                        $('#background').html(`
                            <iframe id="bg-video" width="100%" height="100%" 
                                src="https://streamable.com/e/${Config.VideoID}?autoplay=1&muted=${mutedParam}&nocontrols=1" 
                                frameborder="0" 
                                allow="autoplay; encrypted-media" 
                                allowfullscreen>
                            </iframe>
                        `);
                    });
            } else if (Config.Platform === 'direct' || (Config.VideoID && Config.VideoID.startsWith('http'))) {
                $('#background').html(`
                    <video id="bg-video" autoplay loop playsinline style="width:100%; height:100%; object-fit:cover;">
                        <source src="${Config.VideoID}" type="video/mp4">
                    </video>
                `);
                const vid = document.getElementById('bg-video');
                if (vid) {
                    vid.volume = defaultVol;
                    vid.muted = (defaultVol === 0);
                }
            } else if (Config.Platform === 'youtube') {
                const muteParam = (useVideoAudio && defaultVol > 0) ? '0' : '1';
                $('#background').html(`
                    <iframe id="bg-video" width="100%" height="100%" 
                        src="https://www.youtube.com/embed/${Config.VideoID}?autoplay=1&mute=${muteParam}&controls=0&loop=1&playlist=${Config.VideoID}&enablejsapi=1" 
                        frameborder="0" 
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                        allowfullscreen>
                    </iframe>
                `);
            }
        }
    } else if (Config.BackgroundType === 'image') {
        $('#background').html('<img id="bg-image" src="assets/images/background.jpg" alt="background"></img>');
    } else if (Config.BackgroundType === 'slideshow') {
        startSlideshow();
    }

    // Volume Slider Setup
    const rangeSlider = document.querySelector('.range-slider__range');
    if (rangeSlider) {
        rangeSlider.value = defaultVol * 100;
        
        function updateVolume(sendCmd = true) {
            const val = parseFloat(rangeSlider.value);
            const min = parseFloat(rangeSlider.min) || 0;
            const max = parseFloat(rangeSlider.max) || 100;
            const progress = ((val - min) / (max - min)) * 100;
            rangeSlider.style.setProperty('--range-progress', progress + '%');

            const currentVol = val / 100;

            // Update Volume icon
            if (val === 0) {
                $('.music-card i').removeClass('bi-volume-up').addClass('bi-volume-mute');
                isMuted = true;
            } else {
                $('.music-card i').removeClass('bi-volume-mute').addClass('bi-volume-up');
                isMuted = false;
            }

            if (useVideoAudio) {
                if (sendCmd) {
                    setVideoVolume(currentVol);
                }
            } else if (music) {
                music.volume = currentVol;
            }
        }

        updateVolume(false);
        rangeSlider.addEventListener('input', () => updateVolume(true));
    }

    // Music Player Setup
    if (useVideoAudio) {
        // Video audio mode: Keep volume controls, hide playlist buttons & song timeline
        $('#music-bar-card').hide();
        $('#music-time').hide();
        $('#previous-music').hide();
        $('#next-music').hide();
        
        $('#music-title').html((Config.Translations && Config.Translations.servername) || 'Under Star Community');
        $('#music-artist').html('Video Sound');
    } else if (Config.Songs && Object.keys(Config.Songs).length > 0) {
        songs = Config.Songs;
        const totalSongs = Object.keys(songs).length;

        if (Config.RandomizeMusics) {
            currentSong = Math.floor(Math.random() * totalSongs);
        }

        music = new Audio('musics/' + songs[currentSong].file);
        music.volume = Config.DefaultVolume || 0.1;
        music.play().catch(() => {});

        $('#music-artist').html(songs[currentSong].artist || '');
        $('#music-title').html(songs[currentSong].name || '');
        $('#music-bar').css('width', '0%');
        $('#music-time').html('00:00');

        const musicBarCard = $('#music-bar-card');
        const musicBar = $('#music-bar');

        musicBarCard.on('mousedown', function(e) {
            draggingMouse = true;
            let offset = e.clientX - musicBarCard.offset().left;
            let progress = (offset / musicBarCard.width()) * 100;
            musicBar.css('width', progress + '%');

            function onMouseMove(moveEvent) {
                let currentOffset = moveEvent.clientX - musicBarCard.offset().left;
                let currentProgress = (currentOffset / musicBarCard.width()) * 100;
                currentProgress = Math.max(0, Math.min(100, currentProgress));
                musicBar.css('width', currentProgress + '%');
            }

            function onMouseUp() {
                draggingMouse = false;
                let finalProgress = (parseFloat(musicBar.css('width')) / musicBarCard.width()) * 100;
                if (music && music.duration) {
                    music.currentTime = (finalProgress / 100) * music.duration;
                }
                $(document).off('mousemove', onMouseMove);
                $(document).off('mouseup', onMouseUp);
            }

            $(document).on('mousemove', onMouseMove);
            $(document).on('mouseup', onMouseUp);
        });

        music.addEventListener('ended', function() {
            currentSong++;
            if (currentSong >= Object.keys(Config.Songs).length) {
                currentSong = 0;
            }
            $('#music-artist').html(songs[currentSong].artist || '');
            $('#music-title').html(songs[currentSong].name || '');
            music.src = 'musics/' + songs[currentSong].file;
            music.play().catch(() => {});
        });

        music.addEventListener('timeupdate', function() {
            if (!music.duration) return;
            const progress = (music.currentTime / music.duration) * 100;
            if (!draggingMouse) {
                $('#music-bar').css('width', progress + '%');
            }
            const mins = Math.floor(music.currentTime / 60);
            const secs = Math.floor(music.currentTime - mins * 60);
            const timeStr = String(mins).padStart(2, '0') + ':' + String(secs).padStart(2, '0');
            $('#music-time').html(timeStr);
        });
    }

    // Weather Effects
    if (Config.AddBackgroundEffect === 'rain') {
        createRainEffect();
    } else if (Config.AddBackgroundEffect === 'snow') {
        createSnowEffect();
    }

    // Blur Background
    if (Config.AddBlurToBackground) {
        $('.background img, .background video, .background iframe').css('filter', 'blur(8px)');
    }

    // Color Glow Zones
    const colorZones = [
        { top: '-35%', left: '-15%', width: '65rem', height: '65rem' },
        { top: '60%', left: '36%', width: '65rem', height: '65rem' },
        { top: '-30%', left: '65%', width: '65rem', height: '65rem' }
    ];
    for (let i = 0; i < 3; i++) {
        const zone = $('<div></div>').addClass('color-zone');
        zone.css({
            background: 'radial-gradient(circle, var(--wsbcolor) 0%, rgba(255, 255, 255, 0) 70%)',
            width: colorZones[i].width,
            height: colorZones[i].height,
            borderRadius: '50%',
            top: colorZones[i].top,
            left: colorZones[i].left,
            position: 'absolute',
            zIndex: 1
        });
        $('#background').append(zone);
    }

    // Translations & UI Text
    setUITranslations();

    // Hidden Options
    if (Array.isArray(Config.HiddenOptions)) {
        Config.HiddenOptions.forEach(opt => {
            const btnId = '#open' + opt.charAt(0).toUpperCase() + opt.slice(1);
            $(btnId).hide();
        });
    }

    // Social Links
    setLinks();
});

// Click Volume Icon to Toggle Mute
$(document).on('click', '.music-card i', function() {
    const rangeSlider = document.querySelector('.range-slider__range');
    if (!rangeSlider) return;

    if (!isMuted) {
        previousVol = parseFloat(rangeSlider.value) || 50;
        rangeSlider.value = 0;
    } else {
        rangeSlider.value = previousVol > 0 ? previousVol : 50;
    }
    rangeSlider.dispatchEvent(new Event('input'));
});

// Close popup on clicking outside
$(document).on('click', function(e) {
    if (popupOpened) {
        const targetPopup = $('.popup-' + pageOpened);
        if (!targetPopup.is(e.target) && targetPopup.has(e.target).length === 0) {
            removeBlur();
        }
    }
});

// Popup Triggers
$(document).on('click', '#openRules', function(e) {
    if (!canClick) return;
    $('.selected').removeClass('selected');
    $(this).addClass('selected');
    pageOpened = 'rules';
    addBlur();
    e.stopPropagation();
    setRules();
});

$(document).on('click', '#openTeam', function(e) {
    if (!canClick) return;
    $('.selected').removeClass('selected');
    $(this).addClass('selected');
    pageOpened = 'team';
    addBlur();
    e.stopPropagation();
    setTeamMembers();
});

$(document).on('click', '#openUpdates', function(e) {
    if (!canClick) return;
    $('.selected').removeClass('selected');
    $(this).addClass('selected');
    pageOpened = 'updates';
    addBlur();
    e.stopPropagation();
    setUpdates();
});

$(document).on('click', '#openKeyboard', function(e) {
    if (!canClick) return;
    $('.selected').removeClass('selected');
    $(this).addClass('selected');
    pageOpened = 'keyboard';
    addBlur();
    e.stopPropagation();
    setKeyboard();
});

// Music Controls
$(document).on('click', '#next-music', function() {
    if (!music || !songs.length) return;
    currentSong++;
    if (currentSong >= Object.keys(songs).length) {
        currentSong = 0;
    }
    music.src = 'musics/' + songs[currentSong].file;
    music.play().catch(() => {});
    $('#music-artist').html(songs[currentSong].artist || '');
    $('#music-title').html(songs[currentSong].name || '');
    $('#pause-music').html('<i class="bi bi-pause"></i>');
    $('#music-bar').css('width', '0%');
});

$(document).on('click', '#previous-music', function() {
    if (!music || !songs.length) return;
    currentSong--;
    if (currentSong < 0) {
        currentSong = Object.keys(songs).length - 1;
    }
    music.src = 'musics/' + songs[currentSong].file;
    music.play().catch(() => {});
    $('#music-artist').html(songs[currentSong].artist || '');
    $('#music-title').html(songs[currentSong].name || '');
    $('#pause-music').html('<i class="bi bi-pause"></i>');
    $('#music-bar').css('width', '0%');
});

// Pause / Play Button
$(document).on('click', '#pause-music', function() {
    if (Config.UseVideoAudio) {
        isPaused = !isPaused;
        toggleVideoPlayback(isPaused);
        $('#pause-music').html(isPaused ? '<i class="bi bi-play"></i>' : '<i class="bi bi-pause"></i>');
        return;
    }

    if (!music) return;
    if (music.paused) {
        music.play().catch(() => {});
        $('#pause-music').html('<i class="bi bi-pause"></i>');
    } else {
        music.pause();
        $('#pause-music').html('<i class="bi bi-play"></i>');
    }
});

// Hide UI Overlay toggle
$(document).on('click', '#hide-overlay', function() {
    if (!backgroundShown) {
        $('.overlay').fadeOut(500);
        $('.background').css('filter', 'blur(0px)');
        $('#hide-overlay').html('<i class="bi bi-eye"></i>');
        backgroundShown = true;
    } else {
        $('.overlay').fadeIn(500);
        $('.background').css('filter', 'blur(1px)');
        $('#hide-overlay').html('<i class="bi bi-eye-slash"></i>');
        backgroundShown = false;
    }
});

function createRainEffect() {
    let count = 0;
    let front = '';
    let back = '';
    while (count < 100) {
        const rand1 = Math.floor(Math.random() * 98) + 1;
        const rand2 = Math.floor(Math.random() * 4) + 2;
        count += rand2;
        front += `<div class="rain" style="left: ${count}%; bottom: ${(rand2 + rand2 - 1 + 100)}%; animation-delay: 0.${rand1}s; animation-duration: 0.5${rand1}s;"><div class="rain-drops" style="animation-delay: 0.${rand1}s; animation-duration: 0.5${rand1}s;"></div><div class="rain-splash" style="animation-delay: 0.${rand1}s; animation-duration: 0.5${rand1}s;"></div></div>`;
        back += `<div class="rain" style="right: ${count}%; bottom: ${(rand2 + rand2 - 1 + 100)}%; animation-delay: 0.${rand1}s; animation-duration: 0.5${rand1}s;"><div class="rain-drops" style="animation-delay: 0.${rand1}s; animation-duration: 0.5${rand1}s;"></div></div>`;
    }
    $('.front-row').append(front);
    $('.back-row').append(back);
}

function createSnowEffect() {
    const snowContainer = $('.snow-container');
    const flakes = [];
    let snowInterval;

    function animateFlake(flake) {
        const size = Math.random() * 5 + 1;
        const width = $(window).width() - size;
        const height = $(window).height();
        flake.css({
            width: size + 'px',
            height: size + 'px',
            left: Math.random() * width + 'px',
            top: '-' + size + 'px',
            animationDuration: (Math.random() * 3 + 2) / 1.25 + 's',
            animationTimingFunction: 'linear',
            animationName: Math.random() < 0.5 ? 'fall' : 'diagonal-fall'
        });
        setTimeout(() => {
            if (parseInt(flake.css('top'), 10) < height) {
                animateFlake(flake);
            } else {
                flake.remove();
            }
        }, parseFloat(flake.css('animationDuration')) * 1000);
    }

    function addFlake() {
        if (flakes.length < 200) {
            const flake = $('<div></div>').addClass('snowflake');
            flakes.push(flake);
            snowContainer.append(flake);
            animateFlake(flake);
        }
    }

    function startSnow() {
        const count = Math.ceil($(window).width() * $(window).height() / 1000) * 0.1;
        const interval = 5000 / count;
        clearInterval(snowInterval);
        snowInterval = setInterval(() => {
            if (flakes.length < 200) {
                requestAnimationFrame(addFlake);
            }
        }, interval);
    }
    startSnow();
}

function removeBlur() {
    canClick = false;
    popupOpened = false;
    $('.popup').fadeOut(500);
    setTimeout(() => {
        $('.popup-' + pageOpened).css('display', 'none');
        canClick = true;
    }, 500);
    $('.overlay').css('pointer-events', 'auto');
    $('.selected').removeClass('selected');
}

function addBlur() {
    popupOpened = true;
    $('#background img, #background video, #background iframe').css('filter', 'blur(8px)');
    $('.popup-' + pageOpened).css('display', 'flex').hide().fadeIn(500);
    if (window.event) {
        window.event.stopPropagation();
    }
    $('.overlay').css('pointer-events', 'none');
}

function setKeyboard() {
    const layout = keyboardLayouts[(Config.KeyboardLayout || 'QWERTY').toUpperCase()] || keyboardLayouts['QWERTY'];
    const keysHtml = layout.reduce((acc, key, index) => {
        const isNewRow = index === 0 || 
            layout[index - 1].id.endsWith('pause') || 
            layout[index - 1].id.endsWith('pgup') || 
            layout[index - 1].id.endsWith('pgdn') || 
            layout[index - 1].id.endsWith('enter') || 
            layout[index - 1].id.endsWith('arrow-up') || 
            layout[index - 1].id.endsWith('arrow-right');

        const keyConfig = (Config.KeyboardKeys && (Config.KeyboardKeys[key.id] || Config.KeyboardKeys[key.id.toUpperCase()])) !== undefined;
        const keyDesc = (Config.KeyboardKeys && (Config.KeyboardKeys[key.id] || Config.KeyboardKeys[key.id.toUpperCase()])) || '';
        const keyClass = (keyConfig ? 'green' : '') + ' ' + (key.class ? key.class : '');
        const li = `<li id="${key.id}" class="${keyClass}" data-toggle="popover" title="${keyDesc}">${key.value}</li>`;

        return isNewRow ? acc + '</ul><ul class="newrow">' + li : acc + li;
    }, '<div class="keyboard"><ul class="newrow">') + '</ul></div>';

    $('.popup-keyboard').html(keysHtml);
    $('[data-toggle="popover"]').popover({
        placement: 'top',
        trigger: 'hover'
    });
}

function setTeamMembers() {
    let teamHtml = '';
    const teamMembers = Config.Team || [];
    const total = Object.keys(teamMembers).length;

    for (let i = 0; i < total; i++) {
        const member = teamMembers[i];
        if (!member) continue;
        teamHtml += `
            <div class="swiper-slide team-card">
                <div style="display: flex; flex-direction: column; justify-content: space-between; height: 100%; width: 100%; align-items: center;">
                    <div style="display: flex; flex-direction: row; justify-content: space-between; margin-top: 1rem; width: 100%;">
                        <div style="display: flex; flex-direction: column; margin-left: 1.25rem;">
                            <span class="team-card-title">${member.title}</span>
                            <span class="team-card-name">${member.name}</span>
                        </div>
                        <img class="logo-smaller" src="assets/images/logo.png">
                    </div>
                    <img class="team-card-image" src="assets/images/${member.image}">
                </div>
            </div>
        `;
    }

    $('#swiper-wrapper-team').html(teamHtml);
    if (swiperTeam) {
        swiperTeam.destroy(true, true);
    }
    swiperTeam = new Swiper('#swiper-team', {
        effect: 'coverflow',
        centeredSlides: true,
        slidesPerView: 3,
        spaceBetween: 40,
        loop: false,
        initialSlide: selectedStaff,
        autoplay: {
            delay: (Config.DelayOnStaffSlides || 5) * 1000
        },
        keyboard: {
            enabled: true,
            onlyInViewport: false
        },
        lazyPreloadPrevNext: 10,
        pagination: {
            el: '#swiper-page-team',
            type: 'bullets',
            clickable: true
        },
        coverflowEffect: {
            rotate: 50,
            stretch: 0,
            depth: 300,
            modifier: 1,
            slideShadows: false
        },
        on: {
            slideChange: function() {
                selectedStaff = this.realIndex;
            }
        }
    });
}

function setUpdates() {
    const container = $('.popup-updates');
    container.html('');
    $.each(Config.Updates || [], function(i, update) {
        const item = $('<div></div>').addClass('server-update');
        item.html(`
            <div class="df-fdc">
                <div class="df-jcsb-alc width30-375">
                    <div class="server-update-title">${update.title}</div>
                    <div class="server-update-date">${update.date}</div>
                </div>
                <hr>
                <div>
                    <div class="update-name">${update.name}</div>
                    <div class="update-description">${update.description}</div>
                </div>
            </div>
        `);
        container.append(item);
    });
}

function setRules() {
    const container = $('.popup-rules');
    container.html('');
    $.each(Config.Rules || [], function(i, rule) {
        const item = $('<div></div>').addClass('server-rule');
        item.html(`
            <div class="server-rule-title">${rule.title}</div>
            <hr>
            <div class="server-rule-description">${rule.description}</div>
        `);
        container.append(item);
    });
}

function setLinks() {
    let linksHtml = '';
    if (Config.TebexLink) {
        linksHtml += `<div id="tebex-store-link" class="button darker social-bigger" onclick="openLink('${Config.TebexLink}', true)"><i class="fa-solid fa-earth-americas"></i>${(Config.Translations && Config.Translations.tebexlink) || 'Store'}</div>`;
    }
    if (Config.Links) {
        for (let key in Config.Links) {
            const link = Config.Links[key];
            if (link.url) {
                linksHtml += `<div class="button darker social" onclick="openLink('${key}')"><i class="${link.icon}"></i></div>`;
            }
        }
    }
    $('#social-media').html(linksHtml);
}

function openLink(key, isDirect = false) {
    if (isDirect) {
        if (typeof window.invokeNative === 'function') {
            window.invokeNative('openUrl', key);
        } else {
            window.open(key, '_blank');
        }
    } else {
        const linkObj = Config.Links && Config.Links[key];
        if (linkObj && linkObj.url) {
            if (typeof window.invokeNative === 'function') {
                window.invokeNative('openUrl', linkObj.url);
            } else {
                window.open(linkObj.url, '_blank');
            }
        }
    }
}

function startSlideshow() {
    const path = 'assets/images/';
    const prefix = 'background';
    const ext = '.jpg';
    let slideIndex = 1;

    function nextSlide() {
        let nextSrc = path + prefix + slideIndex + ext;
        checkImage(nextSrc, function(exists) {
            if (!exists) {
                slideIndex = 1;
                nextSrc = path + prefix + slideIndex + ext;
            }
            const img = $('<img>', {
                src: nextSrc,
                class: 'vid',
                alt: 'background'
            });
            const filterVal = Config.AddBlurToBackground ? 'blur(8px)' : 'none';
            img.css('filter', filterVal);

            $('#background img').fadeOut(1000, function() {
                $(this).remove();
                $('#background').append(img);
                img.hide().fadeIn(1000);
            });
        });
        slideIndex++;
    }

    function checkImage(url, callback) {
        const img = new Image();
        img.onload = () => callback(true);
        img.onerror = () => callback(false);
        img.src = url;
    }

    nextSlide();
    setInterval(nextSlide, (Config.SlideshowUpdateInterval || 5) * 1000);
}

function setUITranslations() {
    const trans = Config.Translations || {};
    $('#logo-title').html(trans.servername || '');
    $('#logo-description').html(trans.serverdesc || '');
    $('#openUpdates').html('<i class="fa-regular fa-newspaper"></i>' + (trans.updates || 'Updates'));
    $('#openTeam').html('<i class="bi bi-people"></i>' + (trans.team || 'Team'));
    $('#openRules').html('<i class="bi bi-file-earmark-text"></i>' + (trans.rules || 'Rules'));
    $('#openKeyboard').html('<i class="fa-regular fa-keyboard"></i>' + (trans.keyboard || 'Keyboard'));
    $('#city-loading-text').html(trans.loading || 'Loading...');
}

const handlers = {
    loadProgress(data) {
        $('.loading-bar-fill').css('width', (data.loadFraction * 100) + '%');
        $('#loading-percentage').text(Math.round(data.loadFraction * 100) + '%');
    }
};

window.addEventListener('message', function(e) {
    if (e.data && e.data.eventName && handlers[e.data.eventName]) {
        handlers[e.data.eventName](e.data);
    }
});