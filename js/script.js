(function () {
  const audio = new Audio();
  audio.crossOrigin = "anonymous";
  audio.preload = "none";

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("./service-worker.js").catch(function () {});
  }

  const els = {
    stationList: document.getElementById("stationList"),
    stationName: document.getElementById("stationName"),
    btnPlay: document.getElementById("btnPlay"),
    iconPlay: document.getElementById("iconPlay"),
    iconPause: document.getElementById("iconPause"),
    volumeSlider: document.getElementById("volumeSlider"),
    volumeIcon: document.getElementById("volumeIcon"),
    disc: document.getElementById("disc"),
    equalizer: document.getElementById("equalizer"),
    customUrl: document.getElementById("customUrl"),
    btnCustom: document.getElementById("btnCustom"),
    miniPlayer: document.getElementById("miniPlayer"),
    miniName: document.getElementById("miniName"),
    miniToggle: document.getElementById("miniToggle"),
    miniDot: document.querySelector(".mini-dot"),
    heroPlay: document.getElementById("heroPlay"),
    navbarLive: document.getElementById("navbarLive")
  };

  function saveCustomUrl(url) {
    let btn = els.stationList.querySelector('button[data-id="custom"]');
    if (!btn) {
      btn = document.createElement("button");
      btn.type = "button";
      btn.dataset.id = "custom";
      const info = document.createElement("span");
      info.className = "station-info";
      const name = document.createElement("strong");
      name.textContent = "Rádio personalizada";
      const genre = document.createElement("span");
      genre.className = "station-genre";
      genre.textContent = "Link inserido";
      info.appendChild(name);
      info.appendChild(genre);
      const dot = document.createElement("span");
      dot.className = "status-dot";
      btn.appendChild(info);
      btn.appendChild(dot);
      btn.addEventListener("click", function () {
        playStation(
          { id: "custom", name: "Rádio personalizada", genre: "Link inserido", url: btn.dataset.url },
          btn,
          btn.querySelector(".status-dot")
        );
      });
      const li = document.createElement("li");
      li.appendChild(btn);
      els.stationList.appendChild(li);
    }
    btn.dataset.url = url;
    return btn;
  }

  function playCustom() {
    const raw = els.customUrl.value.trim();
    if (!raw) return;
    let url = raw;
    if (!/^https?:\/\//i.test(url)) {
      url = "https://" + url;
    }
    const btn = saveCustomUrl(url);
    playStation(
      { id: "custom", name: "Rádio personalizada", genre: "Link inserido", url: url },
      btn,
      btn.querySelector(".status-dot")
    );
  }

  els.btnCustom.addEventListener("click", playCustom);
  els.customUrl.addEventListener("keydown", function (e) {
    if (e.key === "Enter") playCustom();
  });

  const savedVolume = localStorage.getItem("rea-volume");
  const volume = savedVolume !== null ? Number(savedVolume) : 80;
  els.volumeSlider.value = volume;
  audio.volume = volume / 100;
  updateVolumeIcon();

  let current = null;
  let retries = 0;

  function buildList() {
    els.stationList.innerHTML = "";
    STATIONS.forEach(function (station) {
      const li = document.createElement("li");
      const btn = document.createElement("button");
      btn.type = "button";
      btn.dataset.id = station.id;

      const info = document.createElement("span");
      info.className = "station-info";
      const name = document.createElement("strong");
      name.textContent = station.name;
      const genre = document.createElement("span");
      genre.className = "station-genre";
      genre.textContent = station.genre;
      info.appendChild(name);
      info.appendChild(genre);

      const dot = document.createElement("span");
      dot.className = "status-dot";

      btn.appendChild(info);
      btn.appendChild(dot);

      btn.addEventListener("click", function () {
        playStation(station, btn, dot);
      });

      li.appendChild(btn);
      els.stationList.appendChild(li);
    });
  }

  function playStation(station, btn, dot) {
    const buttons = els.stationList.querySelectorAll("button");
    buttons.forEach(function (b) {
      b.classList.remove("active");
    });
    if (btn) btn.classList.add("active");
    document.querySelectorAll(".status-dot").forEach(function (d) {
      d.classList.remove("active");
      d.classList.remove("error");
    });
    if (dot) dot.classList.add("active");

    current = station;
    retries = 0;
    els.stationName.textContent = station.name;
    els.miniName.textContent = station.name;
    updateMediaSession();
    audio.src = station.url + (station.url.indexOf("?") >= 0 ? "&" : "?") + "t=" + Date.now();
    audio.play().then(playing).catch(failed);
  }

  function playing() {
    els.disc.classList.add("playing");
    els.equalizer.classList.add("playing");
    els.iconPlay.style.display = "none";
    els.iconPause.style.display = "";
    els.miniToggle.textContent = "\u275A\u275A";
    els.miniDot.classList.add("playing");
    if (els.heroPlay) els.heroPlay.textContent = "Pausar transmiss\u00E3o";
    if (els.navbarLive) els.navbarLive.textContent = "\u25CF AO VIVO";
  }

  function updateMediaSession() {
    if (!current || !("mediaSession" in navigator)) return;
    navigator.mediaSession.metadata = new MediaMetadata({
      title: current.name,
      artist: "R\u00E1dio Gospel",
      album: "Deus \u00E9 Amor",
      artwork: [{ src: "icons/icon-192.png", sizes: "192x192", type: "image/png" }]
    });
  }

  navigator.mediaSession.setActionHandler = navigator.mediaSession.setActionHandler || function () {};

  function paused() {
    els.disc.classList.remove("playing");
    els.equalizer.classList.remove("playing");
    els.iconPlay.style.display = "";
    els.iconPause.style.display = "none";
    els.miniToggle.textContent = "\u25B6";
    els.miniDot.classList.remove("playing");
    if (els.heroPlay) els.heroPlay.textContent = "Ouvir ao vivo";
    if (els.navbarLive) els.navbarLive.textContent = "AO VIVO";
  }

  function failed() {
    paused();
  }

  function togglePlay() {
    if (!current) {
      const first = els.stationList.querySelector("button");
      if (first) first.click();
      return;
    }
    if (audio.paused) {
      audio.play().then(playing).catch(failed);
    } else {
      audio.pause();
      paused();
    }
  }

  els.btnPlay.addEventListener("click", togglePlay);
  if (els.heroPlay) els.heroPlay.addEventListener("click", togglePlay);
  if (els.miniToggle) els.miniToggle.addEventListener("click", togglePlay);
  if (els.navbarLive) els.navbarLive.addEventListener("click", togglePlay);

  audio.addEventListener("playing", playing);
  audio.addEventListener("pause", paused);
  audio.addEventListener("ended", paused);

  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "visible" && current && audio.paused) {
      audio.play().then(playing).catch(failed);
    }
  });

  audio.addEventListener("error", function () {
    if (retries < 2 && current) {
      retries += 1;
      const btn = els.stationList.querySelector('button[data-id="' + current.id + '"]');
      if (btn) btn.click();
    } else {
      paused();
      const dot = document.querySelector(".status-dot.active");
      if (dot) {
        dot.classList.remove("active");
        dot.classList.add("error");
      }
      els.stationName.textContent = "Falha ao conectar";
      els.miniName.textContent = "Falha ao conectar";
    }
  });

  els.volumeSlider.addEventListener("input", function () {
    audio.volume = els.volumeSlider.value / 100;
    localStorage.setItem("rea-volume", els.volumeSlider.value);
    updateVolumeIcon();
  });

  function updateVolumeIcon() {
    const v = Number(els.volumeSlider.value);
    if (v === 0) {
      els.volumeIcon.textContent = "\uD83D\uDD09";
    } else if (v < 50) {
      els.volumeIcon.textContent = "\uD83D\uDD09";
    } else {
      els.volumeIcon.textContent = "\uD83D\uDD0A";
    }
  }

  buildList();
  paused();
})();