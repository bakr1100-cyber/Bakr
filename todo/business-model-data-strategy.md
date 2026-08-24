# Tayarti — Datenquellen & Geschäftsmodell (Entscheidung)

Kontext: Diskussion darüber, dass Duffel pro Suche abrechnet (aktuell ~1500
Suchen pro Buchung erlaubt, danach Gebühr) und Tayarti nicht selbst über
Duffel bucht, sondern per Affiliate-Link weiterleitet — also strukturell
viele Suchen, null Duffel-Buchungen.

## Kernaussage

Affiliate-Weiterleitung ist bei einer Vergleichs-App wie Tayarti nicht die
Notlösung, bis man sich "echte" Live-Preise leisten kann — es ist das
Modell selbst. Skyscanner, Kayak, Google Flights buchen alle nicht selbst.
Die eigentliche Frage ist nicht "wie kriegen wir Live-Preise in die App",
sondern: warum öffnet jemand Tayarti statt Google Flights? Antwort, die
schon existiert: Darija sprechen statt tippen, Wissen um Flug+Zug-Routen
(z. B. Casablanca → Zug nach Fès), Diaspora-Reisemuster kennen. Das braucht
ungefähr richtige Preise plus schlaue Routen, keine auf den Euro genauen
Echtzeitdaten.

## Datenquellen-Aufteilung

- **Preisalarme + "ist das gerade günstig?"** → günstige, zwischengespeicherte
  Daten (z. B. Travelpayouts' Cache-API — genaue aktuelle Konditionen vor
  dem Bauen im Travelpayouts-Dashboard verifizieren, nicht als Fakt
  übernehmen)
- **Der Moment "ich will das jetzt"** → Affiliate-Link, Live-Preis erst beim
  Partner
- **Duffel** → nur zum Entwickeln/Testen, nicht als produktive Datenquelle

## Dringend, bevor der Duffel-Live-Schlüssel gesetzt wird

Die Preis-Check-Job läuft jetzt alle 15 Minuten (96×/Tag), eine
Duffel-Suche pro beobachteter Route und Lauf:
- 10 Nutzer × 2 Alarme = 20 Routen → ~58.000 Suchen/Monat
- 100 Nutzer × 3 Alarme = 300 Routen → ~864.000 Suchen/Monat

Bei aktuell null Duffel-Buchungen. Mit dem Sandbox-Schlüssel kostenlos
(Testdaten), wird aber sofort ein Kostenrisiko, sobald `DUFFEL_API_KEY`
auf einen Live-Schlüssel umgestellt wird. Vor der Live-Umstellung entweder
auf eine Cache-Datenquelle für die Preis-Alarme wechseln, oder das
15-Minuten-Intervall wieder verlängern.

## Rentabilität — nicht nur Flug-Provisionen

Flug-Provisionen sind dünn (~1-2%, viele Klicks buchen nie). Die
Zielgruppe (Diaspora) hat wiederkehrende, oft besser zahlende Bedürfnisse:
Übergepäck, Mietwagen in Marokko, Fähren ab Spanien/Frankreich,
eSIM/Datenpakete, Reiseversicherung. Das wäre eine Ergänzung zu Flügen,
nicht ein Ersatz dafür.
