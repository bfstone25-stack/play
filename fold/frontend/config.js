window.TEL_API = (function () {
  var h = location.hostname || "";
  var off = location.protocol === "file:"
    || /itch\.zone$/i.test(h)
    || /\.itch\.io$/i.test(h);
  return off
    ? "https://apps.blazecore.dev"
    : location.origin;
})();
window.APP_API = window.TEL_API;
