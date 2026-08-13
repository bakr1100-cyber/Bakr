// Lets push notifications (see NotificationService/AccountSyncService, and
// the server-side price-check job in cloudflare-worker/) actually show up
// while this tab/PWA isn't focused - the `firebase_messaging` Flutter
// plugin looks for this exact file at the web root and registers it as a
// service worker automatically. Without it, only foreground (tab-open,
// focused) delivery works, which defeats the entire point of "even when
// the app is closed" notifications (see todo/real-outside-app-price-
// notifications.md).
//
// The config below matches lib/firebase_options.dart - a Firebase web
// apiKey is not a secret (see that file's doc comment for why), so it's
// fine for this to be a plain, committed file.
importScripts('https://www.gstatic.com/firebasejs/10.13.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCE6LHVqKg_wKnf8vD2EyWNpjiavxhj86I',
  authDomain: 'maroc-fly-ia.firebaseapp.com',
  projectId: 'maroc-fly-ia',
  storageBucket: 'maroc-fly-ia.firebasestorage.app',
  messagingSenderId: '746486353177',
  appId: '1:746486353177:web:304a6c26f3d5b419df4988',
});

const messaging = firebase.messaging();

// The server always sends a `notification` payload (see
// sendPriceDropNotification in price_check_job.js), which the Firebase SDK
// already displays automatically in the background - this handler exists
// only as an explicit fallback/log point, not to duplicate that display.
messaging.onBackgroundMessage((payload) => {
  console.log('firebase-messaging-sw.js: background message received', payload);
});
