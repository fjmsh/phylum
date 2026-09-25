const CACHE_NAME = "phylum-app-cache";

const CACHED_URLS = [
  "/",
  "/phylum.webmanifest",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
];

const APP_ROUTES = [
  /^\/$/,
  /^\/accounts/,
  /^\/login/,
  /^\/setup/,
  /^\/home/,
  /^\/recents/,
  /^\/shared/,
  /^\/settings/,
  /^\/trash/,
  /^\/file/,
  /^\/folder/,
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async function () {
      self.skipWaiting();
      const cache = await caches.open(CACHE_NAME);
      await cache.addAll(CACHED_URLS);
    })(),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async function () {
      const cacheNames = await caches.keys();

      await Promise.all(
        cacheNames
          .filter((cacheName) => {
            const deleteThisCache = cacheName !== CACHE_NAME;

            return deleteThisCache;
          })
          .map((cacheName) => caches.delete(cacheName)),
      );
    })(),
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    const path = new URL(event.request.url).pathname;

    if (APP_ROUTES.some((rx) => rx.test(path))) {
      const request = new Request("/", {
        method: event.request.method,
        headers: event.request.headers,
        mode: "same-origin",
        credentials: event.request.credentials,
        redirect: "follow",
      });
      event.respondWith(
        fetch(request).catch(() => {
          return caches.match("/");
        }),
      );
    }
  }
});
