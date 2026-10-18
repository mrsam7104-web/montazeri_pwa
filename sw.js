const CACHE_NAME = 'montazeri-pwa-v5';

const CORE = [
  '/',
  '/index.html',
  '/admin.html',
  '/customer.html',
  '/manifest.webmanifest',
  '/icon-192.png',
  '/icon-512.png',
  '/supabase-config.js'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(async cache => {
      await Promise.all(
        CORE.map(async path => {
          try {
            await cache.add(path);
          } catch (error) {
            // اگر فایلی در دسترس نبود، نصب ادامه پیدا کند
          }
        })
      );
    })
  );

  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys =>
        Promise.all(
          keys
            .filter(
              key =>
                key.startsWith('montazeri-pwa-') &&
                key !== CACHE_NAME
            )
            .map(key => caches.delete(key))
        )
      )
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;

  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  // فقط درخواست‌های مربوط به خود سایت
  if (url.origin !== self.location.origin) return;

  // صفحات سایت: ابتدا نسخه آنلاین، در صورت قطعی نسخه ذخیره‌شده
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then(response => {
          if (response.ok) {
            const copy = response.clone();

            caches.open(CACHE_NAME).then(cache => {
              cache.put(request, copy);
            });
          }

          return response;
        })
        .catch(async () => {
          return (
            (await caches.match(request)) ||
            (await caches.match('/index.html')) ||
            Response.error()
          );
        })
    );

    return;
  }

  // فایل‌ها: اگر نسخه ذخیره‌شده وجود داشت، سریع نمایش بده
  event.respondWith(
    caches.match(request).then(cached => {
      const update = fetch(request)
        .then(response => {
          if (response.ok) {
            const copy = response.clone();

            caches.open(CACHE_NAME).then(cache => {
              cache.put(request, copy);
            });
          }

          return response;
        })
        .catch(() => cached || Response.error());

      return cached || update;
    })
  );
});
