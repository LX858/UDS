const FFA = new Vue({
  el: '.wrapper',
  data: {
    locales: {
      mainmenu: {
        title: "FFA",
        badge: "SYSTEM",
        description: "Here you can Kill your Enemies legally and without any Consequences",
        kills: "Kills",
        deaths: "Deaths",
        kd: "K/D"
      },
      top_list: {
        title: "TOP 10 LIST",
        description: "This are the top 10 Players of all time with Most kills",
        place: "Place"
      },
      plr_stats: {
        kills: "Kills",
        deaths: "Deaths",
        kd: "K/D"
      },
      deathscreen: {
        title: "YOU GOT KILLED",
        by: "By"
      }
    },
    mainmenuopen: false,
    ingame: false,
    deathscreenInterval: null,
    plrstats: {
      kills: 0,
      deaths: 0,
    },
    lobbys: {},
    topplayers: [],
    killfeed: [],
    waitingLobby: {
      active: false,
      mapName: "FFA Arena",
      playerCount: 1,
      maxPlayers: 16
    },
    deathscreen: {
      active: false,
      killer: "",
      time: 3,
    }
  },
  methods: {
    calc_kd: function() {
      let deaths = this.plrstats.deaths;
      if (deaths == 0) {
        deaths = 1;
      }

      let kd = this.plrstats.kills / deaths;
      kd = kd.toFixed(1);
      if (isNaN(kd) || kd == Infinity) {
        return 1;
      } else {
        return kd;
      }
    },
    sortplayers(players) {
      return players.sort((a, b) => {
        return b.kills - a.kills;
      });
    },
    showkillfeedmessage(killer, victim) {
      let id = Math.floor(Math.random() * 100000);
      this.killfeed.push({
        id: id,
        killer: killer,
        victim: victim,
      });

      setTimeout(() => {
        this.killfeed = this.killfeed.filter((feed) => {
          return feed.id != id;
        });
      }, 5000);
    },
    joinLobby: function(key) {
      this.mainmenuopen = false;
      fetch(`https://${GetParentResourceName()}/joinLobby`, {
        method: 'POST',
        body: JSON.stringify({lobby: key}),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8'
        }
      });
    },

    startdeathscreen: function(killer, time) {
      if (this.deathscreenInterval) {
        clearInterval(this.deathscreenInterval);
        this.deathscreenInterval = null;
      }
      this.deathscreen.killer = killer || "Unknown";
      this.deathscreen.time = Number(time) || 3;
      this.deathscreen.active = true;

      this.deathscreenInterval = setInterval(() => {
        this.deathscreen.time--;
        if (this.deathscreen.time <= 0) {
          this.deathscreen.active = false;
          clearInterval(this.deathscreenInterval);
          this.deathscreenInterval = null;
        }
      }, 1000);
    },

    canceldeathscreen: function() {
      if (this.deathscreenInterval) {
        clearInterval(this.deathscreenInterval);
        this.deathscreenInterval = null;
      }
      this.deathscreen.active = false;
    }
  },

  mounted() {
    window.addEventListener('message', (event) => {
      let data = event.data;
      if (data && data.type in Functions) {
        Functions[data.type](data);
      }
    });

    document.addEventListener('keyup', (event) => {
      if (event.key == "Escape") {
        if (this.mainmenuopen) {
          this.mainmenuopen = false;
          fetch(`https://${GetParentResourceName()}/close`);
        }
      }
    });

    fetch(`https://${GetParentResourceName()}/getLocales`).then((response) => {
      response.json().then((locales) => {
        if (locales && typeof locales === 'object') {
          this.locales = Object.assign({}, this.locales, locales);
        }
      });
    }).catch((err) => {
      console.log('Using default locales');
    });
  }
});

const Functions = {
  ["openmainmenu"] ({ topplayers, lobbys, plrdata }) {
    FFA.topplayers = topplayers || [];
    FFA.lobbys = lobbys || {};
    FFA.plrstats = plrdata || { kills: 0, deaths: 0 };
    FFA.ingame = false;
    FFA.waitingLobby.active = false;
    FFA.mainmenuopen = true;
  },
  ["openingame"] ({ plrdata }) {
    FFA.mainmenuopen = false;
    FFA.waitingLobby.active = false;
    if (plrdata) FFA.plrstats = plrdata;
    FFA.ingame = true;
  },
  ["showwaiting"] ({ mapName, playerCount, maxPlayers }) {
    FFA.mainmenuopen = false;
    FFA.waitingLobby.mapName = mapName || "FFA Arena";
    FFA.waitingLobby.playerCount = playerCount || 1;
    FFA.waitingLobby.maxPlayers = maxPlayers || 16;
    FFA.waitingLobby.active = true;
  },
  ["hidewaiting"] () {
    FFA.waitingLobby.active = false;
  },
  ["closemenu"] () {
    FFA.mainmenuopen = false;
  },
  ["leavegame"] () {
    FFA.ingame = false;
    FFA.waitingLobby.active = false;
    FFA.canceldeathscreen();
  },
  ["updatestats"] ({ plrdata }) {
    if (plrdata) FFA.plrstats = plrdata;
  },
  ["sendkillfeedmsg"] ({ killer, victim }) {
    FFA.showkillfeedmessage(killer, victim);
  },
  ["startdeathscreen"] ({ killer, time }) {
    FFA.startdeathscreen(killer, time);
  },
  ["canceldeathscreen"] () {
    FFA.canceldeathscreen();
  },
}
