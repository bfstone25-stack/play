(() => {
  "use strict";
  const standalone = matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
  let installEvent = null;
  const lang = (document.documentElement.lang || navigator.language || "en").toLowerCase();
  const copy = lang.startsWith("zh") ? {
    pitch:"喜欢这个产品？", install:"安装应用", close:"稍后",
    updatePitch:"新版本已经准备好", update:"立即更新", refresh:"刷新进入新版",
    installing:"正在安装…", installed:"已安装。如果主屏幕没有图标，请从底部上滑打开“所有应用”，找到它后长按并拖到主屏幕。",
    ios:"在 Safari 中点击“分享”，然后选择“添加到主屏幕”。",
    mac:"在 Safari 菜单栏选择“文件 → 添加到程序坞”。若没有这个选项，需要 macOS Sonoma 14 或更新版本。", got:"知道了"
  } : lang.startsWith("ja") ? {
    pitch:"気に入りましたか？", install:"アプリをインストール", close:"後で",
    updatePitch:"新しいバージョンを利用できます", update:"今すぐ更新", refresh:"再読み込み",
    installing:"インストール中…", installed:"インストール済みです。ホーム画面にない場合は、アプリ一覧を開き、アイコンを長押ししてホーム画面へドラッグしてください。",
    ios:"Safariの共有ボタンから「ホーム画面に追加」を選んでください。",
    mac:"Safariのメニューバーで「ファイル → Dockに追加」を選択してください。表示されない場合はmacOS Sonoma 14以降が必要です。", got:"OK"
  } : lang.startsWith("es") ? {
    pitch:"¿Te gusta?", install:"Instalar app", close:"Ahora no",
    updatePitch:"Hay una nueva versión", update:"Actualizar ahora", refresh:"Recargar",
    installing:"Instalando…", installed:"Instalada. Si no aparece en Inicio, abre Todas las aplicaciones, mantén pulsado el icono y arrástralo a la pantalla de inicio.",
    ios:"En Safari, toca Compartir y elige “Añadir a pantalla de inicio”.",
    mac:"En Safari, elige Archivo → Añadir al Dock. Si no aparece, necesitas macOS Sonoma 14 o posterior.", got:"Entendido"
  } : lang.startsWith("pt") ? {
    pitch:"Gostou?", install:"Instalar app", close:"Agora não",
    updatePitch:"Uma nova versão está pronta", update:"Atualizar agora", refresh:"Recarregar",
    installing:"Instalando…", installed:"Instalado. Se o ícone não aparecer na tela inicial, abra Todos os apps, mantenha o ícone pressionado e arraste-o para a tela inicial.",
    ios:"No Safari, toque em Compartilhar e escolha “Adicionar à Tela de Início”.",
    mac:"No Safari, escolha Arquivo → Adicionar ao Dock. Se a opção não aparecer, é necessário macOS Sonoma 14 ou posterior.", got:"Entendi"
  } : {
    pitch:"Like this experience?", install:"Install app", close:"Not now",
    updatePitch:"A new version is ready", update:"Update now", refresh:"Reload",
    installing:"Installing…", installed:"Installed. If the icon is not on Home, open All apps, then press and drag the icon to your Home screen.",
    ios:"In Safari, tap Share, then choose “Add to Home Screen.”",
    mac:"In Safari, choose File → Add to Dock. If it is unavailable, macOS Sonoma 14 or later is required.", got:"Got it"
  };
  const isiOS = /iphone|ipad|ipod/i.test(navigator.userAgent);
  const safariEngine = /safari/i.test(navigator.userAgent) && !/chrome|chromium|crios|fxios|edgios|edg|opr/i.test(navigator.userAgent);
  const isMacSafari = /macintosh/i.test(navigator.userAgent) && safariEngine;
  const isSafari = (isiOS && safariEngine) || isMacSafari;
  let host;

  function mount(force) {
    if (host || (!force && (standalone || sessionStorage.getItem("pwa-install-dismissed")))) return;
    host = document.createElement("div");
    host.id = "pwa-install-host";
    const root = host.attachShadow({mode:"open"});
    root.innerHTML = '<style>'+[
      ":host{all:initial;position:fixed;z-index:2147483000;left:50%;bottom:max(18px,env(safe-area-inset-bottom));transform:translateX(-50%);font-family:-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif;color:#fff}",
      ".bar{display:flex;align-items:center;gap:12px;min-width:min(430px,calc(100vw - 28px));padding:10px 10px 10px 16px;border:1px solid rgba(255,255,255,.2);border-radius:18px;background:var(--pwa-theme,#20242c);background:color-mix(in srgb,var(--pwa-theme,#20242c) 88%,transparent);box-shadow:0 16px 45px rgba(0,0,0,.28);backdrop-filter:blur(18px) saturate(1.2);animation:up .55s cubic-bezier(.16,.9,.25,1) both}",
      ".mark{width:34px;height:34px;display:grid;place-items:center;border-radius:10px;background:rgba(255,255,255,.14);font-size:11px;font-weight:800;letter-spacing:.06em}",
      ".copy{min-width:0;flex:1}.pitch{font-size:12px;opacity:.72;margin-bottom:2px}.label{font-size:14px;font-weight:700}",
      "button{font:inherit;color:inherit;cursor:pointer}.install{border:0;border-radius:11px;padding:10px 14px;background:#fff;color:#16171a;font-size:13px;font-weight:800;white-space:nowrap}.x{width:28px;height:28px;border:0;background:transparent;opacity:.58;font-size:18px}",
      ".guide{display:none;max-width:420px;padding:18px;border-radius:18px;background:#17191f;box-shadow:0 18px 55px rgba(0,0,0,.4);font-size:14px;line-height:1.55}.guide.show{display:block}.guide button{display:block;margin:14px 0 0 auto;border:0;border-radius:10px;padding:9px 14px;background:#fff;color:#17191f;font-weight:750}.hidden{display:none}",
      "@keyframes up{from{opacity:0;transform:translateY(22px) scale(.96)}}",
      "@media(max-width:520px){.bar{gap:9px;padding-left:11px}.mark{display:none}.pitch{display:none}.install{padding:10px 12px}}",
      "@media(prefers-reduced-motion:reduce){.bar{animation:none}}"
    ].join("")+'</style>'+
      '<div class="bar" role="region" aria-label="'+copy.install+'">'+
        '<div class="mark" aria-hidden="true"></div>'+
        '<div class="copy"><div class="pitch">'+copy.pitch+'</div><div class="label">'+copy.install+'</div></div>'+
        '<button class="install" type="button">'+copy.install+'</button>'+
        '<button class="x" type="button" aria-label="'+copy.close+'">×</button>'+
      '</div>'+
      '<div class="guide" role="dialog" aria-modal="true">'+(isMacSafari ? copy.mac : copy.ios)+'<button type="button">'+copy.got+'</button></div>';
    const manifest = document.querySelector('link[rel="manifest"]');
    const theme = document.querySelector('meta[name="theme-color"]');
    host.style.setProperty("--pwa-theme", (theme && theme.content) || "#20242c");
    root.querySelector(".mark").textContent = document.title.trim().slice(0,2).toUpperCase();
    root.querySelector(".x").onclick = dismiss;
    root.querySelector(".install").onclick = install;
    root.querySelector(".guide button").onclick = dismiss;
    document.body.appendChild(host);
  }
  function dismiss() {
    sessionStorage.setItem("pwa-install-dismissed","1");
    if (host) host.remove(); host = null;
  }
  function showGuide(message) {
    if (!host) return;
    const root = host.shadowRoot, guide = root.querySelector(".guide");
    root.querySelector(".bar").classList.add("hidden");
    guide.innerHTML = message+'<button type="button">'+copy.got+'</button>';
    guide.querySelector("button").onclick = dismiss;
    guide.classList.add("show");
  }
  function installedNotice() {
    showGuide(copy.installed);
  }
  function showUpdate() {
    if (!host) mount(true);
    if (!host) return;
    const root=host.shadowRoot, bar=root.querySelector(".bar"), button=root.querySelector(".install");
    bar.classList.remove("hidden");
    root.querySelector(".pitch").textContent=copy.updatePitch;
    root.querySelector(".label").textContent=copy.update;
    button.textContent=copy.refresh;
    button.classList.remove("hidden");
    button.onclick=()=>location.reload();
  }
  async function install() {
    if (installEvent) {
      installEvent.prompt();
      const result = await installEvent.userChoice.catch(() => ({outcome:"dismissed"}));
      installEvent = null;
      if (result.outcome === "accepted" && host) {
        const root = host.shadowRoot;
        root.querySelector(".label").textContent = copy.installing;
        root.querySelector(".install").classList.add("hidden");
        setTimeout(() => { if (host) dismiss(); }, 15000);
      }
      return;
    }
    if (isSafari) {
      showGuide(isMacSafari ? copy.mac : copy.ios);
    }
  }
  addEventListener("beforeinstallprompt", event => {
    event.preventDefault(); installEvent = event; mount(false);
  });
  addEventListener("appinstalled", installedNotice);
  if (isSafari && !standalone) addEventListener("load", () => setTimeout(()=>mount(false), 1800), {once:true});
  if ("serviceWorker" in navigator) {
    let hadController=!!navigator.serviceWorker.controller;
    addEventListener("load", () => {
      navigator.serviceWorker.register("./sw.js").then(registration => {
        if (registration.waiting && hadController) showUpdate();
        registration.update().catch(()=>{});
      }).catch(()=>{});
    });
    navigator.serviceWorker.addEventListener("controllerchange", () => {
      if (hadController) showUpdate();
      hadController=true;
    });
  }
  window.PWA_INSTALL = {show:()=>mount(false), checkForUpdate:()=>("serviceWorker" in navigator?navigator.serviceWorker.getRegistration().then(r=>r&&r.update()):Promise.resolve())};
})();