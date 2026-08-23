"use strict";
const CACHE="tell-pwa-20260802131916", CORE=["./","./index.html","./pwa-install.js","./manifest.webmanifest","./icon-192-v2.png","./icon-512-v2.png"];
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting())));
self.addEventListener("activate",e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k.startsWith("tell-pwa-")&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener("fetch",e=>{const r=e.request,u=new URL(r.url);if(r.method!=="GET"||u.origin!==location.origin)return;if(r.mode==="navigate"){e.respondWith(fetch(r).then(x=>{const y=x.clone();caches.open(CACHE).then(c=>c.put("./index.html",y));return x}).catch(()=>caches.match("./index.html")));return}if(r.destination==="")return;e.respondWith(caches.match(r).then(hit=>hit||fetch(r).then(x=>{if(x.ok){const y=x.clone();caches.open(CACHE).then(c=>c.put(r,y))}return x}))) });
