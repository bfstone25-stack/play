(function () {
  "use strict";

  const STORAGE = "flutter_audio_v1";
  const defaults = {music:true, musicVolume:.22, voice:"off", voiceRate:1};
  const profiles = {
    en:      {tempo:66, scale:[0,3,7,10], root:110, wave:"triangle", texture:"velvet"},
    zh:      {tempo:62, scale:[0,4,7,11], root:130.81, wave:"sine", texture:"warm"},
    ja:      {tempo:54, scale:[0,2,7,9], root:146.83, wave:"sine", texture:"rain"},
    es:      {tempo:88, scale:[0,3,7,8], root:123.47, wave:"triangle", texture:"pulse"},
    "pt-BR": {tempo:78, scale:[0,4,7,9], root:130.81, wave:"sine", texture:"sun"}
  };
  // VESPER has no vocal theme. The mainstream game's theme and resolution
  // tracks are its vocal masters ("my-moment-vocal-pilot", "zh-theme-native-v4") and they
  // were reaching this build through a symlink — frontend/audio pointed at
  // ../../flutter/frontend/audio, so the fork was literally playing the romance game's
  // songs. The symlink is gone (ops/afterhours_audio.py --unlink) and these are the fork's
  // own beds. One pair for every edition: the fork's music has no language in it.
  const themeTracks = {
    en: "audio/bgm/afterhours-theme.mp3",
    zh: "audio/bgm/afterhours-theme.mp3",
    ja: "audio/bgm/afterhours-theme.mp3",
    es: "audio/bgm/afterhours-theme.mp3",
    "pt-BR": "audio/bgm/afterhours-theme.mp3"
  };
  const resolutionTracks = {
    en: "audio/bgm/afterhours-resolution.mp3",
    zh: "audio/bgm/afterhours-resolution.mp3",
    ja: "audio/bgm/afterhours-resolution.mp3",
    es: "audio/bgm/afterhours-resolution.mp3",
    "pt-BR": "audio/bgm/afterhours-resolution.mp3"
  };
  const labels = {
    en:{title:"SOUND",music:"Atmosphere",voice:"Dialogue voice",off:"Off",system:"Device voice",edge:"Immersive · on device",edgeNote:"Requires a compatible native NPU voice pack.",privacy:"Generated on this device. Dialogue is not uploaded.",rate:"Voice pace"},
    zh:{title:"声音",music:"氛围音乐",voice:"对话语音",off:"关闭",system:"设备语音",edge:"沉浸语音 · 端侧",edgeNote:"需要原生客户端及兼容的 NPU 角色声音包。",privacy:"在本机生成，不上传对话内容。",rate:"语速"},
    ja:{title:"サウンド",music:"アンビエンス",voice:"会話ボイス",off:"オフ",system:"デバイス音声",edge:"没入ボイス · 端末内",edgeNote:"対応NPUとネイティブ版の音声パックが必要です。",privacy:"会話は端末内で生成され、送信されません。",rate:"話速"},
    es:{title:"SONIDO",music:"Ambiente",voice:"Voz de diálogo",off:"Desactivada",system:"Voz del dispositivo",edge:"Voz inmersiva · local",edgeNote:"Requiere la app nativa y un paquete de voz NPU compatible.",privacy:"Se genera en el dispositivo. El diálogo no se sube.",rate:"Velocidad"},
    "pt-BR":{title:"SOM",music:"Ambiente",voice:"Voz do diálogo",off:"Desligada",system:"Voz do dispositivo",edge:"Voz imersiva · local",edgeNote:"Requer o app nativo e um pacote de voz NPU compatível.",privacy:"Gerado no aparelho. O diálogo não é enviado.",rate:"Velocidade"}
  };

  let state = load(), musicPlayer = null, cuePlayer = null, currentEdition = "en", currentScene = "main", musicBlocked = true, introThemeMode = false;
  let voices = [], duckTimer, cueStartTimer, cueFadeFrame, lastCueAt = 0;

  function clampVol(v) {
    return v > 1 ? 1 : v > 0 ? v : 0;      // also catches NaN, which throws the same way
  }

  function fadePlayer(player, target, duration, done) {
    if (!player) { if (done) done(); return; }
    if (cueFadeFrame) cancelAnimationFrame(cueFadeFrame);
    const from = player.volume, started = performance.now();
    const step = now => {
      if (!player || player !== musicPlayer) {
        cueFadeFrame = null;
        return;
      }
      // `Math.min(1, ...)` alone was not a clamp. rAF's timestamp is the time of the
      // frame's start, which can be EARLIER than the performance.now() read a moment
      // before it was scheduled, so the first step of a fade can see a negative p --
      // and the ease p*(2-p) is then negative too, which carries the value below
      // `from` and, on a fade to zero, below zero. That is the -0.0015455 the play
      // matrix caught. Clamped at both ends, and again on the write below.
      const p = Math.max(0, Math.min(1, (now - started) / duration));
      // Clamped. The eased value is mathematically inside [from, target], but it is
      // floating point and `from` is read back off the element, so the last frame of a
      // fade-out can land a few ten-thousandths under zero -- and HTMLMediaElement
      // throws on that rather than clamping, which killed the whole rAF chain and left
      // the track stuck at whatever volume it had reached. Seen as a page error in the
      // 2026-09-21 play matrix: volume -0.0015455 is outside the range [0, 1].
      player.volume = clampVol(from + (target - from) * (p * (2 - p)));
      if (p < 1) cueFadeFrame = requestAnimationFrame(step);
      else {
        cueFadeFrame = null;
        if (done) done();
      }
    };
    cueFadeFrame = requestAnimationFrame(step);
  }

  function load() {
    try { return Object.assign({}, defaults, JSON.parse(localStorage.getItem(STORAGE) || "{}")); }
    catch (_) { return Object.assign({}, defaults); }
  }
  function save() {
    try { localStorage.setItem(STORAGE, JSON.stringify(state)); } catch (_) {}
  }
  function unlock() {
    if (state.music && !musicBlocked) startMusic();
  }
  function startMusic() {
    if (!state.music || musicBlocked || musicPlayer) return;
    const player = makePlayer(currentEdition, currentScene);
    player.addEventListener("error", ()=>{
      if (musicPlayer !== player) return;
      musicPlayer = null;
      const fallback = new Audio("audio/bgm/"+currentEdition+".ogg");
      fallback.loop = true; fallback.volume = state.musicVolume;
      fallback.play().then(()=>{musicPlayer=fallback;}).catch(()=>{});
    }, {once:true});
    musicPlayer = player;
    player.play().catch(()=>{});
  }
  function makePlayer(edition, scene) {
    const player = new Audio(trackPath(edition, scene));
    player.loop = !["theme","resolution"].includes(scene);
    player.preload = "auto";
    player.volume = state.musicVolume;
    if (scene === "theme" || scene === "resolution") {
      player.addEventListener("ended", ()=>{
        if (musicPlayer !== player || currentScene !== scene) return;
        musicPlayer = null;
        if (scene === "theme" && introThemeMode) return;
        currentScene = scene === "theme" ? "main" : "intimate";
        startMusic();
      }, {once:true});
    }
    return player;
  }
  function trackPath(edition, scene) {
    if (scene === "theme") return themeTracks[edition] || themeTracks.en;
    if (scene === "resolution") return resolutionTracks[edition] || resolutionTracks.en;
    // The Japanese dramatic score was finalized as the v2 suite. Keep the
    // legacy ja-* masters available for archive/reference, never for runtime.
    if (edition === "ja") return "audio/bgm/ja-v2-"+scene+".mp3";
    return "audio/bgm/"+edition+"-"+scene+".mp3";
  }
  function stopMusic() {
    if (!musicPlayer) return;
    musicPlayer.pause(); musicPlayer.src = ""; musicPlayer = null;
  }
  function pauseForOpening() {
    musicBlocked = true;
    introThemeMode = false;
    stopCue();
    stopMusic();
    if (window.speechSynthesis) speechSynthesis.cancel();
  }
  function resumeScene(scene) {
    introThemeMode=false;
    if (["main","conversation","intimate","tension","melancholy","resolution","theme"].includes(scene)) currentScene=scene;
    musicBlocked=false;
    stopMusic();
    if(state.music)startMusic();
  }
  function playIntroTheme() {
    introThemeMode=true;
    currentScene="theme";
    musicBlocked=false;
    stopMusic();
    if(state.music)startMusic();
  }
  function playCue(mood) {
    if (!state.music || !["tender","longing","spark"].includes(mood)) return;
    if (Date.now() - lastCueAt < 9000) return;
    stopCue();
    lastCueAt = Date.now();
    const cue = new Audio(`audio/bgm/cues/${currentEdition}-${mood}.mp3`);
    cue.preload = "auto";
    cue.volume = Math.min(.5, state.musicVolume * 1.45);
    let started = false;
    const restore = ()=>{
      if (cuePlayer !== cue) return;
      clearTimeout(cueStartTimer);
      cuePlayer = null;
      if (musicPlayer) fadePlayer(musicPlayer, state.musicVolume, 900);
    };
    cue.addEventListener("ended", restore, {once:true});
    cue.addEventListener("error", restore, {once:true});
    cuePlayer = cue;
    const begin = ()=>{
      if (cuePlayer !== cue || started) return;
      started = true;
      cue.play().catch(restore);
    };
    // A motif takes over the score instead of being layered on top of it.
    // Keep ambience on its separate bus, but fully clear the musical bed.
    if (musicPlayer) {
      fadePlayer(musicPlayer, 0, 420, begin);
      cueStartTimer = setTimeout(begin, 520);
    } else begin();
  }
  function stopCue() {
    if (!cuePlayer) return;
    clearTimeout(cueStartTimer);
    if (cueFadeFrame) cancelAnimationFrame(cueFadeFrame);
    cueFadeFrame = null;
    cuePlayer.pause();
    cuePlayer.src = "";
    cuePlayer = null;
    if (musicPlayer) fadePlayer(musicPlayer, state.musicVolume, 650);
  }
  function setEdition(id) {
    stopCue();
    currentEdition = profiles[id] ? id : "en";
    if (state.music && musicPlayer) { stopMusic(); setTimeout(()=>{ if(state.music && !musicBlocked) startMusic(); },350); }
    syncUI();
  }
  function setScene(scene) {
    if (!["theme","resolution","main","conversation","intimate","tension","melancholy"].includes(scene) || scene === currentScene) return;
    currentScene = scene;
    if (!state.music || !musicPlayer) return;
    const previous = musicPlayer, next = makePlayer(currentEdition, currentScene);
    next.volume = 0;
    next.addEventListener("error", ()=>{ next.src=""; }, {once:true});
    next.play().then(()=>{
      musicPlayer = next;
      const started = performance.now(), duration = 1400;
      const fade = now => {
        const p = Math.min(1,(now-started)/duration);
        const target = cuePlayer ? 0 : state.musicVolume;
        next.volume = target*p; previous.volume = Math.min(previous.volume, state.musicVolume*(1-p));
        if (p < 1) requestAnimationFrame(fade);
        else { previous.pause(); previous.src=""; }
      };
      requestAnimationFrame(fade);
    }).catch(()=>{});
  }
  function setMusic(on) {
    state.music = !!on; save();
    if (on) startMusic();
    else {
      stopMusic();
      stopCue();
    }
    syncUI();
  }
  function setVolume(value) {
    state.musicVolume = Math.max(0, Math.min(.5, Number(value)));
    if (musicPlayer) musicPlayer.volume = cuePlayer ? 0 : state.musicVolume;
    if (cuePlayer) cuePlayer.volume = Math.min(.5, state.musicVolume * 1.45);
    save();
  }
  function refreshVoices() {
    voices = window.speechSynthesis ? speechSynthesis.getVoices() : [];
  }
  function voiceFor(locale) {
    refreshVoices();
    const wanted = String(locale || "en").toLowerCase(), base = wanted.split("-")[0];
    return voices.find(v=>v.localService && v.lang.toLowerCase()===wanted)
      || voices.find(v=>v.localService && v.lang.toLowerCase().startsWith(base))
      || voices.find(v=>v.lang.toLowerCase().startsWith(base)) || null;
  }
  function cleanSpeech(text) {
    return String(text || "").replace(/\([^)]*\)|（[^）]*）|\*+|_+|`+/g, " ").replace(/\s+/g, " ").trim();
  }
  function speak(text, locale) {
    if (state.voice === "off") return;
    if (state.voice === "edge") {
      if (nativeEdgeAvailable()) {
        try { window.flutterEdgeSpeech.speak({text:cleanSpeech(text), locale}); } catch (_) {}
      }
      window.dispatchEvent(new CustomEvent("flutter:edge-speech-request", {detail:{text, locale}}));
      return;
    }
    if (!window.speechSynthesis) return;
    const copy = cleanSpeech(text); if (!copy) return;
    speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(copy), voice = voiceFor(locale);
    if (voice) utterance.voice = voice;
    utterance.lang = (voice && voice.lang) || locale || "en";
    utterance.rate = state.voiceRate;
    utterance.pitch = currentEdition === "ja" ? .94 : currentEdition === "zh" ? 1.04 : .98;
    utterance.onstart = ()=>duck(true);
    utterance.onend = utterance.onerror = ()=>duck(false);
    speechSynthesis.speak(utterance);
  }
  function duck(on) {
    clearTimeout(duckTimer);
    if (!musicPlayer || !state.music) return;
    musicPlayer.volume = clampVol(on ? state.musicVolume * .28 : state.musicVolume);
    if (on) duckTimer = setTimeout(()=>duck(false), 30000);
  }
  function nativeEdgeAvailable() {
    return !!(window.flutterEdgeSpeech && typeof window.flutterEdgeSpeech.speak === "function");
  }
  function setVoice(mode) {
    if (!["off","system","edge"].includes(mode)) mode = "off";
    if (mode === "edge" && !nativeEdgeAvailable()) return false;
    state.voice = mode; save();
    if (mode === "off" && window.speechSynthesis) speechSynthesis.cancel();
    syncUI(); return true;
  }
  function syncUI() {
    const l = labels[currentEdition] || labels.en, root = document.getElementById("soundPanel");
    if (!root) return;
    root.querySelector("[data-audio-title]").textContent = l.title;
    root.querySelector("[data-music-label]").textContent = l.music;
    root.querySelector("[data-voice-label]").textContent = l.voice;
    root.querySelector("[data-rate-label]").textContent = l.rate;
    root.querySelector("[data-privacy]").textContent = state.voice === "edge" ? l.privacy : "";
    root.querySelector("[data-edge-note]").textContent = nativeEdgeAvailable() ? "" : l.edgeNote;
    root.querySelector("[data-music-toggle]").checked = state.music;
    root.querySelector("[data-volume]").value = state.musicVolume;
    root.querySelector("[data-rate]").value = state.voiceRate;
    const select = root.querySelector("[data-voice]");
    select.innerHTML = `<option value="off">${l.off}</option><option value="system">${l.system}</option><option value="edge"${nativeEdgeAvailable()?"":" disabled"}>${l.edge}</option>`;
    select.value = state.voice === "edge" && !nativeEdgeAvailable() ? "off" : state.voice;
  }
  function mount() {
    refreshVoices();
    if (window.speechSynthesis) speechSynthesis.onvoiceschanged = refreshVoices;
    syncUI();
  }
  window.FLUTTER_AUDIO = {
    mount, unlock, pauseForOpening, resumeScene, playIntroTheme, setEdition, setScene, playCue, setMusic, setVolume, setVoice, speak,
    setRate(value){ state.voiceRate=Math.max(.75,Math.min(1.25,Number(value)));save(); },
    getState(){return Object.assign({},state);},
    getCapabilities(){return {webAudio:!!(window.AudioContext||window.webkitAudioContext),systemTTS:!!window.speechSynthesis,edgeTTS:nativeEdgeAvailable()};}
  };
})();
