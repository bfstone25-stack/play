"use strict";
/* Service worker for VESPER.
 *
 * Two changes from the parent's copy, both found by a fix not reaching a
 * browser that had already loaded the game once:
 *
 * 1. THE CACHE NAME IS STAMPED BY THE BUILD. The parent's copy hardcodes
 *    "flutter-pwa-20260817071322" and nothing ever bumps it, while `activate`
 *    only deletes caches whose key differs from the current one — so the cache
 *    could never be invalidated by shipping anything. tools/build_free.sh
 *    rewrites __BUILD_STAMP__ and fails if the token survives.
 *
 * 2. CODE IS NETWORK-FIRST, MEDIA IS CACHE-FIRST. The parent is cache-first for
 *    every subresource, which is right for 197 MB of audio and portraits and
 *    wrong for cg.js: a returning player would have kept the build of cg.js
 *    that could not fetch an unlocked plate, forever, with no symptom other
 *    than the plate staying covered. Scripts and JSON now go to the network
 *    first and fall back to the cache offline, which keeps the offline promise
 *    while letting a fix actually land.
 */
const CACHE = "flutter-ah-__BUILD_STAMP__";
const CORE = ["./", "./index.html", "./pwa-install.js", "./manifest.webmanifest",
              "./icon-192-v2.png", "./icon-512-v2.png"];
const CODE = /\.(js|json|webmanifest)(\?|$)/i;

self.addEventListener("install", e =>
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting())));

self.addEventListener("activate", e =>
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => (k.startsWith("flutter-pwa-") || k.startsWith("flutter-ah-")) && k !== CACHE)
                              .map(k => caches.delete(k))))
    .then(() => self.clients.claim())));

self.addEventListener("fetch", e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== "GET" || u.origin !== location.origin) return;

  if (r.mode === "navigate") {
    e.respondWith(fetch(r).then(x => {
      const y = x.clone(); caches.open(CACHE).then(c => c.put("./index.html", y)); return x;
    }).catch(() => caches.match("./index.html")));
    return;
  }
  if (r.destination === "") return;

  if (CODE.test(u.pathname)) {                       // network-first: fixes must land
    e.respondWith(fetch(r).then(x => {
      if (x.ok) { const y = x.clone(); caches.open(CACHE).then(c => c.put(r, y)); }
      return x;
    }).catch(() => caches.match(r)));
    return;
  }
  e.respondWith(caches.match(r).then(hit => hit || fetch(r).then(x => {   // media: cache-first
    if (x.ok) { const y = x.clone(); caches.open(CACHE).then(c => c.put(r, y)); }
    return x;
  })));
});
