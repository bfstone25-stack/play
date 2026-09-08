window.SILVERTONGUE_API = (function () {
  var h = location.hostname || "";
  var off = location.protocol === "file:"
    || /itch\.zone$/i.test(h)
    || /\.itch\.io$/i.test(h);
  return off
    ? "https://apps.blazecore.dev/silvertongue"
    : location.origin + "/silvertongue";
})();

// closed-loop telemetry endpoint
window.TEL_APP = "silvertongue";
window.TEL_API = "https://apps.blazecore.dev/silvertongue";
window.APP_API = window.TEL_API;
