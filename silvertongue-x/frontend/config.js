window.SILVERTONGUE_API = (function () {
  var h = location.hostname || "";
  var off = location.protocol === "file:"
    || /itch\.zone$/i.test(h)
    || /\.itch\.io$/i.test(h);
  return off
    ? "https://apps.blazecore.dev/silvertongue-ah"
    : location.origin + "/silvertongue-ah";
})();

// closed-loop telemetry endpoint
window.TEL_APP = "silvertongue-ah";
window.TEL_API = "https://apps.blazecore.dev/silvertongue-ah";
window.APP_API = window.TEL_API;
