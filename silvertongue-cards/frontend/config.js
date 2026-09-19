/* API root. Served by the backend itself at :8919 in the prototype; on a foreign host
 * (itch, Nutaku iframe) the gateway path. Same shape as the parent's config.js. */
window.SILVERTONGUE_CARDS_API = (function () {
  var h = location.hostname || "";
  var off = location.protocol === "file:" || /itch\.zone$/i.test(h) || /\.itch\.io$/i.test(h) || /nutaku/i.test(h);
  return off ? "https://apps.blazecore.dev/silvertongue-cards" : location.origin;
})();
window.TEL_APP = "silvertongue-cards";
window.TEL_API = "https://apps.blazecore.dev/silvertongue-cards";
window.APP_API = window.TEL_API;
/* gate.js: no direct link, no buy URL. This build sells nothing through Gate; it only
 * uses Gate.has / Gate.unlock as the cg_* key store that cg.js expects. */
window.GATE_CONFIG = {price: "", buyUrl: "", seconds: 0};
window.BOARD_FROM = "silvertongue-cards";
