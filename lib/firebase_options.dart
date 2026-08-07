// File generated from the Firebase console (Project overview -> Add app ->
// Web -> "Firebase SDK snippet"), not by the `flutterfire configure` CLI -
// this environment has no interactive browser to run that tool's Google
// OAuth login. Structured to match its usual output so a real
// `flutterfire configure` run later would replace this cleanly.
//
// Unlike DUFFEL_API_KEY (a genuine secret proxied through the Cloudflare
// Worker so it never ships in the client bundle), a Firebase *web* apiKey
// is not a secret - Firebase's own docs say it's fine for it to be public
// in client-side code, since it only identifies the project, not
// authorizes access (that's what Firebase Auth + Firestore/Storage
// security rules are for). Safe to commit; only the `web` platform is
// configured since this app is only deployed to the web.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'DefaultFirebaseOptions have only been configured for web '
      '(this app is only deployed as a web build) - '
      'target platform was $defaultTargetPlatform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCE6LHVqKg_wKnf8vD2EyWNpjiavxhj86I',
    authDomain: 'maroc-fly-ia.firebaseapp.com',
    projectId: 'maroc-fly-ia',
    storageBucket: 'maroc-fly-ia.firebasestorage.app',
    messagingSenderId: '746486353177',
    appId: '1:746486353177:web:304a6c26f3d5b419df4988',
    measurementId: 'G-E9186KHB8P',
  );
}
