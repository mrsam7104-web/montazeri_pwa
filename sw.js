const CACHE_NAME = 'montazeri-pwa-cloud-v3';
const CORE = ['./','./index.html','./admin.html','./customer.html','./manifest.webmanifest','./icons/icon-192.png','./icons/icon-512.png','./supabase-config.js'];
self.addEventListener('install',event=>{event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(CORE)).catch(()=>{}));self.skipWaiting()});
self.addEventListener('activate',event=>{event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE_NAME).map(k=>caches.delete(k)))));self.clients.claim()});
self.addEventListener('fetch',event=>{const req=event.request;if(req.method!=='GET')return;const url=new URL(req.url);if(url.origin!==self.location.origin)return;event.respondWith(fetch(req).then(res=>{if(res&&res.status===200){const copy=res.clone();caches.open(CACHE_NAME).then(c=>c.put(req,copy))}return res}).catch(()=>caches.match(req).then(r=>r||caches.match('./index.html'))))});
