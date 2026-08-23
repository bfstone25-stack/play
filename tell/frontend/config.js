window.TELL_API = (function () {
  var h = location.hostname || "";
  var off = location.protocol === "file:"
    || /itch\.zone$/i.test(h)
    || /\.itch\.io$/i.test(h);
  return off
    ? "https://apps.blazecore.dev/tell"
    : location.origin + "/tell";
})();
