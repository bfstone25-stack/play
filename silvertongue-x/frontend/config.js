// The gateway is the only host that serves the API same-origin. Every other place this
// page ships -- itch (html-classic.itch.zone), the ad track (free.blazecore.dev, *.workers.dev,
// both static Cloudflare assets with no backend) and a plain local static server -- has to
// name the gateway, which sends Access-Control-Allow-Origin: *. Until 2026-10-06 only itch
// and file:// were treated as foreign, so on free.blazecore.dev every API call went to
// free.blazecore.dev/silvertongue-ah/... and 404'd: no adversary/case loaded, and players were left
// clicking an empty map. ?api=local still opts into a local dev proxy.
window.SILVERTONGUE_API = (function () {
  var h = location.hostname || "", local = false;
  try { local = new URLSearchParams(location.search).get("api") === "local"; } catch (e) {}
  return (h === "apps.blazecore.dev" || local)
    ? location.origin + "/silvertongue-ah"
    : "https://apps.blazecore.dev/silvertongue-ah";
})();

// closed-loop telemetry endpoint
window.TEL_APP = "silvertongue-ah";
window.TEL_API = "https://apps.blazecore.dev/silvertongue-ah";
window.APP_API = window.TEL_API;
