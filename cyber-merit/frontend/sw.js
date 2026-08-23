const CACHE = "cyber-merit-1.0.0";
const ASSETS = [
  "./",
  "index.html",
  "css/style.css?v=1.0.0",
  "js/i18n.js?v=1.0.0",
  "js/save.js?v=1.0.0",
  "js/koans.js?v=1.0.0",
  "js/liturgy.js?v=1.0.0",
  "js/audio.js?v=1.0.0",
  "js/particles.js?v=1.0.0",
  "js/altar.js?v=1.0.0",
  "js/mascot.js?v=1.0.0",
  "js/game.js?v=1.0.0",
  "manifest.webmanifest",
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  e.respondWith(
    caches.match(e.request).then((hit) => hit || fetch(e.request).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(e.request, copy)).catch(() => {});
      return res;
    }).catch(() => hit))
  );
});
