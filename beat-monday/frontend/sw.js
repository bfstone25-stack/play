const CACHE = 'beatmonday-v4';
const ASSETS = [
  '.', 'index.html', 'game.js', 'audio.js', 'i18n.js', 'config.js', 'manifest.json',
  'icon-192.png', 'icon-512.png', 'promo.jpg', 'assets/title.webp',
  'assets/fighters/hero.webp', 'assets/fighters/intern.webp', 'assets/fighters/pm.webp',
  'assets/fighters/hr.webp', 'assets/fighters/finance.webp', 'assets/fighters/boss.webp',
  'assets/sprites/stage-office.webp',
  'assets/sprites/hero-idle.webp', 'assets/sprites/hero-walk.webp', 'assets/sprites/hero-punch.webp', 'assets/sprites/hero-kick.webp', 'assets/sprites/hero-hit.webp',
  'assets/sprites/intern-idle.webp', 'assets/sprites/intern-walk.webp', 'assets/sprites/intern-punch.webp', 'assets/sprites/intern-kick.webp', 'assets/sprites/intern-hit.webp',
  'assets/sprites/pm-idle.webp', 'assets/sprites/pm-walk.webp', 'assets/sprites/pm-punch.webp', 'assets/sprites/pm-kick.webp', 'assets/sprites/pm-hit.webp',
  'assets/sprites/hr-idle.webp', 'assets/sprites/hr-walk.webp', 'assets/sprites/hr-punch.webp', 'assets/sprites/hr-kick.webp', 'assets/sprites/hr-hit.webp',
  'assets/sprites/finance-idle.webp', 'assets/sprites/finance-walk.webp', 'assets/sprites/finance-punch.webp', 'assets/sprites/finance-kick.webp', 'assets/sprites/finance-hit.webp',
  'assets/sprites/boss-idle.webp', 'assets/sprites/boss-walk.webp', 'assets/sprites/boss-punch.webp', 'assets/sprites/boss-kick.webp', 'assets/sprites/boss-hit.webp'
];
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(fetch(e.request).then(resp => {
    const cp = resp.clone();
    caches.open(CACHE).then(c => c.put(e.request, cp)).catch(() => {});
    return resp;
  }).catch(() => caches.match(e.request).then(r => r || caches.match('index.html'))));
});
