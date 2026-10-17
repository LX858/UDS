var soundhandler = {}

window.addEventListener("load", (event) => {
	let djresourcenamedata = location.host;
	let djresourcenamedata2 = djresourcenamedata.substring(8);
	$.post('https://'+djresourcenamedata2+'/readyyt', JSON.stringify({}));
});

window.addEventListener('message', function (event) {

	var item = event.data;
			
	if (item.message == "playmusic") {	
	  if (item.resetplayer == true) {
		if (soundhandler[item.djlocation] !== undefined) {
			soundhandler[item.djlocation].stopVideo();
			soundhandler[item.djlocation].destroy();
			soundhandler[item.djlocation] = undefined;
			$("#"+ item.djlocation +"").remove();
		}
	  }

	  if (soundhandler[item.djlocation] == undefined) {
		  $("body").append("<div id='"+ item.djlocation +"'></div>");
		  soundhandler[item.djlocation] = new YT.Player(""+ item.djlocation +"", {
			startSeconds:Number,
			videoId: item.soundsrc,
			origin: window.location.href,
			enablejsapi: 1,
			width: "0",
			height: "0",
			playerVars: { playsinline: 1, controls: 0 },
			events: {
			  'onReady': function(event){
				event.target.unMute();
				event.target.setVolume(0);
				event.target.seekTo(item.soundduration || 0);
				event.target.playVideo();
			  },
			  'onError': function(event){},
			  'onStateChange': function(event){}
			}
		  });

	  } else {
		  if (typeof soundhandler[item.djlocation].setVolume === 'function') {
			soundhandler[item.djlocation].setVolume(item.soundvolume);
			if (item.soundvolume <= 0) {
			  soundhandler[item.djlocation].mute();
			} else {
			  soundhandler[item.djlocation].unMute();
			}
		  }
	  }
	}

	if (item.message == "changeduration") {
	  if (soundhandler[item.djlocation] !== undefined) {
		  soundhandler[item.djlocation].seekTo(item.soundduration || 0);
	  }
	}

	if (item.message == "resumehandler") {
	  if (soundhandler[item.djlocation] !== undefined) {
		  soundhandler[item.djlocation].seekTo(item.soundduration || 0);
		  if (item.resumehandler === true) {
			soundhandler[item.djlocation].pauseVideo();
		  } else {
			soundhandler[item.djlocation].playVideo();
		  }
	  }
	}

	if (item.message == "stopmusic") {
	  if (soundhandler[item.djlocation] !== undefined) {
		  soundhandler[item.djlocation].stopVideo();
		  soundhandler[item.djlocation].destroy();
		  soundhandler[item.djlocation] = undefined;
		  $("#"+ item.djlocation +"").remove();
	  }
	}
});

(() => {
  let djresourcenamedata = location.host;
  let djresourcenamedata2 = djresourcenamedata.substring(8);
  const INTERVAL = 2000;

  let timer = null;
  let running = false;

  function pulse() {
    if (!running) return;

    $.ajax({
      url: `https://${djresourcenamedata2}/alive`, 
      type: "POST",
      data: JSON.stringify({ ts: performance.now() }),
      contentType: "application/json; charset=UTF-8",
      timeout: 1000
    });

    timer = setTimeout(pulse, INTERVAL);
  }

  window.rtxKeepAlive = {
    start() {
      if (running) return;
      running = true;
      pulse();
    },
    stop() {
      running = false;
      clearTimeout(timer);
      timer = null;
    }
  };

  window.rtxKeepAlive.start();
})();
