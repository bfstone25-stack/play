// Where this client talks to.
//
// The adult fork is NOT hosted by the gateway the way the SFW parent is: the
// page itself ships to *.workers.dev (ops/check_adsense_isolation.py — adult
// titles must not live on the AdSense domain), while the story backend and the
// gated-asset endpoints stay on apps.blazecore.dev. So the only host that can
// serve the API same-origin is a local dev proxy; every real deployment is
// cross-origin and must name the gateway. The gateway sends
// Access-Control-Allow-Origin: * (gateway/app.py CORSMiddleware), so this works
// from workers.dev, from html-classic.itch.zone and from file://.
var GATEWAY = "https://apps.blazecore.dev";

window.FLUTTER_API = (function () {
  var h = location.hostname || "";
  var local = /^(127\.0\.0\.1|localhost|\[::1\]|0\.0\.0\.0)$/.test(h);
  return local ? location.origin + "/flutter-after-hours"
               : GATEWAY + "/flutter-after-hours";
})();

// The single-use ticket endpoints for the uncensored plates (/unlock/start and
// /unlock/fetch) live at the gateway ROOT, not under the app prefix — see
// gateway/app.py, where they are declared with @app.post("/unlock/start")
// above the catch-all /{name}/{path} proxy. Pointing this at the app prefix
// instead sends the call into that proxy, which 404s "unknown app".
window.UNLOCK_API = (function () {
  var h = location.hostname || "";
  var local = /^(127\.0\.0\.1|localhost|\[::1\]|0\.0\.0\.0)$/.test(h);
  return local ? location.origin : GATEWAY;   // the dev proxy forwards /unlock/*
})();
window.GATED_CG_APP = "flutter-after-hours";

// closed-loop telemetry endpoint
window.TEL_APP = "flutter-after-hours";
window.TEL_API = GATEWAY + "/flutter-after-hours";
window.APP_API = window.TEL_API;
