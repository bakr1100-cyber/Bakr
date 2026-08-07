# Login / Registrierung (E-Mail + Passwort)

Gewünschter Umfang laut Nutzer: Login + Reise-Einstellungen + Preisalarme ans
Konto binden (nicht nur reines Login).

Blockiert auf einen einmaligen manuellen Schritt vom Nutzer - kann von Claude
nicht selbst gemacht werden (kein Zugriff auf fremde Google-/Cloudflare-Logins):

**Option A - Firebase (empfohlen, sauberste Lösung):**
1. https://console.firebase.google.com öffnen, mit Google-Konto anmelden.
2. "Projekt hinzufügen" → Name z. B. "MarocFly AI" → Analytics überspringen.
3. Build → Authentication → "Los geht's" → Sign-in method → "E-Mail/Passwort"
   aktivieren.
4. Build → Firestore Database → Datenbank erstellen (Region z. B.
   eur3/europe-west), Testmodus.
5. Projektübersicht → "</>" (Web-App registrieren) → Namen vergeben →
   Screenshot vom angezeigten Code-Block (apiKey, authDomain, projectId,
   storageBucket, messagingSenderId, appId) an Claude schicken.

**Option B - Cloudflare D1 (bereits vorhandenes Konto, aber selbst gebaute
Passwort-Sicherheit statt einer fertigen Lösung wie bei Firebase):**
Getestet am 2026-08-07: das aktuell in GitHub hinterlegte
`CLOUDFLARE_API_TOKEN` hat keine D1-Berechtigung ("Authentication error
[code: 10000]" bei `wrangler d1 create`). Der Nutzer müsste im Cloudflare-
Dashboard (dash.cloudflare.com/profile/api-tokens) ein neues Token mit
"D1 Edit"-Berechtigung erstellen (oder das bestehende erweitern) und das
GitHub-Secret aktualisieren.

Sobald einer der beiden Wege erledigt ist: Login-/Registrierungs-Bildschirme
bauen, Auth-State-Provider, Migration von Preisalarmen/Einstellungen vom
lokalen Speicher aufs Konto.
