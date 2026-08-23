const CACHE = "rebound-v6";
const ASSETS = [
  ".",
  "index.html",
  "config.js",
  "manifest.json",
  "icon-192.png",
  "icon-512.png",
  "css/style.css",
  "js/kernel.js",
  "js/copy.js",
  "js/audio.js",
  "js/stage.js",
  "js/game.js",
  "assets/title.webp",
  "assets/guard.webp",
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  e.respondWith(
    fetch(e.request).then((resp) => {
      const cp = resp.clone();
      caches.open(CACHE).then((c) => c.put(e.request, cp)).catch(() => {});
      return resp;
    }).catch(() => caches.match(e.request).then((r) => r || caches.match("index.html"))),
  );
});
