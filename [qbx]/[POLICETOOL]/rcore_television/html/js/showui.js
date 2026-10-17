/* ==========================================================================
   RCORE TELEVISION - INTERACTIVE POPUP UI JAVASCRIPT
   ========================================================================== */

(function () {
    let currentTvData = null;
    let windowSizes = ['size-standard', 'size-wide', 'size-compact'];
    let currentSizeIndex = 0;
    let showingChannels = false;

    // Helper: Parse YouTube URL and extract Video ID & Timestamp
    function parseYoutubeUrl(url) {
        if (!url) return null;
        let videoId = null;
        let time = 0;

        // Match formats: youtube.com/watch?v=ID, youtu.be/ID, youtube.com/embed/ID, youtube.com/shorts/ID
        let regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|shorts\/|watch\?v=|\&v=)([^#\&\?]*).*/;
        let match = url.match(regExp);

        if (match && match[2].length === 11) {
            videoId = match[2];
        }

        // Check for timestamp (t=XX or start=XX)
        let timeMatch = url.match(/[?&](t|start)=(\d+)/);
        if (timeMatch && timeMatch[2]) {
            time = parseInt(timeMatch[2], 10);
        }

        return videoId ? { videoId, time } : null;
    }

    // Helper: Parse Twitch URL
    function parseTwitchUrl(url) {
        if (!url || url.indexOf('twitch.tv') === -1) return null;
        let parts = url.split('/');
        let channel = parts[parts.length - 1].split('?')[0];
        return channel || null;
    }

    // Helper: Is video format
    function isDirectVideo(url) {
        if (!url) return false;
        let clean = url.toLowerCase().split('?')[0];
        return clean.endsWith('.mp4') || clean.endsWith('.webm') || clean.endsWith('.ogg') || clean.endsWith('.mov');
    }

    // Helper: Post NUI Callback with FiveM resource name
    function postNui(event, data) {
        $.post(`https://${GetParentResourceName ? GetParentResourceName() : 'rcore_television'}/${event}`, JSON.stringify(data || {}));
    }

    // Close TV Popup
    window.closeTvPopup = function () {
        $('#tv-popup-overlay').removeClass('active');
        // Clear iframe and video to stop playback sound in NUI
        $('#tv-frame-container').empty();
        showingChannels = false;
        postNui('close_tv_popup', {});
    };

    // Render TV Screen Content
    function renderScreen(url, time, isStandby) {
        const $container = $('#tv-frame-container');
        $container.empty();

        if (isStandby || !url || url.trim() === '') {
            showChannelsGrid();
            return;
        }

        $('#tv-standby-container').hide();
        $container.show();

        const yt = parseYoutubeUrl(url);
        if (yt) {
            const startTime = (time && time > 0) ? time : yt.time;
            const embedUrl = `https://www.youtube.com/embed/${yt.videoId}?autoplay=1&start=${startTime}&enablejsapi=1`;
            const $iframe = $('<iframe>', {
                class: 'tv-frame',
                src: embedUrl,
                allow: 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
                allowfullscreen: true
            });
            $container.append($iframe);
            $('#tv-current-title').text('YouTube Player');
            $('#tv-current-subtitle').text(url);
            return;
        }

        const twitchChannel = parseTwitchUrl(url);
        if (twitchChannel) {
            const embedUrl = `https://player.twitch.tv/?channel=${twitchChannel}&parent=localhost&autoplay=true`;
            const $iframe = $('<iframe>', {
                class: 'tv-frame',
                src: embedUrl,
                allowfullscreen: true
            });
            $container.append($iframe);
            $('#tv-current-title').text('Twitch Live: ' + twitchChannel);
            $('#tv-current-subtitle').text(url);
            return;
        }

        if (isDirectVideo(url)) {
            const $video = $('<video>', {
                class: 'tv-video-element',
                controls: true,
                autoplay: true
            });
            const $source = $('<source>', {
                src: url
            });
            $video.append($source);
            $container.append($video);
            if (time && time > 0) {
                $video[0].currentTime = time;
            }
            $('#tv-current-title').text('Direct Video');
            $('#tv-current-subtitle').text(url);
            return;
        }

        // Generic Web URL or NUI page
        const $iframe = $('<iframe>', {
            class: 'tv-frame',
            src: url,
            allowfullscreen: true
        });
        $container.append($iframe);
        $('#tv-current-title').text('Web View');
        $('#tv-current-subtitle').text(url);
    }

    // Show Default Channels Grid
    function showChannelsGrid() {
        showingChannels = true;
        $('#tv-frame-container').empty().hide();
        $('#tv-standby-container').show();
        $('#tv-current-title').text('TV Standby / Danh sách kênh');
        $('#tv-current-subtitle').text('Chọn kênh hoặc nhập link bên trên để phát');

        const $grid = $('#tv-channels-list');
        $grid.empty();

        const videos = (currentTvData && currentTvData.listVideos) || [];
        if (videos.length === 0) {
            $grid.append('<div style="color: #9ca3af; text-align: center; grid-column: 1/-1;">Chưa có danh sách kênh mặc định</div>');
            return;
        }

        videos.forEach((video, index) => {
            if (!video || !video.name) return;
            const $card = $('<div>', { class: 'tv-channel-card' });
            const iconHtml = `<div class="tv-channel-icon"><i class="${video.icon || 'fas fa-tv'}"></i></div>`;
            const infoHtml = `
                <div class="tv-channel-info">
                    <div class="tv-channel-name">${video.name}</div>
                    <div class="tv-channel-num">Kênh ${index + 1}</div>
                </div>
            `;
            $card.html(iconHtml + infoHtml);

            $card.on('click', function () {
                if (video.url && video.url.trim() !== '') {
                    playUrl(video.url);
                } else {
                    $('#tv-url-input-field').val('').focus();
                }
            });

            $grid.append($card);
        });
    }

    // Play URL Action
    function playUrl(url) {
        if (!url || url.trim() === '') return;
        url = url.trim();
        $('#tv-url-input-field').val(url);
        postNui('tv_popup_play_url', { url: url });
        renderScreen(url, 0, false);
    }

    // Initialize DOM Events
    $(document).ready(function () {
        // Close buttons
        $('#tv-btn-close-popup').on('click', function () {
            closeTvPopup();
        });

        // ESC key to close
        $(document).on('keyup', function (e) {
            if (e.key === 'Escape' || e.keyCode === 27) {
                if ($('#tv-popup-overlay').hasClass('active')) {
                    closeTvPopup();
                }
            }
        });

        // Play Button in Header
        $('#tv-btn-submit-url').on('click', function () {
            const url = $('#tv-url-input-field').val();
            playUrl(url);
        });

        // Enter key in URL input
        $('#tv-url-input-field').on('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                const url = $(this).val();
                playUrl(url);
            }
        });

        // Window size toggle
        $('#tv-btn-toggle-size').on('click', function () {
            const $window = $('#tv-popup-main-window');
            $window.removeClass(windowSizes[currentSizeIndex]);
            currentSizeIndex = (currentSizeIndex + 1) % windowSizes.length;
            $window.addClass(windowSizes[currentSizeIndex]);
        });

        // Reload Screen
        $('#tv-btn-reload-screen').on('click', function () {
            if (currentTvData && currentTvData.url) {
                renderScreen(currentTvData.url, currentTvData.time || 0, false);
            }
        });

        // Toggle Channels Grid
        $('#tv-btn-toggle-channels').on('click', function () {
            if (showingChannels) {
                if (currentTvData && currentTvData.url && currentTvData.url.trim() !== '') {
                    showingChannels = false;
                    renderScreen(currentTvData.url, currentTvData.time || 0, false);
                }
            } else {
                showChannelsGrid();
            }
        });

        // Stop TV Button
        $('#tv-btn-stop-playback').on('click', function () {
            postNui('tv_popup_stop', {});
            showChannelsGrid();
        });

        // Volume Slider
        $('#tv-volume-slider-input').on('input change', function () {
            const vol = parseInt($(this).val(), 10);
            $('#tv-volume-percent-text').text(vol + '%');
            postNui('tv_popup_set_volume', { volume: vol });
        });
    });

    // Listen for FiveM NUI Messages
    window.addEventListener('message', function (event) {
        const data = event.data;
        if (!data) return;

        if (data.type === 'open_tv_popup') {
            currentTvData = data;
            const volume = typeof data.volume === 'number' ? data.volume : 30;
            $('#tv-volume-slider-input').val(volume);
            $('#tv-volume-percent-text').text(volume + '%');
            $('#tv-url-input-field').val(data.url || '');

            $('#tv-popup-overlay').addClass('active');

            if (data.isStandby || !data.url || data.url.trim() === '') {
                showChannelsGrid();
            } else {
                renderScreen(data.url, data.time || 0, false);
            }
        } else if (data.type === 'close_tv_popup') {
            $('#tv-popup-overlay').removeClass('active');
            $('#tv-frame-container').empty();
            showingChannels = false;
        }
    });
})();
