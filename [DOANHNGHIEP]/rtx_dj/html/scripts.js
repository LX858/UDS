var soundhandler = {}

let isPlaying = false;

let djcEditMode   = false;      
let djcEditingId  = null;       
let djcLocations  = [];         

  const DEFAULT_PRIMARY = '#ff66ff';
  const LS_KEY = 'dj_primary_color';
const COLOR_KEY = 'dj_primary_color';

const isHex = (s) => /^#[0-9A-Fa-f]{6}$/.test(String(s || ''));
const setPrimary = (hex) => document.documentElement.style.setProperty('--primary', hex); 

function closeMain() {
    $("body").css("display", "none");
}

function openMain() {
    $("body").css("display", "block");
}

var djresourcename = "rtx_dj";

const djcState = {
  name: '',
  location: null,
  maxDistance: 500,
  everyone: false,
  permissions: [], 
  _nextUid: 10,
  effects: {
	smoke:     { enabled:false, locations:[] }, 
	lights:    { enabled:false, locations:[] },
	lasers:    { enabled:false, locations:[] },
	particles: { enabled:false, entries:[] }    
  }
};

let djcTempPos = null, djcTempRot = null, djcCtx = null;

const djcFmtPos = v => `x:${(+v.x).toFixed(2)} y:${(+v.y).toFixed(2)} z:${(+v.z).toFixed(2)}`;

function formatQueueName(name, maxLen = 30) {
  const glyphs = Array.from(String(name || '').trim()); 
  if (glyphs.length > maxLen) {
    return {
      text: glyphs.slice(0, maxLen).join('') + '…',
      cls: 'queue-name--compact'
    };
  }
  return { text: glyphs.join(''), cls: '' };
}

function loadQueue(songs) {
  const $container = $("#queue-list");
  $container.empty();

  if (!songs || songs.length === 0) {
    $container.append('<div class="queue-empty">Queue is empty</div>');
    return;
  }

  songs.forEach((song, index) => {
    const { text: displayName, cls } = formatQueueName(song.name, 30);

    $container.append(`
      <div class="queue-item ${index === 0 ? 'active' : ''}" data-id="${song.id}">
        <div class="queue-cover">
          <i class="fas fa-music"></i>
        </div>
        <div class="queue-details">
          <div class="queue-name ${cls}" title="${$('<div>').text(song.name || '').html()}">${displayName}</div>
          <div class="queue-artist">${song.artist || ''}</div>
        </div>
        <div class="queue-duration">${song.duration || ''}</div>
      </div>
    `);
  });
}

function djcOpenHome() {

  $('#djc-home').show();
  $('#djc-app').hide();
  $.post('https://' + djresourcename + '/requestLocations', JSON.stringify({}));
}

function djcOpenCreatorCreate() {
  djcEditMode  = false;
  djcEditingId = null;

  djcState.name = '';
  djcState.location = null;
  djcState.maxDistance = 500;
  djcState.everyone = false;
  djcState.permissions = [];
  djcState.effects.smoke     = { enabled:false, locations:[] };
  djcState.effects.lights    = { enabled:false, locations:[] };
  djcState.effects.lasers    = { enabled:false, locations:[] };
  djcState.effects.particles = { enabled:false, entries:[] };

  $('#djc-input-name').val('');
  $('#djc-coord-status').text('Not set');

  $('#djc-range-maxdist').val(500);
  djcSetBubble(); 

  $('#djc-toggle-everyone').prop('checked', false);

  $('#djc-toggle-smoke').prop('checked', false);
  $('#djc-toggle-lights').prop('checked', false);
  $('#djc-toggle-lasers').prop('checked', false);
  $('#djc-toggle-particles').prop('checked', false);

  $('#djc-perm-list').empty();

  $('.djc-title h1').text('DJ LOCATION CREATOR');
  $('#djc-btn-create').html('<i class="fa-solid fa-check"></i> CREATE');

  $('#djc-home').hide();
  openMain();
  $('#djc-app').show();
}

function djcOpenCreatorEdit(loc) {
  djcEditMode  = true;
  djcEditingId = loc._id ?? loc.id ?? null;

  djcLoadStateFromLocation(loc); 
	$.post('https://' + djresourcename + '/editlocationstoggle', JSON.stringify({
		locationdiddata: djcEditingId
	}));	
  $('.djc-title h1').text('DJ LOCATION EDITOR');
  $('#djc-btn-create').html('<i class="fa-solid fa-save"></i> SAVE');

  $('#djc-home').hide();
  openMain();
  $('#djc-app').show();
}

function djcLoadStateFromLocation(loc) {
  djcState.name        = loc?.label || '';
  djcState.location    = loc?.coords ? { x:loc.coords.x, y:loc.coords.y, z:loc.coords.z } : null;
  djcState.maxDistance = Number(loc?.maxdistance) || 500;

  const everyone = !!(loc?.permissions?.everyone);
  djcState.everyone = everyone;
  djcState.permissions = [];
  if (Array.isArray(loc?.permissions?.permissions)) {
    for (const p of loc.permissions.permissions) {
      if (p?.permissiontype && p?.permission) {
        djcState.permissions.push({ type:p.permissiontype, value:p.permission });
      }
    }
  }

  const mapLocs = (arr)=>Array.isArray(arr)?arr.map((o,idx)=>({
    id:o.id ?? idx+1,
    pos:{x:o.coords.x,y:o.coords.y,z:o.coords.z},
    rot:{x:o.rotation.x,y:o.rotation.y,z:o.rotation.z}
  })) : [];

  djcState.effects.smoke.enabled    = !!loc?.smoke?.enabled;
  djcState.effects.smoke.locations  = mapLocs(loc?.smoke?.locations);

  djcState.effects.lights.enabled   = !!loc?.lights?.enabled;
  djcState.effects.lights.locations = mapLocs(loc?.lights?.locations);

  djcState.effects.lasers.enabled   = !!loc?.lasers?.enabled;
  djcState.effects.lasers.locations = mapLocs(loc?.lasers?.locations);

  djcState.effects.particles.enabled = !!loc?.particles?.enabled;
  djcState.effects.particles.entries = mapLocs(loc?.particles?.locations).map(e=>({
    id:e.id, pos:e.pos, rot:e.rot,
    name:(loc?.particles?.locations?.[0]?.animname)||'muz_xs_turret_flamethrower_looping',
    dict:(loc?.particles?.locations?.[0]?.animdict)||'weap_xs_vehicle_weapons'
  }));

  $('#djc-input-name').val(djcState.name);
  $('#djc-coord-status').text(djcState.location ? djcFmtPos(djcState.location) : 'Not set');
  $('#djc-range-maxdist').val(djcState.maxDistance); djcSetBubble();
  $('#djc-toggle-everyone').prop('checked', djcState.everyone);

  $('#djc-toggle-smoke').prop('checked', djcState.effects.smoke.enabled);
  $('#djc-toggle-lights').prop('checked', djcState.effects.lights.enabled);
  $('#djc-toggle-lasers').prop('checked', djcState.effects.lasers.enabled);
  $('#djc-toggle-particles').prop('checked', djcState.effects.particles.enabled);
}

function djcRenderHomeList(list){
  const $c = $('#djc-home-list').empty();
  if (!list || !list.length){
    $c.append('<div class="djc-list-row"><span class="djc-subtitle">No locations yet.</span><span></span></div>');
    return;
  }
  list.forEach(loc=>{
    const id   = loc._id ?? loc.id ?? '';
    const name = loc.label || '(unnamed)';
    const pos  = loc.coords ? `x:${(+loc.coords.x).toFixed(1)} y:${(+loc.coords.y).toFixed(1)} z:${(+loc.coords.z).toFixed(1)}` : '';
    $c.append(`
      <div class="djc-list-row">
        <div><span style="color:#ffffff"><strong>${name}</strong></span><div style="color:#aaa;font-size:.8rem">${pos}</div></div>
        <div style="display:flex; gap:8px">
          <button class="djc-btn djc-home-edit" data-id="${id}"><i class="fa-solid fa-pen"></i> Edit</button>
          <button class="djc-btn djc-btn-danger djc-home-del" data-id="${id}"><i class="fa-solid fa-trash"></i> Delete</button>
        </div>
      </div>
    `);
  });
}

$('#djc-home-close').on('click', function(){
  $('#djc-home').hide();
  $.post('https://'+djresourcename+'/closecreator', JSON.stringify({}));
});

$('#djc-home-create').on('click', djcOpenCreatorCreate);

$('#djc-home-list')
  .on('click', '.djc-home-edit', function(){
    const id = $(this).data('id');
    const loc = djcLocations.find(l => String(l._id??l.id) === String(id));
    if (!loc) return;
    djcOpenCreatorEdit(loc);
  })
  .on('click', '.djc-home-del', function(){
    const id = $(this).data('id');
    $.post('https://' + djresourcename + '/removeLocation', JSON.stringify({ id }));
    djcLocations = djcLocations.filter(l => String(l._id??l.id) !== String(id));
  $('#djc-home').hide();
  $.post('https://'+djresourcename+'/closecreator', JSON.stringify({}));
  });

function formatNowTitle(name, maxLen = 30){
  const glyphs = Array.from(String(name || '').trim());
  if (glyphs.length > maxLen){
    return { text: glyphs.slice(0, maxLen).join('') + '…', compact: true, full: glyphs.join('') };
  }
  return { text: glyphs.join(''), compact: false, full: glyphs.join('') };
}

function clampPct(v){
  const n = parseFloat(v);
  if (Number.isFinite(n)) return Math.max(0, Math.min(100, n)) + '%';

  return String(v || '0%');
}

function updateNowPlaying(song) {
  const titleInfo = formatNowTitle(song?.name, 30);
  const $name = $("#current-song");
  $name
    .text(titleInfo.text)
    .toggleClass('song-name--compact', titleInfo.compact)
    .attr('title', titleInfo.full); 

  if (song?.artist != null) {
    $("#current-artist").text(song.artist);
  }

  if (song?.currenttime != null) {
    $("#current-time").text(song.currenttime);
  }
  if (song?.maxduration != null) {
    $("#total-time").text(song.maxduration);
  }

  if (song?.recalculatedpercentage != null) {
    $("#progress-bar").css("width", clampPct(song.recalculatedpercentage));
  }
}

createjs.Sound.registerPlugins([createjs.WebAudioPlugin, createjs.HTMLAudioPlugin]);
createjs.Sound.alternateExtensions = ["mp3","wav","ogg"];

const registered = new Set();

function playSound(src, volume = 1, channels = 6) {
  const id = src; 

  if (!registered.has(id)) {
    registered.add(id);
    createjs.Sound.registerSound({ src, id, data: channels });
  }

  if (createjs.Sound.loadComplete(id)) {
    return createjs.Sound.play(id, { interrupt: createjs.Sound.INTERRUPT_ANY, volume });
  }

  const onLoad = function (e) {
    if (e.id !== id) return; 
    createjs.Sound.off("fileload", onLoad);
    createjs.Sound.play(id, { interrupt: createjs.Sound.INTERRUPT_ANY, volume });
  };
  createjs.Sound.on("fileload", onLoad);

  return null;
}
$("#queue-list").on("click", ".queue-item", function() {
    const songId = $(this).data("id");
	$.post('https://' + djresourcename + '/removequeuemusic', JSON.stringify({
		queueiddata: songId
	}));		
});

(function () {

  const $picker = $('#primary-color');
  if (!$picker.length) return; 

  const isHex = (s) => /^#[0-9A-Fa-f]{6}$/.test(String(s||''));
  const setPrimary = (hex) => document.documentElement.style.setProperty('--primary', hex);

  const saved = localStorage.getItem(LS_KEY);
  const startColor = isHex(saved) ? saved : DEFAULT_PRIMARY;
  $picker.val(startColor);
  setPrimary(startColor);

  $picker.on('input change', function () {
    const v = $(this).val();
    if (isHex(v)) setPrimary(v);
  });

  $('#save-position').on('click', function () {
    const v = $picker.val();
    if (isHex(v)) localStorage.setItem(LS_KEY, v);
  });

  $('#reset-position').on('click', function () {
    localStorage.removeItem(LS_KEY);
    $picker.val(DEFAULT_PRIMARY).trigger('change');
  });
})();

function refreshScaleValue() {
  const slider = document.getElementById('scale-range');
  const out = document.getElementById('scale-value');
  if (!slider || !out) return;
  const v = parseFloat(slider.value);
  out.textContent = (Number.isFinite(v) ? Math.round(v * 100) : 100) + '%';
}

function loadPrimaryColor() {

  const isHex = (s) => /^#[0-9A-Fa-f]{6}$/.test(String(s || ''));
  const setPrimary = (hex) => document.documentElement.style.setProperty('--primary', hex);

  const saved = localStorage.getItem(LS_KEY);
  const color = isHex(saved) ? saved : DEFAULT_PRIMARY;

  setPrimary(color);

  const picker = document.getElementById('primary-color');
  if (picker) {
    picker.value = color;
  }
}

function getSavedSettings() {
  const zoom = parseFloat(localStorage.getItem('djZoom')) || 1.0;
  const posX = localStorage.getItem('djPosX');
  const posY = localStorage.getItem('djPosY');
  const color = localStorage.getItem(COLOR_KEY) || DEFAULT_PRIMARY;
  return { zoom, posX: posX ? parseFloat(posX) : null, posY: posY ? parseFloat(posY) : null, color };
}

function getZoom($el){
  const z = parseFloat($el.css('zoom'));
  return Number.isFinite(z) && z > 0 ? z : 1.0;
}

function getCenteredPosPx($el){
  const $host = $('#djinterfaceshow');
  const restore = [];

  if ($host.css('display') === 'none') {
    $host.css({ display:'block', visibility:'hidden' });
    restore.push($host);
  }

  const wasHidden = $el.is(':hidden');
  if (wasHidden) {
    $el.css({ display:'block', visibility:'hidden' });
    restore.push($el);
  }

  const zoom = getZoom($el);
  const w = $el.outerWidth()  * zoom;
  const h = $el.outerHeight() * zoom;

  const x = Math.max(0, (window.innerWidth  - w) / 2);
  const y = Math.max(0, (window.innerHeight - h) / 2);

  for (const $n of restore) $n.css({ display:'', visibility:'' });

  return { left: x, top: y };
}

function ensureInViewport($el){
  const zoom = getZoom($el);
  const w = $el.outerWidth()  * zoom;
  const h = $el.outerHeight() * zoom;

  let l = parseFloat($el.css('left')) || 0;
  let t = parseFloat($el.css('top'))  || 0;

  const maxL = Math.max(0, window.innerWidth  - w);
  const maxT = Math.max(0, window.innerHeight - h);

  l = Math.min(Math.max(0, l), maxL);
  t = Math.min(Math.max(0, t), maxT);

  $el.css({ left: l + 'px', top: t + 'px' });
}

function applySettings({ zoom, posX, posY, color }) {
  const $c = $('.dj-container');
  zoom = Number.isFinite(parseFloat(zoom)) ? parseFloat(zoom) : 1.0;
  $c.css({ zoom });

  if (posX == null || posY == null || isNaN(posX) || isNaN(posY)) {

    const { left, top } = getCenteredPosPx($c);
    $c.css({ left: left + 'px', top: top + 'px' });
  } else {
    $c.css({ left: posX + 'px', top: posY + 'px' });
    ensureInViewport($c);
  }

  $('#scale-range').val(zoom);
  $('#scale-value').text(Math.round(zoom * 100) + '%');

  const finalColor = isHex(color) ? color : DEFAULT_PRIMARY;
  setPrimary(finalColor);
  const picker = document.getElementById('primary-color');
  if (picker) picker.value = finalColor;
}

function openDJMenu() {
  $("#djinterfaceshow").fadeIn(300); 
}

function closeDJMenu() {
  $("#djinterfaceshow").fadeOut(200); 
}

$(document).ready(function() {

      let currentTime = 0;
let playlists = [];

function loadPlaylistsFromStorage() {
  const data = localStorage.getItem("djPlaylists");
  if (data) {
    try {
      let parsed = JSON.parse(data);

      parsed = parsed.filter(p => typeof p.name === "string" && Array.isArray(p.urls));

      playlists = parsed;
      savePlaylistsToStorage(); 
    } catch (err) {
      console.warn("Chyba při načítání playlistů:", err);
      playlists = [];
      localStorage.removeItem("djPlaylists");
    }
  }
}

function savePlaylistsToStorage() {
  localStorage.setItem("djPlaylists", JSON.stringify(playlists));
}
function loadPlaylists() {
  const $list = $('#playlist-list');
  $list.empty();

  playlists.forEach((playlist, index) => {
    $list.append(`
      <div class="playlist-item" data-index="${index}">
        <div class="playlist-name">${playlist.name}</div>
        <div class="playlist-count">${playlist.urls.length} songs</div>
        <button class="delete-playlist-btn" title="Delete playlist">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    `);
  });

  $(".delete-playlist-btn").click(function(e) {
    e.stopPropagation();
    const index = $(this).closest('.playlist-item').data('index');
    playlists.splice(index, 1);
    savePlaylistsToStorage();
    loadPlaylists();
  });
}

async function loadAndGetDurationAndFilename(url) {
    return new Promise((resolve, reject) => {
        const id = "temp_" + Date.now(); 

        const filename = url.split('/').pop().split('?')[0].split('#')[0];

        createjs.Sound.registerSound(url, id);

        createjs.Sound.on("fileload", function onFileLoad(event) {
            if (event.id !== id) return;

            createjs.Sound.off("fileload", onFileLoad); 

            const instance = createjs.Sound.play(id, { volume: 0 });

            const checkDuration = () => {
                if (instance.duration && !isNaN(instance.duration)) {
                    instance.stop();
                    createjs.Sound.removeSound(id);

                    resolve({
                        duration: instance.duration, 
                        filename: filename
                    });
                } else {
                    setTimeout(checkDuration, 100);
                }
            };

            checkDuration();
        });

        setTimeout(() => reject("Načítání zvuku selhalo nebo trvá příliš dlouho."), 10000);
    });
}

      $("#play-btn").click(function() {
        isPlaying = !isPlaying;
        $(this).html(`<i class="fas fa-${isPlaying ? 'pause' : 'play'}"></i>`);
		$.post('https://' + djresourcename + '/resume', JSON.stringify({
			resumedata: isPlaying
		}));
      });

      $("#new-playlist").click(function() {
        $("#playlist-modal").fadeIn();
      });

      $("#close-playlist-modal, #cancel-playlist").click(function() {
        $("#playlist-modal").fadeOut();
      });

$("#save-playlist").click(function() {
  const name = $("#playlist-name").val().trim();
  const urlsRaw = $("#playlist-urls").val().trim();

  if (name) {
    const urls = urlsRaw.split('\n').map(url => url.trim()).filter(url => url !== "");

    playlists.unshift({ name, urls }); 
    savePlaylistsToStorage();
    loadPlaylists();

    $("#playlist-name").val("");
    $("#playlist-urls").val("");
    $("#playlist-modal").fadeOut();
  }
});

  $(".color-input").click(function(e) {
	e.stopPropagation();
  });

  $(".color-preview").click(function(e) {
	$(this).find(".color-input").click();
  });

  $(".color-input").change(function() {
	const color = $(this).val();
	$(this).parent().css("color", color);
  });

  $("#clear-queue").click(function() {
	$.post('https://'+djresourcename+'/clearqueue', JSON.stringify({}));
  });

  $("#close-btn").click(function() {

	$.post('https://'+djresourcename+'/closedjmenu', JSON.stringify({}));
	$("#djinterfaceshow").fadeOut();
  });

  $(".effect").click(function(e) {
	if (!$(e.target).hasClass("color-preview") && !$(e.target).hasClass("color-input")) {
	  e.preventDefault();
	}
  });
  $("#volume-slider").on("input", function() {
	$.post('https://' + djresourcename + '/volumechange', JSON.stringify({
		volumedata: $(this).val()
	}));	
  });

  $("#distance-slider").on("input", function() {
	$.post('https://' + djresourcename + '/radiuschange', JSON.stringify({
		radiusdata: $(this).val()
	}));		
  });

  $("#play-pause-btn").click(function() {
	$(this).find("i").toggleClass("fa-play fa-pause");

  });

  $("#stop-btn").click(function() {
	$.post('https://'+djresourcename+'/stopsong', JSON.stringify({}));
  });

  $("#prev-btn").click(function() {
	$.post('https://' + djresourcename + '/forwardbackward', JSON.stringify({
		forwardbackwarddata: false
	}));
  });

  $("#next-btn").click(function() {
	$.post('https://' + djresourcename + '/forwardbackward', JSON.stringify({
		forwardbackwarddata: true
	}));
  });

	$("#loop-btn").click(function() {
		$(this).toggleClass("active");

		const isActive = $(this).hasClass("active");

		$.post('https://' + djresourcename + '/loopenable', JSON.stringify({
			loopdata: isActive
		}));
	});

  $("#volume-slider").on("input", function() {
	const volume = $(this).val();

  });

  $("#distance-slider").on("input", function() {
	const distance = $(this).val();

  });

  $(".color-input").change(function() {
	const effect = $(this).attr("id").replace("-color", "");
	const color = $(this).val();
	$(`#${effect}-color-preview`).css("--color-preview", color);

  });

$(document).on("click", ".playlist-item", async function () {
  const index = $(this).data("index");
  const playlist = playlists[index];

  if (!playlist || !Array.isArray(playlist.urls)) {
    return;
  }

  const results = await Promise.all(
    playlist.urls.map(url =>
      classifyAndCheckSoundUrl(url).catch(() => ({ ok: false }))
    )
  );

  const validTracks = results
    .map((res, i) => ({
      ok: res.ok,
      title: res.title,
      type: res.type,
      durationSec: res.durationSec,
      source: res.source
    }))
    .filter(t => t.ok);

  for (const t of validTracks) {
    $.post('https://' + djresourcename + '/addsongtoqueue', JSON.stringify({
      durationdata: t.durationSec,
      titledata: t.title,
      typedata: t.type,
      linkdata: t.source
    }));
    await new Promise(r => setTimeout(r, 100)); 
  }
});

loadPlaylistsFromStorage();
loadPlaylists();	  
window.addEventListener("message", function (event) {
  const item = event.data;
	if (item.message == "infonotifyshow") {
		document.getElementsByClassName("infonotifytext")[0].innerHTML = item.infonotifytext;
		openMain();
		$("#infonotifyshow").show();	
	}	 

	if (item.message == "hidenotify") {
		$("#infonotifyshow").hide();
	}	

	if (item.message == "djshow") {
		  openMain();
		  loadPlaylists();

		  openDJMenu();     
		  setTimeout(() => {                   
			const saved = getSavedSettings();
			applySettings(saved);
		  }, 0);

		$(".header h1").text(item.djlabel);
		if (item.loop === true) {
			$("#loop-btn").addClass("active");
		} else {
			$("#loop-btn").removeClass("active");
		}	
		if (item.stopped === true) {
			$("#play-btn").html('<i class="fas fa-play"></i>');
			isPlaying = false;
		} else {
			$("#play-btn").html('<i class="fas fa-pause"></i>');
			isPlaying = true;
		}
		$("#distance-slider").attr("max", item.maxradius);
		$("#radius-value").text(Math.round(item.radiusvalue) + "m");
		$("#distance-slider").val(item.radiusvalue);	
		$("#volume-value").text(item.volumedata + "%");
		$("#volume-slider").val(item.volumedata);		
		if (item.smoke === true) {
			$("#fog-effect").show();	
		} else {
			$("#fog-effect").hide();	
		}	
		if (item.particles === true) {
			$("#particles-effect").show();	
		} else {
			$("#particles-effect").hide();	
		}	
		if (item.lights === true) {
			$("#lights-effect").show();	
		} else {
			$("#lights-effect").hide();	
		}	
		if (item.lasers === true) {
			$("#lasers-effect").show();	
		} else {
			$("#lasers-effect").hide();	
		}			
	  const toHex = (c) => {
		if (!c) return '#ffffff';
		const p = n => Math.max(0, Math.min(255, n|0)).toString(16).padStart(2,'0');
		return `#${p(c.r)}${p(c.g)}${p(c.b)}`;
	  };

	  if (item.effects) {

		if (item.effects.lights) {
		  $('#lights-toggle').prop('checked', !!item.effects.lights.enabled);
		  $('#lights-move').prop('checked', !!item.effects.lights.move);
		  const hx = toHex(item.effects.lights.color);
		  $('#lights-color').val(hx);
		  $('#lights-effect .color-preview').css('color', hx);
		}

		if (item.effects.fog) {
		  $('#fog-toggle').prop('checked', !!item.effects.fog.enabled);
		  const hx = toHex(item.effects.fog.color);
		  $('#fog-color').val(hx);
		  $('#fog-effect .color-preview').css('color', hx);
		}

		if (item.effects.lasers) {
		  $('#lasers-toggle').prop('checked', !!item.effects.lasers.enabled);
		  $('#lasers-move').prop('checked', !!item.effects.lasers.move);
		  const hx = toHex(item.effects.lasers.color);
		  $('#lasers-color').val(hx);
		  $('#lasers-effect .color-preview').css('color', hx);
		}

		if (item.effects.particles) {
		  $('#particles-toggle').prop('checked', !!item.effects.particles.enabled);
		}
	  }		
	}	

	if (item.message == "closedjmenu") {
		closeDJMenu();
	}	

	if (item.message == "updatedjmenudata") {
		$("#songcontainershow").show();
		updateNowPlaying(item);
	}	

	if (item.message == "playsoundboard") {
		playSound(item.soundsrc, item.soundvolume);
	}		

	if (item.message === "updatesoundboard") {
	  const grid = $("#sound-grid");
	  grid.empty();

	  item.soundboard.forEach((sound) => {
		const button = `
		  <button class="sound-btn" data-id="${sound.id}">
			<i class="${sound.soundicon}"></i>
			<span>${sound.soundlabel}</span>
		  </button>
		`;
		grid.append(button);
	  });

	}

	if (item.message == "updatequeue") {
		loadQueue(item.queuetable);
	}		

	if (item.message == "updatesettings") {
		$("#radius-value").text(Math.round(item.radiusvalue) + "m");
		$("#distance-slider").val(item.radiusvalue);	
		$("#volume-value").text(item.volumedata + "%");
		$("#volume-slider").val(item.volumedata);		
	}		

	if (item.message == "hidesonginfo") {
		$("#songcontainershow").hide();
	}			

	if (item.message == "djcreatorshow") {
	  openMain();
	  djcOpenHome();
	}	

	if (item.message == "setlocations") {
	  djcLocations = Array.isArray(item.locations) ? item.locations : [];
	  djcRenderHomeList(djcLocations);
	}

	if (item.message == "hidecreator") {
		$("#djc-app").hide();
	}	

	if (item.message == "gizmoshow") {
		openMain();
		$("#gizmoshow").show();
	}	

	if (item.message == "updateinterfacedata") {
		djresourcename = item.djresourcenamedata;
		let root = document.documentElement;
		root.style.setProperty('--primary', item.interfacecolordata);	
	}	

    document.onkeyup = function (data) {
        if (open) {
            if (data.which == 27) {
				$.post('https://'+djresourcename+'/closemenuesc', JSON.stringify({}));
            }
        }	
	};	
});

$("#sound-grid").on("click", ".sound-btn", function() {
    const songId = $(this).data("id");
	$.post('https://' + djresourcename + '/soundboard', JSON.stringify({
		soundiddata: songId
	}));		
});

});

function ChangeDuration(e) {
  const bar = $(".progress-bar");
  const offset = bar.offset();
  const width = bar.width();
  const clickX = e.pageX - offset.left;
  const percentage = Math.max(0, Math.min(100, (clickX / width) * 100));

	$.post('https://'+djresourcename+'/durationchange', JSON.stringify({
		durationdata: percentage
	}));  		
}	

$(".add-to-queue").click(function () {
  $("#queue-modal").fadeIn();
});

$("#close-queue-modal, #cancel-queue-song").click(function () {
  $("#queue-modal").fadeOut();
});

function isAbsoluteHttpUrl(input) {
  try {
    const u = new URL(input, window.location.href);
    return (u.protocol === 'http:' || u.protocol === 'https:');
  } catch {
    return false;
  }
}

function getFileNameFromUrl(url) {
  try {
    const u = new URL(url);
    const path = u.pathname.split('/');
    const last = path[path.length - 1];
    return decodeURIComponent(last) || null;
  } catch {
    return null;
  }
}

function getYouTubeId(url) {
  const m = String(url).match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|shorts\/|v\/))([A-Za-z0-9_-]{11})/);
  return m ? m[1] : null;
}

function isMp3Url(url) {
  return /^https?:\/\/.+\.mp3(\?.*)?$/i.test(url);
}

function toMMSS(totalSeconds) {
  if (!Number.isFinite(totalSeconds) || totalSeconds <= 0) return "0:00";
  const s = Math.round(totalSeconds);
  const m = Math.floor(s / 60);
  const ss = String(s % 60).padStart(2, '0');
  return `${m}:${ss}`;
}

function loadYouTubeAPI() {
  return new Promise((resolve) => {
    if (window.YT && window.YT.Player) return resolve();
    const prev = window.onYouTubeIframeAPIReady;
    window.onYouTubeIframeAPIReady = function() {
      if (typeof prev === 'function') try { prev(); } catch {}
      resolve();
    };
  });
}

function checkYouTubePlayable(videoId, { timeoutMs = 8000 } = {}) {
  return new Promise(async (resolve) => {
    await loadYouTubeAPI();
    const containerId = `ytcheck_${videoId}_${Date.now()}`;
    const div = document.createElement('div');
    div.id = containerId;
    div.style.position = 'fixed';
    div.style.left = '-9999px';
    div.style.width = '1px';
    div.style.height = '1px';
    document.body.appendChild(div);
    let resolved = false;
    let player;
    const cleanup = () => { try { player && player.destroy(); } catch {} div.remove(); };
    const finish = (ok, durationSec = 0, title = `YouTube (${videoId})`) => {
      if (resolved) return;
      resolved = true;
      cleanup();
      resolve({ ok, type: 'youtube', videoId, source: videoId, durationSec, title });
    };
    const t = setTimeout(() => finish(false, 0), timeoutMs);
    player = new YT.Player(containerId, {
      width: '0',
      height: '0',
      videoId,
      playerVars: { playsinline: 1, controls: 0 },
      origin: window.location.origin,
      events: {
        onReady: (ev) => { try { ev.target.mute?.(); ev.target.playVideo(); } catch {} },
        onStateChange: (ev) => {
          if (ev.data === YT.PlayerState.PLAYING) {
            clearTimeout(t);
            let duration = 0;
            let title = `YouTube (${videoId})`;
            try {
              duration = Number(ev.target.getDuration()) || 0;
              const vd = ev.target.getVideoData?.();
              if (vd && vd.title) title = vd.title;
            } catch {}
            finish(true, duration, title);
          }
        },
        onError: () => { clearTimeout(t); finish(false, 0); }
      }
    });
  });
}

function getFileNameFromUrl(url) {
  try {
    const u = new URL(url);
    const path = u.pathname.split('/');
    const last = path[path.length - 1];
    return decodeURIComponent(last) || null;
  } catch {
    return null;
  }
}

function checkMp3Playable(url, { timeoutMs = 8000 } = {}) {
  return new Promise((resolve) => {
    const audio = new Audio();
    let resolved = false;
    const finish = (ok, durationSec = 0, title = null) => {
      if (resolved) return;
      resolved = true;
      cleanup();
      const fileName = title || getFileNameFromUrl(url) || "Unknown";
      resolve({ ok, type: 'mp3', source: url, durationSec, title: fileName });
    };
    const cleanup = () => { try { audio.src = ''; audio.removeAttribute('src'); audio.load(); } catch {} };
    const t = setTimeout(() => finish(false, 0), timeoutMs);
    audio.preload = 'metadata';
    audio.addEventListener('loadedmetadata', () => {
      clearTimeout(t);
      const d = Number(audio.duration);
      finish(Number.isFinite(d) && d > 0, d);
    });
    audio.addEventListener('error', () => { clearTimeout(t); finish(false, 0); });
    try { audio.src = url; audio.load(); } catch { clearTimeout(t); finish(false, 0); }
  });
}

async function classifyAndCheckSoundUrl(inputUrl) {
  if (!isAbsoluteHttpUrl(inputUrl)) return { ok: false, reason: 'Not an absolute HTTP(S) URL.' };
  const ytId = getYouTubeId(inputUrl);
  if (ytId) return await checkYouTubePlayable(ytId);
  if (isMp3Url(inputUrl)) return await checkMp3Playable(inputUrl);
  return { ok: false, reason: 'Only YouTube links or direct .mp3 files are supported.' };
}
$("#save-queue-song").off('click').on('click', async function () {
  const url = $("#queue-song-url").val().trim();
  if (!url) { console.log("Please enter a valid song URL."); return; }
  const $btn = $(this);
  const oldText = $btn.text();
  $btn.prop('disabled', true);
  try {
    const result = await classifyAndCheckSoundUrl(url);
    if (!result.ok) { console.log(result.reason || "This URL cannot be played."); return; }
    const displayName = result.title;
    $("#queue-song-url").val("");
    $("#queue-modal").fadeOut();
	$.post('https://'+djresourcename+'/addsongtoqueue', JSON.stringify({
		durationdata: result.durationSec,
		titledata: displayName,
		typedata: result.type,
		linkdata: result.source
	}));  		
  } catch (e) {
    console.error(e);
    console.log("An error occurred while validating the URL.");
  } finally {
    $btn.prop('disabled', false);
  }
});

$(".effect").click(function(e) {
  if (
    $(e.target).is("input") || 
    $(e.target).is(".color-preview") || 
    $(e.target).is(".color-input") || 
    $(e.target).is("label") || 
    $(e.target).closest("label.toggle").length > 0
  ) {
    return; 
  }

  const $effect = $(this);
  const wasActive = $effect.hasClass("active");
  $(".effect").removeClass("active");

  if (!wasActive) {
    $effect.addClass("active");
  }
});

function djcHexToRgb(hex){
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return m ? { r: parseInt(m[1],16), g: parseInt(m[2],16), b: parseInt(m[3],16) } : null;
}

$(function(){

  $('#lights-toggle').on('change', function(){
    $.post('https://' + djresourcename + '/effecttoggle', JSON.stringify({
      effect: 'lights',
      enabled: this.checked
    }));
  });

  $('#lights-move').on('change', function(){
    $.post('https://' + djresourcename + '/effectmove', JSON.stringify({
      effect: 'lights',
      move: this.checked
    }));
  });

  $('#lights-color').on('input change', function(){
    const hex = this.value;
    const rgb = djcHexToRgb(hex);
    $('#lights-effect .color-preview').css('color', hex);
    if (rgb){
      $.post('https://' + djresourcename + '/effectcolor', JSON.stringify({
        effect: 'lights',
        hex: hex,
        r: rgb.r, g: rgb.g, b: rgb.b
      }));
    }
  });

  $('#fog-toggle').on('change', function(){
    $.post('https://' + djresourcename + '/effecttoggle', JSON.stringify({
      effect: 'fog',
      enabled: this.checked
    }));
  });

  $('#fog-color').on('input change', function(){
    const hex = this.value;
    const rgb = djcHexToRgb(hex);
    $('#fog-effect .color-preview').css('color', hex);
    if (rgb){
      $.post('https://' + djresourcename + '/effectcolor', JSON.stringify({
        effect: 'fog',
        hex: hex,
        r: rgb.r, g: rgb.g, b: rgb.b
      }));
    }
  });

  $('#lasers-toggle').on('change', function(){
    $.post('https://' + djresourcename + '/effecttoggle', JSON.stringify({
      effect: 'lasers',
      enabled: this.checked
    }));
  });

  $('#lasers-move').on('change', function(){
    $.post('https://' + djresourcename + '/effectmove', JSON.stringify({
      effect: 'lasers',
      move: this.checked
    }));
  });

  $('#lasers-color').on('input change', function(){
    const hex = this.value;
    const rgb = djcHexToRgb(hex);
    $('#lasers-effect .color-preview').css('color', hex);
    if (rgb){
      $.post('https://' + djresourcename + '/effectcolor', JSON.stringify({
        effect: 'lasers',
        hex: hex,
        r: rgb.r, g: rgb.g, b: rgb.b
      }));
    }
  });

  $('#particles-toggle').on('change', function(){
    $.post('https://' + djresourcename + '/effecttoggle', JSON.stringify({
      effect: 'particles',
      enabled: this.checked
    }));
  });

});

$("#scale-btn").click(function () {
  $("#scale-panel").fadeToggle(150, function () {
    if ($(this).is(":visible")) {

      if (!$(".dj-container").hasClass("ui-draggable")) {
        $(".dj-container").draggable({
          scroll: false,
          cursor: "move"
        });
      } else {
        $(".dj-container").draggable("enable");
      }
    }
  });
});

$('#scale-range').on('input change', function () {
  const zoom = parseFloat(this.value) || 1.0;
  const $c = $('.dj-container');
  $c.css({ zoom: zoom });                
  $('#scale-value').text(Math.round(zoom * 100) + '%');
});

$('#save-position').on('click', function () {
  const $c = $('.dj-container');

  const pos = $c.position(); 
  const zoom = parseFloat($('#scale-range').val()) || 1.0;

  localStorage.setItem('djZoom', zoom);
  localStorage.setItem('djPosX', pos.left);
  localStorage.setItem('djPosY', pos.top);

  const picker = document.getElementById('primary-color');
  if (picker && isHex(picker.value)) {
    localStorage.setItem(COLOR_KEY, picker.value);
    setPrimary(picker.value); 
  }
});

$('#reset-position').on('click', function () {
  const $c = $('.dj-container');
  localStorage.removeItem('djZoom');
  localStorage.removeItem('djPosX');
  localStorage.removeItem('djPosY');
  localStorage.removeItem(COLOR_KEY);
 const zoom = 1.0;
 $c.css({ zoom });
    const { left, top } = getCenteredPosPx($c);
    $c.css({ left: left + 'px', top: top + 'px' });
  $('#scale-range').val(1.0);
  $('#scale-value').text('100%');

  setPrimary(DEFAULT_PRIMARY);
  const picker = document.getElementById('primary-color');
  if (picker) picker.value = DEFAULT_PRIMARY;
});

$('#close-scale').on('click', function () {
  $('#scale-panel').fadeOut(150);
  $('.dj-container').draggable('disable');

  applySettings(getSavedSettings());
});

$(document).on("click", ".toggle", function (e) {
  const checkbox = $(this).find("input[type=checkbox]");
  const newState = !checkbox.prop("checked");

  checkbox.prop("checked", newState).trigger("change");

  const id = checkbox.attr("id"); 

  if (!id) return;

  const [effect, type] = id.split("-"); 

});

const DJC_RESOURCE = 'dj_creator'; 

function djcSetBubble(){
  const $r = $('#djc-range-maxdist');
  const val = +$r.val(), min = +$r.attr('min'), max = +$r.attr('max');
  const p = (val - min) / (max - min);
  $('#djc-range-bubble').text(val).css('left', `calc(${p*100}% + (${8-p*16}px))`);
}

const DJC_DEFAULT_PARTICLE = { name: 'muz_xs_turret_flamethrower_looping', dict: 'weap_xs_vehicle_weapons' };

$(function(){
  $('#djc-particle-name').attr('placeholder', DJC_DEFAULT_PARTICLE.name);
  $('#djc-particle-dict').attr('placeholder', DJC_DEFAULT_PARTICLE.dict);
  if (!$('#djc-particle-name').val()?.trim()) $('#djc-particle-name').val(DJC_DEFAULT_PARTICLE.name);
  if (!$('#djc-particle-dict').val()?.trim()) $('#djc-particle-dict').val(DJC_DEFAULT_PARTICLE.dict);
});

let djcParticleLast = { name: null, dict: null };

function djcMaybePostParticlesConfig() {
  const name = ($('#djc-particle-name').val() || '').trim();
  const dict = ($('#djc-particle-dict').val() || '').trim();
  if (!name || !dict) return;
  if (name !== djcParticleLast.name || dict !== djcParticleLast.dict) {
    djcParticleLast = { name, dict };
    $.post('https://' + djresourcename + '/locationadd', JSON.stringify({
      locationdata: 'particles',
      namedata: name,
      dictdata: dict
    }));
  }
}

$(function () {
  $('#djc-particle-name, #djc-particle-dict').on('input', djcMaybePostParticlesConfig);
});

function djcOpenAdd(kind){
  djcCtx = kind;
  $("#djc-app").hide();
  $('#djc-overlay-add').css('display','flex');

  $('#djc-pos-x,#djc-pos-y,#djc-pos-z,#djc-rot-x,#djc-rot-y,#djc-rot-z').val('');

  $('#djc-particle-extra').toggle(kind==='particles');
  $('#djc-rotation-extra').toggle(kind!=='location');

  $('#djc-add-title').text(
    kind==='location' ? 'Set DJ Location' :
    (kind==='particles' ? 'Add Particle Location' : 'Add Effect Location')
  );

  if (kind === 'particles') {

    if (!$('#djc-particle-name').val()?.trim()) $('#djc-particle-name').val(DJC_DEFAULT_PARTICLE.name);
    if (!$('#djc-particle-dict').val()?.trim()) $('#djc-particle-dict').val(DJC_DEFAULT_PARTICLE.dict);

    djcParticleLast = { name: null, dict: null };
    djcMaybePostParticlesConfig();
  } else {

    $.post('https://' + djresourcename + '/locationadd', JSON.stringify({
      locationdata: kind
    }));
  }
}

function djcCloseAdd(){ $('#djc-overlay-add').hide(); 
djcCtx=null;
	$.post('https://'+djresourcename+'/closeadd', JSON.stringify({}));
 $("#djc-app").show();
 }

function djcRenderPerms(){
  const $list = $('#djc-perm-list').empty();
  if(!djcState.permissions.length){
	$list.append(`<div class="djc-list-row"><span class="djc-subtitle">No permissions yet.</span><span></span></div>`);
	return;
  }
  djcState.permissions.forEach((p,i)=>{
	$list.append(`<div class="djc-list-row"><div><b>${p.type}</b> — ${p.value}</div><button class="djc-btn djc-btn-danger djc-del-perm" data-i="${i}"><i class="fa-solid fa-xmark"></i></button></div>`);
  });
}

function djcOpenList(key){
  const $c = $('#djc-list-content').empty();
  $('#djc-overlay-list').css('display','flex').data('key', key);
  $('#djc-list-title').text(`${key.charAt(0).toUpperCase()+key.slice(1)} Locations`);
  const arr = key==='particles' ? djcState.effects.particles.entries : djcState.effects[key].locations;
  if(!arr.length){ $c.append(`<div class="djc-list-row"><span class="djc-subtitle">No locations yet.</span><span></span></div>`); return; }
  arr.forEach((o,i)=>{
	const text = key==='particles' ? `${o.name} @ ${o.dict} — ${djcFmtPos(o.pos)}` : `${djcFmtPos(o.pos)}`;
	$c.append(`<div class="djc-list-row"><div>${text}</div><button class="djc-btn djc-btn-danger djc-del-loc" data-i="${i}"><i class="fa-solid fa-trash"></i></button></div>`);
  });
}

window.addEventListener('message', (e)=>{
  const m = e.data || {};
  switch(m.action){
	case 'djc:open':
	  $('#djc-app').show();
	  break;
	case 'djc:close':
	  $('#djc-app').hide();
	  break;
	case 'djc:setPlacement':
	  djcTempPos = {x:+m.x, y:+m.y, z:+m.z};

	  if($('#djc-overlay-add').is(':visible')){
		$('#djc-pos-x').val(djcTempPos.x);
		$('#djc-pos-y').val(djcTempPos.y);
		$('#djc-pos-z').val(djcTempPos.z);
	  }
	  break;
	case 'djc:setRotation':
	  djcTempRot = {x:+m.x, y:+m.y, z:+m.z};
	  if($('#djc-overlay-add').is(':visible')){
		$('#djc-rot-x').val(djcTempRot.x);
		$('#djc-rot-y').val(djcTempRot.y);
		$('#djc-rot-z').val(djcTempRot.z);
	  }
	  break;
  }
});

$(function(){

  $('#djc-close').on('click', function(){
	$('#djc-app').hide();      
	$.post('https://'+djresourcename+'/closecreator', JSON.stringify({}));
  });

  $(document).on('keydown', (e)=>{
	if(e.key==='Escape'){
	  $('#djc-overlay-add,#djc-overlay-perms,#djc-overlay-list').hide();
	}
  });

  $('#djc-input-name').on('input', function(){ djcState.name = this.value.trim(); });

  $('#djc-range-maxdist').on('input change', function(){ djcState.maxDistance = +this.value; djcSetBubble(); });
  djcSetBubble();

  $('#djc-btn-set-loc').on('click', function(){
	djcOpenAdd('location');
  });

  $('#djc-toggle-everyone').on('change', function(){ djcState.everyone = this.checked; });

  $('#djc-btn-perm-add').on('click', function(){
	const type = $('#djc-select-permtype').val();
	const value = ($('#djc-input-permvalue').val() || '').trim();
	if(!value) return;
	djcState.permissions.push({type, value});
	$('#djc-input-permvalue').val('');
  });
  $('#djc-btn-perms-manage').on('click', function(){ djcRenderPerms(); $('#djc-overlay-perms').css('display','flex'); });
  $('#djc-perm-list').on('click', '.djc-del-perm', function(){
	const i = $(this).data('i'); djcState.permissions.splice(i,1); djcRenderPerms();
  });
  $('#djc-perms-close').on('click', function(){ $('#djc-overlay-perms').hide(); });

  $('#djc-toggle-smoke').on('change', function(){ djcState.effects.smoke.enabled = this.checked; });
  $('#djc-toggle-lights').on('change', function(){ djcState.effects.lights.enabled = this.checked; });
  $('#djc-toggle-lasers').on('change', function(){ djcState.effects.lasers.enabled = this.checked; });
  $('#djc-toggle-particles').on('change', function(){ djcState.effects.particles.enabled = this.checked; });

  $('#djc-btn-add-smoke').on('click',   ()=>{ djcOpenAdd('smoke'); });
  $('#djc-btn-add-lights').on('click',  ()=>{ djcOpenAdd('lights');     });
  $('#djc-btn-add-lasers').on('click',  ()=>{ djcOpenAdd('lasers');   });
  $('#djc-btn-add-particles').on('click',()=>{ djcOpenAdd('particles');  });

  $('#djc-btn-list-smoke').on('click',    ()=> djcOpenList('smoke'));
  $('#djc-btn-list-lights').on('click',   ()=> djcOpenList('lights'));
  $('#djc-btn-list-lasers').on('click',   ()=> djcOpenList('lasers'));
  $('#djc-btn-list-particles').on('click',()=> djcOpenList('particles'));

$('#djc-list-content').on('click', '.djc-del-loc', function () {
  const i   = $(this).data('i');
  const key = $('#djc-overlay-list').data('key'); 

  let removed;
  if (key === 'particles') {
    removed = djcState.effects.particles.entries[i];
    djcState.effects.particles.entries.splice(i, 1);
  } else {
    removed = djcState.effects[key].locations[i];
    djcState.effects[key].locations.splice(i, 1);
  }

  const uid = removed && removed.id != null ? removed.id : null;

  $.post('https://' + djresourcename + '/deletelocation', JSON.stringify({
    locationdata: key,        
    locationiddata: uid       
  }));

  djcOpenList(key);
});

$('#djc-list-clear').on('click', function () {
  const key = $('#djc-overlay-list').data('key'); 

  const removedCount = (key === 'particles')
    ? djcState.effects.particles.entries.length
    : djcState.effects[key].locations.length;

  $.post('https://' + djresourcename + '/deletelocationall', JSON.stringify({
    locationdata: key
  }));

  if (key === 'particles') djcState.effects.particles.entries = [];
  else djcState.effects[key].locations = [];

  djcOpenList(key);
});
  $('#djc-list-close').on('click', function(){ $('#djc-overlay-list').hide(); });

  $('#djc-btn-use-pos').on('click', function(){ if(!djcTempPos) return; $('#djc-pos-x').val(djcTempPos.x); $('#djc-pos-y').val(djcTempPos.y); $('#djc-pos-z').val(djcTempPos.z); });
  $('#djc-btn-use-rot').on('click', function(){ if(!djcTempRot) return; $('#djc-rot-x').val(djcTempRot.x); $('#djc-rot-y').val(djcTempRot.y); $('#djc-rot-z').val(djcTempRot.z); });
  $('#djc-add-cancel').on('click', djcCloseAdd);

  $('#djc-add-confirm').on('click', function(){
	const px = parseFloat($('#djc-pos-x').val()), py = parseFloat($('#djc-pos-y').val()), pz = parseFloat($('#djc-pos-z').val());
	if([px,py,pz].some(Number.isNaN)) return;
	const pos = {x:px,y:py,z:pz};

	if(djcCtx==='location'){
	  djcState.location = pos;
	  $('#djc-coord-status').text(djcFmtPos(pos));
	  djcCloseAdd(); return;
	}

	const rot = {
	  x:parseFloat($('#djc-rot-x').val())||0,
	  y:parseFloat($('#djc-rot-y').val())||0,
	  z:parseFloat($('#djc-rot-z').val())||0
	};
	if (djcCtx === 'smoke') {
		  const uid = djcState._nextUid++;
		  const index = djcState.effects.smoke.locations.push({ id: uid, pos, rot }) - 1;
		$.post('https://'+djresourcename+'/confirmadd', JSON.stringify({
			locationdata: "smoke",
			locationiddata:  uid,
			coords: pos,
			rotation: rot
		}));  	  
	}
	if (djcCtx === 'lights') {
		 const uid = djcState._nextUid++;
		  const index = djcState.effects.lights.locations.push({ id: uid, pos, rot }) - 1;
		$.post('https://'+djresourcename+'/confirmadd', JSON.stringify({
			locationdata: "lights",
			locationiddata:  uid,
			coords: pos,
			rotation: rot
		}));  	
	}
	if (djcCtx === 'lasers') {
		 const uid = djcState._nextUid++;
		  const index = djcState.effects.lasers.locations.push({ id: uid, pos, rot }) - 1;
		$.post('https://'+djresourcename+'/confirmadd', JSON.stringify({
			locationdata: "lasers",
			locationiddata:  uid,
			coords: pos,
			rotation: rot
		}));  	 
	}
	if (djcCtx === 'particles') {
	  const name = ($('#djc-particle-name').val() || '').trim();
	  const dict = ($('#djc-particle-dict').val() || '').trim();
	  if (!name || !dict) return;

		  const uid = djcState._nextUid++;
		  const index = djcState.effects.particles.entries.push({ id: uid, pos, rot, name, dict }) - 1;
		$.post('https://'+djresourcename+'/confirmadd', JSON.stringify({
			locationdata: "particles",
			locationiddata:  uid,
			coords: pos,
			rotation: rot,
			particledict: dict,
			particlename: name
		}));  	  
	}
	djcCloseAdd();
  });

$('#djc-btn-create').off('click').on('click', function(){
  $('#djc-app').hide();
  const payload = {
    name: djcState.name || null,
    location: djcState.location,
    maxDistance: djcState.maxDistance,
    access: {
      everyone: djcState.everyone,
      permissions: [...djcState.permissions]
    },
    effects: {
      smoke:     { enabled: djcState.effects.smoke.enabled,     locations: [...djcState.effects.smoke.locations]     },
      lights:    { enabled: djcState.effects.lights.enabled,    locations: [...djcState.effects.lights.locations]    },
      lasers:    { enabled: djcState.effects.lasers.enabled,    locations: [...djcState.effects.lasers.locations]    },
      particles: { enabled: djcState.effects.particles.enabled, entries:   [...djcState.effects.particles.entries]   }
    }
  };

  if (djcEditMode && djcEditingId != null) {
    $.post('https://' + djresourcename + '/savecreator', JSON.stringify({ id: djcEditingId, data: payload }));
  } else {
    $.post('https://' + djresourcename + '/finishcreator', JSON.stringify(payload));
  }

  djcEditMode = false; djcEditingId = null;
  $('#djc-home').hide();
  $.post('https://'+djresourcename+'/closecreator', JSON.stringify({}));
});

});