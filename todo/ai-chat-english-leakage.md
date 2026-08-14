# Die KI mischt englische Wörter in arabische/Darija-Antworten

Aufgefallen im Screen-Recording vom 14.8.2026 (nicht vom Nutzer gemeldet,
sondern beim Auswerten des Videos gesehen). Die Antworten auf Darija
enthalten mitten im arabischen Satz englische Brocken:

> ...حسناً! أتمنى أن أكون **able to help** في...
> ...يمكنني تقديم بعض الخيارات للرحلات إلى **Cities** أخرى في المغرب...

Städtenamen auf Lateinisch (Casablanca, Fès, Marrakech) sind **gewollt** -
das steht so im System-Prompt, weil Eigennamen in allen Sprachen gleich
benutzt werden. Aber `able to help` und `Cities` sind schlicht falsch: das
Modell fällt mitten im Satz ins Englische.

Der Prompt verlangt bereits ausdrücklich "translate every word ... never
leave an English word in the reply" (`_systemPrompt` in
`ai_assistant_service.dart`). Das Modell hält sich nicht daran - das ist
ein bekanntes Verhalten kleiner Modelle bei nicht-lateinischer Schrift.

## Mögliche Ansätze, wenn das angegangen wird
1. **Größeres/besseres Modell für Arabisch.** Der Worker kann schon
   zwischen Mistral und Workers AI wählen; für `ary`/`ar` gezielt das
   stärkere nehmen.
2. **Nachkontrolle**: Antwort auf lateinische Buchstaben prüfen (außer
   bekannten Städtenamen/Flughafencodes) und bei Treffern einmal neu
   generieren lassen. Deterministisch und modellunabhängig, kostet aber
   eine zweite Runde.
3. **Prompt schärfen**: Positivliste der erlaubten lateinischen Wörter
   (genau die Städtenamen aus `airport.dart`) statt der bisherigen
   allgemeinen Anweisung.

Ansatz 2 ist am verlässlichsten, 3 am billigsten. Nicht angefangen, weil
es nicht der gemeldete Fehler war und eine eigene Testrunde braucht.
