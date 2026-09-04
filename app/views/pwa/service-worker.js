// Sangam Service Worker — Web Push Notifications & Offline Support
// Version: 2026.1

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
});

// Process Web Push Notifications
self.addEventListener('push', (event) => {
  let data = {};
  try {
    if (event.data) {
      data = event.data.json();
    }
  } catch (e) {
    data = {
      title: 'Sangam',
      options: {
        body: event.data ? event.data.text() : 'You have a new update on Sangam.'
      }
    };
  }

  const title = data.title || 'Sangam Notification';
  const options = data.options || {};

  // Fill in reliable defaults
  const notificationOptions = {
    body: options.body || 'You have new activity waiting for you on Sangam.',
    icon: options.icon || '/icon.svg',
    badge: options.badge || '/icon.svg',
    tag: options.tag || ('sangam-' + Date.now()),
    renotify: options.renotify !== undefined ? options.renotify : true,
    vibrate: options.vibrate || [100, 50, 100],
    data: options.data || { path: '/' }
  };

  event.waitUntil(
    self.registration.showNotification(title, notificationOptions)
  );
});

// Handle Notification Click & Navigation
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const targetPath = (event.notification.data && event.notification.data.path) ? event.notification.data.path : '/';
  const targetUrl = new URL(targetPath, self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // 1. Check if there's already an open tab with this application
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url && 'focus' in client) {
          // If already on the exact URL or same origin, navigate and focus
          client.navigate(targetUrl);
          return client.focus();
        }
      }

      // 2. If no window is open, open a new window
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
