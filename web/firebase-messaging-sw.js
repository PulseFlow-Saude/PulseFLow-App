// Firebase Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase configuration
firebase.initializeApp({
  apiKey: "AIzaSyBwXGHNg6eV-ABZKvK1SWGpUxb7Fh-8RRI",
  authDomain: "pulseflow-f9154.firebaseapp.com",
  projectId: "pulseflow-f9154",
  storageBucket: "pulseflow-f9154.firebasestorage.app",
  messagingSenderId: "1046085330534",
  appId: "1:1046085330534:web:39e08c1f748fe93b4bafa7"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'PulseFlow';
  const notificationOptions = {
    body: payload.notification?.body || 'Nova notificação',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'pulseflow-notification',
    requireInteraction: true,
    vibrate: [200, 100, 200],
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked', event);
  event.notification.close();
  
  // Open the app when notification is clicked
  event.waitUntil(
    clients.openWindow('/')
  );
});

