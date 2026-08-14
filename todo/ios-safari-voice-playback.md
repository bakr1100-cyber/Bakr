# Warum die Stimme auf iOS Safari stumm blieb — Fundsammlung

Über drei Tage gesucht. Hier stehen **alle** untersuchten Ursachen, damit
niemand (auch ich nicht) sie nochmal von vorn durchgeht.

## Was bewiesen ist
| Frage | Antwort | Beleg |
|---|---|---|
| Erzeugt Azure marokkanisches Audio? | Ja | Deploy-Test: `lang=ar OK via 'azure'`, 18.487 Bytes |
| Kommt das Audio in der App an? | Ja | Testseite lädt es, Größe stimmt |
| Kann das Gerät Ton? | Ja | Nutzer hörte Piepton **und** Frauenstimme auf der Testseite |
| Ist das Gerät stumm geschaltet? | Nein | siehe oben |
| Ist es ein Cache-Problem? | Nein | Service Worker löscht sich selbst (`registration.unregister()`) |
| Liegt es am Anbieter? | Nein | Audio ist korrekt, egal ob Azure oder ElevenLabs |

**Die Testseite spielt ab, die App nicht** — auf demselben Gerät, im
selben Browser. Der Fehler liegt also allein im App-Code.

## Gefundene und behobene Ursachen (in dieser Reihenfolge)
1. **`data:`-URI.** `audioplayers` reicht Bytes als `data:`-URI an das
   Audio-Element (`setSourceBytes` → `Uri.dataFromBytes`). iOS Safari
   spielt daraus keinen Ton ab — ohne Fehlermeldung.
2. **Geste abgelaufen.** `audioplayers` erreicht `player.play()` erst nach
   mehreren `await`s (Quelle setzen, AudioContext aufwecken, abspielen).
   Safari verlangt `play()` *direkt* in der Berührung.
3. **Stumme Freischaltung.** Die Freischaltung spielte den Prime-Clip mit
   `muted = true`. iOS erlaubt stumme Wiedergabe *bedingungslos* — ein
   stummer Play schaltet daher **nichts** frei. Richtig: `volume = 0` bei
   `muted = false`.
4. **Mikrofon nie freigegeben.** `ai_chat_screen.dart` rief nach dem
   Endergebnis der Spracherkennung nie `stopListening()`. iOS hält die
   Audio-Session dann im Aufnahme-Modus, und Wiedergabe in diesem Zustand
   ist unhörbar. Behoben.

## Die eigentliche Lösung
Wiedergabe läuft jetzt über die **Web Audio API** (`package:web`,
`AudioContext` + `decodeAudioData`), nicht über ein `<audio>`-Element.
Grund: Auf dem Gerät des Nutzers hat der Web-Audio-Piepton nachweislich
funktioniert, während das Audio-Element stumm blieb. Ein einmal in einer
Geste aufgeweckter AudioContext bleibt die ganze Sitzung nutzbar — genau
das, was ein Sprachassistent braucht, dessen Audio erst nach einer
Netzwerk-Runde eintrifft. Das `<audio>`-Element bleibt als Rückfallebene.

## Falls es *immer noch* stumm ist
Auf `ton-test.html` gibt es den Knopf **„MIT MIKROFON TESTEN"**. Der spielt
einmal mit laufendem Mikrofon und einmal danach. Hört man nur **eine**
Stimme, ist die Audio-Session durch das Mikrofon blockiert und die
Wiedergabe muss weiter nach hinten verschoben werden (erst Mikrofon ganz
freigeben, kurz warten, dann sprechen).

## Nicht die Ursache (geprüft, ausgeschlossen)
- NVIDIA Nemotron/Riva als Alternative: Nemotron ist ein **Text**-Modell,
  Riva hat **kein** Marokkanisch. Kein Ersatz für Azure.
- Anbieterwechsel allgemein: Das Audio war nie das Problem.
