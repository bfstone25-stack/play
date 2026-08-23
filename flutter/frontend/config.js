// Same-origin on apps.blazecore.dev / the gateway. file:// and itch.io HTML
// embeds are a different origin, so they must hit the public gateway.
window.FLUTTER_API = (function () {
  var h = location.hostname || "";
  var off = location.protocol === "file:"
    || /itch\.zone$/i.test(h)
    || /\.itch\.io$/i.test(h);
  return off
    ? "https://apps.blazecore.dev/flutter"
    : location.origin + "/flutter";
})();
