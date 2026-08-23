(function () {
  "use strict";

  const scripts = {
    en: {
      duration: 6900,
      shots: [
        {at:0, kind:"dawn", scene:"openings/en-dawn-v1.webp", eyebrow:"7:12 AM", text:"Morning finds him already awake."},
        {at:1650, kind:"message", scene:"openings/en-dawn-v1.webp", eyebrow:"ONE NEW MESSAGE", text:"Coffee. No sugar.\nI remembered."},
        {at:3550, kind:"gaze", scene:"openings/en-dawn-v1.webp", eyebrow:"", text:"“Try not to look so surprised.”"},
        {at:5150, kind:"brand"}
      ]
    },
    zh: {
      duration: 7100,
      shots: [
        {at:0, kind:"window", scene:"openings/zh-late-night-v1.webp", eyebrow:"23:08", text:"城市很晚，你也很累。"},
        {at:1700, kind:"message", scene:"openings/zh-late-night-v1.webp", eyebrow:"他发来一条消息", text:"热美式，少冰。\n我记得。"},
        {at:3800, kind:"reach", scene:"openings/zh-late-night-v1.webp", eyebrow:"", text:"有些话，你只说过一次。"},
        {at:5350, kind:"brand"}
      ]
    },
    ja: {
      duration: 8600,
      shots: [
        {at:0, kind:"rain", scene:"openings/ja-rain-train-v1.webp", eyebrow:"午後十一時", text:"雨は、まだ止まない。"},
        {at:2300, kind:"reflection", scene:"openings/ja-rain-train-v1.webp", eyebrow:"未送信", text:"会いたかった"},
        {at:4550, kind:"umbrella", scene:"openings/ja-rain-train-v1.webp", eyebrow:"", text:"「傘、持ってきた。」"},
        {at:6850, kind:"brand"}
      ]
    },
    es: {
      duration: 6200,
      shots: [
        {at:0, kind:"steps", scene:"openings/es-midnight-v1.webp", eyebrow:"MADRID · 00:17", text:"—Llegas tarde."},
        {at:1250, kind:"answer", scene:"openings/es-midnight-v1.webp", eyebrow:"", text:"—¿Me estabas esperando?"},
        {at:2650, kind:"near", scene:"openings/es-midnight-v1.webp", eyebrow:"", text:"“No te hagas ilusiones.”"},
        {at:4450, kind:"brand"}
      ]
    },
    "pt-BR": {
      duration: 6700,
      shots: [
        {at:0, kind:"sun", scene:"openings/pt-sunset-v1.webp", eyebrow:"18:42", text:"O dia ainda não terminou."},
        {at:1450, kind:"laugh", scene:"openings/pt-sunset-v1.webp", eyebrow:"", text:"—Você sempre chega assim?"},
        {at:2950, kind:"close", scene:"openings/pt-sunset-v1.webp", eyebrow:"", text:"—Assim como?\n—Mudando o clima."},
        {at:4900, kind:"brand"}
      ]
    }
  };

  let timers = [];
  let current = null;
  let audioContext = null;
  let ambientMaster = null;
  let ambientSources = [];
  let ambientRecording = null;
  const fieldRecordings = {
    en:"audio/ambience/en-city-morning.mp3",
    zh:"audio/ambience/zh-night-city.mp3",
    ja:"audio/ambience/ja-rain-train.mp3",
    es:"audio/ambience/es-night-plaza.mp3",
    "pt-BR":"audio/ambience/pt-ocean-sunset.mp3"
  };

  function clearTimers() {
    timers.forEach(clearTimeout);
    timers = [];
  }
  function ensureAudio() {
    if (audioContext) return audioContext;
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return null;
    try { audioContext = new Ctx(); } catch (_) {}
    return audioContext;
  }
  function heartbeat() {
    const ctx = ensureAudio();
    if (!ctx || ctx.state !== "running") return;
    const thump = (start, frequency, gain) => {
      const osc = ctx.createOscillator(), amp = ctx.createGain();
      osc.type = "sine"; osc.frequency.setValueAtTime(frequency, start);
      osc.frequency.exponentialRampToValueAtTime(48, start + .16);
      amp.gain.setValueAtTime(.0001, start);
      amp.gain.exponentialRampToValueAtTime(gain, start + .018);
      amp.gain.exponentialRampToValueAtTime(.0001, start + .21);
      osc.connect(amp).connect(ctx.destination);
      osc.start(start); osc.stop(start + .23);
    };
    const now = ctx.currentTime;
    // Low body plus a restrained upper transient so the brand beat survives
    // phone/laptop speakers without becoming a synthetic notification.
    thump(now, 94, .27);thump(now, 176, .052);
    thump(now + .24, 82, .19);thump(now + .24, 154, .038);
  }
  function unlockAudio() {
    const ctx = ensureAudio();
    if (!ctx) return Promise.resolve(false);
    if (ctx.state === "running") return Promise.resolve(true);
    return ctx.resume().then(()=>ctx.state === "running").catch(()=>false);
  }
  function tone(freq, duration, gain, delay, type) {
    const ctx = ensureAudio(); if (!ctx || ctx.state !== "running") return;
    const osc = ctx.createOscillator(), amp = ctx.createGain(), now = ctx.currentTime + (delay || 0);
    osc.type = type || "sine"; osc.frequency.setValueAtTime(freq, now);
    amp.gain.setValueAtTime(.0001, now);
    amp.gain.exponentialRampToValueAtTime(gain, now + .025);
    amp.gain.exponentialRampToValueAtTime(.0001, now + duration);
    osc.connect(amp).connect(ambientMaster || ctx.destination);
    osc.start(now); osc.stop(now + duration + .03);
  }
  function noiseLayer(filterType, frequency, gain) {
    const ctx = ensureAudio(); if (!ctx || !ambientMaster) return;
    const length = ctx.sampleRate * 2, buffer = ctx.createBuffer(1, length, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    let brown = 0;
    for (let i=0;i<length;i++) {
      const white = Math.random()*2-1;
      brown = (brown + .025*white)/1.025;
      data[i] = filterType === "lowpass" ? brown*3.4 : white*.72;
    }
    const src=ctx.createBufferSource(), filter=ctx.createBiquadFilter(), amp=ctx.createGain();
    src.buffer=buffer;src.loop=true;filter.type=filterType;filter.frequency.value=frequency;amp.gain.value=gain;
    src.connect(filter).connect(amp).connect(ambientMaster);src.start();
    ambientSources.push(src);
  }
  function noisePass(delay, duration, frequency, gain, filterType, attack) {
    const ctx=ensureAudio();if(!ctx||!ambientMaster)return;
    const length=Math.ceil(ctx.sampleRate*duration),buffer=ctx.createBuffer(1,length,ctx.sampleRate);
    const data=buffer.getChannelData(0);
    for(let i=0;i<length;i++)data[i]=(Math.random()*2-1)*.7;
    const src=ctx.createBufferSource(),filter=ctx.createBiquadFilter(),amp=ctx.createGain();
    const at=ctx.currentTime+delay;
    src.buffer=buffer;filter.type=filterType||"lowpass";filter.frequency.value=frequency;filter.Q.value=.7;
    amp.gain.setValueAtTime(.0001,at);amp.gain.exponentialRampToValueAtTime(gain,at+duration*(attack||.42));
    amp.gain.exponentialRampToValueAtTime(.0001,at+duration);
    src.connect(filter).connect(amp).connect(ambientMaster);src.start(at);src.stop(at+duration);
    ambientSources.push(src);
  }
  function stopSoundscape() {
    if(ambientRecording){ambientRecording.pause();ambientRecording.src="";ambientRecording=null;}
    const ctx=ensureAudio(),master=ambientMaster;if(!ctx||!master)return;
    const now=ctx.currentTime;
    master.gain.cancelScheduledValues(now);master.gain.setValueAtTime(Math.max(.0001,master.gain.value),now);
    master.gain.exponentialRampToValueAtTime(.0001,now+.55);
    const sources=ambientSources.slice();ambientMaster=null;ambientSources=[];
    setTimeout(()=>sources.forEach(s=>{try{s.stop()}catch(_){}}),650);
  }
  function fadeRecording(duration) {
    const recording=ambientRecording;if(!recording)return;
    const from=recording.volume,started=performance.now();
    const fade=now=>{
      if(ambientRecording!==recording)return;
      const p=Math.min(1,(now-started)/duration);
      recording.volume=from*(1-p);
      if(p<1)requestAnimationFrame(fade);
      else{recording.pause();recording.currentTime=0;}
    };
    requestAnimationFrame(fade);
  }
  function beginSoundscape(id) {
    stopSoundscape();
    const ctx=ensureAudio();if(!ctx||ctx.state!=="running")return;
    ambientMaster=ctx.createGain();ambientMaster.gain.value=.0001;ambientMaster.connect(ctx.destination);
    ambientMaster.gain.exponentialRampToValueAtTime(.95,ctx.currentTime+.35);
    const recording=new Audio(fieldRecordings[id]||fieldRecordings.en);
    recording.preload="auto";recording.volume=id==="zh"?.62:.82;
    ambientRecording=recording;recording.play().catch(()=>{});
  }
  function accent(id, kind) {
    if (!ambientMaster) return;
    // A notification is a narrative motif only in the Chinese late-night edition.
    if(id==="zh"&&kind==="message"){
      tone(880,.18,.045,0,"sine");tone(1175,.28,.035,.13,"sine");
    }
  }

  function renderShot(overlay, edition, shot) {
    const frame = overlay.querySelector(".op-frame");
    frame.className = "op-frame";
    void frame.offsetWidth;
    frame.className = "op-frame op-" + shot.kind;
    frame.innerHTML = "";
    accent(edition.id, shot.kind);
    if (shot.kind === "brand") {
      fadeRecording(720);
      frame.innerHTML =
        '<svg class="pulse-line op-heartline" viewBox="0 0 230 20" aria-hidden="true"><path d="M1 11h73l8-1 5-8 8 17 7-14 7 6h120"/></svg>'+
        '<div class="op-wordmark">FLUTTER</div>'+
        (edition.localTitle ? '<div class="op-local">'+edition.localTitle+'</div>' : "")+
        '<div class="op-category">HER · PSYCHE · RPG</div>'+
        '<div class="op-tagline">'+edition.tagline+'</div>';
      timers.push(setTimeout(heartbeat,780));
      return;
    }
    const scene = shot.scene
      ? '<div class="op-scene-image" aria-hidden="true" style="--op-scene:url(&quot;'+shot.scene+'&quot;)"></div>'
      : "";
    const character = shot.image
      ? '<div class="op-character" aria-hidden="true" style="--op-image:url(&quot;portraits/'+shot.image+'&quot;)"></div>'
      : "";
    frame.innerHTML =
      scene+'<div class="op-world" aria-hidden="true"><i></i><i></i><i></i></div>'+character+
      '<div class="op-caption">'+
        (shot.eyebrow ? '<div class="op-eyebrow">'+shot.eyebrow+'</div>' : "")+
        '<div class="op-text">'+shot.text.replace(/\n/g,"<br>")+'</div>'+
      '</div>';
  }

  function finish() {
    clearTimers();
    stopSoundscape();
    const overlay = document.getElementById("opening");
    if (!overlay) return;
    const finishedEdition = current;
    overlay.classList.remove("show");
    overlay.setAttribute("aria-hidden", "true");
    if (current) {
      try { localStorage.setItem("flutter_opening_seen_"+current, "1"); } catch (_) {}
    }
    current = null;
    window.dispatchEvent(new CustomEvent("flutter:opening-finished", {
      detail: {edition: finishedEdition}
    }));
  }

  function play(id, options) {
    const cfg = scripts[id] || scripts.en;
    const edition = FLUTTER_EDITIONS.editions[id] || FLUTTER_EDITIONS.editions.en;
    const overlay = document.getElementById("opening");
    if (!overlay) return;
    clearTimers(); current = id;
    if (window.FLUTTER_AUDIO) FLUTTER_AUDIO.pauseForOpening();
    unlockAudio().then(running=>{
      if(running && current===id && !ambientMaster)beginSoundscape(id);
    });
    overlay.dataset.opening = id;
    overlay.classList.add("show");
    overlay.setAttribute("aria-hidden", "false");
    const full = !options || options.full !== false;
    if (!full) {
      beginSoundscape(id);
      renderShot(overlay, edition, {kind:"brand"});
      timers.push(setTimeout(finish, 1550));
      return;
    }
    beginSoundscape(id);
    cfg.shots.forEach(shot => timers.push(setTimeout(()=>renderShot(overlay, edition, shot), shot.at)));
    timers.push(setTimeout(finish, cfg.duration));
  }

  function playInitial(id) {
    let seen = false;
    try { seen = !!localStorage.getItem("flutter_opening_seen_"+id); } catch (_) {}
    play(id, {full:!seen});
  }
  function playWithSound(id, options) {
    unlockAudio().then(()=>play(id, options));
  }
  function prime() {
    unlockAudio().then(running=>{if(running)heartbeat();});
  }

  const unlockOpeningSound = ()=>{
    const edition=current;
    unlockAudio().then(running=>{
      if(running && edition && current===edition)beginSoundscape(edition);
    });
  };
  window.addEventListener("pointerdown", unlockOpeningSound, {once:true});
  window.addEventListener("keydown", unlockOpeningSound, {once:true});
  window.FLUTTER_OPENING = {play, playInitial, playWithSound, prime, skip:finish};
})();
