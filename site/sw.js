/*
 * School On App Connect - service worker
 *
 * Deliberately minimal and privacy-safe:
 *  - Only GET requests are touched, everything else passes through untouched.
 *  - No authenticated page is ever stored in the cache, so a shared phone
 *    cannot leak a previous student's data.
 *  - The only cached asset is the offline fallback page.
 */

const CACHE_NAME = 'soa-connect-v1';
const OFFLINE_URL = '/offline.html';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll([OFFLINE_URL]))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)))
      )
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Never intercept anything that is not a plain GET (login POSTs, payments, uploads).
  if (request.method !== 'GET') {
    return;
  }

  // Only handle our own origin.
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) {
    return;
  }

  // Network first. If the network fails, show the offline page instead of
  // the browser error. Nothing is cached from the response.
  event.respondWith(
    fetch(request).catch(() =>
      caches.match(OFFLINE_URL).then((cached) => cached || Response.error())
    )
  );
});
