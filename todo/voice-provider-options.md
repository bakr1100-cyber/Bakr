# Bessere Stimme: die Optionen der Reihe nach durchprobieren

Der Worker kann jetzt zwischen mehreren Sprachdiensten wählen
(`cloudflare-worker/src/tts_providers.js`). Welcher benutzt wird, hängt
**nur davon ab, welche Schlüssel hinterlegt sind** - kein Code muss
geändert werden, um zu wechseln. Reihenfolge, wenn mehrere gesetzt sind:
Azure → Google → ElevenLabs → MeloTTS (gratis, funktioniert aber derzeit
nicht).

Alle Schlüssel kommen an dieselbe Stelle wie der Duffel-Schlüssel:
`github.com/bakr1100-cyber/Bakr/settings/secrets/actions`

Nach dem Eintragen: Der nächste Deploy übernimmt ihn automatisch. Im
Deploy-Protokoll steht dann bei jeder Sprache, welcher Dienst geantwortet
hat, z.B. `lang=de OK via 'azure'`.

---

## Schritt 0 (erledigt, kostenlos): die eingebaute Stimme
Die App nahm bisher immer die **erste** Stimme, die der Browser für eine
Sprache auflistet - auf Apple-Geräten ist das meistens die dünne
"Compact"-Variante, obwohl die deutlich bessere "Enhanced"/"Premium"-Stimme
oft schon installiert ist. Die App sucht jetzt aktiv die beste aus.

**Bitte zuerst so testen.** Wenn das schon gut klingt, kannst du dir alles
Weitere sparen.

Tipp fürs iPad, falls es noch dünn klingt: Einstellungen → Bedienungshilfen
→ Gesprochene Inhalte → Stimmen → Deutsch → dort eine Stimme mit dem
Zusatz *(Erweitert)* oder *(Premium)* herunterladen. Die App nimmt sie dann
automatisch.

---

## ✅ Option 1: Microsoft Azure — ERLEDIGT, LÄUFT
Eingerichtet am 14.8.2026, Region `northeurope`, Tarif F0 (gratis).
Der Deploy-Test bestätigt alle vier Sprachen über Azure, inklusive
marokkanischem Arabisch (`ar-MA-MounaNeural`).

**Noch offen (Hygiene, kein Fehler):** Der Azure-Schlüssel war einmal in
einem Screenshot sichtbar. Gelegentlich im Azure-Portal unter „Schlüssel
und Endpunkt" auf „Schlüssel1 neu generieren" tippen und den neuen Wert im
GitHub-Secret `AZURE_SPEECH_KEY` ersetzen. Freier Tarif, also kein
Kostenrisiko - nur sauberer.

Die ursprüngliche Anleitung, falls du es je neu aufsetzen musst:

### Microsoft Azure — die einzige mit echtem Marokkanisch
Der stärkste Vorteil für deine Zielgruppe: Azure hat echte marokkanische
Stimmen (`ar-MA-MounaNeural` weiblich, `ar-MA-JamalNeural` männlich).
Kein anderer der drei Dienste hat das. Deutsch und Französisch sind
ebenfalls sehr gut. Gratis: 500.000 Zeichen pro Monat.

1. portal.azure.com → Konto anlegen (Kreditkarte nur zur Anmeldung nötig,
   im Gratis-Rahmen wird nichts abgebucht)
2. "Create a resource" → nach **"Speech"** suchen → anlegen
3. Beim Anlegen: Pricing tier auf **F0 (Free)** stellen
4. Nach dem Anlegen → "Keys and Endpoint" → dort stehen **Key 1** und
   **Location/Region** (z.B. `westeurope`)

Zwei GitHub-Secrets anlegen:
- `AZURE_SPEECH_KEY` = Key 1
- `AZURE_SPEECH_REGION` = die Region (nur das Wort, z.B. `westeurope`)

---

## Option 2: Google Cloud — kein zusätzliches Konto nötig
Sehr gutes Deutsch/Französisch. Arabisch nur Hocharabisch (`ar-XA`), kein
Marokkanisch. Vorteil: für die Push-Benachrichtigungen legst du ohnehin
schon ein Google-Cloud-Konto an. Gratis: 1 Mio. Zeichen/Monat (WaveNet).

1. console.cloud.google.com → dasselbe Projekt wie Firebase auswählen
2. "APIs & Services" → "Enable APIs" → **"Cloud Text-to-Speech API"**
   aktivieren
3. "APIs & Services" → "Credentials" → "Create credentials" → **API key**
4. Den Schlüssel kopieren

Ein GitHub-Secret:
- `GOOGLE_TTS_API_KEY` = der API key

---

## Option 3: ElevenLabs — für Darija, gezielt nur dafür
**Von Bakr gefunden: „Ghizlane – Moroccan Darija" in der Voice Library.**
Das ist inhaltlich besser als Azure für Arabisch: Azures `ar-MA` ist
Hocharabisch mit marokkanischem Akzent, Ghizlane ist auf echtem Darija
trainiert.

Der Worker ist darauf vorbereitet: sobald `ELEVENLABS_VOICE_ID_AR` gesetzt
ist, geht **nur Arabisch** an ElevenLabs, alles andere bleibt bei Azure.
So reicht das kleine Gratis-Kontingent (ca. 10.000 Zeichen/Monat) für die
Sprache, wo es den größten Unterschied macht.

So kommst du an die Voice-ID:
1. elevenlabs.io → Konto anlegen
2. **Voice Library** öffnen → nach „Ghizlane" suchen → **„Add to my
   voices"**
3. **My Voices** → die Stimme antippen → dort steht die **Voice ID**
   (eine lange Buchstaben-Zahlen-Folge) → kopieren
4. Profil (oben rechts) → **API Keys** → Schlüssel erstellen → kopieren

Zwei GitHub-Secrets:
- `ELEVENLABS_API_KEY` = der Schlüssel
- `ELEVENLABS_VOICE_ID_AR` = die Voice ID von Ghizlane

### Die allgemeine ElevenLabs-Info
Klingt am menschlichsten, alle Sprachen über ein Modell. Aber: gratis nur
ca. 10.000 Zeichen/Monat - das sind wenige Minuten. Danach kostenpflichtig
(ab ca. 5 $/Monat).

1. elevenlabs.io → Konto anlegen
2. Profil (oben rechts) → "API Keys" → neuen Schlüssel erstellen

Ein GitHub-Secret:
- `ELEVENLABS_API_KEY` = der Schlüssel
- optional `ELEVENLABS_VOICE_ID`, wenn du in deren "Voice Library" eine
  bestimmte Stimme aussuchst; sonst wird eine Standardstimme benutzt

---

## Wichtig zum Umschalten
Sind mehrere Schlüssel gesetzt, gewinnt **Azure vor Google vor
ElevenLabs**. Zum Vergleichen also am besten immer nur einen gleichzeitig
gesetzt lassen (die anderen Secrets löschen oder leeren) - dann hörst du
eindeutig, wen du gerade testest, und das Deploy-Protokoll bestätigt es
(`OK via 'azure'` / `'google'` / `'elevenlabs'`).

## Schutzschaltung (erledigt)
`_cloudTtsEnabledByDefault` in `lib/services/voice_service.dart` steht auf
`true`. Schlägt der Dienst zweimal hintereinander fehl, hört die App für
die Sitzung auf, es zu versuchen, und nimmt sofort die Gerätestimme - eine
Störung beim Anbieter kann die App also nicht ausbremsen.
