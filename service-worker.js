const CACHE = "radio-dgae-v1";
const ASSETS = ["./", "./index.html", "./css/styles.css", "./js/script.js", "./js/stations.js", "./manifest.json"];

self.addEventListener("install", function (e) {
  e.waitUntil(caches.open(CACHE).then(function (c) { return c.addAll(ASSETS); }));
  self.skipWaiting();
});

self.addEventListener("activate", function (e) {
  e.waitUntil(caches.keys().then(function (k) {
    return Promise.all(k.filter(function (n) { return n !== CACHE; }).map(function (n) { return caches.delete(n); }));
  }));
  self.clients.claim();
});

self.addEventListener("fetch", function (e) {
  if (e.request.url.includes("stream.zeno.fm")) {
    e.respondWith(fetch(e.request).catch(function () { return new Response("Sem conexão", { status: 503 }); }));
    return;
  }
  e.respondWith(caches.match(e.request).then(function (r) { return r || fetch(e.request); }));
});